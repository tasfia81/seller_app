"""Local development store: one JSON file on disk, guarded by a lock.

Each transaction works on a copy of the data and replaces it only when the
block finishes without an error, then writes the file atomically.
"""

import copy
import json
import os
import threading
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path

from .base import Doc, Store, Tx


class _LocalTx(Tx):
    def __init__(self, data: dict[str, dict[str, Doc]]):
        self.data = data
        self.dirty = False

    def get(self, collection: str, doc_id: str) -> Doc | None:
        doc = self.data.get(collection, {}).get(doc_id)
        return copy.deepcopy(doc) if doc is not None else None

    def list(self, collection: str) -> list[Doc]:
        return [copy.deepcopy(d) for d in self.data.get(collection, {}).values()]

    def put(self, collection: str, doc: Doc) -> Doc:
        if "id" not in doc:
            raise ValueError("document needs an 'id'")
        self.data.setdefault(collection, {})[doc["id"]] = copy.deepcopy(doc)
        self.dirty = True
        return doc

    def delete(self, collection: str, doc_id: str) -> None:
        self.data.get(collection, {}).pop(doc_id, None)
        self.dirty = True


class LocalStore(Store):
    def __init__(self, path: Path | None):
        """`path=None` keeps everything in memory (used by tests)."""
        self.path = path
        self._lock = threading.RLock()
        self._data: dict[str, dict[str, Doc]] = {}
        if path and path.exists():
            self._data = json.loads(path.read_text(encoding="utf-8"))

    def is_empty(self) -> bool:
        return not any(self._data.values())

    @contextmanager
    def transaction(self) -> Iterator[Tx]:
        with self._lock:
            working = copy.deepcopy(self._data)
            tx = _LocalTx(working)
            yield tx  # an exception here discards `working`
            if tx.dirty:
                self._data = working
                self._save()

    def _save(self) -> None:
        if not self.path:
            return
        self.path.parent.mkdir(parents=True, exist_ok=True)
        tmp = self.path.with_suffix(".tmp")
        tmp.write_text(json.dumps(self._data, ensure_ascii=False, indent=1), encoding="utf-8")
        os.replace(tmp, self.path)

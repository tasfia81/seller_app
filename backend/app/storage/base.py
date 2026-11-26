"""Storage contract.

Data is organised as *collections of documents* (dicts with an "id"), exactly
like Firestore, so moving from the local JSON store to Firebase only means
writing a new `Store` implementation — services and routes stay the same.

All reads and writes happen inside `store.transaction()`; a transaction either
commits completely or not at all.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from collections.abc import Callable, Iterator
from contextlib import AbstractContextManager
from typing import Any

Doc = dict[str, Any]


class Tx(ABC):
    @abstractmethod
    def get(self, collection: str, doc_id: str) -> Doc | None: ...

    @abstractmethod
    def list(self, collection: str) -> list[Doc]: ...

    @abstractmethod
    def put(self, collection: str, doc: Doc) -> Doc: ...

    @abstractmethod
    def delete(self, collection: str, doc_id: str) -> None: ...

    def find(self, collection: str, pred: Callable[[Doc], bool]) -> list[Doc]:
        return [d for d in self.list(collection) if pred(d)]

    def first(self, collection: str, pred: Callable[[Doc], bool]) -> Doc | None:
        return next((d for d in self.list(collection) if pred(d)), None)


class Store(ABC):
    @abstractmethod
    def transaction(self) -> AbstractContextManager[Tx]: ...

    @abstractmethod
    def is_empty(self) -> bool: ...

    def iter_all(self, collection: str) -> Iterator[Doc]:
        with self.transaction() as tx:
            yield from tx.list(collection)

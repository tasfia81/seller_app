from ..core.config import settings
from .base import Store
from .local import LocalStore

_store: Store | None = None


def get_store() -> Store:
    global _store
    if _store is None:
        if settings.storage == "firestore":
            from .firestore import FirestoreStore

            _store = FirestoreStore()
        else:
            _store = LocalStore(settings.data_file)
    return _store


def reset_store(store: Store | None) -> None:
    """Swap the active store (tests use an in-memory LocalStore)."""
    global _store
    _store = store

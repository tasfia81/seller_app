"""Firebase (Cloud Firestore) store — to be implemented when Firebase is connected.

Plan:
  1. `pip install firebase-admin`, set GOOGLE_APPLICATION_CREDENTIALS to the
     service-account JSON (never commit it).
  2. Implement `FirestoreStore.transaction()` with `firestore.transactional`,
     mapping Tx.get/list/put/delete to document reads/writes in the same
     collection names used by the local store.
  3. Run with STORAGE=firestore.
"""

from contextlib import AbstractContextManager

from ..core.errors import NotImplementedYet
from .base import Store, Tx


class FirestoreStore(Store):
    def __init__(self) -> None:
        raise NotImplementedYet("Firebase এখনো যুক্ত করা হয়নি। এখন STORAGE=local ব্যবহার করুন।")

    def transaction(self) -> AbstractContextManager[Tx]:  # pragma: no cover
        raise NotImplementedYet("Firebase এখনো যুক্ত করা হয়নি।")

    def is_empty(self) -> bool:  # pragma: no cover
        raise NotImplementedYet("Firebase এখনো যুক্ত করা হয়নি।")

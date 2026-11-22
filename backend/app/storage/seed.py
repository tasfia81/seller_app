"""Development seed data — clothing products, one admin, two sellers, one pending application.

Runs only when the local store is empty and SEED_DEMO_DATA=true. Contains no real
people or NID numbers. Logins (development only):
    admin  : 01711000000 / admin1234
    seller : 01712345678 / seller1234   (রাকিব হাসান)
    seller : 01819223344 / seller1234   (নুসরাত জাহান)
    investor: 01913000000 / invest1234  (আশরাফুল করিম — funded the jersey L batch)
"""

from datetime import date

from ..core.security import hash_password
from ..core.utils import now_iso
from ..schemas import ApplicationIn, AssignItemIn, AssignmentIn, CategoryIn, HandoverIn, ProductIn, SaleIn, StockReceiptIn
from ..schemas_investor import FundedBatchIn, FundingPartIn, InvestmentIn, InvestorApplicationIn
from ..services import applications, catalog, finance, inventory, investors, sales
from ..services.common import SETTINGS, USERS
from ..services.system import DEFAULT_SETTINGS
from .base import Store

ADMIN = {"id": "usr_admin", "name": "তানভীর আহমেদ"}


def _addr(detail: str, upazila: str, district: str) -> dict:
    return {"division": "ঢাকা", "district": district, "upazila": upazila, "detail": detail}


def _applicant(name: str, mobile: str, nid: str, dob: date) -> ApplicationIn:
    return ApplicationIn(
        full_name=name, mobile=mobile, date_of_birth=dob, gender=None, email=None, guardian_name=None,
        present_address=_addr("বাড়ি ১২, রোড ৩", "মিরপুর", "ঢাকা"), permanent_address=_addr("বাড়ি ১২, রোড ৩", "মিরপুর", "ঢাকা"),
        nid_number=nid, emergency={"name": "সালমা বেগম", "relation": "মা", "mobile": "01819000111"},
        password="seller1234", accepted_privacy=True, accepted_terms=True,
    )


def seed(store: Store) -> None:
    with store.transaction() as tx:
        tx.put(SETTINGS, DEFAULT_SETTINGS)
        tx.put(USERS, {"id": "usr_admin", "role": "admin", "name": ADMIN["name"], "mobile": "01711000000", "email": "admin@streetsales.local",
                       "password_hash": hash_password("admin1234"), "status": "active", "seller_id": None, "application_id": None,
                       "session_version": 0, "created_at": now_iso()})

        cats = {n: catalog.create_category(tx, ADMIN, CategoryIn(name=n))["id"] for n in ("জার্সি", "টি-শার্ট", "প্যান্ট", "অ্যাক্সেসরিজ")}
        P = {}
        for key, data in {
            "jersey": ProductIn(name="জার্সি — বাংলাদেশ", category_id=cats["জার্সি"], sku="JRS-BD", unit_cost=350, price=450, variant_label="সাইজ", variants=["S", "M", "L", "XL"], low_stock_at=20),
            "polo": ProductIn(name="পোলো টি-শার্ট", category_id=cats["টি-শার্ট"], sku="TS-POLO", unit_cost=260, price=380, min_price=350, max_price=420, price_editable=True, variant_label="সাইজ", variants=["M", "L", "XL"]),
            "basic": ProductIn(name="বেসিক টি-শার্ট (সাদা)", category_id=cats["টি-শার্ট"], sku="TS-BSC-W", unit_cost=160, price=250, variant_label="সাইজ", variants=["M", "L", "XL", "XXL"], low_stock_at=20),
            "jogger": ProductIn(name="জগার প্যান্ট", category_id=cats["প্যান্ট"], sku="PNT-JOG", unit_cost=360, price=550, min_price=500, max_price=600, price_editable=True, variant_label="সাইজ", variants=["M", "L", "XL"]),
            "cap": ProductIn(name="ক্রিকেট ক্যাপ", category_id=cats["অ্যাক্সেসরিজ"], sku="ACC-CAP", unit_cost=110, price=180, low_stock_at=20),
            "socks": ProductIn(name="মোজা (৩ জোড়া)", category_id=cats["অ্যাক্সেসরিজ"], sku="ACC-SOCK3", unit="packet", unit_cost=90, price=150),
        }.items():
            P[key] = catalog.create_product(tx, ADMIN, data)["id"]

        # Demo investor: approved through the normal KYC flow, money recorded, then funds a batch.
        inv_app = investors.submit_application(tx, InvestorApplicationIn(
            full_name="আশরাফুল করিম", mobile="01913000000", date_of_birth=date(1986, 5, 20), occupation="চাকরিজীবী", funds_source="বেতন / সঞ্চয়",
            address=_addr("বাড়ি ৪, রোড ৭", "উত্তরা", "ঢাকা"), nid_number="4455667788", proposed_amount=50000,
            payout={"method": "bkash", "account_name": "আশরাফুল করিম", "account_number": "01913000000"},
            nominee={"name": "রেহানা করিম", "relation": "স্ত্রী", "mobile": "01913000111"},
            password="invest1234", accepted_risk=True, accepted_terms=True))
        inv_user = tx.get(USERS, inv_app["user_id"])
        for kind in investors.DOC_KINDS:
            investors.record_document(tx, inv_user, kind, "seed/placeholder.jpg", "image/jpeg")
        investor_id = investors.approve_application(tx, ADMIN, inv_app["application_id"], None)["investor_id"]
        investors.record_investment(tx, ADMIN, InvestmentIn(investor_id=investor_id, amount=50000, method="bank", reference="SEED-FT-0001",
                                                           received_on=date(2026, 11, 1), seen_in_statement=True, client_request_id="seed-investment-01"))

        for key, variant, qty in [("jersey", "S", 10), ("jersey", "M", 30), ("jersey", "L", 60), ("jersey", "XL", 20), ("polo", "M", 24), ("polo", "L", 30),
                                  ("polo", "XL", 22), ("basic", "M", 80), ("basic", "L", 60), ("basic", "XL", 40), ("jogger", "M", 20), ("jogger", "L", 24),
                                  ("jogger", "XL", 10), ("cap", None, 26)]:
            cost = {"jersey": 350, "polo": 260, "basic": 160, "jogger": 360, "cap": 110}[key]
            if (key, variant) == ("jersey", "L"):  # 60 × ৳350 = ৳21,000, all investor money
                investors.fund_batch(tx, ADMIN, FundedBatchIn(product_id=P[key], variant=variant, quantity=qty, unit_cost=cost, batch_ref="ব্যাচ-৮৮",
                                                              supplier="রহমান গার্মেন্টস", parts=[FundingPartIn(investor_id=investor_id, amount=qty * cost)]))
                continue
            inventory.receive_stock(tx, ADMIN, StockReceiptIn(product_id=P[key], variant=variant, quantity=qty, unit_cost=cost, supplier="রহমান গার্মেন্টস", batch_ref="ব্যাচ-৮৮"))

        sellers_created = {}
        for name, mobile, nid in [("রাকিব হাসান", "01712345678", "1234567894521"), ("নুসরাত জাহান", "01819223344", "9876543210")]:
            created = applications.submit(tx, _applicant(name, mobile, nid, date(1999, 3, 14)))
            user = tx.get(USERS, created["user_id"])
            for kind in applications.DOC_KINDS:
                applications.record_document(tx, user, kind, "seed/placeholder.jpg", "image/jpeg")
            sellers_created[name] = applications.approve(tx, ADMIN, created["application_id"])["seller_id"]
        applications.submit(tx, _applicant("ফাহিম রহমান", "01812445566", "5500112233", date(2003, 3, 12)))

    with store.transaction() as tx:
        rakib = tx.get("sellers", sellers_created["রাকিব হাসান"])
        asg = inventory.create_assignment(tx, ADMIN, AssignmentIn(seller_id=rakib["id"], items=[
            AssignItemIn(product_id=P["jersey"], variant="L", quantity=20), AssignItemIn(product_id=P["polo"], variant="XL", quantity=10),
            AssignItemIn(product_id=P["basic"], variant="M", quantity=10)], price_mode="flexible"))
        inventory.accept_assignment(tx, rakib, asg["id"])
        sales.create_sale(tx, rakib, SaleIn(product_id=P["jersey"], variant="L", quantity=2, unit_price=450, payment="bkash", client_request_id="seed-sale-0001"))
        sales.create_sale(tx, rakib, SaleIn(product_id=P["polo"], variant="XL", quantity=1, unit_price=380, payment="cash", client_request_id="seed-sale-0002"))
        sales.create_sale(tx, rakib, SaleIn(product_id=P["basic"], variant="M", quantity=3, unit_price=250, payment="cash", client_request_id="seed-sale-0003"))
        finance.submit_handover(tx, rakib, HandoverIn(amount=1000, method="in_person", note="সকালের বিক্রির ক্যাশ"))

        nusrat = tx.get("sellers", sellers_created["নুসরাত জাহান"])
        inventory.create_assignment(tx, ADMIN, AssignmentIn(seller_id=nusrat["id"], items=[AssignItemIn(product_id=P["jogger"], variant="M", quantity=6), AssignItemIn(product_id=P["cap"], quantity=6)]))

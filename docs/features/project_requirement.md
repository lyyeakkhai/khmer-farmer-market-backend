# Khmer Farmer Market — Database Requirements

---

## 1. Overview

The database must support a multi-role digital marketplace platform for Cambodian farmers.
It must be relational, normalized to 3NF, and designed for scalability, data integrity, and auditability.

---

## 2. Core Database Requirements

### 2.1 User & Authentication
- Store user accounts with email (unique), avatar, status, and soft-delete support
- Support multiple auth providers per user: email/password, Google, Facebook
- Password hash stored only for email provider; null for social logins
- Track active sessions per user with device info, IP, expiry, and revocation
- Enforce unique provider_uid per provider to prevent duplicate social accounts

### 2.2 Role & Access Control
- Define fixed roles: customer, shop_owner, super_admin
- Link users to roles via MEMBERSHIPS table (supports multiple roles per user)
- Shop owners must have a shop_id in their membership record
- Customers and admins have null shop_id in membership
- Soft-delete memberships (deleted_at) to preserve audit history

### 2.3 Customer Profile
- Each user account maps to exactly one CUSTOMERS record (1:1)
- Store customer name and phone number separately from USERS
- Customer profile required before placing any order

### 2.4 Address Management
- Store user addresses in address_user table (house number, province, lat/lng)
- Users can have a default address linked via USERS.address_id (nullable FK)
- Delivery address must be snapshotted at order time — never rely on live address data

---

## 3. Shop & Product Requirements

### 3.1 Shop
- Each shop has a unique slug for URL routing
- Shops support soft-delete via is_deleted flag (not physical deletion)
- Shop metadata stored as JSON for flexible extra attributes
- One shop can have many members (owner + staff via MEMBERSHIPS)

### 3.2 Categories
- Two-tier category system:
  - Platform_categories: managed by admin, hierarchical (self-referencing parent_id), with Khmer name support
  - CATEGORIES: shop-level, flat list, owned by a specific shop
- Products must belong to a shop category; platform category is optional (for discovery)
- Platform categories support image and active/inactive toggle

### 3.3 Products
- Each product belongs to one shop and one shop-level category
- Product slug must be globally unique
- base_price must be >= 0; quantity must be >= 0
- Stock quantity decremented on order placement
- Products can be linked to a platform category for cross-shop browsing
- Multiple images per product stored in ProductImage table

### 3.4 Events / Promotions
- Shop owners create EVENTTYPE records with discount rules (percentage or fixed amount)
- Products are assigned to events via EVENTPRODUCT (many products per event)
- EVENTPRODUCT supports soft-delete (deleted_at) and status toggle
- Discounted price calculated at runtime: base_price minus discount rule

---

## 4. Order Requirements

### 4.1 Order
- Orders are scoped per shop (one order = one shop)
- Order stores total_price, discount_price, subtotal_price as snapshots at time of purchase
- Status lifecycle: pending → paid → processing → shipped → delivered → cancelled
- seller_id (FK to USERS) records which shop owner fulfilled the order

### 4.2 Order Items
- Each ORDERITEM stores sold_price as a snapshot (not live product price)
- quantities must be > 0
- One order can have many items (1:N)

---

## 5. Payment Requirements

### 5.1 Payment Methods
- Shops register payment methods: Visa, Mastercard, Bakong KHQR
- Gateway tokens stored encrypted (VARCHAR 500)
- Card last four digits and expiry stored for display purposes

### 5.2 Transactions
- One transaction per order (can have multiple payment attempts via PAYMENT_INTENTS)
- Transaction records: amount, total_amount, currency (default USD), bank_ref_id from gateway
- Links to the platform fee rule applied at time of transaction
- customer_id and shop_id both stored on transaction for reporting

### 5.3 Payment Intents
- Each payment attempt creates a PAYMENT_INTENTS record
- Bakong KHQR: qr_code_data stored as TEXT
- Status: pending → completed / expired / failed
- expires_at enforced to invalidate stale payment attempts

### 5.4 Invoices
- Auto-generated on successful payment (1:1 with TRANSACTION)
- invoice_no must be globally unique
- Stores sub_total, tax_amount, discount_price, total_amount as immutable snapshot
- Status: draft → issued → paid → cancelled

---

## 6. Delivery Requirements

### 6.1 Delivery Record
- One DELIVERY record per order
- Links to order_delivery_snapshot (not live address) for immutable delivery address

### 6.2 Delivery Address Snapshot
- order_delivery_snapshot copies recipient_name, phone, address fields at order time
- Preserves delivery address even if customer later updates their profile address
- Stores lat/lng for map-based tracking

### 6.3 Delivery Logs
- Each status change appends a new delivery_logs record (append-only audit trail)
- Stores status string, location_description, and timestamp
- Enables real-time shipment tracking history

### 6.4 Hubs
- Physical hub locations stored with province, address, contact_number
- Used as reference points in delivery routing (not directly FK'd to delivery_logs)

---

## 7. Notification Requirements

- Notifications scoped per user (user_id FK)
- Type enum: order, payment, shipment, promotion, verification
- Priority enum: low, medium, high
- is_read flag updated when user views notification
- link_url optional for deep-linking into app screens
- created_at indexed for chronological feed queries

---

## 8. Analytics & Reporting Requirements

### 8.1 Shop Daily Snapshots
- Nightly batch job aggregates per-shop metrics into DAILY_SNAPSHOTS
- Composite unique constraint on (shop_id, snapshot_date) — one record per shop per day
- Stores total_gross, total_profit, order_count

### 8.2 Category Snapshots
- DAILY_C_SNAPSHOTS breaks down each daily snapshot by shop category
- Stores cat_gross_revenue, cat_net_profit, cat_items_sold per category per day

### 8.3 Product Snapshots
- daily_product_snapshots breaks down each category snapshot by product
- Stores qty_sold, base_cost_price, unit_sale_price, stock_at_midnight
- Enables per-product performance tracking over time

### 8.4 Platform Revenue Snapshots
- platform_revenue_snapshots links to individual transactions
- Tracks active_paying_shops count per snapshot_date
- Used by Super Admin for platform-level revenue reporting

---

## 9. Platform Fee Requirements

- Admin defines fee rules in PlatformFee with effective_from date
- fee_type: percentage (0–100%) or fixed amount
- Only one active fee rule applies per transaction (fetched by effective_from <= transaction date)
- TRANSACTION.platform_fee_id records which rule was applied (immutable after payment)
- status field allows admin to deactivate old rules without deleting them

---

## 10. Data Integrity Rules

| Rule | Detail |
|---|---|
| Soft deletes | USERS, MEMBERSHIPS, EVENTPRODUCT use deleted_at instead of hard delete |
| Price snapshots | sold_price in ORDERITEM, sub_total in INVOICES are immutable after creation |
| Address snapshots | order_delivery_snapshot copied at order time, never updated |
| Unique slugs | SHOPS.slug, PRODUCTS.slug, Platform_categories.slug must be globally unique |
| Stock constraint | PRODUCTS.quantity CHECK >= 0 prevents negative stock |
| Fee immutability | TRANSACTION.platform_fee_id set at payment time, not recalculated |
| Session revocation | USER_SESSIONS.revoked_at set on logout; expires_at enforced server-side |
| Invoice uniqueness | INVOICES.invoice_no UNIQUE across all records |

---

## 11. Indexing Recommendations

| Table | Index On | Reason |
|---|---|---|
| USERS | email | Login lookup |
| USER_AUTH | (provider, provider_uid) | Social login dedup |
| USER_SESSIONS | session_uuid | Token validation |
| PRODUCTS | slug | URL routing |
| PRODUCTS | (shop_id, category_id) | Shop inventory queries |
| ORDERS | (customer_id, status) | Customer order history |
| ORDERS | (shop_id, status) | Shop order management |
| TRANSACTION | order_id | Payment lookup per order |
| DAILY_SNAPSHOTS | (shop_id, snapshot_date) | Dashboard queries |
| NOTIFICATIONS | (user_id, is_read) | Unread notification feed |
| delivery_logs | delivery_id | Shipment tracking history |

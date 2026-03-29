# Khmer Farmer Market — Database Design

---

## 1. Design Principles

- Relational model normalized to 3NF
- Soft deletes preferred over hard deletes for auditable entities
- Price and address data snapshotted at transaction time (immutable records)
- Enum types used for fixed-value status fields
- All monetary values stored as DECIMAL(15,2) to avoid floating-point errors
- Timestamps stored as TIMESTAMP (UTC); dates stored as DATE where time is irrelevant

---

## 2. Table Design

---

### 2.1 USERS

**Purpose:** Central identity record for every person on the platform. All other user-related tables reference this. Stores minimal identity data; auth credentials live in USER_AUTH.

| Column | Type | Constraints | Description |
|---|---|---|---|
| user_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique user identifier |
| email | VARCHAR(255) | NOT NULL, UNIQUE | Login email address |
| avatar_url | VARCHAR(500) | NULLABLE | Profile picture URL |
| status | ENUM('active','inactive','banned') | NOT NULL, DEFAULT 'active' | Account status |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Account creation time |
| last_login_at | TIMESTAMP | NULLABLE | Last successful login |
| deleted_at | TIMESTAMP | NULLABLE | Soft delete timestamp |
| address_id | INT | FK → address_user.address_id, NULLABLE | Default delivery address pointer |

---

### 2.2 USER_AUTH

**Purpose:** Stores authentication credentials per provider. Separates auth logic from identity, allowing one user to have multiple login methods (email + Google + Facebook).

| Column | Type | Constraints | Description |
|---|---|---|---|
| auth_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique auth record ID |
| user_id | INT | FK → USERS.user_id, NOT NULL | Owning user |
| provider | ENUM('email','google','facebook') | NOT NULL | Auth provider type |
| provider_uid | VARCHAR(255) | NOT NULL | External provider user ID |
| password_hash | VARCHAR(255) | NULLABLE | Bcrypt hash; null for social logins |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Auth method created time |
| last_login_at | TIMESTAMP | NULLABLE | Last login via this provider |

---

### 2.3 USER_SESSIONS

**Purpose:** Tracks active login sessions per user per device. Enables multi-device session management, forced logout, and security auditing.

| Column | Type | Constraints | Description |
|---|---|---|---|
| session_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique session ID |
| session_uuid | UUID | NOT NULL, UNIQUE | Token used in auth headers |
| user_id | INT | FK → USERS.user_id, NOT NULL | Session owner |
| device_name | VARCHAR(100) | NULLABLE | e.g. "iPhone 14" |
| device_type | VARCHAR(50) | NULLABLE | e.g. "mobile", "web" |
| ip_address | VARCHAR(45) | NULLABLE | IPv4 or IPv6 |
| user_agent | TEXT | NULLABLE | Browser/app user agent string |
| created_at | TIMESTAMP | NOT NULL | Session start time |
| last_activity | TIMESTAMP | NULLABLE | Last API call timestamp |
| expires_at | TIMESTAMP | NOT NULL | Session expiry time |
| revoked_at | TIMESTAMP | NULLABLE | Set on logout or forced revoke |

---

### 2.4 ROLES

**Purpose:** Lookup table defining the three fixed roles on the platform. Referenced by MEMBERSHIPS to assign roles to users.

| Column | Type | Constraints | Description |
|---|---|---|---|
| role_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique role ID |
| role_name | ENUM('customer','shop_owner','super_admin') | NOT NULL, UNIQUE | Role label |

---

### 2.5 MEMBERSHIPS

**Purpose:** Junction table linking users to roles and optionally to shops. A user can hold multiple memberships (e.g. customer + shop_owner of different shops). Soft-deleted to preserve history.

| Column | Type | Constraints | Description |
|---|---|---|---|
| member_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique membership ID |
| user_id | INT | FK → USERS.user_id, NOT NULL | The user |
| role_id | INT | FK → ROLES.role_id, NOT NULL | The assigned role |
| shop_id | INT | FK → SHOPS.shop_id, NULLABLE | Shop context (null for customer/admin) |
| created_at | TIMESTAMP | NOT NULL | Membership granted time |
| updated_at | TIMESTAMP | NULLABLE | Last modification time |
| deleted_at | TIMESTAMP | NULLABLE | Soft delete timestamp |

---

### 2.6 CUSTOMERS

**Purpose:** Extended profile for users with the customer role. Stores customer-specific data (name, phone) separate from the core USERS table to keep identity lean.

| Column | Type | Constraints | Description |
|---|---|---|---|
| customer_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique customer ID |
| user_id | INT | FK → USERS.user_id, NOT NULL, UNIQUE | Linked user account (1:1) |
| name | VARCHAR(150) | NOT NULL | Customer display name |
| phone_number | VARCHAR(20) | NULLABLE | Contact phone number |

---

### 2.7 address_user

**Purpose:** Stores saved delivery addresses for users. Supports multiple addresses per user. The default address is referenced from USERS.address_id. Addresses are snapshotted to order_delivery_snapshot at order time — never read live during delivery.

| Column | Type | Constraints | Description |
|---|---|---|---|
| address_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique address ID |
| user_id | INT | FK → USERS.user_id, NOT NULL | Address owner |
| house_number | VARCHAR(50) | NULLABLE | House/building number |
| province | VARCHAR(100) | NULLABLE | Province or city |
| lat | DECIMAL(10,7) | NULLABLE | GPS latitude |
| lng | DECIMAL(10,7) | NULLABLE | GPS longitude |

---

### 2.8 SHOPS

**Purpose:** Represents a farmer's storefront on the platform. Each shop is independently managed by its owner(s) via MEMBERSHIPS. Supports soft-delete and flexible metadata via JSON.

| Column | Type | Constraints | Description |
|---|---|---|---|
| shop_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique shop ID |
| shop_name | VARCHAR(200) | NOT NULL | Display name of the shop |
| slug | VARCHAR(200) | NOT NULL, UNIQUE | URL-friendly identifier |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE | Whether shop is publicly visible |
| is_deleted | BOOLEAN | NOT NULL, DEFAULT FALSE | Soft delete flag |
| created_at | TIMESTAMP | NOT NULL | Shop creation time |
| updated_at | TIMESTAMP | NULLABLE | Last update time |
| metadata | JSON | NULLABLE | Extra shop info (description, banner, etc.) |

---

### 2.9 Platform_categories

**Purpose:** Admin-managed global category taxonomy for platform-wide product discovery. Supports hierarchical structure via parent_id self-reference and bilingual names (English + Khmer).

| Column | Type | Constraints | Description |
|---|---|---|---|
| category_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique platform category ID |
| name | VARCHAR(150) | NOT NULL | English category name |
| khmer_name | VARCHAR(150) | NULLABLE | Khmer language name |
| slug | VARCHAR(150) | NOT NULL, UNIQUE | URL-friendly identifier |
| parent_id | INT | NULLABLE, self-ref FK | Parent category for hierarchy |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE | Visibility toggle |
| image | VARCHAR(500) | NULLABLE | Category icon/image URL |

---

### 2.10 CATEGORIES

**Purpose:** Shop-level product categories created and managed by the shop owner. Organizes products within a single shop. Separate from platform categories to give owners full control over their own taxonomy.

| Column | Type | Constraints | Description |
|---|---|---|---|
| category_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique shop category ID |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL | Owning shop |
| name | VARCHAR(150) | NOT NULL | Category display name |
| slug | VARCHAR(150) | NOT NULL | URL-friendly identifier |
| sort_order | INT | NOT NULL, DEFAULT 0 | Display ordering |

---

### 2.11 PRODUCTS

**Purpose:** Core product listing table. Each product belongs to one shop and one shop-level category. Optionally linked to a platform category for cross-shop discovery. Tracks live stock quantity.

| Column | Type | Constraints | Description |
|---|---|---|---|
| product_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique product ID |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL | Owning shop |
| category_id | INT | FK → CATEGORIES.category_id, NOT NULL | Shop-level category |
| platform_category_id | INT | FK → Platform_categories.category_id, NULLABLE | Platform-level category |
| name | VARCHAR(200) | NOT NULL | Product display name |
| slug | VARCHAR(200) | NOT NULL, UNIQUE | URL-friendly identifier |
| base_price | DECIMAL(15,2) | NOT NULL, CHECK >= 0 | Listed price before discounts |
| quantity | INT | NOT NULL, DEFAULT 0, CHECK >= 0 | Current stock level |

---

### 2.12 ProductImage

**Purpose:** Stores multiple images per product. Separated from PRODUCTS to support a clean 1:N image gallery without bloating the product record.

| Column | Type | Constraints | Description |
|---|---|---|---|
| image_id | INT | PK, NOT NULL, AUTO_INCREMENT, UNIQUE | Unique image ID |
| product_id | INT | FK → PRODUCTS.product_id, NOT NULL | Linked product |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL | Owning shop (denormalized for query efficiency) |
| image_url | VARCHAR(500) | NOT NULL | Image storage URL |

---

### 2.13 EVENTTYPE

**Purpose:** Defines a promotion or discount event created by a shop owner. Specifies the discount rule (percentage or fixed) that applies to products assigned to this event.

| Column | Type | Constraints | Description |
|---|---|---|---|
| event_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique event ID |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL | Owning shop |
| name | VARCHAR(150) | NOT NULL | Event/promotion name |
| discount | DECIMAL(10,2) | NOT NULL, CHECK >= 0 | Discount value |
| discount_type | ENUM('percentage','fixed') | NOT NULL | How discount is applied |
| is_available | BOOLEAN | NOT NULL, DEFAULT TRUE | Active/inactive toggle |

---

### 2.14 EVENTPRODUCT

**Purpose:** Junction table linking products to events. Allows many products to participate in one event and tracks per-product event status with soft-delete support.

| Column | Type | Constraints | Description |
|---|---|---|---|
| event_product_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique record ID |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL | Owning shop |
| product_id | INT | FK → PRODUCTS.product_id, NOT NULL | Participating product |
| category_id | INT | FK → CATEGORIES.category_id, NOT NULL | Product's category context |
| event_id | INT | FK → EVENTTYPE.event_id, NOT NULL | The event |
| sort_order | INT | DEFAULT 0 | Display ordering within event |
| status | ENUM('active','inactive') | NOT NULL | Participation status |
| created_at | TIMESTAMP | NOT NULL | Record creation time |
| updated_at | TIMESTAMP | NULLABLE | Last update time |
| deleted_at | TIMESTAMP | NULLABLE | Soft delete timestamp |

---

### 2.15 ORDERS

**Purpose:** Represents a customer's purchase from a single shop. Stores price totals as immutable snapshots at time of purchase. Status tracks the full lifecycle from placement to delivery.

| Column | Type | Constraints | Description |
|---|---|---|---|
| order_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique order ID |
| customer_id | INT | FK → CUSTOMERS.customer_id, NOT NULL | Purchasing customer |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL | Selling shop |
| seller_id | INT | FK → USERS.user_id, NOT NULL | Shop owner fulfilling the order |
| status | ENUM('pending','paid','processing','shipped','delivered','cancelled') | NOT NULL, DEFAULT 'pending' | Order lifecycle status |
| total_price | DECIMAL(15,2) | NOT NULL, CHECK >= 0 | Full price before discount |
| discount_price | DECIMAL(15,2) | NOT NULL, DEFAULT 0 | Total discount applied |
| subtotal_price | DECIMAL(15,2) | NOT NULL, CHECK >= 0 | Final amount after discount |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | Order placement time |

---

### 2.16 ORDERITEM

**Purpose:** Line items within an order. sold_price is a snapshot of the price at purchase time — never recalculated from live product data.

| Column | Type | Constraints | Description |
|---|---|---|---|
| order_item_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique line item ID |
| order_id | INT | FK → ORDERS.order_id, NOT NULL | Parent order |
| product_id | INT | FK → PRODUCTS.product_id, NOT NULL | Purchased product |
| quantities | INT | NOT NULL, CHECK > 0 | Number of units purchased |
| sold_price | DECIMAL(15,2) | NOT NULL, CHECK >= 0 | Price per unit at time of purchase (immutable) |

---

### 2.17 TRANSACTION

**Purpose:** Financial record per order. Links order to payment method, platform fee rule, and bank reference. Central table for all payment and revenue reporting.

| Column | Type | Constraints | Description |
|---|---|---|---|
| transaction_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique transaction ID |
| order_id | INT | FK → ORDERS.order_id, NOT NULL | Associated order |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL | Shop receiving payment |
| customer_id | INT | FK → CUSTOMERS.customer_id, NOT NULL | Paying customer |
| platform_fee_id | INT | FK → PlatformFee.id, NULLABLE | Fee rule applied at payment time (immutable after set) |
| intent_id | INT | NULLABLE | Reference to payment intent |
| payer_id | INT | NULLABLE | External payer ID from gateway |
| method_id | INT | FK → SHOP_PAYMENT_METHODS.method_id, NULLABLE | Payment method used |
| bank_ref_id | VARCHAR(100) | NULLABLE | Bank/gateway reference number |
| currency | VARCHAR(10) | NOT NULL, DEFAULT 'USD' | Transaction currency |
| amount | DECIMAL(15,2) | NOT NULL, CHECK >= 0 | Base transaction amount |
| total_amount | DECIMAL(15,2) | NOT NULL, CHECK >= 0 | Total including platform fee |

---

### 2.18 SHOP_PAYMENT_METHODS

**Purpose:** Payment method credentials registered by a shop. Supports Visa, Mastercard, Bakong KHQR. Gateway tokens stored encrypted.

| Column | Type | Constraints | Description |
|---|---|---|---|
| method_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique method ID |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL | Owning shop |
| card_type | ENUM('visa','mastercard','bakong_khqr') | NOT NULL | Payment method type |
| gateway_token | VARCHAR(500) | NULLABLE | Encrypted gateway credential |
| last_four | CHAR(4) | NULLABLE | Last 4 digits of card (display only) |
| expiry_date | DATE | NULLABLE | Card expiry date |

---

### 2.19 PAYMENT_INTENTS

**Purpose:** Tracks individual payment attempts per transaction. A transaction may have multiple intents (retry/expiry). Stores QR code data for Bakong KHQR.

| Column | Type | Constraints | Description |
|---|---|---|---|
| intent_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique intent ID |
| transaction_id | INT | FK → TRANSACTION.transaction_id, NOT NULL | Parent transaction |
| method_id | INT | FK → SHOP_PAYMENT_METHODS.method_id, NOT NULL | Payment method used |
| qr_code_data | TEXT | NULLABLE | KHQR QR payload string |
| status | ENUM('pending','completed','expired','failed') | NOT NULL, DEFAULT 'pending' | Attempt status |
| expires_at | TIMESTAMP | NOT NULL | Intent expiry time |

---

### 2.20 INVOICES

**Purpose:** Auto-generated financial document linked 1:1 to a completed transaction. Immutable after creation. invoice_no globally unique for accounting.

| Column | Type | Constraints | Description |
|---|---|---|---|
| invoice_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique invoice ID |
| transaction_id | INT | FK → TRANSACTION.transaction_id, NOT NULL, UNIQUE | Source transaction (1:1) |
| invoice_no | VARCHAR(50) | NOT NULL, UNIQUE | Human-readable invoice number |
| status | ENUM('draft','issued','paid','cancelled') | NOT NULL | Invoice lifecycle status |
| sub_total | DECIMAL(15,2) | NOT NULL | Pre-tax, pre-discount total |
| tax_amount | DECIMAL(15,2) | NOT NULL, DEFAULT 0 | Tax applied |
| discount_price | DECIMAL(15,2) | NOT NULL, DEFAULT 0 | Discount applied |
| total_amount | DECIMAL(15,2) | NOT NULL | Final payable amount |

---

### 2.21 PlatformFee

**Purpose:** Platform fee rules configured by admin. Correct rule selected at transaction time by effective_from date. Immutable once applied to a transaction.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique fee rule ID |
| fee_name | VARCHAR(100) | NOT NULL | Descriptive rule name |
| fee_type | ENUM('percentage','fixed') | NOT NULL | How fee is calculated |
| percentage | DECIMAL(5,2) | NULLABLE, CHECK 0–100 | Percentage value (if fee_type = percentage) |
| effective_from | DATE | NOT NULL | Date from which this rule applies |
| status | ENUM('active','inactive') | NOT NULL, DEFAULT 'active' | Rule activation status |
| created_at | TIMESTAMP | NOT NULL | Rule creation time |
| updated_at | TIMESTAMP | NULLABLE | Last modification time |

---

### 2.22 DELIVERY

**Purpose:** Physical delivery record per order (1:1). Links to the delivery address snapshot. Parent record for all delivery_logs entries.

| Column | Type | Constraints | Description |
|---|---|---|---|
| delivery_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique delivery ID |
| order_id | INT | FK → ORDERS.order_id, NOT NULL, UNIQUE | Associated order (1:1 enforced) |
| delivery_date | DATE | NULLABLE | Expected or actual delivery date |
| order_delivery_snapshot_id | INT | FK → order_delivery_snapshot.id, NULLABLE | Delivery address snapshot |

---

### 2.23 order_delivery_snapshot

**Purpose:** Immutable copy of delivery address captured at order placement. Preserves recipient details even if customer later updates their profile address.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique snapshot ID |
| order_id | INT | FK → ORDERS.order_id, NOT NULL, UNIQUE | Associated order (1:1 enforced) |
| address_id | INT | FK → address_user.address_id, NULLABLE | Source address reference only |
| recipient_name | VARCHAR(150) | NOT NULL | Name of delivery recipient |
| phone | VARCHAR(20) | NOT NULL | Recipient contact number |
| house_number | VARCHAR(50) | NULLABLE | House/building number |
| province | VARCHAR(100) | NULLABLE | Province or city |
| lat | DECIMAL(10,7) | NULLABLE | GPS latitude |
| lng | DECIMAL(10,7) | NULLABLE | GPS longitude |
| note_delivery | TEXT | NULLABLE | Special delivery instructions |
| status | ENUM('pending','in_transit','delivered','failed') | NOT NULL | Delivery status |

---

### 2.24 delivery_logs

**Purpose:** Append-only audit trail of every delivery status change. Each row is a timestamped event. Enables real-time shipment tracking history.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique log entry ID |
| delivery_id | INT | FK → DELIVERY.delivery_id, NOT NULL | Parent delivery |
| status | VARCHAR(50) | NOT NULL | Status at this point (e.g. 'picked_up') |
| location_description | TEXT | NULLABLE | Human-readable location note |
| timestamp | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | When this status occurred |

---

### 2.25 hubs

**Purpose:** Physical distribution hub locations in the delivery network. Stores province, address, and contact info for logistics routing.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique hub ID |
| hub_name | VARCHAR(150) | NOT NULL | Hub display name |
| province | VARCHAR(100) | NOT NULL | Province where hub is located |
| address | TEXT | NULLABLE | Full address of the hub |
| contact_number | VARCHAR(20) | NULLABLE | Hub contact phone |

---

### 2.26 NOTIFICATIONS

**Purpose:** In-app and push notification records per user. Covers order, payment, shipment, promotion, and verification alerts. Tracks read status.

| Column | Type | Constraints | Description |
|---|---|---|---|
| notification_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique notification ID |
| user_id | INT | FK → USERS.user_id, NOT NULL | Recipient user |
| type | ENUM('order','payment','shipment','promotion','verification') | NOT NULL | Notification category |
| priority | ENUM('low','medium','high') | NOT NULL, DEFAULT 'medium' | Display priority |
| title | VARCHAR(200) | NOT NULL | Short notification title |
| content | TEXT | NOT NULL | Full notification body |
| link_url | VARCHAR(500) | NULLABLE | Deep link URL for the app |
| is_read | BOOLEAN | NOT NULL, DEFAULT FALSE | Whether user has read it |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP | When notification was created |

---

### 2.27 DAILY_SNAPSHOTS

**Purpose:** Nightly aggregated shop performance summary. One record per shop per day enforced by composite UNIQUE constraint. Used for shop owner dashboard.

| Column | Type | Constraints | Description |
|---|---|---|---|
| snapshot_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique snapshot ID |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL | The shop |
| snapshot_date | DATE | NOT NULL | The date being summarized |
| total_gross | DECIMAL(15,2) | NOT NULL, DEFAULT 0 | Total revenue before deductions |
| total_profit | DECIMAL(15,2) | NOT NULL, DEFAULT 0 | Net profit after fees/costs |
| order_count | INT | NOT NULL, DEFAULT 0 | Number of orders that day |
| UNIQUE CONSTRAINT | — | (shop_id, snapshot_date) | One record per shop per day |

---

### 2.28 DAILY_C_SNAPSHOTS

**Purpose:** Breaks down each daily shop snapshot by shop-level category. Enables category-level performance analysis within a shop's daily report.

| Column | Type | Constraints | Description |
|---|---|---|---|
| cat_snap_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique category snapshot ID |
| snapshot_id | INT | FK → DAILY_SNAPSHOTS.snapshot_id, NOT NULL | Parent daily snapshot |
| category_id | INT | FK → CATEGORIES.category_id, NOT NULL | Shop category |
| cat_gross_revenue | DECIMAL(15,2) | NOT NULL, DEFAULT 0 | Gross revenue for this category |
| cat_net_profit | DECIMAL(15,2) | NOT NULL, DEFAULT 0 | Net profit for this category |
| cat_items_sold | INT | NOT NULL, DEFAULT 0 | Units sold in this category |

---

### 2.29 daily_product_snapshots

**Purpose:** Most granular analytics table. Breaks down each category snapshot by individual product. Captures stock level at midnight for inventory trend analysis.

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique product snapshot ID |
| cat_snap_id | INT | FK → DAILY_C_SNAPSHOTS.cat_snap_id, NOT NULL | Parent category snapshot |
| product_id | INT | FK → PRODUCTS.product_id, NOT NULL | The product |
| category_id | INT | FK → CATEGORIES.category_id, NOT NULL | Category context |
| qty_sold | INT | NOT NULL, DEFAULT 0 | Units sold that day |
| base_cost_price | DECIMAL(15,2) | NOT NULL | Cost price at snapshot time |
| unit_sale_price | DECIMAL(15,2) | NOT NULL | Sale price at snapshot time |
| stock_at_midnight | INT | NOT NULL, DEFAULT 0 | Stock level at end of day |

---

### 2.30 platform_revenue_snapshots

**Purpose:** Platform-level revenue tracking linked 1:1 to individual transactions. Used by Super Admin to monitor platform income and active paying shops per day.

| Column | Type | Constraints | Description |
|---|---|---|---|
| platform_snap_id | INT | PK, NOT NULL, AUTO_INCREMENT | Unique platform snapshot ID |
| transaction_id | INT | FK → TRANSACTION.transaction_id, NOT NULL, UNIQUE | Source transaction (1:1 enforced) |
| snapshot_date | DATE | NOT NULL | Date of this snapshot entry |
| active_paying_shops | INT | NOT NULL, DEFAULT 0 | Count of shops with paid transactions |

---

## 3. Relationship Cardinality Table

Fixes applied:
- Removed the backwards `address_user → USERS` entry. USERS holds `address_id` as a nullable pointer to a default address — not a true parent-child. The real direction is `USERS → address_user` (row 6).
- ORDERS → DELIVERY and ORDERS → order_delivery_snapshot corrected to **1:1 (enforced)** — requires `UNIQUE(order_id)` on both tables.
- TRANSACTION → platform_revenue_snapshots corrected to **1:1** — each transaction produces exactly one snapshot row.

| # | Parent Table | Cardinality | Child Table | FK in Child | Enforcement | Description |
|---|---|---|---|---|---|---|
| 1 | USERS | 1 : N | USER_AUTH | user_id | FK NOT NULL | One user can have multiple auth providers |
| 2 | USERS | 1 : N | USER_SESSIONS | user_id | FK NOT NULL | One user can have many active sessions |
| 3 | USERS | 1 : N | MEMBERSHIPS | user_id | FK NOT NULL | One user can hold multiple role memberships |
| 4 | USERS | 1 : 1 | CUSTOMERS | user_id | FK NOT NULL, UNIQUE | One user has exactly one customer profile |
| 5 | USERS | 1 : N | NOTIFICATIONS | user_id | FK NOT NULL | One user receives many notifications |
| 6 | USERS | 1 : N | address_user | user_id | FK NOT NULL | One user can save many delivery addresses |
| 7 | ROLES | 1 : N | MEMBERSHIPS | role_id | FK NOT NULL | One role assigned to many memberships |
| 8 | SHOPS | 1 : N | MEMBERSHIPS | shop_id | FK NULLABLE | One shop can have many member users |
| 9 | SHOPS | 1 : N | CATEGORIES | shop_id | FK NOT NULL | One shop owns many shop-level categories |
| 10 | SHOPS | 1 : N | PRODUCTS | shop_id | FK NOT NULL | One shop lists many products |
| 11 | SHOPS | 1 : N | ProductImage | shop_id | FK NOT NULL | One shop has many product images |
| 12 | SHOPS | 1 : N | EVENTTYPE | shop_id | FK NOT NULL | One shop creates many event types |
| 13 | SHOPS | 1 : N | EVENTPRODUCT | shop_id | FK NOT NULL | One shop has many event-product entries |
| 14 | SHOPS | 1 : N | SHOP_PAYMENT_METHODS | shop_id | FK NOT NULL | One shop registers many payment methods |
| 15 | SHOPS | 1 : N | TRANSACTION | shop_id | FK NOT NULL | One shop has many transactions |
| 16 | SHOPS | 1 : N | DAILY_SNAPSHOTS | shop_id | FK NOT NULL | One shop has one snapshot per day |
| 17 | Platform_categories | 1 : N | PRODUCTS | platform_category_id | FK NULLABLE | One platform category classifies many products |
| 18 | Platform_categories | 1 : N | Platform_categories | parent_id | FK NULLABLE, self-ref | Self-referencing hierarchy |
| 19 | CATEGORIES | 1 : N | PRODUCTS | category_id | FK NOT NULL | One shop category groups many products |
| 20 | CATEGORIES | 1 : N | EVENTPRODUCT | category_id | FK NOT NULL | One category used in many event-product entries |
| 21 | CATEGORIES | 1 : N | DAILY_C_SNAPSHOTS | category_id | FK NOT NULL | One category has many daily category snapshots |
| 22 | CATEGORIES | 1 : N | daily_product_snapshots | category_id | FK NOT NULL | One category has many product snapshot entries |
| 23 | PRODUCTS | 1 : N | ORDERITEM | product_id | FK NOT NULL | One product appears in many order items |
| 24 | PRODUCTS | 1 : N | EVENTPRODUCT | product_id | FK NOT NULL | One product participates in many events |
| 25 | PRODUCTS | 1 : N | ProductImage | product_id | FK NOT NULL | One product has many images |
| 26 | PRODUCTS | 1 : N | daily_product_snapshots | product_id | FK NOT NULL | One product has many daily product snapshots |
| 27 | EVENTTYPE | 1 : N | EVENTPRODUCT | event_id | FK NOT NULL | One event type covers many event-product entries |
| 28 | CUSTOMERS | 1 : N | ORDERS | customer_id | FK NOT NULL | One customer places many orders |
| 29 | ORDERS | 1 : N | ORDERITEM | order_id | FK NOT NULL | One order contains many line items |
| 30 | ORDERS | 1 : N | TRANSACTION | order_id | FK NOT NULL | One order can have one or more transactions |
| 31 | ORDERS | 1 : 1 | DELIVERY | order_id | FK NOT NULL, UNIQUE(order_id) | One order has exactly one delivery record |
| 32 | ORDERS | 1 : 1 | order_delivery_snapshot | order_id | FK NOT NULL, UNIQUE(order_id) | One order has exactly one delivery address snapshot |
| 33 | TRANSACTION | 1 : N | PAYMENT_INTENTS | transaction_id | FK NOT NULL | One transaction can have many payment attempts |
| 34 | TRANSACTION | 1 : 1 | INVOICES | transaction_id | FK NOT NULL, UNIQUE(transaction_id) | One transaction generates exactly one invoice |
| 35 | TRANSACTION | 1 : 1 | platform_revenue_snapshots | transaction_id | FK NOT NULL, UNIQUE(transaction_id) | Each transaction produces one platform revenue row |
| 36 | SHOP_PAYMENT_METHODS | 1 : N | PAYMENT_INTENTS | method_id | FK NOT NULL | One payment method used in many intents |
| 37 | PlatformFee | 1 : N | TRANSACTION | platform_fee_id | FK NULLABLE | One fee rule applied to many transactions |
| 38 | DELIVERY | 1 : N | delivery_logs | delivery_id | FK NOT NULL | One delivery has many status log entries |
| 39 | DAILY_SNAPSHOTS | 1 : N | DAILY_C_SNAPSHOTS | snapshot_id | FK NOT NULL | One daily snapshot broken down by category |
| 40 | DAILY_C_SNAPSHOTS | 1 : N | daily_product_snapshots | cat_snap_id | FK NOT NULL | One category snapshot broken down by product |
| 41 | address_user | 1 : N | order_delivery_snapshot | address_id | FK NULLABLE | One address referenced by many delivery snapshots |

---

## 4. UNIQUE Constraints Required for 1:1 Enforcement

| Table | Column | Constraint | Enforces |
|---|---|---|---|
| CUSTOMERS | user_id | UNIQUE(user_id) | One customer profile per user |
| DELIVERY | order_id | UNIQUE(order_id) | One delivery per order |
| order_delivery_snapshot | order_id | UNIQUE(order_id) | One address snapshot per order |
| INVOICES | transaction_id | UNIQUE(transaction_id) | One invoice per transaction |
| platform_revenue_snapshots | transaction_id | UNIQUE(transaction_id) | One revenue snapshot per transaction |

---

## 5. Requirement Coverage Checklist

| Requirement | Covered By | Status |
|---|---|---|
| Email unique, soft-delete on users | USERS.email UNIQUE, deleted_at | ✅ |
| Multiple auth providers per user | USER_AUTH (provider + provider_uid UNIQUE) | ✅ |
| Password null for social logins | USER_AUTH.password_hash NULLABLE | ✅ |
| Session tracking with revocation | USER_SESSIONS.revoked_at, expires_at | ✅ |
| Fixed roles: customer, shop_owner, super_admin | ROLES.role_name ENUM | ✅ |
| Memberships soft-delete | MEMBERSHIPS.deleted_at | ✅ |
| Customer 1:1 with user | CUSTOMERS.user_id UNIQUE | ✅ |
| Address table with lat/lng | address_user | ✅ |
| Default address pointer on user | USERS.address_id FK NULLABLE | ✅ |
| Address snapshotted at order time | order_delivery_snapshot | ✅ |
| Shop unique slug, soft-delete, JSON metadata | SHOPS.slug UNIQUE, is_deleted, metadata JSON | ✅ |
| Two-tier categories (platform + shop) | Platform_categories + CATEGORIES | ✅ |
| Platform categories hierarchical + Khmer name | Platform_categories.parent_id, khmer_name | ✅ |
| Product slug globally unique, stock >= 0 | PRODUCTS.slug UNIQUE, quantity CHECK >= 0 | ✅ |
| Multiple product images | ProductImage | ✅ |
| Events with percentage/fixed discount | EVENTTYPE.discount_type ENUM | ✅ |
| Event-product junction with soft-delete | EVENTPRODUCT.deleted_at | ✅ |
| Order price snapshot (total, discount, subtotal) | ORDERS columns | ✅ |
| Order status lifecycle | ORDERS.status ENUM | ✅ |
| Order item sold_price snapshot | ORDERITEM.sold_price | ✅ |
| Payment methods: Visa, Mastercard, KHQR | SHOP_PAYMENT_METHODS.card_type ENUM | ✅ |
| Transaction links fee rule (immutable) | TRANSACTION.platform_fee_id | ✅ |
| Multiple payment attempts per transaction | PAYMENT_INTENTS (1:N to TRANSACTION) | ✅ |
| KHQR QR code storage | PAYMENT_INTENTS.qr_code_data TEXT | ✅ |
| Invoice 1:1 with transaction, unique invoice_no | INVOICES.transaction_id UNIQUE, invoice_no UNIQUE | ✅ |
| Delivery 1:1 per order | DELIVERY.order_id UNIQUE | ✅ |
| Delivery address snapshot immutable | order_delivery_snapshot.order_id UNIQUE | ✅ |
| Append-only delivery status logs | delivery_logs (no update, only insert) | ✅ |
| Hub locations | hubs table | ✅ |
| Notifications with type/priority/is_read | NOTIFICATIONS | ✅ |
| Nightly shop snapshots unique per day | DAILY_SNAPSHOTS UNIQUE(shop_id, snapshot_date) | ✅ |
| Category-level daily breakdown | DAILY_C_SNAPSHOTS | ✅ |
| Product-level daily breakdown with stock | daily_product_snapshots.stock_at_midnight | ✅ |
| Platform revenue snapshot per transaction | platform_revenue_snapshots | ✅ |
| Platform fee with effective_from date | PlatformFee.effective_from | ✅ |
| Fee type: percentage or fixed | PlatformFee.fee_type ENUM | ✅ |

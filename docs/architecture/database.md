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
| address_id | INT | FK → address_user.address_id, NULLABLE | Default delivery address |

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

**Purpose:** Stores saved delivery addresses for users. Supports multiple addresses per user. The default address is referenced from USERS.address_id. Addresses are copied (snapshotted) to order_delivery_snapshot at order time.

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

**Purpose:** Admin-managed global category taxonomy used for platform-wide product discovery. Supports hierarchical structure (parent_id self-reference) and bilingual names (English + Khmer).

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

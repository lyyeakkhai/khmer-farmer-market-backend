# Khmer Farmer Market — Project Requirement & Database Design

---

## 1. Project Requirement Detail (What Each User Can Do)

### 1.1 Guest (Unauthenticated)
- Browse platform categories and products
- View shop profiles and product listings
- Register a new account (email or social login)

### 1.2 Customer
- Register / login (email, Google, Facebook)
- Manage profile: name, phone, avatar, address
- Browse and search products by category
- Add products to cart and place orders
- Choose delivery method and provide delivery address
- Pay via Visa, Mastercard, or Bakong KHQR
- Track order status and shipment in real time
- View order history and download invoices
- Receive push notifications (order updates, payment status, promotions)
- Mark notifications as read

### 1.3 Shop Owner (Farmer)
- Register / login and create a shop
- Manage shop profile (name, slug, metadata, active status)
- Create, update, delete product listings (name, price, stock, images, category)
- Manage shop-level categories
- Create promotions / events with discount rules
- View sales reports: revenue, order count, top products
- Manage payment methods (Visa, Mastercard, Bakong KHQR gateway tokens)
- Receive notifications for new orders and payment confirmations
- View daily snapshots of gross revenue, profit, and order count

### 1.4 Super Admin
- Manage all users, shops, roles, and memberships
- Manage platform-level categories (with Khmer names, hierarchy)
- Configure platform fee rules (percentage or fixed)
- View platform revenue snapshots and analytics
- Activate / deactivate shops or users
- Monitor all transactions, invoices, and delivery logs

---

## 2. Entity Attribute Detail (Table Format)

### USERS
| Attribute | Type | Constraints |
|---|---|---|
| user_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| email | VARCHAR(255) | NOT NULL, UNIQUE |
| avatar_url | VARCHAR(500) | NULLABLE |
| status | ENUM('active','inactive','banned') | NOT NULL, DEFAULT 'active' |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| last_login_at | TIMESTAMP | NULLABLE |
| deleted_at | TIMESTAMP | NULLABLE (soft delete) |
| address_id | INT | FK → address_user.address_id, NULLABLE |

### USER_AUTH
| Attribute | Type | Constraints |
|---|---|---|
| auth_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| user_id | INT | FK → USERS.user_id, NOT NULL |
| provider | ENUM('email','google','facebook') | NOT NULL |
| provider_uid | VARCHAR(255) | NOT NULL, UNIQUE per provider |
| password_hash | VARCHAR(255) | NULLABLE (null for social login) |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP |
| last_login_at | TIMESTAMP | NULLABLE |

### USER_SESSIONS
| Attribute | Type | Constraints |
|---|---|---|
| session_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| session_uuid | UUID | NOT NULL, UNIQUE |
| user_id | INT | FK → USERS.user_id, NOT NULL |
| device_name | VARCHAR(100) | NULLABLE |
| device_type | VARCHAR(50) | NULLABLE |
| ip_address | VARCHAR(45) | NULLABLE |
| user_agent | TEXT | NULLABLE |
| created_at | TIMESTAMP | NOT NULL |
| last_activity | TIMESTAMP | NULLABLE |
| expires_at | TIMESTAMP | NOT NULL |
| revoked_at | TIMESTAMP | NULLABLE |

### ROLES
| Attribute | Type | Constraints |
|---|---|---|
| role_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| role_name | ENUM('customer','shop_owner','super_admin') | NOT NULL, UNIQUE |

### MEMBERSHIPS
| Attribute | Type | Constraints |
|---|---|---|
| member_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| user_id | INT | FK → USERS.user_id, NOT NULL |
| role_id | INT | FK → ROLES.role_id, NOT NULL |
| shop_id | INT | FK → SHOPS.shop_id, NULLABLE (null for customer/admin) |
| created_at | TIMESTAMP | NOT NULL |
| updated_at | TIMESTAMP | NULLABLE |
| deleted_at | TIMESTAMP | NULLABLE (soft delete) |

### CUSTOMERS
| Attribute | Type | Constraints |
|---|---|---|
| customer_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| user_id | INT | FK → USERS.user_id, NOT NULL, UNIQUE |
| name | VARCHAR(150) | NOT NULL |
| phone_number | VARCHAR(20) | NULLABLE |

### address_user
| Attribute | Type | Constraints |
|---|---|---|
| address_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| user_id | INT | FK → USERS.user_id, NOT NULL |
| house_number | VARCHAR(50) | NULLABLE |
| province | VARCHAR(100) | NULLABLE |
| lat | DECIMAL(10,7) | NULLABLE |
| lng | DECIMAL(10,7) | NULLABLE |

### SHOPS
| Attribute | Type | Constraints |
|---|---|---|
| shop_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| shop_name | VARCHAR(200) | NOT NULL |
| slug | VARCHAR(200) | NOT NULL, UNIQUE |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE |
| is_deleted | BOOLEAN | NOT NULL, DEFAULT FALSE |
| created_at | TIMESTAMP | NOT NULL |
| updated_at | TIMESTAMP | NULLABLE |
| metadata | JSON | NULLABLE (extra shop info) |

### Platform_categories
| Attribute | Type | Constraints |
|---|---|---|
| category_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| name | VARCHAR(150) | NOT NULL |
| khmer_name | VARCHAR(150) | NULLABLE |
| slug | VARCHAR(150) | NOT NULL, UNIQUE |
| parent_id | INT | NULLABLE, self-ref FK for hierarchy |
| is_active | BOOLEAN | NOT NULL, DEFAULT TRUE |
| image | VARCHAR(500) | NULLABLE |

### CATEGORIES (Shop-level)
| Attribute | Type | Constraints |
|---|---|---|
| category_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL |
| name | VARCHAR(150) | NOT NULL |
| slug | VARCHAR(150) | NOT NULL |
| sort_order | INT | NOT NULL, DEFAULT 0 |

### PRODUCTS
| Attribute | Type | Constraints |
|---|---|---|
| product_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL |
| category_id | INT | FK → CATEGORIES.category_id, NOT NULL |
| platform_category_id | INT | FK → Platform_categories.category_id, NULLABLE |
| name | VARCHAR(200) | NOT NULL |
| slug | VARCHAR(200) | NOT NULL, UNIQUE |
| base_price | DECIMAL(15,2) | NOT NULL, CHECK >= 0 |
| quantity | INT | NOT NULL, DEFAULT 0, CHECK >= 0 |

### ProductImage
| Attribute | Type | Constraints |
|---|---|---|
| image_id | INT | PK, NOT NULL, AUTO_INCREMENT, UNIQUE |
| product_id | INT | FK → PRODUCTS.product_id, NOT NULL |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL |
| image_url | VARCHAR(500) | NOT NULL |

### EVENTTYPE
| Attribute | Type | Constraints |
|---|---|---|
| event_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL |
| name | VARCHAR(150) | NOT NULL |
| discount | DECIMAL(10,2) | NOT NULL, CHECK >= 0 |
| discount_type | ENUM('percentage','fixed') | NOT NULL |
| is_available | BOOLEAN | NOT NULL, DEFAULT TRUE |

### EVENTPRODUCT
| Attribute | Type | Constraints |
|---|---|---|
| event_product_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL |
| product_id | INT | FK → PRODUCTS.product_id, NOT NULL |
| category_id | INT | FK → CATEGORIES.category_id, NOT NULL |
| event_id | INT | FK → EVENTTYPE.event_id, NOT NULL |
| sort_order | INT | DEFAULT 0 |
| status | ENUM('active','inactive') | NOT NULL |
| created_at | TIMESTAMP | NOT NULL |
| updated_at | TIMESTAMP | NULLABLE |
| deleted_at | TIMESTAMP | NULLABLE |

### ORDERS
| Attribute | Type | Constraints |
|---|---|---|
| order_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| customer_id | INT | FK → CUSTOMERS.customer_id, NOT NULL |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL |
| seller_id | INT | FK → USERS.user_id, NOT NULL |
| status | ENUM('pending','paid','processing','shipped','delivered','cancelled') | NOT NULL, DEFAULT 'pending' |
| total_price | DECIMAL(15,2) | NOT NULL, CHECK >= 0 |
| discount_price | DECIMAL(15,2) | NOT NULL, DEFAULT 0 |
| subtotal_price | DECIMAL(15,2) | NOT NULL, CHECK >= 0 |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP |

### ORDERITEM
| Attribute | Type | Constraints |
|---|---|---|
| order_item_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| order_id | INT | FK → ORDERS.order_id, NOT NULL |
| product_id | INT | FK → PRODUCTS.product_id, NOT NULL |
| quantities | INT | NOT NULL, CHECK > 0 |
| sold_price | DECIMAL(15,2) | NOT NULL, CHECK >= 0 |

### TRANSACTION
| Attribute | Type | Constraints |
|---|---|---|
| transaction_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| order_id | INT | FK → ORDERS.order_id, NOT NULL |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL |
| platform_fee_id | INT | FK → PlatformFee.id, NULLABLE |
| intent_id | INT | NULLABLE (ref to payment intent) |
| customer_id | INT | FK → CUSTOMERS.customer_id, NOT NULL |
| payer_id | INT | NULLABLE (external payer reference) |
| method_id | INT | FK → SHOP_PAYMENT_METHODS.method_id, NULLABLE |
| bank_ref_id | VARCHAR(100) | NULLABLE (bank reference number) |
| currency | VARCHAR(10) | NOT NULL, DEFAULT 'USD' |
| amount | DECIMAL(15,2) | NOT NULL, CHECK >= 0 |
| total_amount | DECIMAL(15,2) | NOT NULL, CHECK >= 0 |

### SHOP_PAYMENT_METHODS
| Attribute | Type | Constraints |
|---|---|---|
| method_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL |
| card_type | ENUM('visa','mastercard','bakong_khqr') | NOT NULL |
| gateway_token | VARCHAR(500) | NULLABLE (encrypted token) |
| last_four | CHAR(4) | NULLABLE |
| expiry_date | DATE | NULLABLE |

### PAYMENT_INTENTS
| Attribute | Type | Constraints |
|---|---|---|
| intent_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| transaction_id | INT | FK → TRANSACTION.transaction_id, NOT NULL |
| method_id | INT | FK → SHOP_PAYMENT_METHODS.method_id, NOT NULL |
| qr_code_data | TEXT | NULLABLE (for Bakong KHQR) |
| status | ENUM('pending','completed','expired','failed') | NOT NULL, DEFAULT 'pending' |
| expires_at | TIMESTAMP | NOT NULL |

### INVOICES
| Attribute | Type | Constraints |
|---|---|---|
| invoice_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| transaction_id | INT | FK → TRANSACTION.transaction_id, NOT NULL |
| invoice_no | VARCHAR(50) | NOT NULL, UNIQUE |
| status | ENUM('draft','issued','paid','cancelled') | NOT NULL |
| sub_total | DECIMAL(15,2) | NOT NULL |
| tax_amount | DECIMAL(15,2) | NOT NULL, DEFAULT 0 |
| discount_price | DECIMAL(15,2) | NOT NULL, DEFAULT 0 |
| total_amount | DECIMAL(15,2) | NOT NULL |

### PlatformFee
| Attribute | Type | Constraints |
|---|---|---|
| id | INT | PK, NOT NULL, AUTO_INCREMENT, UNIQUE |
| fee_name | VARCHAR(100) | NOT NULL |
| fee_type | ENUM('percentage','fixed') | NOT NULL |
| percentage | DECIMAL(5,2) | NULLABLE, CHECK 0–100 |
| effective_from | DATE | NOT NULL |
| status | ENUM('active','inactive') | NOT NULL, DEFAULT 'active' |
| created_at | TIMESTAMP | NOT NULL |
| updated_at | TIMESTAMP | NULLABLE |

### DELIVERY
| Attribute | Type | Constraints |
|---|---|---|
| delivery_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| order_id | INT | FK → ORDERS.order_id, NOT NULL |
| delivery_date | DATE | NULLABLE |
| order_delivery_snapshot_id | INT | FK → order_delivery_snapshot.id, NULLABLE |

### order_delivery_snapshot
| Attribute | Type | Constraints |
|---|---|---|
| id | INT | PK, NOT NULL, AUTO_INCREMENT |
| order_id | INT | FK → ORDERS.order_id, NOT NULL |
| address_id | INT | FK → address_user.address_id, NULLABLE |
| recipient_name | VARCHAR(150) | NOT NULL |
| phone | VARCHAR(20) | NOT NULL |
| house_number | VARCHAR(50) | NULLABLE |
| province | VARCHAR(100) | NULLABLE |
| lat | DECIMAL(10,7) | NULLABLE |
| lng | DECIMAL(10,7) | NULLABLE |
| note_delivery | TEXT | NULLABLE |
| status | ENUM('pending','in_transit','delivered','failed') | NOT NULL |

### delivery_logs
| Attribute | Type | Constraints |
|---|---|---|
| id | INT | PK, NOT NULL, AUTO_INCREMENT |
| delivery_id | INT | FK → DELIVERY.delivery_id, NOT NULL |
| status | VARCHAR(50) | NOT NULL |
| location_description | TEXT | NULLABLE |
| timestamp | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP |

### hubs
| Attribute | Type | Constraints |
|---|---|---|
| id | INT | PK, NOT NULL, AUTO_INCREMENT |
| hub_name | VARCHAR(150) | NOT NULL |
| province | VARCHAR(100) | NOT NULL |
| address | TEXT | NULLABLE |
| contact_number | VARCHAR(20) | NULLABLE |

### NOTIFICATIONS
| Attribute | Type | Constraints |
|---|---|---|
| notification_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| user_id | INT | FK → USERS.user_id, NOT NULL |
| type | ENUM('order','payment','shipment','promotion','verification') | NOT NULL |
| priority | ENUM('low','medium','high') | NOT NULL, DEFAULT 'medium' |
| title | VARCHAR(200) | NOT NULL |
| content | TEXT | NOT NULL |
| link_url | VARCHAR(500) | NULLABLE |
| is_read | BOOLEAN | NOT NULL, DEFAULT FALSE |
| created_at | TIMESTAMP | NOT NULL, DEFAULT CURRENT_TIMESTAMP |

### DAILY_SNAPSHOTS
| Attribute | Type | Constraints |
|---|---|---|
| snapshot_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| shop_id | INT | FK → SHOPS.shop_id, NOT NULL |
| snapshot_date | DATE | NOT NULL |
| total_gross | DECIMAL(15,2) | NOT NULL, DEFAULT 0 |
| total_profit | DECIMAL(15,2) | NOT NULL, DEFAULT 0 |
| order_count | INT | NOT NULL, DEFAULT 0 |
| UNIQUE | — | (shop_id, snapshot_date) |

### DAILY_C_SNAPSHOTS
| Attribute | Type | Constraints |
|---|---|---|
| cat_snap_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| snapshot_id | INT | FK → DAILY_SNAPSHOTS.snapshot_id, NOT NULL |
| category_id | INT | FK → CATEGORIES.category_id, NOT NULL |
| cat_gross_revenue | DECIMAL(15,2) | NOT NULL, DEFAULT 0 |
| cat_net_profit | DECIMAL(15,2) | NOT NULL, DEFAULT 0 |
| cat_items_sold | INT | NOT NULL, DEFAULT 0 |

### daily_product_snapshots
| Attribute | Type | Constraints |
|---|---|---|
| id | INT | PK, NOT NULL, AUTO_INCREMENT |
| cat_snap_id | INT | FK → DAILY_C_SNAPSHOTS.cat_snap_id, NOT NULL |
| product_id | INT | FK → PRODUCTS.product_id, NOT NULL |
| category_id | INT | FK → CATEGORIES.category_id, NOT NULL |
| qty_sold | INT | NOT NULL, DEFAULT 0 |
| base_cost_price | DECIMAL(15,2) | NOT NULL |
| unit_sale_price | DECIMAL(15,2) | NOT NULL |
| stock_at_midnight | INT | NOT NULL, DEFAULT 0 |

### platform_revenue_snapshots
| Attribute | Type | Constraints |
|---|---|---|
| platform_snap_id | INT | PK, NOT NULL, AUTO_INCREMENT |
| transaction_id | INT | FK → TRANSACTION.transaction_id, NOT NULL |
| snapshot_date | DATE | NOT NULL |
| active_paying_shops | INT | NOT NULL, DEFAULT 0 |

---

## 3. All Relationship Detail

| From Table | Relationship | To Table | FK Column | Notes |
|---|---|---|---|---|
| address_user | 1 → N | USERS | address_id | One address can be default for a user |
| USERS | 1 → N | USER_AUTH | user_id | One user, many auth providers |
| USERS | 1 → N | USER_SESSIONS | user_id | One user, many sessions |
| USERS | 1 → N | MEMBERSHIPS | user_id | One user, many roles/shops |
| USERS | 1 → 1 | CUSTOMERS | user_id | One user = one customer profile |
| USERS | 1 → N | NOTIFICATIONS | user_id | One user, many notifications |
| ROLES | 1 → N | MEMBERSHIPS | role_id | One role, many memberships |
| SHOPS | 1 → N | MEMBERSHIPS | shop_id | One shop, many members |
| SHOPS | 1 → N | CATEGORIES | shop_id | One shop, many shop categories |
| SHOPS | 1 → N | PRODUCTS | shop_id | One shop, many products |
| SHOPS | 1 → N | EVENTTYPE | shop_id | One shop, many event types |
| SHOPS | 1 → N | EVENTPRODUCT | shop_id | One shop, many event products |
| SHOPS | 1 → N | SHOP_PAYMENT_METHODS | shop_id | One shop, many payment methods |
| SHOPS | 1 → N | TRANSACTION | shop_id | One shop, many transactions |
| SHOPS | 1 → N | DAILY_SNAPSHOTS | shop_id | One shop, many daily snapshots |
| SHOPS | 1 → N | ProductImage | shop_id | One shop, many product images |
| Platform_categories | 1 → N | PRODUCTS | platform_category_id | Platform category classifies products |
| Platform_categories | self-ref | Platform_categories | parent_id | Hierarchical category tree |
| CATEGORIES | 1 → N | PRODUCTS | category_id | Shop category groups products |
| CATEGORIES | 1 → N | EVENTPRODUCT | category_id | Category used in event products |
| CATEGORIES | 1 → N | DAILY_C_SNAPSHOTS | category_id | Category daily analytics |
| CATEGORIES | 1 → N | daily_product_snapshots | category_id | Product snapshot per category |
| PRODUCTS | 1 → N | ORDERITEM | product_id | One product in many order items |
| PRODUCTS | 1 → N | EVENTPRODUCT | product_id | One product in many events |
| PRODUCTS | 1 → N | ProductImage | product_id | One product, many images |
| PRODUCTS | 1 → N | daily_product_snapshots | product_id | Product daily analytics |
| EVENTTYPE | 1 → N | EVENTPRODUCT | event_id | One event type, many event products |
| CUSTOMERS | 1 → N | ORDERS | customer_id | One customer, many orders |
| ORDERS | 1 → N | ORDERITEM | order_id | One order, many items |
| ORDERS | 1 → N | TRANSACTION | order_id | One order, one or more transactions |
| ORDERS | 1 → N | DELIVERY | order_id | One order, one delivery |
| ORDERS | 1 → N | order_delivery_snapshot | order_id | Snapshot of delivery address at order time |
| TRANSACTION | 1 → N | PAYMENT_INTENTS | transaction_id | One transaction, many payment attempts |
| TRANSACTION | 1 → 1 | INVOICES | transaction_id | One transaction generates one invoice |
| TRANSACTION | 1 → N | platform_revenue_snapshots | transaction_id | Transaction feeds platform revenue |
| SHOP_PAYMENT_METHODS | 1 → N | PAYMENT_INTENTS | method_id | One method, many payment intents |
| PlatformFee | 1 → N | TRANSACTION | platform_fee_id | Fee rule applied to transaction |
| DELIVERY | 1 → N | delivery_logs | delivery_id | One delivery, many status logs |
| DAILY_SNAPSHOTS | 1 → N | DAILY_C_SNAPSHOTS | snapshot_id | Daily snapshot broken down by category |
| DAILY_C_SNAPSHOTS | 1 → N | daily_product_snapshots | cat_snap_id | Category snapshot broken down by product |
| address_user | 1 → N | order_delivery_snapshot | address_id | Saved address copied to delivery snapshot |

---

## 4. Entities Separated by Feature Section

---

### Feature 1: Identity & Access Management (IAM)

**Entities:** USERS, USER_AUTH, USER_SESSIONS, ROLES, MEMBERSHIPS, CUSTOMERS, address_user

**Flow:**
```
1. User opens app → hits Register
2. Submits email + password OR selects social provider (Google/Facebook)
3. USER_AUTH record created (provider, provider_uid, password_hash)
4. USERS record created (email, status=active, created_at)
5. CUSTOMERS record created (linked to user_id)
6. ROLES looked up → MEMBERSHIPS record created (user_id + role_id)
7. On login → USER_SESSIONS record created (session_uuid, device, ip, expires_at)
8. On logout / token revoke → revoked_at set on session
9. Shop owner gets additional MEMBERSHIPS row with shop_id
```

**Data needed per step:**
- Register: email, password or provider token, name, phone
- Login: email/provider → returns session_uuid
- Session: device_name, device_type, ip_address, user_agent, expires_at
- Role assignment: user_id, role_id, shop_id (optional)

---

### Feature 2: Shop & Inventory Management

**Entities:** SHOPS, CATEGORIES, PRODUCTS, ProductImage, Platform_categories

**Flow:**
```
1. Shop owner creates shop → SHOPS record (shop_name, slug, is_active=true)
2. MEMBERSHIPS updated with shop_id for the owner
3. Owner creates shop-level CATEGORIES (name, slug, sort_order)
4. Owner creates PRODUCTS (name, slug, base_price, quantity, category_id, platform_category_id)
5. Owner uploads product images → ProductImage records (image_url, product_id, shop_id)
6. Admin manages Platform_categories (hierarchical, with khmer_name)
7. Products linked to both shop category and platform category
8. Owner updates stock (quantity field on PRODUCTS)
```

**Data needed per step:**
- Shop creation: shop_name, slug, metadata
- Category: name, slug, sort_order, shop_id
- Product: name, slug, base_price, quantity, category_id, platform_category_id, shop_id
- Image: image_url, product_id, shop_id

---

### Feature 3: Event / Promotion Management

**Entities:** EVENTTYPE, EVENTPRODUCT

**Flow:**
```
1. Shop owner creates an event → EVENTTYPE (name, discount, discount_type, is_available, shop_id)
2. Owner assigns products to the event → EVENTPRODUCT (product_id, event_id, category_id, shop_id)
3. Event becomes active → is_available = true on EVENTTYPE
4. Customers browsing see discounted prices calculated from base_price + discount rule
5. Owner can deactivate event → is_available = false or deleted_at set on EVENTPRODUCT
```

**Data needed per step:**
- Event creation: name, discount value, discount_type (percentage/fixed), shop_id
- Product assignment: product_id, category_id, event_id, sort_order

---

### Feature 4: Order Management

**Entities:** ORDERS, ORDERITEM, CUSTOMERS

**Flow:**
```
1. Customer browses products and adds to cart (client-side)
2. Customer confirms order → ORDERS record created
   - status = 'pending', customer_id, shop_id, total_price, discount_price, subtotal_price
3. Each cart item → ORDERITEM record (order_id, product_id, quantities, sold_price)
4. PRODUCTS.quantity decremented per item sold
5. Order status updated as payment and delivery progress
```

**Data needed per step:**
- Order: customer_id, shop_id, seller_id, total_price, discount_price, subtotal_price
- Order item: order_id, product_id, quantities, sold_price (snapshot of price at time of purchase)

---

### Feature 5: Payment & Transaction Processing

**Entities:** TRANSACTION, SHOP_PAYMENT_METHODS, PAYMENT_INTENTS, INVOICES, PlatformFee

**Flow:**
```
1. Customer selects payment method (Visa / Mastercard / Bakong KHQR)
2. PAYMENT_INTENTS record created (status=pending, expires_at, method_id, transaction_id)
   - For KHQR: qr_code_data generated and stored
3. TRANSACTION record created (order_id, shop_id, customer_id, amount, currency, platform_fee_id)
4. Payment gateway confirms → PAYMENT_INTENTS.status = 'completed'
5. TRANSACTION.bank_ref_id stored from gateway response
6. PlatformFee rule applied → fee amount calculated and recorded on TRANSACTION
7. INVOICES record auto-generated (invoice_no, sub_total, tax_amount, discount_price, total_amount)
8. ORDERS.status updated to 'paid'
```

**Data needed per step:**
- Payment intent: method_id, transaction_id, qr_code_data (KHQR), expires_at
- Transaction: order_id, shop_id, customer_id, method_id, amount, currency, bank_ref_id, platform_fee_id
- Invoice: transaction_id, invoice_no, sub_total, tax_amount, discount_price, total_amount

---

### Feature 6: Delivery & Shipment Tracking

**Entities:** DELIVERY, order_delivery_snapshot, delivery_logs, hubs

**Flow:**
```
1. On order confirmation → order_delivery_snapshot created
   - Copies recipient_name, phone, address from customer's address_user at that moment
2. DELIVERY record created (order_id, delivery_date)
3. Delivery partner picks up → delivery_logs entry (status='picked_up', timestamp)
4. Package moves through hubs → delivery_logs entries per status change
5. Delivered → delivery_logs (status='delivered'), ORDERS.status = 'delivered'
6. Customer receives push notification on each status change
```

**Data needed per step:**
- Delivery snapshot: order_id, address_id, recipient_name, phone, province, lat, lng, note_delivery
- Delivery: order_id, delivery_date
- Delivery log: delivery_id, status, location_description, timestamp
- Hub: hub_name, province, address, contact_number

---

### Feature 7: Notifications

**Entities:** NOTIFICATIONS

**Flow:**
```
1. System event triggers notification creation (order placed, payment confirmed, shipment update)
2. NOTIFICATIONS record created (user_id, type, priority, title, content, link_url)
3. Push notification sent to mobile/web via notification service
4. User opens notification → is_read = true updated
5. Optional: promotional notifications created by admin or shop owner events
```

**Data needed per step:**
- Notification: user_id, type, priority, title, content, link_url, is_read

---

### Feature 8: Reports & Analytics

**Entities:** DAILY_SNAPSHOTS, DAILY_C_SNAPSHOTS, daily_product_snapshots, platform_revenue_snapshots

**Flow:**
```
1. Nightly job runs at midnight
2. For each shop → DAILY_SNAPSHOTS created (snapshot_date, total_gross, total_profit, order_count)
3. Per category within that shop → DAILY_C_SNAPSHOTS (cat_gross_revenue, cat_net_profit, cat_items_sold)
4. Per product within that category → daily_product_snapshots (qty_sold, base_cost_price, unit_sale_price, stock_at_midnight)
5. Platform-level → platform_revenue_snapshots (snapshot_date, active_paying_shops, linked to transactions)
6. Shop owner views dashboard → queries DAILY_SNAPSHOTS + DAILY_C_SNAPSHOTS
7. Admin views platform revenue → queries platform_revenue_snapshots
```

**Data needed per step:**
- Daily shop snapshot: shop_id, snapshot_date, total_gross, total_profit, order_count
- Category snapshot: snapshot_id, category_id, cat_gross_revenue, cat_net_profit, cat_items_sold
- Product snapshot: cat_snap_id, product_id, category_id, qty_sold, base_cost_price, unit_sale_price, stock_at_midnight
- Platform snapshot: transaction_id, snapshot_date, active_paying_shops

---

### Feature 9: Platform Fee Management

**Entities:** PlatformFee, TRANSACTION

**Flow:**
```
1. Admin creates fee rule → PlatformFee (fee_name, fee_type, percentage, effective_from, status=active)
2. On each transaction → active PlatformFee rule fetched by effective_from date
3. Fee amount calculated: if percentage → amount * percentage / 100; if fixed → fixed amount
4. TRANSACTION.platform_fee_id linked to the applied fee rule
5. platform_revenue_snapshots aggregates fee income per day
```

**Data needed per step:**
- Fee rule: fee_name, fee_type (percentage/fixed), percentage value, effective_from date
- Applied on: TRANSACTION.platform_fee_id, TRANSACTION.amount

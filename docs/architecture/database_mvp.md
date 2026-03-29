# Khmer Farmer Market — Database SQL (PostgreSQL)

## Version: v1.0.0 | Aligned with database.md design

---

```sql
-- ============================================================
-- EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. address_user
-- Purpose: Stores saved delivery addresses per user.
-- ============================================================
CREATE TABLE address_user (
  address_id    SERIAL        PRIMARY KEY,
  user_id       INT           NOT NULL,  -- FK → users.user_id (added after users table)
  house_number  VARCHAR(50),
  province      VARCHAR(100),
  lat           DECIMAL(10,7),
  lng           DECIMAL(10,7)
);

-- ============================================================
-- 2. USERS
-- Purpose: Central identity record for every person.
-- ============================================================
CREATE TABLE users (
  user_id        SERIAL        PRIMARY KEY,
  email          VARCHAR(255)  NOT NULL UNIQUE,
  avatar_url     VARCHAR(500),
  status         VARCHAR(20)   NOT NULL DEFAULT 'active'
                               CHECK (status IN ('active','inactive','banned')),
  created_at     TIMESTAMP     NOT NULL DEFAULT NOW(),
  last_login_at  TIMESTAMP,
  deleted_at     TIMESTAMP,
  address_id     INT           REFERENCES address_user(address_id) ON DELETE SET NULL
);

-- Add FK from address_user back to users
ALTER TABLE address_user
  ADD CONSTRAINT fk_address_user_user
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;

CREATE INDEX idx_users_email ON users(email);

-- ============================================================
-- 3. USER_AUTH
-- Purpose: Auth credentials per provider per user.
-- ============================================================
CREATE TABLE user_auth (
  auth_id        SERIAL        PRIMARY KEY,
  user_id        INT           NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  provider       VARCHAR(20)   NOT NULL CHECK (provider IN ('email','google','facebook')),
  provider_uid   VARCHAR(255)  NOT NULL,
  password_hash  VARCHAR(255),
  created_at     TIMESTAMP     NOT NULL DEFAULT NOW(),
  last_login_at  TIMESTAMP,
  UNIQUE (provider, provider_uid)
);

CREATE INDEX idx_user_auth_user_id ON user_auth(user_id);

-- ============================================================
-- 4. USER_SESSIONS
-- Purpose: Active login sessions per user per device.
-- ============================================================
CREATE TABLE user_sessions (
  session_id    SERIAL        PRIMARY KEY,
  session_uuid  UUID          NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
  user_id       INT           NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  device_name   VARCHAR(100),
  device_type   VARCHAR(50),
  ip_address    VARCHAR(45),
  user_agent    TEXT,
  created_at    TIMESTAMP     NOT NULL DEFAULT NOW(),
  last_activity TIMESTAMP,
  expires_at    TIMESTAMP     NOT NULL,
  revoked_at    TIMESTAMP
);

CREATE INDEX idx_user_sessions_user_id     ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_session_uuid ON user_sessions(session_uuid);

-- ============================================================
-- 5. ROLES
-- Purpose: Fixed role definitions for the platform.
-- ============================================================
CREATE TABLE roles (
  role_id    SERIAL      PRIMARY KEY,
  role_name  VARCHAR(20) NOT NULL UNIQUE
             CHECK (role_name IN ('customer','shop_owner','super_admin'))
);

INSERT INTO roles (role_name) VALUES ('customer'), ('shop_owner'), ('super_admin');

-- ============================================================
-- 6. SHOPS
-- Purpose: Farmer storefronts on the platform.
-- ============================================================
CREATE TABLE shops (
  shop_id     SERIAL        PRIMARY KEY,
  shop_name   VARCHAR(200)  NOT NULL,
  slug        VARCHAR(200)  NOT NULL UNIQUE,
  is_active   BOOLEAN       NOT NULL DEFAULT TRUE,
  is_deleted  BOOLEAN       NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMP     NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMP,
  metadata    JSONB
);

CREATE INDEX idx_shops_slug ON shops(slug);

-- ============================================================
-- 7. MEMBERSHIPS
-- Purpose: Links users to roles and optionally to shops.
-- ============================================================
CREATE TABLE memberships (
  member_id   SERIAL      PRIMARY KEY,
  user_id     INT         NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  role_id     INT         NOT NULL REFERENCES roles(role_id),
  shop_id     INT         REFERENCES shops(shop_id) ON DELETE CASCADE,
  created_at  TIMESTAMP   NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMP,
  deleted_at  TIMESTAMP
);

CREATE INDEX idx_memberships_user_id ON memberships(user_id);
CREATE INDEX idx_memberships_shop_id ON memberships(shop_id);

-- ============================================================
-- 8. CUSTOMERS
-- Purpose: Extended profile for users with customer role.
-- ============================================================
CREATE TABLE customers (
  customer_id   SERIAL        PRIMARY KEY,
  user_id       INT           NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
  name          VARCHAR(150)  NOT NULL,
  phone_number  VARCHAR(20)
);

-- ============================================================
-- 9. Platform_categories
-- Purpose: Admin-managed global hierarchical category taxonomy.
-- ============================================================
CREATE TABLE platform_categories (
  category_id  SERIAL        PRIMARY KEY,
  name         VARCHAR(150)  NOT NULL,
  khmer_name   VARCHAR(150),
  slug         VARCHAR(150)  NOT NULL UNIQUE,
  parent_id    INT           REFERENCES platform_categories(category_id) ON DELETE SET NULL,
  is_active    BOOLEAN       NOT NULL DEFAULT TRUE,
  image        VARCHAR(500)
);

CREATE INDEX idx_platform_categories_slug      ON platform_categories(slug);
CREATE INDEX idx_platform_categories_parent_id ON platform_categories(parent_id);

-- ============================================================
-- 10. CATEGORIES (shop-level)
-- Purpose: Shop-owned product categories.
-- ============================================================
CREATE TABLE categories (
  category_id  SERIAL        PRIMARY KEY,
  shop_id      INT           NOT NULL REFERENCES shops(shop_id) ON DELETE CASCADE,
  name         VARCHAR(150)  NOT NULL,
  slug         VARCHAR(150)  NOT NULL,
  sort_order   INT           NOT NULL DEFAULT 0,
  UNIQUE (shop_id, slug)
);

CREATE INDEX idx_categories_shop_id ON categories(shop_id);

-- ============================================================
-- 11. PRODUCTS
-- Purpose: Core product listings per shop.
-- ============================================================
CREATE TABLE products (
  product_id           SERIAL        PRIMARY KEY,
  shop_id              INT           NOT NULL REFERENCES shops(shop_id) ON DELETE CASCADE,
  category_id          INT           NOT NULL REFERENCES categories(category_id),
  platform_category_id INT           REFERENCES platform_categories(category_id) ON DELETE SET NULL,
  name                 VARCHAR(200)  NOT NULL,
  slug                 VARCHAR(200)  NOT NULL UNIQUE,
  base_price           DECIMAL(15,2) NOT NULL CHECK (base_price >= 0),
  quantity             INT           NOT NULL DEFAULT 0 CHECK (quantity >= 0)
);

CREATE INDEX idx_products_shop_id     ON products(shop_id);
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_slug        ON products(slug);

-- ============================================================
-- 12. ProductImage
-- Purpose: Multiple images per product.
-- ============================================================
CREATE TABLE product_images (
  image_id   SERIAL        PRIMARY KEY,
  product_id INT           NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
  shop_id    INT           NOT NULL REFERENCES shops(shop_id) ON DELETE CASCADE,
  image_url  VARCHAR(500)  NOT NULL
);

CREATE INDEX idx_product_images_product_id ON product_images(product_id);

-- ============================================================
-- 13. EVENTTYPE
-- Purpose: Promotion/discount event definitions per shop.
-- ============================================================
CREATE TABLE event_types (
  event_id       SERIAL        PRIMARY KEY,
  shop_id        INT           NOT NULL REFERENCES shops(shop_id) ON DELETE CASCADE,
  name           VARCHAR(150)  NOT NULL,
  discount       DECIMAL(10,2) NOT NULL CHECK (discount >= 0),
  discount_type  VARCHAR(20)   NOT NULL CHECK (discount_type IN ('percentage','fixed')),
  is_available   BOOLEAN       NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_event_types_shop_id ON event_types(shop_id);

-- ============================================================
-- 14. EVENTPRODUCT
-- Purpose: Junction table linking products to events.
-- ============================================================
CREATE TABLE event_products (
  event_product_id  SERIAL      PRIMARY KEY,
  shop_id           INT         NOT NULL REFERENCES shops(shop_id) ON DELETE CASCADE,
  product_id        INT         NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
  category_id       INT         NOT NULL REFERENCES categories(category_id),
  event_id          INT         NOT NULL REFERENCES event_types(event_id) ON DELETE CASCADE,
  sort_order        INT         NOT NULL DEFAULT 0,
  status            VARCHAR(20) NOT NULL CHECK (status IN ('active','inactive')),
  created_at        TIMESTAMP   NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMP,
  deleted_at        TIMESTAMP
);

CREATE INDEX idx_event_products_event_id   ON event_products(event_id);
CREATE INDEX idx_event_products_product_id ON event_products(product_id);

-- ============================================================
-- 15. ORDERS
-- Purpose: Customer purchase records scoped per shop.
-- ============================================================
CREATE TABLE orders (
  order_id        SERIAL        PRIMARY KEY,
  customer_id     INT           NOT NULL REFERENCES customers(customer_id),
  shop_id         INT           NOT NULL REFERENCES shops(shop_id),
  seller_id       INT           NOT NULL REFERENCES users(user_id),
  status          VARCHAR(20)   NOT NULL DEFAULT 'pending'
                                CHECK (status IN ('pending','paid','processing','shipped','delivered','cancelled')),
  total_price     DECIMAL(15,2) NOT NULL CHECK (total_price >= 0),
  discount_price  DECIMAL(15,2) NOT NULL DEFAULT 0,
  subtotal_price  DECIMAL(15,2) NOT NULL CHECK (subtotal_price >= 0),
  created_at      TIMESTAMP     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_customer_id        ON orders(customer_id);
CREATE INDEX idx_orders_shop_id            ON orders(shop_id);
CREATE INDEX idx_orders_customer_status    ON orders(customer_id, status);
CREATE INDEX idx_orders_shop_status        ON orders(shop_id, status);

-- ============================================================
-- 16. ORDERITEM
-- Purpose: Line items within an order (price snapshot).
-- ============================================================
CREATE TABLE order_items (
  order_item_id  SERIAL        PRIMARY KEY,
  order_id       INT           NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
  product_id     INT           NOT NULL REFERENCES products(product_id),
  quantities     INT           NOT NULL CHECK (quantities > 0),
  sold_price     DECIMAL(15,2) NOT NULL CHECK (sold_price >= 0)
);

CREATE INDEX idx_order_items_order_id ON order_items(order_id);

-- ============================================================
-- 17. PlatformFee
-- Purpose: Platform fee rules applied to transactions.
-- ============================================================
CREATE TABLE platform_fees (
  id              SERIAL        PRIMARY KEY,
  fee_name        VARCHAR(100)  NOT NULL,
  fee_type        VARCHAR(20)   NOT NULL CHECK (fee_type IN ('percentage','fixed')),
  percentage      DECIMAL(5,2)  CHECK (percentage >= 0 AND percentage <= 100),
  effective_from  DATE          NOT NULL,
  status          VARCHAR(20)   NOT NULL DEFAULT 'active'
                                CHECK (status IN ('active','inactive')),
  created_at      TIMESTAMP     NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMP
);

-- ============================================================
-- 18. SHOP_PAYMENT_METHODS
-- Purpose: Payment method credentials registered by shops.
-- ============================================================
CREATE TABLE shop_payment_methods (
  method_id      SERIAL       PRIMARY KEY,
  shop_id        INT          NOT NULL REFERENCES shops(shop_id) ON DELETE CASCADE,
  card_type      VARCHAR(20)  NOT NULL CHECK (card_type IN ('visa','mastercard','bakong_khqr')),
  gateway_token  VARCHAR(500),
  last_four      CHAR(4),
  expiry_date    DATE
);

CREATE INDEX idx_shop_payment_methods_shop_id ON shop_payment_methods(shop_id);

-- ============================================================
-- 19. TRANSACTION
-- Purpose: Financial record per order linking payment, fee, shop.
-- ============================================================
CREATE TABLE transactions (
  transaction_id   SERIAL        PRIMARY KEY,
  order_id         INT           NOT NULL REFERENCES orders(order_id),
  shop_id          INT           NOT NULL REFERENCES shops(shop_id),
  customer_id      INT           NOT NULL REFERENCES customers(customer_id),
  platform_fee_id  INT           REFERENCES platform_fees(id) ON DELETE SET NULL,
  intent_id        INT,
  payer_id         INT,
  method_id        INT           REFERENCES shop_payment_methods(method_id) ON DELETE SET NULL,
  bank_ref_id      VARCHAR(100),
  currency         VARCHAR(10)   NOT NULL DEFAULT 'USD',
  amount           DECIMAL(15,2) NOT NULL CHECK (amount >= 0),
  total_amount     DECIMAL(15,2) NOT NULL CHECK (total_amount >= 0)
);

CREATE INDEX idx_transactions_order_id ON transactions(order_id);
CREATE INDEX idx_transactions_shop_id  ON transactions(shop_id);

-- ============================================================
-- 20. PAYMENT_INTENTS
-- Purpose: Individual payment attempts per transaction.
-- ============================================================
CREATE TABLE payment_intents (
  intent_id       SERIAL      PRIMARY KEY,
  transaction_id  INT         NOT NULL REFERENCES transactions(transaction_id) ON DELETE CASCADE,
  method_id       INT         NOT NULL REFERENCES shop_payment_methods(method_id),
  qr_code_data    TEXT,
  status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                              CHECK (status IN ('pending','completed','expired','failed')),
  expires_at      TIMESTAMP   NOT NULL
);

CREATE INDEX idx_payment_intents_transaction_id ON payment_intents(transaction_id);

-- ============================================================
-- 21. INVOICES
-- Purpose: Auto-generated financial document per transaction (1:1).
-- ============================================================
CREATE TABLE invoices (
  invoice_id      SERIAL        PRIMARY KEY,
  transaction_id  INT           NOT NULL UNIQUE REFERENCES transactions(transaction_id),
  invoice_no      VARCHAR(50)   NOT NULL UNIQUE,
  status          VARCHAR(20)   NOT NULL CHECK (status IN ('draft','issued','paid','cancelled')),
  sub_total       DECIMAL(15,2) NOT NULL,
  tax_amount      DECIMAL(15,2) NOT NULL DEFAULT 0,
  discount_price  DECIMAL(15,2) NOT NULL DEFAULT 0,
  total_amount    DECIMAL(15,2) NOT NULL
);

-- ============================================================
-- 22. order_delivery_snapshot
-- Purpose: Immutable delivery address copy at order time (1:1 with orders).
-- ============================================================
CREATE TABLE order_delivery_snapshots (
  id              SERIAL        PRIMARY KEY,
  order_id        INT           NOT NULL UNIQUE REFERENCES orders(order_id),
  address_id      INT           REFERENCES address_user(address_id) ON DELETE SET NULL,
  recipient_name  VARCHAR(150)  NOT NULL,
  phone           VARCHAR(20)   NOT NULL,
  house_number    VARCHAR(50),
  province        VARCHAR(100),
  lat             DECIMAL(10,7),
  lng             DECIMAL(10,7),
  note_delivery   TEXT,
  status          VARCHAR(20)   NOT NULL DEFAULT 'pending'
                                CHECK (status IN ('pending','in_transit','delivered','failed'))
);

-- ============================================================
-- 23. DELIVERY
-- Purpose: Physical delivery record per order (1:1 with orders).
-- ============================================================
CREATE TABLE deliveries (
  delivery_id                  SERIAL  PRIMARY KEY,
  order_id                     INT     NOT NULL UNIQUE REFERENCES orders(order_id),
  delivery_date                DATE,
  order_delivery_snapshot_id   INT     REFERENCES order_delivery_snapshots(id) ON DELETE SET NULL
);

CREATE INDEX idx_deliveries_order_id ON deliveries(order_id);

-- ============================================================
-- 24. delivery_logs
-- Purpose: Append-only status log per delivery.
-- ============================================================
CREATE TABLE delivery_logs (
  id                    SERIAL       PRIMARY KEY,
  delivery_id           INT          NOT NULL REFERENCES deliveries(delivery_id) ON DELETE CASCADE,
  status                VARCHAR(50)  NOT NULL,
  location_description  TEXT,
  timestamp             TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_delivery_logs_delivery_id ON delivery_logs(delivery_id);

-- ============================================================
-- 25. hubs
-- Purpose: Physical distribution hub locations.
-- ============================================================
CREATE TABLE hubs (
  id              SERIAL        PRIMARY KEY,
  hub_name        VARCHAR(150)  NOT NULL,
  province        VARCHAR(100)  NOT NULL,
  address         TEXT,
  contact_number  VARCHAR(20)
);

-- ============================================================
-- 26. NOTIFICATIONS
-- Purpose: In-app and push notifications per user.
-- ============================================================
CREATE TABLE notifications (
  notification_id  SERIAL        PRIMARY KEY,
  user_id          INT           NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
  type             VARCHAR(20)   NOT NULL
                                 CHECK (type IN ('order','payment','shipment','promotion','verification')),
  priority         VARCHAR(10)   NOT NULL DEFAULT 'medium'
                                 CHECK (priority IN ('low','medium','high')),
  title            VARCHAR(200)  NOT NULL,
  content          TEXT          NOT NULL,
  link_url         VARCHAR(500),
  is_read          BOOLEAN       NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMP     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id      ON notifications(user_id);
CREATE INDEX idx_notifications_user_is_read ON notifications(user_id, is_read);

-- ============================================================
-- 27. DAILY_SNAPSHOTS
-- Purpose: Nightly per-shop performance summary.
-- ============================================================
CREATE TABLE daily_snapshots (
  snapshot_id    SERIAL        PRIMARY KEY,
  shop_id        INT           NOT NULL REFERENCES shops(shop_id) ON DELETE CASCADE,
  snapshot_date  DATE          NOT NULL,
  total_gross    DECIMAL(15,2) NOT NULL DEFAULT 0,
  total_profit   DECIMAL(15,2) NOT NULL DEFAULT 0,
  order_count    INT           NOT NULL DEFAULT 0,
  UNIQUE (shop_id, snapshot_date)
);

CREATE INDEX idx_daily_snapshots_shop_date ON daily_snapshots(shop_id, snapshot_date);

-- ============================================================
-- 28. DAILY_C_SNAPSHOTS
-- Purpose: Daily snapshot broken down by shop category.
-- ============================================================
CREATE TABLE daily_category_snapshots (
  cat_snap_id        SERIAL        PRIMARY KEY,
  snapshot_id        INT           NOT NULL REFERENCES daily_snapshots(snapshot_id) ON DELETE CASCADE,
  category_id        INT           NOT NULL REFERENCES categories(category_id),
  cat_gross_revenue  DECIMAL(15,2) NOT NULL DEFAULT 0,
  cat_net_profit     DECIMAL(15,2) NOT NULL DEFAULT 0,
  cat_items_sold     INT           NOT NULL DEFAULT 0
);

CREATE INDEX idx_daily_cat_snapshots_snapshot_id ON daily_category_snapshots(snapshot_id);

-- ============================================================
-- 29. daily_product_snapshots
-- Purpose: Daily snapshot broken down by product within category.
-- ============================================================
CREATE TABLE daily_product_snapshots (
  id                SERIAL        PRIMARY KEY,
  cat_snap_id       INT           NOT NULL REFERENCES daily_category_snapshots(cat_snap_id) ON DELETE CASCADE,
  product_id        INT           NOT NULL REFERENCES products(product_id),
  category_id       INT           NOT NULL REFERENCES categories(category_id),
  qty_sold          INT           NOT NULL DEFAULT 0,
  base_cost_price   DECIMAL(15,2) NOT NULL,
  unit_sale_price   DECIMAL(15,2) NOT NULL,
  stock_at_midnight INT           NOT NULL DEFAULT 0
);

CREATE INDEX idx_daily_product_snapshots_cat_snap_id ON daily_product_snapshots(cat_snap_id);
CREATE INDEX idx_daily_product_snapshots_product_id  ON daily_product_snapshots(product_id);

-- ============================================================
-- 30. platform_revenue_snapshots
-- Purpose: Platform-level revenue tracking per transaction (1:1).
-- ============================================================
CREATE TABLE platform_revenue_snapshots (
  platform_snap_id     SERIAL  PRIMARY KEY,
  transaction_id       INT     NOT NULL UNIQUE REFERENCES transactions(transaction_id),
  snapshot_date        DATE    NOT NULL,
  active_paying_shops  INT     NOT NULL DEFAULT 0
);

CREATE INDEX idx_platform_revenue_snapshots_date ON platform_revenue_snapshots(snapshot_date);
```

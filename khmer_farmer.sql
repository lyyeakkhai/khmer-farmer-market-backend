-- ============================================================
-- Khmer Farmer Market — Full MySQL Schema
-- Compatible with: MySQL 8.0+ / MySQL Workbench
-- ============================================================

CREATE DATABASE IF NOT EXISTS khmer_farmer_market
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE khmer_farmer_market;

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- 1. address_user
-- Created before USERS because USERS has a FK to it
-- ============================================================
CREATE TABLE address_user (
  address_id   INT           NOT NULL AUTO_INCREMENT,
  user_id      INT           NOT NULL,
  house_number VARCHAR(50)   NULL,
  province     VARCHAR(100)  NULL,
  lat          DECIMAL(10,7) NULL,
  lng          DECIMAL(10,7) NULL,
  PRIMARY KEY (address_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 2. USERS
-- ============================================================
CREATE TABLE users (
  user_id        INT          NOT NULL AUTO_INCREMENT,
  email          VARCHAR(255) NOT NULL,
  avatar_url     VARCHAR(500) NULL,
  status         ENUM('active','inactive','banned') NOT NULL DEFAULT 'active',
  created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_login_at  TIMESTAMP    NULL,
  deleted_at     TIMESTAMP    NULL,
  address_id     INT          NULL,
  PRIMARY KEY (user_id),
  UNIQUE KEY uq_users_email (email),
  CONSTRAINT fk_users_address
    FOREIGN KEY (address_id) REFERENCES address_user(address_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Add FK from address_user back to users
ALTER TABLE address_user
  ADD CONSTRAINT fk_address_user_user
  FOREIGN KEY (user_id) REFERENCES users(user_id)
  ON DELETE CASCADE ON UPDATE CASCADE;

CREATE INDEX idx_users_email ON users(email);

-- ============================================================
-- 3. USER_AUTH
-- ============================================================
CREATE TABLE user_auth (
  auth_id       INT          NOT NULL AUTO_INCREMENT,
  user_id       INT          NOT NULL,
  provider      ENUM('email','google','facebook') NOT NULL,
  provider_uid  VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NULL,
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_login_at TIMESTAMP    NULL,
  PRIMARY KEY (auth_id),
  UNIQUE KEY uq_user_auth_provider (provider, provider_uid),
  CONSTRAINT fk_user_auth_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_user_auth_user_id ON user_auth(user_id);

-- ============================================================
-- 4. USER_SESSIONS
-- ============================================================
CREATE TABLE user_sessions (
  session_id    INT          NOT NULL AUTO_INCREMENT,
  session_uuid  CHAR(36)     NOT NULL,
  user_id       INT          NOT NULL,
  device_name   VARCHAR(100) NULL,
  device_type   VARCHAR(50)  NULL,
  ip_address    VARCHAR(45)  NULL,
  user_agent    TEXT         NULL,
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_activity TIMESTAMP    NULL,
  expires_at    TIMESTAMP    NOT NULL,
  revoked_at    TIMESTAMP    NULL,
  PRIMARY KEY (session_id),
  UNIQUE KEY uq_session_uuid (session_uuid),
  CONSTRAINT fk_sessions_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_user_sessions_user_id      ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_session_uuid ON user_sessions(session_uuid);

-- ============================================================
-- 5. ROLES
-- ============================================================
CREATE TABLE roles (
  role_id   INT         NOT NULL AUTO_INCREMENT,
  role_name ENUM('customer','shop_owner','super_admin') NOT NULL,
  PRIMARY KEY (role_id),
  UNIQUE KEY uq_role_name (role_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO roles (role_name) VALUES ('customer'), ('shop_owner'), ('super_admin');

-- ============================================================
-- 6. SHOPS
-- ============================================================
CREATE TABLE shops (
  shop_id    INT           NOT NULL AUTO_INCREMENT,
  shop_name  VARCHAR(200)  NOT NULL,
  slug       VARCHAR(200)  NOT NULL,
  is_active  TINYINT(1)    NOT NULL DEFAULT 1,
  is_deleted TINYINT(1)    NOT NULL DEFAULT 0,
  created_at TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP     NULL ON UPDATE CURRENT_TIMESTAMP,
  metadata   JSON          NULL,
  PRIMARY KEY (shop_id),
  UNIQUE KEY uq_shops_slug (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_shops_slug ON shops(slug);

-- ============================================================
-- 7. MEMBERSHIPS
-- ============================================================
CREATE TABLE memberships (
  member_id  INT       NOT NULL AUTO_INCREMENT,
  user_id    INT       NOT NULL,
  role_id    INT       NOT NULL,
  shop_id    INT       NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP NULL,
  PRIMARY KEY (member_id),
  CONSTRAINT fk_memberships_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_memberships_role
    FOREIGN KEY (role_id) REFERENCES roles(role_id)
    ON UPDATE CASCADE,
  CONSTRAINT fk_memberships_shop
    FOREIGN KEY (shop_id) REFERENCES shops(shop_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_memberships_user_id ON memberships(user_id);
CREATE INDEX idx_memberships_shop_id ON memberships(shop_id);

-- ============================================================
-- 8. CUSTOMERS
-- ============================================================
CREATE TABLE customers (
  customer_id  INT          NOT NULL AUTO_INCREMENT,
  user_id      INT          NOT NULL,
  name         VARCHAR(150) NOT NULL,
  phone_number VARCHAR(20)  NULL,
  PRIMARY KEY (customer_id),
  UNIQUE KEY uq_customers_user_id (user_id),
  CONSTRAINT fk_customers_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 9. platform_categories
-- ============================================================
CREATE TABLE platform_categories (
  category_id INT          NOT NULL AUTO_INCREMENT,
  name        VARCHAR(150) NOT NULL,
  khmer_name  VARCHAR(150) NULL,
  slug        VARCHAR(150) NOT NULL,
  parent_id   INT          NULL,
  is_active   TINYINT(1)   NOT NULL DEFAULT 1,
  image       VARCHAR(500) NULL,
  PRIMARY KEY (category_id),
  UNIQUE KEY uq_platform_cat_slug (slug),
  CONSTRAINT fk_platform_cat_parent
    FOREIGN KEY (parent_id) REFERENCES platform_categories(category_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_platform_cat_parent_id ON platform_categories(parent_id);

-- ============================================================
-- 10. CATEGORIES (shop-level)
-- ============================================================
CREATE TABLE categories (
  category_id INT          NOT NULL AUTO_INCREMENT,
  shop_id     INT          NOT NULL,
  name        VARCHAR(150) NOT NULL,
  slug        VARCHAR(150) NOT NULL,
  sort_order  INT          NOT NULL DEFAULT 0,
  PRIMARY KEY (category_id),
  UNIQUE KEY uq_categories_shop_slug (shop_id, slug),
  CONSTRAINT fk_categories_shop
    FOREIGN KEY (shop_id) REFERENCES shops(shop_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_categories_shop_id ON categories(shop_id);

-- ============================================================
-- 11. PRODUCTS
-- ============================================================
CREATE TABLE products (
  product_id           INT           NOT NULL AUTO_INCREMENT,
  shop_id              INT           NOT NULL,
  category_id          INT           NOT NULL,
  platform_category_id INT           NULL,
  name                 VARCHAR(200)  NOT NULL,
  slug                 VARCHAR(200)  NOT NULL,
  base_price           DECIMAL(15,2) NOT NULL,
  quantity             INT           NOT NULL DEFAULT 0,
  PRIMARY KEY (product_id),
  UNIQUE KEY uq_products_slug (slug),
  CONSTRAINT chk_products_base_price CHECK (base_price >= 0),
  CONSTRAINT chk_products_quantity   CHECK (quantity >= 0),
  CONSTRAINT fk_products_shop
    FOREIGN KEY (shop_id) REFERENCES shops(shop_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_products_category
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON UPDATE CASCADE,
  CONSTRAINT fk_products_platform_cat
    FOREIGN KEY (platform_category_id) REFERENCES platform_categories(category_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_products_shop_id              ON products(shop_id);
CREATE INDEX idx_products_category_id          ON products(category_id);
CREATE INDEX idx_products_slug                 ON products(slug);
CREATE INDEX idx_products_shop_category        ON products(shop_id, category_id);

-- ============================================================
-- 12. product_images
-- ============================================================
CREATE TABLE product_images (
  image_id   INT          NOT NULL AUTO_INCREMENT,
  product_id INT          NOT NULL,
  shop_id    INT          NOT NULL,
  image_url  VARCHAR(500) NOT NULL,
  PRIMARY KEY (image_id),
  CONSTRAINT fk_product_images_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_product_images_shop
    FOREIGN KEY (shop_id) REFERENCES shops(shop_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_product_images_product_id ON product_images(product_id);

-- ============================================================
-- 13. event_types (EVENTTYPE)
-- ============================================================
CREATE TABLE event_types (
  event_id      INT           NOT NULL AUTO_INCREMENT,
  shop_id       INT           NOT NULL,
  name          VARCHAR(150)  NOT NULL,
  discount      DECIMAL(10,2) NOT NULL,
  discount_type ENUM('percentage','fixed') NOT NULL,
  is_available  TINYINT(1)    NOT NULL DEFAULT 1,
  PRIMARY KEY (event_id),
  CONSTRAINT chk_event_discount CHECK (discount >= 0),
  CONSTRAINT fk_event_types_shop
    FOREIGN KEY (shop_id) REFERENCES shops(shop_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_event_types_shop_id ON event_types(shop_id);

-- ============================================================
-- 14. event_products (EVENTPRODUCT)
-- ============================================================
CREATE TABLE event_products (
  event_product_id INT       NOT NULL AUTO_INCREMENT,
  shop_id          INT       NOT NULL,
  product_id       INT       NOT NULL,
  category_id      INT       NOT NULL,
  event_id         INT       NOT NULL,
  sort_order       INT       NOT NULL DEFAULT 0,
  status           ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP,
  deleted_at       TIMESTAMP NULL,
  PRIMARY KEY (event_product_id),
  CONSTRAINT fk_event_products_shop
    FOREIGN KEY (shop_id) REFERENCES shops(shop_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_event_products_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_event_products_category
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON UPDATE CASCADE,
  CONSTRAINT fk_event_products_event
    FOREIGN KEY (event_id) REFERENCES event_types(event_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_event_products_event_id   ON event_products(event_id);
CREATE INDEX idx_event_products_product_id ON event_products(product_id);

-- ============================================================
-- 15. ORDERS
-- ============================================================
CREATE TABLE orders (
  order_id       INT           NOT NULL AUTO_INCREMENT,
  customer_id    INT           NOT NULL,
  shop_id        INT           NOT NULL,
  seller_id      INT           NOT NULL,
  status         ENUM('pending','paid','processing','shipped','delivered','cancelled')
                               NOT NULL DEFAULT 'pending',
  total_price    DECIMAL(15,2) NOT NULL,
  discount_price DECIMAL(15,2) NOT NULL DEFAULT 0,
  subtotal_price DECIMAL(15,2) NOT NULL,
  created_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (order_id),
  CONSTRAINT chk_orders_total_price    CHECK (total_price >= 0),
  CONSTRAINT chk_orders_subtotal_price CHECK (subtotal_price >= 0),
  CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON UPDATE CASCADE,
  CONSTRAINT fk_orders_shop
    FOREIGN KEY (shop_id) REFERENCES shops(shop_id)
    ON UPDATE CASCADE,
  CONSTRAINT fk_orders_seller
    FOREIGN KEY (seller_id) REFERENCES users(user_id)
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_orders_customer_id     ON orders(customer_id);
CREATE INDEX idx_orders_shop_id         ON orders(shop_id);
CREATE INDEX idx_orders_customer_status ON orders(customer_id, status);
CREATE INDEX idx_orders_shop_status     ON orders(shop_id, status);

-- ============================================================
-- 16. order_items (ORDERITEM)
-- ============================================================
CREATE TABLE order_items (
  order_item_id INT           NOT NULL AUTO_INCREMENT,
  order_id      INT           NOT NULL,
  product_id    INT           NOT NULL,
  quantities    INT           NOT NULL,
  sold_price    DECIMAL(15,2) NOT NULL,
  PRIMARY KEY (order_item_id),
  CONSTRAINT chk_order_items_qty        CHECK (quantities > 0),
  CONSTRAINT chk_order_items_sold_price CHECK (sold_price >= 0),
  CONSTRAINT fk_order_items_order
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_order_items_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_order_items_order_id ON order_items(order_id);

-- ============================================================
-- 17. platform_fees (PlatformFee)
-- ============================================================
CREATE TABLE platform_fees (
  id             INT           NOT NULL AUTO_INCREMENT,
  fee_name       VARCHAR(100)  NOT NULL,
  fee_type       ENUM('percentage','fixed') NOT NULL,
  percentage     DECIMAL(5,2)  NULL,
  effective_from DATE          NOT NULL,
  status         ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     TIMESTAMP     NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT chk_platform_fees_pct CHECK (percentage IS NULL OR (percentage >= 0 AND percentage <= 100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 18. shop_payment_methods
-- ============================================================
CREATE TABLE shop_payment_methods (
  method_id     INT         NOT NULL AUTO_INCREMENT,
  shop_id       INT         NOT NULL,
  card_type     ENUM('visa','mastercard','bakong_khqr') NOT NULL,
  gateway_token VARCHAR(500) NULL,
  last_four     CHAR(4)     NULL,
  expiry_date   DATE        NULL,
  PRIMARY KEY (method_id),
  CONSTRAINT fk_spm_shop
    FOREIGN KEY (shop_id) REFERENCES shops(shop_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_spm_shop_id ON shop_payment_methods(shop_id);

-- ============================================================
-- 19. transactions (TRANSACTION)
-- ============================================================
CREATE TABLE transactions (
  transaction_id  INT           NOT NULL AUTO_INCREMENT,
  order_id        INT           NOT NULL,
  shop_id         INT           NOT NULL,
  customer_id     INT           NOT NULL,
  platform_fee_id INT           NULL,
  intent_id       INT           NULL,
  payer_id        INT           NULL,
  method_id       INT           NULL,
  bank_ref_id     VARCHAR(100)  NULL,
  currency        VARCHAR(10)   NOT NULL DEFAULT 'USD',
  amount          DECIMAL(15,2) NOT NULL,
  total_amount    DECIMAL(15,2) NOT NULL,
  PRIMARY KEY (transaction_id),
  CONSTRAINT chk_transactions_amount       CHECK (amount >= 0),
  CONSTRAINT chk_transactions_total_amount CHECK (total_amount >= 0),
  CONSTRAINT fk_transactions_order
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON UPDATE CASCADE,
  CONSTRAINT fk_transactions_shop
    FOREIGN KEY (shop_id) REFERENCES shops(shop_id)
    ON UPDATE CASCADE,
  CONSTRAINT fk_transactions_customer
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON UPDATE CASCADE,
  CONSTRAINT fk_transactions_platform_fee
    FOREIGN KEY (platform_fee_id) REFERENCES platform_fees(id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_transactions_method
    FOREIGN KEY (method_id) REFERENCES shop_payment_methods(method_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_transactions_order_id ON transactions(order_id);
CREATE INDEX idx_transactions_shop_id  ON transactions(shop_id);

-- ============================================================
-- 20. payment_intents
-- ============================================================
CREATE TABLE payment_intents (
  intent_id      INT       NOT NULL AUTO_INCREMENT,
  transaction_id INT       NOT NULL,
  method_id      INT       NOT NULL,
  qr_code_data   TEXT      NULL,
  status         ENUM('pending','completed','expired','failed') NOT NULL DEFAULT 'pending',
  expires_at     TIMESTAMP NOT NULL,
  PRIMARY KEY (intent_id),
  CONSTRAINT fk_payment_intents_transaction
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_payment_intents_method
    FOREIGN KEY (method_id) REFERENCES shop_payment_methods(method_id)
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_payment_intents_transaction_id ON payment_intents(transaction_id);

-- ============================================================
-- 21. invoices
-- ============================================================
CREATE TABLE invoices (
  invoice_id     INT           NOT NULL AUTO_INCREMENT,
  transaction_id INT           NOT NULL,
  invoice_no     VARCHAR(50)   NOT NULL,
  status         ENUM('draft','issued','paid','cancelled') NOT NULL,
  sub_total      DECIMAL(15,2) NOT NULL,
  tax_amount     DECIMAL(15,2) NOT NULL DEFAULT 0,
  discount_price DECIMAL(15,2) NOT NULL DEFAULT 0,
  total_amount   DECIMAL(15,2) NOT NULL,
  PRIMARY KEY (invoice_id),
  UNIQUE KEY uq_invoices_transaction_id (transaction_id),
  UNIQUE KEY uq_invoices_invoice_no (invoice_no),
  CONSTRAINT fk_invoices_transaction
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 22. order_delivery_snapshots
-- ============================================================
CREATE TABLE order_delivery_snapshots (
  id             INT           NOT NULL AUTO_INCREMENT,
  order_id       INT           NOT NULL,
  address_id     INT           NULL,
  recipient_name VARCHAR(150)  NOT NULL,
  phone          VARCHAR(20)   NOT NULL,
  house_number   VARCHAR(50)   NULL,
  province       VARCHAR(100)  NULL,
  lat            DECIMAL(10,7) NULL,
  lng            DECIMAL(10,7) NULL,
  note_delivery  TEXT          NULL,
  status         ENUM('pending','in_transit','delivered','failed') NOT NULL DEFAULT 'pending',
  PRIMARY KEY (id),
  UNIQUE KEY uq_ods_order_id (order_id),
  CONSTRAINT fk_ods_order
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ods_address
    FOREIGN KEY (address_id) REFERENCES address_user(address_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 23. deliveries (DELIVERY)
-- ============================================================
CREATE TABLE deliveries (
  delivery_id                INT  NOT NULL AUTO_INCREMENT,
  order_id                   INT  NOT NULL,
  delivery_date              DATE NULL,
  order_delivery_snapshot_id INT  NULL,
  PRIMARY KEY (delivery_id),
  UNIQUE KEY uq_deliveries_order_id (order_id),
  CONSTRAINT fk_deliveries_order
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_deliveries_snapshot
    FOREIGN KEY (order_delivery_snapshot_id) REFERENCES order_delivery_snapshots(id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_deliveries_order_id ON deliveries(order_id);

-- ============================================================
-- 24. delivery_logs
-- ============================================================
CREATE TABLE delivery_logs (
  id                   INT          NOT NULL AUTO_INCREMENT,
  delivery_id          INT          NOT NULL,
  status               VARCHAR(50)  NOT NULL,
  location_description TEXT         NULL,
  timestamp            TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT fk_delivery_logs_delivery
    FOREIGN KEY (delivery_id) REFERENCES deliveries(delivery_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_delivery_logs_delivery_id ON delivery_logs(delivery_id);

-- ============================================================
-- 25. hubs
-- ============================================================
CREATE TABLE hubs (
  id             INT          NOT NULL AUTO_INCREMENT,
  hub_name       VARCHAR(150) NOT NULL,
  province       VARCHAR(100) NOT NULL,
  address        TEXT         NULL,
  contact_number VARCHAR(20)  NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 26. notifications
-- ============================================================
CREATE TABLE notifications (
  notification_id INT          NOT NULL AUTO_INCREMENT,
  user_id         INT          NOT NULL,
  type            ENUM('order','payment','shipment','promotion','verification') NOT NULL,
  priority        ENUM('low','medium','high') NOT NULL DEFAULT 'medium',
  title           VARCHAR(200) NOT NULL,
  content         TEXT         NOT NULL,
  link_url        VARCHAR(500) NULL,
  is_read         TINYINT(1)   NOT NULL DEFAULT 0,
  created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (notification_id),
  CONSTRAINT fk_notifications_user
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_notifications_user_id      ON notifications(user_id);
CREATE INDEX idx_notifications_user_is_read ON notifications(user_id, is_read);

-- ============================================================
-- 27. daily_snapshots (DAILY_SNAPSHOTS)
-- ============================================================
CREATE TABLE daily_snapshots (
  snapshot_id   INT           NOT NULL AUTO_INCREMENT,
  shop_id       INT           NOT NULL,
  snapshot_date DATE          NOT NULL,
  total_gross   DECIMAL(15,2) NOT NULL DEFAULT 0,
  total_profit  DECIMAL(15,2) NOT NULL DEFAULT 0,
  order_count   INT           NOT NULL DEFAULT 0,
  PRIMARY KEY (snapshot_id),
  UNIQUE KEY uq_daily_snapshots_shop_date (shop_id, snapshot_date),
  CONSTRAINT fk_daily_snapshots_shop
    FOREIGN KEY (shop_id) REFERENCES shops(shop_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_daily_snapshots_shop_date ON daily_snapshots(shop_id, snapshot_date);

-- ============================================================
-- 28. daily_category_snapshots (DAILY_C_SNAPSHOTS)
-- ============================================================
CREATE TABLE daily_category_snapshots (
  cat_snap_id       INT           NOT NULL AUTO_INCREMENT,
  snapshot_id       INT           NOT NULL,
  category_id       INT           NOT NULL,
  cat_gross_revenue DECIMAL(15,2) NOT NULL DEFAULT 0,
  cat_net_profit    DECIMAL(15,2) NOT NULL DEFAULT 0,
  cat_items_sold    INT           NOT NULL DEFAULT 0,
  PRIMARY KEY (cat_snap_id),
  CONSTRAINT fk_dcs_snapshot
    FOREIGN KEY (snapshot_id) REFERENCES daily_snapshots(snapshot_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_dcs_category
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_dcs_snapshot_id ON daily_category_snapshots(snapshot_id);

-- ============================================================
-- 29. daily_product_snapshots
-- ============================================================
CREATE TABLE daily_product_snapshots (
  id                INT           NOT NULL AUTO_INCREMENT,
  cat_snap_id       INT           NOT NULL,
  product_id        INT           NOT NULL,
  category_id       INT           NOT NULL,
  qty_sold          INT           NOT NULL DEFAULT 0,
  base_cost_price   DECIMAL(15,2) NOT NULL,
  unit_sale_price   DECIMAL(15,2) NOT NULL,
  stock_at_midnight INT           NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  CONSTRAINT fk_dps_cat_snap
    FOREIGN KEY (cat_snap_id) REFERENCES daily_category_snapshots(cat_snap_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_dps_product
    FOREIGN KEY (product_id) REFERENCES products(product_id)
    ON UPDATE CASCADE,
  CONSTRAINT fk_dps_category
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_dps_cat_snap_id ON daily_product_snapshots(cat_snap_id);
CREATE INDEX idx_dps_product_id  ON daily_product_snapshots(product_id);

-- ============================================================
-- 30. platform_revenue_snapshots
-- ============================================================
CREATE TABLE platform_revenue_snapshots (
  platform_snap_id    INT  NOT NULL AUTO_INCREMENT,
  transaction_id      INT  NOT NULL,
  snapshot_date       DATE NOT NULL,
  active_paying_shops INT  NOT NULL DEFAULT 0,
  PRIMARY KEY (platform_snap_id),
  UNIQUE KEY uq_prs_transaction_id (transaction_id),
  CONSTRAINT fk_prs_transaction
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id)
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_prs_snapshot_date ON platform_revenue_snapshots(snapshot_date);

-- ============================================================
-- Re-enable FK checks
-- ============================================================
SET FOREIGN_KEY_CHECKS = 1;

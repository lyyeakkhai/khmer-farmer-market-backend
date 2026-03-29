-- ============================================================
-- Khmer Farmer Market — Test Data & Feature Queries
-- Run AFTER khmer_farmer.sql
-- MySQL 8.0+ / MySQL Workbench
-- ============================================================

USE khmer_farmer_market;
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- SEED DATA
-- ============================================================

-- ------------------------------------------------------------
-- address_user (created before users due to circular FK)
-- ------------------------------------------------------------
INSERT INTO address_user (address_id, user_id, house_number, province, lat, lng) VALUES
(1, 1, '12A', 'Phnom Penh',   11.5564, 104.9282),
(2, 2, '45B', 'Siem Reap',    13.3671, 103.8448),
(3, 3, '7C',  'Battambang',   13.0957, 103.2022),
(4, 4, '88D', 'Kampot',       10.6100, 104.1800),
(5, 5, '3E',  'Phnom Penh',   11.5700, 104.9100);

-- ------------------------------------------------------------
-- USERS
-- ------------------------------------------------------------
INSERT INTO users (user_id, email, avatar_url, status, created_at, address_id) VALUES
(1, 'admin@khmerfarmer.com',   NULL,                          'active', '2024-01-01 08:00:00', 1),
(2, 'sophea@gmail.com',        'https://cdn.kfm/u2.jpg',      'active', '2024-01-05 09:00:00', 2),
(3, 'dara@gmail.com',          'https://cdn.kfm/u3.jpg',      'active', '2024-01-10 10:00:00', 3),
(4, 'maly@gmail.com',          'https://cdn.kfm/u4.jpg',      'active', '2024-02-01 11:00:00', 4),
(5, 'rith@gmail.com',          'https://cdn.kfm/u5.jpg',      'active', '2024-02-15 12:00:00', 5),
(6, 'customer1@gmail.com',     NULL,                          'active', '2024-03-01 08:00:00', NULL),
(7, 'customer2@gmail.com',     NULL,                          'active', '2024-03-05 09:00:00', NULL),
(8, 'banned@gmail.com',        NULL,                          'banned', '2024-03-10 10:00:00', NULL);

-- Update address_user.user_id to match
UPDATE address_user SET user_id = 1 WHERE address_id = 1;
UPDATE address_user SET user_id = 2 WHERE address_id = 2;
UPDATE address_user SET user_id = 3 WHERE address_id = 3;
UPDATE address_user SET user_id = 4 WHERE address_id = 4;
UPDATE address_user SET user_id = 5 WHERE address_id = 5;

-- ------------------------------------------------------------
-- USER_AUTH
-- ------------------------------------------------------------
INSERT INTO user_auth (user_id, provider, provider_uid, password_hash) VALUES
(1, 'email',    'admin@khmerfarmer.com',  '$2b$10$adminhashedpwd'),
(2, 'email',    'sophea@gmail.com',       '$2b$10$sopheahash'),
(2, 'google',   'google_uid_sophea',      NULL),
(3, 'email',    'dara@gmail.com',         '$2b$10$darahash'),
(4, 'facebook', 'fb_uid_maly',            NULL),
(5, 'email',    'rith@gmail.com',         '$2b$10$rithhash'),
(6, 'email',    'customer1@gmail.com',    '$2b$10$cust1hash'),
(7, 'email',    'customer2@gmail.com',    '$2b$10$cust2hash');

-- ------------------------------------------------------------
-- USER_SESSIONS
-- ------------------------------------------------------------
INSERT INTO user_sessions (session_uuid, user_id, device_name, device_type, ip_address, expires_at) VALUES
('a1b2c3d4-0001-0001-0001-000000000001', 2, 'iPhone 14',      'mobile',  '192.168.1.10', '2025-12-31 23:59:59'),
('a1b2c3d4-0002-0002-0002-000000000002', 3, 'Samsung Galaxy', 'mobile',  '192.168.1.11', '2025-12-31 23:59:59'),
('a1b2c3d4-0003-0003-0003-000000000003', 6, 'Chrome/Windows', 'desktop', '10.0.0.5',     '2025-12-31 23:59:59'),
('a1b2c3d4-0004-0004-0004-000000000004', 7, 'Safari/Mac',     'desktop', '10.0.0.6',     '2024-01-01 00:00:00');

-- ------------------------------------------------------------
-- ROLES (already seeded in schema, skip re-insert)
-- role_id 1=customer, 2=shop_owner, 3=super_admin
-- ------------------------------------------------------------

-- ------------------------------------------------------------
-- SHOPS
-- ------------------------------------------------------------
INSERT INTO shops (shop_id, shop_name, slug, is_active, is_deleted, created_at, metadata) VALUES
(1, 'Sophea Rice Farm',    'sophea-rice-farm',    1, 0, '2024-01-06 09:00:00', '{"description":"Premium Cambodian rice","province":"Siem Reap"}'),
(2, 'Dara Organic Vegs',   'dara-organic-vegs',   1, 0, '2024-01-11 10:00:00', '{"description":"Fresh organic vegetables","province":"Battambang"}'),
(3, 'Maly Fruit Garden',   'maly-fruit-garden',   1, 0, '2024-02-02 11:00:00', '{"description":"Tropical fruits","province":"Kampot"}'),
(4, 'Rith Spice House',    'rith-spice-house',    0, 0, '2024-02-16 12:00:00', '{"description":"Cambodian spices","province":"Phnom Penh"}');

-- ------------------------------------------------------------
-- MEMBERSHIPS
-- user 1 = super_admin, users 2-5 = shop_owners, users 6-7 = customers
-- ------------------------------------------------------------
INSERT INTO memberships (user_id, role_id, shop_id) VALUES
(1, 3, NULL),   -- admin
(2, 2, 1),      -- sophea owns shop 1
(3, 2, 2),      -- dara owns shop 2
(4, 2, 3),      -- maly owns shop 3
(5, 2, 4),      -- rith owns shop 4
(6, 1, NULL),   -- customer1
(7, 1, NULL);   -- customer2

-- ------------------------------------------------------------
-- CUSTOMERS
-- ------------------------------------------------------------
INSERT INTO customers (customer_id, user_id, name, phone_number) VALUES
(1, 6, 'Chenda Sok',   '012345678'),
(2, 7, 'Bopha Keo',    '098765432');

-- ------------------------------------------------------------
-- platform_categories
-- ------------------------------------------------------------
INSERT INTO platform_categories (category_id, name, khmer_name, slug, parent_id, is_active) VALUES
(1, 'Agriculture',    'កសិកម្ម',      'agriculture',    NULL, 1),
(2, 'Rice & Grains',  'អង្ករ និងធញ្ញជាតិ', 'rice-grains',  1,    1),
(3, 'Vegetables',     'បន្លែ',         'vegetables',     1,    1),
(4, 'Fruits',         'ផ្លែឈើ',        'fruits',         1,    1),
(5, 'Spices & Herbs', 'គ្រឿងទេស',     'spices-herbs',   1,    1);

-- ------------------------------------------------------------
-- CATEGORIES (shop-level)
-- ------------------------------------------------------------
INSERT INTO categories (category_id, shop_id, name, slug, sort_order) VALUES
(1, 1, 'White Rice',     'white-rice',     1),
(2, 1, 'Brown Rice',     'brown-rice',     2),
(3, 2, 'Leafy Greens',   'leafy-greens',   1),
(4, 2, 'Root Vegetables','root-vegetables',2),
(5, 3, 'Tropical Fruits','tropical-fruits',1),
(6, 3, 'Citrus',         'citrus',         2),
(7, 4, 'Dried Spices',   'dried-spices',   1);

-- ------------------------------------------------------------
-- PRODUCTS
-- ------------------------------------------------------------
INSERT INTO products (product_id, shop_id, category_id, platform_category_id, name, slug, base_price, quantity) VALUES
(1,  1, 1, 2, 'Jasmine White Rice 5kg',   'jasmine-white-rice-5kg',   12.50, 200),
(2,  1, 1, 2, 'Phka Malis Rice 10kg',     'phka-malis-rice-10kg',     22.00, 150),
(3,  1, 2, 2, 'Brown Rice 5kg',           'brown-rice-5kg',           14.00, 100),
(4,  2, 3, 3, 'Morning Glory 500g',       'morning-glory-500g',        2.50, 500),
(5,  2, 3, 3, 'Water Spinach 1kg',        'water-spinach-1kg',         3.00, 400),
(6,  2, 4, 3, 'Cassava 2kg',              'cassava-2kg',               4.50, 300),
(7,  3, 5, 4, 'Mango 1kg',               'mango-1kg',                 5.00, 250),
(8,  3, 5, 4, 'Durian 1 piece',          'durian-1-piece',           15.00,  80),
(9,  3, 6, 4, 'Lime 500g',               'lime-500g',                 2.00, 600),
(10, 4, 7, 5, 'Kampot Pepper 100g',      'kampot-pepper-100g',        8.00, 120);

-- ------------------------------------------------------------
-- product_images
-- ------------------------------------------------------------
INSERT INTO product_images (product_id, shop_id, image_url) VALUES
(1, 1, 'https://cdn.kfm/products/jasmine-rice-1.jpg'),
(1, 1, 'https://cdn.kfm/products/jasmine-rice-2.jpg'),
(2, 1, 'https://cdn.kfm/products/phka-malis-1.jpg'),
(4, 2, 'https://cdn.kfm/products/morning-glory-1.jpg'),
(7, 3, 'https://cdn.kfm/products/mango-1.jpg'),
(8, 3, 'https://cdn.kfm/products/durian-1.jpg'),
(10,4, 'https://cdn.kfm/products/pepper-1.jpg');

-- ------------------------------------------------------------
-- event_types
-- ------------------------------------------------------------
INSERT INTO event_types (event_id, shop_id, name, discount, discount_type, is_available) VALUES
(1, 1, 'Harvest Season Sale',  10.00, 'percentage', 1),
(2, 2, 'Fresh Veggie Week',     1.00, 'fixed',       1),
(3, 3, 'Fruit Festival',       15.00, 'percentage',  1),
(4, 1, 'New Year Promo',        5.00, 'percentage',  0);

-- ------------------------------------------------------------
-- event_products
-- ------------------------------------------------------------
INSERT INTO event_products (shop_id, product_id, category_id, event_id, sort_order, status) VALUES
(1, 1, 1, 1, 1, 'active'),
(1, 2, 1, 1, 2, 'active'),
(1, 3, 2, 1, 3, 'active'),
(2, 4, 3, 2, 1, 'active'),
(2, 5, 3, 2, 2, 'active'),
(3, 7, 5, 3, 1, 'active'),
(3, 8, 5, 3, 2, 'active'),
(1, 1, 1, 4, 1, 'inactive');

-- ------------------------------------------------------------
-- platform_fees
-- ------------------------------------------------------------
INSERT INTO platform_fees (id, fee_name, fee_type, percentage, effective_from, status) VALUES
(1, 'Standard Fee v1', 'percentage', 3.00, '2024-01-01', 'inactive'),
(2, 'Standard Fee v2', 'percentage', 2.50, '2024-06-01', 'active'),
(3, 'Fixed Fee Test',  'fixed',      NULL, '2024-03-01', 'inactive');

-- ------------------------------------------------------------
-- shop_payment_methods
-- ------------------------------------------------------------
INSERT INTO shop_payment_methods (method_id, shop_id, card_type, gateway_token, last_four, expiry_date) VALUES
(1, 1, 'bakong_khqr', 'token_shop1_khqr',       NULL,   NULL),
(2, 1, 'visa',        'token_shop1_visa',        '4242', '2026-12-31'),
(3, 2, 'bakong_khqr', 'token_shop2_khqr',        NULL,   NULL),
(4, 3, 'mastercard',  'token_shop3_mc',          '5555', '2027-06-30'),
(5, 3, 'bakong_khqr', 'token_shop3_khqr',        NULL,   NULL),
(6, 4, 'visa',        'token_shop4_visa',        '1234', '2025-09-30');

-- ------------------------------------------------------------
-- ORDERS
-- ------------------------------------------------------------
INSERT INTO orders (order_id, customer_id, shop_id, seller_id, status, total_price, discount_price, subtotal_price, created_at) VALUES
(1, 1, 1, 2, 'delivered',  25.00,  2.50, 22.50, '2024-04-01 10:00:00'),
(2, 1, 2, 3, 'paid',        5.50,  1.00,  4.50, '2024-04-05 11:00:00'),
(3, 2, 3, 4, 'shipped',    20.00,  3.00, 17.00, '2024-04-10 09:00:00'),
(4, 1, 1, 2, 'pending',    22.00,  0.00, 22.00, '2024-05-01 14:00:00'),
(5, 2, 2, 3, 'cancelled',   3.00,  0.00,  3.00, '2024-05-05 15:00:00'),
(6, 1, 3, 4, 'delivered',  15.00,  2.25, 12.75, '2024-05-10 16:00:00'),
(7, 2, 1, 2, 'processing', 12.50,  1.25, 11.25, '2024-06-01 08:00:00');

-- ------------------------------------------------------------
-- order_items
-- ------------------------------------------------------------
INSERT INTO order_items (order_id, product_id, quantities, sold_price) VALUES
(1, 1, 2, 12.50),
(2, 4, 2,  2.50),
(2, 5, 1,  3.00),
(3, 7, 2,  5.00),
(3, 8, 1, 15.00),
(4, 2, 1, 22.00),
(5, 4, 1,  2.50),
(6, 8, 1, 15.00),
(7, 1, 1, 12.50);

-- ------------------------------------------------------------
-- transactions
-- ------------------------------------------------------------
INSERT INTO transactions (transaction_id, order_id, shop_id, customer_id, platform_fee_id, method_id, bank_ref_id, currency, amount, total_amount) VALUES
(1, 1, 1, 1, 2, 1, 'BANK_REF_001', 'USD', 22.50, 23.06),
(2, 2, 2, 1, 2, 3, 'BANK_REF_002', 'USD',  4.50,  4.61),
(3, 3, 3, 2, 2, 4, 'BANK_REF_003', 'USD', 17.00, 17.43),
(4, 6, 3, 1, 2, 5, 'BANK_REF_004', 'USD', 12.75, 13.07),
(5, 7, 1, 2, 2, 1, 'BANK_REF_005', 'USD', 11.25, 11.53);

-- ------------------------------------------------------------
-- payment_intents
-- ------------------------------------------------------------
INSERT INTO payment_intents (transaction_id, method_id, qr_code_data, status, expires_at) VALUES
(1, 1, '00020101021229370016A000000625010193520415KHQR_DATA_001', 'completed', '2024-04-01 10:30:00'),
(2, 3, '00020101021229370016A000000625010193520415KHQR_DATA_002', 'completed', '2024-04-05 11:30:00'),
(3, 4, NULL,                                                       'completed', '2024-04-10 09:30:00'),
(4, 5, '00020101021229370016A000000625010193520415KHQR_DATA_004', 'completed', '2024-05-10 16:30:00'),
(5, 1, '00020101021229370016A000000625010193520415KHQR_DATA_005', 'pending',   '2025-12-31 23:59:59');

-- ------------------------------------------------------------
-- invoices
-- ------------------------------------------------------------
INSERT INTO invoices (transaction_id, invoice_no, status, sub_total, tax_amount, discount_price, total_amount) VALUES
(1, 'INV-2024-0001', 'paid',   22.50, 0.56, 2.50, 23.06),
(2, 'INV-2024-0002', 'paid',    4.50, 0.11, 1.00,  4.61),
(3, 'INV-2024-0003', 'paid',   17.00, 0.43, 3.00, 17.43),
(4, 'INV-2024-0004', 'paid',   12.75, 0.32, 2.25, 13.07);

-- ------------------------------------------------------------
-- order_delivery_snapshots
-- ------------------------------------------------------------
INSERT INTO order_delivery_snapshots (order_id, address_id, recipient_name, phone, house_number, province, lat, lng, note_delivery, status) VALUES
(1, 1, 'Chenda Sok', '012345678', '12A', 'Phnom Penh', 11.5564, 104.9282, 'Leave at door',  'delivered'),
(3, 2, 'Bopha Keo',  '098765432', '45B', 'Siem Reap',  13.3671, 103.8448, NULL,             'in_transit'),
(6, 1, 'Chenda Sok', '012345678', '12A', 'Phnom Penh', 11.5564, 104.9282, 'Call on arrival','delivered');

-- ------------------------------------------------------------
-- deliveries
-- ------------------------------------------------------------
INSERT INTO deliveries (order_id, delivery_date, order_delivery_snapshot_id) VALUES
(1, '2024-04-03', 1),
(3, '2024-04-13', 2),
(6, '2024-05-12', 3);

-- ------------------------------------------------------------
-- delivery_logs
-- ------------------------------------------------------------
INSERT INTO delivery_logs (delivery_id, status, location_description, timestamp) VALUES
(1, 'picked_up',   'Siem Reap warehouse',         '2024-04-01 14:00:00'),
(1, 'in_transit',  'Phnom Penh sorting hub',       '2024-04-02 08:00:00'),
(1, 'delivered',   'Customer address - Phnom Penh','2024-04-03 11:00:00'),
(2, 'picked_up',   'Battambang warehouse',         '2024-04-10 13:00:00'),
(2, 'in_transit',  'Siem Reap hub',                '2024-04-11 09:00:00'),
(3, 'picked_up',   'Kampot warehouse',             '2024-05-10 10:00:00'),
(3, 'in_transit',  'Phnom Penh sorting hub',       '2024-05-11 07:00:00'),
(3, 'delivered',   'Customer address - Phnom Penh','2024-05-12 14:00:00');

-- ------------------------------------------------------------
-- hubs
-- ------------------------------------------------------------
INSERT INTO hubs (hub_name, province, address, contact_number) VALUES
('Phnom Penh Central Hub', 'Phnom Penh', 'St 271, Toul Kork', '023-456-789'),
('Siem Reap Hub',          'Siem Reap',  'NR6, Svay Dangkum', '063-123-456'),
('Battambang Hub',         'Battambang', 'St 3, Rattanak',    '053-789-012'),
('Kampot Hub',             'Kampot',     'NR3, Kampot Town',  '033-234-567');

-- ------------------------------------------------------------
-- notifications
-- ------------------------------------------------------------
INSERT INTO notifications (user_id, type, priority, title, content, link_url, is_read) VALUES
(6, 'order',    'high',   'Order Placed',          'Your order #1 has been placed.',          '/orders/1', 1),
(6, 'payment',  'high',   'Payment Confirmed',     'Payment for order #1 confirmed.',         '/orders/1', 1),
(6, 'shipment', 'medium', 'Order Shipped',         'Your order #1 is on the way.',            '/orders/1', 1),
(6, 'shipment', 'medium', 'Order Delivered',       'Your order #1 has been delivered.',       '/orders/1', 0),
(7, 'order',    'high',   'Order Placed',          'Your order #3 has been placed.',          '/orders/3', 1),
(7, 'shipment', 'medium', 'Order In Transit',      'Your order #3 is in transit.',            '/orders/3', 0),
(2, 'order',    'high',   'New Order Received',    'You have a new order #1 from Chenda.',    '/shop/orders/1', 1),
(2, 'order',    'high',   'New Order Received',    'You have a new order #7 from Bopha.',     '/shop/orders/7', 0),
(6, 'promotion','low',    'Harvest Season Sale',   '10% off all rice products this week!',    '/events/1', 0);

-- ------------------------------------------------------------
-- daily_snapshots
-- ------------------------------------------------------------
INSERT INTO daily_snapshots (shop_id, snapshot_date, total_gross, total_profit, order_count) VALUES
(1, '2024-04-01', 25.00, 18.50, 1),
(1, '2024-05-01', 22.00, 16.00, 1),
(1, '2024-06-01', 12.50,  9.00, 1),
(2, '2024-04-05',  5.50,  4.00, 1),
(3, '2024-04-10', 20.00, 14.00, 1),
(3, '2024-05-10', 15.00, 10.50, 1);

-- ------------------------------------------------------------
-- daily_category_snapshots
-- ------------------------------------------------------------
INSERT INTO daily_category_snapshots (snapshot_id, category_id, cat_gross_revenue, cat_net_profit, cat_items_sold) VALUES
(1, 1, 25.00, 18.50, 2),
(2, 1, 22.00, 16.00, 1),
(3, 1, 12.50,  9.00, 1),
(4, 3,  5.50,  4.00, 3),
(5, 5, 20.00, 14.00, 3),
(6, 5, 15.00, 10.50, 1);

-- ------------------------------------------------------------
-- daily_product_snapshots
-- ------------------------------------------------------------
INSERT INTO daily_product_snapshots (cat_snap_id, product_id, category_id, qty_sold, base_cost_price, unit_sale_price, stock_at_midnight) VALUES
(1, 1, 1, 2, 10.00, 12.50, 198),
(2, 2, 1, 1, 18.00, 22.00, 149),
(3, 1, 1, 1, 10.00, 12.50, 197),
(4, 4, 3, 2,  1.50,  2.50, 498),
(4, 5, 3, 1,  2.00,  3.00, 399),
(5, 7, 5, 2,  3.50,  5.00, 248),
(5, 8, 5, 1, 10.00, 15.00,  79),
(6, 8, 5, 1, 10.00, 15.00,  78);

-- ------------------------------------------------------------
-- platform_revenue_snapshots
-- ------------------------------------------------------------
INSERT INTO platform_revenue_snapshots (transaction_id, snapshot_date, active_paying_shops) VALUES
(1, '2024-04-01', 1),
(2, '2024-04-05', 1),
(3, '2024-04-10', 1),
(4, '2024-05-10', 1);

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- FEATURE QUERIES
-- ============================================================

-- ============================================================
-- FEATURE 1: Identity & Access Management (IAM)
-- ============================================================

-- Q1.1 Login lookup — find user by email with their auth provider
SELECT u.user_id, u.email, u.status, ua.provider, ua.provider_uid,
       ua.password_hash IS NOT NULL AS has_password
FROM users u
JOIN user_auth ua ON ua.user_id = u.user_id
WHERE u.email = 'sophea@gmail.com' AND u.deleted_at IS NULL;

-- Q1.2 All active sessions for a user (not expired, not revoked)
SELECT s.session_id, s.session_uuid, s.device_name, s.device_type,
       s.ip_address, s.created_at, s.expires_at
FROM user_sessions s
WHERE s.user_id = 2
  AND s.revoked_at IS NULL
  AND s.expires_at > NOW();

-- Q1.3 Complex: Users with multiple auth providers + their active session count
SELECT u.user_id, u.email,
       COUNT(DISTINCT ua.provider)  AS provider_count,
       GROUP_CONCAT(ua.provider)    AS providers,
       COUNT(DISTINCT s.session_id) AS active_sessions
FROM users u
LEFT JOIN user_auth ua ON ua.user_id = u.user_id
LEFT JOIN user_sessions s ON s.user_id = u.user_id
       AND s.revoked_at IS NULL AND s.expires_at > NOW()
WHERE u.deleted_at IS NULL
GROUP BY u.user_id, u.email
ORDER BY provider_count DESC;

-- Q1.4 Complex: All shop owners with their shop names and membership status
SELECT u.user_id, u.email, r.role_name, s.shop_name, s.slug,
       s.is_active AS shop_active, m.deleted_at AS membership_revoked
FROM memberships m
JOIN users u  ON u.user_id  = m.user_id
JOIN roles r  ON r.role_id  = m.role_id
LEFT JOIN shops s ON s.shop_id = m.shop_id
WHERE r.role_name = 'shop_owner'
ORDER BY u.user_id;

-- Q1.5 Banned or soft-deleted users with their last login
SELECT u.user_id, u.email, u.status, u.deleted_at,
       MAX(ua.last_login_at) AS last_login
FROM users u
LEFT JOIN user_auth ua ON ua.user_id = u.user_id
WHERE u.status = 'banned' OR u.deleted_at IS NOT NULL
GROUP BY u.user_id, u.email, u.status, u.deleted_at;

-- ============================================================
-- FEATURE 2: Shop & Inventory Management
-- ============================================================

-- Q2.1 All active shops with owner email and product count
SELECT s.shop_id, s.shop_name, s.slug, u.email AS owner_email,
       COUNT(p.product_id) AS product_count
FROM shops s
JOIN memberships m ON m.shop_id = s.shop_id
JOIN users u       ON u.user_id = m.user_id
JOIN roles r       ON r.role_id = m.role_id AND r.role_name = 'shop_owner'
LEFT JOIN products p ON p.shop_id = s.shop_id
WHERE s.is_active = 1 AND s.is_deleted = 0
GROUP BY s.shop_id, s.shop_name, s.slug, u.email
ORDER BY product_count DESC;

-- Q2.2 Products with low stock (quantity < 100)
SELECT p.product_id, p.name, p.slug, p.quantity, p.base_price,
       s.shop_name, c.name AS category
FROM products p
JOIN shops s      ON s.shop_id      = p.shop_id
JOIN categories c ON c.category_id  = p.category_id
WHERE p.quantity < 100
ORDER BY p.quantity ASC;

-- Q2.3 Complex: Product catalog with platform category, shop category, image count
SELECT p.product_id, p.name, p.base_price, p.quantity,
       s.shop_name,
       c.name  AS shop_category,
       pc.name AS platform_category,
       COUNT(pi.image_id) AS image_count
FROM products p
JOIN shops s               ON s.shop_id      = p.shop_id
JOIN categories c          ON c.category_id  = p.category_id
LEFT JOIN platform_categories pc ON pc.category_id = p.platform_category_id
LEFT JOIN product_images pi ON pi.product_id = p.product_id
GROUP BY p.product_id, p.name, p.base_price, p.quantity,
         s.shop_name, c.name, pc.name
ORDER BY s.shop_name, c.name;

-- Q2.4 Complex: Platform category hierarchy (parent → children)
SELECT parent.name AS parent_category,
       child.name  AS child_category,
       child.khmer_name,
       child.slug,
       child.is_active,
       COUNT(p.product_id) AS products_linked
FROM platform_categories child
LEFT JOIN platform_categories parent ON parent.category_id = child.parent_id
LEFT JOIN products p ON p.platform_category_id = child.category_id
GROUP BY parent.name, child.name, child.khmer_name, child.slug, child.is_active
ORDER BY parent.name, child.name;

-- ============================================================
-- FEATURE 3: Event / Promotion Management
-- ============================================================

-- Q3.1 All active events with shop name and product count
SELECT et.event_id, et.name AS event_name, et.discount, et.discount_type,
       s.shop_name,
       COUNT(ep.event_product_id) AS products_in_event
FROM event_types et
JOIN shops s ON s.shop_id = et.shop_id
LEFT JOIN event_products ep ON ep.event_id = et.event_id AND ep.deleted_at IS NULL
WHERE et.is_available = 1
GROUP BY et.event_id, et.name, et.discount, et.discount_type, s.shop_name;

-- Q3.2 Complex: Products with their effective discounted price per active event
SELECT p.product_id, p.name AS product_name, p.base_price,
       et.name AS event_name, et.discount, et.discount_type,
       CASE
         WHEN et.discount_type = 'percentage'
           THEN ROUND(p.base_price - (p.base_price * et.discount / 100), 2)
         WHEN et.discount_type = 'fixed'
           THEN ROUND(p.base_price - et.discount, 2)
       END AS discounted_price,
       s.shop_name
FROM event_products ep
JOIN products    p  ON p.product_id = ep.product_id
JOIN event_types et ON et.event_id  = ep.event_id
JOIN shops       s  ON s.shop_id    = ep.shop_id
WHERE et.is_available = 1 AND ep.status = 'active' AND ep.deleted_at IS NULL
ORDER BY s.shop_name, et.name;

-- Q3.3 Complex: Shops with most active promotions and total discount exposure
SELECT s.shop_id, s.shop_name,
       COUNT(DISTINCT et.event_id)       AS active_events,
       COUNT(ep.event_product_id)        AS promoted_products,
       AVG(et.discount)                  AS avg_discount,
       MAX(et.discount)                  AS max_discount
FROM shops s
JOIN event_types    et ON et.shop_id  = s.shop_id AND et.is_available = 1
JOIN event_products ep ON ep.event_id = et.event_id AND ep.status = 'active'
GROUP BY s.shop_id, s.shop_name
ORDER BY active_events DESC;

-- ============================================================
-- FEATURE 4: Order Management
-- ============================================================

-- Q4.1 Customer order history with item count and total
SELECT o.order_id, o.status, o.total_price, o.discount_price, o.subtotal_price,
       o.created_at, s.shop_name,
       COUNT(oi.order_item_id) AS item_count
FROM orders o
JOIN shops s      ON s.shop_id = o.shop_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.customer_id = 1
GROUP BY o.order_id, o.status, o.total_price, o.discount_price,
         o.subtotal_price, o.created_at, s.shop_name
ORDER BY o.created_at DESC;

-- Q4.2 Order detail — items with product info
SELECT o.order_id, o.status, c.name AS customer_name,
       p.name AS product_name, oi.quantities, oi.sold_price,
       (oi.quantities * oi.sold_price) AS line_total
FROM orders o
JOIN customers c  ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p   ON p.product_id  = oi.product_id
WHERE o.order_id = 1;

-- Q4.3 Complex: Shop order summary — revenue by status
SELECT s.shop_name,
       o.status,
       COUNT(o.order_id)    AS order_count,
       SUM(o.subtotal_price) AS total_revenue,
       AVG(o.subtotal_price) AS avg_order_value
FROM orders o
JOIN shops s ON s.shop_id = o.shop_id
GROUP BY s.shop_name, o.status
ORDER BY s.shop_name, total_revenue DESC;

-- Q4.4 Complex: Top selling products across all orders
SELECT p.product_id, p.name AS product_name, s.shop_name,
       SUM(oi.quantities)                    AS total_units_sold,
       SUM(oi.quantities * oi.sold_price)    AS total_revenue,
       COUNT(DISTINCT oi.order_id)           AS orders_count
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN shops    s ON s.shop_id    = p.shop_id
GROUP BY p.product_id, p.name, s.shop_name
ORDER BY total_units_sold DESC
LIMIT 10;

-- Q4.5 Complex: Customers with order frequency, total spend, and last order date
SELECT c.customer_id, c.name AS customer_name, u.email,
       COUNT(o.order_id)          AS total_orders,
       SUM(o.subtotal_price)      AS lifetime_spend,
       AVG(o.subtotal_price)      AS avg_order_value,
       MAX(o.created_at)          AS last_order_date,
       SUM(CASE WHEN o.status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_orders
FROM customers c
JOIN users u  ON u.user_id = c.user_id
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name, u.email
ORDER BY lifetime_spend DESC;

-- ============================================================
-- FEATURE 5: Payment & Transaction Processing
-- ============================================================

-- Q5.1 Transaction summary per order with invoice status
SELECT t.transaction_id, o.order_id, o.status AS order_status,
       t.amount, t.total_amount, t.currency, t.bank_ref_id,
       spm.card_type AS payment_method,
       i.invoice_no, i.status AS invoice_status
FROM transactions t
JOIN orders o                ON o.order_id  = t.order_id
JOIN shop_payment_methods spm ON spm.method_id = t.method_id
LEFT JOIN invoices i         ON i.transaction_id = t.transaction_id
ORDER BY t.transaction_id;

-- Q5.2 Payment intents per transaction with status
SELECT pi.intent_id, t.transaction_id, o.order_id,
       spm.card_type, pi.status AS intent_status,
       pi.expires_at,
       pi.qr_code_data IS NOT NULL AS has_qr
FROM payment_intents pi
JOIN transactions t           ON t.transaction_id = pi.transaction_id
JOIN orders o                 ON o.order_id        = t.order_id
JOIN shop_payment_methods spm ON spm.method_id     = pi.method_id
ORDER BY pi.intent_id;

-- Q5.3 Complex: Platform fee applied per transaction with fee calculation
SELECT t.transaction_id, t.amount, t.total_amount,
       pf.fee_name, pf.fee_type, pf.percentage,
       CASE
         WHEN pf.fee_type = 'percentage'
           THEN ROUND(t.amount * pf.percentage / 100, 2)
         ELSE pf.percentage
       END AS fee_charged,
       (t.total_amount - t.amount) AS actual_fee_diff
FROM transactions t
JOIN platform_fees pf ON pf.id = t.platform_fee_id
ORDER BY t.transaction_id;

-- Q5.4 Complex: Revenue breakdown per shop — gross, fee, net
SELECT s.shop_name,
       COUNT(t.transaction_id)          AS transaction_count,
       SUM(t.amount)                    AS gross_revenue,
       SUM(ROUND(t.amount * pf.percentage / 100, 2)) AS platform_fee_total,
       SUM(t.amount) - SUM(ROUND(t.amount * pf.percentage / 100, 2)) AS net_revenue
FROM transactions t
JOIN shops s         ON s.shop_id = t.shop_id
JOIN platform_fees pf ON pf.id   = t.platform_fee_id
GROUP BY s.shop_name
ORDER BY gross_revenue DESC;

-- Q5.5 Complex: Invoice audit — check sub_total + tax - discount = total_amount
SELECT invoice_id, invoice_no, status,
       sub_total, tax_amount, discount_price, total_amount,
       ROUND(sub_total + tax_amount - discount_price, 2) AS calculated_total,
       CASE
         WHEN ROUND(sub_total + tax_amount - discount_price, 2) = total_amount
           THEN 'OK'
         ELSE 'MISMATCH'
       END AS integrity_check
FROM invoices;

-- ============================================================
-- FEATURE 6: Delivery & Shipment Tracking
-- ============================================================

-- Q6.1 Delivery status per order with recipient info
SELECT o.order_id, o.status AS order_status,
       ods.recipient_name, ods.phone, ods.province,
       ods.status AS delivery_status,
       d.delivery_date
FROM deliveries d
JOIN orders o                    ON o.order_id = d.order_id
JOIN order_delivery_snapshots ods ON ods.id    = d.order_delivery_snapshot_id
ORDER BY o.order_id;

-- Q6.2 Full delivery log timeline per order
SELECT o.order_id, dl.status, dl.location_description, dl.timestamp
FROM delivery_logs dl
JOIN deliveries d ON d.delivery_id = dl.delivery_id
JOIN orders o     ON o.order_id    = d.order_id
ORDER BY o.order_id, dl.timestamp;

-- Q6.3 Complex: Delivery performance — avg steps to deliver per shop
SELECT s.shop_name,
       COUNT(DISTINCT d.delivery_id)  AS total_deliveries,
       COUNT(dl.id)                   AS total_log_entries,
       ROUND(COUNT(dl.id) / COUNT(DISTINCT d.delivery_id), 1) AS avg_steps_per_delivery,
       SUM(CASE WHEN ods.status = 'delivered' THEN 1 ELSE 0 END) AS completed_deliveries,
       SUM(CASE WHEN ods.status = 'failed'    THEN 1 ELSE 0 END) AS failed_deliveries
FROM deliveries d
JOIN orders o                     ON o.order_id = d.order_id
JOIN shops s                      ON s.shop_id  = o.shop_id
JOIN order_delivery_snapshots ods ON ods.id     = d.order_delivery_snapshot_id
LEFT JOIN delivery_logs dl        ON dl.delivery_id = d.delivery_id
GROUP BY s.shop_name;

-- Q6.4 Complex: Orders with delivery address vs current user address (detect changes)
SELECT o.order_id, c.name AS customer_name,
       ods.province AS delivery_province,
       au.province  AS current_province,
       CASE WHEN ods.province != au.province THEN 'ADDRESS CHANGED' ELSE 'SAME' END AS address_status,
       ods.recipient_name, ods.phone
FROM orders o
JOIN customers c                  ON c.customer_id = o.customer_id
JOIN order_delivery_snapshots ods ON ods.order_id  = o.order_id
JOIN users u                      ON u.user_id     = c.user_id
LEFT JOIN address_user au         ON au.address_id = u.address_id;

-- ============================================================
-- FEATURE 7: Notifications
-- ============================================================

-- Q7.1 Unread notifications per user
SELECT u.email, n.type, n.priority, n.title, n.created_at
FROM notifications n
JOIN users u ON u.user_id = n.user_id
WHERE n.is_read = 0
ORDER BY n.priority DESC, n.created_at DESC;

-- Q7.2 Complex: Notification summary per user — unread count by type
SELECT u.email,
       COUNT(n.notification_id)                                          AS total_notifications,
       SUM(CASE WHEN n.is_read = 0 THEN 1 ELSE 0 END)                   AS unread_count,
       SUM(CASE WHEN n.type = 'order'     AND n.is_read = 0 THEN 1 ELSE 0 END) AS unread_orders,
       SUM(CASE WHEN n.type = 'payment'   AND n.is_read = 0 THEN 1 ELSE 0 END) AS unread_payments,
       SUM(CASE WHEN n.type = 'shipment'  AND n.is_read = 0 THEN 1 ELSE 0 END) AS unread_shipments,
       SUM(CASE WHEN n.type = 'promotion' AND n.is_read = 0 THEN 1 ELSE 0 END) AS unread_promos
FROM notifications n
JOIN users u ON u.user_id = n.user_id
GROUP BY u.email
ORDER BY unread_count DESC;

-- ============================================================
-- FEATURE 8: Reports & Analytics
-- ============================================================

-- Q8.1 Shop daily performance summary
SELECT s.shop_name, ds.snapshot_date,
       ds.total_gross, ds.total_profit, ds.order_count,
       ROUND(ds.total_profit / NULLIF(ds.total_gross, 0) * 100, 1) AS profit_margin_pct
FROM daily_snapshots ds
JOIN shops s ON s.shop_id = ds.shop_id
ORDER BY ds.snapshot_date, s.shop_name;

-- Q8.2 Category performance breakdown per shop per day
SELECT s.shop_name, ds.snapshot_date, c.name AS category,
       dcs.cat_gross_revenue, dcs.cat_net_profit, dcs.cat_items_sold
FROM daily_category_snapshots dcs
JOIN daily_snapshots ds ON ds.snapshot_id = dcs.snapshot_id
JOIN categories c       ON c.category_id  = dcs.category_id
JOIN shops s            ON s.shop_id      = ds.shop_id
ORDER BY ds.snapshot_date, s.shop_name, dcs.cat_gross_revenue DESC;

-- Q8.3 Complex: Product-level daily analytics with profit per unit
SELECT s.shop_name, ds.snapshot_date, p.name AS product,
       dps.qty_sold, dps.unit_sale_price, dps.base_cost_price,
       ROUND(dps.unit_sale_price - dps.base_cost_price, 2)          AS profit_per_unit,
       ROUND((dps.unit_sale_price - dps.base_cost_price) * dps.qty_sold, 2) AS total_profit,
       dps.stock_at_midnight
FROM daily_product_snapshots dps
JOIN daily_category_snapshots dcs ON dcs.cat_snap_id = dps.cat_snap_id
JOIN daily_snapshots ds           ON ds.snapshot_id  = dcs.snapshot_id
JOIN products p                   ON p.product_id    = dps.product_id
JOIN shops s                      ON s.shop_id       = ds.shop_id
ORDER BY ds.snapshot_date, total_profit DESC;

-- Q8.4 Complex: Platform revenue trend by date with shop count
SELECT prs.snapshot_date,
       COUNT(prs.platform_snap_id)  AS transaction_count,
       SUM(t.total_amount)          AS gross_platform_revenue,
       SUM(ROUND(t.amount * pf.percentage / 100, 2)) AS fee_collected,
       MAX(prs.active_paying_shops) AS active_shops
FROM platform_revenue_snapshots prs
JOIN transactions t   ON t.transaction_id = prs.transaction_id
JOIN platform_fees pf ON pf.id            = t.platform_fee_id
GROUP BY prs.snapshot_date
ORDER BY prs.snapshot_date;

-- Q8.5 Complex: Rolling 30-day shop revenue (window-style using subquery)
SELECT s.shop_name,
       SUM(ds.total_gross)  AS revenue_last_30_days,
       SUM(ds.total_profit) AS profit_last_30_days,
       SUM(ds.order_count)  AS orders_last_30_days,
       ROUND(SUM(ds.total_profit) / NULLIF(SUM(ds.total_gross), 0) * 100, 1) AS margin_pct
FROM daily_snapshots ds
JOIN shops s ON s.shop_id = ds.shop_id
WHERE ds.snapshot_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY s.shop_name
ORDER BY revenue_last_30_days DESC;

-- ============================================================
-- FEATURE 9: Platform Fee Management
-- ============================================================

-- Q9.1 Active fee rules
SELECT id, fee_name, fee_type, percentage, effective_from, status
FROM platform_fees
WHERE status = 'active'
ORDER BY effective_from DESC;

-- Q9.2 Complex: Fee rule applied to each transaction with effective date validation
SELECT t.transaction_id, t.amount,
       pf.fee_name, pf.fee_type, pf.percentage, pf.effective_from,
       ROUND(t.amount * pf.percentage / 100, 2) AS fee_amount,
       o.created_at AS order_date,
       CASE
         WHEN pf.effective_from <= DATE(o.created_at) THEN 'VALID'
         ELSE 'INVALID - fee not yet effective'
       END AS fee_validity
FROM transactions t
JOIN platform_fees pf ON pf.id    = t.platform_fee_id
JOIN orders o         ON o.order_id = t.order_id
ORDER BY t.transaction_id;

-- Q9.3 Complex: Total platform earnings per fee rule
SELECT pf.fee_name, pf.fee_type, pf.percentage,
       COUNT(t.transaction_id)                              AS transactions_applied,
       SUM(t.amount)                                        AS total_transaction_volume,
       SUM(ROUND(t.amount * pf.percentage / 100, 2))       AS total_fee_earned
FROM platform_fees pf
JOIN transactions t ON t.platform_fee_id = pf.id
GROUP BY pf.fee_name, pf.fee_type, pf.percentage
ORDER BY total_fee_earned DESC;

-- ============================================================
-- BONUS: Cross-feature complex queries
-- ============================================================

-- BQ1: Full order lifecycle — order → payment → delivery → invoice in one view
SELECT o.order_id,
       c.name          AS customer,
       s.shop_name,
       o.status        AS order_status,
       o.subtotal_price,
       spm.card_type   AS payment_method,
       pi.status       AS payment_status,
       i.invoice_no,
       i.status        AS invoice_status,
       ods.status      AS delivery_status,
       d.delivery_date
FROM orders o
JOIN customers c                       ON c.customer_id  = o.customer_id
JOIN shops s                           ON s.shop_id      = o.shop_id
LEFT JOIN transactions t               ON t.order_id     = o.order_id
LEFT JOIN shop_payment_methods spm     ON spm.method_id  = t.method_id
LEFT JOIN payment_intents pi           ON pi.transaction_id = t.transaction_id
LEFT JOIN invoices i                   ON i.transaction_id  = t.transaction_id
LEFT JOIN deliveries d                 ON d.order_id     = o.order_id
LEFT JOIN order_delivery_snapshots ods ON ods.id         = d.order_delivery_snapshot_id
ORDER BY o.order_id;

-- BQ2: Shop health dashboard — products, orders, revenue, active events
SELECT s.shop_id, s.shop_name,
       COUNT(DISTINCT p.product_id)                                    AS total_products,
       SUM(p.quantity)                                                  AS total_stock,
       COUNT(DISTINCT o.order_id)                                       AS total_orders,
       SUM(o.subtotal_price)                                            AS total_revenue,
       COUNT(DISTINCT CASE WHEN o.status = 'delivered' THEN o.order_id END) AS delivered_orders,
       COUNT(DISTINCT et.event_id)                                      AS active_events
FROM shops s
LEFT JOIN products p    ON p.shop_id  = s.shop_id
LEFT JOIN orders o      ON o.shop_id  = s.shop_id
LEFT JOIN event_types et ON et.shop_id = s.shop_id AND et.is_available = 1
WHERE s.is_deleted = 0
GROUP BY s.shop_id, s.shop_name
ORDER BY total_revenue DESC;

-- BQ3: Customer 360 view — profile, orders, spend, notifications
SELECT c.customer_id, c.name, u.email, c.phone_number,
       au.province AS home_province,
       COUNT(DISTINCT o.order_id)                                        AS total_orders,
       SUM(o.subtotal_price)                                             AS total_spend,
       SUM(CASE WHEN o.status = 'cancelled' THEN 1 ELSE 0 END)          AS cancelled,
       COUNT(DISTINCT n.notification_id)                                 AS total_notifications,
       SUM(CASE WHEN n.is_read = 0 THEN 1 ELSE 0 END)                   AS unread_notifications
FROM customers c
JOIN users u ON u.user_id = c.user_id
LEFT JOIN address_user au ON au.address_id = u.address_id
LEFT JOIN orders o        ON o.customer_id = c.customer_id
LEFT JOIN notifications n ON n.user_id     = u.user_id
GROUP BY c.customer_id, c.name, u.email, c.phone_number, au.province;

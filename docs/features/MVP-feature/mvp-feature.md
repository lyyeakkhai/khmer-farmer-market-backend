# Khmer Farmer Market — MVP Feature Spec

## Feature → Module → Database Mapping

| Feature | Module | Table |
|---------|--------|-------|
| Authentication & Roles | `auth` | `users`, `roles` |
| Shop Creation | `shop` | `shops` |
| Product Management | `product` | `products` |
| Event Management | `event` | `events` |
| Discount System | `discount` | `discounts` |
| Payment Methods | `payment` | `payment_methods` |
| Shop Category | `category` | `shop_categories` |
| Global Category | `category` | `global_categories` |
| Delivery Integration | `delivery` | `deliveries` |

---

## 1. Authentication & Roles

**Module:** `auth`

**Actors:**
- Customer
- Seller
- Admin

**Features:**
- Register / Login
- JWT authentication
- Role-based access control (RBAC)

**Rules:**
- New users default to `Customer` role
- A `Customer` can upgrade to `Seller` by creating a shop

---

## 2. Shop Creation

**Module:** `shop`  
**Table:** `shops`

**Description:**  
A user becomes a Seller by creating a shop. This triggers a role upgrade from `Customer` to `Seller`.

**Flow:**
1. User registers as Customer
2. User submits shop information
3. System creates the shop record
4. User role is upgraded to `Seller`

**Data Fields:**
- `name` — Shop name
- `description` — Shop description
- `location` — Physical or regional location

---

## 3. Product Management

**Module:** `product`  
**Table:** `products`

**Actors:** Seller

**Capabilities:**
- Create a product
- Update product details
- Delete a product
- Upload product images
- Set product price

---

## 4. Event Management

**Module:** `event`  
**Table:** `events`

**Purpose:**  
Allow sellers or admins to run promotions and seasonal campaigns.

**Examples:**
- "Khmer New Year Sale"
- Harvest season promotions

---

## 5. Discount System

**Module:** `discount`  
**Table:** `discounts`

**Actors:** Seller

**Capabilities:**
- Set a discount percentage on a product
- Define a start date and end date for the discount

---

## 6. Payment Methods

**Module:** `payment`  
**Table:** `payment_methods`

**Actors:** Seller

**Supported Methods:**
- ABA
- KHQR
- Visa

**System Requirements:**
- Store payment info securely
- Link payment methods to the seller's shop

---

## 7. Shop Category (Seller-level)

**Module:** `category`  
**Table:** `shop_categories`

**Actors:** Seller

**Description:**  
Sellers define their own product groupings within their shop.

**Examples:**
- Fruits
- Vegetables

---

## 8. Global Category (Admin-level)

**Module:** `category`  
**Table:** `global_categories`

**Actors:** Admin

**Description:**  
Admins define platform-wide categories that apply across all shops.

**Examples:**
- Organic Products
- Fresh Food

---

## 9. Delivery Integration

**Module:** `delivery`  
**Table:** `deliveries`

**System Requirements:**
- Calculate delivery cost
- Track delivery status

**Future Scope:**
- Integrate third-party delivery providers

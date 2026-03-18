# Authentication Feature — MVP Spec

## Version

| Field | Value |
|-------|-------|
| Feature | Authentication & Authorization |
| Version | v1.0.0 |
| Status | Draft |
| Module | `auth` |
| Stack | NestJS + JWT + Passport.js |

---

## Vision

Provide a secure, lightweight, and scalable authentication system that supports:

- Email/password registration and login
- Social login via Google and Facebook (OAuth 2.0)
- JWT-based stateless session management
- Role-based access control (RBAC) with three roles: `Customer`, `Seller`, `Admin`

The system must be simple enough for MVP delivery but structured to support future expansion (e.g., phone OTP, Apple login).

---

## Tech Recommendation

For a lightweight OAuth integration in NestJS, the recommended approach is:

**Passport.js** with the following strategies:

| Strategy | Package | Purpose |
|----------|---------|---------|
| Local | `passport-local` | Email + password login |
| JWT | `passport-jwt` | Stateless token validation |
| Google OAuth 2.0 | `passport-google-oauth20` | Google social login |
| Facebook OAuth 2.0 | `passport-facebook` | Facebook social login |

Why Passport.js:
- Native NestJS support via `@nestjs/passport`
- Minimal boilerplate, battle-tested
- Unified strategy interface for all auth methods
- No heavy dependencies or external auth servers needed

---

## Actors

| Actor | Description |
|-------|-------------|
| `Customer` | Default role on registration |
| `Seller` | Upgraded from Customer after shop creation |
| `Admin` | Platform administrator, manually assigned |

---

## User Data Model

Fields required before handoff to the service engineer:

```ts
User {
  id           : UUID          // primary key
  email        : string        // unique, required for local auth
  password     : string | null // hashed (bcrypt), null for OAuth users
  name         : string
  avatar       : string | null // profile picture URL
  role         : enum('customer', 'seller', 'admin')
  provider     : enum('local', 'google', 'facebook')
  providerId   : string | null // OAuth provider's user ID
  isVerified   : boolean       // email verification flag
  refreshToken : string | null // hashed refresh token
  createdAt    : timestamp
  updatedAt    : timestamp
}
```

---

## Token Strategy

| Token | Type | Expiry | Storage |
|-------|------|--------|---------|
| Access Token | JWT (signed HS256) | 15 minutes | Memory / Authorization header |
| Refresh Token | Opaque (hashed in DB) | 7 days | HttpOnly cookie |

- Access token carries: `sub` (userId), `role`, `email`, `iat`, `exp`
- Refresh token is rotated on every use (rotation strategy)
- On logout, refresh token is invalidated in DB

---

## Feature Workflows

### 1. Email / Password Registration

```
Client                        Server
  |                              |
  |-- POST /auth/register ------>|
  |   { name, email, password }  |
  |                              |-- Validate input
  |                              |-- Check email uniqueness
  |                              |-- Hash password (bcrypt, 12 rounds)
  |                              |-- Create user (role: customer)
  |                              |-- Send verification email (future)
  |<-- 201 { message: "ok" } ----|
```

### 2. Email / Password Login

```
Client                        Server
  |                              |
  |-- POST /auth/login --------->|
  |   { email, password }        |
  |                              |-- Find user by email
  |                              |-- Compare password (bcrypt)
  |                              |-- Generate Access Token (15m)
  |                              |-- Generate Refresh Token (7d)
  |                              |-- Hash & store refresh token in DB
  |<-- 200 {                 ----|
  |     accessToken,             |
  |     user: { id, name, role } |
  |   }                          |
  |   Set-Cookie: refreshToken   |
```

### 3. Google OAuth Login

```
Client                        Server                      Google
  |                              |                            |
  |-- GET /auth/google --------->|                            |
  |                              |-- Redirect to Google ----->|
  |                              |                            |-- User consents
  |                              |<-- Authorization code -----|
  |                              |-- Exchange code for token  |
  |                              |-- Fetch user profile       |
  |                              |-- Find or create user      |
  |                              |   (provider: google)       |
  |                              |-- Generate JWT tokens      |
  |<-- Redirect with tokens -----|
```

### 4. Facebook OAuth Login

```
Client                        Server                      Facebook
  |                              |                            |
  |-- GET /auth/facebook ------->|                            |
  |                              |-- Redirect to Facebook --->|
  |                              |                            |-- User consents
  |                              |<-- Authorization code -----|
  |                              |-- Exchange code for token  |
  |                              |-- Fetch user profile       |
  |                              |-- Find or create user      |
  |                              |   (provider: facebook)     |
  |                              |-- Generate JWT tokens      |
  |<-- Redirect with tokens -----|
```

### 5. Token Refresh

```
Client                        Server
  |                              |
  |-- POST /auth/refresh ------->|
  |   Cookie: refreshToken       |
  |                              |-- Validate refresh token
  |                              |-- Compare with hashed token in DB
  |                              |-- Rotate: generate new refresh token
  |                              |-- Update DB with new hashed token
  |<-- 200 { accessToken }   ----|
  |   Set-Cookie: new refresh    |
```

### 6. Logout

```
Client                        Server
  |                              |
  |-- POST /auth/logout -------->|
  |   Cookie: refreshToken       |
  |                              |-- Invalidate refresh token in DB
  |                              |-- Clear cookie
  |<-- 200 { message: "ok" } ----|
```

---

## API Endpoints

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/auth/register` | Email/password registration | No |
| POST | `/auth/login` | Email/password login | No |
| POST | `/auth/refresh` | Refresh access token | No (cookie) |
| POST | `/auth/logout` | Logout and invalidate token | Yes |
| GET | `/auth/google` | Initiate Google OAuth | No |
| GET | `/auth/google/callback` | Google OAuth callback | No |
| GET | `/auth/facebook` | Initiate Facebook OAuth | No |
| GET | `/auth/facebook/callback` | Facebook OAuth callback | No |
| GET | `/auth/me` | Get current user profile | Yes |

---

## Role-Based Access Control

| Role | Permissions |
|------|-------------|
| `customer` | Browse products, place orders, manage own profile |
| `seller` | All customer permissions + manage shop, products, discounts |
| `admin` | Full platform access, manage global categories, users |

Guards applied via NestJS `@Roles()` decorator + `RolesGuard`.

---

## Security Rules

- Passwords hashed with `bcrypt` (12 salt rounds)
- Refresh tokens stored as hashed values (never plain text)
- Access tokens are short-lived (15 min) to limit exposure
- HttpOnly cookies for refresh tokens (XSS protection)
- Rate limiting on `/auth/login` and `/auth/register`
- OAuth state parameter validated to prevent CSRF

---

## Out of Scope (v1.0.0)

- Phone number / OTP login
- Apple Sign-In
- Two-factor authentication (2FA)
- Email verification flow (deferred to v1.1.0)

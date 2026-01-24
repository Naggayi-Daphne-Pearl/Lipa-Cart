# Authentication Flow - Visual Diagram

## Where to Insert Authentication in Your Flowchart

```
                                CUSTOMER
┌───────────────────────────────────────────────────────────────┐
│                                                               │
│   ┌─────────┐                                                 │
│   │  START  │                                                 │
│   └────┬────┘                                                 │
│        │                                                      │
│        ▼                                                      │
│   ┌─────────────────────────┐                                │
│   │  Browse/Search Items    │  ← No Auth Required            │
│   │  Create Shopping        │                                │
│   └────────────┬────────────┘                                │
│                │                                              │
│                ▼                                              │
│   ┌─────────────────────────┐                                │
│   │  Add items to list      │  ← No Auth Required            │
│   └────────────┬────────────┘                                │
│                │                                              │
│                ▼                                              │
│   ┌─────────────────────────┐                                │
│   │  Review Cart            │  ← No Auth Required            │
│   └────────────┬────────────┘                                │
│                │                                              │
│                │                                              │
│   ╔════════════▼═══════════════════════════════════╗         │
│   ║  🔐 AUTHENTICATION CHECKPOINT (NEW)            ║         │
│   ╚════════════════════════════════════════════════╝         │
│                │                                              │
│                ▼                                              │
│        ╱─────────────╲                                        │
│       ╱   Is User     ╲                                       │
│      │  Authenticated? │ ← Decision Point                     │
│       ╲               ╱                                       │
│        ╲─────────────╱                                        │
│          │         │                                          │
│      YES │         │ NO                                       │
│          │         │                                          │
│          │         └──────┐                                   │
│          │                │                                   │
│          │                ▼                                   │
│          │     ┌─────────────────────────┐                   │
│          │     │  📱 Login Screen        │  ← NEW PAGE       │
│          │     │  Enter Phone Number     │                   │
│          │     └──────────┬──────────────┘                   │
│          │                │                                   │
│          │                │ (Send OTP)                        │
│          │                │                                   │
│          │                ▼                                   │
│          │     ┌─────────────────────────┐                   │
│          │     │  🔢 OTP Screen          │  ← NEW PAGE       │
│          │     │  Enter 6-digit Code     │                   │
│          │     └──────────┬──────────────┘                   │
│          │                │                                   │
│          │                │ (Verify OTP)                      │
│          │                │                                   │
│          └────────────────┴──────┐                            │
│                                   │                           │
│                                   ▼                           │
│                      ┌─────────────────────────┐             │
│                      │  Select Address &       │ ← Auth Req  │
│                      │  Payment                │             │
│                      └──────────┬──────────────┘             │
│                                 │                             │
│                                 ▼                             │
│                      ┌─────────────────────────┐             │
│                      │  Place Order            │             │
│                      └──────────┬──────────────┘             │
│                                 │                             │
└─────────────────────────────────┼─────────────────────────────┘
                                  │
                                  ▼
                    (Continue to SYSTEM section...)
```

---

## Summary of Changes

### Pages to Add to Your Flowchart:

1. **Decision Diamond**: "Is User Authenticated?"
   - Position: Between "Review Cart" and "Select Address & Payment"
   - Type: Decision/Conditional box (diamond shape)

2. **Login Screen** (NEW PAGE)
   - Shows: Phone number input field
   - Action: User enters phone number, clicks Continue
   - Backend: System sends OTP to phone number

3. **OTP Screen** (NEW PAGE)
   - Shows: 6-digit OTP input field
   - Action: User enters OTP code received via SMS
   - Backend: System verifies OTP
   - On Success: User is authenticated → proceed to checkout
   - On Failure: Show error, allow retry

### Flow Paths:

**Path 1: Already Authenticated User**
```
Review Cart → [Check Auth] → YES → Select Address & Payment → Place Order
```

**Path 2: Guest User (Not Authenticated)**
```
Review Cart → [Check Auth] → NO → Login Screen → OTP Screen → Select Address & Payment → Place Order
```

---

## Color Coding Suggestion for Flowchart:

- **Green Boxes**: No authentication required (Browse, Add to Cart, Review Cart)
- **Orange Boxes**: Authentication checkpoint and auth screens
- **Red Boxes**: Authentication required (Select Address, Place Order, onwards)

---

## Notes:

- The authentication flow seamlessly redirects users back to checkout after successful login
- Cart contents are preserved during the authentication process
- This is a one-time authentication - once logged in, users can place multiple orders
- The demo OTP code is: `123456`

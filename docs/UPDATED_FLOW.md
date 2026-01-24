# Updated LipaCart Flow with Authentication

## Flow 1: Complete Order Journey (End-to-End) - Updated

### CUSTOMER SECTION (Updated)

1. **START**
2. **Browse/Search Items/Create Shopping** (No authentication required)
3. **Add items to list** (No authentication required)
4. **Review Cart** (No authentication required)

### AUTHENTICATION CHECKPOINT (NEW)

5. **Check Authentication Status** (Decision Point)
   - **IF User is Authenticated** → Go to Step 8
   - **IF User is NOT Authenticated** → Continue to Step 6

6. **Sign In/Login Screen**
   - Customer enters phone number
   - System sends OTP

7. **OTP Verification Screen**
   - Customer enters 6-digit OTP code
   - System verifies OTP
   - **IF OTP is Valid** → User is authenticated → Continue to Step 8
   - **IF OTP is Invalid** → Return to Step 7 (retry OTP)

### CHECKOUT FLOW (Continues after authentication)

8. **Select Address & Payment**
   - User must be authenticated to reach this step
   - Select delivery address
   - Choose payment method

9. **Place Order**
   - Confirm order details
   - Submit order

### SYSTEM SECTION

10. **Payment Processing**
11. **Create Order**
12. **Assign Shopper at the Market**
13. **Send Notification**

### SHOPPER SECTION

14. **Receive Order**
15. **Accept Order**
16. **Shop for Items**
17. **Enter Prices**
18. **Complete Shopping**
19. **Mark Ready**

### RIDER SECTION

20. **Receives Requests**
21. **Accepts Requests**
22. **Collect Package**
23. **Deliver Package**
24. **Confirm Delivery**

### SYSTEM & CUSTOMER (Final Steps)

25. **Update Order Status**
26. **Confirms order with code**
27. **END**

---

## Visual Flow Update Instructions

To update your flowchart image:

### Add these new boxes in the CUSTOMER lane:

**After "Review Cart" box, add:**

```
┌─────────────────────────┐
│  Check if Authenticated │ (Diamond/Decision shape)
└─────────────────────────┘
         │
         ├─── YES ──────────────────────┐
         │                              │
         └─── NO ───┐                   │
                    ▼                   │
         ┌─────────────────────────┐   │
         │   Sign In/Login Screen  │   │
         │   (Enter Phone Number)  │   │
         └─────────────────────────┘   │
                    │                   │
                    ▼                   │
         ┌─────────────────────────┐   │
         │   OTP Verification      │   │
         │   (Enter 6-digit code)  │   │
         └─────────────────────────┘   │
                    │                   │
                    └───────────────────┤
                                        ▼
                         ┌─────────────────────────┐
                         │ Select Address & Payment│
                         └─────────────────────────┘
```

### Key Points:

1. **Guest Shopping**: Steps 2-4 (Browse → Add → Review) do NOT require authentication
2. **Authentication Gate**: After "Review Cart", there's a decision point
3. **Two Paths**:
   - **Authenticated**: Direct to "Select Address & Payment"
   - **Not Authenticated**: Through Login → OTP → then to "Select Address & Payment"
4. **Post-Authentication**: Everything from "Select Address & Payment" onwards requires authentication

---

## Implementation Details

### Authentication Screens Location:
- **Login Screen**: `lib/screens/auth/login_screen.dart`
- **OTP Screen**: `lib/screens/auth/otp_screen.dart`

### Logic Implementation:
- **Cart Screen**: `lib/screens/cart/cart_screen.dart:14` (Line 14 contains the auth check logic)

### Flow Control:
- When user clicks "Proceed to Checkout" in Cart Screen
- System checks `authProvider.isAuthenticated`
- Routes accordingly with return route parameter for seamless flow

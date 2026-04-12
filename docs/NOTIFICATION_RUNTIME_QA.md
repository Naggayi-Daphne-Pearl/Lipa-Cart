# Notification Runtime QA

## Purpose

Validate notification behavior across app states (foreground, background, terminated) on mobile and web, and confirm routing consistency from payload `data.route`.

## Prerequisites

- Backend running with Firebase credentials configured.
- Frontend running on at least:
  - Android or iOS device/emulator
  - Web (Chrome)
- Test users:
  - Customer
  - Shopper
  - Rider
  - Admin

## Core Checks

1. Foreground behavior
- Keep app open and active.
- Trigger each notification category:
  - `order_status`
  - `new_task`
  - `new_delivery`
  - `substitute_suggestion`
  - `substitute_response`
  - `promo`
  - `system`
- Expected:
  - Local/system notification is shown or in-app equivalent behavior occurs.
  - Inbox count increments.
  - Entry appears in inbox with correct type icon/color.

2. Background behavior
- Put app in background.
- Trigger the same categories.
- Tap notification.
- Expected:
  - App opens to route from `data.route`.
  - If no `data.route`, role-based fallback route is used.

3. Terminated behavior
- Kill app process.
- Trigger notification.
- Tap notification from tray.
- Expected:
  - App cold-starts and navigates correctly using initial message payload.

4. Web deep link behavior
- Receive notification in web app.
- Open route from notification payload.
- Reload page on destination.
- Expected:
  - Route remains valid after reload for customer/shopper/rider/admin.

5. Ownership and read state
- Verify user A cannot mark user B notifications read.
- Verify `read-all` only affects authenticated user.
- Verify unread badge decrements after opening inbox and marking read.

## Coverage Map

Current backend producers:

- `order_status`: order lifecycle status updates.
- `new_task`: shopper task availability fanout.
- `new_delivery`: rider delivery availability fanout.
- `substitute_suggestion`: shopper substitution proposals.
- `substitute_response`: customer approval/rejection responses.
- `promo`: admin promo sends (`/api/notifications/admin/send-promo`).
- `system`: admin system sends (`/api/notifications/admin/send-system`).

## Suggested Execution Command Set

Backend:

```bash
cd Lipa-Cart-Backend
npm run check:types
```

Frontend static checks:

```bash
cd Lipa-Cart
flutter analyze lib/services/notification_service.dart lib/providers/auth_provider.dart lib/screens/notifications/notification_inbox_screen.dart lib/screens/admin/admin_shell.dart lib/screens/shopper/shopper_home_screen.dart lib/screens/rider/rider_home_screen.dart
```

## Sign-off Template

- Date:
- Tester:
- Platform(s):
- Roles tested:
- Categories tested:
- Pass/Fail per scenario:
- Notes / defects:

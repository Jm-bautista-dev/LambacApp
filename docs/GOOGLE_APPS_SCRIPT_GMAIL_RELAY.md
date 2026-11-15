# Google Apps Script Gmail Relay — Deployment & Verification Guide

## Purpose
Ensures that Customer Registration OTP emails are dynamically and strictly routed to the **customer's email address** entered in the registration form, while the developer's authorized Gmail account (`jmbautistaa0428@gmail.com`) acts solely as the secure SMTP sender/relay.

---

## 1. Updating the Active Apps Script Deployment

1. Open [Google Apps Script Dashboard](https://script.google.com).
2. Sign in with the relay sender account: `jmbautistaa0428@gmail.com`.
3. Locate the existing project: **Lambac Email Gateway** (or the project corresponding to deployment ID `AKfycbySs5fu20uioslsQ9w1n2i4VhFZrMKkfn68e8q28_Dr0KXn2g7s8tqMDwU3lJg_GSg`).
4. Replace the contents of the main script (`Code.gs`) with the updated source code located at:
   [`scripts/google_apps_script_gmail_relay.js`](file:///c:/Users/Admin/OneDrive/Desktop/LambacApp/scripts/google_apps_script_gmail_relay.js)
5. Click **Deploy** > **Manage deployments**.
6. Click the **Edit (pencil)** icon on the active Web App deployment.
7. Under **Version**, select **New version**.
8. Verify configuration:
   - **Execute as**: `Me (jmbautistaa0428@gmail.com)`
   - **Who has access**: `Anyone` (required so the Flutter mobile & web app can invoke the gateway)
9. Click **Deploy**.

---

## 2. API Contract & Payload Specification

### Endpoint
`https://script.google.com/macros/s/AKfycbySs5fu20uioslsQ9w1n2i4VhFZrMKkfn68e8q28_Dr0KXn2g7s8tqMDwU3lJg_GSg/exec`

### Supported Methods
- **POST** (Primary): Accepts `application/json` or `application/x-www-form-urlencoded`.
- **GET** (Fallback): Accepts URL query parameters.

### Request Payload Keys
| Key | Type | Description |
| :--- | :--- | :--- |
| `recipientEmail` | String | **Required**. Customer's email entered into the registration form. |
| `to` | String | Equivalent to `recipientEmail` (for backwards compatibility). |
| `otp` | String | **Required**. 6-digit numeric OTP code. |
| `action` | String | `registration_otp` or `login_otp`. |
| `name` / `recipientName` | String | Optional. Customer's full name. |
| `subject` | String | Optional. Custom branded email subject. |
| `html` | String | Optional. Full responsive HTML template. |

### Success Response
```json
{
  "status": "success",
  "recipient": "e•••••••e@gmail.com",
  "action": "registration_otp",
  "dispatchedAt": "2026-11-06T15:45:00.000Z"
}
```

### Error Responses
- Missing / invalid recipient:
  ```json
  {"status": "error", "code": "MISSING_RECIPIENT", "message": "..."}
  ```
- Missing / non-6-digit OTP:
  ```json
  {"status": "error", "code": "INVALID_OTP_FORMAT", "message": "..."}
  ```
- Gmail quota exceeded:
  ```json
  {"status": "error", "code": "GMAIL_QUOTA_EXCEEDED", "message": "..."}
  ```


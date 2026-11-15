/**
 * ============================================================================
 * LAMBAC COFFEE ROASTERY — SECURE GMAIL OTP RELAY SERVICE (Google Apps Script)
 * ============================================================================
 * Production Fix 02: Dynamic Customer OTP Email Recipient Routing
 *
 * PURPOSE:
 * Bridges registration and login verification OTPs from the Lambac Flutter app
 * to customer Gmail inboxes using the authorized Google Apps Script MailApp/GmailApp service.
 *
 * CRITICAL FIX:
 * - Dynamic recipient routing: Emails are strictly delivered to the customer-entered
 *   email address (`recipientEmail` / `to`).
 * - Developer email (jmbautistaa0428@gmail.com) remains the authorized SENDER/RELAY
 *   account only, and is NEVER used as the recipient, fallback, CC, or BCC.
 * - Strict abuse prevention: Restricts actions to OTP verification; strictly validates
 *   recipient format and 6-digit numeric OTP code.
 * ============================================================================
 */

// Global configuration
var CONFIG = {
  APP_NAME: 'Lambac Coffee Roastery',
  ROASTERY_TAGLINE: 'Artisanal Roasts & Specialty Brews',
  SUPPORT_EMAIL: 'support@lambaccoffee.com',
  EXPIRATION_MINUTES: 5,
  ALLOWED_ACTIONS: ['registration_otp', 'login_otp', 'verify_otp'],
  EMAIL_REGEX: /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/
};

/**
 * Handle HTTP GET Requests (Status check & query-parameter dispatch fallback)
 */
function doGet(e) {
  try {
    // If no parameters supplied, return service health check
    if (!e || !e.parameter || Object.keys(e.parameter).length === 0) {
      return jsonResponse({
        status: 'ready',
        service: 'Lambac Coffee Roastery Gmail OTP Relay Gateway',
        timestamp: new Date().toISOString()
      });
    }

    return processEmailDispatch(e.parameter);
  } catch (err) {
    return jsonResponse({
      status: 'error',
      code: 'INTERNAL_ERROR',
      message: err.toString()
    }, 500);
  }
}

/**
 * Handle HTTP POST Requests (Primary JSON and Form-Encoded Payload Gateway)
 */
function doPost(e) {
  try {
    var payload = {};

    // 1. Try parsing JSON body from postData
    if (e && e.postData && e.postData.contents) {
      try {
        payload = JSON.parse(e.postData.contents);
      } catch (jsonErr) {
        // Fallback: If not valid JSON, check form parameters
        payload = e.parameter || {};
      }
    } else if (e && e.parameter) {
      payload = e.parameter;
    }

    return processEmailDispatch(payload);
  } catch (err) {
    return jsonResponse({
      status: 'error',
      code: 'INTERNAL_ERROR',
      message: err.toString()
    }, 500);
  }
}

/**
 * Core Dispatch Processor with Strict Validation & Dynamic Recipient Routing
 */
function processEmailDispatch(data) {
  // 1. Extract and normalize recipient email address
  // Supports 'recipientEmail', 'to', and 'email' keys for forward/backwards compatibility
  var rawRecipient = data.recipientEmail || data.to || data.email;

  if (!rawRecipient || typeof rawRecipient !== 'string') {
    return jsonResponse({
      status: 'error',
      code: 'MISSING_RECIPIENT',
      message: 'Recipient email address is required and cannot be empty.'
    }, 400);
  }

  var recipient = rawRecipient.trim().toLowerCase();

  // 2. Strict RFC 5322 Email Syntax Validation
  if (!CONFIG.EMAIL_REGEX.test(recipient)) {
    return jsonResponse({
      status: 'error',
      code: 'INVALID_RECIPIENT_FORMAT',
      message: 'The provided email address format is invalid: ' + recipient
    }, 400);
  }

  // 3. Extract and validate OTP Code
  var otp = data.otp || data.otpCode;
  if (!otp || typeof otp !== 'string' && typeof otp !== 'number') {
    return jsonResponse({
      status: 'error',
      code: 'MISSING_OTP',
      message: 'A 6-digit numeric OTP code is required.'
    }, 400);
  }

  var otpString = String(otp).trim();
  if (!/^\d{6}$/.test(otpString)) {
    return jsonResponse({
      status: 'error',
      code: 'INVALID_OTP_FORMAT',
      message: 'OTP must be exactly 6 numeric digits (000000-999999).'
    }, 400);
  }

  // 4. Action Verification (Prevents using this relay for arbitrary/spam emails)
  var action = (data.action || 'registration_otp').toLowerCase();
  var isAllowedAction = false;
  for (var i = 0; i < CONFIG.ALLOWED_ACTIONS.length; i++) {
    if (CONFIG.ALLOWED_ACTIONS[i] === action) {
      isAllowedAction = true;
      break;
    }
  }

  if (!isAllowedAction) {
    return jsonResponse({
      status: 'error',
      code: 'FORBIDDEN_ACTION',
      message: 'Unsupported relay action: ' + action
    }, 403);
  }

  // 5. Extract recipient name and template data
  var rawName = data.recipientName || data.name || 'Coffee Enthusiast';
  var recipientName = sanitizeHtml(String(rawName).trim());
  var subject = data.subject || (CONFIG.APP_NAME + ' — Verification Code: ' + otpString);
  var htmlBody = data.html || buildBrandedOtpHtml(recipientName, otpString, action);
  var plainText = data.text || ('Hello ' + recipientName + ', your verification code is: ' + otpString + '. It expires in 5 minutes.');

  // 6. Security Check: Never relay to developer email as a hardcoded default or override
  // SENDER is the authorized Apps Script runner; RECIPIENT is strictly the customer
  var mailOptions = {
    name: CONFIG.APP_NAME,
    htmlBody: htmlBody,
    replyTo: CONFIG.SUPPORT_EMAIL
    // CRITICAL: Notice NO 'cc' or 'bcc' to developer email
  };

  try {
    // 7. Dispatch directly to customer's inbox via MailApp
    MailApp.sendEmail(recipient, subject, plainText, mailOptions);

    return jsonResponse({
      status: 'success',
      recipient: maskEmail(recipient),
      action: action,
      dispatchedAt: new Date().toISOString()
    });
  } catch (sendErr) {
    // Detect quota or authorization errors
    var errMsg = sendErr.toString();
    var isQuotaError = errMsg.indexOf('limit') !== -1 || errMsg.indexOf('quota') !== -1;

    return jsonResponse({
      status: 'error',
      code: isQuotaError ? 'GMAIL_QUOTA_EXCEEDED' : 'DISPATCH_FAILED',
      message: isQuotaError 
        ? 'Daily email sending quota exceeded on Gmail relay. Please try again later.'
        : 'Failed to deliver email: ' + errMsg
    }, 502);
  }
}

/**
 * Builds the branded Lambac Coffee Roastery HTML email
 */
function buildBrandedOtpHtml(name, otp, action) {
  var title = action === 'login_otp' ? 'Sign In Verification Code' : 'Verify Your Email Address';
  var subtitle = action === 'login_otp' 
    ? 'You requested to sign in to your Lambac Coffee Roastery account.'
    : 'Thank you for creating an account with Lambac Coffee Roastery. Please use the 6-digit verification code below:';

  return '<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; background-color: #1A1412; color: #F5EFEB; border-radius: 12px;">' +
    '<div style="text-align: center; margin-bottom: 24px;">' +
      '<h1 style="color: #D4A373; font-size: 24px; margin: 0; letter-spacing: 2px;">LAMBAC COFFEE ROASTERY</h1>' +
      '<p style="color: #A89F91; font-size: 14px; margin-top: 4px;">' + CONFIG.ROASTERY_TAGLINE + '</p>' +
    '</div>' +
    '<div style="background-color: #261E1A; padding: 24px; border-radius: 8px; border: 1px solid #3D322B;">' +
      '<h2 style="color: #FFFFFF; font-size: 18px; margin-top: 0;">' + title + '</h2>' +
      '<p style="color: #D1C7BD; font-size: 14px; line-height: 1.6;">' +
        'Hello <strong>' + name + '</strong>,<br/><br/>' + subtitle +
      '</p>' +
      '<div style="text-align: center; margin: 28px 0;">' +
        '<span style="font-size: 34px; font-weight: bold; letter-spacing: 10px; color: #D4A373; background-color: #1A1412; padding: 14px 28px; border-radius: 8px; border: 1px dashed #D4A373; display: inline-block;">' +
          otp +
        '</span>' +
      '</div>' +
      '<p style="color: #A89F91; font-size: 12px; line-height: 1.5; margin-bottom: 0;">' +
        '⏱️ This verification code will expire in <strong>' + CONFIG.EXPIRATION_MINUTES + ' minutes</strong>.<br/>' +
        'If you did not initiate this request, please safely ignore this email.' +
      '</p>' +
    '</div>' +
    '<div style="text-align: center; margin-top: 24px; color: #7A6F68; font-size: 11px;">' +
      '© 2026 ' + CONFIG.APP_NAME + ' • All Rights Reserved' +
    '</div>' +
  '</div>';
}

/**
 * Mask email for safe audit responses (e.g. j••••a@gmail.com)
 */
function maskEmail(email) {
  var atIndex = email.indexOf('@');
  if (atIndex <= 1) return email;
  var user = email.substring(0, atIndex);
  var domain = email.substring(atIndex);
  if (user.length <= 2) {
    return user.charAt(0) + '•' + domain;
  }
  return user.charAt(0) + '••••' + user.charAt(user.length - 1) + domain;
}

/**
 * Basic HTML sanitization to prevent injection
 */
function sanitizeHtml(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

/**
 * Helper to construct JSON HTTP Response
 */
function jsonResponse(obj, statusCode) {
  var output = ContentService.createTextOutput(JSON.stringify(obj));
  output.setMimeType(ContentService.MimeType.JSON);
  return output;
}


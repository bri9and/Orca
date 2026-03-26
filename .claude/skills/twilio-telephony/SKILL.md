---
name: twilio-telephony
description: Enforce idempotent, webhook-driven Twilio call flows — TwiML, call state, signature validation. Use when implementing or modifying telephony features.
---

# Twilio Telephony

Implement reliable telephony flows using Twilio.

## Rules

- All call handling must be webhook-driven
- Never trust client-side call state
- Treat every webhook as potentially retried or duplicated
- Design flows to be idempotent

## Call Handling

- Incoming calls handled via webhook (TwiML or API response)
- Outbound calls initiated server-side only
- Always log call SID and key metadata
- Use status callbacks to track call lifecycle

## Reliability

- Handle retries and duplicate webhooks safely
- Do not assume order of status events
- Implement fallback logic for failed calls
- Store call SID to deduplicate events

## State Management

- Track call state server-side
- Do not rely on Twilio as sole state store
- Sync events from webhooks into your system
- Use idempotency keys for outbound API calls

## Security

- Validate Twilio webhook signatures with `twilio.validateRequest()`
- Do not expose internal endpoints publicly without validation
- Never trust inbound request data without verification
- Restrict webhook endpoints to Twilio IP ranges when possible

## Anti-Patterns (block these)

- Handling call logic in frontend
- Ignoring webhook retries
- Not validating signatures
- Assuming single execution of events
- Polling Twilio API instead of using webhooks

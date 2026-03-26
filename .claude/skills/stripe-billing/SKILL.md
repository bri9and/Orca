---
name: stripe-billing
description: Enforce webhook-driven Stripe billing correctness — subscriptions, checkout, idempotent event handling. Use when implementing or modifying payment flows.
---

# Stripe Billing

Implement and manage Stripe billing safely and correctly.

## Rules

- Use Stripe Checkout unless custom flow is required
- Never trust client-side payment state — always verify server-side
- All billing logic must be handled via webhooks
- Validate webhook signatures before processing

## Subscriptions

- Use Stripe as source of truth for subscription status
- Do not store derived billing state without syncing from Stripe
- Handle lifecycle events:
  - `checkout.session.completed`
  - `invoice.paid`
  - `invoice.payment_failed`
  - `customer.subscription.updated`
  - `customer.subscription.deleted`

## Webhooks

- Must be idempotent — same event processed twice = same result
- Must verify signature with `stripe.webhooks.constructEvent()`
- Must handle retries safely
- Never assume single delivery
- Store event ID to deduplicate

## Data Handling

- Store Stripe IDs (`customer_id`, `subscription_id`, `price_id`)
- Do not store sensitive payment details (card numbers, CVV)
- Sync local state from webhook events, not API polling

## Anti-Patterns (block these)

- Trusting frontend for payment success
- Missing webhook signature validation
- Not handling failed payments
- Creating duplicate subscriptions
- Storing card details locally

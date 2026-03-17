# Webhooks

Manages webhook subscriptions with Shopify and processes incoming webhook notifications for order creation and bulk operation completion events.

## Quick reference

- **Entry point(s)**: `Codeunits/ShpfyWebhooksMgt.Codeunit.al`, `Codeunits/ShpfyWebhookNotification.Codeunit.al`
- **Key patterns**: BC Webhook Subscription table integration, TaskScheduler for async processing, cross-company webhook sharing

## Structure

- Codeunits (4): WebhooksMgt (registration, enable/disable, notification routing), WebhookNotification (notification processing), WebhooksAPI (Shopify API calls), DeleteWebhookSubs
- Enums (1): WebhookTopic (ORDERS_CREATE, BULK_OPERATIONS_FINISH)

## Key concepts

- Two supported webhook topics: `ORDERS_CREATE` (triggers order sync) and `BULK_OPERATIONS_FINISH` (notifies bulk operation completion)
- `EnableWebhook` registers a webhook with Shopify, creates a BC `Webhook Subscription` record, and handles user ID assignment for the notification run-as context
- Webhook notifications arrive via the BC `Webhook Notification` table's OnAfterInsert event; the handler iterates all companies and schedules a background task via `TaskScheduler.CreateTask`
- Order created notifications check for existing ready job queue entries to avoid duplicate order sync runs
- Webhooks are shared across shops with the same Shopify URL; disabling a webhook checks all companies and shops before actually deleting the Shopify subscription
- Company deletion automatically disables all webhooks for shops in that company

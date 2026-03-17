# Webhooks

Event subscription management and incoming webhook processing. Handles registration of webhooks with Shopify and dispatching notifications to the correct BC company and shop.

## How it works

`ShpfyWebhooksMgt.Codeunit.al` is the central hub. When a `Webhook Notification` record is inserted, the `HandleOnWebhookNotificationInsert` event subscriber iterates over all BC companies and creates a `TaskScheduler` task for each, running `ShpfyWebhookNotification.Codeunit.al` in that company's context. The notification codeunit then finds all enabled shops matching the webhook's shop domain (reconstructed as `https://{SubscriptionID}.myshopify.com/`) and dispatches based on the resource type name -- `ORDERS_CREATE` triggers an order sync, `BULK_OPERATIONS_FINISH` processes the bulk operation result.

Webhook registration uses `ShpfyWebhooksAPI.Codeunit.al` to create subscriptions via GraphQL. Before creating a new subscription, the existing one (if any) is deleted both locally and in Shopify. The local `Webhook Subscription` record uses the shop domain as the subscription ID and the webhook topic as the endpoint. Disabling a webhook is multi-company aware: before deleting the Shopify subscription, it checks all companies for other shops with the same URL that still have the webhook enabled, and if found, transfers ownership of the local subscription record to that company instead of deleting it.

## Things to know

- Webhooks are shared across companies -- a single Shopify webhook subscription serves all BC companies that have a shop with the matching Shopify URL. The `Company Name` on `Webhook Subscription` indicates the "owning" company, but all companies process the notification.
- Each notification creates one `TaskScheduler` task per company, regardless of whether that company has a matching shop. The task's codeunit exits early if no enabled shop matches the domain.
- Order-created webhook processing is deduplicated: before scheduling a new sync, it checks for existing `Ready`-state job queue entries for the same shop filter and skips if one exists.
- The `Run Notification As` user ID on the webhook subscription determines which user context the webhook tasks execute under. Changing the user on one shop propagates to all other shops with the same URL via `ChangePrevWebhookUserId`.
- Company deletion triggers automatic webhook cleanup -- the `OnBeforeDeleteEvent` subscriber on the `Company` table disables all webhooks for shops in the deleted company, but skips cleanup if the tenant license state is Suspended, Deleted, or LockedOut.

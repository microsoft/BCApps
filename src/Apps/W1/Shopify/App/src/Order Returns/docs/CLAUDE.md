# Order Returns

Part of [Shopify Connector](../../CLAUDE.md).

Tracks customer returns of physical goods, including return reasons, status, and quantities.

## AL objects

| Type | Name | Purpose |
|------|------|---------|
| Table | Shpfy Return Header (30147) | Return request header |
| Table | Shpfy Return Line (30141) | Return line items |
| Codeunit | Shpfy Returns API (30172) | GraphQL operations for returns |
| Codeunit | Shpfy Return Enum Convertor (30173) | Converts Shopify return enums to BC enums |
| Enum | Shpfy Return Status (30143) | Return workflow status (Open, Closed, Cancelled, etc.) |
| Enum | Shpfy Order Return Status (30144) | Order-level return status |
| Enum | Shpfy Return Decline Reason (30145) | Why return was declined |
| Enum | Shpfy Return Reason (30146) | Why customer is returning item |
| Enum | Shpfy Return Line Type (30147) | Type of return line |
| Page | Shpfy Returns (30147) | List of returns |
| Page | Shpfy Return (30148) | Return details card |
| Page | Shpfy Return Lines (30149) | Return line subpage |

## Key concepts

- **Return**: Customer initiates return for delivered items; Shopify creates return record with return lines.
- **Return status**: Workflow states include Open (pending approval), Requested (waiting for items), Inspection (items received, being checked), Closed (completed), Cancelled, Declined.
- **Return reason**: Customer-provided reason (Unwanted, Size Too Small, Size Too Large, Defective, Style, Color, Wrong Item, Other).
- **Return decline**: Merchant can decline return with reason (Final Sale, Other, Product Not As Described, etc.) and optional note.
- **Return lines**: Track which order lines are being returned, quantity, weight, and whether they can be refunded or restocked.
- **Relationship to refunds**: Returns track physical goods; refunds track money. A return can trigger a refund, but refunds can also occur without returns (e.g., discount adjustment).
- **Import control**: Shop setting `Return and Refund Process` determines if returns are imported (Auto Create Credit Memo and Import Only both import; other modes may skip).

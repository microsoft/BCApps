#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;

using Microsoft.Purchases.History;

/// <summary>
/// Query to get the e-document lines sorted by the receipt number that they have assigned
/// </summary>
query 6100 "E-Doc. Line by Receipt"
{
    Access = Internal;
    ObsoleteState = Pending;
    ObsoleteReason = 'No longer used; e-document invoice lines are no longer grouped by receipt number when creating the purchase invoice.';
    ObsoleteTag = '29.0';
    OrderBy = ascending(ReceiptNo);
    InherentEntitlements = X;
    InherentPermissions = X;

    elements
    {
        dataitem(EDocumentPurchaseLine; "E-Document Purchase Line")
        {
            column(SystemId; SystemId)
            {
            }
            column(EDocumentEntryNo; "E-Document Entry No.")
            {
            }
            dataitem(EDocPurchaseLinePOMatch; "E-Doc. Purchase Line PO Match")
            {
                DataItemLink = "E-Doc. Purchase Line SystemId" = EDocumentPurchaseLine.SystemId;
                SqlJoinType = LeftOuterJoin;
                column(PurchaseLineSystemId; "Purchase Line SystemId")
                {
                }
                column(ReceiptLineSystemId; "Receipt Line SystemId")
                {
                }
                dataitem(PurchRcptLine; "Purch. Rcpt. Line")
                {
                    DataItemLink = SystemId = EDocPurchaseLinePOMatch."Receipt Line SystemId";
                    column(ReceiptNo; "Document No.")
                    {
                    }
                }
            }
        }
    }
}
#endif
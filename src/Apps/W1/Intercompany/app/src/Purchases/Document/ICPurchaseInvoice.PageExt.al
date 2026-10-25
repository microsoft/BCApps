// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Intercompany;

/// <summary>
/// Extends Purchase Invoice with Intercompany-specific actions.
/// Adds the Reject IC Purchase Invoice action and tracks whether the current invoice is incoming IC.
/// Shows warnings for duplicate intercompany documents when the page opens.
/// </summary>
pageextension 8456 ICPurchaseInvoice extends "Purchase Invoice"
{
    actions
    {
        addafter(Reopen)
        {
            action("Reject IC Purchase Invoice")
            {
                ApplicationArea = Intercompany;
                Caption = 'Reject IC Purchase Invoice';
                Enabled = RejectICPurchaseInvoiceEnabled;
                Image = Cancel;
                ToolTip = 'Deletes the invoice and sends the rejection to the company that created it.';

                trigger OnAction()
                var
                    ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
                begin
                    if not ICInboxOutboxMgt.IsPurchaseHeaderFromIncomingIC(Rec) then
                        exit;
                    if Confirm(SureToRejectMsg) then
                        ICInboxOutboxMgt.RejectAcceptedPurchaseHeader(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
    begin
        RejectICPurchaseInvoiceEnabled := ICInboxOutboxMgt.IsPurchaseHeaderFromIncomingIC(Rec);
    end;

    trigger OnOpenPage()
    var
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
    begin
        ICInboxOutboxMgt.CheckIncomingICPurchaseInvoiceDuplicates(Rec);
    end;

    var
        SureToRejectMsg: Label 'Do you want to reject this Intercompany purchase invoice?';
        RejectICPurchaseInvoiceEnabled: Boolean;
}

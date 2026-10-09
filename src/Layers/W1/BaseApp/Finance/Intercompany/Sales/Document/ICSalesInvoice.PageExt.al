// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Intercompany;

/// <summary>
/// Extends Sales Invoice with Intercompany-specific actions.
/// </summary>
pageextension 8488 ICSalesInvoice extends "Sales Invoice"
{
    actions
    {
        addafter(Reopen)
        {
            action("Reject IC Sales Invoice")
            {
                ApplicationArea = Intercompany;
                Caption = 'Reject IC Sales Invoice';
                Enabled = RejectICSalesInvoiceEnabled;
                Image = Cancel;
                ToolTip = 'Deletes the invoice and sends the rejection to the company that created it.';

                trigger OnAction()
                var
                    ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
                begin
                    if not ICInboxOutboxMgt.IsSalesHeaderFromIncomingIC(Rec) then
                        exit;
                    if Confirm(SureToRejectMsg) then
                        ICInboxOutboxMgt.RejectAcceptedSalesHeader(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
    begin
        RejectICSalesInvoiceEnabled := ICInboxOutboxMgt.IsSalesHeaderFromIncomingIC(Rec);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        SureToRejectMsg: Label 'Do you want to reject this Intercompany sales invoice?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        RejectICSalesInvoiceEnabled: Boolean;
}

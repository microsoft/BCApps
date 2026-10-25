// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Intercompany;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Outbox;
using System.Automation;

/// <summary>
/// Extends Sales Order with Intercompany-specific actions.
/// </summary>
pageextension 8486 ICSalesOrder extends "Sales Order"
{
    actions
    {
        addafter("Archive Document_Promoted")
        {
            actionref("Send IC Sales Order_Promoted"; "Send IC Sales Order")
            {
            }
        }
        addafter("Archive Document")
        {
            action("Send IC Sales Order")
            {
                AccessByPermission = TableData "IC G/L Account" = R;
                ApplicationArea = Intercompany;
                Caption = 'Send IC Sales Order';
                Image = IntercompanyOrder;
                ToolTip = 'Send the sales order to the intercompany outbox or directly to the intercompany partner if automatic transaction sending is enabled.';

                trigger OnAction()
                var
                    ICInOutboxMgt: Codeunit ICInboxOutboxMgt;
                    ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    ICFeedback: Codeunit "IC Feedback";
                begin
                    Rec.TestField("IC Direction", Rec."IC Direction"::Outgoing);
                    if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then begin
                        ICInOutboxMgt.SendSalesDoc(Rec, false);
                        ICFeedback.ShowIntercompanyMessage(Rec, "IC Transaction Document Type"::Order);
                    end;
                end;
            }
            action("Reject IC Sales Order")
            {
                ApplicationArea = Intercompany;
                Caption = 'Reject IC Sales Order';
                Enabled = RejectICSalesOrderEnabled;
                Image = Cancel;
                ToolTip = 'Deletes the order and sends the rejection to the company that created it.';

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
        RejectICSalesOrderEnabled := ICInboxOutboxMgt.IsSalesHeaderFromIncomingIC(Rec);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        SureToRejectMsg: Label 'Rejecting this order will remove it from your company and send it back to the partner company.\\Do you want to continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        RejectICSalesOrderEnabled: Boolean;
}

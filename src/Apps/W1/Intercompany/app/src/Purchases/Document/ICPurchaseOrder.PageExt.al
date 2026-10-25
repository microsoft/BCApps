// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Intercompany;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Outbox;
using System.Automation;

/// <summary>
/// Extends Purchase Order with Intercompany-specific actions.
/// </summary>
pageextension 8457 ICPurchaseOrder extends "Purchase Order"
{
    actions
    {
        addafter("Create Inventor&y Put-away/Pick_Promoted")
        {
            actionref("Send Intercompany Purchase Order_Promoted"; "Send Intercompany Purchase Order")
            {
            }
        }
        addafter("Archive Document")
        {
            action("Send Intercompany Purchase Order")
            {
                AccessByPermission = TableData "IC G/L Account" = R;
                ApplicationArea = Intercompany;
                Caption = 'Send Intercompany Purchase Order';
                Image = IntercompanyOrder;
                ToolTip = 'Send the purchase order to the intercompany outbox or directly to the intercompany partner if automatic transaction sending is enabled.';

                trigger OnAction()
                var
                    ICInOutboxMgt: Codeunit ICInboxOutboxMgt;
                    ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    ICFeedback: Codeunit "IC Feedback";
                begin
                    if ApprovalsMgmt.PrePostApprovalCheckPurch(Rec) then begin
                        ICInOutboxMgt.SendPurchDoc(Rec, false);
                        ICFeedback.ShowIntercompanyMessage(Rec, Enum::"IC Transaction Document Type"::Order);
                    end;
                end;
            }
            action("Reject IC Purchase Order")
            {
                ApplicationArea = Intercompany;
                Caption = 'Reject IC Purchase Order';
                Image = Cancel;
                ToolTip = 'Deletes the order and sends the rejection to the company that created it.';

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

    var
        SureToRejectMsg: Label 'Rejecting this order will remove it from your company and send it back to the partner company.\\Do you want to continue?';
}

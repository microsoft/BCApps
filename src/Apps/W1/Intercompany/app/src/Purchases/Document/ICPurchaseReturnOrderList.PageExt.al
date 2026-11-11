// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Intercompany;
using Microsoft.Intercompany.GLAccount;
using System.Automation;

/// <summary>
/// Extends Purchase Return Order List with Intercompany-specific actions.
/// </summary>
pageextension 8460 ICPurchaseReturnOrderList extends "Purchase Return Order List"
{
    actions
    {
        addafter("Get Posted Doc&ument Lines to Reverse")
        {
            action("Send IC Return Order")
            {
                AccessByPermission = TableData "IC G/L Account" = R;
                ApplicationArea = Intercompany;
                Caption = 'Send IC Return Order';
                Image = IntercompanyOrder;
                ToolTip = 'Send the document to the intercompany outbox or directly to the intercompany partner if automatic transaction sending is enabled.';

                trigger OnAction()
                var
                    ICInOutMgt: Codeunit ICInboxOutboxMgt;
                    ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                begin
                    if ApprovalsMgmt.PrePostApprovalCheckPurch(Rec) then
                        ICInOutMgt.SendPurchDoc(Rec, false);
                end;
            }
        }

        addlast(Category_Process)
        {
            actionref("Send IC Return Order_Promoted"; "Send IC Return Order")
            {
            }
        }
    }
}

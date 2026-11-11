// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Intercompany;
using Microsoft.Intercompany.GLAccount;
using System.Automation;

/// <summary>
/// Extends Purchase Return Order with Intercompany-specific actions.
/// </summary>
pageextension 8458 ICPurchaseReturnOrder extends "Purchase Return Order"
{
    actions
    {
        addafter("Archive Document")
        {
            action("Send IC Return Order")
            {
                AccessByPermission = TableData "IC G/L Account" = R;
                ApplicationArea = Intercompany;
                Caption = 'Send IC Return Order';
                Image = IntercompanyOrder;
                ToolTip = 'Prepare to send the return order to an intercompany partner.';

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
    }
}

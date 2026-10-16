// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Intercompany;
using Microsoft.Intercompany.GLAccount;
using System.Automation;

/// <summary>
/// Extends Sales Return Order with Intercompany-specific actions.
/// </summary>
pageextension 8491 ICSalesReturnOrder extends "Sales Return Order"
{
    actions
    {
        addafter("Archive Document")
        {
            action("Send IC Return Order Cnfmn.")
            {
                AccessByPermission = TableData "IC G/L Account" = R;
                ApplicationArea = Intercompany;
                Caption = 'Send IC Return Order Cnfmn.';
                Image = IntercompanyOrder;
                ToolTip = 'Prepare to send the return order confirmation to an intercompany partner.';

                trigger OnAction()
                var
                    ICInOutboxMgt: Codeunit ICInboxOutboxMgt;
                    ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                begin
                    if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then
                        ICInOutboxMgt.SendSalesDoc(Rec, false);
                end;
            }
        }
    }
}

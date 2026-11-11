// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Intercompany.GLAccount;

/// <summary>
/// Extends Purchase Order List with Intercompany-specific actions.
/// </summary>
pageextension 8459 ICPurchaseOrderList extends "Purchase Order List"
{
    actions
    {
        addfirst("F&unctions")
        {
            action("Send IC Purchase Order")
            {
                AccessByPermission = TableData "IC G/L Account" = R;
                ApplicationArea = Intercompany;
                Caption = 'Send IC Purchase Order';
                Image = IntercompanyOrder;
                ToolTip = 'Send the document to the intercompany outbox or directly to the intercompany partner if automatic transaction sending is enabled.';

                trigger OnAction()
                var
                    PurchaseHeader: Record "Purchase Header";
                begin
                    CurrPage.SetSelectionFilter(PurchaseHeader);
                    Rec.SendICPurchaseDoc(PurchaseHeader);
                end;
            }
        }

        addlast(Category_Process)
        {
            actionref("Send IC Purchase Order_Promoted"; "Send IC Purchase Order")
            {
            }
        }
    }
}

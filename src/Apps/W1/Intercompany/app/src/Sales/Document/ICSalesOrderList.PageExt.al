// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Intercompany.GLAccount;

/// <summary>
/// Extends Sales Order List with Intercompany-specific actions.
/// </summary>
pageextension 8490 ICSalesOrderList extends "Sales Order List"
{
    actions
    {
        addafter("Order &Promising")
        {
            action("Send IC Sales Order Cnfmn.")
            {
                AccessByPermission = TableData "IC G/L Account" = R;
                ApplicationArea = Intercompany;
                Caption = 'Send IC Sales Order Cnfmn.';
                Image = IntercompanyOrder;
                ToolTip = 'Send the document to the intercompany outbox or directly to the intercompany partner if automatic transaction sending is enabled.';

                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                begin
                    CurrPage.SetSelectionFilter(SalesHeader);
                    Rec.SendICSalesDoc(SalesHeader);
                end;
            }
        }

        addlast(Category_Process)
        {
            actionref("Send IC Sales Order Cnfmn._Promoted"; "Send IC Sales Order Cnfmn.")
            {
            }
        }
    }
}

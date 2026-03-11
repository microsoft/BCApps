// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Capacity;

pageextension 99001502 "Subc. CapLEntries" extends "Capacity Ledger Entries"
{
    layout
    {
        addlast(Control1)
        {
            field("Subcontr. Purch. Order No."; Rec."Subcontr. Purch. Order No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the related purchase order.';
                Visible = false;
            }
            field("Subcontr. PO Line No."; Rec."Subcontr. PO Line No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the related purchase order line.';
                Visible = false;
            }
            field("Subcontractor No."; Rec."Subcontractor No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the number of the related subcontractor.';
                Visible = false;
            }
        }
    }
    actions
    {
        addafter("Ent&ry")
        {
            group(Production)
            {
                Caption = 'Production';

                action("Purchase Order")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontracting Purchase Order';
                    Image = Order;
                    ToolTip = 'Specifies the depended Purchase Order of this Subcontracting Transfer Order.';
                    trigger OnAction()
                    begin
                        ShowPurchaseOrder(Rec);
                    end;
                }
            }
        }
    }
    local procedure ShowPurchaseOrder(RecRelatedVariant: Variant)
    var
        SubcFactboxMgmt: Codeunit "Subc. Factbox Mgmt.";
    begin
        SubcFactboxMgmt.ShowPurchaseOrder(RecRelatedVariant);
    end;
}
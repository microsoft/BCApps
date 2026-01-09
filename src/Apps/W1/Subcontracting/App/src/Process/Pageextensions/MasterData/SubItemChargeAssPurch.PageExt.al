// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

pageextension 99001522 "Sub. ItemChargeAss.(Purch)" extends "Item Charge Assignment (Purch)"
{
    actions
    {
        addafter(GetReceiptLines)
        {
            action(GetReceiptLinesSubcontracting)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Get Receipt Lines for Subcontracting';
                Image = Receipt;
                ToolTip = 'Select a posted subcontracting purchase receipt for the item that you want to assign the item charge to, for example, if you received an invoice for the item charge after you posted the original purchase receipt.';
                Visible = GetReceiptLinesSubcontractingVisible;

                trigger OnAction()
                begin
                    OpenPurchaseReceiptLinesSubcontracting();
                end;
            }
        }
        addafter(GetReceiptLines_Promoted)
        {
            actionref(GetReceiptLinesSubcontracting_Promoted; GetReceiptLinesSubcontracting) { }
        }
    }
    var
        SubManagementSetup: Record "Sub. Management Setup";
        GetReceiptLinesSubcontractingVisible: Boolean;

    local procedure OpenPurchaseReceiptLinesSubcontracting()
    var
        ItemChargeAssgntPurch: Record "Item Charge Assignment (Purch)";
        PurchReceiptLines: Page "Purch. Receipt Lines";
    begin
        PurchLine2.TestField("Qty. to Invoice");

        ItemChargeAssgntPurch.SetRange("Document Type", Rec."Document Type");
        ItemChargeAssgntPurch.SetRange("Document No.", Rec."Document No.");
        ItemChargeAssgntPurch.SetRange("Document Line No.", Rec."Document Line No.");
        PurchRcptLine.SetFilter("Prod. Order No.", '<>%1', '');
        PurchRcptLine.SetFilter("Routing No.", '<>%1', '');
        PurchRcptLine.SetFilter("Operation No.", '<>%1', '');

        PurchReceiptLines.SetTableView(PurchRcptLine);
        if ItemChargeAssgntPurch.FindLast() then
            PurchReceiptLines.Initialize(ItemChargeAssgntPurch, PurchLine2."Unit Cost")
        else
            PurchReceiptLines.Initialize(Rec, PurchLine2."Unit Cost");
        PurchReceiptLines.LookupMode(true);
        PurchReceiptLines.RunModal();
        PurchRcptLine.SetRange("Prod. Order No.");
        PurchRcptLine.SetRange("Routing No.");
        PurchRcptLine.SetRange("Operation No.");
    end;

    trigger OnOpenPage()
    begin
        GetReceiptLinesSubcontractingVisible := SubManagementSetup.ItemChargeToRcptSubReferenceEnabled();
    end;
}
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.TaxBase;

pageextension 18722 "Purchase Order" extends "Purchase Order"
{
    layout
    {
        addlast(General)
        {
            field("Include GST in TDS Base"; Rec."Include GST in TDS Base")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Select this field to include GST value in the TDS Base.';

                trigger OnValidate()
                var
                    PurchaseLine: Record "Purchase Line";
                    CalculateTax: Codeunit "Calculate Tax";
                begin
                    CurrPage.SaveRecord();
                    PurchaseLine.SetRange("Document Type", Rec."Document Type");
                    PurchaseLine.SetRange("Document No.", Rec."No.");
                    if PurchaseLine.FindSet() then
                        repeat
                            if PurchaseLine.Type <> PurchaseLine.Type::" " then
                                CalculateTax.CallTaxEngineOnPurchaseLine(PurchaseLine, PurchaseLine);
                        until PurchaseLine.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
            field("Remaining TDS Cert. Value"; Rec."Remaining TDS Cert. Value")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Displays the remaining TDS Certificate Value for the vendor on this purchase invoice.';
            }
            field(NoOfTestLines; NoOfTestLines)
            {
                ApplicationArea = All;
                Caption = 'No. of Test Lines';
                ToolTip = 'TEST ONLY. Specifies how many purchase lines to create from the first line.';
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action(CreateTestLines)
            {
                ApplicationArea = All;
                Caption = 'Create Test Lines';
                ToolTip = 'TEST ONLY. Creates the specified number of purchase lines by copying the first line, without running triggers (no tax calculation).';
                Image = CreateLinesFromJob;

                trigger OnAction()
                begin
                    CreateTestPurchaseLines();
                end;
            }
            action(NoOfPurchaseLines)
            {
                ApplicationArea = All;
                Caption = 'No. of Purchase Lines';
                ToolTip = 'Count Purchase Lines for this Purchase Order.';
                Image = Continue;

                trigger OnAction()
                var
                    FirstPurchaseLine: Record "Purchase Line";
                begin
                    FirstPurchaseLine.SetRange("Document Type", Rec."Document Type");
                    FirstPurchaseLine.SetRange("Document No.", Rec."No.");
                    if FirstPurchaseLine.FindSet() then
                        message('There are %1 purchase lines for this purchase order.', FirstPurchaseLine.Count());
                end;
            }
            action(ModifyQuantityOnPurchaseLines)
            {
                ApplicationArea = All;
                Caption = 'Modify Quantity on Purchase Lines';
                ToolTip = 'Modify the quantity on all purchase lines for this purchase order.';
                Image = Continue;

                trigger OnAction()
                var
                    FirstPurchaseLine: Record "Purchase Line";
                begin
                    FirstPurchaseLine.SetRange("Document Type", Rec."Document Type");
                    FirstPurchaseLine.SetRange("Document No.", Rec."No.");
                    if FirstPurchaseLine.FindSet() then
                        FirstPurchaseLine.ModifyAll("Quantity", NoOfTestLines, false);
                end;
            }
            action(ModifyCostOnPurchaseLines)
            {
                ApplicationArea = All;
                Caption = 'Modify Cost on Purchase Lines';
                ToolTip = 'Modify the cost on all purchase lines for this purchase order.';
                Image = Continue;

                trigger OnAction()
                var
                    FirstPurchaseLine: Record "Purchase Line";
                begin
                    FirstPurchaseLine.SetRange("Document Type", Rec."Document Type");
                    FirstPurchaseLine.SetRange("Document No.", Rec."No.");
                    if FirstPurchaseLine.FindSet() then
                        FirstPurchaseLine.ModifyAll("Direct Unit Cost", NoOfTestLines, false);
                end;
            }
        }
    }

    var
        NoOfTestLines: Integer;
        NoTemplateLineErr: Label 'Please add one purchase line first. It will be used as the template.';
        NoOfLinesErr: Label 'Enter a number of test lines greater than zero.';

    // NOTE: TEST-ONLY tooling to bulk-generate purchase lines for performance testing.
    // Copies the first (template) line N times using Insert(false) so no triggers fire
    // (i.e. no tax calculation during creation). Do NOT ship this in the final PR.
    local procedure CreateTestPurchaseLines()
    var
        FirstPurchaseLine: Record "Purchase Line";
        PurchaseLine: Record "Purchase Line";
        NewPurchaseLine: Record "Purchase Line";
        NextLineNo: Integer;
        Index: Integer;
    begin
        if NoOfTestLines <= 0 then
            Error(NoOfLinesErr);

        FirstPurchaseLine.SetRange("Document Type", Rec."Document Type");
        FirstPurchaseLine.SetRange("Document No.", Rec."No.");
        if not FirstPurchaseLine.FindFirst() then
            Error(NoTemplateLineErr);

        PurchaseLine.SetRange("Document Type", Rec."Document Type");
        PurchaseLine.SetRange("Document No.", Rec."No.");
        if PurchaseLine.FindLast() then
            NextLineNo := PurchaseLine."Line No.";

        for Index := 1 to NoOfTestLines do begin
            NextLineNo += 10000;
            NewPurchaseLine := FirstPurchaseLine;
            NewPurchaseLine."Line No." := NextLineNo;
            NewPurchaseLine.Insert(false); // Insert without triggers -> no tax calculation
        end;

        CurrPage.Update(false);
    end;
}

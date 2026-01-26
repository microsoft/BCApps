// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using System.Utilities;

page 12210 "Withholding Tax Lines"
{
    AutoSplitKey = true;
    Caption = 'Withholding Tax Lines';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Withholding Tax Line";

    layout
    {
        area(content)
        {
            group(Header)
            {
                field("Total Base - Excluded Amount"; TotalAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Base - Excluded Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total amount of the original purchase that is excluded from the withholding tax calculation as defined by law.';
                }
            }
            repeater(General)
            {
                field("Base - Excluded Amount"; Rec."Base - Excluded Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Unfavorable;
                    StyleExpr = EmptyIncomeTypeStyleExpr;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from the withholding tax calculation, based on exclusions allowed by law.';

                    trigger OnValidate()
                    begin
                        UpdateStyle();
                    end;
                }
                field("Non-Taxable Income Type"; Rec."Non-Taxable Income Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of non-taxable income.';

                    trigger OnValidate()
                    begin
                        UpdateStyle();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateStyle();
    end;

    trigger OnOpenPage()
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        if Rec.GetFilter("Withholding Tax Entry No.") <> '' then
            Evaluate(WithholdingTax."Entry No.", Rec.GetFilter("Withholding Tax Entry No."));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(CheckAmounts());
    end;

    var
        AmountNotEqualQst: Label 'The total amount of all valid lines is %1, which is not equal to the value of the Base - Excluded Amount field (%2) on the Withholding Tax Card. This will result in an error when you export the entry. \ Do you want to close the page anyway?', Comment = '%1=amount,%2=another amount';
        TotalAmount: Decimal;
        EmptyIncomeTypeStyleExpr: Boolean;

    procedure SetTotalAmount(TotAmount: Decimal)
    begin
        TotalAmount := TotAmount;
    end;

    local procedure CheckAmounts(): Boolean
    var
        WithholdingTax: Record "Withholding Tax";
        ConfirmManagement: Codeunit "Confirm Management";
        TotalLineAmount: Decimal;
    begin
        if not Rec.FindSet() then
            exit(true);
        WithholdingTax.SetRange("Entry No.", Rec."Withholding Tax Entry No.");
        WithholdingTax.FindFirst();
        TotalLineAmount := Rec.GetAmountForEntryNo(Rec."Withholding Tax Entry No.");
        if WithholdingTax."Base - Excluded Amount" = TotalLineAmount then
            exit(true);
        exit(ConfirmManagement.GetResponse(
            StrSubstNo(AmountNotEqualQst, TotalLineAmount, WithholdingTax."Base - Excluded Amount"), false));
    end;

    local procedure UpdateStyle()
    begin
        EmptyIncomeTypeStyleExpr := Rec."Non-Taxable Income Type" = Rec."Non-Taxable Income Type"::" ";
    end;
}


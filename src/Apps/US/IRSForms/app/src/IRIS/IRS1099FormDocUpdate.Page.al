// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 10067 "IRS 1099 Form Doc. Update"
{
    PageType = ListPlus;
    ApplicationArea = BasicCA, BasicUS;
    Caption = 'Update 1099 Form Documents';
    InsertAllowed = false;
    DeleteAllowed = false;
    SourceTableView = sorting("Line Action");
    SourceTable = "IRS 1099 Form Doc. Line";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            label(UpdateInstruction)
            {
                Caption = 'Compare the current and new amounts, minimum reportable amounts, and Include in 1099 values. Include in 1099 can change even when the amount stays the same. Select Process Line for each change you want to apply. Lines that are not selected stay unchanged.';
                Style = StandardAccent;
            }
            repeater(General)
            {
#pragma warning disable AA0219
                field("Process Line"; Rec."Process Line")
                {
                    Caption = 'Process Line';
                    ToolTip = 'Select this check box to apply the recalculated amount, minimum reportable amount, and Include in 1099 value, or to create a document from current vendor ledger entries. Leave it cleared to keep the existing line unchanged.';
                    Visible = true;
                }
#pragma warning restore AA0219
                field("Line Action"; Rec."Line Action")
                {
                    ToolTip = 'Specifies the action to be performed on the 1099 form document line.';
                    Style = Favorable;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ToolTip = 'Specifies the vendor number to which the 1099 form document line belongs.';
                    Editable = false;
                }
                field("Form No."; Rec."Form No.")
                {
                    ToolTip = 'Specifies the form type of the 1099 form document line.';
                    Visible = false;
                }
                field("Form Box No."; Rec."Form Box No.")
                {
                    ToolTip = 'Specifies the form box number of the 1099 form document line.';
                    Editable = false;
                }
                field(CurrentLineExists; CurrLineExists)
                {
                    Caption = 'Current Line Exists';
                    ToolTip = 'Specifies whether the document line already exists. If Line Action is Create, there is no existing line to compare.';
                    Editable = false;
                }
                field(CurrentAmount; CurrAmount)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Current Amount';
                    ToolTip = 'Specifies the amount that was calculated from the vendor ledger entries when the 1099 form document was created.';
                    Editable = false;
                }
                field(NewAmount; Rec.Amount)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'New Amount';
                    ToolTip = 'Specifies the amount that is calculated from the current vendor ledger entries.';
                }
                field(CurrentMinimumReportableAmount; CurrMinimumReportableAmount)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Current Minimum Reportable Amount';
                    ToolTip = 'Specifies the minimum reportable amount on the existing document line. Compare it with the new minimum to check whether the line is still included in 1099 reporting.';
                    Editable = false;
                }
                field(NewMinimumReportableAmount; Rec."Minimum Reportable Amount")
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'New Minimum Reportable Amount';
                    ToolTip = 'Specifies the recalculated minimum reportable amount. It is applied only when Process Line is selected.';
                    Editable = false;
                }
                field(CurrentIncludeIn1099; CurrIncludeIn1099)
                {
                    Caption = 'Current Include in 1099';
                    ToolTip = 'Specifies whether the existing document line is included in 1099 reporting. If Current Line Exists is cleared, there is no existing line to compare.';
                    Editable = false;
                }
                field(NewIncludeIn1099; Rec."Include In 1099")
                {
                    Caption = 'New Include in 1099';
                    ToolTip = 'Specifies whether the recalculated line is included in 1099 reporting, based on the minimum reportable amount and withholding. Check this value even when the income amount stays the same.';
                    Editable = false;
                }
                field("Adjustment Amount"; Rec."Adjustment Amount")
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Tooltip = 'Specifies the calculated adjustment amount of the document line. It is set using the Adjustments action of the IRS Reporting Periods page.';
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        IRS1099FormDocLine: Record "IRS 1099 Form Doc. Line";
    begin
        Clear(CurrAmount);
        Clear(CurrMinimumReportableAmount);
        Clear(CurrIncludeIn1099);
        CurrLineExists := false;
        if Rec."Line Action" = Rec."Line Action"::Create then
            exit;

        if IRS1099FormDocLine.Get(Rec."Period No.", Rec."Vendor No.", Rec."Form No.", Rec."Document ID", Rec."Line No.") then begin
            CurrLineExists := true;
            CurrAmount := IRS1099FormDocLine.Amount;
            CurrMinimumReportableAmount := IRS1099FormDocLine."Minimum Reportable Amount";
            CurrIncludeIn1099 := IRS1099FormDocLine."Include In 1099";
        end;
    end;

    var
        CurrAmount: Decimal;
        CurrMinimumReportableAmount: Decimal;
        CurrIncludeIn1099: Boolean;
        CurrLineExists: Boolean;

    internal procedure SetLines(var TempIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line" temporary)
    begin
        if TempIRS1099FormDocLine.FindSet() then
            repeat
                Rec := TempIRS1099FormDocLine;
                Rec.Insert();
            until TempIRS1099FormDocLine.Next() = 0;
    end;

    internal procedure GetSelectedLines(var TempIRS1099FormDocLine: Record "IRS 1099 Form Doc. Line" temporary)
    begin
        TempIRS1099FormDocLine.Reset();
        TempIRS1099FormDocLine.DeleteAll();

        Rec.SetRange("Process Line", true);
        if Rec.FindSet() then
            repeat
                TempIRS1099FormDocLine := Rec;
                TempIRS1099FormDocLine.Insert();
            until Rec.Next() = 0;
    end;
}
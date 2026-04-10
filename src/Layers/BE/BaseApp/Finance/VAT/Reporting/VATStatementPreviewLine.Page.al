// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;

/// <summary>
/// Preview interface displaying VAT statement lines with calculated amounts and drill-down capabilities.
/// Provides read-only view of VAT statement calculations with interactive access to underlying VAT and G/L entries.
/// </summary>
#pragma warning disable AS0106 // Protected variable VATDateType was removed before AS0106 was introduced.
page 475 "VAT Statement Preview Line"
#pragma warning restore AS0106
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "VAT Statement Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Row No."; Rec."Row No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Jurisdiction Code"; Rec."Tax Jurisdiction Code")
                {
                    ApplicationArea = SalesTax;
                    Visible = false;
                }
                field("Use Tax"; Rec."Use Tax")
                {
                    ApplicationArea = SalesTax;
                    Visible = false;
                }
                field(ColumnValue; ColumnValue)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'Column Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the type of entries that will be included in the amounts in columns.';

                    trigger OnDrillDown()
                    begin
                        case Rec.Type of
                            Rec.Type::"Account Totaling":
                                begin
                                    GLEntry.SetCurrentKey("Journal Templ. Name", "G/L Account No.", "VAT Reporting Date", "Document Type");
                                    GLEntry.SetFilter("G/L Account No.", Rec."Account Totaling");
                                    Rec.CopyFilter("Date Filter", GLEntry."VAT Reporting Date");
                                    if Rec."Document Type" = Rec."Document Type"::"All except Credit Memo" then
                                        GLEntry.SetFilter("Document Type", '<>%1', Rec."Document Type"::"Credit Memo")
                                    else
                                        GLEntry.SetRange("Document Type", Rec."Document Type");
                                    OnColumnValueDrillDownOnBeforeRunGeneralLedgerEntries(VATEntry, GLEntry, Rec);
                                    PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
                                end;
                            Rec.Type::"VAT Entry Totaling":
                                begin
                                    VATEntry.Reset();
                                    VATEntry.SetCurrentKey("Journal Templ. Name", Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date");
                                    VATEntry.SetRange(Type, Rec."Gen. Posting Type");
                                    VATEntry.SetRange("VAT Bus. Posting Group", Rec."VAT Bus. Posting Group");
                                    VATEntry.SetRange("VAT Prod. Posting Group", Rec."VAT Prod. Posting Group");
                                    VATEntry.SetRange("Tax Jurisdiction Code", Rec."Tax Jurisdiction Code");
                                    VATEntry.SetRange("Use Tax", Rec."Use Tax");
                                    if Rec."Document Type" = Rec."Document Type"::"All except Credit Memo" then
                                        VATEntry.SetFilter("Document Type", '<>%1', Rec."Document Type"::"Credit Memo")
                                    else
                                        VATEntry.SetRange("Document Type", Rec."Document Type");
                                    if Rec.GetFilter("Date Filter") <> '' then
                                        SetDateFilterForVATEntry(VATEntry);

                                    case Selection of
                                        Selection::Open:
                                            VATEntry.SetRange(Closed, false);
                                        Selection::Closed:
                                            VATEntry.SetRange(Closed, true);
                                        Selection::"Open and Closed":
                                            VATEntry.SetRange(Closed);
                                    end;
                                    OnBeforeOpenPageVATEntryTotaling(VATEntry, Rec, GLEntry);
                                    PAGE.Run(PAGE::"VAT Entries", VATEntry);
                                end;
                            Rec.Type::"Row Totaling",
                            Rec.Type::Description:
                                Error(Text000, Rec.FieldCaption(Type), Rec.Type);
                        end;
                    end;
                }
                field(CorrectionValue; CorrectionValue)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'Correction Amount';
                    ToolTip = 'Specifies the amount of the VAT correction. You must enter the correction amount, not the new amount.';

                    trigger OnDrillDown()
                    begin
                        DrillDownCorrectionValue();
                    end;
                }
                field(TotalAmount; ColumnValue + CorrectionValue)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'Total Amount';
                    ToolTip = 'Specifies the total amount minus any invoice discount amount for the service order. The value does not include VAT.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Clear(VATStatement);
        VATStatement.InitializeRequest(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr);
        CalcColumnValue(Rec, ColumnValue, CorrectionValue, NetAmountLCY, '', 0);
        if Rec."Print with" = Rec."Print with"::"Opposite Sign" then begin
            ColumnValue := -ColumnValue;
            CorrectionValue := -CorrectionValue;
        end;
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Drilldown is not possible when %1 is %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        VATStmtName: Record "VAT Statement Name";
        VATStatement: Report "VAT Statement";
        ColumnValue: Decimal;
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        UseAmtsInAddCurr: Boolean;
        CorrectionValue: Decimal;
        NetAmountLCY: Decimal;

    local procedure SetDateFilterForVATEntry(var VATEntryLocal: Record "VAT Entry")
    begin
        if PeriodSelection = PeriodSelection::"Before and Within Period" then
            VATEntryLocal.SetRange("VAT Reporting Date", 0D, Rec.GetRangeMax("Date Filter"))
        else
            Rec.CopyFilter("Date Filter", VATEntryLocal."VAT Reporting Date");
    end;

    local procedure CalcColumnValue(VATStatementLine: Record "VAT Statement Line"; var ColumnValue: Decimal; var CorrectionValue: Decimal; var NetAmountLCY: Decimal; JournalTempl: Code[10]; Level: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcColumnValue(VATStatementLine, ColumnValue, CorrectionValue, NetAmountLCY, JournalTempl, Level, IsHandled, Selection, PeriodSelection, false, UseAmtsInAddCurr);
        if IsHandled then
            exit;

        VATStatement.CalcLineTotal(VATStatementLine, ColumnValue, CorrectionValue, NetAmountLCY, JournalTempl, Level);
    end;

    /// <summary>
    /// Updates the VAT statement preview with new calculation parameters and filters.
    /// Refreshes display with updated selection criteria and currency preferences.
    /// </summary>
    /// <param name="VATStmtName">VAT statement name configuration</param>
    /// <param name="NewSelection">Period or closing date selection type</param>
    /// <param name="NewPeriodSelection">Period range selection criteria</param>
    /// <param name="NewUseAmtsInAddCurr">Whether to use additional reporting currency amounts</param>
    procedure UpdateForm(var VATStmtName: Record "VAT Statement Name"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewUseAmtsInAddCurr: Boolean)
    begin
        UpdateForm(VATStmtName, NewSelection, NewPeriodSelection, NewUseAmtsInAddCurr, '');
    end;

    /// <summary>
    /// Updates the VAT statement preview with new calculation parameters including country/region filtering.
    /// Extended version providing geographic filtering capability for multi-country VAT reporting scenarios.
    /// </summary>
    /// <param name="VATStmtName">VAT statement name configuration</param>
    /// <param name="NewSelection">Period or closing date selection type</param>
    /// <param name="NewPeriodSelection">Period range selection criteria</param>
    /// <param name="NewUseAmtsInAddCurr">Whether to use additional reporting currency amounts</param>
    /// <param name="NewCountryRegionFilter">Country/region filter for geographic reporting</param>
    procedure UpdateForm(var VATStmtName: Record "VAT Statement Name"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewUseAmtsInAddCurr: Boolean; NewCountryRegionFilter: Text)
    begin
        VATStmtName.CopyFilter("Date Filter", Rec."Date Filter");
        Selection := NewSelection;
        PeriodSelection := NewPeriodSelection;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
        OnUpdateFormOnBeforeVatStatementInitializeRequest(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr);
        VATStatement.InitializeRequest(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr, NewCountryRegionFilter);
        OnUpdateFormOnBeforePageUpdate(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr);
        CurrPage.Update();

        OnAfterUpdateForm();
    end;

    local procedure ApplyDateFilter(var ManualVATCorrection: Record "Manual VAT Correction")
    begin
        if Rec.GetFilter("Date Filter") <> '' then
            if PeriodSelection = PeriodSelection::"Before and Within Period" then
                ManualVATCorrection.SetRange("Posting Date", 0D, Rec.GetRangeMax("Date Filter"))
            else
                Rec.CopyFilter("Date Filter", ManualVATCorrection."Posting Date");
    end;

    procedure DrillDownCorrectionValue()
    var
        ManualVATCorrection: Record "Manual VAT Correction";
        ManualVATCorrectionListPage: Page "Manual VAT Correction List";
        IncludesRowTotaling: Boolean;
    begin
        Clear(ManualVATCorrectionListPage);
        ManualVATCorrection.Reset();
        ManualVATCorrection.FilterGroup(2);
        IncludesRowTotaling := MarkManVATCorrections(Rec, ManualVATCorrection);
        if IncludesRowTotaling then begin
            ManualVATCorrectionListPage.SetCorrStatementLineNo(Rec."Line No.");
            ManualVATCorrection.SetRange("Statement Line No.");
            ManualVATCorrection.MarkedOnly(true);
        end;
        ManualVATCorrection.FilterGroup(0);
        ManualVATCorrectionListPage.SetTableView(ManualVATCorrection);
        ManualVATCorrectionListPage.Run();
    end;

    local procedure MarkLinesManVATCorrections(VATStatementLine: Record "VAT Statement Line"; var ManualVATCorrection: Record "Manual VAT Correction")
    begin
        ManualVATCorrection.SetRange("Statement Template Name", VATStatementLine."Statement Template Name");
        ManualVATCorrection.SetRange("Statement Name", VATStatementLine."Statement Name");
        ManualVATCorrection.SetRange("Statement Line No.", VATStatementLine."Line No.");
        ApplyDateFilter(ManualVATCorrection);
        if ManualVATCorrection.FindSet() then
            repeat
                ManualVATCorrection.Mark(true);
            until ManualVATCorrection.Next() = 0;
    end;

    local procedure MarkManVATCorrections(VATStatementLine: Record "VAT Statement Line"; var ManualVATCorrection: Record "Manual VAT Correction"): Boolean
    begin
        MarkLinesManVATCorrections(VATStatementLine, ManualVATCorrection);
        if (VATStatementLine.Type = VATStatementLine.Type::"Row Totaling") and
           (VATStatementLine."Row Totaling" <> '')
        then begin
            VATStatementLine.SetRange("Statement Template Name", VATStatementLine."Statement Template Name");
            VATStatementLine.SetRange("Statement Name", VATStatementLine."Statement Name");
            VATStatementLine.SetFilter("Row No.", VATStatementLine."Row Totaling");
            if VATStatementLine.FindSet() then
                repeat
                    MarkManVATCorrections(VATStatementLine, ManualVATCorrection);
                until VATStatementLine.Next() = 0;
            exit(true);
        end;
        exit(false);
    end;

    /// <summary>
    /// Integration event raised before calculating column values for VAT statement line preview.
    /// Enables custom calculation logic and override of standard amount calculations.
    /// </summary>
    /// <param name="VATStatementLine">VAT statement line being calculated</param>
    /// <param name="TotalAmount">Total amount result, can be modified</param>
    /// <param name="Level">Current calculation nesting level</param>
    /// <param name="IsHandled">Set to true to skip standard calculation logic</param>
    /// <param name="Selection">Selection type determining calculation criteria</param>
    /// <param name="PeriodSelection">Period selection for calculation scope</param>
    /// <param name="PrintInIntegers">Whether amounts are displayed as integers</param>
    /// <param name="UseAmtsInAddCurr">Whether additional currency amounts are used</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalcColumnValue(VATStatementLine: Record "VAT Statement Line"; var TotalAmount: Decimal; var CorrectionValue: Decimal; var NetAmountLCY: Decimal; JournalTempl: Code[10]; Level: Integer; var IsHandled: Boolean; Selection: Enum "VAT Statement Report Selection"; PeriodSelection: Enum "VAT Statement Report Period Selection"; PrintInIntegers: Boolean; UseAmtsInAddCurr: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before opening VAT entry page for VAT entry totaling drill-down.
    /// Enables custom filtering and modification of VAT entry records before page display.
    /// </summary>
    /// <param name="VATEntry">VAT entry record to be displayed</param>
    /// <param name="VATStatementLine">VAT statement line providing drill-down context</param>
    /// <param name="GLEntry">G/L entry record for related transactions</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeOpenPageVATEntryTotaling(var VATEntry: Record "VAT Entry"; var VATStatementLine: Record "VAT Statement Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before running G/L entries page during column value drill-down.
    /// Enables custom filtering and modification of G/L entry records before page display.
    /// </summary>
    /// <param name="VATEntry">VAT entry record providing drill-down context</param>
    /// <param name="GLEntry">G/L entry record to be displayed</param>
    /// <param name="VATStatementLine">VAT statement line providing calculation context</param>
    [IntegrationEvent(false, false)]
    local procedure OnColumnValueDrillDownOnBeforeRunGeneralLedgerEntries(var VATEntry: Record "VAT Entry"; var GLEntry: Record "G/L Entry"; var VATStatementLine: Record "VAT Statement Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before updating the page during form update process.
    /// Enables custom modifications to VAT statement configuration before page refresh.
    /// </summary>
    /// <param name="NewVATStmtName">VAT statement name being updated</param>
    /// <param name="NewVATStatementLine">VAT statement line being updated</param>
    /// <param name="NewSelection">New selection type being applied</param>
    /// <param name="NewPeriodSelection">New period selection being applied</param>
    /// <param name="NewPrintInIntegers">New print in integers setting</param>
    /// <param name="NewUseAmtsInAddCurr">New additional currency setting</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateFormOnBeforePageUpdate(var NewVATStmtName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after completing the form update process.
    /// Enables custom post-processing after VAT statement preview has been refreshed.
    /// </summary>
    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateForm()
    begin
    end;

    /// <summary>
    /// Integration event raised before initializing VAT statement request during form update.
    /// Enables custom configuration of VAT statement parameters before calculation initialization.
    /// </summary>
    /// <param name="NewVATStatementName">VAT statement name being configured</param>
    /// <param name="NewVATStatementLine">VAT statement line being configured</param>
    /// <param name="NewSelection">Selection type for calculation</param>
    /// <param name="NewPeriodSelection">Period selection for calculation</param>
    /// <param name="NewPrintInIntegers">Print in integers preference</param>
    /// <param name="NewUseAmtsInAddCurr">Additional currency preference</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateFormOnBeforeVatStatementInitializeRequest(var NewVATStatementName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean)
    begin
    end;
}


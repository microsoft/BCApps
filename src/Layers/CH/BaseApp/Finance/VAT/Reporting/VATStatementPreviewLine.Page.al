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
    RefreshOnActivate = true;
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
                field("VAT Statement Cipher"; Rec."VAT Statement Cipher")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a row number in the VAT statement report.';
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
                field(TotalEmpty; TotalEmpty)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the amount of the entry on the line.';

                    trigger OnDrillDown()
                    begin
                        if Rec.Type <> Rec.Type::"Row Totaling" then
                            if Rec.Type <> Rec.Type::"Account Totaling" then
                                Rec.FieldError(Type);
                        DrillDownOnEntries();
                    end;
                }
                field(TotalBase; TotalBase)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'Base Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the amount that does no represent VAT.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOnEntries();
                    end;
                }
                field(TotalAmount; TotalAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'VAT Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the total VAT amount that has been calculated.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOnEntries();
                    end;
                }
                field(TotalUnrealizedBase; TotalUnrealizedBase)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'Unrealized Base Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the unrealized amount if you use unrealized VAT.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOnEntries();
                    end;
                }
                field(UnrealizedVATAmount; TotalUnrealizedAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    BlankZero = true;
                    Caption = 'Unrealized VAT Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the unrealized amount if you use unrealized VAT.';

                    trigger OnDrillDown()
                    begin
                        DrillDownOnEntries();
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
        CalcColumnValue(Rec, TotalAmount, TotalEmpty, TotalBase, TotalUnrealizedAmount, TotalUnrealizedBase, 0);
        if Rec."Print with" = Rec."Print with"::"Opposite Sign" then begin
            TotalEmpty := -TotalEmpty;
            TotalBase := -TotalBase;
            TotalAmount := -TotalAmount;
            TotalUnrealizedAmount := -TotalUnrealizedAmount;
            TotalUnrealizedBase := -TotalUnrealizedBase;
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
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        UseAmtsInAddCurr: Boolean;
        VATStatementGermany: Report "VAT Statement Germany";
        TotalAmount: Decimal;
        TotalEmpty: Decimal;
        TotalBase: Decimal;
        TotalUnrealizedAmount: Decimal;
        TotalUnrealizedBase: Decimal;

    local procedure SetKeyForVATEntry(var VATEntryLocal: Record "VAT Entry")
    begin
        if not VATEntryLocal.SetCurrentKey(Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date") then
            VATEntryLocal.SetCurrentKey(Type, Closed, "Tax Jurisdiction Code", "Use Tax", "VAT Reporting Date");
    end;

    local procedure SetDateFilterForVATEntry(var VATEntryLocal: Record "VAT Entry")
    begin
        if PeriodSelection = PeriodSelection::"Before and Within Period" then
            VATEntryLocal.SetRange("VAT Reporting Date", 0D, Rec.GetRangeMax("Date Filter"))
        else
            Rec.CopyFilter("Date Filter", VATEntryLocal."VAT Reporting Date");
    end;

    local procedure CalcColumnValue(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; var TotalEmpty: Decimal; var TotalBase: Decimal; var TotalUnrealizedAmount: Decimal; var TotalUnrealizedBase: Decimal; Level: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcColumnValue(VATStmtLine2, TotalAmount, TotalEmpty, TotalBase, TotalUnrealizedAmount, TotalUnrealizedBase, Level, IsHandled, Selection, PeriodSelection, false, UseAmtsInAddCurr, Rec);
        if IsHandled then
            exit;

        VATStatementGermany.CalcLineTotal(VATStmtLine2, TotalAmount, TotalEmpty, TotalBase, TotalUnrealizedAmount, TotalUnrealizedBase, Level);
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
        Rec.SetRange("Statement Template Name", VATStmtName."Statement Template Name");
        Rec.SetRange("Statement Name", VATStmtName.Name);
        VATStmtName.CopyFilter("Date Filter", Rec."Date Filter");
        Selection := NewSelection;
        PeriodSelection := NewPeriodSelection;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;
        VATStatementGermany.InitializeRequest(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr, NewCountryRegionFilter);
        OnUpdateFormOnBeforePageUpdate(VATStmtName, Rec, Selection, PeriodSelection, false, UseAmtsInAddCurr);
        CurrPage.Update();

        OnAfterUpdateForm();
    end;

    [Scope('OnPrem')]
    procedure DrillDownOnEntries()
    begin
        case Rec.Type of
            Rec.Type::"Account Totaling":
                begin
                    GLEntry.SetFilter("G/L Account No.", Rec."Account Totaling");
                    Rec.CopyFilter("Date Filter", GLEntry."VAT Reporting Date");
                    OnColumnValueDrillDownOnBeforeRunGeneralLedgerEntries(VATEntry, GLEntry, Rec);
                    PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
                end;
            Rec.Type::"VAT Entry Totaling":
                begin
                    VATEntry.Reset();
                    SetKeyForVATEntry(VATEntry);
                    VATEntry.SetRange(Type, Rec."Gen. Posting Type");
                    VATEntry.SetRange("VAT Bus. Posting Group", Rec."VAT Bus. Posting Group");
                    VATEntry.SetRange("VAT Prod. Posting Group", Rec."VAT Prod. Posting Group");
                    VATEntry.SetRange("Tax Jurisdiction Code", Rec."Tax Jurisdiction Code");
                    VATEntry.SetRange("Use Tax", Rec."Use Tax");
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
    local procedure OnBeforeCalcColumnValue(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; var TotalEmpty: Decimal; var TotalBase: Decimal; var TotalUnrealizedAmount: Decimal; var TotalUnrealizedBase: Decimal; Level: Integer; var IsHandled: Boolean; Selection: Enum "VAT Statement Report Selection"; PeriodSelection: Enum "VAT Statement Report Period Selection"; PrintInIntegers: Boolean; UseAmtsInAddCurr: Boolean; var VATStatementLine: Record "VAT Statement Line")
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
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;

/// <summary>
/// Generates formatted VAT statements with calculated totals and detailed breakdowns.
/// Processes VAT statement templates and lines to produce regulatory compliance reports for tax authorities.
/// </summary>
report 12 "VAT Statement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/VAT/Reporting/VATStatement.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Statement';
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = "VAT Statement Name";

    dataset
    {
        dataitem("VAT Statement Name"; "VAT Statement Name")
        {
            DataItemTableView = sorting("Statement Template Name", Name);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Statement Template Name", Name;
            column(StmtName1_VatStmtName; "Statement Template Name")
            {
            }
            column(Name1_VatStmtName; Name)
            {
            }
            dataitem("VAT Statement Line"; "VAT Statement Line")
            {
                DataItemLink = "Statement Template Name" = field("Statement Template Name"), "Statement Name" = field(Name);
                DataItemTableView = sorting("Statement Template Name", "Statement Name") where(Print = const(true));
                RequestFilterFields = "Row No.";
                column(Heading; Heading)
                {
                }
                column(CompanyName; COMPANYPROPERTY.DisplayName())
                {
                }
                column(StmtName_VatStmtName; "VAT Statement Name"."Statement Template Name")
                {
                }
                column(Name_VatStmtName; "VAT Statement Name".Name)
                {
                }
                column(Heading2; Heading2)
                {
                }
                column(HeaderText; HeaderText)
                {
                }
                column(GlSetupLCYCode; GLSetup."LCY Code")
                {
                }
                column(Allamountsarein; AllamountsareinLbl)
                {
                }
                column(TxtGLSetupAddnalReportCur; StrSubstNo(Text003, GLSetup."Additional Reporting Currency"))
                {
                }
                column(GLSetupAddRepCurrency; GLSetup."Additional Reporting Currency")
                {
                }
                column(VatStmLineTableCaptFilter; TableCaption + ': ' + VATStmtLineFilter)
                {
                }
                column(VatStmtLineFilter; VATStmtLineFilter)
                {
                }
                column(VatStmtLineRowNo; "Row No.")
                {
                    IncludeCaption = true;
                }
                column(Description_VatStmtLine; Description)
                {
                    IncludeCaption = true;
                }
                column(TotalAmount; TotalAmount)
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(UseAmtsInAddCurr; UseAmtsInAddCurr)
                {
                }
                column(Selection; Selection)
                {
                }
                column(PeriodSelection; PeriodSelection)
                {
                }
                column(PrintInIntegers; PrintInIntegers)
                {
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
                column(VATStmtCaption; VATStmtCaptionLbl)
                {
                }
                column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
                {
                }
                column(VATStmtTemplateCaption; VATStmtTemplateCaptionLbl)
                {
                }
                column(VATStmtNameCaption; VATStmtNameCaptionLbl)
                {
                }
                column(AmtsareinwholeLCYsCaption; AmtsareinwholeLCYsCaptionLbl)
                {
                }
                column(ReportinclallVATentriesCaption; ReportinclallVATentriesCaptionLbl)
                {
                }
                column(RepinclonlyclosedVATentCaption; RepinclonlyclosedVATentCaptionLbl)
                {
                }
                column(TotalAmountCaption; TotalAmountCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                var
                    CorrectionAmount: Decimal;
                begin
                    CalcLineTotal("VAT Statement Line", TotalAmount, CorrectionAmount, NetAmountLCY, '', 0);
                    if PrintInIntegers then begin
                        TotalAmount := RoundAmount(TotalAmount);
                        CorrectionAmount := RoundAmount(CorrectionAmount);
                    end;
                    TotalAmount := TotalAmount + CorrectionAmount;
                    if "Print with" = "Print with"::"Opposite Sign" then
                        TotalAmount := -TotalAmount;
                    PageGroupNo := NextPageGroupNo;
                    if "New Page" then
                        NextPageGroupNo := PageGroupNo + 1;
                end;

                trigger OnPreDataItem()
                begin
                    PageGroupNo := 1;
                    NextPageGroupNo := 1;
                end;
            }

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About VAT Statement';
        AboutText = 'The **VAT Statement** report provides a structured summary of VAT amounts based on your custom VAT Statement setup, including input and output VAT and totals. Use it for preparing official VAT filings by consolidating VAT posting data into a format suitable for submission to tax authorities.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Statement Period")
                    {
                        Caption = 'Statement Period';
                        field(StartingDate; StartDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the date from which the report or batch job processes information.';
                        }
                        field(EndingDate; EndDateReq)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the end date for the time interval for VAT statement lines in the report.';
                        }
                    }
                    field(Selection; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        Importance = Additional;
                        ToolTip = 'Specifies if you want to include open VAT entries in the report.';
                    }
                    field(PeriodSelection; PeriodSelection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        Importance = Additional;
                        ToolTip = 'Specifies if you want to include VAT entries from before the specified time period in the report.';
                    }
                    field(RoundToWholeNumbers; PrintInIntegers)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Round to Whole Numbers';
                        Importance = Additional;
                        ToolTip = 'Specifies if you want the amounts in the report to be rounded to whole numbers.';
                    }
                    field(ShowAmtInAddCurrency; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        Importance = Additional;
                        MultiLine = true;
                        ToolTip = 'Specifies if you want the amounts to be printed in the additional reporting currency. If you leave this check box empty, the amounts will be printed in LCY.';
                    }
                    field("Country/Region Filter"; CountryRegionFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Country/Region Filter';
                        ToolTip = 'Specifies the country/region to filter the VAT entries.';
                        Importance = Additional;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            CountryRegion: Record "Country/Region";
                            CountriesRegions: Page "Countries/Regions";
                        begin
                            CountriesRegions.LookupMode(true);
                            if CountriesRegions.RunModal() = Action::LookupOK then begin
                                CountriesRegions.GetRecord(CountryRegion);
                                CountryRegionFilter := CountryRegion.Code;
                                exit(true);
                            end;
                            exit(false);
                        end;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if EndDateReq = 0D then
            EndDate := DMY2Date(31, 12, 9999)
        else
            EndDate := EndDateReq;
        VATStmtLine.SetRange("Date Filter", StartDate, EndDateReq);
        if PeriodSelection = PeriodSelection::"Before and Within Period" then
            Heading := Text000
        else
            Heading := Text004;
        Heading2 := StrSubstNo(Text005, StartDate, EndDateReq);
        VATStmtLineFilter := VATStmtLine.GetFilters();
    end;

    var
        GLAcc: Record "G/L Account";
        VATEntry: Record "VAT Entry";
        GLSetup: Record "General Ledger Setup";
        VATStmtLine: Record "VAT Statement Line";
        GLEntry: Record "G/L Entry";
        VATStmtLineFilter: Text;
        Heading: Text[50];
        Base: Decimal;
        Amount: Decimal;
        RowNo: array[6] of Code[10];
        ErrorText: Text[80];
        i: Integer;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        Amount2: Decimal;
        NetAmountLCY: Decimal;

#pragma warning disable AA0074
        Text000: Label 'VAT entries before and within the period';
#pragma warning disable AA0470
        Text003: Label 'Amounts are in %1, rounded without decimals.';
#pragma warning restore AA0470
        Text004: Label 'VAT entries within the period';
#pragma warning disable AA0470
        Text005: Label 'Period: %1..%2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        AllamountsareinLbl: Label 'All amounts are in';
        VATStmtCaptionLbl: Label 'VAT Statement';
        CurrReportPageNoCaptionLbl: Label 'Page';
        VATStmtTemplateCaptionLbl: Label 'VAT Statement Template';
        VATStmtNameCaptionLbl: Label 'VAT Statement Name';
        AmtsareinwholeLCYsCaptionLbl: Label 'Amounts are in whole LCYs.';
        ReportinclallVATentriesCaptionLbl: Label 'The report includes all VAT entries.';
        RepinclonlyclosedVATentCaptionLbl: Label 'The report includes only closed VAT entries.';
        TotalAmountCaptionLbl: Label 'Amount';
        DefaultRoundingDirectionTok: Label '<', Locked = true;

    protected var
        EndDate: Date;
        StartDate: Date;
        EndDateReq: Date;
        HeaderText: Text[50];
        Heading2: Text;
        PrintInIntegers: Boolean;
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        Selection: Enum "VAT Statement Report Selection";
        TotalAmount: Decimal;
        UseAmtsInAddCurr: Boolean;
        CountryRegionFilter: Text;

    /// <summary>
    /// Calculates the total amount for a VAT statement line based on configured calculation rules.
    /// Processes VAT entries and G/L accounts according to line type and formula settings.
    /// </summary>
    /// <param name="VATStmtLine2">VAT statement line to calculate total for</param>
    /// <param name="TotalAmount">Returns calculated total amount</param>
    /// <param name="Level">Current calculation level for nested formulas</param>
    /// <returns>True if calculation completed successfully, false if errors occurred</returns>
    procedure CalcLineTotal(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; var CorrectionAmount: Decimal; var NetAmountLCY: Decimal; JournalTempl: Code[10]; Level: Integer): Boolean
    var
        DummyTotalBase: Decimal;
    begin
        exit(CalcLineTotalWithBase(VATStmtLine2, TotalAmount, DummyTotalBase, CorrectionAmount, NetAmountLCY, JournalTempl, Level));
    end;

    /// <summary>
    /// Calculates both total amount and total base for a VAT statement line with detailed VAT calculations.
    /// Processes VAT entries and G/L accounts to determine both VAT amount and base amount components.
    /// </summary>
    /// <param name="VATStmtLine2">VAT statement line to calculate totals for</param>
    /// <param name="TotalAmount">Returns calculated VAT total amount</param>
    /// <param name="TotalBase">Returns calculated VAT base amount</param>
    /// <param name="Level">Current calculation level for nested formulas</param>
    /// <returns>True if calculation completed successfully, false if errors occurred</returns>
    procedure CalcLineTotalWithBase(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; var TotalBase: Decimal; var CorrectionAmount: Decimal; var NetAmountLCY: Decimal; JournalTempl: Code[10]; Level: Integer): Boolean
    var
        VATReportSetup: Record "VAT Report Setup";
        Result: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcLineTotalWithBase(VATStmtLine2, TotalAmount, TotalBase, Level, RowNo, ErrorText, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Level = 0 then begin
            TotalAmount := 0;
            TotalBase := 0;
            NetAmountLCY := 0;
            CorrectionAmount := 0;
        end;
        CalcCorrection(VATStmtLine2, CorrectionAmount);
        case VATStmtLine2.Type of
            VATStmtLine2.Type::"Account Totaling":
                begin
                    GLAcc.SetFilter("No.", VATStmtLine2."Account Totaling");
                    if EndDateReq = 0D then
                        EndDate := DMY2Date(31, 12, 9999)
                    else
                        EndDate := EndDateReq;
                    GLEntry.SetCurrentKey("Journal Templ. Name", "G/L Account No.", "Posting Date", "Document Type");
                    GLEntry.SetRange("VAT Reporting Date", GetPeriodStartDate(), EndDate);
                    if JournalTempl <> '' then
                        GLEntry.SetRange("Journal Templ. Name", JournalTempl);

                    if VATStmtLine2."Document Type" = VATStmtLine2."Document Type"::"All except Credit Memo" then
                        GLEntry.SetFilter("Document Type", '<>%1', VATStmtLine2."Document Type"::"Credit Memo")
                    else
                        GLEntry.SetRange("Document Type", VATStmtLine2."Document Type");
                    OnCalcLineTotalWithBaseOnAfterGLAccSetFilters(GLAcc, VATStmtLine2, GLEntry);
                    Amount := 0;
                    Amount2 := 0;
                    if GLAcc.Find('-') and (VATStmtLine2."Account Totaling" <> '') then
                        repeat
                            GLEntry.SetRange("G/L Account No.", GLAcc."No.");
                            GLEntry.CalcSums(Amount, GLEntry."Additional-Currency Amount");
                            Amount := ConditionalAdd(Amount, GLEntry.Amount, GLEntry."Additional-Currency Amount");
                            Amount2 := Amount;
                        until GLAcc.Next() = 0;
                    OnCalcLineTotalOnBeforeCalcTotalAmountAccountTotaling(VATStmtLine2, VATEntry, Amount, UseAmtsInAddCurr);
                    CalcTotalAmount(VATStmtLine2, TotalAmount, TotalBase, NetAmountLCY);
                end;
            VATStmtLine2.Type::"VAT Entry Totaling":
                begin
                    VATEntry.Reset();
                    Amount := 0;
                    SetVATEntryKeyAndRangesForVATDate(VATStmtLine2);
                    if JournalTempl <> '' then
                        VATEntry.SetRange("Journal Templ. Name", JournalTempl);
                    VATEntry.SetRange(Type, VATStmtLine2."Gen. Posting Type");
                    if VATStmtLine2."Document Type" = VATStmtLine2."Document Type"::"All except Credit Memo" then
                        VATEntry.SetFilter("Document Type", '<>%1', VATStmtLine2."Document Type"::"Credit Memo")
                    else
                        VATEntry.SetRange("Document Type", VATStmtLine2."Document Type");
                    SetVATDate();
                    case Selection of
                        Selection::Open:
                            VATEntry.SetRange(Closed, false);
                        Selection::Closed:
                            VATEntry.SetRange(Closed, true);
                        else
                            VATEntry.SetRange(Closed);
                    end;
                    if CountryRegionFilter <> '' then
                        VATEntry.SetFilter("Country/Region Code", CountryRegionFilter);
                    OnCalcLineTotalOnVATEntryTotalingOnAfterVATEntrySetFilters(VATStmtLine2, VATEntry, Selection);
                    case VATStmtLine2."Amount Type" of
                        VATStmtLine2."Amount Type"::Amount:
                            begin
                                VATEntry.CalcSums(Base, "Additional-Currency Base", Amount, "Additional-Currency Amount");
                                Base := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
                                Amount := ConditionalAdd(0, VATEntry.Amount, VATEntry."Additional-Currency Amount");
                                if VATStmtLine2."Incl. Non Deductible VAT" then begin
                                    VATEntry.CalcSums("Non Ded. VAT Amount", "Non Ded. Source Curr. VAT Amt.");
                                    Amount := ConditionalAdd(Amount, VATEntry."Non Ded. VAT Amount", VATEntry."Non Ded. Source Curr. VAT Amt.");
                                end;
                                Amount2 := Amount;
                            end;
                        VATStmtLine2."Amount Type"::Base:
                            begin
                                VATEntry.CalcSums(Base, "Additional-Currency Base", "Base Before Pmt. Disc.");
                                Amount := ConditionalAdd(0, VATEntry.Base, VATEntry."Additional-Currency Base");
                                if VATStmtLine2."Incl. Non Deductible VAT" then begin
                                    VATEntry.CalcSums("Non Ded. VAT Amount", "Non Ded. Source Curr. VAT Amt.");
                                    Amount := ConditionalAdd(Amount, -VATEntry."Non Ded. VAT Amount", -VATEntry."Non Ded. Source Curr. VAT Amt.");
                                end;
                                Amount2 := ConditionalAdd(0, VATEntry."Base Before Pmt. Disc.", 0);
                            end;
                        VATStmtLine2."Amount Type"::"Non-Deductible Amount":
                            begin
                                VATEntry.CalcSums("Non-Deductible VAT Base", "Non-Deductible VAT Base ACY", "Non-Deductible VAT Amount", "Non-Deductible VAT Amount ACY");
                                Amount := ConditionalAdd(0, VATEntry."Non-Deductible VAT Amount", VATEntry."Non-Deductible VAT Amount ACY");
                                if VATReportSetup.Get() then;
                                if VATReportSetup."Report VAT Base" then
                                    Base := ConditionalAdd(0, VATEntry."Non-Deductible VAT Base", VATEntry."Non-Deductible VAT Base ACY");
                            end;
                        VATStmtLine2."Amount Type"::"Non-Deductible Base":
                            begin
                                VATEntry.CalcSums("Non-Deductible VAT Base", "Non-Deductible VAT Base ACY");
                                Amount := ConditionalAdd(0, VATEntry."Non-Deductible VAT Base", VATEntry."Non-Deductible VAT Base ACY");
                            end;
                        VATStmtLine2."Amount Type"::"Full Amount":
                            begin
                                VATEntry.CalcSums(
                                    Base, "Additional-Currency Base", Amount, "Additional-Currency Amount",
                                    "Non-Deductible VAT Base", "Non-Deductible VAT Base ACY", "Non-Deductible VAT Amount", "Non-Deductible VAT Amount ACY");
                                Amount :=
                                    ConditionalAdd(0, VATEntry.Amount + VATEntry."Non-Deductible VAT Amount", VATEntry."Additional-Currency Amount" + VATEntry."Non-Deductible VAT Amount ACY");
                                if VATReportSetup.Get() then;
                                if VATReportSetup."Report VAT Base" then
                                    Base := ConditionalAdd(0, VATEntry.Base + VATEntry."Non-Deductible VAT Base", VATEntry."Additional-Currency Base" + VATEntry."Non-Deductible VAT Base ACY");
                            end;
                        VATStmtLine2."Amount Type"::"Full Base":
                            begin
                                VATEntry.CalcSums(Base, "Additional-Currency Base", "Non-Deductible VAT Base", "Non-Deductible VAT Base ACY");
                                Amount := ConditionalAdd(0, VATEntry.Base + VATEntry."Non-Deductible VAT Base", VATEntry."Additional-Currency Base" + VATEntry."Non-Deductible VAT Base ACY");
                            end;
                        VATStmtLine2."Amount Type"::"Unrealized Amount":
                            begin
                                VATEntry.CalcSums("Remaining Unrealized Amount", "Add.-Curr. Rem. Unreal. Amount");
                                Amount := ConditionalAdd(0, VATEntry."Remaining Unrealized Amount", VATEntry."Add.-Curr. Rem. Unreal. Amount");
                                Amount2 := Amount;
                            end;
                        VATStmtLine2."Amount Type"::"Unrealized Base":
                            begin
                                VATEntry.CalcSums("Remaining Unrealized Base", "Add.-Curr. Rem. Unreal. Base");
                                Amount := ConditionalAdd(0, VATEntry."Remaining Unrealized Base", VATEntry."Add.-Curr. Rem. Unreal. Base");
                                Amount2 := Amount;
                            end;
                    end;
                    OnCalcLineTotalOnBeforeCalcTotalAmountVATEntryTotaling(VATStmtLine2, VATEntry, Amount, UseAmtsInAddCurr);
                    CalcTotalAmount(VATStmtLine2, TotalAmount, TotalBase, NetAmountLCY);
                end;
            VATStmtLine2.Type::"Row Totaling":
                begin
                    if Level >= ArrayLen(RowNo) then
                        exit(false);
                    Level := Level + 1;
                    RowNo[Level] := VATStmtLine2."Row No.";

                    if VATStmtLine2."Row Totaling" = '' then
                        exit(true);
                    VATStmtLine2.SetRange("Statement Template Name", VATStmtLine2."Statement Template Name");
                    VATStmtLine2.SetRange("Statement Name", VATStmtLine2."Statement Name");
                    VATStmtLine2.SetFilter("Row No.", VATStmtLine2."Row Totaling");
                    if VATStmtLine2.Find('-') then
                        repeat
                            if not CalcLineTotalWithBase(VATStmtLine2, TotalAmount, TotalBase, CorrectionAmount, NetAmountLCY, JournalTempl, Level) then begin
                                if Level > 1 then
                                    exit(false);
                                for i := 1 to ArrayLen(RowNo) do
                                    ErrorText := ErrorText + RowNo[i] + ' => ';
                                ErrorText := ErrorText + '...';
                                VATStmtLine2.FieldError("Row No.", ErrorText);
                            end;
                        until VATStmtLine2.Next() = 0;
                end;
            else
                OnCalcLineTotalWithBaseOnCaseElse(VATStmtLine2, Amount, TotalAmount, Level, PeriodSelection, StartDate, EndDate, EndDateReq, PrintInIntegers, UseAmtsInAddCurr, TotalBase);
        end;

        exit(true);
    end;

    local procedure SetVATEntryKeyAndRangesForVATDate(var VATStmtLine: Record "VAT Statement Line")
    begin
        VATEntry.SetCurrentKey("Journal Templ. Name", Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Document Type", "VAT Reporting Date");
        VATEntry.SetRange("VAT Bus. Posting Group", VATStmtLine."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATStmtLine."VAT Prod. Posting Group");
    end;

    local procedure SetVATDate()
    var
        TempDate: Date;
    begin
        if (EndDateReq <> 0D) or (StartDate <> 0D) then begin
            if PeriodSelection = PeriodSelection::"Before and Within Period" then
                TempDate := 0D
            else
                TempDate := StartDate;

            VATEntry.SetRange("VAT Reporting Date", TempDate, EndDate);
        end;
    end;

    local procedure CalcTotalAmount(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; var TotalBase: Decimal; var NetAmountLCY: Decimal)
    begin
        if VATStmtLine2."Calculate with" = 1 then begin
            Amount := -Amount;
            Amount2 := -Amount2;
        end;
        if PrintInIntegers and VATStmtLine2.Print then begin
            Amount := RoundAmount(Amount);
            Amount2 := RoundAmount(Amount2);
        end;
        TotalAmount := TotalAmount + Amount;
        if VATStmtLine2."Calculate with" = 1 then
            Base := -Base;
        if PrintInIntegers and VATStmtLine2.Print then
            Base := RoundAmount(Base);
        TotalBase := TotalBase + Base;
        NetAmountLCY := NetAmountLCY + Amount2;
    end;

    /// <summary>
    /// Initializes VAT statement report parameters with standard configuration options.
    /// Sets up report context including VAT statement template, selection criteria, and formatting preferences.
    /// </summary>
    /// <param name="NewVATStmtName">VAT statement name configuration</param>
    /// <param name="NewVATStatementLine">VAT statement line filters</param>
    /// <param name="NewSelection">Period or closing date selection type</param>
    /// <param name="NewPeriodSelection">Period range selection criteria</param>
    /// <param name="NewPrintInIntegers">Whether to print amounts as integers</param>
    /// <param name="NewUseAmtsInAddCurr">Whether to use additional reporting currency amounts</param>
    procedure InitializeRequest(var NewVATStmtName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean)
    begin
        InitializeRequest(NewVATStmtName, NewVATStatementLine, NewSelection, NewPeriodSelection, NewPrintInIntegers, NewUseAmtsInAddCurr, '');
    end;

    /// <summary>
    /// Initializes VAT statement report parameters with country/region filtering capability.
    /// Extended version including geographic filtering for multi-country VAT reporting scenarios.
    /// </summary>
    /// <param name="NewVATStmtName">VAT statement name configuration</param>
    /// <param name="NewVATStatementLine">VAT statement line filters</param>
    /// <param name="NewSelection">Period or closing date selection type</param>
    /// <param name="NewPeriodSelection">Period range selection criteria</param>
    /// <param name="NewPrintInIntegers">Whether to print amounts as integers</param>
    /// <param name="NewUseAmtsInAddCurr">Whether to use additional reporting currency amounts</param>
    /// <param name="NewCountryRegionFilter">Country/region filter for geographic reporting</param>
    procedure InitializeRequest(var NewVATStmtName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean; NewCountryRegionFilter: Text)
    begin
        ClearAll();
        "VAT Statement Name".Copy(NewVATStmtName);
        "VAT Statement Line".Copy(NewVATStatementLine);
        Selection := NewSelection;
        PeriodSelection := NewPeriodSelection;
        PrintInIntegers := NewPrintInIntegers;
        UseAmtsInAddCurr := NewUseAmtsInAddCurr;

        if NewVATStatementLine.GetFilter("Date Filter") <> '' then begin
            StartDate := NewVATStatementLine.GetRangeMin("Date Filter");
            EndDateReq := NewVATStatementLine.GetRangeMax("Date Filter");
            EndDate := EndDateReq;
        end else begin
            StartDate := 0D;
            EndDateReq := 0D;
            EndDate := DMY2Date(31, 12, 9999);
        end;
        CountryRegionFilter := NewCountryRegionFilter;
    end;

    local procedure ConditionalAdd(Amount: Decimal; AmountToAdd: Decimal; AddCurrAmountToAdd: Decimal): Decimal
    begin
        if UseAmtsInAddCurr then
            exit(Amount + AddCurrAmountToAdd);

        exit(Amount + AmountToAdd);
    end;

    protected procedure GetCurrency(): Code[10]
    begin
        if UseAmtsInAddCurr then
            exit(GLSetup."Additional Reporting Currency");

        exit('');
    end;

    local procedure CalcCorrection(VATStmtLine2: Record "VAT Statement Line"; var CorrectionAmount: Decimal)
    var
        ManualVATCorrection: Record "Manual VAT Correction";
    begin
        CalcManualVATCorrectionSums(VATStmtLine2, ManualVATCorrection);
        Amount := ConditionalAdd(0, ManualVATCorrection.Amount, ManualVATCorrection."Additional-Currency Amount");
        if VATStmtLine2."Calculate with" = VATStmtLine2."Calculate with"::"Opposite Sign" then
            Amount := -Amount;
        if PrintInIntegers and VATStmtLine2.Print then
            Amount := RoundAmount(Amount);
        CorrectionAmount := CorrectionAmount + Amount;
    end;

    local procedure CalcManualVATCorrectionSums(VATStmtLine2: Record "VAT Statement Line"; var ManualVATCorrection: Record "Manual VAT Correction")
    begin
        ManualVATCorrection.Reset();
        ManualVATCorrection.SetRange("Statement Template Name", VATStmtLine2."Statement Template Name");
        ManualVATCorrection.SetRange("Statement Name", VATStmtLine2."Statement Name");
        ManualVATCorrection.SetRange("Statement Line No.", VATStmtLine2."Line No.");
        ManualVATCorrection.SetRange("Posting Date", GetPeriodStartDate(), EndDate);
        OnCalcManualVATCorrectionSumsOnAfterManualVATCorrectionSetFilters(VATStmtLine2, ManualVATCorrection);
        ManualVATCorrection.CalcSums(Amount, "Additional-Currency Amount");
    end;

    local procedure GetPeriodStartDate(): Date
    begin
        if PeriodSelection = PeriodSelection::"Before and Within Period" then
            exit(0D);
        exit(StartDate);
    end;

    protected procedure GetAmtRoundingDirection() Direction: Text[1]
    begin
        Direction := DefaultRoundingDirectionTok;
        OnAfterGetAmtRoundingDirection(Direction);
    end;

    protected procedure RoundAmount(Amt: Decimal): Decimal
    begin
        exit(Round(Amt, 1, GetAmtRoundingDirection()));
    end;

    /// <summary>
    /// Integration event raised before calculating total amounts for VAT entry totaling lines.
    /// Enables custom calculation logic and amount modifications before standard VAT entry processing.
    /// </summary>
    /// <param name="VATStmtLine">VAT statement line being calculated</param>
    /// <param name="VATEntry">VAT entry record used for totaling</param>
    /// <param name="Amount">Current calculated amount, can be modified</param>
    /// <param name="UseAmtsInAddCurr">Whether additional reporting currency amounts are used</param>
    [IntegrationEvent(false, false)]
    local procedure OnCalcManualVATCorrectionSumsOnAfterManualVATCorrectionSetFilters(VATStmtLine: Record "VAT Statement Line"; var ManualVATCorrection: Record "Manual VAT Correction")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcLineTotalOnBeforeCalcTotalAmountVATEntryTotaling(VATStmtLine: Record "VAT Statement Line"; var VATEntry: Record "VAT Entry"; var Amount: Decimal; UseAmtsInAddCurr: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before calculating total amounts for G/L account totaling lines.
    /// Enables custom calculation logic and amount modifications before standard G/L account processing.
    /// </summary>
    /// <param name="VATStmtLine">VAT statement line being calculated</param>
    /// <param name="VATEntry">VAT entry record used for account totaling</param>
    /// <param name="Amount">Current calculated amount, can be modified</param>
    /// <param name="UseAmtsInAddCurr">Whether additional reporting currency amounts are used</param>
    [IntegrationEvent(false, false)]
    local procedure OnCalcLineTotalOnBeforeCalcTotalAmountAccountTotaling(VATStmtLine: Record "VAT Statement Line"; var VATEntry: Record "VAT Entry"; var Amount: Decimal; UseAmtsInAddCurr: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after setting filters on VAT entries for VAT entry totaling calculations.
    /// Enables additional filter modifications or custom VAT entry selection logic.
    /// </summary>
    /// <param name="VATStmtLine">VAT statement line being processed</param>
    /// <param name="VATEntry">VAT entry record with applied filters</param>
    /// <param name="Selection">Selection type determining filter criteria</param>
    [IntegrationEvent(false, false)]
    local procedure OnCalcLineTotalOnVATEntryTotalingOnAfterVATEntrySetFilters(VATStmtLine: Record "VAT Statement Line"; var VATEntry: Record "VAT Entry"; Selection: Enum "VAT Statement Report Selection")
    begin
    end;

    /// <summary>
    /// Integration event raised for custom VAT statement line types not handled by standard calculation logic.
    /// Enables implementation of custom totaling and calculation methods for extended line types.
    /// </summary>
    /// <param name="VATStmtLine2">VAT statement line being calculated</param>
    /// <param name="Amount">Current amount calculation, can be modified</param>
    /// <param name="TotalAmount">Running total amount accumulator</param>
    /// <param name="Level">Current calculation nesting level</param>
    /// <param name="PeriodSelection">Period selection criteria</param>
    /// <param name="StartDate">Period start date</param>
    /// <param name="EndDate">Period end date</param>
    /// <param name="EndDateReq">Requested end date</param>
    /// <param name="PrintInIntegers">Whether amounts are printed as integers</param>
    /// <param name="UseAmtsInAddCurr">Whether additional currency amounts are used</param>
    /// <param name="TotalBase">Running total base amount accumulator</param>
    [IntegrationEvent(false, false)]
    local procedure OnCalcLineTotalWithBaseOnCaseElse(var VATStmtLine2: Record "VAT Statement Line"; var Amount: Decimal; var TotalAmount: Decimal; Level: Integer; PeriodSelection: Enum "VAT Statement Report Period Selection"; StartDate: Date; EndDate: Date; EndDateReq: Date; PrintInIntegers: Boolean; UseAmtsInAddCurr: Boolean; var TotalBase: Decimal)
    begin
    end;

    /// <summary>
    /// Integration event raised after setting filters on G/L accounts for account totaling calculations.
    /// Enables additional filter modifications or custom G/L account selection logic.
    /// </summary>
    /// <param name="GLAccount">G/L account record with applied filters</param>
    /// <param name="VATStatementLine2">VAT statement line being processed</param>
    [IntegrationEvent(false, false)]
    local procedure OnCalcLineTotalWithBaseOnAfterGLAccSetFilters(var GLAccount: Record "G/L Account"; VATStatementLine2: Record "VAT Statement Line"; var GLEntry: Record "G/L Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after determining amount rounding direction for VAT statement calculations.
    /// Enables custom rounding direction logic based on specific business requirements.
    /// </summary>
    /// <param name="Direction">Rounding direction character, can be modified</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAmtRoundingDirection(var Direction: Text[1]);
    begin
    end;

    /// <summary>
    /// Integration event raised before calculating VAT statement line totals with base amounts.
    /// Enables complete override of line total calculation logic with custom implementations.
    /// </summary>
    /// <param name="VATStmtLine2">VAT statement line being calculated</param>
    /// <param name="TotalAmount">Total VAT amount result</param>
    /// <param name="TotalBase">Total base amount result</param>
    /// <param name="Level">Current calculation nesting level</param>
    /// <param name="RowNo">Row number array for error tracking</param>
    /// <param name="ErrorText">Error message text for validation failures</param>
    /// <param name="Result">Calculation success result</param>
    /// <param name="IsHandled">Set to true to skip standard calculation logic</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeCalcLineTotalWithBase(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; var TotalBase: Decimal; Level: Integer; var RowNo: array[6] of Code[10]; var ErrorText: Text[80]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}


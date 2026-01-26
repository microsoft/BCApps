// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;
// using Microsoft.Foundation.Enums;
using Microsoft.Utilities;
#if not CLEAN27
using System.Environment.Configuration;
#endif

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
            column(StmtTmplName_VATStmtName; "Statement Template Name")
            {
            }
            column(Name_VATStmtName; Name)
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
                column(Heading2; Heading2)
                {
                }
                column(HeaderText; HeaderText)
                {
                }
                column(AllAmountsAreIn; AllAmountsAreInLbl)
                {
                }
                column(VATStmtLineFilter; VATStmtLineFilter)
                {
                }
                column(VATStmtLineDesc_VATStmtLine; Description)
                {
                    IncludeCaption = true;
                }
                column(TotalAmount; TotalAmount)
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(Selection; Selection)
                {
                }
                column(PrintInIntegers; PrintInIntegers)
                {
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
                column(StmtName_VATStmtLine; "Statement Name")
                {
                }
                column(VATStatementCaption; VATStatementCaptionLbl)
                {
                }
                column(TotalAmountCaption; TotalAmountCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcLineTotal("VAT Statement Line", TotalAmount, 0);

                    if "Round Factor" = "Round Factor"::"1" then
                        if (Abs(TotalAmount) mod 1) <= 0.5 then
                            TotalAmount := Round(TotalAmount, 1, '<')
                        else
                            TotalAmount := Round(TotalAmount, 1, '>');

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
                            ToolTip = 'Specifies the start date for the time interval for VAT statement lines in the report.';

                            trigger OnValidate()
                            begin
                                if StartDate <> 0D then
                                    VATPeriod := '';
                            end;
                        }
                        field(EndingDate; EndDateReq)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the end date for the time interval for VAT statement lines in the report.';

                            trigger OnValidate()
                            begin
                                if EndDateReq <> 0D then
                                    VATPeriod := '';
                            end;
                        }
                    }
                    field(Selection; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        Importance = Additional;
                        ToolTip = 'Specifies if you want to include open VAT entries in the report.';

                        trigger OnValidate()
                        begin
                            if Selection in [Selection::"Open and Closed", Selection::Open] then
                                VATPeriod := '';
                        end;
                    }
                    field(PeriodSelection; PeriodSelection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        Importance = Additional;
                        ToolTip = 'Specifies if you want to include VAT entries from before the specified time period in the report.';

                        trigger OnValidate()
                        begin
                            if PeriodSelection = PeriodSelection::"Before and Within Period" then
                                VATPeriod := '';
                        end;
                    }
#if not CLEAN27
                    field(VatPeriod; VATPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vat Period';
                        Importance = Additional;
                        LookupPageID = "Periodic VAT Settlement List";
                        TableRelation = "Periodic Settlement VAT Entry";
                        ToolTip = 'Specifies the period of time that defines the VAT period.';
                        Visible = not VATSettlementByActivityCodeIsEnabled;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Replaced by VAT settlement per activity code.';
                        ObsoleteTag = '27.0';

                        trigger OnValidate()
                        begin
                            if VATPeriod <> '' then begin
                                Selection := Selection::Closed;
                                PeriodSelection := PeriodSelection::"Within Period";
                                StartDate := 0D;
                                EndDateReq := 0D;
                            end;
                        end;
                    }
                    field(VatPeriodByActivityCode; VATPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vat Period';
                        Importance = Additional;
                        LookupPageID = "Periodic VAT Settl. List";
                        TableRelation = "Periodic VAT Settlement Entry";
                        ToolTip = 'Specifies the period of time that defines the VAT period.';
                        Visible = VATSettlementByActivityCodeIsEnabled;

                        trigger OnValidate()
                        begin
                            if VATPeriod <> '' then begin
                                Selection := Selection::Closed;
                                PeriodSelection := PeriodSelection::"Within Period";
                                StartDate := 0D;
                                EndDateReq := 0D;
                            end;
                        end;
                    }
#else
                    field(VatPeriodByActivityCode; VATPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vat Period';
                        Importance = Additional;
                        LookupPageID = "Periodic VAT Settl. List";
                        TableRelation = "Periodic VAT Settlement Entry";
                        ToolTip = 'Specifies the period of time that defines the VAT period.';

                        trigger OnValidate()
                        begin
                            if VATPeriod <> '' then begin
                                Selection := Selection::Closed;
                                PeriodSelection := PeriodSelection::"Within Period";
                                StartDate := 0D;
                                EndDateReq := 0D;
                            end;
                        end;
                    }
#endif
                    field(ActivityCode; ActivityCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Activity Code';
                        Importance = Additional;
                        TableRelation = "Activity Code";
                        ToolTip = 'Specifies the activity code that is assigned to the VAT settlement transaction.';
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

        trigger OnOpenPage()
        begin
            PeriodSelection := PeriodSelection::"Within Period";
        end;
    }

    labels
    {
    }

#if not CLEAN27
    trigger OnInitReport()
    var
        FeatureManagementIT: Codeunit "Feature Management IT";
    begin
        VATSettlementByActivityCodeIsEnabled := FeatureManagementIT.IsVATSettlementPerActivityCodeFeatureEnabled();
    end;
#endif

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
        if Selection = Selection::Closed then
            Heading := 'VAT Period : ' + VATPeriod
    end;

    var
        GLAcc: Record "G/L Account";
        VATEntry: Record "VAT Entry";
        GLSetup: Record "General Ledger Setup";
        VATStmtLine: Record "VAT Statement Line";
        VATStmtLineFilter: Text;
        Heading: Text[50];
        Amount: Decimal;
        RowNo: array[6] of Code[10];
        ErrorText: Text[80];
        i: Integer;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        Heading2: Text[50];
#if not CLEAN27
        PeriodicSettlVATEntry: Record "Periodic Settlement VAT Entry";
        PeriodVATSettlEntry: Record "Periodic VAT Settlement Entry";
#else
        PeriodVATSettlEntry: Record "Periodic VAT Settlement Entry";
#endif
#if not CLEAN27
        VATSettlementByActivityCodeIsEnabled: Boolean;
#endif
        VATPeriod: Code[10];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'VAT entries before and within the period';
        Text004: Label 'VAT entries within the period';
        Text005: Label 'Period: %1..%2';
#pragma warning restore AA0470
#pragma warning restore AA0074        
        AllAmountsAreInLbl: Label 'All amounts are in';
        VATStatementCaptionLbl: Label 'VAT Statement';
        TotalAmountCaptionLbl: Label 'Amount';

    protected var
        EndDate: Date;
        StartDate: Date;
        EndDateReq: Date;
        HeaderText: Text[50];
        PrintInIntegers: Boolean;
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        Selection: Enum "VAT Statement Report Selection";
        TotalAmount: Decimal;
        UseAmtsInAddCurr: Boolean;
        ActivityCode: Code[6];
        CountryRegionFilter: Text;

    /// <summary>
    /// Calculates the total amount for a VAT statement line based on configured calculation rules.
    /// Processes VAT entries and G/L accounts according to line type and formula settings.
    /// </summary>
    /// <param name="VATStmtLine2">VAT statement line to calculate total for</param>
    /// <param name="TotalAmount">Returns calculated total amount</param>
    /// <param name="Level">Current calculation level for nested formulas</param>
    /// <returns>True if calculation completed successfully, false if errors occurred</returns>
    procedure CalcLineTotal(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal; Level: Integer): Boolean
    var
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        Result: Boolean;
        IsHandled: Boolean;
        DummyBase: Decimal;
    begin
        IsHandled := false;
        OnBeforeCalcLineTotalWithBase(VATStmtLine2, TotalAmount, DummyBase, Level, RowNo, ErrorText, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Level = 0 then
            TotalAmount := 0;
        Amount := 0;
        case VATStmtLine2.Type of
            VATStmtLine2.Type::"Account Totaling":
                begin
                    GLAcc.SetFilter("No.", VATStmtLine2."Account Totaling");
                    if EndDateReq = 0D then
                        EndDate := DMY2Date(31, 12, 9999)
                    else
                        EndDate := EndDateReq;
                    GLAcc.SetRange("Date Filter", StartDate, EndDate);
                    OnCalcLineTotalWithBaseOnAfterGLAccSetFilters(GLAcc, VATStmtLine2);
                    Amount := 0;
                    if GLAcc.Find('-') and (VATStmtLine2."Account Totaling" <> '') then
                        repeat
                            GLAcc.CalcFields("Net Change", "Additional-Currency Net Change");
                            Amount := ConditionalAdd(Amount, GLAcc."Net Change", GLAcc."Additional-Currency Net Change");
                        until GLAcc.Next() = 0;
                    OnCalcLineTotalOnBeforeCalcTotalAmountAccountTotaling(VATStmtLine2, VATEntry, Amount, UseAmtsInAddCurr);
                    CalcTotalAmount(VATStmtLine2, TotalAmount);
                end;
            VATStmtLine2.Type::"VAT Entry Totaling":
                begin
                    VATEntry.Reset();
                    Amount := 0;
                    if VATEntry.SetCurrentKey(
                         Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Posting Date")
                    then begin
                        VATEntry.SetRange("VAT Bus. Posting Group", VATStmtLine2."VAT Bus. Posting Group");
                        VATEntry.SetRange("VAT Prod. Posting Group", VATStmtLine2."VAT Prod. Posting Group");
                    end else begin
                        VATEntry.SetCurrentKey(
                          Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group",
                          "Tax Jurisdiction Code", "Use Tax", "Tax Liable", "VAT Period", "Operation Occurred Date");
                        VATEntry.SetRange("Tax Jurisdiction Code", VATStmtLine2."Tax Jurisdiction Code");
                        VATEntry.SetRange("Use Tax", VATStmtLine2."Use Tax");
                    end;
                    VATEntry.SetRange(Type, VATStmtLine2."Gen. Posting Type");
                    if GLSetup."Use Activity Code" then
                        VATEntry.SetFilter("Activity Code", "VAT Statement Line".GetFilter("Activity Code Filter"));
                    if (EndDateReq = 0D) and (StartDate = 0D) then
                        VATEntry.SetRange("Operation Occurred Date")
                    else
                        if PeriodSelection = PeriodSelection::"Before and Within Period" then
                            VATEntry.SetRange("Operation Occurred Date", 0D, EndDate)
                        else
                            VATEntry.SetRange("Operation Occurred Date", StartDate, EndDate);

                    case Selection of
                        Selection::Open:
                            VATEntry.SetRange(Closed, false);
                        Selection::Closed:
                            begin
                                VATEntry.SetRange(Closed, true);
                                if VATPeriod <> '' then begin
                                    VATEntry.SetRange("VAT Period", VATPeriod);
                                    VATEntry.SetRange("Operation Occurred Date");
                                end;
                            end;
                        else
                            VATEntry.SetRange(Closed);
                    end;
                    if CountryRegionFilter <> '' then
                        VATEntry.SetFilter("Country/Region Code", CountryRegionFilter);
                    OnCalcLineTotalOnVATEntryTotalingOnAfterVATEntrySetFilters(VATStmtLine2, VATEntry, Selection);
                    case VATStmtLine2."Amount Type" of
                        VATStmtLine2."Amount Type"::Amount:
                            begin
                                VATEntry.CalcSums(Amount, "Additional-Currency Amount");
                                Amount := ConditionalAdd(0, VATEntry.Amount, VATEntry."Additional-Currency Amount");
                            end;
                        VATStmtLine2."Amount Type"::Base:
                            begin
                                VATEntry.CalcSums(Base, "Nondeductible Base", "Additional-Currency Base", "Add. Curr. Nondeductible Base");
                                Amount := ConditionalAdd(0, VATEntry.Base + VATEntry."Nondeductible Base",
                                    VATEntry."Additional-Currency Base" + VATEntry."Add. Curr. Nondeductible Base");
                            end;
                        VATStmtLine2."Amount Type"::"Full Amount":
                            if NonDeductibleVAT.IsNonDeductibleVATEnabled() then begin
                                VATEntry.CalcSums(
                                    Amount, "Additional-Currency Amount", "Non-Deductible VAT Amount", "Non-Deductible VAT Amount ACY");
                                Amount :=
                                    ConditionalAdd(0, VATEntry.Amount + VATEntry."Non-Deductible VAT Amount", VATEntry."Additional-Currency Amount" + VATEntry."Non-Deductible VAT Amount ACY");
                            end else begin
                                VATEntry.CalcSums(
                                    Amount, "Additional-Currency Amount", "Nondeductible Amount", "Add. Curr. Nondeductible Amt.");
                                Amount :=
                                    ConditionalAdd(0, VATEntry.Amount + VATEntry."Nondeductible Amount", VATEntry."Additional-Currency Amount" + VATEntry."Add. Curr. Nondeductible Amt.");
                            end;
                        VATStmtLine2."Amount Type"::"Full Base":
                            if NonDeductibleVAT.IsNonDeductibleVATEnabled() then begin
                                VATEntry.CalcSums(Base, "Additional-Currency Base", "Non-Deductible VAT Base", "Non-Deductible VAT Base ACY");
                                Amount := ConditionalAdd(0, VATEntry.Base + VATEntry."Non-Deductible VAT Base", VATEntry."Additional-Currency Base" + VATEntry."Non-Deductible VAT Base ACY");
                            end else begin
                                VATEntry.CalcSums(Base, "Additional-Currency Base", "Nondeductible Base", "Add. Curr. Nondeductible Base");
                                Amount := ConditionalAdd(0, VATEntry.Base + VATEntry."Nondeductible Base", VATEntry."Additional-Currency Base" + VATEntry."Add. Curr. Nondeductible Base");
                            end;
                        VATStmtLine2."Amount Type"::"Unrealized Amount":
                            begin
                                VATEntry.CalcSums("Remaining Unrealized Amount", "Add.-Curr. Rem. Unreal. Amount");
                                Amount := ConditionalAdd(0, VATEntry."Remaining Unrealized Amount", VATEntry."Add.-Curr. Rem. Unreal. Amount");
                            end;
                        VATStmtLine2."Amount Type"::"Unrealized Base":
                            begin
                                VATEntry.CalcSums("Remaining Unrealized Base", "Add.-Curr. Rem. Unreal. Base");
                                Amount := ConditionalAdd(0, VATEntry."Remaining Unrealized Base", VATEntry."Add.-Curr. Rem. Unreal. Base");
                            end;
                        VATStmtLine2."Amount Type"::"Non-Deductible Amount":
                            if NonDeductibleVAT.IsNonDeductibleVATEnabled() then begin
                                VATEntry.CalcSums("Non-Deductible VAT Amount", "Non-Deductible VAT Amount ACY");
                                Amount := ConditionalAdd(0, VATEntry."Non-Deductible VAT Amount", VATEntry."Non-Deductible VAT Amount ACY");
                            end else begin
                                VATEntry.CalcSums("Nondeductible Amount", "Add. Curr. Nondeductible Amt.");
                                Amount := ConditionalAdd(0, VATEntry."Nondeductible Amount", VATEntry."Add. Curr. Nondeductible Amt.");
                            end;
                        VATStmtLine2."Amount Type"::"Non-Deductible Base":
                            if NonDeductibleVAT.IsNonDeductibleVATEnabled() then begin
                                VATEntry.CalcSums("Non-Deductible VAT Base", "Non-Deductible VAT Base ACY");
                                Amount := ConditionalAdd(0, VATEntry."Non-Deductible VAT Base", VATEntry."Non-Deductible VAT Base ACY");
                            end else begin
                                VATEntry.CalcSums("Nondeductible Base", "Add. Curr. Nondeductible Base");
                                Amount := ConditionalAdd(0, VATEntry."Nondeductible Base", VATEntry."Add. Curr. Nondeductible Base");
                            end;
                    end;
                    OnCalcLineTotalOnBeforeCalcTotalAmountVATEntryTotaling(VATStmtLine2, VATEntry, Amount, UseAmtsInAddCurr);
                    CalcTotalAmount(VATStmtLine2, TotalAmount);
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
                            if not CalcLineTotal(VATStmtLine2, TotalAmount, Level) then begin
                                if Level > 1 then
                                    exit(false);
                                for i := 1 to ArrayLen(RowNo) do
                                    ErrorText := ErrorText + RowNo[i] + ' => ';
                                ErrorText := ErrorText + '...';
                                VATStmtLine2.FieldError("Row No.", ErrorText);
                            end;
                        until VATStmtLine2.Next() = 0;
                end;
            VATStmtLine2.Type::Description:
                ;

            VATStmtLine2.Type::"Periodic VAT Settl.":    // IT
                begin
                    case Selection of
                        Selection::Open:

#if not CLEAN27
                            if VATSettlementByActivityCodeIsEnabled then begin
                                PeriodVATSettlEntry.Reset();
                                PeriodVATSettlEntry.SetCurrentKey("VAT Period Closed");
                                PeriodVATSettlEntry.SetRange("VAT Period Closed", false);
                                PeriodVATSettlEntry.SetRange("Activity Code", ActivityCode);
                            end else begin
                                PeriodicSettlVATEntry.Reset();
                                PeriodicSettlVATEntry.SetCurrentKey("VAT Period Closed");
                                PeriodicSettlVATEntry.SetRange("VAT Period Closed", false);
                            end;
#else
                            begin
                                PeriodVATSettlEntry.Reset();
                                PeriodVATSettlEntry.SetCurrentKey("VAT Period Closed");
                                PeriodVATSettlEntry.SetRange("VAT Period Closed", false);
                                PeriodVATSettlEntry.SetRange("Activity Code", ActivityCode);
                            end;
#endif

                        Selection::Closed:
#if not CLEAN27
                            if VATSettlementByActivityCodeIsEnabled then begin
                                PeriodVATSettlEntry.Reset();
                                PeriodVATSettlEntry.SetRange("VAT Period", VATPeriod);
                                PeriodVATSettlEntry.SetRange("Activity Code", ActivityCode);
                            end else begin
                                PeriodicSettlVATEntry.Reset();
                                PeriodicSettlVATEntry.SetRange("VAT Period", VATPeriod);
                            end;
#else
                            begin
                                PeriodVATSettlEntry.Reset();
                                PeriodVATSettlEntry.SetRange("VAT Period", VATPeriod);
                                PeriodVATSettlEntry.SetRange("Activity Code", ActivityCode);
                            end;
#endif
                    end;

                    case VATStmtLine2."Gen. Posting Type" of
                        VATStmtLine2."Gen. Posting Type"::"Prior Period Input VAT":
#if not CLEAN27
                            if VATSettlementByActivityCodeIsEnabled then begin
                                PeriodVATSettlEntry.CalcSums("Prior Period Input VAT", "Add Curr. Prior Per. Inp. VAT");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodVATSettlEntry."Prior Period Input VAT", PeriodVATSettlEntry."Add Curr. Prior Per. Inp. VAT");
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end else begin
                                PeriodicSettlVATEntry.CalcSums("Prior Period Input VAT", "Add Curr. Prior Per. Inp. VAT");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Prior Period Input VAT", PeriodicSettlVATEntry."Add Curr. Prior Per. Inp. VAT");
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#else
                            begin
                                PeriodVATSettlEntry.CalcSums("Prior Period Input VAT", "Add Curr. Prior Per. Inp. VAT");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodVATSettlEntry."Prior Period Input VAT", PeriodVATSettlEntry."Add Curr. Prior Per. Inp. VAT");
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#endif
                        VATStmtLine2."Gen. Posting Type"::"Prior Period Output VAT":
#if not CLEAN27
                            if VATSettlementByActivityCodeIsEnabled then begin
                                PeriodVATSettlEntry.CalcSums("Prior Period Output VAT", "Add Curr. Prior Per. Out VAT");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodVATSettlEntry."Prior Period Output VAT", PeriodVATSettlEntry."Add Curr. Prior Per. Out VAT");
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end else begin
                                PeriodicSettlVATEntry.CalcSums("Prior Period Output VAT", "Add Curr. Prior Per. Out VAT");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Prior Period Output VAT", PeriodicSettlVATEntry."Add Curr. Prior Per. Out VAT");
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#else
                            begin
                                PeriodVATSettlEntry.CalcSums("Prior Period Output VAT", "Add Curr. Prior Per. Out VAT");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodVATSettlEntry."Prior Period Output VAT", PeriodVATSettlEntry."Add Curr. Prior Per. Out VAT");
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#endif
                        VATStmtLine2."Gen. Posting Type"::Paid:
#if not CLEAN27
                            if VATSettlementByActivityCodeIsEnabled then begin
                                PeriodVATSettlEntry.CalcSums("Paid Amount", "Add-Curr. Paid. Amount");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodVATSettlEntry."Paid Amount", PeriodVATSettlEntry."Add-Curr. Paid. Amount");
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end else begin
                                PeriodicSettlVATEntry.CalcSums("Paid Amount", "Add-Curr. Paid. Amount");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Paid Amount", PeriodicSettlVATEntry."Add-Curr. Paid. Amount");
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#else
                            begin
                                PeriodVATSettlEntry.CalcSums("Paid Amount", "Add-Curr. Paid. Amount");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodVATSettlEntry."Paid Amount", PeriodVATSettlEntry."Add-Curr. Paid. Amount");
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#endif
                        VATStmtLine2."Gen. Posting Type"::Advanced:
#if not CLEAN27
                            if VATSettlementByActivityCodeIsEnabled then begin
                                PeriodVATSettlEntry.CalcSums("Advanced Amount", "Add-Curr. Advanced Amount");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodVATSettlEntry."Advanced Amount", PeriodVATSettlEntry."Add-Curr. Advanced Amount");
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end else begin
                                PeriodicSettlVATEntry.CalcSums("Advanced Amount", "Add-Curr. Advanced Amount");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Advanced Amount", PeriodicSettlVATEntry."Add-Curr. Advanced Amount");
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#else
                            begin
                                PeriodVATSettlEntry.CalcSums("Advanced Amount", "Add-Curr. Advanced Amount");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodVATSettlEntry."Advanced Amount", PeriodVATSettlEntry."Add-Curr. Advanced Amount");
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#endif
                        VATStmtLine2."Gen. Posting Type"::"Credit VAT Compens.":
#if not CLEAN27
                            if VATSettlementByActivityCodeIsEnabled then begin
                                PeriodicSettlVATEntry.CalcSums("Credit VAT Compensation");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Credit VAT Compensation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end else begin
                                PeriodicSettlVATEntry.CalcSums("Credit VAT Compensation");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Credit VAT Compensation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#else
                            begin
                                PeriodVATSettlEntry.CalcSums("Credit VAT Compensation");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodVATSettlEntry."Credit VAT Compensation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#endif
                        VATStmtLine2."Gen. Posting Type"::"Payab. VAT Variation":
#if not CLEAN27
                            if VATSettlementByActivityCodeIsEnabled then begin
                                PeriodVATSettlEntry.CalcSums("Payable VAT Variation");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodVATSettlEntry."Payable VAT Variation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end else begin
                                PeriodicSettlVATEntry.CalcSums("Payable VAT Variation");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Payable VAT Variation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#else
                            begin
                                PeriodVATSettlEntry.CalcSums("Payable VAT Variation");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodVATSettlEntry."Payable VAT Variation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#endif
                        VATStmtLine2."Gen. Posting Type"::"Deduc. VAT Variation.":
#if not CLEAN27
                            if VATSettlementByActivityCodeIsEnabled then begin
                                PeriodVATSettlEntry.CalcSums("Deductible VAT Variation");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodVATSettlEntry."Deductible VAT Variation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end else begin
                                PeriodicSettlVATEntry.CalcSums("Deductible VAT Variation");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Deductible VAT Variation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#else
                            begin
                                PeriodVATSettlEntry.CalcSums("Deductible VAT Variation");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodVATSettlEntry."Deductible VAT Variation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#endif
                        VATStmtLine2."Gen. Posting Type"::"Tax Debit Variat.":
#if not CLEAN27
                            if VATSettlementByActivityCodeIsEnabled then begin
                                PeriodVATSettlEntry.CalcSums("Tax Debit Variation");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodVATSettlEntry."Tax Debit Variation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end else begin
                                PeriodicSettlVATEntry.CalcSums("Tax Debit Variation");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Tax Debit Variation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#else
                            begin
                                PeriodVATSettlEntry.CalcSums("Tax Debit Variation");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodVATSettlEntry."Tax Debit Variation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#endif
                        VATStmtLine2."Gen. Posting Type"::"Tax Credit Variation":
#if not CLEAN27
                            if VATSettlementByActivityCodeIsEnabled then begin
                                PeriodVATSettlEntry.CalcSums("Tax Credit Variation");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodVATSettlEntry."Tax Credit Variation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end else begin
                                PeriodicSettlVATEntry.CalcSums("Tax Credit Variation");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Tax Credit Variation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#else
                            begin
                                PeriodVATSettlEntry.CalcSums("Tax Credit Variation");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodVATSettlEntry."Tax Credit Variation", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#endif
                        VATStmtLine2."Gen. Posting Type"::"Tax Deb. Variat. Int.":
#if not CLEAN27
                            if VATSettlementByActivityCodeIsEnabled then begin
                                PeriodVATSettlEntry.CalcSums("Tax Debit Variation Interest");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodVATSettlEntry."Tax Debit Variation Interest", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end else begin
                                PeriodicSettlVATEntry.CalcSums("Tax Debit Variation Interest");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Tax Debit Variation Interest", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#else
                            begin
                                PeriodVATSettlEntry.CalcSums("Tax Debit Variation Interest");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodVATSettlEntry."Tax Debit Variation Interest", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#endif
                        VATStmtLine2."Gen. Posting Type"::"Unpaid VAT Prev. Periods":
#if not CLEAN27
                            if VATSettlementByActivityCodeIsEnabled then begin
                                PeriodVATSettlEntry.CalcSums("Unpaid VAT Previous Periods");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodVATSettlEntry."Unpaid VAT Previous Periods", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end else begin
                                PeriodicSettlVATEntry.CalcSums("Unpaid VAT Previous Periods");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Unpaid VAT Previous Periods", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#else
                            begin
                                PeriodVATSettlEntry.CalcSums("Unpaid VAT Previous Periods");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodVATSettlEntry."Unpaid VAT Previous Periods", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#endif
                        VATStmtLine2."Gen. Posting Type"::"Omit Payable Int.":
#if not CLEAN27
                            if VATSettlementByActivityCodeIsEnabled then begin
                                PeriodVATSettlEntry.CalcSums("Omit VAT Payable Interest");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodVATSettlEntry."Omit VAT Payable Interest", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end else begin
                                PeriodicSettlVATEntry.CalcSums("Omit VAT Payable Interest");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Omit VAT Payable Interest", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#else
                            begin
                                PeriodVATSettlEntry.CalcSums("Omit VAT Payable Interest");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodVATSettlEntry."Omit VAT Payable Interest", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#endif
                        VATStmtLine2."Gen. Posting Type"::"Special Credit":
#if not CLEAN27
                            if VATSettlementByActivityCodeIsEnabled then begin
                                PeriodVATSettlEntry.CalcSums("Special Credit");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodVATSettlEntry."Special Credit", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end else begin
                                PeriodicSettlVATEntry.CalcSums("Special Credit");
                                Amount :=
                                ConditionalAdd(
                                    0, PeriodicSettlVATEntry."Special Credit", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#else
                            begin
                                PeriodVATSettlEntry.CalcSums("Special Credit");
                                Amount :=
                                  ConditionalAdd(
                                    0, PeriodVATSettlEntry."Special Credit", 0);
                                CalcTotalAmount(VATStmtLine2, TotalAmount);
                            end;
#endif
                        else
                            Amount := 0;

                    end;
                end;
            else
                OnCalcLineTotalWithBaseOnCaseElse(VATStmtLine2, Amount, TotalAmount, Level, PeriodSelection, StartDate, EndDate, EndDateReq, PrintInIntegers, UseAmtsInAddCurr);
        end;

        exit(true);
    end;

    local procedure CalcTotalAmount(VATStmtLine2: Record "VAT Statement Line"; var TotalAmount: Decimal)
    begin
        if VATStmtLine2."Calculate with" = 1 then
            Amount := -Amount;
        if PrintInIntegers and VATStmtLine2.Print then
            Amount := Round(Amount, 1, '<');
        TotalAmount := TotalAmount + Amount;
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
    procedure InitializeRequest(var NewVATStmtName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean; NewVATPeriod: Code[10])
    begin
        InitializeRequest(NewVATStmtName, NewVATStatementLine, NewSelection, NewPeriodSelection, NewPrintInIntegers, NewUseAmtsInAddCurr, NewVATPeriod, '');
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
    procedure InitializeRequest(var NewVATStmtName: Record "VAT Statement Name"; var NewVATStatementLine: Record "VAT Statement Line"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewPrintInIntegers: Boolean; NewUseAmtsInAddCurr: Boolean; NewVATPeriod: Code[10]; NewCountryRegionFilter: Text[250])
    begin
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
        VATPeriod := NewVATPeriod;
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

    /// <summary>
    /// Integration event raised before calculating total amounts for VAT entry totaling lines.
    /// Enables custom calculation logic and amount modifications before standard VAT entry processing.
    /// </summary>
    /// <param name="VATStmtLine">VAT statement line being calculated</param>
    /// <param name="VATEntry">VAT entry record used for totaling</param>
    /// <param name="Amount">Current calculated amount, can be modified</param>
    /// <param name="UseAmtsInAddCurr">Whether additional reporting currency amounts are used</param>
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
    local procedure OnCalcLineTotalWithBaseOnCaseElse(var VATStmtLine2: Record "VAT Statement Line"; var Amount: Decimal; var TotalAmount: Decimal; Level: Integer; PeriodSelection: Enum "VAT Statement Report Period Selection"; StartDate: Date; EndDate: Date; EndDateReq: Date; PrintInIntegers: Boolean; UseAmtsInAddCurr: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after setting filters on G/L accounts for account totaling calculations.
    /// Enables additional filter modifications or custom G/L account selection logic.
    /// </summary>
    /// <param name="GLAccount">G/L account record with applied filters</param>
    /// <param name="VATStatementLine2">VAT statement line being processed</param>
    [IntegrationEvent(false, false)]
    local procedure OnCalcLineTotalWithBaseOnAfterGLAccSetFilters(var GLAccount: Record "G/L Account"; VATStatementLine2: Record "VAT Statement Line")
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


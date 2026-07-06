// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Reports;

using Microsoft.CostAccounting.Account;
using Microsoft.Finance.GeneralLedger.Setup;

report 1123 "Cost Acctg. Stmt. per Period"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CostAccounting/Reports/CostAcctgStmtperPeriod.rdlc';
    ApplicationArea = CostAccounting;
    Caption = 'Cost Acctg. Stmt. per Period';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Cost Type"; "Cost Type")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", Type, "Date Filter", "Cost Center Filter", "Cost Object Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FilterTxt; FilterTxt)
            {
            }
            column(ComparePeriodTxt; ComparePeriodTxt)
            {
            }
            column(ActPeriodTxt; ActPeriodTxt)
            {
            }
            column(ShowAddCurr; ShowAddCurr)
            {
            }
            column(LcyCode_GLSetup; GLSetup."LCY Code")
            {
            }
            column(AllAmountare; AllAmountareLbl)
            {
            }
            column(AddRepCurr_GLSetup; GLSetup."Additional Reporting Currency")
            {
            }
            column(ActAmt; -ActAmt)
            {
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(ActAmtControl9; ActAmt)
            {
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(Pct; Pct)
            {
                DecimalPlaces = 1 : 1;
            }
            column(DiffAmount; DiffAmount)
            {
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(CompareAmt; -CompareAmt)
            {
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(CompareAmtControl12; CompareAmt)
            {
                AutoFormatType = 1;
                DecimalPlaces = 0 : 0;
            }
            column(PadstrIndentation2Name; PadStr('', Indentation * 2) + Name)
            {
            }
            column(No_CostType; "No.")
            {
            }
            column(LineTypeInt; LineTypeInt)
            {
            }
            column(CostAcctgStmtperPeriodCaption; CostAcctgStmtperPeriodCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(IncreaseDecreaseCaption; IncreaseDecreaseCaptionLbl)
            {
            }
            column(PercentOfCaption; PercentOfCaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(NumberCaption; NumberCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                ActAmt := CalcAmount("Cost Type", StartDate, EndDate, AmtType);
                CompareAmt := CalcAmount("Cost Type", FromCompareDate, ToCompareDate, AmtType);
                DiffAmount := ActAmt - CompareAmt;

                if CompareAmt <> 0 then
                    Pct := Round(ActAmt / CompareAmt * 100, 0.1)
                else
                    Pct := 0;

                if (Type = Type::"Cost Type") and
                   OnlyAccWithEntries and
                   (ActAmt = 0) and
                   (CompareAmt = 0)
                then
                    CurrReport.Skip();

                if NewPage then begin
                    PageGroupNo := PageGroupNo + 1;
                    NewPage := false;
                end;
                NewPage := "New Page";

                LineTypeInt := Type.AsInteger();
            end;

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                if (StartDate = 0D) or (EndDate = 0D) or (FromCompareDate = 0D) or (ToCompareDate = 0D) then
                    Error(Text000);

                if (EndDate < StartDate) or (ToCompareDate < FromCompareDate) then
                    Error(Text001);

                if GetFilters <> '' then
                    FilterTxt := Text002 + ' ' + GetFilters();

                // Col header for balance or movement
                if AmtType = AmtType::Balance then begin
                    ActPeriodTxt := StrSubstNo(Text003, EndDate);
                    ComparePeriodTxt := StrSubstNo(Text003, ToCompareDate);
                end else begin
                    ActPeriodTxt := StrSubstNo(Text004, StartDate, EndDate);
                    ComparePeriodTxt := StrSubstNo(Text004, FromCompareDate, ToCompareDate);
                end;

                PageGroupNo := 1;
                NewPage := false;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Cost Acctg. Stmt. per Period';
        AboutText = 'The **Cost Accounting Statement per Period** report displays actual cost entries grouped by specific reporting periods (e.g., monthly or quarterly), with filtering options for dates and cost dimensions. Use it for reviewing and analyzing cost trends and spending patterns over time, helping you monitor financial performance across defined intervals.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ComparisonType; ComparisonType)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Comparison Type';
                        OptionCaption = 'Last Year,Last Half Year,Last Quarter,Last Month,Same Period Last Year,Free comparison';
                        ToolTip = 'Specifies a comparison type such as prior year, last half year, and so on.';

                        trigger OnValidate()
                        begin
                            ComparisonTypeOnAfterValidate();
                        end;
                    }
                    group("Current Period")
                    {
                        Caption = 'Current Period';
                        field(StartDate; StartDate)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the date for the beginning of the period covered by the statement.';

                            trigger OnValidate()
                            begin
                                StartDateOnAfterValidate();
                            end;
                        }
                        field(EndingDate; EndDate)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the end date for the accounting period.';

                            trigger OnValidate()
                            begin
                                EndDateOnAfterValidate();
                            end;
                        }
                    }
                    group("Comparison Period")
                    {
                        Caption = 'Comparison Period';
                        field(FromCompareDate; FromCompareDate)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the date for the beginning of the period covered by the statement.';

                            trigger OnValidate()
                            begin
                                FromCompareDateOnAfterValidate();
                            end;
                        }
                        field(ToCompareDate; ToCompareDate)
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the end date for the accounting period.';

                            trigger OnValidate()
                            begin
                                ToCompareDateOnAfterValidate();
                            end;
                        }
                    }
                    field(AmtType; AmtType)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Amounts in';
                        OptionCaption = 'Balance,Net Change';
                        ToolTip = 'Specifies whether you want to show balance or net change on the cost types.';
                    }
                    field(OnlyAccWithEntries; OnlyAccWithEntries)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Only Accounts with Balance or Movement';
                        ToolTip = 'Specifies that you want to display only the balance or movement on the cost types.';
                    }
                    field(ShowAddCurrency; ShowAddCurr)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Show Amounts in Additional Currency';
                        ToolTip = 'Specifies that you want to display amounts in additional currency.';
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

    var
        GLSetup: Record "General Ledger Setup";
        StartDate: Date;
        EndDate: Date;
        FromCompareDate: Date;
        ToCompareDate: Date;
        ComparisonType: Option "Last Year","Last Half Year","Last Quarter","Last Month","Same Period Last Year","Free Comparison";
        AmtType: Option Balance,Movement;
        FilterTxt: Text;
        ActPeriodTxt: Text[30];
        ComparePeriodTxt: Text[30];
        OnlyAccWithEntries: Boolean;
        ShowAddCurr: Boolean;
        ActAmt: Decimal;
        CompareAmt: Decimal;
        DiffAmount: Decimal;
        Pct: Decimal;
        PageGroupNo: Integer;
        NewPage: Boolean;
        LineTypeInt: Integer;

#pragma warning disable AA0074
        Text000: Label 'Starting date and ending date for the current period and comparison period must be defined.';
        Text001: Label 'Ending date must not be before starting date.';
        Text002: Label 'Filter:';
#pragma warning disable AA0470
        Text003: Label 'Balance at %1';
#pragma warning restore AA0470
        Text004: Label 'Movement  %1 - %2', Comment = '%1 = Start Date, %2 = End Date';
#pragma warning restore AA0074
        FreeCompTypeErr: Label 'You cannot change the date because the Comparison Type is not set to Free Comparison.';
        FreeCompSamePeriodTypeErr: Label 'You cannot change the date because the Comparison Type is not set to Free Comparison or Same Period Last Year.';
        AllAmountareLbl: Label 'All amounts are in';
        CostAcctgStmtperPeriodCaptionLbl: Label 'Cost Acctg. Stmt. per Period';
        PageNoCaptionLbl: Label 'Page';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        IncreaseDecreaseCaptionLbl: Label 'Increase/Decrease';
        PercentOfCaptionLbl: Label '% of';
        NameCaptionLbl: Label 'Name';
        NumberCaptionLbl: Label 'Number';

    local procedure CalcPeriod()
    begin
        if StartDate = 0D then
            exit;

        case ComparisonType of
            ComparisonType::"Last Year":
                begin
                    StartDate := CalcDate('<-CY>', StartDate);
                    EndDate := CalcDate('<CY>', StartDate);
                    FromCompareDate := CalcDate('<-1Y>', StartDate);
                    ToCompareDate := CalcDate('<-1Y>', EndDate);
                end;
            ComparisonType::"Last Half Year":
                begin
                    StartDate := CalcDate('<-CM>', StartDate);
                    EndDate := CalcDate('<6M-1D>', StartDate);
                    FromCompareDate := CalcDate('<-6M>', StartDate);
                    ToCompareDate := CalcDate('<-1D>', StartDate);
                end;
            ComparisonType::"Last Quarter":
                begin
                    StartDate := CalcDate('<-CM>', StartDate);
                    EndDate := CalcDate('<3M-1D>', StartDate);
                    FromCompareDate := CalcDate('<-3M>', StartDate);
                    ToCompareDate := CalcDate('<-1D>', StartDate);
                end;
            ComparisonType::"Last Month":
                begin
                    StartDate := CalcDate('<-CM>', StartDate);
                    EndDate := CalcDate('<1M-1D>', StartDate);
                    FromCompareDate := CalcDate('<-1M>', StartDate);
                    ToCompareDate := CalcDate('<-1D>', StartDate);
                end;
            ComparisonType::"Same Period Last Year":
                begin
                    FromCompareDate := CalcDate('<-1Y>', StartDate);
                    if EndDate <> 0D then
                        ToCompareDate := CalcDate('<-1Y>', EndDate);
                end;
        end;
    end;

    local procedure FromCompareDateOnAfterValidate()
    begin
        if ComparisonType <> ComparisonType::"Free Comparison" then
            Error(FreeCompTypeErr);
    end;

    local procedure ToCompareDateOnAfterValidate()
    begin
        if ComparisonType <> ComparisonType::"Free Comparison" then
            Error(FreeCompTypeErr);
    end;

    local procedure EndDateOnAfterValidate()
    begin
        if not (ComparisonType in [ComparisonType::"Same Period Last Year", ComparisonType::"Free Comparison"]) then
            Error(FreeCompSamePeriodTypeErr);

        if ComparisonType = ComparisonType::"Same Period Last Year" then
            if EndDate <> 0D then
                ToCompareDate := CalcDate('<-1Y>', EndDate)
            else
                ToCompareDate := 0D;
    end;

    local procedure StartDateOnAfterValidate()
    begin
        CalcPeriod();
    end;

    local procedure ComparisonTypeOnAfterValidate()
    begin
        CalcPeriod();
    end;

    local procedure CalcAmount(CostType: Record "Cost Type"; FromDate: Date; ToDate: Date; AmountType: Option): Decimal
    begin
        CostType.SetRange("Date Filter", FromDate, ToDate);
        if AmountType = AmtType::Movement then begin
            if ShowAddCurr then begin
                CostType.CalcFields("Add. Currency Net Change");
                exit(CostType."Add. Currency Net Change");
            end;
            CostType.CalcFields("Net Change");
            exit(CostType."Net Change");
        end;
        if ShowAddCurr then begin
            CostType.CalcFields("Add. Currency Balance at Date");
            exit(CostType."Add. Currency Balance at Date");
        end;
        CostType.CalcFields("Balance at Date");
        exit(CostType."Balance at Date");
    end;
}


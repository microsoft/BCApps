// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

report 11004 "Vendor Total-Balance"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorTotalBalance.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Total-Balance';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Date Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(STRSUBSTNO_Text1140001_PeriodText_; StrSubstNo(Text1140001, PeriodText))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(AdjustText; AdjustText)
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(Vendor_TABLECAPTION__________VendorFilter; Vendor.TableCaption + ': ' + VendorFilter)
            {
            }
            column(VendorFilter; VendorFilter)
            {
            }
            column(FORMAT_AccountingPeriod__Starting_Date__1_; '..' + Format(AccountingPeriod."Starting Date" - 1))
            {
            }
            column(EmptyString; '')
            {
            }
            column(YearText; YearText)
            {
            }
            column(Text1140003; Text1140003Lbl)
            {
            }
            column(FORMAT_EndDate_; '..' + Format(EndDate))
            {
            }
            column(EmptyString_Control1140022; '')
            {
            }
            column(PeriodText; PeriodText)
            {
            }
            column(Text1140002; Text1140002Lbl)
            {
            }
            column(FORMAT_YearStartDate_1_; '..' + Format(YearStartDate - 1))
            {
            }
            column(Vendor_Vendor__No__; Vendor."No.")
            {
            }
            column(Vendor_Vendor_Name; Vendor.Name)
            {
            }
            column(ABS_StartBalance_; Abs(StartBalance))
            {
                AutoFormatType = 1;
            }
            column(StartBalanceType; StartBalanceType)
            {
                OptionCaption = ' ,Debit,Credit';
            }
            column(PeriodDebitAmount; PeriodDebitAmount)
            {
                AutoFormatType = 1;
            }
            column(PeriodCreditAmount; PeriodCreditAmount)
            {
                AutoFormatType = 1;
            }
            column(ABS_PeriodEndBalance_; Abs(PeriodEndBalance))
            {
                AutoFormatType = 1;
            }
            column(PeriodEndBalanceType; PeriodEndBalanceType)
            {
                OptionCaption = ' ,Debit,Credit';
            }
            column(YearDebitAmount; YearDebitAmount)
            {
                AutoFormatType = 1;
            }
            column(YearCreditAmount; YearCreditAmount)
            {
                AutoFormatType = 1;
            }
            column(ABS_EndBalance_; Abs(EndBalance))
            {
                AutoFormatType = 1;
            }
            column(EndBalanceType; EndBalanceType)
            {
                OptionCaption = ' ,Debit,Credit';
            }
            column(ABS_StartBalance__Control1140043; Abs(StartBalance))
            {
                AutoFormatType = 1;
            }
            column(StartBalanceType_Control1140044; StartBalanceType)
            {
                OptionCaption = ' ,Debit,Credit';
            }
            column(PeriodDebitAmount_Control1140045; PeriodDebitAmount)
            {
                AutoFormatType = 1;
            }
            column(PeriodCreditAmount_Control1140046; PeriodCreditAmount)
            {
                AutoFormatType = 1;
            }
            column(ABS_PeriodEndBalance__Control1140047; Abs(PeriodEndBalance))
            {
                AutoFormatType = 1;
            }
            column(PeriodEndBalanceType_Control1140048; PeriodEndBalanceType)
            {
                OptionCaption = ' ,Debit,Credit';
            }
            column(YearDebitAmount_Control1140049; YearDebitAmount)
            {
                AutoFormatType = 1;
            }
            column(YearCreditAmount_Control1140050; YearCreditAmount)
            {
                AutoFormatType = 1;
            }
            column(ABS_EndBalance__Control1140051; Abs(EndBalance))
            {
                AutoFormatType = 1;
            }
            column(EndBalanceType_Control1140052; EndBalanceType)
            {
                OptionCaption = ' ,Debit,Credit';
            }
            column(StartBalance; StartBalance)
            {
                AutoFormatType = 1;
            }
            column(PeriodEndBalance; PeriodEndBalance)
            {
                AutoFormatType = 1;
            }
            column(EndBalance; EndBalance)
            {
                AutoFormatType = 1;
            }
            column(Vendor_Total_BalanceCaption; Vendor_Total_BalanceCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Vendor_Vendor__No__Caption; FieldCaption("No."))
            {
            }
            column(Vendor_Vendor_NameCaption; FieldCaption(Name))
            {
            }
            column(Debit__CreditCaption; Debit__CreditCaptionLbl)
            {
            }
            column(Year_Ending_BalanceCaption; Year_Ending_BalanceCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(Period_Ending_BalanceCaption; Period_Ending_BalanceCaptionLbl)
            {
            }
            column(Debit__CreditCaption_Control1140021; Debit__CreditCaption_Control1140021Lbl)
            {
            }
            column(CreditCaption_Control1140025; CreditCaption_Control1140025Lbl)
            {
            }
            column(DebitCaption_Control1140026; DebitCaption_Control1140026Lbl)
            {
            }
            column(Debit__CreditCaption_Control1140027; Debit__CreditCaption_Control1140027Lbl)
            {
            }
            column(Starting_BalanceCaption; Starting_BalanceCaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                SetRange("Date Filter", 0D, ClosingDate(YearStartDate - 1));
                CalcFields("Net Change (LCY)");
                OnAfterGetRecordVendorPeriodOnAfterCalcFieldsNetChangeLCY(Vendor);

                if "Net Change (LCY)" <> 0 then
                    if "Net Change (LCY)" > 0 then
                        StartBalanceType := StartBalanceType::Credit
                    else
                        StartBalanceType := StartBalanceType::Debit
                else
                    StartBalanceType := 0;
                StartBalance := "Net Change (LCY)";

                SetRange("Date Filter", StartDate, EndDate);
                CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
                OnAfterGetRecordVendorPeriodOnAfterCalcFieldsDebitCreditAmountLCY(Vendor);

                PeriodDebitAmount := "Debit Amount (LCY)";
                PeriodCreditAmount := "Credit Amount (LCY)";

                if AdjustAmounts then begin
                    AdjPeriodAmount := 0;
                    DetailedVendorLedgEntry.Reset();
                    DetailedVendorLedgEntry.SetCurrentKey("Vendor No.", "Posting Date", "Entry Type", "Currency Code");
                    DetailedVendorLedgEntry.SetRange("Vendor No.", "No.");
                    DetailedVendorLedgEntry.SetRange("Posting Date", StartDate, EndDate);
                    DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::"Realized Loss",
                      DetailedVendorLedgEntry."Entry Type"::"Realized Gain");
                    OnAfterGetRecordVendorPeriodOnAfterDetailedVendorLedgEntrySetFilters(DetailedVendorLedgEntry);
                    if DetailedVendorLedgEntry.FindSet() then
                        repeat
                            DetailedVendorLedgEntry2.Reset();
                            DetailedVendorLedgEntry2.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
                            DetailedVendorLedgEntry2.SetRange("Vendor Ledger Entry No.", DetailedVendorLedgEntry."Vendor Ledger Entry No.");
                            DetailedVendorLedgEntry2.SetRange("Entry Type", DetailedVendorLedgEntry2."Entry Type"::"Initial Entry");
                            DetailedVendorLedgEntry2.SetRange("Document Type", DetailedVendorLedgEntry2."Document Type"::Payment);
                            if DetailedVendorLedgEntry2.FindSet() then
                                repeat
                                    if ((DetailedVendorLedgEntry."Debit Amount (LCY)" <> 0) and (DetailedVendorLedgEntry2."Credit Amount (LCY)" <> 0)) or
                                       ((DetailedVendorLedgEntry."Credit Amount (LCY)" <> 0) and (DetailedVendorLedgEntry2."Debit Amount (LCY)" <> 0))
                                    then
                                        AdjPeriodAmount := AdjPeriodAmount +
                                          DetailedVendorLedgEntry."Debit Amount (LCY)" +
                                          DetailedVendorLedgEntry."Credit Amount (LCY)";
                                until DetailedVendorLedgEntry2.Next() = 0
                            else begin
                                VendorLedgEntry.Get(DetailedVendorLedgEntry."Vendor Ledger Entry No.");
                                if VendorLedgEntry."Closed by Entry No." <> 0 then begin
                                    VendorLedgEntry2.Get(VendorLedgEntry."Closed by Entry No.");
                                    if VendorLedgEntry2."Document Type" = VendorLedgEntry2."Document Type"::Payment then
                                        AdjPeriodAmount := GetAdjAmount(VendorLedgEntry2."Entry No.");
                                end else begin
                                    VendorLedgEntry2.Reset();
                                    VendorLedgEntry2.SetCurrentKey("Closed by Entry No.");
                                    VendorLedgEntry2.SetRange("Closed by Entry No.", VendorLedgEntry."Entry No.");
                                    VendorLedgEntry2.SetRange("Document Type", VendorLedgEntry2."Document Type"::Payment);
                                    if VendorLedgEntry2.FindSet() then
                                        repeat
                                            AdjPeriodAmount := AdjPeriodAmount + GetAdjAmount(VendorLedgEntry2."Entry No.");
                                        until VendorLedgEntry2.Next() = 0;
                                end;
                            end;

                        until DetailedVendorLedgEntry.Next() = 0;
                    PeriodDebitAmount := PeriodDebitAmount - AdjPeriodAmount;
                    PeriodCreditAmount := PeriodCreditAmount - AdjPeriodAmount;
                end;

                SetRange("Date Filter", 0D, EndDate);
                CalcFields("Net Change (LCY)");
                OnAfterGetRecordVendorYearOnAfterCalcFieldsNetChangeLCY(Vendor);

                if "Net Change (LCY)" <> 0 then
                    if "Net Change (LCY)" > 0 then
                        PeriodEndBalanceType := PeriodEndBalanceType::Credit
                    else
                        PeriodEndBalanceType := PeriodEndBalanceType::Debit
                else
                    PeriodEndBalanceType := 0;
                PeriodEndBalance := "Net Change (LCY)";

                SetRange("Date Filter", YearStartDate, EndDate);
                CalcFields("Debit Amount (LCY)", "Credit Amount (LCY)");
                OnAfterGetRecordVendorYearOnAfterCalcFieldsDebitCreditAmountLCY(Vendor);
                YearDebitAmount := "Debit Amount (LCY)";
                YearCreditAmount := "Credit Amount (LCY)";

                if AdjustAmounts then begin
                    AdjYearAmount := 0;
                    DetailedVendorLedgEntry.Reset();
                    DetailedVendorLedgEntry.SetCurrentKey("Vendor No.", "Posting Date", "Entry Type", "Currency Code");
                    DetailedVendorLedgEntry.SetRange("Vendor No.", "No.");
                    DetailedVendorLedgEntry.SetRange("Posting Date", YearStartDate, EndDate);
                    DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::"Realized Loss",
                      DetailedVendorLedgEntry."Entry Type"::"Realized Gain");
                    OnAfterGetRecordVendorYearOnAfterDetailedVendorLedgEntrySetFilters(DetailedVendorLedgEntry);
                    if DetailedVendorLedgEntry.FindSet() then
                        repeat
                            DetailedVendorLedgEntry2.Reset();
                            DetailedVendorLedgEntry2.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
                            DetailedVendorLedgEntry2.SetRange("Vendor Ledger Entry No.", DetailedVendorLedgEntry."Vendor Ledger Entry No.");
                            DetailedVendorLedgEntry2.SetRange("Entry Type", DetailedVendorLedgEntry2."Entry Type"::"Initial Entry");
                            DetailedVendorLedgEntry2.SetRange("Document Type", DetailedVendorLedgEntry2."Document Type"::Payment);
                            if DetailedVendorLedgEntry2.FindSet() then
                                repeat
                                    if ((DetailedVendorLedgEntry."Debit Amount (LCY)" <> 0) and (DetailedVendorLedgEntry2."Credit Amount (LCY)" <> 0)) or
                                       ((DetailedVendorLedgEntry."Credit Amount (LCY)" <> 0) and (DetailedVendorLedgEntry2."Debit Amount (LCY)" <> 0))
                                    then
                                        AdjYearAmount := AdjYearAmount +
                                          DetailedVendorLedgEntry."Debit Amount (LCY)" +
                                          DetailedVendorLedgEntry."Credit Amount (LCY)";
                                until DetailedVendorLedgEntry2.Next() = 0
                            else begin
                                VendorLedgEntry.Get(DetailedVendorLedgEntry."Vendor Ledger Entry No.");
                                if VendorLedgEntry."Closed by Entry No." <> 0 then begin
                                    VendorLedgEntry2.Get(VendorLedgEntry."Closed by Entry No.");
                                    if VendorLedgEntry2."Document Type" = VendorLedgEntry2."Document Type"::Payment then
                                        AdjYearAmount := GetAdjAmount(VendorLedgEntry2."Entry No.");
                                end else begin
                                    VendorLedgEntry2.Reset();
                                    VendorLedgEntry2.SetCurrentKey("Closed by Entry No.");
                                    VendorLedgEntry2.SetRange("Closed by Entry No.", VendorLedgEntry."Entry No.");
                                    VendorLedgEntry2.SetRange("Document Type", VendorLedgEntry2."Document Type"::Payment);
                                    if VendorLedgEntry2.FindSet() then
                                        repeat
                                            AdjYearAmount := AdjYearAmount + GetAdjAmount(VendorLedgEntry2."Entry No.");
                                        until VendorLedgEntry2.Next() = 0;
                                end;
                            end;
                        until DetailedVendorLedgEntry.Next() = 0;
                    YearDebitAmount := YearDebitAmount - AdjYearAmount;
                    YearCreditAmount := YearCreditAmount - AdjYearAmount;
                end;

                SetRange("Date Filter", 0D, AccountingPeriod."Starting Date" - 1);
                CalcFields("Net Change (LCY)");
                OnAfterGetRecordVendorEndOnAfterCalcFieldsNetChangeLCY(Vendor);
                if "Net Change (LCY)" <> 0 then
                    if "Net Change (LCY)" > 0 then
                        EndBalanceType := EndBalanceType::Credit
                    else
                        EndBalanceType := EndBalanceType::Debit
                else
                    EndBalanceType := 0;
                EndBalance := "Net Change (LCY)";

                SetRange("Date Filter", StartDate, EndDate);
            end;

            trigger OnPreDataItem()
            begin
                Clear(StartBalance);
                Clear(PeriodDebitAmount);
                Clear(PeriodCreditAmount);
                Clear(PeriodEndBalance);
                Clear(YearDebitAmount);
                Clear(YearCreditAmount);
                Clear(EndBalance);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AdjustExchRateDifferences; AdjustAmounts)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Adjust Exch. Rate Differences';
                        ToolTip = 'Specifies if you want to include exchange rate differences in the report. If you select this check box, all debit and credit amounts will be corrected by the realized profit and loss due to the exchange rate differences. Warning: If you do not select the check box, all exchange rate differences of realized profit and loss will not be considered. This could lead to problems with reconciling with the corresponding receivables accounts.';
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

    trigger OnInitReport()
    begin
        AdjustAmounts := true;
    end;

    trigger OnPreReport()
    begin
        VendorFilter := Vendor.GetFilters();
        PeriodText := Vendor.GetFilter("Date Filter");
        StartDate := Vendor.GetRangeMin("Date Filter");
        EndDate := Vendor.GetRangeMax("Date Filter");

        AccountingPeriod.Reset();
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod."Starting Date" := StartDate;
        AccountingPeriod.Find('=<');
        YearStartDate := AccountingPeriod."Starting Date";
        if AccountingPeriod.Next() = 0 then
            Error(Text1140000);

        YearText := Format(YearStartDate) + '..' + Format(EndDate);

        GLSetup.Get();
        GLSetup.TestField("LCY Code");
        HeaderText := StrSubstNo(Text1140021, GLSetup."LCY Code");

        if AdjustAmounts then
            AdjustText := Text1140022
        else
            AdjustText := Text1140023;
    end;

    var
        Text1140000: Label 'Accounting Period is not available';
        Text1140001: Label 'Period: %1';
        Text1140021: Label 'All amounts are in %1';
        Text1140022: Label 'Exch. Rate Differences Adjustment; Debit and credit amounts are adjusted by real. losses and gains';
        Text1140023: Label 'No Exch. Rate Differences Adjustment; Debit and credit amounts are not adjusted by real. losses and gains';
        AccountingPeriod: Record "Accounting Period";
        GLSetup: Record "General Ledger Setup";
        VendorLedgEntry: Record "Vendor Ledger Entry";
        VendorLedgEntry2: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        VendorFilter: Text;
        PeriodText: Text;
        YearText: Text[30];
        HeaderText: Text[50];
        AdjustText: Text;
        StartDate: Date;
        EndDate: Date;
        YearStartDate: Date;
        StartBalanceType: Option " ",Debit,Credit;
        StartBalance: Decimal;
        PeriodDebitAmount: Decimal;
        PeriodCreditAmount: Decimal;
        YearDebitAmount: Decimal;
        YearCreditAmount: Decimal;
        AdjPeriodAmount: Decimal;
        AdjYearAmount: Decimal;
        AdjustAmounts: Boolean;
        Text1140003Lbl: Label 'Year';
        Text1140002Lbl: Label 'Period';
        Vendor_Total_BalanceCaptionLbl: Label 'Vendor Total-Balance';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Debit__CreditCaptionLbl: Label 'Debit/ Credit';
        Year_Ending_BalanceCaptionLbl: Label 'Year Ending Balance';
        CreditCaptionLbl: Label 'Credit';
        DebitCaptionLbl: Label 'Debit';
        Period_Ending_BalanceCaptionLbl: Label 'Period Ending Balance';
        Debit__CreditCaption_Control1140021Lbl: Label 'Debit/ Credit';
        CreditCaption_Control1140025Lbl: Label 'Credit';
        DebitCaption_Control1140026Lbl: Label 'Debit';
        Debit__CreditCaption_Control1140027Lbl: Label 'Debit/ Credit';
        Starting_BalanceCaptionLbl: Label 'Starting Balance';
        TotalCaptionLbl: Label 'Total';

    protected var
        EndBalance: Decimal;
        EndBalanceType: Option " ",Debit,Credit;
        PeriodEndBalance: Decimal;
        PeriodEndBalanceType: Option " ",Debit,Credit;

    [Scope('OnPrem')]
    procedure GetAdjAmount(VendorLedgEntryEntryNo: Integer): Decimal
    var
        AdjAmount: Decimal;
    begin
        AdjAmount := 0;
        DetailedVendorLedgEntry2.Reset();
        DetailedVendorLedgEntry2.SetRange("Vendor Ledger Entry No.", VendorLedgEntryEntryNo);
        DetailedVendorLedgEntry2.SetRange("Entry Type", DetailedVendorLedgEntry2."Entry Type"::"Initial Entry");
        DetailedVendorLedgEntry2.SetRange("Document Type", DetailedVendorLedgEntry2."Document Type"::Payment);
        if DetailedVendorLedgEntry2.FindSet() then
            repeat
                if ((DetailedVendorLedgEntry."Debit Amount (LCY)" <> 0) and (DetailedVendorLedgEntry2."Credit Amount (LCY)" <> 0)) or
                   ((DetailedVendorLedgEntry."Credit Amount (LCY)" <> 0) and (DetailedVendorLedgEntry2."Debit Amount (LCY)" <> 0))
                then
                    AdjAmount := AdjAmount + DetailedVendorLedgEntry."Debit Amount (LCY)" + DetailedVendorLedgEntry."Credit Amount (LCY)";
            until DetailedVendorLedgEntry2.Next() = 0;
        exit(AdjAmount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordVendorPeriodOnAfterCalcFieldsNetChangeLCY(var Vendor: Record "Vendor");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordVendorPeriodOnAfterCalcFieldsDebitCreditAmountLCY(var Vendor: Record "Vendor");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordVendorPeriodOnAfterDetailedVendorLedgEntrySetFilters(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordVendorYearOnAfterCalcFieldsNetChangeLCY(var Vendor: Record "Vendor");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordVendorYearOnAfterCalcFieldsDebitCreditAmountLCY(var Vendor: Record "Vendor");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordVendorYearOnAfterDetailedVendorLedgEntrySetFilters(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordVendorEndOnAfterCalcFieldsNetChangeLCY(var Vendor: Record "Vendor");
    begin
    end;
}


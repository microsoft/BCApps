// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Globalization;
using System.Utilities;

report 10072 "Customer Statements"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerStatements.rdlc';
    ApplicationArea = Basic, Suite;
    UsageCategory = Documents;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Print Statements", "Date Filter";
            column(Customer_No_; "No.")
            {
            }
            column(Customer_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Customer_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            dataitem(HeaderFooter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(CompanyInformation_Picture; CompanyInformation.Picture)
                {
                }
                column(CompanyInfo1_Picture; CompanyInfo1.Picture)
                {
                }
                column(CompanyInfo2_Picture; CompanyInfo2.Picture)
                {
                }
                column(CompanyAddress_1_; CompanyAddress[1])
                {
                }
                column(CompanyAddress_2_; CompanyAddress[2])
                {
                }
                column(CompanyAddress_3_; CompanyAddress[3])
                {
                }
                column(CompanyAddress_4_; CompanyAddress[4])
                {
                }
                column(CompanyAddress_5_; CompanyAddress[5])
                {
                }
                column(ToDate; ToDate)
                {
                }
                column(CompanyAddress_6_; CompanyAddress[6])
                {
                }
                column(Customer__No__; Customer."No.")
                {
                }
                column(CurrReport_PAGENO; CurrReport.PageNo())
                {
                }
                column(CustomerAddress_1_; CustomerAddress[1])
                {
                }
                column(CustomerAddress_2_; CustomerAddress[2])
                {
                }
                column(CustomerAddress_3_; CustomerAddress[3])
                {
                }
                column(CustomerAddress_4_; CustomerAddress[4])
                {
                }
                column(CustomerAddress_5_; CustomerAddress[5])
                {
                }
                column(CustomerAddress_6_; CustomerAddress[6])
                {
                }
                column(CustomerAddress_7_; CustomerAddress[7])
                {
                }
                column(CompanyAddress_7_; CompanyAddress[7])
                {
                }
                column(CompanyAddress_8_; CompanyAddress[8])
                {
                }
                column(CustomerAddress_8_; CustomerAddress[8])
                {
                }
                column(CurrencyDesc; CurrencyDesc)
                {
                }
                column(AgingMethod_Int; AgingMethod_Int)
                {
                }
                column(StatementStyle_Int; StatementStyle_Int)
                {
                }
                column(printfooter3ornot; (AgingMethod <> AgingMethod::None) and StatementComplete)
                {
                }
                column(DebitBalance; DebitBalance)
                {
                }
                column(CreditBalance; -CreditBalance)
                {
                }
                column(BalanceToPrint; BalanceToPrint)
                {
                }
                column(DebitBalance_Control22; DebitBalance)
                {
                }
                column(CreditBalance_Control23; -CreditBalance)
                {
                }
                column(BalanceToPrint_Control24; BalanceToPrint)
                {
                }
                column(AgingDaysText; AgingDaysText)
                {
                }
                column(AgingHead_1_; AgingHead[1])
                {
                }
                column(AgingHead_2_; AgingHead[2])
                {
                }
                column(AgingHead_3_; AgingHead[3])
                {
                }
                column(AgingHead_4_; AgingHead[4])
                {
                }
                column(AmountDue_1_; AmountDue[1])
                {
                }
                column(AmountDue_2_; AmountDue[2])
                {
                }
                column(AmountDue_3_; AmountDue[3])
                {
                }
                column(AmountDue_4_; AmountDue[4])
                {
                }
                column(TempAmountDue_1_; TempAmountDue[1])
                {
                }
                column(TempAmountDue_3_; TempAmountDue[3])
                {
                }
                column(TempAmountDue_2_; TempAmountDue[2])
                {
                }
                column(TempAmountDue_4_; TempAmountDue[4])
                {
                }
                column(HeaderFooter_Number; Number)
                {
                }
                column(STATEMENTCaption; STATEMENTCaptionLbl)
                {
                }
                column(Statement_Date_Caption; Statement_Date_CaptionLbl)
                {
                }
                column(Account_Number_Caption; Account_Number_CaptionLbl)
                {
                }
                column(Page_Caption; Page_CaptionLbl)
                {
                }
                column(RETURN_THIS_PORTION_OF_STATEMENT_WITH_YOUR_PAYMENT_Caption; RETURN_THIS_PORTION_OF_STATEMENT_WITH_YOUR_PAYMENT_CaptionLbl)
                {
                }
                column(Amount_RemittedCaption; Amount_RemittedCaptionLbl)
                {
                }
                column(TempCustLedgEntry__Document_No__Caption; TempCustLedgEntry__Document_No__CaptionLbl)
                {
                }
                column(TempCustLedgEntry__Posting_Date_Caption; TempCustLedgEntry__Posting_Date_CaptionLbl)
                {
                }
                column(GetTermsString_TempCustLedgEntry_Caption; GetTermsString_TempCustLedgEntry_CaptionLbl)
                {
                }
                column(TempCustLedgEntry__Document_Type_Caption; TempCustLedgEntry__Document_Type_CaptionLbl)
                {
                }
                column(TempCustLedgEntry__Remaining_Amount_Caption; TempCustLedgEntry__Remaining_Amount_CaptionLbl)
                {
                }
                column(TempCustLedgEntry__Remaining_Amount__Control47Caption; TempCustLedgEntry__Remaining_Amount__Control47CaptionLbl)
                {
                }
                column(BalanceToPrint_Control48Caption; BalanceToPrint_Control48CaptionLbl)
                {
                }
                column(Statement_BalanceCaption; Statement_BalanceCaptionLbl)
                {
                }
                column(Statement_BalanceCaption_Control25; Statement_BalanceCaption_Control25Lbl)
                {
                }
                column(Statement_Aging_Caption; Statement_Aging_CaptionLbl)
                {
                }
                column(Aged_amounts_Caption; Aged_amounts_CaptionLbl)
                {
                }
                dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
                {
                    DataItemLink = "Customer No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                    DataItemLinkReference = Customer;
                    DataItemTableView = sorting("Customer No.", Open) where(Open = const(true));

                    trigger OnAfterGetRecord()
                    begin
                        SetRange("Date Filter", 0D, ToDate);
                        CalcFields("Remaining Amount");
                        if "Remaining Amount" <> 0 then
                            InsertTemp("Cust. Ledger Entry");
                    end;

                    trigger OnPreDataItem()
                    begin
                        if (AgingMethod = AgingMethod::None) and (StatementStyle = StatementStyle::Balance) then
                            CurrReport.Break();    // Optimization

                        // Find ledger entries which are open and posted before the statement date.
                        SetRange("Posting Date", 0D, ToDate);
                    end;
                }
                dataitem(AfterStmntDateEntry; "Cust. Ledger Entry")
                {
                    DataItemLink = "Customer No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                    DataItemLinkReference = Customer;
                    DataItemTableView = sorting("Customer No.", "Posting Date");

                    trigger OnAfterGetRecord()
                    begin
                        EntryApplicationMgt.GetAppliedCustEntries(TempAppliedCustLedgEntry, AfterStmntDateEntry, false);
                        TempAppliedCustLedgEntry.SetRange("Posting Date", 0D, ToDate);
                        if TempAppliedCustLedgEntry.Find('-') then
                            repeat
                                InsertTemp(TempAppliedCustLedgEntry);
                            until TempAppliedCustLedgEntry.Next() = 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if (AgingMethod = AgingMethod::None) and (StatementStyle = StatementStyle::Balance) then
                            CurrReport.Break();    // Optimization

                        // Find ledger entries which are posted after the statement date and eliminate
                        // their application to ledger entries posted before the statement date.
                        SetFilter("Posting Date", '%1..', ToDate + 1);
                    end;
                }
                dataitem("Balance Forward"; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(FromDate___1; FromDate - 1)
                    {
                    }
                    column(BalanceToPrint_Control39; BalanceToPrint)
                    {
                    }
                    column(Balance_Forward_Number; Number)
                    {
                    }
                    column(Balance_ForwardCaption; Balance_ForwardCaptionLbl)
                    {
                    }
                    column(Bal_FwdCaption; Bal_FwdCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if StatementStyle <> StatementStyle::Balance then
                            CurrReport.Break();
                    end;

                    trigger OnPreDataItem()
                    begin
                        StatementStyle_Int := StatementStyle;
                    end;
                }
                dataitem(OpenItem; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(TempCustLedgEntry__Document_No__; TempCustLedgEntry."Document No.")
                    {
                    }
                    column(TempCustLedgEntry__Posting_Date_; TempCustLedgEntry."Posting Date")
                    {
                    }
                    column(TempCustLedgEntry__Document_Dat_; TempCustLedgEntry."Document Date")
                    {
                    }
                    column(GetTermsString_TempCustLedgEntry_; GetTermsString(TempCustLedgEntry))
                    {
                    }
                    column(TempCustLedgEntry__Document_Type_; TempCustLedgEntry."Document Type")
                    {
                    }
                    column(TempCustLedgEntry__Remaining_Amount_; TempCustLedgEntry."Remaining Amount")
                    {
                    }
                    column(TempCustLedgEntry__Remaining_Amount__Control47; -TempCustLedgEntry."Remaining Amount")
                    {
                    }
                    column(BalanceToPrint_Control48; BalanceToPrint)
                    {
                    }
                    column(OpenItem_Number; Number)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then
                            TempCustLedgEntry.Find('-')
                        else
                            TempCustLedgEntry.Next();

                        TempCustLedgEntry.CalcFields("Remaining Amount");
                        if TempCustLedgEntry."Currency Code" <> Customer."Currency Code" then
                            TempCustLedgEntry."Remaining Amount" :=
                              Round(
                                CurrExchRate.ExchangeAmtFCYToFCY(
                                  TempCustLedgEntry."Posting Date",
                                  TempCustLedgEntry."Currency Code",
                                  Customer."Currency Code",
                                  TempCustLedgEntry."Remaining Amount"),
                                Currency."Amount Rounding Precision");

                        if AgingMethod <> AgingMethod::None then begin
                            case AgingMethod of
                                AgingMethod::"Due Date":
                                    AgingDate := TempCustLedgEntry."Due Date";
                                AgingMethod::"Trans Date":
                                    AgingDate := TempCustLedgEntry."Posting Date";
                                AgingMethod::"Doc Date":
                                    AgingDate := TempCustLedgEntry."Document Date";
                            end;
                            i := 0;
                            while AgingDate < PeriodEndingDate[i + 1] do
                                i := i + 1;
                            if i = 0 then
                                i := 1;
                            AmountDue[i] := TempCustLedgEntry."Remaining Amount";
                            TempAmountDue[i] := TempAmountDue[i] + AmountDue[i];
                        end;

                        if StatementStyle = StatementStyle::"Open Item" then begin
                            BalanceToPrint := BalanceToPrint + TempCustLedgEntry."Remaining Amount";
                            if TempCustLedgEntry."Remaining Amount" >= 0 then
                                DebitBalance := DebitBalance + TempCustLedgEntry."Remaining Amount"
                            else
                                CreditBalance := CreditBalance + TempCustLedgEntry."Remaining Amount";
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if (not TempCustLedgEntry.Find('-')) or
                           ((StatementStyle = StatementStyle::Balance) and
                            (AgingMethod = AgingMethod::None))
                        then
                            CurrReport.Break();
                        SetRange(Number, 1, TempCustLedgEntry.Count);
                        TempCustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
                        TempCustLedgEntry.SetRange("Date Filter", 0D, ToDate);
                    end;
                }
                dataitem(CustLedgerEntry4; "Cust. Ledger Entry")
                {
                    DataItemLink = "Customer No." = field("No.");
                    DataItemLinkReference = Customer;
                    DataItemTableView = sorting("Customer No.", "Posting Date");
                    column(CustLedgerEntry4__Document_No__; "Document No.")
                    {
                    }
                    column(CustLedgerEntry4__Posting_Date_; "Posting Date")
                    {
                    }
                    column(GetTermsString_CustLedgerEntry4_; GetTermsString(CustLedgerEntry4))
                    {
                    }
                    column(CustLedgerEntry4__Document_Type_; "Document Type")
                    {
                    }
                    column(CustLedgerEntry4_Amount; Amount)
                    {
                    }
                    column(Amount; -Amount)
                    {
                    }
                    column(BalanceToPrint_Control55; BalanceToPrint)
                    {
                    }
                    column(CustLedgerEntry4_Entry_No_; "Entry No.")
                    {
                    }
                    column(CustLedgerEntry4_Customer_No_; "Customer No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        CalcFields(Amount, "Amount (LCY)");
                        if (Customer."Currency Code" = '') and ("Cust. Ledger Entry"."Currency Code" = '') then
                            Amount := "Amount (LCY)"
                        else
                            Amount :=
                              Round(
                                CurrExchRate.ExchangeAmtFCYToFCY(
                                  "Posting Date",
                                  "Currency Code",
                                  Customer."Currency Code",
                                  Amount),
                                Currency."Amount Rounding Precision");

                        BalanceToPrint := BalanceToPrint + Amount;
                        if Amount >= 0 then
                            DebitBalance := DebitBalance + Amount
                        else
                            CreditBalance := CreditBalance + Amount;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if StatementStyle <> StatementStyle::Balance then
                            CurrReport.Break();
                        SetRange("Posting Date", FromDate, ToDate);
                    end;
                }
                dataitem(EndOfCustomer; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(StatementComplete; StatementComplete)
                    {
                    }
                    column(EndOfCustomer_Number; Number)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        StatementComplete := true;
                        if UpdateNumbers and (not CurrReport.Preview) then begin
                            Customer.Modify(); // just update the Last Statement No
                            Commit();
                        end;
                    end;
                }

                trigger OnPreDataItem()
                begin
                    AgingMethod_Int := AgingMethod;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");

                DebitBalance := 0;
                CreditBalance := 0;
                Clear(AmountDue);
                Clear(TempAmountDue);
                Print := false;
                if AllHavingBalance then begin
                    SetRange("Date Filter", 0D, ToDate);
                    CalcFields("Net Change");
                    Print := "Net Change" <> 0;
                end;
                if (not Print) and AllHavingEntries then begin
                    "Cust. Ledger Entry".Reset();
                    if StatementStyle = StatementStyle::Balance then begin
                        "Cust. Ledger Entry".SetCurrentKey("Customer No.", "Posting Date");
                        "Cust. Ledger Entry".SetRange("Posting Date", FromDate, ToDate);
                    end else begin
                        "Cust. Ledger Entry".SetCurrentKey("Customer No.", Open);
                        "Cust. Ledger Entry".SetRange("Posting Date", 0D, ToDate);
                        "Cust. Ledger Entry".SetRange(Open, true);
                    end;
                    "Cust. Ledger Entry".SetRange("Customer No.", "No.");
                    Print := "Cust. Ledger Entry".Find('-');
                end;
                if not Print then
                    CurrReport.Skip();

                TempCustLedgEntry.DeleteAll();

                AgingDaysText := '';
                if AgingMethod <> AgingMethod::None then begin
                    AgingHead[1] := CurrentTxt;
                    PeriodEndingDate[1] := ToDate;
                    if AgingMethod = AgingMethod::"Due Date" then begin
                        PeriodEndingDate[2] := PeriodEndingDate[1];
                        for i := 3 to 4 do
                            PeriodEndingDate[i] := CalcDate(PeriodCalculation, PeriodEndingDate[i - 1]);
                        AgingDaysText := DaysOverdueTxt;
                        AgingHead[2] := StrSubstNo(UpToDaysTxt, PeriodEndingDate[1] - PeriodEndingDate[3]);
                    end else begin
                        for i := 2 to 4 do
                            PeriodEndingDate[i] := CalcDate(PeriodCalculation, PeriodEndingDate[i - 1]);
                        AgingDaysText := DaysOldTxt;
                        AgingHead[2] :=
                          StrSubstNo(FromToDaysTxt, PeriodEndingDate[1] - PeriodEndingDate[2] + 1, PeriodEndingDate[1] - PeriodEndingDate[3]);
                    end;
                    PeriodEndingDate[5] := 0D;
                    AgingHead[3] :=
                      StrSubstNo(FromToDaysTxt, PeriodEndingDate[1] - PeriodEndingDate[3] + 1, PeriodEndingDate[1] - PeriodEndingDate[4]);
                    AgingHead[4] := StrSubstNo(OverDaysTxt, PeriodEndingDate[1] - PeriodEndingDate[4]);
                end;

                if "Currency Code" = '' then begin
                    Clear(Currency);
                    CurrencyDesc := '';
                end else begin
                    Currency.Get("Currency Code");
                    CurrencyDesc := StrSubstNo(CurrencyDescTxt, Currency.Description);
                end;

                if StatementStyle = StatementStyle::Balance then begin
                    SetRange("Date Filter", 0D, FromDate - 1);
                    CalcFields("Net Change (LCY)");
                    if "Currency Code" = '' then
                        BalanceToPrint := "Net Change (LCY)"
                    else
                        BalanceToPrint := CurrExchRate.ExchangeAmtFCYToFCY(FromDate - 1, '', "Currency Code", "Net Change (LCY)");
                    SetRange("Date Filter");
                end else
                    BalanceToPrint := 0;

                // Update Statement Number so it can be printed on the document. However, defer actually updating the customer file until the statement is complete.
                if "Last Statement No." >= 9999 then
                    "Last Statement No." := 1
                else
                    "Last Statement No." := "Last Statement No." + 1;
                CurrReport.PageNo := 1;

                FormatAddress.Customer(CustomerAddress, Customer);
                StatementComplete := false;

                if LogInteraction then
                    if not CurrReport.Preview then
                        SegManagement.LogDocument(
                          7, Format("Last Statement No."), 0, 0, DATABASE::Customer, "No.", "Salesperson Code",
                          '', StrSubstNo(LastStmtNoTxt, "Last Statement No."), '');
            end;

            trigger OnPreDataItem()
            begin
                // remove user-entered date filter; info now in FromDate & ToDate
                SetRange("Date Filter");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AllHavingEntries; AllHavingEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print All with Entries';
                        ToolTip = 'Specifies if an account statement is included for all customers with entries by the end of the statement period, as specified in the date filter.';
                    }
                    field(AllHavingBalance; AllHavingBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print All with Balance';
                        ToolTip = 'Specifies if an account statement is included for all customers with a balance by the end of the statement period, as specified in the date filter.';
                    }
                    field(UpdateNumbers; UpdateNumbers)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Update Statement No.';
                        ToolTip = 'Specifies if you want to update the Last Statement No. field on each customer card after it prints the customer''s statement. Do not select this check box if you are not using statement numbers, if you are just viewing the statements, or if you are printing statements which will not be sent to the customer.';
                    }
                    field(PrintCompany; PrintCompany)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Company Address';
                        ToolTip = 'Specifies if your company address is printed at the top of the sheet, because you do not use pre-printed paper. Leave this check box blank to omit your company''s address.';
                    }
                    field(StatementStyle; StatementStyle)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Statement Style';
                        OptionCaption = 'Open Item,Balance';
                        ToolTip = 'Specifies how to print the statement. Balance: Prints balance forward statements that list all entries made during the statement period that you specify in the date filter. Open Item: Prints open item statements that list all entries that are still open as of the date that you specify in the date filter.';
                    }
                    field(AgingMethod; AgingMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Aged By';
                        OptionCaption = 'None,Due Date,Trans Date,Doc Date';
                        ToolTip = 'Specifies how aging is calculated. Due Date: Aging is calculated by the number of days that the transaction is overdue. Trans Date: Aging is calculated by the number of days since the transaction posting date. Document Date: Aging is calculated by the number of days since the document date.';
                    }
                    field(PeriodCalculation; PeriodCalculation)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Length of Aging Periods';
                        ToolTip = 'Specifies the length of each of the aging periods. For example, enter 30D to base aging on 30-day intervals.';

                        trigger OnValidate()
                        begin
                            if (AgingMethod <> AgingMethod::None) and (Format(PeriodCalculation) = '') then
                                Error(AgingPeriodLengthErr);
                        end;
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want to record the related interactions with the involved contact person in the Interaction Log Entry table.';
                    }
                    group(OutputOptions)
                    {
                        Caption = 'Output Options';
                        field(ReportOutput; SupportedOutputMethod)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Report Output';
                            ToolTip = 'Specifies the output of the scheduled report, such as PDF or Word.';

                            trigger OnValidate()
                            begin
                                MapOutputMethod();
                            end;
                        }
                        field(OutputMethod; ChosenOutputMethod)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                    }
                    group(EmailOptions)
                    {
                        Caption = 'Email Options';
                        Visible = ShowPrintIfEmailIsMissing;
                        field(PrintMissingAddresses; PrintIfEmailIsMissing)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Print remaining statements';
                            ToolTip = 'Specifies that amounts that remain to be paid will be included.';
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            LogInteractionEnable := true;
        end;

        trigger OnOpenPage()
        begin
            if (not AllHavingEntries) and (not AllHavingBalance) then
                AllHavingBalance := true;

            LogInteraction := SegManagement.FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Sales Stmnt.") <> '';
            LogInteractionEnable := LogInteraction;
            MapOutputMethod();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if (not AllHavingEntries) and (not AllHavingBalance) then
            Error(EntriesOrBalanceErr);
        if UpdateNumbers and CurrReport.Preview then
            Error(UpdStmtNmbrsPrintErr);
        FromDate := Customer.GetRangeMin("Date Filter");
        ToDate := Customer.GetRangeMax("Date Filter");

        if (StatementStyle = StatementStyle::Balance) and (FromDate = ToDate) then
            Error(DateFilterRangeErr);

        if (AgingMethod <> AgingMethod::None) and (Format(PeriodCalculation) = '') then
            Error(AgingPeriodLengthErr);

        if Format(PeriodCalculation) <> '' then
            Evaluate(PeriodCalculation, StrSubstNo(PeriodCalcTxt, PeriodCalculation));

        if PrintCompany then begin
            CompanyInformation.Get();
            FormatAddress.Company(CompanyAddress, CompanyInformation);
        end else
            Clear(CompanyAddress);

        SalesSetup.Get();

        case SalesSetup."Logo Position on Documents" of
            SalesSetup."Logo Position on Documents"::"No Logo":
                ;
            SalesSetup."Logo Position on Documents"::Left:
                CompanyInformation.CalcFields(Picture);
            SalesSetup."Logo Position on Documents"::Center:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Right:
                begin
                    CompanyInfo2.Get();
                    CompanyInfo2.CalcFields(Picture);
                end;
        end;
    end;

    var
        SalesSetup: Record "Sales & Receivables Setup";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        LanguageMgt: Codeunit Language;
        TempAppliedCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        FormatAddress: Codeunit "Format Address";
        EntryApplicationMgt: Codeunit "Entry Application Management";
        SegManagement: Codeunit SegManagement;
        StatementStyle: Option "Open Item",Balance;
        AllHavingEntries: Boolean;
        AllHavingBalance: Boolean;
        UpdateNumbers: Boolean;
        AgingMethod: Option "None","Due Date","Trans Date","Doc Date";
        PrintCompany: Boolean;
        PeriodCalculation: DateFormula;
        Print: Boolean;
        FromDate: Date;
        ToDate: Date;
        AgingDate: Date;
        LogInteraction: Boolean;
        CustomerAddress: array[8] of Text[100];
        CompanyAddress: array[8] of Text[100];
        BalanceToPrint: Decimal;
        DebitBalance: Decimal;
        CreditBalance: Decimal;
        AgingHead: array[4] of Text[20];
        AmountDue: array[4] of Decimal;
        AgingDaysText: Text[20];
        PeriodEndingDate: array[5] of Date;
        StatementComplete: Boolean;
        i: Integer;
        CurrencyDesc: Text[80];
        EntriesOrBalanceErr: Label 'You must select either All with Entries or All with Balance.';
        UpdStmtNmbrsPrintErr: Label 'You must print statements if you want to update statement numbers.';
        DateFilterRangeErr: Label 'You must enter a range of dates (not just one date) in the Date Filter if you want to print Balance Forward Statements.';
        AgingPeriodLengthErr: Label 'You must enter a Length of Aging Periods if you select aging.';
        CurrentTxt: Label 'Current';
        DaysOverdueTxt: Label 'Days overdue:';
        UpToDaysTxt: Label 'Up To %1 Days', Comment = '%1 = a number of days overdue';
        FromToDaysTxt: Label '%1 - %2 Days', Comment = '%1, %2 = a number of days overdue';
        DaysOldTxt: Label 'Days old:';
        OverDaysTxt: Label 'Over %1 Days', Comment = '%1 = a number of days overdue';
        LastStmtNoTxt: Label 'Statement %1', Comment = '%1 = Customer''s Last Statement No.';
        CurrencyDescTxt: Label '(All amounts are in %1)', Comment = '%1 = Currency name';
        TempAmountDue: array[4] of Decimal;
        AgingMethod_Int: Integer;
        StatementStyle_Int: Integer;
        LogInteractionEnable: Boolean;
        PeriodCalcTxt: Label '-%1', Comment = '%1 = length of Aging Periods, dateformula';
        STATEMENTCaptionLbl: Label 'STATEMENT', Comment = 'Page title.';
        Statement_Date_CaptionLbl: Label 'Statement Date:';
        Account_Number_CaptionLbl: Label 'Account Number:';
        Page_CaptionLbl: Label 'Page:';
        RETURN_THIS_PORTION_OF_STATEMENT_WITH_YOUR_PAYMENT_CaptionLbl: Label 'RETURN THIS PORTION OF STATEMENT WITH YOUR PAYMENT.', Comment = 'Part of page header.';
        Amount_RemittedCaptionLbl: Label 'Amount Remitted';
        TempCustLedgEntry__Document_No__CaptionLbl: Label 'Document';
        TempCustLedgEntry__Posting_Date_CaptionLbl: Label 'Date';
        GetTermsString_TempCustLedgEntry_CaptionLbl: Label 'Terms';
        TempCustLedgEntry__Document_Type_CaptionLbl: Label 'Code';
        TempCustLedgEntry__Remaining_Amount_CaptionLbl: Label 'Debits';
        TempCustLedgEntry__Remaining_Amount__Control47CaptionLbl: Label 'Credits';
        BalanceToPrint_Control48CaptionLbl: Label 'Balance';
        Statement_BalanceCaptionLbl: Label 'Statement Balance';
        Statement_BalanceCaption_Control25Lbl: Label 'Statement Balance';
        Statement_Aging_CaptionLbl: Label 'Statement Aging:';
        Aged_amounts_CaptionLbl: Label 'Aged amounts:';
        Balance_ForwardCaptionLbl: Label 'Balance Forward';
        Bal_FwdCaptionLbl: Label 'Bal Fwd';
        SupportedOutputMethod: Option Print,Preview,PDF,Email,Excel,XML;
        ChosenOutputMethod: Integer;
        PrintIfEmailIsMissing: Boolean;
        ShowPrintIfEmailIsMissing: Boolean;

    protected var
        CompanyInformation: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;

    procedure GetTermsString(var CustLedgerEntry: Record "Cust. Ledger Entry"): Text[250]
    var
        SalesInvHeader: Record "Sales Invoice Header";
        PaymentTerms: Record "Payment Terms";
    begin
        if (CustLedgerEntry."Document No." = '') or (CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Invoice) then
            exit('');

        if SalesInvHeader.ReadPermission then
            if SalesInvHeader.Get(CustLedgerEntry."Document No.") then begin
                if PaymentTerms.Get(SalesInvHeader."Payment Terms Code") then begin
                    if PaymentTerms.Description <> '' then
                        exit(PaymentTerms.Description);

                    exit(SalesInvHeader."Payment Terms Code");
                end;
                exit(SalesInvHeader."Payment Terms Code");
            end;

        if Customer."Payment Terms Code" <> '' then begin
            if PaymentTerms.Get(Customer."Payment Terms Code") then begin
                if PaymentTerms.Description <> '' then
                    exit(PaymentTerms.Description);

                exit(Customer."Payment Terms Code");
            end;
            exit(Customer."Payment Terms Code");
        end;

        exit('');
    end;

    local procedure InsertTemp(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        if TempCustLedgEntry.Get(CustLedgEntry."Entry No.") then
            exit;
        TempCustLedgEntry := CustLedgEntry;
        TempCustLedgEntry.Insert();
    end;

    local procedure MapOutputMethod()
    var
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
    begin
        ShowPrintIfEmailIsMissing := (SupportedOutputMethod = SupportedOutputMethod::Email);
        // Map the supported option (shown on the page) to the list of supported output methods
        // Most output methods map directly - Word/XML do not, however.
        case SupportedOutputMethod of
            SupportedOutputMethod::XML:
                ChosenOutputMethod := CustomLayoutReporting.GetXMLOption();
            else
                ChosenOutputMethod := SupportedOutputMethod;
        end;
    end;
}


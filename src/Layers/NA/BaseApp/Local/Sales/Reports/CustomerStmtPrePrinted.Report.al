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
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;
using System.Globalization;
using System.Utilities;

report 10071 "Customer Stmt. (Pre-Printed)"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerStmtPrePrinted.rdlc';
    Caption = 'Customer Stmt. (Pre-Printed)';

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Print Statements", "Date Filter";
            column(No_Customer; "No.")
            {
            }
            column(GlobalDimension1Filter_Customer; "Global Dimension 1 Filter")
            {
            }
            column(GlobalDimension2Filter_Customer; "Global Dimension 2 Filter")
            {
            }
            dataitem(HeaderFooter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(CompanyAddress1; CompanyAddress[1])
                {
                }
                column(CompanyAddress2; CompanyAddress[2])
                {
                }
                column(CompanyAddress3; CompanyAddress[3])
                {
                }
                column(CompanyAddress4; CompanyAddress[4])
                {
                }
                column(CompanyAddress5; CompanyAddress[5])
                {
                }
                column(ToDate; ToDate)
                {
                }
                column(CompanyAddress6; CompanyAddress[6])
                {
                }
                column(CustomerNo_HeaderFooter; Customer."No.")
                {
                }
                column(CustomerAddress1; CustomerAddress[1])
                {
                }
                column(CustomerAddress2; CustomerAddress[2])
                {
                }
                column(CustomerAddress3; CustomerAddress[3])
                {
                }
                column(CustomerAddress4; CustomerAddress[4])
                {
                }
                column(CustomerAddress5; CustomerAddress[5])
                {
                }
                column(CustomerAddress6; CustomerAddress[6])
                {
                }
                column(CustomerAddress7; CustomerAddress[7])
                {
                }
                column(CompanyAddress7; CompanyAddress[7])
                {
                }
                column(CompanyAddress8; CompanyAddress[8])
                {
                }
                column(CustomerAddress8; CustomerAddress[8])
                {
                }
                column(CurrencyDesc; CurrencyDesc)
                {
                }
                column(AgingMethodInt; AgingMethod_Int)
                {
                }
                column(StatementStyleInt; StatementStyle_Int)
                {
                }
                column(PrintFooterOrNot; (AgingMethod <> AgingMethod::None) and StatementComplete)
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
                column(AgingDaysText; AgingDaysText)
                {
                }
                column(AgingHead1; AgingHead[1])
                {
                }
                column(AgingHead2; AgingHead[2])
                {
                }
                column(AgingHead3; AgingHead[3])
                {
                }
                column(AgingHead4; AgingHead[4])
                {
                }
                column(AmountDue1; AmountDue[1])
                {
                }
                column(AmountDue2; AmountDue[2])
                {
                }
                column(AmountDue3; AmountDue[3])
                {
                }
                column(AmountDue4; AmountDue[4])
                {
                }
                column(TempAmountDue1; TempAmountDue[1])
                {
                }
                column(TempAmountDue2; TempAmountDue[2])
                {
                }
                column(TempAmountDue4; TempAmountDue[4])
                {
                }
                column(TempAmountDue3; TempAmountDue[3])
                {
                }
                column(StatementBalanceCaption; StatementBalanceCaptionLbl)
                {
                }
                column(StatementAgingCaption; StatementAgingCaptionLbl)
                {
                }
                column(AgedAmountsCaption; AgedAmountsCaptionLbl)
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
                        EntryAppMgt.GetAppliedCustEntries(TempAppliedCustLedgEntry, AfterStmntDateEntry, false);
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
                    column(FromDate1; FromDate - 1)
                    {
                    }
                    column(BalanceToPrintBalForward; BalanceToPrint)
                    {
                    }
                    column(BalanceForwardCaption; BalanceForwardCaptionLbl)
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
                    column(TempCustLedgEntryDocNo; TempCustLedgEntry."Document No.")
                    {
                    }
                    column(TempCustLedgEntryPostingDate; TempCustLedgEntry."Posting Date")
                    {
                    }
                    column(GetTermsStrTempCustLedgEntry; GetTermsString(TempCustLedgEntry))
                    {
                    }
                    column(TempCustLedgEntryDocType; TempCustLedgEntry."Document Type")
                    {
                    }
                    column(TempCustLedgEntryRemainingAmount; TempCustLedgEntry."Remaining Amount")
                    {
                    }
                    column(TempCustLedgEntryNegRemainingAmount; -TempCustLedgEntry."Remaining Amount")
                    {
                    }
                    column(BalanceToPrintOpenItem; BalanceToPrint)
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
                        Clear(AmountDue);
                    end;
                }
                dataitem(CustLedgerEntry4; "Cust. Ledger Entry")
                {
                    DataItemLink = "Customer No." = field("No.");
                    DataItemLinkReference = Customer;
                    DataItemTableView = sorting("Customer No.", "Posting Date");
                    column(DocumentNo_CustLedgerEntry4; "Document No.")
                    {
                    }
                    column(PostingDate_CustLedgerEntry4; "Posting Date")
                    {
                    }
                    column(GetTermsStr_CustLedgerEntry4; GetTermsString(CustLedgerEntry4))
                    {
                    }
                    column(DocumentType_CustLedgerEntry4; "Document Type")
                    {
                    }
                    column(Amount_CustLedgerEntry4; Amount)
                    {
                    }
                    column(NegAmount_CustLedgerEntry4; -Amount)
                    {
                    }
                    column(BalanceToPrint_CustLedgerEntry4; BalanceToPrint)
                    {
                    }
                    column(EntryNo_CustLedgerEntry4; "Entry No.")
                    {
                    }
                    column(CustomerNo_CustLedgerEntry4; "Customer No.")
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
                    AgingHead[1] := Text006;
                    PeriodEndingDate[1] := ToDate;
                    if AgingMethod = AgingMethod::"Due Date" then begin
                        PeriodEndingDate[2] := PeriodEndingDate[1];
                        for i := 3 to 4 do
                            PeriodEndingDate[i] := CalcDate(PeriodCalculation, PeriodEndingDate[i - 1]);
                        AgingDaysText := Text007;
                        AgingHead[2] := Text008 + ' '
                          + Format(PeriodEndingDate[1] - PeriodEndingDate[3])
                          + Text009;
                    end else begin
                        for i := 2 to 4 do
                            PeriodEndingDate[i] := CalcDate(PeriodCalculation, PeriodEndingDate[i - 1]);
                        AgingDaysText := Text010;
                        AgingHead[2] := Format(PeriodEndingDate[1] - PeriodEndingDate[2] + 1)
                          + ' - '
                          + Format(PeriodEndingDate[1] - PeriodEndingDate[3])
                          + Text009;
                    end;
                    PeriodEndingDate[5] := 0D;
                    AgingHead[3] := Format(PeriodEndingDate[1] - PeriodEndingDate[3] + 1)
                      + ' - '
                      + Format(PeriodEndingDate[1] - PeriodEndingDate[4])
                      + Text009;
                    AgingHead[4] := Text011 + ' '
                      + Format(PeriodEndingDate[1] - PeriodEndingDate[4])
                      + Text009;
                end;

                if "Currency Code" = '' then begin
                    Clear(Currency);
                    CurrencyDesc := '';
                end else begin
                    Currency.Get("Currency Code");
                    CurrencyDesc := StrSubstNo(Text013, Currency.Description);
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

                /* Update Statement Number so it can be printed on the document. However,
                  defer actually updating the customer file until the statement is complete. */
                if "Last Statement No." >= 9999 then
                    "Last Statement No." := 1
                else
                    "Last Statement No." := "Last Statement No." + 1;

                FormatAddress.Customer(CustomerAddress, Customer);
                StatementComplete := false;

                if LogInteraction then
                    if not CurrReport.Preview then
                        SegManagement.LogDocument(
                          7, Format(Customer."Last Statement No."), 0, 0, DATABASE::Customer, "No.", "Salesperson Code",
                          '', Text012 + Format(Customer."Last Statement No."), '');

            end;

            trigger OnPreDataItem()
            begin
                /* remove user-entered date filter; info now in FromDate & ToDate */
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
                                Error(Text014);
                        end;
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want to record the related interactions with the involved contact person in the Interaction Log Entry table.';
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
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if (not AllHavingEntries) and (not AllHavingBalance) then
            Error(Text000);
        if UpdateNumbers and CurrReport.Preview then
            Error(Text001);
        FromDate := Customer.GetRangeMin("Date Filter");
        ToDate := Customer.GetRangeMax("Date Filter");

        if (StatementStyle = StatementStyle::Balance) and (FromDate = ToDate) then
            Error(Text002 + ' '
              + Text003);

        if (AgingMethod <> AgingMethod::None) and (Format(PeriodCalculation) = '') then
            Error(Text004);

        if Format(PeriodCalculation) <> '' then
            Evaluate(PeriodCalculation, '-' + Format(PeriodCalculation));

        if PrintCompany then begin
            CompanyInformation.Get();
            FormatAddress.Company(CompanyAddress, CompanyInformation);
        end else
            Clear(CompanyAddress);
    end;

    var
        CompanyInformation: Record "Company Information";
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        TempAppliedCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        LanguageMgt: Codeunit Language;
        FormatAddress: Codeunit "Format Address";
        EntryAppMgt: Codeunit "Entry Application Management";
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
        SegManagement: Codeunit SegManagement;
        Text000: Label 'You must select either All with Entries or All with Balance.';
        Text001: Label 'You must print statements if you want to update statement numbers.';
        Text002: Label 'You must enter a range of dates (not just one date) in the';
        Text003: Label 'Date Filter if you want to print Balance Forward Statements.';
        Text004: Label 'You must enter a Length of Aging Periods if you select aging.';
        Text006: Label 'Current';
        Text007: Label 'Days overdue:';
        Text008: Label 'Up To';
        Text009: Label ' Days';
        Text010: Label 'Days old:';
        Text011: Label 'Over';
        Text012: Label 'Statement ';
        Text013: Label '(All amounts are in %1)';
        TempAmountDue: array[4] of Decimal;
        StatementStyle_Int: Integer;
        AgingMethod_Int: Integer;
        LogInteractionEnable: Boolean;
        Text014: Label 'You must enter a Length of Aging Periods if you select aging.';
        StatementBalanceCaptionLbl: Label 'Statement Balance';
        StatementAgingCaptionLbl: Label 'Statement Aging:';
        AgedAmountsCaptionLbl: Label 'Aged amounts:';
        BalanceForwardCaptionLbl: Label 'Balance Forward';

    procedure GetTermsString(var CustLedgerEntry: Record "Cust. Ledger Entry"): Text[250]
    var
        InvoiceHeader: Record "Sales Invoice Header";
        PaymentTerms: Record "Payment Terms";
    begin
        if (CustLedgerEntry."Document No." = '') or (CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Invoice) then
            exit('');

        if InvoiceHeader.ReadPermission then
            if InvoiceHeader.Get(CustLedgerEntry."Document No.") then begin
                if PaymentTerms.Get(InvoiceHeader."Payment Terms Code") then begin
                    if PaymentTerms.Description <> '' then
                        exit(PaymentTerms.Description);

                    exit(InvoiceHeader."Payment Terms Code");
                end;
                exit(InvoiceHeader."Payment Terms Code");
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
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;
using System.Text;
using System.Utilities;

report 121 "Customer - Balance to Date"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/CustomerBalancetoDate.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Balance to Date';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Date Filter", Blocked;
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(TxtCustGeTranmaxDtFilter; StrSubstNo(Text000, Format(GetRangeMax("Date Filter"))))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(PrintOnePrPage; PrintOnePrPage)
            {
            }
            column(CustFilter; CustFilter)
            {
            }
            column(PrintAmountInLCY; PrintAmountInLCY)
            {
            }
            column(CustTableCaptCustFilter; TableCaption + ': ' + CustFilter)
            {
            }
            column(No_Customer; "No.")
            {
            }
            column(Name_Customer; Name)
            {
            }
            column(PhoneNo_Customer; "Phone No.")
            {
                IncludeCaption = true;
            }
            column(CustBalancetoDateCaption; CustBalancetoDateCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(AllamtsareinLCYCaption; AllamtsareinLCYCaptionLbl)
            {
            }
            column(CustLedgEntryPostingDtCaption; CustLedgEntryPostingDtCaptionLbl)
            {
            }
            column(OriginalAmtCaption; OriginalAmtCaptionLbl)
            {
            }
            dataitem(CustLedgEntry3; "Cust. Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(PostingDt_CustLedgEntry; Format("Posting Date"))
                {
                    IncludeCaption = false;
                }
                column(DocType_CustLedgEntry; "Document Type")
                {
                    IncludeCaption = true;
                }
                column(DocNo_CustLedgEntry; "Document No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_CustLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(OriginalAmt; Format(OriginalAmt, 0, AutoFormat.ResolveAutoFormat(Enum::"Auto Format"::AmountFormat, CurrencyCode)))
                {
                }
                column(EntryNo_CustLedgEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(CurrencyCode; CurrencyCode)
                {
                }
                dataitem("Detailed Cust. Ledg. Entry"; "Detailed Cust. Ledg. Entry")
                {
                    DataItemLink = "Cust. Ledger Entry No." = field("Entry No."), "Posting Date" = field("Date Filter");
                    DataItemTableView = sorting("Cust. Ledger Entry No.", "Posting Date") where("Entry Type" = filter(<> "Initial Entry"));
                    column(EntType_DtldCustLedgEnt; "Entry Type")
                    {
                    }
                    column(postDt_DtldCustLedgEntry; Format("Posting Date"))
                    {
                    }
                    column(DocType_DtldCustLedgEntry; "Document Type")
                    {
                    }
                    column(DocNo_DtldCustLedgEntry; "Document No.")
                    {
                    }
                    column(Amt; Format(Amt, 0, AutoFormat.ResolveAutoFormat(Enum::"Auto Format"::AmountFormat, CurrencyCode)))
                    {
                    }
                    column(CurrencyCodeDtldCustLedgEntry; CurrencyCode)
                    {
                    }
                    column(EntNo_DtldCustLedgEntry; DtldCustLedgEntryNum)
                    {
                    }
                    column(RemainingAmt; Format(RemainingAmt, 0, AutoFormat.ResolveAutoFormat(Enum::"Auto Format"::AmountFormat, CurrencyCode)))
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not PrintUnappliedEntries then
                            if Unapplied then
                                CurrReport.Skip();

                        if PrintAmountInLCY then begin
                            Amt := "Amount (LCY)";
                            CurrencyCode := '';
                        end else begin
                            Amt := Amount;
                            CurrencyCode := "Currency Code";
                        end;
                        OnAfterDetailedCustLedgEntryOnAfterCalcAmt("Detailed Cust. Ledg. Entry", PrintAmountInLCY, Amt, CurrencyCode, MaxDate);

                        if Amt = 0 then
                            CurrReport.Skip();

                        DtldCustLedgEntryNum := DtldCustLedgEntryNum + 1;
                    end;

                    trigger OnPreDataItem()
                    begin
                        DtldCustLedgEntryNum := 0;
                        CustLedgEntry3.CopyFilter("Posting Date", "Posting Date");
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintAmountInLCY then begin
                        CalcFields("Original Amt. (LCY)", "Remaining Amt. (LCY)");
                        OriginalAmt := "Original Amt. (LCY)";
                        RemainingAmt := "Remaining Amt. (LCY)";
                        CurrencyCode := '';
                    end else begin
                        CalcFields("Original Amount", "Remaining Amount");
                        OriginalAmt := "Original Amount";
                        RemainingAmt := "Remaining Amount";
                        CurrencyCode := "Currency Code";
                    end;

                    OnAfterCustLedgEntry3OnAfterGetRecord(CustLedgEntry3, PrintAmountInLCY, OriginalAmt, RemainingAmt, CurrencyCode, MaxDate);
                end;

                trigger OnPreDataItem()
                var
                    TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
                    ClosedEntryIncluded: Boolean;
                begin
                    Reset();
                    SetRange("Date Filter", 0D, MaxDate);
                    FilterCustLedgerEntry(CustLedgEntry3);
                    if FindSet() then
                        repeat
                            if not Open then
                                ClosedEntryIncluded := CheckCustEntryIncluded("Entry No.");
                            if Open or ClosedEntryIncluded then begin
                                Mark(true);
                                TempCustLedgerEntry := CustLedgEntry3;
                                TempCustLedgerEntry.Insert();
                            end;
                        until Next() = 0;

                    SetCurrentKey("Entry No.");
                    MarkedOnly(true);

                    AddCustomerDimensionFilter(CustLedgEntry3);

                    CalcCustomerTotalAmount(TempCustLedgerEntry);
                end;
            }
            dataitem(Integer2; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(CustName; Customer.Name)
                {
                }
                column(TtlAmtCurrencyTtlBuff; TempCurrencyTotalBuffer."Total Amount")
                {
                    AutoFormatExpression = TempCurrencyTotalBuffer."Currency Code";
                    AutoFormatType = 1;
                }
                column(CurryCode_CurrencyTtBuff; TempCurrencyTotalBuffer."Currency Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        OK := TempCurrencyTotalBuffer.Find('-')
                    else
                        OK := TempCurrencyTotalBuffer.Next() <> 0;
                    if not OK then
                        CurrReport.Break();

                    TempCurrencyTotalBuffer2.UpdateTotal(
                      TempCurrencyTotalBuffer."Currency Code",
                      TempCurrencyTotalBuffer."Total Amount",
                      0,
                      Counter1);
                end;

                trigger OnPostDataItem()
                begin
                    TempCurrencyTotalBuffer.DeleteAll();
                end;

                trigger OnPreDataItem()
                begin
                    if not ShowEntriesWithZeroBalance then
                        TempCurrencyTotalBuffer.SetFilter("Total Amount", '<>0');
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if MaxDate = 0D then
                    Error(BlankMaxDateErr);

                CalcFields("Net Change (LCY)", "Net Change");

                if ("Net Change (LCY)" = 0) and
                   ("Net Change" = 0) and
                   (not ShowEntriesWithZeroBalance)
                then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                DateFilterTxt := GetFilter("Date Filter");
                SetRange("Date Filter", 0D, MaxDate);
            end;
        }
        dataitem(Integer3; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(CurryCode_CurrencyTtBuff2; TempCurrencyTotalBuffer2."Currency Code")
            {
            }
            column(TtlAmtCurrencyTtlBuff2; TempCurrencyTotalBuffer2."Total Amount")
            {
                AutoFormatExpression = TempCurrencyTotalBuffer2."Currency Code";
                AutoFormatType = 1;
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    OK := TempCurrencyTotalBuffer2.Find('-')
                else
                    OK := TempCurrencyTotalBuffer2.Next() <> 0;
                if not OK then
                    CurrReport.Break();
            end;

            trigger OnPostDataItem()
            begin
                TempCurrencyTotalBuffer2.DeleteAll();
            end;

            trigger OnPreDataItem()
            begin
                TempCurrencyTotalBuffer2.SetFilter("Total Amount", '<>0');
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Customer Balance to Date';
        AboutText = 'Generate customer statements to get a clear summary of amounts due. You can share the amounts with customers to follow up on payments. For example, if you need to close an accounting period or fiscal year.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Ending Date"; MaxDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date until which information in the report is shown.';
                        ShowMandatory = true;
                    }
                    field(PrintAmountInLCY; PrintAmountInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in LCY';
                        ToolTip = 'Specifies if amounts in the report are displayed in LCY. If you leave the check box blank, amounts are shown in foreign currencies.';
                    }
                    field(PrintOnePrPage; PrintOnePrPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Customer';
                        ToolTip = 'Specifies if each customer balance is printed on a separate page, in case two or more customers are included in the report.';
                    }
                    field(PrintUnappliedEntries; PrintUnappliedEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Unapplied Entries';
                        ToolTip = 'Specifies if the report includes entries that have been applied and later unapplied using the Unapply action. By default, the report does not show such entries.';
                    }
                    field(ShowEntriesWithZeroBalance; ShowEntriesWithZeroBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Entries with Zero Balance';
                        ToolTip = 'Specifies if the report must include customer ledger entries with a balance of 0. By default, the report only includes customer ledger entries with a positive or negative balance.';
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
    var
        FormatDocument: Codeunit "Format Document";
    begin
        CustFilter := FormatDocument.GetRecordFiltersWithCaptions(Customer);
    end;

    var
        AutoFormat: Codeunit "Auto Format";
        DtldCustLedgEntryNum: Integer;
        OK: Boolean;
        DateFilterTxt: Text;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Balance on %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CustBalancetoDateCaptionLbl: Label 'Customer - Balance to Date';
        CurrReportPageNoCaptionLbl: Label 'Page';
        AllamtsareinLCYCaptionLbl: Label 'All amounts are in LCY.';
        CustLedgEntryPostingDtCaptionLbl: Label 'Posting Date';
        OriginalAmtCaptionLbl: Label 'Amount';
        TotalCaptionLbl: Label 'Total';
        BlankMaxDateErr: Label 'Ending Date must have a value.';

    protected var
        TempCurrencyTotalBuffer: Record "Currency Total Buffer" temporary;
        TempCurrencyTotalBuffer2: Record "Currency Total Buffer" temporary;
        CurrencyCode: Code[10];
        MaxDate: Date;
        PrintAmountInLCY: Boolean;
        PrintOnePrPage: Boolean;
        ShowEntriesWithZeroBalance: Boolean;
        PrintUnappliedEntries: Boolean;
        CustFilter: Text;
        OriginalAmt: Decimal;
        Amt: Decimal;
        RemainingAmt: Decimal;
        Counter1: Integer;

    procedure InitializeRequest(NewPrintAmountInLCY: Boolean; NewPrintOnePrPage: Boolean; NewPrintUnappliedEntries: Boolean; NewEndingDate: Date)
    begin
        PrintAmountInLCY := NewPrintAmountInLCY;
        PrintOnePrPage := NewPrintOnePrPage;
        PrintUnappliedEntries := NewPrintUnappliedEntries;
        MaxDate := NewEndingDate;
    end;

    local procedure FilterCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.SetCurrentKey("Customer No.", "Posting Date");
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.SetRange("Posting Date", 0D, MaxDate);
    end;

    local procedure AddCustomerDimensionFilter(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        if Customer.GetFilter("Global Dimension 1 Filter") <> '' then
            CustLedgerEntry.SetFilter("Global Dimension 1 Code", Customer.GetFilter("Global Dimension 1 Filter"));
        if Customer.GetFilter("Global Dimension 2 Filter") <> '' then
            CustLedgerEntry.SetFilter("Global Dimension 2 Code", Customer.GetFilter("Global Dimension 2 Filter"));
        if Customer.GetFilter("Currency Filter") <> '' then
            CustLedgerEntry.SetFilter("Currency Code", Customer.GetFilter("Currency Filter"));
    end;

    local procedure CalcCustomerTotalAmount(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary)
    begin
        TempCustLedgerEntry.SetCurrentKey("Entry No.");
        TempCustLedgerEntry.SetRange("Date Filter", 0D, MaxDate);
        AddCustomerDimensionFilter(TempCustLedgerEntry);
        if TempCustLedgerEntry.FindSet() then
            repeat
                CalcRemainingAmount(TempCustLedgerEntry);
                if (RemainingAmt <> 0) or ShowEntriesWithZeroBalance then
                    TempCurrencyTotalBuffer.UpdateTotal(
                      CurrencyCode,
                      RemainingAmt,
                      0,
                      Counter1);
                OnCalcCustomerTotalAmountOnAfterUpdateCurrencyTotalBuffer(TempCustLedgerEntry, TempCurrencyTotalBuffer, Counter1, RemainingAmt, ShowEntriesWithZeroBalance);
            until TempCustLedgerEntry.Next() = 0;
    end;

    local procedure CalcRemainingAmount(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary);
    begin
        if PrintAmountInLCY then begin
            TempCustLedgerEntry.CalcFields("Remaining Amt. (LCY)");
            RemainingAmt := TempCustLedgerEntry."Remaining Amt. (LCY)";
            CurrencyCode := '';
        end else begin
            TempCustLedgerEntry.CalcFields("Remaining Amount");
            RemainingAmt := TempCustLedgerEntry."Remaining Amount";
            CurrencyCode := TempCustLedgerEntry."Currency Code";
        end;

        OnAfterCalcRemainingAmount(TempCustLedgerEntry, PrintAmountInLCY, RemainingAmt, CurrencyCode);
    end;

    local procedure CheckCustEntryIncluded(EntryNo: Integer): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ClosingCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry.Get(EntryNo) and (CustLedgerEntry."Posting Date" <= MaxDate) then begin
            CustLedgerEntry.SetRange("Date Filter", 0D, MaxDate);
            CustLedgerEntry.CalcFields("Remaining Amount", "Original Amount", Amount);
            if CustLedgerEntry."Remaining Amount" <> 0 then
                exit(not CheckUnbalancedUnappliedEntryExists(EntryNo));

            if (ShowEntriesWithZeroBalance) and (DateFilterTxt <> '') then begin
                if ClosingCustLedgerEntry.Get(CustLedgerEntry."Closed by Entry No.") then begin
                    ClosingCustLedgerEntry.SetFilter("Date Filter", DateFilterTxt);
                    if CheckCustEntryIncludedWhenShowEntriesWithZeroBalance(ClosingCustLedgerEntry) then
                        exit(true);
                end;

                if (CustLedgerEntry.Amount = 0) and
                   (CustLedgerEntry."Original Amount" = 0) and
                   not CustLedgerEntry.Open and
                   (CustLedgerEntry."Posting Date" <= MaxDate)
                then
                    exit(true);
            end;

            if PrintUnappliedEntries then
                exit(CheckUnappliedEntryExists(EntryNo));
        end;

        exit(false);
    end;

    local procedure CheckUnappliedEntryExists(EntryNo: Integer): Boolean
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", EntryNo);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetFilter("Posting Date", '>%1', MaxDate);
        DetailedCustLedgEntry.SetRange(Unapplied, true);
        exit(not DetailedCustLedgEntry.IsEmpty);
    end;

    local procedure CheckCustEntryIncludedWhenShowEntriesWithZeroBalance(var ClosingCustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        DateListText: List of [Text];
        MinDate: Date;
        ListMaxDate: Date;
    begin
        if StrPos(DateFilterTxt, '..') > 0 then begin
            DateListText := ClosingCustLedgerEntry.GetFilter("Date Filter").Split('..');
            if DateListText.Get(1) <> '' then
                Evaluate(MinDate, DateListText.Get(1));

            if DateListText.Get(2) <> '' then
                Evaluate(ListMaxDate, DateListText.Get(2));

            if (ListMaxDate = 0D) and (MinDate <> 0D) then
                exit(ClosingCustLedgerEntry."Posting Date" >= MinDate);

            if true in [
                (ClosingCustLedgerEntry."Posting Date" <= ListMaxDate) and (ClosingCustLedgerEntry."Posting Date" >= MinDate),
                (ClosingCustLedgerEntry."Posting Date" <= ListMaxDate)]
            then
                exit(true);
        end else
            if (ClosingCustLedgerEntry."Posting Date" = ClosingCustLedgerEntry.GetRangeMax("Date Filter")) then
                exit(true);
    end;

    local procedure CheckUnbalancedUnappliedEntryExists(EntryNo: Integer): Boolean
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", EntryNo);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetFilter("Posting Date", '>%1', MaxDate);
        DetailedCustLedgEntry.SetRange(Unapplied, true);
        DetailedCustLedgEntry.CalcSums(Amount);
        exit(DetailedCustLedgEntry.Amount <> 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcRemainingAmount(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; PrintAmountInLCY: Boolean; var RemainingAmt: Decimal; var CurrencyCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCustLedgEntry3OnAfterGetRecord(var CustLedgerEntry: Record "Cust. Ledger Entry"; PrintAmountInLCY: Boolean; var OriginalAmt: Decimal; var RemainingAmt: Decimal; var CurrencyCode: Code[10]; MaxDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDetailedCustLedgEntryOnAfterCalcAmt(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; PrintAmountInLCY: Boolean; var Amt: Decimal; var CurrencyCode: Code[10]; MaxDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCustomerTotalAmountOnAfterUpdateCurrencyTotalBuffer(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var TempCurrencyTotalBuffer: Record "Currency Total Buffer" temporary; Counter1: Integer; RemainingAmt: Decimal; ShowEntriesWithZeroBalance: Boolean)
    begin
    end;
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 11540 "SR Cust. - Balance to Date"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/SRCustBalancetoDate.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'SR Customer - Balance to Date';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", Blocked;
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CustGetRangeMaxDateFilter; StrSubstNo(Text000, Format(Customer.GetRangeMax("Date Filter"))))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CustTableCaptionCustFilter; Customer.TableCaption + ': ' + CustFilter)
            {
            }
            column(PrintOnePerPage; PrintOnePerPage)
            {
            }
            column(OutputNo; OutputNo)
            {
            }
            column(No_Cust; "No.")
            {
            }
            column(Address; Name + ', ' + "Post Code" + ' ' + City)
            {
            }
            column(TransferAmt; TransferAmt)
            {
            }
            column(CustBalancetoDateCaption; CustBalancetoDateCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(DueDateCaption; DueDateCaptionLbl)
            {
            }
            column(AgeCaption; AgeCaptionLbl)
            {
            }
            column(DateCaption; DateCaptionLbl)
            {
            }
            column(DaysCaption; DaysCaptionLbl)
            {
            }
            column(ReferenceCaption; ReferenceCaptionLbl)
            {
            }
            column(EntryNoCaption; EntryNoCaptionLbl)
            {
            }
            column(NoCaption; NoCaptionLbl)
            {
            }
            column(DocumentCaption; DocumentCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(AmountLCYCaption; AmountLCYCaptionLbl)
            {
            }
            column(TransferCaption; TransferCaptionLbl)
            {
            }
            dataitem(CustLedgEntry3; "Cust. Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(PostingDate_CustLedgEntry; Format("Posting Date"))
                {
                }
                column(DocType_CustLedgEntry; "Document Type")
                {
                }
                column(DocNo_CustLedgEntry; "Document No.")
                {
                }
                column(Desc_CustLedgEntry; Description)
                {
                }
                column(OriginalAmt; OriginalAmt)
                {
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                }
                column(EntryNo_CustLedgEntry; "Entry No.")
                {
                }
                column(CurrencyCode; CurrencyCode)
                {
                }
                column(AgeDays; AgeDays)
                {
                }
                column(DueDays; DueDays)
                {
                }
                column(DueDate_CustLedgEntry; Format("Due Date"))
                {
                }
                column(NoOpenEntries; NoOpenEntries)
                {
                }
                column(OriginalAmtLCY; OriginalAmtLCY)
                {
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                }
                column(DateFilter_CustLedgEntry; "Date Filter")
                {
                }
                dataitem("Detailed Cust. Ledg. Entry"; "Detailed Cust. Ledg. Entry")
                {
                    DataItemLink = "Cust. Ledger Entry No." = field("Entry No."), "Posting Date" = field("Date Filter");
                    DataItemTableView = sorting("Cust. Ledger Entry No.", "Posting Date") where("Entry Type" = filter(<> "Initial Entry"));
                    column(EntryType_DtldCustLedgEntry; "Entry Type")
                    {
                    }
                    column(PostingDate_DtldCustLedgEntry; Format("Posting Date"))
                    {
                    }
                    column(DocType_DtldCustLedgEntry; "Document Type")
                    {
                    }
                    column(DocNo_DtldCustLedgEntry; "Document No.")
                    {
                    }
                    column(Amt; Amt)
                    {
                        AutoFormatExpression = CurrencyCode;
                        AutoFormatType = 1;
                    }
                    column(CurrencyCode_DtldCustLedgEntry; CurrencyCode)
                    {
                    }
                    column(AmtLCY; AmtLCY)
                    {
                        AutoFormatExpression = CurrencyCode;
                        AutoFormatType = 1;
                    }
                    column(RemainingAmt; RemainingAmt)
                    {
                        AutoFormatExpression = CurrencyCode;
                        AutoFormatType = 1;
                    }
                    column(CustLedgEntry3DocNo; Text001 + ' ' + CustLedgEntry3."Document No.")
                    {
                    }
                    column(RemainingAmtLCY; RemainingAmtLCY)
                    {
                        AutoFormatExpression = CurrencyCode;
                        AutoFormatType = 1;
                    }
                    column(EntryNo_DtldCustLedgEntry; "Entry No.")
                    {
                    }
                    column(ConsNo_DtldCustLedgEntry; ConsNoDtldCustLedgEntry)
                    {
                    }
                    column(CustLedgEntryNo_DtldCustLedgEntry; "Cust. Ledger Entry No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not PrintUnappliedEntries then
                            if Unapplied then
                                CurrReport.Skip();

                        AmtLCY := "Amount (LCY)";
                        Amt := Amount;
                        CurrencyCode := "Currency Code";

                        if (Amt = 0) and (AmtLCY = 0) then
                            CurrReport.Skip();

                        if CurrencyCode = '' then begin
                            CurrencyCode := GLSetup."LCY Code";
                            Amt := 0;
                        end;
                        ConsNoDtldCustLedgEntry += 1;
                    end;

                    trigger OnPreDataItem()
                    begin
                        ConsNoDtldCustLedgEntry := 0;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields("Original Amt. (LCY)", "Remaining Amt. (LCY)", "Original Amount", "Remaining Amount");
                    OriginalAmtLCY := "Original Amt. (LCY)";
                    RemainingAmtLCY := "Remaining Amt. (LCY)";
                    OriginalAmt := "Original Amount";
                    RemainingAmt := "Remaining Amount";
                    CurrencyCode := "Currency Code";
                    if CurrencyCode = '' then
                        CurrencyCode := GLSetup."LCY Code";

                    CurrencyTotalBuffer.UpdateTotal(CurrencyCode, RemainingAmt, RemainingAmtLCY, Counter1);

                    AgeDays := FixedDay - "Posting Date";
                    if ("Due Date" <> 0D) and (FixedDay > "Due Date") then
                        DueDays := FixedDay - "Due Date"
                    else
                        DueDays := 0;
                    NoOpenEntries := NoOpenEntries + 1;

                    if CurrencyCode = GLSetup."LCY Code" then begin
                        RemainingAmt := 0;
                        OriginalAmt := 0;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    Reset();
                    DtldCustLedgEntry.SetCurrentKey("Customer No.", "Posting Date", "Entry Type");
                    DtldCustLedgEntry.SetRange("Customer No.", Customer."No.");
                    DtldCustLedgEntry.SetRange("Posting Date", CalcDate('<+1D>', FixedDay), 99991231D);
                    DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
                    if not PrintUnappliedEntries then
                        DtldCustLedgEntry.SetRange(Unapplied, false);

                    if DtldCustLedgEntry.FindSet() then
                        repeat
                            "Entry No." := DtldCustLedgEntry."Cust. Ledger Entry No.";
                            Mark(true);
                        until DtldCustLedgEntry.Next() = 0;

                    SetCurrentKey("Customer No.", Open);
                    SetRange("Customer No.", Customer."No.");
                    SetRange(Open, true);
                    SetRange("Posting Date", 0D, FixedDay);
                    if FindSet() then
                        repeat
                            Mark(true);
                        until Next() = 0;

                    SetCurrentKey("Entry No.");
                    SetRange(Open);
                    MarkedOnly(true);
                    SetRange("Date Filter", 0D, FixedDay);
                end;
            }
            dataitem(Integer2; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(TotalCustName; Text002 + ' ' + Customer.Name)
                {
                }
                column(CurrencyTotalBuffTotalAmt; CurrencyTotalBuffer."Total Amount")
                {
                    AutoFormatExpression = CurrencyTotalBuffer."Currency Code";
                    AutoFormatType = 1;
                }
                column(CurrencyTotalBuffCurrCode; CurrencyTotalBuffer."Currency Code")
                {
                }
                column(CurrencyTotalBuffTotalAmtLCY; CurrencyTotalBuffer."Total Amount (LCY)")
                {
                    AutoFormatExpression = CurrencyTotalBuffer."Currency Code";
                    AutoFormatType = 1;
                }
                column(GLSetupLCYCode; GLSetup."LCY Code")
                {
                }
                column(CustomerTotalLCY; CustomerTotalLCY)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        OK := CurrencyTotalBuffer.FindSet()
                    else
                        OK := CurrencyTotalBuffer.Next() <> 0;
                    if not OK then
                        CurrReport.Break();

                    CurrencyTotalBuffer2.UpdateTotal(
                      CurrencyTotalBuffer."Currency Code",
                      CurrencyTotalBuffer."Total Amount",
                      CurrencyTotalBuffer."Total Amount (LCY)",
                      Counter1);

                    CustomerTotalLCY += CurrencyTotalBuffer."Total Amount (LCY)";

                    if (CurrencyTotalBuffer."Total Amount" = 0) and
                       (CurrencyTotalBuffer."Total Amount (LCY)" = 0)
                    then
                        CurrReport.Skip();
                end;

                trigger OnPostDataItem()
                begin
                    CurrencyTotalBuffer.DeleteAll();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                SetRange("Date Filter", 0D, FixedDay);
                CustomerTotalLCY := 0;
                NoOpenEntries := 0;
                if PrintOnePerPage then
                    OutputNo += 1;
            end;

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                OutputNo := 0;
            end;
        }
        dataitem(Integer3; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(CurrencyTotalBuff2CurrCode; CurrencyTotalBuffer2."Currency Code")
            {
            }
            column(CurrencyTotalBuff2TotalAmt; CurrencyTotalBuffer2."Total Amount")
            {
                AutoFormatExpression = CurrencyTotalBuffer2."Currency Code";
                AutoFormatType = 1;
            }
            column(TotalReportLCY; TotalReportLCY)
            {
                AutoFormatType = 1;
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(TotalBalancetoDateCaption; TotalBalancetoDateCaptionLbl)
            {
            }
            column(GLSetupLCYCode_Integer3; GLSetup."LCY Code")
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    OK := CurrencyTotalBuffer2.FindSet()
                else
                    OK := CurrencyTotalBuffer2.Next() <> 0;
                if not OK then
                    CurrReport.Break();

                TotalReportLCY := TotalReportLCY + CurrencyTotalBuffer2."Total Amount (LCY)";

                if (CurrencyTotalBuffer2."Total Amount" = 0) and
                   (CurrencyTotalBuffer2."Total Amount (LCY)" = 0)
                then
                    CurrReport.Skip();
            end;

            trigger OnPostDataItem()
            begin
                CurrencyTotalBuffer2.DeleteAll();

                Customer.SetRange("Date Filter");
                if CheckGLReceivables and (Customer.GetFilters = '') then
                    CheckReceivablesAccounts();
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
                    field(FixedDay; FixedDay)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Fixed Day';
                        ToolTip = 'Specifies the date from which due customer payments are included.';
                    }
                    field(PrintOnePerPage; PrintOnePerPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Customer';
                        ToolTip = 'Specifies if each customer balance is printed on a separate page.';
                    }
                    field(CheckGLReceivables; CheckGLReceivables)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Check Receivables Accounts';
                        ToolTip = 'Specifies if the calculated balance at close out matches the balance of the combined accounts receivable in the general ledger. A warning message is displayed if there is any variance.';
                    }
                    field(PrintUnappliedEntries; PrintUnappliedEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Unapplied Entries';
                        ToolTip = 'Specifies if the report includes unapplied entries.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if FixedDay = 0D then
                FixedDay := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CustFilter := Customer.GetFilters();
    end;

    var
        CurrencyTotalBuffer: Record "Currency Total Buffer" temporary;
        CurrencyTotalBuffer2: Record "Currency Total Buffer" temporary;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GLSetup: Record "General Ledger Setup";
        PrintOnePerPage: Boolean;
        CustFilter: Text[250];
        FixedDay: Date;
        OriginalAmt: Decimal;
        OriginalAmtLCY: Decimal;
        Amt: Decimal;
        AmtLCY: Decimal;
        RemainingAmt: Decimal;
        RemainingAmtLCY: Decimal;
        Counter1: Integer;
        OK: Boolean;
        CurrencyCode: Code[10];
        AgeDays: Integer;
        DueDays: Integer;
        NoOpenEntries: Integer;
        TransferAmt: Decimal;
        TotalReportLCY: Decimal;
        CheckGLReceivables: Boolean;
        PrintUnappliedEntries: Boolean;
        Text000: Label 'Balance on %1';
        Text001: Label 'Remaining Amount Document';
        Text002: Label 'Total';
        Text003: Label 'The calculated balance of the report doesn''t meet the balance of all receivables accounts in G/L. There''s a difference of %1 %2. Please check if no direct postings have been done on this accounts.';
        CustBalancetoDateCaptionLbl: Label 'Customer - Balance to Date';
        PageNoCaptionLbl: Label 'Page';
        DueDateCaptionLbl: Label 'Due Date';
        AgeCaptionLbl: Label 'Age';
        DateCaptionLbl: Label 'Date';
        DaysCaptionLbl: Label 'Days';
        ReferenceCaptionLbl: Label 'Reference';
        EntryNoCaptionLbl: Label 'Entry No.';
        NoCaptionLbl: Label 'No.';
        DocumentCaptionLbl: Label 'Document';
        DescriptionCaptionLbl: Label 'Description';
        AmountCaptionLbl: Label 'Amount';
        AmountLCYCaptionLbl: Label 'Amount LCY';
        TransferCaptionLbl: Label 'Transfer';
        TotalCaptionLbl: Label 'Total';
        TotalBalancetoDateCaptionLbl: Label 'Total Balance to Date';
        CustomerTotalLCY: Decimal;
        ConsNoDtldCustLedgEntry: Integer;
        OutputNo: Integer;

    [Scope('OnPrem')]
    procedure CheckReceivablesAccounts()
    var
        CustPostGroup: Record "Customer Posting Group";
        GLAcc: Record "G/L Account";
        TmpGLAcc: Record "G/L Account" temporary;
        TotalReceivables: Decimal;
    begin
        if CustPostGroup.FindSet() then begin
            // Insert Receivabels Accounts in temp. table because the same account can be in
            // more than one posting groups
            repeat
                if (not TmpGLAcc.Get(CustPostGroup."Receivables Account")) and
                   (CustPostGroup."Receivables Account" <> '')
                then begin
                    TmpGLAcc."No." := CustPostGroup."Receivables Account";
                    TmpGLAcc.Insert();
                end;
            until CustPostGroup.Next() = 0;

            if TmpGLAcc.FindSet() then
                repeat
                    GLAcc.Get(TmpGLAcc."No.");
                    GLAcc.SetFilter("Date Filter", '..%1', FixedDay);
                    GLAcc.CalcFields("Balance at Date");
                    TotalReceivables := TotalReceivables + GLAcc."Balance at Date";
                until TmpGLAcc.Next() = 0;

            if TotalReportLCY <> TotalReceivables then
                Message(Text003, GLSetup."LCY Code", Abs(TotalReportLCY - TotalReceivables));
        end;
    end;
}


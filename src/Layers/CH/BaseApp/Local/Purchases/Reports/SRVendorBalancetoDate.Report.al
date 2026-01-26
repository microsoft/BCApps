// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 11559 "SR Vendor - Balance to Date"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/SRVendorBalancetoDate.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'SR Vendor - Balance to Date';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", Blocked;
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(DateFilter; StrSubstNo(Text000, Format(Vendor.GetRangeMax("Date Filter"))))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(VendFilter; Vendor.TableCaption + ': ' + VendFilter)
            {
            }
            column(VendorFilter; VendFilter)
            {
            }
            column(PrintOnePerPage; PrintOnePerPage)
            {
            }
            column(No_Vend; "No.")
            {
            }
            column(Address; Name + ', ' + "Post Code" + ' ' + City)
            {
            }
            column(TransferAmt; TransferAmt)
            {
            }
            column(VendorBalancetoDateCaption; VendorBalancetoDateCaptionLbl)
            {
            }
            column(OutputNo; outputno)
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
            dataitem(VendLedgEntry3; "Vendor Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(PostingDate_VendLedgEntry; Format("Posting Date"))
                {
                }
                column(DocType_VendLedgEntry; "Document Type")
                {
                }
                column(DocNo_VendLedgEntry; "Document No.")
                {
                }
                column(Description; Description)
                {
                }
                column(OriginalAmt; OriginalAmt)
                {
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                }
                column(EntryNo_VendLedgEntry; "Entry No.")
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
                column(DueDate_VendLedgEntry; Format("Due Date"))
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
                column(DateFilter_VendLedgEntry; "Date Filter")
                {
                }
                dataitem("Detailed Vendor Ledg. Entry"; "Detailed Vendor Ledg. Entry")
                {
                    DataItemLink = "Vendor Ledger Entry No." = field("Entry No."), "Posting Date" = field("Date Filter");
                    DataItemTableView = sorting("Vendor Ledger Entry No.", "Posting Date") where("Entry Type" = filter(<> "Initial Entry"));
                    column(EntryType_DtldVendLedgEntry; "Entry Type")
                    {
                    }
                    column(PostingDate_DtldVendLedgEntry; Format("Posting Date"))
                    {
                    }
                    column(DocType_DtldVendLedgEntry; "Document Type")
                    {
                    }
                    column(DocNo_DtldVendLedgEntry; "Document No.")
                    {
                    }
                    column(Amt; Amt)
                    {
                        AutoFormatExpression = CurrencyCode;
                        AutoFormatType = 1;
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
                    column(VendLedgEntryDocNo; Text001 + ' ' + VendLedgEntry3."Document No.")
                    {
                    }
                    column(RemainingAmtLCY; RemainingAmtLCY)
                    {
                        AutoFormatExpression = CurrencyCode;
                        AutoFormatType = 1;
                    }
                    column(EntryNo_DtldVendLedgEntry; "Entry No.")
                    {
                    }
                    column(ConsNo_DtldVendLedgEntry; ConsNoDtldVendLedgEntry)
                    {
                    }
                    column(VendLedgEntryNo_DtldVendLedgEntry; "Vendor Ledger Entry No.")
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
                        ConsNoDtldVendLedgEntry += 1;
                    end;

                    trigger OnPreDataItem()
                    begin
                        ConsNoDtldVendLedgEntry := 0;
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
                    DtldVendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date", "Entry Type");
                    DtldVendLedgEntry.SetRange("Vendor No.", Vendor."No.");
                    DtldVendLedgEntry.SetRange("Posting Date", CalcDate('<+1D>', FixedDay), 99991231D);
                    DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
                    if not PrintUnappliedEntries then
                        DtldVendLedgEntry.SetRange(Unapplied, false);

                    if DtldVendLedgEntry.Find('-') then
                        repeat
                            "Entry No." := DtldVendLedgEntry."Vendor Ledger Entry No.";
                            Mark(true);
                        until DtldVendLedgEntry.Next() = 0;

                    SetCurrentKey("Vendor No.", Open);
                    SetRange("Vendor No.", Vendor."No.");
                    SetRange(Open, true);
                    SetRange("Posting Date", 0D, FixedDay);
                    if Find('-') then
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
                column(VendorName; Text002 + ' ' + Vendor.Name)
                {
                }
                column(CurrTotalBuffTotalAmt; CurrencyTotalBuffer."Total Amount")
                {
                    AutoFormatExpression = CurrencyTotalBuffer."Currency Code";
                    AutoFormatType = 1;
                }
                column(CurrTotalBuffCurrCode; CurrencyTotalBuffer."Currency Code")
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

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        OK := CurrencyTotalBuffer.Find('-')
                    else
                        OK := CurrencyTotalBuffer.Next() <> 0;
                    if not OK then
                        CurrReport.Break();

                    CurrencyTotalBuffer2.UpdateTotal(
                      CurrencyTotalBuffer."Currency Code",
                      CurrencyTotalBuffer."Total Amount",
                      CurrencyTotalBuffer."Total Amount (LCY)",
                      Counter1);

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
                NoOpenEntries := 0;

                if PrintOnePerPage then
                    outputno := outputno + 1;
            end;

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                outputno := 1
            end;
        }
        dataitem(Integer3; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(CurrencyTotalBuffer2_CurrCode; CurrencyTotalBuffer2."Currency Code")
            {
            }
            column(CurrencyTotalBuffer2_TotAmt; CurrencyTotalBuffer2."Total Amount")
            {
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
            column(GLSetupLCYCode2; GLSetup."LCY Code")
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    OK := CurrencyTotalBuffer2.Find('-')
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

                Vendor.SetRange("Date Filter");
                if CheckGLPayables and (Vendor.GetFilters = '') then
                    CheckPayablesAccounts();
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
                        ToolTip = 'Specifies the date from which due vendor payments are included.';
                    }
                    field(PrintOnePerPage; PrintOnePerPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Vendor';
                        ToolTip = 'Specifies if each vendor balance is printed on a separate page.';
                    }
                    field(CheckGLPayables; CheckGLPayables)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Check Payables Accounts';
                        ToolTip = 'Specifies if the calculated balance at close out matches the balance of the combined accounts payables in the general ledger. A warning message is displayed if there is any variance.';
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
        VendFilter := Vendor.GetFilters();
    end;

    var
        Text000: Label 'Balance on %1';
        Text001: Label 'Remaining Amount Document';
        Text002: Label 'Total';
        Text003: Label 'The calculated balance of the report doesn''t meet the balance of all payables accounts in G/L. There''s a difference of %1 %2. Please check if no direct postings have been done on this accounts.';
        CurrencyTotalBuffer: Record "Currency Total Buffer" temporary;
        CurrencyTotalBuffer2: Record "Currency Total Buffer" temporary;
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        GLSetup: Record "General Ledger Setup";
        PrintOnePerPage: Boolean;
        VendFilter: Text[250];
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
        CheckGLPayables: Boolean;
        PrintUnappliedEntries: Boolean;
        VendorBalancetoDateCaptionLbl: Label 'Vendor - Balance to Date';
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
        outputno: Integer;
        ConsNoDtldVendLedgEntry: Integer;

    [Scope('OnPrem')]
    procedure CheckPayablesAccounts()
    var
        VendPostGroup: Record "Vendor Posting Group";
        GLAcc: Record "G/L Account";
        TmpGLAcc: Record "G/L Account" temporary;
        TotalPayables: Decimal;
    begin
        if VendPostGroup.Find('-') then begin

            // Insert Payables Accounts in temp. table because the same account can be in
            // more than one posting groups
            repeat
                if (not TmpGLAcc.Get(VendPostGroup."Payables Account")) and
                   (VendPostGroup."Payables Account" <> '')
                then begin
                    TmpGLAcc."No." := VendPostGroup."Payables Account";
                    TmpGLAcc.Insert();
                end;
            until VendPostGroup.Next() = 0;

            if TmpGLAcc.Find('-') then
                repeat
                    GLAcc.Get(TmpGLAcc."No.");
                    GLAcc.SetFilter("Date Filter", '..%1', FixedDay);
                    GLAcc.CalcFields("Balance at Date");
                    TotalPayables := TotalPayables + GLAcc."Balance at Date";
                until TmpGLAcc.Next() = 0;

            if TotalReportLCY <> TotalPayables then
                Message(Text003, GLSetup."LCY Code", Abs(TotalReportLCY - TotalPayables));
        end;
    end;
}


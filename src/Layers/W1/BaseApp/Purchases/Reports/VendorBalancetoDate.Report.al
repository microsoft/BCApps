// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Text;
using System.Utilities;

report 321 "Vendor - Balance to Date"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/VendorBalancetoDate.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor - Balance to Date';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;
    WordMergeDataItem = Vendor;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", Blocked, "Date Filter";
            column(StrNoVenGetMaxDtFilter; StrSubstNo(Text000, Format(GetRangeMax("Date Filter"))))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(VendFilter; VendFilter)
            {
            }
            column(PrintAmountInLCY; PrintAmountInLCY)
            {
            }
            column(PrintOnePrPage; PrintOnePrPage)
            {
            }
            column(VendorCaption; TableCaption + ': ' + VendFilter)
            {
            }
            column(No_Vendor; "No.")
            {
            }
            column(Name_Vendor; Name)
            {
            }
            column(PhoneNo_Vendor; "Phone No.")
            {
                IncludeCaption = true;
            }
            column(VendorBalancetoDateCptn; VendorBalancetoDateCptnLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(AllamountsareinLCYCaption; AllamountsareinLCYCaptionLbl)
            {
            }
            column(PostingDateCption; PostingDateCptionLbl)
            {
            }
            column(OriginalAmtCaption; OriginalAmtCaptionLbl)
            {
            }
            column(DocNoCaption; DocNoCaption)
            {
            }
            dataitem(VendLedgEntry3; "Vendor Ledger Entry")
            {
                DataItemTableView = sorting("Entry No.");
                column(PostDt_VendLedgEntry3; Format("Posting Date"))
                {
                }
                column(DocType_VendLedgEntry3; "Document Type")
                {
                    IncludeCaption = true;
                }
                column(DocNo_VendLedgEntry3; VendLedgDocumentNo)
                {
                }
                column(Desc_VendLedgEntry3; Description)
                {
                    IncludeCaption = true;
                }
                column(OriginalAmt; Format(OriginalAmt, 0, AutoFormat.ResolveAutoFormat(Enum::"Auto Format"::AmountFormat, CurrencyCode)))
                {
                }
                column(EntryNo_VendLedgEntry3; "Entry No.")
                {
                    IncludeCaption = true;
                }
                column(CurrencyCode; CurrencyCode)
                {
                }
                dataitem("Detailed Vendor Ledg. Entry"; "Detailed Vendor Ledg. Entry")
                {
                    DataItemLink = "Vendor Ledger Entry No." = field("Entry No."), "Posting Date" = field("Date Filter");
                    DataItemTableView = sorting("Vendor Ledger Entry No.", "Posting Date") where("Entry Type" = filter(<> "Initial Entry"));
                    column(EntryTp_DtldVendLedgEntry; "Entry Type")
                    {
                    }
                    column(PostDate_DtldVendLedEnt; Format("Posting Date"))
                    {
                    }
                    column(DocType_DtldVendLedEnt; "Document Type")
                    {
                    }
                    column(DocNo_DtldVendLedgEntry; DtldVendLedgDocumentNo)
                    {
                    }
                    column(Amt; Format(Amt, 0, AutoFormat.ResolveAutoFormat(Enum::"Auto Format"::AmountFormat, CurrencyCode)))
                    {
                    }
                    column(CurrencyCode1; CurrencyCode)
                    {
                    }
                    column(DtldVendtLedgEntryNum; DtldVendtLedgEntryNum)
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
                        if Amt = 0 then
                            CurrReport.Skip();

                        if UseExternalDocNo then
                            DtldVendLedgDocumentNo := GetAppliedEntryExternalDocNo("Applied Vend. Ledger Entry No.")
                        else
                            DtldVendLedgDocumentNo := "Document No.";

                        DtldVendtLedgEntryNum := DtldVendtLedgEntryNum + 1;
                    end;

                    trigger OnPreDataItem()
                    begin
                        DtldVendtLedgEntryNum := 0;
                        VendLedgEntry3.CopyFilter("Posting Date", "Posting Date");
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

                    if UseExternalDocNo then begin
                        VendLedgDocumentNo := "External Document No.";
                        if VendLedgDocumentNo = '' then
                            VendLedgDocumentNo := "Document No.";
                    end else
                        VendLedgDocumentNo := "Document No.";

                    OnAfterVendLedgEntry3OnAfterGetRecord(VendLedgEntry3, PrintAmountInLCY, OriginalAmt, RemainingAmt, CurrencyCode);
                end;

                trigger OnPreDataItem()
                begin
                    Reset();
                    FilterDetailedVendLedgerEntry(DtldVendLedgEntry, StrSubstNo('%1..%2', MaxDate + 1, DMY2Date(31, 12, 9999)));
                    if DtldVendLedgEntry.Find('-') then
                        repeat
                            "Entry No." := DtldVendLedgEntry."Vendor Ledger Entry No.";
                            if CheckVendLedgerEntryIncludedWithCache("Entry No.") then
                                Mark(true);
                        until DtldVendLedgEntry.Next() = 0;

                    FilterVendorLedgerEntry(VendLedgEntry3);
                    if Find('-') then
                        repeat
                            if CheckVendLedgerEntryIncludedWithCache("Entry No.") then
                                Mark(true);
                        until Next() = 0;

                    SetCurrentKey("Entry No.");
                    SetRange(Open);
                    MarkedOnly(true);
                    SetRange("Date Filter", 0D, MaxDate);

                    AddVendorDimensionFilter(VendLedgEntry3);

                    CalcTotalVendorAmount();
                end;
            }
            dataitem(Integer2; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(Name1_Vendor; Vendor.Name)
                {
                }
                column(CurrTotalBufferTotalAmt; TempCurrencyTotalBuffer."Total Amount")
                {
                    AutoFormatExpression = TempCurrencyTotalBuffer."Currency Code";
                    AutoFormatType = 1;
                }
                column(CurrTotalBufferCurrCode; TempCurrencyTotalBuffer."Currency Code")
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
            var
                ShouldSkipVendor: Boolean;
            begin
                Clear(VendorLedgerEntriesIncluded);
                MaxDate := GetRangeMax("Date Filter");
                if MinDate = 0D then
                    MinDate := GetRangeMin("Date Filter");
                SetRange("Date Filter", 0D, MaxDate);
                CalcFields("Net Change (LCY)", "Net Change");

                ShouldSkipVendor := ("Net Change (LCY)" = 0) and ("Net Change" = 0) and (not ShowEntriesWithZeroBalance);
                OnVendorOnAfterGetRecordOnAfterCalcShouldSkipVendor(Vendor, ShouldSkipVendor);
                if ShouldSkipVendor then
                    CurrReport.Skip();
            end;
        }
        dataitem(Integer3; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(CurrTotalBuffer2CurrCode; TempCurrencyTotalBuffer2."Currency Code")
            {
            }
            column(CurrTotalBuffer2TotalAmt; TempCurrencyTotalBuffer2."Total Amount")
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
        AboutTitle = 'About Vendor - Balance to Date';
        AboutText = 'Track your outstanding payables and manage your vendor relationships';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowAmountsInLCY; PrintAmountInLCY)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in LCY';
                        ToolTip = 'Specifies if amounts in the report are displayed in LCY. If you leave the check box blank, amounts are shown in foreign currencies.';
                    }
                    field(PrintOnePrPage; PrintOnePrPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Vendor';
                        ToolTip = 'Specifies that you want to print each vendor balance on a separate page, if you have chosen two or more vendors to be included in the report.';
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
                        ToolTip = 'Specifies if the report must include vendor ledger entries with a balance of 0. By default, the report only includes vendor ledger entries with a positive or negative balance.';
                    }
                    field(UseExternalDocNo; UseExternalDocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use External Document No.';
                        ToolTip = 'Specifies if you want to print the vendor''''s document numbers, such as the invoice number, for all transactions. Clear this check box to print only internal document numbers.';
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
        VendFilter := FormatDocument.GetRecordFiltersWithCaptions(Vendor);
        if UseExternalDocNo then
            DocNoCaption := VendLedgEntry3.FieldCaption("External Document No.")
        else
            DocNoCaption := VendLedgEntry3.FieldCaption("Document No.");
    end;

    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        TempCurrencyTotalBuffer: Record "Currency Total Buffer" temporary;
        TempCurrencyTotalBuffer2: Record "Currency Total Buffer" temporary;
        VendorLedgerEntriesIncluded: Dictionary of [Integer, Boolean];
        AutoFormat: Codeunit "Auto Format";
        PrintAmountInLCY: Boolean;
        PrintOnePrPage: Boolean;
        VendFilter: Text;
        MaxDate: Date;
        MinDate: Date;
        OriginalAmt: Decimal;
        Amt: Decimal;
        RemainingAmt: Decimal;
        Counter1: Integer;
        DtldVendtLedgEntryNum: Integer;
        OK: Boolean;
        CurrencyCode: Code[10];
        PrintUnappliedEntries: Boolean;
        ShowEntriesWithZeroBalance: Boolean;
        UseExternalDocNo: Boolean;
        VendLedgDocumentNo: Code[35];
        DtldVendLedgDocumentNo: Code[35];
        DocNoCaption: Text;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Balance on %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        VendorBalancetoDateCptnLbl: Label 'Vendor - Balance to Date';
        PageNoCaptionLbl: Label 'Page';
        AllamountsareinLCYCaptionLbl: Label 'All amounts are in LCY.';
        PostingDateCptionLbl: Label 'Posting Date';
        OriginalAmtCaptionLbl: Label 'Amount';
        TotalCaptionLbl: Label 'Total';

    procedure InitializeRequest(NewPrintAmountInLCY: Boolean; NewPrintOnePrPage: Boolean; NewPrintUnappliedEntries: Boolean)
    begin
        PrintAmountInLCY := NewPrintAmountInLCY;
        PrintOnePrPage := NewPrintOnePrPage;
        PrintUnappliedEntries := NewPrintUnappliedEntries;
    end;

    local procedure FilterDetailedVendLedgerEntry(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; DateFilter: Text)
    begin
        DetailedVendorLedgEntry.SetCurrentKey("Vendor No.", "Posting Date", "Entry Type");
        DetailedVendorLedgEntry.SetRange("Vendor No.", Vendor."No.");
        DetailedVendorLedgEntry.SetFilter("Posting Date", DateFilter);
        DetailedVendorLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
    end;

    local procedure FilterVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.SetCurrentKey("Vendor No.", Open);
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        if not ShowEntriesWithZeroBalance then
            VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.SetRange("Posting Date", 0D, MaxDate);
    end;

    local procedure AddVendorDimensionFilter(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        if Vendor.GetFilter("Global Dimension 1 Filter") <> '' then
            VendorLedgerEntry.SetRange("Global Dimension 1 Code", Vendor.GetFilter("Global Dimension 1 Filter"));
        if Vendor.GetFilter("Global Dimension 2 Filter") <> '' then
            VendorLedgerEntry.SetRange("Global Dimension 2 Code", Vendor.GetFilter("Global Dimension 2 Filter"));
        if Vendor.GetFilter("Currency Filter") <> '' then
            VendorLedgerEntry.SetRange("Currency Code", Vendor.GetFilter("Currency Filter"));
    end;

    local procedure CalcTotalVendorAmount()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        FilterDetailedVendLedgerEntry(DetailedVendorLedgEntry, '');
        if DetailedVendorLedgEntry.FindSet() then
            repeat
                VendorLedgerEntry.Get(DetailedVendorLedgEntry."Vendor Ledger Entry No.");
                if not TempVendorLedgerEntry.Get(VendorLedgerEntry."Entry No.") then
                    if CheckVendLedgerEntryIncludedWithCache(VendorLedgerEntry."Entry No.") then begin
                        TempVendorLedgerEntry := VendorLedgerEntry;
                        TempVendorLedgerEntry.Insert();
                    end;
            until DetailedVendorLedgEntry.Next() = 0;

        FilterVendorLedgerEntry(VendorLedgerEntry);
        if VendorLedgerEntry.FindSet() then
            repeat
                if not TempVendorLedgerEntry.Get(VendorLedgerEntry."Entry No.") then
                    if CheckVendLedgerEntryIncludedWithCache(VendorLedgerEntry."Entry No.") then begin
                        TempVendorLedgerEntry := VendorLedgerEntry;
                        TempVendorLedgerEntry.Insert();
                    end;
            until VendorLedgerEntry.Next() = 0;

        TempVendorLedgerEntry.SetCurrentKey("Entry No.");
        TempVendorLedgerEntry.SetRange("Date Filter", 0D, MaxDate);
        AddVendorDimensionFilter(TempVendorLedgerEntry);
        if TempVendorLedgerEntry.FindSet() then
            repeat
                CalcVendorRemainingAmount(TempVendorLedgerEntry);

                if (RemainingAmt <> 0) or ShowEntriesWithZeroBalance then
                    TempCurrencyTotalBuffer.UpdateTotal(
                      CurrencyCode,
                      RemainingAmt,
                      0,
                      Counter1);

                OnCalcTotalVendorAmountOnAfterUpdateCurrencyTotalBuffer(TempVendorLedgerEntry, TempCurrencyTotalBuffer, Counter1, RemainingAmt, ShowEntriesWithZeroBalance)
            until TempVendorLedgerEntry.Next() = 0;
    end;

    local procedure CalcVendorRemainingAmount(var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary)
    begin
        if PrintAmountInLCY then begin
            TempVendorLedgerEntry.CalcFields("Remaining Amt. (LCY)");
            RemainingAmt := TempVendorLedgerEntry."Remaining Amt. (LCY)";
            CurrencyCode := '';
        end else begin
            TempVendorLedgerEntry.CalcFields("Remaining Amount");
            RemainingAmt := TempVendorLedgerEntry."Remaining Amount";
            CurrencyCode := TempVendorLedgerEntry."Currency Code";
        end;

        OnAfterCalcVendorRemainingAmount(TempVendorLedgerEntry, PrintAmountInLCY, RemainingAmt, CurrencyCode);
    end;

    local procedure CheckVendLedgerEntryIncludedWithCache(EntryNo: Integer): Boolean
    var
        IsIncluded: Boolean;
    begin
        if VendorLedgerEntriesIncluded.ContainsKey(EntryNo) then begin
            VendorLedgerEntriesIncluded.Get(EntryNo, IsIncluded);
            exit(IsIncluded);
        end;

        IsIncluded := CheckVendEntryIncluded(EntryNo);

        VendorLedgerEntriesIncluded.Add(EntryNo, IsIncluded);
        exit(IsIncluded);
    end;

    local procedure CheckVendEntryIncluded(EntryNo: Integer): Boolean
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ClosingVendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if VendorLedgerEntry.Get(EntryNo) and (VendorLedgerEntry."Posting Date" <= MaxDate) then begin
            VendorLedgerEntry.SetRange("Date Filter", 0D, MaxDate);
            VendorLedgerEntry.CalcFields("Remaining Amount", "Original Amount", Amount);
            if VendorLedgerEntry."Remaining Amount" <> 0 then
                exit(true);
            // if "Show Entries with Zero Balance" is checked, show only closed entries that were closed within the report date filter
            if ShowEntriesWithZeroBalance then begin
                if ClosingVendorLedgerEntry.Get(VendorLedgerEntry."Closed by Entry No.") then
                    exit((ClosingVendorLedgerEntry."Posting Date" >= MinDate) and (ClosingVendorLedgerEntry."Posting Date" <= MaxDate));
                if (VendorLedgerEntry.Amount = 0) and
                   (VendorLedgerEntry."Original Amount" = 0) and
                   not VendorLedgerEntry.Open and
                   (VendorLedgerEntry."Posting Date" >= MinDate) and
                   (VendorLedgerEntry."Posting Date" <= MaxDate) then
                    exit(true);
            end;
            if PrintUnappliedEntries then
                exit(CheckUnappliedEntryExists(EntryNo));
        end;
        exit(false);
    end;

    local procedure CheckUnappliedEntryExists(EntryNo: Integer): Boolean
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
        DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", EntryNo);
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.SetFilter("Posting Date", '>%1', MaxDate);
        DetailedVendorLedgEntry.SetRange(Unapplied, true);
        exit(not DetailedVendorLedgEntry.IsEmpty);
    end;

    local procedure GetAppliedEntryExternalDocNo(AppliedEntryNo: Integer): Code[35]
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if VendorLedgerEntry.Get(AppliedEntryNo) then
            exit(VendorLedgerEntry."External Document No.");

        exit('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcVendorRemainingAmount(var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; PrintAmountInLCY: Boolean; var RemainingAmt: Decimal; var CurrencyCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVendLedgEntry3OnAfterGetRecord(VendorLedgerEntry: Record "Vendor Ledger Entry"; PrintAmountInLCY: Boolean; var OriginalAmt: Decimal; var RemainingAmt: Decimal; var CurrencyCode: Code[10])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnVendorOnAfterGetRecordOnAfterCalcShouldSkipVendor(var Vendor: Record Vendor; var ShouldSkipVendor: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTotalVendorAmountOnAfterUpdateCurrencyTotalBuffer(var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; var TempCurrencyTotalBuffer: Record "Currency Total Buffer" temporary; Counter1: Integer; RemainingAmt: Decimal; ShowEntriesWithZeroBalance: Boolean)
    begin
    end;
}


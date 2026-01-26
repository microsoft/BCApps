// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 11507 "Vendor Payments List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorPaymentsList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Payments List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
        {
            DataItemTableView = sorting("Vendor No.", "Applies-to ID", Open, Positive, "Due Date") where(Reversed = filter(false));
            RequestFilterFields = "Vendor No.", "Posting Date", "Vendor Posting Group", "Currency Code", Open, "Purchaser Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(Text003___SELECTSTR_Layout___1_Text006_; Text003 + SelectStr(Layout + 1, Text006))
            {
            }
            column(Text004___GETFILTERS; Text004 + GetFilters)
            {
            }
            column(LayoutInt; LayoutInt)
            {
            }
            column(SortInt; SortInt)
            {
            }
            column(LinesperGrp; LinesPerGrp)
            {
            }
            column(Vendor_Ledger_Entry__Amount__LCY__; "Amount (LCY)")
            {
            }
            column(Vendor_Ledger_Entry__Document_No__; "Document No.")
            {
            }
            column(COPYSTR_FORMAT__Document_Type___1_1_; CopyStr(Format("Document Type"), 1, 1))
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date_; Format("Posting Date"))
            {
            }
            column(AccNo; AccNo)
            {
            }
            column(AccName; AccName)
            {
            }
            column(TempVendorLedgerEntry__Document_Type_; CopyStr(Format(TempVendorLedgerEntry."Document Type"), 1, 1))
            {
            }
            column(TempVendorLedgerEntry__Document_No__; TempVendorLedgerEntry."Document No.")
            {
            }
            column(PaymentLCY; PaymentLCY)
            {
                AutoFormatType = 1;
            }
            column(PmtDiscLCY; PmtDiscLCY)
            {
                AutoFormatType = 1;
            }
            column(Vendor_Ledger_Entry__Document_No___Control11; "Document No.")
            {
            }
            column(COPYSTR_FORMAT__Document_Type___1_1__Control13; CopyStr(Format("Document Type"), 1, 1))
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date__Control17; Format("Posting Date"))
            {
            }
            column(AccNo_Control23; AccNo)
            {
            }
            column(Vendor_Ledger_Entry__Currency_Code_; "Currency Code")
            {
            }
            column(Vendor_Ledger_Entry_Amount; Amount)
            {
            }
            column(Vendor_Ledger_Entry__Amount__LCY___Control56; "Amount (LCY)")
            {
            }
            column(Status; Status)
            {
            }
            column(Exrate; Exrate)
            {
            }
            column(Vendor_Ledger_Entry_Description; Description)
            {
            }
            column(Vendor_Ledger_Entry__Original_Amount_; "Original Amount")
            {
            }
            column(Vendor_Ledger_Entry__Amount__LCY___Control41; "Amount (LCY)")
            {
            }
            column(AccNo_Control42; AccNo)
            {
            }
            column(Vendor_Ledger_Entry__Entry_No__; "Entry No.")
            {
            }
            column(Vendor_Ledger_Entry__Vendor_Posting_Group_; "Vendor Posting Group")
            {
            }
            column(Vendor_Ledger_Entry__Global_Dimension_1_Code_; "Global Dimension 1 Code")
            {
            }
            column(Vendor_Ledger_Entry__Global_Dimension_2_Code_; "Global Dimension 2 Code")
            {
            }
            column(Vendor_Ledger_Entry__Purchaser_Code_; "Purchaser Code")
            {
            }
            column(Vendor_Ledger_Entry__User_ID_; "User ID")
            {
            }
            column(Vendor_Ledger_Entry__Source_Code_; "Source Code")
            {
            }
            column(Vendor_Ledger_Entry__Transaction_No__; "Transaction No.")
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date__Control83; Format("Posting Date"))
            {
            }
            column(COPYSTR_FORMAT__Document_Type___1_1__Control84; CopyStr(Format("Document Type"), 1, 1))
            {
            }
            column(Vendor_Ledger_Entry__Document_No___Control85; "Document No.")
            {
            }
            column(Vendor_Ledger_Entry__Amount__LCY___Control32; "Amount (LCY)")
            {
            }
            column(Text005_________Vendor__No____________Vendor_Name; Text005 + ' ' + Vendor."No." + ', ' + Vendor.Name)
            {
            }
            column(PaymentLCY_Control1150004; PaymentLCY)
            {
                AutoFormatType = 1;
            }
            column(PmtDiscLCY_Control1150005; PmtDiscLCY)
            {
                AutoFormatType = 1;
            }
            column(Vendor_Ledger_Entry__Amount__LCY___Control9; "Amount (LCY)")
            {
            }
            column(FORMAT_NoOfPmts_; Format(NoOfPmts))
            {
            }
            column(PaymentLCY_Control1150006; PaymentLCY)
            {
                AutoFormatType = 1;
            }
            column(PmtDiscLCY_Control1150007; PmtDiscLCY)
            {
                AutoFormatType = 1;
            }
            column(Vendor_Ledger_Entry_Vendor_No_; "Vendor No.")
            {
            }
            column(Vendor_Payments_ListCaption; Vendor_Payments_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(AccNoCaption; AccNoCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date_Caption; Vendor_Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Document_No__Caption; Vendor_Ledger_Entry__Document_No__CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Amount__LCY__Caption; Vendor_Ledger_Entry__Amount__LCY__CaptionLbl)
            {
            }
            column(AccNameCaption; AccNameCaptionLbl)
            {
            }
            column(Applies_to_Doc__No_Caption; Applies_to_Doc__No_CaptionLbl)
            {
            }
            column(PaymentLCYCaption; PaymentLCYCaptionLbl)
            {
            }
            column(PmtDiscLCYCaption; PmtDiscLCYCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Document_No___Control11Caption; Vendor_Ledger_Entry__Document_No___Control11CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date__Control17Caption; Vendor_Ledger_Entry__Posting_Date__Control17CaptionLbl)
            {
            }
            column(AccNo_Control23Caption; AccNo_Control23CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry_AmountCaption; Vendor_Ledger_Entry_AmountCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Amount__LCY___Control56Caption; Vendor_Ledger_Entry__Amount__LCY___Control56CaptionLbl)
            {
            }
            column(StatusCaption; StatusCaptionLbl)
            {
            }
            column(ExrateCaption; ExrateCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry_DescriptionCaption; Vendor_Ledger_Entry_DescriptionCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Original_Amount_Caption; Vendor_Ledger_Entry__Original_Amount_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Amount__LCY___Control41Caption; Vendor_Ledger_Entry__Amount__LCY___Control41CaptionLbl)
            {
            }
            column(AccNo_Control42Caption; AccNo_Control42CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Source_Code_Caption; Vendor_Ledger_Entry__Source_Code_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__User_ID_Caption; Vendor_Ledger_Entry__User_ID_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Purchaser_Code_Caption; Vendor_Ledger_Entry__Purchaser_Code_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Global_Dimension_2_Code_Caption; FieldCaption("Global Dimension 2 Code"))
            {
            }
            column(Vendor_Ledger_Entry__Global_Dimension_1_Code_Caption; FieldCaption("Global Dimension 1 Code"))
            {
            }
            column(Vendor_Ledger_Entry__Transaction_No__Caption; Vendor_Ledger_Entry__Transaction_No__CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Vendor_Posting_Group_Caption; Vendor_Ledger_Entry__Vendor_Posting_Group_CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Entry_No__Caption; FieldCaption("Entry No."))
            {
            }
            column(Vendor_Ledger_Entry__Document_No___Control85Caption; Vendor_Ledger_Entry__Document_No___Control85CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Posting_Date__Control83Caption; Vendor_Ledger_Entry__Posting_Date__Control83CaptionLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(Total_Pmt_Disc_LCY; TotalPmtDiscLCY)
            {
            }
            column(Total_Payment_LCY; TotalPaymentLCY)
            {
            }
            column(Total_Amount_LCY; TotalAmountLCY)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(TempVendorLedgerEntry__Document_No___Control1150008; TempVendorLedgerEntry."Document No.")
                {
                }
                column(TempVendorLedgerEntry__Document_Type__Control1150009; TempVendorLedgerEntry."Document Type")
                {
                }
                column(Integer_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        TempVendorLedgerEntry.Next();
                        "Vendor Ledger Entry"."Amount (LCY)" := 0;
                        PaymentLCY := 0;
                        PmtDiscLCY := 0;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, TempVendorLedgerEntry.Count);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if PrevAccNo <> "Vendor Ledger Entry"."Vendor No." then begin
                    // Moved from OnPostSection
                    LinesPerGrp := 0;
                    PrevAccNo := "Vendor No.";
                end;
                if not ("Document Type" in ["Document Type"::Payment]) then
                    CurrReport.Skip();

                CalcFields("Remaining Amt. (LCY)", "Amount (LCY)", "Original Amount", "Original Amt. (LCY)");

                if Layout = Layout::"FCY Amounts" then begin
                    if "Currency Code" in ['', GlSetup."LCY Code"] then begin
                        Exrate := 0;
                        "Currency Code" := GlSetup."LCY Code";
                    end else
                        Exrate := CalcExrate("Original Amount", "Original Amt. (LCY)");

                    Status := CopyStr(Text000, 1, MaxStrLen(Status));
                    if Open then
                        if "Remaining Amt. (LCY)" = "Amount (LCY)" then
                            Status := CopyStr(Text001, 1, MaxStrLen(Status))
                        else
                            Status := CopyStr(Text002, 1, MaxStrLen(Status));
                end;

                if Layout = Layout::Standard then begin
                    PmtDiscLCY := "Amount (LCY)" - "Original Amt. (LCY)";
                    PaymentLCY := "Original Amt. (LCY)";
                    GetAppliedDocs();
                    if TempVendorLedgerEntry.Find('-') then begin
                        "Vendor Ledger Entry"."Applies-to Doc. Type" := TempVendorLedgerEntry."Applies-to Doc. Type";
                        "Vendor Ledger Entry"."Applies-to Doc. No." := TempVendorLedgerEntry."Applies-to Doc. No.";
                    end;
                end;

                AccNo := "Vendor No.";
                if Vendor.Get("Vendor No.") then
                    AccName := Vendor.Name;

                if Sorting = Sorting::Vendor then begin
                    LinesPerGrp := LinesPerGrp + 1;
                    if LinesPerGrp > 1 then begin
                        AccNo := '';
                        AccName := '';
                    end;
                end;

                NoOfPmts := NoOfPmts + 1;
                TotalPmtDiscLCY += "Amount (LCY)" - "Original Amt. (LCY)";
                TotalPaymentLCY += "Original Amt. (LCY)";
                TotalAmountLCY += "Amount (LCY)";
            end;

            trigger OnPreDataItem()
            begin
                LayoutInt := Layout;
                SortInt := Sorting;

                if Sorting = Sorting::Chronological then
                    "Vendor Ledger Entry".SetCurrentKey("Entry No.");

                GlSetup.Get();
                Clear(PmtDiscLCY);
                Clear(PaymentLCY);
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
                    field(Sorting; Sorting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sorting';
                        OptionCaption = 'Vendor with Group Total,Chronological by Entry No.';
                        ToolTip = 'Specifies the sorting order.';
                    }
                    field("Layout"; Layout)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Layout';
                        OptionCaption = 'Standard,FCY Amounts,Posting Info';
                        ToolTip = 'Specifies the layout of the report. If you select Standard, the report lists payments with amounts in your local currency. If you select FCY Amounts, amounts are in the appropriate foreign currencies. If you select Posting, the report includes information such as the posting group and the user who posted the document.';
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
        TotalPmtDiscLCY := 0;
        TotalPaymentLCY := 0;
        TotalAmountLCY := 0;
    end;

    var
        Text000: Label 'Closed';
        Text001: Label 'Open';
        Text002: Label 'Partial';
        Text003: Label 'Layout ';
        Text004: Label 'Filter: ';
        Text005: Label 'Total Vendor';
        GlSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        Sorting: Option Vendor,Chronological;
        "Layout": Option Standard,"FCY Amounts","Posting Info";
        LinesPerGrp: Integer;
        NoOfPmts: Integer;
        AccNo: Text[20];
        AccName: Text[100];
        Status: Text[8];
        Exrate: Decimal;
        Text006: Label 'Standard,FCY Amounts,Posting Info';
        PmtDiscLCY: Decimal;
        PaymentLCY: Decimal;
        LayoutInt: Integer;
        SortInt: Integer;
        PrevAccNo: Text[30];
        Vendor_Payments_ListCaptionLbl: Label 'Vendor Payments List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        AccNoCaptionLbl: Label 'Vendor No.';
        Vendor_Ledger_Entry__Posting_Date_CaptionLbl: Label 'Date';
        Vendor_Ledger_Entry__Document_No__CaptionLbl: Label 'Doc.';
        Vendor_Ledger_Entry__Amount__LCY__CaptionLbl: Label 'Amt. LCY';
        AccNameCaptionLbl: Label 'Name';
        Applies_to_Doc__No_CaptionLbl: Label 'Applies-to Doc. No.';
        PaymentLCYCaptionLbl: Label 'Payment (LCY)';
        PmtDiscLCYCaptionLbl: Label 'Pmt. Disc.& Curr.Diff.';
        Vendor_Ledger_Entry__Document_No___Control11CaptionLbl: Label 'Doc.';
        Vendor_Ledger_Entry__Posting_Date__Control17CaptionLbl: Label 'Date';
        AccNo_Control23CaptionLbl: Label 'Vendor No.';
        Vendor_Ledger_Entry_AmountCaptionLbl: Label 'Amount';
        Vendor_Ledger_Entry__Amount__LCY___Control56CaptionLbl: Label 'Applic. LCY';
        StatusCaptionLbl: Label 'Status';
        ExrateCaptionLbl: Label 'Exchange Rate';
        Vendor_Ledger_Entry_DescriptionCaptionLbl: Label 'Text';
        Vendor_Ledger_Entry__Original_Amount_CaptionLbl: Label 'Payment';
        Vendor_Ledger_Entry__Amount__LCY___Control41CaptionLbl: Label 'Amt. LCY';
        AccNo_Control42CaptionLbl: Label 'Vendor No.';
        Vendor_Ledger_Entry__Source_Code_CaptionLbl: Label 'Src';
        Vendor_Ledger_Entry__User_ID_CaptionLbl: Label 'User ID';
        Vendor_Ledger_Entry__Purchaser_Code_CaptionLbl: Label 'P.P.';
        Vendor_Ledger_Entry__Transaction_No__CaptionLbl: Label 'Tr No';
        Vendor_Ledger_Entry__Vendor_Posting_Group_CaptionLbl: Label 'Post Gr.';
        Vendor_Ledger_Entry__Document_No___Control85CaptionLbl: Label 'Doc.';
        Vendor_Ledger_Entry__Posting_Date__Control83CaptionLbl: Label 'Date';
        TotalCaptionLbl: Label 'Total';
        TotalPmtDiscLCY: Decimal;
        TotalPaymentLCY: Decimal;
        TotalAmountLCY: Decimal;

    [Scope('OnPrem')]
    procedure CalcExrate(_FcyAmt: Decimal; _LcyAmt: Decimal) _ExRate: Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        if (_FcyAmt <> 0) and (_FcyAmt <> _LcyAmt) then begin
            CurrExchRate.SetRange("Currency Code", "Vendor Ledger Entry"."Currency Code");
            CurrExchRate.SetFilter("Starting Date", '<=%1', "Vendor Ledger Entry"."Posting Date");
            if CurrExchRate.FindLast() then
                _ExRate := Round(_LcyAmt * CurrExchRate."Relational Exch. Rate Amount" / _FcyAmt, 0.001);
        end else
            _ExRate := 0;
    end;

    [Scope('OnPrem')]
    procedure GetAppliedDocs()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgerEntry: Record "Detailed Vendor Ledg. Entry";
        Counter: Integer;
        VendorLedgerEntryNo: Integer;
        SumAmount: Decimal;
    begin
        TempVendorLedgerEntry.DeleteAll();
        TempVendorLedgerEntry.Init();
        Counter := 0;

        DetailedVendorLedgerEntry.Reset();
        DetailedVendorLedgerEntry.SetCurrentKey("Applied Vend. Ledger Entry No.");
        DetailedVendorLedgerEntry.SetRange("Applied Vend. Ledger Entry No.", "Vendor Ledger Entry"."Entry No.");
        DetailedVendorLedgerEntry.SetFilter("Vendor Ledger Entry No.", '<>%1&<>%2', 0, "Vendor Ledger Entry"."Entry No.");
        DetailedVendorLedgerEntry.SetRange(Unapplied, false);
        SumAmount := 0;
        VendorLedgerEntryNo := 0;
        if DetailedVendorLedgerEntry.FindSet() then begin
            repeat
                if (VendorLedgerEntryNo <> 0) and (VendorLedgerEntryNo <> DetailedVendorLedgerEntry."Vendor Ledger Entry No.") then begin
                    VendorLedgerEntry.Get(VendorLedgerEntryNo);
                    if SumAmount <> 0 then begin
                        Counter := Counter + 1;
                        TempVendorLedgerEntry := VendorLedgerEntry;
                        TempVendorLedgerEntry."Entry No." := Counter;
                        TempVendorLedgerEntry.Insert();
                        SumAmount := 0;
                    end;
                end;
                SumAmount := SumAmount + DetailedVendorLedgerEntry."Amount (LCY)";
                VendorLedgerEntryNo := DetailedVendorLedgerEntry."Vendor Ledger Entry No.";
            until DetailedVendorLedgerEntry.Next() = 0;
            VendorLedgerEntry.Get(VendorLedgerEntryNo);
            if SumAmount <> 0 then begin
                Counter := Counter + 1;
                TempVendorLedgerEntry := VendorLedgerEntry;
                TempVendorLedgerEntry."Entry No." := Counter;
                TempVendorLedgerEntry.Insert();
            end;
        end;

        DetailedVendorLedgerEntry.Reset();
        DetailedVendorLedgerEntry.SetCurrentKey("Vendor Ledger Entry No.");
        DetailedVendorLedgerEntry.SetRange("Vendor Ledger Entry No.", "Vendor Ledger Entry"."Entry No.");
        DetailedVendorLedgerEntry.SetFilter("Applied Vend. Ledger Entry No.", '<>%1&<>%2', 0, "Vendor Ledger Entry"."Entry No.");
        DetailedVendorLedgerEntry.SetRange(Unapplied, false);
        SumAmount := 0;
        VendorLedgerEntryNo := 0;
        if DetailedVendorLedgerEntry.FindSet() then begin
            repeat
                VendorLedgerEntry.Get(DetailedVendorLedgerEntry."Applied Vend. Ledger Entry No.");
                if (VendorLedgerEntryNo <> 0) and (VendorLedgerEntryNo <> DetailedVendorLedgerEntry."Vendor Ledger Entry No.") then
                    if SumAmount <> 0 then begin
                        Counter := Counter + 1;
                        TempVendorLedgerEntry := VendorLedgerEntry;
                        TempVendorLedgerEntry."Entry No." := Counter;
                        TempVendorLedgerEntry.Insert();
                        SumAmount := 0;
                    end;
                SumAmount := SumAmount - DetailedVendorLedgerEntry."Amount (LCY)";
                VendorLedgerEntryNo := DetailedVendorLedgerEntry."Vendor Ledger Entry No.";
            until DetailedVendorLedgerEntry.Next() = 0;
            VendorLedgerEntry.Get(DetailedVendorLedgerEntry."Applied Vend. Ledger Entry No.");
            if SumAmount <> 0 then begin
                Counter := Counter + 1;
                TempVendorLedgerEntry := VendorLedgerEntry;
                TempVendorLedgerEntry."Entry No." := Counter;
                TempVendorLedgerEntry.Insert();
            end;
        end;
    end;
}


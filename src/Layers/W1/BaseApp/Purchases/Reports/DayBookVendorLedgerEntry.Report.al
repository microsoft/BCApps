// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 2502 "Day Book Vendor Ledger Entry"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/DayBookVendorLedgerEntry.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Day Book Vendor Ledger Entry';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(ReqVendLedgEntry; "Vendor Ledger Entry")
        {
            DataItemTableView = sorting("Document Type", "Vendor No.", "Posting Date", "Currency Code");
            RequestFilterFields = "Document Type", "Vendor No.", "Posting Date", "Currency Code";

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem(Date; Date)
        {
            DataItemTableView = sorting("Period Type", "Period Start") where("Period Type" = const(Date));
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(All_amounts_are_in___GLSetup__LCY_Code_; StrSubstNo(AllAmountsAreInLbl, GLSetup."LCY Code"))
            {
            }
            column(Vendor_Ledger_Entry__TABLENAME__________VendLedgFilter; "Vendor Ledger Entry".TableCaption + ': ' + VendLedgFilter)
            {
            }
            column(VendLedgFilter; VendLedgFilter)
            {
            }
            column(PrintCLDetails; PrintCLDetails)
            {
            }
            column(Total_for______Vendor_Ledger_Entry__TABLENAME__________VendLedgFilter; StrSubstNo(TotalForVendLedgerEntryLbl, "Vendor Ledger Entry".TableCaption(), VendLedgFilter))
            {
            }
            column(Vendor_Ledger_Entry___Amount__LCY__; "Vendor Ledger Entry"."Amount (LCY)")
            {
                AutoFormatType = 1;
            }
            column(PmtDiscRcd; PmtDiscRcd)
            {
                AutoFormatType = 1;
            }
            column(ActualAmount; ActualAmount)
            {
                AutoFormatType = 1;
            }
            column(VATBase; VATBase)
            {
                AutoFormatType = 1;
            }
            column(VATAmount; VATAmount)
            {
                AutoFormatType = 1;
            }
            column(PmtDiscRcd4; PmtDiscRcd4)
            {
            }
            column(AmountLCY4; AmountLCY4)
            {
            }
            column(PmtDiscRcd3; PmtDiscRcd3)
            {
            }
            column(AmountLCY3; AmountLCY3)
            {
            }
            column(Date_Period_Type; "Period Type")
            {
            }
            column(Date_Period_Start; "Period Start")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Day_Book_Vendor_Ledger_EntryCaption; Day_Book_Vendor_Ledger_EntryCaptionLbl)
            {
            }
            column(VATAmount_Control23Caption; VATAmount_Control23CaptionLbl)
            {
            }
            column(PmtDiscRcd_Control32Caption; PmtDiscRcd_Control32CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Amount__LCY__Caption; Vendor_Ledger_Entry__Amount__LCY__CaptionLbl)
            {
            }
            column(ActualAmount_Control35Caption; ActualAmount_Control35CaptionLbl)
            {
            }
            column(VATBase_Control26Caption; VATBase_Control26CaptionLbl)
            {
            }
            column(VATAmount_Control23Caption_Control24; VATAmount_Control23Caption_Control24Lbl)
            {
            }
            column(PmtDiscRcd_Control32Caption_Control33; PmtDiscRcd_Control32Caption_Control33Lbl)
            {
            }
            column(VATBase_Control26Caption_Control27; VATBase_Control26Caption_Control27Lbl)
            {
            }
            column(Vendor_Ledger_Entry__Amount__LCY__Caption_Control30; Vendor_Ledger_Entry__Amount__LCY__Caption_Control30Lbl)
            {
            }
            column(Vendor_NameCaption; Vendor_NameCaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__Vendor_No__Caption; Vendor_Ledger_Entry__Vendor_No__CaptionLbl)
            {
            }
            column(Vendor_Ledger_Entry__External_Document_No__Caption; "Vendor Ledger Entry".FieldCaption("External Document No."))
            {
            }
            column(Vendor_Ledger_Entry__Document_No__Caption; "Vendor Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(ActualAmount_Control35Caption_Control54; ActualAmount_Control35Caption_Control54Lbl)
            {
            }
            dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
            {
                DataItemTableView = sorting("Document Type", "Vendor No.", "Posting Date", "Currency Code");
                column(Vendor_Ledger_Entry__FIELDNAME__Posting_Date__________FORMAT_Date__Period_Start__0_4_; FieldCaption("Posting Date") + ' ' + Format(Date."Period Start", 0, 4))
                {
                }
                column(FIELDNAME__Document_Type___________FORMAT___Document_Type__; FieldCaption("Document Type") + ' ' + Format("Document Type"))
                {
                }
                column(Vendor_Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Vendor_Ledger_Entry__External_Document_No__; "External Document No.")
                {
                }
                column(VATAmount_Control23; VATAmount)
                {
                    AutoFormatType = 1;
                }
                column(Vendor_Ledger_Entry__Amount__LCY__; "Amount (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(PmtDiscRcd_Control32; PmtDiscRcd)
                {
                    AutoFormatType = 1;
                }
                column(Vendor_Name; Vendor.Name)
                {
                }
                column(Vendor_Ledger_Entry__Vendor_No__; "Vendor No.")
                {
                }
                column(VATBase_Control26; VATBase)
                {
                    AutoFormatType = 1;
                }
                column(ActualAmount_Control35; ActualAmount)
                {
                    AutoFormatType = 1;
                }
                column(VendorLedgerEntry___EntryNo__; "Entry No.")
                {
                }
                column(Total_for___FIELDNAME__Document_Type_________FORMAT__Document_Type__; StrSubstNo(TotalForVendLedgerEntryLbl, FieldCaption("Document Type"), Format("Document Type")))
                {
                }
                column(Vendor_Ledger_Entry__Amount__LCY___Control46; "Amount (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(PmtDiscRcd_Control47; PmtDiscRcd)
                {
                    AutoFormatType = 1;
                }
                column(ActualAmount_Control48; ActualAmount)
                {
                    AutoFormatType = 1;
                }
                column(VATBase_Control49; VATBase)
                {
                    AutoFormatType = 1;
                }
                column(VATAmount_Control50; VATAmount)
                {
                    AutoFormatType = 1;
                }
                column(AmountLCY2; AmountLCY2)
                {
                }
                column(PmtDiscRcd2; PmtDiscRcd2)
                {
                }
                column(Total_for_____FORMAT_Date__Period_Start__0_4_; StrSubstNo(TotalForDatePeriodStartLbl, Format(Date."Period Start", 0, 4)))
                {
                }
                column(Vendor_Ledger_Entry__Amount__LCY___Control51; "Amount (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(PmtDiscRcd_Control58; PmtDiscRcd)
                {
                    AutoFormatType = 1;
                }
                column(ActualAmount_Control59; ActualAmount)
                {
                    AutoFormatType = 1;
                }
                column(VATBase_Control61; VATBase)
                {
                    AutoFormatType = 1;
                }
                column(VATAmount_Control62; VATAmount)
                {
                    AutoFormatType = 1;
                }
                column(Vendor_Ledger_Entry_Document_Type; "Document Type")
                {
                }
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemTableView = sorting("Transaction No.");
                    column(G_L_Entry__G_L_Account_No__; "G/L Account No.")
                    {
                    }
                    column(G_L_Entry_Amount; Amount)
                    {
                        AutoFormatType = 1;
                    }
                    column(GLAcc_Name; GLAcc.Name)
                    {
                    }
                    column(G_L_Entry___Entry_No__; "Entry No.")
                    {
                    }
                    column(GetPmtDiscRcd; PmtDiscRcd1)
                    {
                    }
                    column(GetVatBase; VatBase1)
                    {
                    }
                    column(GetVatAmount; VatAmount1)
                    {
                    }
                    column(GetAmountLCY; AmountLCY1)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if "G/L Account No." <> GLAcc."No." then
                            if not GLAcc.Get("G/L Account No.") then
                                GLAcc.Init();

                        AmountLCY1 := "Vendor Ledger Entry"."Amount (LCY)";
                        PmtDiscRcd1 := PmtDiscRcd;
                        if SecondStep then begin
                            VatBase1 := 0;
                            VatAmount1 := 0;
                            SecondStep := false;
                        end else begin
                            VatBase1 := VATBase;
                            VatAmount1 := VATAmount;
                        end;
                    end;

                    trigger OnPreDataItem()
                    var
                        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                        TransactionNoFilter: Text[250];
                    begin
                        if not PrintGLDetails then
                            CurrReport.Break();

                        DtldVendLedgEntry.Reset();
                        DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", "Vendor Ledger Entry"."Entry No.");
                        DtldVendLedgEntry.SetFilter("Entry Type", '<>%1', DtldVendLedgEntry."Entry Type"::Application);
                        if DtldVendLedgEntry.FindSet() then begin
                            TransactionNoFilter := Format(DtldVendLedgEntry."Transaction No.");
                            while DtldVendLedgEntry.Next() <> 0 do
                                TransactionNoFilter := TransactionNoFilter + '|' + Format(DtldVendLedgEntry."Transaction No.");
                        end;
                        SetFilter("Transaction No.", TransactionNoFilter);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    TempVATEntry: Record "VAT Entry" temporary;
                begin
                    SecondStep := true;
                    if "Document Type" <> PreviousVendorLedgerEntry."Document Type" then begin
                        AmountLCY2 := 0;
                        PmtDiscRcd2 := 0;
                    end;
                    AmountLCY2 := AmountLCY2 + "Amount (LCY)";
                    AmountLCY3 := AmountLCY3 + "Amount (LCY)";
                    AmountLCY4 := AmountLCY4 + "Amount (LCY)";
                    PmtDiscRcd2 := PmtDiscRcd2 + PmtDiscRcd;
                    PmtDiscRcd3 := PmtDiscRcd3 + PmtDiscRcd;
                    PmtDiscRcd4 := PmtDiscRcd4 + PmtDiscRcd;
                    PreviousVendorLedgerEntry := "Vendor Ledger Entry";

                    if "Vendor No." <> Vendor."No." then
                        if not Vendor.Get("Vendor No.") then
                            Vendor.Init();

                    VATAmount := 0;
                    VATBase := 0;
                    VATEntry.SetCurrentKey("Transaction No.");
                    VATEntry.SetRange("Transaction No.", "Transaction No.");
                    if VATEntry.FindSet() then
                        if VATEntry."Tax Liable" then begin
                            repeat
                                TempVATEntry.SetRange("Tax Area Code", VATEntry."Tax Area Code");
                                TempVATEntry.SetRange("Tax Group Code", VATEntry."Tax Group Code");
                                if TempVATEntry.FindFirst() then begin
                                    TempVATEntry.Amount += VATEntry.Amount;
                                    TempVATEntry.Modify();
                                end else begin
                                    TempVATEntry := VATEntry;
                                    TempVATEntry.Insert();
                                end;
                            until VATEntry.Next() = 0;
                            TempVATEntry.Reset();
                            TempVATEntry.CalcSums(Amount, Base);
                            VATAmount := -TempVATEntry.Amount;
                            VATBase := -TempVATEntry.Base;
                            TempVATEntry.DeleteAll();
                        end else begin
                            VATEntry.CalcSums(Amount, Base);
                            VATAmount := -VATEntry.Amount;
                            VATBase := -VATEntry.Base;
                        end;

                    PmtDiscRcd := 0;
                    VendLedgEntry.SetCurrentKey("Closed by Entry No.");
                    VendLedgEntry.SetRange("Closed by Entry No.", "Entry No.");
                    if VendLedgEntry.Find('-') then
                        repeat
                            PmtDiscRcd := PmtDiscRcd - VendLedgEntry."Pmt. Disc. Rcd.(LCY)"
                        until VendLedgEntry.Next() = 0;

                    ActualAmount := "Amount (LCY)" - PmtDiscRcd;
                end;

                trigger OnPreDataItem()
                begin
                    Clear(VATAmount);
                    Clear(PmtDiscRcd);
                    Clear(VATBase);
                    Clear(ActualAmount);
                    CopyFilters(ReqVendLedgEntry);
                    SetRange("Posting Date", Date."Period Start");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                AmountLCY2 := 0;
                AmountLCY3 := 0;
                PmtDiscRcd2 := 0;
                PmtDiscRcd3 := 0;
            end;

            trigger OnPreDataItem()
            var
                PostingDateStart: Date;
                PostingDateEnd: Date;
            begin
                Clear(VATAmount);
                Clear(PmtDiscRcd);
                Clear(VATBase);
                Clear(ActualAmount);
                ReqVendLedgEntry.CopyFilter("Posting Date", "Period Start");

                if ReqVendLedgEntry.GetFilter("Posting Date") = '' then
                    Error(MissingDateRangeFilterErr);

                PostingDateStart := ReqVendLedgEntry.GetRangeMin("Posting Date");
                PostingDateEnd := CalcDate('<+1Y>', PostingDateStart);

                if ReqVendLedgEntry.GetRangeMax("Posting Date") > PostingDateEnd then
                    Error(MaxPostingDateErr);
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
                    field(PrintVendLedgerDetails; PrintCLDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Vend. Ledger Details';
                        ToolTip = 'Specifies if Cust. Ledger Details is printed';

                        trigger OnValidate()
                        begin
                            PrintCLDetailsOnAfterValidate();
                        end;
                    }
                    field(PrintGLEntryDetails; PrintGLDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print G/L Entry Details';
                        ToolTip = 'Specifies if G/L Entry Details are printed';

                        trigger OnValidate()
                        begin
                            PrintGLDetailsOnAfterValidate();
                        end;
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
        VendLedgFilter := ReqVendLedgEntry.GetFilters();
        GLSetup.Get();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GLAcc: Record "G/L Account";
        Vendor: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        PreviousVendorLedgerEntry: Record "Vendor Ledger Entry";
        VendLedgFilter: Text;
        PmtDiscRcd: Decimal;
        VATAmount: Decimal;
        ActualAmount: Decimal;
        VATBase: Decimal;
        AmountLCY1: Decimal;
        PmtDiscRcd1: Decimal;
        VatAmount1: Decimal;
        VatBase1: Decimal;
        PrintGLDetails: Boolean;
        PrintCLDetails: Boolean;
        SecondStep: Boolean;
        AmountLCY2: Decimal;
        PmtDiscRcd2: Decimal;
        AmountLCY3: Decimal;
        AmountLCY4: Decimal;
        PmtDiscRcd3: Decimal;
        PmtDiscRcd4: Decimal;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Day_Book_Vendor_Ledger_EntryCaptionLbl: Label 'Day Book Vendor Ledger Entry';
        VATAmount_Control23CaptionLbl: Label 'VAT Amount';
        PmtDiscRcd_Control32CaptionLbl: Label 'Payment Discount Rcd.';
        Vendor_Ledger_Entry__Amount__LCY__CaptionLbl: Label 'Ledger Entry Amount';
        ActualAmount_Control35CaptionLbl: Label 'Actual Amount';
        VATBase_Control26CaptionLbl: Label 'VAT Base';
        VATAmount_Control23Caption_Control24Lbl: Label 'VAT Amount';
        PmtDiscRcd_Control32Caption_Control33Lbl: Label 'Payment Discount Rcd.';
        VATBase_Control26Caption_Control27Lbl: Label 'VAT Base';
        Vendor_Ledger_Entry__Amount__LCY__Caption_Control30Lbl: Label 'Ledger Entry Amount';
        Vendor_NameCaptionLbl: Label 'Name';
        Vendor_Ledger_Entry__Vendor_No__CaptionLbl: Label 'Account No.';
        ActualAmount_Control35Caption_Control54Lbl: Label 'Actual Amount';
        MissingDateRangeFilterErr: Label 'Posting Date filter must be set.';
        MaxPostingDateErr: Label 'Posting Date period must not be longer than 1 year.';
#pragma warning disable AA0470
        TotalForVendLedgerEntryLbl: Label 'Total for  %1 : %2.', Comment = 'Total for Vend. Ledger Entry 3403  ';
        TotalForDatePeriodStartLbl: Label 'Total for %1.', Comment = 'Total for posting date 12122012';
        AllAmountsAreInLbl: Label 'All amounts are in %1.', Comment = 'All amounts are in GBP';
#pragma warning restore AA0470

    local procedure PrintGLDetailsOnAfterValidate()
    begin
        if PrintGLDetails then
            PrintCLDetails := true;
    end;

    local procedure PrintCLDetailsOnAfterValidate()
    begin
        if not PrintCLDetails then
            PrintGLDetails := false;
    end;
}


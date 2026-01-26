// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Utilities;

report 12110 "Vendor Sheet - Print"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorSheetPrint.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Sheet - Print';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.") order(ascending);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Date Filter", "Currency Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompAddr5; CompAddr[5])
            {
            }
            column(CompAddr4; CompAddr[4])
            {
            }
            column(CompAddr3; CompAddr[3])
            {
            }
            column(PeriodVendDateFilter; Text1035 + VendDateFilter)
            {
            }
            column(CompAddr2; CompAddr[2])
            {
            }
            column(CompAddr1; CompAddr[1])
            {
            }
            column(Filters2; Filters[2])
            {
            }
            column(Filters1; Filters[1])
            {
            }
            column(VendFilterNo; VendFilterNo)
            {
            }
            column(AmtsAreInGLSetupLCYCodeCurr; Text1038 + GLSetup."LCY Code" + Text1039)
            {
            }
            column(VendVendNoVendName; Text1040 + Vendor."No." + ' - ' + Vendor.Name)
            {
            }
            column(No_Vendor; "No.")
            {
            }
            column(CurrencyFilter_Vendor; "Currency Filter")
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(VendorSheetCaption; VendorSheetCaptionLbl)
            {
            }
            column(DepartmentCodeCaption; DepartmentCodeCaptionLbl)
            {
            }
            column(ProjectNoCaption; ProjectNoCaptionLbl)
            {
            }
            column(VendFilterNoCaption; VendNoCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(BalanceCaption; BalanceCaptionLbl)
            {
            }
            column(DocDateCaption; DocumentDateCaptionLbl)
            {
            }
            column(VendLedgEntryExternalDocNoCaption; "Vendor Ledger Entry".FieldCaption("External Document No."))
            {
            }
            column(VendLedgEntryDescCaption; "Vendor Ledger Entry".FieldCaption(Description))
            {
            }
            column(CurrencyCodeCaption; CurrencyCodeCaptionLbl)
            {
            }
            column(OrigAmountCaption; OrigAmountCaptionLbl)
            {
            }
            column(VendLedgEntryDocNoCaption; "Vendor Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(VendLedgEntryPostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(VendLedgEntryTransactionNoCaption; "Vendor Ledger Entry".FieldCaption("Transaction No."))
            {
            }
            column(VendLedgEntryEntryNoCaption; "Vendor Ledger Entry".FieldCaption("Entry No."))
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) order(ascending) where(Number = const(1));
                PrintOnlyIfDetail = true;
                column(StartOnHand; StartOnHand)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 5;
                }
                column(ProgressiveTotAtMinDateFormat; Text1041 + Format(MinimumDate))
                {
                }
                column(PrintedEntriesTotProgressiveTotCaption; PrintedEntriesTotProgressiveTotCaptionLbl)
                {
                }
                column(PrintedEntriesTotCaption; PrintedEntriesTotCaptionLbl)
                {
                }
                dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
                {
                    DataItemLink = "Vendor No." = field("No."), "Posting Date" = field("Date Filter"), "Currency Code" = field("Currency Filter");
                    DataItemLinkReference = Vendor;
                    DataItemTableView = sorting("Posting Date", "Transaction No.", "Entry No.") order(ascending);
                    column(StartOnHandAmtLCY; StartOnHand + AmountLCY)
                    {
                        AutoFormatType = 1;
                        DecimalPlaces = 0 : 5;
                    }
                    column(Amnt; Amnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(DecreasesAmnt; DecreasesAmnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(IcreasesAmnt; IcreasesAmnt)
                    {
                        AutoFormatType = 1;
                    }
                    column(CurrencyCode; CurrencyCode)
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(OrigAmount; OrigAmount)
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Description_VendLedgEntry; Description)
                    {
                    }
                    column(ExternalDocNo_VendLedgEntry; "External Document No.")
                    {
                    }
                    column(DocDateFormat_VendLedgEntry; Format("Document Date"))
                    {
                    }
                    column(DocNo_VendLedgEntry; "Document No.")
                    {
                    }
                    column(PostingDateFormat_VendLedgEntry; Format("Posting Date"))
                    {
                    }
                    column(TransactionNo_VendLedgEntry; "Transaction No.")
                    {
                    }
                    column(EntryNo_VendLedgEntry; "Entry No.")
                    {
                    }
                    column(DetVendLedgEntryCount; DetVendLedgEntry.Count)
                    {
                    }
                    column(IcreasesAmntForRTC; IcreasesAmntForRTC)
                    {
                    }
                    column(DecreasesAmntForRTC; DecreasesAmntForRTC)
                    {
                    }
                    column(AmntForRTC; AmntForRTC)
                    {
                    }
                    column(AmountLCY; AmountLCY)
                    {
                        AutoFormatType = 1;
                    }
                    column(TotalIcreasesAmntForRTC; TotalIcreasesAmntForRTC)
                    {
                    }
                    column(TotalDecreasesAmntForRTC; TotalDecreasesAmntForRTC)
                    {
                    }
                    column(TotalAmountLCYForRTC; TotalAmountLCYForRTC)
                    {
                    }
                    column(VendNo_VendLedgEntry; "Vendor No.")
                    {
                    }
                    column(CurrCode_VendLedgEntry; "Currency Code")
                    {
                    }
                    dataitem("Detailed Vendor Ledg. Entry"; "Detailed Vendor Ledg. Entry")
                    {
                        column(VendLedgEntryDocDateFormat; Format("Vendor Ledger Entry"."Document Date"))
                        {
                        }
                        column(Amount; Amnt)
                        {
                        }
                        column(VendLedgEntryExternalDocNo; "Vendor Ledger Entry"."External Document No.")
                        {
                        }
                        column(PostingDateFormat_DtldVendLedgEntry; Format("Posting Date"))
                        {
                        }
                        column(EntryType_DtldVendLedgEntry; "Entry Type")
                        {
                        }
                        column(TransactionNo_DtldVendLedgEntry; "Transaction No.")
                        {
                        }
                        column(DocNo_DtldVendLedgEntry; "Document No.")
                        {
                        }
                        column(DebitAmtLCY_DtldVendorLedgEntry; "Debit Amount (LCY)")
                        {
                        }
                        column(CrAmtLCY_DtldVendLedgEntry; "Credit Amount (LCY)")
                        {
                        }
                        column(VendLedgEntryNo_DtldVendLedgEntry; "Vendor Ledger Entry No.")
                        {
                        }
                        column(EntryNo_DtldVendLedgEntry; "Entry No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Amnt := Amnt + "Amount (LCY)";
                            IcreasesAmnt := IcreasesAmnt + "Debit Amount (LCY)";
                            DecreasesAmnt := DecreasesAmnt + "Credit Amount (LCY)";
                            AmountLCY := AmountLCY + "Amount (LCY)";

                            TotalAmountLCYForRTC := TotalAmountLCYForRTC + "Amount (LCY)";
                            TotalIcreasesAmntForRTC := TotalIcreasesAmntForRTC + "Debit Amount (LCY)";
                            TotalDecreasesAmntForRTC := TotalDecreasesAmntForRTC + "Credit Amount (LCY)";
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("Document Type", "Vendor Ledger Entry"."Document Type");
                            SetRange("Document No.", "Vendor Ledger Entry"."Document No.");
                            SetRange("Entry Type", "Entry Type"::"Correction of Remaining Amount");
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        DetVendLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
                        DetVendLedgEntry.SetRange("Vendor Ledger Entry No.", "Entry No.");

                        DetVendLedgEntry.SetFilter("Entry Type",
                          StrSubstNo('<>%1 & <>%2 & <>%3',
                            DetVendLedgEntry."Entry Type"::Application,
                            DetVendLedgEntry."Entry Type"::"Appln. Rounding",
                            DetVendLedgEntry."Entry Type"::"Correction of Remaining Amount"));
                        DetVendLedgEntry.SetFilter("Posting Date", VendDateFilter);

                        DetVendLedgEntry.CalcSums("Amount (LCY)");
                        AmountLCY := DetVendLedgEntry."Amount (LCY)";

                        Amnt := Amnt + AmountLCY;

                        IcreasesAmnt := 0;
                        DecreasesAmnt := 0;
                        if AmountLCY > 0 then
                            IcreasesAmnt := AmountLCY
                        else
                            DecreasesAmnt := Abs(AmountLCY);

                        CalcFields(Amount);

                        if "Currency Code" <> '' then begin
                            CurrencyCode := "Currency Code";
                            OrigAmount := Format(Amount);
                        end else begin
                            CurrencyCode := '';
                            OrigAmount := '';
                        end;

                        AmntForRTC := Amnt;
                        IcreasesAmntForRTC := IcreasesAmnt;
                        DecreasesAmntForRTC := DecreasesAmnt;

                        TotalAmountLCYForRTC := TotalAmountLCYForRTC + AmountLCY;
                        TotalIcreasesAmntForRTC := TotalIcreasesAmntForRTC + IcreasesAmnt;
                        TotalDecreasesAmntForRTC := TotalDecreasesAmntForRTC + DecreasesAmnt;
                    end;

                    trigger OnPreDataItem()
                    begin
                        TotalAmountLCYForRTC := 0;
                        TotalIcreasesAmntForRTC := 0;
                        TotalDecreasesAmntForRTC := 0;
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                StartOnHand := 0;
                if VendDateFilter <> '' then
                    if GetRangeMin("Date Filter") > 00000101D then begin
                        SetRange("Date Filter", 0D, GetRangeMin("Date Filter") - 1);
                        CalcFields("Net Change (LCY)");
                        StartOnHand := -"Net Change (LCY)";
                        SetFilter("Date Filter", VendDateFilter);
                    end;
                Amnt := StartOnHand;

                if Vendor.GetFilter("No.") <> '' then
                    VendFilterNo := Vendor.GetFilter("No.")
                else
                    VendFilterNo := Text1036;
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                CompAddr[1] := CompanyInfo.Name;
                CompAddr[2] := CompanyInfo.Address;
                CompAddr[3] := CompanyInfo."Post Code";
                CompAddr[4] := CompanyInfo.City;
                CompAddr[5] := CompanyInfo."Fiscal Code";
                CompressArray(CompAddr);
            end;
        }
    }

    requestpage
    {

        layout
        {
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
        ITReportManagement: Codeunit "IT - Report Management";
    begin
        GLSetup.Get();
        VendDateFilter := Vendor.GetFilter("Date Filter");

        if VendDateFilter <> '' then begin
            MinimumDate := Vendor.GetRangeMin("Date Filter") - 1;
            ITReportManagement.CheckPurchDocNoGaps(Vendor.GetRangeMax("Date Filter"), false);
        end else
            ITReportManagement.CheckPurchDocNoGaps(0D, false);
    end;

    var
        Text1035: Label 'Period: ';
        Text1036: Label 'ALL';
        Text1038: Label 'Amounts are in ';
        Text1039: Label ' currency.';
        Text1040: Label 'Vendor: ';
        Text1041: Label 'Progressive Total at ';
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        DetVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        CompAddr: array[5] of Text[100];
        VendFilterNo: Text[30];
        VendDateFilter: Text;
        OrigAmount: Text[30];
        Amnt: Decimal;
        StartOnHand: Decimal;
        IcreasesAmnt: Decimal;
        DecreasesAmnt: Decimal;
        AmountLCY: Decimal;
        CurrencyCode: Code[10];
        Filters: array[2] of Text[20];
        MinimumDate: Date;
        IcreasesAmntForRTC: Decimal;
        DecreasesAmntForRTC: Decimal;
        AmntForRTC: Decimal;
        TotalIcreasesAmntForRTC: Decimal;
        TotalDecreasesAmntForRTC: Decimal;
        TotalAmountLCYForRTC: Decimal;
        PageNoCaptionLbl: Label 'Page';
        VendorSheetCaptionLbl: Label 'Vendor Sheet';
        DepartmentCodeCaptionLbl: Label 'Department Code';
        ProjectNoCaptionLbl: Label 'Project No.';
        VendNoCaptionLbl: Label 'Vendor No.';
        DebitCaptionLbl: Label 'Debit Amount';
        CreditCaptionLbl: Label 'Credit Amount';
        BalanceCaptionLbl: Label 'Balance';
        DocumentDateCaptionLbl: Label 'Document Date';
        CurrencyCodeCaptionLbl: Label 'Currency Code';
        OrigAmountCaptionLbl: Label 'Original Amount';
        PostingDateCaptionLbl: Label 'Posting Date';
        PrintedEntriesTotCaptionLbl: Label 'Printed Entries Total';
        PrintedEntriesTotProgressiveTotCaptionLbl: Label 'Printed Entries Total + Progressive Total';
}


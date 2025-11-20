// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Utilities;

report 311 "Vendor - Top 10 List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/VendorTop10List.rdlc';
    ApplicationArea = Suite;
    Caption = 'Vendor - Top 10 List';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Vendor Posting Group", "Currency Code", "Date Filter";

            trigger OnAfterGetRecord()
            begin
                WindowDialog.Update(1, "No.");
                CalcFields("Purchases (LCY)", "Balance (LCY)");
                if ("Purchases (LCY)" = 0) and ("Balance (LCY)" = 0) then
                    CurrReport.Skip();
                TempVendorAmount.Init();
                TempVendorAmount."Vendor No." := "No.";
                if ShowType = ShowType::"Purchases (LCY)" then begin
                    TempVendorAmount."Amount (LCY)" := -"Purchases (LCY)";
                    TempVendorAmount."Amount 2 (LCY)" := -"Balance (LCY)";
                end else begin
                    TempVendorAmount."Amount (LCY)" := -"Balance (LCY)";
                    TempVendorAmount."Amount 2 (LCY)" := -"Purchases (LCY)";
                end;
                TempVendorAmount.Insert();
                if (NoOfRecordsToPrint = 0) or (i < NoOfRecordsToPrint) then
                    i := i + 1
                else begin
                    TempVendorAmount.Find('+');
                    TempVendorAmount.Delete();
                end;

                TotalVenPurchases += "Purchases (LCY)";
                TotalVenBalance += "Balance (LCY)";
            end;

            trigger OnPreDataItem()
            begin
                WindowDialog.Open(SortingVendorsTxt);
                TempVendorAmount.DeleteAll();
                i := 0;
            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
            column(STRSUBSTNO_Text001_VendDateFilter_; StrSubstNo(PeriodTxt, VendDateFilter))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO_Text002_SELECTSTR_ShowType_1_Text004__; StrSubstNo(RankAccordingToTxt, SelectStr(ShowType + 1, AmountTypeTxt)))
            {
            }
            column(STRSUBSTNO___1___2__Vendor_TABLECAPTION_VendFilter_; StrSubstNo(TableFilterTxt, Vendor.TableCaption(), VendFilter))
            {
            }
            column(VendFilter; VendFilter)
            {
            }
            column(STRSUBSTNO_Text003_SELECTSTR_ShowType_1_Text004__; StrSubstNo(PortionOfTxt, SelectStr(ShowType + 1, AmountTypeTxt)))
            {
            }
            column(Integer_Number; Number)
            {
            }
            column(Vendor__No__; Vendor."No.")
            {
            }
            column(Vendor_Name; Vendor.Name)
            {
            }
            column(Vendor__Purchases__LCY__; Vendor."Purchases (LCY)")
            {
            }
            column(Vendor__Balance__LCY__; Vendor."Balance (LCY)")
            {
            }
            column(BarText; BarText)
            {
            }
            column(Vendor__Purchases__LCY___Control23; Vendor."Purchases (LCY)")
            {
            }
            column(VendPurchLCY; VendPurchLCY)
            {
                AutoFormatType = 1;
            }
            column(PurchPct; PurchPct)
            {
                DecimalPlaces = 1 : 1;
            }
            column(TotalVenBalance; TotalVenBalance)
            {
            }
            column(TotalVenPurchases; TotalVenPurchases)
            {
            }
            column(Vendor___Top_10_ListCaption; Vendor___Top_10_ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Integer_NumberCaption; Integer_NumberCaptionLbl)
            {
            }
            column(Vendor__No__Caption; Vendor.FieldCaption("No."))
            {
            }
            column(Vendor_NameCaption; Vendor.FieldCaption(Name))
            {
            }
            column(Vendor__Purchases__LCY__Caption; Vendor.FieldCaption("Purchases (LCY)"))
            {
            }
            column(Vendor__Balance__LCY__Caption; Vendor.FieldCaption("Balance (LCY)"))
            {
            }
            column(Vendor__Purchases__LCY___Control23Caption; Vendor__Purchases__LCY___Control23CaptionLbl)
            {
            }
            column(VendPurchLCYCaption; VendPurchLCYCaptionLbl)
            {
            }
            column(PurchPctCaption; PurchPctCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then begin
                    if not TempVendorAmount.Find('-') then
                        CurrReport.Break();
                end else
                    if TempVendorAmount.Next() = 0 then
                        CurrReport.Break();
                TempVendorAmount."Amount (LCY)" := -TempVendorAmount."Amount (LCY)";
                Vendor.Get(TempVendorAmount."Vendor No.");
                Vendor.CalcFields("Purchases (LCY)", "Balance (LCY)");
                if MaxAmount = 0 then
                    MaxAmount := TempVendorAmount."Amount (LCY)";
                if (MaxAmount > 0) and (TempVendorAmount."Amount (LCY)" > 0) then
                    BarText := PadStr('', Round(TempVendorAmount."Amount (LCY)" / MaxAmount * 45, 1), '*')
                else
                    BarText := '';
                TempVendorAmount."Amount (LCY)" := -TempVendorAmount."Amount (LCY)";
            end;

            trigger OnPreDataItem()
            begin
                VendPurchLCY := Vendor."Purchases (LCY)";
                WindowDialog.Close();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Vendor - Top 10 List';
        AboutText = 'Review a summary of vendors with the most transactions within a selected period to monitor supplier relationships, plan upcoming payments and identify potential cashflow issues.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Show; ShowType)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Show';
                        OptionCaption = 'Purchases (LCY),Balance (LCY)';
                        ToolTip = 'Specifies how the report will sort the vendors: Purchases, to sort by purchase volume; or Balance, to sort by balance. In either case, the vendors with the largest amounts will be shown first.';
                    }
                    field(Quantity; NoOfRecordsToPrint)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Quantity';
                        ToolTip = 'Specifies the number of vendors that will be included in the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if NoOfRecordsToPrint = 0 then
                NoOfRecordsToPrint := 10;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        FormatDocument: Codeunit "Format Document";
    begin
        VendFilter := FormatDocument.GetRecordFiltersWithCaptions(Vendor);
        VendDateFilter := Vendor.GetFilter("Date Filter");
    end;

    var
        TempVendorAmount: Record "Vendor Amount" temporary;
        WindowDialog: Dialog;
        VendFilter: Text;
        VendDateFilter: Text;
        ShowType: Option "Purchases (LCY)","Balance (LCY)";
        NoOfRecordsToPrint: Integer;
        VendPurchLCY: Decimal;
        PurchPct: Decimal;
        MaxAmount: Decimal;
        BarText: Text;
        i: Integer;
        TotalVenPurchases: Decimal;
        TotalVenBalance: Decimal;
        Vendor___Top_10_ListCaptionLbl: Label 'Vendor - Top 10 List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Integer_NumberCaptionLbl: Label 'Rank';
        Vendor__Purchases__LCY___Control23CaptionLbl: Label 'Total';
        VendPurchLCYCaptionLbl: Label 'Total Purchases';
        PurchPctCaptionLbl: Label '% of Total Purchases';

        SortingVendorsTxt: Label 'Sorting vendors       #1##########', Comment = '%1 - progress bar';
        PeriodTxt: Label 'Period: %1', Comment = '%1 - period text';
        RankAccordingToTxt: Label 'Rank according to %1', Comment = '%1 - ranking type';
        PortionOfTxt: Label 'Portion of %1', Comment = '%1 - type amount';
        AmountTypeTxt: Label 'Purchases (LCY),Balance (LCY)';
        TableFilterTxt: Label '%1: %2', Locked = true;

    procedure InitializeRequest(NewShowType: Option; NewNoOfRecordsToPrint: Integer)
    begin
        ShowType := NewShowType;
        NoOfRecordsToPrint := NewNoOfRecordsToPrint;
    end;
}


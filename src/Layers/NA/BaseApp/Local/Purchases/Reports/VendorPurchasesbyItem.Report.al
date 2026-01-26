// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Vendor;

report 10163 "Vendor Purchases by Item"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorPurchasesbyItem.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Purchases by Item';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Date Filter", "Location Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(SubTitle; SubTitle)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(ItemLedgEntryFilter; ItemLedgEntryFilter)
            {
            }
            column(IncludeReturns; IncludeReturns)
            {
            }
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(Item_Ledger_Entry__TABLECAPTION__________ItemLedgEntryFilter; "Item Ledger Entry".TableCaption + ': ' + ItemLedgEntryFilter)
            {
            }
            column(PurchasesText; PurchasesText)
            {
            }
            column(QtyText; QtyText)
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Description; Description)
            {
            }
            column(FIELDCAPTION__Base_Unit_of_Measure_____________Base_Unit_of_Measure_; FieldCaption("Base Unit of Measure") + ': ' + "Base Unit of Measure")
            {
            }
            column(ValueEntry__Purchase_Amount__Actual_____ValueEntry__Discount_Amount_; ValueEntry."Purchase Amount (Actual)" + ValueEntry."Discount Amount")
            {
            }
            column(ValueEntry__Discount_Amount_; ValueEntry."Discount Amount")
            {
            }
            column(ValueEntry__Purchase_Amount__Actual__; ValueEntry."Purchase Amount (Actual)")
            {
            }
            column(Item_Date_Filter; "Date Filter")
            {
            }
            column(Item_Location_Filter; "Location Filter")
            {
            }
            column(Item_Variant_Filter; "Variant Filter")
            {
            }
            column(Item_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Item_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Vendor_Purchases_by_ItemCaption; Vendor_Purchases_by_ItemCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Returns_are_included_in_Purchase_Quantities_Caption; Returns_are_included_in_Purchase_Quantities_CaptionLbl)
            {
            }
            column(Returns_are_not_included_in_Purchase_Quantities_Caption; Returns_are_not_included_in_Purchase_Quantities_CaptionLbl)
            {
            }
            column(Item_Ledger_Entry__Source_No__Caption; Item_Ledger_Entry__Source_No__CaptionLbl)
            {
            }
            column(Vend_NameCaption; Vend_NameCaptionLbl)
            {
            }
            column(Item_Ledger_Entry__Invoiced_Quantity_Caption; "Item Ledger Entry".FieldCaption("Invoiced Quantity"))
            {
            }
            column(ValueEntry__Purchase_Amount__Actual_____ValueEntry__Discount_Amount__Control29Caption; ValueEntry__Purchase_Amount__Actual_____ValueEntry__Discount_Amount__Control29CaptionLbl)
            {
            }
            column(ValueEntry__Discount_Amount__Control30Caption; ValueEntry__Discount_Amount__Control30CaptionLbl)
            {
            }
            column(ValueEntry__Purchase_Amount__Actual___Control31Caption; ValueEntry__Purchase_Amount__Actual___Control31CaptionLbl)
            {
            }
            column(Net_Average_Caption; Net_Average_CaptionLbl)
            {
            }
            column(Report_TotalCaption; Report_TotalCaptionLbl)
            {
            }
            dataitem("Item Ledger Entry"; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = field("No."), "Posting Date" = field("Date Filter"), "Location Code" = field("Location Filter"), "Variant Code" = field("Variant Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Entry Type", "Item No.", "Variant Code", "Source Type", "Source No.", "Posting Date") where("Entry Type" = const(Purchase), "Source Type" = const(Vendor));
                RequestFilterFields = "Source No.";
                column(FIELDCAPTION__Variant_Code_____________Variant_Code_; FieldCaption("Variant Code") + ': ' + "Variant Code")
                {
                }
                column(Item_Ledger_Entry__Source_No__; "Source No.")
                {
                }
                column(Vend_Name; Vend.Name)
                {
                }
                column(Item_Ledger_Entry__Invoiced_Quantity_; "Invoiced Quantity")
                {
                    DecimalPlaces = 2 : 5;
                }
                column(ValueEntry__Purchase_Amount__Actual_____ValueEntry__Discount_Amount__Control29; ValueEntry."Purchase Amount (Actual)" + ValueEntry."Discount Amount")
                {
                }
                column(ValueEntry__Discount_Amount__Control30; ValueEntry."Discount Amount")
                {
                }
                column(ValueEntry__Purchase_Amount__Actual___Control31; ValueEntry."Purchase Amount (Actual)")
                {
                }
                column(Net_Average_; "Net Average")
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Text008_________FIELDCAPTION__Variant_Code_____________Variant_Code_; Text008 + ' ' + FieldCaption("Variant Code") + ': ' + "Variant Code")
                {
                }
                column(Net_Average__Control9; "Net Average")
                {
                    DecimalPlaces = 2 : 5;
                }
                column(ValueEntry__Purchase_Amount__Actual___Control19; ValueEntry."Purchase Amount (Actual)")
                {
                }
                column(ValueEntry__Discount_Amount__Control25; ValueEntry."Discount Amount")
                {
                }
                column(ValueEntry__Purchase_Amount__Actual_____ValueEntry__Discount_Amount__Control39; ValueEntry."Purchase Amount (Actual)" + ValueEntry."Discount Amount")
                {
                }
                column(Item_Ledger_Entry__Invoiced_Quantity__Control40; "Invoiced Quantity")
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Item_Ledger_Entry__Invoiced_Quantity__Control34; "Invoiced Quantity")
                {
                    DecimalPlaces = 2 : 5;
                }
                column(ValueEntry__Purchase_Amount__Actual_____ValueEntry__Discount_Amount__Control35; ValueEntry."Purchase Amount (Actual)" + ValueEntry."Discount Amount")
                {
                }
                column(ValueEntry__Discount_Amount__Control36; ValueEntry."Discount Amount")
                {
                }
                column(ValueEntry__Purchase_Amount__Actual___Control37; ValueEntry."Purchase Amount (Actual)")
                {
                }
                column(Net_Average__Control38; "Net Average")
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Text008_________FIELDCAPTION__Item_No______________Item_No__; Text008 + ' ' + FieldCaption("Item No.") + ': ' + "Item No.")
                {
                }
                column(Item_Ledger_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Item_Ledger_Entry_Variant_Code; "Variant Code")
                {
                }
                column(Item_Ledger_Entry_Item_No_; "Item No.")
                {
                }
                column(Item_Ledger_Entry_Posting_Date; "Posting Date")
                {
                }
                column(Item_Ledger_Entry_Location_Code; "Location Code")
                {
                }
                column(Item_Ledger_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                {
                }
                column(Item_Ledger_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    ValueEntry.SetRange("Item Ledger Entry No.", "Item Ledger Entry"."Entry No.");
                    ValueEntry.CalcSums("Purchase Amount (Actual)", "Discount Amount");
                    if "Source No." <> '' then
                        Vend.Get("Source No.")
                    else
                        Clear(Vend);
                end;

                trigger OnPreDataItem()
                begin
                    if IncludeReturns then
                        SetFilter("Invoiced Quantity", '<>0')
                    else
                        SetFilter("Invoiced Quantity", '>0');

                    ValueEntry.Reset();
                    ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Purchases (Qty.)", "Purchases (LCY)");
                if MinPurchases <> 0 then
                    if "Purchases (LCY)" <= MinPurchases then
                        CurrReport.Skip();
                if MaxPurchases <> 0 then
                    if "Purchases (LCY)" >= MaxPurchases then
                        CurrReport.Skip();
                if MinQty <> 0 then
                    if "Purchases (Qty.)" <= MinQty then
                        CurrReport.Skip();
                if MaxQty <> 0 then
                    if "Purchases (Qty.)" >= MaxQty then
                        CurrReport.Skip();
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
                    field(IncludeReturns; IncludeReturns)
                    {
                        Caption = 'Include Returns';
                        ToolTip = 'Specifies if sales tax related to purchase returns is included in the report.';
                    }
                    group("Items with Net Purch. ($)")
                    {
                        Caption = 'Items with Net Purch. ($)';
                        field(MinPurchases; MinPurchases)
                        {
                            BlankZero = true;
                            Caption = 'Greater than';
                            ToolTip = 'Specifies a maximum dollar value for sales. You can limit which items appear on the report by indicating a sales dollar range.';
                        }
                        field(MaxPurchases; MaxPurchases)
                        {
                            BlankZero = true;
                            Caption = 'Less than';
                            ToolTip = 'Specifies a minimum dollar value for sales. You can limit which items appear on the report by indicating a sales dollar range.';
                        }
                    }
                    group("Items with Net Purch. (Qty)")
                    {
                        Caption = 'Items with Net Purch. (Qty)';
                        field(MinQty; MinQty)
                        {
                            BlankZero = true;
                            Caption = 'Greater than';
                            ToolTip = 'Specifies a maximum dollar value for sales. You can limit which items appear on the report by indicating a sales dollar range.';
                        }
                        field(MaxQty; MaxQty)
                        {
                            BlankZero = true;
                            Caption = 'Less than';
                            ToolTip = 'Specifies a minimum dollar value for sales. You can limit which items appear on the report by indicating a sales dollar range.';
                        }
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
        CompanyInformation.Get();
        ItemFilter := Item.GetFilters();
        PeriodText := "Item Ledger Entry".GetFilter("Posting Date");
        "Item Ledger Entry".SetRange("Posting Date");
        ItemLedgEntryFilter := "Item Ledger Entry".GetFilters();
        if PeriodText = '' then
            SubTitle := Text000
        else
            SubTitle := Text001 + ' ' + PeriodText;
        if MinPurchases = 0 then
            PurchasesText := ''
        else
            PurchasesText := StrSubstNo(Text002, MinPurchases);
        if MaxPurchases <> 0 then
            if PurchasesText = '' then
                PurchasesText := StrSubstNo(Text003, MaxPurchases)
            else
                PurchasesText := PurchasesText + StrSubstNo(Text004, MaxPurchases);
        if MinQty = 0 then
            QtyText := ''
        else
            QtyText := StrSubstNo(Text005, MinQty);
        if MaxQty <> 0 then
            if QtyText = '' then
                QtyText := StrSubstNo(Text006, MaxQty)
            else
                QtyText := QtyText + StrSubstNo(Text007, MaxQty);
    end;

    var
        Vend: Record Vendor;
        CompanyInformation: Record "Company Information";
        ValueEntry: Record "Value Entry";
        IncludeReturns: Boolean;
        MinPurchases: Decimal;
        MaxPurchases: Decimal;
        MinQty: Decimal;
        MaxQty: Decimal;
        SubTitle: Text;
        PurchasesText: Text[132];
        QtyText: Text[132];
        "Net Average": Decimal;
        PeriodText: Text;
        ItemFilter: Text;
        ItemLedgEntryFilter: Text;
        Text000: Label 'All Purchases to Date';
        Text001: Label 'Purchases during the Period';
        Text002: Label 'Items with Net Purchases of more than $%1';
        Text003: Label 'Items with Net Purchases of less than $%1';
        Text004: Label ' and less than $%1';
        Text005: Label 'Items with Net Purchase Quantity more than %1';
        Text006: Label 'Items with Net Purchase Quantity less than %1';
        Text007: Label ' and less than %1';
        Text008: Label 'Total for';
        Vendor_Purchases_by_ItemCaptionLbl: Label 'Vendor Purchases by Item';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Returns_are_included_in_Purchase_Quantities_CaptionLbl: Label 'Returns are included in Purchase Quantities.';
        Returns_are_not_included_in_Purchase_Quantities_CaptionLbl: Label 'Returns are not included in Purchase Quantities.';
        Item_Ledger_Entry__Source_No__CaptionLbl: Label 'Vendor No.';
        Vend_NameCaptionLbl: Label 'Name';
        ValueEntry__Purchase_Amount__Actual_____ValueEntry__Discount_Amount__Control29CaptionLbl: Label 'Amount Before Discount';
        ValueEntry__Discount_Amount__Control30CaptionLbl: Label 'Discount Amount';
        ValueEntry__Purchase_Amount__Actual___Control31CaptionLbl: Label 'Amount';
        Net_Average_CaptionLbl: Label 'Net Average';
        Report_TotalCaptionLbl: Label 'Report Total';

    procedure CalcNetAverage()
    begin
        if "Item Ledger Entry"."Invoiced Quantity" <> 0 then
            "Net Average" := ValueEntry."Purchase Amount (Actual)" / "Item Ledger Entry"."Invoiced Quantity"
        else
            "Net Average" := 0;
    end;
}


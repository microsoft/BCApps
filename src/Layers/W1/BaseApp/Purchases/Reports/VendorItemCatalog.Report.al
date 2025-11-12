// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;

report 320 "Vendor Item Catalog"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/VendorItemCatalog.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Item Catalog';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(VendTblCapVendFltr; TableCaption + ': ' + VendFilter)
            {
            }
            column(VendFilter; VendFilter)
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
            column(PricesInclVATText; PricesInclVATText)
            {
            }
            column(VendorItemCatalogCaption; VendorItemCatalogCaptionLbl)
            {
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(ItemNoCaption; ItemVendor.FieldCaption("Item No."))
            {
            }
            column(ItemDescriptionCaption; ItemDescriptionCaptionLbl)
            {
            }
            column(PurchPriceStartDateCaption; PurchPriceStartDateCaptionLbl)
            {
            }
            column(DirectUnitCostCaption; Direct_Unit_Cost_CaptionLbl)
            {
            }
            column(ItemVendLeadTimeCalcCaptn; ItemVendLeadTimeCalcCaptnLbl)
            {
            }
            column(ItemVendorItemNoCaption; ItemVendorItemNoCaptionLbl)
            {
            }
            column(ExtendedPriceFeatureEnabled; ExtendedPriceEnabled)
            {
            }
            dataitem("Purchase Price"; "Purchase Price")
            {
                DataItemLink = "Vendor No." = field("No.");
                DataItemTableView = sorting("Vendor No.");
                column(ItemNo_PurchPrice; "Item No.")
                {
                    IncludeCaption = true;
                }
                column(ItemDescription; Item.Description)
                {
                    IncludeCaption = false;
                }
                column(StartingDt_PurchPrice; Format("Starting Date"))
                {
                }
                column(DrctUnitCost_PurchPrice; "Direct Unit Cost")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 2;
                    IncludeCaption = true;
                }
                column(CurrCode_PurchPrice; "Currency Code")
                {
                }
                column(ItemVendLeadTimeCal; ItemVendor."Lead Time Calculation")
                {
                    IncludeCaption = false;
                }
                column(ItemVendVendorItemNo; ItemVendor."Vendor Item No.")
                {
                    IncludeCaption = false;
                }
                trigger OnPreDataItem()
                begin
                    if ExtendedPriceEnabled then
                        CurrReport.Break();
                end;

                trigger OnAfterGetRecord()
                begin
                    InitGlobals("Vendor No.", "Item No.", "Variant Code");
                end;
            }
            dataitem(PriceListLine; "Price List Line")
            {
                DataItemLink = "Source No." = field("No.");
                DataItemTableView = sorting("Source No.") where("Source Type" = const(Vendor), "Asset Type" = const(Item), Status = const(Active));
                column(Price_ItemNo; "Asset No.")
                {
                    IncludeCaption = false;
                }
                column(Price_ItemDescription; Item.Description)
                {
                    IncludeCaption = false;
                }
                column(Price_StartingDt; Format("Starting Date"))
                {
                }
                column(Price_DrctUnitCost; "Direct Unit Cost")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 2;
                }
                column(Price_CurrencyCode; "Currency Code")
                {
                }
                column(Price_ItemVendLeadTimeCal; ItemVendor."Lead Time Calculation")
                {
                    IncludeCaption = false;
                }
                column(Price_ItemVendVendorItemNo; ItemVendor."Vendor Item No.")
                {
                    IncludeCaption = false;
                }
                trigger OnPreDataItem()
                begin
                    if not ExtendedPriceEnabled then
                        CurrReport.Break();
                end;

                trigger OnAfterGetRecord()
                begin
                    InitGlobals("Source No.", "Asset No.", "Variant Code");
                end;
            }
            trigger OnAfterGetRecord()
            begin
                if "Prices Including VAT" then
                    PricesInclVATText := PricesIncludeVATTxt
                else
                    PricesInclVATText := PricesExcludeVATTxt;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Vendor Item Catalog';
        AboutText = 'Get a list of vendors by item or items per vendor.';

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
        FormatDocument: Codeunit "Format Document";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        VendFilter := FormatDocument.GetRecordFiltersWithCaptions(Vendor);
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        Item: Record Item;
        ItemVendor: Record "Item Vendor";
        VendFilter: Text;
        PricesInclVATText: Text[30];
        ExtendedPriceEnabled: Boolean;
        VendorItemCatalogCaptionLbl: Label 'Vendor Item Catalog';
        CurrReportPageNoCaptionLbl: Label 'Page';
        ItemDescriptionCaptionLbl: Label 'Description';
        PurchPriceStartDateCaptionLbl: Label 'Starting Date';
        ItemVendLeadTimeCalcCaptnLbl: Label 'Lead Time Calculation';
        ItemVendorItemNoCaptionLbl: Label 'Vendor Item No.';
        Direct_Unit_Cost_CaptionLbl: Label 'Direct Unit Cost';

        PricesIncludeVATTxt: Label 'Prices Include VAT';
        PricesExcludeVATTxt: Label 'Prices Exclude VAT';

    local procedure InitGlobals(VendorNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        if ItemNo <> Item."No." then
            Item.Get(ItemNo);

        if not ItemVendor.Get(VendorNo, ItemNo, VariantCode) then
            ItemVendor.Init();
    end;
}


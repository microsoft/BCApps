// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.Vendor;

report 720 "Item/Vendor Catalog"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/ItemVendorCatalog.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Item/Vendor Catalog';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Item_TABLECAPTION__________ItemFilter; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Description; Description)
            {
            }
            column(Item__Base_Unit_of_Measure_; "Base Unit of Measure")
            {
            }
            column(Item_Vendor_CatalogCaption; Item_Vendor_CatalogCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Purchase_Price__Vendor_No__Caption; ItemVend.FieldCaption("Vendor No."))
            {
            }
            column(Vend_NameCaption; Vend_NameCaptionLbl)
            {
            }
            column(Purchase_Price__Starting_Date_Caption; Purchase_Price__Starting_Date_CaptionLbl)
            {
            }
            column(Purchase_Price__Direct_Unit_Cost_Caption; Direct_Unit_Cost_CaptionLbl)
            {
            }
            column(ItemVend__Lead_Time_Calculation_Caption; ItemVend__Lead_Time_Calculation_CaptionLbl)
            {
            }
            column(ItemVend__Vendor_Item_No__Caption; ItemVend__Vendor_Item_No__CaptionLbl)
            {
            }
            column(Item__Base_Unit_of_Measure_Caption; FieldCaption("Base Unit of Measure"))
            {
            }
            column(ExtendedPriceFeatureEnabled; ExtendedPriceEnabled)
            {
            }
            dataitem("Purchase Price"; "Purchase Price")
            {
                DataItemLink = "Item No." = field("No.");
                DataItemTableView = sorting("Item No.");
                column(Purchase_Price__Vendor_No__; "Vendor No.")
                {
                }
                column(Vend_Name; Vend.Name)
                {
                }
                column(Purchase_Price__Starting_Date_; Format("Starting Date"))
                {
                }
                column(Purchase_Price__Direct_Unit_Cost_; "Direct Unit Cost")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 2;
                }
                column(Purchase_Price__Currency_Code_; "Currency Code")
                {
                }
                column(ItemVend__Lead_Time_Calculation_; ItemVend."Lead Time Calculation")
                {
                }
                column(ItemVend__Vendor_Item_No__; ItemVend."Vendor Item No.")
                {
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
                DataItemLink = "Asset No." = field("No.");
                DataItemTableView = sorting("Asset No.") where("Source Type" = const(Vendor), "Asset Type" = const(Item), Status = const(Active));
                column(Price_Vendor_No; "Source No.")
                {
                }
                column(Price_Vend_Name; Vend.Name)
                {
                }
                column(Price_Starting_Date; Format("Starting Date"))
                {
                }
                column(Price_Direct_Unit_Cost; "Direct Unit Cost")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 2;
                }
                column(Price_Currency_Code_; "Currency Code")
                {
                }
                column(ItemVend_Lead_Time_Calculation; ItemVend."Lead Time Calculation")
                {
                }
                column(ItemVend_Vendor_Item_No; ItemVend."Vendor Item No.")
                {
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
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        ItemFilter := Item.GetFilters();
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        ItemVend: Record "Item Vendor";
        Vend: Record Vendor;
        ItemFilter: Text;
        ExtendedPriceEnabled: Boolean;
        Item_Vendor_CatalogCaptionLbl: Label 'Item/Vendor Catalog';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Vend_NameCaptionLbl: Label 'Name';
        Purchase_Price__Starting_Date_CaptionLbl: Label 'Date';
        ItemVend__Lead_Time_Calculation_CaptionLbl: Label 'Lead Time Calculation';
        ItemVend__Vendor_Item_No__CaptionLbl: Label 'Item Vendor No.';
        Direct_Unit_Cost_CaptionLbl: Label 'Direct Unit Cost';

    local procedure InitGlobals(VendorNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        if VendorNo <> Vend."No." then
            Vend.Get(VendorNo);

        if not ItemVend.Get(VendorNo, ItemNo, VariantCode) then
            ItemVend.Init();
    end;
}


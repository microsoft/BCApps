// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Calculation;

report 10159 "Sales Promotion"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Pricing/SalesPromotion.rdlc';
    Caption = 'Sales Promotion';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", Description;
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
            column(ItemFilter; ItemFilter)
            {
            }
            column(SalesPriceFilter; SalesPriceFilter)
            {
            }
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(Sales_Price__TABLECAPTION__________SalesPriceFilter; "Sales Price".TableCaption + ': ' + SalesPriceFilter)
            {
            }
            column(Item_No_; "No.")
            {
            }
            column(Item_Variant_Filter; "Variant Filter")
            {
            }
            column(Sales_PromotionCaption; Sales_PromotionCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Item__No__Caption; FieldCaption("No."))
            {
            }
            column(Item_DescriptionCaption; FieldCaption(Description))
            {
            }
            column(Item__Base_Unit_of_Measure_Caption; FieldCaption("Base Unit of Measure"))
            {
            }
            column(Sales_Price__Starting_Date_Caption; "Sales Price".FieldCaption("Starting Date"))
            {
            }
            column(Item__Unit_Price_Caption; Item__Unit_Price_CaptionLbl)
            {
            }
            column(Sales_Price__Unit_Price_Caption; Sales_Price__Unit_Price_CaptionLbl)
            {
            }
            column(Sales_Price__Currency_Code_Caption; "Sales Price".FieldCaption("Currency Code"))
            {
            }
            column(Sales_Price__Sales_Code_Caption; "Sales Price".FieldCaption("Sales Code"))
            {
            }
            dataitem("Sales Price"; "Sales Price")
            {
                DataItemLink = "Item No." = field("No."), "Variant Code" = field("Variant Filter");
                DataItemTableView = sorting("Item No.", "Sales Type", "Sales Code", "Starting Date", "Currency Code", "Variant Code", "Unit of Measure Code");
                RequestFilterFields = "Sales Type", "Starting Date";
                column(Item__No__; Item."No.")
                {
                }
                column(Item_Description; Item.Description)
                {
                }
                column(Item__Base_Unit_of_Measure_; Item."Base Unit of Measure")
                {
                }
                column(Sales_Price__Starting_Date_; "Starting Date")
                {
                }
                column(Item__Unit_Price_; Item."Unit Price")
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Sales_Price__Unit_Price_; "Unit Price")
                {
                }
                column(Sales_Price__Currency_Code_; "Currency Code")
                {
                }
                column(Sales_Price__Sales_Code_; "Sales Code")
                {
                }
                column(Sales_Price_Item_No_; "Item No.")
                {
                }
                column(Sales_Price_Sales_Type; "Sales Type")
                {
                }
                column(Sales_Price_Variant_Code; "Variant Code")
                {
                }
                column(Sales_Price_Unit_of_Measure_Code; "Unit of Measure Code")
                {
                }
                column(Sales_Price_Minimum_Quantity; "Minimum Quantity")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    SalesPromotionExists := true;

                    if "Unit Price" = Item."Unit Price" then
                        CurrReport.Skip();
                end;
            }
        }
    }

    requestpage
    {
        SaveValues = true;

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

    trigger OnInitReport()
    var
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        FeaturePriceCalculation.FailIfFeatureEnabled();
    end;

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        ItemFilter := Item.GetFilters();
        SalesPriceFilter := "Sales Price".GetFilters();
    end;

    trigger OnPostReport()
    begin
        if (not SalesPromotionExists) then
            Message(SalesPromotionExistsMsg);
    end;

    var
        CompanyInformation: Record "Company Information";
        SalesPromotionExists: Boolean;
        ItemFilter: Text;
        SalesPriceFilter: Text;
        SalesPromotionExistsMsg: Label 'No sales promotions were found';
        Sales_PromotionCaptionLbl: Label 'Sales Promotion';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Item__Unit_Price_CaptionLbl: Label 'List Price';
        Sales_Price__Unit_Price_CaptionLbl: Label 'Sale Price';
}

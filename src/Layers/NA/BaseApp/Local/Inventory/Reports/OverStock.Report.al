// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

report 10150 "Over Stock"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/OverStock.rdlc';
    Caption = 'Over Stock';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", Description, "Location Filter";
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
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(UseSKU; UseSKU)
            {
            }
            column(ValuedAmount; ValuedAmount)
            {
            }
            column(QuantityOver; QuantityOver)
            {
                DecimalPlaces = 2 : 5;
            }
            column(AvgCost; AvgCost)
            {
            }
            column(Item__Maximum_Inventory_; "Maximum Inventory")
            {
                DecimalPlaces = 2 : 5;
            }
            column(Item__Vendor_No__; "Vendor No.")
            {
            }
            column(QuantityOnHand; QuantityOnHand)
            {
                DecimalPlaces = 2 : 5;
            }
            column(Item_Description; Description)
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Item__Stockkeeping_Unit_Exists_; Item."Stockkeeping Unit Exists")
            {
            }
            column(Item__No___Control18; "No.")
            {
            }
            column(Item_Description_Control19; Description)
            {
            }
            column(Item__Vendor_No___Control20; "Vendor No.")
            {
            }
            column(QuantityOnHand_Control21; QuantityOnHand)
            {
                DecimalPlaces = 2 : 5;
            }
            column(Item__Maximum_Inventory__Control22; "Maximum Inventory")
            {
                DecimalPlaces = 2 : 5;
            }
            column(QuantityOver_Control23; QuantityOver)
            {
                DecimalPlaces = 2 : 5;
            }
            column(AvgCost_Control24; AvgCost)
            {
            }
            column(ValuedAmount_Control25; ValuedAmount)
            {
            }
            column(QuantityOnHand_Control26; QuantityOnHand)
            {
                DecimalPlaces = 2 : 5;
            }
            column(ValuedAmount_Control27; ValuedAmount)
            {
            }
            column(QuantityOver_Control2; QuantityOver)
            {
                DecimalPlaces = 2 : 5;
            }
            column(ValuedAmount_Control1480016; ValuedAmount)
            {
            }
            column(QuantityOver_Control1480017; QuantityOver)
            {
                DecimalPlaces = 2 : 5;
            }
            column(QuantityOnHand_Control1480018; QuantityOnHand)
            {
                DecimalPlaces = 2 : 5;
            }
            column(Item_Location_Filter; "Location Filter")
            {
            }
            column(Item_Variant_Filter; "Variant Filter")
            {
            }
            column(Item_Date_Filter; "Date Filter")
            {
            }
            column(Over_StockCaption; Over_StockCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(ValuedAmount_Control25Caption; ValuedAmount_Control25CaptionLbl)
            {
            }
            column(Item__No___Control18Caption; FieldCaption("No."))
            {
            }
            column(Item_Description_Control19Caption; FieldCaption(Description))
            {
            }
            column(Item__Vendor_No___Control20Caption; FieldCaption("Vendor No."))
            {
            }
            column(QuantityOnHand_Control21Caption; QuantityOnHand_Control21CaptionLbl)
            {
            }
            column(Item__Maximum_Inventory__Control22Caption; FieldCaption("Maximum Inventory"))
            {
            }
            column(QuantityOver_Control23Caption; QuantityOver_Control23CaptionLbl)
            {
            }
            column(AvgCost_Control24Caption; AvgCost_Control24CaptionLbl)
            {
            }
            column(ValuedAmount_Control1480008Caption; ValuedAmount_Control1480008CaptionLbl)
            {
            }
            column(AvgCost_Control1480009Caption; AvgCost_Control1480009CaptionLbl)
            {
            }
            column(Stockkeeping_Unit__Maximum_Inventory_Caption; "Stockkeeping Unit".FieldCaption("Maximum Inventory"))
            {
            }
            column(QuantityOver_Control1480011Caption; QuantityOver_Control1480011CaptionLbl)
            {
            }
            column(Stockkeeping_Unit_DescriptionCaption; "Stockkeeping Unit".FieldCaption(Description))
            {
            }
            column(Stockkeeping_Unit__Vendor_No__Caption; "Stockkeeping Unit".FieldCaption("Vendor No."))
            {
            }
            column(QuantityOnHand_Control1480013Caption; QuantityOnHand_Control1480013CaptionLbl)
            {
            }
            column(Stockkeeping_Unit__Item_No__Caption; "Stockkeeping Unit".FieldCaption("Item No."))
            {
            }
            column(Stockkeeping_Unit__Location_Code_Caption; "Stockkeeping Unit".FieldCaption("Location Code"))
            {
            }
            column(Stockkeeping_Unit__Variant_Code_Caption; "Stockkeeping Unit".FieldCaption("Variant Code"))
            {
            }
            column(Report_TotalCaption; Report_TotalCaptionLbl)
            {
            }
            column(Report_TotalCaption_Control1480019; Report_TotalCaption_Control1480019Lbl)
            {
            }
            dataitem("Stockkeeping Unit"; "Stockkeeping Unit")
            {
                DataItemLink = "Item No." = field("No."), "Location Code" = field("Location Filter"), "Variant Code" = field("Variant Filter"), "Date Filter" = field("Date Filter");
                DataItemTableView = sorting("Item No.", "Location Code", "Variant Code");
                column(ValuedAmount_Control1480008; ValuedAmount)
                {
                }
                column(AvgCost_Control1480009; AvgCost)
                {
                }
                column(Stockkeeping_Unit__Maximum_Inventory_; "Maximum Inventory")
                {
                    DecimalPlaces = 2 : 5;
                }
                column(QuantityOver_Control1480011; QuantityOver)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Stockkeeping_Unit__Vendor_No__; "Vendor No.")
                {
                }
                column(QuantityOnHand_Control1480013; QuantityOnHand)
                {
                    DecimalPlaces = 2 : 5;
                }
                column(Stockkeeping_Unit_Description; Description)
                {
                }
                column(Stockkeeping_Unit__Item_No__; "Item No.")
                {
                }
                column(Stockkeeping_Unit__Location_Code_; "Location Code")
                {
                }
                column(Stockkeeping_Unit__Variant_Code_; "Variant Code")
                {
                }
                column(Stockkeeping_Unit_Date_Filter; "Date Filter")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    CalcFields(Description);
                    Item2 := Item;
                    Item2.Reset();
                    if "Location Code" <> '' then
                        Item2.SetRange("Location Filter", "Location Code");
                    if "Variant Code" <> '' then
                        Item2.SetRange("Variant Filter", "Variant Code");
                    Item.CopyFilter("Date Filter", Item2."Date Filter");
                    ItemCostMgmt.CalculateAverageCost(Item2, AvgCost, AvgCostACY);
                    Item2.CalcFields("Net Change");
                    if Item2."Net Change" > "Maximum Inventory" then begin
                        QuantityOnHand := Item2."Net Change";
                        QuantityOver := QuantityOnHand - "Maximum Inventory";
                    end else
                        CurrReport.Skip();
                    ValuedAmount := QuantityOver * AvgCost;
                end;

                trigger OnPreDataItem()
                begin
                    if not UseSKU then
                        CurrReport.Break();
                    Clear(QuantityOnHand);
                    Clear(QuantityOver);
                    Clear(ValuedAmount);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Net Change", "Stockkeeping Unit Exists");
                if not UseSKU or not "Stockkeeping Unit Exists" then begin
                    if "Net Change" > "Maximum Inventory" then begin
                        QuantityOnHand := "Net Change";
                        QuantityOver := QuantityOnHand - "Maximum Inventory";
                    end else
                        CurrReport.Skip();
                    ItemCostMgmt.CalculateAverageCost(Item, AvgCost, AvgCostACY);
                    ValuedAmount := QuantityOver * AvgCost;
                end;
            end;

            trigger OnPreDataItem()
            begin
                Clear(QuantityOnHand);
                Clear(QuantityOver);
                Clear(ValuedAmount);
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
                    field(UseStockkeepingUnit; UseSKU)
                    {
                        Caption = 'Use Stockkeeping Unit';
                        ToolTip = 'Specifies if you want to only include items that are set up as SKUs. This adds SKU-related fields, such as the Location Code, Variant Code, and Qty. in Transit fields, to the report.';
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
    end;

    var
        CompanyInformation: Record "Company Information";
        Item2: Record Item;
        ItemCostMgmt: Codeunit ItemCostManagement;
        ItemFilter: Text;
        QuantityOnHand: Decimal;
        QuantityOver: Decimal;
        ValuedAmount: Decimal;
        AvgCost: Decimal;
        AvgCostACY: Decimal;
        UseSKU: Boolean;
        Over_StockCaptionLbl: Label 'Over Stock';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        ValuedAmount_Control25CaptionLbl: Label 'Estimated Over Stock Value';
        QuantityOnHand_Control21CaptionLbl: Label 'Quantity on Hand';
        QuantityOver_Control23CaptionLbl: Label 'Over Stock Quantity';
        AvgCost_Control24CaptionLbl: Label 'Average Cost';
        ValuedAmount_Control1480008CaptionLbl: Label 'Estimated Over Stock Value';
        AvgCost_Control1480009CaptionLbl: Label 'Average Cost';
        QuantityOver_Control1480011CaptionLbl: Label 'Over Stock Quantity';
        QuantityOnHand_Control1480013CaptionLbl: Label 'Quantity on Hand';
        Report_TotalCaptionLbl: Label 'Report Total';
        Report_TotalCaption_Control1480019Lbl: Label 'Report Total';
}


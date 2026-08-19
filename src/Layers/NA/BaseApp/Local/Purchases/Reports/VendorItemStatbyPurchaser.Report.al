// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.CRM.Team;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;

report 10114 "Vendor Item Stat. by Purchaser"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorItemStatbyPurchaser.rdlc';
    ApplicationArea = Suite;
    Caption = 'Vendor Item Stat. by Purchaser';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Salesperson/Purchaser"; "Salesperson/Purchaser")
        {
            DataItemTableView = sorting(Code);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Code", Name;
            RequestFilterHeading = 'Purchaser';
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
            column(FilterString; FilterString)
            {
            }
            column(FilterString3; FilterString3)
            {
            }
            column(FilterString2; FilterString2)
            {
            }
            column(OnlyOnePerPage; OnlyOnePerPage)
            {
            }
            column(Salesperson_Purchaser__TABLECAPTION__________FilterString; "Salesperson/Purchaser".TableCaption + ': ' + FilterString)
            {
            }
            column(Vendor_TABLECAPTION__________FilterString2; Vendor.TableCaption + ': ' + FilterString2)
            {
            }
            column(Value_Entry__TABLECAPTION__________FilterString3; "Value Entry".TableCaption + ': ' + FilterString3)
            {
            }
            column(Salesperson_Purchaser_Code; Code)
            {
            }
            column(Salesperson_Purchaser_Name; Name)
            {
            }
            column(Value_Entry___Purchase_Amount__Actual__; "Value Entry"."Purchase Amount (Actual)")
            {
            }
            column(Value_Entry___Discount_Amount_; "Value Entry"."Discount Amount")
            {
            }
            column(Vendor_Item_Statistics_by_PurchaserCaption; Vendor_Item_Statistics_by_PurchaserCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Salesperson_Purchaser_CodeCaption; Salesperson_Purchaser_CodeCaptionLbl)
            {
            }
            column(Salesperson_Purchaser_NameCaption; Salesperson_Purchaser_NameCaptionLbl)
            {
            }
            column(Vendor__No__Caption; Vendor__No__CaptionLbl)
            {
            }
            column(Vendor_NameCaption; Vendor_NameCaptionLbl)
            {
            }
            column(Value_Entry__Item_No__Caption; Value_Entry__Item_No__CaptionLbl)
            {
            }
            column(Item_DescriptionCaption; Item_DescriptionCaptionLbl)
            {
            }
            column(Value_Entry__Invoiced_Quantity_Caption; Value_Entry__Invoiced_Quantity_CaptionLbl)
            {
            }
            column(AmountCaption; AmountCaptionLbl)
            {
            }
            column(Value_Entry__Discount_Amount_Caption; "Value Entry".FieldCaption("Discount Amount"))
            {
            }
            column(AvgCostCaption; AvgCostCaptionLbl)
            {
            }
            column(AvgDaysCaption; AvgDaysCaptionLbl)
            {
            }
            column(Item__Base_Unit_of_Measure_Caption; Item__Base_Unit_of_Measure_CaptionLbl)
            {
            }
            column(Report_TotalsCaption; Report_TotalsCaptionLbl)
            {
            }
            dataitem(Vendor; Vendor)
            {
                DataItemLink = "Purchaser Code" = field(Code);
                DataItemTableView = sorting("Purchaser Code", "No.");
                PrintOnlyIfDetail = true;
                RequestFilterFields = "No.", "Search Name";
                column(Vendor__No__; "No.")
                {
                }
                column(Vendor_Name; Name)
                {
                }
                column(Vendor__Phone_No__; "Phone No.")
                {
                }
                column(Vendor_Contact; Contact)
                {
                }
                column(Salesperson_Purchaser__Code; "Salesperson/Purchaser".Code)
                {
                }
                column(Value_Entry___Purchase_Amount__Actual___Control38; "Value Entry"."Purchase Amount (Actual)")
                {
                }
                column(Value_Entry___Discount_Amount__Control39; "Value Entry"."Discount Amount")
                {
                }
                column(Vendor_Purchaser_Code; "Purchaser Code")
                {
                }
                column(Vendor_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
                {
                }
                column(Vendor_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
                {
                }
                column(Phone_Caption; Phone_CaptionLbl)
                {
                }
                column(Contact_Caption; Contact_CaptionLbl)
                {
                }
                column(Purchaser_TotalsCaption; Purchaser_TotalsCaptionLbl)
                {
                }
                dataitem("Value Entry"; "Value Entry")
                {
                    DataItemLink = "Source No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                    DataItemTableView = sorting("Source Type", "Source No.", "Item Ledger Entry Type", "Item No.", "Posting Date") where("Source Type" = const(Vendor), "Item Ledger Entry Type" = const(Purchase));
                    RequestFilterFields = "Item Ledger Entry Type", "Inventory Posting Group", "Posting Date";
                    column(Value_Entry__Item_No__; "Item No.")
                    {
                    }
                    column(Item_Description; Item.Description)
                    {
                    }
                    column(Value_Entry__Invoiced_Quantity_; "Invoiced Quantity")
                    {
                    }
                    column(Item__Base_Unit_of_Measure_; Item."Base Unit of Measure")
                    {
                    }
                    column(Value_Entry__Purchase_Amount__Actual__; "Purchase Amount (Actual)")
                    {
                    }
                    column(Value_Entry__Discount_Amount_; "Discount Amount")
                    {
                    }
                    column(AvgCost; AvgCost)
                    {
                    }
                    column(AvgDays; AvgDays)
                    {
                        DecimalPlaces = 0 : 0;
                    }
                    column(Vendor__No___Control49; Vendor."No.")
                    {
                    }
                    column(Value_Entry__Purchase_Amount__Actual___Control50; "Purchase Amount (Actual)")
                    {
                    }
                    column(Value_Entry__Discount_Amount__Control51; "Discount Amount")
                    {
                    }
                    column(Value_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(Value_Entry_Source_No_; "Source No.")
                    {
                    }
                    column(Value_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                    {
                    }
                    column(Value_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                    {
                    }
                    column(Vendor_TotalsCaption; Vendor_TotalsCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        PurchInvHeader.SetRange("Posting Date", "Posting Date");
                        PurchInvHeader.SetRange("Vendor Invoice No.", "Document No.");
                        if PurchInvHeader.FindFirst() then
                            if PurchInvHeader."Order Date" > 0D then begin
                                "TotalQuantity-LT" := "TotalQuantity-LT" + "Invoiced Quantity";
                                TotalDays := TotalDays + (("Posting Date" - PurchInvHeader."Order Date")
                                                          * "Invoiced Quantity");
                            end;

                        if not Item.Get("Item No.") then begin
                            Item.Description := 'Others';
                            Item."Base Unit of Measure" := '';
                        end;
                        if "Invoiced Quantity" <> 0 then begin
                            ItemCostMgt.CalculateAverageCost(Item, AvgCost, AverageCostACY);
                            AvgCost := Round(AvgCost, 0.00001);
                        end else
                            AvgCost := 0;
                        if "TotalQuantity-LT" <> 0 then
                            AvgDays := TotalDays / "TotalQuantity-LT"
                        else
                            AvgDays := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Invoiced Quantity", '<>0');
                        TotalDays := 0;
                        "TotalQuantity-LT" := 0;
                    end;
                }
            }
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
                    field(OnlyOnePerPage; OnlyOnePerPage)
                    {
                        ApplicationArea = Suite;
                        Caption = 'New Page per Account';
                        ToolTip = 'Specifies if you want to print each account on a separate page. Each account will begin at the top of the following page. Otherwise, each account will follow the previous account on the current page.';
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
        FilterString := "Salesperson/Purchaser".GetFilters();
        FilterString2 := Vendor.GetFilters();
        FilterString3 := "Value Entry".GetFilters();
    end;

    var
        FilterString: Text;
        FilterString2: Text;
        FilterString3: Text;
        OnlyOnePerPage: Boolean;
        TotalDays: Decimal;
        "TotalQuantity-LT": Decimal;
        AvgDays: Decimal;
        AvgCost: Decimal;
        AverageCostACY: Decimal;
        Item: Record Item;
        CompanyInformation: Record "Company Information";
        PurchInvHeader: Record "Purch. Inv. Header";
        ItemCostMgt: Codeunit ItemCostManagement;
        Vendor_Item_Statistics_by_PurchaserCaptionLbl: Label 'Vendor/Item Statistics by Purchaser';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Salesperson_Purchaser_CodeCaptionLbl: Label 'Purchaser';
        Salesperson_Purchaser_NameCaptionLbl: Label 'Purchaser Name';
        Vendor__No__CaptionLbl: Label 'Vendor';
        Vendor_NameCaptionLbl: Label 'Vendor Name';
        Value_Entry__Item_No__CaptionLbl: Label 'Item';
        Item_DescriptionCaptionLbl: Label 'Item Description';
        Value_Entry__Invoiced_Quantity_CaptionLbl: Label 'Quantity';
        AmountCaptionLbl: Label 'Amount';
        AvgCostCaptionLbl: Label 'Average Cost';
        AvgDaysCaptionLbl: Label 'Average Lead Time';
        Item__Base_Unit_of_Measure_CaptionLbl: Label 'Unit';
        Report_TotalsCaptionLbl: Label 'Report Totals';
        Phone_CaptionLbl: Label 'Phone:';
        Contact_CaptionLbl: Label 'Contact:';
        Purchaser_TotalsCaptionLbl: Label 'Purchaser Totals';
        Vendor_TotalsCaptionLbl: Label 'Vendor Totals';
}


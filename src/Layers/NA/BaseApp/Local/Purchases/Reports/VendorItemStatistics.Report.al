// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;

report 10113 "Vendor/Item Statistics"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorItemStatistics.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor/Item Statistics';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Vendor Posting Group";
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
            column(OnlyOnePerPage; OnlyOnePerPage)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(Vendor_TABLECAPTION__________FilterString; Vendor.TableCaption + ': ' + FilterString)
            {
            }
            column(Value_Entry__TABLECAPTION__________FilterString2; "Value Entry".TableCaption + ': ' + FilterString2)
            {
            }
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
            column(Value_Entry___Purchase_Amount__Actual__; "Value Entry"."Purchase Amount (Actual)")
            {
            }
            column(Value_Entry___Discount_Amount_; "Value Entry"."Discount Amount")
            {
            }
            column(Vendor_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Vendor_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Vendor___Item_StatisticsCaption; Vendor___Item_StatisticsCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Vendor__No__Caption; Vendor__No__CaptionLbl)
            {
            }
            column(Vendor_NameCaption; FieldCaption(Name))
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
            column(Value_Entry__Purchase_Amount__Actual__Caption; "Value Entry".FieldCaption("Purchase Amount (Actual)"))
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
            column(Phone_Caption; Phone_CaptionLbl)
            {
            }
            column(Contact_Caption; Contact_CaptionLbl)
            {
            }
            column(Report_TotalCaption; Report_TotalCaptionLbl)
            {
            }
            dataitem("Value Entry"; "Value Entry")
            {
                DataItemLink = "Source No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter");
                DataItemTableView = sorting("Source Type", "Source No.", "Item Ledger Entry Type", "Item No.", "Posting Date") where("Source Type" = const(Vendor), "Item Ledger Entry Type" = const(Purchase));
                RequestFilterFields = "Item No.", "Inventory Posting Group", "Posting Date";
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
                column(TotalDays; TotalDays)
                {
                }
                column(Value_Entry__Purchase_Amount__Actual___Control38; "Purchase Amount (Actual)")
                {
                }
                column(Value_Entry__Discount_Amount__Control39; "Discount Amount")
                {
                }
                column(Vendor__No___Control37; Vendor."No.")
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
                column(Vendor_TotalCaption; Vendor_TotalCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    PurchInvHeader.SetRange("Posting Date", "Posting Date");
                    PurchInvHeader.SetRange("Vendor Invoice No.", "External Document No.");
                    if PurchInvHeader.FindFirst() then
                        if PurchInvHeader."Order Date" > 0D then
                            TotalDays := ("Posting Date" - PurchInvHeader."Order Date") * "Invoiced Quantity";

                    if not Item.Get("Item No.") then begin
                        Item.Description := 'Others';
                        Item."Base Unit of Measure" := '';
                    end;
                    if "Invoiced Quantity" <> 0 then begin
                        ItemCostMgt.CalculateAverageCost(Item, AvgCost, AverageCostACY);
                        AvgCost := Round(AvgCost, 0.00001);
                    end else
                        AvgCost := 0;
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Invoiced Quantity", '<>0');
                    PurchInvHeader.SetCurrentKey("Vendor Invoice No.", "Posting Date");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if OnlyOnePerPage then
                    PageGroupNo := PageGroupNo + 1;
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
                    field(OnlyOnePerPage; OnlyOnePerPage)
                    {
                        ApplicationArea = Basic, Suite;
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
        FilterString := Vendor.GetFilters();
        FilterString2 := "Value Entry".GetFilters();
    end;

    var
        FilterString: Text;
        FilterString2: Text;
        OnlyOnePerPage: Boolean;
        TotalDays: Decimal;
        AvgCost: Decimal;
        AvgDays: Decimal;
        AverageCostACY: Decimal;
        Item: Record Item;
        CompanyInformation: Record "Company Information";
        PurchInvHeader: Record "Purch. Inv. Header";
        PageGroupNo: Integer;
        ItemCostMgt: Codeunit ItemCostManagement;
        Vendor___Item_StatisticsCaptionLbl: Label 'Vendor / Item Statistics';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Vendor__No__CaptionLbl: Label 'Vendor';
        Value_Entry__Item_No__CaptionLbl: Label 'Item';
        Item_DescriptionCaptionLbl: Label 'Description';
        Value_Entry__Invoiced_Quantity_CaptionLbl: Label 'Quantity';
        AvgCostCaptionLbl: Label 'Average Cost';
        AvgDaysCaptionLbl: Label 'Lead Time';
        Item__Base_Unit_of_Measure_CaptionLbl: Label 'Unit';
        Phone_CaptionLbl: Label 'Phone:';
        Contact_CaptionLbl: Label 'Contact:';
        Report_TotalCaptionLbl: Label 'Report Total';
        Vendor_TotalCaptionLbl: Label 'Vendor Total';
}


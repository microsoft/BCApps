// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.CRM.Team;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

report 10091 "Item Statistics by Purchaser"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/ItemStatisticsbyPurchaser.rdlc';
    ApplicationArea = Suite;
    Caption = 'Item Statistics by Purchaser';
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
            column(Salesperson_Purchaser__TABLECAPTION__________FilterString; "Salesperson/Purchaser".TableCaption + ': ' + FilterString)
            {
            }
            column(FilterString; FilterString)
            {
            }
            column(Value_Entry__TABLECAPTION__________FilterString2; "Value Entry".TableCaption + ': ' + FilterString2)
            {
            }
            column(FilterString2; FilterString2)
            {
            }
            column(Salesperson_Purchaser_Code; Code)
            {
            }
            column(Salesperson_Purchaser_Name; Name)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(OnlyOnePerPage; OnlyOnePerPage)
            {
            }
            column(Value_Entry___Cost_Amount__Actual__; "Value Entry"."Cost Amount (Actual)")
            {
            }
            column(Value_Entry___Discount_Amount_; "Value Entry"."Discount Amount")
            {
            }
            column(Item_Statistics_by_PurchaserCaption; Item_Statistics_by_PurchaserCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Salesperson_Purchaser_CodeCaption; Salesperson_Purchaser_CodeCaptionLbl)
            {
            }
            column(Salesperson_Purchaser_NameCaption; FieldCaption(Name))
            {
            }
            column(Value_Entry__Item_No__Caption; Value_Entry__Item_No__CaptionLbl)
            {
            }
            column(Item_DescriptionCaption; Item_DescriptionCaptionLbl)
            {
            }
            column(Value_Entry__Invoiced_Quantity_Caption; "Value Entry".FieldCaption("Invoiced Quantity"))
            {
            }
            column(Value_Entry__Cost_Amount__Actual__Caption; "Value Entry".FieldCaption("Cost Amount (Actual)"))
            {
            }
            column(Value_Entry__Discount_Amount_Caption; "Value Entry".FieldCaption("Discount Amount"))
            {
            }
            column(AverageCostCaption; AverageCostCaptionLbl)
            {
            }
            column(Item__Base_Unit_of_Measure_Caption; Item__Base_Unit_of_Measure_CaptionLbl)
            {
            }
            column(Item__Lead_Time_Calculation_Caption; Item__Lead_Time_Calculation_CaptionLbl)
            {
            }
            column(Report_TotalsCaption; Report_TotalsCaptionLbl)
            {
            }
            dataitem("Value Entry"; "Value Entry")
            {
                DataItemLink = "Salespers./Purch. Code" = field(Code);
                DataItemTableView = sorting("Item No.", "Posting Date", "Item Ledger Entry Type", "Entry Type", "Variance Type", "Item Charge No.", "Location Code", "Variant Code") where("Source Type" = const(Vendor), "Item Ledger Entry Type" = const(Purchase));
                RequestFilterFields = "Item No.", "Posting Date";
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
                column(Value_Entry__Cost_Amount__Actual__; "Cost Amount (Actual)")
                {
                }
                column(Value_Entry__Discount_Amount_; "Discount Amount")
                {
                }
                column(AverageCost; AverageCost)
                {
                }
                column(Item__Lead_Time_Calculation_; Item."Lead Time Calculation")
                {
                }
                column(Value_Entry__Cost_Amount__Actual___Control32; "Cost Amount (Actual)")
                {
                }
                column(Value_Entry__Discount_Amount__Control33; "Discount Amount")
                {
                }
                column(Salesperson_Purchaser__Code; "Salesperson/Purchaser".Code)
                {
                }
                column(Value_Entry_Entry_No_; "Entry No.")
                {
                }
                column(Value_Entry_Salespers__Purch__Code; "Salespers./Purch. Code")
                {
                }
                column(Purchaser_TotalsCaption; Purchaser_TotalsCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not Item.Get("Item No.") then begin
                        Item.Description := 'Others';
                        Item."Base Unit of Measure" := '';
                        AverageCost := 0.0;
                    end else begin
                        if "Invoiced Quantity" = 0 then
                            AverageCost := 0.0
                        else
                            AverageCost := "Cost Amount (Actual)" / "Invoiced Quantity";
                        AverageCost := Round(AverageCost, 0.00001);
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    /* Programmer's note:  This report's performance will improve if you
                      add the key below to the Value Entry table; no SumIndexFields necessary.         */
                    if not SetCurrentKey("Source Type", "Salespers./Purch. Code", "Item Ledger Entry Type", "Item No.") then
                        SetCurrentKey("Item No.", "Posting Date", "Item Ledger Entry Type");
                    SetFilter("Invoiced Quantity", '<>0');

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
        FilterString2 := "Value Entry".GetFilters();
    end;

    var
        FilterString: Text;
        FilterString2: Text;
        OnlyOnePerPage: Boolean;
        Item: Record Item;
        CompanyInformation: Record "Company Information";
        AverageCost: Decimal;
        PageGroupNo: Integer;
        Item_Statistics_by_PurchaserCaptionLbl: Label 'Item Statistics by Purchaser';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Salesperson_Purchaser_CodeCaptionLbl: Label 'Purchaser';
        Value_Entry__Item_No__CaptionLbl: Label 'Item';
        Item_DescriptionCaptionLbl: Label 'Description';
        AverageCostCaptionLbl: Label 'Average Cost';
        Item__Base_Unit_of_Measure_CaptionLbl: Label 'Unit';
        Item__Lead_Time_Calculation_CaptionLbl: Label 'Lead Time';
        Report_TotalsCaptionLbl: Label 'Report Totals';
        Purchaser_TotalsCaptionLbl: Label 'Purchaser Totals';
}


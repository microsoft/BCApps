// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.IO;

report 10142 "Item Cost and Price List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/ItemCostandPriceList.rdlc';
    Caption = 'Item Cost and Price List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Search Description", "Inventory Posting Group";
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
            column(UseSKU; UseSKU)
            {
            }
            column(PrintToExcel; PrintToExcel)
            {
            }
            column(StockkeepingUnitExist; StockkeepingUnitExist)
            {
            }
            column(TLGrouping; TLGrouping)
            {
            }
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(FIELDCAPTION__Inventory_Posting_Group_____________Inventory_Posting_Group_; FieldCaption("Inventory Posting Group") + ': ' + "Inventory Posting Group")
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(Item_Description; Description)
            {
            }
            column(AvgCost; AvgCost)
            {
            }
            column(Item__Standard_Cost_; "Standard Cost")
            {
            }
            column(Item__Last_Direct_Cost_; "Last Direct Cost")
            {
            }
            column(Item__Unit_Price_; "Unit Price")
            {
            }
            column(Item__Base_Unit_of_Measure_; "Base Unit of Measure")
            {
            }
            column(Item__Unit_Price__Control1480000; "Unit Price")
            {
            }
            column(AvgCost_Control1480001; AvgCost)
            {
            }
            column(Item__Last_Direct_Cost__Control1480002; "Last Direct Cost")
            {
            }
            column(Item__Standard_Cost__Control1480003; "Standard Cost")
            {
            }
            column(Item__Base_Unit_of_Measure__Control1480005; "Base Unit of Measure")
            {
            }
            column(Item_Description_Control1480006; Description)
            {
            }
            column(Item__No___Control1480007; "No.")
            {
            }
            column(Item_Inventory_Posting_Group; "Inventory Posting Group")
            {
            }
            column(Item_Location_Filter; "Location Filter")
            {
            }
            column(Item_Variant_Filter; "Variant Filter")
            {
            }
            column(Item_Cost_and_Price_ListCaption; Item_Cost_and_Price_ListCaptionLbl)
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
            column(AvgCostCaption; AvgCostCaptionLbl)
            {
            }
            column(Item__Standard_Cost_Caption; FieldCaption("Standard Cost"))
            {
            }
            column(Item__Last_Direct_Cost_Caption; FieldCaption("Last Direct Cost"))
            {
            }
            column(Item__Unit_Price_Caption; FieldCaption("Unit Price"))
            {
            }
            column(Item__Unit_Price__Control1480000Caption; FieldCaption("Unit Price"))
            {
            }
            column(AvgCost_Control1480001Caption; AvgCost_Control1480001CaptionLbl)
            {
            }
            column(Item__Last_Direct_Cost__Control1480002Caption; FieldCaption("Last Direct Cost"))
            {
            }
            column(Item__Standard_Cost__Control1480003Caption; FieldCaption("Standard Cost"))
            {
            }
            column(Item__Base_Unit_of_Measure__Control1480005Caption; FieldCaption("Base Unit of Measure"))
            {
            }
            column(Item_Description_Control1480006Caption; FieldCaption(Description))
            {
            }
            column(Item__No___Control1480007Caption; FieldCaption("No."))
            {
            }
            column(Stockkeeping_Unit__Location_Code_Caption; "Stockkeeping Unit".FieldCaption("Location Code"))
            {
            }
            column(Stockkeeping_Unit__Variant_Code_Caption; "Stockkeeping Unit".FieldCaption("Variant Code"))
            {
            }
            dataitem("Stockkeeping Unit"; "Stockkeeping Unit")
            {
                DataItemLink = "Item No." = field("No."), "Location Code" = field("Location Filter"), "Variant Code" = field("Variant Filter");
                DataItemTableView = sorting("Item No.", "Location Code", "Variant Code");
                column(Stockkeeping_Unit__Item_No__; "Item No.")
                {
                }
                column(Stockkeeping_Unit__Location_Code_; "Location Code")
                {
                }
                column(Stockkeeping_Unit__Variant_Code_; "Variant Code")
                {
                }
                column(Stockkeeping_Unit_Description; Description)
                {
                }
                column(Stockkeeping_Unit__Standard_Cost_; "Standard Cost")
                {
                }
                column(Stockkeeping_Unit__Last_Direct_Cost_; "Last Direct Cost")
                {
                }
                column(Item__Base_Unit_of_Measure__Control1480030; Item."Base Unit of Measure")
                {
                }
                column(AvgCost_Control1480031; AvgCost)
                {
                }
                column(Item__Unit_Price__Control1480032; Item."Unit Price")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Item2 := Item;
                    Item2.Reset();
                    if "Location Code" <> '' then
                        Item2.SetRange("Location Filter", "Location Code");
                    if "Variant Code" <> '' then
                        Item2.SetRange("Variant Filter", "Variant Code");
                    Item.CopyFilter("Date Filter", Item2."Date Filter");
                    ItemCostMgmt.CalculateAverageCost(Item2, AvgCost, AvgCostACY);
                    CalcFields(Description);
                    if PrintToExcel then
                        MakeExcelDataBody();
                end;

                trigger OnPreDataItem()
                begin
                    if not UseSKU then
                        CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CalcFields("Stockkeeping Unit Exists");
                StockkeepingUnitExist := "Stockkeeping Unit Exists";
                if (not UseSKU) or (not "Stockkeeping Unit Exists") then
                    ItemCostMgmt.CalculateAverageCost(Item, AvgCost, AvgCostACY);

                if PrintToExcel and not (UseSKU and "Stockkeeping Unit Exists") then
                    MakeExcelDataBody();
            end;

            trigger OnPreDataItem()
            begin
                if StrPos(CurrentKey, FieldCaption("Inventory Posting Group")) = 0 then
                    TLGrouping := false
                else
                    TLGrouping := true;
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
                    field(UseSKU; UseSKU)
                    {
                        Caption = 'Use Stockkeeping Unit';
                        ToolTip = 'Specifies if you want to only include items that are set up as SKUs. This adds SKU-related fields, such as the Location Code, Variant Code, and Qty. in Transit fields, to the report.';
                    }
                    field(PrintToExcel; PrintToExcel)
                    {
                        Caption = 'Print to Excel';
                        ToolTip = 'Specifies if you want to export the data to an Excel spreadsheet for additional analysis or formatting before printing.';
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

    trigger OnPostReport()
    begin
        if PrintToExcel then
            CreateExcelbook();
    end;

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        ItemFilter := Item.GetFilters();

        ExcelDataHeaderPrinted := false;
        InvPostingGroupUsed := false;
        if PrintToExcel then
            MakeExcelInfo();
    end;

    var
        CompanyInformation: Record "Company Information";
        Item2: Record Item;
        ExcelBuf: Record "Excel Buffer" temporary;
        ItemCostMgmt: Codeunit ItemCostManagement;
        ItemFilter: Text;
        AvgCost: Decimal;
        AvgCostACY: Decimal;
        UseSKU: Boolean;
        PrintToExcel: Boolean;
        Text001: Label 'Data';
        Text002: Label 'Item Cost and Price List';
        Text003: Label 'Company Name';
        Text004: Label 'Report No.';
        Text005: Label 'Report Name';
        Text006: Label 'User ID';
        Text007: Label 'Date / Time';
        Text008: Label 'Item Filters';
        Text009: Label 'Average Cost';
        InvPostingGroupUsed: Boolean;
        ExcelDataHeaderPrinted: Boolean;
        StockkeepingUnitExist: Boolean;
        TLGrouping: Boolean;
        Item_Cost_and_Price_ListCaptionLbl: Label 'Item Cost and Price List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        AvgCostCaptionLbl: Label 'Average Cost';
        AvgCost_Control1480001CaptionLbl: Label 'Average Cost';

    local procedure MakeExcelInfo()
    begin
        ExcelBuf.SetUseInfoSheet();
        ExcelBuf.AddInfoColumn(Format(Text003), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(CompanyInformation.Name, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text005), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(Format(Text002), false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text004), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(REPORT::"Item Cost and Price List", false, false, false, false, '', ExcelBuf."Cell Type"::Number);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text006), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(UserId, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text007), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(Today, false, false, false, false, '', ExcelBuf."Cell Type"::Date);
        ExcelBuf.AddInfoColumn(Time, false, false, false, false, '', ExcelBuf."Cell Type"::Time);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text008), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(ItemFilter, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.ClearNewRow();
    end;

    local procedure MakeExcelDataHeader()
    begin
        ExcelBuf.NewRow();
        if InvPostingGroupUsed then
            ExcelBuf.AddColumn(Item.FieldCaption("Inventory Posting Group"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("Stockkeeping Unit".FieldCaption("Item No."), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        if UseSKU then begin
            ExcelBuf.AddColumn("Stockkeeping Unit".FieldCaption("Location Code"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
            ExcelBuf.AddColumn("Stockkeeping Unit".FieldCaption("Variant Code"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        end;
        ExcelBuf.AddColumn(Item.FieldCaption(Description), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Item.FieldCaption("Base Unit of Measure"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Item.FieldCaption("Standard Cost"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Item.FieldCaption("Last Direct Cost"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Format(Text009), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Item.FieldCaption("Unit Price"), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelDataHeaderPrinted := true;
    end;

    local procedure MakeExcelDataBody()
    begin
        if not ExcelDataHeaderPrinted then
            MakeExcelDataHeader();

        ExcelBuf.NewRow();
        if InvPostingGroupUsed then
            ExcelBuf.AddColumn(Item."Inventory Posting Group", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Item."No.", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        if UseSKU then
            if Item."Stockkeeping Unit Exists" then begin
                ExcelBuf.AddColumn("Stockkeeping Unit"."Location Code", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                ExcelBuf.AddColumn("Stockkeeping Unit"."Variant Code", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
            end else begin
                ExcelBuf.AddColumn('', false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                ExcelBuf.AddColumn('', false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
            end;
        if UseSKU and Item."Stockkeeping Unit Exists" then begin
            ExcelBuf.AddColumn("Stockkeeping Unit".Description, false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
            ExcelBuf.AddColumn(Item."Base Unit of Measure", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
            ExcelBuf.AddColumn("Stockkeeping Unit"."Standard Cost", false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
            ExcelBuf.AddColumn("Stockkeeping Unit"."Last Direct Cost", false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
        end else begin
            ExcelBuf.AddColumn(Item.Description, false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
            ExcelBuf.AddColumn(Item."Base Unit of Measure", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
            ExcelBuf.AddColumn(Item."Standard Cost", false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
            ExcelBuf.AddColumn(Item."Last Direct Cost", false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
        end;
        ExcelBuf.AddColumn(AvgCost, false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
        ExcelBuf.AddColumn(Item."Unit Price", false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
    end;

    local procedure CreateExcelbook()
    begin
        ExcelBuf.CreateBookAndOpenExcel('', Text001, Text002, CompanyName, UserId);
        Error('');
    end;
}


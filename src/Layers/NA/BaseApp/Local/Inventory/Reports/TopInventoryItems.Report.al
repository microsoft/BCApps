// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Utilities;
using System.IO;
using System.Utilities;

report 10162 "Top __ Inventory Items"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/TopInventoryItems.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Top __ Inventory Items';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Inventory Posting Group", "Date Filter", "Location Filter", "Base Unit of Measure";
            column(MainTitle; MainTitle)
            {
            }
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
            column(Item_TABLECAPTION__________ItemFilter; Item.TableCaption + ': ' + ItemFilter)
            {
            }
            column(ColHead; ColHead)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(PrintToExcel; PrintToExcel)
            {
            }
            column(Item_No_; "No.")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Integer_NumberCaption; Integer_NumberCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(Top__Caption; Top__CaptionLbl)
            {
            }
            column(TopNo_Number_Caption; TopNo_Number_CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
                CalcFields("Sales (LCY)", "Net Change");
                TopSale[NextTopLineNo] := "Sales (LCY)";
                TopQty[NextTopLineNo] := "Net Change";
                ValueEntry.Reset();
                if (Item.GetFilter("Global Dimension 1 Filter") <> '') or
                   (Item.GetFilter("Global Dimension 2 Filter") <> '')
                then
                    ValueEntry.SetCurrentKey(
                      "Item No.", "Posting Date", "Item Ledger Entry Type", "Entry Type",
                      "Variance Type", "Item Charge No.", "Location Code", "Variant Code",
                      "Global Dimension 1 Code", "Global Dimension 2 Code")
                else
                    ValueEntry.SetCurrentKey(
                      "Item No.", "Posting Date", "Item Ledger Entry Type", "Entry Type",
                      "Variance Type", "Item Charge No.", "Location Code", "Variant Code");
                ValueEntry.SetRange("Item No.", Item."No.");
                Item.CopyFilter("Location Filter", ValueEntry."Location Code");
                Item.CopyFilter("Variant Filter", ValueEntry."Variant Code");
                Item.CopyFilter("Global Dimension 1 Filter", ValueEntry."Global Dimension 1 Code");
                Item.CopyFilter("Global Dimension 2 Filter", ValueEntry."Global Dimension 2 Code");
                Item.CopyFilter("Date Filter", ValueEntry."Posting Date");
                ValueEntry.CalcSums("Cost Amount (Actual)");
                TopValue[NextTopLineNo] := ValueEntry."Cost Amount (Actual)";
                case TopType of
                    TopType::Sales:
                        TopAmount[NextTopLineNo] := TopSale[NextTopLineNo];
                    TopType::"Qty on Hand":
                        TopAmount[NextTopLineNo] := TopQty[NextTopLineNo];
                    TopType::"Inventory Value":
                        TopAmount[NextTopLineNo] := TopValue[NextTopLineNo];
                end;
                if (TopAmount[NextTopLineNo] = 0) and not PrintAlsoIfZero then
                    CurrReport.Skip();
                GrandTotal := GrandTotal + TopAmount[NextTopLineNo];
                GrandTotalSale := GrandTotalSale + TopSale[NextTopLineNo];
                GrandTotalQty := GrandTotalQty + TopQty[NextTopLineNo];
                GrandTotalValue := GrandTotalValue + TopValue[NextTopLineNo];
                TopNo[NextTopLineNo] := "No.";
                TopName[NextTopLineNo] := Description;
                i := NextTopLineNo;
                if NextTopLineNo < (ItemsToRank + 1) then
                    NextTopLineNo := NextTopLineNo + 1;
                while i > 1 do begin
                    i := i - 1;
                    if TopSorting = TopSorting::Largest then begin
                        if TopAmount[i + 1] > TopAmount[i] then
                            Interchange(i);
                    end else
                        if TopAmount[i + 1] < TopAmount[i] then
                            Interchange(i);
                end;
            end;

            trigger OnPreDataItem()
            begin
                if ItemsToRank = 0 then // defaults to 20 if no amount entered
                    ItemsToRank := 20;
                MainTitle := StrSubstNo(Text000, ItemsToRank);
                if TopSorting = TopSorting::Largest then
                    SubTitle := Text001
                else
                    SubTitle := Text002;
                case TopType of
                    TopType::Sales:
                        begin
                            SubTitle := SubTitle + ' ' + Text003;
                            if GetFilter("Date Filter") <> '' then
                                SubTitle := SubTitle + ' ' + Text006 + ' ' + GetFilter("Date Filter");
                            ColHead := Text008;
                        end;
                    TopType::"Inventory Value":
                        begin
                            SubTitle := SubTitle + ' ' + Text004;
                            if GetFilter("Date Filter") <> '' then begin
                                /* readjust filter so it is correct */
                                TempDate := GetRangeMax("Date Filter");
                                SetRange("Date Filter", 0D, TempDate);
                                SubTitle := SubTitle + ' ' + StrSubstNo(Text007, TempDate);
                            end;
                            ColHead := Text009;
                        end;
                    TopType::"Qty on Hand":
                        begin
                            SubTitle := SubTitle + ' ' + Text005;
                            if GetFilter("Date Filter") <> '' then begin
                                /* readjust filter so it is correct */
                                TempDate := GetRangeMax("Date Filter");
                                SetRange("Date Filter", 0D, TempDate);
                                SubTitle := SubTitle + ' ' + StrSubstNo(Text007, TempDate);
                            end;
                            ColHead := Text010;
                        end;
                end;
                NextTopLineNo := 1;
                Window.Open(Text011);

                if PrintToExcel then
                    MakeExcelInfo();

            end;
        }
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 99;
            column(Integer_Number; Number)
            {
            }
            column(TopNo_Number_; TopNo[Number])
            {
            }
            column(TopName_Number_; TopName[Number])
            {
            }
            column(Top__; "Top%")
            {
                DecimalPlaces = 1 : 1;
            }
            column(TopAmount_Number_; TopAmount[Number])
            {
            }
            column(BarText; BarText)
            {
            }
            column(BarTextNNC; BarTextNNC)
            {
            }
            column(STRSUBSTNO_Text013_ItemsToRank_TopTotalText_; StrSubstNo(Text013, ItemsToRank, TopTotalText))
            {
            }
            column(Top___Control22; "Top%")
            {
                DecimalPlaces = 1 : 1;
            }
            column(TopTotal; TopTotal)
            {
            }
            column(V100_0____Top__; 100.0 - "Top%")
            {
                DecimalPlaces = 1 : 1;
            }
            column(GrandTotal___TopTotal; GrandTotal - TopTotal)
            {
            }
            column(STRSUBSTNO_Text014_TopTotalText_; StrSubstNo(Text014, TopTotalText))
            {
            }
            column(GrandTotal; GrandTotal)
            {
            }
            column(All_other_itemsCaption; All_other_itemsCaptionLbl)
            {
            }
            column(V100_0Caption; V100_0CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                TopTotal := TopTotal + TopAmount[Number];
                TopTotalSale := TopTotalSale + TopSale[Number];
                TopTotalQty := TopTotalQty + TopQty[Number];
                TopTotalValue := TopTotalValue + TopValue[Number];
                if (TopScale > 0) and (TopAmount[Number] > 0) then
                    BarText :=
                      ParagraphHandling.PadStrProportional(
                        '', Round(TopAmount[Number] / TopScale * 61, 1), 7, '|')
                else
                    BarText := '';
                if GrandTotal <> 0 then
                    "Top%" := Round(TopAmount[Number] / GrandTotal * 100, 0.1)
                else
                    "Top%" := 0;

                if (TopScale > 0) and (TopAmount[Number] > 0) then
                    BarTextNNC := Round(TopAmount[Number] / TopScale * 100, 1)
                else
                    BarTextNNC := 0;

                case TopType of
                    TopType::Sales:
                        TopTotalText := Text008;
                    TopType::"Inventory Value":
                        TopTotalText := Text009;
                    TopType::"Qty on Hand":
                        TopTotalText := Text010;
                end;

                if PrintToExcel then
                    MakeExcelDataBody();
            end;

            trigger OnPostDataItem()
            begin
                if PrintToExcel then
                    if (GrandTotalValue <> TopTotalValue) or
                       (GrandTotalQty <> TopTotalQty) or
                       (GrandTotalSale <> TopTotalSale)
                    then begin
                        if GrandTotal <> 0 then
                            "Top%" := Round(TopTotal / GrandTotal * 100, 0.1)
                        else
                            "Top%" := 0;
                        ExcelBuf.NewRow();
                        ExcelBuf.AddColumn('', false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                        ExcelBuf.AddColumn(Format(Text115), false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                        ExcelBuf.AddColumn(GrandTotalSale - TopTotalSale, false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
                        ExcelBuf.AddColumn(GrandTotalQty - TopTotalQty, false, '', false, false, false, '', ExcelBuf."Cell Type"::Number);
                        ExcelBuf.AddColumn(GrandTotalValue - TopTotalValue, false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
                        ExcelBuf.AddColumn((100 - "Top%") / 100, false, '', false, false, false, '0.0%', ExcelBuf."Cell Type"::Number);
                    end;
            end;

            trigger OnPreDataItem()
            begin
                Window.Close();
                SetRange(Number, 1, NextTopLineNo - 1);
                if TopSorting = TopSorting::Largest then
                    TopScale := TopAmount[1]
                else
                    if NextTopLineNo > 1 then
                        TopScale := TopAmount[NextTopLineNo - 1]
                    else
                        TopScale := 0;
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
                    field(TopSorting; TopSorting)
                    {
                        Caption = 'Show';
                        OptionCaption = 'Largest,Smallest';
                        ToolTip = 'Specifies which accounts to include. All Accounts: Includes all accounts with transactions. Accounts with Balances: Includes accounts with balances. Accounts with Activity: Includes accounts that are currently active.';
                    }
                    field(TopType; TopType)
                    {
                        Caption = 'Amounts to Show';
                        OptionCaption = 'Sales,Qty on Hand,Inventory Value';
                        ToolTip = 'Specifies which amounts are shown. Select Sales to list the items by sales amounts. Select Qty on Hand to list items by quantity on hand. Select Inventory Value to list the items by their value.';
                    }
                    field(PrintAlsoIfZero; PrintAlsoIfZero)
                    {
                        Caption = 'Including Zero Amounts';
                        ToolTip = 'Specifies if you want to include items that have no sales or a quantity of zero. ';
                    }
                    field(ItemsToRank; ItemsToRank)
                    {
                        Caption = 'Number of Items to Rank';
                        MaxValue = 99;
                        MinValue = 0;
                        ToolTip = 'Specifies the number of items that will be listed. You can enter from 1 to 99.';
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

        trigger OnClosePage()
        begin
            if ItemsToRank > 99 then
                Error(Text012);
        end;
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
        /* temporarily remove date filter, since it will show in the header anyway */
        Item.SetRange("Date Filter");
        ItemFilter := Item.GetFilters();

    end;

    var
        ValueEntry: Record "Value Entry";
        CompanyInformation: Record "Company Information";
        ExcelBuf: Record "Excel Buffer" temporary;
        ItemFilter: Text;
        MainTitle: Text;
        SubTitle: Text;
        ColHead: Text[20];
        TempDate: Date;
        TopTotalText: Text[40];
        BarText: Text[250];
        TopName: array[100] of Text[100];
        TopNo: array[100] of Code[20];
        TopAmount: array[100] of Decimal;
        TopQty: array[100] of Decimal;
        TopSale: array[100] of Decimal;
        TopValue: array[100] of Decimal;
        TopScale: Decimal;
        TopTotal: Decimal;
        TopTotalQty: Decimal;
        TopTotalSale: Decimal;
        TopTotalValue: Decimal;
        GrandTotal: Decimal;
        GrandTotalQty: Decimal;
        GrandTotalSale: Decimal;
        GrandTotalValue: Decimal;
        "Top%": Decimal;
        NextTopLineNo: Integer;
        ItemsToRank: Integer;
        i: Integer;
        TopType: Option Sales,"Qty on Hand","Inventory Value";
        TopSorting: Option Largest,Smallest;
        PrintAlsoIfZero: Boolean;
        Window: Dialog;
        ParagraphHandling: Codeunit "Paragraph Handling";
        Text000: Label 'Top %1 Inventory Items';
        Text001: Label 'Largest';
        Text002: Label 'Smallest';
        Text003: Label 'sales';
        Text004: Label 'inventory value';
        Text005: Label 'quantity on hand';
        Text006: Label 'during the period';
        Text007: Label 'on %1';
        Text008: Label 'Sales';
        Text009: Label 'Inventory Value';
        Text010: Label 'Quantity on Hand';
        Text011: Label 'Sorting items    #1##################';
        Text012: Label 'Number of Items must be less than %1';
        Text013: Label 'Top %1 Total %2';
        Text014: Label 'Total %1';
        PrintToExcel: Boolean;
        Text101: Label 'Data';
        Text103: Label 'Company Name';
        Text104: Label 'Report No.';
        Text105: Label 'Report Name';
        Text106: Label 'User ID';
        Text107: Label 'Date / Time';
        Text108: Label 'Subtitle';
        Text109: Label 'Item Filters';
        Text112: Label 'Percent of Total Sales';
        Text113: Label 'Percent of Total Inventory Value';
        Text114: Label 'Percent of Total Quantity on Hand';
        Text115: Label 'All other inventory items';
        BarTextNNC: Integer;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Integer_NumberCaptionLbl: Label 'Rank';
        DescriptionCaptionLbl: Label 'Description';
        Top__CaptionLbl: Label '% of Total';
        TopNo_Number_CaptionLbl: Label 'Item No.';
        All_other_itemsCaptionLbl: Label 'All other items';
        V100_0CaptionLbl: Label '100.0';

    procedure Interchange(i: Integer)
    begin
        SwapCode(TopNo, i);
        SwapText(TopName, i);
        SwapAmt(TopAmount, i);
        SwapAmt(TopQty, i);
        SwapAmt(TopValue, i);
        SwapAmt(TopSale, i);
    end;

    local procedure MakeExcelInfo()
    begin
        ExcelBuf.SetUseInfoSheet();
        ExcelBuf.AddInfoColumn(Format(Text103), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(CompanyInformation.Name, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text105), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(Format(MainTitle), false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text104), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(REPORT::"Top __ Inventory Items", false, false, false, false, '', ExcelBuf."Cell Type"::Number);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text106), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(UserId, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text107), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(Today, false, false, false, false, '', ExcelBuf."Cell Type"::Date);
        ExcelBuf.AddInfoColumn(Time, false, false, false, false, '', ExcelBuf."Cell Type"::Time);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text108), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(SubTitle, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text109), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(ItemFilter, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.ClearNewRow();
        MakeExcelDataHeader();
    end;

    local procedure MakeExcelDataHeader()
    begin
        ExcelBuf.NewRow();
        ExcelBuf.AddColumn(
          Item.TableCaption + ' ' + Item.FieldCaption("No."), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Item.FieldCaption(Description), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Format(Text008), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Format(Text010), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(Format(Text009), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        case TopType of
            TopType::Sales:
                ExcelBuf.AddColumn(Format(Text112), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
            TopType::"Qty on Hand":
                ExcelBuf.AddColumn(Format(Text114), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
            TopType::"Inventory Value":
                ExcelBuf.AddColumn(Format(Text113), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        end;
    end;

    local procedure MakeExcelDataBody()
    begin
        ExcelBuf.NewRow();
        ExcelBuf.AddColumn(TopNo[Integer.Number], false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(TopName[Integer.Number], false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn(TopSale[Integer.Number], false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
        ExcelBuf.AddColumn(TopQty[Integer.Number], false, '', false, false, false, '', ExcelBuf."Cell Type"::Number);
        ExcelBuf.AddColumn(TopValue[Integer.Number], false, '', false, false, false, '#,##0.00', ExcelBuf."Cell Type"::Number);
        ExcelBuf.AddColumn("Top%" / 100, false, '', false, false, false, '0.0%', ExcelBuf."Cell Type"::Number);
    end;

    local procedure CreateExcelbook()
    begin
        ExcelBuf.CreateBookAndOpenExcel('', Text101, MainTitle, CompanyName, UserId);
        Error('');
    end;

    local procedure SwapAmt(var AmtArray: array[100] of Decimal; Index: Integer)
    var
        TempAmt: Decimal;
    begin
        TempAmt := AmtArray[Index];
        AmtArray[Index] := AmtArray[Index + 1];
        AmtArray[Index + 1] := TempAmt;
    end;

    local procedure SwapText(var TextArray: array[100] of Text[100]; Index: Integer)
    var
        TempText: Text[100];
    begin
        TempText := TextArray[Index];
        TextArray[Index] := TextArray[Index + 1];
        TextArray[Index + 1] := TempText;
    end;

    local procedure SwapCode(var CodeArray: array[100] of Code[20]; Index: Integer)
    var
        TempCode: Code[20];
    begin
        TempCode := CodeArray[Index];
        CodeArray[Index] := CodeArray[Index + 1];
        CodeArray[Index + 1] := TempCode;
    end;
}


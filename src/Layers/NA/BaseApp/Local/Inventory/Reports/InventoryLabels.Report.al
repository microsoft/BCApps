// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using System.Utilities;

report 10137 "Inventory Labels"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Inventory/Reports/InventoryLabels.rdlc';
    Caption = 'Inventory Labels';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = Suite;

    dataset
    {
        dataitem(Item; Item)
        {
            RequestFilterFields = "No.", "Search Description", "Shelf No.", "Inventory Posting Group";
            column(ItemNo_1_; ItemNo[1])
            {
            }
            column(ItemDescription_1_; ItemDescription[1])
            {
            }
            column(ItemUnit_1_; ItemUnit[1])
            {
            }
            column(ItemShelf_1_; ItemShelf[1])
            {
            }
            column(ColumnNo; ColumnNo)
            {
            }
            column(LabelsPerRow; LabelsPerRow)
            {
            }
            column(Item__No__; Item."No.")
            {
            }
            column(ItemNo_1__Control11; ItemNo[1])
            {
            }
            column(ItemDescription_1__Control13; ItemDescription[1])
            {
            }
            column(ItemUnit_1__Control15; ItemUnit[1])
            {
            }
            column(ItemShelf_1__Control17; ItemShelf[1])
            {
            }
            column(ItemNo_2_; ItemNo[2])
            {
            }
            column(ItemDescription_2_; ItemDescription[2])
            {
            }
            column(ItemUnit_2_; ItemUnit[2])
            {
            }
            column(ItemShelf_2_; ItemShelf[2])
            {
            }
            column(ItemNo_1__Control31; ItemNo[1])
            {
            }
            column(ItemDescription_1__Control33; ItemDescription[1])
            {
            }
            column(ItemUnit_1__Control35; ItemUnit[1])
            {
            }
            column(ItemShelf_1__Control37; ItemShelf[1])
            {
            }
            column(ItemNo_2__Control39; ItemNo[2])
            {
            }
            column(ItemDescription_2__Control41; ItemDescription[2])
            {
            }
            column(ItemUnit_2__Control43; ItemUnit[2])
            {
            }
            column(ItemShelf_2__Control45; ItemShelf[2])
            {
            }
            column(ItemNo_3_; ItemNo[3])
            {
            }
            column(ItemDescription_3_; ItemDescription[3])
            {
            }
            column(ItemUnit_3_; ItemUnit[3])
            {
            }
            column(ItemShelf_3_; ItemShelf[3])
            {
            }
            column(ItemNo_1_Caption; ItemNo_1_CaptionLbl)
            {
            }
            column(ItemDescription_1_Caption; ItemDescription_1_CaptionLbl)
            {
            }
            column(ItemUnit_1_Caption; ItemUnit_1_CaptionLbl)
            {
            }
            column(ItemShelf_1_Caption; ItemShelf_1_CaptionLbl)
            {
            }
            column(ItemNo_1__Control11Caption; ItemNo_1__Control11CaptionLbl)
            {
            }
            column(ItemDescription_1__Control13Caption; ItemDescription_1__Control13CaptionLbl)
            {
            }
            column(ItemUnit_1__Control15Caption; ItemUnit_1__Control15CaptionLbl)
            {
            }
            column(ItemShelf_1__Control17Caption; ItemShelf_1__Control17CaptionLbl)
            {
            }
            column(ItemNo_2_Caption; ItemNo_2_CaptionLbl)
            {
            }
            column(ItemDescription_2_Caption; ItemDescription_2_CaptionLbl)
            {
            }
            column(ItemUnit_2_Caption; ItemUnit_2_CaptionLbl)
            {
            }
            column(ItemShelf_2_Caption; ItemShelf_2_CaptionLbl)
            {
            }
            column(ItemNo_1__Control31Caption; ItemNo_1__Control31CaptionLbl)
            {
            }
            column(ItemDescription_1__Control33Caption; ItemDescription_1__Control33CaptionLbl)
            {
            }
            column(ItemUnit_1__Control35Caption; ItemUnit_1__Control35CaptionLbl)
            {
            }
            column(ItemShelf_1__Control37Caption; ItemShelf_1__Control37CaptionLbl)
            {
            }
            column(ItemNo_2__Control39Caption; ItemNo_2__Control39CaptionLbl)
            {
            }
            column(ItemDescription_2__Control41Caption; ItemDescription_2__Control41CaptionLbl)
            {
            }
            column(ItemUnit_2__Control43Caption; ItemUnit_2__Control43CaptionLbl)
            {
            }
            column(ItemShelf_2__Control45Caption; ItemShelf_2__Control45CaptionLbl)
            {
            }
            column(ItemNo_3_Caption; ItemNo_3_CaptionLbl)
            {
            }
            column(ItemDescription_3_Caption; ItemDescription_3_CaptionLbl)
            {
            }
            column(ItemUnit_3_Caption; ItemUnit_3_CaptionLbl)
            {
            }
            column(ItemShelf_3_Caption; ItemShelf_3_CaptionLbl)
            {
            }
            dataitem(BlankLine; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(BlankLine_Number; Number)
                {
                }

                trigger OnPreDataItem()
                begin
                    if PrintLinesPerLabel <= 4 then
                        CurrReport.Break();
                    SetRange(Number, 1, PrintLinesPerLabel - 4);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ColumnNo := ColumnNo + 1;
                RecordNo := RecordNo + 1;
                ItemNo[ColumnNo] := "No.";
                ItemDescription[ColumnNo] := Description;
                ItemUnit[ColumnNo] := "Base Unit of Measure";
                ItemShelf[ColumnNo] := "Shelf No.";
                if RecordNo = NoRecords then
                    while ColumnNo < LabelsPerRow do begin
                        ColumnNo := ColumnNo + 1;
                        Clear(ItemNo[ColumnNo]);
                        Clear(ItemDescription[ColumnNo]);
                        Clear(ItemUnit[ColumnNo]);
                        Clear(ItemShelf[ColumnNo]);
                    end;
                if ColumnNo = LabelsPerRow then
                    ColumnNo := 0;
            end;

            trigger OnPreDataItem()
            begin
                ColumnNo := 0;
                RecordNo := 0;
                NoRecords := Count;
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
                    field(PrintLinesPerLabel; PrintLinesPerLabel)
                    {
                        ApplicationArea = Suite;
                        Caption = 'No. of print lines per label';
                        MaxValue = 99;
                        MinValue = 4;
                        ToolTip = 'Specifies the height of each label in print lines. Since each print line is .16 inches, you can measure the height of the label (top of one label to the top of the next label) in inches and then multiply the result by 6.';
                    }
                    field(NoOfLabelsPerRow; LabelsPerRow)
                    {
                        ApplicationArea = Suite;
                        Caption = 'No. of labels per row';
                        MaxValue = 3;
                        MinValue = 1;
                        ToolTip = 'Specifies the number of labels across one row of labels.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PrintLinesPerLabel = 0 then
                PrintLinesPerLabel := 6;
            if LabelsPerRow = 0 then
                LabelsPerRow := 1;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if PrintLinesPerLabel < 4 then
            PrintLinesPerLabel := 4;
    end;

    var
        PrintLinesPerLabel: Integer;
        LabelsPerRow: Integer;
        ItemNo: array[3] of Code[20];
        ItemDescription: array[3] of Text;
        ItemUnit: array[3] of Text[10];
        ItemShelf: array[3] of Code[10];
        ColumnNo: Integer;
        RecordNo: Integer;
        NoRecords: Integer;
        ItemNo_1_CaptionLbl: Label 'Inventory Item No.';
        ItemDescription_1_CaptionLbl: Label 'Description';
        ItemUnit_1_CaptionLbl: Label 'Unit of Measure';
        ItemShelf_1_CaptionLbl: Label 'Shelf/Bin No.';
        ItemNo_1__Control11CaptionLbl: Label 'Inventory Item No.';
        ItemDescription_1__Control13CaptionLbl: Label 'Description';
        ItemUnit_1__Control15CaptionLbl: Label 'Unit of Measure';
        ItemShelf_1__Control17CaptionLbl: Label 'Shelf/Bin No.';
        ItemNo_2_CaptionLbl: Label 'Inventory Item No.';
        ItemDescription_2_CaptionLbl: Label 'Description';
        ItemUnit_2_CaptionLbl: Label 'Unit of Measure';
        ItemShelf_2_CaptionLbl: Label 'Shelf/Bin No.';
        ItemNo_1__Control31CaptionLbl: Label 'Inventory Item No.';
        ItemDescription_1__Control33CaptionLbl: Label 'Description';
        ItemUnit_1__Control35CaptionLbl: Label 'Unit of Measure';
        ItemShelf_1__Control37CaptionLbl: Label 'Shelf/Bin No.';
        ItemNo_2__Control39CaptionLbl: Label 'Inventory Item No.';
        ItemDescription_2__Control41CaptionLbl: Label 'Description';
        ItemUnit_2__Control43CaptionLbl: Label 'Unit of Measure';
        ItemShelf_2__Control45CaptionLbl: Label 'Shelf/Bin No.';
        ItemNo_3_CaptionLbl: Label 'Inventory Item No.';
        ItemDescription_3_CaptionLbl: Label 'Description';
        ItemUnit_3_CaptionLbl: Label 'Unit of Measure';
        ItemShelf_3_CaptionLbl: Label 'Shelf/Bin No.';
}


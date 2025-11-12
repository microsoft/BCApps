#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using System.Utilities;

report 99000758 "Compare List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/CompareList.rdlc';
    ApplicationArea = Manufacturing;
    Caption = 'Item BOM Compare List (Obsolete)';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteReason = 'This report has been replaced by the "Compare Production Cost Shares" report and will be removed in a future release.';
    ObsoleteTag = '27.0';

    dataset
    {
        dataitem(ItemLoop; "Integer")
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;

            trigger OnPreDataItem()
            begin
                for i := 1 to 2 do begin
                    Item[i].Get(Item[i]."No.");
                    Item[i].TestField("Production BOM No.");
                end;
                BOMMatrixMgt.CompareTwoItems(
                  Item[1],
                  Item[2],
                  CalculateDate,
                  true,
                  VersionCode1,
                  VersionCode2,
                  UnitOfMeasure1, UnitOfMeasure2);
            end;
        }
        dataitem(BOMLoop; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(AsOfCalcDate; Text000 + Format(CalculateDate))
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(Item1No; Item[1]."No.")
            {
            }
            column(Item2No; Item[2]."No.")
            {
            }
            column(BOMMatrixListItemNo; BOMMatrixList."Item No.")
            {
            }
            column(BOMMatrixListDesc; BOMMatrixList.Description)
            {
            }
            column(CompItemUnitCost; CompItem."Unit Cost")
            {
                AutoFormatType = 2;
            }
            column(Qty1; Qty1)
            {
                DecimalPlaces = 0 : 5;
            }
            column(Cost1; Cost1)
            {
                AutoFormatType = 1;
            }
            column(Qty2; Qty2)
            {
                DecimalPlaces = 0 : 5;
            }
            column(Cost2; Cost2)
            {
                AutoFormatType = 1;
            }
            column(CostDiff; CostDiff)
            {
                AutoFormatType = 1;
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(CompareListCaption; CompareListCaptionLbl)
            {
            }
            column(BOMMatrixListItemNoCapt; BOMMatrixListItemNoCaptLbl)
            {
            }
            column(BOMMatrixListDescCapt; BOMMatrixListDescCaptLbl)
            {
            }
            column(CompItemUnitCostCapt; CompItemUnitCostCaptLbl)
            {
            }
            column(CostDiffCaption; CostDiffCaptionLbl)
            {
            }
            column(Item1NoCaption; Item1NoCaptionLbl)
            {
            }
            column(Item2NoCaption; Item2NoCaptionLbl)
            {
            }
            column(TotalCostDifferenceCapt; TotalCostDifferenceCaptLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if First then begin
                    if not BOMMatrixMgt.FindRecord('-', BOMMatrixList) then
                        CurrReport.Break();
                    First := false;
                end else
                    if BOMMatrixMgt.NextRecord(1, BOMMatrixList) = 0 then
                        CurrReport.Break();

                Qty1 := BOMMatrixMgt.GetComponentNeed(BOMMatrixList."Item No.", BOMMatrixList."Variant Code", Item[1]."No.");
                Qty2 := BOMMatrixMgt.GetComponentNeed(BOMMatrixList."Item No.", BOMMatrixList."Variant Code", Item[2]."No.");

                CompItem.Get(BOMMatrixList."Item No.");

                Cost1 := CompItem."Unit Cost" * Qty1;
                Cost2 := CompItem."Unit Cost" * Qty2;
                CostDiff := Cost1 - Cost2;
            end;

            trigger OnPreDataItem()
            begin
                Clear(CostDiff);
                First := true;
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Item BOM Compare List (Obsolete)';
        AboutText = 'Compare the costs of similar final products. ** This report is obsolete and will be removed in a later release.** Please consult the report documentation for alternative ways to get to this data.';
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ItemNo1; Item[1]."No.")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Item No. 1';
                        DrillDownPageID = "Item List";
                        LookupPageID = "Item List";
                        NotBlank = true;
                        TableRelation = Item;
                        ToolTip = 'Specifies the number of the first item you want to compare, when comparing components for two items.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            Item[1].SetCurrentKey("Production BOM No.");
                            Item[1].SetFilter("Production BOM No.", '<>%1', '');
                            if PAGE.RunModal(PAGE::"Item List", Item[1]) = ACTION::LookupOK then begin
                                Text := Item[1]."No.";
                                exit(true);
                            end;
                            exit(false);
                        end;

                        trigger OnValidate()
                        begin
                            Item[1].Get(Item[1]."No.");
                            Item[1].TestField("Production BOM No.");

                            if Item[1]."No." = Item[2]."No." then
                                Item[1].FieldError("No.");
                        end;
                    }
                    field(ItemNo2; Item[2]."No.")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Item No. 2';
                        LookupPageID = "Item List";
                        NotBlank = true;
                        TableRelation = Item;
                        ToolTip = 'Specifies the number of the second item you want to compare, when comparing components for two items.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            Item[2].SetCurrentKey("Production BOM No.");
                            Item[2].SetFilter("Production BOM No.", '<>%1', '');
                            if PAGE.RunModal(PAGE::"Item List", Item[2]) = ACTION::LookupOK then begin
                                Text := Item[2]."No.";
                                exit(true);
                            end;
                            exit(false);
                        end;

                        trigger OnValidate()
                        begin
                            Item[2].Get(Item[2]."No.");
                            Item[2].TestField("Production BOM No.");

                            if Item[1]."No." = Item[2]."No." then
                                Item[2].FieldError("No.");
                        end;
                    }
                    field(CalculationDt; CalculateDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Calculation Date';
                        ToolTip = 'Specifies the date for which you want to make the comparison. The program automatically enters the working date.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            CalculateDate := WorkDate();
        end;
    }

    labels
    {
        Qty1Caption = 'Exploded Quantity';
        Cost1Caption = 'Cost Share';
    }

    var
        CompItem: Record Item;
        BOMMatrixList: Record "Production Matrix BOM Line";
        BOMMatrixMgt: Codeunit "BOM Matrix Management";
        CalculateDate: Date;
        i: Integer;
        First: Boolean;
        VersionCode1: Code[20];
        VersionCode2: Code[20];
        UnitOfMeasure1: Code[10];
        UnitOfMeasure2: Code[10];
        Qty1: Decimal;
        Qty2: Decimal;
        Cost1: Decimal;
        Cost2: Decimal;
        CostDiff: Decimal;

#pragma warning disable AA0074
        Text000: Label 'As of ';
#pragma warning restore AA0074
        CurrReportPageNoCaptionLbl: Label 'Page';
        CompareListCaptionLbl: Label 'Compare List';
        BOMMatrixListItemNoCaptLbl: Label 'No.';
        BOMMatrixListDescCaptLbl: Label 'Description';
        CompItemUnitCostCaptLbl: Label 'Unit Cost';
        CostDiffCaptionLbl: Label 'Difference Cost';
        Item1NoCaptionLbl: Label 'Item No. 1';
        Item2NoCaptionLbl: Label 'Item No. 2';
        TotalCostDifferenceCaptLbl: Label 'Total Cost Difference';

    protected var
        Item: array[2] of Record Item;

    procedure InitializeRequest(NewItem1: Code[20]; NewItem2: Code[20]; NewCalculateDate: Date)
    begin
        Item[1]."No." := NewItem1;
        Item[2]."No." := NewItem2;
        CalculateDate := NewCalculateDate;
    end;
}
#endif
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.BOM.Tree;

report 99000794 "Compare Production Cost Shares"
{
    ApplicationArea = Manufacturing;
    Caption = 'Compare Production Cost Shares';
    UsageCategory = ReportsAndAnalysis;
    DefaultRenderingLayout = CompareProductionCostSharesExcel;

    dataset
    {
        dataitem(CompareCostSharesBuffer; "Compare Cost Shares Buffer")
        {
            DataItemTableView = sorting(Indentation, Type, "No.");

            column(Item1; Item[1]."No." + ' ' + Item[1].Description)
            {
            }
            column(Item2; Item[2]."No." + ' ' + Item[2].Description)
            {
            }
            column(Level; PadStr('', Indentation, ' ') + Format(Indentation))
            {
            }
            column(Type; Type)
            {
                IncludeCaption = true;
            }
            column(No; "No.")
            {
                IncludeCaption = true;
            }
            column(Description; Description)
            {
                IncludeCaption = true;
            }
            column(IsLeaf; "Is Leaf")
            {
                IncludeCaption = true;
            }
            column(Item1QtyPerTopItem; "Item 1 Qty. per Top Item")
            {
                IncludeCaption = true;
            }
            column(Item2QtyPerTopItem; "Item 2 Qty. per Top Item")
            {
                IncludeCaption = true;
            }
            column(Item1UnitCost; "Item 1 Unit Cost")
            {
                IncludeCaption = true;
            }
            column(Item2UnitCost; "Item 2 Unit Cost")
            {
                IncludeCaption = true;
            }
            column(Item1TotalCost; "Item 1 Total Cost")
            {
                IncludeCaption = true;
            }
            column(Item2TotalCost; "Item 2 Total Cost")
            {
                IncludeCaption = true;
            }
            column(DifferenceCost; "Difference Cost")
            {
                IncludeCaption = true;
            }
        }
    }

    requestpage
    {
        AboutTitle = 'About Compare Production Cost Shares';
        AboutText = 'Compare the costs of similar final products.';
        layout
        {
            area(Content)
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
                            if Page.RunModal(Page::"Item List", Item[1]) = Action::LookupOK then begin
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
                            if Page.RunModal(Page::"Item List", Item[2]) = Action::LookupOK then begin
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
                }
            }
        }
    }

    rendering
    {
        layout(CompareProductionCostSharesExcel)
        {
            Caption = 'Compare Production Cost Shares Excel';
            Type = Excel;
            LayoutFile = './Manufacturing/Reports/CompareProductionCostShares.xlsx';
        }
    }

    labels
    {
        CompareProductionCostSharesList = 'Compare Production Cost Shares - List';
        CompareProductionCostSharesExploded = 'Compare Production Cost Shares - Exploded';
        CompareListPrint = 'Compare List (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        CompareExplodedPrint = 'Compare Exploded (Print)', MaxLength = 31, Comment = 'Excel worksheet name.';
        CompareCostSharesAnalysis = 'Compare Cost Shares (Analysis)', MaxLength = 31, Comment = 'Excel worksheet name.';
        DataRetrieved = 'Data retrieved:';
        Item1Label = 'Item 1:';
        Item2Label = 'Item 2:';
        LevelLabel = 'Level';
        // About the report labels
        AboutTheReportLabel = 'About the report', MaxLength = 31, Comment = 'Excel worksheet name.';
        EnvironmentLabel = 'Environment';
        CompanyLabel = 'Company';
        UserLabel = 'User';
        RunOnLabel = 'Run on';
        ReportNameLabel = 'Report name';
        DocumentationLabel = 'Documentation';
    }

    trigger OnPreReport()
    begin
        GenerateTreeForItems(TempBOMBuffer1, Item[1]."No.");
        GenerateTreeForItems(TempBOMBuffer2, Item[2]."No.");

        BuildDataSet(TempBOMBuffer1, true);
        BuildDataSet(TempBOMBuffer2, false);
    end;

    var
        TempBOMBuffer1: Record "BOM Buffer" temporary;
        TempBOMBuffer2: Record "BOM Buffer" temporary;
        ItemNoBOMLbl: Label 'Item %1 does not have a BOM.', Comment = '%1 = Item No.';
        TopItemDescriptionLbl: Label '%1 - %2', Comment = '%1 = Item No. 1, %2 = Item No. 2';

    protected var
        Item: array[2] of Record Item;

    local procedure GenerateTreeForItems(var BOMBuffer: Record "BOM Buffer" temporary; ItemNo: Code[20])
    var
        Item2: Record Item;
        CalcBOMTree: Codeunit "Calculate BOM Tree";
        HasBOM: Boolean;
    begin
        Item2.Get(ItemNo);
        HasBOM := Item2.HasBOM() or (Item2."Routing No." <> '');

        if not HasBOM then
            Error(ItemNoBOMLbl, ItemNo);

        CalcBOMTree.GenerateTreeForOneItem(Item2, BOMBuffer, WorkDate(), "BOM Tree Type"::Cost);
    end;

    local procedure BuildDataSet(var BOMBuffer: Record "BOM Buffer" temporary; Item1: Boolean)
    begin
        BOMBuffer.Reset();
        if BOMBuffer.FindSet() then
            repeat
                if BOMBuffer.Indentation = 0 then begin
                    BOMBuffer."No." := '';
                    BOMBuffer.Description := StrSubstNo(TopItemDescriptionLbl, Item[1]."No.", Item[2]."No.");
                end;
                CompareCostSharesBuffer.TransferFromBOMBuffer(BOMBuffer, Item1);
            until BOMBuffer.Next() = 0;
    end;

    procedure InitializeRequest(NewItem1: Code[20]; NewItem2: Code[20])
    begin
        Item[1]."No." := NewItem1;
        Item[2]."No." := NewItem2;
    end;
}
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.BOM;
using Microsoft.Inventory.BOM.Tree;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using System.Utilities;

report 5872 "BOM Cost Share Distribution"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/BOMCostShareDistribution.rdlc';
    AdditionalSearchTerms = 'cost breakdown,rolled-up cost';
    ApplicationArea = Assembly;
    Caption = 'BOM Cost Share Distribution';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(ItemTABLECAPTION_ItemFilter; TableCaption + ': ' + ItemFilters)
            {
            }
            column(ItemNo; "No.")
            {
                IncludeCaption = true;
            }
            column(ItemDescription; Description)
            {
                IncludeCaption = true;
            }
            column(ReportCostShareDescription; StrSubstNo(Text000, SelectStr(ShowCostShareAs + 1, ShowCostShareAsTxt)))
            {
            }
            column(ShowDetails; ShowDetails)
            {
            }
            column(ShowLevelAs; ShowLevelAs)
            {
                OptionCaption = 'First BOM Level,BOM Leaves';
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            dataitem(BOMBufferLoop; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(TypeNo; StrSubstNo('%1 %2', TempBOMBuffer.Type, TempBOMBuffer."No."))
                {
                }
                column(Type; TempBOMBuffer.Type)
                {
                }
                column(No; TempBOMBuffer."No.")
                {
                }
                column(Description; TempBOMBuffer.Description)
                {
                }
                column(Indentation; TempBOMBuffer.Indentation)
                {
                }
                column(DirectCost; TempBOMBuffer.CalcDirectCost())
                {
                }
                column(IndirectCost; TempBOMBuffer.CalcIndirectCost())
                {
                }
                column(MaterialCost; MaterialCost)
                {
                }
                column(NonInventoryMaterialCost; NonInventoryMaterialCost)
                {
                }
                column(CapacityCost; CapacityCost)
                {
                }
                column(SubcontrdCost; SubcontrdCost)
                {
                }
                column(CapOvhdCost; CapOvhdCost)
                {
                }
                column(MfgOvhdCost; MfgOvhdCost)
                {
                }
                column(TotalCost; TempBOMBuffer."Total Cost")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not FindNextRecord(TempBOMBuffer, Number) then
                        CurrReport.Break();

                    MaterialCost := TempBOMBuffer."Rolled-up Material Cost";
                    if CostCalcMgt.CanIncNonInvCostIntoProductionItem() then
                        NonInventoryMaterialCost := TempBOMBuffer."Rolled-up Mat. Non-Invt. Cost";

                    CapacityCost := TempBOMBuffer."Rolled-up Capacity Cost";
                    SubcontrdCost := TempBOMBuffer."Rolled-up Subcontracted Cost";
                    MfgOvhdCost := TempBOMBuffer."Rolled-up Mfg. Ovhd Cost";
                    CapOvhdCost := TempBOMBuffer."Rolled-up Capacity Ovhd. Cost";

                    if (MaterialCost = 0) and
                       (NonInventoryMaterialCost = 0) and
                       (CapacityCost = 0) and
                       (SubcontrdCost = 0) and
                       (CapOvhdCost = 0) and
                       (MfgOvhdCost = 0)
                    then
                        CurrReport.Skip();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not GenerateAvailTrend() then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                ItemFilters := GetFilters();
                BOMBuffer.DeleteAll();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About BOM Cost Share Distribution';
        AboutText = 'Helps you decide whether to change component suppliers or replace internal resources with outsourced labor (or vice versa). It can also help you review and modify an item''s bill of materials.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowCostShareAs; ShowCostShareAs)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Cost Shares as';
                        OptionCaption = 'Single-level,Rolled-up';
                        ToolTip = 'Specifies the BOM cost shares as single-level costs or as rolled-up costs.';
                    }
                    field(ShowLevelAs; ShowLevelAs)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show only';
                        OptionCaption = 'First BOM Level,BOM Leaves';
                        ToolTip = 'Specifies the cost shares for items on the first BOM level only or for items on the lowest BOM levels, components, only.';
                    }
                    field(ShowDetails; ShowDetails)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Details';
                        ToolTip = 'Specifies that a table is added at the bottom of the report that provides a summary of the single-level or rolled-up values in the BOM Cost Shares window.';
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
        BOMCostSharesReportCaption = 'BOM Cost Share Distribution';
        TypeCaption = 'Type';
        QtyPerTopItemCaption = 'Qty. per Top Item';
        UnitPriceCaption = 'Unit Price';
        UnitCostCaption = 'Unit Cost';
        DirectCostCaption = 'Direct Cost';
        IndirectCostCaption = 'Indirect Cost';
        MaterialCostCaption = 'Material';
        NonInventoryMaterialCostCaption = 'Non Inventory Material';
        CapacityCostCaption = 'Capacity';
        SubcontrdCostCaption = 'Subcontracted';
        CapOvhdCostCaption = 'Capacity Overhead';
        MfgOvhdCostCaption = 'Mfg. Overhead';
        CostDistributionByMaterialLaborCaption = 'By Material/Labor';
        CostDistributionByDirectIndirectCaption = 'By Direct/Indirect';
        CostDistributionByCostSharesCaption = 'By Cost Share';
        TotalCostCaption = 'Total Cost';
        MaterialCaption = 'Material';
        LaborCaption = 'Labor';
        OverheadCaption = 'Overhead';
    }

    var
        BOMBuffer: Record "BOM Buffer";
        TempBOMBuffer: Record "BOM Buffer" temporary;
        CalcBOMTree: Codeunit "Calculate BOM Tree";
        CostCalcMgt: Codeunit "Cost Calculation Management";
        ItemFilters: Text;
        ShowLevelAs: Option "First BOM Level","BOM Leaves";
        ShowDetails: Boolean;
        ShowCostShareAs: Option "Single-level","Rolled-up";
        MaterialCost: Decimal;
        NonInventoryMaterialCost: Decimal;
        CapacityCost: Decimal;
        SubcontrdCost: Decimal;
        CapOvhdCost: Decimal;
        MfgOvhdCost: Decimal;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 cost shares only';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        ShowCostShareAsTxt: Label 'Single-level,Rolled-up';

    local procedure GenerateAvailTrend(): Boolean
    var
        NewOvhdCost: Decimal;
        NewMaterialCost: Decimal;
        IsKeepOnlyMfgOvhd: Boolean;
        IsTransferCostToMaterial: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnGenerateAvailTrendOnBeforeGenerateTreeForItem(Item, TempBOMBuffer, IsHandled);
        if not IsHandled then
            CalcBOMTree.GenerateTreeForOneItem(Item, TempBOMBuffer, WorkDate(), "BOM Tree Type"::Cost);

        if TempBOMBuffer.FindFirst() then
            repeat
                IsKeepOnlyMfgOvhd := KeepOnlyMfgOvhdCost();
                IsTransferCostToMaterial := TransferCostToMaterial();
                NewOvhdCost := 0;
                NewMaterialCost := 0;

                if IsKeepOnlyMfgOvhd then begin
                    TempBOMBuffer.Description := CopyStr(TempBOMBuffer.FieldCaption("Single-Level Mfg. Ovhd Cost"), 1, MaxStrLen(TempBOMBuffer.Description));
                    NewOvhdCost := TempBOMBuffer."Single-Level Mfg. Ovhd Cost";
                    TempBOMBuffer.RoundCosts(0);
                    TempBOMBuffer.AddMfgOvhdCost(NewOvhdCost, NewOvhdCost);
                end;

                if IsTransferCostToMaterial then begin
                    NewMaterialCost := TempBOMBuffer.CalcDirectCost() + TempBOMBuffer.CalcIndirectCost();
                    TempBOMBuffer.RoundCosts(0);
                    TempBOMBuffer.AddMaterialCost(NewMaterialCost, NewMaterialCost);
                end;

                if DeleteThisLine() then
                    TempBOMBuffer.Delete()
                else
                    if IsKeepOnlyMfgOvhd or IsTransferCostToMaterial then begin
                        TempBOMBuffer.CalcIndirectCost();
                        TempBOMBuffer.CalcUnitCost();
                        TempBOMBuffer.Modify();
                    end;
            until TempBOMBuffer.Next() = 0;
        MergeLinesWithSameTypeAndNo();

        exit(not TempBOMBuffer.IsEmpty);
    end;

    local procedure KeepOnlyMfgOvhdCost(): Boolean
    begin
        if TempBOMBuffer.Indentation = 0 then
            exit(true);
        if ShowLevelAs = ShowLevelAs::"First BOM Level" then
            exit(false);
        exit(not TempBOMBuffer."Is Leaf");
    end;

    local procedure TransferCostToMaterial(): Boolean
    begin
        if ShowCostShareAs <> ShowCostShareAs::"Single-level" then
            exit(false);
        if TempBOMBuffer.Indentation = 0 then
            exit(false);
        if (TempBOMBuffer.Indentation = 1) and TempBOMBuffer."Is Leaf" then
            exit(false);
        exit(true);
    end;

    local procedure DeleteThisLine(): Boolean
    begin
        if TempBOMBuffer.Indentation = 0 then
            exit(TempBOMBuffer."Single-Level Mfg. Ovhd Cost" = 0);
        if ShowLevelAs = ShowLevelAs::"First BOM Level" then
            exit(TempBOMBuffer.Indentation > 1);
        if TempBOMBuffer."Is Leaf" then
            exit(false);
        if ShowCostShareAs = ShowCostShareAs::"Single-level" then
            if CostCalcMgt.CanIncNonInvCostIntoProductionItem() then
                exit((TempBOMBuffer."Single-Level Material Cost" = 0) and (TempBOMBuffer."Single-Lvl Mat. Non-Invt. Cost" = 0))
            else
                exit(TempBOMBuffer."Single-Level Material Cost" = 0);
        exit(TempBOMBuffer."Single-Level Mfg. Ovhd Cost" = 0);
    end;

    local procedure MergeLinesWithSameTypeAndNo()
    var
        CopyOfBOMBuffer: Record "BOM Buffer";
    begin
        if TempBOMBuffer.FindFirst() then
            repeat
                if TempBOMBuffer.Indentation <> 0 then begin
                    CopyOfBOMBuffer.Copy(TempBOMBuffer);
                    TempBOMBuffer.SetRange(Type, TempBOMBuffer.Type);
                    TempBOMBuffer.SetRange("No.", TempBOMBuffer."No.");
                    while TempBOMBuffer.Next() <> 0 do begin
                        CopyOfBOMBuffer.AddMaterialCost(TempBOMBuffer."Single-Level Material Cost", TempBOMBuffer."Rolled-up Material Cost");
                        CopyOfBOMBuffer.AddNonInvMaterialCost(TempBOMBuffer."Single-Lvl Mat. Non-Invt. Cost", TempBOMBuffer."Rolled-up Mat. Non-Invt. Cost");
                        CopyOfBOMBuffer.AddCapacityCost(TempBOMBuffer."Single-Level Capacity Cost", TempBOMBuffer."Rolled-up Capacity Cost");
                        CopyOfBOMBuffer.AddSubcontrdCost(TempBOMBuffer."Single-Level Subcontrd. Cost", TempBOMBuffer."Rolled-up Subcontracted Cost");
                        CopyOfBOMBuffer.AddCapOvhdCost(TempBOMBuffer."Single-Level Cap. Ovhd Cost", TempBOMBuffer."Rolled-up Capacity Ovhd. Cost");
                        CopyOfBOMBuffer.AddMfgOvhdCost(TempBOMBuffer."Single-Level Mfg. Ovhd Cost", TempBOMBuffer."Rolled-up Mfg. Ovhd Cost");
                        CopyOfBOMBuffer.AddScrapCost(TempBOMBuffer."Single-Level Scrap Cost", TempBOMBuffer."Rolled-up Scrap Cost");
                        TempBOMBuffer.Delete();
                    end;
                    TempBOMBuffer.Copy(CopyOfBOMBuffer);
                    TempBOMBuffer.CalcDirectCost();
                    TempBOMBuffer.CalcIndirectCost();
                    TempBOMBuffer.CalcUnitCost();
                    TempBOMBuffer.Modify();
                end;
            until TempBOMBuffer.Next() = 0;
    end;

    local procedure FindNextRecord(var BOMBuffer: Record "BOM Buffer"; Position: Integer): Boolean
    begin
        if Position = 1 then begin
            BOMBuffer.SetCurrentKey("Total Cost");
            exit(BOMBuffer.Find('-'));
        end;
        exit(BOMBuffer.Next() <> 0);
    end;

    procedure InitializeRequest(NewShowLevelAs: Option; NewShowDetails: Boolean; NewShowCostShareAs: Option)
    begin
        ShowLevelAs := NewShowLevelAs;
        ShowDetails := NewShowDetails;
        ShowCostShareAs := NewShowCostShareAs;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenerateAvailTrendOnBeforeGenerateTreeForItem(var Item: Record "Item"; var TempBOMBuffer: Record "BOM Buffer" temporary; var IsHandled: Boolean)
    begin
    end;
}


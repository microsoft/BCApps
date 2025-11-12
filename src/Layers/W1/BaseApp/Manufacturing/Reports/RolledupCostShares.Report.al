// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using System.Utilities;

report 99000754 "Rolled-up Cost Shares"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/RolledupCostShares.rdlc';
    ApplicationArea = Manufacturing;
    Caption = 'Rolled-up Cost Shares';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Search Description", "Inventory Posting Group";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(AsOfFormatCalcDate; Text000 + Format(CalculateDate))
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(ItemTableCaptionFilter; TableCaption + ': ' + ItemFilter)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(No_Item; "No.")
            {
            }
            column(Description_Item; Description)
            {
            }
            column(RolledupCostSharesCapt; RolledupCostSharesCaptLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(TotalCostCaption; TotalCostCaptionLbl)
            {
            }
            column(OverheadCostCaption; OverheadCostCaptionLbl)
            {
            }
            column(CapacityCostCaption; CapacityCostCaptionLbl)
            {
            }
            column(MaterialCostCaption; MaterialCostCaptionLbl)
            {
            }
            column(BOMCompQtyBaseCapt; BOMCompQtyBaseCaptLbl)
            {
            }
            column(ProdBOMLineIndexDescCapt; ProdBOMLineIndexDescCaptLbl)
            {
            }
            column(ProdBOMLineIndexNoCapt; ProdBOMLineIndexNoCaptLbl)
            {
            }
            column(FormatLevelCapt; FormatLevelCaptLbl)
            {
            }
            column(CompItemBaseUOMCapt; CompItemBaseUOMCaptLbl)
            {
            }
            dataitem(BOMLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(RolledupMaterialCost_Item; Item."Rolled-up Material Cost")
                {
                    AutoFormatType = 2;
                    DecimalPlaces = 2 : 5;
                }
                column(ItemRoldupCptySbcntrctCst; Item."Rolled-up Capacity Cost" + Item."Rolled-up Subcontracted Cost")
                {
                    AutoFormatType = 2;
                    DecimalPlaces = 2 : 5;
                }
                column(ItemRoldupMfgOvhdOvrHdCst; Item."Rolled-up Mfg. Ovhd Cost" + Item."Rolled-up Cap. Overhead Cost")
                {
                    AutoFormatType = 2;
                    DecimalPlaces = 2 : 5;
                }
                column(UnitCost_Item; Item."Unit Cost")
                {
                    AutoFormatType = 2;
                    DecimalPlaces = 2 : 5;
                }
                column(CostShareItemCapt; CostShareItemCaptLbl)
                {
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 1;
                    column(ProdBOMLineIndexNo; ProdBOMLine[Index]."No.")
                    {
                    }
                    column(ProdBOMLineIndexDesc; ProdBOMLine[Index].Description)
                    {
                    }
                    column(BOMCompQtyBase; BOMCompQtyBase)
                    {
                        AutoFormatType = 2;
                        DecimalPlaces = 0 : 5;
                    }
                    column(PADSTRLevelFormatLevel; PadStr('', Level, ' ') + Format(Level))
                    {
                    }
                    column(MaterialCost; MaterialCost)
                    {
                        AutoFormatType = 2;
                        DecimalPlaces = 2 : 5;
                    }
                    column(CapacityCost; CapacityCost)
                    {
                        AutoFormatType = 2;
                        DecimalPlaces = 2 : 5;
                    }
                    column(OverheadCost; OverheadCost)
                    {
                        AutoFormatType = 2;
                        DecimalPlaces = 2 : 5;
                    }
                    column(TotalCost; TotalCost)
                    {
                        AutoFormatType = 2;
                        DecimalPlaces = 2 : 5;
                    }
                    column(CompItemBaseUOM; CompItem."Base Unit of Measure")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        BOMCompQtyBase := Quantity[Index] * CompItemQtyBase / LotSize[Index];

                        MaterialCost :=
                          Round(
                            BOMCompQtyBase * CompItem."Rolled-up Material Cost",
                            GLSetup."Unit-Amount Rounding Precision");
                        CapacityCost :=
                          Round(
                            BOMCompQtyBase * (CompItem."Rolled-up Capacity Cost" + CompItem."Rolled-up Subcontracted Cost"),
                            GLSetup."Unit-Amount Rounding Precision");
                        OverheadCost :=
                          Round(
                            BOMCompQtyBase * (CompItem."Rolled-up Mfg. Ovhd Cost" + CompItem."Rolled-up Cap. Overhead Cost"),
                            GLSetup."Unit-Amount Rounding Precision");

                        TotalCost := MaterialCost + CapacityCost + OverheadCost;
                    end;

                    trigger OnPostDataItem()
                    begin
                        Index := NextIndex;

                        if CompItem.IsMfgItem() and (CompItem."Production BOM No." <> '') then begin
                            MfgItem := CompItem;
                            Level := Level + 1;
                        end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    while ProdBOMLine[Index].Next() = 0 do begin
                        if NoListType[Index] = NoListType[Index] ::Item then
                            Level := Level - 1;
                        Index := Index - 1;
                        if Index < 1 then
                            CurrReport.Break();
                        if NoListType[Index] = NoListType[Index] ::Item then
                            MfgItem.Get(NoList[Index])
                        else
                            MfgItem."Production BOM No." := NoList[Index];
                        ProdBOMLine[Index].SetRange("Production BOM No.", MfgItem."Production BOM No.");
                        ProdBOMLine[Index].SetRange("Version Code", VersionCode[Index]);
                    end;

                    NextIndex := Index;

                    OnOnAfterGetRecordOnBOMLoopOnBeforeCalcCompItemQtyBase(Item, ProdBOMLine[Index], CalculateDate);

                    CompItemQtyBase :=
                      MfgCostCalcMgt.CalcCompItemQtyBase(
                        ProdBOMLine[Index], CalculateDate, MfgItemQtyBase[Index], MfgItem."Routing No.",
                        NoListType[Index] = NoListType[Index] ::Item);

                    Clear(CompItem);

                    case ProdBOMLine[Index].Type of
                        ProdBOMLine[Index].Type::Item:
                            begin
                                CompItem.Get(ProdBOMLine[Index]."No.");
                                OnOnAfterGetRecordOnBOMLoopOnAfterGetCompItem(MfgItem, ProdBOMLine, CompItem, Index);
                                if CompItem.IsMfgItem() and (CompItem."Production BOM No." <> '') then begin
                                    ProdBOMHeader.Get(CompItem."Production BOM No.");
                                    if ProdBOMHeader.Status = ProdBOMHeader.Status::Closed then
                                        CurrReport.Skip();
                                    NextIndex := Index + 1;
                                    if Index > 1 then
                                        if (NextIndex > 50) or (ProdBOMLine[Index]."No." = NoList[Index - 1]) then
                                            Error(ProductionBomErr, 50, Item."No.", MfgItem."Production BOM No.", Level);
                                    VersionCode[NextIndex] := VersionMgt.GetBOMVersion(CompItem."Production BOM No.", CalculateDate, true);
                                    NoListType[NextIndex] := NoListType[NextIndex] ::Item;
                                    NoList[NextIndex] := CompItem."No.";

                                    Clear(ProdBOMLine[NextIndex]);
                                    ProdBOMLine[NextIndex].SetRange("Production BOM No.", CompItem."Production BOM No.");
                                    ProdBOMLine[NextIndex].SetRange("Version Code", VersionCode[NextIndex]);
                                    ProdBOMLine[NextIndex].SetFilter("Starting Date", '%1|..%2', 0D, CalculateDate);
                                    ProdBOMLine[NextIndex].SetFilter("Ending Date", '%1|%2..', 0D, CalculateDate);

                                    LotSize[NextIndex] := GetLotSize(CompItem);
                                    MfgItemQtyBase[NextIndex] := CalcMfgItemQtyBase(CompItem, VersionCode[NextIndex], LotSize[NextIndex]);
                                    Quantity[NextIndex] := Quantity[Index] * CompItemQtyBase / LotSize[Index];
                                end;
                            end;
                        ProdBOMLine[Index].Type::"Production BOM":
                            begin
                                NextIndex := Index + 1;

                                ProdBOMHeader.Get(ProdBOMLine[Index]."No.");
                                if ProdBOMHeader.Status = ProdBOMHeader.Status::Closed then
                                    CurrReport.Skip();
                                if Index > 1 then
                                    if (NextIndex > 50) or (ProdBOMLine[Index]."No." = NoList[Index - 1]) then
                                        Error(ProductionBomErr, 50, Item."No.", MfgItem."Production BOM No.", Level);
                                VersionCode[NextIndex] := VersionMgt.GetBOMVersion(ProdBOMHeader."No.", CalculateDate, true);
                                NoListType[NextIndex] := NoListType[NextIndex] ::"Production BOM";
                                NoList[NextIndex] := ProdBOMHeader."No.";

                                Clear(ProdBOMLine[NextIndex]);
                                ProdBOMLine[NextIndex].SetRange("Production BOM No.", NoList[NextIndex]);
                                ProdBOMLine[NextIndex].SetRange("Version Code", VersionCode[NextIndex]);
                                ProdBOMLine[NextIndex].SetFilter("Starting Date", '%1|..%2', 0D, CalculateDate);
                                ProdBOMLine[NextIndex].SetFilter("Ending Date", '%1|%2..', 0D, CalculateDate);

                                LotSize[NextIndex] := LotSize[Index];
                                MfgItemQtyBase[NextIndex] := CompItemQtyBase;
                                Quantity[NextIndex] := Quantity[Index];
                            end;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    Index := 1;
                    Level := 1;

                    VersionCode[Index] := VersionMgt.GetBOMVersion(Item."Production BOM No.", CalculateDate, true);
                    NoListType[Index] := NoListType[Index] ::Item;
                    NoList[Index] := Item."No.";

                    Clear(ProdBOMLine);
                    ProdBOMLine[Index].SetRange("Production BOM No.", Item."Production BOM No.");
                    ProdBOMLine[Index].SetRange("Version Code", VersionCode[Index]);
                    ProdBOMLine[Index].SetFilter("Starting Date", '%1|..%2', 0D, CalculateDate);
                    ProdBOMLine[Index].SetFilter("Ending Date", '%1|%2..', 0D, CalculateDate);

                    LotSize[Index] := GetLotSize(Item);
                    MfgItemQtyBase[Index] := CalcMfgItemQtyBase(Item, VersionCode[Index], LotSize[Index]);
                    Quantity[Index] := 1;

                    MfgItem := Item;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not IsMfgItem() or ("Production BOM No." = '') then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                ItemFilter := GetFilters();
                GLSetup.Get();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Rolled-up Cost Shares';
        AboutText = 'Get a comprehensive view of the costs associated with manufactured items, broken down into different cost components. For example, material, capacity, capacity overhead, subcontracting, and manufacturing overhead.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CalculateDate; CalculateDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Calculation Date';
                        ToolTip = 'Specifies the date you want the cost shares to be calculated.';
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
    }

    trigger OnPreReport()
    begin
        OnBeforeOnPreReport(Item);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ProdBOMHeader: Record "Production BOM Header";
        MfgItem: Record Item;
        CompItem: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        VersionMgt: Codeunit VersionManagement;
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        ItemFilter: Text;
        BOMCompQtyBase: Decimal;
        MaterialCost: Decimal;
        CapacityCost: Decimal;
        OverheadCost: Decimal;
        TotalCost: Decimal;
        CompItemQtyBase: Decimal;

#pragma warning disable AA0074
        Text000: Label 'As of ';
#pragma warning restore AA0074
        RolledupCostSharesCaptLbl: Label 'Rolled-up Cost Shares';
        PageCaptionLbl: Label 'Page';
        TotalCostCaptionLbl: Label 'Total Cost';
        OverheadCostCaptionLbl: Label 'Overhead Cost';
        CapacityCostCaptionLbl: Label 'Capacity Cost';
        MaterialCostCaptionLbl: Label 'Material Cost';
        BOMCompQtyBaseCaptLbl: Label 'Quantity (Base)';
        ProdBOMLineIndexDescCaptLbl: Label 'Description';
        ProdBOMLineIndexNoCaptLbl: Label 'No.';
        FormatLevelCaptLbl: Label 'Level';
        CompItemBaseUOMCaptLbl: Label 'Base Unit of Measure Code';
        CostShareItemCaptLbl: Label 'Cost Shares for this Item';
#pragma warning disable AA0470
        ProductionBomErr: Label 'The maximum number of BOM levels, %1, was exceeded. The process stopped at item number %2, BOM header number %3, BOM level %4.';
#pragma warning restore AA0470

    protected var
        ProdBOMLine: array[99] of Record "Production BOM Line";
        CalculateDate: Date;
        Level: Integer;
        Index: Integer;
        NextIndex: Integer;
        VersionCode: array[99] of Code[20];
        NoListType: array[99] of Option Item,"Production BOM";
        NoList: array[99] of Code[20];
        LotSize: array[99] of Decimal;
        MfgItemQtyBase: array[99] of Decimal;
        Quantity: array[99] of Decimal;

    local procedure GetLotSize(Item: Record Item): Decimal
    begin
        if Item."Lot Size" <> 0 then
            exit(Item."Lot Size");

        exit(1);
    end;

    local procedure CalcMfgItemQtyBase(Item: Record Item; VersionCode: Code[20]; LotSize: Decimal): Decimal
    begin
        exit(
          MfgCostCalcMgt.CalcQtyAdjdForBOMScrap(LotSize, Item."Scrap %") /
          UOMMgt.GetQtyPerUnitOfMeasure(Item, VersionMgt.GetBOMUnitOfMeasure(Item."Production BOM No.", VersionCode)));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnAfterGetRecordOnBOMLoopOnBeforeCalcCompItemQtyBase(var Item: Record Item; var ProductionBOMLine: Record "Production BOM Line"; CalculationDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreReport(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnAfterGetRecordOnBOMLoopOnAfterGetCompItem(var MfgItem: Record Item; var ProductionBOMLine: array[99] of Record "Production BOM Line"; var CompItem: Record Item; Index: Integer)
    begin
    end;
}


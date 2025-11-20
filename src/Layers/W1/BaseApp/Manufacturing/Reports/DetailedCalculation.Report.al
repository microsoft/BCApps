// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Reports;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using System.Utilities;

report 99000756 "Detailed Calculation"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Manufacturing/Reports/DetailedCalculation.rdlc';
    ApplicationArea = Manufacturing;
    Caption = 'Detailed Calculation';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("Low-Level Code");
            RequestFilterFields = "No.";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(AsofCalcDate; CalculateDateLbl + Format(CalculateDate))
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
                IncludeCaption = true;
            }
            column(Description_Item; Description)
            {
                IncludeCaption = true;
            }
            column(ProductionBOMNo_Item; "Production BOM No.")
            {
                IncludeCaption = true;
            }
            column(RoutingNo_Item; "Routing No.")
            {
                IncludeCaption = true;
            }
            column(PBOMVersionCode1; PBOMVersionCode[1])
            {
            }
            column(RtngVersionCode; RtngVersionCode)
            {
            }
            column(LotSize_Item; "Lot Size")
            {
                IncludeCaption = true;
            }
            column(BaseUOM_Item; "Base Unit of Measure")
            {
            }
            column(CurrReportPageNoCapt; CurrReportPageNoCaptLbl)
            {
            }
            column(DetailedCalculationCapt; DetailedCalculationCaptLbl)
            {
            }
            dataitem("Routing Line"; "Routing Line")
            {
                DataItemLink = "Routing No." = field("Routing No.");
                DataItemTableView = sorting("Routing No.", "Version Code", "Operation No.");
                column(InRouting; InRouting)
                {
                }
                column(OperationNo_RtngLine; "Operation No.")
                {
                    IncludeCaption = true;
                }
                column(Type_RtngLine; Type)
                {
                    IncludeCaption = true;
                }
                column(No_RtngLine; "No.")
                {
                    IncludeCaption = true;
                }
                column(Desc_RtngLine; Description)
                {
                    IncludeCaption = true;
                }
                column(SetupTime_RtngLine; "Setup Time")
                {
                    IncludeCaption = true;
                }
                column(RunTime_RtngLine; "Run Time")
                {
                    IncludeCaption = true;
                }
                column(CostTime; CostTime)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(ProdUnitCost; ProdUnitCost)
                {
                    AutoFormatType = 2;
                }
                column(ProdTotalCost; ProdTotalCost)
                {
                    AutoFormatType = 1;
                }
                column(CostTimeCaption; CostTimeCaptionLbl)
                {
                }
                column(ProdTotalCostCaption; ProdTotalCostCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                var
                    UnitCostCalculation: Enum "Unit Cost Calculation Type";
                begin
                    ProdUnitCost := "Unit Cost per";

                    MfgCostCalcMgt.CalcRoutingCostPerUnit(
                      Type, "No.", DirectUnitCost, IndirectCostPct, OverheadRate, ProdUnitCost, UnitCostCalculation);
                    CostTime :=
                      MfgCostCalcMgt.CalculateCostTime(
                        MfgCostCalcMgt.CalcQtyAdjdForBOMScrap(Item."Lot Size", Item."Scrap %"),
                        "Setup Time", "Setup Time Unit of Meas. Code",
                        "Run Time", "Run Time Unit of Meas. Code", "Lot Size",
                        "Scrap Factor % (Accumulated)", "Fixed Scrap Qty. (Accum.)",
                        "Work Center No.", UnitCostCalculation, MfgSetup."Cost Incl. Setup",
                        "Concurrent Capacities") /
                      Item."Lot Size";

                    ProdTotalCost := CostTime * ProdUnitCost;

                    FooterProdTotalCost += ProdTotalCost;
                end;

                trigger OnPostDataItem()
                begin
                    InRouting := false;
                end;

                trigger OnPreDataItem()
                begin
                    Clear(ProdTotalCost);
                    SetRange("Version Code", RtngVersionCode);

                    InRouting := true;
                end;
            }
            dataitem(BOMLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(InBOM; InBOM)
                {
                }
                column(ProdBOMLineLevelNoCaption; ProdBOMLineLevelNoCaptionLbl)
                {
                }
                column(ProdBOMLineLevelDescCapt; ProdBOMLineLevelDescCaptLbl)
                {
                }
                column(ProdBOMLineLevelQtyCapt; ProdBOMLineLevelQtyCaptLbl)
                {
                }
                column(CostTotalCaption; CostTotalCaptionLbl)
                {
                }
                column(ProdBOMLineLevelTypeCapt; ProdBOMLineLevelTypeCaptLbl)
                {
                }
                column(CompItemBaseUOMCapt; CompItemBaseUOMCaptLbl)
                {
                }
                dataitem(BOMComponentLine; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 1;
                    column(ProdBOMLineLevelType; Format(ProdBOMLine[Level].Type))
                    {
                    }
                    column(ProdBOMLineLevelNo; ProdBOMLine[Level]."No.")
                    {
                    }
                    column(ProdBOMLineLevelDesc; ProdBOMLine[Level].Description)
                    {
                    }
                    column(ProdBOMLineLevelQty; ProdBOMLine[Level].Quantity)
                    {
                    }
                    column(UnitCost_CompItem; CompItem."Unit Cost")
                    {
                        AutoFormatType = 2;
                        DecimalPlaces = 2 : 5;
                    }
                    column(CostTotal; CostTotal)
                    {
                        AutoFormatType = 1;
                    }
                    column(BaseUOM_CompItem; CompItem."Base Unit of Measure")
                    {
                    }
                    column(ShowLine; ProdBOMLine[Level].Type = ProdBOMLine[Level].Type::Item)
                    {
                    }
                }

                trigger OnAfterGetRecord()
                var
                    UOMFactor: Decimal;
                begin
                    CostTotal := 0;

                    while ProdBOMLine[Level].Next() = 0 do begin
                        Level := Level - 1;
                        if Level < 1 then
                            CurrReport.Break();
                        ProdBOMLine[Level].SetRange("Production BOM No.", PBOMNoList[Level]);
                        ProdBOMLine[Level].SetRange("Version Code", PBOMVersionCode[Level]);

                        OnAfterGetRecordBOMLoopOnAfterProdBOMLineLevelSetFilters(ProdBOMLine, Level);
                    end;

                    NextLevel := Level;
                    Clear(CompItem);

                    if Level = 1 then
                        UOMFactor :=
                          UOMMgt.GetQtyPerUnitOfMeasure(Item, VersionMgt.GetBOMUnitOfMeasure(PBOMNoList[Level], PBOMVersionCode[Level]))
                    else
                        UOMFactor := 1;

                    CompItemQtyBase :=
                      MfgCostCalcMgt.CalcCompItemQtyBase(ProdBOMLine[Level], CalculateDate, Quantity[Level], Item."Routing No.", Level = 1) /
                      UOMFactor;

                    case ProdBOMLine[Level].Type of
                        ProdBOMLine[Level].Type::Item:
                            begin
                                CompItem.Get(ProdBOMLine[Level]."No.");
                                ProdBOMLine[Level].Quantity := CompItemQtyBase / Item."Lot Size";
                                CostTotal := ProdBOMLine[Level].Quantity * CompItem."Unit Cost";
                                FooterCostTotal += CostTotal;
                            end;
                        ProdBOMLine[Level].Type::"Production BOM":
                            begin
                                NextLevel := Level + 1;
                                Clear(ProdBOMLine[NextLevel]);
                                PBOMNoList[NextLevel] := ProdBOMLine[Level]."No.";
                                PBOMVersionCode[NextLevel] :=
                                  VersionMgt.GetBOMVersion(ProdBOMLine[Level]."No.", CalculateDate, false);
                                ProdBOMLine[NextLevel].SetRange("Production BOM No.", PBOMNoList[NextLevel]);
                                ProdBOMLine[NextLevel].SetRange("Version Code", PBOMVersionCode[NextLevel]);
                                ProdBOMLine[NextLevel].SetFilter("Starting Date", '%1|..%2', 0D, CalculateDate);
                                ProdBOMLine[NextLevel].SetFilter("Ending Date", '%1|%2..', 0D, CalculateDate);
                                Quantity[NextLevel] := CompItemQtyBase;
                                Level := NextLevel;
                            end;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    InBOM := false;
                end;

                trigger OnPreDataItem()
                begin
                    if Item."Production BOM No." = '' then
                        CurrReport.Break();

                    Level := 1;

                    ProdBOMHeader.Get(PBOMNoList[Level]);

                    Clear(ProdBOMLine);
                    ProdBOMLine[Level].SetRange("Production BOM No.", PBOMNoList[Level]);
                    ProdBOMLine[Level].SetRange("Version Code", PBOMVersionCode[Level]);
                    ProdBOMLine[Level].SetFilter("Starting Date", '%1|..%2', 0D, CalculateDate);
                    ProdBOMLine[Level].SetFilter("Ending Date", '%1|%2..', 0D, CalculateDate);
                    OnPreDataItemBOMLoopOnProdBOMLineLevelSetFilters(ProdBOMLine, Level);

                    Quantity[Level] := MfgCostCalcMgt.CalcQtyAdjdForBOMScrap(Item."Lot Size", Item."Scrap %");

                    InBOM := true;
                end;
            }
            dataitem(Footer; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(UnitCost_Item; Item."Unit Cost")
                {
                    AutoFormatType = 1;
                }
                column(SingleLevelMfgOvhd; SingleLevelMfgOvhd)
                {
                    AutoFormatType = 1;
                }
                column(FooterCostTotal; FooterCostTotal)
                {
                }
                column(FooterProdTotalCost; FooterProdTotalCost)
                {
                }
                column(ProdTotalCostCapt; ProdTotalCostCaptLbl)
                {
                }
                column(CostTotalCapt; CostTotalCaptLbl)
                {
                }
                column(SingleLevelMfgOvhdCaption; SingleLevelMfgOvhdCaptionLbl)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                if "Lot Size" = 0 then
                    "Lot Size" := 1;

                if ("Production BOM No." = '') and
                   ("Routing No." = '')
                then
                    CurrReport.Skip();

                CostTotal := 0;

                PBOMNoList[1] := "Production BOM No.";

                if "Production BOM No." <> '' then
                    PBOMVersionCode[1] :=
                      VersionMgt.GetBOMVersion("Production BOM No.", CalculateDate, false);

                if "Routing No." <> '' then
                    RtngVersionCode := VersionMgt.GetRtngVersion("Routing No.", CalculateDate, false);

                SingleLevelMfgOvhd := "Single-Level Mfg. Ovhd Cost";

                FooterProdTotalCost := 0;
                FooterCostTotal := 0;
            end;

            trigger OnPreDataItem()
            begin
                ItemFilter := GetFilters();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Detailed Calculation';
        AboutText = 'This report provides a detailed breakdown of manufacturing costs, including Production BOM details, Routing operations, and associated expenses. It also accounts for scrap costs, ensuring an accurate total cost for producing the item.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CalculationDate; CalculateDate)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Calculation Date';
                        ToolTip = 'Specifies the specific date for which to get the cost list. The standard entry in this field is the working date.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            CalculateDate := WorkDate();
        end;
    }

    labels
    {
        ProdUnitCostCaption = 'Unit Cost';
    }

    trigger OnInitReport()
    begin
        MfgSetup.Get();
    end;

    trigger OnPreReport()
    begin
        OnBeforeOnPreReport(Item);
    end;

    var
        MfgSetup: Record "Manufacturing Setup";
        ProdBOMHeader: Record "Production BOM Header";
        UOMMgt: Codeunit "Unit of Measure Management";
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        VersionMgt: Codeunit VersionManagement;
        RtngVersionCode: Code[20];
        ItemFilter: Text;
        InBOM: Boolean;
        InRouting: Boolean;
        DirectUnitCost: Decimal;
        IndirectCostPct: Decimal;
        OverheadRate: Decimal;

        CalculateDateLbl: Label 'As of ';
        CurrReportPageNoCaptLbl: Label 'Page';
        DetailedCalculationCaptLbl: Label 'Detailed Calculation';
        CostTimeCaptionLbl: Label 'Cost Time';
        ProdTotalCostCaptionLbl: Label 'Total Cost';
        ProdBOMLineLevelNoCaptionLbl: Label 'No.';
        ProdBOMLineLevelDescCaptLbl: Label 'Description';
        ProdBOMLineLevelQtyCaptLbl: Label 'Quantity (Base)';
        CostTotalCaptionLbl: Label 'Total Cost';
        ProdBOMLineLevelTypeCaptLbl: Label 'Type';
        CompItemBaseUOMCaptLbl: Label 'Base Unit of Measure Code';
        ProdTotalCostCaptLbl: Label 'Cost of Production';
        CostTotalCaptLbl: Label 'Cost of Components';
        SingleLevelMfgOvhdCaptionLbl: Label 'Single-Level Mfg. Overhead Cost';

    protected var
        CompItem: Record Item;
        ProdBOMLine: array[99] of Record "Production BOM Line";
        PBOMNoList: array[99] of Code[20];
        PBOMVersionCode: array[99] of Code[20];
        Quantity: array[99] of Decimal;
        CalculateDate: Date;
        Level: Integer;
        NextLevel: Integer;
        CompItemQtyBase: Decimal;
        CostTotal: Decimal;
        ProdUnitCost: Decimal;
        ProdTotalCost: Decimal;
        CostTime: Decimal;
        SingleLevelMfgOvhd: Decimal;
        FooterProdTotalCost: Decimal;
        FooterCostTotal: Decimal;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordBOMLoopOnAfterProdBOMLineLevelSetFilters(var ProductionBOMLineArray: array[99] of Record "Production BOM Line"; var Level: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreDataItemBOMLoopOnProdBOMLineLevelSetFilters(var ProductionBOMLineArray: array[99] of Record "Production BOM Line"; var Level: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreReport(var Item: Record Item)
    begin
    end;
}

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using System.Utilities;

report 99001500 "Subc. Detailed Calculation"
{
    ApplicationArea = Manufacturing;
    Caption = 'Detailed Calculation';
    DefaultLayout = RDLC;
    RDLCLayout = 'src\Process\Reports\Rep99001500.SubcDetailedCalculation.rdl';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("Low-Level Code");
            RequestFilterFields = "No.";
            column(BaseUnitOfMeasure_Item; "Base Unit of Measure")
            {
            }
            column(CalculateDate; AsOfLbl + Format(CalculateDate))
            {
            }
            column(CompanyName; CompanyProperty.DisplayName())
            {
            }
            column(Description_Item; Description)
            {
                IncludeCaption = true;
            }
            column(DetailedCalculationCaption; DetailedCalculationCaptionLbl)
            {
            }
            column(ItemFilter; ItemFilter)
            {
            }
            column(ItemFilterCaption; Item.TableCaption() + ': ' + ItemFilter)
            {
            }
            column(LotSize_Item; "Lot Size")
            {
                IncludeCaption = true;
            }
            column(No_Item; "No.")
            {
                IncludeCaption = true;
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(PBOMVersionCode1; PBOMVersionCode[1])
            {
            }
            column(ProductionBOMNo_Item; "Production BOM No.")
            {
                IncludeCaption = true;
            }
            column(RoutingNo_Item; "Routing No.")
            {
                IncludeCaption = true;
            }
            column(RtngVersionCode; RtngVersionCode)
            {
            }
            column(TodayFormatted; Format(Today(), 0, 4))
            {
            }
            column(UnitCostCaption; UnitCostCaptionLbl)
            {
            }
            dataitem("Routing Line"; "Routing Line")
            {
                DataItemLink = "Routing No." = field("Routing No.");
                DataItemTableView = sorting("Routing No.", "Version Code", "Operation No.");
                column(CostTime; CostTime)
                {
                    DecimalPlaces = 0 : 5;
                }
                column(CostTimeCaption; CostTimeCaptionLbl)
                {
                }
                column(Description_RtngLine; Description)
                {
                    IncludeCaption = true;
                }
                column(InRouting; InRouting)
                {
                }
                column(No_RtngLine; "No.")
                {
                    IncludeCaption = true;
                }
                column(OperationNo_RtngLine; "Operation No.")
                {
                    IncludeCaption = true;
                }
                column(ProdTotalCost; ProdTotalCost)
                {
                    AutoFormatType = 1;
                }
                column(ProdUnitCost; ProdUnitCost)
                {
                    AutoFormatType = 2;
                }
                column(RunTime_RtngLine; "Run Time")
                {
                    IncludeCaption = true;
                }
                column(SetupTime_RtngLine; "Setup Time")
                {
                    IncludeCaption = true;
                }
                column(TotalCostCaption; TotalCostCaptionLbl)
                {
                }
                column(Type_RtngLine; Type)
                {
                    IncludeCaption = true;
                }
                column(VersionCode_RtngLine; "Version Code")
                {
                }
                trigger OnAfterGetRecord()
                var
                    SubcontractorPrice: Record "Subcontractor Price";
                    WorkCenter: Record "Work Center";
                    SubcPriceManagement: Codeunit "Subc. Price Management";
                    UnitCostCalculationType: Enum "Unit Cost Calculation Type";
                begin
                    ProdUnitCost := "Unit Cost per";

                    if "Routing Line".Type = "Routing Line".Type::"Work Center" then
                        WorkCenter.Get("Routing Line"."Work Center No.");
                    if ("Routing Line".Type = "Routing Line".Type::"Work Center") and
                       (WorkCenter."Subcontractor No." <> '')
                    then begin
                        SubcontractorPrice."Vendor No." := WorkCenter."Subcontractor No.";
                        SubcontractorPrice."Item No." := Item."No.";
                        SubcontractorPrice."Standard Task Code" := "Routing Line"."Standard Task Code";
                        SubcontractorPrice."Work Center No." := WorkCenter."No.";
                        SubcontractorPrice."Variant Code" := '';
                        SubcontractorPrice."Unit of Measure Code" := Item."Base Unit of Measure";
                        SubcontractorPrice."Starting Date" := CalculateDate;
                        SubcontractorPrice."Currency Code" := '';
                        SubcPriceManagement.SetRoutingPriceListCost(
                          SubcontractorPrice,
                          WorkCenter,
                          DirectUnitCost,
                          IndirectCostPct,
                          OverheadRate,
                          ProdUnitCost,
                          UnitCostCalculationType,
                          1,
                          1,
                          1);
                    end else
                        MfgCostCalculationMgt.CalcRoutingCostPerUnit(
                          Type,
                          "No.",
                          DirectUnitCost,
                          IndirectCostPct,
                          OverheadRate, ProdUnitCost, UnitCostCalculationType);

                    CostTime :=
                      MfgCostCalculationMgt.CalculateCostTime(
                        MfgCostCalculationMgt.CalcQtyAdjdForBOMScrap(Item."Lot Size", Item."Scrap %"),
                        "Setup Time", "Setup Time Unit of Meas. Code",
                        "Run Time", "Run Time Unit of Meas. Code", "Lot Size",
                        "Scrap Factor % (Accumulated)", "Fixed Scrap Qty. (Accum.)",
                        "Work Center No.", UnitCostCalculationType, ManufacturingSetup."Cost Incl. Setup",
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
                column(BaseUnitOfMeasureCaption; BaseUnitOfMeasureCaptionLbl)
                {
                }
                column(DescriptionCaption; DescriptionCaptionLbl)
                {
                }
                column(InBOM; InBOM)
                {
                }
                column(NoCaption; NoCaptionLbl)
                {
                }
                column(QuantityCaption; QuantityCaptionLbl)
                {
                }
                column(TotalCost1Caption; TotalCost1CaptionLbl)
                {
                }
                column(TypeCaption; TypeCaptionLbl)
                {
                }
                dataitem(BOMComponentLine; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 1;
                    column(CompItemBaseUOM; CompItem."Base Unit of Measure")
                    {
                    }
                    column(CompItemUnitCost; CompItem."Unit Cost")
                    {
                        AutoFormatType = 2;
                        DecimalPlaces = 2 : 5;
                    }
                    column(CostTotal; CostTotal)
                    {
                        AutoFormatType = 1;
                    }
                    column(ProdBOMLineLevelDesc; ProdBOMLine[Level].Description)
                    {
                    }
                    column(ProdBOMLineLevelNo; ProdBOMLine[Level]."No.")
                    {
                    }
                    column(ProdBOMLineLevelQuantity; ProdBOMLine[Level].Quantity)
                    {
                    }
                    column(ProdBOMLineLevelType; Format(ProdBOMLine[Level].Type))
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
                    while ProdBOMLine[Level].Next() = 0 do begin
                        Level := Level - 1;
                        if Level < 1 then
                            CurrReport.Break();
                        ProdBOMLine[Level].SetRange("Production BOM No.", PBOMNoList[Level]);
                        ProdBOMLine[Level].SetRange("Version Code", PBOMVersionCode[Level]);
                    end;

                    NextLevel := Level;
                    Clear(CompItem);

                    if Level = 1 then
                        UOMFactor :=
                          UnitofMeasureManagement.GetQtyPerUnitOfMeasure(Item, VersionManagement.GetBOMUnitOfMeasure(PBOMNoList[Level], PBOMVersionCode[Level]))
                    else
                        UOMFactor := 1;

                    CompItemQtyBase :=
                      MfgCostCalculationMgt.CalcCompItemQtyBase(ProdBOMLine[Level], CalculateDate, Quantity[Level], Item."Routing No.", Level = 1) /
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
                                  VersionManagement.GetBOMVersion(ProdBOMLine[Level]."No.", CalculateDate, false);
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

                    Clear(CostTotal);
                    Level := 1;

                    ProductionBOMHeader.Get(PBOMNoList[Level]);

                    Clear(ProdBOMLine);
                    ProdBOMLine[Level].SetRange("Production BOM No.", PBOMNoList[Level]);
                    ProdBOMLine[Level].SetRange("Version Code", PBOMVersionCode[Level]);
                    ProdBOMLine[Level].SetFilter("Starting Date", '%1|..%2', 0D, CalculateDate);
                    ProdBOMLine[Level].SetFilter("Ending Date", '%1|%2..', 0D, CalculateDate);

                    Quantity[Level] := MfgCostCalculationMgt.CalcQtyAdjdForBOMScrap(Item."Lot Size", Item."Scrap %");

                    InBOM := true;
                end;
            }
            dataitem(Footer; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(Number_IntegerLine; Number)
                {
                }
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(CostOfComponentsCaption; CostOfComponentsCaptionLbl)
                {
                }
                column(CostOfProductionCaption; CostOfProductionCaptionLbl)
                {
                }
                column(FooterCostTotal; FooterCostTotal)
                {
                }
                column(FooterProdTotalCost; FooterProdTotalCost)
                {
                }
                column(FormatCostTotal; CostTotal)
                {
                    AutoFormatType = 1;
                }
                column(SingleLevelMfgOverheadCostCaption; SingleLevelMfgOverheadCostCaptionLbl)
                {
                }
                column(SingleLevelMfgOvhd; SingleLevelMfgOvhd)
                {
                    AutoFormatType = 1;
                }
                column(TotalProdTotalCost; ProdTotalCost)
                {
                    AutoFormatType = 1;
                }
                column(UnitCost_Item; Item."Unit Cost")
                {
                    AutoFormatType = 1;
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
                      VersionManagement.GetBOMVersion("Production BOM No.", CalculateDate, false);

                if "Routing No." <> '' then
                    RtngVersionCode := VersionManagement.GetRtngVersion("Routing No.", CalculateDate, false);

                SingleLevelMfgOvhd := Item."Single-Level Mfg. Ovhd Cost";

                FooterProdTotalCost := 0;
                FooterCostTotal := 0;
            end;

            trigger OnPreDataItem()
            begin
                ItemFilter := Item.GetFilters();
            end;
        }
    }
    requestpage
    {
        layout
        {
            area(Content)
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
    trigger OnInitReport()
    begin
        ManufacturingSetup.Get();
    end;

    var
        CompItem: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        ProdBOMLine: array[99] of Record "Production BOM Line";
        MfgCostCalculationMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        UnitofMeasureManagement: Codeunit "Unit of Measure Management";
        VersionManagement: Codeunit VersionManagement;
        InBOM: Boolean;
        InRouting: Boolean;
        PBOMNoList: array[99] of Code[20];
        PBOMVersionCode: array[99] of Code[20];
        RtngVersionCode: Code[20];
        CalculateDate: Date;
        CompItemQtyBase: Decimal;
        CostTime: Decimal;
        CostTotal: Decimal;
        DirectUnitCost: Decimal;
        FooterCostTotal: Decimal;
        FooterProdTotalCost: Decimal;
        IndirectCostPct: Decimal;
        OverheadRate: Decimal;
        ProdTotalCost: Decimal;
        ProdUnitCost: Decimal;
        Quantity: array[99] of Decimal;
        SingleLevelMfgOvhd: Decimal;
        Level: Integer;
        NextLevel: Integer;
        AsOfLbl: Label 'As of ';
        BaseUnitOfMeasureCaptionLbl: Label 'Base Unit of Measure Code';
        CostOfComponentsCaptionLbl: Label 'Cost of Components';
        CostOfProductionCaptionLbl: Label 'Cost of Production';
        CostTimeCaptionLbl: Label 'Cost Time';
        DescriptionCaptionLbl: Label 'Description';
        DetailedCalculationCaptionLbl: Label 'Detailed Calculation';
        NoCaptionLbl: Label 'No.';
        PageNoCaptionLbl: Label 'Page';
        QuantityCaptionLbl: Label 'Quantity (Base)';
        SingleLevelMfgOverheadCostCaptionLbl: Label 'Single-Level Mfg. Overhead Cost';
        TotalCost1CaptionLbl: Label 'Total Cost';
        TotalCostCaptionLbl: Label 'Total Cost';
        TypeCaptionLbl: Label 'Type';
        UnitCostCaptionLbl: Label 'Unit Cost';
        ItemFilter: Text;
}
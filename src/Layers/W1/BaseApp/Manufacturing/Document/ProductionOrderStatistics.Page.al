// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Costing;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Setup;

page 99000816 "Production Order Statistics"
{
    Caption = 'Production Order Statistics';
    DataCaptionFields = "No.", Description;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Production Order";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                fixed(Control1903895301)
                {
                    ShowCaption = false;
                    group("Standard Cost")
                    {
                        Caption = 'Standard Cost';
                        field(MaterialCost_StandardCost; StdCost[1])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Caption = 'Material Cost';
                            Editable = false;
                            ToolTip = 'Specifies the material cost related to the production order.';
                        }
                        field(NonInventoryMaterialCost_StandardCost; NonInvStdCost)
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Caption = 'Non-Inventory Material Cost';
                            Editable = false;
                            ToolTip = 'Specifies the non-inventory material cost related to the production order.';
                        }
                        field(CapacityCost_StandardCost; StdCost[2])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Caption = 'Capacity Cost';
                            Editable = false;
                            ToolTip = 'Specifies the cost amount of all production capacities (machine and work centers) that are used for lines in the production order.';
                        }
                        field("StdCost[3]"; StdCost[3])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Caption = 'Subcontracted Cost';
                            Editable = false;
                            ToolTip = 'Specifies the subcontracted cost amount of all the lines in the production order.';
                        }
                        field("StdCost[4]"; StdCost[4])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Caption = 'Capacity Overhead';
                            Editable = false;
                            ToolTip = 'Specifies the capacity overhead amount of all the lines in the production order.';
                        }
                        field("StdCost[5]"; StdCost[5])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Caption = 'Manufacturing Overhead';
                            Editable = false;
                            ToolTip = 'Specifies the manufacturing overhead related to the production order.';
                        }
                        field(TotalCost_StandardCost; StdCost[6])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Caption = 'Total Cost';
                            Editable = false;
                            ToolTip = 'Specifies the sum of the lines in each column.';
                        }
                        field(CapacityUoM; CapacityUoM)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Capacity Need';
                            TableRelation = "Capacity Unit of Measure".Code;
                            ToolTip = 'Specifies the total capacity need of all the lines in the production order.';

                            trigger OnValidate()
                            var
                                CalendarMgt: Codeunit "Shop Calendar Management";
                            begin
                                ExpCapNeed := MfgCostCalcMgt.CalcProdOrderExpCapNeed(Rec, false) / CalendarMgt.TimeFactor(CapacityUoM);
                                ActTimeUsed := MfgCostCalcMgt.CalcProdOrderActTimeUsed(Rec, false) / CalendarMgt.TimeFactor(CapacityUoM);
                            end;
                        }
                    }
                    group("Expected Cost")
                    {
                        Caption = 'Expected Cost';
                        field(MaterialCost_ExpectedCost; ExpCost[1])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(NonInventoryMaterialCost_ExpectedCost; NonInvExpCost)
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(CapacityCost_ExpectedCost; ExpCost[2])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("ExpCost[3]"; ExpCost[3])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("ExpCost[4]"; ExpCost[4])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(MfgOverhead_ExpectedCost; ExpCost[5])
                        {
                            ApplicationArea = Manufacturing;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(TotalCost_ExpectedCost; ExpCost[6])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(ExpCapNeed; ExpCapNeed)
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;

                            trigger OnDrillDown()
                            begin
                                MfgCostCalcMgt.CalcProdOrderExpCapNeed(Rec, true);
                            end;
                        }
                    }
                    group("Actual Cost")
                    {
                        Caption = 'Actual Cost';
                        field(MaterialCost_ActualCost; ActCost[1])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(NonInventoryMaterialCost_ActualCost; NonInvActCost)
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(CapacityCost_ActualCost; ActCost[2])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("ActCost[3]"; ActCost[3])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("ActCost[4]"; ActCost[4])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("ActCost[5]"; ActCost[5])
                        {
                            ApplicationArea = Manufacturing;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(TotalCost_ActualCost; ActCost[6])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(ActTimeUsed; ActTimeUsed)
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;

                            trigger OnDrillDown()
                            begin
                                MfgCostCalcMgt.CalcProdOrderActTimeUsed(Rec, true);
                            end;
                        }
                    }
                    group("Dev. %")
                    {
                        Caption = 'Dev. %';
                        field("VarPct[1]"; VarPct[1])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("NonInventoryVarPct"; NonInvVarPct)
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("VarPct[2]"; VarPct[2])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("VarPct[3]"; VarPct[3])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("VarPct[4]"; VarPct[4])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("VarPct[5]"; VarPct[5])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("VarPct[6]"; VarPct[6])
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(TimeExpendedPct; TimeExpendedPct)
                        {
                            ApplicationArea = Manufacturing;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;
                        }
                    }
                    group(Variance)
                    {
                        Caption = 'Variance';
                        field("VarAmt[1]"; VarAmt[1])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("NonInventoryVarAmt"; NonInvVarAmt)
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("VarAmt[2]"; VarAmt[2])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("VarAmt[3]"; VarAmt[3])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("VarAmt[4]"; VarAmt[4])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("VarAmt[5]"; VarAmt[5])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field("VarAmt[6]"; VarAmt[6])
                        {
                            ApplicationArea = Manufacturing;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                    }
                }
            }
            group(Components)
            {
                Caption = 'Components';

                field("Reserved From Stock"; Rec.GetQtyReservedFromStockState())
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    Caption = 'Reserved from stock';
                    ToolTip = 'Specifies what part of the component items is reserved from inventory.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        CalendarMgt: Codeunit "Shop Calendar Management";
    begin
        Clear(StdCost);
        Clear(ExpCost);
        Clear(ActCost);
        Clear(MfgCostCalcMgt);
        Clear(NonInvStdCost);
        Clear(NonInvExpCost);
        Clear(NonInvActCost);

        GLSetup.Get();

        ExpCapNeed := MfgCostCalcMgt.CalcProdOrderExpCapNeed(Rec, false) / CalendarMgt.TimeFactor(CapacityUoM);
        ActTimeUsed := MfgCostCalcMgt.CalcProdOrderActTimeUsed(Rec, false) / CalendarMgt.TimeFactor(CapacityUoM);
        ProdOrderLine.SetRange(Status, Rec.Status);
        ProdOrderLine.SetRange("Prod. Order No.", Rec."No.");
        ProdOrderLine.SetRange("Planning Level Code", 0);
        ProdOrderLine.SetFilter("Item No.", '<>%1', '');
        if ProdOrderLine.Find('-') then
            repeat
                MfgCostCalcMgt.CalcShareOfTotalCapCost(ProdOrderLine, ShareOfTotalCapCost);

                if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then begin
                    MfgCostCalcMgt.CalcProdOrderLineStdCost(
                      ProdOrderLine, 1, GLSetup."Amount Rounding Precision",
                      StdCost[1], NonInvStdCost, StdCost[2], StdCost[3], StdCost[4], StdCost[5]);
                    MfgCostCalcMgt.CalcProdOrderLineExpCost(
                      ProdOrderLine, ShareOfTotalCapCost,
                      ExpCost[1], NonInvExpCost, ExpCost[2], ExpCost[3], ExpCost[4], ExpCost[5]);
                    MfgCostCalcMgt.CalcProdOrderLineActCost(
                      ProdOrderLine,
                      ActCost[1], NonInvActCost, ActCost[2], ActCost[3], ActCost[4], ActCost[5],
                      DummyVar, DummyVar, DummyVar, DummyVar, DummyVar, DummyVar);
                end else begin
                    MfgCostCalcMgt.CalcProdOrderLineStdCost(
                      ProdOrderLine, 1, GLSetup."Amount Rounding Precision",
                      StdCost[1], StdCost[2], StdCost[3], StdCost[4], StdCost[5]);
                    MfgCostCalcMgt.CalcProdOrderLineExpCost(
                      ProdOrderLine, ShareOfTotalCapCost,
                      ExpCost[1], ExpCost[2], ExpCost[3], ExpCost[4], ExpCost[5]);
                    MfgCostCalcMgt.CalcProdOrderLineActCost(
                      ProdOrderLine,
                      ActCost[1], ActCost[2], ActCost[3], ActCost[4], ActCost[5],
                      DummyVar, DummyVar, DummyVar, DummyVar, DummyVar);
                end;
            until ProdOrderLine.Next() = 0;

        CalcTotal(StdCost, StdCost[6]);
        CalcTotal(ExpCost, ExpCost[6]);
        CalcTotal(ActCost, ActCost[6]);
        if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then begin
            StdCost[6] += NonInvStdCost;
            ExpCost[6] += NonInvExpCost;
            ActCost[6] += NonInvActCost;
            NonInvVarAmt := NonInvActCost - NonInvStdCost;
            NonInvVarPct := CalcIndicatorPct(NonInvStdCost, NonInvActCost);
        end;

        CalcVariance();
        TimeExpendedPct := CalcIndicatorPct(ExpCapNeed, ActTimeUsed);
    end;

    trigger OnOpenPage()
    var
        MfgSetup: Record "Manufacturing Setup";
    begin
        MfgSetup.Get();
        MfgSetup.TestField("Show Capacity In");
        CapacityUoM := MfgSetup."Show Capacity In";
    end;

    var
        ProdOrderLine: Record "Prod. Order Line";
        GLSetup: Record "General Ledger Setup";
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        DummyVar: Decimal;
        ShareOfTotalCapCost: Decimal;
        TimeExpendedPct: Decimal;
        ExpCapNeed: Decimal;
        ActTimeUsed: Decimal;
        CapacityUoM: Code[10];

    protected var
        StdCost: array[6] of Decimal;
        ExpCost: array[6] of Decimal;
        ActCost: array[6] of Decimal;
        VarAmt: array[6] of Decimal;
        VarPct: array[6] of Decimal;
        NonInvStdCost: Decimal;
        NonInvExpCost: Decimal;
        NonInvActCost: Decimal;
        NonInvVarAmt: Decimal;
        NonInvVarPct: Decimal;

    local procedure CalcTotal(Operand: array[6] of Decimal; var Total: Decimal)
    var
        i: Integer;
    begin
        Total := 0;

        for i := 1 to ArrayLen(Operand) - 1 do
            Total := Total + Operand[i];
    end;

    local procedure CalcVariance()
    var
        i: Integer;
        IsHandled: Boolean;
    begin
        for i := 1 to ArrayLen(VarAmt) do begin
            IsHandled := false;
            OnBeforeCalcVariance(VarAmt, VarPct, StdCost, ActCost, i, IsHandled, ExpCost);
            if not IsHandled then begin
                VarAmt[i] := ActCost[i] - StdCost[i];
                VarPct[i] := CalcIndicatorPct(StdCost[i], ActCost[i]);
            end;
        end;
    end;

    local procedure CalcIndicatorPct(Value: Decimal; "Sum": Decimal): Decimal
    begin
        if Value = 0 then
            exit(0);

        exit(Round((Sum - Value) / Value * 100, 1));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcVariance(var VarAmt: array[6] of Decimal; var VarPct: array[6] of Decimal; var StdCost: array[6] of Decimal; var ActCost: array[6] of Decimal; i: Integer; var IsHandled: Boolean; var ExpCost: array[6] of Decimal)
    begin
    end;
}


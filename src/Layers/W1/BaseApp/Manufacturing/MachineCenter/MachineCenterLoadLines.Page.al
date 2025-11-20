// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.MachineCenter;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using System.Utilities;

page 99000890 "Machine Center Load Lines"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = "Load Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Period Start"; Rec."Period Start")
                {
                    ApplicationArea = Planning;
                    Caption = 'Period Start';
                    ToolTip = 'Specifies the starting date for the evaluation of the machine centers, which according to the actual planning are overloaded.';
                }
                field("Period Name"; Rec."Period Name")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the name of the period shown in the line.';
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Capacity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the amount of work that can be done in a specified time period at this machine center.';

                    trigger OnDrillDown()
                    var
                        CalendarEntry: Record "Calendar Entry";
                    begin
                        CalendarEntry.SetRange("Capacity Type", CalendarEntry."Capacity Type"::"Machine Center");
                        CalendarEntry.SetRange("No.", MachineCenter."No.");
                        CalendarEntry.SetRange(Date, Rec."Period Start", Rec."Period End");

                        PAGE.Run(0, CalendarEntry);
                    end;
                }
                field(AllocatedQty; Rec."Allocated Qty.")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Allocated Qty.';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the amount of capacity that is needed to produce a desired output in a given time period. ';

                    trigger OnDrillDown()
                    var
                        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
                    begin
                        ProdOrderCapNeed.SetCurrentKey(Type, "No.", "Starting Date-Time");
                        ProdOrderCapNeed.SetRange(Type, ProdOrderCapNeed.Type::"Machine Center");
                        ProdOrderCapNeed.SetRange("No.", MachineCenter."No.");
                        ProdOrderCapNeed.SetRange(Date, Rec."Period Start", Rec."Period End");
                        ProdOrderCapNeed.SetRange("Requested Only", false);
                        PAGE.Run(0, ProdOrderCapNeed);
                    end;
                }
                field(CapacityAvailable; Rec."Availability After Orders")
                {
                    ApplicationArea = Planning;
                    Caption = 'Availability After Orders';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the available capacity of this machine center that is not used in the planning of a given time period.';
                }
                field(CapacityEfficiency; Rec.Load)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Load';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the sum of the required number of times that all the planned and actual orders are run on the machine center in a specified period.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if DateRec.Get(Rec."Period Type", Rec."Period Start") then;
        CalcLine();
    end;

    trigger OnFindRecord(Which: Text) FoundDate: Boolean
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        FoundDate := PeriodFormLinesMgt.FindDate(VariantRec, DateRec, Which, PeriodType.AsInteger());
        Rec := VariantRec;
    end;

    trigger OnNextRecord(Steps: Integer) ResultSteps: Integer
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        ResultSteps := PeriodFormLinesMgt.NextDate(VariantRec, DateRec, Steps, PeriodType.AsInteger());
        Rec := VariantRec;
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
    end;

    var
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";

    protected var
        MachineCenter: Record "Machine Center";
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";

    procedure SetLines(var NewMachineCenter: Record "Machine Center"; NewPeriodType: Enum "Analysis Period Type"; NewAmountType: Enum "Analysis Amount Type")
    begin
        MachineCenter.Copy(NewMachineCenter);
        Rec.DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            MachineCenter.SetRange("Date Filter", Rec."Period Start", Rec."Period End")
        else
            MachineCenter.SetRange("Date Filter", 0D, Rec."Period End");
    end;

    local procedure CalcLine()
    begin
        SetDateFilter();
        MachineCenter.CalcFields("Capacity (Effective)", "Prod. Order Need (Qty.)");
        Rec.Capacity := MachineCenter."Capacity (Effective)";
        Rec."Allocated Qty." := MachineCenter."Prod. Order Need (Qty.)";
        Rec."Availability After Orders" := MachineCenter."Capacity (Effective)" - MachineCenter."Prod. Order Need (Qty.)";
        if MachineCenter."Capacity (Effective)" <> 0 then
            Rec.Load := Round(MachineCenter."Prod. Order Need (Qty.)" / MachineCenter."Capacity (Effective)" * 100, 0.1)
        else
            Rec.Load := 0;

        OnAfterCalcLine(MachineCenter, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLine(var MachineCenter: Record "Machine Center"; var LoadBuffer: Record "Load Buffer")
    begin
    end;
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.WorkCenter;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using System.Utilities;

page 99000888 "Work Center Load Lines"
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
                    ApplicationArea = Manufacturing;
                    Caption = 'Period Start';
                    ToolTip = 'Specifies the starting date for the evaluation of the load on a work center.';
                }
                field("Period Name"; Rec."Period Name")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Period Name';
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Capacity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the amount of work that can be done in a specified time period at this work center group. ';

                    trigger OnDrillDown()
                    var
                        CalendarEntry: Record "Calendar Entry";
                    begin
                        CurrPage.Update(true);
                        CalendarEntry.SetRange("Capacity Type", CalendarEntry."Capacity Type"::"Work Center");
                        CalendarEntry.SetRange("No.", WorkCenter."No.");
                        CalendarEntry.SetFilter(Date, WorkCenter.GetFilter("Date Filter"));
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
                        CurrPage.Update(true);
                        ProdOrderCapNeed.SetCurrentKey("Work Center No.", Date);
                        ProdOrderCapNeed.SetRange("Requested Only", false);
                        ProdOrderCapNeed.SetRange("Work Center No.", WorkCenter."No.");
                        ProdOrderCapNeed.SetFilter(Date, WorkCenter.GetFilter("Date Filter"));
                        PAGE.Run(0, ProdOrderCapNeed);
                    end;
                }
                field(CapacityAvailable; Rec."Availability After Orders")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Availability After Orders';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the available capacity of this resource.';
                }
                field(CapacityEfficiency; Rec.Load)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Load';
                    DecimalPlaces = 0 : 5;
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
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";

    protected var
        WorkCenter: Record "Work Center";
        CapacityUoM: Code[10];

    procedure SetLines(var NewWorkCenter: Record "Work Center"; NewPeriodType: Enum "Analysis Period Type"; NewAmountType: Enum "Analysis Amount Type")
    var
        MfgSetup: Record "Manufacturing Setup";
    begin
        MfgSetup.SetLoadFields("Show Capacity In");
        MfgSetup.Get();
        MfgSetup.TestField("Show Capacity In");
        CapacityUoM := MfgSetup."Show Capacity In";
        SetLines(NewWorkCenter, NewPeriodType, NewAmountType, CapacityUoM);
    end;

    procedure SetLines(var NewWorkCenter: Record "Work Center"; NewPeriodType: Enum "Analysis Period Type"; NewAmountType: Enum "Analysis Amount Type"; NewCapUoM: Code[10])
    begin
        WorkCenter.Copy(NewWorkCenter);
        Rec.DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CapacityUoM := NewCapUoM;
        CurrPage.Update(false);

        OnAfterSetLines(WorkCenter, PeriodType, AmountType);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            WorkCenter.SetRange("Date Filter", Rec."Period Start", Rec."Period End")
        else
            WorkCenter.SetRange("Date Filter", 0D, Rec."Period End");
    end;

    local procedure CalcLine()
    var
        CalendarMgt: Codeunit "Shop Calendar Management";
        CapacityTimeFactor: Decimal;
    begin
        SetDateFilter();
        WorkCenter.CalcFields("Capacity (Effective)", "Prod. Order Need (Qty.)");
        if (CapacityUoM <> '') and (WorkCenter."Unit of Measure Code" <> '') then
            CapacityTimeFactor :=
                CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code") /
                CalendarMgt.TimeFactor(CapacityUoM)
        else
            CapacityTimeFactor := 1;
        Rec.Capacity := WorkCenter."Capacity (Effective)" * CapacityTimeFactor;
        Rec."Allocated Qty." := WorkCenter."Prod. Order Need (Qty.)" * CapacityTimeFactor;
        Rec."Availability After Orders" := Rec.Capacity - Rec."Allocated Qty.";
        if WorkCenter."Capacity (Effective)" <> 0 then
            Rec.Load := Round(WorkCenter."Prod. Order Need (Qty.)" / WorkCenter."Capacity (Effective)" * 100, 0.1)
        else
            Rec.Load := 0;

        OnAfterCalcLine(WorkCenter, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLine(var WorkCenter: Record "Work Center"; var LoadBuffer: Record "Load Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetLines(var WorkCenter: Record "Work Center"; PeriodType: Enum "Analysis Period Type"; AmountType: Enum "Analysis Amount Type")
    begin
    end;
}


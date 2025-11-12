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

page 99000892 "Work Center Group Load Lines"
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
                    ToolTip = 'Specifies the starting date of the period that you want to view, for an overview of availability at the current work center group.';
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
                    ToolTip = 'Specifies the amount of work that can be done in a specified time period at this work center group. ';

                    trigger OnDrillDown()
                    var
                        CalendarEntry: Record "Calendar Entry";
                    begin
                        CalendarEntry.SetCurrentKey("Work Center Group Code");
                        CalendarEntry.SetRange("Work Center Group Code", WorkCenterGroup.Code);
                        CalendarEntry.SetFilter(Date, WorkCenterGroup.GetFilter("Date Filter"));
                        PAGE.Run(0, CalendarEntry);
                    end;
                }
#pragma warning disable AA0100
                field("WorkCenterGroup.""Prod. Order Need (Qty.)"""; Rec."Allocated Qty.")
#pragma warning restore AA0100
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Allocated Qty.';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the amount of capacity that is needed to produce a desired output in a given time period. ';

                    trigger OnDrillDown()
                    var
                        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
                    begin
                        ProdOrderCapNeed.SetCurrentKey("Work Center Group Code", Date);
                        ProdOrderCapNeed.SetRange("Requested Only", false);
                        ProdOrderCapNeed.SetRange("Work Center Group Code", WorkCenterGroup.Code);
                        ProdOrderCapNeed.SetFilter(Date, WorkCenterGroup.GetFilter("Date Filter"));
                        PAGE.Run(0, ProdOrderCapNeed);
                    end;
                }
                field(CapacityAvailable; Rec."Availability After Orders")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Availability After Orders';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the available capacity of this work center group that is not used in the planning of a given time period.';
                }
                field(CapacityEfficiency; Rec.Load)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Load';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the sum of the required number of times that all the planned and actual orders are run on the work center group in a specified period.';
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
        MfgSetup.Get();
        MfgSetup.TestField("Show Capacity In");
    end;

    var
        MfgSetup: Record "Manufacturing Setup";
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";

    protected var
        WorkCenterGroup: Record "Work Center Group";
        CapacityUoM: Code[10];
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";

    procedure SetLines(var NewWorkCenterGroup: Record "Work Center Group"; NewPeriodType: Enum "Analysis Period Type"; NewAmountType: Enum "Analysis Amount Type"; NewCapUoM: Code[10])
    begin
        WorkCenterGroup.Copy(NewWorkCenterGroup);
        Rec.DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CapacityUoM := NewCapUoM;
        CurrPage.Update(false);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            WorkCenterGroup.SetRange("Date Filter", Rec."Period Start", Rec."Period End")
        else
            WorkCenterGroup.SetRange("Date Filter", 0D, Rec."Period End");
    end;

    local procedure CalculateCapacity(var WorkCenterGroup: Record "Work Center Group")
    var
        WorkCenter: Record "Work Center";
        CalendarMgt: Codeunit "Shop Calendar Management";
    begin
        if CapacityUoM = '' then
            CapacityUoM := MfgSetup."Show Capacity In";

        OnBeforeCalculateCapacity(WorkCenterGroup, CapacityUoM);

        Clear(WorkCenterGroup."Capacity (Effective)");
        Clear(WorkCenterGroup."Prod. Order Need (Qty.)");

        WorkCenter.SetCurrentKey("Work Center Group Code");
        WorkCenter.SetRange("Work Center Group Code", WorkCenterGroup.Code);
        if WorkCenter.FindSet() then
            repeat
                WorkCenterGroup.CopyFilter("Date Filter", WorkCenter."Date Filter");
                WorkCenter.CalcFields("Capacity (Effective)", "Prod. Order Need (Qty.)");
                WorkCenterGroup."Capacity (Effective)" +=
                    WorkCenter."Capacity (Effective)" *
                    CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code") /
                    CalendarMgt.TimeFactor(CapacityUoM);

                WorkCenterGroup."Prod. Order Need (Qty.)" +=
                    WorkCenter."Prod. Order Need (Qty.)" *
                    CalendarMgt.TimeFactor(WorkCenter."Unit of Measure Code") /
                    CalendarMgt.TimeFactor(CapacityUoM);

                OnAfterCalculateWorkCenterCapacity(WorkCenter, WorkCenterGroup, CapacityUoM);
            until WorkCenter.Next() = 0;

        OnAfterCalculateCapacity(WorkCenterGroup, CapacityUoM);
    end;

    local procedure CalcLine()
    begin
        SetDateFilter();
        CalculateCapacity(WorkCenterGroup);
        Rec.Capacity := WorkCenterGroup."Capacity (Effective)";
        Rec."Allocated Qty." := WorkCenterGroup."Prod. Order Need (Qty.)";
        Rec."Availability After Orders" := WorkCenterGroup."Capacity (Effective)" - WorkCenterGroup."Prod. Order Need (Qty.)";
        if WorkCenterGroup."Capacity (Effective)" <> 0 then
            Rec.Load := Round(WorkCenterGroup."Prod. Order Need (Qty.)" / WorkCenterGroup."Capacity (Effective)" * 100, 0.1)
        else
            Rec.Load := 0;

        OnAfterCalcLine(WorkCenterGroup, Rec, CapacityUoM);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLine(var WorkCenterGroup: Record "Work Center Group"; var LoadBuffer: Record "Load Buffer"; CapacityUoM: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateCapacity(var WorkCenterGroup: Record "Work Center Group"; var CapacityUoM: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateCapacity(var WorkCenterGroup: Record "Work Center Group"; var CapacityUoM: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateWorkCenterCapacity(var WorkCenter: Record "Work Center"; var WorkCenterGroup: Record "Work Center Group"; var CapacityUoM: Code[10])
    begin
    end;
}


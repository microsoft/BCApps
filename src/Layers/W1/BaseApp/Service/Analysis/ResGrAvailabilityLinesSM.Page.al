// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Analysis;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Projects.Resources.Analysis;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Document;
using System.Utilities;

page 6012 "Res.Gr Availability Lines (SM)"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = "Res. Availability Buffer";
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Start';
                    ToolTip = 'Specifies the start date of the period defined on the line for the resource group. ';
                }
                field("Period Name"; Rec."Period Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the name of the period shown in the line.';
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Capacity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total capacity for the corresponding time period.';

                    trigger OnDrillDown()
                    var
                        ResCapacityEntry: Record "Res. Capacity Entry";
                        IsHandled: Boolean;
                    begin
                        ResCapacityEntry.SetRange("Resource Group No.", ResGr."No.");
                        ResCapacityEntry.SetRange(Date, Rec."Period Start", Rec."Period End");
                        IsHandled := false;
                        OnAfterCapacityOnDrillDown(ResCapacityEntry, IsHandled);
                        if IsHandled then
                            exit;

                        PAGE.RunModal(0, ResCapacityEntry);
                    end;
                }
#pragma warning disable AA0100
                field("ResGr.""Qty. on Service Order"""; Rec."Qty. on Service Order")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Qty. on Service Order';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the item are allocated to service orders, meaning listed on outstanding service order lines.';

                    trigger OnDrillDown()
                    var
                        ServOrderAlloc: Record "Service Order Allocation";
                    begin
                        ServOrderAlloc.SetRange("Resource Group No.", ResGr."No.");
                        ServOrderAlloc.SetRange("Allocation Date", Rec."Period Start", Rec."Period End");
                        ServOrderAlloc.SetFilter(Status, '%1|%2', ServOrderAlloc.Status::Active, ServOrderAlloc.Status::Finished);
                        ServOrderAlloc.SetRange(Posted, false);
                        PAGE.RunModal(0, ServOrderAlloc);
                    end;
                }
                field(NetAvailability; Rec."Net Availability")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Availability';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies capacity, minus the quantity on order (Project), minus quantity on Service Order, minus Project Quotes Allocation.';
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
        ResGr: Record "Resource Group";

    procedure SetLines(var NewResGr: Record "Resource Group"; NewPeriodType: Enum "Analysis Period Type"; NewAmountType: Enum "Analysis Amount Type")
    begin
        ResGr.Copy(NewResGr);
        Rec.DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            ResGr.SetRange("Date Filter", Rec."Period Start", Rec."Period End")
        else
            ResGr.SetRange("Date Filter", 0D, Rec."Period End");
    end;

    local procedure CalcLine()
    begin
        SetDateFilter();
        ResGr.CalcFields(Capacity, "Qty. on Service Order");

        Rec.Capacity := ResGr.Capacity;
        Rec."Qty. on Service Order" := ResGr."Qty. on Service Order";
        Rec."Net Availability" := Rec.Capacity - Rec."Qty. on Service Order";

        OnAfterCalcLine(ResGr, Rec);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcLine(var ResourceGroup: Record "Resource Group"; var ResAvailabilityBuffer: Record "Res. Availability Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCapacityOnDrillDown(var ResCapacityEntry: Record "Res. Capacity Entry"; var IsHandled: Boolean)
    begin
    end;
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Analysis;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Projects.Resources.Resource;
using System.Utilities;

page 362 "Res. Gr. Availability Lines"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = "Res. Gr. Availability Buffer";
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Capacity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total capacity for the corresponding time period.';
                }
#pragma warning disable AA0100
                field("ResGr.""Qty. on Order (Job)"""; Rec."Qty. on Order (Job)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qty. on Order';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the amount of measuring units allocated to projects with the status order.';
                }
                field(CapacityAfterOrders; Rec."Availability After Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Availability After Orders';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the capacity minus the quantity on order.';
                }
#pragma warning disable AA0100
                field("ResGr.""Qty. Quoted (Job)"""; Rec."Qty. Quoted (Job)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Quotes Allocation';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the amount of measuring units allocated to projects with the status quote.';
                }
                field(CapacityAfterQuotes; Rec."Net Availability")
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
        SetDateFilter();
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
        ResGr.CalcFields(Capacity, "Qty. on Order (Job)", "Qty. Quoted (Job)");
        Rec.Capacity := ResGr.Capacity;
        Rec."Qty. on Order (Job)" := ResGr."Qty. on Order (Job)";
        Rec."Qty. Quoted (Job)" := ResGr."Qty. Quoted (Job)";
        Rec."Availability After Orders" := ResGr.Capacity - ResGr."Qty. on Order (Job)";
        Rec."Net Availability" := Rec."Availability After Orders" - ResGr."Qty. Quoted (Job)";

        OnAfterCalcLine(ResGr, Rec."Availability After Orders", Rec."Net Availability", Rec);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcLine(var ResourceGroup: Record "Resource Group"; var CapacityAfterOrders: Decimal; var CapacityAfterQuotes: Decimal; var ResGrAvailabilityBuffer: Record "Res. Gr. Availability Buffer")
    begin
    end;
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Service.Ledger;
using System.Utilities;

page 5984 "Service Item Trend Lines"
{
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Service Item Trend Buffer";
    SourceTableTemporary = true;


    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Period Start"; Rec."Period Start")
                {
                    ApplicationArea = Service;
                    Caption = 'Period Start';
                    ToolTip = 'Specifies the start date of the period defined on the line for the service trend.';
                }
                field("Period Name"; Rec."Period Name")
                {
                    ApplicationArea = Service;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the name of the period shown in the line.';
                }
#pragma warning disable AA0100
                field("ServItem.""Prepaid Amount"""; Rec."Prepaid Income")
#pragma warning restore AA0100
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Prepaid Income';
                    ToolTip = 'Specifies the total income (in LCY) that has been posted to the prepaid account with regard to the service item in the periods specified in the Period Start field.';

                    trigger OnDrillDown()
                    begin
                        ShowServLedgEntries(false);
                    end;
                }
#pragma warning disable AA0100
                field("ServItem.""Invoiced Amount"""; Rec."Posted Income")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Posted Income';
                    DrillDown = true;
                    ToolTip = 'Specifies the total income (in LCY) that has been posted to the general ledger for the service item in the periods specified in the Period Start field.';

                    trigger OnDrillDown()
                    begin
                        ShowServLedgEntries(true);
                    end;
                }
#pragma warning disable AA0100
                field("ServItem.""Parts Used"""; Rec."Parts Used")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Parts Used';
                    DrillDown = true;
                    ToolTip = 'Specifies the cost of resources used in the specified period.';

                    trigger OnDrillDown()
                    begin
                        ShowServLedgEntriesByType(ServLedgEntry.Type::Item);
                    end;
                }
#pragma warning disable AA0100
                field("ServItem.""Resources Used"""; Rec."Resources Used")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Resources Used';
                    DrillDown = true;
                    ToolTip = 'Specifies the cost of spare parts used in the period shown in the Period Start field.';

                    trigger OnDrillDown()
                    begin
                        ShowServLedgEntriesByType(ServLedgEntry.Type::Resource);
                    end;
                }
#pragma warning disable AA0100
                field("ServItem.""Cost Used"""; Rec."Cost Used")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Cost Used';
                    ToolTip = 'Specifies the amount of service usage based on service cost for this service item.';

                    trigger OnDrillDown()
                    begin
                        ShowServLedgEntriesByType(ServLedgEntry.Type::"Service Cost");
                    end;
                }
                field(Profit; Rec.Profit)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Profit';
                    ToolTip = 'Specifies the profit (posted income minus posted cost in LCY) for the service item in the period specified in the Period Start field.';
                }
                field(ProfitPct; Rec."Profit %")
                {
                    ApplicationArea = Service;
                    Caption = 'Profit %';
                    ToolTip = 'Specifies the profit percentage for the service item in the specified period.';
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
        ServLedgEntry: Record "Service Ledger Entry";
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";

    protected var
        ServItem: Record "Service Item";

    procedure SetLines(var ServItem1: Record "Service Item"; NewPeriodType: Enum "Analysis Period Type"; NewAmountType: Enum "Analysis Amount Type")
    begin
        ServItem.Copy(ServItem1);
        Rec.DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            ServItem.SetRange("Date Filter", Rec."Period Start", Rec."Period End")
        else
            ServItem.SetRange("Date Filter", 0D, Rec."Period End");
    end;

    local procedure ShowServLedgEntries(Prepaid: Boolean)
    begin
        SetDateFilter();
        ServLedgEntry.Reset();
        ServLedgEntry.SetCurrentKey("Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.", Type, "Posting Date");
        ServLedgEntry.SetRange("Service Item No. (Serviced)", ServItem."No.");
        ServLedgEntry.SetRange("Entry Type", ServLedgEntry."Entry Type"::Sale);
        ServLedgEntry.SetRange("Moved from Prepaid Acc.", Prepaid);
        ServLedgEntry.SetRange(Open, false);
        ServLedgEntry.SetFilter("Posting Date", ServItem.GetFilter("Date Filter"));
        PAGE.Run(0, ServLedgEntry);
    end;

    local procedure ShowServLedgEntriesByType(Type: Enum "Service Ledger Entry Type")
    begin
        SetDateFilter();
        ServLedgEntry.Reset();
        ServLedgEntry.SetCurrentKey("Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.", Type, "Posting Date");
        ServLedgEntry.SetRange("Service Item No. (Serviced)", ServItem."No.");
        ServLedgEntry.SetRange("Entry Type", ServLedgEntry."Entry Type"::Sale);
        ServLedgEntry.SetRange(Type, Type);
        ServLedgEntry.SetFilter("Posting Date", ServItem.GetFilter("Date Filter"));
        PAGE.Run(0, ServLedgEntry);
    end;

    local procedure CalcLine()
    begin
        SetDateFilter();
        ServItem.CalcFields("Invoiced Amount", "Resources Used", "Parts Used", "Cost Used", "Prepaid Amount");
        Rec.Profit := ServItem."Invoiced Amount" - ServItem."Resources Used" - ServItem."Parts Used" - ServItem."Cost Used";
        if ServItem."Invoiced Amount" <> 0 then
            Rec."Profit %" := Round((Rec.Profit / ServItem."Invoiced Amount") * 100, 0.01)
        else
            Rec."Profit %" := 0;

        Rec."Prepaid Income" := ServItem."Prepaid Amount";
        Rec."Posted Income" := ServItem."Invoiced Amount";
        Rec."Parts Used" := ServItem."Parts Used";
        Rec."Resources Used" := ServItem."Resources Used";
        Rec."Cost Used" := ServItem."Cost Used";

        OnAfterCalcLine(ServItem, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLine(var ServItem: Record "Service Item"; var ServiceItemTrendBuffer: Record "Service Item Trend Buffer")
    begin
    end;
}


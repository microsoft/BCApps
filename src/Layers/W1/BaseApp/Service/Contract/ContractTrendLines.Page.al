// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Service.Ledger;
using System.Utilities;

page 6061 "Contract Trend Lines"
{
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Contract Trend Buffer";
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
                    ToolTip = 'Specifies the starting date of the period that you want to view.';
                }
                field("Period Name"; Rec."Period Name")
                {
                    ApplicationArea = Service;
                    Caption = 'Period Name';
                    ToolTip = 'Specifies the name of the period shown in the line.';
                }
#pragma warning disable AA0100
                field("ServContract.""Contract Prepaid Amount"""; Rec."Prepaid Income")
#pragma warning restore AA0100
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Prepaid Income';
                    ToolTip = 'Specifies the total income (in LCY) that has been posted to the prepaid account for the service contract in the periods specified in the Period Start field.';

                    trigger OnDrillDown()
                    begin
                        SetDateFilter();
                        ServLedgEntry.Reset();
                        ServLedgEntry.SetCurrentKey(Type, "No.", "Entry Type", "Moved from Prepaid Acc.", "Posting Date");
                        ServLedgEntry.SetRange("Service Contract No.", ServContract."Contract No.");
                        ServLedgEntry.SetRange("Entry Type", ServLedgEntry."Entry Type"::Sale);
                        ServLedgEntry.SetRange("Moved from Prepaid Acc.", false);
                        ServLedgEntry.SetRange(Type, ServLedgEntry.Type::"Service Contract");
                        ServLedgEntry.SetRange(Open, false);
                        ServLedgEntry.SetRange(Prepaid, true);
                        ServLedgEntry.SetFilter("Posting Date", ServContract.GetFilter("Date Filter"));
                        PAGE.RunModal(0, ServLedgEntry);
                    end;
                }
#pragma warning disable AA0100
                field("ServContract.""Contract Invoice Amount"""; Rec."Posted Income")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Posted Income';
                    DrillDown = true;
                    ToolTip = 'Specifies the total income (in LCY) that has been posted to the general ledger for the service contract in the periods specified in the Period Start field.';

                    trigger OnDrillDown()
                    begin
                        SetDateFilter();
                        ServLedgEntry.Reset();
                        ServLedgEntry.SetCurrentKey(Type, "No.", "Entry Type", "Moved from Prepaid Acc.", "Posting Date");
                        ServLedgEntry.SetRange("Service Contract No.", ServContract."Contract No.");
                        ServLedgEntry.SetRange("Entry Type", ServLedgEntry."Entry Type"::Sale);
                        ServLedgEntry.SetRange("Moved from Prepaid Acc.", true);
                        ServLedgEntry.SetRange(Open, false);
                        ServLedgEntry.SetFilter("Posting Date", ServContract.GetFilter("Date Filter"));
                        PAGE.RunModal(0, ServLedgEntry);
                    end;
                }
#pragma warning disable AA0100
                field("ServContract.""Contract Cost Amount"""; Rec."Posted Cost")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Posted Cost';
                    ToolTip = 'Specifies the cost of the service contract based on its service usage in the periods specified in the Period Start field.';

                    trigger OnDrillDown()
                    begin
                        SetDateFilter();
                        Clear(ServLedgEntry);
                        ServLedgEntry.SetCurrentKey(Type, "No.", "Entry Type", "Moved from Prepaid Acc.", "Posting Date");
                        ServLedgEntry.SetRange("Entry Type", ServLedgEntry."Entry Type"::Usage);
                        ServLedgEntry.SetRange("Service Contract No.", ServContract."Contract No.");
                        ServLedgEntry.SetRange("Moved from Prepaid Acc.", true);
                        ServLedgEntry.SetRange(Open, false);
                        ServLedgEntry.SetFilter("Posting Date", ServContract.GetFilter("Date Filter"));
                        PAGE.RunModal(0, ServLedgEntry);
                    end;
                }
#pragma warning disable AA0100
                field("ServContract.""Contract Discount Amount"""; Rec."Discount Amount")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Discount Amount';
                    ToolTip = 'Specifies the amount of discount being applied for the line.';

                    trigger OnDrillDown()
                    begin
                        SetDateFilter();
                        Clear(ServLedgEntry);
                        ServLedgEntry.SetCurrentKey("Service Contract No.");
                        ServLedgEntry.SetRange("Service Contract No.", ServContract."Contract No.");
                        ServLedgEntry.SetRange("Entry Type", ServLedgEntry."Entry Type"::Usage);
                        ServLedgEntry.SetRange("Moved from Prepaid Acc.", true);
                        ServLedgEntry.SetRange(Open, false);
                        ServLedgEntry.SetFilter("Posting Date", ServContract.GetFilter("Date Filter"));
                        PAGE.RunModal(0, ServLedgEntry);
                    end;
                }
                field(ProfitAmount; Rec.Profit)
                {
                    ApplicationArea = Service;
                    AutoFormatType = 1;
                    Caption = 'Profit';
                    ToolTip = 'Specifies the profit (posted incom0e minus posted cost in LCY) for the service contract in the periods specified in the Period Start field.';
                }
                field(ProfitPct; Rec."Profit %")
                {
                    ApplicationArea = Service;
                    Caption = 'Profit %';
                    ToolTip = 'Specifies the profit percentage for the service contract in the periods specified in the Period Start field. ';
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
        ServContract: Record "Service Contract Header";

    procedure SetLines(var NewServContract: Record "Service Contract Header"; NewPeriodType: Enum "Analysis Period Type"; NewAmountType: Enum "Analysis Amount Type")
    begin
        ServContract.Copy(NewServContract);
        Rec.DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            ServContract.SetRange("Date Filter", Rec."Period Start", Rec."Period End")
        else
            ServContract.SetRange("Date Filter", 0D, Rec."Period End");
    end;

    local procedure CalcLine()
    begin
        SetDateFilter();
        ServContract.CalcFields(
          "Contract Invoice Amount",
          "Contract Discount Amount",
          "Contract Cost Amount",
          "Contract Prepaid Amount");

        Rec."Prepaid Income" := ServContract."Contract Prepaid Amount";
        Rec."Posted Income" := ServContract."Contract Invoice Amount";
        Rec."Posted Cost" := ServContract."Contract Cost Amount";
        Rec."Discount Amount" := ServContract."Contract Discount Amount";

        Rec.Profit := ServContract."Contract Invoice Amount" - ServContract."Contract Cost Amount";
        if ServContract."Contract Invoice Amount" <> 0 then
            Rec."Profit %" := Round((Rec.Profit / ServContract."Contract Invoice Amount") * 100, 0.01)
        else
            Rec."Profit %" := 0;

        OnAfterCalcLine(ServContract, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLine(var ServiceContractHeader: Record "Service Contract Header"; var ServiceItemTrendBuffer: Record "Contract Trend Buffer")
    begin
    end;
}


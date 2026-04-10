// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Item;

page 909 "Assembly Line Avail."
{
    Caption = 'Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Assembly Line";
    SourceTableTemporary = true;
    SourceTableView = sorting("Document Type", "Document No.", Type)
                      order(ascending)
                      where("Document Type" = const(Order),
                            Type = const(Item),
                            "No." = filter(<> ''));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Assembly;
                }
                field(Inventory; Inventory)
                {
                    AutoFormatType = 0;
                    ApplicationArea = Assembly;
                    Caption = 'Inventory';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the assembly component are in inventory.';
                    Visible = false;
                }
                field(GrossRequirement; GrossRequirement)
                {
                    AutoFormatType = 0;
                    ApplicationArea = Assembly;
                    Caption = 'Gross Requirement';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the total demand for the assembly component.';
                }
                field(ScheduledReceipt; ScheduledRcpt)
                {
                    AutoFormatType = 0;
                    ApplicationArea = Assembly;
                    Caption = 'Scheduled Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the assembly component are inbound on orders.';
                }
                field(ExpectedAvailableInventory; ExpectedInventory)
                {
                    AutoFormatType = 0;
                    ApplicationArea = Assembly;
                    Caption = 'Expected Available Inventory';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the assembly component are available for the current assembly order on the due date.';
                    Visible = true;
                }
                field(CurrentQuantity; Rec."Remaining Quantity")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Current Quantity';
                    ToolTip = 'Specifies how many units of the component are required on the assembly order line.';
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    ApplicationArea = Assembly;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    Caption = 'Current Reserved Quantity';
                    Visible = false;
                }
                field(EarliestAvailableDate; EarliestDate)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Earliest Available Date';
                    ToolTip = 'Specifies the late arrival date of an inbound supply order that can cover the needed quantity of the assembly component.';
                }
                field(AbleToAssemble; AbleToAssemble)
                {
                    AutoFormatType = 0;
                    ApplicationArea = Assembly;
                    Caption = 'Able to Assemble';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the assembly item on the assembly order header can be assembled, based on the availability of the component.';
                }
                field("Lead-Time Offset"; Rec."Lead-Time Offset")
                {
                    ApplicationArea = Assembly;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                }
                field("Substitution Available"; Rec."Substitution Available")
                {
                    ApplicationArea = Assembly;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        IsHandled: Boolean;
    begin
        Rec.SetItemFilter(Item);

        IsHandled := false;
        OnAfterGetRecordOnBeforeCalcAvailToAssemble(Rec, AssemblyHeader, Item, GrossRequirement, ScheduledRcpt, ExpectedInventory, Inventory, EarliestDate, AbleToAssemble, IsHandled);
        if not IsHandled then
            Rec.CalcAvailToAssemble(
              AssemblyHeader,
              Item,
              GrossRequirement,
              ScheduledRcpt,
              ExpectedInventory,
              Inventory,
              EarliestDate,
              AbleToAssemble);
    end;

    trigger OnInit()
    begin
        Rec.SetItemFilter(Item);
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        Rec.SetRange(Type, Rec.Type::Item);
        Rec.SetFilter("No.", '<>%1', '');
        Rec.SetFilter("Quantity per", '<>%1', 0);
    end;

    var
        AssemblyHeader: Record "Assembly Header";
        Item: Record Item;
        ExpectedInventory: Decimal;
        GrossRequirement: Decimal;
        ScheduledRcpt: Decimal;
        Inventory: Decimal;
        EarliestDate: Date;
        AbleToAssemble: Decimal;

    procedure SetLinesRecord(var AssemblyLine: Record "Assembly Line")
    begin
        Rec.Copy(AssemblyLine, true);
    end;

    procedure SetHeader(AssemblyHeader2: Record "Assembly Header")
    begin
        AssemblyHeader := AssemblyHeader2;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetRecordOnBeforeCalcAvailToAssemble(var AssemblyLine: Record "Assembly Line"; var AssemblyHeader: Record "Assembly Header"; var Item: Record Item; var GrossRequirement: Decimal; var ScheduledReceipt: Decimal; var ExpectedInventory: Decimal; var AvailableInventory: Decimal; var EarliestDate: Date; var AbleToAssemble: Decimal; var IsHandled: Boolean);
    begin
    end;
}


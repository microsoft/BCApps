// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Utilities;

table 99000880 "Order Promising Line"
{
    Caption = 'Order Promising Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(12; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Editable = false;
            TableRelation = Location;
        }
        field(13; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(14; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(15; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(16; "Unavailable Quantity"; Decimal)
        {
            Caption = 'Unavailable Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(17; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Unavailable Quantity (Base)"; Decimal)
        {
            Caption = 'Unavailable Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(19; "Required Quantity (Base)"; Decimal)
        {
            Caption = 'Required Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(20; "Source Type"; Enum "Order Promising Line Source Type")
        {
            Caption = 'Source Type';
        }
        field(21; "Source Subtype"; Integer)
        {
            Caption = 'Source Subtype';
        }
        field(22; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
        }
        field(23; "Source Batch Name"; Code[10])
        {
            Caption = 'Source Batch Name';
        }
        field(25; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        field(30; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(31; "Required Quantity"; Decimal)
        {
            Caption = 'Required Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(40; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';

            trigger OnValidate()
            begin
                OnValidateRequestedDeliveryDate(Rec);
            end;
        }
        field(41; "Planned Delivery Date"; Date)
        {
            Caption = 'Planned Delivery Date';

            trigger OnValidate()
            begin
                if "Planned Delivery Date" <> 0D then
                    OnValidatePlannedDeliveryDate(Rec);
            end;
        }
        field(42; "Original Shipment Date"; Date)
        {
            Caption = 'Original Shipment Date';
        }
        field(43; "Earliest Shipment Date"; Date)
        {
            Caption = 'Earliest Shipment Date';

            trigger OnValidate()
            begin
                OnValidateEarliestDeliveryDate(Rec);
            end;
        }
        field(44; "Requested Shipment Date"; Date)
        {
            Caption = 'Requested Shipment Date';
            Editable = false;
        }
        field(45; "Unavailability Date"; Date)
        {
            Caption = 'Unavailability Date';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Requested Shipment Date")
        {
        }
    }

    fieldgroups
    {
    }

#if not CLEAN25
    [Obsolete('Replaced by procedure TransferToOrderPromisingLine() in codeunit Sales Availability Mgt.', '25.0')]
    procedure TransferFromSalesLine(var SalesLine: Record Microsoft.Sales.Document."Sales Line")
    var
        SalesAvailabilityMgt: Codeunit Microsoft.Sales.Document."Sales Availability Mgt.";
    begin
        SalesAvailabilityMgt.TransferToOrderPromisingLine(Rec, SalesLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure TransferToOrderPromisingLine() in codeunit Serv. Availability Mgt.', '25.0')]
    procedure TransferFromServLine(var ServLine: Record Microsoft.Service.Document."Service Line")
    var
        ServAvailabilityMgt: Codeunit Microsoft.Service.Document."Serv. Availability Mgt.";
    begin
        ServAvailabilityMgt.TransferToOrderPromisingLine(Rec, ServLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by procedure TransferToOrderPromisingLine() in codeunit Job Planning Availability Mgt.', '25.0')]
    procedure TransferFromJobPlanningLine(var JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line")
    var
        JobPlanningAvailabilityMgt: Codeunit Microsoft.Projects.Project.Planning."Job Planning Availability Mgt.";
    begin
        JobPlanningAvailabilityMgt.TransferToOrderPromisingLine(Rec, JobPlanningLine);
    end;
#endif

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure CalcAvailability(): Decimal
    var
        Item: Record Item;
        AvailableToPromise: Codeunit "Available to Promise";
        LookaheadDateformula: DateFormula;
        GrossRequirement: Decimal;
        ScheduledReceipt: Decimal;
        PeriodType: Enum "Analysis Period Type";
        AvailabilityDate: Date;
    begin
        if Item.Get("Item No.") then begin
            if "Original Shipment Date" > 0D then
                AvailabilityDate := "Original Shipment Date"
            else
                AvailabilityDate := WorkDate();

            Item.Reset();
            Item.SetRange("Date Filter", 0D, AvailabilityDate);
            Item.SetRange("Variant Filter", "Variant Code");
            Item.SetRange("Location Filter", "Location Code");
            Item.SetRange("Drop Shipment Filter", false);
            exit(
              AvailableToPromise.CalcQtyAvailabletoPromise(
                Item,
                GrossRequirement,
                ScheduledReceipt,
                AvailabilityDate,
                PeriodType,
                LookaheadDateformula));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateRequestedDeliveryDate(var OrderPromisingLine: Record "Order Promising Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidatePlannedDeliveryDate(var OrderPromisingLine: Record "Order Promising Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateEarliestDeliveryDate(var OrderPromisingLine: Record "Order Promising Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAfterTransferFromSalesLine(var OrderPromisingLine: Record "Order Promising Line"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
        OnAfterTransferFromSalesLine(OrderPromisingLine, SalesLine);
    end;

    [Obsolete('Replaced by event OnAfterTransferToOrderPromisingLine in codeunit Sales Availability Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromSalesLine(var OrderPromisingLine: Record "Order Promising Line"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromServLine(var OrderPromisingLine: Record "Order Promising Line"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
        OnAfterTransferFromServLine(OrderPromisingLine, ServiceLine);
    end;

    [Obsolete('Replaced by event OnAfterTransferToOrderPromisingLine in codeunit Serv. Availability Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromServLine(var OrderPromisingLine: Record "Order Promising Line"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromJobPlanningLine(var OrderPromisingLine: Record "Order Promising Line"; JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line")
    begin
        OnAfterTransferFromJobPlanningLine(OrderPromisingLine, JobPlanningLine);
    end;

    [Obsolete('Replaced by event OnAfterTransferToOrderPromisingLine in codeunit Job Planning Availability Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromJobPlanningLine(var OrderPromisingLine: Record "Order Promising Line"; JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line")
    begin
    end;
#endif
}


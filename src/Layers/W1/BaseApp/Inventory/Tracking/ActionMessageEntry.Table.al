// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Utilities;
using Microsoft.Warehouse.Structure;

table 99000849 "Action Message Entry"
{
    Caption = 'Action Message Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; Type; Enum "Action Message Type")
        {
            Caption = 'Type';
        }
        field(3; "Reservation Entry"; Integer)
        {
            Caption = 'Reservation Entry';
            TableRelation = "Reservation Entry"."Entry No.";
        }
        field(4; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(5; "New Date"; Date)
        {
            Caption = 'New Date';
        }
        field(6; Calculation; Option)
        {
            Caption = 'Calculation';
            OptionCaption = 'Sum,None';
            OptionMembers = "Sum","None";
        }
        field(7; "Suppressed Action Msg."; Boolean)
        {
            Caption = 'Suppressed Action Msg.';
        }
        field(10; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(11; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(12; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
        }
        field(13; "Source Batch Name"; Code[10])
        {
            Caption = 'Source Batch Name';
        }
        field(14; "Source Prod. Order Line"; Integer)
        {
            Caption = 'Source Prod. Order Line';
        }
        field(15; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
        }
        field(16; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(17; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(18; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(19; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Reservation Entry", Calculation)
        {
            SumIndexFields = Quantity;
        }
        key(Key3; "Source Type", "Source Subtype", "Source ID", "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.", "Item No.", "Location Code", "Bin Code", "Variant Code")
        {
            SumIndexFields = Quantity;
        }
    }

    fieldgroups
    {
    }

    var
        ComponentBinding: Boolean;
        FirstDate: Date;
        FirstTime: Time;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure SumUp(var ActionMessageEntry: Record "Action Message Entry")
    var
        ActionMessageEntry2: Record "Action Message Entry";
        TypeArray: array[5] of Boolean;
    begin
        ActionMessageEntry2 := ActionMessageEntry;

        ActionMessageEntry2.SetSourceFilterFromActionEntry(Rec);
        ActionMessageEntry2.SetRange("Location Code", ActionMessageEntry2."Location Code");
        ActionMessageEntry2.SetRange("Bin Code", ActionMessageEntry2."Bin Code");
        ActionMessageEntry2.SetRange("Variant Code", ActionMessageEntry2."Variant Code");
        ActionMessageEntry2.SetRange("Item No.", ActionMessageEntry2."Item No.");
        ActionMessageEntry."New Date" := 0D;
        ActionMessageEntry.Quantity := 0;
        OnAfterAssignMessageEntry(ActionMessageEntry, ActionMessageEntry2);
        ActionMessageEntry.Type := ActionMessageEntry.Type::" ";
        if ActionMessageEntry2.FindSet() then
            repeat
                if ActionMessageEntry2.Quantity <> 0 then begin
                    ActionMessageEntry.Quantity += ActionMessageEntry2.Quantity;
                    TypeArray[2] := true;
                    OnAfterAssignQuantity(ActionMessageEntry, ActionMessageEntry2);
                end;
                if ActionMessageEntry2."New Date" <> 0D then begin
                    ActionMessageEntry."New Date" := ActionMessageEntry2."New Date";
                    TypeArray[3] := true;
                end;
            until ActionMessageEntry2.Next() = 0;

        if TypeArray[2] then
            ActionMessageEntry.Type := ActionMessageEntry.Type::"Change Qty.";

        if TypeArray[3] then
            ActionMessageEntry.Type := ActionMessageEntry.Type::Reschedule;

        if TypeArray[2] and TypeArray[3] then
            ActionMessageEntry.Type := ActionMessageEntry.Type::"Resched. & Chg. Qty.";

        if TypeArray[1] then
            ActionMessageEntry.Type := ActionMessageEntry.Type::New;

        if TypeArray[5] then
            ActionMessageEntry.Type := ActionMessageEntry.Type::Cancel;

        OnAfterAssignEntryType(ActionMessageEntry, ActionMessageEntry2);
        ActionMessageEntry2."New Date" := ActionMessageEntry."New Date";
        ActionMessageEntry2.Quantity := ActionMessageEntry.Quantity;
        ActionMessageEntry2.Type := ActionMessageEntry.Type;
        ActionMessageEntry := ActionMessageEntry2;

        OnAfterSumUp(ActionMessageEntry, ComponentBinding, FirstDate, FirstTime);
    end;

    procedure TransferFromReservEntry(var ReservEntry: Record "Reservation Entry")
    begin
        "Reservation Entry" := ReservEntry."Entry No.";
        SetSourceFromReservEntry(ReservEntry);
        "Location Code" := ReservEntry."Location Code";
        "Variant Code" := ReservEntry."Variant Code";
        "Item No." := ReservEntry."Item No.";
    end;

    procedure FilterFromReservEntry(var ReservEntry: Record "Reservation Entry")
    begin
        SetSourceFilterFromReservEntry(ReservEntry);
        SetRange("Location Code", ReservEntry."Location Code");
        SetRange("Variant Code", ReservEntry."Variant Code");
        SetRange("Item No.", ReservEntry."Item No.");
    end;

    procedure FilterToReservEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter("Source Type", "Source Subtype", "Source ID", "Source Ref. No.", true);
        ReservEntry.SetSourceFilter("Source Batch Name", "Source Prod. Order Line");
    end;

    procedure BoundToComponent(): Boolean
    begin
        exit(ComponentBinding);
    end;

    procedure ComponentDueDate(): Date
    begin
        exit(FirstDate);
    end;

    procedure ComponentDueTime(): Time
    begin
        exit(FirstTime);
    end;

    procedure SetSource(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        "Source Type" := SourceType;
        "Source Subtype" := SourceSubtype;
        "Source ID" := SourceID;
        "Source Ref. No." := SourceRefNo;
        "Source Batch Name" := SourceBatchName;
        "Source Prod. Order Line" := SourceProdOrderLine;
    end;

    procedure SetSourceFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        "Source Type" := ReservEntry."Source Type";
        "Source Subtype" := ReservEntry."Source Subtype";
        "Source ID" := ReservEntry."Source ID";
        "Source Ref. No." := ReservEntry."Source Ref. No.";
        "Source Batch Name" := ReservEntry."Source Batch Name";
        "Source Prod. Order Line" := ReservEntry."Source Prod. Order Line";
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceKey: Boolean)
    begin
        if SourceKey then
            SetCurrentKey(
              "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.");
        SetRange("Source Type", SourceType);
        if SourceSubtype >= 0 then
            SetRange("Source Subtype", SourceSubtype);
        SetRange("Source ID", SourceID);
        if SourceRefNo >= 0 then
            SetRange("Source Ref. No.", SourceRefNo);
        OnAfterSetSourceFilter(Rec, SourceType, SourceSubtype, SourceID, SourceRefNo, SourceKey);
    end;

    procedure SetSourceFilter(SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        SetRange("Source Batch Name", SourceBatchName);
        SetRange("Source Prod. Order Line", SourceProdOrderLine);
    end;

    procedure SetSourceFilterFromActionEntry(ActionMessageEntry: Record "Action Message Entry")
    begin
        SetRange("Source Type", ActionMessageEntry."Source Type");
        SetRange("Source Subtype", ActionMessageEntry."Source Subtype");
        SetRange("Source ID", ActionMessageEntry."Source ID");
        SetRange("Source Ref. No.", ActionMessageEntry."Source Ref. No.");
        SetRange("Source Batch Name", ActionMessageEntry."Source Batch Name");
        SetRange("Source Prod. Order Line", ActionMessageEntry."Source Prod. Order Line");
    end;

    procedure SetSourceFilterFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        SetRange("Source Type", ReservEntry."Source Type");
        SetRange("Source Subtype", ReservEntry."Source Subtype");
        SetRange("Source ID", ReservEntry."Source ID");
        SetRange("Source Ref. No.", ReservEntry."Source Ref. No.");
        SetRange("Source Batch Name", ReservEntry."Source Batch Name");
        SetRange("Source Prod. Order Line", ReservEntry."Source Prod. Order Line");
    end;

    procedure ClearSourceFilter()
    begin
        SetRange("Source Type");
        SetRange("Source Subtype");
        SetRange("Source ID");
        SetRange("Source Batch Name");
        SetRange("Source Prod. Order Line");
        SetRange("Source Ref. No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilter(var ActionMessageEntry: Record "Action Message Entry"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceKey: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignMessageEntry(var ActionMessageEntry: Record "Action Message Entry"; var ActionMessageEntry2: Record "Action Message Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignQuantity(var ActionMessageEntry: Record "Action Message Entry"; var ActionMessageEntry2: Record "Action Message Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignEntryType(var ActionMessageEntry: Record "Action Message Entry"; var ActionMessageEntry2: Record "Action Message Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSumUp(var ActionMessageEntry: Record "Action Message Entry"; var ComponentBinding: Boolean; var FirstDate: Date; var FirstTime: Time)
    begin
    end;
}


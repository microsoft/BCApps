// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.IO;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using System.Reflection;

table 6529 "Record Buffer"
{
    Caption = 'Record Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Table No."; Integer)
        {
            Caption = 'Table No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Table Name"; Text[250])
        {
            Caption = 'Table Name';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(5; "Record Identifier"; RecordID)
        {
            Caption = 'Record Identifier';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(6; "Search Record ID"; Code[100])
        {
            Caption = 'Search Record ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(7; "Primary Key"; Text[250])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(8; "Primary Key Field 1 No."; Integer)
        {
            Caption = 'Primary Key Field 1 No.';
            DataClassification = SystemMetadata;
            TableRelation = Field."No." where(TableNo = field("Table No."));
        }
        field(9; "Primary Key Field 1 Name"; Text[80])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table No."),
                                                              "No." = field("Primary Key Field 1 No.")));
            Caption = 'Primary Key Field 1 Name';
            FieldClass = FlowField;
        }
        field(10; "Primary Key Field 1 Value"; Text[50])
        {
            Caption = 'Primary Key Field 1 Value';
            DataClassification = SystemMetadata;
        }
        field(11; "Primary Key Field 2 No."; Integer)
        {
            Caption = 'Primary Key Field 2 No.';
            DataClassification = SystemMetadata;
            TableRelation = Field."No." where(TableNo = field("Table No."));
        }
        field(12; "Primary Key Field 2 Name"; Text[80])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table No."),
                                                              "No." = field("Primary Key Field 2 No.")));
            Caption = 'Primary Key Field 2 Name';
            FieldClass = FlowField;
        }
        field(13; "Primary Key Field 2 Value"; Text[50])
        {
            Caption = 'Primary Key Field 2 Value';
            DataClassification = SystemMetadata;
        }
        field(14; "Primary Key Field 3 No."; Integer)
        {
            Caption = 'Primary Key Field 3 No.';
            DataClassification = SystemMetadata;
            TableRelation = Field."No." where(TableNo = field("Table No."));
        }
        field(15; "Primary Key Field 3 Name"; Text[80])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table No."),
                                                              "No." = field("Primary Key Field 3 No.")));
            Caption = 'Primary Key Field 3 Name';
            FieldClass = FlowField;
        }
        field(16; "Primary Key Field 3 Value"; Text[50])
        {
            Caption = 'Primary Key Field 3 Value';
            DataClassification = SystemMetadata;
        }
        field(17; Level; Integer)
        {
            Caption = 'Level';
            DataClassification = SystemMetadata;
        }
        field(20; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            DataClassification = SystemMetadata;

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", ItemTrackingType::"Serial No.", "Serial No.");
            end;
        }
        field(21; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            DataClassification = SystemMetadata;

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", ItemTrackingType::"Lot No.", "Lot No.");
            end;
        }
        field(22; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = SystemMetadata;
            TableRelation = Item;
        }
        field(23; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = SystemMetadata;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            DataClassification = SystemMetadata;

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", "Item Tracking Type"::"Package No.", "Package No.");
            end;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Table No.", "Search Record ID")
        {
        }
        key(Key3; "Search Record ID")
        {
        }
    }

    fieldgroups
    {
    }

    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ItemTrackingType: Enum "Item Tracking Type";

    procedure CopyTrackingFromItemTrackingSetup(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        "Serial No." := ItemTrackingSetup."Serial No.";
        "Lot No." := ItemTrackingSetup."Lot No.";

        OnAfterCopyTrackingFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromItemTrackingSetup(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        SetRange("Serial No.", ItemTrackingSetup."Serial No.");
        SetRange("Lot No.", ItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    procedure InsertRecordBuffer(RecRef: RecordRef)
    var
        KeyFldRef: FieldRef;
        KeyRef1: KeyRef;
        i: Integer;
    begin
        SetRange("Record Identifier", RecRef.RecordId);
        if not Find('-') then begin
            Init();
            "Entry No." := "Entry No." + 10;
            "Table No." := RecRef.Number;
            "Record Identifier" := RecRef.RecordId;
            "Search Record ID" :=
                CopyStr(Format("Record Identifier"), 1, MaxStrLen("Search Record ID"));

            KeyRef1 := RecRef.KeyIndex(1);
            for i := 1 to KeyRef1.FieldCount do begin
                KeyFldRef := KeyRef1.FieldIndex(i);
                if i = 1 then
                    "Primary Key" :=
                        CopyStr(
                            StrSubstNo('%1=%2', KeyFldRef.Caption, FormatValue(KeyFldRef, RecRef.Number)),
                            1, MaxStrLen("Primary Key"))
                else
                    if MaxStrLen("Primary Key") >
                       StrLen("Primary Key") +
                       StrLen(StrSubstNo(', %1=%2', KeyFldRef.Caption, FormatValue(KeyFldRef, RecRef.Number)))
                    then
                        "Primary Key" :=
                            CopyStr(
                                "Primary Key" +
                                StrSubstNo(', %1=%2', KeyFldRef.Caption, FormatValue(KeyFldRef, RecRef.Number)),
                                1, MaxStrLen("Primary Key"));
                case i of
                    1:
                        begin
                            "Primary Key Field 1 No." := KeyFldRef.Number;
                            "Primary Key Field 1 Value" :=
                                CopyStr(
                                    FormatValue(KeyFldRef, RecRef.Number), 1, MaxStrLen("Primary Key Field 1 Value"));
                        end;
                    2:
                        begin
                            "Primary Key Field 2 No." := KeyFldRef.Number;
                            "Primary Key Field 2 Value" :=
                                CopyStr(
                                    FormatValue(KeyFldRef, RecRef.Number), 1, MaxStrLen("Primary Key Field 2 Value"));
                        end;
                    3:
                        begin
                            "Primary Key Field 3 No." := KeyFldRef.Number;
                            "Primary Key Field 3 Value" :=
                                CopyStr(
                                    FormatValue(KeyFldRef, RecRef.Number), 1, MaxStrLen("Primary Key Field 3 Value"));
                        end;
                end;
            end;
            Insert();
        end;
    end;

    procedure FormatValue(var FldRef: FieldRef; TableNumber: Integer): Text
    var
        "Field": Record System.Reflection.Field;
        OptionNo: Integer;
        OptionStr: Text;
        i: Integer;
    begin
        Field.Get(TableNumber, FldRef.Number);
        if Field.Type = Field.Type::Option then begin
            OptionNo := FldRef.Value();
            OptionStr := Format(FldRef.OptionCaption);
            for i := 1 to OptionNo do
                OptionStr := CopyStr(OptionStr, StrPos(OptionStr, ',') + 1);
            if StrPos(OptionStr, ',') > 0 then
                if StrPos(OptionStr, ',') = 1 then
                    OptionStr := ''
                else
                    OptionStr := CopyStr(OptionStr, 1, StrPos(OptionStr, ',') - 1);
            exit(OptionStr);
        end;
        exit(Format(FldRef.Value));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemTrackingSetup(var RecordBuffer: Record "Record Buffer"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetup(var RecordBuffer: Record "Record Buffer"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;
}


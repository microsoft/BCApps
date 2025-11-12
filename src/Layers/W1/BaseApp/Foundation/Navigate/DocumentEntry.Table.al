// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Inventory.Tracking;
using System.Reflection;

table 265 "Document Entry"
{
    Caption = 'Document Entry';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(2; "No. of Records"; Integer)
        {
            Caption = 'No. of Records';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            FieldClass = FlowFilter;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            FieldClass = FlowFilter;
        }
        field(5; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(6; "Table Name"; Text[100])
        {
            Caption = 'Table Name';
        }
        field(7; "No. of Records 2"; Integer)
        {
            Caption = 'No. of Records 2';
        }
        field(8; "Document Type"; Enum "Document Entry Document Type")
        {
            Caption = 'Document Type';
        }
        field(9; "Lot No. Filter"; Code[50])
        {
            Caption = 'Lot No. Filter';
            FieldClass = FlowFilter;
        }
        field(10; "Serial No. Filter"; Code[50])
        {
            Caption = 'Serial No. Filter';
            FieldClass = FlowFilter;
        }
        field(11; "Package No. Filter"; Code[50])
        {
            Caption = 'Package No. Filter';
            FieldClass = FlowFilter;
        }
        field(12; "Ref. Document No."; Code[20])
        {
            Caption = 'Ref. Document No.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Table ID")
        {
        }
    }

    fieldgroups
    {
    }

    procedure SetTrackingFilterFromItemTrackingSetup(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Serial No." <> '' then
            SetRange("Serial No. Filter", ItemTrackingSetup."Serial No.");
        if ItemTrackingSetup."Lot No." <> '' then
            SetRange("Lot No. Filter", ItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    procedure InsertIntoDocEntry(DocTableID: Integer; DocTableName: Text; DocNoOfRecords: Integer)
    begin
        InsertIntoDocEntry(DocTableID, Enum::"Document Entry Document Type"::" ", DocTableName, DocNoOfRecords);
    end;

    procedure InsertIntoDocEntry(DocTableID: Integer; DocType: Enum "Document Entry Document Type"; DocTableName: Text; DocNoOfRecords: Integer)
    begin
        if DocNoOfRecords = 0 then
            exit;

        Rec.Init();
        Rec."Entry No." := Rec."Entry No." + 1;
        Rec."Table ID" := DocTableID;
        Rec."Document Type" := DocType;
        Rec."Table Name" := CopyStr(DocTableName, 1, MaxStrLen(Rec."Table Name"));
        Rec."No. of Records" := DocNoOfRecords;
        Rec.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetup(var DocumentEntry: Record "Document Entry"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;
}

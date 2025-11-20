// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Duplicates;

using System.Reflection;
using System.Utilities;

table 65 "Merge Duplicates Line Buffer"
{
    Caption = 'Merge Duplicates Line Buffer';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ',Field,Table';
            OptionMembers = ,"Field","Table";
        }
        field(2; ID; Integer)
        {
            Caption = 'ID';
        }
        field(3; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(4; "Duplicate Value"; Text[2048])
        {
            Caption = 'Duplicate Value';

            trigger OnValidate()
            begin
                "Duplicate Value" := CopyStr("Duplicate Value", 1, GetMaxFieldLen());
                ValidateDuplicateValue();
                Modified := "Duplicate Value" <> "Current Value";
            end;
        }
        field(5; "Current Value"; Text[2048])
        {
            Caption = 'Current Value';
        }
        field(6; Override; Boolean)
        {
            Caption = 'Override';

            trigger OnValidate()
            begin
                if Type = Type::Field then
                    TestField("In Primary Key", "In Primary Key"::No);
            end;
        }
        field(7; "Duplicate Count"; Integer)
        {
            Caption = 'Duplicate Count';
        }
        field(8; "Current Count"; Integer)
        {
            Caption = 'Current Count';
        }
        field(9; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(10; "Table Name"; Text[30])
        {
            Caption = 'Table Name';
        }
        field(11; "In Primary Key"; Option)
        {
            Caption = 'In Primary Key';
            InitValue = No;
            OptionCaption = 'Yes,No';
            OptionMembers = Yes,No;
        }
        field(12; Conflicts; Integer)
        {
            Caption = 'Conflicts';
        }
        field(13; Modified; Boolean)
        {
            Caption = 'Modified';
        }
        field(14; "Data Type"; Text[30])
        {
            Caption = 'Data Type';
            Editable = false;
        }
        field(15; "Can Be Renamed"; Boolean)
        {
            Caption = 'Can Be Renamed';
        }
    }

    keys
    {
        key(Key1; Type, "Table ID", ID)
        {
            Clustered = true;
        }
        key(Key2; "In Primary Key")
        {
        }
    }

    fieldgroups
    {
    }

    procedure AddFieldData(RecordRef: array[2] of RecordRef; ConflictFieldID: Integer; Index: Integer; FoundDuplicateRecord: Boolean; var TempPKInt: Record "Integer")
    var
        FieldRef: FieldRef;
    begin
        Init();
        Type := Type::Field;
        "Table ID" := RecordRef[1].Number;
        FieldRef := RecordRef[1].FieldIndex(Index);
        ID := FieldRef.Number;
        "Data Type" := CopyStr(Format(FieldRef.Type), 1, MaxStrLen("Data Type"));
        if TempPKInt.Get(ID) then
            "In Primary Key" := "In Primary Key"::Yes;
        Name := CopyStr(FieldRef.Caption, 1, MaxStrLen(Name));
        "Current Value" :=
          CopyStr(DelChr(Format(FieldRef.Value), '<>', ' '), 1, MaxStrLen("Current Value"));
        if FoundDuplicateRecord then begin
            FieldRef := RecordRef[2].FieldIndex(Index);
            "Duplicate Value" :=
              CopyStr(DelChr(Format(FieldRef.Value), '<>', ' '), 1, MaxStrLen("Duplicate Value"));
        end;
        if ("Duplicate Value" <> "Current Value") or ("In Primary Key" = "In Primary Key"::Yes) then begin
            if ConflictFieldID <> 0 then
                "Can Be Renamed" :=
                  ("In Primary Key" = "In Primary Key"::Yes) and ("Duplicate Value" = "Current Value") and
                  ("Data Type" in ['Text', 'Code']) and (ConflictFieldID <> ID);
            Insert();
        end;
    end;

    procedure AddTableData(MergeDuplicatesBuffer: Record "Merge Duplicates Buffer"; TableNo: Integer; FieldNo: Integer)
    var
        RecordRef: RecordRef;
    begin
        Init();
        Type := Type::Table;
        "Table ID" := TableNo;
        ID := FieldNo;
        RecordRef.Open("Table ID");
        "In Primary Key" := IsInPrimaryKey(RecordRef, FieldNo);
        CountRecords(MergeDuplicatesBuffer, RecordRef);
        RecordRef.Close();
        if "Duplicate Count" <> 0 then
            Insert();
    end;

    local procedure CountRecords(MergeDuplicatesBuffer: Record "Merge Duplicates Buffer"; RecordRef: RecordRef)
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
        FieldRef: FieldRef;
    begin
        "Table Name" := CopyStr(RecordRef.Caption, 1, MaxStrLen("Table Name"));
        if FindConditionalRelation(MergeDuplicatesBuffer."Table ID", TableRelationsMetadata) then begin
            FieldRef := RecordRef.Field(TableRelationsMetadata."Condition Field No.");
            FieldRef.SetFilter(TableRelationsMetadata."Condition Value");
        end;
        FieldRef := RecordRef.Field(ID);
        Name := CopyStr(FieldRef.Caption, 1, MaxStrLen(Name));
        FieldRef.SetRange(MergeDuplicatesBuffer.Duplicate);
        "Duplicate Count" := RecordRef.Count();
        FieldRef.SetRange(MergeDuplicatesBuffer.Current);
        "Current Count" := RecordRef.Count();
    end;

    local procedure FindConditionalRelation(RelatedTableID: Integer; var TableRelationsMetadata: Record "Table Relations Metadata"): Boolean
    begin
        TableRelationsMetadata.Reset();
        TableRelationsMetadata.SetRange("Table ID", "Table ID");
        TableRelationsMetadata.SetRange("Field No.", ID);
        TableRelationsMetadata.SetRange("Related Table ID", RelatedTableID);
        exit(TableRelationsMetadata.FindFirst());
    end;

    procedure FindConflicts(OldKey: Text; NewKey: Text; var TempMergeDuplicatesConflict: Record "Merge Duplicates Conflict" temporary): Integer
    var
        RecordRef: RecordRef;
        NewRecordRef: RecordRef;
        FieldRef: FieldRef;
        NewFieldRef: FieldRef;
    begin
        TempMergeDuplicatesConflict.Reset();
        TempMergeDuplicatesConflict.SetRange("Table ID", "Table ID");
        TempMergeDuplicatesConflict.DeleteAll();

        RecordRef.Open("Table ID");
        FieldRef := RecordRef.Field(ID);
        FieldRef.SetRange(OldKey);
        if RecordRef.FindSet() then
            repeat
                NewRecordRef.Get(RecordRef.RecordId);
                NewFieldRef := NewRecordRef.Field(ID);
                NewFieldRef.Value(NewKey);
                if NewRecordRef.Find() then begin
                    TempMergeDuplicatesConflict.Init();
                    TempMergeDuplicatesConflict.Validate("Table ID", "Table ID");
                    TempMergeDuplicatesConflict.Duplicate := RecordRef.RecordId;
                    TempMergeDuplicatesConflict.Current := NewRecordRef.RecordId;
                    TempMergeDuplicatesConflict."Field ID" := ID;
                    TempMergeDuplicatesConflict.Insert();
                end;
            until RecordRef.Next() = 0;
        RecordRef.Close();

        Conflicts := TempMergeDuplicatesConflict.Count();
        TempMergeDuplicatesConflict.Reset();
        exit(Conflicts);
    end;

    procedure GetPrimaryKeyFields(RecRef: RecordRef; var TempPKInt: Record "Integer" temporary): Integer
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        KeyFieldIndex: Integer;
    begin
        TempPKInt.Reset();
        TempPKInt.DeleteAll();
        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldIndex := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(KeyFieldIndex);
            TempPKInt.Number := FieldRef.Number;
            TempPKInt.Insert();
        end;
        exit(TempPKInt.Count);
    end;

    local procedure IsInPrimaryKey(RecordRef: RecordRef; FieldNo: Integer): Integer
    var
        TempPKInt: Record "Integer" temporary;
    begin
        GetPrimaryKeyFields(RecordRef, TempPKInt);
        if TempPKInt.Get(FieldNo) then
            exit("In Primary Key"::Yes);
        exit("In Primary Key"::No);
    end;

    procedure HasFieldToOverride() Result: Boolean
    var
        TempMergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer" temporary;
    begin
        TempMergeDuplicatesLineBuffer.Copy(Rec, true);
        TempMergeDuplicatesLineBuffer.SetRange(Type, Type::Field);
        TempMergeDuplicatesLineBuffer.SetRange(Override, true);
        Result := not TempMergeDuplicatesLineBuffer.IsEmpty();
    end;

    procedure HasModifiedField() Result: Boolean
    var
        TempMergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer" temporary;
    begin
        TempMergeDuplicatesLineBuffer.Copy(Rec, true);
        TempMergeDuplicatesLineBuffer.SetRange(Type, Type::Field);
        TempMergeDuplicatesLineBuffer.SetRange(Modified, true);
        Result := not TempMergeDuplicatesLineBuffer.IsEmpty();
    end;

    local procedure GetMaxFieldLen(): Integer
    var
        "Field": Record "Field";
    begin
        Field.Get("Table ID", ID);
        exit(Field.Len);
    end;

    local procedure ValidateDuplicateValue()
    var
        TempMergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer" temporary;
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        TempMergeDuplicatesLineBuffer.Copy(xRec, true);
        RecRef.Open("Table ID");
        TempMergeDuplicatesLineBuffer.Reset();
        if TempMergeDuplicatesLineBuffer.FindSet() then
            repeat
                FieldRef := RecRef.Field(TempMergeDuplicatesLineBuffer.ID);
                FieldRef.SetFilter(TempMergeDuplicatesLineBuffer."Duplicate Value");
            until TempMergeDuplicatesLineBuffer.Next() = 0;
        if RecRef.FindFirst() then begin
            FieldRef := RecRef.Field(ID);
            FieldRef.Validate("Duplicate Value");
            "Duplicate Value" := Format(FieldRef.Value);
        end;
        RecRef.Close();
    end;
}


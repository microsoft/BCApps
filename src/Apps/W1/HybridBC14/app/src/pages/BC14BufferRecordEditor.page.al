// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

/// <summary>
/// Generic buffer record editor page.
/// Allows editing any buffer table record using RecordRef, similar to Integration Table Mapping approach.
/// </summary>
page 50178 "BC14 Buffer Record Editor"
{
    PageType = List;
    ApplicationArea = All;
    Caption = 'Buffer Record Editor';
    SourceTable = "BC14 Buffer Field Editor";
    SourceTableTemporary = true;
    Editable = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(RecordInfo)
            {
                Caption = 'Record Information';
                field(TableNameField; TableNameText)
                {
                    ApplicationArea = All;
                    Caption = 'Table';
                    ToolTip = 'Specifies the buffer table name.';
                    Editable = false;
                }
                field(RecordKeyField; RecordKeyText)
                {
                    ApplicationArea = All;
                    Caption = 'Record Key';
                    ToolTip = 'Specifies the record primary key.';
                    Editable = false;
                }
            }
            repeater(Fields)
            {
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field name.';
                    Editable = false;
                    Style = Strong;
                }
                field("Field Value"; Rec."Field Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field value. Edit to change.';
                    Editable = Rec."Is Editable";

                    trigger OnValidate()
                    begin
                        FieldValueChanged := true;
                    end;
                }
                field("Field Type"; Rec."Field Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field data type.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SaveChanges)
            {
                ApplicationArea = All;
                Caption = 'Save Changes';
                ToolTip = 'Save all changes back to the buffer record.';
                Image = Save;

                trigger OnAction()
                begin
                    SaveRecordChanges();
                    Message(ChangesSavedMsg);
                end;
            }
            action(ReloadRecord)
            {
                ApplicationArea = All;
                Caption = 'Reload';
                ToolTip = 'Reload the record from the database, discarding unsaved changes.';
                Image = Refresh;

                trigger OnAction()
                begin
                    LoadRecordFields();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(SaveChanges_Promoted; SaveChanges) { }
            actionref(ReloadRecord_Promoted; ReloadRecord) { }
        }
    }

    trigger OnOpenPage()
    begin
        if Format(SourceRecordId) = '' then
            Error(NoRecordSpecifiedErr);

        LoadRecordFields();
    end;

    trigger OnClosePage()
    begin
        if FieldValueChanged then
            if Confirm(SaveChangesQst) then
                SaveRecordChanges();
    end;

    var
        SourceRecordId: RecordId;
        TableNameText: Text[250];
        RecordKeyText: Text[250];
        FieldValueChanged: Boolean;
        NoRecordSpecifiedErr: Label 'No record was specified for editing.';
        ChangesSavedMsg: Label 'Changes have been saved to the buffer record.';
        SaveChangesQst: Label 'You have unsaved changes. Do you want to save them?';
        RecordNotFoundErr: Label 'The record could not be found. It may have been deleted.';

    procedure SetSourceRecord(NewRecordId: RecordId)
    begin
        SourceRecordId := NewRecordId;
    end;

    local procedure LoadRecordFields()
    var
        SourceRecRef: RecordRef;
        SourceFldRef: FieldRef;
        i: Integer;
    begin
        Rec.DeleteAll();
        FieldValueChanged := false;

        SourceRecRef.Open(SourceRecordId.TableNo);
        if not SourceRecRef.Get(SourceRecordId) then
            Error(RecordNotFoundErr);

        TableNameText := CopyStr(SourceRecRef.Caption, 1, MaxStrLen(TableNameText));
        RecordKeyText := CopyStr(Format(SourceRecRef.RecordId), 1, MaxStrLen(RecordKeyText));

        for i := 1 to SourceRecRef.FieldCount do begin
            SourceFldRef := SourceRecRef.FieldIndex(i);

            // Skip FlowFields, FlowFilters, and system fields
            if SourceFldRef.Class = FieldClass::Normal then
                if not IsSystemField(SourceFldRef.Number) then begin
                    Rec.Init();
                    Rec."Field No." := SourceFldRef.Number;
                    Rec."Field Name" := CopyStr(SourceFldRef.Caption, 1, MaxStrLen(Rec."Field Name"));
                    Rec."Field Value" := CopyStr(Format(SourceFldRef.Value), 1, MaxStrLen(Rec."Field Value"));
                    Rec."Field Type" := CopyStr(Format(SourceFldRef.Type), 1, MaxStrLen(Rec."Field Type"));
                    Rec."Is Editable" := IsEditableFieldType(SourceFldRef.Type);
                    Rec.Insert();
                end;
        end;

        SourceRecRef.Close();

        if Rec.FindFirst() then;
    end;

    local procedure SaveRecordChanges()
    var
        SourceRecRef: RecordRef;
        SourceFldRef: FieldRef;
    begin
        SourceRecRef.Open(SourceRecordId.TableNo);
        if not SourceRecRef.Get(SourceRecordId) then
            Error(RecordNotFoundErr);

        if Rec.FindSet() then
            repeat
                if Rec."Is Editable" then begin
                    SourceFldRef := SourceRecRef.Field(Rec."Field No.");
                    SetFieldValue(SourceFldRef, Rec."Field Value");
                end;
            until Rec.Next() = 0;

        SourceRecRef.Modify(true);
        SourceRecRef.Close();
        FieldValueChanged := false;
    end;

    local procedure SetFieldValue(var FldRef: FieldRef; NewValue: Text)
    var
        IntValue: Integer;
        DecValue: Decimal;
        BoolValue: Boolean;
        DateValue: Date;
        TimeValue: Time;
        DateTimeValue: DateTime;
    begin
        case FldRef.Type of
            FieldType::Text, FieldType::Code:
                FldRef.Value := NewValue;
            FieldType::Integer, FieldType::Option:
                if Evaluate(IntValue, NewValue) then
                    FldRef.Value := IntValue;
            FieldType::Decimal:
                if Evaluate(DecValue, NewValue) then
                    FldRef.Value := DecValue;
            FieldType::Boolean:
                if Evaluate(BoolValue, NewValue) then
                    FldRef.Value := BoolValue;
            FieldType::Date:
                if Evaluate(DateValue, NewValue) then
                    FldRef.Value := DateValue;
            FieldType::Time:
                if Evaluate(TimeValue, NewValue) then
                    FldRef.Value := TimeValue;
            FieldType::DateTime:
                if Evaluate(DateTimeValue, NewValue) then
                    FldRef.Value := DateTimeValue;
        end;
    end;

    local procedure IsEditableFieldType(FldType: FieldType): Boolean
    begin
        exit(FldType in [
            FieldType::Text,
            FieldType::Code,
            FieldType::Integer,
            FieldType::Decimal,
            FieldType::Boolean,
            FieldType::Date,
            FieldType::Time,
            FieldType::DateTime,
            FieldType::Option
        ]);
    end;

    local procedure IsSystemField(FieldNo: Integer): Boolean
    begin
        // System fields: SystemId, SystemCreatedAt, SystemCreatedBy, SystemModifiedAt, SystemModifiedBy
        exit(FieldNo in [2000000000 .. 2000000999]);
    end;
}

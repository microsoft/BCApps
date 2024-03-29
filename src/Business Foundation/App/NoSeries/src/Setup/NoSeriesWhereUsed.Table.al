// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

table 1 "No. Series Where-Used"
{
    Caption = 'No. Series Where-Used';
    LookupPageID = "No. Series Where-Used List";
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(3; "Table Name"; Text[150])
        {
            Caption = 'Table Name';
        }
        field(5; "Field Name"; Text[150])
        {
            Caption = 'Field Name';
        }
        field(6; Line; Text[250])
        {
            Caption = 'Line';
        }
        field(7; "No. Series Code"; Code[20])
        {
            Caption = 'No. Series Code';
        }
        field(8; "No. Series Description"; Text[100])
        {
            Caption = 'No. Series Description';
        }
        field(9; "Key 1"; Text[50])
        {
            Caption = 'Key 1';
        }
        field(10; "Key 2"; Text[50])
        {
            Caption = 'Key 2';
        }
        field(11; "Key 3"; Text[50])
        {
            Caption = 'Key 3';
        }
        field(12; "Key 4"; Text[50])
        {
            Caption = 'Key 4';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Table Name")
        {
        }
    }

    fieldgroups
    {
    }

    var
        WrongParameterTypeErr: Label 'Parameter type must be Record or RecordRef.';

    procedure Caption(): Text
    begin
        exit(StrSubstNo('%1 %2', "No. Series Code", "No. Series Description"));
    end;

    // TODO: The "Find Record Management" codeunit is located in the W1 BaseApp Utilities
    // TODO: We would need to implement the Find Record Management into the System Application
    // procedure GetLastEntryNo(): Integer;
    // var
    //     FindRecordManagement: Codeunit "Find Record Management";
    // begin
    //     exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    // end;

    procedure GetLastEntryNo(): Integer;
    begin
        GetLastEntryIntFieldValue(Rec, FieldNo("Entry No."));
    end;

    procedure GetLastEntryIntFieldValue(SourceRec: Variant; FieldNo: Integer): Integer;
    var
        IntFields: list of [Integer];
    begin
        IntFields.Add(FieldNo);
        GetLastEntryIntFieldValues(SourceRec, IntFields);
        exit(IntFields.Get(1));
    end;

    procedure GetLastEntryIntFieldValues(SourceRec: Variant; var FieldNoValues: List of [Integer])
    var
        RecRef: RecordRef;
        FieldNo: Integer;
        FirstIteration: Boolean;
    begin
        ConvertVariantToRecordRef(SourceRec, RecRef);
        RecRef.Reset();
        FirstIteration := true;
        foreach FieldNo in FieldNoValues do
            if RecRef.FieldExist(FieldNo) then
                if FirstIteration then begin
                    RecRef.SetLoadFields(FieldNo);
                    FirstIteration := false;
                end else
                    RecRef.AddLoadFields(FieldNo);

        FindLastEntryIgnoringSecurityFilter(RecRef);
        GetIntFieldValues(RecRef, FieldNoValues);
    end;

    local procedure ConvertVariantToRecordRef(SourceRec: Variant; var RecRef: RecordRef)
    begin
        case true of
            SourceRec.IsRecordRef:
                RecRef := SourceRec;
            SourceRec.IsRecord:
                RecRef.GetTable(SourceRec);
            else
                Error(WrongParameterTypeErr);
        end;
    end;

    procedure FindLastEntryIgnoringSecurityFilter(var RecRef: RecordRef) Found: Boolean;
    var
        IsHandled: Boolean;
        xSecurityFilter: SecurityFilter;
    begin
        OnBeforeFindLastEntryIgnoringSecurityFilter(RecRef, Found, IsHandled);
        if IsHandled then
            exit(Found);

        xSecurityFilter := RecRef.SecurityFiltering;
        RecRef.SecurityFiltering(RecRef.SecurityFiltering::Ignored);
        Found := RecRef.FindLast();
        if RecRef.SecurityFiltering <> xSecurityFilter then
            RecRef.SecurityFiltering(xSecurityFilter)
    end;

    // [Scope('OnPrem')]
    procedure GetIntFieldValues(RecRef: RecordRef; var IntFields: list of [Integer])
    var
        FieldNos: list of [Integer];
        FieldNo: Integer;
        FieldValue: Variant;
    begin
        FieldNos := IntFields;
        clear(IntFields);
        foreach FieldNo in FieldNos do
            if IsFieldValid(RecRef, FieldNo, FieldType::Integer, FieldValue) then
                IntFields.Add(FieldValue)
            else
                IntFields.Add(0);
    end;

    local procedure IsFieldValid(RecRef: RecordRef; FieldNo: Integer; ExpectedFieldType: FieldType; var Value: Variant): Boolean
    var
        FldRef: FieldRef;
    begin
        Clear(Value);
        if RecRef.FieldExist(FieldNo) then begin
            FldRef := RecRef.Field(FieldNo);
            if FldRef.Type = ExpectedFieldType then begin
                if FldRef.Class = FieldClass::FlowField then
                    FldRef.CalcField();
                Value := FldRef.Value();
                exit(true);
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindLastEntryIgnoringSecurityFilter(var RecRef: RecordRef; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

}
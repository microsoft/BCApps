// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using System.IO;
using System.Reflection;
using System.Text;
using System.Utilities;

table 11003 "Data Export Record Definition"
{
    Caption = 'Data Export Record Definition';
    DataCaptionFields = "Data Export Code", "Data Exp. Rec. Type Code";
    LookupPageID = "Data Export Record Definitions";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Export Code"; Code[10])
        {
            Caption = 'Data Export Code';
            NotBlank = true;
            TableRelation = "Data Export";
        }
        field(2; "Data Exp. Rec. Type Code"; Code[10])
        {
            Caption = 'Data Export Record Type Code';
            NotBlank = true;
            TableRelation = "Data Export Record Type";

            trigger OnValidate()
            var
                DataExportRecordType: Record "Data Export Record Type";
            begin
                if DataExportRecordType.Get("Data Exp. Rec. Type Code") and (Description = '') then
                    Description := DataExportRecordType.Description;
            end;
        }
        field(3; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(5; "DTD File Name"; Text[50])
        {
            Caption = 'DTD File Name';
            Editable = false;
        }
        field(6; "DTD File"; BLOB)
        {
            Caption = 'DTD File';
        }
        field(7; "File Encoding"; Enum "Data Export File Encoding")
        {
            Caption = 'File Encoding';
        }
    }

    keys
    {
        key(Key1; "Data Export Code", "Data Exp. Rec. Type Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DataExportRecordSource: Record "Data Export Record Source";
    begin
        DataExportRecordSource.Reset();
        DataExportRecordSource.SetRange("Data Export Code", "Data Export Code");
        DataExportRecordSource.SetRange("Data Exp. Rec. Type Code", "Data Exp. Rec. Type Code");
        DataExportRecordSource.DeleteAll(true);
    end;

    trigger OnRename()
    begin
        Error(MustRenameErr, TableCaption);
    end;

    var
        MustRenameErr: Label 'You must not rename a %1.';
        NotFirstFieldMsg: Label 'The %1 field is not the first field that is specified for the %2 table. You must change the data export setup to list the primary key field first.';
        CannotIncludePeriodFieldMsg: Label 'You cannot include the period field %1 in the table filter expression for the %2 table.';
        ValidatedCorrectlyMsg: Label 'The data export record source validated correctly.';

    [Scope('OnPrem')]
    procedure ValidateExportSources()
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecordField: Record "Data Export Record Field";
        KeyBuffer: Record "Key Buffer";
        "Field": Record "Field";
        KeyArray: array[20] of Text[250];
        PrimaryKeyText: Text[250];
        ErrorsFound: Boolean;
        IsPrimary: Boolean;
        IsKey: Boolean;
        ShowMessage: Boolean;
        Count1: Integer;
        Count2: Integer;
        i: Integer;
        NoOfComma: Integer;
    begin
        ErrorsFound := false;

        OnBeforeValidateExportSources(Rec, ErrorsFound);
        DataExportRecordSource.Reset();
        DataExportRecordSource.SetRange("Data Export Code", "Data Export Code");
        DataExportRecordSource.SetRange("Data Exp. Rec. Type Code", "Data Exp. Rec. Type Code");
        UpdateRecordSources(DataExportRecordSource);
        if DataExportRecordSource.FindSet() then
            repeat
                Count1 := 0;
                i := 1;
                NoOfComma := 0;
                PrimaryKeyText := '';
                FillKeyBuffer(DataExportRecordSource."Table No.", KeyBuffer);
                if KeyBuffer.FindFirst() then begin
                    PrimaryKeyText := KeyBuffer.Key;
                    repeat
                        KeyArray[i] := SelectStr(1, PrimaryKeyText);
                        i := i + 1;
                        NoOfComma := StrPos(PrimaryKeyText, ',');
                        PrimaryKeyText := CopyStr(PrimaryKeyText, NoOfComma + 1, MaxStrLen(PrimaryKeyText));
                        Count1 := Count1 + 1;
                    until NoOfComma = 0;
                    Count2 := Count1;
                end;

                i := 1;
                IsKey := true;
                IsPrimary := true;
                ShowMessage := true;
                DataExportRecordField.Reset();
                DataExportRecordField.SetRange("Data Export Code", "Data Export Code");
                DataExportRecordField.SetRange("Data Exp. Rec. Type Code", "Data Exp. Rec. Type Code");
                DataExportRecordField.SetRange("Table No.", DataExportRecordSource."Table No.");
                DataExportRecordField.SetRange("Source Line No.", DataExportRecordSource."Line No.");
                if DataExportRecordField.FindSet() then
                    repeat
                        repeat
                            DataExportRecordField.CalcFields("Table Name", "Field Name");
                            Field.Reset();
                            Field.SetRange(TableNo, DataExportRecordField."Table No.");
                            Field.SetRange("No.", DataExportRecordField."Field No.");
                            Field.FindFirst();
                            if KeyArray[i] = Field.FieldName then begin
                                if IsPrimary and not IsKey and ShowMessage then begin
                                    ErrorsFound := true;
                                    Message(NotFirstFieldMsg, DataExportRecordField."Field Name", DataExportRecordField."Table Name");
                                    ShowMessage := false;
                                end else begin
                                    IsPrimary := true;
                                    IsKey := true;
                                end;
                                Count1 := 0;
                            end else begin
                                i := i + 1;
                                Count1 := Count1 - 1;
                                if Count1 = 0 then
                                    IsKey := false;
                            end;
                        until Count1 = 0;
                        i := 1;
                        Count1 := Count2;
                    until DataExportRecordField.Next() = 0;

                if DataExportRecordSource.IsPeriodFieldInTableFilter() then begin
                    ErrorsFound := true;
                    DataExportRecordSource.CalcFields("Table Name");
                    Message(CannotIncludePeriodFieldMsg, DataExportRecordSource."Period Field Name", DataExportRecordSource."Table Name");
                end;

            until DataExportRecordSource.Next() = 0;

        if not ErrorsFound then
            Message(ValidatedCorrectlyMsg);
    end;

    [Scope('OnPrem')]
    procedure FillKeyBuffer(TableNo: Integer; var KeyBuffer: Record "Key Buffer")
    var
        "Key": Record "Key";
    begin
        KeyBuffer.DeleteAll();
        Key.Reset();
        Key.SetRange(TableNo, TableNo);
        if Key.FindSet() then
            repeat
                KeyBuffer.Init();
                KeyBuffer."Table No" := Key.TableNo;
                KeyBuffer."Field No." := Key."No.";
                KeyBuffer.Key := CopyStr(Key.Key, 1, 250);
                KeyBuffer.Insert();
            until Key.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ImportFile(DataExportRecordDefinition: Record "Data Export Record Definition")
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        RecordRef: RecordRef;
        FileName: Text;
    begin
        FileName := FileMgt.BLOBImport(TempBlob, FileName);
        if FileName = '' then
            exit;
        while StrPos(FileName, '\') <> 0 do
            FileName := CopyStr(FileName, StrPos(FileName, '\') + 1);
        DataExportRecordDefinition."DTD File Name" := CopyStr(FileName, 1, MaxStrLen(DataExportRecordDefinition."DTD File Name"));
        RecordRef.GetTable(DataExportRecordDefinition);
        TempBlob.ToRecordRef(RecordRef, DataExportRecordDefinition.FieldNo("DTD File"));
        RecordRef.SetTable(DataExportRecordDefinition);
        DataExportRecordDefinition.Modify();
    end;

    [Scope('OnPrem')]
    procedure ExportFile(DataExportRecordDefinition: Record "Data Export Record Definition"; ShowDialog: Boolean): Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        RecordRef: RecordRef;
        ToFile: Text;
    begin
        DataExportRecordDefinition.CalcFields("DTD File");
        if DataExportRecordDefinition."DTD File".HasValue or not ShowDialog then begin
            RecordRef.GetTable(DataExportRecordDefinition);
            TempBlob.ToRecordRef(RecordRef, DataExportRecordDefinition.FieldNo("DTD File"));
            RecordRef.SetTable(DataExportRecordDefinition);
            ToFile := FileMgt.BLOBExport(TempBlob, DataExportRecordDefinition."DTD File Name", ShowDialog);
            exit(ToFile);
        end;
        exit('');
    end;

    local procedure UpdateRecordSources(var DataExportRecordSource: Record "Data Export Record Source")
    var
        ParentLineNo: array[100] of Integer;
    begin
        if DataExportRecordSource.FindSet() then
            repeat
                if DataExportRecordSource.Indentation > 0 then
                    DataExportRecordSource."Relation To Line No." := ParentLineNo[DataExportRecordSource.Indentation];

                if UpdateFields(DataExportRecordSource) then
                    DataExportRecordSource."Date Filter Handling" := FindDateFilterHandling(DataExportRecordSource);
                DataExportRecordSource.Modify();

                ParentLineNo[DataExportRecordSource.Indentation + 1] := DataExportRecordSource."Line No.";
            until DataExportRecordSource.Next() = 0;
    end;

    local procedure FindDateFilterHandling(DataExportRecordSource: Record "Data Export Record Source"): Integer
    var
        TableFilterPage: Page "Table Filter";
        TempTableFilter: Record "Table Filter";
        DataExportRecordField: Record "Data Export Record Field";
        TableFilterText: Text;
    begin
        TableFilterText := Format(DataExportRecordSource."Table Filter");
        if TableFilterText <> '' then begin
            TableFilterPage.SetSourceTable(TableFilterText, DataExportRecordSource."Table No.", DataExportRecordSource."Table Name");
            TableFilterPage.GetFilterFieldsList(TempTableFilter);
            if TempTableFilter.FindSet() then
                repeat
                    DataExportRecordField.SetRange("Data Export Code", DataExportRecordSource."Data Export Code");
                    DataExportRecordField.SetRange("Data Exp. Rec. Type Code", DataExportRecordSource."Data Exp. Rec. Type Code");
                    DataExportRecordField.SetRange("Table No.", DataExportRecordSource."Table No.");
                    DataExportRecordField.SetRange("Field No.", TempTableFilter."Field Number");
                    DataExportRecordField.SetRange("Field Class", DataExportRecordField."Field Class"::FlowField);
                    if DataExportRecordField.FindFirst() then
                        exit(DataExportRecordField."Date Filter Handling");
                until TempTableFilter.Next() = 0;
        end;
    end;

    local procedure UpdateFields(DataExportRecordSource: Record "Data Export Record Source") Updated: Boolean
    var
        DataExportRecordField: Record "Data Export Record Field";
        NewDataExportRecordField: Record "Data Export Record Field";
    begin
        DataExportRecordField.SetRange("Data Export Code", DataExportRecordSource."Data Export Code");
        DataExportRecordField.SetRange("Data Exp. Rec. Type Code", DataExportRecordSource."Data Exp. Rec. Type Code");
        DataExportRecordField.SetRange("Table No.", DataExportRecordSource."Table No.");
        DataExportRecordField.SetRange("Source Line No.", 0);
        if DataExportRecordField.FindSet() then begin
            repeat
                NewDataExportRecordField := DataExportRecordField;
                NewDataExportRecordField."Source Line No." := DataExportRecordSource."Line No.";
                NewDataExportRecordField.Validate("Field No.");
                NewDataExportRecordField.Insert();
            until DataExportRecordField.Next() = 0;
            DataExportRecordField.DeleteAll();
            Updated := true;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateExportSources(var DataExportRecordDefinition: Record "Data Export Record Definition"; var ErrorsFound: Boolean)
    begin
    end;
}

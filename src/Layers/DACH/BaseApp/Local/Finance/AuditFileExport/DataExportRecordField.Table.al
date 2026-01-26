// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using System.Reflection;

table 11005 "Data Export Record Field"
{
    Caption = 'Data Exp. Rec. Field';
    DataCaptionFields = "Data Export Code", "Data Exp. Rec. Type Code";
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
        }
        field(3; "Table No."; Integer)
        {
            BlankZero = true;
            Caption = 'Table No.';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnValidate()
            begin
                UpdateFieldProperties();
            end;
        }
        field(4; "Table Name"; Text[80])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table No.")));
            Caption = 'Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Field No."; Integer)
        {
            BlankZero = true;
            Caption = 'Field No.';
            NotBlank = true;
            TableRelation = Field."No." where(TableNo = field("Table No."),
                                               Type = filter(Option | Text | Code | Integer | Decimal | Date | Boolean | DateTime),
                                               ObsoleteState = filter(<> Removed));

            trigger OnValidate()
            var
                Field: Record Field;
                DataExportManagement: Codeunit "Data Export Management";
            begin
                Field.Get("Table No.", "Field No.");
                if "Export Field Name" = '' then
                    "Export Field Name" := DataExportManagement.FormatForIndexXML(Field.FieldName);

                TestField("Export Field Name");
                UpdateFieldProperties();
            end;
        }
        field(6; "Field Name"; Text[80])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table No."),
                                                              "No." = field("Field No.")));
            Caption = 'Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(8; "Field Class"; Option)
        {
            Caption = 'Field Class';
            Editable = false;
            OptionCaption = 'Normal,FlowField,FlowFilter';
            OptionMembers = Normal,FlowField,FlowFilter;
        }
        field(9; "Date Filter Handling"; Option)
        {
            Caption = 'Date Filter Handling';
            OptionCaption = ' ,Period,End Date Only,Start Date Only';
            OptionMembers = " ",Period,"End Date Only","Start Date Only";

            trigger OnValidate()
            begin
                if "Field Class" <> "Field Class"::FlowField then
                    Error(CannotModifyErr, FieldCaption("Date Filter Handling"));
            end;
        }
        field(10; "Field Type"; Option)
        {
            Caption = 'Field Type';
            Editable = false;
            OptionCaption = ',Date,Decimal,Text,Code,Boolean,Integer,Option,DateTime';
            OptionMembers = ,Date,Decimal,Text,"Code",Boolean,"Integer",Option,DateTime;
        }
        field(11; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        field(50; "Export Field Name"; Text[50])
        {
            Caption = 'Export Field Name';
        }
    }

    keys
    {
        key(Key1; "Data Export Code", "Data Exp. Rec. Type Code", "Source Line No.", "Table No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Data Export Code");
        TestField("Data Exp. Rec. Type Code");
        CheckIfInsertAllowed(Rec);
    end;

    var
        CannotModifyErr: Label 'The %1 can only be modified for fields that have the FieldClass property set to "FlowField".';
        FieldAlreadyAddedErr: Label 'The %1 field has already been added. Only fields of type "FlowField" can be added more than once.';

    [Scope('OnPrem')]
    procedure MoveRecordUp(SelectedDataExportRecordField: Record "Data Export Record Field") NewLineNo: Integer
    begin
        NewLineNo := FindPreviousRecordLineNo(SelectedDataExportRecordField);
        MoveRecord(SelectedDataExportRecordField, NewLineNo);
    end;

    [Scope('OnPrem')]
    procedure MoveRecordDown(SelectedDataExportRecordField: Record "Data Export Record Field") NewLineNo: Integer
    begin
        NewLineNo := FindNextRecordLineNo(SelectedDataExportRecordField);
        MoveRecord(SelectedDataExportRecordField, NewLineNo);
    end;

    local procedure MoveRecord(SelectedDataExportRecordField: Record "Data Export Record Field"; NewLineNo: Integer)
    begin
        if NewLineNo = -1 then
            NewLineNo := SelectedDataExportRecordField."Line No."
        else begin
            Get(
              SelectedDataExportRecordField."Data Export Code",
              SelectedDataExportRecordField."Data Exp. Rec. Type Code",
              SelectedDataExportRecordField."Source Line No.",
              SelectedDataExportRecordField."Table No.",
              NewLineNo);
            Swap(Rec, SelectedDataExportRecordField);
        end;
    end;

    local procedure Swap(DataExportRecordField1: Record "Data Export Record Field"; DataExportRecordField2: Record "Data Export Record Field")
    var
        TempLineNo1: Integer;
        TempLineNo2: Integer;
    begin
        TempLineNo1 := DataExportRecordField1."Line No.";
        TempLineNo2 := DataExportRecordField2."Line No.";
        DataExportRecordField1.Rename(DataExportRecordField1."Data Export Code", DataExportRecordField1."Data Exp. Rec. Type Code", DataExportRecordField1."Source Line No.", DataExportRecordField1."Table No.", FindUnusedLineNo(DataExportRecordField1));
        DataExportRecordField2.Rename(DataExportRecordField2."Data Export Code", DataExportRecordField2."Data Exp. Rec. Type Code", DataExportRecordField2."Source Line No.", DataExportRecordField2."Table No.", TempLineNo1);
        DataExportRecordField1.Rename(DataExportRecordField1."Data Export Code", DataExportRecordField1."Data Exp. Rec. Type Code", DataExportRecordField1."Source Line No.", DataExportRecordField1."Table No.", TempLineNo2);
    end;

    local procedure FindPreviousRecordLineNo(SearchDataExportRecordField: Record "Data Export Record Field"): Integer
    begin
        exit(FindAdjacentRecordLineNo(SearchDataExportRecordField, -1));
    end;

    local procedure FindNextRecordLineNo(SearchDataExportRecordField: Record "Data Export Record Field"): Integer
    begin
        exit(FindAdjacentRecordLineNo(SearchDataExportRecordField, 1));
    end;

    local procedure FindAdjacentRecordLineNo(SearchDataExportRecordField: Record "Data Export Record Field"; Step: Integer) NextRecLineNo: Integer
    var
        CurrentPosition: Text[1024];
    begin
        NextRecLineNo := -1;
        CurrentPosition := SearchDataExportRecordField.GetPosition();
        SetFiltersForKeyWithoutLineNo(
          SearchDataExportRecordField,
          SearchDataExportRecordField."Data Export Code",
          SearchDataExportRecordField."Data Exp. Rec. Type Code",
          SearchDataExportRecordField."Source Line No.");
        if SearchDataExportRecordField.Next(Step) <> 0 then
            NextRecLineNo := SearchDataExportRecordField."Line No.";

        SearchDataExportRecordField.SetPosition(CurrentPosition);
    end;

    local procedure FindUnusedLineNo(SearchDataExportRecordField: Record "Data Export Record Field"): Integer
    var
        DataExportRecordField: Record "Data Export Record Field";
        UnusedLineNo: Integer;
    begin
        UnusedLineNo := -9999;
        while DataExportRecordField.Get(
                SearchDataExportRecordField."Data Export Code",
                SearchDataExportRecordField."Data Exp. Rec. Type Code",
                SearchDataExportRecordField."Source Line No.",
                SearchDataExportRecordField."Table No.",
                UnusedLineNo)
        do
            UnusedLineNo += 1;
        exit(UnusedLineNo);
    end;

    local procedure InsertLine(ExportCode: Code[10]; RecordCode: Code[10]; SourceLineNo: Integer; SelectedLineNo: Integer; TableNo: Integer; FieldNo: Integer) NewLineNo: Integer
    var
        NewDataExportRecordField: Record "Data Export Record Field";
    begin
        NewLineNo := InsertLineAtEnd(ExportCode, RecordCode, SourceLineNo, TableNo, FieldNo);
        if SelectedLineNo = 0 then
            exit;

        NewDataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, NewLineNo);
        while FindPreviousRecordLineNo(NewDataExportRecordField) <> SelectedLineNo do begin
            NewLineNo := MoveRecordUp(NewDataExportRecordField);
            NewDataExportRecordField.Get(ExportCode, RecordCode, SourceLineNo, TableNo, NewLineNo);
        end;
    end;

    local procedure InsertLineAtEnd(ExportCode: Code[10]; RecordCode: Code[10]; SourceLineNo: Integer; TableNo: Integer; FieldNo: Integer) NewLineNo: Integer
    var
        NewDataExportRecordField: Record "Data Export Record Field";
    begin
        NewLineNo := GetLineNoForLastRecord(ExportCode, RecordCode, SourceLineNo);

        NewDataExportRecordField.Init();
        NewDataExportRecordField."Data Export Code" := ExportCode;
        NewDataExportRecordField."Data Exp. Rec. Type Code" := RecordCode;
        NewDataExportRecordField."Source Line No." := SourceLineNo;
        NewDataExportRecordField."Line No." := NewLineNo;
        NewDataExportRecordField."Table No." := TableNo;
        NewDataExportRecordField.Validate("Field No.", FieldNo);
        NewDataExportRecordField.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure InsertSelectedFields(var SelectedField: Record "Field"; DataExportCode: Code[10]; DataExpRecTypeCode: Code[10]; SourceLineNo: Integer; SelectedLineNo: Integer)
    var
        TableNo: Integer;
        NewLineNo: Integer;
    begin
        LockTable();
        NewLineNo := SelectedLineNo;
        if SelectedField.FindSet() then begin
            TableNo := SelectedField.TableNo;
            repeat
                NewLineNo := InsertLine(DataExportCode, DataExpRecTypeCode, SourceLineNo, NewLineNo, TableNo, SelectedField."No.");
            until SelectedField.Next() = 0;
        end;

        // Keep the original selection
        if SelectedLineNo = 0 then
            SelectedLineNo := GetFirstLineNo();
        Get(DataExportCode, DataExpRecTypeCode, SourceLineNo, TableNo, SelectedLineNo);
    end;

    local procedure GetFirstLineNo(): Integer
    begin
        exit(1000);
    end;

    local procedure GetLineNoStep(): Integer
    begin
        exit(1000);
    end;

    local procedure CheckIfInsertAllowed(DataExportRecordField: Record "Data Export Record Field")
    begin
        SetFiltersForKeyWithoutLineNo(
          DataExportRecordField, DataExportRecordField."Data Export Code",
          DataExportRecordField."Data Exp. Rec. Type Code",
          DataExportRecordField."Source Line No.");
        DataExportRecordField.SetRange("Field No.", DataExportRecordField."Field No.");
        DataExportRecordField.SetFilter("Field Class", '%1|%2', "Field Class"::Normal, "Field Class"::FlowFilter);
        if not DataExportRecordField.IsEmpty() then begin
            DataExportRecordField.CalcFields("Field Name");
            Error(FieldAlreadyAddedErr, Format(DataExportRecordField."Field Name"));
        end;
    end;

    local procedure GetLineNoForLastRecord(ExportCode: Code[10]; RecordCode: Code[10]; SourceLineNo: Integer) NewLine: Integer
    var
        DataExportRecordField: Record "Data Export Record Field";
    begin
        SetFiltersForKeyWithoutLineNo(DataExportRecordField, ExportCode, RecordCode, SourceLineNo);
        if DataExportRecordField.FindLast() then
            NewLine := DataExportRecordField."Line No." + GetLineNoStep()
        else
            NewLine := GetFirstLineNo();
    end;

    local procedure SetFiltersForKeyWithoutLineNo(var DataExportRecordField: Record "Data Export Record Field"; ExportCode: Code[10]; RecordCode: Code[10]; SourceLineNo: Integer)
    begin
        DataExportRecordField.SetRange("Data Export Code", ExportCode);
        DataExportRecordField.SetRange("Data Exp. Rec. Type Code", RecordCode);
        DataExportRecordField.SetRange("Source Line No.", SourceLineNo);
    end;

    local procedure UpdateFieldProperties()
    var
        "Field": Record "Field";
        TypeHelper: Codeunit "Type Helper";
    begin
        if TypeHelper.GetField("Table No.", "Field No.", Field) then begin
            "Field Class" := Field.Class;
            case Field.Type of
                Field.Type::Date:
                    "Field Type" := "Field Type"::Date;
                Field.Type::Decimal:
                    "Field Type" := "Field Type"::Decimal;
                Field.Type::Text:
                    "Field Type" := "Field Type"::Text;
                Field.Type::Code:
                    "Field Type" := "Field Type"::Code;
                Field.Type::Boolean:
                    "Field Type" := "Field Type"::Boolean;
                Field.Type::Integer:
                    "Field Type" := "Field Type"::Integer;
                Field.Type::Option:
                    "Field Type" := "Field Type"::Option;
                Field.Type::DateTime:
                    "Field Type" := "Field Type"::DateTime;
            end;
        end else begin
            "Field Class" := 0;
            "Field Type" := 0;
        end;
    end;
}


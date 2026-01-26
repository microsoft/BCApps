// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using System.IO;
using System.Reflection;

table 11004 "Data Export Record Source"
{
    Caption = 'Data Export Record Source';
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
            TableRelation = AllObj."Object ID" where("Object Type" = const(Table));

            trigger OnValidate()
            var
                AllObjWithCaption: Record AllObjWithCaption;
            begin
                TestField("Table No.");
                if (xRec."Table No." <> 0) and (xRec."Table No." <> "Table No.") then
                    Error(CannotModifyErr, FieldCaption("Table No."));

                AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, "Table No.");
                Validate("Export Table Name", AllObjWithCaption."Object Name");
                FindDataFilterField();
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
        field(5; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;

            trigger OnValidate()
            var
                DataExportManagement: Codeunit "Data Export Management";
            begin
                if Indentation <> xRec.Indentation then
                    DataExportManagement.UpdateSourceIndentation(Rec, xRec.Indentation);
            end;
        }
        field(6; "Fields Selected"; Boolean)
        {
            CalcFormula = exist("Data Export Record Field" where("Data Export Code" = field("Data Export Code"),
                                                                  "Data Exp. Rec. Type Code" = field("Data Exp. Rec. Type Code"),
                                                                  "Table No." = field("Table No.")));
            Caption = 'Fields Selected';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Relation To Table No."; Integer)
        {
            BlankZero = true;
            Caption = 'Relation To Table No.';
            TableRelation = AllObj."Object ID" where("Object Type" = const(Table));
        }
        field(8; "Relation To Table Name"; Text[80])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Relation To Table No.")));
            Caption = 'Relation To Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Period Field No."; Integer)
        {
            BlankZero = true;
            Caption = 'Period Field No.';
            TableRelation = Field."No." where(TableNo = field("Table No."),
                                               Type = filter(Date),
                                               Class = const(Normal),
                                               ObsoleteState = filter(<> Removed));

            trigger OnLookup()
            var
                "Field": Record "Field";
            begin
                TestField("Table No.");
                Field.SetRange(TableNo, "Table No.");
                Field.SetRange(Type, Field.Type::Date);
                Field.SetRange(Class, Field.Class::Normal);
                Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
                if PAGE.RunModal(PAGE::"Data Export Field List", Field) = ACTION::LookupOK then
                    Validate("Period Field No.", Field."No.");
            end;

            trigger OnValidate()
            begin
                CheckPeriodFieldInTableFilter();
            end;
        }
        field(10; "Period Field Name"; Text[80])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table No."),
                                                              "No." = field("Period Field No.")));
            Caption = 'Period Field Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Table Relation Defined"; Boolean)
        {
            CalcFormula = exist("Data Export Table Relation" where("Data Export Code" = field("Data Export Code"),
                                                                    "Data Exp. Rec. Type Code" = field("Data Exp. Rec. Type Code"),
                                                                    "To Table No." = field("Table No."),
                                                                    "From Table No." = field("Relation To Table No.")));
            Caption = 'Table Relation Defined';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(13; "Export File Name"; Text[250])
        {
            Caption = 'Export File Name';

            trigger OnValidate()
            var
                FileMgt: Codeunit "File Management";
            begin
                TestField("Export File Name");
                if not FileMgt.IsValidFileName("Export File Name") then
                    Error(NotValidFileNameErr, "Export File Name");
                "Export File Name" := CopyStr(FindUniqueFileName(), 1, MaxStrLen("Export File Name"));
            end;
        }
        field(14; "Relation To Line No."; Integer)
        {
            Caption = 'Relation To Line No.';
        }
        field(30; "Table Filter"; TableFilter)
        {
            Caption = 'Table Filter';

            trigger OnValidate()
            begin
                CheckPeriodFieldInTableFilter();
            end;
        }
        field(31; "Key No."; Integer)
        {
            Caption = 'Key No.';

            trigger OnLookup()
            var
                "Key": Record "Key";
                DataExportTableKeys: Page "Data Export Table Keys";
            begin
                TestField("Table No.");
                Clear(DataExportTableKeys);
                if "Key No." <> 0 then begin
                    Key.Get("Table No.", "Key No.");
                    DataExportTableKeys.SetRecord(Key);
                end;
                Key.SetRange(TableNo, "Table No.");
                Key.SetRange(Enabled, true);
                DataExportTableKeys.SetTableView(Key);
                DataExportTableKeys.LookupMode := true;
                if DataExportTableKeys.RunModal() = ACTION::LookupOK then begin
                    DataExportTableKeys.GetRecord(Key);
                    Validate("Key No.", Key."No.");
                end;
            end;

            trigger OnValidate()
            var
                "Key": Record "Key";
            begin
                if "Key No." <> 0 then begin
                    TestField("Table No.");
                    Key.Get("Table No.", "Key No.");
                end;
                if ("Key No." <> 0) and (xRec."Key No." <> "Key No.") then
                    FindSeqNumberAmongActiveKeys();
            end;
        }
        field(32; "Date Filter Field No."; Integer)
        {
            Caption = 'Date Filter Field No.';
            TableRelation = Field."No." where(TableNo = field("Table No."),
                                               Type = const(Date),
                                               Class = const(FlowFilter),
                                               ObsoleteState = filter(<> Removed));
        }
        field(33; "Date Filter Handling"; Option)
        {
            Caption = 'Date Filter Handling';
            OptionCaption = ' ,Period,End Date Only,Start Date Only';
            OptionMembers = " ",Period,"End Date Only","Start Date Only";
        }
        field(41; "Active Key Seq. No."; Integer)
        {
            Caption = 'Active Key Seq. No.';
        }
        field(50; "Export Table Name"; Text[80])
        {
            Caption = 'Export Table Name';

            trigger OnValidate()
            var
                DataExportManagement: Codeunit "Data Export Management";
            begin
                "Export Table Name" := CopyStr(FindUniqueTableName(), 1, MaxStrLen("Export Table Name"));
                TestField("Export Table Name");
                Validate("Export File Name", DataExportManagement.FormatFileName("Export Table Name") + '.txt');
            end;
        }
    }

    keys
    {
        key(Key1; "Data Export Code", "Data Exp. Rec. Type Code", "Line No.")
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
        DataExportTableRelation: Record "Data Export Table Relation";
        DataExportRecordField: Record "Data Export Record Field";
    begin
        DataExportRecordField.Reset();
        DataExportRecordField.SetRange("Data Export Code", "Data Export Code");
        DataExportRecordField.SetRange("Data Exp. Rec. Type Code", "Data Exp. Rec. Type Code");
        DataExportRecordField.SetRange("Source Line No.", "Line No.");
        DataExportRecordField.DeleteAll();

        if "Relation To Line No." <> 0 then begin
            DataExportTableRelation.Reset();
            DataExportTableRelation.SetRange("Data Export Code", "Data Export Code");
            DataExportTableRelation.SetRange("Data Exp. Rec. Type Code", "Data Exp. Rec. Type Code");
            DataExportTableRelation.SetRange("To Table No.", "Table No.");
            if DataExportTableRelation.FindSet() then
                repeat
                    if not DoesExistDuplicateSourceLine() then
                        DataExportTableRelation.Delete();
                until DataExportTableRelation.Next() = 0;
        end;

        DataExportRecordSource.Reset();
        DataExportRecordSource.SetRange("Data Export Code", "Data Export Code");
        DataExportRecordSource.SetRange("Data Exp. Rec. Type Code", "Data Exp. Rec. Type Code");
        DataExportRecordSource.SetRange("Relation To Line No.", "Line No.");
        DataExportRecordSource.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        TestField("Table No.");
        TestField("Export Table Name");
        TestField("Export File Name");
    end;

    trigger OnModify()
    begin
        TestField("Table No.");
        TestField("Export Table Name");
        TestField("Export File Name");
    end;

    trigger OnRename()
    begin
        Error(CannotRenameErr, TableCaption);
    end;

    var
        CannotModifyErr: Label 'You cannot modify the %1 field.';
        CannotRenameErr: Label 'You cannot rename a %1.';
        NotValidFileNameErr: Label '%1 is not a valid file name.';
        CannotUsePeriodFieldErr: Label 'You cannot use the period field %1 in the table filter.';

    local procedure ApplyDataExportRecordSourceFilter(var DataExportRecordSource: Record "Data Export Record Source"; FieldId: Integer)
    begin
        DataExportRecordSource.Reset();
        DataExportRecordSource.SetRange("Data Export Code", "Data Export Code");
        DataExportRecordSource.SetRange("Data Exp. Rec. Type Code", "Data Exp. Rec. Type Code");
        DataExportRecordSource.SetFilter("Line No.", '<>%1', "Line No.");
        case FieldId of
            DataExportRecordSource.FieldNo("Export File Name"):
                DataExportRecordSource.SetRange("Export File Name", "Export File Name");
            DataExportRecordSource.FieldNo("Export Table Name"):
                DataExportRecordSource.SetRange("Export Table Name", "Export Table Name")
        end;
    end;

    local procedure FindUniqueTableName(): Text
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportManagement: Codeunit "Data Export Management";
        Postfix: Text;
        PostfixInt: Integer;
        LargestPostfix: Integer;
    begin
        "Export Table Name" := DataExportManagement.FormatForIndexXML("Export Table Name");
        ApplyDataExportRecordSourceFilter(DataExportRecordSource, FieldNo("Export Table Name"));
        if not DataExportRecordSource.FindSet() then
            exit("Export Table Name");
        DataExportRecordSource.SetFilter("Export Table Name", "Export Table Name" + '*');
        DataExportRecordSource.FindSet();
        LargestPostfix := 0;
        repeat
            Postfix := DelStr(DataExportRecordSource."Export Table Name", 1, StrLen("Export Table Name"));
            if Evaluate(PostfixInt, Postfix) and (PostfixInt > LargestPostfix) then
                LargestPostfix := PostfixInt;
        until DataExportRecordSource.Next() = 0;
        exit(StrSubstNo('%1 %2', "Export Table Name", LargestPostfix + 1));
    end;

    local procedure FindUniqueFileName(): Text
    var
        DataExportRecordSource: Record "Data Export Record Source";
        Postfix: Text;
        PostfixInt: Integer;
        LargestPostfix: Integer;
    begin
        ApplyDataExportRecordSourceFilter(DataExportRecordSource, FieldNo("Export File Name"));
        if not DataExportRecordSource.FindSet() then
            exit("Export File Name");
        "Export File Name" := DelStr("Export File Name", StrPos("Export File Name", '.'));
        DataExportRecordSource.SetFilter("Export File Name", "Export File Name" + '*');
        DataExportRecordSource.FindSet();
        LargestPostfix := 0;
        repeat
            Postfix := DelStr(DataExportRecordSource."Export File Name", 1, StrLen("Export File Name"));
            if StrPos(Postfix, '.') <> 0 then
                Postfix := DelStr(Postfix, StrPos(Postfix, '.'));
            if Evaluate(PostfixInt, Postfix) and (PostfixInt > LargestPostfix) then
                LargestPostfix := PostfixInt;
        until DataExportRecordSource.Next() = 0;
        exit(StrSubstNo('%1%2.txt', "Export File Name", LargestPostfix + 1));
    end;

    [Scope('OnPrem')]
    procedure FindSeqNumberAmongActiveKeys()
    var
        RecRef: RecordRef;
        KeyRef: KeyRef;
        KeyCounter: Integer;
        ActiveKeyCounter: Integer;
    begin
        if "Table No." <> 0 then begin
            RecRef.Open("Table No.");
            ActiveKeyCounter := 0;
            for KeyCounter := 1 to RecRef.KeyCount do begin
                KeyRef := RecRef.KeyIndex(KeyCounter);
                if KeyRef.Active then
                    ActiveKeyCounter += 1;
                if "Key No." = KeyCounter then
                    "Active Key Seq. No." := ActiveKeyCounter;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure IsPeriodFieldInTableFilter(): Boolean
    var
        TableFilterText: Text;
    begin
        if "Period Field No." = 0 then
            exit(false);

        Evaluate(TableFilterText, Format("Table Filter"));
        if TableFilterText = '' then
            exit(false);

        CalcFields("Period Field Name");
        exit(StrPos(TableFilterText, "Period Field Name" + '=') <> 0);
    end;

    local procedure CheckPeriodFieldInTableFilter()
    begin
        if IsPeriodFieldInTableFilter() then
            Error(CannotUsePeriodFieldErr, "Period Field Name");
    end;

    [Scope('OnPrem')]
    procedure FindDataFilterField()
    var
        "Field": Record "Field";
    begin
        Field.SetRange(TableNo, "Table No.");
        Field.SetRange(Type, Field.Type::Date);
        Field.SetRange(Class, Field.Class::FlowFilter);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        if Field.Count = 1 then begin
            Field.FindFirst();
            "Date Filter Field No." := Field."No.";
        end;
    end;

    local procedure DoesExistDuplicateSourceLine(): Boolean
    var
        DataExportRecordSource: Record "Data Export Record Source";
    begin
        DataExportRecordSource.Reset();
        DataExportRecordSource.SetRange("Data Export Code", "Data Export Code");
        DataExportRecordSource.SetRange("Data Exp. Rec. Type Code", "Data Exp. Rec. Type Code");
        DataExportRecordSource.SetFilter("Line No.", '<>%1', "Line No.");
        DataExportRecordSource.SetRange("Table No.", "Table No.");
        exit(not DataExportRecordSource.IsEmpty);
    end;
}


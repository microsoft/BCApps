namespace System.IO;

using Microsoft.Bank.PositivePay;
using System.Reflection;

table 1224 "Data Exch. Mapping"
{
    Caption = 'Data Exch. Mapping';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exch. Def Code"; Code[20])
        {
            Caption = 'Data Exch. Def Code';
            NotBlank = true;
            TableRelation = "Data Exch. Def";
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(3; Name; Text[250])
        {
            Caption = 'Name';
        }
        field(4; "Mapping Codeunit"; Integer)
        {
            Caption = 'Mapping Codeunit';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));
        }
        field(6; "Data Exch. No. Field ID"; Integer)
        {
            Caption = 'Data Exch. No. Field ID';
            Description = 'The ID of the field in the target table that contains the Data Exchange No..';
            TableRelation = Field."No." where(TableNo = field("Table ID"));
        }
        field(7; "Data Exch. Line Field ID"; Integer)
        {
            Caption = 'Data Exch. Line Field ID';
            Description = 'The ID of the field in the target table that contains the Data Exchange Line No..';
            TableRelation = Field."No." where(TableNo = field("Table ID"));
        }
        field(8; "Data Exch. Line Def Code"; Code[20])
        {
            Caption = 'Data Exch. Line Def Code';
            NotBlank = true;
            TableRelation = "Data Exch. Line Def".Code where("Data Exch. Def Code" = field("Data Exch. Def Code"));
        }
        field(9; "Pre-Mapping Codeunit"; Integer)
        {
            Caption = 'Pre-Mapping Codeunit';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));
        }
        field(10; "Post-Mapping Codeunit"; Integer)
        {
            Caption = 'Post-Mapping Codeunit';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));
        }
        field(20; "Use as Intermediate Table"; Boolean)
        {
            Caption = 'Use as Intermediate Table';
        }
        field(21; "Key Index"; Integer)
        {
            Caption = 'Key Index';
            TableRelation = Key."No." where(TableNo = field("Table ID"));
        }
        field(22; "Key"; Text[250])
        {
            Caption = 'Key';
            FieldClass = FlowField;
            CalcFormula = lookup(Key.Key where(TableNo = field("Table ID"), "No." = field("Key Index")));
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Data Exch. Def Code", "Data Exch. Line Def Code", "Table ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DataExchFieldGrouping: Record "Data Exch. Field Grouping";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, IsHandled);
        if IsHandled then
            exit;

        DataExchFieldMapping.SetRange("Data Exch. Def Code", "Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Table ID", "Table ID");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", "Data Exch. Line Def Code");
        DataExchFieldMapping.DeleteAll();

        DataExchFieldGrouping.SetRange("Data Exch. Def Code", "Data Exch. Def Code");
        DataExchFieldGrouping.SetRange("Table ID", "Table ID");
        DataExchFieldGrouping.SetRange("Data Exch. Line Def Code", "Data Exch. Line Def Code");
        DataExchFieldGrouping.DeleteAll();
    end;

    trigger OnRename()
    begin
        if HasFieldMappings() then
            Error(RenameErr);
    end;

    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
#pragma warning disable AA0470
        RecordNameFormatTok: Label '%1 to %2';
#pragma warning restore AA0470
        RenameErr: Label 'You cannot rename the record if one or more field mapping lines exist.';

    procedure InsertRec(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; TableId: Integer; NewName: Text[250]; MappingCodeunit: Integer; DataExchNoFieldId: Integer; DataExchLineFieldId: Integer)
    begin
        Init();
        Validate("Data Exch. Def Code", DataExchDefCode);
        Validate("Data Exch. Line Def Code", DataExchLineDefCode);
        Validate("Table ID", TableId);
        Validate(Name, NewName);
        Validate("Mapping Codeunit", MappingCodeunit);
        Validate("Data Exch. No. Field ID", DataExchNoFieldId);
        Validate("Data Exch. Line Field ID", DataExchLineFieldId);
        Insert();
    end;

    procedure InsertRecForExport(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; TableId: Integer; NewName: Text[250]; ProcessingCodeunit: Integer)
    begin
        Init();
        Validate("Data Exch. Def Code", DataExchDefCode);
        Validate("Data Exch. Line Def Code", DataExchLineDefCode);
        Validate("Table ID", TableId);
        Validate(Name, NewName);
        Validate("Mapping Codeunit", ProcessingCodeunit);
        Insert();
    end;

    procedure InsertRecForImport(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; TableId: Integer; NewName: Text[250]; DataExchNoFieldId: Integer; DataExchLineFieldId: Integer)
    begin
        Init();
        Validate("Data Exch. Def Code", DataExchDefCode);
        Validate("Data Exch. Line Def Code", DataExchLineDefCode);
        Validate("Table ID", TableId);
        Validate(Name, NewName);
        Validate("Data Exch. No. Field ID", DataExchNoFieldId);
        Validate("Data Exch. Line Field ID", DataExchLineFieldId);
        Insert();
    end;

    procedure CreateDataExchMapping(TableID: Integer; CodeunitID: Integer; DataExchNoFieldID: Integer; DataExchLineFieldID: Integer)
    begin
        InsertRec("Data Exch. Def Code", "Data Exch. Line Def Code", TableID,
          CreateName(TableID, "Data Exch. Def Code"), CodeunitID, DataExchNoFieldID, DataExchLineFieldID);
    end;

    local procedure CreateName(TableID: Integer; "Code": Code[20]): Text[250]
    var
        recRef: RecordRef;
    begin
        recRef.Open(TableID);
        exit(StrSubstNo(RecordNameFormatTok, Code, recRef.Caption));
    end;

    local procedure HasFieldMappings(): Boolean
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchFieldMapping.SetRange("Data Exch. Def Code", "Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", "Data Exch. Line Def Code");
        DataExchFieldMapping.SetRange("Table ID", xRec."Table ID");
        DataExchFieldMapping.SetFilter("Column No.", '<>%1', 0);
        exit(not DataExchFieldMapping.IsEmpty);
    end;

    procedure PositivePayUpdateCodeunits(): Boolean
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchDef.SetRange(Code, "Data Exch. Def Code");
        if DataExchDef.FindFirst() then
            if DataExchDef.Type = DataExchDef.Type::"Positive Pay Export" then begin
                DataExchLineDef.SetRange("Data Exch. Def Code", "Data Exch. Def Code");
                DataExchLineDef.SetRange(Code, "Data Exch. Line Def Code");
                if DataExchLineDef.FindFirst() then begin
                    case DataExchLineDef."Line Type" of
                        DataExchLineDef."Line Type"::Header:
                            begin
                                "Pre-Mapping Codeunit" := CODEUNIT::"Exp. Pre-Mapping Head Pos. Pay";
                                "Mapping Codeunit" := CODEUNIT::"Exp. Mapping Head Pos. Pay";
                            end;
                        DataExchLineDef."Line Type"::Detail:
                            begin
                                "Pre-Mapping Codeunit" := CODEUNIT::"Exp. Pre-Mapping Det Pos. Pay";
                                "Mapping Codeunit" := CODEUNIT::"Exp. Mapping Det Pos. Pay";
                            end;
                        DataExchLineDef."Line Type"::Footer:
                            begin
                                "Pre-Mapping Codeunit" := CODEUNIT::"Exp. Pre-Mapping Foot Pos. Pay";
                                "Mapping Codeunit" := CODEUNIT::"Exp. Mapping Foot Pos. Pay";
                            end;
                    end;
                    exit(true);
                end;
            end;

        if DataExchDef.Type <> DataExchDef.Type::"Positive Pay Export" then begin
            "Pre-Mapping Codeunit" := 0;
            "Mapping Codeunit" := 0;
        end;

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var DataExchMapping: Record "Data Exch. Mapping"; var IsHandled: Boolean)
    begin
    end;
}
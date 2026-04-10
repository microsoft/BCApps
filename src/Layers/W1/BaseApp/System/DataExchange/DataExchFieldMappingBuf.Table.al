namespace System.IO;

using System.Reflection;

table 1265 "Data Exch. Field Mapping Buf."
{
    Caption = 'Data Exch. Field Mapping Buf.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exchange Def Code"; Code[20])
        {
            Caption = 'Data Exchange Def Code';
            DataClassification = SystemMetadata;
        }
        field(2; "Data Exchange Line Def Code"; Code[20])
        {
            Caption = 'Data Exchange Line Def Code';
            DataClassification = SystemMetadata;
        }
        field(3; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;
        }
        field(4; "Column No."; Integer)
        {
            Caption = 'Column No.';
            DataClassification = SystemMetadata;
        }
        field(5; Type; Option)
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Field,Table';
            OptionMembers = "Field","Table";
        }
        field(10; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            DataClassification = SystemMetadata;
        }
        field(11; "Default Value"; Text[250])
        {
            Caption = 'Default Value';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                DataExchFieldMapping: Record "Data Exch. Field Mapping";
            begin
                TestField(Type, Type::Field);
                DataExchFieldMapping.Get("Data Exchange Def Code", "Data Exchange Line Def Code", "Table ID", "Column No.", "Field ID");
                DataExchFieldMapping.Validate("Default Value", "Default Value");
                DataExchFieldMapping.Modify(true);
            end;
        }
        field(13; Source; Text[250])
        {
            Caption = 'Source';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                DataExchColumnDef: Record "Data Exch. Column Def";
                DataExchLineDef: Record "Data Exch. Line Def";
            begin
                case Type of
                    Type::Field:
                        if not DataExchColumnDef.Get("Data Exchange Def Code", "Data Exchange Line Def Code", "Column No.") then
                            CreateDataExchColumnDef()
                        else begin
                            DataExchColumnDef.Validate(Path, Source);
                            DataExchColumnDef.Modify(true);
                        end;
                    Type::Table:
                        begin
                            DataExchLineDef.Get("Data Exchange Def Code", "Data Exchange Line Def Code");
                            DataExchLineDef.Validate("Data Line Tag", Source);
                            DataExchLineDef.Modify(true);
                        end;
                end;
            end;
        }
        field(20; Caption; Text[250])
        {
            Caption = 'Caption';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(22; Depth; Integer)
        {
            Caption = 'Depth';
            DataClassification = SystemMetadata;
        }
        field(23; "Transformation Rule"; Code[20])
        {
            Caption = 'Transformation Rule';
            DataClassification = SystemMetadata;
            TableRelation = "Transformation Rule";

            trigger OnValidate()
            var
                DataExchFieldMapping: Record "Data Exch. Field Mapping";
            begin
                TestField(Type, Type::Field);
                DataExchFieldMapping.Get("Data Exchange Def Code", "Data Exchange Line Def Code", "Table ID", "Column No.", "Field ID");
                DataExchFieldMapping.Validate("Transformation Rule", "Transformation Rule");
                DataExchFieldMapping.Modify(true);
            end;
        }
    }

    keys
    {
        key(Key1; "Data Exchange Def Code", "Data Exchange Line Def Code", "Field ID", "Table ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        TestField(Type, Type::Field);
        if DataExchFieldMapping.Get("Data Exchange Def Code", "Data Exchange Line Def Code", "Table ID", "Column No.", "Field ID") then
            DataExchFieldMapping.Delete(true);

        if DataExchColumnDef.Get("Data Exchange Def Code", "Data Exchange Line Def Code", "Column No.") then
            DataExchColumnDef.Delete(true);
    end;

    trigger OnInsert()
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        TestField(Type, Type::Field);
        if "Column No." = 0 then
            CreateDataExchColumnDef();

        if not DataExchFieldMapping.Get("Data Exchange Def Code", "Data Exchange Line Def Code", "Table ID", "Column No.", "Field ID") then
            CreateFieldMapping();
    end;

    trigger OnRename()
    begin
        // TODO: Test and implement
    end;

    procedure InsertFromDataExchDefinition(var TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary; DataExchDef: Record "Data Exch. Def"; var TempSuggestedField: Record "Field" temporary)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.SetRange("Parent Code", '');

        if DataExchLineDef.FindSet() then
            repeat
                InsertFromDataExchDefinitionLine(TempDataExchFieldMappingBuf, DataExchLineDef, TempSuggestedField, 0);
            until DataExchLineDef.Next() = 0;
    end;

    procedure InsertFromDataExchDefinitionLine(var TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary; DataExchLineDef: Record "Data Exch. Line Def"; var TempSuggestedField: Record "Field" temporary; NewDepth: Integer)
    var
        DataExchMapping: Record "Data Exch. Mapping";
        ChildDataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchMapping.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchMapping.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);

        if DataExchMapping.FindSet() then
            repeat
                InsertDataExchLineDefMappingLine(TempDataExchFieldMappingBuf, DataExchMapping, NewDepth);
                InsertFieldMappingDefinition(TempDataExchFieldMappingBuf, DataExchMapping, NewDepth + 1);
                InsertSuggestedFields(TempDataExchFieldMappingBuf, DataExchMapping, TempSuggestedField, NewDepth + 1);
            until DataExchMapping.Next() = 0;

        ChildDataExchLineDef.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        ChildDataExchLineDef.SetRange("Parent Code", DataExchLineDef.Code);

        if ChildDataExchLineDef.FindSet() then
            repeat
                InsertFromDataExchDefinitionLine(TempDataExchFieldMappingBuf, ChildDataExchLineDef, TempSuggestedField, NewDepth + 1);
            until ChildDataExchLineDef.Next() = 0;
    end;

    procedure InsertFieldMappingDefinition(var TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary; DataExchMapping: Record "Data Exch. Mapping"; Indentation: Integer)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
        DataExchFieldMapping.SetRange("Table ID", DataExchMapping."Table ID");

        if not DataExchFieldMapping.FindSet() then
            exit;

        repeat
            InsertFieldMappingLineDefinition(TempDataExchFieldMappingBuf, DataExchMapping, DataExchFieldMapping, Indentation);
        until DataExchFieldMapping.Next() = 0;
    end;

    procedure InsertSuggestedFields(var TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary; DataExchMapping: Record "Data Exch. Mapping"; var TempSuggestedField: Record "Field" temporary; Indentation: Integer)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        TempSuggestedField.SetRange(TableNo, DataExchMapping."Table ID");

        if not TempSuggestedField.FindSet() then
            exit;

        repeat
            DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
            DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
            DataExchFieldMapping.SetRange("Table ID", DataExchMapping."Table ID");
            DataExchFieldMapping.SetRange("Field ID", TempSuggestedField."No.");
            if not DataExchFieldMapping.FindFirst() then begin
                InitializeDataExchangeSetupLine(
                  TempDataExchFieldMappingBuf, DataExchMapping, TempSuggestedField."No.", Indentation, TempSuggestedField."Field Caption");
                TempDataExchFieldMappingBuf.Insert(true);
            end;
        until TempSuggestedField.Next() = 0;
    end;

    procedure InsertFieldMappingLineDefinition(var TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary; DataExchMapping: Record "Data Exch. Mapping"; DataExchFieldMapping: Record "Data Exch. Field Mapping"; Indentation: Integer)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        InitializeDataExchangeSetupLine(
          TempDataExchFieldMappingBuf, DataExchMapping, DataExchFieldMapping."Field ID", Indentation, DataExchFieldMapping.GetFieldCaption());
        TempDataExchFieldMappingBuf."Column No." := DataExchFieldMapping."Column No.";
        TempDataExchFieldMappingBuf."Default Value" := DataExchFieldMapping."Default Value";
        TempDataExchFieldMappingBuf."Transformation Rule" := DataExchFieldMapping."Transformation Rule";
        DataExchColumnDef.Get(
          DataExchFieldMapping."Data Exch. Def Code", DataExchFieldMapping."Data Exch. Line Def Code",
          DataExchFieldMapping."Column No.");
        TempDataExchFieldMappingBuf.Source := DataExchColumnDef.Path;
        TempDataExchFieldMappingBuf.Insert(true);
    end;

    local procedure InsertDataExchLineDefMappingLine(var TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary; DataExchMapping: Record "Data Exch. Mapping"; Indentation: Integer)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchDef.Get(DataExchMapping."Data Exch. Def Code");
        DataExchLineDef.Get(DataExchMapping."Data Exch. Def Code", DataExchMapping."Data Exch. Line Def Code");
        Clear(TempDataExchFieldMappingBuf);
        TempDataExchFieldMappingBuf.Init();
        TempDataExchFieldMappingBuf."Data Exchange Def Code" := DataExchMapping."Data Exch. Def Code";
        TempDataExchFieldMappingBuf."Data Exchange Line Def Code" := DataExchMapping."Data Exch. Line Def Code";
        TempDataExchFieldMappingBuf.Type := TempDataExchFieldMappingBuf.Type::Table;
        TempDataExchFieldMappingBuf."Table ID" := DataExchMapping."Table ID";
        TempDataExchFieldMappingBuf.Caption := DataExchLineDef.Name;
        TempDataExchFieldMappingBuf.Depth := Indentation;
        TempDataExchFieldMappingBuf.Source := DataExchLineDef."Data Line Tag";
        TempDataExchFieldMappingBuf.Insert();
    end;

    local procedure InitializeDataExchangeSetupLine(var TempDataExchFieldMappingBuf: Record "Data Exch. Field Mapping Buf." temporary; DataExchMapping: Record "Data Exch. Mapping"; FieldID: Integer; Indentation: Integer; NewCaption: Text)
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        DataExchDef.Get(DataExchMapping."Data Exch. Def Code");

        Clear(TempDataExchFieldMappingBuf);
        TempDataExchFieldMappingBuf.Init();
        TempDataExchFieldMappingBuf."Data Exchange Def Code" := DataExchMapping."Data Exch. Def Code";
        TempDataExchFieldMappingBuf."Data Exchange Line Def Code" := DataExchMapping."Data Exch. Line Def Code";
        TempDataExchFieldMappingBuf.Type := TempDataExchFieldMappingBuf.Type::Field;
        TempDataExchFieldMappingBuf."Table ID" := DataExchMapping."Table ID";
        TempDataExchFieldMappingBuf."Field ID" := FieldID;
        TempDataExchFieldMappingBuf.Caption := CopyStr(NewCaption, 1, MaxStrLen(TempDataExchFieldMappingBuf.Caption));
        TempDataExchFieldMappingBuf.Depth := Indentation;
    end;

    procedure SourceAssistEdit(var XMLBuffer: Record "XML Buffer")
    begin
        if PAGE.RunModal(PAGE::"Select Source", XMLBuffer) = ACTION::LookupOK then
            Validate(Source, XMLBuffer.Path);
    end;

    procedure CaptionAssistEdit()
    var
        "Field": Record "Field";
        FieldSelection: Codeunit "Field Selection";
    begin
        Field.SetRange(TableNo, "Table ID");
        if FieldSelection.Open(Field) then begin
            Validate("Field ID", Field."No.");
            Validate(Caption, Field."Field Caption");
        end;
    end;

    local procedure GetLastColumnNo(): Integer
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", "Data Exchange Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", "Data Exchange Line Def Code");
        if DataExchColumnDef.FindLast() then
            exit(DataExchColumnDef."Column No.");

        exit(GetIncrement());
    end;

    local procedure GetIncrement(): Integer
    begin
        exit(10000);
    end;

    local procedure CreateDataExchColumnDef()
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        if "Data Exchange Def Code" <> '' then begin
            "Column No." := GetLastColumnNo() + GetIncrement();
            DataExchColumnDef.Init();
            DataExchColumnDef."Data Exch. Def Code" := "Data Exchange Def Code";
            DataExchColumnDef."Data Exch. Line Def Code" := "Data Exchange Line Def Code";
            DataExchColumnDef."Column No." := "Column No.";
            DataExchColumnDef.Path := Source;
            DataExchColumnDef.Insert(true);
        end;
    end;

    local procedure CreateFieldMapping()
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        if "Data Exchange Def Code" <> '' then begin
            DataExchFieldMapping.Init();
            DataExchFieldMapping.Validate("Data Exch. Def Code", "Data Exchange Def Code");
            DataExchFieldMapping.Validate("Data Exch. Line Def Code", "Data Exchange Line Def Code");
            DataExchFieldMapping.Validate("Table ID", "Table ID");
            DataExchFieldMapping.Validate("Column No.", "Column No.");
            DataExchFieldMapping.Validate("Field ID", "Field ID");
            DataExchFieldMapping.Validate("Default Value", "Default Value");
            DataExchFieldMapping.Validate("Transformation Rule", "Transformation Rule");
            DataExchFieldMapping.Insert(true);
        end;
    end;
}


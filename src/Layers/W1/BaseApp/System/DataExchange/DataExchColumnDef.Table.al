namespace System.IO;

table 1223 "Data Exch. Column Def"
{
    Caption = 'Data Exch. Column Def';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exch. Def Code"; Code[20])
        {
            Caption = 'Data Exch. Def Code';
            NotBlank = true;
            TableRelation = "Data Exch. Def";
        }
        field(2; "Column No."; Integer)
        {
            Caption = 'Column No.';
            MinValue = 1;
            NotBlank = true;
        }
        field(3; Name; Text[250])
        {
            Caption = 'Name';
        }
        field(4; Show; Boolean)
        {
            Caption = 'Show';
        }
        field(5; "Data Type"; Option)
        {
            Caption = 'Data Type';
            OptionCaption = 'Text,Date,Decimal,DateTime,Boolean';
            OptionMembers = Text,Date,Decimal,DateTime,Boolean;
        }
        field(6; "Data Format"; Text[100])
        {
            Caption = 'Data Format';
        }
        field(7; "Data Formatting Culture"; Text[10])
        {
            Caption = 'Data Formatting Culture';
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; "Data Exch. Line Def Code"; Code[20])
        {
            Caption = 'Data Exch. Line Def Code';
            NotBlank = true;
            TableRelation = "Data Exch. Line Def".Code where("Data Exch. Def Code" = field("Data Exch. Def Code"));
        }
        field(11; Length; Integer)
        {
            Caption = 'Length';
        }
        field(12; Constant; Text[30])
        {
            Caption = 'Constant';
        }
        field(13; Path; Text[250])
        {
            Caption = 'Path';
        }
        field(14; "Negative-Sign Identifier"; Text[30])
        {
            Caption = 'Negative-Sign Identifier';
        }
        field(15; "Text Padding Required"; Boolean)
        {
            Caption = 'Text Padding Required';
        }
        field(16; "Pad Character"; Text[1])
        {
            Caption = 'Pad Character';
        }
        field(17; Justification; Option)
        {
            Caption = 'Justification';
            OptionCaption = 'Right,Left';
            OptionMembers = Right,Left;
        }
        field(18; "Use Node Name as Value"; Boolean)
        {
            Caption = 'Use Node Name as Value';
        }
        field(19; "Blank Zero"; Boolean)
        {
            Caption = 'Blank Zero';
        }
        field(20; "Export If Not Blank"; Boolean)
        {
            Caption = 'Export If Not Blank';
        }
    }

    keys
    {
        key(Key1; "Data Exch. Def Code", "Data Exch. Line Def Code", "Column No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        DataExchFieldMapping.SetRange("Data Exch. Def Code", "Data Exch. Def Code");
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", "Data Exch. Line Def Code");
        DataExchFieldMapping.SetRange("Column No.", "Column No.");
        if not DataExchFieldMapping.IsEmpty() and GuiAllowed then
            if not Confirm(StrSubstNo(DeleteFieldMappingQst, DataExchColumnDef.TableCaption(), DataExchFieldMapping.TableCaption())) then
                Error('');
        DataExchFieldMapping.DeleteAll();
    end;

    trigger OnInsert()
    begin
        ValidateRec();
    end;

    trigger OnModify()
    begin
        ValidateRec();
    end;

    var
#pragma warning disable AA0470
        DeleteFieldMappingQst: Label 'The %1 that you are about to delete is used for one or more %2, which will also be deleted. \\Do you want to continue?';
#pragma warning restore AA0470

    procedure InsertRec(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; ColumnNo: Integer; NewName: Text[250]; NewShow: Boolean; DataType: Option; DataTypeFormatting: Text[100]; DataFormattingCulture: Text[10]; NewDescription: Text[50])
    begin
        Init();
        Validate("Data Exch. Def Code", DataExchDefCode);
        Validate("Data Exch. Line Def Code", DataExchLineDefCode);
        Validate("Column No.", ColumnNo);
        Validate(Name, NewName);
        Validate(Show, NewShow);
        Validate("Data Type", DataType);
        Validate("Data Format", DataTypeFormatting);
        Validate("Data Formatting Culture", DataFormattingCulture);
        Validate(Description, NewDescription);
        Insert();
    end;

    procedure InsertRecForExport(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; ColumnNo: Integer; NewName: Text[250]; DataType: Option; DataFormat: Text[100]; NewLength: Integer; NewConstant: Text[30])
    begin
        Init();
        Validate("Data Exch. Def Code", DataExchDefCode);
        Validate("Data Exch. Line Def Code", DataExchLineDefCode);
        Validate("Column No.", ColumnNo);
        Validate(Name, NewName);
        Validate("Data Type", DataType);
        Validate("Data Format", DataFormat);
        Validate(Length, NewLength);
        Validate(Constant, NewConstant);
        Insert();
    end;

    procedure InsertRecordForImport(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; ColumnNo: Integer; NewName: Text[250]; NewDescription: Text[100]; NewShow: Boolean; DataType: Option; DataFormat: Text[100]; DataFormattingCulture: Text[10])
    begin
        Init();
        Validate("Data Exch. Def Code", DataExchDefCode);
        Validate("Data Exch. Line Def Code", DataExchLineDefCode);
        Validate("Column No.", ColumnNo);
        Validate(Name, NewName);
        Validate(Description, NewDescription);
        Validate(Show, NewShow);
        Validate("Data Type", DataType);
        Validate("Data Format", DataFormat);
        Validate("Data Formatting Culture", DataFormattingCulture);
        Insert();
    end;

    procedure ValidateRec()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        TestField("Data Exch. Def Code");
        TestField("Column No.");

        DataExchDef.Get("Data Exch. Def Code");

        if DataExchDef."File Type" = DataExchDef."File Type"::"Fixed Text" then
            TestField(Length);

        if IsDataFormatRequired() then
            TestField("Data Format");

        if IsDataFormattingCultureRequired() then
            TestField("Data Formatting Culture");
    end;

    procedure IsDataFormatRequired(): Boolean
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        if IsXML() or IsJson() then
            exit(false);

        DataExchDef.Get("Data Exch. Def Code");

        case "Data Type" of
            "Data Type"::Date:
                exit(DataExchDef.Type <> DataExchDef.Type::"Payment Export");
            "Data Type"::Text:
                ;
            else
                exit(DataExchDef.Type = DataExchDef.Type::"Payment Export");
        end;
    end;

    procedure IsDataFormattingCultureRequired(): Boolean
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        if ("Data Type" <> "Data Type"::Text) and not IsXML() and not IsJson() then begin
            DataExchDef.Get("Data Exch. Def Code");
            exit(DataExchDef.Type <> DataExchDef.Type::"Payment Export");
        end;
    end;

    local procedure IsXML(): Boolean
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        DataExchDef.Get("Data Exch. Def Code");
        exit(DataExchDef."File Type" = DataExchDef."File Type"::Xml);
    end;

    local procedure IsJson(): Boolean
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        DataExchDef.Get("Data Exch. Def Code");
        exit(DataExchDef."File Type" = DataExchDef."File Type"::Json);
    end;

    procedure SetXMLDataFormattingValues(SimpleDataType: Text)
    var
        DataExchColDef: Record "Data Exch. Column Def";
    begin
        case DelChr(LowerCase(SimpleDataType)) of
            'decimal':
                "Data Type" := DataExchColDef."Data Type"::Decimal;
            'date', 'datetime':
                "Data Type" := DataExchColDef."Data Type"::Date;
            else
                "Data Type" := DataExchColDef."Data Type"::Text;
        end;
        Modify();
    end;

    procedure IsOfDataLine(): Boolean
    var
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchLineDef.Get("Data Exch. Def Code", "Data Exch. Line Def Code");

        if not (IsXML() or IsJson()) or (DataExchLineDef."Data Line Tag" = '') then
            exit(true);

        exit(StrPos(Path, DataExchLineDef."Data Line Tag") > 0);
    end;
}


namespace System.IO;

using Microsoft.Bank.PositivePay;
using System.Reflection;

table 1222 "Data Exch. Def"
{
    Caption = 'Data Exch. Def';
    DrillDownPageId = "Data Exch Def List";
    LookupPageId = "Data Exch Def List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; Type; Enum "Data Exchange Definition Type")
        {
            Caption = 'Type';
        }
        field(4; "Reading/Writing XMLport"; Integer)
        {
            Caption = 'Reading/Writing XMLport';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(XMLport));
        }
        field(5; "Header Lines"; Integer)
        {
            Caption = 'Header Lines';
        }
        field(8; "Header Tag"; Text[250])
        {
            Caption = 'Header Tag';
        }
        field(9; "Footer Tag"; Text[250])
        {
            Caption = 'Footer Tag';
        }
        field(10; "Column Separator"; Option)
        {
            Caption = 'Column Separator';
            InitValue = Comma;
            OptionCaption = ',Tab,Semicolon,Comma,Space,Custom';
            OptionMembers = ,Tab,Semicolon,Comma,Space,Custom;
        }
        field(11; "File Encoding"; Option)
        {
            Caption = 'File Encoding';
            InitValue = WINDOWS;
            OptionCaption = 'MS-DOS,UTF-8,UTF-16,WINDOWS';
            OptionMembers = "MS-DOS","UTF-8","UTF-16",WINDOWS;
        }
        field(13; "File Type"; Option)
        {
            Caption = 'File Type';
            OptionCaption = 'Xml,Variable Text,Fixed Text,Json';
            OptionMembers = Xml,"Variable Text","Fixed Text",Json;
        }
        field(14; "Ext. Data Handling Codeunit"; Integer)
        {
            Caption = 'Ext. Data Handling Codeunit';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));
        }
        field(15; "Reading/Writing Codeunit"; Integer)
        {
            Caption = 'Reading/Writing Codeunit';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));
        }
        field(16; "Validation Codeunit"; Integer)
        {
            Caption = 'Validation Codeunit';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));
        }
        field(17; "Data Handling Codeunit"; Integer)
        {
            Caption = 'Data Handling Codeunit';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));
        }
        field(18; "User Feedback Codeunit"; Integer)
        {
            Caption = 'User Feedback Codeunit';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));
        }
        field(19; "Custom Column Separator"; Text[10])
        {
            Caption = 'Custom Column Separator';
        }
        field(20; "Line Separator"; Option)
        {
            Caption = 'Line Separator';
            OptionMembers = "CRLF","CR","LF";
            OptionCaption = 'CRLF,CR,LF';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; Type)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", Code);
        DataExchLineDef.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        if Name = '' then
            Name := Code;
    end;

    var
        ColumnSeparatorMissingErr: Label 'Column separator is missing in the definition.';

    procedure InsertRec(NewCode: Code[20]; NewName: Text[100]; NewType: Enum "Data Exchange Definition Type"; ProcessingXMLport: Integer; HeaderCount: Integer; HeaderTag: Text[250]; FooterTag: Text[250])
    begin
        Init();
        Validate(Code, NewCode);
        Validate(Name, NewName);
        Validate(Type, NewType);
        Validate("Reading/Writing XMLport", ProcessingXMLport);
        Validate("Header Lines", HeaderCount);
        Validate("Header Tag", HeaderTag);
        Validate("Footer Tag", FooterTag);
        Insert();
    end;

    procedure InsertRecForExport(NewCode: Code[20]; NewName: Text[100]; NewType: Option; ProcessingXMLport: Integer; FileType: Option)
    begin
        Init();
        Validate(Code, NewCode);
        Validate(Name, NewName);
        "File Type" := FileType;
        Type := "Data Exchange Definition Type".FromInteger(NewType);
        Validate("File Type", FileType);
        Validate(Type, NewType);

        Validate("Reading/Writing XMLport", ProcessingXMLport);
        Insert();
    end;

    procedure ColumnSeparatorChar(): Text
    var
        SeparatorChar: Text;
    begin
        case "Column Separator" of
            "Column Separator"::Tab:
                begin
                    SeparatorChar[1] := 9;
                    exit(SeparatorChar);
                end;
            "Column Separator"::Semicolon:
                exit(';');
            "Column Separator"::Comma:
                exit(',');
            "Column Separator"::Space:
                exit(' ');
            "Column Separator"::Custom:
                begin
                    if "Custom Column Separator" <> '' then
                        exit("Custom Column Separator");
                    Error(ColumnSeparatorMissingErr);
                end;
            else
                Error(ColumnSeparatorMissingErr)
        end
    end;

    procedure CheckEnableDisableIsNonXMLFileType(): Boolean
    begin
        exit(not ("File Type" in ["File Type"::Xml, "File Type"::Json]))
    end;

    procedure CheckEnableDisableIsImportType(): Boolean
    begin
        if Type in [Type::"Payment Export", Type::"Positive Pay Export"] then
            exit(false);
        exit(not ("File Type" in ["File Type"::Xml, "File Type"::Json]))
    end;

    procedure CheckEnableDisableIsBankStatementImportType(): Boolean
    begin
        exit(Type = Type::"Bank Statement Import");
    end;

    procedure CheckEnableDisableDelimitedFileType(): Boolean
    begin
        exit("File Type" = "File Type"::"Variable Text");
    end;

    procedure PositivePayUpdateCodeunits(): Boolean
    begin
        if Type = Type::"Positive Pay Export" then begin
            "Validation Codeunit" := CODEUNIT::"Exp. Validation Pos. Pay";
            "Reading/Writing Codeunit" := CODEUNIT::"Exp. Writing Pos. Pay";
            "Reading/Writing XMLport" := XMLPORT::"Export Generic Fixed Width";
            "Ext. Data Handling Codeunit" := CODEUNIT::"Exp. External Data Pos. Pay";
            "User Feedback Codeunit" := CODEUNIT::"Exp. User Feedback Pos. Pay";
        end else begin
            "Validation Codeunit" := 0;
            "Reading/Writing Codeunit" := 0;
            "Reading/Writing XMLport" := 0;
            "Ext. Data Handling Codeunit" := 0;
            "User Feedback Codeunit" := 0;
        end;
        exit(Type = Type::"Positive Pay Export");
    end;

    procedure ProcessDataExchange(var DataExch: Record "Data Exch.")
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        if "Data Handling Codeunit" <> 0 then
            CODEUNIT.Run("Data Handling Codeunit", DataExch);

        DataExchLineDef.SetRange("Data Exch. Def Code", Code);
        DataExchLineDef.SetRange("Parent Code", '');
        DataExchLineDef.FindSet();

        repeat
            DataExchMapping.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
            DataExchMapping.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
            DataExchMapping.FindSet();

            repeat
                if DataExchMapping."Pre-Mapping Codeunit" <> 0 then
                    CODEUNIT.Run(DataExchMapping."Pre-Mapping Codeunit", DataExch);

                if DataExchMapping."Mapping Codeunit" <> 0 then
                    CODEUNIT.Run(DataExchMapping."Mapping Codeunit", DataExch);

                if DataExchMapping."Post-Mapping Codeunit" <> 0 then
                    CODEUNIT.Run(DataExchMapping."Post-Mapping Codeunit", DataExch);
            until DataExchMapping.Next() = 0;
        until DataExchLineDef.Next() = 0;
    end;
}


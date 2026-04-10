namespace System.IO;

using Microsoft.EServices.EDocument;
using System.Utilities;

table 1220 "Data Exch."
{
    Caption = 'Data Exch.';
    Permissions = TableData "Data Exch." = ri,
                  TableData "Data Exch. Field" = rimd;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; "File Name"; Text[250])
        {
            Caption = 'File Name';
        }
        field(3; "File Content"; BLOB)
        {
            Caption = 'File Content';
        }
        field(4; "Data Exch. Def Code"; Code[20])
        {
            Caption = 'Data Exch. Def Code';
            TableRelation = "Data Exch. Def";
        }
        field(5; "Data Exch. Line Def Code"; Code[20])
        {
            Caption = 'Data Exch. Line Def Code';
            TableRelation = "Data Exch. Line Def".Code where("Data Exch. Def Code" = field("Data Exch. Def Code"));
        }
        field(6; "Table Filters"; BLOB)
        {
            Caption = 'Table Filters';
        }
        field(10; "Incoming Entry No."; Integer)
        {
            Caption = 'Incoming Entry No.';
            TableRelation = "Incoming Document";
        }
        field(11; "Related Record"; RecordID)
        {
            Caption = 'Related Record';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Data Exch. Def Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DataExchField: Record "Data Exch. Field";
    begin
        DataExchField.SetRange("Data Exch. No.", "Entry No.");
        DataExchField.DeleteAll();
    end;

    var
        ProgressWindowMsg: Label 'Please wait while the operation is being completed.';
        TxtExtTok: Label '.txt', Locked = true;
        XmlExtTok: Label '.xml', Locked = true;
        JsonExtTok: Label '.json', Locked = true;

    procedure InsertRec(FileName: Text[250]; var FileContent: InStream; DataExchDefCode: Code[20])
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        OutStream: OutStream;
    begin
        Init();
        Validate("File Name", FileName);
        "File Content".CreateOutStream(OutStream);
        CopyStream(OutStream, FileContent);
        Validate("Data Exch. Def Code", DataExchDefCode);
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        if DataExchLineDef.FindFirst() then
            Validate("Data Exch. Line Def Code", DataExchLineDef.Code);
        Insert();
    end;

    procedure ImportFileContent(DataExchDef: Record "Data Exch. Def"): Boolean
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        RelatedRecord: RecordID;
    begin
        RelatedRecord := "Related Record";
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        if DataExchLineDef.FindFirst() then;

        Init();
        "Data Exch. Def Code" := DataExchDef.Code;
        "Data Exch. Line Def Code" := DataExchLineDef.Code;
        "Related Record" := RelatedRecord;

        DataExchDef.TestField("Ext. Data Handling Codeunit");
        CODEUNIT.Run(DataExchDef."Ext. Data Handling Codeunit", Rec);

        if not "File Content".HasValue() then
            exit(false);

        Insert();
        exit(true);
    end;

    procedure ImportToDataExch(DataExchDef: Record "Data Exch. Def"): Boolean
    var
        Source: InStream;
        ProgressWindow: Dialog;
    begin
        if not "File Content".HasValue() then
            if not ImportFileContent(DataExchDef) then
                exit(false);

        ProgressWindow.Open(ProgressWindowMsg);

        "File Content".CreateInStream(Source);
        SetRange("Entry No.", "Entry No.");
        if DataExchDef."Reading/Writing Codeunit" > 0 then
            CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", Rec)
        else begin
            DataExchDef.TestField("Reading/Writing XMLport");
            XMLPORT.Import(DataExchDef."Reading/Writing XMLport", Source, Rec);
        end;

        ProgressWindow.Close();

        exit(true);
    end;

    procedure ExportFromDataExch(DataExchMapping: Record "Data Exch. Mapping")
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        DataExchMapping.TestField("Mapping Codeunit");

        DataExchDef.Get("Data Exch. Def Code");
        DataExchDef.TestField("Reading/Writing Codeunit");
        DataExchDef.TestField("Ext. Data Handling Codeunit");

        if DataExchMapping."Pre-Mapping Codeunit" > 0 then
            CODEUNIT.Run(DataExchMapping."Pre-Mapping Codeunit", Rec);

        CODEUNIT.Run(DataExchMapping."Mapping Codeunit", Rec);

        if DataExchMapping."Post-Mapping Codeunit" > 0 then
            CODEUNIT.Run(DataExchMapping."Post-Mapping Codeunit", Rec);

        CODEUNIT.Run(DataExchDef."Reading/Writing Codeunit", Rec);

        CODEUNIT.Run(DataExchDef."Ext. Data Handling Codeunit", Rec);

        if DataExchDef."User Feedback Codeunit" > 0 then
            CODEUNIT.Run(DataExchDef."User Feedback Codeunit", Rec);
    end;

    procedure GetFileExtension(): Text
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        DataExchDef.Get("Data Exch. Def Code");
        case DataExchDef."File Type" of
            DataExchDef."File Type"::Xml:
                exit(XmlExtTok);
            DataExchDef."File Type"::Json:
                exit(JsonExtTok);
            else
                exit(TxtExtTok);
        end;
    end;

    procedure SetFileContentFromBlob(TempBlob: Codeunit "Temp Blob")
    var
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, FieldNo("File Content"));
        RecordRef.SetTable(Rec);
    end;
}


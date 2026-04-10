namespace System.IO;

codeunit 1241 "Fixed File Import"
{
    Permissions = TableData "Data Exch. Field" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        ReadStream: InStream;
        ReadText: Text;
        ReadLen: Integer;
        LineNo: Integer;
        SkippedLineNo: Integer;
    begin
        DataExchDef.Get(Rec."Data Exch. Def Code");
        case DataExchDef."File Encoding" of
            DataExchDef."File Encoding"::"MS-DOS":
                Rec."File Content".CreateInStream(ReadStream, TextEncoding::MSDos);
            DataExchDef."File Encoding"::"UTF-8":
                Rec."File Content".CreateInStream(ReadStream, TextEncoding::UTF8);
            DataExchDef."File Encoding"::"UTF-16":
                Rec."File Content".CreateInStream(ReadStream, TextEncoding::UTF16);
            DataExchDef."File Encoding"::WINDOWS:
                Rec."File Content".CreateInStream(ReadStream, TextEncoding::Windows);
        end;
        LineNo := 1;
        repeat
            ReadLen := ReadStream.ReadText(ReadText);
            if ReadLen > 0 then
                ParseLine(ReadText, Rec, LineNo, SkippedLineNo);
        until ReadLen = 0;
    end;

    var
        DataExchDef: Record "Data Exch. Def";

    local procedure ParseLine(Line: Text; DataExch: Record "Data Exch."; var LineNo: Integer; var SkippedLineNo: Integer)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchField: Record "Data Exch. Field";
        StartPosition: Integer;
        IsHandled: Boolean;
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchLineDef.FindFirst();

        if ((LineNo + SkippedLineNo) <= DataExchDef."Header Lines") or
           ((DataExchLineDef."Data Line Tag" <> '') and (StrPos(Line, DataExchLineDef."Data Line Tag") <> 1))
        then begin
            SkippedLineNo += 1;
            exit;
        end;

        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchColumnDef.FindSet();

        StartPosition := 1;
        IsHandled := false;
        OnParseLineOnBeforeDataExchColumnDefLoop(DataExch, DataExchDef, DataExchColumnDef, DataExchField, Line, LineNo, StartPosition, IsHandled);
        if not IsHandled then
            repeat
                DataExchField.InsertRecXMLField(DataExch."Entry No.", LineNo, DataExchColumnDef."Column No.", '',
                  CopyStr(Line, StartPosition, DataExchColumnDef.Length), DataExchLineDef.Code);
                StartPosition += DataExchColumnDef.Length;
            until DataExchColumnDef.Next() = 0;
        LineNo += 1;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnParseLineOnBeforeDataExchColumnDefLoop(DataExch: Record "Data Exch."; var DataExchDef: Record "Data Exch. Def"; var DataExchColumnDef: Record "Data Exch. Column Def"; var DataExchField: Record "Data Exch. Field"; var Line: Text; LineNo: Integer; var StartPosition: Integer; var IsHandled: Boolean);
    begin
    end;
}


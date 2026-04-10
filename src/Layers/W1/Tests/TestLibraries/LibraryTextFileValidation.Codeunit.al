codeunit 131003 "Library - Text File Validation"
{
    // // Contains functions for text file validation.


    trigger OnRun()
    begin
    end;

    var
        NoSuchFieldPositionErr: Label 'There is no field position %1 in the line.';

    procedure NewFindLineWithValue(FileName: Text; StartingPosition: Integer; FieldLength: Integer; Value: Text): Text
    var
        NewFileName: Text;
        NewValue: Text;
    begin
        NewFileName := CopyStr(FileName, 1);
        NewValue := CopyStr(Value, 1);

        exit(FindLineWithValue(NewFileName, StartingPosition, FieldLength, NewValue));
    end;

    procedure FindLineWithValue(FileName: Text; StartingPosition: Integer; FieldLength: Integer; Value: Text) Line: Text
    var
        File: File;
        InStr: InStream;
        FieldValue: Text;
    begin
        File.TextMode(true);
        File.Open(FileName);
        File.Read(Line);
        File.CreateInStream(InStr);
        while (not InStr.EOS) and (FieldValue <> Value) do begin
            InStr.ReadText(Line);
            FieldValue := CopyStr(Line, StartingPosition, FieldLength);
        end;
        if FieldValue <> Value then
            Line := '';  // If value is not found in the file, this will return an empty line.
    end;

    procedure FindLineWithValue(FileInStream: InStream; StartingPosition: Integer; FieldLength: Integer; Value: Text) Line: Text
    var
        FieldValue: Text;
    begin
        while (not FileInStream.EOS) and (FieldValue <> Value) do begin
            FileInStream.ReadText(Line);
            FieldValue := CopyStr(Line, StartingPosition, FieldLength);
        end;
        if FieldValue <> Value then
            Line := '';  // If value is not found in the file, this will return an empty line.
    end;

    procedure FindLineContainingValue(FileName: Text; StartingPosition: Integer; FieldLength: Integer; Value: Text) Line: Text
    var
        File: File;
        InStr: InStream;
        FieldValue: Text;
    begin
        File.TextMode(true);
        File.Open(FileName);
        File.Read(Line);
        File.CreateInStream(InStr);
        while (not InStr.EOS) and (StrPos(FieldValue, Value) = 0) do begin
            InStr.ReadText(Line);
            FieldValue := CopyStr(Line, StartingPosition, FieldLength);
        end;
        if StrPos(FieldValue, Value) = 0 then
            Line := '';  // If value is not found in the file, this will return an empty line.
    end;

    procedure FindLineContainingValue(FileInStream: InStream; StartingPosition: Integer; FieldLength: Integer; Value: Text) Line: Text
    var
        FieldValue: Text;
    begin
        while (not FileInStream.EOS) and (StrPos(FieldValue, Value) = 0) do begin
            FileInStream.ReadText(Line);
            FieldValue := CopyStr(Line, StartingPosition, FieldLength);
        end;
        if StrPos(FieldValue, Value) = 0 then
            Line := '';  // If value is not found in the file, this will return an empty line.
    end;

    procedure DoesFileContainValue(FileName: Text; Value: Text): Boolean
    var
        StreamReader: DotNet StreamReader;
        Line: DotNet String;
    begin
        StreamReader := StreamReader.StreamReader(FileName);
        Line := StreamReader.ReadLine();
        while not IsNull(Line) do begin
            Line := StreamReader.ReadLine();
            if not IsNull(Line) then
                if Line.Contains(Value) then
                    exit(true);
        end;

        exit(false);
    end;

    procedure CountNoOfLinesWithValue(FileName: Text; Value: Text; StartingPosition: Integer; FieldLength: Integer) NoOfLines: Integer
    var
        File: File;
        InStr: InStream;
        Line: Text;
        FieldValue: Text;
    begin
        NoOfLines := 0;
        File.TextMode(true);
        File.Open(FileName);
        File.CreateInStream(InStr);
        while not InStr.EOS do begin
            InStr.ReadText(Line);
            FieldValue := CopyStr(Line, StartingPosition, FieldLength);
            if FieldValue = Value then
                NoOfLines += 1;
        end;
    end;

    procedure ReadTextFile(FilePath: Text; var Content: BigText)
    var
        File: File;
        InStr: InStream;
        ContentLocal: BigText;
    begin
        File.Open(FilePath);
        File.CreateInStream(InStr);
        ContentLocal.Read(InStr); // needed for PreCAL to avoid 'VAR BigText...' complications
        Content := ContentLocal;
        File.Close();
        Erase(FilePath);
    end;

    procedure ReadLineFromStream(FileInStream: InStream; LineNumber: Integer) Line: Text
    var
        i: Integer;
    begin
        for i := 1 to LineNumber do
            FileInStream.ReadText(Line);
    end;


    procedure ReadLine(FileName: Text; LineNumber: Integer) Line: Text
    var
        File: File;
        InStr: InStream;
        i: Integer;
    begin
        File.TextMode(true);
        File.Open(FileName);
        File.CreateInStream(InStr);
        for i := 1 to LineNumber do
            InStr.ReadText(Line);
    end;

    procedure ReadLineWithEncoding(FileName: Text; Encoding: TextEncoding; LineNumber: Integer) Line: Text
    var
        File: File;
        InStr: InStream;
        i: Integer;
    begin
        File.TextMode(true);
        File.Open(FileName, Encoding);
        File.CreateInStream(InStr);
        for i := 1 to LineNumber do
            InStr.ReadText(Line);
    end;

    procedure ReadValue(Line: Text; StartingPosition: Integer; Length: Integer) FieldValue: Text
    begin
        FieldValue := CopyStr(Line, StartingPosition, Length);
    end;

    procedure ReadValueFromLine(FileName: Text; LineNumber: Integer; StartingPosition: Integer; Length: Integer) FieldValue: Text
    var
        Line: Text;
    begin
        Line := ReadLine(FileName, LineNumber);
        FieldValue := ReadValue(Line, StartingPosition, Length);
    end;

    procedure ReadField(Line: Text; FieldPosition: Integer; Delimiter: Text[1]) FieldValue: Text
    var
        CurrFieldPos: Integer;
        Pos: Integer;
        LastField: Boolean;
    begin
        CurrFieldPos := 1;
        repeat
            Pos := StrPos(Line, Delimiter);
            LastField := Pos = 0;
            if LastField then begin
                if FieldPosition <> CurrFieldPos then
                    Error(NoSuchFieldPositionErr, FieldPosition);
                FieldValue := Line;
            end else
                FieldValue := CopyStr(Line, 1, Pos - 1);
            Line := CopyStr(Line, Pos + 1);
            CurrFieldPos += 1;
        until FieldPosition < CurrFieldPos;
        exit(FieldValue);
    end;

    local procedure AreEqualValues(ActualValue: array[5] of Text; ExpectedValue: array[5] of Text) AreEqual: Boolean
    var
        i: Integer;
    begin
        AreEqual := true;
        for i := 1 to ArrayLen(ActualValue) do
            AreEqual := AreEqual and (ActualValue[i] = ExpectedValue[i]);
        exit(AreEqual);
    end;

    procedure FindLineWithValues(FileName: Text; StartingPosition: array[5] of Integer; FieldLength: array[5] of Integer; ExpectedValue: array[5] of Text) Line: Text
    var
        File: File;
        InStr: InStream;
        ActualValue: array[5] of Text;
        AreEqual: Boolean;
    begin
        File.TextMode(true);
        File.Open(FileName);
        File.Read(Line);
        File.CreateInStream(InStr);
        while (not InStr.EOS) and not AreEqual do begin
            InStr.ReadText(Line);
            GetFieldValues(Line, StartingPosition, FieldLength, ActualValue);
            AreEqual := AreEqualValues(ActualValue, ExpectedValue);
        end;
        if not AreEqual then
            Line := '';  // If value is not found in the file, this will return an empty line.
    end;

    procedure FindLineNoWithValue(FileName: Text; StartingPosition: Integer; FieldLength: Integer; Value: Text; Occurrence: Integer) LineNo: Integer
    var
        File: File;
        InStr: InStream;
        FieldValue: Text;
        Line: Text;
        OccurrenceNo: Integer;
    begin
        OccurrenceNo := 0;
        File.TextMode(true);
        File.Open(FileName);
        File.Read(Line);
        LineNo := 0;
        File.CreateInStream(InStr);
        while (not InStr.EOS) and (OccurrenceNo <> Occurrence) do begin
            InStr.ReadText(Line);
            FieldValue := CopyStr(Line, StartingPosition, FieldLength);
            LineNo += 1;
            if FieldValue = Value then
                OccurrenceNo += 1;
        end;
        if (FieldValue <> Value) or (OccurrenceNo <> Occurrence) then
            LineNo := 0;  // If value is not found in the file, this will return 0
    end;

    local procedure GetFieldValues(Line: Text; StartingPosition: array[5] of Integer; FieldLength: array[5] of Integer; var ActualValue: array[5] of Text)
    var
        i: Integer;
    begin
        Clear(ActualValue);
        for i := 1 to ArrayLen(ActualValue) do
            if FieldLength[i] > 0 then
                ActualValue[i] := CopyStr(Line, StartingPosition[i], FieldLength[i]);
    end;
}


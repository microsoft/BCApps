namespace System.IO;

using System;
using System.Utilities;

/// <summary>
/// Table to store CSV (comma-separated values).
/// </summary>
table 1234 "CSV Buffer"
{
    Caption = 'CSV Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Field No."; Integer)
        {
            Caption = 'Field No.';
            DataClassification = SystemMetadata;
        }
        field(3; Value; Text[250])
        {
            Caption = 'Value';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Line No.", "Field No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        IndexDoesNotExistErr: Label 'The field in line %1 with index %2 does not exist. The data could not be retrieved.', Comment = '%1 = line no, %2 = index of the field';
        CSVFile: DotNet File;
        StreamReader: DotNet StreamReader;
        Separator: Text[1];
        CharactersToTrim: Text;

    /// <summary>
    /// Inserts an entry to the record.
    /// </summary>
    /// <param name="LineNo">The line number on which to insert the value.</param>
    /// <param name="FieldNo">The field number (or position) on which to insert the value.</param>
    /// <param name="FieldValue">The value to insert.</param>
    procedure InsertEntry(LineNo: Integer; FieldNo: Integer; FieldValue: Text[250])
    begin
        Rec.Init();
        Rec."Line No." := LineNo;
        Rec."Field No." := FieldNo;
        Rec.Value := FieldValue;
        Rec.Insert();
    end;

    /// <summary>
    /// Loads data from a file.
    /// </summary>
    /// <remark>
    /// Reads the content of the file by lines and separate values using <paramref name="CSVFieldSeparator"/>.
    /// All the characters in <paramref name="CSVCharactersToTrim"/> will be removed from the beginning and the end of the read values.
    /// </remark>
    /// <param name="CSVFileName">The name of the file from which to laod data.</param>
    /// <param name="CSVFieldSeparator">The separator to use to split the values.</param>
    /// <param name="CSVCharactersToTrim">Characters to trim from the beginning and the end of the read values.</param>
    [Scope('OnPrem')]
    procedure LoadData(CSVFileName: Text; CSVFieldSeparator: Text[1]; CSVCharactersToTrim: Text)
    begin
        InitializeReader(CSVFileName, CSVFieldSeparator, CSVCharactersToTrim);
        ReadLines(0);
        StreamReader.Close();
    end;

    /// <summary>
    /// Loads data from a file.
    /// </summary>
    /// <remark>
    /// Reads the content of the file by lines and separate values using <paramref name="CSVFieldSeparator"/>.
    /// </remark>
    /// <param name="CSVFileName">The name of the file from which to load data.</param>
    /// <param name="CSVFieldSeparator">The character to use to split the values.</param>
    [Scope('OnPrem')]
    procedure LoadData(CSVFileName: Text; CSVFieldSeparator: Text[1])
    begin
        LoadData(CSVFileName, CSVFieldSeparator, '');
    end;

    /// <summary>
    /// Loads data from a stream.
    /// </summary>
    /// <remark>
    /// Reads the content of the stream by lines and separate values using <paramref name="CSVFieldSeparator"/>.
    /// All the characters in <paramref name="CSVCharactersToTrim"/> will be omitted from the read values.
    /// </remark>
    /// <param name="CSVInStream">The stream from which to laod data.</param>
    /// <param name="CSVFieldSeparator">The character to use to split the values.</param>
    /// <param name="CSVCharactersToTrim">Characters to trim from the beginning and the end of the read values.</param>
    procedure LoadDataFromStream(CSVInStream: InStream; CSVFieldSeparator: Text[1]; CSVCharactersToTrim: Text)
    begin
        InitializeReaderFromStream(CSVInStream, CSVFieldSeparator, CSVCharactersToTrim);
        ReadLines(0);
        StreamReader.Close();
    end;

    /// <summary>
    /// Loads data from a stream.
    /// </summary>
    /// <remark>
    /// Reads the content of the stream by lines and separate values using <paramref name="CSVFieldSeparator"/>.
    /// </remark>
    /// <param name="CSVInStream">The stream from which to laod data.</param>
    /// <param name="CSVFieldSeparator">The character to use to split the values.</param>
    procedure LoadDataFromStream(CSVInStream: InStream; CSVFieldSeparator: Text[1])
    begin
        LoadDataFromStream(CSVInStream, CSVFieldSeparator, '');
    end;

    /// <summary>
    /// Saves the data stored in the record to a file.
    /// </summary>
    /// <param name="CSVFileName">The name of the output file.</param>
    /// <param name="CSVFieldSeparator">The character to use as separator.</param>
    [Scope('OnPrem')]
    procedure SaveData(CSVFileName: Text; CSVFieldSeparator: Text[1])
    var
        FileManagement: Codeunit "File Management";
        FileMode: DotNet FileMode;
        StreamWriter: DotNet StreamWriter;
    begin
        FileManagement.IsAllowedPath(CSVFileName, false);
        StreamWriter := StreamWriter.StreamWriter(CSVFile.Open(CSVFileName, FileMode.Create));
        WriteToStream(StreamWriter, CSVFieldSeparator);
        StreamWriter.Close();
    end;

    /// <summary>
    /// Saves the data stored in the record to a BLOB.
    /// </summary>
    /// <param name="TempBlob">The BLOB in which to save the data.</param>
    /// <param name="CSVFieldSeparator">The character to use as separator.</param>
    procedure SaveDataToBlob(var TempBlob: Codeunit "Temp Blob"; CSVFieldSeparator: Text[1])
    var
        CSVOutStream: OutStream;
        StreamWriter: DotNet StreamWriter;
    begin
        TempBlob.CreateOutStream(CSVOutStream);
        StreamWriter := StreamWriter.StreamWriter(CSVOutStream);
        WriteToStream(StreamWriter, CSVFieldSeparator);
        StreamWriter.Close();
    end;

    local procedure WriteToStream(var StreamWriter: DotNet StreamWriter; CSVFieldSeparator: Text[1])
    var
        NumberOfColumns: Integer;
    begin
        NumberOfColumns := GetNumberOfColumns();
        if FindSet() then
            repeat
                StreamWriter.Write(Value);
                if "Field No." < NumberOfColumns then
                    StreamWriter.Write(CSVFieldSeparator)
                else
                    StreamWriter.WriteLine();
            until Next() = 0;
    end;

    /// <summary>
    /// Initializes the CSV buffer.
    /// </summary>
    /// <remarks>
    /// No data is inserted into the buffer.
    /// </remarks>
    /// <param name="CSVFileName">The name of the file from which to read data.</param>
    /// <param name="CSVFieldSeparator">The character to use to split the values.</param>
    [Scope('OnPrem')]
    procedure InitializeReader(CSVFileName: Text; CSVFieldSeparator: Text[1])
    begin
        InitializeReader(CSVFileName, CSVFieldSeparator, '');
    end;

    /// <summary>
    /// Initializes the CSV buffer.
    /// </summary>
    /// <remarks>
    /// No data is inserted into the buffer.
    /// </remarks>
    /// <param name="CSVFileName">The name of the file from which to read data.</param>
    /// <param name="CSVFieldSeparator">The character to use to split the values.</param>
    /// <param name="CSVCharactersToTrim">Characters to trim from the beginning and the end of the read values.</param>
    [Scope('OnPrem')]
    procedure InitializeReader(CSVFileName: Text; CSVFieldSeparator: Text[1]; CSVCharactersToTrim: Text)
    var
        FileManagement: Codeunit "File Management";
        Encoding: DotNet Encoding;
    begin
        FileManagement.IsAllowedPath(CSVFileName, false);
        StreamReader := StreamReader.StreamReader(CSVFile.OpenRead(CSVFileName), Encoding.GetEncoding(0));
        Separator := CSVFieldSeparator;
        CharactersToTrim := CSVCharactersToTrim;
    end;

    /// <summary>
    /// Initializes the CSV buffer.
    /// </summary>
    /// <remarks>
    /// No data is inserted into the buffer.
    /// </remarks>
    /// <param name="CSVFileName">The name of the file from which to read data.</param>
    /// <param name="CSVFieldSeparator">The character to use to split the values.</param>
    /// <param name="CSVCharactersToTrim">Characters to trim from the beginning and the end of the read values.</param>
    /// <param name="Encoding">The character encoding to use.</param>
    [Scope('OnPrem')]
    procedure InitializeReader(CSVFileName: Text; CSVFieldSeparator: Text[1]; CSVCharactersToTrim: Text; Encoding: DotNet Encoding)
    var
        FileManagement: Codeunit "File Management";
    begin
        FileManagement.IsAllowedPath(CSVFileName, false);
        StreamReader := StreamReader.StreamReader(CSVFile.OpenRead(CSVFileName), Encoding);
        Separator := CSVFieldSeparator;
        CharactersToTrim := CSVCharactersToTrim;
    end;

    /// <summary>
    /// Initializes the CSV buffer.
    /// </summary>
    /// <remarks>
    /// No data is inserted into the buffer.
    /// </remarks>
    /// <param name="CSVInStream">The stream from which to read data.</param>
    /// <param name="CSVFieldSeparator">The character to use to split the values.</param>
    /// <param name="CSVCharactersToTrim">Characters to trim from the beginning and the end of the read values.</param>
    procedure InitializeReaderFromStream(CSVInStream: InStream; CSVFieldSeparator: Text[1]; CSVCharactersToTrim: Text)
    begin
        StreamReader := StreamReader.StreamReader(CSVInStream);
        Separator := CSVFieldSeparator;
        CharactersToTrim := CSVCharactersToTrim;
    end;

    /// <summary>
    /// Initializes the CSV buffer.
    /// </summary>
    /// <remarks>
    /// No data is inserted into the buffer.
    /// </remarks>
    /// <param name="CSVInStream">The stream from which to read data.</param>
    /// <param name="CSVFieldSeparator">The character to use to split the values.</param>
    procedure InitializeReaderFromStream(CSVInStream: InStream; CSVFieldSeparator: Text[1])
    begin
        InitializeReaderFromStream(CSVInStream, CSVFieldSeparator, '');
    end;

    /// <summary>
    /// Loads data from a stream.
    /// </summary>
    /// <param name="CSVInStream">Instream from which to read data.</param>
    /// <param name="CSVFieldSeparator">The character to use to split the values.</param>
    /// <param name="EncodingCodePage">Encoding page from the file that was loaded in the stream. For more references you can see the Encoding.GetEncoding(EncodingCodePage) in C#.</param>
    procedure LoadDataFromStream(CSVInStream: InStream; CSVFieldSeparator: Text[1]; EncodingCodePage: Integer)
    begin
        LoadDataFromStream(CSVInStream, CSVFieldSeparator, '', EncodingCodePage);
    end;

    /// <summary>
    /// Loads data from a stream.
    /// </summary>
    /// <param name="CSVInStream">Instream from which to read data.</param>
    /// <param name="CSVFieldSeparator">The character to use to split the values.</param>
    /// <param name="CSVCharactersToTrim">Characters to trim from the beginning and the end of the read values.</param>
    /// <param name="EncodingCodePage">Encoding page from the file that was loaded in the stream. For more references you can see the Encoding.GetEncoding(EncodingCodePage) in C#.</param>
    procedure LoadDataFromStream(CSVInStream: InStream; CSVFieldSeparator: Text[1]; CSVCharactersToTrim: Text; EncodingCodePage: Integer)
    begin
        InitializeReaderFromStream(CSVInStream, CSVFieldSeparator, CSVCharactersToTrim, EncodingCodePage);
        ReadLines(0);
        StreamReader.Close();
    end;

    /// <summary>
    /// Initializes the CSV buffer.
    /// </summary>
    /// <param name="CSVInStream">The stream from which to read data.</param>
    /// <param name="CSVFieldSeparator">The character to use to split the values.</param>
    /// <param name="CSVCharactersToTrim">Characters to trim from the beginning and the end of the read values.</param>
    /// <param name="EncodingCodePage">Encoding page from the file that was loaded in the stream. For more references you can see the Encoding.GetEncoding(EncodingCodePage) in C#.</param>
    procedure InitializeReaderFromStream(CSVInStream: InStream; CSVFieldSeparator: Text[1]; CSVCharactersToTrim: Text; EncodingCodePage: Integer)
    var
        Encoding: DotNet Encoding;
    begin
        StreamReader := StreamReader.StreamReader(CSVInStream, Encoding.GetEncoding(EncodingCodePage));
        Separator := CSVFieldSeparator;
        CharactersToTrim := CSVCharactersToTrim;
    end;

    /// <summary>
    /// Populated the CSV buffer with entries.
    /// </summary>
    /// <remarks>
    /// The entries are read from the stream with which the CSV buffer was initialized.
    /// </remarks>
    /// <param name="NumberOfLines">The number of lines to read. If called with 0 or less, the function will read all of the data.</param>
    /// <returns>True if there were any read lines; otherwise - false.</returns>
    [Scope('OnPrem')]
    procedure ReadLines(NumberOfLines: Integer): Boolean
    var
        String: DotNet String;
        CurrentLineNo: Integer;
        CurrentFieldNo: Integer;
        CurrentIndex: Integer;
        NextIndex: Integer;
        Length: Integer;
        StartQuoteIndex: Integer;
        EndQuoteIndex: Integer;
        QuoteTok: Label '"', Comment = 'Token for the a quote', Locked = true;
    begin
        if StreamReader.EndOfStream then
            exit(false);

        repeat
            StartQuoteIndex := -1;
            EndQuoteIndex := -1;
            String := StreamReader.ReadLine();
            CurrentLineNo += 1;
            CurrentIndex := 0;
            StartQuoteIndex := String.IndexOf(QuoteTok, CurrentIndex);
            EndQuoteIndex := String.IndexOf(QuoteTok, StartQuoteIndex + 1);
            repeat
                CurrentFieldNo += 1;

                Rec.Init();
                Rec."Line No." := CurrentLineNo;
                Rec."Field No." := CurrentFieldNo;

                NextIndex := String.IndexOf(Separator, CurrentIndex);
                if (EndQuoteIndex >= 0) and (EndQuoteIndex < CurrentIndex) then begin // Re-look for "
                    StartQuoteIndex := String.IndexOf(QuoteTok, CurrentIndex);
                    EndQuoteIndex := String.IndexOf(QuoteTok, StartQuoteIndex + 1);
                end;
                if (NextIndex > StartQuoteIndex) and (NextIndex < EndQuoteIndex) then // if seperator is inside opening and closing quote, then treat it as part of the string
                    NextIndex := String.IndexOf(Separator, EndQuoteIndex + 1);

                if NextIndex = -1 then
                    Length := String.Length - CurrentIndex
                else
                    Length := NextIndex - CurrentIndex;

                if Length > 250 then
                    Length := 250;
                Rec.Value := String.Substring(CurrentIndex, Length);
                Rec.Value := DelChr(Rec.Value, '<>', CharactersToTrim);

                CurrentIndex := NextIndex + 1;

                Rec.Insert();
            until NextIndex = -1;
            CurrentFieldNo := 0;
        until StreamReader.EndOfStream or (CurrentLineNo = NumberOfLines);

        exit(true);
    end;

    /// <summary>
    /// Resets the filters on the record.
    /// </summary>
    procedure ResetFilters()
    begin
        Rec.SetRange("Line No.");
        Rec.SetRange("Field No.");
        Rec.SetRange(Value);
    end;

    /// <summary>
    /// Gets a value from the record.
    /// </summary>
    /// <param name="LineNo">The line number to identify the value.</param>
    /// <param name="FieldNo">The field number (or position) to identify the value.</param>
    /// <error>The field in line %1 with index %2 does not exist. The data could not be retrieved.</error>
    /// <returns>The value stored on line <paramref name="LineNo"/> and field <paramref name="FieldNo"/>.</returns>
    procedure GetValue(LineNo: Integer; FieldNo: Integer): Text[250]
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
    begin
        TempCSVBuffer.Copy(Rec, true);
        if not TempCSVBuffer.Get(LineNo, FieldNo) then
            Error(IndexDoesNotExistErr, LineNo, FieldNo);

        exit(TempCSVBuffer.Value);
    end;

    /// <summary>
    /// Gets all the lines that contain a specific value on a specific field/position.
    /// </summary>
    /// <param name="FilterFieldNo">The field number (or position) of the value.</param>
    /// <param name="FilterValue">The value to filter on.</param>
    /// <param name="TempResultCSVBuffer">Out parameter to store the result.</param>
    procedure GetCSVLinesWhere(FilterFieldNo: Integer; FilterValue: Text; var TempResultCSVBuffer: Record "CSV Buffer" temporary)
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
    begin
        TempResultCSVBuffer.Reset();
        TempResultCSVBuffer.DeleteAll();
        TempCSVBuffer.Copy(Rec, true);

        Rec.SetRange("Field No.", FilterFieldNo);
        Rec.SetRange(Value, FilterValue);

        if Rec.FindSet() then
            repeat
                TempCSVBuffer.SetRange("Line No.", "Line No.");
                TempCSVBuffer.FindSet();
                repeat
                    TempResultCSVBuffer := TempCSVBuffer;
                    TempResultCSVBuffer.Insert();
                until TempCSVBuffer.Next() = 0;
            until Rec.Next() = 0;

        TempResultCSVBuffer.SetRange("Field No.", 1);
    end;

    /// <summary>
    /// Gets the value on the current line with a specific field number (or position).
    /// </summary>
    /// <error>The field in line %1 with index %2 does not exist. The data could not be retrieved.</error>
    /// <param name="FieldNo">The field number (or posistion) to identify the value.</param>
    /// <returns>The value on the current line and field number <paramref name="FieldNo"/></returns>
    procedure GetValueOfLineAt(FieldNo: Integer): Text[250]
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
    begin
        TempCSVBuffer.Copy(Rec, true);
        if not TempCSVBuffer.Get("Line No.", FieldNo) then
            Error(IndexDoesNotExistErr, "Line No.", FieldNo);

        exit(TempCSVBuffer.Value);
    end;

    /// <summary>
    /// Gets the value on the current line with a specific field number (or position).
    /// </summary>
    /// <error>The field in line %1 with index %2 does not exist. The data could not be retrieved.</error>
    /// <error>unless AcceptNonExisting is set</error>
    /// <param name="FieldNo">The field number (or posistion) to identify the value.</param>
    /// <returns>The value on the current line and field number <paramref name="FieldNo"/></returns>
    procedure GetValueOfLineAt(FieldNo: Integer; AcceptNonExisting: Boolean): Text[250]
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
    begin
        TempCSVBuffer.Copy(Rec, true);
        if not TempCSVBuffer.Get("Line No.", FieldNo) then
            if AcceptNonExisting then
                exit('')
            else
                Error(IndexDoesNotExistErr, "Line No.", FieldNo);

        exit(TempCSVBuffer.Value);
    end;
    /// <summary>
    /// Gets the number of columns store in the record.
    /// </summary>
    /// <returns>The number of fields for every line.</returns>
    procedure GetNumberOfColumns(): Integer
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
    begin
        TempCSVBuffer.Copy(Rec, true);
        TempCSVBuffer.ResetFilters();
        TempCSVBuffer.SetRange("Line No.", "Line No.");
        if TempCSVBuffer.FindLast() then
            exit(TempCSVBuffer."Field No.");

        exit(0);
    end;

    /// <summary>
    /// Gets the number of lines stored in the record.
    /// </summary>
    /// <returns>The number of lines stored in the record.</returns>
    procedure GetNumberOfLines(): Integer
    begin
        if Rec.FindLast() then
            exit(Rec."Line No.");

        exit(0);
    end;
}


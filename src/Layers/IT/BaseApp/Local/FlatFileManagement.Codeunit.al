// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using System.IO;
using System.Utilities;

codeunit 12133 "Flat File Management"
{

    trigger OnRun()
    begin
    end;

    var
        FileMgt: Codeunit "File Management";
        ExportFile: File;
        OutputStream: OutStream;
        ConstFormat: Option AN,CB,CB12,CF,CN,PI,DA,DT,DN,D4,D6,NP,NU,NUp,Nx,PC,PR,QU,PN,VP;
        ConstRecordType: Option A,B,C,D,E,G,H,Z;
        IsRecordOpen: Boolean;
        CodeFieldLengthErr: Label 'The field code must be 8 characters.';
        SplitFormatErr: Label 'Only a value in the AN format can be split. The value is more than 16 characters.';
        ValueWontFitErr: Label 'The value %1 in position %2 exceeds the maximum field size of %3 characters.', Comment = '%1 = Value, %2 = Position, %3 = No. of Characters';
        BlockValueToBigErr: Label 'The maximum size of 1126 characters has been exceeded.';
        RecordToBigErr: Label 'The record does not fit the specification of the data format.';
        ServerTempFileName: Text;
        OutBuf: Text;
        ServerFileName: Text;
        ConstMaxRecordLength: Integer;
        ConstMaxFileSize: Integer;
        CurrentPosition: Integer;
        NumberOfFiles: Integer;
        FileCount: Integer;
        HeaderFooterRecordCountPerFile: Integer;
        RecordCount: array[8] of Integer;
        TotalRecordCount: Integer;
        EstimatedNumberOfRecords: Integer;

    procedure CleanPhoneNumber(PhoneNumber: Text): Text
    var
        CleanedNumber: Text;
        Index: Integer;
    begin
        CleanedNumber := '';
        for Index := 1 to StrLen(PhoneNumber) do
            if PhoneNumber[Index] in ['0' .. '9'] then
                CleanedNumber += Format(PhoneNumber[Index]);
        exit(CleanedNumber);
    end;

    procedure CleanString(InputStr: Text) OutputStr: Text
    var
        Index: Integer;
        IndexWrite: Integer;
    begin
        OutputStr := PadStr(' ', StrLen(InputStr));
        IndexWrite := 1;
        for Index := 1 to StrLen(InputStr) do
            if InputStr[Index] in ['a' .. 'z', 'A' .. 'Z', '0' .. '9', '-', ',', ' ', '@', '.', '_'] then begin
                OutputStr[IndexWrite] := InputStr[Index];
                IndexWrite += 1;
            end;
        OutputStr[IndexWrite] := 0;
    end;

    procedure CopyStringEnding(InputStr: Text; Length: Integer): Text
    var
        InputLength: Integer;
    begin
        InputLength := StrLen(InputStr);
        if InputLength > Length then
            exit(CopyStr(InputStr, InputLength - Length + 1, Length));
        exit(InputStr);
    end;

    procedure EndFile()
    begin
        if IsRecordOpen then
            EndRecord();
        ExportFile.Close();
    end;

    local procedure EndRecord()
    begin
        OutBuf[ConstMaxRecordLength - 2] := 'A';
        OutBuf[ConstMaxRecordLength - 1] := 13;
        OutBuf[ConstMaxRecordLength] := 10;

        OutputStream.WriteText(OutBuf, StrLen(OutBuf));
        IsRecordOpen := false;
    end;

    procedure DownloadFile(FileName: Text)
    var
        FileManagement: Codeunit "File Management";
        DataCompression: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        ServerTempFileInStream: InStream;
        ZipInStream: InStream;
        ZipOutStream: OutStream;
        ToFilter: Text;
        UserFileName: Text;
        ServerFileNameSeries: Text;
        ServerTempFileNameSeries: Text;
        ZipFileNameSeries: Text;
        FileNo: Integer;
    begin
        if ServerFileName <> '' then
            for FileNo := 1 to NumberOfFiles do begin
                ServerTempFileNameSeries := GetSeriesFilename(ServerTempFileName, FileNo);
                ServerFileNameSeries := GetSeriesFilename(ServerFileName, FileNo);
                FileManagement.CopyServerFile(ServerTempFileNameSeries, ServerFileNameSeries, true);
                FileManagement.DeleteServerFile(ServerTempFileNameSeries);
            end
        else
            if NumberOfFiles > 1 then begin
                DataCompression.CreateZipArchive();
                for FileNo := 1 to NumberOfFiles do begin
                    ServerTempFileNameSeries := GetSeriesFilename(ServerTempFileName, FileNo);
                    ZipFileNameSeries := GetSeriesFilename(FileManagement.GetFileName(FileName), FileNo);
                    FileManagement.BLOBImportFromServerFile(TempBlob, ServerTempFileNameSeries);
                    TempBlob.CreateInStream(ServerTempFileInStream);
                    DataCompression.AddEntry(ServerTempFileInStream, ZipFileNameSeries);
                end;
                UserFileName := StrSubstNo('%1.zip', FileManagement.GetFileNameWithoutExtension(FileName));
                Clear(TempBlob);
                TempBlob.CreateOutStream(ZipOutStream);
                DataCompression.SaveZipArchive(ZipOutStream);
                DataCompression.CloseZipArchive();
                TempBlob.CreateInStream(ZipInStream);
                ToFilter := FileManagement.GetToFilterText('', UserFileName);
                DownloadFromStream(ZipInStream, '', '', ToFilter, UserFileName);
            end else begin
                UserFileName := FileManagement.GetFileName(FileName);
                Download(ServerTempFileName, '', '', FileManagement.GetToFilterText('', UserFileName), UserFileName);
            end;
    end;

    procedure FormatDate(InputDate: Date; OutputFormat: Option): Text
    begin
        case OutputFormat of
            ConstFormat::DT, ConstFormat::DN:
                exit(Format(InputDate, 0, '<Day,2><Month,2><Year4>'));
            ConstFormat::DA:
                exit(Format(InputDate, 0, '<Year4>'));
            ConstFormat::D4:
                exit(Format(InputDate, 0, '<Day,2><Month,2>'));
            ConstFormat::D6:
                exit(Format(InputDate, 0, '<Month,2><Year4>'));
        end;
        exit(Format(InputDate));
    end;

    procedure FormatNum(Number: Decimal; ValueFormat: Option): Text
    var
        RoundOption: Text;
    begin
        RoundOption := '=';
        if (Number > -1) and (Number < 1) then
            RoundOption := '>';

        case ValueFormat of
            ConstFormat::NP:
                exit(Format(Round(Abs(Number), 1, RoundOption), 0, '<integer>'));
            ConstFormat::NU:
                exit(Format(Round(Number, 1, RoundOption), 0, '<sign><integer>'));
            ConstFormat::VP:
                begin
                    if Number = 0 then
                        exit('0');
                    exit(Format(Number, 0, '<sign><integer><Decimals,3>'));
                end;
        end;
        exit(Format(Number));
    end;

    procedure FormatPadding(ValueFormat: Option; Value: Text; Length: Integer): Text
    begin
        case ValueFormat of
            ConstFormat::NUp, ConstFormat::CN:
                exit(PadStr('', Length - StrLen(Value), '0') + Value);
            ConstFormat::NU, ConstFormat::CB, ConstFormat::DT, ConstFormat::DA, ConstFormat::DN, ConstFormat::D4,
          ConstFormat::D6, ConstFormat::NP, ConstFormat::Nx, ConstFormat::PC, ConstFormat::QU, ConstFormat::CB12,
          ConstFormat::VP:
                exit(PadStr(' ', Length - StrLen(Value)) + Value);
            ConstFormat::PI, ConstFormat::AN, ConstFormat::CF, ConstFormat::PR:
                exit(UpperCase(Value) + PadStr(' ', Length - StrLen(Value)));
        end;
        exit(Value);
    end;

    procedure GetFileCount(): Integer
    begin
        exit(FileCount);
    end;

    procedure GetMaxRecordsPerFile(): Integer
    begin
        exit((ConstMaxFileSize - HeaderFooterRecordCountPerFile * ConstMaxRecordLength) div ConstMaxRecordLength);
    end;

    procedure GetRecordCount(RecordType: Option A,B,C,D,E,G,H,Z): Integer
    begin
        exit(RecordCount[RecordType + 1]);
    end;

    procedure GetEstimatedNumberOfRecords(): Integer
    begin
        exit(EstimatedNumberOfRecords);
    end;

    procedure GetTotalTransmissions(): Integer
    begin
        exit(NumberOfFiles);
    end;

    procedure Initialize()
    var
        FileManagement: Codeunit "File Management";
    begin
        // Set internal variables
        IsRecordOpen := false;
        ConstMaxFileSize := 5 * 1024 * 1024;
        ConstMaxRecordLength := 1900;
        Clear(RecordCount);
        FileCount := 0;
        NumberOfFiles := 1;
        HeaderFooterRecordCountPerFile := 3; // Default = 1 title + 1 header + 1 footer

        // Setup output file
        ServerTempFileName := FileManagement.ServerTempFileName('txt');
    end;

    procedure RecordsPerFileExceeded(Type: Option A,B,C,D,E,G,H,Z): Boolean
    begin
        if Type in [ConstRecordType::C, ConstRecordType::D, ConstRecordType::H] then
            if TotalRecordCount > 0 then
                if (TotalRecordCount mod GetMaxRecordsPerFile()) = 0 then
                    exit(true);
        exit(false);
    end;

    procedure SetServerFileName(FileName: Text)
    begin
        ServerFileName := FileName;
    end;

    procedure SetEstimatedNumberOfRecords(NewEstimatedNumberOfRecords: Integer)
    begin
        EstimatedNumberOfRecords := NewEstimatedNumberOfRecords;
        NumberOfFiles := EstimatedNumberOfRecords div (GetMaxRecordsPerFile() + 1) + 1;
    end;

    procedure SetHeaderFooterRecordCountPerFile(NewHeaderFooterRecordCountPerFile: Integer)
    begin
        HeaderFooterRecordCountPerFile := NewHeaderFooterRecordCountPerFile;
    end;

    procedure StartNewFile()
    var
        ServerTempFileNameSeries: Text;
    begin
        FileCount += 1;
        ServerTempFileNameSeries := GetSeriesFilename(ServerTempFileName, FileCount);

        ExportFile.TextMode := true;
        ExportFile.WriteMode := true;
        ExportFile.Create(ServerTempFileNameSeries);
        ExportFile.CreateOutStream(OutputStream);

        Clear(RecordCount);
    end;

    procedure StartNewRecord(Type: Option A,B,C,D,E,G,H,Z)
    begin
        if IsRecordOpen then
            EndRecord();

        if Type in [ConstRecordType::C, ConstRecordType::D, ConstRecordType::H] then
            TotalRecordCount += 1;

        IsRecordOpen := true;

        OutBuf := PadStr(' ', ConstMaxRecordLength);

        if Type in [ConstRecordType::C .. ConstRecordType::H] then
            CurrentPosition := 90
        else
            CurrentPosition := ConstMaxRecordLength;

        RecordCount[Type + 1] += 1;

        WritePositionalValue(1, 1, ConstFormat::AN, Format(Type), false);
    end;

    procedure WritePositionalValue(Position: Integer; Length: Integer; ValueFormat: Option; Value: Text; Truncate: Boolean)
    begin
        if ValueFormat = ConstFormat::NU then
            ValueFormat := ConstFormat::NUp;

        Value := CleanString(Value);
        if Truncate then
            Value := CopyStr(Value, 1, Length);
        if StrLen(Value) > Length then
            Error(ValueWontFitErr, Value, Position, Length);

        WriteValue(Position, Length, FormatPadding(ValueFormat, Value, Length))
    end;

    procedure WriteBlockValue("Code": Code[8]; ValueFormat: Option; Value: Text)
    var
        Splits: Integer;
        Index: Integer;
        SplitSize: Integer;
        Offset: Integer;
        Concat: Text;
        NumericalValue: Decimal;
    begin
        if StrLen(Code) <> 8 then
            Error(CodeFieldLengthErr);

        Value := CleanString(Value);
        if StrLen(Value) = 0 then
            exit;

        if ValueFormat in [ConstFormat::NP, ConstFormat::NU] then begin
            Evaluate(NumericalValue, Value);
            if NumericalValue = 0 then
                exit;
        end;

        Splits := Round(Abs(StrLen(Value) - 2) / 15, 1, '<') + 1;
        if (Splits > 1) and (ValueFormat <> ConstFormat::AN) then
            Error(SplitFormatErr);

        if Splits > 75 then
            Error(BlockValueToBigErr);

        if CurrentPosition + GetBlockLength() * Splits > ConstMaxRecordLength - 10 then
            Error(RecordToBigErr);

        Offset := 1;
        for Index := 1 to Splits do begin
            if Index = 1 then begin
                SplitSize := 16;
                Concat := ''
            end else begin
                SplitSize := 15;
                Concat := '+';
            end;

            WriteValue(CurrentPosition, GetBlockLength(), Code + FormatPadding(ValueFormat, Concat + CopyStr(Value, Offset, SplitSize), 16));
            CurrentPosition += GetBlockLength();
            Offset += SplitSize;
        end
    end;

    [Scope('OnPrem')]
    procedure WriteBlankValue(ValueFormat: Option)
    begin
        WriteValue(CurrentPosition, GetBlockLength(), FormatPadding(ValueFormat, '', GetBlockLength()));
        CurrentPosition += GetBlockLength();
    end;

    procedure WriteValue(Position: Integer; Length: Integer; Value: Text)
    var
        Index: Integer;
    begin
        for Index := 1 to Length do
            if Value[Index] <> 0 then
                OutBuf[Position + Index - 1] := Value[Index];
    end;

    local procedure GetSeriesFilename(FileName: Text; FileNo: Integer): Text
    var
        Directory: Text;
    begin
        if EstimatedNumberOfRecords <= GetMaxRecordsPerFile() then
            exit(FileName);

        if StrPos(FileName, '\') <> 0 then
            Directory := FileMgt.GetDirectoryName(FileName) + '\';
        exit(Directory + FileMgt.GetFileNameWithoutExtension(FileName) + Format(FileNo) + '.' + FileMgt.GetExtension(FileName));
    end;

    local procedure GetBlockLength(): Integer
    begin
        exit(24);
    end;
}


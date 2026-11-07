// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using Microsoft.Bank.BankAccount;
using System.IO;
using System.Text;
using System.Utilities;

codeunit 10331 "EFT Export Mgt"
{
    Permissions = TableData "Data Exch." = rimd,
                  TableData "Data Exch. Field" = rimd,
                  TableData "ACH US Header" = rimd,
                  TableData "ACH US Footer" = rimd;

    trigger OnRun()
    begin
    end;

    var
        ACHUSHeader: Record "ACH US Header";
        ACHUSFooter: Record "ACH US Footer";
        ACHRBHeader: Record "ACH RB Header";
        ACHRBFooter: Record "ACH RB Footer";
        ACHCecobanHeader: Record "ACH Cecoban Header";
        ACHCecobanFooter: Record "ACH Cecoban Footer";
        ExportEFTRB: Codeunit "Export EFT (RB)";
        LineType: Option Detail,Header,Footer;
        FormatNotDefinedErr: Label 'You must choose a valid export format for the bank account. Format %1 is not correctly defined.', Comment = '%1 = Data Exch. Def. Code';
        DataExchLineDefNotFoundErr: Label 'The %1 export format does not support the Payment Method Code %2.', Comment = '%1=Data Exch. Def. Name;%2=Data Exch. Line Def. Code';
        IncorrectLengthOfValuesErr: Label 'The payment that you are trying to export is different from the specified %1, %2.\\The value in the %3 field does not have the length that is required by the export format. \Expected: %4 \Actual: %5 \Field Value: %6.', Comment = '%1=Data Exch.Def Type;%2=Data Exch. Def Code;%3=Field;%4=Expected length;%5=Actual length;%6=Actual Value';
        DateTxt: Label 'Date';

    [Scope('OnPrem')]
    procedure ExportDataExchToFlatFile(DataExchNo: Integer; Filename: Text; LineFileType: Integer; HeaderCount: Integer)
    var
        DataExchField: Record "Data Exch. Field";
        DataExch: Record "Data Exch.";
        TempBlob: Codeunit "Temp Blob";
        ExportGenericFixedWidth: XMLport "Export Generic Fixed Width";
        ExportFile: File;
        RecordRef: RecordRef;
        OutStream: OutStream;
        InStream: InStream;
        CRLF: Text;
        Filename2: Text[250];
    begin
        DataExchField.SetRange("Data Exch. No.", DataExchNo);
        if DataExchField.Count > 0 then begin
            ExportFile.WriteMode := true;
            ExportFile.TextMode := true;
            if Exists(Filename) and ((LineFileType <> LineType::Header) or ((LineFileType = LineType::Header) and (HeaderCount > 1))) then
                ExportFile.Open(Filename)
            else
                ExportFile.Create(Filename);

            // Copy current file contents to TempBlob
            ExportFile.CreateInStream(InStream);
            TempBlob.CreateOutStream(OutStream);
            CopyStream(OutStream, InStream);

            ExportFile.Close();
            ExportFile.Create(Filename);
            TempBlob.CreateInStream(InStream);

            // Copy current tempblob to newly-instantiated file
            ExportFile.CreateOutStream(OutStream);
            CopyStream(OutStream, InStream);

            if (ExportFile.Len > 0) and
               ((LineFileType <> LineType::Header) or ((LineFileType = LineType::Header) and (HeaderCount > 1)))
            then begin
                // Only the first line needs to not write a CRLF.
                CRLF[1] := 13;
                CRLF[2] := 10;
                OutStream.Write(CRLF[1]);
                OutStream.Write(CRLF[2]);
            end;

            if LineFileType = LineType::Footer then begin
                Filename2 := CopyStr(Filename, 1, 250);

                DataExch.Get(DataExchNo);
                DataExch."File Name" := Filename2;

                RecordRef.GetTable(DataExch);
                TempBlob.ToRecordRef(RecordRef, DataExch.FieldNo("File Content"));
                RecordRef.SetTable(DataExch);

                DataExch.Modify();
            end;

            // Now copy current file contents to table, also.
            ExportGenericFixedWidth.SetDestination(OutStream);
            ExportGenericFixedWidth.SetTableView(DataExchField);
            ExportGenericFixedWidth.Export();
            ExportFile.Close();

            DataExchField.DeleteAll(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertDataExchLineForFlatFile(var DataExch: Record "Data Exch."; LineNo: Integer; var RecRef: RecordRef)
    var
        DataExchMapping: Record "Data Exch. Mapping";
        TableID: Integer;
    begin
        DataExchMapping.Init();
        DataExchMapping.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchMapping.SetRange("Data Exch. Line Def Code", DataExch."Data Exch. Line Def Code");
        if DataExchMapping.FindFirst() then begin
            TableID := DataExchMapping."Table ID";
            ProcessColumnMapping(DataExch, RecRef, LineNo, TableID);
        end;
    end;

    local procedure ProcessColumnMapping(var DataExch: Record "Data Exch."; var RecRef: RecordRef; LineNo: Integer; TableID: Integer)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchField: Record "Data Exch. Field";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TransformationRule: Record "Transformation Rule";
        ValueAsDestType: Variant;
        FieldRef2: FieldRef;
        ValueAsString: Text[250];
    begin
        if not DataExchDef.Get(DataExch."Data Exch. Def Code") then
            Error(FormatNotDefinedErr, DataExch."Data Exch. Def Code");

        PrepopulateColumns(DataExchDef, DataExch."Data Exch. Line Def Code", DataExch."Entry No.", LineNo);

        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExch."Data Exch. Line Def Code");
        DataExchFieldMapping.SetRange("Table ID", TableID);
        DataExchFieldMapping.FindSet();
        repeat
            DataExchColumnDef.Get(DataExchDef.Code, DataExch."Data Exch. Line Def Code", DataExchFieldMapping."Column No.");
            if DataExchColumnDef.Constant = '' then begin
                if DataExchFieldMapping."Use Default Value" then
                    ValueAsString := DataExchFieldMapping."Default Value"
                else begin
                    FieldRef2 := RecRef.Field(DataExchFieldMapping."Field ID");

                    if FieldRef2.Class = FieldClass::FlowField then
                        FieldRef2.CalcField();

                    CheckOptional(DataExchFieldMapping.Optional, FieldRef2);

                    CastToDestinationType(ValueAsDestType, FieldRef2.Value, DataExchColumnDef, DataExchFieldMapping.Multiplier);
                    ValueAsString := FormatToText(ValueAsDestType, DataExchDef, DataExchColumnDef);

                    if TransformationRule.Get(DataExchFieldMapping."Transformation Rule") then
                        ValueAsString := CopyStr(TransformationRule.TransformText(ValueAsString), 1, DataExchColumnDef.Length);
                end;
                if DataExchColumnDef."Data Type" <> DataExchColumnDef."Data Type"::Decimal then
                    CheckLength(ValueAsString, RecRef.Field(DataExchFieldMapping."Field ID"), DataExchDef, DataExchColumnDef)
                else
                    ValueAsString := DelChr(ValueAsString, '=', '.,');

                DataExchField.Get(DataExch."Entry No.", LineNo, DataExchFieldMapping."Column No.");
                DataExchField.Value := ValueAsString;
                DataExchField.Modify();
            end else begin
                DataExchField.Get(DataExch."Entry No.", LineNo, DataExchFieldMapping."Column No.");
                CastToDestinationType(ValueAsDestType, DataExchField.Value, DataExchColumnDef, DataExchFieldMapping.Multiplier);
                ValueAsString := FormatToText(DelChr(ValueAsDestType, '>', ' '), DataExchDef, DataExchColumnDef);
                DataExchField.Value := ValueAsString;
                DataExchField.Modify();
            end;

        until DataExchFieldMapping.Next() = 0;
    end;

    local procedure PrepopulateColumns(DataExchDef: Record "Data Exch. Def"; DataExchLineDefCode: Code[20]; DataExchEntryNo: Integer; DataExchLineNo: Integer)
    var
        DataExchField: Record "Data Exch. Field";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        ColumnIndex: Integer;
    begin
        if DataExchDef."File Type" in [DataExchDef."File Type"::"Fixed Text", DataExchDef."File Type"::Xml] then begin
            DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
            DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDefCode);
            if not DataExchColumnDef.FindSet() then
                Error(DataExchLineDefNotFoundErr, DataExchDef.Name, DataExchLineDefCode);
            repeat
                DataExchField.InsertRec(
                  DataExchEntryNo, DataExchLineNo, DataExchColumnDef."Column No.",
                  PadStr(DataExchColumnDef.Constant, DataExchColumnDef.Length), DataExchLineDefCode)
            until DataExchColumnDef.Next() = 0;
        end else begin
            if not DataExchLineDef.Get(DataExchDef.Code, DataExchLineDefCode) then
                Error(DataExchLineDefNotFoundErr, DataExchDef.Name, DataExchLineDefCode);
            for ColumnIndex := 1 to DataExchLineDef."Column Count" do
                if DataExchColumnDef.Get(DataExchDef.Code, DataExchLineDef.Code, ColumnIndex) then
                    DataExchField.InsertRec(
                      DataExchEntryNo, DataExchLineNo, ColumnIndex, DataExchColumnDef.Constant, DataExchLineDefCode)
                else
                    DataExchField.InsertRec(DataExchEntryNo, DataExchLineNo, ColumnIndex, '', DataExchLineDefCode);
        end;
    end;

    local procedure CheckOptional(Optional: Boolean; FieldRef: FieldRef)
    var
        Value: Variant;
        StringValue: Text;
    begin
        if Optional then
            exit;

        Value := FieldRef.Value();
        StringValue := Format(Value);

        // There are fields that are required that can be 0 so this check is not valid for EFT
        if StringValue = '' then
            FieldRef.TestField();
    end;

    local procedure CastToDestinationType(var DestinationValue: Variant; SourceValue: Variant; DataExchColumnDef: Record "Data Exch. Column Def"; Multiplier: Decimal)
    var
        ValueAsDecimal: Decimal;
        ValueAsDate: Date;
        ValueAsDateTime: DateTime;
        ValueAsBoolean: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeCastToDestinationType(DestinationValue, SourceValue, DataExchColumnDef, Multiplier, IsHandled);
        if IsHandled then
            exit;

        case DataExchColumnDef."Data Type" of
            DataExchColumnDef."Data Type"::Decimal:
                begin
                    if Format(SourceValue) = '' then
                        ValueAsDecimal := 0
                    else
                        Evaluate(ValueAsDecimal, Format(SourceValue));
                    DestinationValue := Multiplier * ValueAsDecimal;
                end;
            DataExchColumnDef."Data Type"::Text:
                DestinationValue := Format(SourceValue);
            DataExchColumnDef."Data Type"::Date:
                begin
                    Evaluate(ValueAsDate, Format(SourceValue));
                    DestinationValue := ValueAsDate;
                end;
            DataExchColumnDef."Data Type"::DateTime:
                begin
                    if SourceValue.IsTime() then
                        SourceValue := CreateDateTime(Today(), SourceValue);
                    if SourceValue.IsDate() then
                        SourceValue := CreateDateTime(SourceValue, 0T);
                    Evaluate(ValueAsDateTime, Format(SourceValue, 0, 9), 9);
                    DestinationValue := ValueAsDateTime;
                end;
            DataExchColumnDef."Data Type"::Boolean:
                begin
                    Evaluate(ValueAsBoolean, Format(SourceValue));
                    DestinationValue := ValueAsBoolean;
                end;
        end;
    end;

    local procedure FormatToText(ValueToFormat: Variant; DataExchDef: Record "Data Exch. Def"; DataExchColumnDef: Record "Data Exch. Column Def"): Text[250]
    var
        StringConversionManagement: Codeunit StringConversionManagement;
        NewString: Text[250];
    begin
        if DataExchColumnDef."Data Format" <> '' then
            if DataExchColumnDef."Data Type" <> DataExchColumnDef."Data Type"::Decimal then
                if not ((DataExchColumnDef."Data Type" = DataExchColumnDef."Data Type"::Text) and
                        (StrPos(UpperCase(DataExchColumnDef.Name), UpperCase(DateTxt)) > 0))
                then
                    exit(Format(ValueToFormat, 0, DataExchColumnDef."Data Format"));

        if DataExchDef."File Type" = DataExchDef."File Type"::Xml then
            exit(Format(ValueToFormat, 0, 9));

        if (DataExchDef."File Type" = DataExchDef."File Type"::"Fixed Text") and
           (DataExchColumnDef."Data Type" = DataExchColumnDef."Data Type"::Text)
        then begin
            if DataExchColumnDef."Text Padding Required" and (DataExchColumnDef."Pad Character" <> '') then begin
                NewString :=
                  StringConversionManagement.GetPaddedString(
                    ValueToFormat,
                    DataExchColumnDef.Length,
                    DataExchColumnDef."Pad Character",
                    DataExchColumnDef.Justification);
                exit(Format(NewString, 0, StrSubstNo('<Text,%1>', DataExchColumnDef.Length)));
            end;
            exit(Format(ValueToFormat, 0, StrSubstNo('<Text,%1>', DataExchColumnDef.Length)));
        end;

        if DataExchColumnDef."Data Type" = DataExchColumnDef."Data Type"::Decimal then begin
            ValueToFormat := Format(ValueToFormat, 0, 1);
            if DataExchColumnDef."Text Padding Required" and (DataExchColumnDef."Pad Character" <> '') then begin
                NewString :=
                  StringConversionManagement.GetPaddedString(
                    ValueToFormat,
                    DataExchColumnDef.Length,
                    DataExchColumnDef."Pad Character",
                    DataExchColumnDef.Justification);
                exit(NewString);
            end;
        end;
        exit(Format(ValueToFormat));
    end;

    local procedure CheckLength(Value: Text; FieldRef: FieldRef; DataExchDef: Record "Data Exch. Def"; DataExchColumnDef: Record "Data Exch. Column Def")
    var
        DataExchDefCode: Code[20];
    begin
        DataExchDefCode := DataExchColumnDef."Data Exch. Def Code";

        if (DataExchColumnDef.Length > 0) and (StrLen(Value) > DataExchColumnDef.Length) then
            Error(IncorrectLengthOfValuesErr, GetType(DataExchDefCode), DataExchDefCode,
              FieldRef.Caption, DataExchColumnDef.Length, StrLen(Value), Value);

        if (DataExchDef."File Type" = DataExchDef."File Type"::"Fixed Text") and
           (StrLen(Value) <> DataExchColumnDef.Length)
        then
            Error(IncorrectLengthOfValuesErr, GetType(DataExchDefCode), DataExchDefCode, FieldRef.Caption,
              DataExchColumnDef.Length, StrLen(Value), Value);
    end;

    local procedure GetType(DataExchDefCode: Code[20]): Text
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        DataExchDef.Get(DataExchDefCode);
        exit(Format(DataExchDef.Type));
    end;

    [Scope('OnPrem')]
    procedure PrepareEFTHeader(DataExch: Record "Data Exch."; BankAccountNo: Text[30]; BankAccCode: Code[20])
    var
        BankAccount: Record "Bank Account";
        FileDate: Date;
        FileTime: Time;
        DateInteger: Integer;
        DateFormat: Text[100];
    begin
        FileDate := Today;
        FileTime := Time;

        if BankAccount.Get(BankAccCode) then
            case BankAccount."Export Format" of
                BankAccount."Export Format"::US:
                    if not ACHUSHeader.Get(DataExch."Entry No.") then begin
                        ACHUSHeader.Init();
                        ACHUSHeader."Data Exch. Entry No." := DataExch."Entry No.";
                        OnBeforeACHUSHeaderInsert(ACHUSHeader, BankAccCode);
                        ACHUSHeader.Insert();
                        Commit();
                        ACHUSHeader."Company Name" := CompanyName;
                        ACHUSHeader."Bank Account Number" := BankAccountNo;
                        ACHUSHeader."File Creation Date" := FileDate;
                        ACHUSHeader."File Creation Time" := FileTime;
                        ACHUSHeader.Modify();
                    end;
                BankAccount."Export Format"::CA:
                    if not ACHRBHeader.Get(DataExch."Entry No.") then begin
                        ACHRBHeader.Init();
                        ACHRBHeader."Data Exch. Entry No." := DataExch."Entry No.";
                        OnBeforeACHRBHeaderInsert(ACHRBHeader, BankAccCode);
                        ACHRBHeader.Insert();
                        Commit();
                        ACHRBHeader."File Creation Date" := ExportEFTRB.JulianDate(FileDate);

                        // if can find the column definition, get the value of the Data Format and assign it to DateFormat variable
                        DateFormat := ExportEFTRB.GetDateFormatString(DataExch."Entry No.", ACHRBHeader.FieldName("File Creation Date"));
                        if DateFormat <> '' then begin
                            if (StrPos(DateFormat, '<Year4') > 0) then
                                Evaluate(DateInteger, Format(FileDate, 8, DateFormat))
                            else
                                Evaluate(DateInteger, Format(FileDate, 7, DateFormat));
                            ACHRBHeader."File Creation Date" := DateInteger;
                        end;

                        ACHRBHeader.Modify();
                    end;
                BankAccount."Export Format"::MX:
                    if not ACHCecobanHeader.Get(DataExch."Entry No.") then begin
                        ACHCecobanHeader.Init();
                        ACHCecobanHeader."Data Exch. Entry No." := DataExch."Entry No.";
                        OnBeforeACHCecobanHeaderInsert(ACHCecobanHeader, BankAccCode);
                        ACHCecobanHeader.Insert();
                        Commit();
                        ACHCecobanHeader."Bank Account No" := BankAccountNo;
                        ACHCecobanHeader.Modify();
                    end;
            end;
    end;

    [Scope('OnPrem')]
    procedure PrepareEFTFooter(DataExch: Record "Data Exch."; NoOfBankAccount: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(NoOfBankAccount);
        case BankAccount."Export Format" of
            BankAccount."Export Format"::US:
                if not ACHUSFooter.Get(DataExch."Entry No.") then begin
                    ACHUSFooter.Init();
                    ACHUSFooter."Data Exch. Entry No." := DataExch."Entry No.";
                    ACHUSFooter.Insert();
                    Commit();
                    ACHUSFooter."Company Name" := CompanyName;
                    ACHUSFooter.Modify();
                end;
            BankAccount."Export Format"::CA:
                if not ACHRBFooter.Get(DataExch."Entry No.") then begin
                    ACHRBFooter.Init();
                    ACHRBFooter."Data Exch. Entry No." := DataExch."Entry No.";
                    ACHRBFooter.Insert();
                end;
            BankAccount."Export Format"::MX:
                if not ACHCecobanFooter.Get(DataExch."Entry No.") then begin
                    ACHCecobanFooter.Init();
                    ACHCecobanFooter."Data Exch. Entry No." := DataExch."Entry No.";
                    ACHCecobanFooter.Insert();
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure AddPadBlocks(Filename: Text; var EFTValues: Codeunit "EFT Values")
    var
        TempBlob: Codeunit "Temp Blob";
        ExportFile: File;
        OutStream: OutStream;
        InStream: InStream;
        NoOfRec: Integer;
        IsHandled: Boolean;
    begin
        OnBeforeAddPadBlocks(EFTValues, IsHandled);
        if IsHandled then
            exit;

        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        if Exists(Filename) then
            ExportFile.Open(Filename)
        else
            exit;

        // Copy current file contents to TempBlob
        ExportFile.CreateInStream(InStream);
        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);

        ExportFile.Close();
        ExportFile.Create(Filename);
        TempBlob.CreateInStream(InStream);

        // Copy current tempblob to newly-instantiated file
        ExportFile.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        OutStream.WriteText(); // Carriage Return and Line Feed
        NoOfRec := EFTValues.GetNoOfRec();

        while NoOfRec mod 10 <> 0 do begin // BlockingFactor
            OutStream.WriteText(PadStr('', 94, '9'));
            OutStream.WriteText(); // Carriage Return and Line Feed
            NoOfRec := NoOfRec + 1;
            EFTValues.SetNoOfRec(NoOfRec);
        end;

        ExportFile.Close();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeACHRBHeaderInsert(var ACHRBHeader: Record "ACH RB Header"; BankAccCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeACHUSHeaderInsert(var ACHUSHeader: Record "ACH US Header"; BankAccCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeACHCecobanHeaderInsert(var ACHCecobanHeader: Record "ACH Cecoban Header"; BankAccCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddPadBlocks(var EFTValues: Codeunit "EFT Values"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCastToDestinationType(var DestinationValue: Variant; SourceValue: Variant; DataExchColumnDef: Record "Data Exch. Column Def"; Multiplier: Decimal; var IsHandled: Boolean)
    begin
    end;
}
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.PositivePay;

using System.IO;
using System.Text;

/// <summary>
/// Manages the export of positive pay data to external file formats, handling data exchange processes for positive pay checks.
/// This codeunit orchestrates the complete export workflow including file generation, data mapping, and validation.
/// </summary>
/// <remarks>
/// The Positive Pay Export Management codeunit is responsible for converting positive pay entries into various export formats
/// required by different banks. It handles the data exchange framework operations including field mapping, data transformation,
/// and file formatting. The codeunit supports fixed-width and delimited file formats and ensures data integrity through
/// validation processes. It integrates with the Data Exchange framework to provide flexible export capabilities.
/// </remarks>
codeunit 1711 "Positive Pay Export Mgt"
{
    Permissions = TableData "Data Exch." = rimd,
                  TableData "Data Exch. Field" = rimd,
                  TableData "Positive Pay Header" = rimd,
                  TableData "Positive Pay Footer" = rimd;

    trigger OnRun()
    begin
    end;

    var
        LineType: Option Detail,Header,Footer;
        FormatNotDefinedErr: Label 'You must choose a valid export format for the bank account. Format %1 is not correctly defined.', Comment = '%1 = Data Exch. Def. Code';
        DataExchLineDefNotFoundErr: Label 'The %1 export format does not support the Payment Method Code %2.', Comment = '%1=Data Exch. Def. Name;%2=Data Exch. Line Def. Code';
        IncorrectLengthOfValuesErr: Label 'The payment that you are trying to export is different from the specified %1, %2.\\The value in the %3 field does not have the length that is required by the export format. \Expected: %4 \Actual: %5 \Field Value: %6.', Comment = '%1=Data Exch.Def Type;%2=Data Exch. Def Code;%3=Field;%4=Expected length;%5=Actual length;%6=Actual Value';

    /// <summary>
    /// Exports data exchange records to a flat file format with proper formatting and line structure.
    /// </summary>
    /// <param name="DataExchNo">The data exchange entry number to export.</param>
    /// <param name="Filename">The target file path for the export.</param>
    /// <param name="LineFileType">The type of line being exported (Detail, Header, or Footer).</param>
    /// <param name="HeaderCount">The number of header records processed.</param>
    /// <remarks>
    /// This procedure handles the physical file creation and writing process for positive pay exports.
    /// It manages file appending for multiple line types and ensures proper line termination with CRLF.
    /// The procedure integrates with the Export Generic Fixed Width XMLport for data formatting.
    /// </remarks>
    [Scope('OnPrem')]
    procedure ExportDataExchToFlatFile(DataExchNo: Integer; Filename: Text; LineFileType: Integer; HeaderCount: Integer)
    var
        DataExchField: Record "Data Exch. Field";
        DataExch: Record "Data Exch.";
        ExportGenericFixedWidth: XMLport "Export Generic Fixed Width";
        ExportFile: File;
        OutStream: OutStream;
        InStream: InStream;
        CRLF: Text;
    begin
        DataExchField.SetRange("Data Exch. No.", DataExchNo);
        if DataExchField.Count > 0 then begin
            ExportFile.WriteMode := true;
            ExportFile.TextMode := true;
            if Exists(Filename) and ((LineFileType <> LineType::Header) or ((LineFileType = LineType::Header) and (HeaderCount > 1))) then
                ExportFile.Open(Filename)
            else
                ExportFile.Create(Filename);

            DataExch.Get(DataExchNo);

            // Copy current file contents to Record
            ExportFile.CreateInStream(InStream);
            DataExch."File Content".CreateOutStream(OutStream);
            CopyStream(OutStream, InStream);

            ExportFile.Close();
            // Copy current Record to newly-instantiated file
            ExportFile.Create(Filename);
            DataExch."File Content".CreateInStream(InStream);
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
                DataExch."File Name" := CopyStr(Filename, 1, 250);
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

    /// <summary>
    /// Creates data exchange field records for flat file export based on record data and mapping configuration.
    /// </summary>
    /// <param name="DataExch">The data exchange record containing export configuration.</param>
    /// <param name="LineNo">The line number in the export file.</param>
    /// <param name="RecRef">Reference to the source record containing data to export.</param>
    /// <remarks>
    /// This procedure bridges the gap between source data records and the data exchange framework.
    /// It identifies the appropriate table mapping and delegates field processing to handle data transformation.
    /// </remarks>
    [Scope('OnPrem')]
    procedure InsertDataExchLineForFlatFile(var DataExch: Record "Data Exch."; LineNo: Integer; RecRef: RecordRef)
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

    local procedure ProcessColumnMapping(var DataExch: Record "Data Exch."; RecRef: RecordRef; LineNo: Integer; TableID: Integer)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchField: Record "Data Exch. Field";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TransformationRule: Record "Transformation Rule";
        StringConversionManagement: Codeunit StringConversionManagement;
        ValueAsDestType: Variant;
        FieldRef: FieldRef;
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
            if DataExchFieldMapping."Use Default Value" then
                ValueAsString := DataExchFieldMapping."Default Value"
            else begin
                FieldRef := RecRef.Field(DataExchFieldMapping."Field ID");

                if FieldRef.Class = FieldClass::FlowField then
                    FieldRef.CalcField();
                CheckOptional(DataExchFieldMapping.Optional, FieldRef);
                CastToDestinationType(ValueAsDestType, FieldRef.Value, DataExchColumnDef, DataExchFieldMapping.Multiplier);
                ValueAsString := FormatToText(ValueAsDestType, DataExchDef, DataExchColumnDef);

                if TransformationRule.Get(DataExchFieldMapping."Transformation Rule") then
                    ValueAsString := CopyStr(TransformationRule.TransformText(ValueAsString), 1, DataExchColumnDef.Length);

                if DataExchColumnDef."Text Padding Required" and (DataExchColumnDef."Pad Character" <> '') and (not DataExchColumnDef."Blank Zero") then
                    ValueAsString :=
                      StringConversionManagement.GetPaddedString(
                        ValueAsString,
                        DataExchColumnDef.Length,
                        DataExchColumnDef."Pad Character",
                        DataExchColumnDef.Justification);
            end;
            if DataExchDef."File Type" = DataExchDef."File Type"::"Fixed Text" then
                ValueAsString := Format(ValueAsString, 0, StrSubstNo('<Text,%1>', DataExchColumnDef.Length));
            CheckLength(ValueAsString, RecRef.Field(DataExchFieldMapping."Field ID"), DataExchDef, DataExchColumnDef);

            DataExchField.Get(DataExch."Entry No.", LineNo, DataExchFieldMapping."Column No.");
            DataExchField.Value := ValueAsString;
            DataExchField.Modify();
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

        if ((Value.IsDecimal or Value.IsInteger or Value.IsBigInteger) and (StringValue = '0')) or
           (StringValue = '')
        then
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
    begin
        case true of
            (Format(ValueToFormat) = '0') and (DataExchColumnDef."Blank Zero"):
                exit('');
            DataExchDef."File Type" = DataExchDef."File Type"::Xml:
                exit(Format(ValueToFormat, 0, 9));
            DataExchColumnDef."Data Format" <> '':
                exit(Format(ValueToFormat, 0, DataExchColumnDef."Data Format"));
            DataExchColumnDef."Data Type" = DataExchColumnDef."Data Type"::Decimal:
                exit(Format(ValueToFormat, 0, '<Precision,2><Standard Format,2>')); // Format 2 always uses a period (.) as the decimal separator, regardless of the Regional setting.
            else
                exit(Format(ValueToFormat));
        end;
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

    /// <summary>
    /// Prepares positive pay header record with basic account and company information for export.
    /// </summary>
    /// <param name="DataExch">The data exchange record to associate with the header.</param>
    /// <param name="BankAccountNo">The bank account number for the positive pay file.</param>
    /// <remarks>
    /// This procedure creates the header record that will be included in the positive pay export file.
    /// The header contains essential identification information including company name, account number, and file date.
    /// </remarks>
    procedure PreparePosPayHeader(DataExch: Record "Data Exch."; BankAccountNo: Text[30])
    var
        PosPayHeader: Record "Positive Pay Header";
    begin
        PosPayHeader.Init();
        PosPayHeader."Data Exch. Entry No." := DataExch."Entry No.";
        PosPayHeader."Company Name" := CompanyName;
        PosPayHeader."Account Number" := BankAccountNo;
        PosPayHeader."Date of File" := Today;
        PosPayHeader.Insert();
    end;

    /// <summary>
    /// Prepares positive pay footer record with summary information for the export file.
    /// </summary>
    /// <param name="DataExch">The data exchange record to associate with the footer.</param>
    /// <param name="DataExchDetalEntryNo">The detail entry number for cross-reference.</param>
    /// <param name="BankAccountNo">The bank account number for the positive pay file.</param>
    /// <remarks>
    /// This procedure creates the footer record that concludes the positive pay export file.
    /// The footer provides summary information and maintains referential integrity with detail records.
    /// </remarks>
    procedure PreparePosPayFooter(DataExch: Record "Data Exch."; DataExchDetalEntryNo: Integer; BankAccountNo: Text[30])
    var
        PosPayFooter: Record "Positive Pay Footer";
    begin
        PosPayFooter.Init();
        PosPayFooter."Data Exch. Entry No." := DataExch."Entry No.";
        PosPayFooter."Data Exch. Detail Entry No." := DataExchDetalEntryNo;
        PosPayFooter."Account Number" := BankAccountNo;
        PosPayFooter.Insert();
    end;

    /// <summary>
    /// Integration event that allows customization of data type casting during export processing.
    /// </summary>
    /// <param name="DestinationValue">The converted value in the target data type.</param>
    /// <param name="SourceValue">The original value from the source field.</param>
    /// <param name="DataExchColumnDef">The column definition containing conversion rules.</param>
    /// <param name="Multiplier">The multiplier to apply during numeric conversions.</param>
    /// <param name="IsHandled">Indicates whether the conversion has been handled by subscriber code.</param>
    /// <remarks>
    /// This integration event enables customization of how field values are converted between different data types
    /// during the export process. Subscribers can implement custom conversion logic for specific scenarios.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCastToDestinationType(var DestinationValue: Variant; SourceValue: Variant; DataExchColumnDef: Record "Data Exch. Column Def"; Multiplier: Decimal; var IsHandled: Boolean)
    begin
    end;
}

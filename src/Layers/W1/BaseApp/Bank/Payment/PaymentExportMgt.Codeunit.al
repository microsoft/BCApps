// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using System.IO;
using System.Text;

/// <summary>
/// Codeunit 1210 "Payment Export Mgt" manages the export of payment data to bank files.
/// Handles data exchange creation, payment line processing, column mapping, and file export operations
/// for various payment export formats including SEPA and bank-specific formats.
/// </summary>
/// <remarks>
/// Integrates with Data Exchange Framework for flexible payment file formats. Supports both
/// server-side and client-side file exports. Provides extensibility through integration events
/// for custom export logic and validation.
/// </remarks>
codeunit 1210 "Payment Export Mgt"
{
    Permissions = TableData "Gen. Journal Line" = rm,
                  TableData "Data Exch." = rimd,
                  TableData "Data Exch. Field" = rimd,
                  TableData "Payment Export Data" = rimd;

    trigger OnRun()
    begin
    end;

    var
        ServerFileExtension: Text[3];
        ServerFileName: Text;
        SilentServerMode: Boolean;
        IncorrectLengthOfValuesErr: Label 'The payment that you are trying to export is different from the specified %1, %2.\\The value in the %3 field does not have the length that is required by the export format. \Expected: %4 \Actual: %5 \Field Value: %6.', Comment = '%1=Data Exch.Def Type;%2=Data Exch. Def Code;%3=Field;%4=Expected length;%5=Actual length;%6=Actual Value';
        FormatNotDefinedErr: Label 'You must choose a valid export format for the bank account. Format %1 is not correctly defined.', Comment = '%1 = Data Exch. Def. Code';
        DataExchLineDefNotFoundErr: Label 'The %1 export format does not support the Payment Method Code %2.', Comment = '%1=Data Exch. Def. Name;%2=Data Exch. Line Def. Code';

    /// <summary>
    /// Creates a new data exchange record for payment export.
    /// </summary>
    /// <param name="DataExch">Data exchange record to be created</param>
    /// <param name="BankAccountCode">Bank account code for export format lookup</param>
    procedure CreateDataExch(var DataExch: Record "Data Exch."; BankAccountCode: Code[20])
    var
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        BankAccount.Get(BankAccountCode);
        BankAccount.TestField("Payment Export Format");
        BankExportImportSetup.Get(BankAccount."Payment Export Format");
        BankExportImportSetup.TestField("Data Exch. Def. Code");
        DataExch.Init();
        DataExch."Data Exch. Def Code" := BankExportImportSetup."Data Exch. Def. Code";
        DataExch.Insert(true);
    end;

    /// <summary>
    /// Creates payment lines in the data exchange from payment export data.
    /// </summary>
    /// <param name="PaymentExportData">Payment export data to process</param>
    procedure CreatePaymentLines(var PaymentExportData: Record "Payment Export Data")
    var
        BankAccount: Record "Bank Account";
        DataExch: Record "Data Exch.";
        PaymentExportDataRecRef: RecordRef;
    begin
        BankAccount.Get(PaymentExportData."Sender Bank Account Code");
        PaymentExportData."Sender Bank Account No." :=
          CopyStr(BankAccount.GetBankAccountNo(), 1, MaxStrLen(PaymentExportData."Sender Bank Account No."));
        PaymentExportData.Modify();

        DataExch.Get(PaymentExportData."Data Exch Entry No.");
        PaymentExportDataRecRef.GetTable(PaymentExportData);
        ProcessColumnMapping(DataExch, PaymentExportDataRecRef,
          PaymentExportData."Line No.", PaymentExportData."Data Exch. Line Def Code", PaymentExportDataRecRef.Number);
    end;

    /// <summary>
    /// Processes column mapping for payment export data exchange.
    /// </summary>
    /// <param name="DataExch">Data exchange record</param>
    /// <param name="RecRef">Record reference containing source data</param>
    /// <param name="LineNo">Line number in the data exchange</param>
    /// <param name="DataExchLineDefCode">Data exchange line definition code</param>
    /// <param name="TableID">Table ID of the source record</param>
    procedure ProcessColumnMapping(DataExch: Record "Data Exch."; RecRef: RecordRef; LineNo: Integer; DataExchLineDefCode: Code[20]; TableID: Integer)
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
        IsHandled: Boolean;
    begin
        if not DataExchDef.Get(DataExch."Data Exch. Def Code") then
            Error(FormatNotDefinedErr, DataExch."Data Exch. Def Code");

        PrepopulateColumns(DataExchDef, DataExchLineDefCode, DataExch."Entry No.", LineNo);

        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchLineDefCode);
        DataExchFieldMapping.SetRange("Table ID", TableID);
        DataExchFieldMapping.FindSet();

        repeat
            DataExchColumnDef.Get(DataExchDef.Code, DataExchLineDefCode, DataExchFieldMapping."Column No.");

            if DataExchFieldMapping."Use Default Value" then
                ValueAsString := DataExchFieldMapping."Default Value"
            else begin
                FieldRef := RecRef.Field(DataExchFieldMapping."Field ID");
                if FieldRef.Class = FieldRef.Class::FlowField then
                    FieldRef.CalcField();
                CheckOptional(DataExchFieldMapping.Optional, FieldRef);
                CastToDestinationType(ValueAsDestType, FieldRef.Value, DataExchColumnDef, DataExchFieldMapping.Multiplier);
                IsHandled := false;
                OnOnProcessColumnMappingOnBeforeFormatToText(ValueAsString, ValueAsDestType, DataExchDef, DataExchColumnDef, IsHandled);
                if not IsHandled then
                    ValueAsString := FormatToText(ValueAsDestType, DataExchDef, DataExchColumnDef);

                if TransformationRule.Get(DataExchFieldMapping."Transformation Rule") then
                    ValueAsString := CopyStr(TransformationRule.TransformText(ValueAsString), 1, 250);

                if DataExchColumnDef."Text Padding Required" and (DataExchColumnDef."Pad Character" <> '') and (not DataExchColumnDef."Blank Zero") then
                    ValueAsString :=
                        StringConversionManagement.GetPaddedString(
                            ValueAsString,
                            DataExchColumnDef.Length,
                            DataExchColumnDef."Pad Character",
                            DataExchColumnDef.Justification);
            end;

            OnProcessColumnMappingOnBeforeCheckLength(ValueAsString, DataExchFieldMapping, DataExchColumnDef);
            CheckLength(ValueAsString, RecRef.Field(DataExchFieldMapping."Field ID"), DataExchDef, DataExchColumnDef);

            DataExchField.Get(DataExch."Entry No.", LineNo, DataExchFieldMapping."Column No.");
            DataExchField.Value := ValueAsString;
            DataExchField.Modify();
        until DataExchFieldMapping.Next() = 0;
    end;

    procedure ProcessColumnMapping(var DataExch: Record "Data Exch."; RecRef: RecordRef; var DataExchFlowFieldGrBuff: Record "Data Exch. FlowField Gr. Buff."; LineNo: Integer; DataExchLineDefCode: Code[20]; TableID: Integer)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchField: Record "Data Exch. Field";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        TransformationRule: Record "Transformation Rule";
        StringConversionManagement: Codeunit StringConversionManagement;
        FieldRef: FieldRef;
        ValueAsDestType: Variant;
        ValueAsString: Text[250];
    begin
        if not DataExchDef.Get(DataExch."Data Exch. Def Code") then
            Error(FormatNotDefinedErr, DataExch."Data Exch. Def Code");

        PrepopulateColumns(DataExchDef, DataExchLineDefCode, DataExch."Entry No.", LineNo);

        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", DataExchLineDefCode);
        DataExchFieldMapping.SetRange("Table ID", TableID);
        DataExchFieldMapping.FindSet();

        repeat
            DataExchColumnDef.Get(DataExchDef.Code, DataExchLineDefCode, DataExchFieldMapping."Column No.");

            if DataExchFieldMapping."Use Default Value" then
                ValueAsString := DataExchFieldMapping."Default Value"
            else begin
                FieldRef := RecRef.Field(DataExchFieldMapping."Field ID");
                if FieldRef.Class = FieldRef.Class::FlowField then
                    if DataExchFlowFieldGrBuff.Get(RecRef.RecordId, FieldRef.Number) then
                        FieldRef.Value := DataExchFlowFieldGrBuff.Value
                    else
                        FieldRef.CalcField();

                CheckOptional(DataExchFieldMapping.Optional, FieldRef);
                CastToDestinationType(ValueAsDestType, FieldRef.Value, DataExchColumnDef, DataExchFieldMapping.Multiplier);
                ValueAsString := FormatToText(ValueAsDestType, DataExchDef, DataExchColumnDef);

                if TransformationRule.Get(DataExchFieldMapping."Transformation Rule") then
                    ValueAsString := CopyStr(TransformationRule.TransformText(ValueAsString), 1, 250);

                if DataExchColumnDef."Text Padding Required" and (DataExchColumnDef."Pad Character" <> '') and (not DataExchColumnDef."Blank Zero") then
                    ValueAsString :=
                        StringConversionManagement.GetPaddedString(
                            ValueAsString,
                            DataExchColumnDef.Length,
                            DataExchColumnDef."Pad Character",
                            DataExchColumnDef.Justification);
            end;

            OnProcessColumnMappingOnBeforeCheckLength(ValueAsString, DataExchFieldMapping, DataExchColumnDef);
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
        if DataExchDef."File Type" in
           [DataExchDef."File Type"::"Fixed Text",
            DataExchDef."File Type"::Xml,
            DataExchDef."File Type"::Json]
        then begin
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
    var
        ResultText: Text[250];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFormatToText(ValueToFormat, DataExchDef, DataExchColumnDef, ResultText, IsHandled);
        if IsHandled then
            exit(ResultText);

        if (Format(ValueToFormat) = '0') and (DataExchColumnDef."Blank Zero") then
            exit('');

        if DataExchColumnDef."Data Format" <> '' then
            exit(Format(ValueToFormat, 0, DataExchColumnDef."Data Format"));

        if DataExchDef."File Type" in [DataExchDef."File Type"::Xml,
                                       DataExchDef."File Type"::Json]
        then
            exit(Format(ValueToFormat, 0, 9));

        if (DataExchDef."File Type" = DataExchDef."File Type"::"Fixed Text") and
           (DataExchColumnDef."Data Type" = DataExchColumnDef."Data Type"::Text)
        then
            exit(Format(ValueToFormat, 0, StrSubstNo('<Text,%1>', DataExchColumnDef.Length)));

        exit(Format(ValueToFormat));
    end;

    local procedure CheckLength(Value: Text; FieldRef: FieldRef; DataExchDef: Record "Data Exch. Def"; DataExchColumnDef: Record "Data Exch. Column Def")
    var
        DataExchDefCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLength(Value, FieldRef, DataExchDef, DataExchColumnDef, IsHandled);
        if IsHandled then
            exit;

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
    procedure ExportToFile(EntryNo: Integer)
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
    begin
        DataExch.Get(EntryNo);
        DataExchDef.Get(DataExch."Data Exch. Def Code");
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchDef.TestField("Reading/Writing XMLport");
        if not SilentServerMode then
            XMLPORT.Run(DataExchDef."Reading/Writing XMLport", false, false, DataExchField)
        else
            ExportToServerTempFile(DataExchDef."Reading/Writing XMLport", DataExchField);

        DataExchField.DeleteAll();
        DataExch.Delete();
    end;

    procedure EnableExportToServerTempFile(NewMode: Boolean; NewExtension: Text[3])
    begin
        SilentServerMode := NewMode;
        ServerFileExtension := NewExtension;
    end;

    local procedure ExportToServerTempFile(XMLPortID: Integer; var DataExchField: Record "Data Exch. Field")
    var
        FileManagement: Codeunit "File Management";
        ExportFile: File;
        OutStream: OutStream;
    begin
        ServerFileName := FileManagement.ServerTempFileName(ServerFileExtension);

        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        ExportFile.Create(ServerFileName);
        ExportFile.CreateOutStream(OutStream);
        XMLPORT.Export(XMLPortID, OutStream, DataExchField);
        ExportFile.Close();
    end;

    procedure GetServerTempFileName(): Text[1024]
    begin
        exit(ServerFileName);
    end;

    /// <summary>
    /// Integration event raised before checking the length of a mapped value during payment export processing.
    /// Enables custom length validation logic for export field values.
    /// </summary>
    /// <param name="ValueAsString">The string value to validate</param>
    /// <param name="DataExchFieldMapping">Field mapping configuration for the export</param>
    /// <param name="DataExchColumnDef">Column definition for the export field</param>
    [IntegrationEvent(false, false)]
    local procedure OnProcessColumnMappingOnBeforeCheckLength(var ValueAsString: Text[250]; DataExchFieldMapping: Record "Data Exch. Field Mapping"; DataExchColumnDef: Record "Data Exch. Column Def")
    begin
    end;

    /// <summary>
    /// Integration event raised before formatting a value to text during column mapping in payment export.
    /// Enables custom text formatting logic for export values.
    /// </summary>
    /// <param name="ValueAsString">The string value being formatted</param>
    /// <param name="ValueAsDestType">The value in destination data type</param>
    /// <param name="DataExchDef">Data exchange definition for the export</param>
    /// <param name="DataExchColumnDef">Column definition for the export field</param>
    /// <param name="IsHandled">Set to true to skip standard formatting processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnOnProcessColumnMappingOnBeforeFormatToText(var ValueAsString: Text[250]; ValueAsDestType: Variant; DataExchDef: Record "Data Exch. Def"; DataExchColumnDef: Record "Data Exch. Column Def"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before checking the length of an export value against column definition limits.
    /// Enables custom length validation for payment export fields.
    /// </summary>
    /// <param name="Value">The text value to check</param>
    /// <param name="FieldRef">Field reference for the value being checked</param>
    /// <param name="DataExchDef">Data exchange definition for the export</param>
    /// <param name="DataExchColumnDef">Column definition with length constraints</param>
    /// <param name="IsHandled">Set to true to skip standard length validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLength(Value: Text; FieldRef: FieldRef; DataExchDef: Record "Data Exch. Def"; DataExchColumnDef: Record "Data Exch. Column Def"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before formatting a value to text for payment export.
    /// Enables custom formatting logic for export field values.
    /// </summary>
    /// <param name="ValueToFormat">The value to be formatted</param>
    /// <param name="DataExchDef">Data exchange definition for the export</param>
    /// <param name="DataExchColumnDef">Column definition for formatting rules</param>
    /// <param name="ResultText">The formatted text result</param>
    /// <param name="IsHandled">Set to true to skip standard formatting processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFormatToText(ValueToFormat: Variant; DataExchDef: Record "Data Exch. Def"; DataExchColumnDef: Record "Data Exch. Column Def"; var ResultText: Text[250]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before casting a value to its destination data type during payment export.
    /// Enables custom type conversion logic for export values.
    /// </summary>
    /// <param name="DestinationValue">The value after type conversion</param>
    /// <param name="SourceValue">The original source value</param>
    /// <param name="DataExchColumnDef">Column definition with type information</param>
    /// <param name="Multiplier">Multiplier value for numeric conversions</param>
    /// <param name="IsHandled">Set to true to skip standard type conversion</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCastToDestinationType(var DestinationValue: Variant; SourceValue: Variant; DataExchColumnDef: Record "Data Exch. Column Def"; Multiplier: Decimal; var IsHandled: Boolean)
    begin
    end;
}

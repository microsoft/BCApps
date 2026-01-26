// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using System;
using System.IO;
using System.Reflection;
using System.Telemetry;
using System.Text;
using System.Utilities;

report 11015 "Export Business Data"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Export Business Data';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Data Export Record Definition"; "Data Export Record Definition")
        {
            DataItemTableView = sorting("Data Export Code", "Data Exp. Rec. Type Code");
            RequestFilterFields = "Data Export Code", "Data Exp. Rec. Type Code";

            trigger OnAfterGetRecord()
            var
                StartDateTime: DateTime;
            begin
                TestField(Description);
                if "DTD File Name" = '' then
                    Error(DTDFileNotExistsErr);

                CheckRecordDefinition("Data Export Code", "Data Exp. Rec. Type Code");
                StartDateTime := CurrentDateTime;
                InitStreams("Data Export Record Definition");
                CreateZipArchive();

                if GuiAllowed then
                    Window.Update(1, CreatingXMLFileMsg);
                CreateIndexFile("Data Export Record Definition");
                ExportDTDFile("Data Export Record Definition");

                WriteData("Data Export Record Definition");
                SaveBlobDataToZipEntries();

                if GuiAllowed then
                    Window.Update(1, CreatingLogFileMsg);
                CreateLogFile(CurrentDateTime - StartDateTime);

                SaveZipArchive();
                DownloadFiles("Data Export Record Definition");
            end;

            trigger OnPreDataItem()
            begin
                if StartDate = 0D then
                    Error(StartDateErr);

                if EndDate = 0D then
                    Error(EndDateErr);

                if GuiAllowed then
                    Window.Open(TableNameMsg + ProgressBarMsg);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date that the report includes data for.';
                    }
                    field(CloseDate; CloseDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include Closing Date';
                        ToolTip = 'Specifies if the data export must include the closing date for the period.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        AccPeriod: Record "Accounting Period";
    begin
        FillCharsToDelete();

        StartDate := AccPeriod.GetFiscalYearStartDate(WorkDate());
        EndDate := AccPeriod.GetFiscalYearEndDate(WorkDate());
        if BlobMaxSizeThreshold = 0 then
            BlobMaxSizeThreshold := 1800000000; // ~1.7 GB
    end;

    trigger OnPreReport()
    begin
        GLSetup.Get();
    end;

    trigger OnPostReport()
    begin
        FeatureTelemetry.LogUptake('0001Q0O', DataTok, Enum::"Feature Uptake Status"::"Used");
        FeatureTelemetry.LogUsage('0001Q0P', DataTok, 'DACH data export');
    end;

    var
        GLSetup: Record "General Ledger Setup";
        TempDataExportRecordSource: Record "Data Export Record Source" temporary;
        TempBlobZipArchive: Codeunit "Temp Blob";
        TempBlobArray: array[100] of Codeunit "Temp Blob";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        DotNetEncoding: Codeunit DotNet_Encoding;
        DotNetStreamWriterArr: array[100] of Codeunit DotNet_StreamWriter;
        BlobDataApproxSizeArr: array[100] of Integer;
        FileNameArr: array[100] of Text;
        BlobsToExport: Dictionary of [Integer, List of [Integer]];
        ZipArchive: DotNet ZipArchive;
        StartDate: Date;
        EndDate: Date;
        Window: Dialog;
        TotalNoOfRecords: Integer;
        NoOfRecords: Integer;
        NoOfRecordsArr: array[100] of Integer;
        StepValue: Integer;
        NextStep: Integer;
        LastBlobIndex: Integer;
        BlobMaxSizeThreshold: Integer;
        BOMSize: Integer;
        BytesPerChar: Integer;
        CloseDate: Boolean;
        CharsToDelete: Text;
        NewLine: Text[2];
        ClientFileName: Text;
        DataTok: Label 'DACH Data Export', Locked = true;
        ValueWithQuotesTxt: Label '"%1"', Locked = true;
        CreatingXMLFileMsg: Label 'Creating XML File...';
        StartDateErr: Label 'You must enter a starting date.';
        EndDateErr: Label 'You must enter an ending date.';
        DateFilterMsg: Label '%1 to %2.', Comment = '%1, %2 - <01.01.2014> to <31.01.2014>';
        DefineTableRelationErr: Label 'You must define a %1 for table %2.', Comment = '%1 - "Data Export Table Relation", %2 - table name';
        DTDFileNotExistsErr: Label 'The DTD file does not exist.';
        NoticeMsg: Label 'Important Notice:';
        PrimaryKeyField1Msg: Label 'The %1 for table %2 that you defined contains primary key fields that are not specified at the top of the list.', Comment = '%1 - "Data Export Record Field", %2 - table name';
        PrimaryKeyField2Msg: Label 'In this case, the order of the fields that you want to export will not match the order that is stated in the .xml file.';
        PrimaryKeyField3Msg: Label 'If you want to use the exported data for digital audit purposes, make sure that primary key fields are specified first, followed by ordinary fields.';
        PrimaryKeyField4Msg: Label 'Do you want to continue?';
        TableNameMsg: Label 'Table Name:       #1#################\', Comment = '#1 - table name';
        CreatingLogFileMsg: Label 'Creating Log File...';
        DurationMsg: Label 'Duration: %1.', Comment = '%1 - how long the report runs';
        LogEntryMsg: Label 'For table %1, %2 data records were exported, and file %3 was created.', Comment = '%1 - table name, %2 - number of exported records, %3 - file name to which records were exported';
        LogFileNameTxt: Label 'Log.txt';
        IndexFileNameTxt: Label 'index.xml';
        NoOfDefinedTablesMsg: Label 'Number of defined tables: %1.', Comment = '%1 - number of tables to be exported';
        NoOfEmptyTablesMsg: Label 'Number of empty tables: %1.', Comment = '%1 - number of empty tables';
        ProgressBarMsg: Label 'Progress:         @5@@@@@@@@@@@@@@@@@\';
        NoExportFieldsErr: Label 'Data cannot be exported because no fields have been defined for one or more tables in the %1 data export.', Comment = '%1 - data export code';
        ExceedNoOfStreamsErr: Label '%2 cannot write to more than %1 files.', Comment = '%1 - number of files to zip, %2 - product name';

    [Scope('OnPrem')]
    procedure InitializeRequest(FromDate: Date; ToDate: Date)
    begin
        StartDate := FromDate;
        EndDate := ToDate;
        CloseDate := false;
    end;

    procedure InitializeBlobMaxSizeThreshold(NewBlobMaxSizeThreshold: Integer)
    begin
        BlobMaxSizeThreshold := NewBlobMaxSizeThreshold;
    end;

    local procedure InitStreams(DataExportRecordDefinition: Record "Data Export Record Definition")
    var
        DataExportRecSource: Record "Data Export Record Source";
        DotNetStreamWriter: Codeunit DotNet_StreamWriter;
        BlobOutStream: OutStream;
        BlobIndexes: List of [Integer];
        MaxNumOfStreams: Integer;
        BlobIndex: Integer;
    begin
        Clear(NoOfRecordsArr);
        Clear(TempBlobArray);
        Clear(DotNetStreamWriterArr);
        Clear(BlobsToExport);
        Clear(FileNameArr);

        DotNetEncoding.Encoding(GetCodePageByEncodingName(Format(DataExportRecordDefinition."File Encoding")));
        BytesPerChar := 1;
        if DotNetEncoding.CodePage() = 1200 then        // UTF-16
            BytesPerChar := 2;

        DataExportRecSource.SetRange("Data Export Code", DataExportRecordDefinition."Data Export Code");
        DataExportRecSource.SetRange("Data Exp. Rec. Type Code", DataExportRecordDefinition."Data Exp. Rec. Type Code");
        MaxNumOfStreams := ArrayLen(DotNetStreamWriterArr);
        if DataExportRecSource.Count() > MaxNumOfStreams then
            Error(ExceedNoOfStreamsErr, MaxNumOfStreams, ProductName.Full());
        BlobIndex := 0;
        if DataExportRecSource.FindSet() then
            repeat
                DataExportRecSource.TestField("Export File Name");
                DataExportRecSource.Validate("Table Filter");

                DataExportRecSource.CalcFields("Table Name");
                if GuiAllowed then
                    Window.Update(1, DataExportRecSource."Table Name");

                BlobIndex += 1;

                Clear(BlobOutStream);
                Clear(DotNetStreamWriter);

                TempBlobArray[BlobIndex].CreateOutStream(BlobOutStream);
                DotNetStreamWriter.StreamWriter(BlobOutStream, DotNetEncoding);
                DotNetStreamWriterArr[BlobIndex] := DotNetStreamWriter;

                // get BOM size in bytes for UTF-7/8/16 encoding to skip them during archiving
                DotNetStreamWriterArr[BlobIndex].Flush();
                BOMSize := TempBlobArray[BlobIndex].Length();

                FileNameArr[BlobIndex] := DataExportRecSource."Export File Name";

                Clear(BlobIndexes);
                BlobIndexes.Add(BlobIndex);
                BlobsToExport.Add(DataExportRecSource."Line No.", BlobIndexes);

                InsertFilesExportBuffer(DataExportRecSource);

                TotalNoOfRecords += CountRecords(TempDataExportRecordSource);
            until DataExportRecSource.Next() = 0;
        LastBlobIndex := BlobIndex;
        StepValue := TotalNoOfRecords div 100;
        if GuiAllowed then
            Window.Update(1, '');
    end;

    local procedure CountRecords(DataExportRecordSource: Record "Data Export Record Source") TotalRecords: Integer
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(DataExportRecordSource."Table No.");
        RecordRef.CurrentKeyIndex(DataExportRecordSource."Key No.");
        SetPeriodFilter(DataExportRecordSource."Period Field No.", RecordRef);
        TotalRecords := RecordRef.Count();
        RecordRef.Close();
    end;

    local procedure InsertFilesExportBuffer(DataExportRecordSource: Record "Data Export Record Source")
    begin
        TempDataExportRecordSource := DataExportRecordSource;
        if TempDataExportRecordSource."Key No." = 0 then
            TempDataExportRecordSource."Key No." := 1;
        TempDataExportRecordSource.Insert();
    end;

    local procedure CreateIndexFile(DataExportRecDefinition: Record "Data Export Record Definition")
    var
        TempBlob: Codeunit "Temp Blob";
        DataExportManagement: Codeunit "Data Export Management";
        FileInStream: InStream;
        FileOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(FileOutStream);
        DataExportManagement.CreateIndexXmlStream(
            TempDataExportRecordSource, FileOutStream, DataExportRecDefinition.Description, StartDate, EndDate,
            DataExportRecDefinition."DTD File Name", Format(DataExportRecDefinition."File Encoding"));
        TempBlob.CreateInStream(FileInStream);
        AddZipEntry(FileInStream, IndexFileNameTxt);
    end;

    local procedure ExportDTDFile(DataExportRecDefinition: Record "Data Export Record Definition")
    var
        DTDFileInStream: InStream;
    begin
        DataExportRecDefinition.CalcFields("DTD File");
        DataExportRecDefinition."DTD File".CreateInStream(DTDFileInStream);
        AddZipEntry(DTDFileInStream, DataExportRecDefinition."DTD File Name");
    end;

    local procedure CreateLogFile(Duration: Duration)
    var
        TempBlob: Codeunit "Temp Blob";
        FileReadStream: InStream;
        FileWriteStream: OutStream;
        NoOfDefinedTables: Integer;
        NoOfEmptyTables: Integer;
        FirstBlobIndex: Integer;
    begin
        TempBlob.CreateOutStream(FileWriteStream);
        WriteLineToOutStream(FileWriteStream, StrSubstNo(DateFilterMsg, Format(StartDate), Format(CalcEndDate(EndDate))));
        WriteLineToOutStream(FileWriteStream, Format(Today));
        TempDataExportRecordSource.Reset();
        if TempDataExportRecordSource.FindSet() then begin
            NoOfDefinedTables := 0;
            NoOfEmptyTables := 0;
            WriteLineToOutStream(FileWriteStream, TempDataExportRecordSource."Data Export Code" + ';' + TempDataExportRecordSource."Data Exp. Rec. Type Code");
            repeat
                FirstBlobIndex := GetFirstBlobIndex(TempDataExportRecordSource."Line No.");
                if NoOfRecordsArr[FirstBlobIndex] = 0 then
                    NoOfEmptyTables += 1
                else
                    NoOfDefinedTables += 1;
                TempDataExportRecordSource.CalcFields("Table Name");
                WriteLineToOutStream(FileWriteStream, StrSubstNo(LogEntryMsg, TempDataExportRecordSource."Table Name", NoOfRecordsArr[FirstBlobIndex], TempDataExportRecordSource."Export File Name"));
            until TempDataExportRecordSource.Next() = 0;
        end;
        WriteLineToOutStream(FileWriteStream, StrSubstNo(NoOfDefinedTablesMsg, NoOfDefinedTables));
        WriteLineToOutStream(FileWriteStream, StrSubstNo(NoOfEmptyTablesMsg, NoOfEmptyTables));
        WriteLineToOutStream(FileWriteStream, StrSubstNo(DurationMsg, Duration));
        TempBlob.CreateInStream(FileReadStream);
        AddZipEntry(FileReadStream, LogFileNameTxt);
    end;

    local procedure WriteData(DataExportRecordDefinition: Record "Data Export Record Definition")
    var
        CurrTempDataExportRecordSource: Record "Data Export Record Source";
        RecRef: RecordRef;
    begin
        TempDataExportRecordSource.Reset();
        TempDataExportRecordSource.SetRange("Data Export Code", DataExportRecordDefinition."Data Export Code");
        TempDataExportRecordSource.SetRange("Data Exp. Rec. Type Code", DataExportRecordDefinition."Data Exp. Rec. Type Code");
        TempDataExportRecordSource.SetRange("Relation To Line No.", 0);
        if TempDataExportRecordSource.FindSet() then
            repeat
                CurrTempDataExportRecordSource.Copy(TempDataExportRecordSource);
                RecRef.Open(TempDataExportRecordSource."Table No.");
                ApplyTableFilter(TempDataExportRecordSource, RecRef);
                WriteTable(TempDataExportRecordSource, RecRef);
                RecRef.Close();
                TempDataExportRecordSource.Copy(CurrTempDataExportRecordSource);
            until TempDataExportRecordSource.Next() = 0;
    end;

    local procedure WriteTable(DataExportRecordSource: Record "Data Export Record Source"; var RecRef: RecordRef)
    var
        RecRefToExport: RecordRef;
        CurrBlobIndex: Integer;
        FirstBlobIndex: Integer;
    begin
        if RecRef.FindSet() then begin
            CurrBlobIndex := GetCurrentBlobIndex(DataExportRecordSource."Line No.");
            FirstBlobIndex := GetFirstBlobIndex(DataExportRecordSource."Line No.");
            NoOfRecordsArr[FirstBlobIndex] += RecRef.Count();
            if GuiAllowed then
                Window.Update(1, RecRef.Caption);
            repeat
                RecRefToExport := RecRef.Duplicate();
                WriteRecord(DataExportRecordSource, RecRefToExport, CurrBlobIndex);
                UpdateProgressBar();
                WriteRelatedRecords(DataExportRecordSource, RecRefToExport);
            until RecRef.Next() = 0;
        end;
    end;

    local procedure UpdateProgressBar()
    begin
        NoOfRecords := NoOfRecords + 1;
        if NoOfRecords >= NextStep then begin
            if TotalNoOfRecords <> 0 then
                if GuiAllowed then
                    Window.Update(5, Round(NoOfRecords / TotalNoOfRecords * 10000, 1));
            NextStep := NextStep + StepValue;
        end;
    end;

    local procedure ApplyTableFilter(DataExportRecordSource: Record "Data Export Record Source"; var RecRef: RecordRef)
    var
        TableFilterPage: Page "Table Filter";
        TableFilterText: Text;
    begin
        TableFilterText := Format(DataExportRecordSource."Table Filter");
        if TableFilterText <> '' then begin
            TableFilterPage.SetSourceTable(TableFilterText, DataExportRecordSource."Table No.", DataExportRecordSource."Table Name");
            RecRef.SetView(TableFilterPage.GetViewFilter());
            SetFlowFilterDateFields(DataExportRecordSource, RecRef);
        end;
        RecRef.CurrentKeyIndex(DataExportRecordSource."Key No.");
        SetPeriodFilter(DataExportRecordSource."Period Field No.", RecRef);
    end;

    local procedure WriteRelatedRecords(var ParentDataExportRecordSource: Record "Data Export Record Source"; ParentRecRef: RecordRef)
    var
        DataExportTableRelation: Record "Data Export Table Relation";
        RelatedRecRef: RecordRef;
        RelatedFieldRef: FieldRef;
        ParentFieldRef: FieldRef;
    begin
        TempDataExportRecordSource.Reset();
        TempDataExportRecordSource.SetRange("Data Export Code", ParentDataExportRecordSource."Data Export Code");
        TempDataExportRecordSource.SetRange("Data Exp. Rec. Type Code", ParentDataExportRecordSource."Data Exp. Rec. Type Code");
        TempDataExportRecordSource.SetRange("Relation To Line No.", ParentDataExportRecordSource."Line No.");
        if TempDataExportRecordSource.FindSet() then begin
            DataExportTableRelation.Reset();
            DataExportTableRelation.SetRange("Data Export Code", TempDataExportRecordSource."Data Export Code");
            DataExportTableRelation.SetRange("Data Exp. Rec. Type Code", TempDataExportRecordSource."Data Exp. Rec. Type Code");
            DataExportTableRelation.SetRange("From Table No.", ParentDataExportRecordSource."Table No.");
            repeat
                DataExportTableRelation.SetRange("To Table No.", TempDataExportRecordSource."Table No.");
                if DataExportTableRelation.FindSet() then begin
                    RelatedRecRef.Open(TempDataExportRecordSource."Table No.");
                    ApplyTableFilter(TempDataExportRecordSource, RelatedRecRef);
                    repeat
                        ParentFieldRef := ParentRecRef.Field(DataExportTableRelation."From Field No.");
                        RelatedFieldRef := RelatedRecRef.Field(DataExportTableRelation."To Field No.");
                        RelatedFieldRef.SetRange(ParentFieldRef.Value);
                    until DataExportTableRelation.Next() = 0;

                    WriteTable(TempDataExportRecordSource, RelatedRecRef);

                    TempDataExportRecordSource.SetRange("Relation To Line No.", ParentDataExportRecordSource."Line No.");

                    RelatedRecRef.Close();
                end else begin
                    TempDataExportRecordSource.CalcFields("Table Name");
                    Error(DefineTableRelationErr, DataExportTableRelation.TableCaption(), TempDataExportRecordSource."Table Name");
                end;
            until TempDataExportRecordSource.Next() = 0;
        end;
    end;

    local procedure SetPeriodFilter(PeriodFieldNo: Integer; var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
    begin
        if PeriodFieldNo <> 0 then begin
            FieldRef := RecRef.Field(PeriodFieldNo);
            FieldRef.SetRange(StartDate, CalcEndDate(EndDate));
        end;
    end;

    local procedure WriteRecord(var DataExportRecordSource: Record "Data Export Record Source"; var RecRef: RecordRef; var CurrBlobIndex: Integer)
    var
        DataExportRecordField: Record "Data Export Record Field";
        RecordText: Text;
        FieldValue: Text;
    begin
        if FindFields(DataExportRecordField, DataExportRecordSource) then begin
            if IsCurrentBlobFull(CurrBlobIndex) then
                CurrBlobIndex := InitNewTempBlob(DataExportRecordSource."Line No.", CurrBlobIndex);
            repeat
                FieldValue :=
                  GetDataExportRecFieldValue(
                    DataExportRecordField, DataExportRecordSource."Date Filter Field No.", RecRef);
                RecordText += FieldValue + ';';
            until DataExportRecordField.Next() = 0;
            RecordText := CopyStr(RecordText, 1, StrLen(RecordText) - 1);
            DotNetStreamWriterArr[CurrBlobIndex].WriteLine(RecordText);
            UpdateBlobDataSize(CurrBlobIndex, StrLen(RecordText));
        end else
            Error(NoExportFieldsErr, DataExportRecordSource."Data Export Code");
    end;

    local procedure FormatField2String(var FieldRef: FieldRef; DataExportRecordField: Record "Data Export Record Field") FieldValueText: Text
    var
        OptionNo: Integer;
    begin
        case DataExportRecordField."Field Type" of
            DataExportRecordField."Field Type"::Option:
                begin
                    OptionNo := FieldRef.Value();
                    if OptionNo <= GetMaxOptionIndex(FieldRef.OptionCaption) then
                        FieldValueText := SelectStr(OptionNo + 1, Format(FieldRef.OptionCaption))
                    else
                        FieldValueText := Format(OptionNo);
                end;
            DataExportRecordField."Field Type"::Decimal:
                FieldValueText := Format(FieldRef.Value, 0, '<Precision,' + GLSetup."Amount Decimal Places" + '><Standard Format,0>');
            DataExportRecordField."Field Type"::Date:
                FieldValueText := Format(FieldRef.Value, 10, '<day,2>.<month,2>.<year4>');
            else
                FieldValueText := Format(FieldRef.Value);
        end;
        if DataExportRecordField."Field Type" in [DataExportRecordField."Field Type"::Boolean, DataExportRecordField."Field Type"::Code, DataExportRecordField."Field Type"::Option, DataExportRecordField."Field Type"::Text] then
            FieldValueText := StrSubstNo(ValueWithQuotesTxt, ConvertString(FieldValueText));
    end;

    local procedure ConvertString(String: Text) NewString: Text
    begin
        NewString := DelChr(String, '=', CharsToDelete);
    end;

    local procedure CheckRecordDefinition(ExportCode: Code[10]; RecordCode: Code[10])
    var
        DataExportRecordSource: Record "Data Export Record Source";
        DataExportRecordField: Record "Data Export Record Field";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        ActiveKeyFound: Boolean;
        KeyFieldFound: Boolean;
        NonKeyFieldFound: Boolean;
        FieldMismatch: Boolean;
        i: Integer;
        j: Integer;
    begin
        DataExportRecordSource.Reset();
        DataExportRecordSource.SetRange("Data Export Code", ExportCode);
        DataExportRecordSource.SetRange("Data Exp. Rec. Type Code", RecordCode);
        if DataExportRecordSource.FindSet() then
            repeat
                RecRef.Open(DataExportRecordSource."Table No.");
                i := 0;
                ActiveKeyFound := false;
                NonKeyFieldFound := false;
                FieldMismatch := false;
                repeat
                    i := i + 1;
                    KeyRef := RecRef.KeyIndex(i);
                    if KeyRef.Active then
                        ActiveKeyFound := true;
                until (i >= RecRef.KeyCount) or ActiveKeyFound;
                if ActiveKeyFound then
                    if FindFields(DataExportRecordField, DataExportRecordSource) then
                        repeat
                            KeyFieldFound := false;
                            for j := 1 to KeyRef.FieldCount do begin
                                FieldRef := KeyRef.FieldIndex(j);
                                if DataExportRecordField."Field No." = FieldRef.Number then
                                    KeyFieldFound := true;
                            end;
                            if not KeyFieldFound then
                                NonKeyFieldFound := true;
                            if NonKeyFieldFound and KeyFieldFound then begin
                                FieldMismatch := true;
                                DataExportRecordField.CalcFields("Table Name");
                                if GuiAllowed then
                                    if not Confirm(NoticeMsg + '\' + '\' +
                                         PrimaryKeyField1Msg + ' ' +
                                         PrimaryKeyField2Msg + ' ' +
                                         PrimaryKeyField3Msg + '\' + '\' +
                                         PrimaryKeyField4Msg,
                                         true,
                                         DataExportRecordField.TableCaption(),
                                         DataExportRecordField."Table Name")
                                    then
                                        Error('');
                            end;
                        until FieldMismatch or (DataExportRecordField.Next() = 0);
                RecRef.Close();
            until FieldMismatch or (DataExportRecordSource.Next() = 0);
    end;

    [Scope('OnPrem')]
    procedure FindFields(var DataExportRecordField: Record "Data Export Record Field"; var DataExportRecordSource: Record "Data Export Record Source"): Boolean
    begin
        DataExportRecordField.SetRange("Data Export Code", DataExportRecordSource."Data Export Code");
        DataExportRecordField.SetRange("Data Exp. Rec. Type Code", DataExportRecordSource."Data Exp. Rec. Type Code");
        DataExportRecordField.SetRange("Source Line No.", DataExportRecordSource."Line No.");
        exit(DataExportRecordField.FindSet());
    end;

    local procedure SetFlowFilterDateFields(DataExportRecordSource: Record "Data Export Record Source"; var RecRef: RecordRef)
    var
        DataExportRecordField: Record "Data Export Record Field";
    begin
        if DataExportRecordSource."Date Filter Handling" <> DataExportRecordSource."Date Filter Handling"::" " then begin
            DataExportRecordField.Init();
            DataExportRecordField."Table No." := DataExportRecordSource."Table No.";
            DataExportRecordField."Date Filter Handling" := DataExportRecordSource."Date Filter Handling";
            SetFlowFilterDateField(DataExportRecordField, DataExportRecordSource."Date Filter Field No.", RecRef);
        end;
    end;

    local procedure SetFlowFilterDateField(var DataExportRecordField: Record "Data Export Record Field"; DateFilterFieldNo: Integer; var RecRef: RecordRef)
    var
        "Field": Record "Field";
    begin
        if DateFilterFieldNo > 0 then
            SetFlowFilter(DateFilterFieldNo, DataExportRecordField."Date Filter Handling", RecRef)
        else begin
            Field.Reset();
            Field.SetRange(TableNo, DataExportRecordField."Table No.");
            Field.SetRange(Type, Field.Type::Date);
            Field.SetRange(Class, Field.Class::FlowFilter);
            Field.SetRange(Enabled, true);
            Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
            if Field.FindSet() then
                repeat
                    SetFlowFilter(Field."No.", DataExportRecordField."Date Filter Handling", RecRef)
                until Field.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetDataExportRecFieldValue(var DataExportRecordField: Record "Data Export Record Field"; FlowFilterFieldNo: Integer; RecRef: RecordRef) FieldValueText: Text
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(DataExportRecordField."Field No.");
        if DataExportRecordField."Field Class" = DataExportRecordField."Field Class"::FlowField then begin
            SetFlowFilterDateField(DataExportRecordField, FlowFilterFieldNo, RecRef);
            FieldRef := RecRef.Field(DataExportRecordField."Field No.");
            FieldRef.CalcField();
        end;
        FieldValueText := FormatField2String(FieldRef, DataExportRecordField);
    end;

    [Scope('OnPrem')]
    procedure SetFlowFilter(FlowFilterFieldNo: Integer; DateFilterHandling: Option; var RecRef: RecordRef)
    var
        DataExportRecField: Record "Data Export Record Field";
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(FlowFilterFieldNo);
        case DateFilterHandling of
            DataExportRecField."Date Filter Handling"::" ":
                FieldRef.SetRange(); // remove filter
            DataExportRecField."Date Filter Handling"::Period:
                FieldRef.SetRange(StartDate, CalcEndDate(EndDate));
            DataExportRecField."Date Filter Handling"::"End Date Only":
                FieldRef.SetRange(0D, CalcEndDate(EndDate));
            DataExportRecField."Date Filter Handling"::"Start Date Only":
                FieldRef.SetRange(0D, ClosingDate(StartDate - 1));
        end;
    end;

    [Scope('OnPrem')]
    procedure SetClientFileName(NewClientFileName: Text)
    begin
        ClientFileName := NewClientFileName;
    end;

    local procedure CalcEndDate(Date: Date): Date
    begin
        if CloseDate then
            exit(ClosingDate(Date));
        exit(Date);
    end;

    local procedure FillCharsToDelete()
    var
        i: Integer;
        S: Text;
    begin
        NewLine[1] := 13;
        NewLine[2] := 10;

        CharsToDelete := NewLine;
        CharsToDelete[3] := 34;
        CharsToDelete[4] := 39;
        for i := 128 to 255 do begin
            S[1] := i;
            if not (S in ['Ä', 'ä', 'Ö', 'ö', 'Ü', 'ü', 'ß']) then
                CharsToDelete := CharsToDelete + S;
        end;
    end;

    local procedure SaveBlobDataToZipEntries()
    var
        ZipEntry: DotNet ZipArchiveEntry;
        BlobInStream: InStream;
        ZipEntryStream: DotNet Stream;
        FileName: Text;
        DummyBOMByte: Byte;
        BlobIndexes: List of [Integer];
        BlobIndex: Integer;
        RecSourceLineNo: Integer;
        i: Integer;
    begin
        foreach RecSourceLineNo in BlobsToExport.Keys() do begin
            BlobIndexes := BlobsToExport.Get(RecSourceLineNo);
            FileName := FileNameArr[BlobIndexes.Get(1)];
            ZipEntry := ZipArchive.CreateEntry(FileName);
            ZipEntryStream := ZipEntry.Open();
            foreach BlobIndex in BlobIndexes do begin
                DotNetStreamWriterArr[BlobIndex].Dispose();
                TempBlobArray[BlobIndex].CreateInStream(BlobInStream);
                for i := 1 to BOMSize do
                    BlobInStream.Read(DummyBOMByte);        // skip BOM bytes
                CopyStream(ZipEntryStream, BlobInStream);
            end;
            ZipEntryStream.Dispose();       // dispose stream to close ZipEntry
        end;
    end;

    local procedure DownloadFiles(DataExportRecordDefinition: Record "Data Export Record Definition")
    var
        FileMgt: Codeunit "File Management";
        ZipArchiveInStream: InStream;
        ZipFileNameOnServer: Text;
        ZipFileName: Text;
    begin
        TempBlobZipArchive.CreateInStream(ZipArchiveInStream);
        ZipFileName := DataExportRecordDefinition."Data Exp. Rec. Type Code" + '.zip';
        if ClientFileName <> '' then begin
            ZipFileNameOnServer := FileMgt.InstreamExportToServerFile(ZipArchiveInStream, '.zip');
            FileMgt.DownloadHandler(ZipFileNameOnServer, '', '', '', ClientFileName);
        end else
            FileMgt.DownloadFromStreamHandler(ZipArchiveInStream, '', '', '', ZipFileName);
    end;

    [Scope('OnPrem')]
    procedure GetMaxOptionIndex(InputString: Text): Integer
    begin
        exit(StrLen(DelChr(InputString, '=', DelChr(InputString, '=', ','))));
    end;

    local procedure GetCodePageByEncodingName(EncodingName: Text): Integer
    begin
        case EncodingName of
            'UTF8':
                exit(65001);
            'UTF7':
                exit(65000);
            'UTF16':
                exit(1200);
            'ANSI':
                exit(1252); // Western European (Windows)
            'Macintosh':
                exit(10000);
            'OEM':
                exit(437); // OEM United States
        end;
    end;

    local procedure CreateZipArchive()
    var
        ZipArchiveMode: DotNet ZipArchiveMode;
        CompressedOutStream: OutStream;
    begin
        TempBlobZipArchive.CreateOutStream(CompressedOutStream);
        ZipArchive := ZipArchive.ZipArchive(CompressedOutStream, ZipArchiveMode.Create);
    end;

    local procedure SaveZipArchive()
    begin
        ZipArchive.Dispose();
    end;

    local procedure AddZipEntry(InStreamToAdd: InStream; ZipEntryFileName: Text)
    var
        ZipEntry: DotNet ZipArchiveEntry;
    begin
        ZipEntry := ZipArchive.CreateEntry(ZipEntryFileName);
        CopyStream(ZipEntry.Open(), InStreamToAdd);
    end;

    local procedure GetCurrentBlobIndex(RecSourceLineNo: Integer): Integer
    var
        BlobIndexes: List of [Integer];
    begin
        if BlobsToExport.Get(RecSourceLineNo, BlobIndexes) then
            exit(BlobIndexes.Get(BlobIndexes.Count()));
    end;

    local procedure GetFirstBlobIndex(RecSourceLineNo: Integer): Integer
    var
        BlobIndexes: List of [Integer];
    begin
        if BlobsToExport.Get(RecSourceLineNo, BlobIndexes) then
            exit(BlobIndexes.Get(1));
    end;

    local procedure IsCurrentBlobFull(BlobIndex: Integer): Boolean
    begin
        exit(BlobDataApproxSizeArr[BlobIndex] > BlobMaxSizeThreshold);
    end;

    local procedure InitNewTempBlob(RecSourceLineNo: Integer; CurrBlobIndex: Integer) NewBlobIndex: Integer
    var
        DotNetStreamWriter: Codeunit DotNet_StreamWriter;
        BlobIndexes: List of [Integer];
        BlobOutStream: OutStream;
    begin
        DotNetStreamWriterArr[CurrBlobIndex].Flush();

        LastBlobIndex += 1;
        if LastBlobIndex > ArrayLen(TempBlobArray) then
            Error(ExceedNoOfStreamsErr, ArrayLen(TempBlobArray), ProductName.Full());

        NewBlobIndex := LastBlobIndex;
        TempBlobArray[NewBlobIndex].CreateOutStream(BlobOutStream);
        DotNetStreamWriter.StreamWriter(BlobOutStream, DotNetEncoding);
        DotNetStreamWriterArr[NewBlobIndex] := DotNetStreamWriter;

        if BlobsToExport.Get(RecSourceLineNo, BlobIndexes) then
            BlobIndexes.Add(NewBlobIndex);
    end;

    local procedure UpdateBlobDataSize(BlobIndex: Integer; TextLength: Integer)
    begin
        // we assume that most characters are 2 bytes long for UTF-16 and 1 byte long for other supported encodings
        BlobDataApproxSizeArr[BlobIndex] += BytesPerChar * (TextLength + 2);      // 2 bytes for CR+LF
    end;

    local procedure WriteLineToOutStream(OutStr: OutStream; TextLine: Text)
    begin
        OutStr.WriteText(TextLine);
        OutStr.WriteText();
    end;
}


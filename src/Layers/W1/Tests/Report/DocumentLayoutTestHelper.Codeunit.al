// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 134767 "Document Layout Test Helper"
{
    // Creates real report layouts for document layout (Custom Report Selection) scenarios and records which layout
    // was selected when a report was run for each record, so tests can assert that a customer-specific layout was used.
    EventSubscriberInstance = Manual;

    var
        TempSelectedLayoutNameValueBuffer: Record "Name/Value Buffer" temporary;
        LibraryUtility: Codeunit "Library - Utility";
        LastSelectedLayoutName: Text;
        LayoutNameBeforeSaveAs: Text[250];
        LayoutNameTok: Label 'DocLayoutTest-%1-%2', Locked = true;

    procedure CreateWordLayout(ReportID: Integer; var ReportLayoutList: Record "Report Layout List")
    begin
        CreateLayout(ReportID, ReportLayoutList."Layout Format"::Word, ReportLayoutList);
    end;

    procedure CreateRDLCLayout(ReportID: Integer; var ReportLayoutList: Record "Report Layout List")
    begin
        CreateLayout(ReportID, ReportLayoutList."Layout Format"::RDLC, ReportLayoutList);
    end;

    local procedure CreateLayout(ReportID: Integer; LayoutFormat: Option; var ReportLayoutList: Record "Report Layout List")
    var
        ReportLayoutsImpl: Codeunit "Report Layouts Impl.";
        ExcelSheetConfiguration: Enum "Excel Sheet Configuration";
        LayoutName: Text[250];
        ReturnReportID: Integer;
        ReturnLayoutName: Text;
        EmptyGuid: Guid;
    begin
        LayoutName := CopyStr(StrSubstNo(LayoutNameTok, ReportID, LibraryUtility.GenerateGUID()), 1, MaxStrLen(LayoutName));
        ReportLayoutsImpl.InsertNewLayout(
            ReportID, LayoutName, LayoutName, LayoutFormat, true, true, ExcelSheetConfiguration::Default, ReturnReportID, ReturnLayoutName);

        ReportLayoutList.Get(ReportID, LayoutName, EmptyGuid);
        ReportLayoutsImpl.SetSelectedCompany(CompanyName());
        ReportLayoutsImpl.SetLayoutStatus(ReportLayoutList, Enum::"Report Layout Status"::Approved);
        ReportLayoutList.Get(ReportID, LayoutName, EmptyGuid);
    end;

    procedure DeleteTestLayouts()
    var
        TenantReportLayout: Record "Tenant Report Layout";
    begin
        TenantReportLayout.SetFilter(Name, StrSubstNo(LayoutNameTok, '*', '*'));
        TenantReportLayout.DeleteAll(true);
    end;

    procedure SetDocumentLayout(var CustomReportSelection: Record "Custom Report Selection"; ReportLayoutList: Record "Report Layout List")
    begin
        CustomReportSelection."Email Attachment Layout Name" := ReportLayoutList.Name;
        CustomReportSelection."Email Attachment Layout AppID" := ReportLayoutList."Application ID";
    end;

    procedure ClearRecordedLayouts()
    begin
        TempSelectedLayoutNameValueBuffer.Reset();
        TempSelectedLayoutNameValueBuffer.DeleteAll();
        LastSelectedLayoutName := '';
    end;

    procedure GetLastSelectedLayoutName(): Text
    begin
        exit(LastSelectedLayoutName);
    end;

    procedure IsLayoutUsedFor(RecordNo: Code[20]; LayoutName: Text): Boolean
    begin
        TempSelectedLayoutNameValueBuffer.Reset();
        TempSelectedLayoutNameValueBuffer.SetRange(Name, RecordNo);
        TempSelectedLayoutNameValueBuffer.SetRange(Value, CopyStr(LayoutName, 1, MaxStrLen(TempSelectedLayoutNameValueBuffer.Value)));
        exit(not TempSelectedLayoutNameValueBuffer.IsEmpty());
    end;

    procedure GetReportRunCount(RecordNo: Code[20]): Integer
    begin
        TempSelectedLayoutNameValueBuffer.Reset();
        TempSelectedLayoutNameValueBuffer.SetRange(Name, RecordNo);
        exit(TempSelectedLayoutNameValueBuffer.Count());
    end;

    local procedure RecordSelectedLayout(var DataRecRef: RecordRef)
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        RecordLayoutForRecords(DataRecRef, ReportLayoutSelection.GetTempSelectedLayoutName());
    end;

    local procedure RecordLayoutForRecords(var DataRecRef: RecordRef; SelectedLayoutName: Text[250])
    var
        RecordsRecRef: RecordRef;
        PrimaryKeyRef: KeyRef;
    begin
        LastSelectedLayoutName := SelectedLayoutName;

        // The report runs for every record in the view, so each of them was printed with the selected layout.
        // Records are identified by the last field of their primary key, such as "No." of a customer.
        RecordsRecRef := DataRecRef.Duplicate();
        PrimaryKeyRef := RecordsRecRef.KeyIndex(1);
        TempSelectedLayoutNameValueBuffer.Reset();
        if RecordsRecRef.FindSet() then
            repeat
                TempSelectedLayoutNameValueBuffer.AddNewEntry(
                    CopyStr(Format(PrimaryKeyRef.FieldIndex(PrimaryKeyRef.FieldCount()).Value()), 1, 250), SelectedLayoutName);
            until RecordsRecRef.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Custom Layout Reporting", 'OnBeforePrintReport', '', false, false)]
    local procedure OnBeforePrintReport(var DataRecRef: RecordRef; ReportID: Integer)
    begin
        RecordSelectedLayout(DataRecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Custom Layout Reporting", 'OnBeforeCallReportSaveAs', '', false, false)]
    local procedure OnBeforeCallReportSaveAs(ReportID: Integer; ReportFormatValue: ReportFormat)
    var
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        // The selected layout is consumed by the report run, so capture it before the report is saved
        LayoutNameBeforeSaveAs := ReportLayoutSelection.GetTempSelectedLayoutName();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Custom Layout Reporting", 'OnSaveAsReportOnBeforeFileClose', '', false, false)]
    local procedure OnSaveAsReportOnBeforeFileClose(ReportSaved: Boolean; var DataRecRef: RecordRef; ReportID: Integer; RepFormat: ReportFormat; var FileStream: OutStream)
    begin
        RecordLayoutForRecords(DataRecRef, LayoutNameBeforeSaveAs);
        LayoutNameBeforeSaveAs := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforePrintDocument', '', false, false)]
    local procedure OnBeforePrintDocument(TempReportSelections: Record "Report Selections" temporary; IsGUI: Boolean; var RecVarToPrint: Variant; var IsHandled: Boolean)
    var
        DataRecRef: RecordRef;
    begin
        DataRecRef.GetTable(RecVarToPrint);
        RecordSelectedLayout(DataRecRef);
    end;
}

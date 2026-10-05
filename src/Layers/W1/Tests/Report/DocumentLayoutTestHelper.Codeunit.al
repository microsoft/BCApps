// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 134767 "Document Layout Test Helper"
{
    // Creates real report layouts for document layout (Custom Report Selection) scenarios. When bound, it records for
    // each record both the layout that was selected for the report run and the layout the platform rendered the
    // document with (from the report payload), so tests can assert that a customer-specific layout was used.
    EventSubscriberInstance = Manual;

    var
        TempSelectedLayoutNameValueBuffer: Record "Name/Value Buffer" temporary;
        TempRenderedLayoutNameValueBuffer: Record "Name/Value Buffer" temporary;
        LibraryUtility: Codeunit "Library - Utility";
        LastSelectedLayoutName: Text;
        LastRenderedLayoutName: Text;
        LayoutNameBeforeSaveAs: Text[250];
        RenderedLayoutName: Text[250];
        LayoutNameTok: Label 'DocLayoutTest-%1-%2', Locked = true;
        LayoutNamePayloadTok: Label 'layoutname', Locked = true;

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

    procedure SetCompanyDefaultLayout(ReportLayoutList: Record "Report Layout List")
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        EmptyGuid: Guid;
    begin
        // The same record the Report Layouts page writes when a layout is set as the default for the company
        TenantReportLayoutSelection."Report ID" := ReportLayoutList."Report ID";
        TenantReportLayoutSelection."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TenantReportLayoutSelection."Company Name"));
        TenantReportLayoutSelection."User ID" := EmptyGuid;
        TenantReportLayoutSelection."Layout Name" := ReportLayoutList.Name;
        TenantReportLayoutSelection."App ID" := ReportLayoutList."Application ID";
        if not TenantReportLayoutSelection.Insert(true) then
            TenantReportLayoutSelection.Modify(true);
    end;

    procedure RemoveCompanyDefaultLayout(ReportID: Integer)
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        EmptyGuid: Guid;
    begin
        if TenantReportLayoutSelection.Get(ReportID, CopyStr(CompanyName(), 1, MaxStrLen(TenantReportLayoutSelection."Company Name")), EmptyGuid) then
            TenantReportLayoutSelection.Delete(true);
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
        TempRenderedLayoutNameValueBuffer.Reset();
        TempRenderedLayoutNameValueBuffer.DeleteAll();
        LastSelectedLayoutName := '';
        LastRenderedLayoutName := '';
    end;

    procedure GetLastRenderedLayoutName(): Text
    begin
        exit(LastRenderedLayoutName);
    end;

    procedure IsRenderedWithLayout(RecordNo: Code[20]; LayoutName: Text): Boolean
    begin
        TempRenderedLayoutNameValueBuffer.Reset();
        TempRenderedLayoutNameValueBuffer.SetRange(Name, RecordNo);
        TempRenderedLayoutNameValueBuffer.SetRange(Value, CopyStr(LayoutName, 1, MaxStrLen(TempRenderedLayoutNameValueBuffer.Value)));
        exit(not TempRenderedLayoutNameValueBuffer.IsEmpty());
    end;

    procedure GetRenderCount(RecordNo: Code[20]): Integer
    begin
        TempRenderedLayoutNameValueBuffer.Reset();
        TempRenderedLayoutNameValueBuffer.SetRange(Name, RecordNo);
        exit(TempRenderedLayoutNameValueBuffer.Count());
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
    begin
        LastSelectedLayoutName := SelectedLayoutName;
        AddLayoutForRecords(TempSelectedLayoutNameValueBuffer, DataRecRef, SelectedLayoutName);
    end;

    local procedure AddLayoutForRecords(var TempLayoutNameValueBuffer: Record "Name/Value Buffer" temporary; var DataRecRef: RecordRef; LayoutName: Text[250])
    var
        RecordsRecRef: RecordRef;
        PrimaryKeyRef: KeyRef;
    begin
        // The report runs for every record in the view, so each of them got the layout.
        // Records are identified by the last field of their primary key, such as "No." of a customer.
        RecordsRecRef := DataRecRef.Duplicate();
        PrimaryKeyRef := RecordsRecRef.KeyIndex(1);
        TempLayoutNameValueBuffer.Reset();
        if RecordsRecRef.FindSet() then
            repeat
                TempLayoutNameValueBuffer.AddNewEntry(
                    CopyStr(Format(PrimaryKeyRef.FieldIndex(PrimaryKeyRef.FieldCount()).Value()), 1, 250), LayoutName);
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
        RenderedLayoutName := '';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Custom Layout Reporting", 'OnSaveAsReportOnBeforeFileClose', '', false, false)]
    local procedure OnSaveAsReportOnBeforeFileClose(ReportSaved: Boolean; var DataRecRef: RecordRef; ReportID: Integer; RepFormat: ReportFormat; var FileStream: OutStream)
    begin
        RecordLayoutForRecords(DataRecRef, LayoutNameBeforeSaveAs);
        if RenderedLayoutName <> '' then
            AddLayoutForRecords(TempRenderedLayoutNameValueBuffer, DataRecRef, RenderedLayoutName);
        LayoutNameBeforeSaveAs := '';
        RenderedLayoutName := '';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnDocumentReady', '', false, false)]
    local procedure OnDocumentReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    var
        LayoutNameToken: JsonToken;
    begin
        // The payload names the layout the platform rendered the document with, after resolving any default layout
        if not ObjectPayload.Get(LayoutNamePayloadTok, LayoutNameToken) then
            exit;
        RenderedLayoutName := CopyStr(LayoutNameToken.AsValue().AsText(), 1, MaxStrLen(RenderedLayoutName));
        LastRenderedLayoutName := RenderedLayoutName;
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

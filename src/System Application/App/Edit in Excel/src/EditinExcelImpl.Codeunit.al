// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Excel;

using System;
using System.Integration;
using System.Environment;
using System.Reflection;

codeunit 1482 "Edit in Excel Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;


    var
        EditinExcel: Codeunit "Edit in Excel";
        EditInExcelTelemetryCategoryTxt: Label 'Edit in Excel', Locked = true;
        CreateEndpointForObjectTxt: Label 'Creating endpoint for %1 %2.', Locked = true;
        EditInExcelHandledTxt: Label 'Edit in excel has been handled.', Locked = true;
        EditInExcelOnlySupportPageWebServicesTxt: Label 'Edit in Excel only support web services created from pages.', Locked = true;
        EditInExcelInvalidFilterErr: Label 'Certain filters applied on the page are not available in Office, so more rows will be shown compared to Business Central.\ \ Removed filters: %1', Comment = '%1 = The field filters we had to remove because they are not exposed through OData';
        DialogTitleTxt: Label 'Export';
        ExcelFileNameTxt: Text;
        XmlByteEncodingTok: Label '_x00%1_%2', Locked = true;
        XmlByteEncoding2Tok: Label '%1_x00%2_%3', Locked = true;
        XmlByteEncoding3Tok: Label '%1_%2_%3', Locked = true;

    procedure EditPageInExcel(PageCaption: Text[240]; PageId: Integer; EditinExcelFilters: Codeunit "Edit in Excel Filters"; FileName: Text)
    var
        ServiceName: Text[240];
        Handled: Boolean;
    begin
        ServiceName := FindOrCreateWorksheetWebService(PageCaption, PageId);
        ExcelFileNameTxt := FileName;

        EditinExcel.OnEditInExcelWithFilters(ServiceName, EditinExcelFilters, '', Handled);
        if Handled then begin
            Session.LogMessage('0000IG7', EditInExcelHandledTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EditInExcelTelemetryCategoryTxt);
            exit;
        end;

        GetEndPointAndCreateWorkbookWStructuredFilter(ServiceName, EditinExcelFilters, '');
    end;


    #region JSON FILTER SPECIFIC

    procedure GetEndPointAndCreateWorkbookWStructuredFilter(ServiceName: Text[250]; EditinExcelFilters: Codeunit "Edit in Excel Filters"; SearchFilter: Text)
    var
        TenantWebService: Record "Tenant Web Service";
        EditinExcelWorkbook: Codeunit "Edit in Excel Workbook";
    begin
        if (not TenantWebService.Get(TenantWebService."Object Type"::Page, ServiceName)) then
            Error(EditInExcelOnlySupportPageWebServicesTxt);

        Session.LogMessage('0000DB6', StrSubstNo(CreateEndpointForObjectTxt, TenantWebService."Object Type", TenantWebService."Object ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EditInExcelTelemetryCategoryTxt);

        EditinExcelWorkbook.Initialize(TenantWebService."Service Name");
        SetupFieldColumnBindings(EditinExcelWorkbook, TenantWebService."Object ID");
        EditinExcelWorkbook.SetFilters(EditinExcelFilters);

        ExportAndDownloadExcelFile(EditinExcelWorkbook.ExportToStream(), TenantWebService);
    end;

    local procedure SetupFieldColumnBindings(var EditinExcelWorkbook: Codeunit "Edit in Excel Workbook"; PageNo: Integer)
    var
        FieldsTable: Record "Field";
        PageControlField: Record "Page Control Field";
        PageMetadata: Record "Page Metadata";
        DocumentSharing: Codeunit "Document Sharing";
        RecordRef: RecordRef;
        VarFieldRef: FieldRef;
        VarKeyRef: KeyRef;
        AddedFields: List of [Integer];
        KeyFieldNumber: Integer;
        DocumentSharingSource: Enum "Document Sharing Source";
    begin
        // Add all fields on the page backed up by a table field
        PageControlField.SetRange(PageNo, PageNo);
        PageControlField.SetCurrentKey(Sequence);
        PageControlField.SetAscending(Sequence, true);
        if PageControlField.FindSet() then
            repeat
                if FieldsTable.Get(PageControlField.TableNo, PageControlField.FieldNo) then
                    if not AddedFields.Contains(PageControlField.FieldNo) then begin // Make sure we don't add the same field twice
                                                                                     // Add field to Excel
                        EditinExcelWorkbook.AddColumn(FieldsTable."Field Caption", ExternalizeODataObjectName(PageControlField.ControlName));
                        AddedFields.Add(PageControlField.FieldNo);
                    end;
            until PageControlField.Next() = 0;
        PageMetadata.Get(PageNo);

        RecordRef.Open(PageMetadata.SourceTable);
        VarKeyRef := RecordRef.KeyIndex(1);
        for KeyFieldNumber := 1 to VarKeyRef.FieldCount do begin
            VarFieldRef := VarKeyRef.FieldIndex(KeyFieldNumber);

            if not AddedFields.Contains(VarFieldRef.Number) then begin // Make sure we don't add the same field twice
                                                                       // Add missing key fields at the beginning
                EditinExcelWorkbook.InsertColumn(0, VarFieldRef.Caption, ExternalizeODataObjectName(VarFieldRef.Name));
                AddedFields.Add(VarFieldRef.Number);
            end;
        end;

        if DocumentSharing.ShareEnabled(DocumentSharingSource::System) then
            EditinExcelWorkbook.ImposeExcelOnlineRestrictions();
    end;

    #endregion JSON FILTER SPECIFIC


    local procedure ExportAndDownloadExcelFile(InputStream: InStream; TenantWebService: Record "Tenant Web Service")
    begin
        if ExcelFileNameTxt = '' then
            ExcelFileNameTxt := GenerateExcelFileName(TenantWebService);
        ExcelFileNameTxt := ExcelFileNameTxt + '.xlsx';
        DownloadExcelFile(InputStream, ExcelFileNameTxt);
    end;

    local procedure GenerateExcelFileName(TenantWebService: Record "Tenant Web Service") FileName: Text
    var
        PageMetadata: Record "Page Metadata";
        QueryMetadata: Record "Query Metadata";
        CodeunitMetadata: Record "CodeUnit Metadata";
    begin
        case TenantWebService."Object Type" of
            TenantWebService."Object Type"::Page:
                if PageMetadata.Get(TenantWebService."Object ID") then
                    FileName := PageMetadata.Caption;
            TenantWebService."Object Type"::Query:
                if QueryMetadata.Get(TenantWebService."Object ID") then
                    FileName := QueryMetadata.Caption;
            TenantWebService."Object Type"::Codeunit:
                if CodeunitMetadata.Get(TenantWebService."Object ID") then
                    FileName := CodeunitMetadata.Name;
        end;

        if FileName = '' then
            FileName := TenantWebService."Service Name".Replace('_Excel', '');
    end;


    local procedure FindOrCreateWorksheetWebService(PageCaption: Text[240]; PageId: Integer): Text[240]
    var
        TenantWebService: Record "Tenant Web Service";
        ServiceName: Text[240];
    begin
        // Aligned with how platform finds and creates web services
        // The function returns the first web service name that matches:
        // 1. Name is PageCaption_Excel (this allows admin to Publish/Unpublish the web service and be in complete control over whether Edit in Excel works)
        // 2. Published flag = true (prefer enabled web services)
        // 3. Any web service for the page
        // 4. Create a new web service called PageCaption_Excel

        if NameBeginsWithADigit(PageCaption) then
            ServiceName := 'WS' + CopyStr(PageCaption, 1, 232) + '_Excel'
        else
            ServiceName := CopyStr(PageCaption, 1, 234) + '_Excel';

        if TenantWebService.Get(TenantWebService."Object Type"::Page, ServiceName) and (TenantWebService."Object ID" = PageId) then
            exit(ServiceName);

        TenantWebService."Object Type" := TenantWebService."Object Type"::Page;
        TenantWebService."Object ID" := PageId;
        TenantWebService."Service Name" := ServiceName;
        TenantWebService.ExcludeFieldsOutsideRepeater := true;
        TenantWebService.ExcludeNonEditableFlowFields := true;
        TenantWebService.Published := true;
        TenantWebService.Insert(true);
        exit(ServiceName);
    end;

    local procedure NameBeginsWithADigit(Name: Text[240]): Boolean
    begin
        if Name[1] in ['0' .. '9'] then
            exit(true);
        exit(false);
    end;

    local procedure DownloadExcelFile(InputStream: InStream; FileName: Text)
    var
        DocumentSharing: Codeunit "Document Sharing";
        DocumentSharingIntent: Enum "Document Sharing Intent";
        DocumentSharingSource: Enum "Document Sharing Source";
    begin
        if DocumentSharing.ShareEnabled(DocumentSharingSource::System) then begin
            DocumentSharing.Share(FileName, '.xlsx', InputStream, DocumentSharingIntent::Open, DocumentSharingSource::System);
            exit;
        end;

        DownloadFromStream(InputStream, DialogTitleTxt, '', '*.*', FileName);
    end;



    procedure ExternalizeODataObjectName(Name: Text) ConvertedName: Text
    var
        CurrentPosition: Integer;
        Convert: DotNet Convert;
        StartStr: Text;
        EndStr: Text;
        ByteValue: DotNet Byte;
        ConvertedByteValue: Text;
        IsByteValueUnderscore: Dictionary of [Integer, Boolean];
    begin
        ConvertedName := Name;

        if NameBeginsWithADigit(ConvertedName[1]) then begin
            ByteValue := Convert.ToByte(ConvertedName[1]);
            ConvertedName := CopyStr(ConvertedName, 2);
            ConvertedName := StrSubstNo(XmlByteEncodingTok, Convert.ToString(ByteValue, 16), ConvertedName);
        end;

        // Mimics the behavior of the compiler when converting a field or web service name to OData.
        CurrentPosition := StrPos(ConvertedName, '%');
        while CurrentPosition > 0 do begin
            ConvertedName := DelStr(ConvertedName, CurrentPosition, 1);
            ConvertedName := InsStr(ConvertedName, 'Percent', CurrentPosition);
            CurrentPosition := StrPos(ConvertedName, '%');
        end;

        CurrentPosition := 1;

        while CurrentPosition <= StrLen(ConvertedName) do begin
            // Notice in the following line that – (en dash) is not a normal dash (em dash).
            // We need to handle this here because at least the norwegian translation uses en dash.
            if ConvertedName[CurrentPosition] in ['''', '+', '–'] then begin
                if ConvertedName[CurrentPosition] in ['–'] then begin
                    StartStr := CopyStr(ConvertedName, 1, CurrentPosition - 1);
                    EndStr := CopyStr(ConvertedName, CurrentPosition + 1);
                    ConvertedName := StrSubstNo(XmlByteEncoding3Tok, StartStr, 'x2013', EndStr);
                    // length of _x00nn_ minus one that will be added later
                end else begin
                    ByteValue := Convert.ToByte(ConvertedName[CurrentPosition]);
                    StartStr := CopyStr(ConvertedName, 1, CurrentPosition - 1);
                    EndStr := CopyStr(ConvertedName, CurrentPosition + 1);
                    ConvertedByteValue := Convert.ToString(ByteValue, 16);
                    ConvertedByteValue := ConvertedByteValue.ToUpper();
                    ConvertedName := StrSubstNo(XmlByteEncoding2Tok, StartStr, ConvertedByteValue, EndStr);
                end;
                // length of _x00nn_ minus one that will be added later
                CurrentPosition += 6;

                IsByteValueUnderscore.Add(CurrentPosition, true);
            end else
                if ConvertedName[CurrentPosition] in [' ', '\', '/', '"', '.', '(', ')', '-', ':'] then
                    if CurrentPosition > 1 then begin
                        // The only cases where we allow 2 underscores in succession is when
                        // we have substituted a symbol with its byte value and when we have an actual underscore
                        // prefixed with a symbol that should be replaced with underscore.
                        // This code below removes duplicate underscores but
                        // needs to not remove underscores that was added via a byte value.
                        if (ConvertedName[CurrentPosition - 1] = '_') and not IsByteValueUnderscore.ContainsKey(CurrentPosition - 1) then begin
                            ConvertedName := DelStr(ConvertedName, CurrentPosition, 1);
                            CurrentPosition -= 1;
                        end else
                            ConvertedName[CurrentPosition] := '_';
                    end else
                        ConvertedName[CurrentPosition] := '_';

            CurrentPosition += 1;
        end;

        ConvertedName := DelChr(ConvertedName, '>', '_'); // remove trailing underscore
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", OnEditInExcelWithStructuredFilter, '', false, false)]
    local procedure OnEditInExcelWithStructuredFilterEvent(ServiceName: Text[240]; SearchString: Text; Filter: JsonObject; Payload: JsonObject)
    var
        TenantWebService: Record "Tenant Web Service";
        EditinExcelFilters: Codeunit "Edit in Excel Filters";
        FilterErrors: Dictionary of [Text, Boolean];
        Handled: Boolean;
    begin
        EditinExcel.OnEditInExcelWithStructuredFilter(ServiceName, Filter, Payload, SearchString, Handled);
        if Handled then begin
            Session.LogMessage('0000I43', EditInExcelHandledTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EditInExcelTelemetryCategoryTxt);
            exit;
        end;

        if not TenantWebService.Get(TenantWebService."Object Type"::Page, ServiceName) then
            exit;

        EditinExcelFilters.ReadFromJsonFilters(Filter, Payload, TenantWebService."Object ID", FilterErrors);
        EditinExcel.OnEditInExcelWithFilters(ServiceName, EditinExcelFilters, SearchString, Handled);
        if Handled then begin
            Session.LogMessage('0000IG8', EditInExcelHandledTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', EditInExcelTelemetryCategoryTxt);
            exit;
        end;
        if FilterErrors.Count() > 0 then
            Message(EditInExcelInvalidFilterErr, FormatFilterErrors(FilterErrors));
        GetEndPointAndCreateWorkbookWStructuredFilter(ServiceName, EditinExcelFilters, SearchString);
    end;

    local procedure FormatFilterErrors(FilterErrors: Dictionary of [Text, Boolean]): Text
    var
        ConcatenatedErrors: Text;
        ErrorText: Text;
    begin
        foreach ErrorText in FilterErrors.Keys() do
            ConcatenatedErrors := ConcatenatedErrors + ErrorText + ', ';
        if StrLen(ConcatenatedErrors) > 0 then
            ConcatenatedErrors := DelStr(ConcatenatedErrors, StrLen(ConcatenatedErrors) - 1);
        exit(ConcatenatedErrors);
    end;
}
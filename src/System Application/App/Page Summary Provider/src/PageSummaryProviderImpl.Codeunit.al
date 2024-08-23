// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration;

using System;
using System.Environment;
using System.Reflection;
using System.Text;

/// <summary>
/// Implements functionality to get summary data for a given object.
/// </summary>
codeunit 2717 "Page Summary Provider Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Company = r,
                  tabledata "Page Metadata" = r,
                  tabledata "Tenant Media Set" = r,
                  tabledata "Tenant Media Thumbnails" = r;

    procedure GetPageSummary(Parameters: Text): Text
    var
        PageSummaryParameters: Record "Page Summary Parameters";
    begin
        PageSummaryParameters.FromJson(Parameters);
        exit(GetPageSummary(PageSummaryParameters));
    end;

    procedure GetPageSummary(PageSummaryParameters: Record "Page Summary Parameters"): Text
    begin
        if PageSummaryParameters."Page ID" = 0 then
            ThrowPageMustBeSpecifiedError();

        if PageSummaryParameters.Bookmark <> '' then
            exit(GetPageSummary(PageSummaryParameters."Page ID", PageSummaryParameters.Bookmark, PageSummaryParameters."Include Binary Data"));

        if not IsNullGuid(PageSummaryParameters."Record SystemID") then
            exit(GetPageSummary(PageSummaryParameters."Page ID", PageSummaryParameters."Record SystemID", PageSummaryParameters."Include Binary Data"));

        exit(GetPageSummary(PageSummaryParameters."Page ID", '', PageSummaryParameters."Include Binary Data"));
    end;

    procedure GetPageSummary(PageId: Integer; Bookmark: Text; IncludeBinaryData: Boolean): Text
    var
        RecId: RecordId;
        ResultJsonObject: JsonObject;
    begin
        // Add header
        AddPageSummaryHeader(PageId, ResultJsonObject);

        // If show summary record is false, then exit with summary type caption
        if not PageSummarySettings.IsShowRecordSummaryEnabled() then
            exit(Format(ResultJsonObject));

        if Bookmark = '' then
            exit(Format(ResultJsonObject)); // There is no bookmark, so just return page header

        // Initialize variables
        if not Evaluate(RecId, Bookmark, 10) then begin // 10 = Evaluate string into RecordId
            AddErrorMessage(ResultJsonObject, InvalidBookmarkErrorCodeTok, InvalidBookmarkErrorMessageTxt);
            exit(Format(ResultJsonObject)); // Bookmark is invalid, so returning the information we actually have about the page
        end;

        // Add summary fields and record fields
        AddFields(PageId, RecId, Bookmark, ResultJsonObject, IncludeBinaryData);

        exit(Format(ResultJsonObject));
    end;

    procedure GetPageSummary(PageId: Integer; SystemId: Guid; IncludeBinaryData: Boolean): Text
    var
        PageMetadata: Record "Page Metadata";
        RecId: RecordId;
        SourceRecordRef: RecordRef;
        ResultJsonObject: JsonObject;
        Bookmark: Text;
    begin
        // Add header
        AddPageSummaryHeader(PageId, ResultJsonObject);

        // Initialize variables
        if not PageMetadata.Get(PageId) then
            exit(Format(ResultJsonObject));

        SourceRecordRef.Open(PageMetadata.SourceTable);

        if not SourceRecordRef.GetBySystemId(SystemId) then begin
            AddErrorMessage(ResultJsonObject, InvalidSystemIdErrorCodeTok, InvalidSystemIdErrorMessageTxt);
            exit(Format(ResultJsonObject)); // System ID is invalid, so returning the information we actually have about the page
        end;

        AddUrl(ResultJsonObject, PageId, SourceRecordRef);

        // If show summary record is false, then exit with summary type caption
        if not PageSummarySettings.IsShowRecordSummaryEnabled() then
            exit(Format(ResultJsonObject));

        RecId := SourceRecordRef.RecordId;
        Bookmark := Format(RecId, 0, 10); // 10 = Format RecordId into string
        if Bookmark = '' then
            exit(Format(ResultJsonObject));

        // Add summary fields and record fields
        AddFields(PageId, RecId, Bookmark, ResultJsonObject, IncludeBinaryData);

        exit(Format(ResultJsonObject));
    end;

    procedure GetPageUrlBySystemID(PageId: Integer; SystemId: Guid): Text
    var
        PageMetadata: Record "Page Metadata";
        SourceRecordRef: RecordRef;
        ResultJsonObject: JsonObject;
    begin
        ResultJsonObject.Add('version', GetVersion());

        if not PageMetadata.Get(PageId) then begin
            AddErrorMessage(ResultJsonObject, PageNotFoundErrorCodeTok, StrSubstNo(PageNotFoundErrorMessageTxt, PageId));
            exit(Format(ResultJsonObject));
        end;

        SourceRecordRef.Open(PageMetadata.SourceTable);

        if not SourceRecordRef.GetBySystemId(SystemId) then begin
            AddErrorMessage(ResultJsonObject, InvalidSystemIdErrorCodeTok, InvalidSystemIdErrorMessageTxt);
            exit(Format(ResultJsonObject));
        end;

        AddUrl(ResultJsonObject, PageId, SourceRecordRef);
        Session.LogMessage('0000JAT', StrSubstNo(GetPageUrlSuccessTelemetryTxt, PageId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PageSummaryCategoryLbl);
        exit(Format(ResultJsonObject));
    end;


    procedure GetVersion(): Text[30]
    begin
        exit('1.1');
    end;

    procedure InitializePageSummarySettingsFromJson(JsonText: Text; var PageSummaryParameters: Record "Page Summary Parameters")
    var
        PageSummaryJsonObject: JsonObject;
        ParsedJsonToken: JsonToken;
    begin
        Clear(PageSummarySettings);

        PageSummaryJsonObject.ReadFrom(JsonText);
        if not PageSummaryJsonObject.Get(PageIDTok, ParsedJsonToken) then
            ThrowPageMustBeSpecifiedError();

        PageSummaryParameters."Page ID" := ParsedJsonToken.AsValue().AsInteger();

        if PageSummaryJsonObject.Get(BookmarkTok, ParsedJsonToken) then
#pragma warning disable AA0139
            PageSummaryParameters.Bookmark := ParsedJsonToken.AsValue().AsText()
#pragma warning restore AA0139
        else
            if PageSummaryJsonObject.Get(RecordSystemIdTok, ParsedJsonToken) then
                PageSummaryParameters."Record SystemID" := ParsedJsonToken.AsValue().AsText();

        if PageSummaryJsonObject.Get(IncludeBinaryDataTok, ParsedJsonToken) then
            PageSummaryParameters."Include Binary Data" := ParsedJsonToken.AsValue().AsBoolean();
    end;

    local procedure AddFields(PageId: Integer; RecId: RecordId; Bookmark: Text; var ResultJsonObject: JsonObject; IncludeBinaryData: Boolean)
    begin
        // Add Summary fields
        // Fields summary is a "summary" of the fields (i.e. it could be the brick definition, or some custom AL could provide its own summary).
        GetFieldsSummary(PageId, RecId, Bookmark, ResultJsonObject, IncludeBinaryData);

        // Add Record fields
        // Record fields are the backing record fields that are visible on the page.
        if not ResultJsonObject.Contains('error') then
            GetRecordFields(PageId, Bookmark, ResultJsonObject);
    end;

    local procedure GetFieldsSummary(PageId: Integer; RecId: RecordId; Bookmark: Text; var ResultJsonObject: JsonObject; IncludeBinaryData: Boolean)
    var
        PageSummaryProvider: Codeunit "Page Summary Provider";
        FieldsJsonArray: JsonArray;
        Handled: Boolean;
    begin
        // Allow partner to override returned fields
        PageSummaryProvider.OnBeforeGetPageSummary(PageId, RecId, FieldsJsonArray, Handled);
        if Handled then begin // Partner overrode fields
            Session.LogMessage('0000D73', StrSubstNo(OnBeforeGetPageSummaryWasHandledTxt, PageId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PageSummaryCategoryLbl);
            AddFieldsJsonArrayToResult(FieldsJsonArray, ResultJsonObject);
            exit;
        end;

        // Get summary fields
        if not TryGetPageSummaryFields(PageId, RecId, Bookmark, ResultJsonObject, IncludeBinaryData) then
            AddErrorMessage(ResultJsonObject, FailedGetSummaryFieldsCodeTok, GetLastErrorText());
    end;

    local procedure GetRecordFields(PageId: Integer; Bookmark: Text; var ResultJsonObject: JsonObject)
    begin
        // Get all visible and available table fields that back the controls that are visible on the page
        if TryGetAvailableRecordFieldsData(PageId, Bookmark, ResultJsonObject) then
            Session.LogMessage('0000NFZ', StrSubstNo(GetRecordFieldsFailureTelemetryTxt, PageId), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PageSummaryCategoryLbl);
        exit;
    end;

    [TryFunction]
    local procedure TryGetAvailableRecordFieldsData(PageId: Integer; Bookmark: Text; var ResultJsonObject: JsonObject)
    var
        GenericList: DotNet GenericList1;
        NavPageSummaryALFunctions: DotNet NavPageSummaryALFunctions;
        NavPageSummaryALResponse: DotNet NavPageSummaryALResponse;
        NavPageSummaryALField: DotNet NavPageSummaryALField;
        RecordFieldsJsonArray: JsonArray;
    begin
        GenericList := NavPageSummaryALFunctions.GetAvailableTableFields(PageId);
        if IsNull(GenericList) then begin
            Session.LogMessage('0000NCO', StrSubstNo(NoRecordFieldsFoundTelemetryTxt, PageId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PageSummaryCategoryLbl);
            exit;
        end;

        if (GenericList.Count() > 0) then begin
            NavPageSummaryALResponse := NavPageSummaryALFunctions.GetSummary(PageId, Bookmark, GenericList);
            if not NavPageSummaryALResponse.Success then begin
                Session.LogMessage('0000NCX', StrSubstNo(SummaryFailureTelemetryTxt, PageId), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PageSummaryCategoryLbl);
                exit;
            end;

            // Get field values
            foreach NavPageSummaryALField in NavPageSummaryALResponse.SummaryFields do
                AddFieldToFieldsJsonArray(NavPageSummaryALField, RecordFieldsJsonArray, true, false);
        end;
        ResultJsonObject.Add('recordFields', RecordFieldsJsonArray);
    end;

    local procedure AddErrorMessage(var ResultJsonObject: JsonObject; ErrorCode: Text; ErrorMessage: Text)
    var
        ErrorJsonObject: JsonObject;
    begin
        Session.LogMessage('0000EAX', ErrorCode, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PageSummaryCategoryLbl);
        ErrorJsonObject.Add('code', ErrorCode);
        ErrorJsonObject.Add('message', ErrorMessage);
        ResultJsonObject.Add('error', ErrorJsonObject);
    end;

    local procedure AddUrl(var ResultJsonObject: JsonObject; PageId: Integer; SourceRecordRef: RecordRef)
    var
        Url: Text;
    begin
        Url := GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, PageId, SourceRecordRef);
        ResultJsonObject.Add('url', Url);
    end;

    local procedure AddPageSummaryHeader(PageId: Integer; var ResultJsonObject: JsonObject)
    var
        PageMetadata: Record "Page Metadata";
        PageCaption: Text;
    begin
        if PageMetadata.Get(PageId) then
            PageCaption := PageMetadata.Caption
        else
            PageCaption := StrSubstNo(PageTxt, PageId);
        ResultJsonObject.Add('version', GetVersion());
        ResultJsonObject.Add('pageCaption', PageCaption);
        ResultJsonObject.Add('pageType', format(PageMetadata.PageType));
        ResultJsonObject.Add('summaryType', GetSummaryName(Enum::"Summary Type"::Caption)); // default summary type is caption
        ResultJsonObject.Add('cardPageId', PageMetadata.CardPageID);
    end;

    [TryFunction]
    local procedure TryGetPageSummaryFields(PageId: Integer; RecId: RecordId; Bookmark: Text; var ResultJsonObject: JsonObject; IncludeBinaryData: Boolean)
    var
        PageSummaryProvider: Codeunit "Page Summary Provider";
        NavPageSummaryALFunctions: DotNet NavPageSummaryALFunctions;
        GenericList: DotNet GenericList1;
        NavPageSummaryALResponse: DotNet NavPageSummaryALResponse;
        NavPageSummaryALField: DotNet NavPageSummaryALField;
        FieldsJsonArray: JsonArray;
        PageSummaryFieldList: List of [Integer];
        PageSummaryField: Integer;
        ErrorMessage: Text;
    begin
        GenericList := NavPageSummaryALFunctions.GetSummaryFields(PageId);
        if IsNull(GenericList) then
            exit;

        foreach PageSummaryField in GenericList do
            PageSummaryFieldList.Add(PageSummaryField);

        if not IncludeBinaryData then
            RemoveMediaAndBlobFields(RecId, PageSummaryFieldList);

        CorrectFieldOrderingOfBrick(PageSummaryFieldList);

        // Allow partners to override fields to be shown + order
        PageSummaryProvider.OnAfterGetSummaryFields(PageId, RecId, PageSummaryFieldList);
        GenericList.Clear();
        foreach PageSummaryField in PageSummaryFieldList do
            GenericList.Add(PageSummaryField);


        if (GenericList.Count() > 0) then begin
            NavPageSummaryALResponse := NavPageSummaryALFunctions.GetSummary(PageId, Bookmark, GenericList);
            if not NavPageSummaryALResponse.Success then begin
                Session.LogMessage('0000DGV', StrSubstNo(SummaryFailureTelemetryTxt, PageId), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PageSummaryCategoryLbl);
                ErrorMessage := NavPageSummaryALResponse.ErrorMessage;
                Error(ErrorMessage);
            end;
            // Get field values
            foreach NavPageSummaryALField in NavPageSummaryALResponse.SummaryFields do
                AddFieldToFieldsJsonArray(NavPageSummaryALField, FieldsJsonArray, false, true);
        end;

        // Allow partner to finally override field names and values
        PageSummaryProvider.OnAfterGetPageSummary(PageId, RecId, FieldsJsonArray);
        AddFieldsJsonArrayToResult(FieldsJsonArray, ResultJsonObject);
    end;

    local procedure RemoveMediaAndBlobFields(RecId: RecordId; var PageSummaryFieldList: List of [Integer])
    var
        RecordField: Record Field;
        Index: Integer;
        PageSummaryField: Integer;
    begin
        if PageSummaryFieldList.Count() = 0 then
            exit;

        Index := 1;

        repeat
            PageSummaryField := PageSummaryFieldList.Get(Index);
            RecordField.Get(RecId.TableNo, PageSummaryField);

            if (RecordField.Type in [RecordField.Type::Media, RecordField.Type::MediaSet, RecordField.Type::Blob]) then
                PageSummaryFieldList.RemoveAt(Index)
            else
                Index += 1;
        until Index > PageSummaryFieldList.Count();
    end;

    local procedure GetSummaryName(SummaryType: Enum "Summary Type"): Text;
    var
        Index: Integer;
    begin
        Index := SummaryType.Ordinals.IndexOf(SummaryType.AsInteger());
        exit(SummaryType.Names().Get(Index));
    end;

    local procedure AddFieldsJsonArrayToResult(var FieldsJsonArray: JsonArray; var ResultJsonObject: JsonObject)
    begin
        if FieldsJsonArray.Count() > 0 then
            ResultJsonObject.Replace('summaryType', GetSummaryName(Enum::"Summary Type"::Brick));

        ResultJsonObject.Add('fields', FieldsJsonArray);
    end;

    local procedure CorrectFieldOrderingOfBrick(var PageSummaryFieldList: List of [Integer])
    var
        TempValue: Integer;
    begin
        // Currently we just want to swap first and second field if there is more than one
        if PageSummaryFieldList.Count() <= 1 then
            exit;

        TempValue := PageSummaryFieldList.Get(1);
        PageSummaryFieldList.RemoveAt(1);
        PageSummaryFieldList.Insert(2, TempValue);
    end;

    local procedure AddFieldToFieldsJsonArray(NavPageSummaryALField: DotNet NavPageSummaryALField; var FieldsJsonArray: JsonArray; OnlyIncludeNonEmptyFieldValues: Boolean; IncludePictures: Boolean)
    var
        FieldsJsonObject: JsonObject;
        FieldValue: Text;
        FieldType: Text;
        MimeType: Text;
    begin
        if NavPageSummaryALField.FieldType = 33794 then // 33794 == Blob
            exit;
        FieldValue := NavPageSummaryALField.Value.ToString();
        FieldType := NavPageSummaryALField.FieldType.ToString();

        if OnlyIncludeNonEmptyFieldValues then
            if FieldValue = '' then
                exit;

        // Handle pictures - 26209 == MediaSet, 26208 == Media
        if NavPageSummaryALField.FieldType = 26208 then begin
            if not IncludePictures then
                exit;
            ExtractPictureFromMedia(NavPageSummaryALField.Value.ToString(), FieldValue, MimeType, FieldType);
        end;
        if NavPageSummaryALField.FieldType = 26209 then begin
            if not IncludePictures then
                exit;
            ExtractPictureFromMediaSet(NavPageSummaryALField.Value.ToString(), FieldValue, MimeType, FieldType);
        end;

        // Add the actual field
        FieldsJsonObject.Add('caption', NavPageSummaryALField.Caption);
        if NavPageSummaryALField.ExtendedType <> NavPageSummaryALField.ExtendedType::Undefined then
            FieldsJsonObject.Add('extendedType', NavPageSummaryALField.ExtendedType.ToString());
        FieldsJsonObject.Add('fieldValue', FieldValue);
        FieldsJsonObject.Add('fieldType', FieldType);
        FieldsJsonObject.Add('tooltip', NavPageSummaryALField.Tooltip);
        if MimeType <> '' then
            FieldsJsonObject.Add('mimeType', MimeType);
        FieldsJsonArray.Add(FieldsJsonObject);
    end;

    local procedure ExtractPictureFromMedia(ImageGuid: Guid; var FieldValue: Text; var MimeType: Text; var FieldType: Text)
    var
        TenantMediaThumbnails: Record "Tenant Media Thumbnails";
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
    begin
        FieldType := 'Media';
        // Filter on large image thumbnail
        // Whenever an image is stored, we also store a large image thumbnail in dimensions 240 x 240 (used in grid view)
        TenantMediaThumbnails.SetRange("Media Id", ImageGuid);
        TenantMediaThumbnails.SetRange("Height", 240);
        TenantMediaThumbnails.SetRange("Width", 240);
        if not TenantMediaThumbnails.FindFirst() then begin
            Clear(FieldValue);
            Clear(MimeType);
            exit;
        end;

        TenantMediaThumbnails.CalcFields(Content);
        TenantMediaThumbnails.Content.CreateInStream(InStr);
        FieldValue := Base64Convert.ToBase64(InStr);
        MimeType := TenantMediaThumbnails."Mime Type";
    end;

    local procedure ExtractPictureFromMediaSet(ImageGuid: Guid; var FieldValue: Text; var MimeType: Text; var FieldType: Text)
    var
        TenantMediaSet: Record "Tenant Media Set";
    begin
        TenantMediaSet.SetRange(Id, ImageGuid);
        if TenantMediaSet.FindFirst() then;
        ExtractPictureFromMedia(TenantMediaSet."Media ID".MediaId, FieldValue, MimeType, FieldType);
    end;

    local procedure ThrowPageMustBeSpecifiedError()
    var
        ProgrammingErrorInfo: ErrorInfo;
    begin
        ProgrammingErrorInfo.Verbosity := Verbosity::Error;
        ProgrammingErrorInfo.ErrorType := ProgrammingErrorInfo.ErrorType::Internal;
        ProgrammingErrorInfo.Message := PageIDMustBeSpecifiedErr;
        Error(ProgrammingErrorInfo);
    end;

    var
        PageSummarySettings: Codeunit "Page Summary Settings";
        PageTxt: Label 'Page %1', Comment = '%1 is a whole number, ex. 10';
        PageSummaryCategoryLbl: Label 'Page Summary Provider', Locked = true;
        OnBeforeGetPageSummaryWasHandledTxt: Label 'OnBeforeGetPageSummary event was handled for page %1.', Locked = true;
        SummaryFailureTelemetryTxt: Label 'Failure to get summary for page %1.', Locked = true;
        InvalidBookmarkErrorCodeTok: Label 'InvalidBookmark', Locked = true;
        InvalidBookmarkErrorMessageTxt: Label 'The bookmark is invalid.';
        FailedGetSummaryFieldsCodeTok: Label 'FailedGettingPageSummaryFields', Locked = true;
        InvalidSystemIdErrorCodeTok: Label 'InvalidSystemId', Locked = true;
        InvalidSystemIdErrorMessageTxt: Label 'The system ID is invalid.';
        PageNotFoundErrorCodeTok: Label 'PageNotFound', Locked = true;
        PageNotFoundErrorMessageTxt: Label 'Page %1 is not found.', Comment = '%1 is a whole number, ex. 10';
        GetPageUrlSuccessTelemetryTxt: Label 'Successfully added url for page %1.', Locked = true;
        NoRecordFieldsFoundTelemetryTxt: Label 'No record fields found for page %1.', Locked = true;
        GetRecordFieldsFailureTelemetryTxt: Label 'Failure to get record fields for page %1.', Locked = true;
        PageIDMustBeSpecifiedErr: Label 'Page ID must be specified.', Locked = true;
        PageIDTok: Label 'pageId', Locked = true;
        RecordSystemIdTok: Label 'recordSystemId', Locked = true;
        BookmarkTok: Label 'bookmark', Locked = true;
        IncludeBinaryDataTok: Label 'includeBinaryData', Locked = true;
}
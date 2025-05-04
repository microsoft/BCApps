// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI;

using System.Utilities;
using System.Text;
using System.Environment;

codeunit 7783 "AOAI Images Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        FileExtensionToMimeTypeMappingInitialized: Boolean;
        FileExtensionToMimeTypeMapping: Dictionary of [Text, Text];
        MimeTypeFromExtensionNotResolvedErr: Label 'Could not resolve Mime type for the provided file extension %1.', Comment = '%1 = file extension';
        DataUrlFormatLbl: Label 'data:%1;base64,%2', Comment = '%1 = mime type, %2 = base64 encoded data', Locked = true;

    internal procedure PrepareUserMessageContentFromTempBlob(UserText: Text; var TempBlob: Codeunit "Temp Blob"; FileExtension: Text; DetailLevel: Enum "AOAI Image Detail Level") ContentAsText: Text
    var
        ImageStream: InStream;
    begin
        if not TempBlob.HasValue() then
            exit('');

        if FileExtension = '' then
            exit('');

        TempBlob.CreateInStream(ImageStream);
        exit(PrepareUserMessageContentFromStream(UserText, ImageStream, FileExtension, DetailLevel));
    end;

    internal procedure PrepareUserMessageContentFromStream(UserText: Text; ImageStream: InStream; FileExtension: Text; DetailLevel: Enum "AOAI Image Detail Level") ContentAsText: Text
    var
        MimeType: Text;
    begin
        if FileExtension = '' then
            exit('');

        MimeType := ConvertFileExtensionToMimeType(FileExtension);
        if MimeType = '' then
            Error(MimeTypeFromExtensionNotResolvedErr, FileExtension);

        exit(PrepareUserMessageContentFromStreamAndMimeType(UserText, ImageStream, MimeType, DetailLevel));
    end;

    internal procedure PrepareUserMessageContentFromMediaSet(UserText: Text; MediaSetId: Guid; DetailLevel: Enum "AOAI Image Detail Level") ContentAsText: Text
    var
        TenantMediaSet: Record "Tenant Media Set";
        TenantMedia: Record "Tenant Media";
        ImageStream: InStream;
        ContentArray: JsonArray;
        MaxImages: Integer;
        ImageCount: Integer;
    begin
        if IsNullGuid(MediaSetId) then
            exit('');

        if not TenantMediaSet.Get(MediaSetId) then
            exit('');

        MaxImages := 10;
        ImageCount := 0;

        AddTextPart(UserText, ContentArray);

        TenantMediaSet.SetRange(ID, MediaSetId);
        if TenantMediaSet.IsEmpty() then
            exit('');

        if TenantMediaSet.FindSet() then
            repeat
                TenantMedia.Get(TenantMediaSet."Media ID".MediaId());
                TenantMedia.CalcFields(Content);
                TenantMedia.Content.CreateInStream(ImageStream);
                if ImageCount < MaxImages then begin
                    AddImagePart(GetBase64EncodedUrl(ImageStream, TenantMedia."Mime Type"), DetailLevel, ContentArray);
                    ImageCount := ImageCount + 1;
                end;
            until TenantMediaSet.Next() = 0;

        if ImageCount = 0 then
            exit('');

        ContentArray.WriteTo(ContentAsText);
        exit(ContentAsText);
    end;


    internal procedure PrepareUserMessageContentFromMediaRecord(UserText: Text; TenantMedia: Record "Tenant Media"; DetailLevel: Enum "AOAI Image Detail Level") ContentAsText: Text
    var
        ImageStream: InStream;
    begin
        TenantMedia.CalcFields(Content);
        if not TenantMedia.Content.HasValue then
            exit('');

        TenantMedia.Content.CreateInStream(ImageStream);
        exit(PrepareUserMessageContentFromStreamAndMimeType(UserText, ImageStream, TenantMedia."Mime Type", DetailLevel));
    end;

    internal procedure PrepareUserMessageContentFromUrl(UserText: Text; ImageUrl: Text; DetailLevel: Enum "AOAI Image Detail Level") ContentAsText: Text
    var
        ContentArray: JsonArray;
    begin
        if ImageUrl = '' then
            exit('');

        AddTextPart(UserText, ContentArray);
        AddImagePart(ImageUrl, DetailLevel, ContentArray);

        ContentArray.WriteTo(ContentAsText);
        exit(ContentAsText);
    end;

    local procedure PrepareUserMessageContentFromStreamAndMimeType(UserText: Text; ImageStream: InStream; MimeType: Text; DetailLevel: Enum "AOAI Image Detail Level") ContentAsText: Text
    var
        ContentArray: JsonArray;
        DataUrl: Text;
    begin
        if MimeType = '' then
            exit('');

        DataUrl := GetBase64EncodedUrl(ImageStream, MimeType);
        if DataUrl = '' then
            exit('');

        AddTextPart(UserText, ContentArray);
        AddImagePart(DataUrl, DetailLevel, ContentArray);

        ContentArray.WriteTo(ContentAsText);
        exit(ContentAsText);
    end;

    local procedure AddTextPart(UserText: Text; var ContentArray: JsonArray)
    var
        TextObject: JsonObject;
    begin
        if UserText = '' then
            exit;

        TextObject.Add('type', 'text');
        TextObject.Add('text', UserText);
        ContentArray.Add(TextObject);
    end;

    local procedure AddImagePart(ImageUrl: Text; DetailLevel: Enum "AOAI Image Detail Level"; var ContentArray: JsonArray)
    var
        ImageJsonObj: JsonObject;
        UrlJsonObj: JsonObject;
    begin
        if ImageUrl = '' then
            exit;

        UrlJsonObj.Add('url', ImageUrl);
        if DetailLevel <> DetailLevel::auto then // Only add detail if not 'auto'
            UrlJsonObj.Add('detail', Format(DetailLevel));

        ImageJsonObj.Add('type', 'image_url');
        ImageJsonObj.Add('image_url', UrlJsonObj);
        ContentArray.Add(ImageJsonObj);
    end;

    local procedure GetBase64EncodedUrl(ImageStream: InStream; MimeType: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        Base64EncodedData: Text;
        BlobOutStream: OutStream;
        BlobInStream: InStream;
    begin
        if MimeType = '' then
            exit('');

        // Copy AL InStream to Temp Blob
        TempBlob.CreateOutStream(BlobOutStream);
        CopyStream(BlobOutStream, ImageStream);

        // Read from Temp Blob and Base64 Encode
        TempBlob.CreateInStream(BlobInStream);
        Base64EncodedData := Base64Convert.ToBase64(BlobInStream);

        // Construct the data URL
        exit(StrSubstNo(DataUrlFormatLbl, MimeType, Base64EncodedData));
    end;

    local procedure ConvertFileExtensionToMimeType(FileExtension: Text) MimeType: Text
    begin
        InitializeFileExtensionToMimeTypeMapping();
        if not FileExtensionToMimeTypeMapping.Get(LowerCase(FileExtension), MimeType) then
            exit('');

        exit(MimeType);
    end;

    local procedure InitializeFileExtensionToMimeTypeMapping()
    begin
        if FileExtensionToMimeTypeMappingInitialized then
            exit;

        // Initialize default mappings
        FileExtensionToMimeTypeMapping.Add('jpg', 'image/jpeg');
        FileExtensionToMimeTypeMapping.Add('jpeg', 'image/jpeg');
        FileExtensionToMimeTypeMapping.Add('png', 'image/png');
        FileExtensionToMimeTypeMapping.Add('gif', 'image/gif');
        FileExtensionToMimeTypeMapping.Add('bmp', 'image/bmp');
        FileExtensionToMimeTypeMapping.Add('webp', 'image/webp');

        OnAfterInitializeFileExtensionToMimeTypeMapping(FileExtensionToMimeTypeMapping);

        FileExtensionToMimeTypeMappingInitialized := true;
    end;

    internal procedure CheckIfImageContent(Message: Text): Boolean
    var
        ContentJArray: JsonArray;
    begin
        if not ContentJArray.ReadFrom(Message) then
            exit(false);

        exit(ContentJArray.Count() > 0);
    end;

    internal procedure ReadImageContent(Message: Text): JsonArray
    var
        ContentJArray: JsonArray;
        DummyJsonArray: JsonArray;
    begin
        if not ContentJArray.ReadFrom(Message) then
            exit(DummyJsonArray);

        exit(ContentJArray);
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnAfterInitializeFileExtensionToMimeTypeMapping(var FileExtensionToMimeTypeMap: Dictionary of [Text, Text])
    begin
    end;

}
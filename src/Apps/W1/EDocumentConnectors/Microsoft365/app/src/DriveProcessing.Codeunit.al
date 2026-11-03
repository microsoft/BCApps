// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Microsoft365;

using Microsoft.EServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Integration.Receive;
using System.Integration;
using System.Telemetry;
using System.Text;
using System.Utilities;

codeunit 6381 "Drive Processing"
{
    Access = Internal;
    Permissions = tabledata "E-Document" = m,
                  tabledata "E-Document Service Status" = m,
                  tabledata "OneDrive Setup" = rm,
                  tabledata "Sharepoint Setup" = rm;
    InherentPermissions = X;
    InherentEntitlements = X;

    internal procedure MarkEDocumentAsDownloaded(EDocument: Record "E-Document"; EDocumentService: Record "E-Document Service")
    var
        GraphClient: Codeunit "Graph Client";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        DriveId: Text;
        NewFolderId: Text;
    begin
        FeatureTelemetry.LogUptake('0000OAY', FeatureName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000OB1', FeatureName(), Format(EDocumentService."Service Integration V2"));
        if EDocument."Drive Item Id" = '' then
            Error(DocumentIdEmptyErr, EDocument."Entry No");

        DriveId := GetDocumentsDriveId(EDocumentService."Service Integration V2");
        NewFolderId := GetImportedDocumentsFolderId(EDocumentService."Service Integration V2");

        GraphClient.MoveDriveItem(DriveId, EDocument."Drive Item Id", NewFolderId);
    end;

    internal procedure GetSiteAndDriveId(FolderSharedLink: Text[2048]; var SiteId: Text; var DriveId: Text)
    var
        GraphClient: Codeunit "Graph Client";
        Base64Convert: Codeunit "Base64 Convert";
        ParentReferenceLink, Base64SharedLink, ErrorMessageTxt : Text;
        ParentReferenceJson: JsonObject;
        Token: JsonToken;
    begin
        Clear(SiteId);
        Clear(DriveId);
        Base64SharedLink := Base64Convert.ToBase64(FolderSharedLink);
        Base64SharedLink := 'u!' + Base64SharedLink.TrimEnd('=').Replace('/', '_').Replace('+', '-');
        ParentReferenceLink := GetGraphSharesURL() + Base64SharedLink + '/driveItem/parentReference';
        if not GraphClient.GetDriveFolderInfo(ParentReferenceLink, ParentReferenceJson) then begin
            ErrorMessageTxt := GetLastErrorText() + GetLastErrorCallStack();
            ClearLastError();
            Error(ErrorMessageTxt);
        end;

        if ParentReferenceJson.Get('siteId', Token) then
            SiteId := Token.AsValue().AsText();
        if ParentReferenceJson.Get('driveId', Token) then
            DriveId := Token.AsValue().AsText();
    end;

    // Graph cannot move items between drives, so the archive folder must be in the same document library as the documents folder.
    internal procedure CheckFoldersInSameDrive(DocumentsFolder: Text[2048]; DocumentsDriveId: Text; ArchiveFolder: Text[2048])
    var
        SiteId, ArchiveDriveId : Text;
    begin
        if DocumentsDriveId = '' then
            GetSiteAndDriveId(DocumentsFolder, SiteId, DocumentsDriveId);
        GetSiteAndDriveId(ArchiveFolder, SiteId, ArchiveDriveId);
        if (DocumentsDriveId <> '') and (ArchiveDriveId <> '') and (DocumentsDriveId <> ArchiveDriveId) then
            Error(FoldersInDifferentDrivesErr);
    end;

    procedure GetId(FolderSharedLink: Text[2048]): Text
    var
        GraphClient: Codeunit "Graph Client";
        Base64Convert: Codeunit "Base64 Convert";
        MyFolderIdLink, Base64SharedLink, ErrorMessageTxt : Text;
        FilesJson: JsonObject;
        IdToken: JsonToken;
    begin
        Base64SharedLink := Base64Convert.ToBase64(FolderSharedLink);
        Base64SharedLink := 'u!' + Base64SharedLink.TrimEnd('=').Replace('/', '_').Replace('+', '-');
        MyFolderIdLink := GetGraphSharesURL() + Base64SharedLink + '/driveItem?$select=id';
        if not GraphClient.GetDriveFolderInfo(MyFolderIdLink, FilesJson) then begin
            ErrorMessageTxt := GetLastErrorText() + GetLastErrorCallStack();
            ClearLastError();
            Error(ErrorMessageTxt);
        end;

        if FilesJson.Get('id', IdToken) then
            exit(IdToken.AsValue().AsText())
    end;

    procedure GetName(FolderSharedLink: Text[2048]): Text
    var
        GraphClient: Codeunit "Graph Client";
        Base64Convert: Codeunit "Base64 Convert";
        MyFolderIdLink, Base64SharedLink, ErrorMessageTxt : Text;
        FilesJson: JsonObject;
        IdToken: JsonToken;
    begin
        Base64SharedLink := Base64Convert.ToBase64(FolderSharedLink);
        Base64SharedLink := 'u!' + Base64SharedLink.TrimEnd('=').Replace('/', '_').Replace('+', '-');
        MyFolderIdLink := GetGraphSharesURL() + Base64SharedLink + '/driveItem?$select=id,name';
        if not GraphClient.GetDriveFolderInfo(MyFolderIdLink, FilesJson) then begin
            ErrorMessageTxt := GetLastErrorText() + GetLastErrorCallStack();
            ClearLastError();
            Error(ErrorMessageTxt);
        end;

        if FilesJson.Get('name', IdToken) then
            exit(IdToken.AsValue().AsText())
    end;

    procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service"; Documents: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext)
    var
        GraphClient: Codeunit "Graph Client";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        MyBCFilesLink, ErrorMessageTxt : Text;
        FilesJson: JsonObject;
    begin
        FeatureTelemetry.LogUptake('0000OAZ', FeatureName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000OB2', FeatureName(), Format(EDocumentService."Service Integration V2"));
        MyBCFilesLink := GetGraphSharesURL() + GetDocumentsSharedLink(EDocumentService."Service Integration V2") + '/driveItem/children?$top=100&$select=id,name,file,size,malware';
        if not GraphClient.GetDriveFolderInfo(MyBCFilesLink, FilesJson) then begin
            ErrorMessageTxt := GetLastErrorText() + GetLastErrorCallStack();
            ClearLastError();
            Error(ErrorMessageTxt);
        end;

        AddToDocumentsList(Documents, FilesJson);
    end;

    internal procedure FeatureName(): Text
    begin
        exit('Microsoft 365 E-Document Connector')
    end;

    internal procedure AddToReceiveContext(ReceiveContext: Codeunit ReceiveContext; var FilesJson: JSonObject)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        FilesJson.WriteTo(OutStream);
        ReceiveContext.SetTempBlob(TempBlob);
    end;

    internal procedure AddToDocumentsList(Documents: Codeunit "Temp Blob List"; var FilesJson: JSonObject)
    var
        TempBlob: Codeunit "Temp Blob";
        Child: JSonObject;
        Children: JSonArray;
        OutStream: OutStream;
        ChildTxt: Text;
        I: Integer;
        ChildCount: Integer;
    begin
        Children := FilesJson.GetArray('value');
        ChildCount := Children.Count();
        if ChildCount > 0 then
            for I := 0 to (ChildCount - 1) do begin
                Clear(TempBlob);
                TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
                Child := Children.GetObject(I);
                Child.WriteTo(ChildTxt);
                if not IgnoreDriveItem(Child, ChildTxt.ToLower()) then begin
                    OutStream.Write(ChildTxt);
                    Documents.Add(TempBlob);
                end;
            end;
    end;

    local procedure IgnoreDriveItem(Item: JSonObject; ItemAsTxt: Text): Boolean
    var
        SizeToken: JSonToken;
        Size: BigInteger;
    begin
        if Item.Get('size', SizeToken) then
            if SizeToken.IsValue() then
                Size := SizeToken.AsValue().AsBigInteger();

        if ItemAsTxt.Contains('"malware"') then
            exit(true);

        if not DelChr(ItemAsTxt, '=', ' ').Contains('"mimetype":"application/pdf"') then
            exit(true);

        if Size > SizeThreshold() then
            exit(true);
    end;

    internal procedure SizeThreshold(): Integer
    begin
        // 20 MB
        exit(20971520)
    end;

    procedure DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadataBlob: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
    var
        TempDocumentSharing: Record "Document Sharing" temporary;
        GraphClient: Codeunit "Graph Client";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        DocumentOutStream: OutStream;
        DocumentInStream: InStream;
        DocumentId, FileId, DriveId : Text;
    begin
        ExtractItemIdAndName(DocumentMetadataBlob, DocumentId, FileId);

        TempDocumentSharing.Init();
        TempDocumentSharing."Item Id" := CopyStr(DocumentId, 1, MaxStrLen(TempDocumentSharing."Item Id"));
        TempDocumentSharing.Insert();

        DriveId := GetDocumentsDriveId(EDocumentService."Service Integration V2");

        FeatureTelemetry.LogUptake('0000OB0', FeatureName(), Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000OB3', FeatureName(), Format(EDocumentService."Service Integration V2"));

        if not GraphClient.GetFileContent(DriveId, TempDocumentSharing) then begin
            EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, GetLastErrorText());
            ClearLastError();
            exit;
        end;

        TempDocumentSharing.CalcFields(Data);
        if not TempDocumentSharing.Data.HasValue() then
            EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, StrSubstNo(NoContentErr, DocumentId));

        ReceiveContext.GetTempBlob().CreateOutStream(DocumentOutStream, TextEncoding::UTF8);
        TempDocumentSharing.Data.CreateInStream(DocumentInStream, TextEncoding::UTF8);
        CopyStream(DocumentOutStream, DocumentInStream);

        EDocument."Drive Item Id" := CopyStr(DocumentId, 1, MaxStrLen(EDocument."Drive Item Id"));
        EDocument."Source Details" := CopyStr(GetSourceDetails(EDocumentService."Service Integration V2"), 1, MaxStrLen(EDocument."Source Details"));
        EDocument.Modify();
        ReceiveContext.SetName(CopyStr(FileId, 1, 250));
        ReceiveContext.SetFileFormat("E-Doc. File Format"::PDF);
    end;

    internal procedure ExtractItemIdAndName(DocumentMetadataBlob: Codeunit "Temp Blob"; var DocumentId: Text; var FileId: Text)
    var
        Instream: InStream;
        ItemObject: JsonObject;
        ContentData: Text;
    begin
        DocumentMetadataBlob.CreateInStream(Instream);
        Instream.ReadText(ContentData);
        ItemObject.ReadFrom(ContentData);
        DocumentId := ItemObject.GetText('id');
        FileId := ItemObject.GetText('name');
    end;

    local procedure GetGraphSharesURL(): Text
    var
        URLHelper: Codeunit "Url Helper";
    begin
        exit(URLHelper.GetGraphURL() + 'v1.0/shares/')
    end;

    local procedure GetDocumentsSharedLink(var ServiceIntegration: Enum "Service Integration"): Text
    var
        SharepointSetup: Record "Sharepoint Setup";
        OneDriveSetup: Record "OneDrive Setup";
        Base64Convert: Codeunit "Base64 Convert";
        FolderSharedLink: Text;
        Base64Value: Text;
    begin
        case ServiceIntegration of
            ServiceIntegration::SharePoint:
                begin
                    if SharepointSetup.Get() then
                        if SharepointSetup.Enabled then
                            FolderSharedLink := SharepointSetup."Documents Folder";

                    CheckFolderSharedLinkNotEmpty(FolderSharedLink, SharepointSetup.TableCaption());
                end;
            ServiceIntegration::OneDrive:
                begin
                    if OneDriveSetup.Get() then
                        if OneDriveSetup.Enabled then
                            FolderSharedLink := OneDriveSetup."Documents Folder";
                    CheckFolderSharedLinkNotEmpty(FolderSharedLink, OneDriveSetup.TableCaption());
                end;
            else
                Error(UnsupportedIntegrationTypeErr);
        end;
        if FolderSharedLink <> '' then begin
            Base64Value := Base64Convert.ToBase64(FolderSharedLink);
            Base64Value := 'u!' + Base64Value.TrimEnd('=').Replace('/', '_').Replace('+', '-');
            exit(Base64Value);
        end;
    end;

    // /sites/{id}/drive only addresses the site's default document library, so items are addressed by drive instead.
    local procedure GetDocumentsDriveId(var ServiceIntegration: Enum "Service Integration"): Text
    var
        SharepointSetup: Record "Sharepoint Setup";
        OneDriveSetup: Record "OneDrive Setup";
        SiteId, DriveId : Text;
    begin
        // Setups saved before the Drive Id field existed resolve it from the shared link once and store it.
        case ServiceIntegration of
            ServiceIntegration::SharePoint:
                begin
                    CheckSetupEnabled(SharepointSetup);
                    CheckFolderSharedLinkNotEmpty(SharepointSetup."Documents Folder", SharepointSetup.TableCaption());
                    if SharepointSetup."Drive Id" = '' then begin
                        GetSiteAndDriveId(SharepointSetup."Documents Folder", SiteId, DriveId);
                        if DriveId <> '' then begin
                            SharepointSetup."Drive Id" := CopyStr(DriveId, 1, MaxStrLen(SharepointSetup."Drive Id"));
                            SharepointSetup.Modify();
                        end;
                    end;
                    DriveId := SharepointSetup."Drive Id";
                end;
            ServiceIntegration::OneDrive:
                begin
                    CheckSetupEnabled(OneDriveSetup);
                    CheckFolderSharedLinkNotEmpty(OneDriveSetup."Documents Folder", OneDriveSetup.TableCaption());
                    if OneDriveSetup."Drive Id" = '' then begin
                        GetSiteAndDriveId(OneDriveSetup."Documents Folder", SiteId, DriveId);
                        if DriveId <> '' then begin
                            OneDriveSetup."Drive Id" := CopyStr(DriveId, 1, MaxStrLen(OneDriveSetup."Drive Id"));
                            OneDriveSetup.Modify();
                        end;
                    end;
                    DriveId := OneDriveSetup."Drive Id";
                end;
            else
                Error(UnsupportedIntegrationTypeErr);
        end;
        if DriveId = '' then
            Error(DriveIdEmptyErr);
        exit(DriveId);
    end;

    local procedure GetSourceDetails(var ServiceIntegration: Enum "Service Integration"): Text
    var
        SharepointSetup: Record "Sharepoint Setup";
        OneDriveSetup: Record "OneDrive Setup";
        DocumentsFolderName: Text;
    begin
        case ServiceIntegration of
            ServiceIntegration::SharePoint:
                begin
                    CheckSetupEnabled(SharepointSetup);
                    CheckFolderSharedLinkNotEmpty(SharepointSetup."Documents Folder", SharepointSetup.TableCaption());
                    DocumentsFolderName := SharepointSetup."Documents Folder Name";
                end;
            ServiceIntegration::OneDrive:
                begin
                    CheckSetupEnabled(OneDriveSetup);
                    CheckFolderSharedLinkNotEmpty(OneDriveSetup."Documents Folder", OneDriveSetup.TableCaption());
                    DocumentsFolderName := OneDriveSetup."Documents Folder Name";
                end;
        end;
        exit(DocumentsFolderName);
    end;

    local procedure GetImportedDocumentsFolderId(var ServiceIntegration: Enum "Service Integration"): Text
    var
        SharepointSetup: Record "Sharepoint Setup";
        OneDriveSetup: Record "OneDrive Setup";
        ImportedDocumentsFolderId: Text;
    begin
        case ServiceIntegration of
            ServiceIntegration::SharePoint:
                begin
                    CheckSetupEnabled(SharepointSetup);
                    CheckFolderSharedLinkNotEmpty(SharepointSetup."Imp. Documents Folder", SharepointSetup.TableCaption());
                    ImportedDocumentsFolderId := SharepointSetup."Imp. Documents Folder Id";
                end;
            ServiceIntegration::OneDrive:
                begin
                    CheckSetupEnabled(OneDriveSetup);
                    CheckFolderSharedLinkNotEmpty(OneDriveSetup."Imp. Documents Folder", OneDriveSetup.TableCaption());
                    ImportedDocumentsFolderId := OneDriveSetup."Imp. Documents Folder Id";
                end;
            else
                Error(UnsupportedIntegrationTypeErr);
        end;
        exit(ImportedDocumentsFolderId);
    end;


    local procedure CheckSetupEnabled(var OneDriveSetup: Record "OneDrive Setup")
    begin
        if not OneDriveSetup.Get() then
            Error(IntegrationNotEnabledErr, OneDriveSetup.TableCaption());
        if not OneDriveSetup.Enabled then
            Error(IntegrationNotEnabledErr, OneDriveSetup.TableCaption());
    end;

    local procedure CheckSetupEnabled(var SharepointSetup: Record "Sharepoint Setup")
    begin
        if not SharepointSetup.Get() then
            Error(IntegrationNotEnabledErr, SharepointSetup.TableCaption());
        if not SharepointSetup.Enabled then
            Error(IntegrationNotEnabledErr, SharepointSetup.TableCaption());
    end;

    local procedure CheckFolderSharedLinkNotEmpty(FolderSharedLink: Text; SetupTableCaption: Text)
    begin
        if FolderSharedLink = '' then
            Error(IntegrationNotEnabledErr, SetupTableCaption);
    end;

    var
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        NoContentErr: Label 'Empty content retrieved from the service for document id: %1.', Comment = '%1 - Document ID';
        IntegrationNotEnabledErr: Label '%1 must be enabled.', Comment = '%1 - a table caption, Sharepoint Document Import Setup';
        UnsupportedIntegrationTypeErr: Label 'You must choose a upported integration type.';
        DocumentIdEmptyErr: Label 'Drive Item Id is empty on e-document %1.', Comment = '%1 - an integer';
        DriveIdEmptyErr: Label 'Unable to determine the document library of the folder specified on the setup page. Verify that the shared link points to an existing folder and that you have access to it.';
        FoldersInDifferentDrivesErr: Label 'The archive folder must be in the same document library as the document folder.';
}
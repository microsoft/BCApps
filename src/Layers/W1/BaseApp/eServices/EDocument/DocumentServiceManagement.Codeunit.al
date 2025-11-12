// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System;
using System.Azure.Identity;
using System.Azure.KeyVault;
using System.Environment;
using System.Integration;
using System.IO;
using System.Privacy;
using System.Security.Authentication;
using System.Security.Encryption;
using System.Telemetry;
using System.Utilities;

codeunit 9510 "Document Service Management"
{
    // Provides functions for the storage of documents to online services such as O365 (Office 365).
    Permissions = tabledata "Tenant Media" = rimd;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        NoConfigErr: Label 'No online document configuration was found.';
        MultipleConfigsErr: Label 'More than one online document configuration was found.';
        SourceFileNotFoundErr: Label 'Cannot open the specified document from the following location: %1 due to the following error: %2.', Comment = '%1=Full path to the file on disk;%2=the detailed error describing why the document could not be accessed.';
        RequiredSourceNameErr: Label 'You must specify a source path for the document.';
        DocumentService: DotNet IDocumentService;
        DocumentServiceFactory: DotNet DocumentServiceFactory;
        ServiceType: Text;
        LastServiceType: Text;
        RequiredTargetNameErr: Label 'You must specify a name for the document.';
        RequiredTargetURIErr: Label 'You must specify the URI that you want to open.';
        ValidateConnectionErr: Label 'Cannot connect because the user name and password have not been specified, or because the connection was canceled.';
        AccessTokenErrMsg: Label 'Failed to acquire an access token.';
        AccessTokenEmptyErr: Label 'There was a problem authenticating. Please try to sign out and sign in again.';
        MissingClientIdOrSecretErr: Label 'The client ID or client secret have not been initialized.';
        SharePointIsoStorageSecretNotConfiguredErr: Label 'Client secret for SharePoint has not been configured.';
        SharePointIsoStorageSecretNotConfiguredLbl: Label 'Client secret for SharePoint has not been configured.', Locked = true;
        AuthTokenOrCodeNotReceivedErr: Label 'No access token or authorization error code received. The authorization failure error is: %1.', Comment = '%1=Authentiaction Failure Error', Locked = true;
        AccessTokenAcquiredFromCacheErr: Label 'The attempt to acquire the access token form cache has failed.', Locked = false;
        OAuthAuthorityUrlLbl: Label 'https://login.microsoftonline.com/common/oauth2', Locked = true;
        SharePointTelemetryCategoryTxt: Label 'AL Sharepoint Integration', Locked = true;
        SharePointClientIdAKVSecretNameLbl: Label 'sharepoint-clientid', Locked = true;
        SharePointClientSecretAKVSecretNameLbl: Label 'sharepoint-clientsecret', Locked = true;
        MissingClientIdTelemetryTxt: Label 'The client ID has not been initialized.', Locked = true;
        MissingClientSecretTelemetryTxt: Label 'The client secret has not been initialized.', Locked = true;
        InitializedClientIdTelemetryTxt: Label 'The client ID has been initialized.', Locked = true;
        InitializedClientSecretTelemetryTxt: Label 'The client secret has been initialized.', Locked = true;
        AcquiredTokenOnBehalfFlowTxt: Label 'Acquired a token using the on behalf flow.', Locked = true;
        CantFindMySiteErr: Label 'Could not determine the location of your OneDrive for Business, contact your partner to set this up.';
        CantFindMySiteTryLoginErr: Label 'Could not connect to your OneDrive for Business.\Try to sign in to OneDrive from your browser at https://portal.office.com/onedrive.\\Contact your partner if you''re unsure whether you have access to OneDrive.';
        UnknownLocationErr: Label 'An unexpected error occurred while trying to configure the Document Service. Try again later.';
        DocumentSharingNoNameErr: Label 'The document to be shared has not specified a name.';
        DocumentSharingNoExtErr: Label 'The document to be shared has not specified a file extension.';
        SharePointFileExistsInstructionsTxt: Label 'A file named "%1" already exists in your %2 folder in OneDrive for Business.\\ Would you like to use the existing file, add this new file as the latest version of the existing file, or rename it and keep them both?', Comment = '%1 = a file name, for example "CustomerCard.xlsx"; %2 = the product name, for example "Business Central"';
        SharePointFileExistsOptionsTxt: Label 'Use existing,Replace,Keep both', Comment = 'A comma separated list with options.';
        DocumentServiceCategoryLbl: Label 'AL DocumentService', Locked = true;
        DocumentSharingStartLbl: Label 'Handling document sharing event.', Locked = true;
        DocumentServiceDefaultingLbl: Label 'Configuring defaults for document service', Locked = true;
        DefaultLocationErrCodeErr: Label 'Graph request to determine root storage location resulted in status code: %1', Locked = true;
        CouldNotFindLocationInResponseErr: Label 'Graph request could not find the webUrl property for the default location.', Locked = true;
        LocationResponseInvalidErr: Label 'Graph request did not return a JSON document.', Locked = true;
        LocationFoundTxt: Label 'A default location was found of length %1', Locked = true;
        TokenRequestTxt: Label 'A token was requested. GetTokenFromCache: %1', Locked = true;
        CheckingDriveProgressTxt: Label 'Checking that you have a valid drive.';
        CheckingBcDocumentFolderProgressTxt: Label 'Checking that the default folder exists.';
        SharepointUnexpectedStatusCodeErr: Label 'OneDrive returned an unexpected error code: %1.', Comment = '%1 = An error code from OneDrive, for example 503';
        SharepointInvalidJsonErr: Label 'OneDrive returned an invalid response. Details: %1.', Comment = '%1 = The response details from OneDrive (e.g. "Your Drive is not available")';
        MissingOneDriveLicenseSaasErr: Label 'You don''t have a license for OneDrive.';
        MissingOneDriveLicenseOnPremErr: Label 'You don''t have a license for OneDrive, or your Microsoft Entra application for %1 on-premises doesn''t have the necessary permissions.', Comment = '%1 = the product name for Business Central';
        GraphApiUrlOnPremTxt: Label 'https://graph.microsoft.com', Locked = true;
        StartingLinkGenerationTelemetryMsg: Label 'Starting OneDrive link generation.', Locked = true;
        UsingDefaultDocumentServiceTelemetryMsg: Label 'Using default Document Service setup.', Locked = true;
        UsingCustomDocumentServiceTelemetryMsg: Label 'Using a Document Service retrieved from the database.', Locked = true;
        EmptyTokenTelemetryMsg: Label 'Empty access token from Azure AD Mgt.', Locked = true;
        SharepointStatusCodeTelemetryMsg: Label 'Sharepoint returned an error code: %1.', Locked = true;
        SharepointEmptyFileTelemetryMsg: Label 'Sharepoint returned an empty file.', Locked = true;
        SharepointFileTelemetryMsg: Label 'Sharepoint file size: %1', Locked = true;
        NoCompanyFolderTelemetryMsg: Label 'No company specific folder found, falling back to base Document Service folder.', Locked = true;
        NoCompanyOrBcFolderTelemetryMsg: Label 'No Document Service folder found, falling back to OneDrive root.', Locked = true;
        ConfigurationForTestConnectionTelemetryMsg: Label 'Configuration for test connection retrieved, with authentication: %1.', Locked = true;
        TrySaveStreamFromRecTelemetryMsg: Label 'TrySaveStreamFromRec started with conflict behavior: %1.', Locked = true;
        SettingResourceLocationTelemetryTxt: Label 'Setting resource location (old location length: %1, new location length: %2).', Locked = true;
        LocationTooLongTelemetryMsg: Label 'Maximum location length is %1, but the new location has length %2.', Locked = true;
        OneDriveFeatureNameTelemetryTxt: Label 'OneDrive', Locked = true;
        TokenRequestEventTelemetryTxt: Label 'Token Request', Locked = true;
        HttpsDomainTxt: Label 'https://%1', Locked = true;
        ValueDoesNotExistErr: Label 'Value does not exist: %1', Comment = '%1 = The response details from OneDrive (e.g. "Your Drive is not available")';
        DownloadUrlDoesNotExistErr: Label 'Download Url does not exist: %1', Comment = '%1 = The response details from OneDrive (e.g. "Your Drive is not available")';
        SharepointUnexpectedErr: Label 'OneDrive returned an unexpected value. Try again later.';
        SharepointItemIdMsg: Label 'OneDrive item: %1', Comment = '%1 = Item id of file', Locked = true;
        SharepointUnableToGetDownloadUrlMsg: Label 'No download url returned by sharepoint.', Locked = true;

    [Scope('OnPrem')]
    procedure TestConnection()
    var
        DocumentServiceRec: Record "Document Service";
        DocumentServiceHelper: DotNet NavDocumentServiceHelper;
    begin
        // Tests connectivity to the Document Service using the current configuration in Dynamics NAV.
        // An error occurrs if unable to successfully connect.
        if not IsConfiguredLegacy() then
            Error(NoConfigErr);

        DocumentServiceHelper.Reset();
        SetDocumentService();

        if DocumentServiceRec.FindFirst() then begin
            Session.LogMessage('0000FR2', StrSubstNo(ConfigurationForTestConnectionTelemetryMsg, DocumentServiceRec."Authentication Type"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);

            SetProperties(false, DocumentServiceRec);

            if DocumentServiceRec."Authentication Type" = DocumentServiceRec."Authentication Type"::Legacy then
                if IsNull(DocumentService.Credentials) then
                    Error(ValidateConnectionErr);
        end else
            Error(NoConfigErr);

        DocumentService.ValidateConnection();
        CheckError();
    end;

    [Scope('OnPrem')]
    procedure SaveFile(SourcePath: Text; TargetName: Text; ConflictBehavior: Enum "Doc. Sharing Conflict Behavior"): Text
    var
        SourceFile: File;
        SourceInStream: InStream;
    begin
        // Saves a file to the Document Service using the configured location specified in Dynamics NAV.
        // SourcePath: The path to a physical file on the Dynamics NAV server.
        // TargetName: The name which will be given to the file saved to the Document Service.
        // Overwrite: TRUE if the target file should be overwritten.
        // - An error is shown if Overwrite is FALSE and a file with that name already exists.
        // Returns: A URI to the file on the Document Service.

        if SourcePath = '' then
            Error(RequiredSourceNameErr);

        if TargetName = '' then
            Error(RequiredTargetNameErr);

        if not IsConfigured() then
            Error(NoConfigErr);

        if not SourceFile.Open(SourcePath) then
            Error(SourceFileNotFoundErr, SourcePath, GetLastErrorText);

        SourceFile.CreateInStream(SourceInStream);

        exit(SaveStream(SourceInStream, TargetName, ConflictBehavior));
    end;

    procedure RunDocumentServiceSetup(Notification: Notification)
    begin
        Page.Run(Page::"Document Service Setup");
    end;

    procedure GetOneDriveScenario(var DocumentServiceScenario: Record "Document Service Scenario"): Boolean
    var
        Company: Record "Company";
        NullGuid: Guid;
    begin
        Company.Get(CompanyName());

        if not DocumentServiceScenario.Get(DocumentServiceScenario."Service Integration"::OneDrive, Company.Id) then
            if not DocumentServiceScenario.Get(DocumentServiceScenario."Service Integration"::OneDrive, NullGuid) then
                exit(false);

        exit(true);
    end;

    procedure IsConfiguredLegacy(): Boolean
    var
        DocumentServiceRec: Record "Document Service";
        DocumentServiceScenario: Record "Document Service Scenario";
    begin
        if not DocumentServiceScenario.IsEmpty() then
            exit(false);

        if DocumentServiceRec.Count > 1 then
            Error(MultipleConfigsErr);

        if not DocumentServiceRec.FindFirst() then
            exit(false);

        if (DocumentServiceRec.Location = '') or (DocumentServiceRec.Folder = '') then
            exit(false);

        exit(true);
    end;

    local procedure IsOneDriveEnabled(): Boolean
    var
        DocumentServiceRec: Record "Document Service";
        DocumentServiceScenario: Record "Document Service Scenario";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        GetOneDriveScenario(DocumentServiceScenario);

        if not DocumentServiceScenario."Use for Application" then
            exit(false);

        if EnvironmentInformation.IsOnPrem() then begin
            if DocumentServiceScenario."Document Service" = '' then
                exit(false);

            exit(DocumentServiceRec.Get(DocumentServiceScenario."Document Service"));
        end;

        exit(true);
    end;

    local procedure IsOneDriveEnabledForSystem(): Boolean
    var
        DocumentServiceScenario: Record "Document Service Scenario";
    begin
        GetOneDriveScenario(DocumentServiceScenario);
        exit(DocumentServiceScenario."Use for Platform");
    end;

    local procedure IsOneDriveEnabledOrUsingLegacySetup(): Boolean
    var
        DocumentServiceScenario: Record "Document Service Scenario";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not DocumentServiceScenario.IsEmpty() then
            exit(IsOneDriveEnabled());

        exit(IsConfiguredLegacy() or EnvironmentInformation.IsSaaSInfrastructure());
    end;

    procedure IsConfigured(): Boolean
    var
        DocumentServiceRec: Record "Document Service";
        DocumentServiceScenario: Record "Document Service Scenario";
    begin
        // Returns TRUE if Dynamics NAV has been configured with a Document Service.
        OnBeforeIsConfigured(DocumentServiceRec);

        if not DocumentServiceScenario.IsEmpty() then
            exit(IsOneDriveEnabled());

        exit(IsConfiguredLegacy());
    end;

    [Scope('OnPrem')]
    procedure IsServiceUri(TargetURI: Text): Boolean
    var
        DocumentServiceRec: Record "Document Service";
        IsValid: Boolean;
    begin
        // Returns TRUE if the TargetURI points to a location on the currently-configured Document Service.

        if TargetURI = '' then
            exit(false);

        if DocumentServiceRec.FindLast() then
            if DocumentServiceRec.Location <> '' then begin
                SetDocumentService();
                SetProperties(true, DocumentServiceRec);
                IsValid := DocumentService.IsValidUri(TargetURI);
                CheckError();
                exit(IsValid);
            end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure SetServiceType(RequestedServiceType: Text)
    var
        DocumentServiceHelper: DotNet NavDocumentServiceHelper;
    begin
        // Sets the type name of the Document Service.
        // The type must match the DocumentServiceMetadata attribute value on the IDocumentServiceHandler interface
        // exposed by at least one assembly in the Server installation folder.
        // By default, Dynamics NAV uses the SharePoint Online Document Service with type named 'SHAREPOINTONLINE'.
        ServiceType := RequestedServiceType;
        DocumentServiceHelper.SetDocumentServiceType(RequestedServiceType);
    end;

    procedure GetServiceType(): Text
    begin
        // Gets the name of the current Document Service.

        exit(ServiceType);
    end;

    [Scope('OnPrem')]
    procedure OpenDocument(TargetURI: Text)
    begin
        // Navigates to the specified URI on the Document Service from the client device.

        if TargetURI = '' then
            Error(RequiredTargetURIErr);

        if not IsConfigured() then
            Error(NoConfigErr);

        SetDocumentService();
        HyperLink(DocumentService.GenerateViewableDocumentAddress(TargetURI));
        CheckError();
    end;

    local procedure InitializeDefaultService(var DocumentServiceRec: Record "Document Service"; Name: Code[30])
    var
        OAuth2: Codeunit OAuth2;
        RedirectUrl: Text;
    begin
        DocumentServiceRec.Init();
        DocumentServiceRec."Service ID" := Name;
        DocumentServiceRec."Authentication Type" := DocumentServiceRec."Authentication Type"::OAuth2;
        OAuth2.GetDefaultRedirectUrl(RedirectUrl);
        DocumentServiceRec."Redirect URL" := CopyStr(RedirectUrl, 1, MaxStrLen(DocumentServiceRec."Redirect URL"));
        DocumentServiceRec.Location := GetLocation();
        DocumentServiceRec.Folder := GetDefaultFolderName();
    end;

    procedure GetDefaultFolderName(): Text[250]
    begin
        exit(CopyStr(GetSafeDocumentServiceFolderName(ProductName.Short()), 1, 250));
    end;

    local procedure GetSafeCompanyName(): Text
    var
        Company: Record "Company";
        SafeCompanyName: Text;
    begin
        if (not Company.Get(CompanyName())) or (Company."Display Name" = '') then
            exit(GetSafeDocumentServiceFolderName(CompanyName()));

        SafeCompanyName := GetSafeDocumentServiceFolderName(Company."Display Name");

        if SafeCompanyName = '' then
            exit(GetSafeDocumentServiceFolderName(CompanyName()));

        exit(SafeCompanyName);
    end;

    local procedure GetSafeDocumentServiceFolderName(FolderName: Text): Text
    var
        FileManagement: Codeunit "File Management";
    begin
        FolderName := FileManagement.GetSafeFileName(FolderName);
        FolderName := DelChr(FolderName, '<', ' '); // Remove leading whitespace
        FolderName := DelChr(FolderName, '>', '. '); // Remove trailing periods and whitespace
        FolderName := DelChr(FolderName, '=', '%'); // Remove all percentage symbols

        exit(FolderName);
    end;

    local procedure GetLocation(): Text[250]
    var
        DocumentServiceScenario: Record "Document Service Scenario";
        DocumentServiceRec: Record "Document Service";
    begin
        if not GetOneDriveScenario(DocumentServiceScenario) then
            exit(GetDefaultLocation());

        if DocumentServiceScenario."Document Service" <> '' then
            if DocumentServiceRec.Get(DocumentServiceScenario."Document Service") then
                if DocumentServiceRec.Location <> '' then
                    exit(DocumentServiceRec.Location);

        exit(GetDefaultLocation());
    end;

    [TryFunction]
    procedure TryGetDefaultLocation(var Location: Text[250])
    begin
        Location := GetDefaultLocation();
    end;

    local procedure GetDefaultLocation(): Text[250]
    var
        UrlHelper: Codeunit "Url Helper";
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        UriBuilder: Codeunit "Uri Builder";
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        ResponseHeaders: DotNet NameValueCollection;
        StatusCode: DotNet HttpStatusCode;
        DriveJsonObject: JsonObject;
        Location: Text;
        ResponseContent: Text;
        ResponseErrorMessage: Text;
        ResponseErrorDetails: Text;
        Endpoint: Text;
        Token: SecretText;
    begin
        Endpoint := GetGraphDriveRootUrl();
        Token := AzureAdMgt.GetOnBehalfAccessTokenAsSecretText(UrlHelper.GetGraphUrl());

        if Token.IsEmpty() then begin
            Session.LogMessage('0000FSJ', EmptyTokenTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
            Error(AccessTokenEmptyErr);
        end;

        HttpWebRequestMgt.Initialize(Endpoint);
        HttpWebRequestMgt.DisableUI();
        HttpWebRequestMgt.SetReturnType('application/json');
        HttpWebRequestMgt.AddHeader('Authorization', SecretStrSubstNo('Bearer %1', Token));

        if not HttpWebRequestMgt.SendRequestAndReadTextResponse(ResponseContent, ResponseErrorMessage, ResponseErrorDetails, StatusCode, ResponseHeaders) then begin
            if StatusCode in [401, 404] then // Seems to mostly occur when the backend is still provisioning
                Error(CantFindMySiteTryLoginErr);

            CheckLicenseError(StatusCode, ResponseErrorDetails);

            Session.LogMessage('0000FJY', StrSubstNo(DefaultLocationErrCodeErr, StatusCode.ToString()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);
            Error(UnknownLocationErr);
        end;

        if not DriveJsonObject.ReadFrom(ResponseContent) then begin
            Session.LogMessage('0000FLF', LocationResponseInvalidErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);
            Error(UnknownLocationErr);
        end;

        if not ExtractWebUrlFromJson(DriveJsonObject, Location) then begin
            Session.LogMessage('0000FLG', CouldNotFindLocationInResponseErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);
            Error(CantFindMySiteTryLoginErr);
        end;

        UriBuilder.Init(Location);
        Location := 'https://' + UriBuilder.GetHost() + '/';

        Session.LogMessage('0000FLH', StrSubstNo(LocationFoundTxt, StrLen(Location)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);
        exit(CopyStr(Location, 1, 250));
    end;

    local procedure CheckLicenseError(HttpStatusCode: Integer; HttpErrorDetails: Text)
    begin
        if HttpStatusCode in [401, 403, 404] then
            LicenseError();

        if (HttpStatusCode = 400) and (StrPos(HttpErrorDetails, 'Tenant does not have a SPO license.') > 0) then
            LicenseError();
    end;

    local procedure SetResourceLocation(var DocumentServiceRec: Record "Document Service"): Boolean
    var
        NewLocation: Text;
    begin
        SetDocumentService();
        SetProperties(true, DocumentServiceRec);

        NewLocation := DocumentService.GetLocation();

        Session.LogMessage('0000GB1', StrSubstNo(SettingResourceLocationTelemetryTxt, StrLen(DocumentServiceRec.Location), StrLen(NewLocation)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);

        if NewLocation <> '' then begin
            if StrLen(NewLocation) > MaxStrLen(DocumentServiceRec.Location) then
                Session.LogMessage('0000GB2', StrSubstNo(LocationTooLongTelemetryMsg, MaxStrLen(DocumentServiceRec.Location), StrLen(NewLocation)), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);

            DocumentServiceRec.Location := CopyStr(NewLocation, 1, MaxStrLen(DocumentServiceRec.Location));
            exit(true);
        end;

        exit(false); // Couldn't resolve a location, credentials may be invalid for the target site
    end;

    [NonDebuggable]
    local procedure SetProperties(GetTokenFromCache: Boolean; var DocumentServiceRec: Record "Document Service")
    var
        DocumentServiceHelper: DotNet NavDocumentServiceHelper;
        AccessToken: SecretText;
    begin
        OnBeforeSetProperties(DocumentServiceRec);
        // The Document Service will throw an exception if the property is not known to the service type provider.
        DocumentService.Properties.SetProperty(DocumentServiceRec.FieldName(Description), DocumentServiceRec.Description);
        DocumentService.Properties.SetProperty(DocumentServiceRec.FieldName(Location), DocumentServiceRec.Location);
        DocumentService.Properties.SetProperty(DocumentServiceRec.FieldName("Document Repository"), DocumentServiceRec."Document Repository");
        DocumentService.Properties.SetProperty(DocumentServiceRec.FieldName(Folder), DocumentServiceRec.Folder);
        DocumentService.Properties.SetProperty(DocumentServiceRec.FieldName("Authentication Type"), DocumentServiceRec."Authentication Type");
        DocumentService.Properties.SetProperty(DocumentServiceRec.FieldName("User Name"), DocumentServiceRec."User Name");

        if (DocumentServiceRec."Authentication Type" = DocumentServiceRec."Authentication Type"::Legacy) then begin
            DocumentService.Properties.SetProperty(DocumentServiceRec.FieldName(Password), DocumentServiceRec.Password);
            DocumentService.Credentials := DocumentServiceHelper.ProvideCredentials();
        end else begin
            GetAccessToken(DocumentServiceRec.Location, AccessToken, GetTokenFromCache);
            DocumentService.Properties.SetProperty('Token', AccessToken.Unwrap());
        end;

        if not (DocumentServiceHelper.LastErrorMessage = '') then
            Error(DocumentServiceHelper.LastErrorMessage);
    end;

    procedure GetMyBusinessCentralFilesLink(): Text
    var
        PrivacyNotice: Codeunit "Privacy Notice";
        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
        DocumentServiceFolder: Text;
        DriveRootFolderJson: JsonObject;
        DriveBcFolderJson: JsonObject;
        DriveFolderUrl: Text;
        WebUrl: Text;
        ProgressDialog: Dialog;
    begin
        Session.LogMessage('0000FMJ', StartingLinkGenerationTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);

        if not PrivacyNotice.ConfirmPrivacyNoticeApproval(PrivacyNoticeRegistrations.GetOneDrivePrivacyNoticeId()) then
            exit;

        ProgressDialog.Open('#1##############################');

        ProgressDialog.Update(1, CheckingDriveProgressTxt);
        GetDriveFolderInfo(GetGraphDriveRootUrl(), DriveRootFolderJson);

        ProgressDialog.Update(1, CheckingBcDocumentFolderProgressTxt);
        // Try to open the company specific folder. If it does not exist, open the document service folder. Otherwise, show a dialog and fall back.
        DocumentServiceFolder := GetDocumentServiceFolder() + '/' + GetSafeCompanyName();
        DriveFolderUrl := MakeChildrenPathUrl(GetGraphDriveRootUrl(), DocumentServiceFolder);
        if GetDriveFolderInfo(DriveFolderUrl, DriveBcFolderJson) then
            if ExtractWebUrlFromJson(DriveBcFolderJson, WebUrl) then
                exit(WebUrl);

        Session.LogMessage('0000FN5', NoCompanyFolderTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
        DocumentServiceFolder := GetDocumentServiceFolder();
        DriveFolderUrl := MakeChildrenPathUrl(GetGraphDriveRootUrl(), DocumentServiceFolder);
        if GetDriveFolderInfo(DriveFolderUrl, DriveBcFolderJson) then
            if ExtractWebUrlFromJson(DriveBcFolderJson, WebUrl) then
                exit(WebUrl);

        Session.LogMessage('0000FN6', NoCompanyOrBcFolderTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
        if ExtractWebUrlFromJson(DriveRootFolderJson, WebUrl) then
            exit(WebUrl);
    end;

    [TryFunction]
    local procedure ExtractWebUrlFromJson(DriveBcFolderJson: JsonObject; var WebUrl: Text)
    var
        DriveWebUrlJson: JsonToken;
    begin
        if DriveBcFolderJson.Get('webUrl', DriveWebUrlJson) then
            if DriveWebUrlJson.IsValue then begin
                WebUrl := DriveWebUrlJson.AsValue().AsText();
                exit;
            end;

        Error('');
    end;

    [TryFunction]
    local procedure GetDriveFolderInfo(FolderUrl: Text; var FolderJson: JsonObject)
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        ResponseBody: Text;
        ErrorMessage: Text;
        ErrorDetails: Text;
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
    begin
        InitializeWebRequest(FolderUrl, 'GET', 'application/json', HttpWebRequestMgt);

        if not HttpWebRequestMgt.SendRequestAndReadTextResponse(ResponseBody, ErrorMessage, ErrorDetails, HttpStatusCode, ResponseHeaders) then begin
            Session.LogMessage('0000FML', StrSubstNo(SharepointStatusCodeTelemetryMsg, HttpStatusCode), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);

            CheckLicenseError(HttpStatusCode, ErrorDetails);
            Error(SharepointUnexpectedStatusCodeErr, HttpStatusCode);
        end;

        if not FolderJson.ReadFrom(ResponseBody) then
            Error(SharepointInvalidJsonErr, ResponseBody);
    end;

    [TryFunction]
    local procedure GetFileContent(var DocumentSharing: Record "Document Sharing")
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        TempBlob: Codeunit "Temp Blob";
        ErrorMessage: Text;
        ErrorDetails: Text;
        FileUrl: Text;
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
        InStream: InStream;
        OutStream: OutStream;
    begin
        ResolveItemId(DocumentSharing);
        GetFileDownloadUrl(DocumentSharing, FileUrl);

        InitializeWebRequest(FileUrl, 'GET', '', HttpWebRequestMgt);

        if not HttpWebRequestMgt.SendRequestAndReadResponse(TempBlob, ErrorMessage, ErrorDetails, HttpStatusCode, ResponseHeaders) then begin
            Session.LogMessage('0000IN8', StrSubstNo(SharepointStatusCodeTelemetryMsg, HttpStatusCode), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);

            CheckLicenseError(HttpStatusCode, ErrorDetails);
            Error(SharepointUnexpectedStatusCodeErr, HttpStatusCode);
        end;

        if TempBlob.Length() = 0 then
            Session.LogMessage('0000IN9', SharepointEmptyFileTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt)
        else begin
            Session.LogMessage('0000JB4', StrSubstNo(SharepointFileTelemetryMsg, TempBlob.Length()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
            DocumentSharing.Data.CreateOutStream(OutStream);
            TempBlob.CreateInStream(InStream);
            CopyStream(OutStream, InStream);
        end;
    end;

    [TryFunction]
    local procedure GetFileDownloadUrl(var DocumentSharing: Record "Document Sharing"; var FileUrl: Text)
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        ErrorMessage: Text;
        ErrorDetails: Text;
        MetadataUrl: Text;
        ResponseBody: Text;
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
        JsonObject: JsonObject;
        JsonToken: JsonToken;
    begin
        MetadataUrl := GetGraphFileByIdUrl(DocumentSharing."Item Id");

        InitializeWebRequest(MetadataUrl, 'GET', 'application/json', HttpWebRequestMgt);

        if not HttpWebRequestMgt.SendRequestAndReadTextResponse(ResponseBody, ErrorMessage, ErrorDetails, HttpStatusCode, ResponseHeaders) then begin
            Session.LogMessage('0000IN8', StrSubstNo(SharepointStatusCodeTelemetryMsg, HttpStatusCode), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);

            CheckLicenseError(HttpStatusCode, ErrorDetails);
            Error(SharepointUnexpectedStatusCodeErr, HttpStatusCode);
        end;

        if not JsonObject.ReadFrom(ResponseBody) then
            Error(SharepointInvalidJsonErr, ResponseBody);

        if not JsonObject.Get('@microsoft.graph.downloadUrl', JsonToken) then
            Error(DownloadUrlDoesNotExistErr, ResponseBody);

        FileUrl := JsonToken.AsValue().AsText();

        if FileUrl = '' then
            Session.LogMessage('0000JWY', SharepointUnableToGetDownloadUrlMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
    end;

    [TryFunction]
    local procedure DeleteDriveItem(DocumentSharing: Record "Document Sharing")
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        ResponseBody: Text;
        ErrorMessage: Text;
        ErrorDetails: Text;
        FileUrl: Text;
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
    begin
        ResolveItemId(DocumentSharing);
        FileUrl := GetGraphFileByIdUrl(DocumentSharing."Item Id");

        InitializeWebRequest(FileUrl, 'DELETE', 'application/json', HttpWebRequestMgt);

        if not HttpWebRequestMgt.SendRequestAndReadTextResponse(ResponseBody, ErrorMessage, ErrorDetails, HttpStatusCode, ResponseHeaders) then begin
            Session.LogMessage('0000J18', StrSubstNo(SharepointStatusCodeTelemetryMsg, HttpStatusCode), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);

            CheckLicenseError(HttpStatusCode, ErrorDetails);
        end;
    end;

    local procedure ResolveItemId(var DocumentSharing: Record "Document Sharing")
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        JsonObject: JsonObject;
        JsonToken: JsonToken;
        JsonValue: JsonValue;
        ResponseBody: Text;
        ErrorMessage: Text;
        ErrorDetails: Text;
        FileUrl: Text;
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
    begin
        // Item Id has already been retrieved.
        if DocumentSharing."Item Id" <> '' then
            exit;

        FileUrl := GetGraphItemIdUrl(DocumentSharing);
        InitializeWebRequest(FileUrl, 'GET', 'application/json', HttpWebRequestMgt);

        if not HttpWebRequestMgt.SendRequestAndReadTextResponse(ResponseBody, ErrorMessage, ErrorDetails, HttpStatusCode, ResponseHeaders) then begin
            Session.LogMessage('0000J19', StrSubstNo(SharepointStatusCodeTelemetryMsg, HttpStatusCode), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);

            CheckLicenseError(HttpStatusCode, ErrorDetails);
            Error(SharepointUnexpectedStatusCodeErr, HttpStatusCode);
        end;

        if not JsonObject.ReadFrom(ResponseBody) then
            Error(SharepointInvalidJsonErr, ResponseBody);

        if not JsonObject.Get('id', JsonToken) then
            Error(ValueDoesNotExistErr, ResponseBody);

        JsonValue := JsonToken.AsValue();
        DocumentSharing."Item Id" := CopyStr(JsonValue.AsText(), 1, MaxStrLen(DocumentSharing."Item Id"));

        if DocumentSharing."Item Id" = '' then
            Error(SharepointUnexpectedErr);

        Session.LogMessage('0000JB5', StrSubstNo(SharepointItemIdMsg, DocumentSharing."Item Id"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
    end;

    local procedure InitializeWebRequest(Url: Text; Method: Text; ReturnType: Text; var HttpWebRequestMgt: Codeunit "Http Web Request Mgt.")
    var
        AzureADMgt: Codeunit "Azure AD Mgt.";
        Token: SecretText;
    begin
        Token := AzureADMgt.GetAccessTokenAsSecretText(GetGraphDomain(), AzureADMgt.GetO365ResourceName(), false);
        if Token.IsEmpty() then begin
            Session.LogMessage('0000FMK', EmptyTokenTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
            LicenseError();
        end;

        HttpWebRequestMgt.Initialize(Url);
        HttpWebRequestMgt.DisableUI();
        HttpWebRequestMgt.SetMethod(Method);
        HttpWebRequestMgt.SetReturnType(ReturnType);
        HttpWebRequestMgt.AddHeader('Authorization', SecretStrSubstNo('Bearer %1', Token));
    end;

    local procedure LicenseError()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then
            Error(MissingOneDriveLicenseSaasErr)
        else
            Error(MissingOneDriveLicenseOnPremErr, ProductName.Short());
    end;

    local procedure GetDocumentServiceFolder(): Text
    var
        DocumentServiceRec: Record "Document Service";
    begin
        if IsConfiguredLegacy() then begin
            DocumentServiceRec.FindFirst();
            Session.LogMessage('0000FMM', UsingCustomDocumentServiceTelemetryMsg, Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
            exit(DocumentServiceRec.Folder);
        end;

        Session.LogMessage('0000FMN', UsingDefaultDocumentServiceTelemetryMsg, Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
        exit(GetDefaultFolderName());
    end;

    local procedure GetGraphDriveUrl(): Text
    var
        Domain: Text;
    begin
        Domain := GetGraphDomain();

        Domain := DelChr(Domain, '>', '/');
        Domain += '/v1.0/me/drive';

        exit(Domain);
    end;

    local procedure GetGraphDriveRootUrl(): Text
    begin
        exit(GetGraphDriveUrl() + '/root');
    end;

    local procedure GetGraphDriveItemUrl(): Text
    begin
        exit(GetGraphDriveUrl() + '/items');
    end;

    local procedure GetGraphItemIdUrl(DocumentSharing: Record "Document Sharing"): Text
    var
        FileUrl: Text;
    begin
        // The DocumentUri contains /Document at the start and needs to be removed for getting the file-path
        FileUrl := ':/' + DocumentSharing.DocumentUri.Remove(1, StrLen(DocumentSharing.DocumentRootUri + '/Document'));
        exit(GetGraphDriveRootUrl() + FileUrl);
    end;

    local procedure GetGraphFileByIdUrl(ItemId: Text): Text
    begin
        exit(GetGraphDriveItemUrl() + '/' + ItemId);
    end;

    local procedure MakeChildrenPathUrl(RootDriveUrl: Text; FolderString: Text): Text
    var
        Uri: Codeunit Uri;
        Folders: List of [Text];
        Folder: Text;
    begin
        // From: https://go.microsoft.com/fwlink/?linkid=2206172
        // A driveItem can be addressed by either a unique identifier or where that item exists in the drive's hierarchy (i.e. user path).
        // Within an API request, a colon can be used to shift between API path space and user path space.
        // Ensure user data within the URL follows the addressing and path encoding requirements.
        // Examples:
        // /drive/root:/path/to/file                          -> Access a driveItem by path under the root.

        Folders := FolderString.Split('/');
        RootDriveUrl := DelChr(RootDriveUrl, '>', '/') + ':';

        foreach Folder in Folders do
            if Folder <> '' then
                RootDriveUrl := RootDriveUrl + '/' + Uri.EscapeDataString(Folder);

        exit(RootDriveUrl);
    end;

    local procedure GetGraphDomain(): Text
    var
        UrlHelper: Codeunit "Url Helper";
        Domain: Text;
    begin
        Domain := UrlHelper.GetGraphUrl();
        if Domain = '' then
            Domain := GraphApiUrlOnPremTxt; // This fallback is needed for OnPremise

        exit(Domain)
    end;

    local procedure SetDocumentService()
    var
        RequestedServiceType: Text;
    begin
        // Sets the Document Service for the current Service Type, reusing an existing service if possible.

        RequestedServiceType := GetServiceType();

        if RequestedServiceType = '' then
            RequestedServiceType := 'SHAREPOINTONLINE';

        if LastServiceType <> RequestedServiceType then begin
            DocumentService := DocumentServiceFactory.CreateService(RequestedServiceType);
            LastServiceType := RequestedServiceType;
        end;
    end;

    local procedure CheckError()
    begin
        // Checks whether the Document Service received an error and displays that error to the user.

        if not IsNull(DocumentService.LastError) and (DocumentService.LastError.Message <> '') then
            Error(DocumentService.LastError.Message);
    end;

    [TryFunction]
    local procedure TrySaveStreamFromRec(InStream: InStream; TargetName: Text; ConflictBehavior: Enum "Doc. Sharing Conflict Behavior"; var DocumentServiceRec: Record "Document Service"; var DocumentUri: Text; var UploadedFileName: Text)
    var
        LocalDocumentService: Record "Document Service";
        DotNetConflictBehavior: DotNet ConflictBehavior;
        DotNetUploadedDocument: DotNet UploadedDocument;
    begin
        Session.LogMessage('0000FTC', StrSubstNo(TrySaveStreamFromRecTelemetryMsg, Format(ConflictBehavior)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
        Clear(DocumentUri);

        // Saves a stream to the Document Service using the configured location specified in Dynamics NAV.
        SetDocumentService();

        if DocumentServiceRec."Service ID" <> '' then
            SetProperties(true, DocumentServiceRec)
        else begin
            if not LocalDocumentService.FindFirst() then
                Error(NoConfigErr);

            if LocalDocumentService."Authentication Type" = LocalDocumentService."Authentication Type"::OAuth2 then
                SetResourceLocation(LocalDocumentService);

            SetProperties(true, LocalDocumentService);
        end;

        DotNetConflictBehavior := ConflictBehavior.AsInteger();
        DotNetUploadedDocument := DocumentService.Save(InStream, TargetName, DotNetConflictBehavior);
        CheckError();

        UploadedFileName := TargetName;
        if not IsNull(DotNetUploadedDocument) then begin
            if not IsNull(DotNetUploadedDocument.Uri) then
                DocumentUri := DotNetUploadedDocument.Uri.AbsoluteUri;
            if not IsNull(DotNetUploadedDocument.FileName) then
                UploadedFileName := DotNetUploadedDocument.FileName;
        end;
    end;

    local procedure SaveStream(InStream: InStream; TargetName: Text; ConflictBehavior: Enum "Doc. Sharing Conflict Behavior") DocumentUri: Text
    var
        DocumentServiceRec: Record "Document Service";
        TempDocumentServiceRec: Record "Document Service" temporary;
        UploadedFileName: Text;
        DocumentSharingSource: Enum "Document Sharing Source";
    begin
        if IsOneDriveEnabled() then begin
            InitTempDocumentServiceRecord(TempDocumentServiceRec, DocumentSharingSource::App);
            TrySaveStreamFromRec(InStream, TargetName, ConflictBehavior, TempDocumentServiceRec, DocumentUri, UploadedFileName);
        end else
            TrySaveStreamFromRec(InStream, TargetName, ConflictBehavior, DocumentServiceRec, DocumentUri, UploadedFileName);
    end;
#if not CLEAN25

    [NonDebuggable]
    [Obsolete('Replaced by GetAccessToken(Location: Text; var AccessToken: SecretText; GetTokenFromCache: Boolean)', '25.0')]
    local procedure GetAccessToken(Location: Text; var AccessToken: Text; GetTokenFromCache: Boolean)
    var
        AccessTokenAsSecretText: SecretText;
    begin
        AccessTokenAsSecretText := AccessToken;
        GetAccessToken(Location, AccessTokenAsSecretText, GetTokenFromCache);
        AccessToken := AccessTokenAsSecretText.Unwrap();
    end;
#endif

    local procedure GetAccessToken(Location: Text; var AccessToken: SecretText; GetTokenFromCache: Boolean)
    var
        DocumentServiceScenario: Record "Document Service Scenario";
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        EnvironmentInformation: Codeunit "Environment Information";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        OAuth2: Codeunit OAuth2;
        PromptInteraction: Enum "Prompt Interaction";
        Scopes: List of [Text];
        ClientId: Text;
        ClientSecret: SecretText;
        Resource: Text;
        RedirectURL: Text;
        AuthError: Text;
    begin
        Session.LogMessage('0000FSI', StrSubstNo(TokenRequestTxt, Format(GetTokenFromCache)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
        FeatureTelemetry.LogUsage('0000HUM', OneDriveFeatureNameTelemetryTxt, TokenRequestEventTelemetryTxt); // To Account for Platform usage scenarios

        Clear(AccessToken);
        Resource := GetResourceUrl(Location);
        if EnvironmentInformation.IsSaaSInfrastructure() then
            AccessToken := AzureAdMgt.GetOnBehalfAccessTokenAsSecretText(Resource)
        else
            if not DocumentServiceScenario.IsEmpty() then
                AccessToken := AzureAdMgt.GetAccessTokenAsSecretText(Resource, Resource, true);

        if not AccessToken.IsEmpty() then begin
            Session.LogMessage('0000GPT', AcquiredTokenOnBehalfFlowTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
            exit;
        end;

        if (not DocumentServiceScenario.IsEmpty()) then
            Error(AccessTokenErrMsg); // oauth fields are no longer used

        GetScopes(Location, Scopes);
        ClientId := GetClientId();
        ClientSecret := GetClientSecret();
        RedirectURL := GetRedirectURL();

        if GetTokenFromCache then
            OAuth2.AcquireAuthorizationCodeTokenFromCache(ClientId, ClientSecret, RedirectURL, OAuthAuthorityUrlLbl, Scopes, AccessToken);
        if not AccessToken.IsEmpty() then
            exit;

        Session.LogMessage('0000DB7', AccessTokenAcquiredFromCacheErr, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
        OAuth2.AcquireTokenByAuthorizationCode(
                    ClientId,
                    ClientSecret,
                    OAuthAuthorityUrlLbl,
                    RedirectURL,
                    Scopes,
                    PromptInteraction::"Select Account",
                    AccessToken,
                    AuthError
                );

        if AccessToken.IsEmpty() then begin
            Session.LogMessage('0000DB8', StrSubstNo(AuthTokenOrCodeNotReceivedErr, AuthError), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
            Error(AccessTokenErrMsg);
        end;
    end;

    local procedure GetClientId(): Text
    var
        DocumentServiceRec: Record "Document Service";
        AzureKeyVault: Codeunit "Azure Key Vault";
        EnvironmentInformation: Codeunit "Environment Information";
        [NonDebuggable]
        ClientId: Text;
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then
            if not AzureKeyVault.GetAzureKeyVaultSecret(SharePointClientIdAKVSecretNameLbl, ClientId) then
                Session.LogMessage('0000DB9', MissingClientIdTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt)
            else begin
                Session.LogMessage('0000DBA', InitializedClientIdTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
                exit(ClientId);
            end;

        if DocumentServiceRec.FindFirst() then begin
            ClientId := DocumentServiceRec."Client Id";
            OnGetSharePointClientId(ClientId);
            if ClientId <> '' then begin
                Session.LogMessage('0000DBB', InitializedClientIdTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
                exit(ClientId);
            end;
        end;

        Error(MissingClientIdOrSecretErr);
    end;

    local procedure GetClientSecret(): SecretText
    var
        DocumentServiceRec: Record "Document Service";
        AzureKeyVault: Codeunit "Azure Key Vault";
        EnvironmentInformation: Codeunit "Environment Information";
        ClientSecret: SecretText;
        [NonDebuggable]
        ClientSecretFromEvent: Text;
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then
            if not AzureKeyVault.GetAzureKeyVaultSecret(SharePointClientSecretAKVSecretNameLbl, ClientSecret) then
                Session.LogMessage('0000DBC', MissingClientSecretTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt)
            else begin
                Session.LogMessage('0000DBD', InitializedClientSecretTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
                exit(ClientSecret);
            end;

        if not DocumentServiceRec.IsEmpty() then begin
            ClientSecret := GetClientSecretFromIsolatedStorage();
            if not ClientSecret.IsEmpty() then begin
                Session.LogMessage('0000DBE', InitializedClientSecretTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
                exit(ClientSecret);
            end;
        end;

        OnGetSharePointClientSecret(ClientSecretFromEvent);
        ClientSecret := ClientSecretFromEvent;
        if not ClientSecret.IsEmpty() then begin
            Session.LogMessage('0000DBF', InitializedClientSecretTelemetryTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
            exit(ClientSecret);
        end;

        Error(MissingClientIdOrSecretErr);
    end;

    [Scope('OnPrem')]
    local procedure GetRedirectURL(): Text
    var
        DocumentServiceRec: Record "Document Service";
        EnvironmentInformation: Codeunit "Environment Information";
        RedirectURL: Text;
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() then
            exit(RedirectURL);

        if DocumentServiceRec.FindFirst() then
            RedirectURL := DocumentServiceRec."Redirect URL";

        if RedirectURL = '' then
            OnGetSharePointRedirectURL(RedirectURL);

        exit(RedirectURL);
    end;

    local procedure GetScopes(Location: Text; var Scopes: List of [Text])
    begin
        Location := GetResourceUrl(Location);
        Scopes.Add(Location + '/AllSites.FullControl');
        Scopes.Add(Location + '/User.ReadWrite.All');
    end;

    local procedure GetResourceUrl(Location: Text): Text
    var
        Uri: Codeunit Uri;
    begin
        Uri.Init(Location);
        exit(StrSubstNo(HttpsDomainTxt, Uri.GetHost()));
    end;

    [Scope('OnPrem')]
    internal procedure SetClientSecret(ClientSecret: SecretText)
    var
        DocumentServiceRec: Record "Document Service";
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
    begin
        if not DocumentServiceRec.FindFirst() then
            Error(NoConfigErr);

        if ClientSecret.IsEmpty() then
            if not IsNullGuid(DocumentServiceRec."Client Secret Key") then begin
                IsolatedStorageManagement.Delete(DocumentServiceRec."Client Secret Key", DATASCOPE::Company);
                exit;
            end;

        if IsNullGuid(DocumentServiceRec."Client Secret Key") then begin
            DocumentServiceRec."Client Secret Key" := CreateGuid();
            DocumentServiceRec.Modify();
        end;

        IsolatedStorageManagement.Set(DocumentServiceRec."Client Secret Key", ClientSecret, DATASCOPE::Company);
    end;

    [Scope('OnPrem')]
    local procedure GetClientSecretFromIsolatedStorage(): SecretText
    var
        DocumentServiceRec: Record "Document Service";
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";
        ClientSecret: SecretText;
    begin
        if not DocumentServiceRec.FindFirst() then
            Error(NoConfigErr);

        if IsNullGuid(DocumentServiceRec."Client Secret Key") or
           not IsolatedStorage.Contains(DocumentServiceRec."Client Secret Key", DATASCOPE::Company)
        then begin
            Session.LogMessage('0000DBG', SharePointIsoStorageSecretNotConfiguredLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', SharePointTelemetryCategoryTxt);
            Error(SharePointIsoStorageSecretNotConfiguredErr);
        end;

        IsolatedStorageManagement.Get(DocumentServiceRec."Client Secret Key", DATASCOPE::Company, ClientSecret);
        exit(ClientSecret);
    end;

    [Scope('OnPrem')]
    [TryFunction]
    internal procedure TryGetClientSecretFromIsolatedStorage(var ClientSecret: SecretText)
    begin
        ClientSecret := GetClientSecretFromIsolatedStorage();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OnOpenInExcel', '', false, false)]
    [NonDebuggable]
    local procedure OnTryAcquireAccessTokenOnOpenInExcel(Location: Text)
    var
        DocumentServiceScenario: Record "Document Service Scenario";
        DocumentServiceRec: Record "Document Service";
        ResultJson: JsonObject;
        Token: SecretText;
        Result: Text;
    begin
        if DocumentServiceScenario.IsEmpty() then begin
            GetAccessToken(Location, Token, true);
            Session.SetDocumentServiceToken(Token.Unwrap());
        end;

        if Location = '' then
            Location := GetDefaultLocation();

        GetAccessToken(Location, Token, true);

        ResultJson.Add(DocumentServiceRec.FieldName(Location), Location);
        ResultJson.Add(DocumentServiceRec.FieldName(Folder), GetDefaultFolderName() + '/' + GetSafeCompanyName());
        ResultJson.Add('Token', Token.Unwrap());

        ResultJson.WriteTo(Result);
        Session.SetDocumentServiceToken(Result);
    end;

    procedure OpenInOneDrive(FileName: Text; FileExtension: Text; InStream: InStream)
    var
        DocumentSharing: Codeunit "Document Sharing";
    begin
        DocumentSharing.Share(FileName, FileExtension, InStream, Enum::"Document Sharing Intent"::Open);
    end;

    procedure EditInOneDrive(FileName: Text; FileExtension: Text; var TempBlob: Codeunit "Temp Blob"): Boolean
    begin
        exit(EditInOneDrive(FileName, FileExtension, Enum::"Doc. Sharing Conflict Behavior"::Ask, TempBlob));
    end;

    procedure EditInOneDrive(FileName: Text; FileExtension: Text; DocSharingConflictBehavior: Enum "Doc. Sharing Conflict Behavior"; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        TempDocumentSharing: Record "Document Sharing" temporary;
        DocumentSharing: Codeunit "Document Sharing";
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        Hash: Text;
        InStream: InStream;
        OutStream: OutStream;
    begin
        TempDocumentSharing.Name := CopyStr(FileName, 1, MaxStrLen(TempDocumentSharing.Name));
        TempDocumentSharing.Extension := CopyStr(FileExtension, 1, MaxStrLen(TempDocumentSharing.Extension));
        TempDocumentSharing."Document Sharing Intent" := Enum::"Document Sharing Intent"::Edit;
        TempDocumentSharing."Conflict Behavior" := DocSharingConflictBehavior;

        TempBlob.CreateInStream(InStream);
        TempDocumentSharing.Data.CreateOutStream(OutStream);
        CopyStream(OutStream, Instream);
        TempBlob.CreateInStream(InStream);

        Hash := CryptographyManagement.GenerateHash(InStream, HashAlgorithmType::SHA1);

        TempDocumentSharing.Insert();
        DocumentSharing.Share(TempDocumentSharing);

        TempBlob.CreateOutStream(OutStream);
        TempDocumentSharing.Data.CreateInStream(InStream);
        CopyStream(OutStream, InStream);
        TempBlob.CreateInStream(InStream);

        exit(Hash <> CryptographyManagement.GenerateHash(InStream, HashAlgorithmType::SHA1));
    end;

    procedure OpenInOneDriveFromMedia(FileName: Text; FileExtension: Text; MediaId: Guid)
    var
        DocumentSharingIntent: Enum "Document Sharing Intent";
    begin
        InvokeDocumentSharingFlowFromMedia(FileName, FileExtension, MediaId, DocumentSharingintent::Open);
    end;

    procedure EditInOneDriveFromMedia(FileName: Text; FileExtension: Text; MediaId: Guid): Boolean
    var
        DocumentSharingIntent: Enum "Document Sharing Intent";
    begin
        exit(InvokeDocumentSharingFlowFromMedia(FileName, FileExtension, MediaId, DocumentSharingintent::Edit));
    end;

    procedure ShareWithOneDrive(FileName: Text; FileExtension: Text; InStream: InStream)
    var
        DocumentSharing: Codeunit "Document Sharing";
    begin
        DocumentSharing.Share(FileName, FileExtension, InStream, Enum::"Document Sharing Intent"::Share);
    end;

    procedure ShareWithOneDriveFromMedia(FileName: Text; FileExtension: Text; MediaId: Guid)
    var
        DocumentSharingIntent: Enum "Document Sharing Intent";
    begin
        InvokeDocumentSharingFlowFromMedia(FileName, FileExtension, MediaId, DocumentSharingintent::Share);
    end;

    local procedure InvokeDocumentSharingFlowFromMedia(FileName: Text; FileExtension: Text; MediaId: Guid; DocumentSharingIntent: Enum "Document Sharing Intent"): Boolean
    var
        TempDocumentSharing: Record "Document Sharing" temporary;
        TenantMedia: Record "Tenant Media";
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        InStream: InStream;
        OutStream: OutStream;
        Hash: Text;
    begin
        SetFileNameAndExtension(TempDocumentSharing, FileName, FileExtension);

        TenantMedia.Get(MediaId);
        TenantMedia.CalcFields(Content);
        TempDocumentSharing.Data := TenantMedia.Content;
        TempDocumentSharing."Document Sharing Intent" := DocumentSharingIntent;
        TempDocumentSharing.Insert();
        TempDocumentSharing.Data.CreateInStream(InStream);
        Hash := CryptographyManagement.GenerateHash(InStream, HashAlgorithmType::SHA1);
        Codeunit.Run(Codeunit::"Document Sharing", TempDocumentSharing);

        if (DocumentSharingIntent = Enum::"Document Sharing Intent"::Edit) and
            (Hash <> CryptographyManagement.GenerateHash(InStream, HashAlgorithmType::SHA1)) then begin
            TempDocumentSharing.Data.CreateInStream(InStream);
            TenantMedia.Content.CreateOutStream(OutStream);

            CopyStream(OutStream, InStream);
            TenantMedia.Modify();
            exit(true);
        end;
    end;
#if not CLEAN25

    [Scope('OnPrem')]
    [NonDebuggable]
    [Obsolete('Replaced by TestLocationResolves(Location: Text[250]; AccessToken: SecretText)', '25.0')]
    procedure TestLocationResolves(Location: Text[250]; AccessToken: Text): Boolean
    var
        AccessTokenAsSecretText: SecretText;
    begin
        AccessTokenAsSecretText := AccessToken;
        exit(TestLocationResolves(Location, AccessTokenAsSecretText))
    end;
#endif

    [NonDebuggable]
    [Scope('OnPrem')]
    procedure TestLocationResolves(Location: Text[250]; AccessToken: SecretText): Boolean
    var
        DocumentServiceRec: Record "Document Service";
    begin
        SetDocumentService();

        DocumentService.Properties.SetProperty(DocumentServiceRec.FieldName(Location), Location);
        DocumentService.Properties.SetProperty(DocumentServiceRec.FieldName(Folder), GetDefaultFolderName());
        DocumentService.Properties.SetProperty(DocumentServiceRec.FieldName("Authentication Type"), DocumentServiceRec."Authentication Type"::OAuth2);
        DocumentService.Properties.SetProperty(DocumentServiceRec.FieldName("User Name"), '');
        DocumentService.Properties.SetProperty(DocumentServiceRec.FieldName("Document Repository"), '');
        DocumentService.Properties.SetProperty('Token', AccessToken.Unwrap());

        Location := DocumentService.GetLocation();
        exit(Location <> '');
    end;

    local procedure InitTempDocumentServiceRecord(var TempDocumentServiceRec: Record "Document Service" temporary; Source: Enum "Document Sharing Source")
    var
        DocumentServiceRec: Record "Document Service";
        DocumentServiceScenario: Record "Document Service Scenario";
        EnvironmentInformation: Codeunit "Environment Information";
        ScenarioEnabled: Boolean;
    begin
        if Source = Source::App then
            ScenarioEnabled := IsOneDriveEnabled()
        else
            ScenarioEnabled := IsOneDriveEnabledForSystem();

        if (ScenarioEnabled or (EnvironmentInformation.IsSaaSInfrastructure() and DocumentServiceScenario.IsEmpty())) then begin // has new config and app is enabled, or no new config + SaaS
            Session.LogMessage('0000FK0', DocumentServiceDefaultingLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);
            InitializeDefaultService(TempDocumentServiceRec, 'SHARE');
        end else begin
            if not DocumentServiceScenario.IsEmpty() or not DocumentServiceRec.FindFirst() then
                Error(CantFindMySiteErr); // either the new setup has disabled the flow, or there is no setup

            TempDocumentServiceRec.TransferFields(DocumentServiceRec);
        end;

        Clear(TempDocumentServiceRec."User Name"); // Clearing the user name will ensure the NST uploads to the personal store (e.g. OneDrive)
        TempDocumentServiceRec.Folder := CopyStr(TempDocumentServiceRec.Folder + '/' + GetSafeCompanyName(), 1, MaxStrLen(TempDocumentServiceRec.Folder));

        if not SetResourceLocation(TempDocumentServiceRec) then
            Error(CantFindMySiteTryLoginErr);
    end;

    local procedure SetFileNameAndExtension(var TempDocumentSharing: Record "Document Sharing" temporary; FileName: Text; FileExtension: Text)
    begin
        TempDocumentSharing.Name := CopyStr(FileName, 1, MaxStrLen(TempDocumentSharing.Name) - StrLen(FileExtension)) + FileExtension;
        TempDocumentSharing.Extension := CopyStr(FileExtension, 1, MaxStrLen(TempDocumentSharing.Extension));
    end;

    internal procedure GetTelemetryCategory(): Text
    begin
        exit(DocumentServiceCategoryLbl);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Sharing", 'OnCanUploadDocument', '', false, false)]
    local procedure OnCanUploadDocument(var CanUpload: Boolean)
    var
        PrivacyNotice: Codeunit "Privacy Notice";
        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
    begin
        if CanUpload then
            exit;

        if PrivacyNotice.IsApprovalStateDisagreed(PrivacyNoticeRegistrations.GetOneDrivePrivacyNoticeId()) then
            exit;

        CanUpload := IsOneDriveEnabledOrUsingLegacySetup();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Sharing", 'OnCanUploadSystemDocument', '', false, false)]
    local procedure OnCanUploadSystemDocument(var CanUpload: Boolean)
    var
        PrivacyNotice: Codeunit "Privacy Notice";
        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
    begin
        if CanUpload then
            exit;

        if PrivacyNotice.IsApprovalStateDisagreed(PrivacyNoticeRegistrations.GetOneDrivePrivacyNoticeId()) then
            exit;

        CanUpload := IsOneDriveEnabledForSystem();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Sharing", 'OnUploadDocument', '', false, false)]
    local procedure OnUploadDocument(var DocumentSharing: Record "Document Sharing" temporary; var Handled: Boolean)
    var
        TempDocumentServiceRec: Record "Document Service" temporary;
        PrivacyNotice: Codeunit "Privacy Notice";
        FileManagement: Codeunit "File Management";
        PrivacyNoticeRegistrations: Codeunit "Privacy Notice Registrations";
        DocumentUri: Text;
        UploadedFileName: Text;
        InStr: InStream;
        OutStr: OutStream;
    begin
        if Handled then
            exit;

        Session.LogMessage('0000FJZ', DocumentSharingStartLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceCategoryLbl);

        if DocumentSharing.Source = DocumentSharing.Source::App then
            if (not IsOneDriveEnabledOrUsingLegacySetup()) then
                exit;

        if DocumentSharing.Source = DocumentSharing.Source::System then
            if (not IsOneDriveEnabledForSystem()) then
                exit;

        if not PrivacyNotice.ConfirmPrivacyNoticeApproval(PrivacyNoticeRegistrations.GetOneDrivePrivacyNoticeId()) then
            exit;

        DocumentSharing.Name := CopyStr(FileManagement.GetSafeFileName(DocumentSharing.Name), 1, MaxStrLen(DocumentSharing.Name));
        if DocumentSharing.Name = '' then
            Error(DocumentSharingNoNameErr);

        if DocumentSharing.Extension = '' then
            Error(DocumentSharingNoExtErr);

        InitTempDocumentServiceRecord(TempDocumentServiceRec, DocumentSharing.Source);

        DocumentSharing.CalcFields(DocumentSharing.Data);
        DocumentSharing.Data.CreateInStream(InStr);

        if not GuiAllowed() then
            TrySaveStreamFromRec(InStr, DocumentSharing.Name, Enum::"Doc. Sharing Conflict Behavior"::Fail, TempDocumentServiceRec, DocumentUri, UploadedFileName)
        else
            if not TrySaveStreamFromRec(InStr, DocumentSharing.Name, Enum::"Doc. Sharing Conflict Behavior"::Fail, TempDocumentServiceRec, DocumentUri, UploadedFileName)
                or (DocumentUri = '')
            then
                // Use given behavior if not behavior "Ask"
                if DocumentSharing."Conflict Behavior" <> Enum::"Doc. Sharing Conflict Behavior"::Ask then
                    TrySaveStreamFromRec(InStr, DocumentSharing.Name, DocumentSharing."Conflict Behavior", TempDocumentServiceRec, DocumentUri, UploadedFileName)
                else
                    case StrMenu(SharePointFileExistsOptionsTxt, 0, StrSubstNo(SharePointFileExistsInstructionsTxt, DocumentSharing.Name, ProductName.Short())) of
                        0: // Cancel
                            begin
                                Handled := false;
                                exit;
                            end;
                        1: // Reuse
                            TrySaveStreamFromRec(InStr, DocumentSharing.Name, Enum::"Doc. Sharing Conflict Behavior"::Reuse, TempDocumentServiceRec, DocumentUri, UploadedFileName);
                        2: // Replace
                            TrySaveStreamFromRec(InStr, DocumentSharing.Name, Enum::"Doc. Sharing Conflict Behavior"::Replace, TempDocumentServiceRec, DocumentUri, UploadedFileName);
                        3: // Keep both
                            TrySaveStreamFromRec(InStr, DocumentSharing.Name, Enum::"Doc. Sharing Conflict Behavior"::Rename, TempDocumentServiceRec, DocumentUri, UploadedFileName);
                    end;

        DocumentSharing.Name := CopyStr(UploadedFileName, 1, MaxStrLen(DocumentSharing.Name));
        DocumentSharing.DocumentUri := CopyStr(DocumentUri, 1, MaxStrLen(DocumentSharing.DocumentUri));

        DocumentSharing.Token.CreateOutStream(OutStr);
        OutStr.WriteText(DocumentService.Properties.GetProperty('Token'));

        DocumentSharing.DocumentPreviewUri := CopyStr(
            DocumentService.GenerateViewableDocumentAddress(DocumentSharing.DocumentUri),
            1,
            MaxStrLen(DocumentSharing.DocumentPreviewUri));

        if DocumentService.Properties.IsPropertySet('DocumentRootLocation') then
            DocumentSharing.DocumentRootUri := DocumentService.Properties.GetProperty('DocumentRootLocation');

        DocumentSharing.Modify();

        Handled := DocumentSharing.DocumentUri <> '';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Sharing", 'OnGetFileContents', '', false, false)]
    local procedure OnGetFileContents(var DocumentSharing: Record "Document Sharing" temporary; var Handled: Boolean)
    begin
        if Handled then
            exit;
        Handled := GetFileContent(DocumentSharing);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Sharing", 'OnDeleteDocument', '', false, false)]
    local procedure OnDeleteDocument(var DocumentSharing: Record "Document Sharing" temporary; var Handled: Boolean)
    begin
        if Handled then
            exit;
        Handled := DeleteDriveItem(DocumentSharing);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsConfigured(var DocumentServiceRec: Record "Document Service")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetProperties(var DocumentServiceRec: Record "Document Service")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSharePointClientId(var ClientId: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSharePointClientSecret(var ClientSecret: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSharePointRedirectURL(var RedirectURL: Text)
    begin
    end;
}


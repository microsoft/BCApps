namespace System.Integration;

using Microsoft.CRM.Outlook;
using System;
using System.Environment;

codeunit 5320 "Exchange Web Services Client"
{

    trigger OnRun()
    begin
    end;

    var
        TempExchangeFolder: Record "Exchange Folder" temporary;
        [RunOnClient]
        ServiceOnClient: DotNet ExchangeServiceWrapper;
        ConnectionFailedErr: Label 'Connection to the Exchange server failed.';
        LongPathsOmittedMsg: Label 'Folders with a path that exceeds 250 characters have been omitted.';
        ServiceOnServer: DotNet ExchangeServiceWrapper;
        LongPathsDetected: Boolean;
        CategoryTxt: Label 'AL EWS Client', Locked = true;
        FolderFoundOnServerTxt: Label 'Folder has been found on server.', Locked = true;
        FolderFoundOnClientTxt: Label 'Folder has been found on client.', Locked = true;
        FolderNotFoundOnServerTxt: Label 'Folder has not been found on server.', Locked = true;
        FolderNotFoundOnClientTxt: Label 'Folder has not been found on client.', Locked = true;
        InitializedOnServerWithImpersonationTxt: Label 'Service has been initialized on server with impersonation.', Locked = true;
        InitializedOnServerTxt: Label 'Service has been initialized on server.', Locked = true;
        InitializedOnClientTxt: Label 'Service has been initialized on client.', Locked = true;
        NotInitializedOnServerWithImpersonationTxt: Label 'Service has not been initialized on server with impersonation.', Locked = true;
        NotInitializedOnServerTxt: Label 'Service has not been initialized on server.', Locked = true;
        NotInitializedOnClientTxt: Label 'Service has not been initialized on client.', Locked = true;
        ServiceInvalidatedTxt: Label 'Service has been invlidated.', Locked = true;
        ConnectionFailedTxt: Label 'Connection to the Exchange server failed.', Locked = true;
        InvalidCredentialsOnClientTxt: Label 'Invalid credentials on client.', Locked = true;
        InvalidCredentialsOnServerTxt: Label 'Invalid credentials on server.', Locked = true;
        ValidCredentialsOnServerTxt: Label 'Credentials successfully validated on server.', Locked = true;
        ValidCredentialsOnClientTxt: Label 'Credentials successfully validated on server.', Locked = true;
        PublicFolderFoundOnClientTxt: Label 'Public folder has been found on client.', Locked = true;
        PublicFolderFoundOnServerTxt: Label 'Public folder has been found on server.', Locked = true;
        PublicFolderNotFoundTxt: Label 'Public folder has not been found.', Locked = true;
        PublicFolderCachedTxt: Label 'Public folder is cached.', Locked = true;
        ServiceOnServerLastErrorTxt: Label 'Service on server last error: %1.', Locked = true;
        ServiceOnClientLastErrorTxt: Label 'Service on client last error: %1.', Locked = true;

    [Scope('OnPrem')]
    procedure GetPublicFolders(var ExchangeFolder: Record "Exchange Folder"): Boolean
    begin
        if not IsServiceValid() then begin
            Session.LogMessage('0000D87', ConnectionFailedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
            Error(ConnectionFailedErr);
        end;

        if IsNull(ServiceOnServer) then begin
            if GetPublicFoldersOnClient(ExchangeFolder) then begin
                Session.LogMessage('0000D88', PublicFolderFoundOnClientTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
                exit(true);
            end;
            Session.LogMessage('0000DA2', PublicFolderNotFoundTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
            exit(false);
        end;

        if GetPublicFoldersOnServer(ExchangeFolder) then begin
            Session.LogMessage('0000D89', PublicFolderFoundOnServerTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
            exit(true);
        end;
        Session.LogMessage('0000D8A', PublicFolderNotFoundTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
        exit(false);
    end;

    local procedure GetPublicFoldersOnClient(var ExchangeFolder: Record "Exchange Folder") FoundAny: Boolean
    var
        [RunOnClient]
        ParentInfo: DotNet FolderInfo;
        [RunOnClient]
        SubFolders: DotNet FolderInfoEnumerator;
    begin
        if ExchangeFolder.Cached then begin
            Session.LogMessage('0000D8B', PublicFolderCachedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
            exit(false);
        end;

        if ExchangeFolder."Unique ID".HasValue() then begin
            ParentInfo := ParentInfo.FolderInfo(ExchangeFolder.GetUniqueID(), ExchangeFolder.FullPath);
            ExchangeFolder.Cached := true;
            ExchangeFolder.Modify();
        end;

        FoundAny := false;
        LongPathsDetected := false;

        SubFolders := ServiceOnClient.GetPublicFolders(ParentInfo, 1000);

        if not IsNull(SubFolders) then begin
            while SubFolders.MoveNextPage() do
                while SubFolders.MoveNext() do
                    if StrLen(SubFolders.Current.FullPath) > 250 then
                        LongPathsDetected := true
                    else
                        if not TempExchangeFolder.Get(CopyStr(SubFolders.Current.FullPath, 1, 250)) then
                            if IsAllowedFolderType(SubFolders.Current.FolderClass) then begin
                                FoundAny := true;
                                TempExchangeFolder.Init();
                                TempExchangeFolder.FullPath := SubFolders.Current.FullPath;
                                TempExchangeFolder.Depth := SubFolders.Current.Depth;
                                TempExchangeFolder.SetUniqueID(SubFolders.Current.UniqueId);
                                TempExchangeFolder.Name := SubFolders.Current.Name;
                                TempExchangeFolder.Cached := false;
                                TempExchangeFolder.Insert();
                            end;
            if LongPathsDetected then
                Message(LongPathsOmittedMsg);
            ReadBuffer(ExchangeFolder);
        end;

        if ServiceOnClient.LastError <> '' then begin
            LogLastClientError();
            Message(ServiceOnClient.LastError);
        end;

        exit(FoundAny);
    end;

    local procedure GetPublicFoldersOnServer(var ExchangeFolder: Record "Exchange Folder") FoundAny: Boolean
    var
        ParentInfo: DotNet FolderInfo;
        SubFolders: DotNet FolderInfoEnumerator;
    begin
        if ExchangeFolder.Cached then begin
            Session.LogMessage('0000D8D', PublicFolderCachedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
            exit(false);
        end;

        if ExchangeFolder."Unique ID".HasValue() then begin
            ParentInfo := ParentInfo.FolderInfo(ExchangeFolder.GetUniqueID(), ExchangeFolder.FullPath);
            ExchangeFolder.Cached := true;
            ExchangeFolder.Modify();
        end;

        FoundAny := false;
        LongPathsDetected := false;

        SubFolders := ServiceOnServer.GetPublicFolders(ParentInfo, 1000);

        if not IsNull(SubFolders) then begin
            while SubFolders.MoveNextPage() do
                while SubFolders.MoveNext() do
                    if StrLen(SubFolders.Current.FullPath) > 250 then
                        LongPathsDetected := true
                    else
                        if not TempExchangeFolder.Get(CopyStr(SubFolders.Current.FullPath, 1, 250)) then
                            if IsAllowedFolderType(SubFolders.Current.FolderClass) then begin
                                FoundAny := true;
                                TempExchangeFolder.Init();
                                TempExchangeFolder.FullPath := SubFolders.Current.FullPath;
                                TempExchangeFolder.Depth := SubFolders.Current.Depth;
                                TempExchangeFolder.SetUniqueID(SubFolders.Current.UniqueId);
                                TempExchangeFolder.Name := SubFolders.Current.Name;
                                TempExchangeFolder.Cached := false;
                                TempExchangeFolder.Insert();
                            end;
            if LongPathsDetected then
                Message(LongPathsOmittedMsg);
            ReadBuffer(ExchangeFolder);
        end;

        if ServiceOnServer.LastError <> '' then begin
            LogLastServerError();
            Message(ServiceOnServer.LastError);
        end;

        exit(FoundAny);
    end;

    [Scope('OnPrem')]
    procedure InitializeOnClient(AutodiscoveryEmail: Text[250]; ServiceUri: Text): Boolean
    var
        ClientTypeManagement: Codeunit "Client Type Management";
        [RunOnClient]
        ServiceFactoryOnClient: DotNet ServiceWrapperFactory;
        Initialized: Boolean;
    begin
        if ClientTypeManagement.GetCurrentClientType() <> CLIENTTYPE::Windows then
            exit(false);
        if IsNull(ServiceOnClient) then begin
            InvalidateService();
            ServiceOnClient := ServiceFactoryOnClient.CreateServiceWrapper();
        end;

        if ServiceUri <> '' then
            ServiceOnClient.ExchangeServiceUrl := ServiceUri;

        Initialized := ServiceOnClient.ExchangeServiceUrl <> '';
        if not Initialized then
            Initialized := ServiceOnClient.AutodiscoverServiceUrl(AutodiscoveryEmail);

        if Initialized then
            Session.LogMessage('0000D8F', InitializedOnClientTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt)
        else begin
            Session.LogMessage('0000D8G', NotInitializedOnClientTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
            LogLastClientError();
        end;
        exit(Initialized);
    end;

    [Scope('OnPrem')]
    procedure InitializeOnServer(AutodiscoveryEmail: Text[250]; ServiceUri: Text; Credentials: DotNet NetworkCredential): Boolean
    var
        ServiceFactoryOnServer: DotNet ServiceWrapperFactory;
        Initialized: Boolean;
    begin
        if IsNull(ServiceOnServer) then begin
            InvalidateService();
            ServiceOnServer := ServiceFactoryOnServer.CreateServiceWrapperWithCredentials(Credentials);
        end;

        if ServiceUri <> '' then
            ServiceOnServer.ExchangeServiceUrl := ServiceUri;

        Initialized := ServiceOnServer.ExchangeServiceUrl <> '';
        if not Initialized then
            Initialized := ServiceOnServer.AutodiscoverServiceUrl(AutodiscoveryEmail);

        if Initialized then
            Session.LogMessage('0000D8H', InitializedOnServerTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt)
        else begin
            Session.LogMessage('0000D8I', NotInitializedOnServerTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
            LogLastServerError();
        end;

        exit(Initialized);
    end;

    [Scope('OnPrem')]
    procedure InitializeOnServerWithImpersonation(AutodiscoveryEmail: Text[250]; ServiceUri: Text; Credentials: DotNet OAuthCredentials): Boolean
    var
        ServiceFactoryOnServer: DotNet ServiceWrapperFactory;
        Initialized: Boolean;
    begin
        if IsNull(ServiceOnServer) then begin
            InvalidateService();
            ServiceOnServer := ServiceFactoryOnServer.CreateServiceWrapper();
        end;

        ServiceOnServer.SetNetworkCredential(Credentials);
        ServiceOnServer.SetImpersonatedIdentity(AutodiscoveryEmail);

        if ServiceUri <> '' then
            ServiceOnServer.ExchangeServiceUrl := ServiceUri;

        Initialized := ServiceOnServer.ExchangeServiceUrl <> '';
        if not Initialized then
            Initialized := ServiceOnServer.AutodiscoverServiceUrl(AutodiscoveryEmail);

        if Initialized then
            Session.LogMessage('0000D8J', InitializedOnServerWithImpersonationTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt)
        else begin
            Session.LogMessage('0000D8K', NotInitializedOnServerWithImpersonationTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
            LogLastServerError();
        end;

        exit(Initialized);
    end;

    [Scope('OnPrem')]
    procedure FolderExists(UniqueID: Text): Boolean
    var
        Exists: Boolean;
    begin
        if not IsServiceValid() then begin
            Session.LogMessage('0000D8L', ConnectionFailedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
            Error(ConnectionFailedErr);
        end;
        if IsNull(ServiceOnServer) then begin
            Exists := ServiceOnClient.FolderExists(UniqueID);
            if Exists then
                Session.LogMessage('0000D8M', FolderFoundOnClientTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt)
            else begin
                Session.LogMessage('0000D8N', FolderNotFoundOnClientTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
                LogLastClientError();
            end;
        end else begin
            Exists := ServiceOnServer.FolderExists(UniqueID);
            if Exists then
                Session.LogMessage('0000D8O', FolderFoundOnServerTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt)
            else begin
                Session.LogMessage('0000D8P', FolderNotFoundOnServerTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
                LogLastServerError();
            end;
        end;
        exit(Exists);
    end;

    procedure ReadBuffer(var DestExchangeFolder: Record "Exchange Folder"): Boolean
    begin
        if TempExchangeFolder.FindSet() then
            repeat
                if not DestExchangeFolder.Get(TempExchangeFolder.FullPath) then begin
                    TempExchangeFolder.CalcFields("Unique ID");
                    DestExchangeFolder.Init();
                    DestExchangeFolder.TransferFields(TempExchangeFolder);
                    DestExchangeFolder.Insert();
                end;
            until TempExchangeFolder.Next() = 0
        else
            exit(false);
        exit(true);
    end;

    local procedure IsAllowedFolderType(FolderClass: Text): Boolean
    begin
        if FolderClass = '' then
            exit(true);

        if FolderClass = 'IPF.Note' then
            exit(true);

        exit(false);
    end;

    local procedure IsServiceValid(): Boolean
    begin
        if IsNull(ServiceOnServer) and IsNull(ServiceOnClient) then
            exit(false);

        if IsNull(ServiceOnServer) then
            exit(ServiceOnClient.ExchangeServiceUrl <> '');
        exit(ServiceOnServer.ExchangeServiceUrl <> '');
    end;

    procedure InvalidateService()
    begin
        Clear(ServiceOnClient);
        Clear(ServiceOnServer);
        Clear(TempExchangeFolder);
        Clear(LongPathsDetected);
        Session.LogMessage('0000D8Q', ServiceInvalidatedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
    end;

    [Scope('OnPrem')]
    procedure ValidateCredentialsOnServer(): Boolean
    begin
        if not ServiceOnServer.ValidateCredentials() then begin
            Session.LogMessage('0000D8R', InvalidCredentialsOnServerTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
            LogLastServerError();
            exit(false);
        end;
        Session.LogMessage('0000D8S', ValidCredentialsOnServerTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ValidateCredentialsOnClient(): Boolean
    begin
        if not ServiceOnClient.ValidateCredentials() then begin
            Session.LogMessage('0000D8T', InvalidCredentialsOnClientTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
            LogLastClientError();
            exit(false);
        end;
        Session.LogMessage('0000D8U', ValidCredentialsOnClientTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
        exit(true);
    end;

    local procedure LogLastServerError()
    var
        LastError: Text;
    begin
        LastError := ServiceOnServer.LastError();
        if LastError <> '' then
            Session.LogMessage('0000D8E', StrSubstNo(ServiceOnServerLastErrorTxt, LastError), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
    end;

    local procedure LogLastClientError()
    var
        LastError: Text;
    begin
        LastError := ServiceOnClient.LastError();
        if LastError <> '' then
            Session.LogMessage('0000D8C', StrSubstNo(ServiceOnClientLastErrorTxt, LastError), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
    end;
}


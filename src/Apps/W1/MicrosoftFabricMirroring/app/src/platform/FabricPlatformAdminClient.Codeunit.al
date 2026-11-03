namespace Microsoft.FabricExport;

using Microsoft.Utilities;
using System.RestClient;

codeunit 48526 "Fabric Platform Admin Client"
{
    Access = Internal;

    var
        RetrieveWorkspacesTransportErr: Label 'Failed to retrieve workspaces: transport error.';
        RetrieveWorkspacesHttpGenericErr: Label 'Failed to retrieve workspaces. Contact your administrator if the problem persists.';
        RetrieveWorkspacesHttpErr: Label 'Failed to retrieve workspaces. HTTP %1.', Comment = '%1 = HTTP status code';
        RetrieveWorkspacesMalformedErr: Label 'Failed to retrieve workspaces: malformed response from Microsoft Fabric.';
        WorkspaceRequiredForMirroredDbErr: Label 'Select a workspace before choosing an Open Mirroring database.';
        RetrieveMirroredDbsTransportErr: Label 'Failed to retrieve Open Mirroring databases: transport error.';
        RetrieveMirroredDbsHttpGenericErr: Label 'Failed to retrieve Open Mirroring databases. Contact your administrator if the problem persists.';
        RetrieveMirroredDbsHttpStatusErr: Label 'Failed to retrieve Open Mirroring databases. HTTP %1.', Comment = '%1 = HTTP status code';
        RetrieveMirroredDbsMalformedErr: Label 'Failed to retrieve Open Mirroring databases: malformed response from Microsoft Fabric.';
        WorkspaceRequiredForSPErr: Label 'Select a workspace before adding the service principal.';
        PrincipalIdRequiredErr: Label 'Principal ID is missing. Ask your Microsoft Entra administrator for the object ID of the enterprise application, enter it on the Fabric setup page, and try again.';
        ReadPrincipalIdSetupInstructionsLbl: Label 'Read setup instructions';
        PrincipalIdSetupHelpUrlTok: Label 'https://go.microsoft.com/fwlink/?LinkId=2386618', Locked = true;
        AddSPTransportErr: Label 'Failed to add service principal to workspace: transport error.';
        AddSPHttpGenericErr: Label 'Failed to add service principal to workspace. Contact your administrator if the problem persists.';
        AddSPHttpStatusErr: Label 'Failed to add service principal to workspace. HTTP %1.', Comment = '%1 = HTTP status code';
        VerifyWorkspaceRoleTransportErr: Label 'Failed to verify the existing workspace role: transport error.';
        VerifyWorkspaceRoleHttpGenericErr: Label 'Failed to verify the existing workspace role. Contact your administrator if the problem persists.';
        VerifyWorkspaceRoleHttpStatusErr: Label 'Failed to verify the existing workspace role. HTTP %1.', Comment = '%1 = HTTP status code';
        VerifyWorkspaceRoleMalformedErr: Label 'Failed to verify the existing workspace role: malformed response from Microsoft Fabric.';
        WorkspaceRoleRequiredErr: Label 'The service principal must have Contributor, Member, or Admin access on the Fabric workspace. Ask your workspace administrator to verify its role, then try again.';
        MirroredDatabasesUrlTok: Label 'https://api.fabric.microsoft.com/v1/workspaces/%1/mirroredDatabases', Comment = '%1 = workspace ID', Locked = true;
        RoleAssignmentsUrlTok: Label 'https://api.fabric.microsoft.com/v1/workspaces/%1/roleAssignments', Comment = '%1 = workspace ID', Locked = true;

    /// <summary>Fills TempBuffer with Fabric workspaces accessible to the delegated token (Name = display name, Value = workspace GUID).</summary>
    procedure GetWorkspaces(var TempBuffer: Record "Name/Value Buffer" temporary)
    var
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        HttpClient: Codeunit "Fabric Platform Http Client";
        FabricPrivacyNotice: Codeunit "Fabric Privacy Notice";
        RestClientResult: Codeunit "Rest Client";
        Req: Codeunit "Http Request Message";
        Resp: Codeunit "Http Response Message";
        AccessToken: SecretText;
        RootObj: JsonObject;
        ArrayToken: JsonToken;
        ItemToken: JsonToken;
        ItemObj: JsonObject;
        IdToken: JsonToken;
        NameToken: JsonToken;
        JsonArr: JsonArray;
        i: Integer;
    begin
        FabricPrivacyNotice.EnsureApproved();

        TempBuffer.Reset();
        TempBuffer.DeleteAll(false);

        AccessToken := CredMgt.AcquireFabricApiTokenDelegated();
        RestClientResult := HttpClient.CreateClientWithBearer(AccessToken);
        Req := HttpClient.BuildJsonRequest('GET', 'https://api.fabric.microsoft.com/v1/workspaces', '');
        if not HttpClient.TrySend(RestClientResult, Req, Resp) then
            Error(RetrieveWorkspacesTransportErr);
        if not Resp.GetIsSuccessStatusCode() then
            Error(CreateRetrieveWorkspacesHttpErrorInfo(Resp.GetHttpStatusCode()));

        RootObj.ReadFrom(Resp.GetContent().AsText());
        if not RootObj.Get('value', ArrayToken) then
            Error(RetrieveWorkspacesMalformedErr);
        JsonArr := ArrayToken.AsArray();
        for i := 0 to JsonArr.Count() - 1 do begin
            JsonArr.Get(i, ItemToken);
            ItemObj := ItemToken.AsObject();
            if ItemObj.Get('id', IdToken) and ItemObj.Get('displayName', NameToken) then begin
                TempBuffer.ID := i + 1;
                TempBuffer.Name := CopyStr(NameToken.AsValue().AsText(), 1, MaxStrLen(TempBuffer.Name));
                TempBuffer.Value := CopyStr(IdToken.AsValue().AsText(), 1, MaxStrLen(TempBuffer.Value));
                TempBuffer.Insert(false);
            end;
        end;
    end;

    /// <summary>Fills TempBuffer with Open Mirroring databases in WorkspaceId (Name = display name, Value = mirrored database GUID).</summary>
    procedure GetMirroredDatabases(WorkspaceId: Text; var TempBuffer: Record "Name/Value Buffer" temporary)
    var
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        HttpClient: Codeunit "Fabric Platform Http Client";
        Telemetry: Codeunit "Fabric Platform Telemetry";
        FabricPrivacyNotice: Codeunit "Fabric Privacy Notice";
        RestClientResult: Codeunit "Rest Client";
        Req: Codeunit "Http Request Message";
        Resp: Codeunit "Http Response Message";
        AccessToken: SecretText;
        RootObj: JsonObject;
        ArrayToken: JsonToken;
        ItemToken: JsonToken;
        ItemObj: JsonObject;
        IdToken: JsonToken;
        NameToken: JsonToken;
        JsonArr: JsonArray;
        WorkspaceIdForUrl: Text;
        i: Integer;
    begin
        FabricPrivacyNotice.EnsureApproved();
        if WorkspaceId = '' then
            Error(WorkspaceRequiredForMirroredDbErr);

        WorkspaceIdForUrl := FormatGuidForFabricUrl(WorkspaceId);
        if WorkspaceIdForUrl = '' then
            Error(WorkspaceRequiredForMirroredDbErr);

        TempBuffer.Reset();
        TempBuffer.DeleteAll(false);

        AccessToken := CredMgt.AcquireFabricApiTokenDelegated();
        RestClientResult := HttpClient.CreateClientWithBearer(AccessToken);
        Req := HttpClient.BuildJsonRequest(
            'GET',
            StrSubstNo(MirroredDatabasesUrlTok, WorkspaceIdForUrl),
            '');
        if not HttpClient.TrySend(RestClientResult, Req, Resp) then
            Error(RetrieveMirroredDbsTransportErr);
        if not Resp.GetIsSuccessStatusCode() then begin
            Session.LogMessage('0000WBZ', StrSubstNo(RetrieveMirroredDbsHttpStatusErr, Resp.GetHttpStatusCode()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, Telemetry.GetDimensions());
            Error(CreateMirroredDbsHttpErrorInfo(Resp.GetHttpStatusCode()));
        end;
        if not RootObj.ReadFrom(Resp.GetContent().AsText()) then
            Error(RetrieveMirroredDbsMalformedErr);
        if not RootObj.Get('value', ArrayToken) then
            Error(RetrieveMirroredDbsMalformedErr);
        JsonArr := ArrayToken.AsArray();
        for i := 0 to JsonArr.Count() - 1 do begin
            JsonArr.Get(i, ItemToken);
            ItemObj := ItemToken.AsObject();
            if ItemObj.Get('id', IdToken) and ItemObj.Get('displayName', NameToken) then begin
                TempBuffer.ID := i + 1;
                TempBuffer.Name := CopyStr(NameToken.AsValue().AsText(), 1, MaxStrLen(TempBuffer.Name));
                TempBuffer.Value := CopyStr(IdToken.AsValue().AsText(), 1, MaxStrLen(TempBuffer.Value));
                TempBuffer.Insert(false);
            end;
        end;
    end;

    procedure AddServicePrincipalToWorkspace(WorkspaceId: Text; PrincipalId: Text)
    var
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        HttpClient: Codeunit "Fabric Platform Http Client";
        FabricPrivacyNotice: Codeunit "Fabric Privacy Notice";
        RestClientResult: Codeunit "Rest Client";
        Req: Codeunit "Http Request Message";
        Resp: Codeunit "Http Response Message";
        AccessToken: SecretText;
        WorkspaceIdForUrl: Text;
        BodyObj: JsonObject;
        PrincipalObj: JsonObject;
        Body: Text;
    begin
        FabricPrivacyNotice.EnsureApproved();
        if WorkspaceId = '' then
            Error(WorkspaceRequiredForSPErr);
        if PrincipalId.Trim() = '' then
            Error(CreatePrincipalIdRequiredErrorInfo());

        WorkspaceIdForUrl := FormatGuidForFabricUrl(WorkspaceId);
        if WorkspaceIdForUrl = '' then
            Error(WorkspaceRequiredForSPErr);

        AccessToken := CredMgt.AcquireFabricApiTokenDelegated();

        PrincipalObj.Add('id', PrincipalId);
        PrincipalObj.Add('type', 'ServicePrincipal');
        BodyObj.Add('principal', PrincipalObj);
        BodyObj.Add('role', 'Contributor');
        BodyObj.WriteTo(Body);

        RestClientResult := HttpClient.CreateClientWithBearer(AccessToken);
        Req := HttpClient.BuildJsonRequest(
            'POST',
            StrSubstNo(RoleAssignmentsUrlTok, WorkspaceIdForUrl),
            Body);
        if not HttpClient.TrySend(RestClientResult, Req, Resp) then
            Error(AddSPTransportErr);
        if Resp.GetIsSuccessStatusCode() then
            exit;
        if Resp.GetHttpStatusCode() = 409 then begin
            if not HasRequiredWorkspaceRole(WorkspaceIdForUrl, PrincipalId, AccessToken) then
                Error(WorkspaceRoleRequiredErr);
            exit;
        end;
        Error(CreateAddSPHttpErrorInfo(Resp.GetHttpStatusCode()));
    end;

    local procedure HasRequiredWorkspaceRole(WorkspaceId: Text; PrincipalId: Text; AccessToken: SecretText): Boolean
    var
        HttpClient: Codeunit "Fabric Platform Http Client";
        RestClientResult: Codeunit "Rest Client";
        Req: Codeunit "Http Request Message";
        Resp: Codeunit "Http Response Message";
        RootObj: JsonObject;
        ItemObj: JsonObject;
        PrincipalObj: JsonObject;
        ArrayToken: JsonToken;
        ItemToken: JsonToken;
        PrincipalToken: JsonToken;
        IdToken: JsonToken;
        RoleToken: JsonToken;
        ContinuationToken: JsonToken;
        JsonArr: JsonArray;
        VisitedUrls: List of [Text];
        BaseUrl: Text;
        RequestUrl: Text;
        NextRequestUrl: Text;
        i: Integer;
    begin
        RestClientResult := HttpClient.CreateClientWithBearer(AccessToken);
        BaseUrl := StrSubstNo(RoleAssignmentsUrlTok, WorkspaceId);
        RequestUrl := BaseUrl;
        repeat
            if VisitedUrls.Contains(RequestUrl) then
                Error(VerifyWorkspaceRoleMalformedErr);
            VisitedUrls.Add(RequestUrl);

            Req := HttpClient.BuildJsonRequest('GET', RequestUrl, '');
            if not HttpClient.TrySend(RestClientResult, Req, Resp) then
                Error(VerifyWorkspaceRoleTransportErr);
            if not Resp.GetIsSuccessStatusCode() then
                Error(CreateVerifyWorkspaceRoleHttpErrorInfo(Resp.GetHttpStatusCode()));

            Clear(RootObj);
            if not RootObj.ReadFrom(Resp.GetContent().AsText()) then
                Error(VerifyWorkspaceRoleMalformedErr);
            if not RootObj.Get('value', ArrayToken) then
                Error(VerifyWorkspaceRoleMalformedErr);
            if not ArrayToken.IsArray() then
                Error(VerifyWorkspaceRoleMalformedErr);
            JsonArr := ArrayToken.AsArray();
            for i := 0 to JsonArr.Count() - 1 do begin
                JsonArr.Get(i, ItemToken);
                if not ItemToken.IsObject() then
                    Error(VerifyWorkspaceRoleMalformedErr);
                ItemObj := ItemToken.AsObject();
                if not ItemObj.Get('principal', PrincipalToken) then
                    Error(VerifyWorkspaceRoleMalformedErr);
                if not PrincipalToken.IsObject() then
                    Error(VerifyWorkspaceRoleMalformedErr);
                PrincipalObj := PrincipalToken.AsObject();
                if not PrincipalObj.Get('id', IdToken) then
                    Error(VerifyWorkspaceRoleMalformedErr);
                if not IdToken.IsValue() then
                    Error(VerifyWorkspaceRoleMalformedErr);
                if IdToken.AsValue().IsNull() then
                    Error(VerifyWorkspaceRoleMalformedErr);
                if FormatGuidForFabricUrl(IdToken.AsValue().AsText()) = FormatGuidForFabricUrl(PrincipalId) then begin
                    if not ItemObj.Get('role', RoleToken) then
                        Error(VerifyWorkspaceRoleMalformedErr);
                    if not RoleToken.IsValue() then
                        Error(VerifyWorkspaceRoleMalformedErr);
                    if RoleToken.AsValue().IsNull() then
                        Error(VerifyWorkspaceRoleMalformedErr);
                    exit(RoleToken.AsValue().AsText() in ['Contributor', 'Member', 'Admin']);
                end;
            end;

            Clear(NextRequestUrl);
            if RootObj.Get('continuationUri', ContinuationToken) then begin
                if not ContinuationToken.IsValue() then
                    Error(VerifyWorkspaceRoleMalformedErr);
                if not ContinuationToken.AsValue().IsNull() then
                    NextRequestUrl := ContinuationToken.AsValue().AsText();
            end;
            if (NextRequestUrl <> '') and not NextRequestUrl.StartsWith(BaseUrl + '?') then
                Error(VerifyWorkspaceRoleMalformedErr);
            RequestUrl := NextRequestUrl;
        until RequestUrl = '';
        exit(false);
    end;

    /// <summary>Grants the service principal configured in isolated storage Contributor access on the workspace.</summary>
    procedure AddConnectionToWorkspace(WorkspaceId: Text)
    var
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
    begin
        AddServicePrincipalToWorkspace(WorkspaceId, CredMgt.GetPrincipalId());
    end;

    internal procedure GetPrincipalIdSetupHelpUrl(): Text
    begin
        exit(PrincipalIdSetupHelpUrlTok);
    end;

    local procedure CreatePrincipalIdRequiredErrorInfo() ErrInfo: ErrorInfo
    begin
        ErrInfo.Message(PrincipalIdRequiredErr);
        ErrInfo.DataClassification(DataClassification::SystemMetadata);
        ErrInfo.PageNo(Page::"Fabric Platform Setup");
        ErrInfo.AddAction(ReadPrincipalIdSetupInstructionsLbl, Codeunit::"Fabric Platform Admin Client", 'OpenPrincipalIdSetupHelp');
    end;

    internal procedure OpenPrincipalIdSetupHelp(ErrInfo: ErrorInfo)
    begin
        Hyperlink(PrincipalIdSetupHelpUrlTok);
    end;

    local procedure CreateRetrieveWorkspacesHttpErrorInfo(StatusCode: Integer) ErrInfo: ErrorInfo
    begin
        ErrInfo.Message(RetrieveWorkspacesHttpGenericErr);
        ErrInfo.DetailedMessage(StrSubstNo(RetrieveWorkspacesHttpErr, StatusCode));
        ErrInfo.DataClassification(DataClassification::SystemMetadata);
    end;

    local procedure CreateMirroredDbsHttpErrorInfo(StatusCode: Integer) ErrInfo: ErrorInfo
    begin
        ErrInfo.Message(RetrieveMirroredDbsHttpGenericErr);
        ErrInfo.DetailedMessage(StrSubstNo(RetrieveMirroredDbsHttpStatusErr, StatusCode));
        ErrInfo.DataClassification(DataClassification::SystemMetadata);
    end;

    local procedure CreateAddSPHttpErrorInfo(StatusCode: Integer) ErrInfo: ErrorInfo
    begin
        ErrInfo.Message(AddSPHttpGenericErr);
        ErrInfo.DetailedMessage(StrSubstNo(AddSPHttpStatusErr, StatusCode));
        ErrInfo.DataClassification(DataClassification::SystemMetadata);
    end;

    local procedure CreateVerifyWorkspaceRoleHttpErrorInfo(StatusCode: Integer) ErrInfo: ErrorInfo
    begin
        ErrInfo.Message(VerifyWorkspaceRoleHttpGenericErr);
        ErrInfo.DetailedMessage(StrSubstNo(VerifyWorkspaceRoleHttpStatusErr, StatusCode));
        ErrInfo.DataClassification(DataClassification::SystemMetadata);
    end;

    local procedure FormatGuidForFabricUrl(GuidText: Text): Text
    begin
        exit(DelChr(GuidText, '<>', ' {}'));
    end;
}

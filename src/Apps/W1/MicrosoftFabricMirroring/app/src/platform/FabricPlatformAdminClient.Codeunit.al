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
        PrincipalIdRequiredErr: Label 'Principal ID must be filled in before adding to the workspace.';
        AddSPTransportErr: Label 'Failed to add service principal to workspace: transport error.';
        SPAlreadyMemberErr: Label 'The service principal is already a member of this workspace.';
        AddSPHttpGenericErr: Label 'Failed to add service principal to workspace. Contact your administrator if the problem persists.';
        AddSPHttpStatusErr: Label 'Failed to add service principal to workspace. HTTP %1.', Comment = '%1 = HTTP status code';
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
        TelemetryDimensions: Dictionary of [Text, Text];
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
            Telemetry.LogFailureEvent('FAB-120', StrSubstNo(RetrieveMirroredDbsHttpStatusErr, Resp.GetHttpStatusCode()), TelemetryDimensions);
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
        if PrincipalId = '' then
            Error(PrincipalIdRequiredErr);

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

        if Resp.GetHttpStatusCode() = 409 then
            Error(SPAlreadyMemberErr);
        Error(CreateAddSPHttpErrorInfo(Resp.GetHttpStatusCode()));
    end;

    local procedure CreateRetrieveWorkspacesHttpErrorInfo(StatusCode: Integer) ErrInfo: ErrorInfo
    begin
        ErrInfo.Message(RetrieveWorkspacesHttpGenericErr);
        ErrInfo.DetailedMessage(StrSubstNo(RetrieveWorkspacesHttpErr, StatusCode));
        ErrInfo.DataClassification(DataClassification::SystemMetadata);
        ErrInfo.ErrorType(ErrorType::Internal);
    end;

    local procedure CreateMirroredDbsHttpErrorInfo(StatusCode: Integer) ErrInfo: ErrorInfo
    begin
        ErrInfo.Message(RetrieveMirroredDbsHttpGenericErr);
        ErrInfo.DetailedMessage(StrSubstNo(RetrieveMirroredDbsHttpStatusErr, StatusCode));
        ErrInfo.DataClassification(DataClassification::SystemMetadata);
        ErrInfo.ErrorType(ErrorType::Internal);
    end;

    local procedure CreateAddSPHttpErrorInfo(StatusCode: Integer) ErrInfo: ErrorInfo
    begin
        ErrInfo.Message(AddSPHttpGenericErr);
        ErrInfo.DetailedMessage(StrSubstNo(AddSPHttpStatusErr, StatusCode));
        ErrInfo.DataClassification(DataClassification::SystemMetadata);
        ErrInfo.ErrorType(ErrorType::Internal);
    end;

    local procedure FormatGuidForFabricUrl(GuidText: Text): Text
    begin
        exit(DelChr(GuidText, '<>', ' {}'));
    end;
}

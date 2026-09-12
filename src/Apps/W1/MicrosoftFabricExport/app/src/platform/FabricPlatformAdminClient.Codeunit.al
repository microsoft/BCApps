namespace Microsoft.FabricExport;

using Microsoft.Utilities;
using System.RestClient;

codeunit 48526 "Fabric Platform Admin Client"
{
    Access = Internal;

    var
        RetrieveWorkspacesTransportErr: Label 'Failed to retrieve workspaces: transport error.';
        RetrieveWorkspacesHttpErr: Label 'Failed to retrieve workspaces. HTTP %1.', Comment = '%1 = HTTP status code';
        RetrieveWorkspacesMalformedErr: Label 'Failed to retrieve workspaces: malformed response from Microsoft Fabric.';
        WorkspaceRequiredForMirroredDbErr: Label 'Select a workspace before choosing an Open Mirroring database.';
        RetrieveMirroredDbsTransportErr: Label 'Failed to retrieve Open Mirroring databases: transport error.';
        RetrieveMirroredDbsHttpErr: Label 'Failed to retrieve Open Mirroring databases. HTTP %1.\%2', Comment = '%1 = HTTP status code, %2 = response body';
        RetrieveMirroredDbsMalformedErr: Label 'Failed to retrieve Open Mirroring databases: malformed response from Microsoft Fabric.';
        WorkspaceRequiredForSPErr: Label 'Select a workspace before adding the service principal.';
        PrincipalIdRequiredErr: Label 'Principal ID must be filled in before adding to the workspace.';
        AddSPTransportErr: Label 'Failed to add service principal to workspace: transport error.';
        SPAlreadyMemberErr: Label 'The service principal is already a member of this workspace.';
        AddSPHttpErr: Label 'Failed to add service principal to workspace. HTTP %1.\%2', Comment = '%1 = HTTP status code, %2 = response body';

    /// <summary>Fills TempBuffer with Fabric workspaces accessible to the delegated token (Name = display name, Value = workspace GUID).</summary>
    procedure GetWorkspaces(var TempBuffer: Record "Name/Value Buffer" temporary)
    var
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        HttpClient: Codeunit "Fabric Platform Http Client";
        RestClientResult: Codeunit "Rest Client";
        Req: Codeunit "Http Request Message";
        Resp: Codeunit "Http Response Message";
        AccessToken: SecretText;
        ResponseText: Text;
        RootObj: JsonObject;
        ArrayToken: JsonToken;
        ItemToken: JsonToken;
        ItemObj: JsonObject;
        IdToken: JsonToken;
        NameToken: JsonToken;
        JsonArr: JsonArray;
        i: Integer;
    begin
        TempBuffer.Reset();
        TempBuffer.DeleteAll();

        AccessToken := CredMgt.AcquireFabricApiTokenDelegated();
        RestClientResult := HttpClient.CreateClientWithBearer(AccessToken);
        Req := HttpClient.BuildJsonRequest('GET', 'https://api.fabric.microsoft.com/v1/workspaces', '');
        if not HttpClient.TrySend(RestClientResult, Req, Resp) then
            Error(RetrieveWorkspacesTransportErr);
        if not Resp.GetIsSuccessStatusCode() then
            Error(RetrieveWorkspacesHttpErr, Resp.GetHttpStatusCode());

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
                TempBuffer.Insert();
            end;
        end;
    end;

    /// <summary>Fills TempBuffer with Open Mirroring databases in WorkspaceId (Name = display name, Value = mirrored database GUID).</summary>
    procedure GetMirroredDatabases(WorkspaceId: Text; var TempBuffer: Record "Name/Value Buffer" temporary)
    var
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        HttpClient: Codeunit "Fabric Platform Http Client";
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
        ResponseText: Text;
        WorkspaceIdForUrl: Text;
        i: Integer;
    begin
        if WorkspaceId = '' then
            Error(WorkspaceRequiredForMirroredDbErr);

        WorkspaceIdForUrl := FormatGuidForFabricUrl(WorkspaceId);
        if WorkspaceIdForUrl = '' then
            Error(WorkspaceRequiredForMirroredDbErr);

        TempBuffer.Reset();
        TempBuffer.DeleteAll();

        AccessToken := CredMgt.AcquireFabricApiTokenDelegated();
        RestClientResult := HttpClient.CreateClientWithBearer(AccessToken);
        Req := HttpClient.BuildJsonRequest(
            'GET',
            StrSubstNo('https://api.fabric.microsoft.com/v1/workspaces/%1/mirroredDatabases', WorkspaceIdForUrl),
            '');
        if not HttpClient.TrySend(RestClientResult, Req, Resp) then
            Error(RetrieveMirroredDbsTransportErr);
        if not Resp.GetIsSuccessStatusCode() then begin
            ResponseText := Resp.GetContent().AsText();
            Error(RetrieveMirroredDbsHttpErr, Resp.GetHttpStatusCode(), ResponseText);
        end;

        RootObj.ReadFrom(Resp.GetContent().AsText());
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
                TempBuffer.Insert();
            end;
        end;
    end;

    procedure AddServicePrincipalToWorkspace(WorkspaceId: Text; PrincipalId: Text)
    var
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        HttpClient: Codeunit "Fabric Platform Http Client";
        RestClientResult: Codeunit "Rest Client";
        Req: Codeunit "Http Request Message";
        Resp: Codeunit "Http Response Message";
        AccessToken: SecretText;
        ResponseText: Text;
        WorkspaceIdForUrl: Text;
        BodyObj: JsonObject;
        PrincipalObj: JsonObject;
        Body: Text;
    begin
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
            StrSubstNo('https://api.fabric.microsoft.com/v1/workspaces/%1/roleAssignments', WorkspaceIdForUrl),
            Body);
        if not HttpClient.TrySend(RestClientResult, Req, Resp) then
            Error(AddSPTransportErr);
        if Resp.GetIsSuccessStatusCode() then
            exit;

        ResponseText := Resp.GetContent().AsText();
        if Resp.GetHttpStatusCode() = 409 then
            Error(SPAlreadyMemberErr);
        Error(AddSPHttpErr, Resp.GetHttpStatusCode(), ResponseText);
    end;

    local procedure FormatGuidForFabricUrl(GuidText: Text): Text
    begin
        exit(DelChr(GuidText, '<>', ' {}'));
    end;
}

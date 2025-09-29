// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Codespaces;

using System.Environment;
using System.Integration;

codeunit 8432 "AL Project Configuration"
{
    var
        GithubApiHelper: Codeunit "Github API Helper";

    procedure SetGithubAPIHelper(GHAPIHelper: Codeunit "Github API Helper")
    begin
        GithubAPIHelper := GHAPIHelper;
    end;

    procedure PushAlRequestJsonToRepository(Owner: Text; RepoName: Text; AlRequestJsonContent: Text): Boolean
    var
        CommitMessage: Text;
        FilePath: Text;
        Success: Boolean;
    begin
        FilePath := '.vscode/alRequest.json';
        CommitMessage := 'Add/Update alRequest.json for AL development in Codespaces';

        Success := GithubApiHelper.PushFileToRepository(Owner, RepoName, FilePath, AlRequestJsonContent, CommitMessage);

        if Success then
            Message('alRequest.json pushed successfully to %1/%2', Owner, RepoName)
        else
            Error('Failed to push alRequest.json to %1/%2', Owner, RepoName);

        exit(Success);
    end;

    procedure PushCurrentAlRequestConfigToRepository(Owner: Text; RepoName: Text): Boolean
    var
        VSCodeRequestHelper: DotNet VSCodeRequestHelper;
        LaunchLink: Text;
        AlRequestJsonContent: Text;
    begin
        // Get the current launch link
        LaunchLink := VSCodeRequestHelper.GetLaunchInformationQueryPart();

        // Create alRequest.json configuration from the link
        AlRequestJsonContent := CreateAlRequestJsonFromLink(LaunchLink);

        // Push the configuration to the repository
        exit(PushAlRequestJsonToRepository(Owner, RepoName, AlRequestJsonContent));
    end;

    procedure CreateAlRequestJsonFromLink(LaunchLink: Text): Text
    var
        ServerName: Text;
        ServerInstance: Text;
        DeveloperPort: Integer;
        AuthenticationMode: Text;
        RuntimeVersion: Text;
        AppVersion: Text;
        Tenant: Text;
        EnvironmentType: Text;
        EnvironmentName: Text;
    begin
        // Parse the launch link to extract parameters
        ParseLaunchLink(LaunchLink, ServerName, ServerInstance, DeveloperPort, AuthenticationMode, RuntimeVersion, AppVersion, Tenant, EnvironmentType, EnvironmentName);

        // Create configuration JSON with parsed parameters
        exit(CreateConfigurationJson(ServerName, ServerInstance, DeveloperPort, AuthenticationMode, RuntimeVersion, AppVersion, Tenant, EnvironmentType, EnvironmentName));
    end;

    local procedure ParseLaunchLink(LaunchLink: Text; var ServerName: Text; var ServerInstance: Text; var DeveloperPort: Integer; var AuthenticationMode: Text; var RuntimeVersion: Text; var AppVersion: Text; var Tenant: Text; var EnvironmentType: Text; var EnvironmentName: Text)
    var
        Parameters: List of [Text];
        Parameter: Text;
        KeyValue: List of [Text];
        ParameterKey: Text;
        ParameterValue: Text;
    begin
        // Split by & to get individual parameters
        Parameters := LaunchLink.Split('&');

        foreach Parameter in Parameters do begin
            KeyValue := Parameter.Split('=');
            if KeyValue.Count() = 2 then begin
                ParameterKey := KeyValue.Get(1);
                ParameterValue := KeyValue.Get(2);

                case ParameterKey of
                    'server':
                        ServerName := ParameterValue.Replace('http://', '').Replace('https://', '');
                    'serverInstance':
                        ServerInstance := ParameterValue;
                    'port':
                        if not Evaluate(DeveloperPort, ParameterValue) then
                            DeveloperPort := 7049;
                    'authentication':
                        AuthenticationMode := ParameterValue;
                    'runtime':
                        RuntimeVersion := ParameterValue;
                    'appVersion':
                        AppVersion := ParameterValue;
                    'tenant':
                        Tenant := ParameterValue;
                    'environmentType':
                        EnvironmentType := ParameterValue;
                    'environmentName':
                        EnvironmentName := ParameterValue;
                end;
            end;
        end;
    end;

    procedure CreateConfigurationJson(ServerName: Text; ServerInstance: Text; DeveloperPort: Integer; AuthenticationMode: Text; RuntimeVersion: Text; AppVersion: Text; Tenant: Text; EnvironmentType: Text; EnvironmentName: Text): Text
    var
        EnvironmentInfo: Codeunit "Environment Information";
        MainJson: JsonObject;
        ContentJson: JsonObject;
        DependenciesArray: JsonArray;
        JsonText: Text;
        ServerFullNameTxt: Label 'http://%1', Comment = '%1 = Server name';
    begin
        if EnvironmentInfo.IsSaaS() then begin
            ContentJson.Add('environmentType', EnvironmentType);
            ContentJson.Add('environmentName', EnvironmentName);
        end
        else begin
            ContentJson.Add('authentication', AuthenticationMode);
            ContentJson.Add('server', StrSubstNo(ServerFullNameTxt, ServerName));
            ContentJson.Add('serverInstance', ServerInstance);
            ContentJson.Add('port', DeveloperPort);
        end;

        ContentJson.Add('runtimeVersion', RuntimeVersion);
        ContentJson.Add('appVersion', AppVersion);
        ContentJson.Add('dependencies', DependenciesArray); // Empty array
        ContentJson.Add('sessionId', SessionId());

        if Tenant <> '' then
            ContentJson.Add('tenant', Tenant);

        // Create the main JSON object
        MainJson.Add('type', '/configure');
        MainJson.Add('content', ContentJson);

        MainJson.WriteTo(JsonText);
        exit(JsonText);
    end;
}
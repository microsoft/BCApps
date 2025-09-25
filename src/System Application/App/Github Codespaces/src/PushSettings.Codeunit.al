// // ------------------------------------------------------------------------------------------------
// // Copyright (c) Microsoft Corporation. All rights reserved.
// // Licensed under the MIT License. See License.txt in the project root for license information.
// // ------------------------------------------------------------------------------------------------

// namespace System.Integration.Codespaces;

// using System.RestClient;

// codeunit 8432 "Push Settings"
// {
//     var
//         RestClient: Codeunit "Rest Client";
//         GitHubOAuthBrowserHelper: Codeunit "GitHub OAuth Browser Helper";

//     procedure PushLaunchJsonToRepository(Owner: Text; RepoName: Text; LaunchJsonContent: Text): Boolean
//     var
//         HttpContent: Codeunit "Http Content";
//         HttpResponseMessage: Codeunit "Http Response Message";
//         RequestBody: JsonObject;
//         AccessToken: SecretText;
//         ApiUrl: Text;
//         EncodedContent: Text;
//         StatusCode: Integer;
//         CommitMessage: Text;
//         UpdateVSCodeLaunchConfigLbl: Label 'https://api.github.com/repos/%1/%2/contents/.vscode/launch.json', Comment = '%1: Owner, %2: Repository';
//     begin
//         // Get access token
//         AccessToken := GitHubOAuthBrowserHelper.GetGitHubAccessTokenViaDeviceFlow();

//         // Encode file content to Base64
//         EncodedContent := EncodeBase64(LaunchJsonContent);

//         // Construct GitHub API URL for creating/updating files
//         ApiUrl := StrSubstNo(UpdateVSCodeLaunchConfigLbl, Owner, RepoName);

//         // Create request body
//         CommitMessage := 'Add launch.json for AL development in Codespaces';
//         RequestBody.Add('message', CommitMessage);
//         RequestBody.Add('content', EncodedContent);
//         RequestBody.Add('branch', 'main');

//         // Initialize REST client
//         RestClient.Initialize();
//         RestClient.SetDefaultRequestHeader('Accept', 'application/vnd.github+json');
//         RestClient.SetDefaultRequestHeader('X-GitHub-Api-Version', '2022-11-28');
//         RestClient.SetAuthorizationHeader(SecretText.SecretStrSubstNo('Bearer %1', AccessToken));

//         // Create HTTP content
//         HttpContent := HttpContent.Create(RequestBody);

//         // Send PUT request to create/update file
//         HttpResponseMessage := RestClient.Put(ApiUrl, HttpContent);

//         StatusCode := HttpResponseMessage.GetHttpStatusCode();

//         if HttpResponseMessage.GetIsSuccessStatusCode() then begin
//             Message('Launch.json pushed successfully to %1/%2', Owner, RepoName);
//             exit(true);
//         end else begin
//             Message('Failed to push launch.json:\Status Code: %1\Reason: %2\Response: %3',
//                 StatusCode,
//                 HttpResponseMessage.GetReasonPhrase(),
//                 HttpResponseMessage.GetContent().AsText());
//             exit(false);
//         end;
//     end;

//     local procedure EncodeBase64(InputText: Text): Text
//     var
//         TempBlob: Codeunit "Temp Blob";
//         Base64Convert: Codeunit "Base64 Convert";
//         InStream: InStream;
//         OutStream: OutStream;
//     begin
//         TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
//         OutStream.WriteText(InputText);
//         TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
//         exit(Base64Convert.ToBase64(InStream));
//     end;

//     local procedure GetLaunchLink(): Text
//     var
//         LaunchLink: Text;
//         VSCodeRequestHelper: DotNet VSCodeRequestHelper;
//     begin
//         LaunchLink := VSCodeRequestHelper.GetLaunchInformationQueryPart();
//         exit(LaunchLink);
//     end;

//     procedure PushCurrentLaunchConfigToRepository(Owner: Text; RepoName: Text): Boolean
//     var
//         LaunchLink: Text;
//         LaunchJsonContent: Text;
//     begin
//         // Get the current launch link
//         LaunchLink := GetLaunchLink();

//         // Create launch.json configuration from the link
//         LaunchJsonContent := CreateLaunchJsonFromLink(LaunchLink);

//         // Push the configuration to the repository
//         exit(PushLaunchJsonToRepository(Owner, RepoName, LaunchJsonContent));
//     end;

//     procedure CreateLaunchJsonFromLink(LaunchLink: Text): Text
//     var
//         IsSaaS: Boolean;
//         EnvironmentType: Text;
//         EnvironmentName: Text;
//         ServerName: Text;
//         ServerInstance: Text;
//         DeveloperPort: Integer;
//         AuthenticationMode: Text;
//         AadTenantId: Text;
//     begin
//         // Parse the launch link to extract parameters
//         ParseLaunchLink(LaunchLink, IsSaaS, EnvironmentType, EnvironmentName, ServerName, ServerInstance, DeveloperPort, AuthenticationMode, AadTenantId);

//         // Create launch configuration with parsed parameters
//         exit(CreateLaunchJsonConfiguration(IsSaaS, EnvironmentType, EnvironmentName, ServerName, ServerInstance, DeveloperPort, AuthenticationMode, AadTenantId));
//     end;

//     local procedure ParseLaunchLink(LaunchLink: Text; var IsSaaS: Boolean; var EnvironmentType: Text; var EnvironmentName: Text; var ServerName: Text; var ServerInstance: Text; var DeveloperPort: Integer; var AuthenticationMode: Text; var AadTenantId: Text)
//     var
//         Parameters: List of [Text];
//         Parameter: Text;
//         KeyValue: List of [Text];
//         ParameterKey: Text;
//         ParameterValue: Text;
//     begin
//         // Initialize default values
//         IsSaaS := false;
//         DeveloperPort := 7049;

//         // Split by & to get individual parameters
//         Parameters := LaunchLink.Split('&');

//         foreach Parameter in Parameters do begin
//             KeyValue := Parameter.Split('=');
//             if KeyValue.Count() = 2 then begin
//                 ParameterKey := KeyValue.Get(1);
//                 ParameterValue := KeyValue.Get(2);

//                 case ParameterKey of
//                     'server':
//                         ServerName := ParameterValue.Replace('http://', '').Replace('https://', '');
//                     'serverInstance':
//                         ServerInstance := ParameterValue;
//                     'port':
//                         if not Evaluate(DeveloperPort, ParameterValue) then
//                             DeveloperPort := 7049;
//                     'authentication':
//                         AuthenticationMode := ParameterValue;
//                     'tenant':
//                         AadTenantId := ParameterValue;
//                     'environmentType':
//                         begin
//                             IsSaaS := true;
//                             EnvironmentType := ParameterValue;
//                         end;
//                     'environmentName':
//                         begin
//                             IsSaaS := true;
//                             EnvironmentName := ParameterValue;
//                         end;
//                 end;
//             end;
//         end;
//     end;

//     procedure CreateLaunchJsonConfiguration(IsSaaS: Boolean; EnvironmentType: Text; EnvironmentName: Text; ServerName: Text; ServerInstance: Text; DeveloperPort: Integer; AuthenticationMode: Text; AadTenantId: Text): Text
//     var
//         LaunchJson: JsonObject;
//         ConfigurationsArray: JsonArray;
//         Configuration: JsonObject;
//         JsonText: Text;
//     begin
//         if IsSaaS then begin
//             // SaaS configuration with specific parameters
//             Configuration.Add('name', 'Publish: Microsoft cloud sandbox');
//             Configuration.Add('type', 'al');
//             Configuration.Add('request', 'launch');
//             Configuration.Add('environmentType', EnvironmentType);
//             if EnvironmentName <> '' then
//                 Configuration.Add('environmentName', EnvironmentName)
//             else
//                 Configuration.Add('environmentName', 'sandbox');
//             Configuration.Add('startupObjectId', 22);
//             Configuration.Add('breakOnError', 'All');
//             Configuration.Add('breakOnRecordWrite', 'None');
//         end else begin
//             // On-Premises configuration
//             Configuration.Add('name', 'Publish: Local server');
//             Configuration.Add('type', 'al');
//             Configuration.Add('request', 'launch');
//             Configuration.Add('environmentType', 'OnPrem');
//             Configuration.Add('server', StrSubstNo('http://%1', ServerName));
//             Configuration.Add('serverInstance', ServerInstance);
//             Configuration.Add('port', DeveloperPort);
//             Configuration.Add('authentication', AuthenticationMode);
//             Configuration.Add('startupObjectId', 22);
//             Configuration.Add('breakOnError', 'All');
//             Configuration.Add('breakOnRecordWrite', 'None');
//         end;

//         // Add tenant ID if valid
//         if IsValidAadTenantId(AadTenantId) then
//             Configuration.Add('tenant', AadTenantId);

//         ConfigurationsArray.Add(Configuration);

//         LaunchJson.Add('version', '0.2.0');
//         LaunchJson.Add('configurations', ConfigurationsArray);

//         LaunchJson.WriteTo(JsonText);
//         exit(JsonText);
//     end;

//     local procedure IsValidAadTenantId(TenantId: Text): Boolean
//     begin
//         // Check if tenant ID is not empty and is a valid GUID format
//         if TenantId = '' then
//             exit(false);

//         // Basic GUID validation (should be 36 characters with hyphens)
//         if StrLen(TenantId) <> 36 then
//             exit(false);

//         exit(true);
//     end;
// }
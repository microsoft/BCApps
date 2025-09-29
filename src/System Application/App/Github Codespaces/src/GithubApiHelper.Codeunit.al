// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Codespaces;

using System.RestClient;

codeunit 8430 "Github API Helper"
{
    var
        RestClient: Codeunit "Rest Client";
        GitHubOAuthBrowserHelper: Codeunit "GitHub OAuth Browser Helper";


    procedure SetGitHubUserName(UserName: Text[100])
    begin
        GitHubOAuthBrowserHelper.SetGitHubUserName(UserName);
    end;

    procedure GetGitHubUserName(): Text[100]
    begin
        exit(GitHubOAuthBrowserHelper.GetGitHubUserName());
    end;

    procedure SetGitHubAccessToken(Token: Text)
    begin
        GitHubOAuthBrowserHelper.SetGitHubAccessToken(Token);
    end;

    procedure CreateCodespaceInRepo(Owner: Text; Repo: Text): text
    var
        HttpContent: Codeunit "Http Content";
        HttpResponseMessage: Codeunit "Http Response Message";
        CreateCodespaceRequestLbl: Label 'https://api.github.com/repos/%1/%2/codespaces', Comment = '%1: Owner, %2: Repository';
        RequestBody: JsonObject;
        ApiUrl: Text;
        AccessToken: SecretText;
        CodespaceName: JsonToken;
    begin
        // Get access token via device flow
        AccessToken := GitHubOAuthBrowserHelper.GetGitHubAccessTokenViaDeviceFlow();

        // Construct the GitHub API URL
        ApiUrl := StrSubstNo(CreateCodespaceRequestLbl, Owner, Repo);

        // Create request body
        RequestBody.Add('ref', 'main');
        RequestBody.Add('machine', 'standardLinux32gb');

        // Initialize REST client and set headers
        RestClient.Initialize();
        RestClient.SetDefaultRequestHeader('Accept', 'application/vnd.github+json');
        RestClient.SetDefaultRequestHeader('X-GitHub-Api-Version', '2022-11-28');
        RestClient.SetAuthorizationHeader(SecretText.SecretStrSubstNo('Bearer %1', AccessToken));

        // Create HTTP content with JSON body
        HttpContent := HttpContent.Create(RequestBody);

        // Send POST request
        HttpResponseMessage := RestClient.Post(ApiUrl, HttpContent);

        // Handle response
        if HttpResponseMessage.GetIsSuccessStatusCode() then
            Message('Codespace created successfully')
        else
            Error('Failed to create codespace: %1', HttpResponseMessage.GetReasonPhrase());

        HttpResponseMessage.GetContent().AsJsonObject().Get('name', CodespaceName);
        exit(CodespaceName.AsValue().AsText());
    end;

    procedure CreateRepoFromTemplate(TemplateOwner: Text; TemplateRepo: Text; NewOwner: Text; NewRepoName: Text; NewRepoDescription: Text; IsPrivate: Boolean)
    var
        HttpContent: Codeunit "Http Content";
        HttpResponseMessage: Codeunit "Http Response Message";
        CreateRepoFromTemplateRequestLbl: Label 'https://api.github.com/repos/%1/%2/generate', Comment = '%1: Template Owner, %2: Template Repository';
        RequestBody: JsonObject;
        RepoUrlJson: JsonToken;
        ApiUrl: Text;
        ResponseContent: JsonObject;
        RepoUrl: Text;
        AccessToken: SecretText;
    begin
        // Get access token via device flow
        AccessToken := GitHubOAuthBrowserHelper.GetGitHubAccessTokenViaDeviceFlow();

        // Construct the GitHub API URL for template generation
        ApiUrl := StrSubstNo(CreateRepoFromTemplateRequestLbl, TemplateOwner, TemplateRepo);

        // Create request body for repository generation
        RequestBody.Add('owner', NewOwner);
        RequestBody.Add('name', NewRepoName);
        RequestBody.Add('description', NewRepoDescription);
        RequestBody.Add('private', IsPrivate);
        RequestBody.Add('include_all_branches', false);

        // Initialize REST client and set headers
        RestClient.Initialize();
        RestClient.SetDefaultRequestHeader('Accept', 'application/vnd.github+json');
        RestClient.SetDefaultRequestHeader('X-GitHub-Api-Version', '2022-11-28');
        RestClient.SetAuthorizationHeader(SecretText.SecretStrSubstNo('Bearer %1', AccessToken));

        // Create HTTP content with JSON body
        HttpContent := HttpContent.Create(RequestBody);

        // Send POST request
        HttpResponseMessage := RestClient.Post(ApiUrl, HttpContent);

        // Handle response
        if HttpResponseMessage.GetIsSuccessStatusCode() then begin
            ResponseContent := HttpResponseMessage.GetContent().AsJsonObject();
            if ResponseContent.Get('html_url', RepoUrlJson) then begin
                RepoUrl := RepoUrlJson.AsValue().AsText();
                Message('Repository created successfully: %1', RepoUrl);
            end else
                Message('Repository created successfully');
        end else
            Error('Failed to create repository from template: %1', HttpResponseMessage.GetReasonPhrase());
    end;

    procedure GetMyRepositories(): JsonArray
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        AccessToken: SecretText;
        ResponseContent: JsonArray;
    begin
        // Get access token
        AccessToken := GitHubOAuthBrowserHelper.GetGitHubAccessTokenViaDeviceFlow();

        // Initialize REST client and set headers
        RestClient.Initialize();
        RestClient.SetDefaultRequestHeader('Accept', 'application/vnd.github+json');
        RestClient.SetDefaultRequestHeader('X-GitHub-Api-Version', '2022-11-28');
        RestClient.SetAuthorizationHeader(SecretText.SecretStrSubstNo('Bearer %1', AccessToken));

        // Send GET request - this endpoint returns all repos the authenticated user has access to
        HttpResponseMessage := RestClient.Get('https://api.github.com/user/repos?per_page=100');

        // Handle response
        if HttpResponseMessage.GetIsSuccessStatusCode() then begin
            ResponseContent := HttpResponseMessage.GetContent().AsJsonArray();
            exit(ResponseContent);
        end else
            Error('Failed to get my repositories: %1\%2', HttpResponseMessage.GetReasonPhrase(), HttpResponseMessage.GetContent().AsText());
    end;

    procedure GetMyCodespaces(): JsonArray
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        AccessToken: SecretText;
        ResponseContent: JsonObject;
        CodespacesArray: JsonArray;
        CodespacesToken: JsonToken;
        ApiUrl: Text;
    begin
        // Get access token
        AccessToken := GitHubOAuthBrowserHelper.GetGitHubAccessTokenViaDeviceFlow();

        // Initialize REST client and set headers
        RestClient.Initialize();
        RestClient.SetDefaultRequestHeader('Accept', 'application/vnd.github+json');
        RestClient.SetDefaultRequestHeader('X-GitHub-Api-Version', '2022-11-28');
        RestClient.SetAuthorizationHeader(SecretText.SecretStrSubstNo('Bearer %1', AccessToken));

        // Send GET request to get all codespaces for authenticated user
        ApiUrl := 'https://api.github.com/user/codespaces';
        HttpResponseMessage := RestClient.Get(ApiUrl);

        // Handle response
        if HttpResponseMessage.GetIsSuccessStatusCode() then begin
            ResponseContent := HttpResponseMessage.GetContent().AsJsonObject();

            // Extract the codespaces array from the response object
            if ResponseContent.Get('codespaces', CodespacesToken) then begin
                CodespacesArray := CodespacesToken.AsArray();
                exit(CodespacesArray);
            end else
                Error('No codespaces array found in response');
        end else
            Error('Failed to get codespaces: %1\%2', HttpResponseMessage.GetReasonPhrase(), HttpResponseMessage.GetContent().AsText());
    end;

    procedure StartCodespace(CodespaceName: Text)
    var
        HttpContent: Codeunit "Http Content";
        HttpResponseMessage: Codeunit "Http Response Message";
        AccessToken: SecretText;
        ApiUrl: Text;
        EmptyBody: JsonObject;
        StartCodespacesRequestTxt: Label 'https://api.github.com/user/codespaces/%1/start', Comment = '%1: Codespace Name';
    begin
        AccessToken := GitHubOAuthBrowserHelper.GetGitHubAccessTokenViaDeviceFlow();
        ApiUrl := StrSubstNo(StartCodespacesRequestTxt, CodespaceName);

        RestClient.Initialize();
        RestClient.SetDefaultRequestHeader('Accept', 'application/vnd.github+json');
        RestClient.SetDefaultRequestHeader('X-GitHub-Api-Version', '2022-11-28');
        RestClient.SetAuthorizationHeader(SecretText.SecretStrSubstNo('Bearer %1', AccessToken));

        // Create empty JSON content for POST request
        HttpContent := HttpContent.Create(EmptyBody);

        HttpResponseMessage := RestClient.Post(ApiUrl, HttpContent);

        if HttpResponseMessage.GetIsSuccessStatusCode() then
            Message('Codespace "%1" is starting...', CodespaceName)
        else
            Error('Failed to start codespace: %1', HttpResponseMessage.GetReasonPhrase());
    end;

    procedure PushFileToRepository(Owner: Text; RepoName: Text; FilePath: Text; FileContent: Text; CommitMessage: Text): Boolean
    var
        HttpContent: Codeunit "Http Content";
        HttpResponseMessage: Codeunit "Http Response Message";
        RequestBody: JsonObject;
        AccessToken: SecretText;
        ApiUrl: Text;
        EncodedContent: Text;
        ExistingFileSha: Text;
        PushFileRequestLbl: Label 'https://api.github.com/repos/%1/%2/contents/%3', Comment = '%1: Owner, %2: Repository, %3: File Path';
    begin
        // Get access token
        AccessToken := GitHubOAuthBrowserHelper.GetGitHubAccessTokenViaDeviceFlow();

        // Encode file content to Base64
        EncodedContent := EncodeBase64(FileContent);

        // Construct GitHub API URL for creating/updating files
        ApiUrl := StrSubstNo(PushFileRequestLbl, Owner, RepoName, FilePath);

        // Check if file already exists and get its SHA
        ExistingFileSha := GetExistingFileSha(Owner, RepoName, FilePath, AccessToken);

        // Create request body
        RequestBody.Add('message', CommitMessage);
        RequestBody.Add('content', EncodedContent);
        RequestBody.Add('branch', 'main');

        // Add SHA if file exists (required for updates)
        if ExistingFileSha <> '' then
            RequestBody.Add('sha', ExistingFileSha);

        // Initialize REST client
        RestClient.Initialize();
        RestClient.SetDefaultRequestHeader('Accept', 'application/vnd.github+json');
        RestClient.SetDefaultRequestHeader('X-GitHub-Api-Version', '2022-11-28');
        RestClient.SetAuthorizationHeader(SecretText.SecretStrSubstNo('Bearer %1', AccessToken));

        // Create HTTP content
        HttpContent := HttpContent.Create(RequestBody);

        // Send PUT request to create/update file
        HttpResponseMessage := RestClient.Put(ApiUrl, HttpContent);

        if HttpResponseMessage.GetIsSuccessStatusCode() then
            exit(true)
        else
            exit(false);
    end;

    local procedure EncodeBase64(InputText: Text): Text
    begin
        // TODO: Implement proper Base64 encoding
        // For now, returning the input text as placeholder
        // This needs to be implemented with proper Base64 encoding for GitHub API
        exit(InputText);
    end;

    local procedure GetExistingFileSha(Owner: Text; RepoName: Text; FilePath: Text; AccessToken: SecretText): Text
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        ResponseJson: JsonObject;
        ResponseText: Text;
        ApiUrl: Text;
        ShaToken: JsonToken;
        GetFileRequestLbl: Label 'https://api.github.com/repos/%1/%2/contents/%3', Comment = '%1: Owner, %2: Repository, %3: File Path';
    begin
        // Construct GitHub API URL to get file info
        ApiUrl := StrSubstNo(GetFileRequestLbl, Owner, RepoName, FilePath);

        // Initialize REST client
        RestClient.Initialize();
        RestClient.SetDefaultRequestHeader('Accept', 'application/vnd.github+json');
        RestClient.SetDefaultRequestHeader('X-GitHub-Api-Version', '2022-11-28');
        RestClient.SetAuthorizationHeader(SecretText.SecretStrSubstNo('Bearer %1', AccessToken));

        // Send GET request to check if file exists
        HttpResponseMessage := RestClient.Get(ApiUrl);

        if HttpResponseMessage.GetHttpStatusCode() = 200 then begin
            // File exists, extract SHA
            ResponseText := HttpResponseMessage.GetContent().AsText();
            if ResponseJson.ReadFrom(ResponseText) then
                if ResponseJson.Get('sha', ShaToken) then
                    exit(ShaToken.AsValue().AsText());
        end;

        // File doesn't exist or error occurred
        exit('');
    end;
}

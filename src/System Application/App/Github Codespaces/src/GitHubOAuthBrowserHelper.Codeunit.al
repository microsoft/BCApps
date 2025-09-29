// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Codespaces;

using System.RestClient;

codeunit 8431 "GitHub OAuth Browser Helper"
{
    var
        RestClient: Codeunit "Rest Client";
        AccessToken: SecretText;
        GithubUserName: Text[100];

    procedure GetGitHubAccessTokenViaDeviceFlow(): SecretText
    begin
        exit(AccessToken);
        //exit(RequestAuthWithMenu());
    end;

    procedure SetGitHubAccessToken(Token: Text)
    begin
        AccessToken := Token;
    end;

    procedure GetGitHubUserName(): Text[100]
    begin
        exit(GithubUserName);
    end;

    procedure SetGitHubUserName(UserName: Text[100])
    begin
        GithubUserName := UserName;
    end;

    procedure RequestAuthWithMenu(): SecretText
    var
        HttpContent: Codeunit "Http Content";
        HttpResponseMessage: Codeunit "Http Response Message";
        RequestBody: JsonObject;
        ResponseContent: JsonObject;
        UserCode: Text;
        VerificationUri: Text;
        JToken: JsonToken;
        MenuChoice: Integer;
        EmptySecretText: SecretText;
        DeviceCode: Text;
        AuthTxt: Label 'Github Authorization Required\Please visit: %1\and enter code: %2\to authorize this application.\What would you like to do?', Comment = '%1: Verification URI, %2: User Code';
    begin
        // Step 1: Get device codes (same as before)
        RequestBody.Add('client_id', 'Iv1.b507a08c87ecfe98');
        RequestBody.Add('scope', 'repo codespace user');

        RestClient.Initialize();
        RestClient.SetDefaultRequestHeader('Accept', 'application/json');

        HttpContent := HttpContent.Create(RequestBody);
        HttpResponseMessage := RestClient.Post('https://github.com/login/device/code', HttpContent);

        if not HttpResponseMessage.GetIsSuccessStatusCode() then
            Error('Failed to initiate device flow: %1', HttpResponseMessage.GetReasonPhrase());

        ResponseContent := HttpResponseMessage.GetContent().AsJsonObject();

        // Extract values
        ResponseContent.Get('device_code', JToken);
        DeviceCode := JToken.AsValue().AsText();
        ResponseContent.Get('user_code', JToken);
        UserCode := JToken.AsValue().AsText();
        ResponseContent.Get('verification_uri', JToken);
        VerificationUri := JToken.AsValue().AsText();

        // Interactive menu flow
        repeat
            MenuChoice := StrMenu('Open GitHub in browser,I have completed authorization,Check authorization status,Cancel', 1,
                                 StrSubstNo(AuthTxt, VerificationUri, UserCode));

            case MenuChoice of
                1:
                    begin // Open browser
                        Hyperlink(VerificationUri);
                        Message('Browser opened. Please complete the authorization and return here.');
                    end;
                2:
                    begin // Check if completed
                        AccessToken := CheckDeviceAuthorization(DeviceCode);
                        if not AccessToken.IsEmpty() then
                            exit(AccessToken)
                        else
                            Message('Authorization not yet complete. Please finish the process in your browser.');
                    end;
                3:
                    begin // Check status
                        AccessToken := CheckDeviceAuthorization(DeviceCode);
                        if not AccessToken.IsEmpty() then begin
                            Message('Authorization successful!');
                            exit(AccessToken);
                        end else
                            Message('Still waiting for authorization...');
                    end;
                0, 4:
                    exit(EmptySecretText); // Cancel
            end;
        until false;
    end;

    procedure CheckDeviceAuthorization(DeviceCode: Text): SecretText
    var
        HttpContent: Codeunit "Http Content";
        HttpResponseMessage: Codeunit "Http Response Message";
        RequestBody: JsonObject;
        ResponseContent: JsonObject;
        JToken: JsonToken;
        ErrorCode: Text;
        EmptySecretText: SecretText;
    begin
        RequestBody.Add('client_id', 'Iv1.b507a08c87ecfe98'); // GitHub CLI's public client ID
        RequestBody.Add('device_code', DeviceCode);
        RequestBody.Add('grant_type', 'urn:ietf:params:oauth:grant-type:device_code');

        RestClient.Initialize();
        RestClient.SetDefaultRequestHeader('Accept', 'application/json');

        HttpContent := HttpContent.Create(RequestBody);
        HttpResponseMessage := RestClient.Post('https://github.com/login/oauth/access_token', HttpContent);

        if HttpResponseMessage.GetIsSuccessStatusCode() then begin
            ResponseContent := HttpResponseMessage.GetContent().AsJsonObject();

            if ResponseContent.Get('access_token', JToken) then begin
                AccessToken := JToken.AsValue().AsText();
                exit(AccessToken);
            end;
        end;

        // Check for specific errors
        if ResponseContent.Get('error', JToken) then begin
            ErrorCode := JToken.AsValue().AsText();
            case ErrorCode of
                'authorization_pending':
                    exit(EmptySecretText); // Still waiting for user authorization
                'slow_down':
                    begin
                        Sleep(5000); // Wait extra 5 seconds
                        exit(EmptySecretText); // Still waiting
                    end;
                'expired_token':
                    Error('The device code has expired. Please restart the authorization process.');
                'access_denied':
                    Error('Authorization was denied by the user.');
                else
                    Error('Authorization failed: %1', ErrorCode);
            end;
        end;

        exit(EmptySecretText);
    end;

}
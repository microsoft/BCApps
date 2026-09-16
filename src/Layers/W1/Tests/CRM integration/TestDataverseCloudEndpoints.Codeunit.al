// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

// Test double simulating a partner-supplied sovereign-cloud implementation of the
// "Dataverse Cloud Endpoints" interface. Returns US Government (GCC High) style endpoints so tests
// can assert that a partner override flows through the CDS connection code.
codeunit 139201 "Test Dataverse Cloud Endpoints" implements "Dataverse Cloud Endpoints"
{
    var
        OAuthAuthorityUrlTxt: Label 'https://login.microsoftonline.us/common/oauth2', Locked = true;
        ClientCredentialsTokenAuthorityUrlTxt: Label 'https://login.microsoftonline.us/organizations/oauth2/v2.0/token', Locked = true;
        GlobalDiscoveryScopeTxt: Label 'https://globaldisco.crm.microsoftdynamics.us/user_impersonation', Locked = true;
        GlobalDiscoveryApiUrlTxt: Label 'https://globaldisco.crm.microsoftdynamics.us/api/discovery/v2.0/Instances', Locked = true;

    procedure GetOAuthAuthorityUrl(): Text
    begin
        exit(OAuthAuthorityUrlTxt);
    end;

    procedure GetClientCredentialsTokenAuthorityUrl(): Text
    begin
        exit(ClientCredentialsTokenAuthorityUrlTxt);
    end;

    procedure GetGlobalDiscoveryScope(): Text
    begin
        exit(GlobalDiscoveryScopeTxt);
    end;

    procedure GetGlobalDiscoveryApiUrl(): Text
    begin
        exit(GlobalDiscoveryApiUrlTxt);
    end;
}

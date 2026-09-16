// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

/// <summary>
/// Default (commercial) implementation of <see cref="Dataverse Cloud Endpoints"/>, returning the
/// worldwide OAuth authority and Dataverse Global Discovery endpoints.
/// </summary>
codeunit 7208 "Commercial Dataverse Endpoints" implements "Dataverse Cloud Endpoints"
{
    Access = Internal;

    var
        OAuthAuthorityUrlTxt: Label 'https://login.microsoftonline.com/common/oauth2', Locked = true;
        ClientCredentialsTokenAuthorityUrlTxt: Label 'https://login.microsoftonline.com/organizations/oauth2/v2.0/token', Locked = true;
        GlobalDiscoveryScopeTxt: Label 'https://globaldisco.crm.dynamics.com/user_impersonation', Locked = true;
        GlobalDiscoveryApiUrlTxt: Label 'https://globaldisco.crm.dynamics.com/api/discovery/v2.0/Instances', Locked = true;

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

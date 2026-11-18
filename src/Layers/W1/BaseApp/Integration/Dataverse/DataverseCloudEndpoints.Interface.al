// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

/// <summary>
/// Provides the cloud-specific OAuth authority and Dataverse Global Discovery endpoints used when
/// connecting to Dataverse. Implement this interface to support sovereign clouds (for example
/// GCC High, US-DoD or China), where these hosts differ from the worldwide (commercial) defaults.
/// </summary>
interface "Dataverse Cloud Endpoints"
{
    Access = Public;

    /// <summary>
    /// Gets the OAuth authority URL used for the authorization code flow (delegated user sign-in).
    /// </summary>
    /// <returns>The OAuth authority URL, for example 'https://login.microsoftonline.com/common/oauth2'.</returns>
    procedure GetOAuthAuthorityUrl(): Text;

    /// <summary>
    /// Gets the OAuth authority URL used for the client credentials flow (service-to-service tokens).
    /// </summary>
    /// <returns>The OAuth token authority URL, for example 'https://login.microsoftonline.com/organizations/oauth2/v2.0/token'.</returns>
    procedure GetClientCredentialsTokenAuthorityUrl(): Text;

    /// <summary>
    /// Gets the OAuth scope requested when acquiring a token for the Dataverse Global Discovery service.
    /// </summary>
    /// <returns>The Global Discovery scope, for example 'https://globaldisco.crm.dynamics.com/user_impersonation'.</returns>
    procedure GetGlobalDiscoveryScope(): Text;

    /// <summary>
    /// Gets the Dataverse Global Discovery service instances endpoint used to enumerate environments.
    /// </summary>
    /// <returns>The Global Discovery instances URL, for example 'https://globaldisco.crm.dynamics.com/api/discovery/v2.0/Instances'.</returns>
    procedure GetGlobalDiscoveryApiUrl(): Text;

    /// <summary>
    /// Gets the trusted host suffix for this cloud's Dataverse environment URLs, used to validate the
    /// user-entered environment URL for online (SaaS) connections. Return an empty string to skip host
    /// validation. The default implementation returns an empty string, so clouds that do not override
    /// it are not affected.
    /// </summary>
    /// <returns>The trusted environment host suffix, for example 'dynamics.com'; empty to skip validation.</returns>
    procedure GetEnvironmentHostSuffix(): Text
    begin
        exit('');
    end;
}

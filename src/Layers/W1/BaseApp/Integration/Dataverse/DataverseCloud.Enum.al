// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

/// <summary>
/// Identifies the cloud whose OAuth authority and Dataverse Global Discovery endpoints are used when
/// connecting to Dataverse. Extend this enum and implement <see cref="Dataverse Cloud Endpoints"/> to
/// add support for a sovereign cloud (for example GCC High, US-DoD or China), then select it per tenant
/// through <c>CDS Connection Setup.SetDataverseCloud</c>.
/// </summary>
enum 7207 "Dataverse Cloud" implements "Dataverse Cloud Endpoints"
{
    Extensible = true;

    /// <summary>
    /// The worldwide (commercial) cloud, using the public login.microsoftonline.com and
    /// globaldisco.crm.dynamics.com hosts. This is the default.
    /// </summary>
    value(0; Commercial)
    {
        Caption = 'Commercial';
        Implementation = "Dataverse Cloud Endpoints" = "Commercial Dataverse Endpoints";
    }
}

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;
using System.Security.AccessControl;

permissionset 6414 "ForNAV EDoc Setup"
{
    Access = Internal;
    Assignable = true;
    IncludedPermissionSets = LOGIN, "D365 BASIC", Microsoft.eServices.EDocument."E-Doc. Core - Admin", SUPER;
    Permissions =
        page "ForNAV Peppol Oauth API" = X,
        tabledata "ForNAV Peppol Setup" = RIMD,
        tabledata "ForNAV Peppol Role" = R;
}
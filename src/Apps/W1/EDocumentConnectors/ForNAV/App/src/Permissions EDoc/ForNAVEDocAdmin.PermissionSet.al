// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

permissionset 6414 "FORNAV E-Doc Admin"
{
    Access = Internal;
    Assignable = true;
    Permissions =
        page "ForNAV Peppol Oauth API" = X,
        tabledata "ForNAV Peppol Setup" = RIMD,
        tabledata "ForNAV Peppol Role" = RIMD;
}
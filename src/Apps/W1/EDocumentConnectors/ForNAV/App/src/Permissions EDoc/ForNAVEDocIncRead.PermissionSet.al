// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

permissionset 6412 "ForNAV EDoc Inc Read"
{
    Access = Public;
    Assignable = false;

    Permissions =
        tabledata "ForNAV Peppol Setup" = R,
        tabledata "ForNAV Incoming E-Document" = RIMD;
}
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using Microsoft.eServices.EDocument;
permissionset 6410 "FORNAV EDoc Read"
{
    Caption = 'ForNAV EDocument Connect Read';
    Access = Public;
    Assignable = true;
    IncludedPermissionSets = "E-Doc. Core - Read";
    Permissions = tabledata "ForNAV Incoming E-Document" = R;
}
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;
using Microsoft.eServices.EDocument;

permissionset 6413 "ForNAV EDoc Edit"
{
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "E-Doc. Core - User", "ForNAV EDoc Inc Read";
}
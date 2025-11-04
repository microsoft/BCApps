// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using System.Security.AccessControl;

permissionsetextension 6413 "FORNAV Peppol D365 Team Member" extends "D365 Team Member"
{
    IncludedPermissionSets = "FORNAV E-Doc User";
}

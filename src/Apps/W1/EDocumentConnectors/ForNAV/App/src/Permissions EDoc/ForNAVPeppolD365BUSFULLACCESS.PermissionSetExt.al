// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using System.Security.AccessControl;
permissionsetextension 6414 "FORNAV Peppol D365 BUS FULL ACCESS" extends "D365 BUS FULL ACCESS"
{
    IncludedPermissionSets = "FORNAV E-Doc Admin";
}

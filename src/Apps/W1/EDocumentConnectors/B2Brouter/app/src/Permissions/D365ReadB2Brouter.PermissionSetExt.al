// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.B2Brouter;

using System.Security.AccessControl;

permissionsetextension 6491 "D365 Read - B2Brouter" extends "D365 READ"
{
    IncludedPermissionSets = "B2Brouter Edit";
}

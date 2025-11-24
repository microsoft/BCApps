// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Manufacturing.Permissions;

using Microsoft.QualityManagement.Integration.Assembly;
using Microsoft.QualityManagement.Integration.Manufacturing;
using Microsoft.QualityManagement.Integration.Manufacturing.Routing;
using Microsoft.QualityManagement.Permissions;
using Microsoft.QualityManagement.Utilities;

/// <summary>
/// Adds permissions for manufacturing objects
/// </summary>
permissionsetextension 20470 "Qlty. Mfg. Mngmnt. - Objects" extends "QltyMngmnt - Objects"
{
    Permissions =
        codeunit "Qlty. Manufactur. Integration" = X,
        codeunit "Qlty. Assembly Integration" = X,
        codeunit "Qlty. Filter Helpers - Mfg." = X,
        codeunit "Qlty. Session Helper - Mfg." = X,
        page "Qlty. Prod. Gen. Rule Wizard" = X,
        page "Qlty. Routing Line Lookup" = X;
}

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Manufacturing.Permissions;

using Microsoft.QualityManagement.Permissions;
using Microsoft.QualityManagement.Integration.Manufacturing;
using Microsoft.QualityManagement.Integration.Manufacturing.Routing;

/// <summary>
/// Adds permissions for manufacturing objects
/// </summary>
permissionsetextension 20471 "Qlty. Mfg General" extends QltyGeneral
{
    Permissions =
        codeunit "Qlty. Manufactur. Integration" = X,
        //codeunit "Qlty. Mfg. Filter Helpers" = X,
        //codeunit "Qlty. Mfg. Session Helper" = X,
        page "Qlty. Prod. Gen. Rule Wizard" = X,
        page "Qlty. Routing Line Lookup" = X;
}

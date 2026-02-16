// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Installation;

using Microsoft.QualityManagement.Setup.ApplicationAreas;

/// <summary>
/// Install codeunit.
/// </summary>
codeunit 20421 "Qlty. Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        QltyApplicationAreaMgmt: Codeunit "Qlty. Application Area Mgmt.";
    begin
        QltyApplicationAreaMgmt.RefreshExperienceTierCurrentCompany();
    end;
}

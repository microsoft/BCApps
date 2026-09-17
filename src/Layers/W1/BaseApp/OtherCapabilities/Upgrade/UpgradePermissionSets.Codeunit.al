// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Upgrade;

/// <summary>
/// Upgrade code to fix references of obsolete permission sets.
/// </summary>
codeunit 104042 "Upgrade Permission Sets"
{
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    begin
        RunUpgrade();
    end;

    internal procedure RunUpgrade()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade('') then
            exit;

        ReplaceObsoletePermissionSets();
    end;


    local procedure ReplaceObsoletePermissionSets()
    var
        ServerSettings: Codeunit "Server Setting";
    begin
        // Run the upgrade code only if the new permission system is enabled (permissions sets come from extensions) 
        if not ServerSettings.GetUsePermissionSetsFromExtensions() then
            exit;

    end;


    var
        NewPermissionSetNotFoundTxt: Label 'Skipping the upgrade of %1 to %2, as we could not find the permission set %2.', Locked = true;
        TelemetryCategoryTxt: Label 'AL SaaS upgrade', Locked = true;
}

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

codeunit 99001501 "Subcontracting Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        CurrentAppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentAppInfo);

        if CurrentAppInfo.DataVersion() = Version.Create(0, 0, 0, 0) then
            HandleFreshInstallPerCompany()
        else
            HandleReinstallPerCompany();
    end;

    trigger OnInstallAppPerDatabase()
    var
        CurrentAppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentAppInfo);
        if CurrentAppInfo.DataVersion() = Version.Create(0, 0, 0, 0) then
            HandleFreshInstallPerDatabase()
        else
            HandleReinstallPerDatabase();
    end;

    local procedure HandleFreshInstallPerCompany()
    var
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();
    end;

    local procedure HandleReinstallPerCompany()
    var
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();
    end;

    local procedure HandleFreshInstallPerDatabase()
    begin
    end;

    local procedure HandleReinstallPerDatabase()
    begin
    end;
}
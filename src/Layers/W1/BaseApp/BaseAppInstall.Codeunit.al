// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.Upgrade;

codeunit 5000 "BaseApp Install"
{
    SubType = Install;

    trigger OnInstallAppPerCompany()
    begin
        AddWordTemplateTables();
    end;


    local procedure AddWordTemplateTables()
    var
        UpgradeBaseApp: Codeunit "Upgrade - BaseApp";
    begin
        UpgradeBaseApp.UpgradeWordTemplateTables();
    end;
}
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

using System.Upgrade;

codeunit 9222 "User Settings Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Application User Settings" = rim;
    ObsoleteState = Pending;
    ObsoleteReason = 'Table "Extra Settings" has been removed in version 26.';
    ObsoleteTag = '26.0';

    local procedure GetUserSettingsUpgradeTag(): Code[250]
    begin
        exit('MS-417094-UserSettingsTransferFields-20211125');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerDatabaseUpgradeTags, '', false, false)]
    local procedure RegisterPerDatabaseUpgradeTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetUserSettingsUpgradeTag());
    end;
}
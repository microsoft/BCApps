// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

using System.Upgrade;

codeunit 4608 "Ext. SharePoint Upgrade"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Subtype = Upgrade;
    Permissions = tabledata "Ext. SharePoint Account" = rm;

    trigger OnUpgradePerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetUseLegacyRestAPIUpgradeTag()) then
            exit;

        SetUseLegacyRestAPIForExistingAccounts();

        UpgradeTag.SetUpgradeTag(GetUseLegacyRestAPIUpgradeTag());
    end;

    local procedure SetUseLegacyRestAPIForExistingAccounts()
    var
        ExtSharePointAccount: Record "Ext. SharePoint Account";
    begin
        ExtSharePointAccount.SetRange("Use legacy REST API", false);
        if ExtSharePointAccount.IsEmpty() then
            exit;

        ExtSharePointAccount.ModifyAll("Use legacy REST API", true);
    end;

    internal procedure GetUseLegacyRestAPIUpgradeTag(): Code[250]
    begin
        exit('MS-5833-SharePointUseLegacyRestAPI-20260313');
    end;
}

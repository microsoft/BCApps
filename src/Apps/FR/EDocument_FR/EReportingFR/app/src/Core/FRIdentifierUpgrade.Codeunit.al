// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using System.Upgrade;
using System.Utilities;

codeunit 10972 "FR Identifier Upgrade"
{
    Access = Internal;
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        ErrorMessage: Record "Error Message";
        FRIdentifierMigration: Codeunit "FR Identifier Migration";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetUpgradeTag()) then
            exit;
        FRIdentifierMigration.PrepareCompany(ErrorMessage, '');
        UpgradeTag.SetUpgradeTag(GetUpgradeTag());
    end;

    procedure GetUpgradeTag(): Code[250]
    begin
        exit('MS-FR-LegalIdentifiers-v1-20261015');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterUpgradeTag(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetUpgradeTag());
    end;
}

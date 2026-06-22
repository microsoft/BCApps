// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using System.Upgrade;

codeunit 99001570 "Subc. Upgrade Tag Def. Ext."
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetSubcontractingUpgradeTag());
    end;

    internal procedure GetSubcontractingUpgradeTag(): Code[250]
    begin
        exit('MS-406123-Subcontracting-20260601');
    end;
}
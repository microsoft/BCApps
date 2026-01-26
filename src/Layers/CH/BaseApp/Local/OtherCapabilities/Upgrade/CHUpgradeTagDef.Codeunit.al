// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

#if not CLEANSCHEMA27
using System.Upgrade;
#endif

codeunit 35517 "CH Upgrade Tag Def."
{
    // Tag Structure - MS-[TFSID]-[Description]-[DateChangeWasDoneToSeeHowOldItWas]
    // Tags must be the same in all branches

    trigger OnRun()
    begin
    end;

#if not CLEANSCHEMA27
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(UpgradeGLAmountFCYAndCurrencyCode());
    end;

    internal procedure UpgradeGLAmountFCYAndCurrencyCode(): Code[250]
    begin
        exit('MS-578083-UpgradeGLAmountFCYAndCurrencyCode-20250514')
    end;
#endif

}

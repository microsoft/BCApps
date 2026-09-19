// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
/// <summary>
/// Handles data upgrades between Avalara connector app versions, including service integration migration and field transfers.
/// </summary>
namespace Microsoft.EServices.EDocumentConnector.Avalara;

#if not CLEAN30
#pragma warning disable AS0130
#pragma warning disable PTE0025
codeunit 6380 Upgrade
#pragma warning restore AS0130
#pragma warning restore PTE0025
{
    Subtype = Upgrade;
    Access = Internal;
    ObsoleteState = Pending;
    ObsoleteReason = 'Obsolete schema migration code has been removed.';
    ObsoleteTag = '30.0';

    trigger OnUpgradePerCompany()
    begin
    end;

    local procedure UpdateServiceIntegration()
    begin
    end;

    local procedure UpdateAvalaraDocId()
    begin
    end;

    local procedure RegisterPerCompanyTags(PerCompanyUpgradeTags: List of [Code[250]])
    begin
    end;

    local procedure UpgradeServiceIntegrationTag(): Code[250]
    begin
    end;

    local procedure UpgradeAvalaraDocIdTag(): Code[250]
    begin
    end;
}
#endif
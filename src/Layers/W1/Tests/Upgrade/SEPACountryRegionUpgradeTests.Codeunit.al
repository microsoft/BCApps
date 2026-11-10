// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
using Microsoft.Foundation.Address;
using Microsoft.Upgrade;
using System.Upgrade;

codeunit 135950 "SEPA Country/Region Upg. Tests"
{
    Subtype = Test;

    [Test]
    procedure SEPAValuesSurviveMigrationOrRepeatedUpgrade()
    var
        UpgradeStatus: Codeunit "Upgrade Status";
        CountryRegionRef: RecordRef;
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        CountryRegionRef.Open(Database::"Country/Region");
        if not CountryRegionRef.DataPerCompany() then
            exit;
        CountryRegionRef.Close();

        VerifyCountryRegion('UPG-SEPA-Y');
        VerifyCountryRegion('UPG-SEPA-N');
    end;

    [Test]
    procedure SEPAMigrationIsMarkedComplete()
    var
        UpgradeStatus: Codeunit "Upgrade Status";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        Assert: Codeunit "Library Assert";
    begin
        if not UpgradeStatus.UpgradeTriggered() then
            exit;

        Assert.IsTrue(
            UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSEPACountryRegionUpgradeTag()),
            'The SEPA Country/Region upgrade was not marked complete.');
    end;

    local procedure VerifyCountryRegion(CountryCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
        ExpectedSEPAAllowed: Boolean;
    begin
        CountryRegion.Get(CountryCode);
        Evaluate(ExpectedSEPAAllowed, CountryRegion.Name, 9);
        CountryRegion.TestField("SEPA Payments Allowed", ExpectedSEPAAllowed);
        CountryRegion.TestField("ISO Code", '');
        CountryRegion.TestField("EU Country/Region Code", '');
        CountryRegion.TestField("Last Modified Date Time", CreateDateTime(20260101D, 010203T));
    end;
}

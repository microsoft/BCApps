// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

#if not CLEANSCHEMA33
using Microsoft.Foundation.Address;
using System.Reflection;
#endif
using System.Upgrade;

codeunit 104001 "Upgrade SEPA Country/Region"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetSEPACountryRegionUpgradeTag()) then
            exit;

#if not CLEANSCHEMA33
        CopyLegacySEPAAllowed(10800);
        CopyLegacySEPAAllowed(11400);
        CopyLegacySEPAAllowed(13400);
        CopyLegacySEPAAllowed(2000005);
#endif

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetSEPACountryRegionUpgradeTag());
    end;

#if not CLEANSCHEMA33
    local procedure CopyLegacySEPAAllowed(LegacyFieldNo: Integer)
    var
        CountryRegion: Record "Country/Region";
        LegacyField: Record Field;
        SEPACountryDataTransfer: DataTransfer;
    begin
        if not LegacyField.Get(Database::"Country/Region", LegacyFieldNo) then
            exit;

        SEPACountryDataTransfer.SetTables(Database::"Country/Region", Database::"Country/Region");
        SEPACountryDataTransfer.AddFieldValue(LegacyFieldNo, CountryRegion.FieldNo("SEPA Payments Allowed"));
        SEPACountryDataTransfer.UpdateAuditFields := false;
        SEPACountryDataTransfer.CopyFields();
    end;
#endif
}

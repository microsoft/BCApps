// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FADepreciation;

#if not CLEAN30
codeunit 18640 "Migrate FA Depreciation Data"
{
    Subtype = Upgrade;
    ObsoleteState = Pending;
    ObsoleteReason = 'Obsolete schema migration code has been removed.';
    ObsoleteTag = '30.0';

    trigger OnUpgradePerCompany()
    begin
    end;

    local procedure MigrateFAShiftData()
    begin
    end;
}
#endif

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

#if not CLEAN30
using System.Environment.Configuration;
using System.Upgrade;
#endif

codeunit 32000003 "FI Banking Payment Feature"
{
    Access = Internal;

    procedure IsEnabled(): Boolean
#if not CLEAN30
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
#endif
    begin
#if not CLEAN30
        exit(FeatureManagementFacade.IsEnabled(FeatureIdTok));
#else
        exit(true);
#endif
    end;

#if not CLEAN30
    procedure EnsureLegacyProcessingAllowed()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if IsEnabled() or UpgradeTag.HasUpgradeTag(MigrationTagTok) then
            Error(LegacyProcessingErr);
    end;
#endif

    var
#if not CLEAN30
        FeatureIdTok: Label 'BankingAndPaymentsFI', Locked = true;
        // Keep this shared cutover marker aligned with Banking Payments Tags FI.
        MigrationTagTok: Label 'MS-BankingAndPaymentsFIUpgradeTag-20261110', Locked = true;
        LegacyProcessingErr: Label 'Legacy Finnish banking processing is unavailable after cutover. Use the Banking and Payments FI app. Retained legacy entries are for history only.';
#endif
}

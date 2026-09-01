#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Foundation.Navigate;
using System.Environment.Configuration;
using System.Upgrade;

codeunit 10831 "Feature - PaymentMgt FR" implements "Feature Data Update"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteReason = 'Feature Payment Management will be enabled by default in version 31.0.';
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';

    var
        TempDocumentEntry: Record "Document Entry" temporary;
        DescriptionTxt: Label 'Existing records in FR BaseApp fields will be copied to Payment App fields';

    procedure IsDataUpdateRequired(): Boolean;
    var
        PaymentDataMigrationFR: Codeunit "Payment Data Migration FR";
    begin
        PaymentDataMigrationFR.CountRecordsToMigrate(TempDocumentEntry);
        exit(not TempDocumentEntry.IsEmpty());
    end;

    procedure ReviewData();
    var
        DataUpgradeOverview: Page "Data Upgrade Overview";
    begin
        Commit();
        Clear(DataUpgradeOverview);
        DataUpgradeOverview.Set(TempDocumentEntry);
        DataUpgradeOverview.RunModal();
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    begin
        // The data update runs per company, and the framework has already set the status of the company that
        // was updated. The status of the other companies must stay Pending until their own data is migrated.
        SetUpgradeTags();
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status");
    var
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
        StartDateTime: DateTime;
        EndDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, 'Upgrade Payment', StartDateTime);
        UpgradePayment();
        EndDateTime := CurrentDateTime;
        FeatureDataUpdateMgt.LogTask(FeatureDataUpdateStatus, 'Upgrade Payment', EndDateTime);
    end;

    procedure GetTaskDescription() TaskDescription: Text;
    begin
        TaskDescription := DescriptionTxt;
    end;

    local procedure UpgradePayment()
    var
        PaymentDataMigrationFR: Codeunit "Payment Data Migration FR";
    begin
        // The same migration is run by the forced upgrade to version 31 in codeunit
        // "Upgrade Payment Management FR", so that both scenarios migrate the same data.
        PaymentDataMigrationFR.MigratePaymentData();
        PaymentDataMigrationFR.RemapPaymentStepObjectIDs();
    end;

    local procedure SetUpgradeTags()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagPayment: Codeunit "Upg. Tag Payment Management FR";
    begin
        // Set the upgrade tags of this company to indicate that the data update is executed and the feature
        // is enabled. This is needed when the feature is enabled by default in a future version, to skip the
        // data upgrade. The tags are per company, so the other companies still run their own data upgrade.
        if not UpgradeTag.HasUpgradeTag(UpgTagPayment.GetPaymentUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgTagPayment.GetPaymentUpgradeTag());

        if not UpgradeTag.HasUpgradeTag(UpgTagPayment.GetPaymentStepObjectIDsUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgTagPayment.GetPaymentStepObjectIDsUpgradeTag());
    end;
}
#endif

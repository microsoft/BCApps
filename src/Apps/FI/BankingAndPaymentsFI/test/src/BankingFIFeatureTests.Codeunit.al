// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using System.Environment.Configuration;
using System.TestLibraries.Upgrade;
using System.Upgrade;

codeunit 148236 "Banking FI Feature Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

#if not CLEAN30
    [Test]
    procedure RepeatedInactiveInstallDoesNotClassifyExistingCompanyAsFresh()
    var
        FeatureKey: Record "Feature Key";
        Status: Record "Feature Data Update Status";
        BeforeStatus: Record "Feature Data Update Status";
        Setup: Record "Reference File Setup FI";
        ExportSetup: Record "Bank Export/Import Setup";
        Bank: Record "Bank Account";
        Install: Codeunit "Banking Payments Install FI";
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
        Assert: Codeunit Assert;
        HadStatus: Boolean;
        HadRequest: Boolean;
        ModifiedAt: DateTime;
    begin
        if FeatureKey.Get('BankingAndPaymentsFI') then
            FeatureKey.TestField(Enabled, FeatureKey.Enabled::None);
        RemoveMigrationTag();
        HadStatus := BeforeStatus.Get('BankingAndPaymentsFI', CompanyName());
        HadRequest := UpgradeTag.HasUpgradeTag(Tags.GetRequestMarkerTag());
        ExportSetup.Code := 'FI-INACTIVE-EXPORT';
        ExportSetup.Direction := ExportSetup.Direction::Export;
        ExportSetup."Processing Codeunit ID" := 13413;
        ExportSetup.Insert();
        Bank."No." := 'FI-INACTIVE-BANK';
        Bank."Payment Export Format" := ExportSetup.Code;
        Bank.Insert();
        Setup."No." := Bank."No.";
        Setup."File Name" := 'user-owned-reference.xml';
        Setup.Insert();
        ModifiedAt := Setup.SystemModifiedAt;

        Install.InstallCompany();
        Install.InstallCompany();

        Assert.IsFalse(UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()), 'An existing inactive company must never receive a fresh-company completion tag.');
        Assert.AreEqual(HadRequest, UpgradeTag.HasUpgradeTag(Tags.GetRequestMarkerTag()), 'Installation must not prepare a cutover.');
        Assert.AreEqual(HadStatus, Status.Get('BankingAndPaymentsFI', CompanyName()), 'Installation must not manufacture a feature status.');
        if HadStatus then
            Assert.AreEqual(BeforeStatus."Feature Status", Status."Feature Status", 'Installation must not complete or reset an existing company.');
        Setup.Get(Bank."No.");
        Assert.AreEqual('user-owned-reference.xml', Setup."File Name", 'Repeated inactive installation must retain reference defaults.');
        Assert.AreEqual(ModifiedAt, Setup.SystemModifiedAt, 'Repeated inactive installation must not stamp existing setup.');
        ExportSetup.Get('FI-INACTIVE-EXPORT');
        Assert.AreEqual(13413, ExportSetup."Processing Codeunit ID", 'An inactive company must keep its legacy .09 exporter until real cutover.');
        Bank.Get('FI-INACTIVE-BANK');
        Assert.AreEqual(ExportSetup.Code, Bank."Payment Export Format", 'Installation must preserve the linked bank format.');
    end;

    [Test]
    procedure PrematureFacadeActivationDoesNotCopyOrComplete()
    var
        Setup: Record "Reference File Setup FI";
        Status: Record "Feature Data Update Status";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        Update: Codeunit "Banking Payments Update FI";
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
        Assert: Codeunit Assert;
    begin
        RemoveMigrationTag();
        Setup."No." := 'FI-PREMATURE';
        Setup."File Name" := 'unchanged.xml';
        Setup.Insert();
        SetPendingStatus(Status);
        asserterror Update.IsDataUpdateRequired();
        Assert.ExpectedError('A controlled upgrade is required');
        asserterror FeatureManagementFacade.UpdateData(Status);
        Assert.ExpectedError('A controlled upgrade is required');
        Status.Get('BankingAndPaymentsFI', CompanyName());
        Assert.AreEqual(Status."Feature Status"::Pending, Status."Feature Status", 'The failed framework update must roll back its Updating status.');
        Assert.IsFalse(UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()), 'Premature activation must not mark historical data migrated.');
        Setup.Get('FI-PREMATURE');
        Assert.AreEqual('unchanged.xml', Setup."File Name", 'Ordinary activation must not copy or overwrite business data.');
    end;

    [Test]
    procedure InvalidPreparationHasNoCompanySideEffects()
    var
        Status: Record "Feature Data Update Status";
        Update: Codeunit "Banking Payments Update FI";
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
        Assert: Codeunit Assert;
        HadRequest: Boolean;
    begin
        RemoveMigrationTag();
        SetPendingStatus(Status);
        HadRequest := UpgradeTag.HasUpgradeTag(Tags.GetRequestMarkerTag());
        asserterror Update.PrepareControlledUpgrade('not-a-version');
        Assert.IsTrue(
            (StrPos(GetLastErrorText(), 'authenticated management session') > 0) or
            (StrPos(GetLastErrorText(), 'four non-negative integers') > 0),
            'Preparation must reject either unauthorized execution or the invalid target before accessing business data.');
        Status.Get('BankingAndPaymentsFI', CompanyName());
        Assert.AreEqual(Status."Feature Status"::Pending, Status."Feature Status", 'Rejected preparation must not complete or reset framework status.');
        Assert.AreEqual(HadRequest, UpgradeTag.HasUpgradeTag(Tags.GetRequestMarkerTag()), 'Rejected preparation must not record a request.');
        Assert.IsFalse(UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()), 'Preparation is never migration completion.');
    end;

    [Test]
    procedure RequestRejectsSameOlderAndMalformedVersions()
    var
        Update: Codeunit "Banking Payments Update FI";
        Assert: Codeunit Assert;
        Target: Version;
    begin
        asserterror Update.ValidateRequestVersion('29.0.0.0', Version.Create('29.0.0.0'));
        Assert.ExpectedError('must be higher than the installed version');
        asserterror Update.ValidateRequestVersion('28.9.9.9', Version.Create('29.0.0.0'));
        Assert.ExpectedError('must be higher than the installed version');
        asserterror Update.ValidateRequestVersion('30.0.0', Version.Create('29.0.0.0'));
        Assert.ExpectedError('four non-negative integers');
        asserterror Update.ValidateRequestVersion('30.0.-1.0', Version.Create('29.0.0.0'));
        Assert.ExpectedError('four non-negative integers');
        Target := Update.ValidateRequestVersion(' 029.00.000.001 ', Version.Create('29.0.0.0'));
        Assert.IsTrue(Target = Version.Create('29.0.0.1'), 'Equivalent version spellings must select the same exact package.');
    end;

    [Test]
    procedure PreparedRequestSelectsOnlyExactUnscheduledTarget()
    var
        Status: Record "Feature Data Update Status";
        Update: Codeunit "Banking Payments Update FI";
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
        Assert: Codeunit Assert;
        Target: Version;
    begin
        RequirePlatformProvisioning();
        RemoveMigrationTag();
        SetPendingStatus(Status);
        Target := Version.Create('99.1.2.3');
        if UpgradeTag.HasUpgradeTag(Tags.GetRequestMarkerTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(Tags.GetRequestMarkerTag(), CopyStr(CompanyName(), 1, 30));
        if UpgradeTag.HasUpgradeTag(Tags.GetRequestTag(Target)) then
            UpgradeTagLibrary.DeleteUpgradeTag(Tags.GetRequestTag(Target), CopyStr(CompanyName(), 1, 30));
        UpgradeTag.SetUpgradeTag(Tags.GetRequestTag(Target));
        Assert.IsFalse(Update.ShouldMigrateDuringUpgrade(Target), 'A version tag without the atomic request marker is not a prepared request.');
        UpgradeTag.SetUpgradeTag(Tags.GetRequestMarkerTag());
        Assert.IsFalse(Update.ShouldMigrateDuringUpgrade(Version.Create('99.1.2.4')), 'A request cannot authorize another package version.');
        Assert.IsTrue(Update.ShouldMigrateDuringUpgrade(Target), 'A matching prepared target must not depend on facade IsEnabled before migration.');
        Status."Task Id" := CreateGuid();
        Status.Modify();
        asserterror Update.ShouldMigrateDuringUpgrade(Target);
        Assert.ExpectedError('no scheduled or running feature task');
        Assert.IsFalse(UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()), 'Selection and validation must not copy or complete the migration.');
    end;

    [Test]
    [CommitBehavior(CommitBehavior::Error)]
    procedure TagReadyFacadeCompletesWithoutRecopyOrOtherCompanyReset()
    var
        Setup: Record "Reference File Setup FI";
        Status: Record "Feature Data Update Status";
        OtherStatus: Record "Feature Data Update Status";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        Update: Codeunit "Banking Payments Update FI";
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
        Assert: Codeunit Assert;
    begin
        RequirePlatformProvisioning();
        RemoveMigrationTag();
        SetPendingStatus(Status);
        OtherStatus.Init();
        OtherStatus."Feature Key" := 'BankingAndPaymentsFI';
        OtherStatus."Company Name" := 'FI-CUTOVER-OTHER';
        OtherStatus."Data Update Required" := true;
        OtherStatus."Feature Status" := OtherStatus."Feature Status"::Complete;
        OtherStatus.Insert();
        Setup."No." := 'FI-TAG-READY';
        Setup."File Name" := 'lifecycle-snapshot.xml';
        Setup.Insert();
        // The fixture represents a completed lifecycle; this test never executes DataTransfer.
        UpgradeTag.SetUpgradeTag(Tags.GetMigrationTag());
        Assert.IsTrue(Update.IsDataUpdateRequired(), 'A lifecycle tag does not itself finish the framework status.');
        FeatureManagementFacade.UpdateData(Status);
        Status.Get('BankingAndPaymentsFI', CompanyName());
        Assert.AreEqual(Status."Feature Status"::Complete, Status."Feature Status", 'Only the public framework updater completes the status.');
        Assert.IsTrue(FeatureManagementFacade.IsEnabled('BankingAndPaymentsFI'), 'The completed company must be enabled before cutover returns.');
        OtherStatus.Get('BankingAndPaymentsFI', 'FI-CUTOVER-OTHER');
        Assert.AreEqual(OtherStatus."Feature Status"::Complete, OtherStatus."Feature Status", 'Completing one company must not reset other migrated companies.');
        Setup."File Name" := 'later-edit.xml';
        Setup.Modify();
        FeatureManagementFacade.UpdateData(Status);
        Assert.IsFalse(Update.ShouldMigrateDuringUpgrade(Version.Create('99.1.2.3')), 'A later upgrade must not recopy a completed company.');
        Setup.Get('FI-TAG-READY');
        Assert.AreEqual('later-edit.xml', Setup."File Name", 'Repeated completion must preserve replacement edits.');
        Status.Get('BankingAndPaymentsFI', CompanyName());
        Status."Feature Status" := Status."Feature Status"::Pending;
        Status.Modify();
        asserterror Update.ShouldMigrateDuringUpgrade(Version.Create('99.1.2.3'));
        Assert.ExpectedError('inconsistent migration and feature status');
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()), 'A reset must not erase migration evidence or permit recopying.');
    end;

    local procedure SetPendingStatus(var Status: Record "Feature Data Update Status")
    begin
        if not Status.Get('BankingAndPaymentsFI', CompanyName()) then begin
            Status.Init();
            Status."Feature Key" := 'BankingAndPaymentsFI';
            Status."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(Status."Company Name"));
            Status.Insert();
        end;
        Status."Data Update Required" := true;
        Status."Feature Status" := Status."Feature Status"::Pending;
        Status."Background Task" := false;
        Clear(Status."Task Id");
        Status."Session Id" := -1;
        Status."Server Instance Id" := -1;
        Status.Modify();
    end;

    local procedure RemoveMigrationTag()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
    begin
        if UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(Tags.GetMigrationTag(), CopyStr(CompanyName(), 1, 30));
    end;

    local procedure RequirePlatformProvisioning()
    var
        FeatureKey: Record "Feature Key";
    begin
        FeatureKey.Get('BankingAndPaymentsFI');
        FeatureKey.TestField(Enabled, FeatureKey.Enabled::"All Users");
        FeatureKey.TestField("Data Update Required", true);
    end;

    [Test]
    procedure DisabledFeatureDoesNotValidateReplacementFields()
    var
        Journal: Record "Gen. Journal Line";
        LibraryBanking: Codeunit "Library - Banking FI";
        Assert: Codeunit Assert;
    begin
        LibraryBanking.SetFeatureEnabled(false);
        BindSubscription(LibraryBanking);
        Journal.Validate("Payment Message", 'invalid-checksum');
        Assert.AreEqual('invalid-checksum', Journal."Payment Message", 'Replacement validation must be inert while disabled.');
        UnbindSubscription(LibraryBanking);
    end;
#endif

    [Test]
    procedure EnabledFeatureValidatesReplacementFields()
    var
        Journal: Record "Gen. Journal Line";
        LibraryBanking: Codeunit "Library - Banking FI";
        Assert: Codeunit Assert;
    begin
#if not CLEAN30
        LibraryBanking.SetFeatureEnabled(true);
        BindSubscription(LibraryBanking);
#endif
        asserterror Journal.Validate("Payment Message", '2687451');
        Assert.ExpectedError('Incorrect reference number.');
#if not CLEAN30
        UnbindSubscription(LibraryBanking);
#endif
    end;
}

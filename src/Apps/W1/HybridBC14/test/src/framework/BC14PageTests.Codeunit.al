// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration;
using Microsoft.DataMigration.BC14Reimplementation;
using Microsoft.Finance.GeneralLedger.Account;
using System.Integration;
using System.Security.AccessControl;
using System.TestLibraries.Environment;
using System.TestLibraries.Utilities;

codeunit 148909 "BC14 Page Tests"
{
    // [FEATURE] [BC14 Page Tests]
    // Merged from:
    //   - BC14 Balance Validation Pg Tst (148935)
    //   - BC14 Co. Upgrade Pg Tests (148932)
    //   - BC14 Errored Buffer Pg Tests (148927)
    //   - BC14 Mgmt PageExt Tests (148924)
    //   - BC14 Mig. Config Page Tests (148925)
    //   - BC14 Mig. Error Page Tests (148931)
    //   - BC14 Upgrade Settings Pg Tests (148934)

    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        BC14TestHelperFunctions: Codeunit "BC14 Helper Function Tests";

    // ============================================================
    // Balance Validation Page (from BC14BalanceValidationPgTst.Codeunit.al)
    // ============================================================

    local procedure ClearTestAccounts()
    var
        GLAccount: Record "G/L Account";
        BC14GLEntry: Record "BC14 G/L Entry";
    begin
        GLAccount.SetFilter("No.", 'BC14-BAL-*');
        GLAccount.DeleteAll();
        BC14GLEntry.SetFilter("G/L Account No.", 'BC14-BAL-*');
        BC14GLEntry.DeleteAll();
    end;

    local procedure InsertGLAccount(No: Code[20]; AccountType: Enum "G/L Account Type")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount."No." := No;
        GLAccount.Name := No;
        GLAccount."Account Type" := AccountType;
        GLAccount.Insert();
    end;

    local procedure InsertBC14GLEntry(EntryNo: Integer; GLAccountNo: Code[20]; DebitAmt: Decimal; CreditAmt: Decimal)
    var
        BC14GLEntry: Record "BC14 G/L Entry";
    begin
        BC14GLEntry.Init();
        BC14GLEntry."Entry No." := EntryNo;
        BC14GLEntry."G/L Account No." := GLAccountNo;
        BC14GLEntry."Debit Amount" := DebitAmt;
        BC14GLEntry."Credit Amount" := CreditAmt;
        BC14GLEntry.Amount := DebitAmt - CreditAmt;
        BC14GLEntry.Insert();
    end;

    [Test]
    procedure TestBalanceValidation_FiltersToPostingAccountsOnly()
    var
        BalanceValidation: TestPage "BC14 Balance Validation";
        FoundHeading: Boolean;
        FoundPosting: Boolean;
    begin
        // [SCENARIO] The page only lists G/L Accounts whose Account Type = Posting.
        ClearTestAccounts();
        InsertGLAccount('BC14-BAL-POST', "G/L Account Type"::Posting);
        InsertGLAccount('BC14-BAL-HEAD', "G/L Account Type"::Heading);

        // [WHEN] The page is opened
        BalanceValidation.OpenView();

        if BalanceValidation.First() then
            repeat
                if BalanceValidation."No.".Value() = 'BC14-BAL-POST' then
                    FoundPosting := true;
                if BalanceValidation."No.".Value() = 'BC14-BAL-HEAD' then
                    FoundHeading := true;
            until not BalanceValidation.Next();

        // [THEN] Only the Posting account is shown
        Assert.IsTrue(FoundPosting, 'Posting account should be listed.');
        Assert.IsFalse(FoundHeading, 'Heading account should be filtered out.');
        BalanceValidation.Close();
    end;

    [Test]
    procedure TestBalanceValidation_PageIsReadOnly()
    var
        BalanceValidation: TestPage "BC14 Balance Validation";
    begin
        // [SCENARIO] The balance validation list is non-editable.
        ClearTestAccounts();
        InsertGLAccount('BC14-BAL-POST', "G/L Account Type"::Posting);

        // [WHEN] The page is opened
        BalanceValidation.OpenView();

        // [THEN] The page itself is read-only
        Assert.IsFalse(BalanceValidation.Editable(), 'Balance Validation page should be read-only.');

        BalanceValidation.Close();
    end;

    [Test]
    procedure TestBalanceValidation_NoBC14Entries_StatusIsOk()
    var
        BalanceValidation: TestPage "BC14 Balance Validation";
    begin
        // [SCENARIO] When source has no BC14 G/L Entries and BC Online net change is also zero, status is OK.
        ClearTestAccounts();
        InsertGLAccount('BC14-BAL-POST', "G/L Account Type"::Posting);

        // [WHEN] The page is opened and positioned on the account
        BalanceValidation.OpenView();
        BalanceValidation.GotoKey('BC14-BAL-POST');

        // [THEN] Source amounts are zero, difference is zero, status is OK
        Assert.AreEqual(Format(0.0, 0, '<Precision,2:2><Standard Format,0>'), BalanceValidation."BC14 Debit".Value(), 'Source Debit should be 0 with no BC14 entries.');
        Assert.AreEqual(Format(0.0, 0, '<Precision,2:2><Standard Format,0>'), BalanceValidation."BC14 Credit".Value(), 'Source Credit should be 0 with no BC14 entries.');
        Assert.AreEqual(Format(0.0, 0, '<Precision,2:2><Standard Format,0>'), BalanceValidation.Difference.Value(), 'Difference should be 0 when both sides are 0.');
        Assert.AreEqual('OK', BalanceValidation.Status.Value(), 'Status should be OK when balances match.');

        BalanceValidation.Close();
    end;

    [Test]
    procedure TestBalanceValidation_SourceDiffersFromBC_StatusIsDifference()
    var
        BalanceValidation: TestPage "BC14 Balance Validation";
    begin
        // [SCENARIO] Source BC14 entries with no matching live G/L Entry yield a non-zero difference.
        ClearTestAccounts();
        InsertGLAccount('BC14-BAL-POST', "G/L Account Type"::Posting);
        InsertBC14GLEntry(900001, 'BC14-BAL-POST', 100, 0);
        InsertBC14GLEntry(900002, 'BC14-BAL-POST', 50, 0);

        // [WHEN] The page is opened and positioned on the account
        BalanceValidation.OpenView();
        BalanceValidation.GotoKey('BC14-BAL-POST');

        // [THEN] Source debit aggregates to 150 and status is DIFFERENCE
        Assert.AreEqual(Format(150.0, 0, '<Precision,2:2><Standard Format,0>'), BalanceValidation."BC14 Debit".Value(), 'Source Debit should aggregate both BC14 entries.');
        Assert.AreEqual('DIFFERENCE', BalanceValidation.Status.Value(), 'Status should be DIFFERENCE when source != BC.');

        BalanceValidation.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestBalanceValidation_ExportToExcel_ShowsNotImplementedMessage()
    var
        BalanceValidation: TestPage "BC14 Balance Validation";
    begin
        // [SCENARIO] Invoking Export to Excel surfaces a "not implemented" message.
        ClearTestAccounts();
        InsertGLAccount('BC14-BAL-POST', "G/L Account Type"::Posting);
        LibraryVariableStorage.Clear();

        // [WHEN] The user invokes Export to Excel
        BalanceValidation.OpenView();
        BalanceValidation.ExportToExcel.Invoke();

        // [THEN] The "not implemented" guidance message is shown
        Assert.IsTrue(
            LibraryVariableStorage.DequeueText().Contains('Excel'),
            'Export should surface a message mentioning Excel.');

        LibraryVariableStorage.AssertEmpty();
        BalanceValidation.Close();
    end;

    // ============================================================
    // Company Upgrade Status Page (from BC14CoUpgradePgTests.codeunit.al)
    // ============================================================

    local procedure ClearStatuses()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        BC14CompanyMigrationInfo: Record BC14CompanyMigrationInfo;
    begin
        HybridCompanyStatus.DeleteAll();
        BC14CompanyMigrationInfo.DeleteAll();
    end;

    local procedure InsertHybridStatus(CompanyNameValue: Text[50]; UpgradeStatus: Option)
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CompanyNameValue;
        HybridCompanyStatus."Upgrade Status" := UpgradeStatus;
        HybridCompanyStatus.Insert();
    end;

    local procedure InsertMigrationInfo(CompanyNameValue: Text[30]; CompletedMigrators: Integer; TotalMigrators: Integer; LastCompleted: Text[50])
    var
        BC14CompanyMigrationInfo: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanyMigrationInfo.Init();
        BC14CompanyMigrationInfo.Name := CompanyNameValue;
        BC14CompanyMigrationInfo."Phase Migrators Completed" := CompletedMigrators;
        BC14CompanyMigrationInfo."Phase Migrators Total" := TotalMigrators;
        BC14CompanyMigrationInfo."Last Completed Migrator" := LastCompleted;
        BC14CompanyMigrationInfo.Insert();
    end;

    [Test]
    procedure TestCompanyUpgradeStatus_FiltersEmptyNameRow()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        UpgradeStatusPage: TestPage "BC14 Company Upgrade Status";
        EmptyNameFound: Boolean;
    begin
        // [SCENARIO] The page filters out the per-database empty-name row to match the parent field count.
        ClearStatuses();
        InsertHybridStatus('', HybridCompanyStatus."Upgrade Status"::Pending);
        InsertHybridStatus('CO_ALPHA', HybridCompanyStatus."Upgrade Status"::Started);

        // [WHEN] The page is opened
        UpgradeStatusPage.OpenView();

        // [THEN] The empty-name row is excluded
        if UpgradeStatusPage.First() then
            repeat
                if UpgradeStatusPage.Name.Value() = '' then
                    EmptyNameFound := true;
            until not UpgradeStatusPage.Next();

        Assert.IsFalse(EmptyNameFound, 'The empty-name (per-database) row should be filtered out.');
        UpgradeStatusPage.Close();
    end;

    [Test]
    procedure TestCompanyUpgradeStatus_IsReadOnly()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        UpgradeStatusPage: TestPage "BC14 Company Upgrade Status";
    begin
        // [SCENARIO] The page does not allow inserts, edits, or deletes.
        ClearStatuses();
        InsertHybridStatus('CO_ALPHA', HybridCompanyStatus."Upgrade Status"::Started);

        // [WHEN] The page is opened
        UpgradeStatusPage.OpenView();
        UpgradeStatusPage.First();

        // [THEN] Action commands and field editability are read-only
        Assert.IsFalse(UpgradeStatusPage.Editable(), 'Page should be read-only.');
        Assert.IsFalse(UpgradeStatusPage.Name.Editable(), 'Name field should not be editable.');
        Assert.IsFalse(UpgradeStatusPage."Upgrade Status".Editable(), 'Upgrade Status field should not be editable.');

        UpgradeStatusPage.Close();
    end;

    [Test]
    procedure TestCompanyUpgradeStatus_ShowsCurrentPhaseAndProgress()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        UpgradeStatusPage: TestPage "BC14 Company Upgrade Status";
    begin
        // [SCENARIO] The current phase, progress, and last completed migrator come from BC14CompanyMigrationInfo.
        ClearStatuses();
        InsertHybridStatus('CO_BETA', HybridCompanyStatus."Upgrade Status"::Started);
        InsertMigrationInfo('CO_BETA', 4, 9, 'Customer Migrator');

        // [WHEN] The page is opened
        UpgradeStatusPage.OpenView();
        UpgradeStatusPage.GotoKey('CO_BETA');

        // [THEN] Phase progress shows the configured "completed / total" string and the last completed migrator
        Assert.AreEqual('4 / 9', UpgradeStatusPage.PhaseProgress.Value(), 'Phase progress should show completed/total counts.');
        Assert.AreEqual('Customer Migrator', UpgradeStatusPage.LastCompletedMigrator.Value(), 'Last completed migrator should match the migration info.');

        UpgradeStatusPage.Close();
    end;

    [Test]
    procedure TestCompanyUpgradeStatus_NoMigrationInfo_ProgressEmpty()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        UpgradeStatusPage: TestPage "BC14 Company Upgrade Status";
    begin
        // [SCENARIO] When no BC14CompanyMigrationInfo row exists for the company, phase/progress fields are empty.
        ClearStatuses();
        InsertHybridStatus('CO_GAMMA', HybridCompanyStatus."Upgrade Status"::Pending);

        // [WHEN] The page is opened
        UpgradeStatusPage.OpenView();
        UpgradeStatusPage.GotoKey('CO_GAMMA');

        // [THEN] Current Phase, Progress, and Last Completed Migrator are all blank
        Assert.AreEqual('', UpgradeStatusPage.CurrentPhase.Value(), 'Current Phase should be empty when no migration info exists.');
        Assert.AreEqual('', UpgradeStatusPage.PhaseProgress.Value(), 'Progress should be empty when no migration info exists.');
        Assert.AreEqual('', UpgradeStatusPage.LastCompletedMigrator.Value(), 'Last Completed Migrator should be empty when no migration info exists.');

        UpgradeStatusPage.Close();
    end;

    // ============================================================
    // Errored Buffer Records Page (from BC14ErroredBufferPgTests.codeunit.al)
    // ============================================================

    local procedure ClearErrorOverview()
    var
        DataMigrationError: Record "Data Migration Error";
    begin
        DataMigrationError.DeleteAll();
    end;

    local procedure InsertErrorOverview(SourceTableId: Integer)
    var
        DataMigrationError: Record "Data Migration Error";
    begin
        DataMigrationError.Init();
        DataMigrationError."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(DataMigrationError."Company Name"));
        DataMigrationError."Source Table ID" := SourceTableId;
        DataMigrationError."Source Table Name" := 'BC14 G/L Account';
        DataMigrationError."Destination Table ID" := Database::"G/L Account";
        DataMigrationError."Migration Type" := 'Test Migrator';
        DataMigrationError."Error Message" := 'Test error';
        DataMigrationError.Insert(true);
    end;

    [Test]
    procedure TestErroredBufferRecords_NoFilters_RaisesError()
    var
        ErroredBufferRecords: TestPage "BC14 Errored Buffer Records";
    begin
        // [SCENARIO] Opening Errored Buffer Records without filters raises an error explaining the requirement.
        ClearErrorOverview();

        // [WHEN] Page is opened with no filters
        asserterror ErroredBufferRecords.OpenView();

        // [THEN] The page reports that filters are required
        Assert.ExpectedError('must be opened with filters');
    end;

    [Test]
    procedure TestErroredBufferRecords_WithValidFilters_OpensSuccessfully()
    var
        DataMigrationError: Record "Data Migration Error";
        ErroredBufferRecords: TestPage "BC14 Errored Buffer Records";
    begin
        // [SCENARIO] Opening with filters on Source Table ID and Company Name succeeds.
        ClearErrorOverview();
        InsertErrorOverview(Database::"BC14 G/L Account");

        // [GIVEN] Filters scoped to BC14 G/L Account / current company
        DataMigrationError.SetRange("Source Table ID", Database::"BC14 G/L Account");
        DataMigrationError.SetRange("Company Name", CompanyName());

        // [WHEN] The page is opened via Page.Run with those filters
        ErroredBufferRecords.Trap();
        Page.Run(Page::"BC14 Errored Buffer Records", DataMigrationError);

        // [THEN] The page opens (no error). Trigger options default to false.
        Assert.AreEqual(false, ErroredBufferRecords.RunValidateField.AsBoolean(), 'RunValidate should default to false.');
        Assert.AreEqual(false, ErroredBufferRecords.RunModifyField.AsBoolean(), 'RunModify should default to false.');
        ErroredBufferRecords.Close();
    end;

    [Test]
    procedure TestErroredBufferRecords_FieldVisibility_LimitedByBufferFieldCount()
    var
        DataMigrationError: Record "Data Migration Error";
        MetaRef: RecordRef;
        FldRef: FieldRef;
        ErroredBufferRecords: TestPage "BC14 Errored Buffer Records";
        NormalFieldCount: Integer;
        i: Integer;
    begin
        // [SCENARIO] Matrix columns are visible only up to the number of normal fields in the source table.
        ClearErrorOverview();
        InsertErrorOverview(Database::"BC14 G/L Account");

        // [GIVEN] Count of non-system normal fields in the source buffer table
        MetaRef.Open(Database::"BC14 G/L Account");
        NormalFieldCount := 0;
        for i := 1 to MetaRef.FieldCount do begin
            FldRef := MetaRef.FieldIndex(i);
            if (FldRef.Class = FieldClass::Normal) and (CopyStr(FldRef.Name, 1, 7).ToLower() <> '$system') then
                NormalFieldCount += 1;
        end;
        MetaRef.Close();
        if NormalFieldCount > 50 then
            NormalFieldCount := 50;

        // [GIVEN] The buffer table has at least one column, but fewer than 50
        Assert.IsTrue(NormalFieldCount >= 1, 'BC14 G/L Account must expose at least one normal field for this test.');
        Assert.IsTrue(NormalFieldCount < 50, 'BC14 G/L Account is expected to have fewer than 50 normal fields for this test.');

        DataMigrationError.SetRange("Source Table ID", Database::"BC14 G/L Account");
        DataMigrationError.SetRange("Company Name", CompanyName());

        // [WHEN] The page is opened with valid filters
        ErroredBufferRecords.Trap();
        Page.Run(Page::"BC14 Errored Buffer Records", DataMigrationError);

        // [THEN] Column 1 is visible and column 50 (beyond field count) is hidden
        Assert.IsTrue(ErroredBufferRecords.Field1.Visible(), 'Field1 should be visible when source table has at least one field.');
        Assert.IsFalse(ErroredBufferRecords.Field50.Visible(), 'Field50 should be hidden when source table has fewer than 50 fields.');

        ErroredBufferRecords.Close();
    end;

    [Test]
    procedure TestErroredBufferRecords_TriggerOptionsEditable()
    var
        DataMigrationError: Record "Data Migration Error";
        ErroredBufferRecords: TestPage "BC14 Errored Buffer Records";
    begin
        // [SCENARIO] The trigger option fields RunValidate and RunModify are editable.
        ClearErrorOverview();
        InsertErrorOverview(Database::"BC14 G/L Account");
        DataMigrationError.SetRange("Source Table ID", Database::"BC14 G/L Account");
        DataMigrationError.SetRange("Company Name", CompanyName());

        // [WHEN] The page is opened
        ErroredBufferRecords.Trap();
        Page.Run(Page::"BC14 Errored Buffer Records", DataMigrationError);

        // [THEN] The trigger option fields are editable so the user can change them
        Assert.IsTrue(ErroredBufferRecords.RunValidateField.Editable(), 'RunValidate field should be editable.');
        Assert.IsTrue(ErroredBufferRecords.RunModifyField.Editable(), 'RunModify field should be editable.');

        ErroredBufferRecords.Close();
    end;

    // ============================================================
    // Cloud Migration Management Page Extension (from BC14MgmtPageExtTests.codeunit.al)
    // ============================================================

    local procedure EnableBC14Migration()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PermissionManager: Codeunit "Permission Manager";
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        PermissionManager.SetTestabilityIntelligentCloud(true);
        BC14TestHelperFunctions.CreateStandardSetupRecords();
    end;

    local procedure DisableBC14Migration()
    var
        IntelligentCloudSetup: Record "Intelligent Cloud Setup";
    begin
        if IntelligentCloudSetup.Get() then begin
            IntelligentCloudSetup."Product ID" := 'SomeOtherProduct';
            IntelligentCloudSetup.Modify();
        end;
    end;

    local procedure ClearHybridCompanyStatuses()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        HybridCompanyStatus.DeleteAll();
    end;

    local procedure InsertHybridCompanyStatus(CompanyNameValue: Text[50]; UpgradeStatus: Option)
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        HybridCompanyStatus.Init();
        HybridCompanyStatus.Name := CompanyNameValue;
        HybridCompanyStatus."Upgrade Status" := UpgradeStatus;
        HybridCompanyStatus.Insert();
    end;

    [Test]
    procedure TestPageExt_BC14Enabled_ActionsVisible()
    var
        CloudMigrationMgmt: TestPage "Cloud Migration Management";
    begin
        // [GIVEN] BC14 is configured as the active intelligent-cloud product
        EnableBC14Migration();
        ClearHybridCompanyStatuses();

        // [WHEN] The Cloud Migration Management page opens
        CloudMigrationMgmt.OpenView();

        // [THEN] BC14-specific action is enabled and the status field is visible
        Assert.IsTrue(CloudMigrationMgmt.BC14MigrationSettings.Enabled(), 'Migration Settings action should be enabled when BC14 is enabled');
        Assert.IsTrue(CloudMigrationMgmt.BC14CompanyUpgradeStatus.Visible(), 'Companies Upgrade status field should be visible when BC14 is enabled');

        CloudMigrationMgmt.Close();
    end;

    [Test]
    procedure TestPageExt_BC14Disabled_ActionsHidden()
    var
        CloudMigrationMgmt: TestPage "Cloud Migration Management";
    begin
        // [GIVEN] Intelligent Cloud is set up with a different product (not BC14)
        EnableBC14Migration();
        DisableBC14Migration();

        // [WHEN] The Cloud Migration Management page opens
        CloudMigrationMgmt.OpenView();

        // [THEN] BC14-specific action is disabled and the status field is hidden
        Assert.IsFalse(CloudMigrationMgmt.BC14MigrationSettings.Enabled(), 'Migration Settings action should be disabled when BC14 is not the active product');
        Assert.IsFalse(CloudMigrationMgmt.BC14CompanyUpgradeStatus.Visible(), 'Companies Upgrade status field should be hidden when BC14 is not the active product');

        CloudMigrationMgmt.Close();
    end;

    [Test]
    procedure TestPageExt_NoCompanies_StatusShowsNoCompanies()
    var
        CloudMigrationMgmt: TestPage "Cloud Migration Management";
    begin
        // [GIVEN] BC14 enabled, no Hybrid Company Status rows
        EnableBC14Migration();
        ClearHybridCompanyStatuses();

        // [WHEN] The page opens
        CloudMigrationMgmt.OpenView();

        // [THEN] BC14CompanyUpgradeStatus shows the "No companies" placeholder
        Assert.AreEqual('No companies', CloudMigrationMgmt.BC14CompanyUpgradeStatus.Value(), 'Status field should read "No companies" when no statuses exist');

        CloudMigrationMgmt.Close();
    end;

    [Test]
    procedure TestPageExt_MixedStatuses_StatusTextAggregates()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        CloudMigrationMgmt: TestPage "Cloud Migration Management";
        StatusText: Text;
    begin
        // [GIVEN] BC14 enabled and several companies with different upgrade statuses
        EnableBC14Migration();
        ClearHybridCompanyStatuses();
        InsertHybridCompanyStatus('CO_PENDING_1', HybridCompanyStatus."Upgrade Status"::Pending);
        InsertHybridCompanyStatus('CO_PENDING_2', HybridCompanyStatus."Upgrade Status"::Pending);
        InsertHybridCompanyStatus('CO_STARTED_1', HybridCompanyStatus."Upgrade Status"::Started);
        InsertHybridCompanyStatus('CO_DONE_1', HybridCompanyStatus."Upgrade Status"::Completed);
        InsertHybridCompanyStatus('CO_DONE_2', HybridCompanyStatus."Upgrade Status"::Completed);
        InsertHybridCompanyStatus('CO_DONE_3', HybridCompanyStatus."Upgrade Status"::Completed);
        InsertHybridCompanyStatus('CO_FAIL_1', HybridCompanyStatus."Upgrade Status"::Failed);

        // [WHEN] The page opens
        CloudMigrationMgmt.OpenView();

        // [THEN] The status text aggregates all four buckets with the correct counts
        StatusText := CloudMigrationMgmt.BC14CompanyUpgradeStatus.Value();
        Assert.IsTrue(StatusText.Contains('Pending: 2'), 'Status text should include "Pending: 2". Actual: ' + StatusText);
        Assert.IsTrue(StatusText.Contains('Started: 1'), 'Status text should include "Started: 1". Actual: ' + StatusText);
        Assert.IsTrue(StatusText.Contains('Completed: 3'), 'Status text should include "Completed: 3". Actual: ' + StatusText);
        Assert.IsTrue(StatusText.Contains('Failed: 1'), 'Status text should include "Failed: 1". Actual: ' + StatusText);

        CloudMigrationMgmt.Close();
    end;

    [Test]
    procedure TestPageExt_NoFailedCompanies_ErrorDetailsHidden()
    var
        CloudMigrationMgmt: TestPage "Cloud Migration Management";
    begin
        // [GIVEN] BC14 enabled, no failed companies / no UpgradeFailed summary
        EnableBC14Migration();
        ClearHybridCompanyStatuses();

        // [WHEN] The page opens
        CloudMigrationMgmt.OpenView();

        // [THEN] Upgrade Error Details field is not visible
        Assert.IsFalse(CloudMigrationMgmt.BC14UpgradeErrorDetails.Visible(), 'Upgrade Error Details should be hidden when there is no UpgradeFailed summary');

        CloudMigrationMgmt.Close();
    end;

    // ============================================================
    // Migration Configuration Page (from BC14MigConfigPageTests.codeunit.al)
    // ============================================================

    local procedure InitializeSettings(): Record BC14CompanyMigrationInfo
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanySettings.DeleteAll();
        BC14CompanySettings.Init();
        BC14CompanySettings.Name := CopyStr(CompanyName(), 1, MaxStrLen(BC14CompanySettings.Name));
        BC14CompanySettings.Insert();
        exit(BC14CompanySettings);
    end;

    [Test]
    procedure TestConfigPage_NotStarted_ModuleFieldsEditable()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        ConfigPage: TestPage "BC14 Company Migration Status";
    begin
        // [GIVEN] Migration has not started
        BC14CompanySettings := InitializeSettings();
        BC14CompanySettings."Data Migration Started" := false;
        BC14CompanySettings.Modify();

        // [WHEN] The configuration page opens
        ConfigPage.Trap();
        Page.Run(Page::"BC14 Company Migration Status", BC14CompanySettings);

        // [THEN] Module checkboxes are editable
        Assert.IsTrue(ConfigPage."Migrate GL Module".Editable(), 'Migrate GL Module should be editable when migration has not started');
        Assert.IsTrue(ConfigPage."Migrate Receivables Module".Editable(), 'Migrate Receivables Module should be editable when migration has not started');
        Assert.IsTrue(ConfigPage."Migrate Payables Module".Editable(), 'Migrate Payables Module should be editable when migration has not started');
        Assert.IsTrue(ConfigPage."Migrate Inventory Module".Editable(), 'Migrate Inventory Module should be editable when migration has not started');
        Assert.IsTrue(ConfigPage."Skip Posting Journal Batches".Editable(), 'Skip Posting Journal Batches should be editable when migration has not started');
        Assert.IsTrue(ConfigPage."Stop On First Transformation Error".Editable(), 'Stop On First Error should be editable when migration has not started');

        ConfigPage.Close();
    end;

    [Test]
    procedure TestConfigPage_DataMigrationStarted_ModuleFieldsLocked()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        ConfigPage: TestPage "BC14 Company Migration Status";
    begin
        // [GIVEN] Migration has been started
        BC14CompanySettings := InitializeSettings();
        BC14CompanySettings."Data Migration Started" := true;
        BC14CompanySettings."Data Migration Started At" := CurrentDateTime();
        BC14CompanySettings.Modify();

        // [WHEN] The configuration page opens
        ConfigPage.Trap();
        Page.Run(Page::"BC14 Company Migration Status", BC14CompanySettings);

        // [THEN] Module checkboxes are locked
        Assert.IsFalse(ConfigPage."Migrate GL Module".Editable(), 'Migrate GL Module should be locked after migration has started');
        Assert.IsFalse(ConfigPage."Migrate Receivables Module".Editable(), 'Migrate Receivables Module should be locked after migration has started');
        Assert.IsFalse(ConfigPage."Migrate Payables Module".Editable(), 'Migrate Payables Module should be locked after migration has started');
        Assert.IsFalse(ConfigPage."Migrate Inventory Module".Editable(), 'Migrate Inventory Module should be locked after migration has started');
        Assert.IsFalse(ConfigPage."Skip Posting Journal Batches".Editable(), 'Skip Posting Journal Batches should be locked after migration has started');

        ConfigPage.Close();
    end;

    [Test]
    procedure TestConfigPage_PhaseProgress_HiddenWhenNoMigratorsRegistered()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        ConfigPage: TestPage "BC14 Company Migration Status";
    begin
        // [GIVEN] No migrators registered for the current phase
        BC14CompanySettings := InitializeSettings();
        BC14CompanySettings."Phase Migrators Total" := 0;
        BC14CompanySettings.Modify();

        // [WHEN] The page opens
        ConfigPage.Trap();
        Page.Run(Page::"BC14 Company Migration Status", BC14CompanySettings);

        // [THEN] Phase progress field is hidden
        Assert.IsFalse(ConfigPage.PhaseProgress.Visible(), 'Phase Progress should be hidden when there are no migrators');

        ConfigPage.Close();
    end;

    [Test]
    procedure TestConfigPage_PhaseProgress_VisibleAndFormatted()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        ConfigPage: TestPage "BC14 Company Migration Status";
        ProgressText: Text;
    begin
        // [GIVEN] Phase has 10 migrators with 3 completed
        BC14CompanySettings := InitializeSettings();
        BC14CompanySettings."Phase Migrators Total" := 10;
        BC14CompanySettings."Phase Migrators Completed" := 3;
        BC14CompanySettings.Modify();

        // [WHEN] The page opens
        ConfigPage.Trap();
        Page.Run(Page::"BC14 Company Migration Status", BC14CompanySettings);

        // [THEN] Phase progress is visible and shows correct counts and percentage
        Assert.IsTrue(ConfigPage.PhaseProgress.Visible(), 'Phase Progress should be visible when there are migrators');
        ProgressText := ConfigPage.PhaseProgress.Value();
        Assert.IsTrue(ProgressText.Contains('3'), 'Phase progress should contain completed count 3. Actual: ' + ProgressText);
        Assert.IsTrue(ProgressText.Contains('10'), 'Phase progress should contain total count 10. Actual: ' + ProgressText);
        Assert.IsTrue(ProgressText.Contains('30'), 'Phase progress should contain percentage 30. Actual: ' + ProgressText);

        ConfigPage.Close();
    end;

    [Test]
    procedure TestConfigPage_PostingPending_ShowsPendingText()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        ConfigPage: TestPage "BC14 Company Migration Status";
    begin
        // [GIVEN] Posting has not completed yet
        BC14CompanySettings := InitializeSettings();
        BC14CompanySettings."Posting Completed" := false;
        BC14CompanySettings.Modify();

        // [WHEN] The page opens
        ConfigPage.Trap();
        Page.Run(Page::"BC14 Company Migration Status", BC14CompanySettings);

        // [THEN] Posting status text is "Pending"
        Assert.AreEqual('Pending', ConfigPage.PostingStatus.Value(), 'Posting Status should be Pending when posting has not completed');

        ConfigPage.Close();
    end;

    [Test]
    procedure TestConfigPage_PostingCompleted_ShowsCompletedText()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        ConfigPage: TestPage "BC14 Company Migration Status";
    begin
        // [GIVEN] Posting has completed
        BC14CompanySettings := InitializeSettings();
        BC14CompanySettings."Posting Completed" := true;
        BC14CompanySettings.Modify();

        // [WHEN] The page opens
        ConfigPage.Trap();
        Page.Run(Page::"BC14 Company Migration Status", BC14CompanySettings);

        // [THEN] Posting status text is "Completed"
        Assert.AreEqual('Completed', ConfigPage.PostingStatus.Value(), 'Posting Status should be Completed when posting has completed');

        ConfigPage.Close();
    end;

    [Test]
    procedure TestConfigPage_HistoricalCompleted_ShowsCompletedText()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        ConfigPage: TestPage "BC14 Company Migration Status";
    begin
        // [GIVEN] Historical migration has completed without failure
        BC14CompanySettings := InitializeSettings();
        BC14CompanySettings."Historical Completed" := true;
        BC14CompanySettings."Historical Failed" := false;
        BC14CompanySettings.Modify();

        // [WHEN] The page opens
        ConfigPage.Trap();
        Page.Run(Page::"BC14 Company Migration Status", BC14CompanySettings);

        // [THEN] Historical status text is "Completed"
        Assert.AreEqual('Completed', ConfigPage.HistoricalStatus.Value(), 'Historical Status should be Completed when historical has completed');

        ConfigPage.Close();
    end;

    [Test]
    procedure TestConfigPage_HistoricalFailed_ShowsFailureReason()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        ConfigPage: TestPage "BC14 Company Migration Status";
        StatusText: Text;
    begin
        // [GIVEN] Historical migration failed with a reason
        BC14CompanySettings := InitializeSettings();
        BC14CompanySettings."Historical Failed" := true;
        BC14CompanySettings."Historical Failure Reason" := 'Disk full';
        BC14CompanySettings.Modify();

        // [WHEN] The page opens
        ConfigPage.Trap();
        Page.Run(Page::"BC14 Company Migration Status", BC14CompanySettings);

        // [THEN] Historical status text includes the failure reason
        StatusText := ConfigPage.HistoricalStatus.Value();
        Assert.IsTrue(StatusText.Contains('Failed'), 'Historical Status should include "Failed". Actual: ' + StatusText);
        Assert.IsTrue(StatusText.Contains('Disk full'), 'Historical Status should include the failure reason. Actual: ' + StatusText);

        ConfigPage.Close();
    end;

    [Test]
    procedure TestConfigPage_HistoricalDispatched_ShowsRunningText()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        ConfigPage: TestPage "BC14 Company Migration Status";
    begin
        // [GIVEN] Historical migration has been dispatched but not yet completed
        BC14CompanySettings := InitializeSettings();
        BC14CompanySettings."Historical Dispatched" := true;
        BC14CompanySettings."Historical Completed" := false;
        BC14CompanySettings."Historical Failed" := false;
        BC14CompanySettings."Phase Migrators Total" := 0;
        BC14CompanySettings.Modify();

        // [WHEN] The page opens
        ConfigPage.Trap();
        Page.Run(Page::"BC14 Company Migration Status", BC14CompanySettings);

        // [THEN] Historical status text indicates "Running"
        Assert.IsTrue(ConfigPage.HistoricalStatus.Value().Contains('Running'), 'Historical Status should indicate Running when dispatched. Actual: ' + ConfigPage.HistoricalStatus.Value());

        ConfigPage.Close();
    end;

    // ============================================================
    // Migration Error Overview Page (from BC14MigErrorPageTests.codeunit.al)
    // ============================================================

    local procedure ClearErrors()
    var
        DataMigrationError: Record "Data Migration Error";
        HybridCompany: Record "Hybrid Company";
    begin
        // BC14 Migration Error Overview is a temp page that aggregates Data Migration Error
        // rows across every Hybrid Company. Stray HybridCompany rows (or errors stored in
        // foreign companies) from prior tests pull unrelated records into the page and make
        // tests act on the wrong row. Reset to a clean single-company state.
        HybridCompany.DeleteAll();
        DataMigrationError.DeleteAll();

        HybridCompany.Init();
        HybridCompany.Name := CopyStr(CompanyName(), 1, MaxStrLen(HybridCompany.Name));
        HybridCompany.Replicate := true;
        if not HybridCompany.Insert() then
            HybridCompany.Modify();
    end;

    local procedure InsertError(SourceTableId: Integer; SourceRecordKey: Text; Dismissed: Boolean): Record "Data Migration Error"
    var
        DataMigrationError: Record "Data Migration Error";
    begin
        DataMigrationError.Init();
        DataMigrationError."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(DataMigrationError."Company Name"));
        DataMigrationError."Source Table ID" := SourceTableId;
        DataMigrationError."Source Table Name" := 'BC14 G/L Account';
        DataMigrationError."Source Record Key" := CopyStr(SourceRecordKey, 1, MaxStrLen(DataMigrationError."Source Record Key"));
        DataMigrationError."Destination Table ID" := Database::"G/L Account";
        DataMigrationError."Migration Type" := 'G/L Account Migrator';
        DataMigrationError."Error Message" := 'Sample error';
        DataMigrationError."Error Dismissed" := Dismissed;
        DataMigrationError.Insert(true);
        exit(DataMigrationError);
    end;

    [Test]
    procedure TestErrorOverviewPage_ShowsAllErrors()
    var
        ErrorOverview: TestPage "BC14 Migration Error Overview";
        Found1: Boolean;
        Found2: Boolean;
    begin
        // [SCENARIO] All error records (including resolved ones) are shown on the page
        // once the "Show Resolved" toggle is enabled.
        ClearErrors();
        InsertError(Database::"BC14 G/L Account", 'No.=1200', false);
        InsertError(Database::"BC14 G/L Account", 'No.=1300', true);

        // [WHEN] The page is opened, only the unresolved error is shown
        ErrorOverview.OpenView();

        // [THEN] The resolved error is hidden by default
        Assert.IsTrue(ErrorOverview.First(), 'Page should have at least one row by default.');
        Assert.AreEqual('No.=1200', ErrorOverview."Source Record Key".Value(), 'Only the unresolved error should be visible by default.');
        Assert.IsFalse(ErrorOverview.Next(), 'Resolved error must be hidden until Show Resolved is toggled on.');

        // [THEN] Only "Show Resolved" is offered, so assistive tech can tell the filter is off
        Assert.IsTrue(ErrorOverview.ShowResolved.Visible(), 'Show Resolved should be visible while resolved errors are hidden.');
        Assert.IsFalse(ErrorOverview.HideResolved.Visible(), 'Hide Resolved should be hidden while resolved errors are hidden.');

        // [WHEN] Resolved errors are made visible
        ErrorOverview.ShowResolved.Invoke();

        // [THEN] The action set flips to "Hide Resolved" to reflect the new state
        Assert.IsFalse(ErrorOverview.ShowResolved.Visible(), 'Show Resolved should hide once resolved errors are shown.');
        Assert.IsTrue(ErrorOverview.HideResolved.Visible(), 'Hide Resolved should be visible once resolved errors are shown.');

        // [THEN] Both records appear in the repeater
        if ErrorOverview.First() then
            repeat
                if ErrorOverview."Source Record Key".Value() = 'No.=1200' then
                    Found1 := true;
                if ErrorOverview."Source Record Key".Value() = 'No.=1300' then
                    Found2 := true;
            until not ErrorOverview.Next();

        Assert.IsTrue(Found1, 'Error 1 should be visible on the page.');
        Assert.IsTrue(Found2, 'Error 2 should be visible on the page.');

        // [WHEN] Resolved errors are hidden again
        ErrorOverview.HideResolved.Invoke();

        // [THEN] The action set returns to "Show Resolved" and the resolved error drops off
        Assert.IsTrue(ErrorOverview.ShowResolved.Visible(), 'Show Resolved should be visible again after hiding resolved errors.');
        Assert.IsFalse(ErrorOverview.HideResolved.Visible(), 'Hide Resolved should be hidden again after hiding resolved errors.');
        Assert.IsTrue(ErrorOverview.First(), 'Unresolved error should remain after hiding resolved errors.');
        Assert.AreEqual('No.=1200', ErrorOverview."Source Record Key".Value(), 'Only the unresolved error should remain after Hide Resolved.');
        Assert.IsFalse(ErrorOverview.Next(), 'Resolved error must be hidden again after Hide Resolved.');

        ErrorOverview.Close();
    end;

    [Test]
    procedure TestErrorOverviewPage_IdentificationFieldsReadOnly()
    var
        ErrorOverview: TestPage "BC14 Migration Error Overview";
    begin
        // [SCENARIO] Identification/audit fields on the error overview are read-only.
        ClearErrors();
        InsertError(Database::"BC14 G/L Account", 'No.=1200', false);

        // [WHEN] The page is opened in edit mode (OpenView would mark every field
        // read-only at the test page level regardless of the page's Editable property)
        ErrorOverview.OpenEdit();
        ErrorOverview.First();

        // [THEN] Identification fields are read-only
        Assert.IsFalse(ErrorOverview."Source Record Key".Editable(), 'Source Record Key should be read-only.');
        Assert.IsFalse(ErrorOverview."Error Message".Editable(), 'Error Message should be read-only.');
        Assert.IsFalse(ErrorOverview."Error Dismissed".Editable(), 'Error Dismissed should be read-only on the list.');
        Assert.IsFalse(ErrorOverview."Retry Count".Editable(), 'Retry Count should be read-only.');

        ErrorOverview.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestErrorOverviewPage_EditSourceRecord_NoSourceTableId_ShowsMessage()
    var
        ErrorOverview: TestPage "BC14 Migration Error Overview";
    begin
        // [SCENARIO] EditSourceRecord on a record with no Source Table ID shows "record unavailable" message.
        ClearErrors();
        InsertError(0, 'No.=1200', false);
        LibraryVariableStorage.Clear();

        // [WHEN] The user invokes EditSourceRecord
        ErrorOverview.OpenView();
        ErrorOverview.First();
        ErrorOverview.EditSourceRecord.Invoke();

        // [THEN] A message about the record being unavailable is shown
        Assert.IsTrue(
            LibraryVariableStorage.DequeueText().Contains('cannot be opened'),
            'EditSourceRecord with no Source Table ID should show the unavailable message.');

        LibraryVariableStorage.AssertEmpty();
        ErrorOverview.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestErrorOverviewPage_EditSourceRecord_NoSourceRecordKey_ShowsBulkMessage()
    var
        ErrorOverview: TestPage "BC14 Migration Error Overview";
    begin
        // [SCENARIO] EditSourceRecord on a bulk error (empty Source Record Key) shows "no individual source record" message.
        ClearErrors();
        InsertError(Database::"BC14 G/L Account", '', false);
        LibraryVariableStorage.Clear();

        // [WHEN] The user invokes EditSourceRecord
        ErrorOverview.OpenView();
        ErrorOverview.First();
        ErrorOverview.EditSourceRecord.Invoke();

        // [THEN] The "bulk error" message is shown
        Assert.IsTrue(
            LibraryVariableStorage.DequeueText().Contains('bulk transfer'),
            'EditSourceRecord with empty source record key should show the bulk transfer message.');

        LibraryVariableStorage.AssertEmpty();
        ErrorOverview.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure TestErrorOverviewPage_ContinueMigration_AllDismissed_ShowsContinueConfirm()
    var
        ErrorOverview: TestPage "BC14 Migration Error Overview";
        ConfirmText: Text;
    begin
        // [SCENARIO] Continue migration on a company whose errors are all dismissed shows the
        // "Continue migration for company %1?" confirmation (the new behavior after the
        // error overview was collapsed into Data Migration Error).
        ClearErrors();
        InsertError(Database::"BC14 G/L Account", 'No.=1200', true);
        LibraryVariableStorage.Clear();

        // [WHEN] The user invokes Continue migration and declines the confirm
        ErrorOverview.OpenView();

        // [THEN] The dismissed error is hidden by default (no rows visible)
        Assert.IsFalse(ErrorOverview.First(), 'Resolved error must be hidden by default before Show Resolved is toggled.');

        // Toggle resolved errors visible so the only (dismissed) row becomes selectable
        // as the source for the action.
        ErrorOverview.ShowResolved.Invoke();
        ErrorOverview.First();
        ErrorOverview.ContinueMigration.Invoke();

        // [THEN] The continue-migration confirm is shown (no "unresolved errors" warning)
        ConfirmText := LibraryVariableStorage.DequeueText();
        Assert.IsTrue(
            ConfirmText.Contains('Continue migration for company'),
            'Continue migration should show continue-migration confirm. Actual: ' + ConfirmText);
        Assert.IsFalse(
            ConfirmText.Contains('unresolved errors'),
            'Continue migration with all dismissed errors must not show unresolved-errors warning. Actual: ' + ConfirmText);

        LibraryVariableStorage.AssertEmpty();
        ErrorOverview.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure TestErrorOverviewPage_ContinueMigration_WithUnresolved_ShowsUnresolvedWarning()
    var
        ErrorOverview: TestPage "BC14 Migration Error Overview";
        ConfirmText: Text;
    begin
        // [SCENARIO] Continue migration on a company with unresolved errors shows the
        // "%1 unresolved errors ... continue anyway?" warning confirm.
        ClearErrors();
        InsertError(Database::"BC14 G/L Account", 'No.=1200', false);
        LibraryVariableStorage.Clear();

        // [WHEN] The user invokes Continue migration and declines the confirm
        ErrorOverview.OpenView();
        ErrorOverview.First();
        ErrorOverview.ContinueMigration.Invoke();

        // [THEN] The unresolved-errors warning confirm is shown
        ConfirmText := LibraryVariableStorage.DequeueText();
        Assert.IsTrue(
            ConfirmText.Contains('unresolved errors'),
            'Continue migration with unresolved errors should show unresolved-errors warning. Actual: ' + ConfirmText);

        LibraryVariableStorage.AssertEmpty();
        ErrorOverview.Close();
    end;

    // ============================================================
    // Upgrade Settings Page (independent globals card 46864, mirrors GP Upgrade Settings)
    // ============================================================

    local procedure ClearSettings()
    var
        BC14GlobalMigrationSettings: Record "BC14 Global Migration Settings";
    begin
        BC14GlobalMigrationSettings.DeleteAll();
    end;

    [Test]
    procedure TestUpgradeSettings_OpenPage_InsertsDefaultRow()
    var
        BC14GlobalMigrationSettings: Record "BC14 Global Migration Settings";
        UpgradeSettings: TestPage "BC14 Upgrade Settings";
    begin
        // [SCENARIO] Opening the page auto-inserts the singleton settings row if missing.
        ClearSettings();
        Assert.IsFalse(BC14GlobalMigrationSettings.Get(), 'There should be no settings row to begin with.');

        // [WHEN] The page opens
        UpgradeSettings.OpenView();

        // [THEN] A settings row now exists
        Assert.IsTrue(BC14GlobalMigrationSettings.Get(), 'Opening the page should create the singleton settings row.');
        UpgradeSettings.Close();
    end;

    [Test]
    procedure TestUpgradeSettings_AuditFieldsReadOnly()
    var
        UpgradeSettings: TestPage "BC14 Upgrade Settings";
    begin
        // [SCENARIO] Read-only audit fields (Data Upgrade Started, Replication Completed) cannot be edited.
        ClearSettings();

        // [WHEN] The page opens
        UpgradeSettings.OpenEdit();

        // [THEN] Audit timestamps are read-only; settings fields are editable
        Assert.IsFalse(UpgradeSettings.DataUpgradeStarted.Editable(), 'Data Upgrade Started should be read-only.');
        Assert.IsFalse(UpgradeSettings.ReplicationCompleted.Editable(), 'Replication Completed should be read-only.');
        Assert.IsTrue(UpgradeSettings.OneStepUpgrade.Editable(), 'Run upgrade after replication should be editable.');
        Assert.IsTrue(UpgradeSettings.OneStepUpgradeDelay.Editable(), 'Upgrade delay should be editable.');
        Assert.IsTrue(UpgradeSettings.MaxCompanySetupWaitTime.Editable(), 'Max company setup wait time should be editable.');

        UpgradeSettings.Close();
    end;

    [Test]
    procedure TestUpgradeSettings_HistoricalCutoffDate_PersistsValue()
    var
        DefaultRow: Record BC14CompanyMigrationInfo;
        MigrationConfig: TestPage "BC14 Migration Configuration";
    begin
        // [SCENARIO] Setting the Historical Cutoff Date on the Migration Configuration card
        // persists the value to the template row (Name = '') of BC14CompanyMigrationInfo.
        ClearSettings();

        // [WHEN] The user enters a cutoff date and closes the page
        MigrationConfig.OpenEdit();
        MigrationConfig."Historical Cutoff Date".SetValue(20240101D);
        MigrationConfig.Close();

        // [THEN] The value is stored on the template row
        Assert.IsTrue(DefaultRow.Get(''), 'Template row must exist after page edit.');
        Assert.AreEqual(20240101D, DefaultRow."Historical Cutoff Date", 'Historical Cutoff Date should be persisted.');
    end;

    [Test]
    procedure TestUpgradeSettings_OneStepUpgrade_TogglePersists()
    var
        BC14GlobalMigrationSettings: Record "BC14 Global Migration Settings";
        UpgradeSettings: TestPage "BC14 Upgrade Settings";
    begin
        // [SCENARIO] Toggling "Run upgrade after replication" persists the new value.
        ClearSettings();

        // [WHEN] The user toggles the One Step Upgrade flag
        UpgradeSettings.OpenEdit();
        UpgradeSettings.OneStepUpgrade.SetValue(true);
        UpgradeSettings.Close();

        // [THEN] The flag is persisted
        Assert.IsTrue(BC14GlobalMigrationSettings.Get(), 'Settings row must exist after page edit.');
        Assert.IsTrue(BC14GlobalMigrationSettings."One Step Upgrade", 'One Step Upgrade should be true after setting it from the page.');
    end;

    local procedure ClearPerCompanyRows()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        HybridCompany: Record "Hybrid Company";
    begin
        BC14CompanySettings.DeleteAll();
        HybridCompany.DeleteAll();
    end;

    local procedure InsertHybridCompany(Name: Text[50])
    var
        HybridCompany: Record "Hybrid Company";
    begin
        HybridCompany.Init();
        HybridCompany.Name := Name;
        HybridCompany.Replicate := true;
        HybridCompany.Insert();
    end;

    [Test]
    procedure TestCompanySettings_OpenPage_SeedsRowForEveryHybridCompany()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        MigrationConfig: TestPage "BC14 Migration Configuration";
    begin
        // [SCENARIO] Opening the configuration card pre-seeds a per-company row for every Hybrid Company
        // (the embedded "BC14 Co. Migration Settings" ListPart relies on the parent's OnOpenPage).
        ClearSettings();
        ClearPerCompanyRows();
        InsertHybridCompany('BC14-CO-A');
        InsertHybridCompany('BC14-CO-B');

        // [WHEN] The configuration card opens
        MigrationConfig.OpenView();
        MigrationConfig.Close();

        // [THEN] One BC14CompanyMigrationInfo row exists per Hybrid Company
        Assert.IsTrue(BC14CompanySettings.Get('BC14-CO-A'), 'A row should be seeded for BC14-CO-A.');
        Assert.IsTrue(BC14CompanySettings.Get('BC14-CO-B'), 'A row should be seeded for BC14-CO-B.');
    end;

    [Test]
    procedure TestCompanySettings_PerCompanyRow_NotStarted_FieldsEditable()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        MigrationConfig: TestPage "BC14 Migration Configuration";
    begin
        // [SCENARIO] RowEditable is true when "Data Migration Started" = false on the embedded ListPart.
        ClearSettings();
        ClearPerCompanyRows();
        InsertHybridCompany('BC14-CO-A');

        MigrationConfig.OpenEdit();
        MigrationConfig.CompanyList.GotoKey('BC14-CO-A');

        // [THEN] Module toggles and Skip Posting are editable on this row
        Assert.IsTrue(MigrationConfig.CompanyList."Migrate GL Module".Editable(), 'GL should be editable when migration has not started.');
        Assert.IsTrue(MigrationConfig.CompanyList."Migrate Receivables Module".Editable(), 'Receivables should be editable when migration has not started.');
        Assert.IsTrue(MigrationConfig.CompanyList."Migrate Payables Module".Editable(), 'Payables should be editable when migration has not started.');
        Assert.IsTrue(MigrationConfig.CompanyList."Migrate Inventory Module".Editable(), 'Inventory should be editable when migration has not started.');
        Assert.IsTrue(MigrationConfig.CompanyList."Skip Posting Journal Batches".Editable(), 'Skip Posting should be editable when migration has not started.');
        Assert.IsTrue(MigrationConfig.CompanyList."Stop On First Error".Editable(), 'Stop On First Error should be editable when migration has not started.');
        Assert.IsFalse(MigrationConfig.CompanyList.Name.Editable(), 'Company name column is always read-only (drilldown only).');

        MigrationConfig.Close();

        // [SANITY] Make sure the row we navigated to actually exists.
        Assert.IsTrue(BC14CompanySettings.Get('BC14-CO-A'), 'Row should exist after page open.');
    end;

    [Test]
    procedure TestCompanySettings_PerCompanyRow_Started_FieldsLocked()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        MigrationConfig: TestPage "BC14 Migration Configuration";
    begin
        // [SCENARIO] Once "Data Migration Started" is true the row's per-module toggles are locked on the embedded ListPart.
        ClearSettings();
        ClearPerCompanyRows();
        InsertHybridCompany('BC14-CO-A');
        BC14CompanySettings.GetForCompany('BC14-CO-A');
        BC14CompanySettings."Data Migration Started" := true;
        BC14CompanySettings."Data Migration Started At" := CurrentDateTime();
        BC14CompanySettings.Modify();

        MigrationConfig.OpenEdit();
        MigrationConfig.CompanyList.GotoKey('BC14-CO-A');

        // [THEN] All per-row settings are locked
        Assert.IsFalse(MigrationConfig.CompanyList."Migrate GL Module".Editable(), 'GL should be locked after migration has started.');
        Assert.IsFalse(MigrationConfig.CompanyList."Migrate Receivables Module".Editable(), 'Receivables should be locked after migration has started.');
        Assert.IsFalse(MigrationConfig.CompanyList."Migrate Payables Module".Editable(), 'Payables should be locked after migration has started.');
        Assert.IsFalse(MigrationConfig.CompanyList."Migrate Inventory Module".Editable(), 'Inventory should be locked after migration has started.');
        Assert.IsFalse(MigrationConfig.CompanyList."Skip Posting Journal Batches".Editable(), 'Skip Posting should be locked after migration has started.');
        Assert.IsFalse(MigrationConfig.CompanyList."Stop On First Error".Editable(), 'Stop On First Error should be locked after migration has started.');

        MigrationConfig.Close();
    end;

    [Test]
    procedure TestCompanySettings_PerCompanyRow_EditPersists()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        MigrationConfig: TestPage "BC14 Migration Configuration";
    begin
        // [SCENARIO] Toggling a per-company module flag from the embedded repeater persists to the table row.
        ClearSettings();
        ClearPerCompanyRows();
        InsertHybridCompany('BC14-CO-A');

        MigrationConfig.OpenEdit();
        MigrationConfig.CompanyList.GotoKey('BC14-CO-A');
        MigrationConfig.CompanyList."Migrate GL Module".SetValue(false);
        MigrationConfig.CompanyList."Skip Posting Journal Batches".SetValue(true);
        MigrationConfig.Close();

        // [THEN] Underlying row reflects the new values
        Assert.IsTrue(BC14CompanySettings.Get('BC14-CO-A'), 'Per-company row should still exist.');
        Assert.IsFalse(BC14CompanySettings."Migrate GL Module", 'Migrate GL Module should be persisted as false.');
        Assert.IsTrue(BC14CompanySettings."Skip Posting Journal Batches", 'Skip Posting Journal Batches should be persisted as true.');
    end;

    // ============================================================
    // Shared Handlers
    // ============================================================

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := false;
    end;
}

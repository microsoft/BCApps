// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

#if not CLEAN30
using Microsoft.Bank.Reports;
#endif
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
#if not CLEAN30
using Microsoft.Purchases.Reports;
using Microsoft.Sales.Reports;
#endif
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.IO;
using System.Privacy;
using System.Reflection;
using System.Security.AccessControl;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Upgrade;
using System.Utilities;

codeunit 148014 "FR Financial Integration Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        PermissionsMock: Codeunit "Permissions Mock";
        Migration: Codeunit "Library - Reports FR";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
#if not CLEAN30
        FeatureState: Codeunit "Library - Reports FR";
#endif
#if not CLEAN30
        ScheduleCalls: Integer;
        StatementCalls: Integer;
        ExistingReportCalls: Dictionary of [Integer, Integer];
#endif
        StartedPermissionMock: Boolean;
#if not CLEAN30
        ReplacementNamesPageOpened: Boolean;
#endif

#if not CLEAN30
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DisabledFeatureRejectsNewMaintenance()
    var
        ScheduleMgt: Codeunit "FR Financial Schedule Mgt.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] The legacy-disabled state cannot edit a second independent schedule store.
        Initialize();

        // [GIVEN] Reports FR is disabled and legacy configuration remains authoritative.
        FeatureState.SetFeatureEnabled(false);

        // [WHEN] New maintenance is requested.
        asserterror ScheduleMgt.EnsureAvailable();

        // [THEN] The route explicitly requires feature activation.
        Assert.ExpectedError('Enable Reports FR');
        Assert.ExpectedErrorCode('Dialog');
    end;
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure EnabledFeatureRequiresMigration()
    var
        ScheduleMgt: Codeunit "FR Financial Schedule Mgt.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Activation cannot expose an unmigrated writable store.
        Initialize();

        // [GIVEN] Reports FR is enabled but migration has not completed.
        // [WHEN] The maintenance route checks its prerequisites.
        asserterror ScheduleMgt.EnsureAvailable();

        // [THEN] The user receives an explicit migration prerequisite.
        Assert.ExpectedError('Migrate the legacy French financial schedules');
        Assert.ExpectedErrorCode('Dialog');
    end;

#if not CLEAN30
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LegacyWritesAreBlockedAfterMigration()
    var
#pragma warning disable AL0432, AS0105
        LegacyName: Record "FR Acc. Schedule Name";
#pragma warning restore AL0432, AS0105
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] After migration only the replacement configuration can be maintained.
        Initialize();

        // [GIVEN] S has been copied from legacy BaseApp.
        LegacyName.Name := 'GUARD';
        LegacyName.Insert(false);
        Migration.Migrate();
        LegacyName.Description := 'Forbidden legacy change';

        // [WHEN] A compatibility consumer bypasses legacy table triggers.
        asserterror LegacyName.Modify(false);

        // [THEN] The table-event guard still prevents a second writable store.
        Assert.ExpectedError('legacy schedule tables are read-only');
        Assert.ExpectedErrorCode('Dialog');
    end;
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LocalReadCannotMaintainSchedules()
    var
        ScheduleName: Record "FR Financial Schedule Name";
        ScheduleLine: Record "FR Financial Schedule Line";
        CanReadNames: Boolean;
        CanReadLines: Boolean;
        CanWriteNames: Boolean;
        CanWriteLines: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] LOCAL READ grants read access without granting schedule maintenance.
        Initialize();

        // [GIVEN] First-release migration has completed.
        Migration.Migrate();

        // [WHEN] Permissions are lowered to the existing LOCAL READ role.
        BeginPermissionScenario();
        LibraryLowerPermissions.PushPermissionSetWithoutDefaults('LOCAL READ');
        LibraryLowerPermissions.AddO365Basic();
        CanReadNames := ScheduleName.ReadPermission();
        CanReadLines := ScheduleLine.ReadPermission();
        CanWriteNames := ScheduleName.WritePermission();
        CanWriteLines := ScheduleLine.WritePermission();
        EndPermissionScenario();

        // [THEN] Neither destination table has write permission.
        Assert.IsTrue(CanReadNames, 'The read role must read headers.');
        Assert.IsTrue(CanReadLines, 'The read role must read lines.');
        Assert.IsFalse(CanWriteNames, 'The read role must not write headers.');
        Assert.IsFalse(CanWriteLines, 'The read role must not write lines.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LocalRoleCanMaintainSchedules()
    var
        ScheduleName: Record "FR Financial Schedule Name";
        ScheduleLine: Record "FR Financial Schedule Line";
        CanWriteNames: Boolean;
        CanWriteLines: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] The existing LOCAL maintenance role includes both destination tables.
        Initialize();

        // [GIVEN] First-release migration has completed.
        Migration.Migrate();

        // [WHEN] Permissions are lowered to LOCAL.
        BeginPermissionScenario();
        LibraryLowerPermissions.SetLocal();
        LibraryLowerPermissions.AddO365Basic();
        CanWriteNames := ScheduleName.WritePermission();
        CanWriteLines := ScheduleLine.WritePermission();
        EndPermissionScenario();

        // [THEN] The maintenance role has write permission without migration codeunit elevation.
        Assert.IsTrue(CanWriteNames, 'LOCAL must maintain headers.');
        Assert.IsTrue(CanWriteLines, 'LOCAL must maintain lines.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StandaloneFinancialReadCanRunScheduleWithoutMaintenance()
    var
        ScheduleName: Record "FR Financial Schedule Name";
        ScheduleLine: Record "FR Financial Schedule Line";
        Schedule: Report "FR Financial Schedule";
        Data: Codeunit "Temp Blob";
        Output: OutStream;
        Input: InStream;
        CanWriteNames: Boolean;
        CanWriteLines: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] The standalone financial read role executes a migrated schedule without LOCAL grants.
        Initialize();

        // [GIVEN] A migrated schedule has a blank row which does not require financial-ledger permissions.
        Migration.Migrate();
        ScheduleName.Name := 'READ';
        ScheduleName.Insert(false);
        ScheduleLine."Schedule Name" := ScheduleName.Name;
        ScheduleLine."Line No." := 10000;
        ScheduleLine.Insert(false);
        ScheduleName.SetRecFilter();
        Schedule.SetTableView(ScheduleName);
        Data.CreateOutStream(Output);

        // [WHEN] The scoped read role and basic runtime access are assigned without Test Tables or LOCAL.
        BeginPermissionScenario();
        PermissionsMock.Set('Reports FR Fin. Read');
        LibraryLowerPermissions.AddO365Basic();
        CanWriteNames := ScheduleName.WritePermission();
        CanWriteLines := ScheduleLine.WritePermission();
        Schedule.SaveAs('', ReportFormat::Xml, Output);
        EndPermissionScenario();

        // [THEN] Compatibility context dataitems do not require LOCAL, and neither destination is writable.
        Assert.IsFalse(CanWriteNames, 'Standalone readers must not maintain headers.');
        Assert.IsFalse(CanWriteLines, 'Standalone readers must not maintain lines.');
        Data.CreateInStream(Input);
        LibraryReportDataset.LoadFromInStream(Input);
        LibraryReportDataset.AssertElementWithValueExists('FR_Acc__Schedule_Name_Name', 'READ');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FinancialEditRoleDoesNotGrantLedgerWrites()
    var
        CodeunitMetadata: Record "CodeUnit Metadata";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] The expanded financial maintain role grants schedule writes without direct or indirect ledger writes.
        Initialize();

        // [GIVEN] The installed financial application owns the maintenance role.
        CodeunitMetadata.Get(Codeunit::"FR Financial Schedule Mgt.");

        // [WHEN] Native expanded permissions resolve the role and its included sets.
        // [THEN] Both destination tables have full maintenance grants and the ledger has none.
        VerifyScheduleMaintenanceGrant(CodeunitMetadata."App ID", Database::"FR Financial Schedule Name");
        VerifyScheduleMaintenanceGrant(CodeunitMetadata."App ID", Database::"FR Financial Schedule Line");
        VerifyNoLedgerWriteGrant(CodeunitMetadata."App ID");
    end;

#if not CLEAN30
#pragma warning disable AL0432
    [Test]
    [HandlerFunctions('ScheduleReportHandler,StatementReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResidualReportsAreSubstitutedOnce()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Old residual report IDs route to the new reports without a substitution loop.
        Initialize();

        // [GIVEN] The existing Reports FR feature is enabled.
        // [WHEN] Reports are run through their old IDs and then directly.
        Report.Run(Report::"FR Account Schedule");
        Report.Run(Report::"G/L Account Statement");
        Report.Run(Report::"FR Financial Schedule");
        Report.Run(Report::"G/L Account Statement FR");

        // [THEN] Both residual reports map once and destination IDs remain unchanged.
        Assert.AreEqual(2, ScheduleCalls, 'Both schedule calls must reach the destination exactly once.');
        Assert.AreEqual(2, StatementCalls, 'Both statement calls must reach the destination exactly once.');
    end;

    [Test]
    [HandlerFunctions('CustomerDetailHandler,VendorTrialHandler,CustomerTrialHandler,VendorDetailHandler,GLTrialHandler,GLDetailHandler,BankTrialHandler,BankJournalHandler,CustomerJournalHandler,GLJournalHandler,VendorJournalHandler,JournalsHandler,BankDetailHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ExistingThirteenSubstitutionsRemainUnchanged()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Residual mappings do not alter the thirteen original mappings or introduce destination loops.
        Initialize();

        // [GIVEN] Reports FR is enabled on the existing owner baseline.
        // [WHEN] Every original ID and its destination is run through the native report entry point.
        VerifyExistingReportPair(Report::"Customer Detail Trial Balance", Report::"Cust. Detail Trial Balance");
        VerifyExistingReportPair(Report::"Vendor Trial Balance FR", Report::"Vendor Trial Balance");
        VerifyExistingReportPair(Report::"Customer Trial Balance FR", Report::"Customer Trial Balance");
        VerifyExistingReportPair(Report::"Vendor Detail Trial Balance FR", Report::"Vendor Detail Trial Balance");
        VerifyExistingReportPair(Report::"G/L Trial Balance", Report::"G/L Trial Balance FR");
        VerifyExistingReportPair(Report::"G/L Detail Trial Balance", Report::"G/L Detail Trial Balance FR");
        VerifyExistingReportPair(Report::"Bank Account Trial Balance", Report::"Bank Acc. Trial Balance");
        VerifyExistingReportPair(Report::"Bank Account Journal", Report::"Bank Account Journal FR");
        VerifyExistingReportPair(Report::"Customer Journal", Report::"Customer Journal FR");
        VerifyExistingReportPair(Report::"G/L Journal", Report::"G/L Journal FR");
        VerifyExistingReportPair(Report::"Vendor Journal", Report::"Vendor Journal FR");
        VerifyExistingReportPair(Report::Journals, Report::"Journals FR");
        VerifyExistingReportPair(Report::"Bank Acc. Detail Trial Balance", Report::"Bank Acc. Det. Trial Balance");

        // [THEN] All thirteen destinations were reached exactly twice.
        Assert.AreEqual(13, ExistingReportCalls.Count(), 'The original substitution set must remain complete.');
    end;
#pragma warning restore AL0432
#endif

#if not CLEAN30
#pragma warning disable AL0432, AS0105
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OldScheduleHeaderFilterDoesNotLeakToNextReport()
    var
        LegacyName: Record "FR Acc. Schedule Name";
        LegacyLine: Record "FR Acc. Schedule Line";
        ScheduleName: Record "FR Financial Schedule Name";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] A native legacy-header selection is preserved without contaminating a subsequent direct report.
        Initialize();

        // [GIVEN] S and the committed fixture have independent migrated definitions.
        LegacyName.Name := 'HEADER';
        LegacyName.Insert(false);
        LegacyLine."Schedule Name" := LegacyName.Name;
        LegacyLine."Line No." := 10000;
        LegacyLine.Insert(false);
        LegacyName.SetRecFilter();
        Migration.Migrate();

        // [WHEN] The old report ID is called with the legacy header record.
        LibraryReportDataset.RunReportAndLoad(10811, LegacyName, '');

        // [THEN] Only S is emitted and a subsequent direct call can select the other definition.
        LibraryReportDataset.AssertElementWithValueExists('FR_Acc__Schedule_Name_Name', 'HEADER');
        LibraryReportDataset.AssertElementWithValueNotExist('FR_Acc__Schedule_Name_Name', 'PERSISTENT');
        ScheduleName.SetRange(Name, 'PERSISTENT');
        LibraryReportDataset.RunReportAndLoad(Report::"FR Financial Schedule", ScheduleName, '');
        LibraryReportDataset.AssertElementWithValueExists('FR_Acc__Schedule_Name_Name', 'PERSISTENT');
        LibraryReportDataset.AssertElementWithValueNotExist('FR_Acc__Schedule_Name_Name', 'HEADER');
    end;
#pragma warning restore AL0432, AS0105
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SharedInitializationMigratesBeforeAvailability()
    var
        ScheduleMgt: Codeunit "FR Financial Schedule Mgt.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] The shared lifecycle initializes layout and data before the new route becomes available.
        Initialize();

        // [GIVEN] An unmigrated company uses the first-release coordinator.
        // [WHEN] Shared initialization completes twice.
        Migration.MigrateCompanyData();
        Migration.MigrateCompanyData();

        // [THEN] Availability requires no independent readiness switch and migration is idempotent.
        ScheduleMgt.EnsureAvailable();
        Assert.IsTrue(Migration.IsMigrated(), 'The shared coordinator must complete configuration migration.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [CommitBehavior(CommitBehavior::Ignore)]
    procedure CompanyInitializationCompletesEnabledFeature()
    var
#if not CLEAN30
        FeatureKey: Record "Feature Key";
        Status: Record "Feature Data Update Status";
#endif
        ScheduleName: Record "FR Financial Schedule Name";
        CompanyInitialize: Codeunit "Company-Initialize";
        ScheduleMgt: Codeunit "FR Financial Schedule Mgt.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] The native company-setup event completes migration and readiness before new maintenance.
        Initialize();

        // [GIVEN] The platform feature is enabled for a company whose migration has not run.
#if not CLEAN30
        FeatureKey.Get('FRReports');
        FeatureKey.Enabled := FeatureKey.Enabled::"All Users";
        FeatureKey.Modify(false);
#endif

        // [WHEN] Native company initialization raises the completed-setup lifecycle callback.
        CompanyInitialize.Run();

        // [THEN] The real subscriber migrated the company and completed its feature status without inventing defaults.
        ScheduleMgt.EnsureAvailable();
        Assert.IsTrue(Migration.IsMigrated(), 'Company initialization must complete migration.');
#if not CLEAN30
        Status.Get('FRReports', CompanyName());
        Assert.AreEqual(Status."Feature Status"::Complete, Status."Feature Status", 'A new enabled company must be ready.');
#endif
        Assert.IsFalse(ScheduleName.Get('DEFAULT'), 'Initialization must not overwrite user definitions with a default.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TrialBalanceDefaultIsSelected()
    var
        TenantSelection: Record "Tenant Report Layout Selection";
        LayoutsFR: Codeunit "Library - Reports FR";
        EmptyGuid: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] A fresh company uses the installed French extension layout.
        Initialize();

        // [GIVEN] No deliberate report 7 layout selection exists.
        TenantSelection.SetRange("Report ID", Report::"Trial Balance/Previous Year");
        TenantSelection.SetRange("Company Name", CompanyName());
        TenantSelection.DeleteAll();

        // [WHEN] The shared layout manager initializes the report.
        LayoutsFR.SetDefaultReportLayouts();

        // [THEN] The company default points to the exact extension layout.
        TenantSelection.Get(Report::"Trial Balance/Previous Year", CompanyName(), EmptyGuid);
        Assert.AreEqual('FRFinancialReporting', TenantSelection."Layout Name", 'The FR layout must be selected, not just deployed.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure CustomTrialBalanceChoiceAndBindingsSurvive()
    var
        CustomLayout: Record "Custom Report Layout";
        Selection: Record "Report Layout Selection";
        LayoutsFR: Codeunit "Library - Reports FR";
        Input: InStream;
        Document: XmlDocument;
        Nodes: XmlNodeList;
        Code: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] A deliberate custom RDLC remains selected and its ambiguous FR debit binding is migrated.
        Initialize();

        // [GIVEN] A custom copy of the legacy FR built-in report 7 layout is selected.
        Code := CreateLegacyCustomLayout(CustomLayout, Report::"Trial Balance/Previous Year");
        SetCustomSelection(Report::"Trial Balance/Previous Year", Code);

        // [WHEN] The shared manager updates bindings without replacing the customer choice.
        LayoutsFR.SetDefaultReportLayouts();

        // [THEN] The selected code is unchanged and its dataset uses the explicit FR movement column.
        Selection.Get(Report::"Trial Balance/Previous Year", CompanyName());
        Assert.AreEqual(Code, Selection."Custom Report Layout Code", 'A deliberate custom choice must remain selected.');
        CustomLayout.Get(Code);
        CustomLayout.CalcFields(Layout);
        CustomLayout.Layout.CreateInStream(Input);
        XmlDocument.ReadFrom(Input, Document);
        Document.SelectNodes('//*[local-name()="Field" and @Name="FRPeriodDebitAmount"]', Nodes);
        Assert.AreEqual(1, Nodes.Count(), 'The custom debit binding must use the FR column rather than the W1 net column.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ResidualCustomLayoutIsCopiedWithoutChangingLegacy()
    var
        LegacyLayout: Record "Custom Report Layout";
        DestinationLayout: Record "Custom Report Layout";
        LegacySelection: Record "Report Layout Selection";
        DestinationSelection: Record "Report Layout Selection";
        LayoutsFR: Codeunit "Library - Reports FR";
        Code: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] The statement replacement inherits a custom layout while unmigrated companies retain the legacy layout.
        Initialize();

        // [GIVEN] The legacy statement has a selected custom RDLC.
        Code := CreateLegacyCustomLayout(LegacyLayout, 10842);
        SetCustomSelection(10842, Code);

        // [WHEN] Replacement layouts and selections are prepared.
        LayoutsFR.SetDefaultReportLayouts();

        // [THEN] Old and new selections reference separate records without losing the customer's layout.
        LegacySelection.Get(10842, CompanyName());
        DestinationSelection.Get(Report::"G/L Account Statement FR", CompanyName());
        Assert.AreEqual(Code, LegacySelection."Custom Report Layout Code", 'The legacy choice must not change for other companies.');
        Assert.AreNotEqual(Code, DestinationSelection."Custom Report Layout Code", 'The replacement needs its own layout identity.');
        DestinationLayout.Get(DestinationSelection."Custom Report Layout Code");
        Assert.AreEqual(Report::"G/L Account Statement FR", DestinationLayout."Report ID", 'The copied layout must belong to the replacement.');
        Assert.IsTrue(LegacyLayout.Get(Code), 'The source layout must be retained.');
    end;

#if not CLEAN30
#pragma warning disable AL0432
    [Test]
    [HandlerFunctions('LegacyStatementParametersHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SavedStatementParametersAreCopied()
    var
        Source: Record "Object Options";
        Destination: Record "Object Options";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        LayoutsFR: Codeunit "Library - Reports FR";
        Data: Codeunit "Temp Blob";
        AccountRef: RecordRef;
        Output: OutStream;
        Input: InStream;
        Document: XmlDocument;
        Nodes: XmlNodeList;
        Parameters: Text;
        VisibleEntryNo: Integer;
        HiddenEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] Saved evaluation and status parameters survive replacement report IDs.
        Initialize();

        // [GIVEN] A saved legacy statement request includes a historical evaluation date.
#if not CLEAN30
        FeatureState.SetFeatureEnabled(false);
#endif
        Parameters := Report.RunRequestPage(10842);
#if not CLEAN30
        FeatureState.SetFeatureEnabled(true);
#endif
        Source."Object Type" := Source."Object Type"::Report;
        Source."Object ID" := 10842;
        Source."Parameter Name" := '653672 saved request';
        Source."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(Source."Company Name"));
        Source."Option Data".CreateOutStream(Output, TextEncoding::UTF8);
        Output.WriteText(Parameters);
        Source.Insert(false);

        // [WHEN] The shared manager prepares the replacement.
        LayoutsFR.SetDefaultReportLayouts();

        // [THEN] The new setting retains the old request fields and the old setting remains available.
        Destination.Get(Source."Parameter Name", 10855, Source."Object Type", Source."User Name", Source."Company Name");
        Destination.CalcFields("Option Data");
        Destination."Option Data".CreateInStream(Input, TextEncoding::UTF8);
        XmlDocument.ReadFrom(Input, Document);
        Document.SelectNodes('/ReportParameters[@id="10855"]/Options/Field[@name="EvaluationDate" and text()="2026-01-31"]', Nodes);
        Assert.AreEqual(1, Nodes.Count(), 'Saved request controls and dates must be retained.');
        Assert.IsTrue(Source.Get(Source."Parameter Name", 10842, Source."Object Type", Source."User Name", Source."Company Name"), 'The legacy saved request must be retained.');

        // [GIVEN] A has an applied entry on the evaluation boundary and a future entry.
        Migration.Migrate();
        LibraryERM.CreateGLAccount(GLAccount);
        VisibleEntryNo := CreateSecurityEntry(GLAccount."No.", 100);
        GLEntry.Get(VisibleEntryNo);
        GLEntry.Letter := 'ABC';
        GLEntry."Letter Date" := 20260131D;
        GLEntry.Modify(false);
        HiddenEntryNo := CreateSecurityEntry(GLAccount."No.", 900);
        GLEntry.Get(HiddenEntryNo);
        GLEntry."Posting Date" := 20260201D;
        GLEntry.Modify(false);
        GLAccount.SetRecFilter();
        AccountRef.GetTable(GLAccount);
        Document.WriteTo(Parameters);
        Data.CreateOutStream(Output);

        // [WHEN] The migrated saved XML is executed, rather than merely inspected.
        Report.SaveAs(10855, Parameters, ReportFormat::Xml, Output, AccountRef);
        Data.CreateInStream(Input);
        XmlDocument.ReadFrom(Input, Document);

        // [THEN] The retained controls enforce actual entry inclusion and exclusion.
        Document.SelectNodes('//*[@name="EntryNo_GLEntry" and text()="' + Format(VisibleEntryNo, 0, 9) + '"]', Nodes);
        Assert.AreEqual(1, Nodes.Count(), 'The saved Applied selection must include the boundary entry.');
        Document.SelectNodes('//*[@name="EntryNo_GLEntry" and text()="' + Format(HiddenEntryNo, 0, 9) + '"]', Nodes);
        Assert.AreEqual(0, Nodes.Count(), 'The saved evaluation date must exclude the future entry.');
    end;
#pragma warning restore AL0432
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FinancialTablesAreClassifiedNormal()
    var
        Sensitivity: Record "Data Sensitivity";
        ScheduleMgt: Codeunit "FR Financial Schedule Mgt.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] The moved customer-content fields retain Normal sensitivity.
        Initialize();

        // [GIVEN] The replacement tables are installed.
        // [WHEN] The scoped classification initializer runs.
        ScheduleMgt.ClassifyFinancialSchedules();

        // [THEN] The schedule identity and dimension reference are classified.
        Sensitivity.Get(CompanyName(), Database::"FR Financial Schedule Name", 1);
        Assert.AreEqual(Sensitivity."Data Sensitivity"::Normal, Sensitivity."Data Sensitivity", 'Header classification must be initialized.');
        Sensitivity.Get(CompanyName(), Database::"FR Financial Schedule Line", 480);
        Assert.AreEqual(Sensitivity."Data Sensitivity"::Normal, Sensitivity."Data Sensitivity", 'Dimension identity classification must be initialized.');
    end;

#if not CLEAN30
#pragma warning disable AL0432
    [Test]
    [HandlerFunctions('ForwardedScheduleNamesHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure LegacyNamesPageOpenViewRunsForwarding()
    var
        LegacyNames: TestPage "FR Account Schedule Names";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] The supported TestPage lifecycle executes the legacy page publisher and opens the replacement.
        InitializeNavigation();

        // [GIVEN] The dedicated company has committed, migrated schedule definitions.
        Clear(ReplacementNamesPageOpened);

        // [WHEN] The real legacy page is opened through its native test-page lifecycle.
        LegacyNames.OpenView();

        // [THEN] The publisher and replacement handler both execute.
#if not CLEAN30
        Assert.IsTrue(FeatureState.GetLegacyNamesPageOpened(), 'The native page lifecycle must execute the forwarding publisher.');
#endif
        Assert.IsTrue(ReplacementNamesPageOpened, 'The replacement maintenance page must open.');
    end;
#pragma warning restore AL0432
#endif

    [Test]
    [HandlerFunctions('PrintScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MaintenancePrintActionRunsSelectedSchedule()
    var
        ScheduleName: Record "FR Financial Schedule Name";
        SchedulePage: TestPage "FR Financial Schedule";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] The actual worksheet Print action runs only its selected schedule.
        InitializeNavigation();

        // [GIVEN] S has a maintained row and another migrated schedule exists.
        ScheduleName.Get('PRINT');
        SchedulePage.OpenView();
        SchedulePage.CurrentSchedName.SetValue(ScheduleName.Name);

        // [WHEN] The worksheet Print action executes the report request.
        SchedulePage.Print.Invoke();
        SchedulePage.Close();
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] The actual report dataset contains only the selected definition.
        LibraryReportDataset.AssertElementWithValueExists('FR_Acc__Schedule_Name_Name', 'PRINT');
        LibraryReportDataset.AssertElementWithValueNotExist('FR_Acc__Schedule_Name_Name', 'PERSISTENT');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MigratedCustomTrialLayoutActuallyRenders()
    var
        GLAccount: Record "G/L Account";
        CustomLayout: Record "Custom Report Layout";
        TempCells: Record "Excel Buffer" temporary;
        TrialBalance: Report "Trial Balance/Previous Year";
        LayoutsFR: Codeunit "Library - Reports FR";
        Data: Codeunit "Temp Blob";
        Output: OutStream;
        Code: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] A migrated customer RDLC renders the gross movement contract, not just valid binding XML.
        Initialize();

        // [GIVEN] A deliberate legacy custom layout is selected and A has mixed movements.
        Code := CreateLegacyCustomLayout(CustomLayout, Report::"Trial Balance/Previous Year");
        SetCustomSelection(Report::"Trial Balance/Previous Year", Code);
        LayoutsFR.SetDefaultReportLayouts();
        Migration.Migrate();
        LibraryERM.CreateGLAccount(GLAccount);
        CreateSecurityEntry(GLAccount."No.", 100);
        CreateSecurityEntry(GLAccount."No.", -40);
        GLAccount.SetRecFilter();
        GLAccount.SetRange("Date Filter", 20260101D, 20260131D);
        TrialBalance.SetTableView(GLAccount);
        Data.CreateOutStream(Output);

        // [WHEN] Report 7 executes the migrated customer layout.
        TrialBalance.SaveAs('', ReportFormat::Excel, Output);
        ReadRenderedExcel(Data, TempCells);

        // [THEN] Gross debit and credit remain separate in the actual workbook.
        VerifyRenderedNumber(TempCells, 100);
        VerifyRenderedNumber(TempCells, 40);
        SaveArtifact('653672-CustomTrialBalance.xlsx', Data);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure UnsupportedCustomLayoutRequiresRemediation()
    var
        CustomLayout: Record "Custom Report Layout";
        LayoutsFR: Codeunit "Library - Reports FR";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] An unsupported customer layout blocks activation with explicit remediation instead of silent replacement.
        Initialize();

        // [GIVEN] The legacy statement has a customer Word layout.
        CustomLayout.Code := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(CustomLayout.Code));
        CustomLayout."Report ID" := 10842;
        CustomLayout."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(CustomLayout."Company Name"));
        CustomLayout.Type := CustomLayout.Type::Word;
        CustomLayout.Insert(false);

        // [WHEN] Shared lifecycle prepares the replacement layouts.
        asserterror LayoutsFR.SetDefaultReportLayouts();

        // [THEN] Activation cannot silently discard unsupported customizations.
        Assert.ExpectedError('custom layout that cannot be migrated automatically');
        Assert.ExpectedErrorCode('Dialog');
        Assert.IsFalse(Migration.IsMigrated(), 'Layout prerequisites must precede migration completion.');
    end;

#if not CLEAN30
#pragma warning disable AL0432
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OldScheduleIDPreservesLineAndDateFilters()
    var
        LegacyName: Record "FR Acc. Schedule Name";
        LegacyLine: Record "FR Acc. Schedule Line";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        Data: Codeunit "Temp Blob";
        SourceRef: RecordRef;
        Output: OutStream;
        Input: InStream;
        Document: XmlDocument;
        Diagnostic: Text;
        Node: XmlNode;
        Amount: Decimal;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] An old-ID call with a legacy line record preserves schedule and date context in the replacement dataset.
        Initialize();

        // [GIVEN] S has a legacy row selecting current +60 and an excluded previous-year +900.
        LibraryERM.CreateGLAccount(GLAccount);
        CreateSecurityEntry(GLAccount."No.", 60);
        GLEntry.Get(CreateSecurityEntry(GLAccount."No.", 900));
        GLEntry."Posting Date" := 20250115D;
        GLEntry.Modify(false);
        LegacyName.Name := 'FILTER';
        LegacyName."Caption Column 1" := 'Current';
        LegacyName.Insert(false);
        LegacyLine."Schedule Name" := LegacyName.Name;
        LegacyLine."Line No." := 10000;
        LegacyLine.Totaling := GLAccount."No.";
        LegacyLine.Insert(false);
        LegacyLine.SetRange("Schedule Name", LegacyName.Name);
        LegacyLine.SetRange("Date Filter", 20260101D, 20260131D);
        Migration.Migrate();

        // [WHEN] The original report ID is executed with the old line-table record.
        SourceRef.GetTable(LegacyLine);
        Data.CreateOutStream(Output);
        Report.SaveAs(10811, '', ReportFormat::Xml, Output, SourceRef);
        Data.CreateInStream(Input);
        XmlDocument.ReadFrom(Input, Document);
        Assert.IsTrue(Document.SelectSingleNode('//*[@name="AccSchedLineFilter"]', Node), 'The report must describe its execution context.');
        Diagnostic := Node.AsXmlElement().InnerText();
        Data.CreateInStream(Input);
        LibraryReportDataset.LoadFromInStream(Input);

        // [THEN] The replacement receives exactly the requested schedule and filtered accounting total.
#if not CLEAN30
        Assert.AreEqual(LegacyLine.GetFilter("Date Filter"), FeatureState.GetLegacyReportDateFilter(), 'The platform publisher must deliver the original execution filter.');
#endif
        LibraryReportDataset.AssertElementWithValueExists('FR_Acc__Schedule_Name_Name', LegacyName.Name);
        Assert.IsTrue(Document.SelectSingleNode('//*[@name="Sign_TotalCurrentYear"]', Node), 'The replacement must emit its total.');
        Evaluate(Amount, Node.AsXmlElement().InnerText(), 9);
        Assert.AreEqual(60, Amount, 'The old-ID call must retain execution context. Dataset: ' + Diagnostic);
        LibraryReportDataset.AssertElementWithValueNotExist('FR_Acc__Schedule_Name_Name', 'PERSISTENT');
    end;
#pragma warning restore AL0432
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure FrenchStatementRendersTranslatedHeading()
    var
        GLAccount: Record "G/L Account";
        TempCells: Record "Excel Buffer" temporary;
        Statement: Report "G/L Account Statement FR";
        Data: Codeunit "Temp Blob";
        Output: OutStream;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653672] French language output is proved through the rendered workbook rather than source translations.
        Initialize();

        // [GIVEN] A contains an entry and the session language is French.
        Migration.Migrate();
        LibraryERM.CreateGLAccount(GLAccount);
        CreateSecurityEntry(GLAccount."No.", 100);
        GLAccount.SetRecFilter();
        Statement.SetTableView(GLAccount);
        Statement.SetOptions(0, 0, 20260131D);
        Statement.Language(1036);
        Data.CreateOutStream(Output);

        // [WHEN] The selected statement layout is rendered.
        Statement.SaveAs('', ReportFormat::Excel, Output);
        ReadRenderedExcel(Data, TempCells);

        // [THEN] The output contains the delivered French heading.
        VerifyRenderedText(TempCells, 'Justification du solde comptable');
        SaveArtifact('653672-Statement-French.xlsx', Data);
    end;

    local procedure Initialize()
    begin
        Clear(LibraryReportDataset);
        LibraryLowerPermissions.SetOutsideO365Scope();
#if not CLEAN30
        ScheduleCalls := 0;
        StatementCalls := 0;
        Clear(ExistingReportCalls);
#endif
        if Migration.IsMigrated() then
            UpgradeTagLibrary.DeleteUpgradeTag(Migration.GetUpgradeTag(), CopyStr(CompanyName(), 1, 30));
#if not CLEAN30
        Clear(FeatureState);
        FeatureState.SetFeatureEnabled(true);
        BindSubscription(FeatureState);
#endif
    end;

#if not CLEAN30
    local procedure VerifyExistingReportPair(SourceReportID: Integer; DestinationReportID: Integer)
    begin
        Report.Run(SourceReportID);
        Report.Run(DestinationReportID);
        Assert.AreEqual(2, ExistingReportCalls.Get(DestinationReportID), 'Old-ID and direct calls must each reach the original destination once.');
    end;

    local procedure ObserveExistingReport(ReportID: Integer)
    var
        Calls: Integer;
    begin
        if not ExistingReportCalls.Get(ReportID, Calls) then
            Calls := 0;
        ExistingReportCalls.Set(ReportID, Calls + 1);
    end;

#endif

    local procedure InitializeNavigation()
    begin
        if CompanyName() <> '653672 Migration Target' then
            Error('Navigation tests require the committed fixture in 653672 Migration Target; run PrepareNavigationFixture there first.');
        Clear(LibraryReportDataset);
#if not CLEAN30
        Clear(FeatureState);
        FeatureState.SetFeatureEnabled(true);
        BindSubscription(FeatureState);
#endif
        Assert.IsTrue(Migration.IsMigrated(), 'The navigation company must be committed and migrated before opening modal pages.');
    end;

    local procedure BeginPermissionScenario()
    begin
        StartedPermissionMock := not PermissionsMock.IsStarted();
        if StartedPermissionMock then
            PermissionsMock.Start();
    end;

    local procedure EndPermissionScenario()
    begin
        if StartedPermissionMock then
            PermissionsMock.Stop()
        else
            LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    local procedure VerifyScheduleMaintenanceGrant(AppID: Guid; TableID: Integer)
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        Assert.IsTrue(
            ExpandedPermission.Get(AppID, 'Reports FR Fin. Edit', ExpandedPermission."Object Type"::"Table Data", TableID),
            'The expanded financial role must contain the schedule table grant.');
        Assert.AreEqual(ExpandedPermission."Read Permission"::Yes, ExpandedPermission."Read Permission", 'Schedule read permission must be direct.');
        Assert.AreEqual(ExpandedPermission."Insert Permission"::Yes, ExpandedPermission."Insert Permission", 'Schedule insert permission must be direct.');
        Assert.AreEqual(ExpandedPermission."Modify Permission"::Yes, ExpandedPermission."Modify Permission", 'Schedule modify permission must be direct.');
        Assert.AreEqual(ExpandedPermission."Delete Permission"::Yes, ExpandedPermission."Delete Permission", 'Schedule delete permission must be direct.');
    end;

    local procedure VerifyNoLedgerWriteGrant(AppID: Guid)
    var
        ExpandedPermission: Record "Expanded Permission";
    begin
        Assert.IsTrue(
            ExpandedPermission.Get(AppID, 'Reports FR Fin. Edit', ExpandedPermission."Object Type"::Page, Page::"FR Financial Schedule Names"),
            'Expanded permissions must resolve the page grant inherited from the financial read role.');
        Assert.AreEqual(ExpandedPermission."Execute Permission"::Yes, ExpandedPermission."Execute Permission", 'The inherited page execution grant must remain available.');
        ExpandedPermission.SetRange("App ID", AppID);
        ExpandedPermission.SetRange("Role ID", 'Reports FR Fin. Edit');
        ExpandedPermission.SetRange("Object Type", ExpandedPermission."Object Type"::"Table Data");
        ExpandedPermission.SetFilter("Object ID", '%1|%2', 0, Database::"G/L Entry");
        ExpandedPermission.SetFilter("Insert Permission", '<>%1', ExpandedPermission."Insert Permission"::" ");
        Assert.IsTrue(ExpandedPermission.IsEmpty(), 'The financial role must not grant direct or indirect ledger insertion, including wildcard grants.');
        ExpandedPermission.SetRange("Insert Permission");
        ExpandedPermission.SetFilter("Modify Permission", '<>%1', ExpandedPermission."Modify Permission"::" ");
        Assert.IsTrue(ExpandedPermission.IsEmpty(), 'The financial role must not grant direct or indirect ledger modification, including wildcard grants.');
        ExpandedPermission.SetRange("Modify Permission");
        ExpandedPermission.SetFilter("Delete Permission", '<>%1', ExpandedPermission."Delete Permission"::" ");
        Assert.IsTrue(ExpandedPermission.IsEmpty(), 'The financial role must not grant direct or indirect ledger deletion, including wildcard grants.');
    end;

    local procedure CreateLegacyCustomLayout(var CustomLayout: Record "Custom Report Layout"; ReportID: Integer): Code[20]
    var
        LayoutList: Record "Report Layout List";
        Data: Codeunit "Temp Blob";
        Output: OutStream;
    begin
        LayoutList.SetRange("Report ID", ReportID);
        LayoutList.SetRange("Application ID", '{437dbf0e-84ff-417a-965d-ed2bb9650972}');
        LayoutList.SetRange("Layout Format", LayoutList."Layout Format"::RDLC);
        LayoutList.FindFirst();
        Data.CreateOutStream(Output);
        LayoutList.Layout.ExportStream(Output);
        CustomLayout.Code := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(CustomLayout.Code));
        CustomLayout."Report ID" := ReportID;
        CustomLayout."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(CustomLayout."Company Name"));
        CustomLayout.Type := CustomLayout.Type::RDLC;
        CustomLayout.Insert(true);
        CustomLayout.SetLayoutBlob(Data);
        exit(CustomLayout.Code);
    end;

    local procedure SetCustomSelection(ReportID: Integer; Code: Code[20])
    var
        Selection: Record "Report Layout Selection";
    begin
        if not Selection.Get(ReportID, CompanyName()) then begin
            Selection."Report ID" := ReportID;
            Selection."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(Selection."Company Name"));
            Selection.Insert(false);
        end;
        Selection.Type := Selection.Type::"Custom Layout";
        Selection."Custom Report Layout Code" := Code;
        Selection.Modify(false);
    end;

    local procedure CreateSecurityEntry(AccountNo: Code[20]; Amount: Decimal): Integer
    var
        GLEntry: Record "G/L Entry";
        EntryNo: Integer;
    begin
        if GLEntry.FindLast() then
            EntryNo := GLEntry."Entry No." + 1
        else
            EntryNo := 1;
        GLEntry.Init();
        GLEntry."Entry No." := EntryNo;
        GLEntry."G/L Account No." := AccountNo;
        GLEntry."Posting Date" := 20260115D;
        GLEntry.Amount := Amount;
        if Amount >= 0 then
            GLEntry."Debit Amount" := Amount
        else
            GLEntry."Credit Amount" := -Amount;
        GLEntry.Insert(false);
        exit(EntryNo);
    end;

    procedure PrepareNavigationFixture()
    var
        ScheduleName: Record "FR Financial Schedule Name";
        ScheduleLine: Record "FR Financial Schedule Line";
#if not CLEAN30
#pragma warning disable AL0432, AS0105
        LegacyName: Record "FR Acc. Schedule Name";
#pragma warning restore AL0432, AS0105
#endif
        Names: List of [Code[10]];
        Name: Code[10];
    begin
        if CompanyName() <> '653672 Migration Target' then
            Error('Navigation setup is restricted to the dedicated migration target company.');
        Migration.Migrate();
        Names.AddRange('UIROUTE', 'PRINT', 'PERSISTENT');
        foreach Name in Names do begin
            if not ScheduleName.Get(Name) then begin
                ScheduleName.Init();
                ScheduleName.Name := Name;
                ScheduleName.Insert(false);
            end;
            if not ScheduleLine.Get(Name, 10000) then begin
                ScheduleLine.Init();
                ScheduleLine."Schedule Name" := Name;
                ScheduleLine."Line No." := 10000;
                ScheduleLine.Insert(false);
            end;
        end;
#if not CLEAN30
        if not LegacyName.Get('UIROUTE') then begin
            UpgradeTagLibrary.DeleteUpgradeTag(Migration.GetUpgradeTag(), CopyStr(CompanyName(), 1, 30));
            ScheduleName.Get('UIROUTE');
            LegacyName.TransferFields(ScheduleName);
            LegacyName.SystemId := ScheduleName.SystemId;
            LegacyName.Insert(false, true);
            Migration.Migrate();
        end;
#endif
    end;

    procedure EnableArtifactCapture()
    begin
        if not CompanyName().StartsWith('653672 ') then
            Error('Artifact capture is restricted to the dedicated migration fixture companies.');
        IsolatedStorage.Set('653672-CaptureArtifacts', 'true', DataScope::Company);
    end;

    procedure SaveArtifact(FileName: Text; var Data: Codeunit "Temp Blob")
    var
        FileManagement: Codeunit "File Management";
        Artifact: File;
        Input: InStream;
        Output: OutStream;
        Directory: Text;
    begin
        if not IsolatedStorage.Contains('653672-CaptureArtifacts', DataScope::Company) then
            exit;
        if not FileName.StartsWith('653672-') or FileName.Contains('\') or FileName.Contains('/') or FileName.Contains('..') then
            Error('The artifact name must be a task-specific file name without a directory.');
        Directory := FileManagement.GetDirectoryName(FileManagement.ServerTempFileName('tmp'));
        Artifact.Create(Directory + '\' + FileName);
        Artifact.CreateOutStream(Output);
        Data.CreateInStream(Input);
        CopyStream(Output, Input);
        Artifact.Close();
        IsolatedStorage.Set('653672-Path-' + FileName, Directory + '\' + FileName, DataScope::Company);
    end;

    procedure GetArtifactLocation(FileName: Text): Text
    var
        Location: Text;
    begin
        if not IsolatedStorage.Get('653672-Path-' + FileName, DataScope::Company, Location) then
            Error('The requested test artifact has not been captured.');
        exit(Location);
    end;

    procedure GetNativeArtifactDirectory(): Text
    var
        FileManagement: Codeunit "File Management";
    begin
        exit(FileManagement.GetDirectoryName(FileManagement.ServerTempFileName('tmp')));
    end;

    procedure ReadRenderedExcel(var Data: Codeunit "Temp Blob"; var TempCells: Record "Excel Buffer" temporary): Integer
    var
        TempSheets: Record "Name/Value Buffer" temporary;
        Input: InStream;
        OpenError: Text;
        SheetCount: Integer;
    begin
        Data.CreateInStream(Input);
        Assert.IsTrue(TempCells.GetSheetsNameListFromStream(Input, TempSheets), 'The rendered workbook must contain a worksheet.');
        SheetCount := TempSheets.Count();
        TempSheets.FindFirst();
        Data.CreateInStream(Input);
        OpenError := TempCells.OpenBookStream(Input, TempSheets.Value);
        Assert.AreEqual('', OpenError, 'The rendered workbook must open successfully.');
        TempCells.ReadSheet();
        exit(SheetCount);
    end;

    procedure VerifyRenderedText(var TempCells: Record "Excel Buffer" temporary; Expected: Text)
    var
        RenderedText: Text;
    begin
        TempCells.Reset();
        if TempCells.FindSet() then
            repeat
                RenderedText += TempCells."Cell Value as Text" + ' | ';
            until (TempCells.Next() = 0) or (StrLen(RenderedText) > 1500);
        TempCells.SetRange("Cell Value as Text", Expected);
        Assert.IsFalse(TempCells.IsEmpty(), 'The expected caption must be present in the rendered workbook: ' + Expected + '. Found: ' + RenderedText);
        TempCells.Reset();
    end;

    procedure VerifyRenderedNumber(var TempCells: Record "Excel Buffer" temporary; Expected: Decimal)
    var
        Value: Decimal;
        Found: Boolean;
    begin
        TempCells.Reset();
        if TempCells.FindSet() then
            repeat
                if Evaluate(Value, TempCells."Cell Value as Text", 9) then
                    Found := Found or (Value = Expected);
            until TempCells.Next() = 0;
        Assert.IsTrue(Found, 'The expected accounting value must be present in the rendered workbook.');
    end;

#if not CLEAN30
    [ReportHandler]
    procedure ScheduleReportHandler(var ScheduleReport: Report "FR Financial Schedule")
    begin
        ScheduleCalls += 1;
    end;

    [ReportHandler]
    procedure StatementReportHandler(var StatementReport: Report "G/L Account Statement FR")
    begin
        StatementCalls += 1;
    end;

    [ReportHandler]
    procedure CustomerDetailHandler(var ReportInstance: Report "Cust. Detail Trial Balance")
    begin
        ObserveExistingReport(Report::"Cust. Detail Trial Balance");
    end;

    [ReportHandler]
    procedure VendorTrialHandler(var ReportInstance: Report "Vendor Trial Balance")
    begin
        ObserveExistingReport(Report::"Vendor Trial Balance");
    end;

    [ReportHandler]
    procedure CustomerTrialHandler(var ReportInstance: Report "Customer Trial Balance")
    begin
        ObserveExistingReport(Report::"Customer Trial Balance");
    end;

    [ReportHandler]
    procedure VendorDetailHandler(var ReportInstance: Report "Vendor Detail Trial Balance")
    begin
        ObserveExistingReport(Report::"Vendor Detail Trial Balance");
    end;

    [ReportHandler]
    procedure GLTrialHandler(var ReportInstance: Report "G/L Trial Balance FR")
    begin
        ObserveExistingReport(Report::"G/L Trial Balance FR");
    end;

    [ReportHandler]
    procedure GLDetailHandler(var ReportInstance: Report "G/L Detail Trial Balance FR")
    begin
        ObserveExistingReport(Report::"G/L Detail Trial Balance FR");
    end;

    [ReportHandler]
    procedure BankTrialHandler(var ReportInstance: Report "Bank Acc. Trial Balance")
    begin
        ObserveExistingReport(Report::"Bank Acc. Trial Balance");
    end;

    [ReportHandler]
    procedure BankJournalHandler(var ReportInstance: Report "Bank Account Journal FR")
    begin
        ObserveExistingReport(Report::"Bank Account Journal FR");
    end;

    [ReportHandler]
    procedure CustomerJournalHandler(var ReportInstance: Report "Customer Journal FR")
    begin
        ObserveExistingReport(Report::"Customer Journal FR");
    end;

    [ReportHandler]
    procedure GLJournalHandler(var ReportInstance: Report "G/L Journal FR")
    begin
        ObserveExistingReport(Report::"G/L Journal FR");
    end;

    [ReportHandler]
    procedure VendorJournalHandler(var ReportInstance: Report "Vendor Journal FR")
    begin
        ObserveExistingReport(Report::"Vendor Journal FR");
    end;

    [ReportHandler]
    procedure JournalsHandler(var ReportInstance: Report "Journals FR")
    begin
        ObserveExistingReport(Report::"Journals FR");
    end;

    [ReportHandler]
    procedure BankDetailHandler(var ReportInstance: Report "Bank Acc. Det. Trial Balance")
    begin
        ObserveExistingReport(Report::"Bank Acc. Det. Trial Balance");
    end;
#endif

#if not CLEAN30
    [ModalPageHandler]
    procedure ForwardedScheduleNamesHandler(var ScheduleNames: TestPage "FR Financial Schedule Names")
    begin
        ReplacementNamesPageOpened := true;
    end;
#endif

    [RequestPageHandler]
    procedure PrintScheduleRequestPageHandler(var RequestPage: TestRequestPage "FR Financial Schedule")
    begin
        RequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

#if not CLEAN30
#pragma warning disable AL0432
    [RequestPageHandler]
    procedure LegacyStatementParametersHandler(var RequestPage: TestRequestPage "G/L Account Statement")
    begin
        RequestPage.EvaluationDate.SetValue(20260131D);
        RequestPage.GLEntries.SetValue('Applied');
        RequestPage.OK().Invoke();
    end;
#pragma warning restore AL0432
#endif
}

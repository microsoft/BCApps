// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Foundation.Reporting;
using System.Reflection;
using System.Upgrade;
using System.TestLibraries.Upgrade;

codeunit 148235 "Banking FI Migration Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure CompletedMigrationDoesNotOverwriteLaterEdits()
    var
        Setup: Record "Reference File Setup FI";
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        Setup."No." := 'FI-MIGRATION-EDIT';
        Setup."File Name" := 'later-edit.xml';
        Setup.Insert();
        if not UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()) then
            UpgradeTag.SetUpgradeTag(Tags.GetMigrationTag());
        Migrate.MigrateDuringLifecycle();
        Setup.Get('FI-MIGRATION-EDIT');
        Assert.AreEqual('later-edit.xml', Setup."File Name", 'A repeated migration must preserve subsequent replacement edits.');
    end;

    [Test]
    procedure ConflictingSetupAbortsBeforeTagging()
    var
        Setup: Record "Reference File Setup FI";
        Source: RecordRef;
        Target: RecordRef;
        SourceField: FieldRef;
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
        Migrate: Codeunit "Banking Payments Migrate FI";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
    begin
        if UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(Tags.GetMigrationTag(), CopyStr(CompanyName(), 1, 30));
        Source.Open(32000000, true);
        Source.Init();
        SourceField := Source.Field(1);
        SourceField.Value := 'FI-MIGRATION-CONFLICT';
        SourceField := Source.Field(21);
        SourceField.Value := 'legacy.xml';
        Source.Insert(false);
        Setup."No." := 'FI-MIGRATION-CONFLICT';
        Setup."File Name" := 'replacement.xml';
        Setup.Insert();
        Target.GetTable(Setup);
        asserterror Migrate.ValidateMatchingRow(Source, Target);
        Assert.ExpectedError('conflicts with existing replacement data');
        Source.Close();
        Assert.IsFalse(UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()), 'A conflicting migration must not set the completed tag.');
        Setup.Get('FI-MIGRATION-CONFLICT');
        Assert.AreEqual('replacement.xml', Setup."File Name", 'Conflicting replacement data must not be overwritten.');
    end;

    [Test]
    procedure EqualBusinessFieldsWithDifferentSystemIdConflict()
    var
        SourceSetup: Record "Reference File Setup FI" temporary;
        TargetSetup: Record "Reference File Setup FI" temporary;
        Source: RecordRef;
        Target: RecordRef;
        Migrate: Codeunit "Banking Payments Migrate FI";
        TargetSystemId: Guid;
    begin
        SourceSetup."No." := 'FI-AUDIT-CONFLICT';
        SourceSetup.SystemId := CreateGuid();
        SourceSetup.Insert(false, true);
        TargetSetup."No." := SourceSetup."No.";
        TargetSetup.SystemId := CreateGuid();
        TargetSetup.Insert(false, true);
        TargetSystemId := TargetSetup.SystemId;
        Source.GetTable(SourceSetup);
        Target.GetTable(TargetSetup);
        asserterror Migrate.ValidateMatchingRow(Source, Target);
        Assert.ExpectedError('field 2000000000 conflicts');
        TargetSetup.Get(SourceSetup."No.");
        Assert.AreEqual(TargetSystemId, TargetSetup.SystemId, 'An identity conflict must not overwrite the target.');
    end;

    [Test]
    procedure DifferentAuditStampConflictsEvenWhenIdentityMatches()
    var
        Setup: Record "Reference File Setup FI" temporary;
        Source: RecordRef;
        Target: RecordRef;
        AuditField: FieldRef;
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        Setup."No." := 'FI-AUDIT-STAMP';
        Setup.Insert();
        Source.GetTable(Setup);
        Target.GetTable(Setup);
        Migrate.ValidateMatchingRow(Source, Target);
        AuditField := Target.Field(2000000003);
        if Setup.SystemModifiedAt = 0DT then
            AuditField.Value := CreateDateTime(20260101D, 120000T)
        else
            AuditField.Value := Setup.SystemModifiedAt + 1000;
        asserterror Migrate.ValidateMatchingRow(Source, Target);
        Assert.ExpectedError('field 2000000003 conflicts');
    end;

    [Test]
    procedure OrdinaryExecutionCannotCopyHistoricalData()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
        Migrate: Codeunit "Banking Payments Migrate FI";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
    begin
        if UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(Tags.GetMigrationTag(), CopyStr(CompanyName(), 1, 30));
        asserterror Migrate.MigrateDuringLifecycle();
        Assert.ExpectedError('only be copied during an actual app install or upgrade');
        Assert.IsFalse(UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()), 'Ordinary execution cannot claim a lifecycle migration.');
    end;

    [Test]
    procedure SharedBuiltInSelectionPlanPreservesScopeAndChoice()
    var
        Source: Record "Report Layout Selection" temporary;
        Planned: Record "Report Layout Selection" temporary;
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        CreateBuiltInSelection(Source, '');
        Migrate.PlanBuiltInLayoutSelection(Source, Report::"Payment FI", Planned);
        Assert.AreEqual(Report::"Payment FI", Planned."Report ID", 'The counterpart must refer to the replacement report.');
        Assert.AreEqual('', Planned."Company Name", 'A shared selection must not become a current-company override.');
        Assert.AreEqual(Source.Type, Planned.Type, 'The same built-in format must be selected, not the replacement default.');
        Assert.AreEqual(Source."Report Name", Planned."Report Name", 'Historical stored names must survive the copy.');
        Source.Get(32000005, '');
        Assert.AreEqual(32000005, Source."Report ID", 'Planning must leave the shared legacy selection available.');
        Assert.IsTrue(IsNullGuid(Planned.SystemId), 'A second key in the same table cannot reuse the legacy identity.');
    end;

    [Test]
    procedure CompanyBuiltInSelectionPlanPreservesScopeAndAudit()
    var
        Source: Record "Report Layout Selection" temporary;
        Planned: Record "Report Layout Selection" temporary;
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        CreateBuiltInSelection(Source, CopyStr(CompanyName(), 1, 30));
        Migrate.PlanBuiltInLayoutSelection(Source, Report::"Payment FI", Planned);
        Assert.AreEqual(Source."Company Name", Planned."Company Name", 'A company override must not become shared.');
        Assert.AreEqual(Source.SystemCreatedAt, Planned.SystemCreatedAt, 'Planning must preserve the historical creation time.');
        Assert.AreEqual(Source.SystemModifiedBy, Planned.SystemModifiedBy, 'Planning must preserve the historical modifying user.');
        Migrate.PlanBuiltInLayoutSelection(Source, Report::"Payment FI", Planned);
        Source.Get(32000005, Source."Company Name");
        Assert.AreEqual(Source.SystemModifiedAt, Planned.SystemModifiedAt, 'Repeated planning must not stamp or modify the source.');
    end;

    [Test]
    procedure CustomChoiceCannotBeConvertedToBuiltIn()
    var
        Source: Record "Report Layout Selection" temporary;
        Planned: Record "Report Layout Selection" temporary;
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        CreateBuiltInSelection(Source, '');
        Source.Type := Source.Type::"Custom Layout";
        Source."Custom Report Layout Code" := 'FI-CUSTOM-CHOICE';
        Source.Modify();
        asserterror Migrate.PlanBuiltInLayoutSelection(Source, Report::"Payment FI", Planned);
        Assert.ExpectedError('approved audit-preserving layout-content and selection mapping');
        Source.Get(32000005, '');
        Assert.AreEqual('FI-CUSTOM-CHOICE', Source."Custom Report Layout Code", 'An unsupported custom choice must not be cleared.');
        Assert.AreEqual(Source.Type::"Custom Layout", Source.Type, 'Failure must not silently substitute RDLC.');
    end;

    [Test]
    procedure MissingBuiltInFormatCannotFallBackToDefault()
    var
        Source: Record "Report Layout Selection" temporary;
        Planned: Record "Report Layout Selection" temporary;
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        CreateBuiltInSelection(Source, '');
        Source.Type := Source.Type::"Word (built-in)";
        Source.Modify();
        asserterror Migrate.PlanBuiltInLayoutSelection(Source, Report::"Payment FI", Planned);
        Assert.ExpectedError('has no Word layout');
        Source.Get(32000005, '');
        Assert.AreEqual(Source.Type::"Word (built-in)", Source.Type, 'The missing format must not change the stored legacy choice.');
    end;

    [Test]
    procedure IdenticalSelectionCounterpartIsRepeatSafeWithNewIdentity()
    var
        Source: Record "Report Layout Selection" temporary;
        Planned: Record "Report Layout Selection" temporary;
        Target: Record "Report Layout Selection" temporary;
        Migrate: Codeunit "Banking Payments Migrate FI";
        TargetSystemId: Guid;
    begin
        CreateBuiltInSelection(Source, '');
        Migrate.PlanBuiltInLayoutSelection(Source, Report::"Payment FI", Planned);
        Target := Planned;
        Target.SystemId := CreateGuid();
        Target.Insert(false, true);
        TargetSystemId := Target.SystemId;
        Migrate.ValidateMatchingLayoutSelection(Planned, Target);
        Migrate.ValidateMatchingLayoutSelection(Planned, Target);
        Target.Get(Report::"Payment FI", '');
        Assert.AreEqual(TargetSystemId, Target.SystemId, 'Repeat validation must retain the distinct counterpart identity.');
        Source.Get(32000005, '');
        Assert.AreNotEqual(Source.SystemId, Target.SystemId, 'The old shared selection must retain its own immutable identity.');
    end;

    [Test]
    procedure ConflictingSelectionCounterpartIsNotOverwritten()
    var
        Source: Record "Report Layout Selection" temporary;
        Planned: Record "Report Layout Selection" temporary;
        Target: Record "Report Layout Selection" temporary;
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        CreateBuiltInSelection(Source, '');
        Migrate.PlanBuiltInLayoutSelection(Source, Report::"Payment FI", Planned);
        Target := Planned;
        Target.Type := Target.Type::"Custom Layout";
        Target."Custom Report Layout Code" := 'FI-EXISTING-CHOICE';
        Target.Insert();
        asserterror Migrate.ValidateMatchingLayoutSelection(Planned, Target);
        Assert.ExpectedError('conflicts with existing replacement data');
        Target.Get(Report::"Payment FI", '');
        Assert.AreEqual('FI-EXISTING-CHOICE', Target."Custom Report Layout Code", 'A conflicting target must retain its custom choice.');
        Source.Get(32000005, '');
        Assert.AreEqual(Source.Type::"RDLC (built-in)", Source.Type, 'A target conflict must not alter the legacy choice.');
    end;

    [Test]
    procedure SelectionCounterpartWithDifferentAuditIsRejected()
    var
        Source: Record "Report Layout Selection" temporary;
        Planned: Record "Report Layout Selection" temporary;
        Target: Record "Report Layout Selection" temporary;
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        CreateBuiltInSelection(Source, '');
        Migrate.PlanBuiltInLayoutSelection(Source, Report::"Payment FI", Planned);
        Target := Planned;
        Target.SystemModifiedAt := Planned.SystemModifiedAt + 1000;
        Target.Insert();
        asserterror Migrate.ValidateMatchingLayoutSelection(Planned, Target);
        Assert.ExpectedError('field 2000000003 conflicts');
        Target.Get(Report::"Payment FI", '');
        Assert.AreEqual(Planned.SystemModifiedAt + 1000, Target.SystemModifiedAt, 'Validation must not restore audit fields through a record write.');
    end;

    [Test]
    procedure SharedCustomLayoutFailurePreservesBothBlobsAndAudit()
    begin
        VerifyCustomLayoutFailurePreservesContent('');
    end;

    [Test]
    procedure CompanyCustomLayoutFailurePreservesBothBlobsAndAudit()
    begin
        VerifyCustomLayoutFailurePreservesContent(CopyStr(CompanyName(), 1, 30));
    end;

    [Test]
    procedure OtherCompanyCustomLayoutDoesNotBlockCurrentCompany()
    var
        Layout: Record "Custom Report Layout";
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        Layout.Code := 'FI-LAYOUT-OTHER';
        Layout."Report ID" := 32000005;
        Layout."Company Name" := CopyStr(CreateGuid(), 1, 30);
        Layout.Insert(false);
        Migrate.ValidateReportLayouts(32000005, Report::"Payment FI");
        Layout.Get('FI-LAYOUT-OTHER');
        Assert.AreEqual(32000005, Layout."Report ID", 'A not-yet-migrated company must keep its own legacy layout.');
    end;

    [Test]
    procedure SharedModernSelectionMustNotBeSilentlyRetargeted()
    var
        Selection: Record "Tenant Report Layout Selection";
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        Selection."Report ID" := 32000005;
        Selection."Company Name" := '';
        Selection."Layout Name" := 'FI shared user-defined layout';
        Selection.Insert(false);
        asserterror Migrate.ValidateReportLayouts(32000005, Report::"Payment FI");
        Assert.ExpectedError('Tenant Report Layout Selection');
        Selection.Get(32000005, '', Selection."User ID");
        Assert.AreEqual('FI shared user-defined layout', Selection."Layout Name", 'The shared modern selection must remain unchanged.');
    end;

    [Test]
    procedure ReplacementUserSelectionRequiresExplicitReconciliation()
    var
        Selection: Record "Tenant Report Layout Selection";
        Migrate: Codeunit "Banking Payments Migrate FI";
        UserId: Guid;
    begin
        UserId := CreateGuid();
        Selection."Report ID" := Report::"Payment FI";
        Selection."Company Name" := CopyStr(CompanyName(), 1, 30);
        Selection."User ID" := UserId;
        Selection."Layout Name" := 'FI existing user choice';
        Selection.Insert(false);
        asserterror Migrate.ValidateReportLayouts(32000005, Report::"Payment FI");
        Assert.ExpectedError('approved audit-preserving layout-content and selection mapping');
        Selection.Get(Report::"Payment FI", CopyStr(CompanyName(), 1, 30), UserId);
        Assert.AreEqual('FI existing user choice', Selection."Layout Name", 'A user-specific replacement override must not be ignored or overwritten.');
    end;

    local procedure CreateBuiltInSelection(var Selection: Record "Report Layout Selection" temporary; ScopeCompany: Text[30])
    begin
        Selection."Report ID" := 32000005;
        Selection."Company Name" := ScopeCompany;
        Selection."Report Name" := 'Historical payment name';
        Selection.Type := Selection.Type::"RDLC (built-in)";
        Selection.SystemId := CreateGuid();
        Selection.SystemCreatedAt := CreateDateTime(20260101D, 120000T);
        Selection.SystemModifiedAt := CreateDateTime(20260102D, 120000T);
        Selection.SystemCreatedBy := CreateGuid();
        Selection.SystemModifiedBy := CreateGuid();
        Selection.Insert(false, true);
    end;

    local procedure VerifyCustomLayoutFailurePreservesContent(ScopeCompany: Text[30])
    var
        Layout: Record "Custom Report Layout";
        Migrate: Codeunit "Banking Payments Migrate FI";
        Output: OutStream;
        Input: InStream;
        Content: Text;
        SystemId: Guid;
        ModifiedAt: DateTime;
    begin
        Layout.Code := 'FI-LAYOUT-CONTENT';
        Layout."Report ID" := 32000005;
        Layout."Company Name" := ScopeCompany;
        Layout.Layout.CreateOutStream(Output, TextEncoding::UTF8);
        Output.WriteText('retained-layout-content');
        Layout."Custom XML Part".CreateOutStream(Output, TextEncoding::UTF8);
        Output.WriteText('<retained-custom-xml />');
        Layout.Insert(false);
        SystemId := Layout.SystemId;
        ModifiedAt := Layout.SystemModifiedAt;
        asserterror Migrate.ValidateReportLayouts(32000005, Report::"Payment FI");
        Assert.ExpectedError('approved audit-preserving layout-content and selection mapping');
        Layout.Get('FI-LAYOUT-CONTENT');
        Layout.CalcFields(Layout, "Custom XML Part");
        Layout.Layout.CreateInStream(Input, TextEncoding::UTF8);
        Input.ReadText(Content);
        Assert.AreEqual('retained-layout-content', Content, 'Failure must not truncate or replace the layout BLOB.');
        Layout."Custom XML Part".CreateInStream(Input, TextEncoding::UTF8);
        Input.ReadText(Content);
        Assert.AreEqual('<retained-custom-xml />', Content, 'Failure must preserve the independent custom XML BLOB.');
        Assert.AreEqual(SystemId, Layout.SystemId, 'The legacy layout identity must remain unchanged.');
        Assert.AreEqual(ModifiedAt, Layout.SystemModifiedAt, 'Validation must not stamp the shared layout.');
        Assert.AreEqual(ScopeCompany, Layout."Company Name", 'Failure must not alter layout ownership.');
        Assert.AreEqual(32000005, Layout."Report ID", 'Failure must keep the original report-to-layout relationship.');
    end;
}

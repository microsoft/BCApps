// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.Reports;
using Microsoft.Foundation.Reporting;
using System.Reflection;
using System.Security.Encryption;
using System.Upgrade;
using System.Utilities;
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
    procedure SharedClassicRdlcPreservesContentAndOriginalOnRetry()
    begin
        VerifyCompatibleClassicLayout('', 32000005, Report::"Payment FI");
    end;

    [Test]
    procedure CompanyImportedPaymentsRdlcPreservesContentAndScope()
    begin
        VerifyCompatibleClassicLayout(CopyStr(CompanyName(), 1, 30), 32000001, Report::"Ref. Payment Imported FI");
    end;

    [Test]
    procedure DifferentCustomXmlBytesRejectExistingCounterpart()
    var
        Source: Record "Custom Report Layout";
        Planned: Record "Custom Report Layout" temporary;
        Target: Record "Custom Report Layout";
        Migrate: Codeunit "Banking Payments Migrate FI";
        Output: OutStream;
        OriginalHash: Text;
        TargetHash: Text;
    begin
        CreateCompatibleClassicLayout(Source, '', 32000005, Report::"Payment FI");
        OriginalHash := GetLayoutHash(Source, Source.FieldNo("Custom XML Part"));
        Migrate.PlanCustomReportLayout(Source, Report::"Payment FI", Planned);
        Target := Planned;
        Target."Custom XML Part".CreateOutStream(Output, TextEncoding::UTF8);
        Output.WriteText('<changedx-custom-xml />');
        Target.Insert(false);
        TargetHash := GetLayoutHash(Target, Target.FieldNo("Custom XML Part"));
        asserterror Migrate.ValidateReportLayouts(32000005, Report::"Payment FI");
        Assert.ExpectedError('field 12 conflicts');
        Source.Get(Source.Code);
        Target.Get(Target.Code);
        Assert.AreEqual(OriginalHash, GetLayoutHash(Source, Source.FieldNo("Custom XML Part")), 'A conflict must not alter the original XML bytes.');
        Assert.AreEqual(TargetHash, GetLayoutHash(Target, Target.FieldNo("Custom XML Part")), 'A conflict must not overwrite the target XML, even when its length matches.');
    end;

    [Test]
    procedure DifferentRdlcBytesRejectExistingCounterpart()
    var
        Source: Record "Custom Report Layout";
        Planned: Record "Custom Report Layout" temporary;
        Target: Record "Custom Report Layout";
        Migrate: Codeunit "Banking Payments Migrate FI";
        Output: OutStream;
        OriginalHash: Text;
    begin
        CreateCompatibleClassicLayout(Source, '', 32000005, Report::"Payment FI");
        OriginalHash := GetLayoutHash(Source, Source.FieldNo(Layout));
        Migrate.PlanCustomReportLayout(Source, Report::"Payment FI", Planned);
        Target := Planned;
        Target.Layout.CreateOutStream(Output, TextEncoding::UTF8);
        Output.WriteText('existing replacement content');
        Target.Insert(false);
        asserterror Migrate.ValidateReportLayouts(32000005, Report::"Payment FI");
        Assert.ExpectedError('field 7 conflicts');
        Source.Get(Source.Code);
        Assert.AreEqual(OriginalHash, GetLayoutHash(Source, Source.FieldNo(Layout)), 'A content conflict must preserve the original RDLC.');
    end;

    [Test]
    procedure MissingExtensionColumnCannotPassDatasetValidation()
    var
        Source: Record "Custom Report Layout";
        Target: Record "Custom Report Layout";
        Migrate: Codeunit "Banking Payments Migrate FI";
        Input: InStream;
        Output: OutStream;
        Content: BigText;
        LayoutText: Text;
        OriginalHash: Text;
        OriginalModifiedAt: DateTime;
    begin
        CreateCompatibleClassicLayout(Source, '', 32000005, Report::"Payment FI");
        Source.Layout.CreateInStream(Input, TextEncoding::UTF8);
        Content.Read(Input);
        Content.GetSubText(LayoutText, 1);
        LayoutText := LayoutText.Replace('No_BankAccount', 'RemovedLegacyExtensionColumn');
        Source.Layout.CreateOutStream(Output, TextEncoding::UTF8);
        Output.WriteText(LayoutText);
        Source.Modify(false);
        OriginalHash := GetLayoutHash(Source, Source.FieldNo(Layout));
        OriginalModifiedAt := Source.SystemModifiedAt;
        asserterror Migrate.ValidateReportLayouts(32000005, Report::"Payment FI");
        Assert.ExpectedError('Original content and selections are unchanged');
        Assert.IsFalse(Target.Get(Migrate.GetMappedLayoutCode(Source)), 'Preflight must not leave a replacement for an incompatible dataset.');
        Source.Get(Source.Code);
        Assert.AreEqual(OriginalHash, GetLayoutHash(Source, Source.FieldNo(Layout)), 'Validation must not remove unavailable extension fields from the original.');
        Assert.AreEqual(OriginalModifiedAt, Source.SystemModifiedAt, 'Validation must not update the original audit stamp.');
    end;

    [Test]
    procedure ProcessingOnlyReportCannotAcquireAnUnprovenLayout()
    var
        Source: Record "Custom Report Layout";
        Planned: Record "Custom Report Layout" temporary;
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        CreateCompatibleClassicLayout(Source, '', 13403, Report::"Payment FI");
        asserterror Migrate.PlanCustomReportLayout(Source, Report::"Export SEPA Payment File FI", Planned);
        Assert.ExpectedError('This release cannot complete cutover with unsupported layout originals or selections');
        Source.Get(Source.Code);
        Assert.AreEqual(13403, Source."Report ID", 'An unsupported report pair must retain its original layout.');
    end;

    [Test]
    procedure ClassicPrintAndEmailBodySelectionsUseTheSameMapping()
    var
        Layout: Record "Custom Report Layout";
        Source: Record "Report Selections" temporary;
        Planned: Record "Report Selections" temporary;
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        CreateCompatibleClassicLayout(Layout, '', 32000005, Report::"Payment FI");
        Source.Usage := Source.Usage::"P.Order";
        Source.Sequence := '7';
        Source."Report ID" := 32000005;
        Source."Custom Report Layout Code" := Layout.Code;
        Source."Use for Email Body" := true;
        Source."Use for Email Attachment" := false;
        Source."Email Body Layout Type" := Source."Email Body Layout Type"::"Custom Report Layout";
        Source."Email Body Layout Code" := Layout.Code;
        Source.Insert(false);
        Migrate.PlanReportSelection(Source, Report::"Payment FI", Planned);
        Assert.AreEqual(Report::"Payment FI", Planned."Report ID", 'The stored report and layout references must be mapped together.');
        Assert.AreEqual(Migrate.GetMappedLayoutCode(Layout), Planned."Custom Report Layout Code", 'Print must use the deterministic counterpart.');
        Assert.AreEqual(Planned."Custom Report Layout Code", Planned."Email Body Layout Code", 'The body must not silently fall back to a built-in layout.');
        Assert.IsTrue(Planned."Use for Email Body", 'Body selection flags must remain unchanged.');
        Assert.IsFalse(Planned."Use for Email Attachment", 'A disabled attachment must not be enabled.');
        Assert.AreEqual(Source.SystemId, Planned.SystemId, 'The same company-specific selector keeps its identity.');
        Assert.AreEqual(Layout.Code, Source."Email Body Layout Code", 'Planning must leave the legacy choice unchanged.');
    end;

    [Test]
    procedure CustomerAndVendorOverridesPreserveContactsAndEmailChoices()
    begin
        VerifyCustomSelectorPlan(18);
        VerifyCustomSelectorPlan(23);
    end;

    [Test]
    procedure SharedSelectionCannotUseAnotherCompanysLayout()
    var
        Layout: Record "Custom Report Layout";
        Source: Record "Report Layout Selection" temporary;
        Planned: Record "Report Layout Selection" temporary;
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        CreateCompatibleClassicLayout(Layout, CopyStr(CompanyName(), 1, 30), 32000005, Report::"Payment FI");
        CreateBuiltInSelection(Source, '');
        Source.Type := Source.Type::"Custom Layout";
        Source."Custom Report Layout Code" := Layout.Code;
        Source.Modify(false);
        asserterror Migrate.PlanLayoutSelection(Source, Report::"Payment FI", Planned);
        Assert.ExpectedError('outside this scope');
        Assert.AreEqual(Layout.Code, Source."Custom Report Layout Code", 'An invalid scope must not be repaired by changing the legacy selection.');
    end;

    [Test]
    procedure NamedEmailAttachmentCannotBeMistakenForClassicLayout()
    var
        Source: Record "Custom Report Selection" temporary;
        Planned: Record "Custom Report Selection" temporary;
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        Source."Report ID" := 32000005;
        Source."Email Attachment Layout Name" := 'Existing named attachment';
        Source."Email Attachment Layout AppID" := CreateGuid();
        Source.Insert(false);
        asserterror Migrate.PlanCustomReportSelection(Source, Report::"Payment FI", Planned);
        Assert.ExpectedError('Export this layout');
        Assert.ExpectedError('export/adapt/import/reselect alone does not unblock this release');
        Assert.AreEqual('Existing named attachment', Source."Email Attachment Layout Name", 'A named attachment must never be dropped during classic mapping.');
    end;

    [Test]
    procedure CustomDefaultConflictLeavesBothReportChoicesUntouched()
    var
        Layout: Record "Custom Report Layout";
        TargetLayout: Record "Custom Report Layout";
        Source: Record "Report Layout Selection";
        Target: Record "Report Layout Selection";
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        CreateCompatibleClassicLayout(Layout, '', 32000005, Report::"Payment FI");
        Source."Report ID" := 32000005;
        Source."Company Name" := CopyStr(CompanyName(), 1, 30);
        Source.Type := Source.Type::"Custom Layout";
        Source."Custom Report Layout Code" := Layout.Code;
        Source.Insert(false);
        Target."Report ID" := Report::"Payment FI";
        Target."Company Name" := Source."Company Name";
        Target.Type := Target.Type::"RDLC (built-in)";
        Target.Insert(false);
        asserterror Migrate.ValidateReportLayouts(32000005, Report::"Payment FI");
        Assert.ExpectedError('field 4 conflicts');
        Assert.IsFalse(TargetLayout.Get(Migrate.GetMappedLayoutCode(Layout)), 'Selection preflight must finish before inserting any counterpart.');
        Source.Get(32000005, Source."Company Name");
        Target.Get(Report::"Payment FI", Target."Company Name");
        Assert.AreEqual(Layout.Code, Source."Custom Report Layout Code", 'The original custom choice must remain selected.');
        Assert.AreEqual(Target.Type::"RDLC (built-in)", Target.Type, 'A conflicting replacement choice must not be overwritten.');
    end;

    [Test]
    procedure ReplacementDefaultWithoutLegacyChoiceRequiresReconciliation()
    var
        Source: Record "Report Layout Selection";
        Target: Record "Report Layout Selection";
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        Target."Report ID" := Report::"Payment FI";
        Target."Company Name" := CopyStr(CompanyName(), 1, 30);
        Target.Type := Target.Type::"RDLC (built-in)";
        Target.Insert(false);
        Assert.IsFalse(Source.Get(32000005, Target."Company Name"), 'The fixture requires an implicit legacy default.');
        asserterror Migrate.ValidateReportLayouts(32000005, Report::"Payment FI");
        Assert.ExpectedError('field 4 conflicts');
        Target.Get(Report::"Payment FI", Target."Company Name");
        Assert.AreEqual(Target.Type::"RDLC (built-in)", Target.Type, 'An unmatched replacement default must be reconciled, not overwritten.');
        Assert.IsFalse(Source.Get(32000005, Target."Company Name"), 'Validation must not invent a historical choice.');
    end;

    [Test]
    procedure MissingClassicLayoutReferenceDoesNotBecomeDefault()
    var
        Source: Record "Report Selections" temporary;
        Planned: Record "Report Selections" temporary;
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        Source."Report ID" := 32000005;
        Source."Custom Report Layout Code" := 'FI-MISSING-LAYOUT';
        Source.Insert(false);
        asserterror Migrate.PlanReportSelection(Source, Report::"Payment FI", Planned);
        Assert.ExpectedError('original layout is missing');
        Assert.AreEqual('FI-MISSING-LAYOUT', Source."Custom Report Layout Code", 'A dangling custom reference must not silently become the default.');
    end;

    [Test]
    procedure ReplacementSelectorCannotKeepALegacyReportsLayoutCode()
    var
        Layout: Record "Custom Report Layout";
        Source: Record "Custom Report Selection";
        Migrate: Codeunit "Banking Payments Migrate FI";
    begin
        CreateCompatibleClassicLayout(Layout, '', 32000005, Report::"Payment FI");
        Source."Source Type" := 23;
        Source."Source No." := 'FI-AMBIGUOUS-CHOICE';
        Source."Report ID" := Report::"Payment FI";
        Source."Custom Report Layout Code" := Layout.Code;
        Source.Insert(false);
        asserterror Migrate.ValidateReportLayouts(32000005, Report::"Payment FI");
        Assert.ExpectedError('Custom Report Selection');
        Source.Get(Source."Source Type", Source."Source No.", Source.Usage, Source.Sequence);
        Assert.AreEqual(Layout.Code, Source."Custom Report Layout Code", 'An ambiguous cross-report reference requires explicit reconciliation.');
    end;

    [Test]
    procedure SharedWordLayoutFailurePreservesBothBlobsAndAudit()
    begin
        VerifyWordLayoutFailurePreservesContent('');
    end;

    [Test]
    procedure CompanyWordLayoutFailurePreservesBothBlobsAndAudit()
    begin
        VerifyWordLayoutFailurePreservesContent(CopyStr(CompanyName(), 1, 30));
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

    local procedure VerifyCompatibleClassicLayout(ScopeCompany: Text[30]; OldId: Integer; NewId: Integer)
    var
        Source: Record "Custom Report Layout";
        Planned: Record "Custom Report Layout" temporary;
        Target: Record "Custom Report Layout";
        Selection: Record "Report Layout Selection" temporary;
        PlannedSelection: Record "Report Layout Selection" temporary;
        Migrate: Codeunit "Banking Payments Migrate FI";
        OriginalSystemId: Guid;
        TargetSystemId: Guid;
        OriginalModifiedAt: DateTime;
        OriginalLayoutHash: Text;
        OriginalXmlHash: Text;
    begin
        CreateCompatibleClassicLayout(Source, ScopeCompany, OldId, NewId);
        OriginalSystemId := Source.SystemId;
        OriginalModifiedAt := Source.SystemModifiedAt;
        OriginalLayoutHash := GetLayoutHash(Source, Source.FieldNo(Layout));
        OriginalXmlHash := GetLayoutHash(Source, Source.FieldNo("Custom XML Part"));
        Migrate.PlanCustomReportLayout(Source, NewId, Planned);
        Assert.IsTrue(IsNullGuid(Planned.SystemId), 'A planned counterpart must not reuse a source or temporary identity.');
        Assert.AreEqual(ScopeCompany, Planned."Company Name", 'Classic layout scope must remain shared or company-specific.');
        Assert.AreEqual(Source.Description, Planned.Description, 'The custom layout name must survive.');
        Assert.AreEqual(Source.Type, Planned.Type, 'The layout format must survive.');
        Assert.AreEqual(Source."App ID", Planned."App ID", 'Classic application identity metadata must be retained.');
        Assert.AreEqual(Source."Last Modified", Planned."Last Modified", 'Stored historical modification information must survive.');
        Assert.AreEqual(OriginalLayoutHash, GetLayoutHash(Planned, Planned.FieldNo(Layout)), 'The RDLC stream must be copied byte for byte.');
        Assert.AreEqual(OriginalXmlHash, GetLayoutHash(Planned, Planned.FieldNo("Custom XML Part")), 'The independent XML stream must be copied byte for byte.');
        Target := Planned;
        Target.Insert(false);
        TargetSystemId := Target.SystemId;
        Migrate.ValidateReportLayouts(OldId, NewId);
        Migrate.ValidateReportLayouts(OldId, NewId);
        Selection."Report ID" := OldId;
        Selection."Company Name" := ScopeCompany;
        Selection.Type := Selection.Type::"Custom Layout";
        Selection."Custom Report Layout Code" := Source.Code;
        Selection.Insert(false);
        Migrate.PlanLayoutSelection(Selection, NewId, PlannedSelection);
        Assert.AreEqual(Target.Code, PlannedSelection."Custom Report Layout Code", 'The selection must point at the repeat-safe counterpart.');
        Assert.AreEqual(ScopeCompany, PlannedSelection."Company Name", 'The selection must retain its scope.');
        Assert.AreEqual(Selection.Type, PlannedSelection.Type, 'Custom must never become built-in.');
        Target.Get(Target.Code);
        Assert.AreEqual(TargetSystemId, Target.SystemId, 'Retry validation must retain the existing target identity.');
        Assert.AreNotEqual(OriginalSystemId, TargetSystemId, 'Two rows in the same table require different identities.');
        Source.Get(Source.Code);
        Assert.AreEqual(OldId, Source."Report ID", 'The legacy layout must remain attached to its original report.');
        Assert.AreEqual(OriginalSystemId, Source.SystemId, 'The original layout identity must be preserved.');
        Assert.AreEqual(OriginalModifiedAt, Source.SystemModifiedAt, 'Planning and repeat validation must not stamp the original.');
        Assert.AreEqual(OriginalLayoutHash, GetLayoutHash(Source, Source.FieldNo(Layout)), 'The original RDLC bytes must survive.');
        Assert.AreEqual(OriginalXmlHash, GetLayoutHash(Source, Source.FieldNo("Custom XML Part")), 'The original XML bytes must survive.');
    end;

    local procedure VerifyCustomSelectorPlan(SourceType: Integer)
    var
        Layout: Record "Custom Report Layout";
        Source: Record "Custom Report Selection" temporary;
        Planned: Record "Custom Report Selection" temporary;
        Migrate: Codeunit "Banking Payments Migrate FI";
        Output: OutStream;
        Input: InStream;
        Contacts: Text;
    begin
        CreateCompatibleClassicLayout(Layout, CopyStr(CompanyName(), 1, 30), 32000005, Report::"Payment FI");
        Source."Source Type" := SourceType;
        Source."Source No." := 'FI-CUSTOM-SELECTOR';
        Source.Usage := Source.Usage::"P.Order";
        Source."Report ID" := 32000005;
        Source."Custom Report Layout Code" := Layout.Code;
        Source."Email Body Layout Code" := Layout.Code;
        Source."Use for Email Body" := true;
        Source."Use for Email Attachment" := true;
        Source."Send To Email" := 'retained@example.com';
        Source."Selected Contacts Filter".CreateOutStream(Output, TextEncoding::UTF8);
        Output.WriteText('retained-contact-filter');
        Source.Insert(false);
        Migrate.PlanCustomReportSelection(Source, Report::"Payment FI", Planned);
        Assert.AreEqual(SourceType, Planned."Source Type", 'Customer/vendor ownership must survive.');
        Assert.AreEqual(Source."Source No.", Planned."Source No.", 'The selected customer/vendor must not change.');
        Assert.AreEqual(Source.SystemId, Planned.SystemId, 'Remapping in place must retain selector identity.');
        Assert.AreEqual(Source.SystemModifiedAt, Planned.SystemModifiedAt, 'Planning must retain selector audit.');
        Assert.AreEqual(Source."Send To Email", Planned."Send To Email", 'The recipient must survive.');
        Assert.IsTrue(Planned."Use for Email Body" and Planned."Use for Email Attachment", 'Both email flags must survive.');
        Assert.AreEqual(Migrate.GetMappedLayoutCode(Layout), Planned."Custom Report Layout Code", 'The customer/vendor print override must map.');
        Assert.AreEqual(Planned."Custom Report Layout Code", Planned."Email Body Layout Code", 'The email body override must map too.');
        Planned."Selected Contacts Filter".CreateInStream(Input, TextEncoding::UTF8);
        Input.ReadText(Contacts);
        Assert.AreEqual('retained-contact-filter', Contacts, 'Selected-contact content must survive planning without DataTransfer.');
        Assert.AreEqual(Layout.Code, Source."Custom Report Layout Code", 'Planning must not mutate the source override.');
    end;

    local procedure CreateCompatibleClassicLayout(var Layout: Record "Custom Report Layout"; ScopeCompany: Text[30]; OldId: Integer; LayoutReportId: Integer)
    var
        BuiltInLayout: Record "Report Layout List";
        Input: InStream;
        Output: OutStream;
        Content: BigText;
        LayoutText: Text;
    begin
        Layout.Init();
        Layout.Code := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(Layout.Code));
        Layout."Report ID" := OldId;
        Layout."Company Name" := ScopeCompany;
        Layout.Type := Layout.Type::RDLC;
        Layout."File Extension" := 'RDLC';
        Layout.Description := 'Retained Finnish classic layout';
        Layout."Last Modified" := CreateDateTime(20260101D, 120000T);
        Layout."Last Modified by User" := 'Historical user';
        Layout."App ID" := CreateGuid();
        BuiltInLayout.SetRange("Report ID", LayoutReportId);
        BuiltInLayout.SetRange("Layout Format", BuiltInLayout."Layout Format"::RDLC);
        BuiltInLayout.FindFirst();
        Layout.Layout.CreateOutStream(Output);
        Assert.IsTrue(BuiltInLayout.Layout.ExportStream(Output), 'The compiled replacement RDLC must be available as a compatible fixture.');
        Layout.Layout.CreateInStream(Input, TextEncoding::UTF8);
        Content.Read(Input);
        Content.GetSubText(LayoutText, 1);
        LayoutText := LayoutText.Replace('<Value>=Globals!ExecutionTime</Value>', '<Value>Retained Finnish custom heading</Value>');
        Assert.IsTrue(StrPos(LayoutText, 'Retained Finnish custom heading') > 0, 'The fixture must exercise a visible customization, not just built-in bytes.');
        Layout.Layout.CreateOutStream(Output, TextEncoding::UTF8);
        Output.WriteText(LayoutText);
        Layout."Custom XML Part".CreateOutStream(Output, TextEncoding::UTF8);
        Output.WriteText('<retained-custom-xml />');
        Layout.Insert(false);
    end;

    local procedure GetLayoutHash(Layout: Record "Custom Report Layout"; FieldId: Integer): Text
    var
        Blob: Codeunit "Temp Blob";
        Cryptography: Codeunit "Cryptography Management";
        Input: InStream;
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        Blob.FromRecord(Layout, FieldId);
        Blob.CreateInStream(Input);
        exit(Cryptography.GenerateHash(Input, HashAlgorithm::SHA256));
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

    local procedure VerifyWordLayoutFailurePreservesContent(ScopeCompany: Text[30])
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
        Layout.Type := Layout.Type::Word;
        Layout.Layout.CreateOutStream(Output, TextEncoding::UTF8);
        Output.WriteText('retained-layout-content');
        Layout."Custom XML Part".CreateOutStream(Output, TextEncoding::UTF8);
        Output.WriteText('<retained-custom-xml />');
        Layout.Insert(false);
        SystemId := Layout.SystemId;
        ModifiedAt := Layout.SystemModifiedAt;
        asserterror Migrate.ValidateReportLayouts(32000005, Report::"Payment FI");
        Assert.ExpectedError('approved audit-preserving layout-content and selection mapping');
        Assert.ExpectedError('This release cannot complete cutover with unsupported layout originals or selections');
        Assert.ExpectedError('Originals, content and selections are preserved');
        Assert.ExpectedError('export/adapt/import/reselect alone does not unblock this release');
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

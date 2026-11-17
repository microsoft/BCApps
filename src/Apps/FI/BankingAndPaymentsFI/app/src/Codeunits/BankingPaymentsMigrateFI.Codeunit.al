// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.Setup;
using Microsoft.Foundation.Reporting;
using System.Reflection;
using System.Security.Encryption;
using System.Upgrade;
using System.Utilities;

codeunit 13582 "Banking Payments Migrate FI"
{
    Access = Internal;

    [CommitBehavior(CommitBehavior::Error)]
    procedure MigrateDuringLifecycle()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
    begin
        if UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()) then begin
            if UpgradeTag.HasUpgradeTagSkipped(Tags.GetMigrationTag(), CopyStr(CompanyName(), 1, 30)) then
                Error(SkippedMigrationErr);
            exit;
        end;
        if GetExecutionContext() = ExecutionContext::Normal then
            Error(LifecycleRequiredErr);

        ValidateStoredReportLayouts();
        CopyTable(32000000, Database::"Reference File Setup FI");
        CopyTable(32000001, Database::"Ref. Payment - Imported FI");
        CopyTable(32000002, Database::"Ref. Payment - Exported FI");
        CopyTable(32000003, Database::"Foreign Payment Types FI");
        CopyTable(32000004, Database::"Ref. Payment Export Buffer FI");
        CopyStandardFields();
        RemapStoredObjects();
        UpgradeTag.SetUpgradeTag(Tags.GetMigrationTag());
    end;

    local procedure CopyStandardFields()
    begin
        CopyField(81, 32000000, 13511);
        CopyField(81, 32000001, 13512);
        CopyField(81, 32000002, 13513);
        CopyField(81, 32000003, 13514);
        CopyField(81, 32000004, 13515);
        CopyField(181, 32000000, 13511);
        CopyField(181, 32000001, 13512);
        CopyField(181, 32000002, 13513);
        CopyField(181, 32000003, 13514);
        CopyField(181, 32000004, 13515);
        CopyField(3, 32000001, 13516);
        CopyField(38, 32000000, 13512);
        CopyField(38, 32000001, 13513);
        CopyField(38, 32000002, 13514);
        CopyField(122, 32000000, 13512);
        CopyField(122, 32000001, 13513);
        CopyField(122, 32000002, 13514);
        CopyField(317, 32000000, 13517);
        CopyField(25, 32000000, 13512);
        CopyField(25, 32000001, 13513);
        CopyField(25, 32000002, 13514);
        CopyField(25, 32000003, 13515);
        CopyField(312, 32000000, 13519);
        CopyField(23, 32000000, 13520);
        CopyField(288, 13400, 13521);
        CopyField(288, 32000001, 13522);
        CopyField(1383, 32000000, 13520);
        CopyField(287, 32000001, 13522);
        CopyField(112, 32000000, 13511);
        CopyField(21, 32000000, 13511);
        CopyField(21, 32000001, 13516);
        CopyField(297, 32000000, 13511);
        CopyField(298, 32000000, 13511);
        CopyField(296, 32000000, 13511);
        CopyField(311, 32000000, 13523);
        CopyField(311, 32000001, 13524);
        CopyField(311, 32000002, 13525);
        CopyField(311, 32000003, 13526);
        CopyField(311, 32000004, 13527);
        CopyField(311, 32000005, 13528);
        CopyField(5992, 32000000, 13511);
    end;

    local procedure CopyField(TableId: Integer; SourceFieldId: Integer; TargetFieldId: Integer)
    var
        Source: RecordRef;
        Transfer: DataTransfer;
    begin
        Source.Open(TableId);
        if not Source.FieldExist(SourceFieldId) then
            Error(MissingSchemaErr, TableId, SourceFieldId);
        Source.Close();
        Transfer.SetTables(TableId, TableId);
        Transfer.AddFieldValue(SourceFieldId, TargetFieldId);
        Transfer.UpdateAuditFields(false);
        Transfer.CopyFields();
    end;

    local procedure CopyTable(SourceTableId: Integer; TargetTableId: Integer)
    var
        Source: RecordRef;
        Target: RecordRef;
        SourceField: FieldRef;
        TargetField: FieldRef;
        PrimaryKey: KeyRef;
        Transfer: DataTransfer;
        FieldIndex: Integer;
        SystemFieldId: Integer;
        KeyIndex: Integer;
    begin
        Source.Open(SourceTableId);
        Target.Open(TargetTableId);
        Source.LockTable();
        Target.LockTable();
        if Source.FindSet() then
            repeat
                Target.Init();
                PrimaryKey := Source.KeyIndex(1);
                for KeyIndex := 1 to PrimaryKey.FieldCount() do begin
                    SourceField := PrimaryKey.FieldIndex(KeyIndex);
                    TargetField := Target.Field(SourceField.Number);
                    TargetField.Value := SourceField.Value;
                end;
                if Target.Find('=') then
                    ValidateMatchingRow(Source, Target)
                else begin
                    TargetField := Target.Field(2000000000);
                    TargetField.SetRange(Source.Field(2000000000).Value);
                    if Target.FindFirst() then
                        Error(ConflictErr, TargetTableId, Format(Target.RecordId), 2000000000);
                    TargetField.SetRange();
                    Clear(Transfer);
                    Transfer.SetTables(SourceTableId, TargetTableId);
                    for FieldIndex := 1 to Source.FieldCount() do begin
                        SourceField := Source.FieldIndex(FieldIndex);
                        if IsBusinessField(SourceField) then
                            Transfer.AddFieldValue(SourceField.Number, SourceField.Number);
                    end;
                    // CopyRows supports identity and audit fields, but not rowversion/timestamp.
                    for SystemFieldId := 2000000000 to 2000000004 do
                        Transfer.AddFieldValue(SystemFieldId, SystemFieldId);
                    for KeyIndex := 1 to PrimaryKey.FieldCount() do begin
                        SourceField := PrimaryKey.FieldIndex(KeyIndex);
                        Transfer.AddSourceFilter(SourceField.Number, '=%1', SourceField.Value);
                    end;
                    Transfer.CopyRows();
                end;
            until Source.Next() = 0;
        Target.Close();
        Source.Close();
    end;

    internal procedure ValidateMatchingRow(Source: RecordRef; Target: RecordRef)
    var
        SourceField: FieldRef;
        TargetField: FieldRef;
        FieldIndex: Integer;
        SystemFieldId: Integer;
    begin
        for FieldIndex := 1 to Source.FieldCount() do begin
            SourceField := Source.FieldIndex(FieldIndex);
            if IsBusinessField(SourceField) then begin
                TargetField := Target.Field(SourceField.Number);
                if TargetField.Value <> SourceField.Value then
                    Error(ConflictErr, Target.Number(), Format(Target.RecordId), SourceField.Number);
            end;
        end;
        for SystemFieldId := 2000000000 to 2000000004 do begin
            SourceField := Source.Field(SystemFieldId);
            TargetField := Target.Field(SystemFieldId);
            if TargetField.Value <> SourceField.Value then
                Error(ConflictErr, Target.Number(), Format(Target.RecordId), SystemFieldId);
        end;
    end;

    local procedure IsBusinessField(SourceField: FieldRef): Boolean
    begin
        exit((SourceField.Class = FieldClass::Normal) and
             (SourceField.Number > 0) and (SourceField.Number < 2000000000));
    end;

    local procedure RemapStoredObjects()
    begin
        RemapCodeunit(32000002, 13511);
        RemapCodeunit(13413, 13513);
        RemapCodeunit(13403, 13515);
        RemapCodeunit(32000000, 13526);
        RemapCodeunit(13410, 13535);
        RemapReport(13413, 13514);
        RemapReport(13403, 13516);
        RemapReport(32000001, 13524);
        RemapReport(32000003, 13527);
        RemapReport(32000006, 13528);
        RemapReport(32000004, 13529);
        RemapReport(32000000, 13530);
        RemapReport(32000005, 13531);
    end;

    local procedure RemapCodeunit(OldId: Integer; NewId: Integer)
    begin
        RemapIntegerField(1200, 4, OldId, NewId, 0, 0);
        RemapIntegerField(1200, 11, OldId, NewId, 0, 0);
        RemapIntegerField(472, 8, OldId, NewId, 7, 5);
    end;

    local procedure RemapReport(OldId: Integer; NewId: Integer)
    begin
        ValidateReportLayouts(OldId, NewId);
        CopyCustomReportLayouts(OldId, NewId);
        CopyLayoutSelections(OldId, NewId);
        RemapReportSelections(OldId, NewId);
        RemapIntegerField(472, 8, OldId, NewId, 7, 3);
    end;

    local procedure ValidateStoredReportLayouts()
    var
        CustomLayout: Record "Custom Report Layout";
        Selection: Record "Report Layout Selection";
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
    begin
        CustomLayout.LockTable();
        Selection.LockTable();
        ReportSelections.LockTable();
        CustomReportSelection.LockTable();
        ValidateReportLayouts(13413, 13514);
        ValidateReportLayouts(13403, 13516);
        ValidateReportLayouts(32000001, 13524);
        ValidateReportLayouts(32000003, 13527);
        ValidateReportLayouts(32000006, 13528);
        ValidateReportLayouts(32000004, 13529);
        ValidateReportLayouts(32000000, 13530);
        ValidateReportLayouts(32000005, 13531);
    end;

    internal procedure ValidateReportLayouts(OldId: Integer; NewId: Integer)
    var
        CustomLayout: Record "Custom Report Layout";
        PlannedLayout: Record "Custom Report Layout" temporary;
        TargetLayout: Record "Custom Report Layout";
        Selection: Record "Report Layout Selection";
        PlannedSelection: Record "Report Layout Selection" temporary;
        TargetSelection: Record "Report Layout Selection";
        TenantLayout: Record "Tenant Report Layout";
        TenantSelection: Record "Tenant Report Layout Selection";
        TenantLayoutCfg: Record "Tenant Report Layout Cfg";
        ReportSelections: Record "Report Selections";
        PlannedReportSelection: Record "Report Selections" temporary;
        CustomReportSelection: Record "Custom Report Selection";
        PlannedCustomSelection: Record "Custom Report Selection" temporary;
    begin
        CustomLayout.SetRange("Report ID", OldId);
        CustomLayout.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if CustomLayout.FindSet() then
            repeat
                ValidateClassicLayoutConsumers(CustomLayout, NewId);
                PlanCustomReportLayout(CustomLayout, NewId, PlannedLayout);
                if TargetLayout.Get(PlannedLayout.Code) then
                    ValidateMatchingCustomLayout(PlannedLayout, TargetLayout);
            until CustomLayout.Next() = 0;

        // System-table layouts use Media and cannot be copied with DataTransfer.
        // Check both IDs: a pre-existing replacement override must not silently win.
        TenantLayout.SetFilter("Report ID", '%1|%2', OldId, NewId);
        TenantLayout.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if TenantLayout.FindFirst() then
            Error(LayoutMigrationErr, OldId, NewId, TenantLayout.TableName(), Format(TenantLayout.RecordId));
        TenantSelection.SetFilter("Report ID", '%1|%2', OldId, NewId);
        TenantSelection.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if TenantSelection.FindFirst() then
            Error(LayoutMigrationErr, OldId, NewId, TenantSelection.TableName(), Format(TenantSelection.RecordId));
        TenantLayoutCfg.SetFilter("Report ID", '%1|%2', OldId, NewId);
        TenantLayoutCfg.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if TenantLayoutCfg.FindFirst() then
            Error(LayoutMigrationErr, OldId, NewId, TenantLayoutCfg.TableName(), Format(TenantLayoutCfg.RecordId));

        ReportSelections.SetRange("Report ID", OldId);
        if ReportSelections.FindSet() then
            repeat
                PlanReportSelection(ReportSelections, NewId, PlannedReportSelection);
            until ReportSelections.Next() = 0;
        CustomReportSelection.SetRange("Report ID", OldId);
        if CustomReportSelection.FindSet() then
            repeat
                PlanCustomReportSelection(CustomReportSelection, NewId, PlannedCustomSelection);
            until CustomReportSelection.Next() = 0;

        Selection.SetRange("Report ID", OldId);
        Selection.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if Selection.FindSet() then
            repeat
                PlanLayoutSelection(Selection, NewId, PlannedSelection);
                if TargetSelection.Get(NewId, Selection."Company Name") then
                    ValidateMatchingLayoutSelection(PlannedSelection, TargetSelection);
            until Selection.Next() = 0;
        // An explicit replacement override must not silently replace an implicit
        // legacy default or introduce a company override of a shared choice.
        TargetSelection.SetRange("Report ID", NewId);
        TargetSelection.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if TargetSelection.FindSet() then
            repeat
                if not Selection.Get(OldId, TargetSelection."Company Name") then
                    Error(ConflictErr, Database::"Report Layout Selection", Format(TargetSelection.RecordId), TargetSelection.FieldNo(Type));
            until TargetSelection.Next() = 0;
    end;

    internal procedure PlanCustomReportLayout(Source: Record "Custom Report Layout"; NewId: Integer; var Planned: Record "Custom Report Layout" temporary)
    var
        LayoutBlob: Codeunit "Temp Blob";
        SourceRef: RecordRef;
        SourceField: FieldRef;
        FieldIndex: Integer;
        Input: InStream;
        Output: OutStream;
    begin
        // Only these two pairs have printable datasets: 32 and 31 unchanged
        // columns respectively. Mapped table fields retain their names/types;
        // CustLedgerEntryReferenceNo remains Code[20]. The other six pairs are
        // processing-only. Word binds to the old report namespace, so is not copied.
        // Validate each RDLC too: report extensions/custom fields are not implied
        // compatible by identical built-in layouts.
        if not (((Source."Report ID" = 32000001) and (NewId = 13524)) or
                ((Source."Report ID" = 32000005) and (NewId = 13531))) or
           (Source.Type <> Source.Type::RDLC) or Source."Built-In"
        then
            Error(LayoutMigrationErr, Source."Report ID", NewId, Source.TableName(), Format(Source.RecordId));
        SourceRef.GetTable(Source);
        for FieldIndex := 1 to SourceRef.FieldCount() do begin
            SourceField := SourceRef.FieldIndex(FieldIndex);
            if IsBusinessField(SourceField) then
                if (SourceField.Type in [FieldType::Media, FieldType::MediaSet]) or
                   ((SourceField.Type = FieldType::Blob) and
                    not (SourceField.Number in [Source.FieldNo(Layout), Source.FieldNo("Custom XML Part")]))
                then
                    Error(SelectionFieldTypeErr, SourceField.Number);
        end;
        Source.CalcFields(Layout, "Custom XML Part");
        Source.GetLayoutBlob(LayoutBlob);
        if not LayoutBlob.HasValue() then
            Error(LayoutMigrationErr, Source."Report ID", NewId, Source.TableName(), Format(Source.RecordId));

        Planned.Reset();
        Planned.DeleteAll();
        Planned := Source;
        Planned.Code := GetMappedLayoutCode(Source);
        Planned."Report ID" := NewId;
        Clear(Planned.SystemId);
        Clear(Planned.Layout);
        Clear(Planned."Custom XML Part");
        LayoutBlob.CreateInStream(Input);
        Planned.Layout.CreateOutStream(Output);
        CopyStream(Output, Input);
        if Source."Custom XML Part".HasValue() then begin
            Source."Custom XML Part".CreateInStream(Input);
            Planned."Custom XML Part".CreateOutStream(Output);
            CopyStream(Output, Input);
        end;
        Planned.Insert(false);
        ClearLastError();
        if not TryValidateClassicLayout(Planned) then
            Error(LayoutValidationErr, Source."Report ID", NewId, Source.Code, GetLastErrorText());
        // Temporary insertion assigns an identity. The persistent counterpart
        // must obtain its own identity without touching the original's audit.
        Clear(Planned.SystemId);
    end;

    local procedure ValidateClassicLayoutConsumers(Source: Record "Custom Report Layout"; NewId: Integer)
    var
        Selection: Record "Report Layout Selection";
        ReportSelections: Record "Report Selections";
        CustomSelection: Record "Custom Report Selection";
    begin
        Selection.SetFilter("Report ID", '<>%1', Source."Report ID");
        Selection.SetFilter("Company Name", '%1|%2', '', CompanyName());
        Selection.SetRange("Custom Report Layout Code", Source.Code);
        if Selection.FindFirst() then
            Error(LayoutMigrationErr, Source."Report ID", NewId, Selection.TableName(), Format(Selection.RecordId));
        ReportSelections.SetFilter("Report ID", '<>%1', Source."Report ID");
        ReportSelections.SetRange("Custom Report Layout Code", Source.Code);
        if ReportSelections.FindFirst() then
            Error(LayoutMigrationErr, Source."Report ID", NewId, ReportSelections.TableName(), Format(ReportSelections.RecordId));
        ReportSelections.SetRange("Custom Report Layout Code");
        ReportSelections.SetRange("Email Body Layout Code", Source.Code);
        if ReportSelections.FindFirst() then
            Error(LayoutMigrationErr, Source."Report ID", NewId, ReportSelections.TableName(), Format(ReportSelections.RecordId));
        CustomSelection.SetFilter("Report ID", '<>%1', Source."Report ID");
        CustomSelection.SetRange("Custom Report Layout Code", Source.Code);
        if CustomSelection.FindFirst() then
            Error(LayoutMigrationErr, Source."Report ID", NewId, CustomSelection.TableName(), Format(CustomSelection.RecordId));
        CustomSelection.SetRange("Custom Report Layout Code");
        CustomSelection.SetRange("Email Body Layout Code", Source.Code);
        if CustomSelection.FindFirst() then
            Error(LayoutMigrationErr, Source."Report ID", NewId, CustomSelection.TableName(), Format(CustomSelection.RecordId));
    end;

    [TryFunction]
    local procedure TryValidateClassicLayout(var Planned: Record "Custom Report Layout" temporary)
    begin
        // Public OnPrem API, matching this app's target. Unlike ImportLayoutBlob,
        // this neither updates bytes nor commits and never displays a confirm.
        if not Planned.ValidateLayout(false, false) then
            Error(EmptyLayoutErr);
    end;

    internal procedure GetMappedLayoutCode(Source: Record "Custom Report Layout"): Code[20]
    var
        Cryptography: Codeunit "Cryptography Management";
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        // Source codes are tenant-wide unique. Never choose another code on a
        // collision: validation must reject a nonidentical existing counterpart.
        exit(CopyStr('FI' + Cryptography.GenerateHash(Source.Code, HashAlgorithm::SHA256), 1, 20));
    end;

    internal procedure ValidateMatchingCustomLayout(Planned: Record "Custom Report Layout"; Target: Record "Custom Report Layout")
    var
        PlannedRef: RecordRef;
        TargetRef: RecordRef;
        PlannedField: FieldRef;
        TargetField: FieldRef;
        FieldIndex: Integer;
    begin
        PlannedRef.GetTable(Planned);
        TargetRef.GetTable(Target);
        for FieldIndex := 1 to PlannedRef.FieldCount() do begin
            PlannedField := PlannedRef.FieldIndex(FieldIndex);
            if IsBusinessField(PlannedField) then begin
                TargetField := TargetRef.Field(PlannedField.Number);
                case PlannedField.Type of
                    FieldType::Blob:
                        ValidateMatchingLayoutBlob(PlannedRef, TargetRef, PlannedField.Number);
                    FieldType::Media, FieldType::MediaSet:
                        Error(SelectionFieldTypeErr, PlannedField.Number);
                    else
                        if TargetField.Value <> PlannedField.Value then
                            Error(ConflictErr, TargetRef.Number(), Format(TargetRef.RecordId), PlannedField.Number);
                end;
            end;
        end;
    end;

    local procedure ValidateMatchingLayoutBlob(Planned: RecordRef; Target: RecordRef; FieldId: Integer)
    var
        PlannedBlob: Codeunit "Temp Blob";
        TargetBlob: Codeunit "Temp Blob";
        Cryptography: Codeunit "Cryptography Management";
        PlannedInput: InStream;
        TargetInput: InStream;
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        PlannedBlob.FromRecordRef(Planned, FieldId);
        TargetBlob.FromRecordRef(Target, FieldId);
        if PlannedBlob.Length() <> TargetBlob.Length() then
            Error(ConflictErr, Target.Number(), Format(Target.RecordId), FieldId);
        if not PlannedBlob.HasValue() then
            exit;
        PlannedBlob.CreateInStream(PlannedInput);
        TargetBlob.CreateInStream(TargetInput);
        if Cryptography.GenerateHash(PlannedInput, HashAlgorithm::SHA256) <>
           Cryptography.GenerateHash(TargetInput, HashAlgorithm::SHA256)
        then
            Error(ConflictErr, Target.Number(), Format(Target.RecordId), FieldId);
    end;

    local procedure CopyCustomReportLayouts(OldId: Integer; NewId: Integer)
    var
        Source: Record "Custom Report Layout";
        Planned: Record "Custom Report Layout" temporary;
        Target: Record "Custom Report Layout";
    begin
        Source.SetRange("Report ID", OldId);
        Source.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if Source.FindSet() then
            repeat
                PlanCustomReportLayout(Source, NewId, Planned);
                if Target.Get(Planned.Code) then
                    ValidateMatchingCustomLayout(Planned, Target)
                else begin
                    Target := Planned;
                    Target.Insert(false);
                end;
            until Source.Next() = 0;
    end;

    local procedure MapLayoutReference(LayoutCode: Code[20]; OldId: Integer; NewId: Integer; ScopeCompany: Text[30]): Code[20]
    var
        Source: Record "Custom Report Layout";
    begin
        if LayoutCode = '' then
            exit('');
        if not Source.Get(LayoutCode) then
            Error(LayoutReferenceErr, LayoutCode, OldId, NewId, ScopeCompany);
        if (Source."Report ID" <> OldId) or
           ((Source."Company Name" <> '') and (Source."Company Name" <> ScopeCompany))
        then
            Error(LayoutReferenceErr, LayoutCode, OldId, NewId, ScopeCompany);
        exit(GetMappedLayoutCode(Source));
    end;

    internal procedure PlanLayoutSelection(Source: Record "Report Layout Selection"; NewId: Integer; var Planned: Record "Report Layout Selection")
    var
        SourceRef: RecordRef;
    begin
        if Source.Type <> Source.Type::"Custom Layout" then begin
            PlanBuiltInLayoutSelection(Source, NewId, Planned);
            exit;
        end;
        if Source."Custom Report Layout Code" = '' then
            Error(LayoutMigrationErr, Source."Report ID", NewId, Source.TableName(), Format(Source.RecordId));
        SourceRef.GetTable(Source);
        ValidateSelectionFieldTypes(SourceRef);
        Planned := Source;
        Planned."Report ID" := NewId;
        Planned."Custom Report Layout Code" := MapLayoutReference(Source."Custom Report Layout Code", Source."Report ID", NewId, Source."Company Name");
        Clear(Planned.SystemId);
    end;

    internal procedure PlanReportSelection(Source: Record "Report Selections"; NewId: Integer; var Planned: Record "Report Selections")
    begin
        if (Source."Email Body Layout Name" <> '') or (Source."Report Layout Name" <> '') or
           not IsNullGuid(Source."Email Body Layout AppID") or not IsNullGuid(Source."Report Layout AppID") or
           ((Source."Email Body Layout Code" <> '') and (Source."Email Body Layout Type" <> Source."Email Body Layout Type"::"Custom Report Layout"))
        then
            Error(LayoutMigrationErr, Source."Report ID", NewId, Source.TableName(), Format(Source.RecordId));
        Planned := Source;
        Planned."Report ID" := NewId;
        Planned."Custom Report Layout Code" := MapLayoutReference(Source."Custom Report Layout Code", Source."Report ID", NewId, CopyStr(CompanyName(), 1, 30));
        Planned."Email Body Layout Code" := MapLayoutReference(Source."Email Body Layout Code", Source."Report ID", NewId, CopyStr(CompanyName(), 1, 30));
    end;

    internal procedure PlanCustomReportSelection(Source: Record "Custom Report Selection"; NewId: Integer; var Planned: Record "Custom Report Selection")
    begin
        if (Source."Email Body Layout Name" <> '') or (Source."Email Attachment Layout Name" <> '') or
           not IsNullGuid(Source."Email Body Layout AppID") or not IsNullGuid(Source."Email Attachment Layout AppID")
        then
            Error(LayoutMigrationErr, Source."Report ID", NewId, Source.TableName(), Format(Source.RecordId));
        Source.CalcFields("Selected Contacts Filter");
        Planned := Source;
        Planned."Report ID" := NewId;
        Planned."Custom Report Layout Code" := MapLayoutReference(Source."Custom Report Layout Code", Source."Report ID", NewId, CopyStr(CompanyName(), 1, 30));
        Planned."Email Body Layout Code" := MapLayoutReference(Source."Email Body Layout Code", Source."Report ID", NewId, CopyStr(CompanyName(), 1, 30));
    end;

    local procedure RemapReportSelections(OldId: Integer; NewId: Integer)
    var
        Source: Record "Report Selections";
        Planned: Record "Report Selections" temporary;
        CustomSource: Record "Custom Report Selection";
        CustomPlanned: Record "Custom Report Selection" temporary;
        SourceRef: RecordRef;
    begin
        Source.SetRange("Report ID", OldId);
        if Source.FindSet() then
            repeat
                PlanReportSelection(Source, NewId, Planned);
                SourceRef.GetTable(Source);
                RemapSelectionRow(SourceRef, Source.FieldNo("Report ID"), NewId, Planned."Custom Report Layout Code", Planned."Email Body Layout Code");
            until Source.Next() = 0;
        CustomSource.SetRange("Report ID", OldId);
        if CustomSource.FindSet() then
            repeat
                PlanCustomReportSelection(CustomSource, NewId, CustomPlanned);
                SourceRef.GetTable(CustomSource);
                RemapSelectionRow(SourceRef, CustomSource.FieldNo("Report ID"), NewId, CustomPlanned."Custom Report Layout Code", CustomPlanned."Email Body Layout Code");
            until CustomSource.Next() = 0;
    end;

    local procedure RemapSelectionRow(Source: RecordRef; ReportFieldId: Integer; NewId: Integer; LayoutCode: Code[20]; BodyLayoutCode: Code[20])
    var
        Transfer: DataTransfer;
        PrimaryKey: KeyRef;
        KeyField: FieldRef;
        KeyIndex: Integer;
    begin
        Transfer.SetTables(Source.Number(), Source.Number());
        Transfer.AddConstantValue(NewId, ReportFieldId);
        Transfer.AddConstantValue(LayoutCode, 7);
        Transfer.AddConstantValue(BodyLayoutCode, 21);
        PrimaryKey := Source.KeyIndex(1);
        for KeyIndex := 1 to PrimaryKey.FieldCount() do begin
            KeyField := PrimaryKey.FieldIndex(KeyIndex);
            Transfer.AddSourceFilter(KeyField.Number, '=%1', KeyField.Value);
        end;
        // Change only the three references. Contact BLOBs, email flags, scope,
        // identity and historical audit stamps remain on the existing selector.
        Transfer.UpdateAuditFields(false);
        Transfer.CopyFields();
    end;

    internal procedure PlanBuiltInLayoutSelection(Source: Record "Report Layout Selection"; NewReportId: Integer; var Planned: Record "Report Layout Selection")
    var
        SourceRef: RecordRef;
    begin
        if (Source.Type = Source.Type::"Custom Layout") or (Source."Custom Report Layout Code" <> '') then
            Error(LayoutMigrationErr, Source."Report ID", NewReportId, Source.TableName(), Format(Source.RecordId));
        SourceRef.GetTable(Source);
        ValidateSelectionFieldTypes(SourceRef);
        Planned := Source;
        Planned."Report ID" := NewReportId;
        // Validate the same choice against the replacement report, not its default.
        Planned.Validate(Type, Source.Type);
        Planned."Report Name" := Source."Report Name";
        Clear(Planned.SystemId);
    end;

    internal procedure ValidateMatchingLayoutSelection(Planned: Record "Report Layout Selection"; Target: Record "Report Layout Selection")
    var
        PlannedRef: RecordRef;
        TargetRef: RecordRef;
        PlannedField: FieldRef;
        TargetField: FieldRef;
        FieldIndex: Integer;
        SystemFieldId: Integer;
    begin
        PlannedRef.GetTable(Planned);
        TargetRef.GetTable(Target);
        ValidateSelectionFieldTypes(PlannedRef);
        for FieldIndex := 1 to PlannedRef.FieldCount() do begin
            PlannedField := PlannedRef.FieldIndex(FieldIndex);
            if IsBusinessField(PlannedField) then begin
                TargetField := TargetRef.Field(PlannedField.Number);
                if TargetField.Value <> PlannedField.Value then
                    Error(ConflictErr, TargetRef.Number(), Format(TargetRef.RecordId), PlannedField.Number);
            end;
        end;
        // The counterpart has a different key in the same table, so its SystemId
        // must be distinct. Its historical audit fields must still match.
        for SystemFieldId := 2000000001 to 2000000004 do begin
            PlannedField := PlannedRef.Field(SystemFieldId);
            TargetField := TargetRef.Field(SystemFieldId);
            if TargetField.Value <> PlannedField.Value then
                Error(ConflictErr, TargetRef.Number(), Format(TargetRef.RecordId), SystemFieldId);
        end;
    end;

    local procedure ValidateSelectionFieldTypes(Selection: RecordRef)
    var
        SelectionField: FieldRef;
        FieldIndex: Integer;
    begin
        for FieldIndex := 1 to Selection.FieldCount() do begin
            SelectionField := Selection.FieldIndex(FieldIndex);
            if IsBusinessField(SelectionField) then
                if SelectionField.Type in [FieldType::Blob, FieldType::Media, FieldType::MediaSet] then
                    Error(SelectionFieldTypeErr, SelectionField.Number);
        end;
    end;

    local procedure CopyLayoutSelections(OldId: Integer; NewId: Integer)
    var
        Selection: Record "Report Layout Selection";
        PlannedSelection: Record "Report Layout Selection";
        TargetSelection: Record "Report Layout Selection";
        SelectionRef: RecordRef;
        SelectionField: FieldRef;
        Transfer: DataTransfer;
        FieldIndex: Integer;
        SystemFieldId: Integer;
    begin
        Selection.LockTable();
        Selection.SetRange("Report ID", OldId);
        Selection.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if Selection.FindSet() then
            repeat
                PlanLayoutSelection(Selection, NewId, PlannedSelection);
                if TargetSelection.Get(NewId, Selection."Company Name") then
                    ValidateMatchingLayoutSelection(PlannedSelection, TargetSelection)
                else begin
                    Clear(Transfer);
                    Transfer.SetTables(Database::"Report Layout Selection", Database::"Report Layout Selection");
                    SelectionRef.GetTable(Selection);
                    for FieldIndex := 1 to SelectionRef.FieldCount() do begin
                        SelectionField := SelectionRef.FieldIndex(FieldIndex);
                        if IsBusinessField(SelectionField) and
                           not (SelectionField.Number in [Selection.FieldNo("Report ID"), Selection.FieldNo("Custom Report Layout Code")])
                        then
                            Transfer.AddFieldValue(SelectionField.Number, SelectionField.Number);
                    end;
                    Transfer.AddConstantValue(NewId, Selection.FieldNo("Report ID"));
                    Transfer.AddConstantValue(PlannedSelection."Custom Report Layout Code", Selection.FieldNo("Custom Report Layout Code"));
                    Transfer.AddConstantValue(CreateGuid(), 2000000000);
                    for SystemFieldId := 2000000001 to 2000000004 do
                        Transfer.AddFieldValue(SystemFieldId, SystemFieldId);
                    Transfer.AddSourceFilter(Selection.FieldNo("Report ID"), '=%1', OldId);
                    Transfer.AddSourceFilter(Selection.FieldNo("Company Name"), '=%1', Selection."Company Name");
                    Transfer.CopyRows();
                end;
            until Selection.Next() = 0;
    end;

    local procedure RemapIntegerField(TableId: Integer; FieldId: Integer; OldId: Integer; NewId: Integer; TypeFieldId: Integer; TypeValue: Integer)
    var
        Transfer: DataTransfer;
    begin
        Transfer.SetTables(TableId, TableId);
        Transfer.AddSourceFilter(FieldId, '=%1', OldId);
        if TypeFieldId <> 0 then
            Transfer.AddSourceFilter(TypeFieldId, '=%1', TypeValue);
        Transfer.AddConstantValue(NewId, FieldId);
        Transfer.UpdateAuditFields(false);
        Transfer.CopyFields();
    end;

    var
        LifecycleRequiredErr: Label 'Finnish banking historical data can only be copied during an actual app install or upgrade. Prepare and perform the controlled tenant-exclusive upgrade.';
        SkippedMigrationErr: Label 'The Finnish banking migration tag is marked skipped. Recover and verify the actual lifecycle migration explicitly; a skipped tag is not proof of completed migration.';
        MissingSchemaErr: Label 'Cannot migrate Finnish banking: retained field %2 on table %1 is missing. Restore the retained schema and verify migration before CLEANSCHEMA33.', Comment = '%1 = table ID, %2 = field ID';
        ConflictErr: Label 'Cannot migrate Finnish banking: table %1, record %2, field %3 conflicts with existing replacement data. Resolve the conflicting record before retrying.', Comment = '%1 = table ID, %2 = record ID, %3 = field ID';
        LayoutMigrationErr: Label 'Cannot migrate Finnish banking report %1 to %2: %3, record %4 requires an approved audit-preserving layout-content and selection mapping that this release does not provide for unsupported customizations. Automatic migration supports only non-built-in classic RDLC layouts for reports 32000001 and 32000005 that validate against their replacement datasets. Word, built-in classic, processing-only and tenant/named layout customizations are unsupported. This release cannot complete cutover with unsupported layout originals or selections. Originals, content and selections are preserved. Export this layout and its shared/company/user print and email selections for compatibility assessment; export/adapt/import/reselect alone does not unblock this release. Defer cutover until a supported migration is available.', Comment = '%1 = legacy report ID, %2 = replacement report ID, %3 = layout table name, %4 = layout record ID';
        LayoutValidationErr: Label 'Cannot migrate Finnish banking report %1 to %2, classic layout %3: %4. Original content and selections are unchanged. This release cannot complete cutover with this incompatible layout original. Export the layout and its selections for compatibility assessment; export/adapt/import/reselect alone does not unblock this release. The original is preserved. Defer cutover until a supported migration is available.', Comment = '%1 = legacy report ID, %2 = replacement report ID, %3 = layout code, %4 = public layout validation error';
        LayoutReferenceErr: Label 'Cannot migrate Finnish banking layout %1 from report %2 to %3 for company scope "%4": the original layout is missing, belongs to another report or is outside this scope. Originals are preserved. Correct the print/email reference to a compatible existing original layout before retrying the controlled upgrade. Unsupported Word/named/tenant originals remain cutover blockers in this release.', Comment = '%1 = layout code, %2 = legacy report ID, %3 = replacement report ID, %4 = company scope (blank means shared)';
        EmptyLayoutErr: Label 'The public report layout validator did not accept the layout content.';
        SelectionFieldTypeErr: Label 'Cannot copy Finnish banking report layout selections: field %1 contains unsupported BLOB or Media data. This release cannot complete cutover with this unsupported layout field. Originals are preserved; export/adapt/import/reselect alone does not unblock this release. Defer cutover until a supported migration is available.', Comment = '%1 = field ID';
}

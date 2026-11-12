// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.Setup;
using Microsoft.Foundation.Reporting;
using System.Reflection;
using System.Upgrade;

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
        CopyBuiltInLayoutSelections(OldId, NewId);
        RemapIntegerField(77, 3, OldId, NewId, 0, 0);
        RemapIntegerField(9657, 5, OldId, NewId, 0, 0);
        RemapIntegerField(472, 8, OldId, NewId, 7, 3);
    end;

    internal procedure ValidateReportLayouts(OldId: Integer; NewId: Integer)
    var
        CustomLayout: Record "Custom Report Layout";
        Selection: Record "Report Layout Selection";
        PlannedSelection: Record "Report Layout Selection";
        TargetSelection: Record "Report Layout Selection";
        TenantLayout: Record "Tenant Report Layout";
        TenantSelection: Record "Tenant Report Layout Selection";
        TenantLayoutCfg: Record "Tenant Report Layout Cfg";
        ReportSelections: Record "Report Selections";
        CustomReportSelection: Record "Custom Report Selection";
    begin
        CustomLayout.SetRange("Report ID", OldId);
        CustomLayout.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if CustomLayout.FindFirst() then
            Error(LayoutMigrationErr, OldId, NewId, CustomLayout.TableName(), Format(CustomLayout.RecordId));

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
                if (ReportSelections."Custom Report Layout Code" <> '') or
                   (ReportSelections."Email Body Layout Code" <> '') or
                   (ReportSelections."Email Body Layout Name" <> '') or
                   (ReportSelections."Report Layout Name" <> '') or
                   not IsNullGuid(ReportSelections."Email Body Layout AppID") or
                   not IsNullGuid(ReportSelections."Report Layout AppID")
                then
                    Error(LayoutMigrationErr, OldId, NewId, ReportSelections.TableName(), Format(ReportSelections.RecordId));
            until ReportSelections.Next() = 0;
        CustomReportSelection.SetRange("Report ID", OldId);
        if CustomReportSelection.FindSet() then
            repeat
                if (CustomReportSelection."Custom Report Layout Code" <> '') or
                   (CustomReportSelection."Email Body Layout Code" <> '') or
                   (CustomReportSelection."Email Body Layout Name" <> '') or
                   (CustomReportSelection."Email Attachment Layout Name" <> '') or
                   not IsNullGuid(CustomReportSelection."Email Body Layout AppID") or
                   not IsNullGuid(CustomReportSelection."Email Attachment Layout AppID")
                then
                    Error(LayoutMigrationErr, OldId, NewId, CustomReportSelection.TableName(), Format(CustomReportSelection.RecordId));
            until CustomReportSelection.Next() = 0;

        Selection.SetRange("Report ID", OldId);
        Selection.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if Selection.FindSet() then
            repeat
                PlanBuiltInLayoutSelection(Selection, NewId, PlannedSelection);
                if TargetSelection.Get(NewId, Selection."Company Name") then
                    ValidateMatchingLayoutSelection(PlannedSelection, TargetSelection);
            until Selection.Next() = 0;
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

    local procedure CopyBuiltInLayoutSelections(OldId: Integer; NewId: Integer)
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
                PlanBuiltInLayoutSelection(Selection, NewId, PlannedSelection);
                if TargetSelection.Get(NewId, Selection."Company Name") then
                    ValidateMatchingLayoutSelection(PlannedSelection, TargetSelection)
                else begin
                    Clear(Transfer);
                    Transfer.SetTables(Database::"Report Layout Selection", Database::"Report Layout Selection");
                    SelectionRef.GetTable(Selection);
                    for FieldIndex := 1 to SelectionRef.FieldCount() do begin
                        SelectionField := SelectionRef.FieldIndex(FieldIndex);
                        if IsBusinessField(SelectionField) and (SelectionField.Number <> Selection.FieldNo("Report ID")) then
                            Transfer.AddFieldValue(SelectionField.Number, SelectionField.Number);
                    end;
                    Transfer.AddConstantValue(NewId, Selection.FieldNo("Report ID"));
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
        LayoutMigrationErr: Label 'Cannot migrate Finnish banking report %1 to %2: %3, record %4 requires an approved audit-preserving layout-content and selection mapping. Existing shared and company-specific layouts and choices have not been retargeted.', Comment = '%1 = legacy report ID, %2 = replacement report ID, %3 = layout table name, %4 = layout record ID';
        SelectionFieldTypeErr: Label 'Cannot copy Finnish banking report layout selections: field %1 contains BLOB or Media data and requires an approved audit-preserving copy contract.', Comment = '%1 = field ID';
}

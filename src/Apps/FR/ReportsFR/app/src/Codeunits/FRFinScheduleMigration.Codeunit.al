// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

#if CLEAN30
using Microsoft.Bank.Reports;
#endif
using System.IO;
using System.Upgrade;

codeunit 10846 "FR Fin. Schedule Migration"
{
    Access = Internal;
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions =
#if not CLEANSCHEMA33
#pragma warning disable AL0432, AS0105
                  tabledata "FR Acc. Schedule Name" = r,
                  tabledata "FR Acc. Schedule Line" = r,
#pragma warning restore AL0432, AS0105
#endif
                  tabledata "FR Financial Schedule Name" = rimd,
                  tabledata "FR Financial Schedule Line" = rimd,
                  tabledata "Config. Package Table" = rimd,
                  tabledata "Config. Package Field" = rimd,
                  tabledata "Config. Package Filter" = rimd,
                  tabledata "Config. Package Record" = rimd,
                  tabledata "Config. Package Data" = rimd,
                  tabledata "Config. Package Error" = rimd,
                  tabledata "Config. Field Map" = rimd,
                  tabledata "Config. Table Processing Rule" = rimd,
                  tabledata "Config. Line" = rm;

    var
        MigrationTagTok: Label 'MS-653672-FRFinancialSchedules-20261019', Locked = true;
#if not CLEANSCHEMA33
        ConflictErr: Label 'French financial schedule migration found a conflicting destination record in table %1. No schedules have been migrated. Reconcile the destination with the legacy configuration and retry.', Comment = '%1 = table caption';
        OrphanErr: Label 'French financial schedule migration found a line without a schedule header. Restore its legacy header and retry.';
        SchemaErr: Label 'French financial schedule migration cannot map field %1 from table %2. Update the dependent extension to provide the same stored field on the replacement schedule table before retrying.', Comment = '%1 = field number, %2 = source table caption';
        ExtensionMigrationErr: Label 'French financial schedule field %1 on table %2 requires an explicit extension data migration. Contact the extension publisher before retrying. No schedules have been migrated.', Comment = '%1 = field number, %2 = source table caption';
        LegacyReadOnlyErr: Label 'French financial schedules have been migrated. Use the Balance Sheet & Income Statement page in Reports FR to maintain them. The legacy schedule tables are read-only.';
        UnsupportedCompanyNameErr: Label 'The company name exceeds the supported migration-tag company-name length.';
#endif
        OrphanDestinationErr: Label 'French financial schedule migration found a destination line without a schedule header. Reconcile the destination configuration and retry.';
        ConfigConflictErr: Label 'A configuration package already contains the replacement French schedule table. Reconcile the legacy and replacement package definitions before retrying the migration.';
        ConfigRecordErr: Label 'A configuration-package error references a missing legacy schedule record. Resolve the package validation errors before retrying the migration.';

    trigger OnUpgradePerCompany()
#if CLEAN30
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
#endif
    begin
#if CLEAN30
        ReportLayoutsFR.MigrateCompanyData();
#endif
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure Migrate()
    var
#if not CLEANSCHEMA33
#pragma warning disable AL0432, AS0105
        LegacyName: Record "FR Acc. Schedule Name";
        LegacyLine: Record "FR Acc. Schedule Line";
#pragma warning restore AL0432, AS0105
#endif
        ScheduleName: Record "FR Financial Schedule Name";
        ScheduleLine: Record "FR Financial Schedule Line";
        UpgradeTag: Codeunit "Upgrade Tag";
#if not CLEANSCHEMA33
        SourceRef: RecordRef;
        TargetRef: RecordRef;
#endif
    begin
#if not CLEANSCHEMA33
        LegacyName.LockTable();
        LegacyLine.LockTable();
#endif
        ScheduleName.LockTable();
        ScheduleLine.LockTable();
        if IsMigrated() then
            exit;

#if not CLEANSCHEMA33
        SourceRef.GetTable(LegacyName);
        TargetRef.GetTable(ScheduleName);
        CheckSchema(SourceRef, TargetRef);
        SourceRef.GetTable(LegacyLine);
        TargetRef.GetTable(ScheduleLine);
        CheckSchema(SourceRef, TargetRef);

        if LegacyLine.FindSet() then
            repeat
                if not LegacyName.Get(LegacyLine."Schedule Name") then
                    Error(OrphanErr);
            until LegacyLine.Next() = 0;

        LegacyName.Reset();
        if LegacyName.FindSet() then
            repeat
                if ScheduleName.Get(LegacyName.Name) then begin
                    SourceRef.GetTable(LegacyName);
                    TargetRef.GetTable(ScheduleName);
                    CheckIdentical(SourceRef, TargetRef);
                end else begin
                    ScheduleName.Init();
                    ScheduleName.TransferFields(LegacyName);
                    ScheduleName.SystemId := LegacyName.SystemId;
                    ScheduleName.Insert(false, true);
                end;
            until LegacyName.Next() = 0;

        if LegacyLine.FindSet() then
            repeat
                if ScheduleLine.Get(LegacyLine."Schedule Name", LegacyLine."Line No.") then begin
                    SourceRef.GetTable(LegacyLine);
                    TargetRef.GetTable(ScheduleLine);
                    CheckIdentical(SourceRef, TargetRef);
                end else begin
                    ScheduleLine.Init();
                    ScheduleLine.TransferFields(LegacyLine);
                    ScheduleLine.SystemId := LegacyLine.SystemId;
                    ScheduleLine.Insert(false, true);
                end;
            until LegacyLine.Next() = 0;
#endif

        ScheduleLine.Reset();
        if ScheduleLine.FindSet() then
            repeat
                if not ScheduleName.Get(ScheduleLine."Schedule Name") then
                    Error(OrphanDestinationErr);
            until ScheduleLine.Next() = 0;

        MigrateConfigurationPackages('');
        OnBeforeCompleteMigration();
        UpgradeTag.SetUpgradeTag(GetUpgradeTag());
    end;

    procedure IsMigrated(): Boolean
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        exit(UpgradeTag.HasUpgradeTag(GetUpgradeTag()));
    end;

    procedure GetUpgradeTag(): Code[250]
    begin
        exit(MigrationTagTok);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    procedure MigrateConfigurationPackages(PackageCode: Code[20])
    begin
        RemapConfigurationTable(10800, Database::"FR Financial Schedule Name", PackageCode);
        RemapConfigurationTable(10801, Database::"FR Financial Schedule Line", PackageCode);
    end;

    local procedure RemapConfigurationTable(OldTableID: Integer; NewTableID: Integer; PackageCode: Code[20])
    var
        PackageTable: Record "Config. Package Table";
        PackageField: Record "Config. Package Field";
        ConfigLine: Record "Config. Line";
    begin
        RemapPackageRecords(Database::"Config. Package Table", OldTableID, NewTableID, PackageCode);
        RemapPackageRecords(Database::"Config. Package Field", OldTableID, NewTableID, PackageCode);
        RemapPackageRecords(Database::"Config. Package Filter", OldTableID, NewTableID, PackageCode);
        RemapPackageRecords(Database::"Config. Package Record", OldTableID, NewTableID, PackageCode);
        RemapPackageRecords(Database::"Config. Package Data", OldTableID, NewTableID, PackageCode);
        RemapPackageRecords(Database::"Config. Package Error", OldTableID, NewTableID, PackageCode);
        RemapFieldMaps(OldTableID, NewTableID, PackageCode);
        RemapPackageRecords(Database::"Config. Table Processing Rule", OldTableID, NewTableID, PackageCode);
        if PackageCode <> '' then begin
            PackageTable.SetRange("Package Code", PackageCode);
            PackageField.SetRange("Package Code", PackageCode);
            ConfigLine.SetRange("Package Code", PackageCode);
        end;
        PackageTable.SetRange("Parent Table ID", OldTableID);
        PackageTable.ModifyAll("Parent Table ID", NewTableID);
        PackageTable.SetRange("Parent Table ID");
        PackageTable.SetRange("Page ID", OldTableID);
        PackageTable.ModifyAll("Page ID", NewTableID);
        PackageField.SetRange("Relation Table ID", OldTableID);
        PackageField.ModifyAll("Relation Table ID", NewTableID);
        ConfigLine.SetRange("Table ID", OldTableID);
        ConfigLine.ModifyAll("Table ID", NewTableID);
        ConfigLine.SetRange("Table ID");
        ConfigLine.SetRange("Page ID", OldTableID);
        ConfigLine.ModifyAll("Page ID", NewTableID);
    end;

    local procedure RemapFieldMaps(OldTableID: Integer; NewTableID: Integer; PackageCode: Code[20])
    var
        Source: Record "Config. Field Map";
        Destination: Record "Config. Field Map";
    begin
        Source.LockTable();
        Source.SetRange("Table ID", OldTableID);
        if PackageCode <> '' then
            Source.SetRange("Package Code", PackageCode);
        if Source.FindSet(true) then
            repeat
                Destination.SetRange("Package Code", Source."Package Code");
                Destination.SetRange("Table ID", NewTableID);
                Destination.SetRange("Field ID", Source."Field ID");
                Destination.SetRange("Old Value", Source."Old Value");
                if not Destination.IsEmpty() then
                    Error(ConfigConflictErr);
                // Table ID is not part of this table's primary key; retain the mapping identity.
                Source."Table ID" := NewTableID;
                Source.Modify(false);
            until Source.Next() = 0;
    end;

    local procedure RemapPackageRecords(TableID: Integer; OldTableID: Integer; NewTableID: Integer; PackageCode: Code[20])
    var
        Source: RecordRef;
        Target: RecordRef;
        ExistingTarget: RecordRef;
        CurrentField: FieldRef;
        FieldIndex: Integer;
    begin
        Source.Open(TableID);
        Source.LockTable();
        Source.Field(2).SetRange(OldTableID);
        if PackageCode <> '' then
            Source.Field(1).SetRange(PackageCode);
        Target.Open(TableID);
        ExistingTarget.Open(TableID);
        if Source.FindSet() then
            repeat
                Target.Get(Source.RecordId());
                for FieldIndex := 1 to Target.FieldCount() do begin
                    CurrentField := Target.FieldIndex(FieldIndex);
                    if CurrentField.Type = FieldType::Blob then
                        CurrentField.CalcField();
                end;
                Target.Field(2).Value := NewTableID;
                if ExistingTarget.Get(Target.RecordId()) then
                    Error(ConfigConflictErr);
                if TableID = Database::"Config. Package Error" then
                    RemapErrorRecordID(Target, OldTableID, NewTableID);
                Source.Delete(false);
                Target.Insert(false, true);
            until Source.Next() = 0;
        Source.Close();
        Target.Close();
        ExistingTarget.Close();
    end;

    local procedure RemapErrorRecordID(var PackageError: RecordRef; OldTableID: Integer; NewTableID: Integer)
    var
        Source: RecordRef;
        Target: RecordRef;
        SourceRecordID: RecordId;
    begin
        SourceRecordID := PackageError.Field(9).Value;
        if SourceRecordID.TableNo() <> OldTableID then
            exit;
        Source.Open(OldTableID);
        if not Source.Get(SourceRecordID) then
            Error(ConfigRecordErr);
        Target.Open(NewTableID);
        if not Target.GetBySystemId(Source.Field(Source.SystemIdNo).Value) then
            Error(ConfigRecordErr);
        PackageError.Field(9).Value := Target.RecordId();
        Source.Close();
        Target.Close();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Config. XML Exchange", 'OnAfterImportPackageXMLDocument', '', false, false)]
    local procedure RemapImportedPackage(PackageCode: Code[20]; ExcelMode: Boolean; var Result: Boolean)
    begin
        if Result and IsMigrated() then
            MigrateConfigurationPackages(PackageCode);
    end;

#if not CLEANSCHEMA33
    local procedure CheckIdentical(SourceRef: RecordRef; TargetRef: RecordRef)
    var
        SourceField: FieldRef;
        TargetField: FieldRef;
        FieldIndex: Integer;
    begin
        for FieldIndex := 1 to SourceRef.FieldCount() do begin
            SourceField := SourceRef.FieldIndex(FieldIndex);
            if (SourceField.Class = FieldClass::Normal) and (SourceField.Number < 2000000000) then begin
                if not TargetRef.FieldExist(SourceField.Number) then
                    Error(ConflictErr, TargetRef.Caption);
                TargetField := TargetRef.Field(SourceField.Number);
                if Format(SourceField.Value, 0, 9) <> Format(TargetField.Value, 0, 9) then
                    Error(ConflictErr, TargetRef.Caption);
            end;
        end;
        if SourceRef.Field(SourceRef.SystemIdNo).Value <> TargetRef.Field(TargetRef.SystemIdNo).Value then
            Error(ConflictErr, TargetRef.Caption);
    end;

    local procedure CheckSchema(SourceRef: RecordRef; TargetRef: RecordRef)
    var
        SourceField: FieldRef;
        TargetField: FieldRef;
        FieldIndex: Integer;
    begin
        for FieldIndex := 1 to SourceRef.FieldCount() do begin
            SourceField := SourceRef.FieldIndex(FieldIndex);
            if (SourceField.Class = FieldClass::Normal) and (SourceField.Number < 2000000000) then begin
                if SourceField.Type in [FieldType::Blob, FieldType::Media, FieldType::MediaSet] then
                    Error(ExtensionMigrationErr, SourceField.Number, SourceRef.Caption);
                if not TargetRef.FieldExist(SourceField.Number) then
                    Error(SchemaErr, SourceField.Number, SourceRef.Caption);
                TargetField := TargetRef.Field(SourceField.Number);
                if (SourceField.Type <> TargetField.Type) or (SourceField.Length > TargetField.Length) then
                    Error(SchemaErr, SourceField.Number, SourceRef.Caption);
            end;
        end;
    end;

    local procedure CheckLegacyWrite(IsTemporary: Boolean; TargetCompany: Text)
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if IsTemporary then
            exit;
        if StrLen(TargetCompany) > 30 then
            Error(UnsupportedCompanyNameErr);
        if UpgradeTag.HasUpgradeTag(GetUpgradeTag(), CopyStr(TargetCompany, 1, 30)) then
            Error(LegacyReadOnlyErr);
    end;

#pragma warning disable AL0432, AS0105
    [EventSubscriber(ObjectType::Table, Database::"FR Acc. Schedule Name", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BeforeInsertLegacyName(var Rec: Record "FR Acc. Schedule Name"; RunTrigger: Boolean)
    begin
        CheckLegacyWrite(Rec.IsTemporary(), Rec.CurrentCompany());
    end;

    [EventSubscriber(ObjectType::Table, Database::"FR Acc. Schedule Name", 'OnBeforeModifyEvent', '', false, false)]
    local procedure BeforeModifyLegacyName(var Rec: Record "FR Acc. Schedule Name"; var xRec: Record "FR Acc. Schedule Name"; RunTrigger: Boolean)
    begin
        CheckLegacyWrite(Rec.IsTemporary(), Rec.CurrentCompany());
    end;

    [EventSubscriber(ObjectType::Table, Database::"FR Acc. Schedule Name", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure BeforeDeleteLegacyName(var Rec: Record "FR Acc. Schedule Name"; RunTrigger: Boolean)
    begin
        CheckLegacyWrite(Rec.IsTemporary(), Rec.CurrentCompany());
    end;

    [EventSubscriber(ObjectType::Table, Database::"FR Acc. Schedule Name", 'OnBeforeRenameEvent', '', false, false)]
    local procedure BeforeRenameLegacyName(var Rec: Record "FR Acc. Schedule Name"; var xRec: Record "FR Acc. Schedule Name"; RunTrigger: Boolean)
    begin
        CheckLegacyWrite(Rec.IsTemporary(), Rec.CurrentCompany());
    end;

    [EventSubscriber(ObjectType::Table, Database::"FR Acc. Schedule Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BeforeInsertLegacyLine(var Rec: Record "FR Acc. Schedule Line"; RunTrigger: Boolean)
    begin
        CheckLegacyWrite(Rec.IsTemporary(), Rec.CurrentCompany());
    end;

    [EventSubscriber(ObjectType::Table, Database::"FR Acc. Schedule Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure BeforeModifyLegacyLine(var Rec: Record "FR Acc. Schedule Line"; var xRec: Record "FR Acc. Schedule Line"; RunTrigger: Boolean)
    begin
        CheckLegacyWrite(Rec.IsTemporary(), Rec.CurrentCompany());
    end;

    [EventSubscriber(ObjectType::Table, Database::"FR Acc. Schedule Line", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure BeforeDeleteLegacyLine(var Rec: Record "FR Acc. Schedule Line"; RunTrigger: Boolean)
    begin
        CheckLegacyWrite(Rec.IsTemporary(), Rec.CurrentCompany());
    end;

    [EventSubscriber(ObjectType::Table, Database::"FR Acc. Schedule Line", 'OnBeforeRenameEvent', '', false, false)]
    local procedure BeforeRenameLegacyLine(var Rec: Record "FR Acc. Schedule Line"; var xRec: Record "FR Acc. Schedule Line"; RunTrigger: Boolean)
    begin
        CheckLegacyWrite(Rec.IsTemporary(), Rec.CurrentCompany());
    end;
#pragma warning restore AL0432, AS0105
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCompleteMigration()
    begin
    end;
}

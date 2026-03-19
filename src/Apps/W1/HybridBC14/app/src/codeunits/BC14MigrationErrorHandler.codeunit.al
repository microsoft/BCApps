// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;
using System.Integration;

codeunit 50154 "BC14 Migration Error Handler"
{
    SingleInstance = true;

    [EventSubscriber(ObjectType::Table, Database::"Data Migration Error", 'OnAfterInsertEvent', '', false, false)]
    local procedure UpdateErrorOverviewOnInsert(RunTrigger: Boolean; var Rec: Record "Data Migration Error")
    begin
        UpdateErrorOverview(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migration Error", 'OnAfterModifyEvent', '', false, false)]
    local procedure UpdateErrorOverviewOnModify(RunTrigger: Boolean; var Rec: Record "Data Migration Error")
    begin
        UpdateErrorOverview(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Data Migration Error", 'OnAfterDeleteEvent', '', false, false)]
    local procedure UpdateErrorOverviewOnDelete(RunTrigger: Boolean; var Rec: Record "Data Migration Error")
    var
        BC14MigrationErrorOverview: Record "BC14 Migration Error Overview";
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        if not BC14Wizard.GetBC14MigrationEnabled() then
            exit;

        ErrorOccurred := true;
        if BC14MigrationErrorOverview.Get(Rec.Id, CompanyName()) then begin
            BC14MigrationErrorOverview."Error Dismissed" := true;
            BC14MigrationErrorOverview.Modify();
        end;
    end;

    local procedure UpdateErrorOverview(var DataMigrationError: Record "Data Migration Error")
    var
        BC14MigrationErrorOverview: Record "BC14 Migration Error Overview";
        BC14Wizard: Codeunit "BC14 Wizard";
        Exists: Boolean;
    begin
        if not BC14Wizard.GetBC14MigrationEnabled() then
            exit;
        ErrorOccurred := true;
        BC14MigrationErrorOverview.ReadIsolation := IsolationLevel::ReadUncommitted;
        Exists := BC14MigrationErrorOverview.Get(DataMigrationError.Id, CompanyName());
        if not Exists then begin
            BC14MigrationErrorOverview.Id := DataMigrationError.Id;
            BC14MigrationErrorOverview."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(BC14MigrationErrorOverview."Company Name"));
            BC14MigrationErrorOverview.Insert();
        end;

        BC14MigrationErrorOverview.TransferFields(DataMigrationError);
        BC14MigrationErrorOverview.SetFullExceptionMessage(DataMigrationError.GetFullExceptionMessage());
        BC14MigrationErrorOverview.SetLastRecordUnderProcessingLog(DataMigrationError.GetLastRecordsUnderProcessingLog());
        BC14MigrationErrorOverview.SetExceptionCallStack(DataMigrationError.GetExceptionCallStack());
        BC14MigrationErrorOverview.Modify();
    end;

    procedure ClearErrorOccurred()
    begin
        Clear(ErrorOccurred);
    end;

    procedure GetErrorOccurred(): Boolean
    begin
        exit(ErrorOccurred);
    end;

    internal procedure ErrorOccurredDuringLastUpgrade(): Boolean
    var
        BC14MigrationErrorOverview: Record "BC14 Migration Error Overview";
        BC14MigrationErrors: Record "BC14 Migration Errors";
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
    begin
        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);

        // Check BC14 Migration Errors table (populated by Runner's LogError)
        BC14MigrationErrors.SetRange("Company Name", CopyStr(CompanyName(), 1, 30));
        BC14MigrationErrors.SetRange("Resolved", false);
        if not BC14MigrationErrors.IsEmpty() then
            exit(true);

        // Also check BC14 Migration Error Overview table (populated by Data Migration Error events)
        BC14MigrationErrorOverview.SetRange("Company Name", CompanyName());
        BC14MigrationErrorOverview.SetFilter(SystemModifiedAt, '>%1', BC14GlobalSettings."Data Upgrade Started");
        exit(not BC14MigrationErrorOverview.IsEmpty());
    end;

    procedure LogError(MigrationType: Text[250]; SourceTableId: Integer; SourceTableName: Text[250]; SourceRecordKey: Text[250]; DestinationTableId: Integer; ErrorMessage: Text; RecId: RecordId)
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
    begin
        ErrorOccurred := true;

        // Check for existing unresolved error for the same source record to avoid duplicates
        BC14MigrationErrors.SetRange("Company Name", CopyStr(CompanyName(), 1, 30));
        BC14MigrationErrors.SetRange("Source Table ID", SourceTableId);
        BC14MigrationErrors.SetRange("Source Record Key", SourceRecordKey);
        BC14MigrationErrors.SetRange("Resolved", false);
        if BC14MigrationErrors.FindFirst() then begin
            BC14MigrationErrors."Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(BC14MigrationErrors."Error Message"));
            BC14MigrationErrors."Retry Count" += 1;
            BC14MigrationErrors."Last Retry On" := CurrentDateTime();
            BC14MigrationErrors."Record Id" := RecId;
            BC14MigrationErrors.Modify(true);
            exit;
        end;

        BC14MigrationErrors.Init();
        BC14MigrationErrors."Migration Type" := MigrationType;
        BC14MigrationErrors."Source Table ID" := SourceTableId;
        BC14MigrationErrors."Source Table Name" := SourceTableName;
        BC14MigrationErrors."Source Record Key" := SourceRecordKey;
        BC14MigrationErrors."Destination Table ID" := DestinationTableId;
        BC14MigrationErrors."Company Name" := CopyStr(CompanyName(), 1, 30);
        BC14MigrationErrors."Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(BC14MigrationErrors."Error Message"));
        BC14MigrationErrors."Created On" := CurrentDateTime();
        BC14MigrationErrors."Record Id" := RecId;
        BC14MigrationErrors.Insert(true);
    end;

    procedure HasUnresolvedError(SourceTableId: Integer; SourceRecordKey: Text[250]): Boolean
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
    begin
        BC14MigrationErrors.SetRange("Company Name", CopyStr(CompanyName(), 1, 30));
        BC14MigrationErrors.SetRange("Source Table ID", SourceTableId);
        BC14MigrationErrors.SetRange("Source Record Key", SourceRecordKey);
        BC14MigrationErrors.SetRange("Resolved", false);
        exit(not BC14MigrationErrors.IsEmpty());
    end;

    procedure ResolveErrorForRecord(SourceTableId: Integer; SourceRecordKey: Text[250])
    var
        BC14MigrationErrors: Record "BC14 Migration Errors";
    begin
        BC14MigrationErrors.SetRange("Company Name", CopyStr(CompanyName(), 1, 30));
        BC14MigrationErrors.SetRange("Source Table ID", SourceTableId);
        BC14MigrationErrors.SetRange("Source Record Key", SourceRecordKey);
        BC14MigrationErrors.SetRange("Resolved", false);
        if BC14MigrationErrors.FindFirst() then begin
            BC14MigrationErrors."Resolved" := true;
            BC14MigrationErrors."Resolved On" := CurrentDateTime();
            BC14MigrationErrors."Resolution Notes" := CopyStr('Auto-resolved: record migrated successfully on retry', 1, 250);
            BC14MigrationErrors.Modify(true);
        end;
    end;

    var
        ErrorOccurred: Boolean;
}

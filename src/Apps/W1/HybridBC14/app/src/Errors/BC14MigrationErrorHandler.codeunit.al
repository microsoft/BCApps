// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;
using System.Integration;

codeunit 46854 "BC14 Migration Error Handler"
{
    // SingleInstance = true means ErrorOccurred is per-session only.
    // The main migration flow and Historical Worker run in separate sessions,
    // so each has its own independent ErrorOccurred flag. This is intentional:
    // cross-session error detection is done via Data Migration Error table queries.
    SingleInstance = true;

    internal procedure ErrorOccurredInCurrentCompany(): Boolean
    var
        DataMigrationError: Record "Data Migration Error";
        BC14GlobalSettings: Record "BC14 Global Migration Settings";
    begin
        BC14GlobalSettings.GetOrInsertGlobalSettings(BC14GlobalSettings);

        // Data Migration Error is DataPerCompany; no Company Name filter is needed (and adding
        // one would risk false negatives on rows inserted by the platform framework that did not
        // populate the BC14 tableext field).
        // Filter by "Created On" to avoid false positives from errors left over
        // from a previous migration attempt that were never dismissed.
        DataMigrationError.SetRange("Error Dismissed", false);
        if BC14GlobalSettings."Data Upgrade Started" <> 0DT then
            DataMigrationError.SetFilter("Created On", '>=%1', BC14GlobalSettings."Data Upgrade Started");
        exit(not DataMigrationError.IsEmpty());
    end;

    procedure ClearErrorOccurred()
    begin
        ClearLastError();
        Clear(ErrorOccurred);
    end;

    procedure GetErrorOccurred(): Boolean
    begin
        exit(ErrorOccurred);
    end;

    procedure LogError(MigrationType: Text[250]; SourceTableId: Integer; SourceTableName: Text[250]; SourceRecordKey: Text[250]; DestinationTableId: Integer; ErrorMessage: Text; RecId: RecordId)
    var
        DataMigrationError: Record "Data Migration Error";
    begin
        ErrorOccurred := true;

        DataMigrationError.SetRange("Source Table ID", SourceTableId);
        DataMigrationError.SetRange("Source Record Key", SourceRecordKey);
        DataMigrationError.SetRange("Error Dismissed", false);
        if DataMigrationError.FindFirst() then begin
            DataMigrationError."Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(DataMigrationError."Error Message"));
            DataMigrationError."Retry Count" += 1;
            DataMigrationError."Last Retry On" := CurrentDateTime();
            DataMigrationError."Source Staging Table Record ID" := RecId;
            DataMigrationError.Modify(true);
            exit;
        end;

        DataMigrationError.Init();
        DataMigrationError."Migration Type" := MigrationType;
        DataMigrationError."Source Table ID" := SourceTableId;
        DataMigrationError."Source Table Name" := SourceTableName;
        DataMigrationError."Source Record Key" := SourceRecordKey;
        DataMigrationError."Destination Table ID" := DestinationTableId;
        DataMigrationError."Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(DataMigrationError."Error Message"));
        DataMigrationError."Created On" := CurrentDateTime();
        DataMigrationError."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(DataMigrationError."Company Name"));
        DataMigrationError."Source Staging Table Record ID" := RecId;
        DataMigrationError.Insert(true);
    end;

    procedure HasUnresolvedError(SourceTableId: Integer; SourceRecordKey: Text[250]): Boolean
    var
        DataMigrationError: Record "Data Migration Error";
    begin
        DataMigrationError.SetRange("Source Table ID", SourceTableId);
        DataMigrationError.SetRange("Source Record Key", SourceRecordKey);
        DataMigrationError.SetRange("Error Dismissed", false);
        exit(not DataMigrationError.IsEmpty());
    end;

    procedure ResolveErrorForRecord(SourceTableId: Integer; SourceRecordKey: Text[250])
    var
        DataMigrationError: Record "Data Migration Error";
    begin
        DataMigrationError.SetRange("Source Table ID", SourceTableId);
        DataMigrationError.SetRange("Source Record Key", SourceRecordKey);
        DataMigrationError.SetRange("Error Dismissed", false);
        if DataMigrationError.FindFirst() then begin
            DataMigrationError."Error Dismissed" := true;
            DataMigrationError."Resolved On" := CurrentDateTime();
            DataMigrationError.Modify(true);
        end;
    end;

    var
        ErrorOccurred: Boolean;
}

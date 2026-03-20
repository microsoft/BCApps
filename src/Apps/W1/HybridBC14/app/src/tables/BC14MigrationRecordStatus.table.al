// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

/// <summary>
/// Tracks migration status at the record level.
/// Used to support resumable migrations - records marked as migrated will be skipped on rerun.
/// </summary>
table 50199 "BC14 Migration Record Status"
{
    Caption = 'BC14 Migration Record Status';
    DataClassification = SystemMetadata;
    ReplicateData = false;

    fields
    {
        field(1; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(2; "Source Table ID"; Integer)
        {
            Caption = 'Source Table ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Source Record Key"; Text[250])
        {
            Caption = 'Source Record Key';
            DataClassification = CustomerContent;
        }
        field(5; "Migrated On"; DateTime)
        {
            Caption = 'Migrated On';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Company Name", "Source Table ID", "Source Record Key")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Checks if a specific record has been migrated.
    /// </summary>
    procedure IsMigrated(SourceTableId: Integer; SourceRecordKey: Text[250]): Boolean
    begin
        exit(Get(CompanyName(), SourceTableId, SourceRecordKey));
    end;

    /// <summary>
    /// Marks a record as successfully migrated.
    /// </summary>
    procedure MarkAsMigrated(SourceTableId: Integer; SourceRecordKey: Text[250])
    begin
        Init();
        "Company Name" := CopyStr(CompanyName(), 1, MaxStrLen("Company Name"));
        "Source Table ID" := SourceTableId;
        "Source Record Key" := SourceRecordKey;
        "Migrated On" := CurrentDateTime();
        if not Insert() then; // Ignore duplicate - record already marked as migrated (idempotent)
    end;

    /// <summary>
    /// Clears all migration status for current company.
    /// </summary>
    /// <returns>Number of records deleted.</returns>
    procedure ClearAllMigrationStatus(): Integer
    var
        BC14MigrationRecordStatusBatch: Record "BC14 Migration Record Status";
        DeletedCount: Integer;
        BatchCount: Integer;
    begin
        repeat
            BC14MigrationRecordStatusBatch.Reset();
            BC14MigrationRecordStatusBatch.SetRange("Company Name", CompanyName());
            if not BC14MigrationRecordStatusBatch.FindFirst() then
                break;
            BC14MigrationRecordStatusBatch.SetRange("Source Table ID", BC14MigrationRecordStatusBatch."Source Table ID");
            BatchCount := BC14MigrationRecordStatusBatch.Count();
            BC14MigrationRecordStatusBatch.DeleteAll();
            DeletedCount += BatchCount;
            Commit();
        until false;

        exit(DeletedCount);
    end;
}

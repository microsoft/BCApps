// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

table 3320 "PA Email Cleanup Setup"
{
    Caption = 'Payables Agent Email Cleanup Setup';
    DataClassification = SystemMetadata;
    Access = Internal;
    Extensible = false;
    ReplicateData = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    DataPerCompany = true;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            AllowInCustomizations = Never;
        }
        field(10; "Commit Batch Size"; Integer)
        {
            Caption = 'Rows per commit';
            ToolTip = 'Specifies how many Email Inbox rows are deleted before the deletions are committed. Smaller batches keep transactions and locks short on large inboxes; rows deleted before an interruption stay deleted.';
            InitValue = 100;
            MinValue = 1;
            MaxValue = 10000;
        }
        field(22; "Starting Date/Time"; DateTime)
        {
            Caption = 'Starting date/time';
            ToolTip = 'Specifies the earliest date and time the background cleanup is allowed to start.';
        }
        field(30; "Job Queue Entry ID"; Guid)
        {
            Caption = 'Job Queue Entry ID';
            Editable = false;
        }
        field(40; "Last Run At"; DateTime)
        {
            Caption = 'Last run at';
            Editable = false;
        }
        field(41; "Last Deleted Count"; Integer)
        {
            Caption = 'Last run''s copies deleted';
            Editable = false;
        }
        field(42; "Last Skipped Count"; Integer)
        {
            Caption = 'Last run''s copies skipped';
            Editable = false;
        }
        field(50; "Limit Rows To Delete"; Boolean)
        {
            Caption = 'Limit rows to delete (test run)';
            ToolTip = 'Specifies whether a cleanup deletes only a limited number of copies. Enable this to do a small test run and verify the outcome before deleting everything.';
        }
        field(51; "Rows To Delete Limit"; Integer)
        {
            Caption = 'Rows to delete';
            ToolTip = 'Specifies the maximum number of redundant copies a cleanup deletes in one run. Only used when "Limit rows to delete (test run)" is enabled.';
            InitValue = 10;
            MinValue = 1;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Returns the singleton row, creating it on first use.
    /// </summary>
    procedure GetSingleton()
    begin
        if Rec.Get() then
            exit;
        Rec.Init();
        Rec."Primary Key" := '';
        if not Rec.Insert() then
            Rec.Get();
    end;

    /// <summary>
    /// Returns the persisted batch size, repairing it if it was never set or was stored with an invalid value.
    /// </summary>
    procedure GetCommitBatchSize(): Integer
    begin
        GetSingleton();
        if Rec."Commit Batch Size" < 1 then begin
            Rec."Commit Batch Size" := DefaultCommitBatchSize();
            Rec.Modify();
        end;
        exit(Rec."Commit Batch Size");
    end;

    procedure DefaultCommitBatchSize(): Integer
    begin
        exit(100);
    end;

    procedure GetDeletionLimit(): Integer
    begin
        GetSingleton();
        if not Rec."Limit Rows To Delete" then
            exit(0);
        if Rec."Rows To Delete Limit" < 1 then begin
            Rec."Rows To Delete Limit" := DefaultDeletionLimit();
            Rec.Modify();
        end;
        exit(Rec."Rows To Delete Limit");
    end;

    procedure DefaultDeletionLimit(): Integer
    begin
        exit(10);
    end;
}

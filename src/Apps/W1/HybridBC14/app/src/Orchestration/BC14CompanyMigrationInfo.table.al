// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration;

table 46855 BC14CompanyMigrationInfo
{
    ReplicateData = false;
    DataPerCompany = false;
    Description = 'Company-level info for Business Central 14 migration';

    fields
    {
        field(1; Name; Text[30])
        {
            TableRelation = "Hybrid Company".Name;
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(2; "Migrate Receivables Module"; Boolean)
        {
            InitValue = true;
            DataClassification = SystemMetadata;
        }
        field(3; "Migrate Payables Module"; Boolean)
        {
            InitValue = true;
            DataClassification = SystemMetadata;
        }
        field(4; "Migrate Inventory Module"; Boolean)
        {
            InitValue = true;
            DataClassification = SystemMetadata;
        }
        field(5; "Migrate GL Module"; Boolean)
        {
            InitValue = true;
            DataClassification = SystemMetadata;
        }
        field(6; "Data Migration Started"; Boolean)
        {
            DataClassification = SystemMetadata;
            InitValue = false;
            Caption = 'Data Migration Started';
        }
        field(7; "Data Migration Started At"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Data Migration Started At';
        }
        field(50; "Skip Posting Journal Batches"; Boolean)
        {
            DataClassification = SystemMetadata;
            InitValue = false;
            Caption = 'Skip Posting Journal Batches';
        }
        field(60; Replicate; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = lookup("Hybrid Company".Replicate where(Name = field(Name)));
            Caption = 'Replicate';
        }
        field(62; "Stop On First Error"; Boolean)
        {
            InitValue = false;
            DataClassification = SystemMetadata;
            Caption = 'Stop On First Error';
        }
        field(70; "Current Migration Step"; Enum "BC14 Migration Step")
        {
            DataClassification = SystemMetadata;
            Caption = 'Migration State';
        }
        field(71; "Last Completed Phase"; Enum "BC14 Migration Step")
        {
            DataClassification = SystemMetadata;
            Caption = 'Last Completed Phase';
        }
        field(72; "Last Completed Migrator"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Last Completed Migrator';
        }
        field(80; "Posting Completed"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Posting Completed';
        }
        field(81; "Historical Completed"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Historical Completed';
        }
        field(82; "Historical Dispatched"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Historical Dispatched';
        }
        field(83; "Historical Run Id"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Historical Run Id';
        }
        field(84; "Historical Failed"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Historical Failed';
        }
        field(85; "Historical Failure Reason"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Historical Failure Reason';
        }
        field(88; "Phase Migrators Total"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Phase Migrators Total';
        }
        field(89; "Phase Migrators Completed"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Phase Migrators Completed';
        }
        field(90; "Historical Cutoff Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Historical cutoff date';
        }
    }

    keys
    {
        key(PK; Name)
        {
            Clustered = true;
        }
    }

    procedure GetSingleInstance()
    begin
        GetForCompany(CompanyName());
    end;

    /// <summary>
    /// Loads (or inserts) the per-company row for an arbitrary company name. Used by the
    /// merged Migration Settings card to pre-seed rows for every Hybrid Company and by
    /// drilldowns from cross-company status pages so the per-company card opens on the
    /// clicked company instead of the session's current company.
    /// </summary>
    procedure GetForCompany(TargetCompanyName: Text)
    begin
        if not Rec.Get(TargetCompanyName) then begin
            Rec.Name := CopyStr(TargetCompanyName, 1, MaxStrLen(Rec.Name));
            Rec.Insert();
        end;
    end;

    internal procedure GetOrInsertTemplate(var Template: Record BC14CompanyMigrationInfo)
    begin
        if not Template.Get('') then begin
            Template.Init();
            Template.Name := '';
            Template.Insert();
        end;
    end;

    procedure GetGLModuleEnabled(): Boolean
    begin
        GetSingleInstance();
        exit(Rec."Migrate GL Module");
    end;

    procedure GetPayablesModuleEnabled(): Boolean
    begin
        GetSingleInstance();
        exit(Rec."Migrate Payables Module");
    end;

    procedure GetReceivablesModuleEnabled(): Boolean
    begin
        GetSingleInstance();
        exit(Rec."Migrate Receivables Module");
    end;

    procedure GetInventoryModuleEnabled(): Boolean
    begin
        GetSingleInstance();
        exit(Rec."Migrate Inventory Module");
    end;

    procedure IsDataMigrationStarted(): Boolean
    begin
        GetSingleInstance();
        exit(Rec."Data Migration Started");
    end;

    internal procedure GetHistoricalCutoffDate(): Date
    var
        DefaultsRow: Record BC14CompanyMigrationInfo;
    begin
        GetOrInsertTemplate(DefaultsRow);
        exit(DefaultsRow."Historical Cutoff Date");
    end;

    procedure SetDataMigrationStarted()
    begin
        GetSingleInstance();
        if not Rec."Data Migration Started" then begin
            Rec."Data Migration Started" := true;
            Rec."Data Migration Started At" := CurrentDateTime();
            Rec.Modify();
        end;
    end;

    internal procedure IsAnyCompanyDataMigrationStarted(): Boolean
    var
        CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        CompanySettings.SetFilter(Name, '<>%1', '');
        CompanySettings.SetRange("Data Migration Started", true);
        exit(not CompanySettings.IsEmpty());
    end;

    internal procedure SetDataMigrationStartedForAllCompanies()
    var
        HybridCompany: Record "Hybrid Company";
        CompanySettings: Record BC14CompanyMigrationInfo;
        StartedAt: DateTime;
    begin
        StartedAt := CurrentDateTime();
        HybridCompany.SetRange(Replicate, true);
        if HybridCompany.FindSet() then
            repeat
                if not CompanySettings.Get(HybridCompany.Name) then begin
                    CompanySettings.Name := CopyStr(HybridCompany.Name, 1, MaxStrLen(CompanySettings.Name));
                    CompanySettings."Data Migration Started" := true;
                    CompanySettings."Data Migration Started At" := StartedAt;
                    CompanySettings.Insert();
                end else
                    if CompanySettings."Data Migration Started" then
                        Error(DataMigrationAlreadyStartedErr, HybridCompany.Name)
                    else begin
                        CompanySettings."Data Migration Started" := true;
                        CompanySettings."Data Migration Started At" := StartedAt;
                        CompanySettings.Modify();
                    end;
            until HybridCompany.Next() = 0;
    end;

    procedure GetSkipPostingJournalBatches(): Boolean
    begin
        GetSingleInstance();
        exit(Rec."Skip Posting Journal Batches");
    end;

    procedure GetStopOnFirstTransformationError(): Boolean
    begin
        GetSingleInstance();
        exit(Rec."Stop On First Error");
    end;

    procedure GetMigrationState(): Enum "BC14 Migration Step"
    begin
        GetSingleInstance();
        exit(Rec."Current Migration Step");
    end;

    procedure SetMigrationState(NewState: Enum "BC14 Migration Step")
    begin
        Rec.ReadIsolation := IsolationLevel::UpdLock;
        GetSingleInstance();
        if Rec."Current Migration Step" = NewState then
            exit;
        Rec."Current Migration Step" := NewState;
        Rec.Modify();
    end;

    procedure SetMigrationPhaseCompleted(Phase: Enum "BC14 Migration Step"; MigratorName: Text[100])
    begin
        Rec.ReadIsolation := IsolationLevel::UpdLock;
        GetSingleInstance();
        Rec."Last Completed Phase" := Phase;
        Rec."Last Completed Migrator" := MigratorName;
        Rec.Modify();
        Commit();
    end;

    procedure SetLastCompletedMigrator(MigratorName: Text[100])
    begin
        GetSingleInstance();
        Rec."Last Completed Migrator" := MigratorName;
        Rec.Modify();
    end;

    procedure GetLastCompletedPhase(): Enum "BC14 Migration Step"
    begin
        GetSingleInstance();
        exit(Rec."Last Completed Phase");
    end;

    procedure GetLastCompletedMigrator(): Text[100]
    begin
        GetSingleInstance();
        exit(Rec."Last Completed Migrator");
    end;

    internal procedure SetPostingCompleted()
    begin
        Rec.ReadIsolation := IsolationLevel::UpdLock;
        GetSingleInstance();
        Rec."Posting Completed" := true;
        Rec.Modify();
    end;

    internal procedure SetHistoricalCompleted()
    begin
        Rec.ReadIsolation := IsolationLevel::UpdLock;
        GetSingleInstance();
        Rec."Historical Completed" := true;
        Rec."Historical Dispatched" := false;
        Rec.Modify();
    end;

    internal procedure BeginHistoricalDispatch(): Guid
    var
        NewRunId: Guid;
    begin
        NewRunId := CreateGuid();
        Rec.ReadIsolation := IsolationLevel::UpdLock;
        GetSingleInstance();
        Rec."Historical Dispatched" := true;
        Rec."Historical Run Id" := NewRunId;
        // Reset progress counters at the start of each dispatch so the UI does not show
        // stale numbers from the last main phase. RunMigratorList re-initializes Total
        // once it knows the enabled-migrator count.
        Rec."Phase Migrators Total" := 0;
        Rec."Phase Migrators Completed" := 0;
        Rec.Modify();
        exit(NewRunId);
    end;

    internal procedure GetHistoricalRunId(): Guid
    begin
        GetSingleInstance();
        exit(Rec."Historical Run Id");
    end;

    internal procedure ClearHistoricalDispatched()
    begin
        Rec.ReadIsolation := IsolationLevel::UpdLock;
        GetSingleInstance();
        Rec."Historical Dispatched" := false;
        Rec.Modify();
    end;

    internal procedure TrySetHistoricalCompleted(ExpectedRunId: Guid): Boolean
    begin
        if IsNullGuid(ExpectedRunId) then
            exit(false);
        Rec.ReadIsolation := IsolationLevel::UpdLock;
        GetSingleInstance();
        if Rec."Historical Run Id" <> ExpectedRunId then
            exit(false);
        Rec."Historical Completed" := true;
        Rec."Historical Dispatched" := false;
        Rec.Modify();
        exit(true);
    end;

    internal procedure TryClearHistoricalDispatched(ExpectedRunId: Guid): Boolean
    begin
        if IsNullGuid(ExpectedRunId) then
            exit(false);
        Rec.ReadIsolation := IsolationLevel::UpdLock;
        GetSingleInstance();
        if Rec."Historical Run Id" <> ExpectedRunId then
            exit(false);
        Rec."Historical Dispatched" := false;
        Rec.Modify();
        exit(true);
    end;

    internal procedure TryMarkHistoricalFailed(ExpectedRunId: Guid; FailureReason: Text): Boolean
    begin
        if IsNullGuid(ExpectedRunId) then
            exit(false);
        Rec.ReadIsolation := IsolationLevel::UpdLock;
        GetSingleInstance();
        if Rec."Historical Run Id" <> ExpectedRunId then
            exit(false);
        Rec."Historical Failed" := true;
        Rec."Historical Failure Reason" := CopyStr(FailureReason, 1, MaxStrLen(Rec."Historical Failure Reason"));
        Rec."Historical Completed" := true;
        Rec."Historical Dispatched" := false;
        Rec.Modify();
        exit(true);
    end;

    internal procedure IsHistoricalFailed(): Boolean
    begin
        GetSingleInstance();
        exit(Rec."Historical Failed");
    end;

    internal procedure PrepareHistoricalForRerun(TargetCompanyName: Text[30])
    begin
        Rec.ReadIsolation := IsolationLevel::UpdLock;
        if not Rec.Get(TargetCompanyName) then
            exit;

        Rec."Historical Run Id" := CreateGuid();

        if Rec."Historical Failed" then begin
            Rec."Historical Completed" := false;
            Rec."Historical Failed" := false;
            Rec."Historical Failure Reason" := '';
            Rec."Historical Dispatched" := false;
        end else
            if Rec."Historical Dispatched" and not Rec."Historical Completed" then
                Rec."Historical Dispatched" := false;
        Rec.Modify();
    end;

    internal procedure PrepareMainForRerun(TargetCompanyName: Text[30])
    begin
        Rec.ReadIsolation := IsolationLevel::UpdLock;
        if not Rec.Get(TargetCompanyName) then
            exit;

        if Rec."Last Completed Phase" = Rec."Last Completed Phase"::Completed then
            Error(MigrationAlreadyCompletedErr, TargetCompanyName);

        Rec."Current Migration Step" := Rec."Last Completed Phase";
        Rec."Phase Migrators Total" := 0;
        Rec."Phase Migrators Completed" := 0;

        Rec.Modify();
    end;

    internal procedure IsReadyToFinalize(): Boolean
    begin
        GetSingleInstance();
        exit(Rec."Posting Completed" and Rec."Historical Completed");
    end;

    internal procedure InitCurrentPhaseProgress(TotalMigrators: Integer)
    begin
        Rec.ReadIsolation := IsolationLevel::UpdLock;
        GetSingleInstance();
        Rec."Phase Migrators Total" := TotalMigrators;
        Rec."Phase Migrators Completed" := 0;
        Rec.Modify();
    end;

    internal procedure IncrementCurrentPhaseProgress()
    begin
        Rec.ReadIsolation := IsolationLevel::UpdLock;
        GetSingleInstance();
        Rec."Phase Migrators Completed" += 1;
        Rec.Modify();
    end;

    var
        DataMigrationAlreadyStartedErr: Label 'Data migration has already been started for company %1.', Comment = '%1 = Company Name';
        MigrationAlreadyCompletedErr: Label 'Migration for company %1 has already completed successfully. There is nothing to rerun.', Comment = '%1 = Company Name';

}

namespace Microsoft.Integration.MDM;

using Microsoft.Integration.SyncEngine;
using System.Environment;
using System.Threading;

/// <summary>
/// Cross-environment change detector. One recurring job on the subsidiary polls the source's
/// LastModifiedAtPerTable for the tables it synchronizes and, for those changed since the mapping's watermark,
/// nudges that table's synchronization job to run now. A job already In Process is left alone.
/// </summary>
codeunit 7245 "MDM Cross-Env Change Detector"
{
    Access = Internal;
    Permissions = tabledata "Master Data Management Setup" = r,
                  tabledata "Integration Table Mapping" = r,
                  tabledata "Job Queue Entry" = rm,
                  tabledata "Scheduled Task" = r;

    var
        LastModifiedFeatureTok: Label 'lastModifiedPerTable', Locked = true;
        DetectorParseFailedTxt: Label 'The cross-environment change detector received an invalid response from the source and skipped this run.', Locked = true;
        DetectionContractFailedTxt: Label 'The cross-environment change detector received a response without a valid tables array and skipped this run.', Locked = true;
        DetectorTransportFailedTxt: Label 'The cross-environment change detector could not reach the source and skipped this run; the next scheduled run will retry.', Locked = true;
        DetectorCapabilitiesFailedTxt: Label 'The cross-environment change detector could not negotiate capabilities with the source (malformed or unsupported response) and skipped this run.', Locked = true;

    trigger OnRun()
    begin
        DetectChanges();
    end;

    internal procedure DetectChanges()
    var
        MasterDataManagementSetup: Record "Master Data Management Setup";
        SourceConnection: Codeunit "MDM Source Connection";
        SourceResponse: Codeunit "MDM Source Response";
        MasterDataManagement: Codeunit "Master Data Management";
        Transport: Interface "IMDM Source Transport";
        Response: JsonObject;
        TableIds: JsonArray;
        Dimensions: Dictionary of [Text, Text];
        ResponseText: Text;
        Supported: Boolean;
    begin
        if not MasterDataManagementSetup.Get() then
            exit;
        if not MasterDataManagementSetup."Is Enabled" then
            exit;
        if MasterDataManagementSetup."Source Environment Name" = '' then
            exit; // detector is cross-environment only

        if not CollectSynchronizedTableIds(TableIds) then
            exit;

        Transport := SourceConnection.GetTransport();
        // Capability negotiation is a deterministic contract exchange; a failure here (e.g. malformed capabilities) is
        // NOT a transport outage, so classify it distinctly instead of masking it as "could not reach the source".
        // Still non-fatal to this recurring job: skip the poll, the next scheduled run retries.
        if not TryNegotiateDetectionSupport(Transport, Supported) then begin
            Dimensions.Add('Category', MasterDataManagement.GetTelemetryCategory());
            Session.LogMessage('0000VAZ', DetectorCapabilitiesFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
            exit;
        end;
        // Older source doesn't advertise the detection action: skip rather than error every run.
        if not Supported then
            exit;
        // An operational transport failure (source outage, auth, bad connection state) must NOT error this recurring
        // detector job - that would burn its retry budget. Skip this poll; the next scheduled run recovers.
        if not TryFetchDetection(Transport, TableIds, ResponseText) then begin
            Dimensions.Add('Category', MasterDataManagement.GetTelemetryCategory());
            Session.LogMessage('0000VAO', DetectorTransportFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
            exit;
        end;
        if not SourceResponse.TryParse(ResponseText, Response) then begin
            Session.LogMessage('0000VAP', DetectorParseFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MasterDataManagement.GetTelemetryCategory());
            exit;
        end;

        ProcessDetectionResponse(Response);
    end;

    // Capability negotiation is a deterministic contract exchange; isolate it so a malformed-capabilities failure is
    // classified distinctly from a transport outage. Both are caught by the caller (log + skip), never erroring the job.
    [TryFunction]
    local procedure TryNegotiateDetectionSupport(Transport: Interface "IMDM Source Transport"; var Supported: Boolean)
    var
        SourceCapabilities: Codeunit "MDM Source Capabilities";
    begin
        Supported := SourceCapabilities.IsSupported(Transport, LastModifiedFeatureTok);
    end;

    // Isolates the LastModifiedAtPerTable transport call so an operational transport error skips the poll instead of
    // escaping and erroring the recurring detector job.
    [TryFunction]
    local procedure TryFetchDetection(Transport: Interface "IMDM Source Transport"; TableIds: JsonArray; var ResponseText: Text)
    begin
        ResponseText := Transport.LastModifiedAtPerTable(WriteArray(TableIds));
    end;

    local procedure CollectSynchronizedTableIds(var TableIds: JsonArray): Boolean
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        AddedTables: List of [Integer];
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::"Master Data Management");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetRange(Status, IntegrationTableMapping.Status::Enabled);
        IntegrationTableMapping.SetLoadFields("Integration Table ID");
        if not IntegrationTableMapping.FindSet() then
            exit(false);
        repeat
            if not AddedTables.Contains(IntegrationTableMapping."Integration Table ID") then begin
                AddedTables.Add(IntegrationTableMapping."Integration Table ID");
                TableIds.Add(IntegrationTableMapping."Integration Table ID");
            end;
        until IntegrationTableMapping.Next() = 0;
        exit(TableIds.Count() > 0);
    end;

    local procedure ProcessDetectionResponse(var Response: JsonObject)
    var
        MasterDataManagement: Codeunit "Master Data Management";
        SourceResponse: Codeunit "MDM Source Response";
        Tables: JsonArray;
        TablesToken: JsonToken;
        EntryToken: JsonToken;
    begin
        if SourceResponse.ConsentRequired(Response) then
            exit; // source hasn't consented to sharing; the sync job surfaces the actionable error, the detector skips
        if (not Response.Get('tables', TablesToken)) or (not TablesToken.IsArray()) then begin
            Session.LogMessage('0000VAQ', DetectionContractFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MasterDataManagement.GetTelemetryCategory());
            exit;
        end;
        Tables := TablesToken.AsArray();
        foreach EntryToken in Tables do
            if EntryToken.IsObject() then // skip a malformed non-object entry instead of aborting the recurring job
                ProcessTableEntry(EntryToken.AsObject());
    end;

    local procedure ProcessTableEntry(Entry: JsonObject)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        LastModifiedAt: DateTime;
        TableId: Integer;
        HasTimestamp: Boolean;
    begin
        TableId := GetInteger(Entry, 'tableId');
        if TableId = 0 then
            exit;
        if not GetBoolean(Entry, 'tableAvailable', true) then
            exit; // the sync job itself will report the unavailability

        // No timestamp (indexed:false or empty table): can't compare cheaply, so let the sync job poll (scan).
        HasTimestamp := GetDateTime(Entry, 'lastModifiedAt', LastModifiedAt);

        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::"Master Data Management");
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetRange("Integration Table ID", TableId);
        IntegrationTableMapping.SetRange(Status, IntegrationTableMapping.Status::Enabled);
        IntegrationTableMapping.SetLoadFields("Synch. Modified On Filter");
        if not IntegrationTableMapping.FindSet() then
            exit;
        repeat
            if (not HasTimestamp) or (LastModifiedAt > IntegrationTableMapping."Synch. Modified On Filter") then
                NudgeSynchJob(IntegrationTableMapping);
        until IntegrationTableMapping.Next() = 0;
    end;

    local procedure NudgeSynchJob(IntegrationTableMapping: Record "Integration Table Mapping")
    var
        JobQueueEntry: Record "Job Queue Entry";
        IsHandled: Boolean;
    begin
        // In Process / Error / missing jobs are left alone (FindIdleSynchJob returns only idle jobs).
        if not FindIdleSynchJob(IntegrationTableMapping, JobQueueEntry) then
            exit;

        // Seam so tests can observe the decision and skip the reschedule (jobs can't be scheduled in the test lab).
        IsHandled := false;
        OnBeforeRescheduleSynchJob(JobQueueEntry, IntegrationTableMapping, IsHandled);
        if IsHandled then
            exit;

        RescheduleSynchJobNow(JobQueueEntry);
    end;

    local procedure FindIdleSynchJob(IntegrationTableMapping: Record "Integration Table Mapping"; var JobQueueEntry: Record "Job Queue Entry"): Boolean
    begin
        JobQueueEntry.ReadIsolation := IsolationLevel::ReadUncommitted;
        JobQueueEntry.SetLoadFields(Status, "System Task ID");
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
        JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
        JobQueueEntry.SetRange("Recurring Job", true);
        // Only idle jobs. In Process / Error / plain On Hold are excluded, so a running job is left alone.
        JobQueueEntry.SetFilter(Status, '%1|%2', JobQueueEntry.Status::Ready, JobQueueEntry.Status::"On Hold with Inactivity Timeout");
        exit(JobQueueEntry.FindFirst());
    end;

    local procedure RescheduleSynchJobNow(JobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueEntryUpdate: Record "Job Queue Entry";
        ScheduledTask: Record "Scheduled Task";
        NewEarliestStart: DateTime;
    begin
        NewEarliestStart := CurrentDateTime();
        ScheduledTask.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not ScheduledTask.Get(JobQueueEntry."System Task ID") then
            exit;
        if ScheduledTask."Not Before" <= NewEarliestStart then
            exit; // already due to run

        if not TaskScheduler.SetTaskReady(ScheduledTask.ID, NewEarliestStart) then
            exit;

        JobQueueEntryUpdate.ReadIsolation := IsolationLevel::UpdLock;
        JobQueueEntryUpdate.ID := JobQueueEntry.ID;
        if JobQueueEntryUpdate.GetRecLockedExtendedTimeout() then
            if JobQueueEntryUpdate.Status in [JobQueueEntryUpdate.Status::Ready, JobQueueEntryUpdate.Status::"On Hold with Inactivity Timeout"] then begin
                JobQueueEntryUpdate.Status := JobQueueEntryUpdate.Status::Ready;
                JobQueueEntryUpdate."Earliest Start Date/Time" := NewEarliestStart;
                JobQueueEntryUpdate.Modify();
            end;
    end;

    [InternalEvent(false)]
    local procedure OnBeforeRescheduleSynchJob(var JobQueueEntry: Record "Job Queue Entry"; IntegrationTableMapping: Record "Integration Table Mapping"; var IsHandled: Boolean)
    begin
    end;

    local procedure GetInteger(var Container: JsonObject; PropertyName: Text): Integer
    var
        Token: JsonToken;
        Value: Integer;
    begin
        // A parseable but malformed entry must not throw and kill the recurring job: skip it (returns 0).
        if Container.Get(PropertyName, Token) then
            if Token.IsValue() and TryReadInteger(Token, Value) then
                exit(Value);
        exit(0);
    end;

    [TryFunction]
    local procedure TryReadInteger(Token: JsonToken; var Value: Integer)
    begin
        Value := Token.AsValue().AsInteger();
    end;

    local procedure GetBoolean(var Container: JsonObject; PropertyName: Text; DefaultValue: Boolean): Boolean
    var
        Token: JsonToken;
        Value: Boolean;
    begin
        if Container.Get(PropertyName, Token) then
            if Token.IsValue() and TryReadBoolean(Token, Value) then
                exit(Value);
        exit(DefaultValue);
    end;

    [TryFunction]
    local procedure TryReadBoolean(Token: JsonToken; var Value: Boolean)
    begin
        Value := Token.AsValue().AsBoolean();
    end;

    local procedure GetDateTime(var Container: JsonObject; PropertyName: Text; var Value: DateTime): Boolean
    var
        Token: JsonToken;
        ValueText: Text;
    begin
        if not Container.Get(PropertyName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        ValueText := Token.AsValue().AsText();
        if ValueText = '' then
            exit(false);
        exit(Evaluate(Value, ValueText, 9));
    end;

    local procedure WriteArray(JsonArrayValue: JsonArray) ResultText: Text
    begin
        JsonArrayValue.WriteTo(ResultText);
    end;
}

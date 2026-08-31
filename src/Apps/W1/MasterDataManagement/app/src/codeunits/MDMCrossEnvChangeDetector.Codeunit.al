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
        // An operational transport failure (source outage, auth, bad connection state) must NOT error this recurring
        // detector job - that would burn its retry budget and could stop change detection. Skip this poll instead;
        // the next scheduled run recovers.
        if not TryFetchDetection(Transport, TableIds, Supported, ResponseText) then begin
            // A transport failure here is operational (source outage, auth, bad connection state); skip this poll. The
            // raw error text is not emitted: GetLastErrorText can carry customer content and this event is All-scope.
            Dimensions.Add('Category', MasterDataManagement.GetTelemetryCategory());
            Session.LogMessage('0000VAO', DetectorTransportFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
            exit;
        end;
        // Older source doesn't advertise the detection action: skip rather than error every run.
        if not Supported then
            exit;
        if not SourceResponse.TryParse(ResponseText, Response) then begin
            Session.LogMessage('0000VAP', DetectorParseFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', MasterDataManagement.GetTelemetryCategory());
            exit;
        end;

        ProcessDetectionResponse(Response);
    end;

    // Contains the source calls (capability negotiation + LastModifiedAtPerTable) so an operational transport error
    // is caught by the caller (log + skip) instead of escaping and erroring the recurring detector job.
    [TryFunction]
    local procedure TryFetchDetection(Transport: Interface "IMDM Source Transport"; TableIds: JsonArray; var Supported: Boolean; var ResponseText: Text)
    var
        SourceCapabilities: Codeunit "MDM Source Capabilities";
    begin
        Supported := SourceCapabilities.IsSupported(Transport, LastModifiedFeatureTok);
        if not Supported then
            exit;
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
        Tables: JsonArray;
        TablesToken: JsonToken;
        EntryToken: JsonToken;
    begin
        if (not Response.Get('tables', TablesToken)) or (not TablesToken.IsArray()) then begin
            Session.LogMessage('0000VAQ', DetectionContractFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', MasterDataManagement.GetTelemetryCategory());
            exit;
        end;
        Tables := TablesToken.AsArray();
        foreach EntryToken in Tables do
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
    begin
        if Container.Get(PropertyName, Token) then
            exit(Token.AsValue().AsInteger());
        exit(0);
    end;

    local procedure GetBoolean(var Container: JsonObject; PropertyName: Text; DefaultValue: Boolean): Boolean
    var
        Token: JsonToken;
    begin
        if Container.Get(PropertyName, Token) then
            exit(Token.AsValue().AsBoolean());
        exit(DefaultValue);
    end;

    local procedure GetDateTime(var Container: JsonObject; PropertyName: Text; var Value: DateTime): Boolean
    var
        Token: JsonToken;
        ValueText: Text;
    begin
        if not Container.Get(PropertyName, Token) then
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

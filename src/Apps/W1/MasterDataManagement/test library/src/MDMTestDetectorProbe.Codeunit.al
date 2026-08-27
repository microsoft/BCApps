#pragma warning disable AA0247
codeunit 139930 "MDM Test Detector Probe"
{
    // Captures which tables the change detector decided to nudge and short-circuits the real reschedule, so the
    // detector's decision logic can be asserted without scheduling background jobs (not possible in the test lab).
    SingleInstance = true;
    Access = Public;

    var
        NudgedTableIds: List of [Integer];
        Active: Boolean;

    procedure Activate()
    begin
        Active := true;
        Clear(NudgedTableIds);
    end;

    procedure Deactivate()
    begin
        Active := false;
        Clear(NudgedTableIds);
    end;

    procedure WasNudged(TableId: Integer): Boolean
    begin
        exit(NudgedTableIds.Contains(TableId));
    end;

    procedure NudgeCount(): Integer
    begin
        exit(NudgedTableIds.Count());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MDM Cross-Env Change Detector", 'OnBeforeRescheduleSynchJob', '', false, false)]
    local procedure CaptureNudge(var JobQueueEntry: Record "Job Queue Entry"; IntegrationTableMapping: Record "Integration Table Mapping"; var IsHandled: Boolean)
    begin
        if not Active then
            exit;
        if not NudgedTableIds.Contains(IntegrationTableMapping."Integration Table ID") then
            NudgedTableIds.Add(IntegrationTableMapping."Integration Table ID");
        IsHandled := true; // the test lab cannot reschedule background jobs
    end;
}

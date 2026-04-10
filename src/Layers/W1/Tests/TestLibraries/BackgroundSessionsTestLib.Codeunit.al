codeunit 132460 "Background Sessions Test Lib"
{
    // // Wraps the Session Management codeunit to provide testability
    // // helpers specifically for Background Sessions.


    trigger OnRun()
    begin
    end;

    var
        SessionManagement: Codeunit "Session Management";
        Text001: Label 'Background Session %1 on Server Instance %2 did not end within %3 ms when asked to stop by Session %4. SessionEvent Table Dump: %5.';
        Text002: Label 'Failed to abort %1 Background Sessions on Server Instance %2 from Session %3 within the timeout limit of %4 ms.  SessionEvent Table Dump: %5.';
        Text003: Label 'Failed to abort Background Session %1 on Server Instance %2 from Session %3 within the timeout limit of %4 ms. SessionEvent Table Dump: %5.';

    [Scope('OnPrem')]
    procedure CleanupAll()
    var
        ActiveSession: Record "Active Session";
        Flagged: Integer;
        Timeout: Integer;
    begin
        Timeout := 60000;
        Flagged := SessionManagement.StopAllOnCurrentServerInstance(ActiveSession."Client Type"::Background);
        if not SessionManagement.WaitForAllToStopOnCurrentServerInstance(Timeout) then
            Error(Text002, Flagged, ServiceInstanceId(), SessionId(), Timeout, GetSessionEventDump());
    end;

    [Scope('OnPrem')]
    procedure WaitEnd(Session: Integer; AbortOnTimeout: Boolean)
    var
        Timeout: Integer;
    begin
        Timeout := 20000;
        if not SessionManagement.WaitForSessionToStop(Session, Timeout) then begin
            if AbortOnTimeout then
                Abort(Session);
            Error(Text001, Session, ServiceInstanceId(), Timeout, SessionId(), GetSessionEventDump());
        end;
    end;

    [Scope('OnPrem')]
    procedure ActiveBackgroundSessionCount(): Integer
    var
        ActiveSession: Record "Active Session";
    begin
        exit(SessionManagement.ActiveSessionCount(ServiceInstanceId(), ActiveSession."Client Type"::Background));
    end;

    [Scope('OnPrem')]
    procedure Abort(Session: Integer)
    var
        Timeout: Integer;
    begin
        Timeout := 20000;
        if not SessionManagement.SynchronousStopSession(Session, Timeout) then
            Error(Text003, Session, ServiceInstanceId(), SessionId(), Timeout, GetSessionEventDump());
    end;

    [Scope('OnPrem')]
    procedure IsBackgroundSessionActive(Session: Integer): Boolean
    begin
        exit(IsSessionActive(Session));
    end;

    local procedure GetSessionEventDump() dump: Text
    var
        SessionEvent: Record "Session Event";
    begin
        // Selects all sessions from the ALTest session onwards.
        SessionEvent.LockTable();
        SessionEvent.SetRange("Server Instance ID", ServiceInstanceId());
        SessionEvent.SetRange("User ID", UserId);
        SessionEvent.SetFilter("Session ID", '>=%1', SessionId());
        SessionEvent.Ascending(false);

        if SessionEvent.FindSet() then
            repeat
                dump += '\[' +
                  Format(SessionEvent."Session ID") + '][' +
                  Format(SessionEvent."Client Type") + '][' +
                  Format(SessionEvent."Event Type") + '][' +
                  Format(SessionEvent."Event Datetime", 0, '<Minutes,2>:<Seconds,2>:<Second dec>') + '][' +
                  SessionEvent.Comment + ']';
            until SessionEvent.Next() = 0;

        exit(dump);
    end;
}


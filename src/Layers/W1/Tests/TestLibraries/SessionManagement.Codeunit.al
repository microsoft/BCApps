codeunit 132455 "Session Management"
{
    // This library provides useful functions to manage Sessions by wrapping the system tables
    // which track Sessions.
    // 
    // NOTE that records in the Active Session table recycle the Session ID whenever the Server Instance
    // is restarted (ie. IDs increment from 1 again). In cases where restarting the Service will not
    // spawn sessions in the same sequence, this function may positively identify the wrong session.
    // 
    // NOTE that although an Active Session record may exist, the corresponding Session may not. Such
    // records may take up to 5 minutes to time out and be removed from the Active Session table.


    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'Session was aborted by user %1';

    [Scope('OnPrem')]
    procedure StopAllOnCurrentServerInstance(ClientType: Integer): Integer
    var
        ActiveSession: Record "Active Session";
        Stopped: Integer;
    begin
        ActiveSession.SetRange("Client Type", ClientType);
        ActiveSession.SetRange("Server Instance ID", ServiceInstanceId());

        Stopped := 0;
        if ActiveSession.FindSet() then
            repeat
                StopSession(ActiveSession."Session ID", StrSubstNo(Text001, UserId));
                Stopped := Stopped + 1;
            until ActiveSession.Next() = 0;

        exit(Stopped);
    end;

    [Scope('OnPrem')]
    procedure WaitForAllToStopOnCurrentServerInstance(Timeout: Duration): Boolean
    var
        ActiveSession: Record "Active Session";
        StartDateTime: DateTime;
    begin
        ActiveSession.SetRange("Client Type", ActiveSession."Client Type"::Background);
        ActiveSession.SetRange("Server Instance ID", ServiceInstanceId());

        StartDateTime := CurrentDateTime;
        while ActiveSession.FindFirst() do begin
            if CurrentDateTime - StartDateTime > Timeout then
                exit(false);

            Sleep(1000);
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure WaitForSessionToStop(Session: Integer; Timeout: Duration): Boolean
    var
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime;
        while IsSessionActive(Session) do begin
            if CurrentDateTime - StartDateTime > Timeout then
                exit(false);

            Sleep(500);
        end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ActiveSessionCount(ServerInstance: Integer; ClientType: Integer): Integer
    var
        ActiveSession: Record "Active Session";
    begin
        SelectLatestVersion();

        if ClientType <> -1 then
            ActiveSession.SetRange("Client Type", ClientType);

        if ServerInstance <> -1 then
            ActiveSession.SetRange("Server Instance ID", ServerInstance);

        exit(ActiveSession.Count);
    end;

    [Scope('OnPrem')]
    procedure SynchronousStopSession(Session: Integer; Timeout: Duration): Boolean
    begin
        StopSession(Session, StrSubstNo(Text001, UserId));
        exit(WaitForSessionToStop(Session, Timeout));
    end;
}


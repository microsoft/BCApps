namespace Tour.UnixTimestamp;

using System.Reflection;
using System.DateTime;
using System.Environment.Configuration;

/// <summary>
/// Exploratory tour instrument for commit 5c5cdeff91.
///
/// Build 30.0.55076.0 still carries the PRE-fix "Type Helper".EvaluateUnixTimestamp
/// (epoch-created-locally + Timestamp*1000 + user timezone offset) AND the
/// System Application codeunit "Unix Timestamp" that the fix delegates to.
/// So both sides of the behaviour change are callable in one session, and this
/// codeunit records them side by side.
///
///   "Old Result"        = what EvaluateUnixTimestamp returns today (pre-fix)
///   "Manual Old Result" = the pre-fix formula recomputed by hand (self-control)
///   "New Result"        = what EvaluateUnixTimestamp will return after the fix
/// </summary>
codeunit 50100 "Tour Unix Probe"
{
    Permissions = tabledata "Tour Unix Result" = rimd;

    trigger OnRun()
    begin
        RunAll();
    end;

    /// <summary>
    /// Sets the user's time zone through AL, not SQL.
    ///
    /// Writing [dbo].[User Personalization] directly does NOT work: the service tier caches
    /// the record, so every later session still reported the previous zone while SQL showed
    /// the new one. Call this in its own SOAP round trip, then call RunAll in the next one -
    /// each SOAP call is a fresh session, so the new session both reads the new record and
    /// starts with the new session time zone.
    /// </summary>
    procedure SetTimeZone(NewTimeZone: Text)
    var
        UserPersonalization: Record "User Personalization";
    begin
        if not UserPersonalization.Get(UserSecurityId()) then begin
            UserPersonalization.Init();
            UserPersonalization."User SID" := UserSecurityId();
            UserPersonalization.Insert();
        end;
        UserPersonalization."Time Zone" := CopyStr(NewTimeZone, 1, MaxStrLen(UserPersonalization."Time Zone"));
        UserPersonalization.Modify();
        Commit();
    end;

    procedure ClearResults()
    var
        Result: Record "Tour Unix Result";
    begin
        Result.DeleteAll();
        Commit();
    end;

    procedure RunAll()
    var
        Cases: List of [Text];
        CaseText: Text;
    begin
        RecordEnvironment();

        Cases.Add('0|epoch');
        Cases.Add('1|epoch+1s');
        Cases.Add('-1|epoch-1s (pre-1970)');
        Cases.Add('-2208988800|1900-01-01 (pre-1970, large negative)');
        Cases.Add('1789375237|shipped test vector, expect 2026-09-14T08:40:37Z');
        Cases.Add('1789375237000|millisecond-scale value passed as seconds');
        Cases.Add('2147483647|Int32 max (2038-01-19T03:14:07Z)');
        Cases.Add('2147483648|Int32 max + 1 (Y2038 boundary)');
        Cases.Add('1709164800|2024-02-29T00:00:00Z leap day');
        Cases.Add('2088460799|2036-02-29T23:59:59Z leap day end');
        Cases.Add('253402300799|9999-12-31T23:59:59Z (DateTimeOffset max)');
        Cases.Add('253402300800|one second past DateTimeOffset max');
        Cases.Add('-62135596800|0001-01-01T00:00:00Z (DateTimeOffset min)');
        Cases.Add('-62135596801|one second before DateTimeOffset min');
        Cases.Add('-6847804800|1753-01-01T00:00:00Z (AL/SQL DateTime min)');
        Cases.Add('-6847804801|one second before AL/SQL DateTime min');
        Cases.Add('-6847891200|1752-12-31T00:00:00Z');
        Cases.Add('-17987443200|1400-01-01T00:00:00Z');
        Cases.Add('-30610224000|1000-01-01T00:00:00Z');
        Cases.Add('9223372036854775807|BigInteger max');
        Cases.Add('-9223372036854775808|BigInteger min');
        Cases.Add('9223372036854775|BigInteger max div 1000 (Timestamp*1000 boundary)');
        Cases.Add('9223372036854776|one past that boundary');
        // Central European DST: spring forward 2026-03-29 01:00Z, autumn fold 2026-10-25 01:00Z.
        Cases.Add('1774828799|2026-03-29T00:59:59Z, one second before CET spring-forward');
        Cases.Add('1774828800|2026-03-29T01:00:00Z, the CET spring-forward instant');
        Cases.Add('1774828801|2026-03-29T01:00:01Z, first instant of CEST');
        Cases.Add('1792544400|2026-10-25T01:00:00Z, the CET autumn fold instant');
        Cases.Add('1792540800|2026-10-25T00:00:00Z, inside the CEST half of the fold');
        // A zone whose offset changed historically: CET observed no DST in 1970.
        Cases.Add('0|1970-01-01, before European DST was reintroduced');

        foreach CaseText in Cases do
            ProbeOne(CaseText);

        ProbeInverse();
    end;

    local procedure ProbeOne(CaseText: Text)
    var
        Result: Record "Tour Unix Result";
        Parts: List of [Text];
        Ts: BigInteger;
        Dt: DateTime;
        RtTs: BigInteger;
    begin
        Parts := CaseText.Split('|');

        Result.Init();
        Result.Probe := 'evaluate';
        Result."Case Name" := CopyStr(Parts.Get(2), 1, MaxStrLen(Result."Case Name"));
        if not Evaluate(Ts, Parts.Get(1)) then begin
            Result.Note := 'could not evaluate the literal in AL';
            Result.Insert(true);
            exit;
        end;
        Result."Input Ts" := Ts;
        FillContext(Result);

        if TryOld(Ts, Dt) then
            Result."Old Result" := CopyStr(Format(Dt, 0, 9), 1, MaxStrLen(Result."Old Result"))
        else
            Result."Old Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Result."Old Error"));
        ClearLastError();

        if TryManualOld(Ts, Dt) then
            Result."Manual Old Result" := CopyStr(Format(Dt, 0, 9), 1, MaxStrLen(Result."Manual Old Result"))
        else
            Result."Manual Old Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Result."Manual Old Error"));
        ClearLastError();

        if TryNew(Ts, Dt) then begin
            Result."New Result" := CopyStr(Format(Dt, 0, 9), 1, MaxStrLen(Result."New Result"));
            if Dt = 0DT then
                Result.Note := 'NEW returned 0DT (undefined DateTime) and raised NO error';
            if TryCreateTimestamp(Dt, RtTs) then begin
                Result."Round Trip Ts" := RtTs;
                Result."Round Trip Ok" := RtTs = Ts;
            end else
                Result."Round Trip Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Result."Round Trip Error"));
            ClearLastError();

            if TryIrsEpochSeconds(Dt, RtTs) then
                Result."Irs Epoch Ts" := RtTs
            else
                Result."Irs Epoch Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Result."Irs Epoch Error"));
            ClearLastError();
        end else
            Result."New Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Result."New Error"));
        ClearLastError();

        Result.Insert(true);
    end;

    /// <summary>
    /// The inverse direction. codeunit "Unix Timestamp".CreateTimestampSeconds is the
    /// System Application inverse; IRSForms OAuthClientIRIS.GetEpochTime hand-rolls its own
    /// using a locally created 1970 epoch - the same idiom the fix has just removed from
    /// "Type Helper". If the two disagree, the disagreement is the user's UTC offset.
    /// </summary>
    local procedure ProbeInverse()
    var
        Stamps: List of [Text];
        S: Text;
    begin
        Stamps.Add('2026-09-14T08:40:37Z|test vector');
        Stamps.Add('1970-01-01T00:00:00Z|epoch');
        Stamps.Add('2026-01-15T12:00:00Z|winter, standard time in CET');
        Stamps.Add('2026-07-15T12:00:00Z|summer, daylight saving in CET');
        Stamps.Add('2026-03-29T01:00:00Z|CET spring-forward instant');
        Stamps.Add('2026-10-25T01:00:00Z|CET autumn fold instant');
        Stamps.Add('2024-02-29T23:59:59Z|leap day');
        Stamps.Add('2038-01-19T03:14:07Z|Int32 seconds max');
        Stamps.Add('2038-01-19T03:14:08Z|Int32 seconds max + 1');
        Stamps.Add('9999-12-31T23:59:59Z|DateTime max');
        Stamps.Add('0001-01-01T00:00:00Z|DateTime min');

        foreach S in Stamps do
            ProbeInverseOne(S);
    end;

    local procedure ProbeInverseOne(CaseText: Text)
    var
        Result: Record "Tour Unix Result";
        Parts: List of [Text];
        Dt: DateTime;
        Ts: BigInteger;
        BackDt: DateTime;
    begin
        Parts := CaseText.Split('|');

        Result.Init();
        Result.Probe := 'inverse';
        Result."Case Name" := CopyStr(Parts.Get(2) + ' <- ' + Parts.Get(1), 1, MaxStrLen(Result."Case Name"));
        FillContext(Result);

        if not Evaluate(Dt, Parts.Get(1), 9) then begin
            Result.Note := 'AL could not Evaluate this round-trip literal';
            Result.Insert(true);
            exit;
        end;
        Result."Old Result" := CopyStr(Format(Dt, 0, 9), 1, MaxStrLen(Result."Old Result"));

        if TryCreateTimestamp(Dt, Ts) then begin
            Result."Input Ts" := Ts;
            if TryNew(Ts, BackDt) then begin
                Result."New Result" := CopyStr(Format(BackDt, 0, 9), 1, MaxStrLen(Result."New Result"));
                Result."Round Trip Ok" := BackDt = Dt;
            end else
                Result."New Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Result."New Error"));
            ClearLastError();
        end else
            Result."Round Trip Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Result."Round Trip Error"));
        ClearLastError();

        if TryIrsEpochSeconds(Dt, Ts) then
            Result."Irs Epoch Ts" := Ts
        else
            Result."Irs Epoch Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen(Result."Irs Epoch Error"));
        ClearLastError();

        Result.Insert(true);
    end;

    local procedure RecordEnvironment()
    var
        Result: Record "Tour Unix Result";
        Epoch: DateTime;
    begin
        Result.Init();
        Result.Probe := 'environment';
        Result."Case Name" := 'CreateDateTime(DMY2Date(1,1,1970),0T) as a UTC instant';
        FillContext(Result);
        Epoch := CreateDateTime(DMY2Date(1, 1, 1970), 0T);
        Result."Old Result" := CopyStr(Format(Epoch, 0, 9), 1, MaxStrLen(Result."Old Result"));
        Result."New Result" := CopyStr(Format(CurrentDateTime(), 0, 9), 1, MaxStrLen(Result."New Result"));
        Result.Note := CopyStr('CurrentDateTime default format: ' + Format(CurrentDateTime()), 1, MaxStrLen(Result.Note));
        Result.Insert(true);
    end;

    local procedure FillContext(var Result: Record "Tour Unix Result")
    var
        TypeHelper: Codeunit "Type Helper";
        Offset: Duration;
    begin
        Result."Offset Ok" := TypeHelper.GetUserTimezoneOffset(Offset);
        if not Result."Offset Ok" then
            Offset := 0;
        Result."Offset Ms" := Offset;
        Result."Tz Setting" := CopyStr(CurrentTimeZoneName(), 1, MaxStrLen(Result."Tz Setting"));
    end;

    local procedure CurrentTimeZoneName(): Text
    var
        UserPersonalization: Record "User Personalization";
    begin
        if UserPersonalization.Get(UserSecurityId()) then
            exit(UserPersonalization."Time Zone");
        exit('<no User Personalization row>');
    end;

    [TryFunction]
    local procedure TryOld(Ts: BigInteger; var Dt: DateTime)
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        Dt := TypeHelper.EvaluateUnixTimestamp(Ts);
    end;

    [TryFunction]
    local procedure TryNew(Ts: BigInteger; var Dt: DateTime)
    var
        UnixTimestamp: Codeunit "Unix Timestamp";
    begin
        Dt := UnixTimestamp.EvaluateTimestamp(Ts);
    end;

    /// <summary>The pre-fix body of EvaluateUnixTimestamp, recomputed here as a self-control.</summary>
    [TryFunction]
    local procedure TryManualOld(Ts: BigInteger; var Dt: DateTime)
    var
        TypeHelper: Codeunit "Type Helper";
        TimezoneOffset: Duration;
        EpochDateTime: DateTime;
        TimestampInMilliseconds: BigInteger;
    begin
        if not TypeHelper.GetUserTimezoneOffset(TimezoneOffset) then
            TimezoneOffset := 0;
        EpochDateTime := CreateDateTime(DMY2Date(1, 1, 1970), 0T);
        TimestampInMilliseconds := Ts * 1000;
        Dt := EpochDateTime + TimestampInMilliseconds + TimezoneOffset;
    end;

    [TryFunction]
    local procedure TryCreateTimestamp(Dt: DateTime; var Ts: BigInteger)
    var
        UnixTimestamp: Codeunit "Unix Timestamp";
    begin
        Ts := UnixTimestamp.CreateTimestampSeconds(Dt);
    end;

    /// <summary>
    /// Verbatim copy of OAuthClientIRIS.GetEpochTime (src/Apps/US/IRSForms), except that the
    /// result is widened from Integer to BigInteger so the Y2038 truncation shows up as a
    /// value rather than an overflow.
    /// </summary>
    [TryFunction]
    local procedure TryIrsEpochSeconds(InputDateTime: DateTime; var Secs: BigInteger)
    var
        UnixEpoch: DateTime;
        Dur: Duration;
    begin
        UnixEpoch := CreateDateTime(DMY2Date(1, 1, 1970), 0T);
        Dur := InputDateTime - UnixEpoch;
        Secs := Dur div 1000;
    end;
}

namespace System.DateTime;

/// <summary>
/// Codeunit that provides helper methods for DateTime and Time types.
/// </summary>
codeunit 8723 "Date and Time Helper Impl."
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    procedure Compare(FirstDateTime: DateTime; SecondDateTime: DateTime): Integer
    begin
        if FirstDateTime = SecondDateTime then
            exit(0);

        if FirstDateTime = 0DT then
            exit(-1);

        if SecondDateTime = 0DT then
            exit(1);

        // Round the Time values to the nearest 0, 3, or 7 milliseconds.
        FirstDateTime := RoundToSQLAccuracy(FirstDateTime);
        SecondDateTime := RoundToSQLAccuracy(SecondDateTime);

        if FirstDateTime = SecondDateTime then
            exit(0);

        if FirstDateTime > SecondDateTime then
            exit(1);

        exit(-1);
    end;

    procedure RoundToSQLAccuracy(DateTimeToRound: DateTime): DateTime
    var
        TimeToRound: Time;
        RoundedTime: Time;
    begin
        TimeToRound := DT2Time(DateTimeToRound);
        RoundedTime := RoundToSQLAccuracy(TimeToRound);
        if RoundedTime <> TimeToRound then
            exit(CreateDateTime(DT2Date(DateTimeToRound), RoundedTime))
        else
            exit(DateTimeToRound);
    end;

    procedure Compare(FirstTime: Time; SecondTime: Time): Integer
    begin
        if FirstTime = SecondTime then
            exit(0);

        if FirstTime = 0T then
            exit(-1);

        if SecondTime = 0T then
            exit(1);

        // Round the Time values to the nearest 0, 3, or 7 milliseconds.
        FirstTime := RoundToSQLAccuracy(FirstTime);
        SecondTime := RoundToSQLAccuracy(SecondTime);

        if FirstTime = SecondTime then
            exit(0);

        if FirstTime > SecondTime then
            exit(1);

        exit(-1);
    end;

    procedure RoundToSQLAccuracy(TimeToRound: Time): Time
    begin
        // Rounds the specified Time value to the nearest 0, 3, or 7 milliseconds.
        case (TimeToRound - 000000T) mod 10 of
            1:
                exit(TimeToRound - 1); // round to 0
            2:
                exit(TimeToRound + 1); // round to 3
            4:
                exit(TimeToRound - 1); // round to 3
            5:
                exit(TimeToRound + 2); // round to 7
            6:
                exit(TimeToRound + 1); // round to 7
            8:
                exit(TimeToRound - 1); // round to 7
            9:
                exit(TimeToRound + 1); // round to 0
            else
                exit(TimeToRound);
        end;
    end;
}
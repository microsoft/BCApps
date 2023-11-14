namespace System.DateTime;

/// <summary>
/// Codeunit that provides helper methods for DateTime and Time types.
/// </summary>
codeunit 8723 "Date and Time Helper Impl."
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    procedure CompareDateTimes(firstDateTime: DateTime; secondDateTime: DateTime): Integer
    begin
        if firstDateTime = secondDateTime then
            exit(0);

        if firstDateTime = 0DT then
            exit(-1);

        if secondDateTime = 0DT then
            exit(1);

        // Round the Time values to the nearest 0, 3, or 7 milliseconds.
        firstDateTime := RoundToSQLAccuracy(firstDateTime);
        secondDateTime := RoundToSQLAccuracy(secondDateTime);

        if firstDateTime = secondDateTime then
            exit(0);

        if firstDateTime > secondDateTime then
            exit(1);

        exit(-1);
    end;

    procedure RoundToSQLAccuracy(DateTimeToRound: DateTime): DateTime
    begin
        // Rounds the specified DateTime value to the nearest 0, 3, or 7 milliseconds.
        case (DateTimeToRound - 0DT) mod 10 of
            1:
                exit(DateTimeToRound - 1); // round to 0
            2:
                exit(DateTimeToRound + 1); // round to 3
            4:
                exit(DateTimeToRound - 1); // round to 3
            5:
                exit(DateTimeToRound + 2); // round to 7
            6:
                exit(DateTimeToRound + 1); // round to 7
            8:
                exit(DateTimeToRound - 1); // round to 7
            9:
                exit(DateTimeToRound + 1); // round to 0
            else
                exit(DateTimeToRound);
        end;
    end;

    procedure CompareTimes(firstTime: Time; secondTime: Time): Integer
    begin
        if firstTime = secondTime then
            exit(0);

        if firstTime = 0T then
            exit(-1);

        if secondTime = 0T then
            exit(1);

        // Round the Time values to the nearest 0, 3, or 7 milliseconds.
        firstTime := RoundToSQLAccuracy(firstTime);
        secondTime := RoundToSQLAccuracy(secondTime);

        if firstTime = secondTime then
            exit(0);

        if firstTime > secondTime then
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
namespace System.DateTime;

/// <summary>
/// Codeunit that provides helper methods for DateTime and Time types.
/// </summary>
codeunit 8722 "Date and Time Helper"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Compares two DateTime values and returns true if the FirstDateTime is greater than the SecondDateTime.
    /// The DateTimes are rounded to SQL Server accuracy before comparison,
    /// to account for the fact that SQL Server rounds DateTime values to the nearest 0, 3, or 7 milliseconds.
    /// </summary>
    /// <param name="FirstDateTime">The first DateTime value to compare.</param>
    /// <param name="SecondDateTime">The second DateTime value to compare</param>
    /// <returns>true if the FirstDateTime is greater than the SecondDateTime; otherwise, false.</returns>
    procedure IsGreater(FirstDateTime: DateTime; SecondDateTime: DateTime): Boolean
    var
        DateandTimeHelperImpl: Codeunit "Date and Time Helper Impl.";
    begin
        exit(DateandTimeHelperImpl.Compare(FirstDateTime, SecondDateTime) = 1);
    end;

    /// <summary>
    /// Compares two DateTime values and returns true if the FirstDateTime is less than the SecondDateTime.
    /// The DateTimes are rounded to SQL Server accuracy before comparison,
    /// to account for the fact that SQL Server rounds DateTime values to the nearest 0, 3, or 7 milliseconds.
    /// </summary>
    /// <param name="FirstDateTime">The first DateTime value to compare.</param>
    /// <param name="SecondDateTime">The second DateTime value to compare</param>
    /// <returns>true if the FirstDateTime is less than the SecondDateTime; otherwise, false.</returns>
    procedure IsLess(FirstDateTime: DateTime; SecondDateTime: DateTime): Boolean
    var
        DateandTimeHelperImpl: Codeunit "Date and Time Helper Impl.";
    begin
        exit(DateandTimeHelperImpl.Compare(FirstDateTime, SecondDateTime) = -1);
    end;

    /// <summary>
    /// Compares two DateTime values and returns true if the FirstDateTime is equal to the SecondDateTime.
    /// The DateTimes are rounded to SQL Server accuracy before comparison,
    /// to account for the fact that SQL Server rounds DateTime values to the nearest 0, 3, or 7 milliseconds.
    /// </summary>
    /// <param name="FirstDateTime">The first DateTime value to compare.</param>
    /// <param name="SecondDateTime">The second DateTime value to compare</param>
    /// <returns>true if the FirstDateTime is equal to the SecondDateTime; otherwise, false.</returns>
    procedure IsEqual(FirstDateTime: DateTime; SecondDateTime: DateTime): Boolean
    var
        DateandTimeHelperImpl: Codeunit "Date and Time Helper Impl.";
    begin
        exit(DateandTimeHelperImpl.Compare(FirstDateTime, SecondDateTime) = 0);
    end;

    /// <summary>
    /// Compares two DateTime values and returns an integer indicating their relative order.
    ///         - 0 if the two values are equal.
    ///         - 1 if the firstDateTime is greater than the secondDateTime.
    ///         - -1 if the firstDateTime is less than the secondDateTime.
    /// The DateTimes are rounded to SQL Server accuracy before comparison,
    /// to account for the fact that SQL Server rounds DateTime values to the nearest 0, 3, or 7 milliseconds.
    /// </summary>
    /// <param name="FirstDateTime">The first DateTime value to compare.</param>
    /// <param name="SecondDateTime">The second DateTime value to compare</param>
    /// <returns>An integer indicating the relative order of the two DateTime values</returns>
    procedure Compare(FirstDateTime: DateTime; SecondDateTime: DateTime): Integer
    var
        DateandTimeHelperImpl: Codeunit "Date and Time Helper Impl.";
    begin
        exit(DateandTimeHelperImpl.Compare(FirstDateTime, SecondDateTime));
    end;

    /// <summary>
    /// Rounds the given DateTime value to the nearest value that can be accurately represented in SQL Server.
    /// </summary>
    /// <param name="DateTimeToRound">The DateTime value to round.</param>
    /// <returns>The rounded DateTime value.</returns>
    procedure RoundToSQLAccuracy(DateTimeToRound: DateTime): DateTime
    var
        DateandTimeHelperImpl: Codeunit "Date and Time Helper Impl.";
    begin
        exit(DateandTimeHelperImpl.RoundToSQLAccuracy(DateTimeToRound));
    end;

    /// <summary>
    /// Compares two Time values and returns true if the FirstTime is greater than the SecondTime.
    /// The Times are rounded to SQL Server accuracy before comparison,
    /// to account for the fact that SQL Server rounds DateTime values to the nearest 0, 3, or 7 milliseconds.
    /// </summary>
    /// <param name="FirstTime">The first Time value to compare.</param>
    /// <param name="SecondTime">The second Time value to compare</param>
    /// <returns>true if the FirstTime is greater than the SecondTime; otherwise, false.</returns>
    procedure IsGreater(FirstTime: Time; SecondTime: Time): Boolean
    var
        DateandTimeHelperImpl: Codeunit "Date and Time Helper Impl.";
    begin
        exit(DateandTimeHelperImpl.Compare(FirstTime, SecondTime) = 1);
    end;

    /// <summary>
    /// Compares two Time values and returns true if the FirstTime is less than the SecondTime.
    /// The Times are rounded to SQL Server accuracy before comparison,
    /// to account for the fact that SQL Server rounds DateTime values to the nearest 0, 3, or 7 milliseconds.
    /// </summary>
    /// <param name="FirstTime">The first Time value to compare.</param>
    /// <param name="SecondTime">The second Time value to compare</param>
    /// <returns>true if the FirstTime is less than the SecondTime; otherwise, false.</returns>
    procedure IsLess(FirstTime: Time; SecondTime: Time): Boolean
    var
        DateandTimeHelperImpl: Codeunit "Date and Time Helper Impl.";
    begin
        exit(DateandTimeHelperImpl.Compare(FirstTime, SecondTime) = -1);
    end;

    /// <summary>
    /// Compares two Time values and returns true if the FirstTime is equal to the SecondTime.
    /// The Times are rounded to SQL Server accuracy before comparison,
    /// to account for the fact that SQL Server rounds DateTime values to the nearest 0, 3, or 7 milliseconds.
    /// </summary>
    /// <param name="FirstTime">The first Time value to compare.</param>
    /// <param name="SecondTime">The second Time value to compare</param>
    /// <returns>true if the FirstTime is equal to the SecondTime; otherwise, false.</returns>
    procedure IsEqual(FirstTime: Time; SecondTime: Time): Boolean
    var
        DateandTimeHelperImpl: Codeunit "Date and Time Helper Impl.";
    begin
        exit(DateandTimeHelperImpl.Compare(FirstTime, SecondTime) = 0);
    end;

    /// <summary>
    /// Compares two Time values and returns an integer indicating their relative order.
    ///         - 0 if the two values are equal.
    ///         - 1 if the firstTime is greater than the secondTime.
    ///         - -1 if the firstTime is less than the secondTime.
    /// The Times are rounded to SQL Server accuracy before comparison,
    /// to account for the fact that SQL Server rounds DateTime values to the nearest 0, 3, or 7 milliseconds.
    /// </summary>
    /// <param name="FirstTime">The first Time value to compare.</param>
    /// <param name="SecondTime">The second Time value to compare</param>
    /// <returns>An integer indicating the relative order of the two Time values</returns>
    procedure Compare(FirstTime: Time; SecondTime: Time): Integer
    var
        DateandTimeHelperImpl: Codeunit "Date and Time Helper Impl.";
    begin
        exit(DateandTimeHelperImpl.Compare(FirstTime, SecondTime));
    end;

    /// <summary>
    /// Rounds the given Time value to the nearest value that can be accurately represented in SQL Server.
    /// </summary>
    /// <param name="TimeToRound">The Time value to round.</param>
    /// <returns>The rounded Time value.</returns>
    procedure RoundToSQLAccuracy(TimeToRound: Time): Time
    var
        DateandTimeHelperImpl: Codeunit "Date and Time Helper Impl.";
    begin
        exit(DateandTimeHelperImpl.RoundToSQLAccuracy(TimeToRound));
    end;

}
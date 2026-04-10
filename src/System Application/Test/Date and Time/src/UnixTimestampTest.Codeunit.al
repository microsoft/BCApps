// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.DateTime;

using System.DateTime;
using System.TestLibraries.Utilities;

codeunit 132980 "Unix Timestamp Test"
{
    Subtype = Test;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure DateTimeCreatesUnixTimestampSeconds()
    var
        UnixTimestamp: Codeunit "Unix Timestamp";
        TimeZone: Codeunit "Time Zone";
        Offset: Duration;
        GivenDateTime: DateTime;
        ResultTimestamp: BigInteger;
    begin
        // [SCENARIO #0001] A given datetime results in a given Unix timestamp in seconds

        // [GIVEN] A DateTime with value 2024-07-01 06:30:30 in the user time zone
        GivenDateTime := CreateDateTime(20240701D, 063030T);
        // [GIVEN] The offset of the session's timezone
        Offset := TimeZone.GetTimezoneOffset(GivenDateTime);

        // [WHEN] Given DateTime is converted to a Unix timestamp after a correction for timezone offset
        ResultTimestamp := UnixTimestamp.CreateTimestampSeconds(GivenDateTime + Offset);

        // [THEN] The timestamp in seconds is 1719815430
        LibraryAssert.AreEqual(ResultTimestamp, 1719815430L, 'Given DateTime does not create the correct Unix timestamp');
    end;

    [Test]
    procedure DateTimeCreatesUnixTimestampMilliseconds()
    var
        UnixTimestamp: Codeunit "Unix Timestamp";
        TimeZone: Codeunit "Time Zone";
        Offset: Duration;
        GivenDateTime: DateTime;
        ResultTimestamp: BigInteger;
    begin
        // [SCENARIO #00012 A given datetime results in a given Unix timestamp in miliseconds

        // [GIVEN] A DateTime with value 2024-07-01 06:30:30 in the user time zone
        GivenDateTime := CreateDateTime(20240701D, 063030T);
        // [GIVEN] The offset of the session's timezone
        Offset := TimeZone.GetTimezoneOffset(GivenDateTime);

        // [WHEN] Given DateTime is converted to a Unix timestamp after a correction for timezone offset
        ResultTimestamp := UnixTimestamp.CreateTimestampMilliseconds(GivenDateTime + Offset);

        // [THEN] The timestamp in miliseconds is 1719815430000
        LibraryAssert.AreEqual(ResultTimestamp, 1719815430000L, 'Given DateTime does not create the correct Unix timestamp');
    end;

    [Test]
    procedure CreateAndEvaluateTimestampAreConsistent()
    var
        UnixTimestamp: Codeunit "Unix Timestamp";
        GivenDateTime, ResultDateTime : DateTime;
        ResultTimestamp: BigInteger;
    begin
        // [SCENARIO #0003] A given DateTime that is converted to Unix timestamp and then evaluated back to a result DateTime are equal

        // [GIVEN] The current date time
        GivenDateTime := CreateDateTime(20240701D, 063030T);

        // [WHEN] Given DateTime is converted to a Unix timestamp and then evaluated back to DateTime
        ResultTimestamp := UnixTimestamp.CreateTimestampSeconds(GivenDateTime);
        ResultDateTime := UnixTimestamp.EvaluateTimestamp(ResultTimestamp);

        // [THEN] The evaluated DateTime is equal to the given DateTime
        LibraryAssert.AreEqual(ResultDateTime, GivenDateTime, 'Given DateTime does not match result DateTime');
    end;
}
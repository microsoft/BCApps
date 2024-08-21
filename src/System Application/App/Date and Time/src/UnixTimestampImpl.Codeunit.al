// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.DateTime;
using System;

codeunit 8723 "Unix Timestamp Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CreateTimestampSeconds(DateTimeFrom: DateTime): BigInteger
    var
        DateTimeOffset: DotNet DateTimeOffset;
        DateTimeStyles: DotNet DateTimeStyles;
        DateTimeFormatInfo: Dotnet DateTimeFormatInfo;
        RoundTripDateTime: Text;
    begin
        RoundTripDateTime := Format(DateTimeFrom, 0, 9);
        DateTimeOffset := DateTimeOffset.Parse(RoundTripDateTime, DateTimeFormatInfo, DateTimeStyles.RoundtripKind);
        exit(DateTimeOffset.ToUniversalTime().ToUnixTimeSeconds());
    end;

    procedure CreateTimestampMiliseconds(DateTimeFrom: DateTime): BigInteger
    var
        DateTimeOffset: DotNet DateTimeOffset;
        DateTimeStyles: DotNet DateTimeStyles;
        DateTimeFormatInfo: Dotnet DateTimeFormatInfo;
        RoundTripDateTime: Text;
    begin
        RoundTripDateTime := Format(DateTimeFrom, 0, 9);
        DateTimeOffset := DateTimeOffset.Parse(RoundTripDateTime, DateTimeFormatInfo, DateTimeStyles.RoundtripKind);
        exit(DateTimeOffset.ToUniversalTime().ToUnixTimeMilliseconds());
    end;

    procedure EvaluateTimestamp(Timestamp: BigInteger) Result: DateTime
    var
        DateTimeOffset: DotNet DateTimeOffset;
        RoundTripDateTime: Text;
    begin
        DateTimeOffset := DateTimeOffset.FromUnixTimeSeconds(Timestamp);
        RoundTripDateTime := DateTimeOffset.ToString('o');
        Evaluate(Result, RoundTripDateTime, 9);
    end;
}
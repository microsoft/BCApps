// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.DateTime;

codeunit 8722 "Unix Timestamp"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        UnixTimestampImpl: Codeunit "Unix Timestamp Impl.";

    /// <summary>
    /// Create a Unix timestamp in seconds for the current date and time
    /// </summary>
    /// <returns>A Unix timestamp in seconds representing the current date and time</returns>
    procedure CreateTimestampSeconds(): BigInteger
    begin
        exit(CreateTimestampSeconds(CurrentDateTime));
    end;

    /// <summary>
    /// Create a Unix timestamp in seconds for the specified date and time
    /// </summary>
    /// <param name="DateTimeFrom">The DateTime that should be used to create the Unix timestamp</param>
    /// <returns>A Unix timestamp in seconds representing the specified date and time</returns>
    procedure CreateTimestampSeconds(DateTimeFrom: DateTime): BigInteger
    begin
        exit(UnixTimestampImpl.CreateTimestampSeconds(DateTimeFrom));
    end;

    /// <summary>
    /// Create a Unix timestamp in milliseconds for the current date and time
    /// </summary>
    /// <returns>A Unix timestamp in milliseconds representing the current date and time</returns>
    procedure CreateTimestampMilliseconds(): BigInteger
    begin
        exit(CreateTimestampMilliseconds(CurrentDateTime));
    end;

    /// <summary>
    /// Create a Unix timestamp in milliseconds for the specified date and time
    /// </summary>
    /// <param name="DateTimeFrom">The DateTime that should be used to create the Unix timestamp</param>
    /// <returns>A Unix timestamp in milliseconds representing the specified date and time</returns>
    procedure CreateTimestampMilliseconds(DateTimeFrom: DateTime): BigInteger
    begin
        exit(UnixTimestampImpl.CreateTimestampMilliseconds(DateTimeFrom));
    end;

    /// <summary>
    /// Evaluate a Unix timestamp to a DateTime
    /// </summary>
    /// <param name="Timestamp">The Unix timestamp that should be evaluated to a DateTime</param>
    /// <returns>The evaluated DateTime</returns>
    procedure EvaluateTimestamp(Timestamp: BigInteger): DateTime
    begin
        exit(UnixTimestampImpl.EvaluateTimestamp(Timestamp));
    end;
}
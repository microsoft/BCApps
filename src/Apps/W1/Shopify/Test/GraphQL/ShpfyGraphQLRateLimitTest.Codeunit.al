// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy GraphQL Rate Limit Test (ID 135611).
/// </summary>
codeunit 139571 "Shpfy GraphQL Rate Limit Test"
{
    Subtype = Test;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure UnitTestWaitForRequestAvailable()
    var
        GraphQLRateLimit: Codeunit "Shpfy GraphQL Rate Limit";
        EndTime: DateTime;
        StartTime: DateTime;
        WaitTime: Duration;
        JThrottleStatus: JsonObject;
        JThrottleStatusTxt: Label '{"maximumAvailable": 1000, "restoreRate": 50, "currentlyAvailable": %1}', Comment = '%1 = currentAvailable', Locked = true;
    begin
        // [SCENARIO] Set the availability to 1000. Then wait for the availability.
        // [GIVEN] Set currentAvailable = 1000 in the JThottleStatus
        JThrottleStatus.ReadFrom(StrSubstNo(JThrottleStatusTxt, 1000));
        GraphQLRateLimit.SetQueryCost(JThrottleStatus.AsToken());
        // [WHEN] Invoke WaitFromRequestAvailable(0)
        StartTime := CurrentDateTime;
        GraphQLRateLimit.WaitForRequestAvailable(0);
        EndTime := CurrentDateTime;
        WaitTime := EndTime - StartTime;
        // [THEN] WaitTime < 1000 (less then 1 sec.)
        LibraryAssert.IsTrue(WaitTime < 1000, 'currentlyAvailable = 1000, WaitForRequestAvailable(0)');

        // [SCENARIO] Set the availability to 50. Then wait for the availability for an expected cost of 150.
        // [GIVEN] Set currentAvailable = 50 in the JThottleStatus
        JThrottleStatus.ReadFrom(StrSubstNo(JThrottleStatusTxt, 50));
        GraphQLRateLimit.SetQueryCost(JThrottleStatus.AsToken());
        // [WHEN] Invoke WaitFromRequestAvailable(150)
        StartTime := CurrentDateTime;
        GraphQLRateLimit.WaitForRequestAvailable(150);
        EndTime := CurrentDateTime;
        WaitTime := EndTime - StartTime;
        // [THEN] Waittime is about 2 sec.
        LibraryAssert.AreNearlyEqual(2000, WaitTime, 200, 'currentlyAvailable = 50, WaitForRequestAvailable(150)');
    end;

    [Test]
    procedure UnitTestWaitForRequestAvailableAfterElapsedTime()
    var
        GraphQLRateLimit: Codeunit "Shpfy GraphQL Rate Limit";
        EndTime: DateTime;
        StartTime: DateTime;
        WaitTime: Duration;
        JThrottleStatus: JsonObject;
        JThrottleStatusTxt: Label '{"maximumAvailable": 1000, "restoreRate": 50, "currentlyAvailable": %1}', Comment = '%1 = currentAvailable', Locked = true;
    begin
        // [SCENARIO] Part of the required restore time elapses between the throttle response and the next request.
        // WaitForRequestAvailable must wait only the remaining time - not skip the wait, and not restart the full wait.
        // [GIVEN] currentAvailable = 50, restoreRate = 50 (an expected cost of 200 needs 3 sec. to restore)
        JThrottleStatus.ReadFrom(StrSubstNo(JThrottleStatusTxt, 50));
        GraphQLRateLimit.SetQueryCost(JThrottleStatus.AsToken());
        // [GIVEN] 2 sec. elapse before the next request is issued
        Sleep(2000);
        // [WHEN] Invoke WaitForRequestAvailable(200)
        StartTime := CurrentDateTime;
        GraphQLRateLimit.WaitForRequestAvailable(200);
        EndTime := CurrentDateTime;
        WaitTime := EndTime - StartTime;
        // [THEN] It waits about the remaining 1 sec. (3 sec. total - 2 sec. already elapsed), not zero and not the full 3 sec.
        LibraryAssert.AreNearlyEqual(1000, WaitTime, 400, 'currentlyAvailable = 50, WaitForRequestAvailable(200) after 2 sec. elapsed');
    end;
}
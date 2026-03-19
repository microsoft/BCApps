// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

interface "AIT Eval Limit Provider"
{
    procedure CheckBeforeRun(AITTestSuite: Record "AIT Test Suite"): Boolean;
    procedure IsLimitReached(): Boolean;
    procedure HandleLimitReached(var AITTestSuite: Record "AIT Test Suite");
    procedure ShowNotifications();
    procedure OpenSetupPage();
}

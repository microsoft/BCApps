// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

codeunit 149041 "AIT Eval No Limit" implements "AIT Eval Limit Provider"
{
    Access = Internal;
    SingleInstance = true;

    procedure CheckBeforeRun(AITTestSuite: Record "AIT Test Suite"): Boolean
    begin
    end;

    procedure IsLimitReached(): Boolean
    begin
        exit(false);
    end;

    procedure HandleLimitReached(var AITTestSuite: Record "AIT Test Suite")
    begin
    end;

    procedure ShowNotifications()
    begin
    end;

    procedure OpenSetupPage()
    begin
    end;
}

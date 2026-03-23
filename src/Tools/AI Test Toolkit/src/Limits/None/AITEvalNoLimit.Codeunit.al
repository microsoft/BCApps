// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

codeunit 149041 "AIT Eval No Limit" implements "AIT Eval Limit Provider"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <inheritdoc />
    procedure CheckBeforeRun(AITTestSuite: Record "AIT Test Suite")
    begin
    end;

    /// <inheritdoc />
    procedure IsLimitReached(): Boolean
    begin
        exit(false);
    end;

    /// <inheritdoc />
    procedure ShowNotifications()
    begin
    end;

    /// <inheritdoc />
    procedure OpenConfigurationPage()
    begin
    end;
}

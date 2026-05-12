// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Agents;

using System.Environment;

codeunit 130563 "Library - Agent Utilities"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure VerifyCanRunOnCurrentEnvironment()
    begin
        if not IsSupportedEnvironment() then
            Error(UnsupportedEnvironmentErr);
    end;

    [NonDebuggable]
    local procedure IsSupportedEnvironment(): Boolean
    var
        FeatureAccessManagement: Codeunit "Feature Access Management";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not EnvironmentInformation.IsSaaS() then
            exit(true);

        if EnvironmentInformation.IsSandbox() then
            exit(true);

        if FeatureAccessManagement.IsEnvironmentPositiveListed() then
            exit(true);

        exit(false);
    end;

    var
        UnsupportedEnvironmentErr: Label 'This functionality is not supported in the current environment. This functionality is only available in sandbox environments.';
}
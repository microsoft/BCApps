// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Environment;

codeunit 149030 "BCCT Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if EnvironmentInformation.IsSaaSInfrastructure() and (not EnvironmentInformation.IsSandbox()) then
            Error(this.CannotInstallErr);
    end;

    var
        CannotInstallErr: Label 'Cannot install on environment that is not a Sandbox or OnPrem.//Please contact your administrator.';
}
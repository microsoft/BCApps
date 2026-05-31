// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Agents;

codeunit 130562 "Library - Agent Install"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        LibraryAgentUtilities: Codeunit "Library - Agent Utilities";
    begin
        LibraryAgentUtilities.VerifyCanRunOnCurrentEnvironment();
    end;
}
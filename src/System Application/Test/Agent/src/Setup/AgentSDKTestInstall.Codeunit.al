// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Agents;

codeunit 133950 "Agent SDK Test Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        TestAgentSetup: Codeunit "Mock Agent Setup";
    begin
        TestAgentSetup.RegisterCapability();
    end;
}

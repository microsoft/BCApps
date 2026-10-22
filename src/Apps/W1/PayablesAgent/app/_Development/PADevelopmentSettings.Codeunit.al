#if DEVELOPMENT
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

codeunit 3329 "PA Development Settings"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure IsV2Enabled(): Boolean
    var
        DevelopmentSettings: Record "PA Development Settings";
    begin
        GetSettings(DevelopmentSettings);
        exit(DevelopmentSettings."Enable V2");
    end;

    internal procedure SimulateAgentExperience(): Boolean
    var
        DevelopmentSettings: Record "PA Development Settings";
    begin
        GetSettings(DevelopmentSettings);
        exit(DevelopmentSettings."Simulate Agent Experience");
    end;

    internal procedure GetSettings(var DevelopmentSettings: Record "PA Development Settings")
    begin
        if DevelopmentSettings.Get(SetupKeyTok) then
            exit;

        DevelopmentSettings.Init();
        DevelopmentSettings."Primary Key" := SetupKeyTok;
        DevelopmentSettings.Insert();
    end;

    var
        SetupKeyTok: Label 'SETUP', Locked = true;
}
#endif

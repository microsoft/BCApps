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

    var
        SetupKeyTok: Label 'SETUP', Locked = true;
        UnknownEvaluationVersionErr: Label 'An evaluation must select version 1 or version 2 of the Payables Agent.';

    internal procedure IsV2Enabled(): Boolean
    var
        DevelopmentSettings: Record "PA Development Settings";
    begin
        GetSettings(DevelopmentSettings);
        exit(DevelopmentSettings."Enable V2");
    end;

    internal procedure SetEvaluationVersionOverride(Version: Enum "PA Version")
    var
        DevelopmentSettings: Record "PA Development Settings";
    begin
        if Version = Version::Unknown then
            Error(UnknownEvaluationVersionErr);
        GetSettings(DevelopmentSettings);
        if DevelopmentSettings."Evaluation Version Override" = Version then
            exit;
        DevelopmentSettings."Evaluation Version Override" := Version;
        DevelopmentSettings.Modify();
    end;

    internal procedure GetEvaluationVersionOverride(): Enum "PA Version"
    var
        DevelopmentSettings: Record "PA Development Settings";
    begin
        GetSettings(DevelopmentSettings);
        exit(DevelopmentSettings."Evaluation Version Override");
    end;

    internal procedure ClearEvaluationVersionOverride()
    var
        DevelopmentSettings: Record "PA Development Settings";
    begin
        GetSettings(DevelopmentSettings);
        if DevelopmentSettings."Evaluation Version Override" = "PA Version"::Unknown then
            exit;
        DevelopmentSettings."Evaluation Version Override" := "PA Version"::Unknown;
        DevelopmentSettings.Modify();
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

}
#endif

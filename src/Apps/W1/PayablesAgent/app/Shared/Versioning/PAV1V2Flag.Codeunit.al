// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

codeunit 3339 "PA V1V2 Flag"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

#if DEVELOPMENT
    var
        DevelopmentSettings: Codeunit "PA Development Settings";
#endif

    internal procedure GetVersion(): Enum "PA Version"
#if DEVELOPMENT
    var
        EvaluationVersion: Enum "PA Version";
#endif
    begin
#if DEVELOPMENT
        EvaluationVersion := DevelopmentSettings.GetEvaluationVersionOverride();
        if EvaluationVersion <> EvaluationVersion::Unknown then
            exit(EvaluationVersion);
        if DevelopmentSettings.IsV2Enabled() then
            exit("PA Version"::V2);
#endif
        exit("PA Version"::V1);
    end;

    internal procedure IsV2Active(): Boolean
    begin
        exit(GetVersion() = "PA Version"::V2);
    end;
}

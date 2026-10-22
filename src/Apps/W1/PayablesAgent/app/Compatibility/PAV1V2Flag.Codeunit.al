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

    internal procedure GetVersion(): Enum "PA Version"
    begin
#if DEVELOPMENT
        if DevelopmentSettings.IsV2Enabled() then
            exit("PA Version"::V2);
#endif
        exit("PA Version"::V1);
    end;

    internal procedure IsV2Active(): Boolean
    begin
        exit(GetVersion() = "PA Version"::V2);
    end;

#if DEVELOPMENT
    var
        DevelopmentSettings: Codeunit "PA Development Settings";
#endif
}

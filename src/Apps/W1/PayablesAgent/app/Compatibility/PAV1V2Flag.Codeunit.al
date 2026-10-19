// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

/// <summary>
/// Single hardcoded source of truth for whether Payables Agent v2 is active.
/// Only these codeunits may reference it (keep in sync with architecture.md, "Where the v1/v2 switch may be used"):
/// - "PA Setup"           (Setup/Model/PASetup.Codeunit.al)
/// - "PA Task"            (Task/Model/PATask.Codeunit.al)
/// - "PA Task Collection" (Task/Model/PATaskCollection.Codeunit.al)
/// Everyone else calls those codeunits, which branch on it.
/// </summary>
codeunit 3339 "PA V1V2 Flag"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// While this returns false, every facade stays on the v1 (e-document based) behavior.
    /// </summary>
    internal procedure IsV2Active(): Boolean
    var
        PAV1V2: Record DEVPAV1V2;
    begin
        exit(PAV1V2.V2);
    end;
}

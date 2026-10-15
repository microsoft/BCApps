// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

/// <summary>
/// Single hardcoded source of truth for whether Payables Agent v2 is active.
/// Only the compatibility facades ("PA Task", "PA Task Collection", "PA Setup") may reference this codeunit;
/// everyone else talks to the facades, which branch on it.
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
    begin
        exit(false);
    end;
}

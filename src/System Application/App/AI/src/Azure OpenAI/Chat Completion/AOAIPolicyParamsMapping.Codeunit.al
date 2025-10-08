// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI;

/// <summary>
/// Interface for mapping AOAI policy parameters to AOAI policy enums.
/// </summary>
codeunit 7777 "AOAI Policy Params Mapping"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AOAIPolicyParamsMappingImpl: Codeunit "AOAI Policy Params Map. Impl.";

    /// <summary>
    /// Gets the AOAI policy enum based on the provided policy parameters.
    /// </summary>
    /// <param name="PolicyParams">The AOAI policy parameters containing harms severity and XPIA detection settings.</param>
    /// <returns>The corresponding AOAI policy enum value.</returns>
    procedure GetAOAIPolicy(PolicyParams: Codeunit "AOAI Policy Params"): Enum "AOAI Policy"
    begin
        exit(AOAIPolicyParamsMappingImpl.GetAOAIPolicy(PolicyParams));
    end;
}
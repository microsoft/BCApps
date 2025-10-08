// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.AI;

/// <summary>
/// Implementation for mapping AOAI policy parameters to AOAI policy enums.
/// </summary>
codeunit 7789 "AOAI Policy Params Map. Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Gets the AOAI policy enum based on the provided policy parameters.
    /// </summary>
    /// <param name="PolicyParams">The AOAI policy parameters containing harms severity and XPIA detection settings.</param>
    /// <returns>The corresponding AOAI policy enum value.</returns>
    procedure GetAOAIPolicy(PolicyParams: Codeunit "AOAI Policy Params"): Enum "AOAI Policy"
    var
        AOAIPolicyHarmsSeverity: Enum "AOAI Policy Harms Severity";
        AOAIPolicyXPIADetection: Enum "AOAI Policy XPIA Detection";
        CombinationKey: Text;
    begin
        AOAIPolicyHarmsSeverity := PolicyParams.GetHarmsSeverity();
        AOAIPolicyXPIADetection := PolicyParams.GetXPIADetection();

        // Create readable combination key
        CombinationKey := 'Harms' + Format(AOAIPolicyHarmsSeverity) + '|XPIA' + Format(AOAIPolicyXPIADetection);

        case CombinationKey of
            'HarmsLow|XPIAEnabled':
                exit("AOAI Policy"::"ConservativeWithXPIA");
            'HarmsLow|XPIADisabled':
                exit("AOAI Policy"::"Conservative");
            'HarmsMedium|XPIAEnabled':
                exit("AOAI Policy"::"MediumWithXPIA");
            'HarmsMedium|XPIADisabled':
                exit("AOAI Policy"::"Default");
        end;
    end;
}
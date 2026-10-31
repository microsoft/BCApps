// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using System.Telemetry;

codeunit 20509 "Subc. Feature Telemetry"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SubcontractingTok: Label 'Subcontracting', Locked = true;

    internal procedure LogFeatureUptakeDiscovered()
    begin
        FeatureTelemetry.LogUptake('0001Q7N', SubcontractingTok, Enum::"Feature Uptake Status"::Discovered);
    end;

    internal procedure LogFeatureUptakeSetup()
    begin
        LogFeatureUptakeDiscovered();
        FeatureTelemetry.LogUptake('0001Q7O', SubcontractingTok, Enum::"Feature Uptake Status"::"Set up");
    end;

    internal procedure LogFeatureUptakeUsed()
    begin
        LogFeatureUptakeSetup();
        FeatureTelemetry.LogUptake('0000VQ2', SubcontractingTok, Enum::"Feature Uptake Status"::Used);
    end;
}

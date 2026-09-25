#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using System.Environment.Configuration;
using System.Telemetry;

codeunit 10815 "Sales FR"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteReason = 'Feature SalesFR will be enabled by default in version 31.0.';
    ObsoleteState = Pending;
    ObsoleteTag = '30.0';

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        FeatureKeyIdTok: Label 'SalesFR', Locked = true;
        FeatureNameTok: Label 'Sales FR', Locked = true;

    procedure IsEnabled() Enabled: Boolean
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
        Enabled := FeatureManagementFacade.IsEnabled(FeatureKeyIdTok);
    end;

    procedure GetFeatureKeyId(): Text
    begin
        exit(FeatureKeyIdTok);
    end;

    procedure LogFeatureDiscovered()
    begin
        FeatureTelemetry.LogUptake('', FeatureNameTok, Enum::"Feature Uptake Status"::Discovered);
    end;

    procedure LogFeatureSetUp()
    begin
        FeatureTelemetry.LogUptake('', FeatureNameTok, Enum::"Feature Uptake Status"::"Set up");
    end;

    procedure LogFeatureUsed()
    begin
        FeatureTelemetry.LogUptake('', FeatureNameTok, Enum::"Feature Uptake Status"::Used);
    end;
}
#endif

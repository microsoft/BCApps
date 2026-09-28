#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

using System.Environment.Configuration;

codeunit 13466 "FI Depreciation Diff. Feature"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteReason = 'Feature Depreciation Differences FI will be enabled by default in version 33.0.';
    ObsoleteState = Pending;
    ObsoleteTag = '30.0';

    var
        FeatureKeyIdTok: Label 'DepreciationDifferencesFI', Locked = true, MaxLength = 50;

    procedure IsEnabled() Enabled: Boolean
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
        Enabled := FeatureManagementFacade.IsEnabled(FeatureKeyIdTok);
        OnAfterCheckFeatureEnabled(Enabled);
    end;

    procedure GetFeatureKeyId(): Text[50]
    begin
        exit(FeatureKeyIdTok);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCheckFeatureEnabled(var IsEnabled: Boolean)
    begin
    end;
}
#endif

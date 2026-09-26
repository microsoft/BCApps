// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.FixedAssets.Depreciation;

#if not CLEAN30
using System.Environment.Configuration;
#endif

codeunit 13466 "FI Depreciation Diff. Feature"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        FeatureKeyIdTok: Label 'DepreciationDifferencesFI', Locked = true, MaxLength = 50;

    procedure IsEnabled() Enabled: Boolean
#if not CLEAN30
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
#endif
    begin
#if not CLEAN30
        Enabled := FeatureManagementFacade.IsEnabled(FeatureKeyIdTok);
        OnAfterCheckFeatureEnabled(Enabled);
#else
        Enabled := true;
#endif
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

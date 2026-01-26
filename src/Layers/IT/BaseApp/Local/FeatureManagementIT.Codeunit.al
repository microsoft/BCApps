#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

codeunit 12100 "Feature Management IT"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ITCalcAndPostPerActivityCodeFeatureKeyIdTok: Label 'ITCalcAndPostPerActivityCode', Locked = true;

    procedure IsVATSettlementPerActivityCodeFeatureEnabled() Enabled: Boolean
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
        Enabled := FeatureManagementFacade.IsEnabled(GetVATSettlementPerActivityCodeFeatureKeyId());
        OnAfterCheckVATSettlementPerActivityCodeFeatureEnabled(Enabled);
    end;

    procedure GetVATSettlementPerActivityCodeFeatureKeyId(): Text[50]
    begin
        exit(ITCalcAndPostPerActivityCodeFeatureKeyIdTok);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCheckVATSettlementPerActivityCodeFeatureEnabled(var IsEnabled: Boolean)
    begin
    end;
}
#endif
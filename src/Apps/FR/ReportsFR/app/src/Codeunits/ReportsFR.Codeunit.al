#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using System.Environment.Configuration;

codeunit 10832 "Reports FR"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteReason = 'Feature Reports FR will be enabled by default in version 33.0.';
    ObsoleteState = Pending;
    ObsoleteTag = '30.0';

    var
        FeatureKeyIdTok: Label 'FRReports', Locked = true;

    procedure IsEnabled() Enabled: Boolean
    begin
        exit(IsEnabled(true));
    end;

    internal procedure IsEnabled(AllowInsert: Boolean) Enabled: Boolean
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
        Enabled := FeatureManagementFacade.IsEnabled(FeatureKeyIdTok, AllowInsert);
        OnAfterCheckFeatureEnabled(Enabled);
    end;

    procedure GetFeatureKeyId(): Text
    begin
        exit(FeatureKeyIdTok);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCheckFeatureEnabled(var IsEnabled: Boolean)
    begin
    end;
}
#endif
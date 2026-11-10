// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using System.Environment;
using System.Environment.Configuration;

codeunit 3375 "MX E-Document Feature"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        // TODO: replace with the feature key registered in Feature Management
        FeatureKeyIdTok: Label 'CFDICartaPorteMX', Locked = true;
        FeatureNotEnabledErr: Label 'E-Document for Mexico is in preview. It can only be used in sandbox environments where the feature is enabled in Feature Management.';

    procedure IsEnabled() Enabled: Boolean
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        Enabled := EnvironmentInformation.IsSandbox() and FeatureManagementFacade.IsEnabled(FeatureKeyIdTok, false);
        OnAfterCheckFeatureEnabled(Enabled);
    end;

    procedure CheckEnabled()
    begin
        if not IsEnabled() then
            Error(FeatureNotEnabledErr);
    end;

    procedure GetFeatureKeyId(): Text[50]
    begin
        exit(FeatureKeyIdTok);
    end;

    [InternalEvent(false)]
    local procedure OnAfterCheckFeatureEnabled(var IsEnabled: Boolean)
    begin
    end;
}

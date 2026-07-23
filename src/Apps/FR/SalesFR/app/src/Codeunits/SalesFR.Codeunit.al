#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using System.Environment.Configuration;

codeunit 10815 "Sales FR"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteReason = 'Feature SalesFR will be enabled by default in version 31.0.';
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';

    var
        FeatureKeyIdTok: Label 'SalesFR', Locked = true;

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
}
#endif

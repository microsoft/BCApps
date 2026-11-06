// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura.Tests;

using Microsoft.EServices.EDocument.Interfactura;

codeunit 148759 "MX Feature Test Helper"
{
    SingleInstance = true;
    EventSubscriberInstance = StaticAutomatic;

    var
        FeatureDisabled: Boolean;

    procedure DisableFeature()
    begin
        FeatureDisabled := true;
    end;

    procedure EnableFeature()
    begin
        FeatureDisabled := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MX E-Document Feature", 'OnAfterCheckFeatureEnabled', '', false, false)]
    local procedure EnableFeatureForTests(var IsEnabled: Boolean)
    begin
        IsEnabled := not FeatureDisabled;
    end;
}

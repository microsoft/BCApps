// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Environment.Configuration;

codeunit 13412 "FICore VIES Decl. Feature"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        VIESDeclarationFeatureIdTok: Label 'FIVATVIESDeclaration', Locked = true, MaxLength = 50;

    procedure IsEnabled() FeatureEnabled: Boolean
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
        FeatureEnabled := FeatureManagementFacade.IsEnabled(GetFeatureKey());
    end;

    procedure GetFeatureKey(): Text[50]
    begin
        exit(VIESDeclarationFeatureIdTok);
    end;
}

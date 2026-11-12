// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

codeunit 148171 "FI VIES Feature Handler"
{
    Access = Internal;
    SingleInstance = true;

    var
        IsFeatureEnabled: Boolean;

    procedure SetEnabled(NewIsFeatureEnabled: Boolean)
    begin
        IsFeatureEnabled := NewIsFeatureEnabled;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FICore VIES Decl. Feature", OnAfterIsEnabled, '', false, false)]
    local procedure SetFeatureEnabled(var FeatureEnabled: Boolean)
    begin
        FeatureEnabled := IsFeatureEnabled;
    end;
}
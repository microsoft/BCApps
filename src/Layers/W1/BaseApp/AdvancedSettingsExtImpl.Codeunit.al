// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using Microsoft.Foundation.Company;

codeunit 1819 "Advanced Settings Ext. Impl."
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Navigation Bar Subscribers", 'OnBeforeDefaultOpenCompanySettings', '', false, false)]
    local procedure OpenCompanySettings(var Handled: Boolean)
    var
        AdvancedSettingsExtApi: Codeunit "Advanced Settings Ext.";
        CompanySettingsID: Integer;
    begin
        CompanySettingsID := page::"Company Information";
        AdvancedSettingsExtApi.OnBeforeOpenCompanySettings(CompanySettingsID, Handled);
        if not Handled then
            PAGE.Run(CompanySettingsID);
        Handled := true;
    end;
}

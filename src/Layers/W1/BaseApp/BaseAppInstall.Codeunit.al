// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.Upgrade;
#if not CLEAN25
using System.Reflection;
#endif

codeunit 5000 "BaseApp Install"
{
    SubType = Install;

    trigger OnInstallAppPerCompany()
    begin
        AddWordTemplateTables();
    end;

#if not CLEAN25
    [Obsolete('Disabling the BLANK profile is now done using a profile extension object.', '25.0')]
    procedure DisableBlankProfile()
    var
        AllProfile: Record "All Profile";
    begin
        if AllProfile.Get(AllProfile.Scope::Tenant, '63ca2fa4-4f03-4f2b-a480-172fef340d3f', 'BLANK') then
            if AllProfile.Enabled then begin
                AllProfile.Enabled := false;
                AllProfile.Modify();
            end;
    end;
#endif

    local procedure AddWordTemplateTables()
    var
        UpgradeBaseApp: Codeunit "Upgrade - BaseApp";
    begin
        UpgradeBaseApp.UpgradeWordTemplateTables();
    end;
}
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.SE;

using Microsoft.Peppol;

codeunit 37453 "PEPPOL30 SE Initialize"
{
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    var
        AppInfo: ModuleInfo;
    begin
        // Only run on the first install: OnInstallAppPerCompany also fires on a reinstall
        // over preserved data, which must not re-apply the migration.
        NavApp.GetCurrentModuleInfo(AppInfo);
        if AppInfo.DataVersion() = Version.Create('0.0.0.0') then
            SetSEFormatsOnExistingSetup();
    end;

    internal procedure SetSEFormatsOnExistingSetup()
    var
        PeppolSetup: Record "PEPPOL 3.0 Setup";
    begin
        // A setup record inserted before this app was installed never went through the
        // OnAfterInsert subscriber. Move it to the SE formats, but only from the W1 defaults
        // so a deliberately configured format is not overridden.
        if not PeppolSetup.Get() then
            exit;
        if PeppolSetup."PEPPOL 3.0 Sales Format" = PeppolSetup."PEPPOL 3.0 Sales Format"::"PEPPOL 3.0 - Sales" then
            PeppolSetup."PEPPOL 3.0 Sales Format" := PeppolSetup."PEPPOL 3.0 Sales Format"::"PEPPOL 3.0 - SE Sales";
        if PeppolSetup."PEPPOL 3.0 Service Format" = PeppolSetup."PEPPOL 3.0 Service Format"::"PEPPOL 3.0 - Service" then
            PeppolSetup."PEPPOL 3.0 Service Format" := PeppolSetup."PEPPOL 3.0 Service Format"::"PEPPOL 3.0 - SE Service";
        PeppolSetup.Modify();
    end;
}

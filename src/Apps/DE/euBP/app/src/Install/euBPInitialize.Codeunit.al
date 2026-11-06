// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.euBP;

using Microsoft.Finance.AuditFileExport;

codeunit 6546 "euBP - Initialize"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        EUBPSetup: Record "euBP Setup";
        AuditFileExportSetup: Record "Audit File Export Setup";
        AuditFileExportFormatSetup: Record "Audit File Export Format Setup";
        AuditFileExportFormat: Enum "Audit File Export Format";
        AppInfo: ModuleInfo;
    begin
        EUBPSetup.EnsureExists();

        NavApp.GetCurrentModuleInfo(AppInfo);
        if (AppInfo.DataVersion() <> Version.Create('0.0.0.0')) then
            exit;

        AuditFileExportSetup.InitSetup(AuditFileExportFormat::euBP);
        AuditFileExportFormatSetup.InitSetup(AuditFileExportFormat::euBP, 'euBP.zip', true);
    end;
}

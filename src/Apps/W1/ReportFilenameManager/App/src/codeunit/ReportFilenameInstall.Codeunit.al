// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Company;

codeunit 8144 "Report Filename Install"
{
    Access = Internal;
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
    begin
        ReportFilenameDefaults.InitializeExistingCompany();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnBeforeOnRun', '', false, false)]
    local procedure OnBeforeCompanyInitialize()
    var
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
    begin
        ReportFilenameDefaults.OnBeforeCompanyInitialize();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure OnCompanyInitialize()
    var
        ReportFilenameDefaults: Codeunit "Report Filename Defaults";
    begin
        ReportFilenameDefaults.OnCompanyInitialize();
    end;
}

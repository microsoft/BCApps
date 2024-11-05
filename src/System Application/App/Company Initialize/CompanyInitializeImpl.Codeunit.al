// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

using System.Environment;

codeunit 901 "Company Initialize Impl."
{
    Access = Internal;

    procedure InitializeCompany()
    var
        CompanyInitialize: Record "Company Initialize";
        CompanyInitializeCodeunit: Codeunit "Company Initialize";
        ModuleInfo: ModuleInfo;
    begin
        CompanyInitialize."Initialized Time" := CurrentDateTime();

        if NavApp.GetCurrentModuleInfo(ModuleInfo) then
            CompanyInitialize."Initialized Version" := format(ModuleInfo.AppVersion());
        CompanyInitialize.Insert();

        CompanyInitializeCodeunit.InitializeCompanySetup();

        CompanyInitializeCodeunit.InitializeCompany();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnLoginInitializeCompany()
    var
        CompanyInitialize: Record "Company Initialize";
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        if not GuiAllowed() then
            exit;

        if ClientTypeManagement.GetCurrentClientType() = ClientType::Background then
            exit;

        if GetExecutionContext() <> ExecutionContext::Normal then
            exit;

        if CompanyInitialize.Get() then
            exit;

        InitializeCompany();
    end;
}
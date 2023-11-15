// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment;

using System;
using System.Environment.Configuration;

codeunit 3702 "Environment Information Impl."
{
    Access = Internal;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        NavTenantSettingsHelper: DotNet NavTenantSettingsHelper;
        TestabilitySoftwareAsAService: Boolean;
        TestabilitySandbox: Boolean;
        IsSaasInitialized: Boolean;
        IsSaaSConfig: Boolean;
        IsSandboxConfig: Boolean;
        IsSandboxInitialized: Boolean;
        DefaultSandboxEnvironmentNameTxt: Label 'Sandbox', Locked = true;
        DefaultProductionEnvironmentNameTxt: Label 'Production', Locked = true;

    procedure IsProduction(): Boolean
    var
        IsProduction: Boolean;
        TestMode: Boolean;
    begin
        OnBeforeIsProduction(TestMode, IsProduction);
        if TestMode then
            exit(IsProduction);

        exit(NavTenantSettingsHelper.IsProduction())
    end;

    procedure IsSandbox(): Boolean
    var
        IsSandbox: Boolean;
        TestMode: Boolean;
    begin
        OnBeforeIsSandbox(TestMode, IsSandbox);
        if TestMode then
            exit(IsSandbox);

        if TestabilitySandbox then
            exit(true);

        if not IsSandboxInitialized then begin
            IsSandboxConfig := NavTenantSettingsHelper.IsSandbox();
            IsSandboxInitialized := true;
        end;
        exit(IsSandboxConfig);
    end;

    procedure GetEnvironmentName(): Text
    var
        EnvironmentName: Text;
        TestMode: Boolean;
    begin
        OnBeforeEnvironmentName(TestMode, EnvironmentName);
        if TestMode then
            exit(EnvironmentName);

        EnvironmentName := NavTenantSettingsHelper.GetEnvironmentName();
        if EnvironmentName <> '' then
            exit(EnvironmentName);

        if IsProduction() then
            exit(DefaultProductionEnvironmentNameTxt);

        exit(DefaultSandboxEnvironmentNameTxt);
    end;

    procedure SetTestabilitySandbox(EnableSandboxForTest: Boolean)
    begin
        TestabilitySandbox := EnableSandboxForTest;
    end;

    procedure SetTestabilitySoftwareAsAService(EnableSoftwareAsAServiceForTest: Boolean)
    begin
        TestabilitySoftwareAsAService := EnableSoftwareAsAServiceForTest;
    end;

    procedure IsSaaS(): Boolean
    var
        ServerSettings: Codeunit "Server Setting";
        TestMode: Boolean;
        IsSaaS: Boolean;
    begin
        OnBeforeIsSaaS(TestMode, IsSaaS);
        if TestMode then
            exit(IsSaaS);

        if TestabilitySoftwareAsAService then
            exit(true);

        if not IsSaasInitialized then begin
            IsSaaSConfig := IsSandbox() or ServerSettings.GetEnableMembershipEntitlement();
            IsSaasInitialized := true;
        end;

        exit(IsSaaSConfig);
    end;

    procedure IsSaaSInfrastructure(): Boolean
    var
        UserAccountHelper: DotNet NavUserAccountHelper;
        IsSaaSInfrastructure: Boolean;
        TestMode: Boolean;
    begin
        OnBeforeIsSaaSInfrastructure(TestMode, IsSaaSInfrastructure);
        if TestMode then
            exit(IsSaaSInfrastructure);

        if TestabilitySoftwareAsAService then
            exit(true);

        exit(IsSaaS() and UserAccountHelper.IsAzure());
    end;

    procedure IsOnPrem(): Boolean
    begin
        exit(GetAppId() = 'NAV');
    end;

    procedure IsFinancials(): Boolean
    begin
        exit(GetAppId() = 'FIN');
    end;

    procedure GetApplicationFamily(): Text
    var
        TestMode: Boolean;
        ApplicationFamily: Text;
    begin
        OnBeforeApplicationFamily(TestMode, ApplicationFamily);
        if TestMode then
            exit(ApplicationFamily);

        exit(NavTenantSettingsHelper.GetApplicationFamily());
    end;

    procedure VersionInstalled(AppID: Guid): Integer
    var
        AppInfo: ModuleInfo;
        VersionInstalled: Integer;
        TestMode: Boolean;
    begin
        OnBeforeVersionInstalled(TestMode, VersionInstalled);
        if TestMode then
            exit(VersionInstalled);

        NavApp.GetModuleInfo(AppId, AppInfo);
        exit(AppInfo.DataVersion.Major());
    end;

    procedure CanStartSession(): Boolean
    var
        NavTestExecution: DotNet NavTestExecution;
    begin
        if GetExecutionContext() in [ExecutionContext::Install, ExecutionContext::Upgrade] then
            exit(false);

        // Sessions cannot be started in tests if test isolation is enabled
        // 1) check that a test is indeed being executed (so the current user is not delegated admin / device / GDAP guest user)
        if NavTestExecution.IsInTestMode() then
            // 2) check for test isolation
            exit(TaskScheduler.CanCreateTask());

        exit(true);
    end;

    procedure EnableM365Collaboration()
    begin
        NavTenantSettingsHelper.EnableM365Collaboration();
    end;

    local procedure GetAppId() AppId: Text
    begin
        OnBeforeGetApplicationIdentifier(AppId);
        if AppId = '' then
            AppId := ApplicationIdentifier();
    end;

    [InternalEvent(false)]
    procedure OnBeforeGetApplicationIdentifier(var AppId: Text)
    begin
        // An event which asks for the AppId to be filled in by the subscriber.
        // Do not use this event in a production environment. This should be subscribed to only in tests.
    end;

    [InternalEvent(false)]
    procedure OnBeforeIsSaaSInfrastructure(var TestMode: Boolean; var IsSaaSInfrastructure: Boolean)
    begin
        // An event which asks for the AppId to be filled in by the subscriber.
        // Do not use this event in a production environment. This should be subscribed to only in tests.
    end;

    [InternalEvent(false)]
    procedure OnBeforeVersionInstalled(var TestMode: Boolean; var VersionInstalled: Integer)
    begin
        // An event which asks for the AppId to be filled in by the subscriber.
        // Do not use this event in a production environment. This should be subscribed to only in tests.
    end;

    [InternalEvent(false)]
    procedure OnBeforeIsSaaS(var TestMode: Boolean; var IsSaaS: Boolean)
    begin
        // An event which asks for the AppId to be filled in by the subscriber.
        // Do not use this event in a production environment. This should be subscribed to only in tests.
    end;

    [InternalEvent(false)]
    procedure OnBeforeEnvironmentName(var TestMode: Boolean; var EnvironmentName: Text)
    begin
        // An event which asks for the AppId to be filled in by the subscriber.
        // Do not use this event in a production environment. This should be subscribed to only in tests.
    end;

    [InternalEvent(false)]
    procedure OnBeforeIsSandbox(var TestMode: Boolean; var IsSandbox: Boolean)
    begin
        // An event which asks for the AppId to be filled in by the subscriber.
        // Do not use this event in a production environment. This should be subscribed to only in tests.
    end;

    [InternalEvent(false)]
    procedure OnBeforeIsProduction(var TestMode: Boolean; var IsProduction: Boolean)
    begin
        // An event which asks for the AppId to be filled in by the subscriber.
        // Do not use this event in a production environment. This should be subscribed to only in tests.
    end;

    [InternalEvent(false)]
    procedure OnBeforeApplicationFamily(var TestMode: Boolean; var ApplicationFamily: Text)
    begin
        // An event which asks for the AppId to be filled in by the subscriber.
        // Do not use this event in a production environment. This should be subscribed to only in tests.
    end;
}


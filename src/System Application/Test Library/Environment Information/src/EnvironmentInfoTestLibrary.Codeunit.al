// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Environment;

using System.Environment;

codeunit 135094 "Environment Info Test Library"
{
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    var
        EnvironmentInformationImpl: Codeunit "Environment Information Impl.";
        TestAppId: Text;
        TestApplicationFamily: Text;
        TestIsProduction: Boolean;
        TestIsSandbox: Boolean;
        TestEnvironmentName: Text;
        TestIsSaaS: Boolean;
        TestVersionInstalled: Integer;
        TestIsSaaSInfrastructure: Boolean;
        TestApplicationIdentifier: Text;



    /// <summary>
    /// Sets the testability sandbox flag.
    /// </summary>
    /// <remarks>
    /// This functions should only be used for testing purposes.
    /// </remarks>
    /// <param name="EnableSandboxForTest">The value to be set to the testability sandbox flag.</param>
    procedure SetTestabilitySandbox(EnableSandboxForTest: Boolean)
    begin
        EnvironmentInformationImpl.SetTestabilitySandbox(EnableSandboxForTest);
    end;

    /// <summary>
    /// Sets the testability SaaS flag.
    /// </summary>
    /// <remarks>
    /// This functions should only be used for testing purposes.
    /// </remarks>
    /// <param name="EnableSoftwareAsAServiceForTest">The value to be set to the testability SaaS flag.</param>
    procedure SetTestabilitySoftwareAsAService(EnableSoftwareAsAServiceForTest: Boolean)
    begin
        EnvironmentInformationImpl.SetTestabilitySoftwareAsAService(EnableSoftwareAsAServiceForTest);
    end;

    /// <summary>
    /// Sets the App ID that of the current application (for example, 'FIN' - Financials) when the subscription is bound.
    /// Uses <see cref="OnBeforeGetApplicationIdentifier"/> event.
    /// </summary>
    /// <param name="NewAppId">The desired ne App ID.</param>
    procedure SetAppId(NewAppId: Text)
    begin
        TestAppId := NewAppId;
    end;

    /// <summary>
    /// Sets the Is SaaS Infrastructure that of the current Environment when the subscription is bound.
    /// Uses <see cref="OnBeforeIsSaaSInfrastructure"/> event.
    /// </summary>
    /// <param name="NewIsSaaSInfrastructure">The desired new Is SaaS Infrastructure.</param>
    procedure SetIsSaaSInfrastructure(NewIsSaaSInfrastructure: Boolean)
    begin
        TestIsSaaSInfrastructure := NewIsSaaSInfrastructure;
    end;

    /// <summary>
    /// Sets the App Version that of the current application when the subscription is bound.
    /// Uses <see cref="OnBeforeVersionInstalled"/> event.
    /// </summary>
    /// <param name="NewVersionInstalled">The desired new Version Installed</param>
    procedure SetVersionInstalled(NewVersionInstalled: Integer)
    begin
        TestVersionInstalled := NewVersionInstalled;
    end;

    /// <summary>
    /// Sets the App ID that of the current application (for example, 'FIN' - Financials) when the subscription is bound.
    /// Uses <see cref="OnBeforeIsSaaS"/> event.
    /// </summary>
    /// <param name="NewIsSaaS">The desired new Is SaaS</param>
    procedure SetIsSaaS(NewIsSaaS: Boolean)
    begin
        TestIsSaaS := NewIsSaaS;
    end;

    /// <summary>
    /// Sets the App ID that of the current environment when the subscription is bound.
    /// Uses <see cref="OnBeforeEnvironmentName"/> event.
    /// </summary>
    /// <param name="NewEnvironmentName">The desired new Environment Name.</param>
    procedure SetEnvironmentName(NewEnvironmentName: Text)
    begin
        TestEnvironmentName := NewEnvironmentName;
    end;

    /// <summary>
    /// Sets the App ID that of the current environment when the subscription is bound.
    /// Uses <see cref="OnBeforeIsSandbox"/> event.
    /// </summary>
    /// <param name="NewIsSandbox">The desired ne App ID.</param>
    procedure SetIsSandbox(NewIsSandbox: Boolean)
    begin
        TestIsSandbox := NewIsSandbox;
    end;

    /// <summary>
    /// Sets the App ID that of the current environment when the subscription is bound.
    /// Uses <see cref="OnBeforeIsProduction"/> event.
    /// </summary>
    /// <param name="NewIsProduction">The desired new is production.</param>
    procedure SetIsProduction(NewIsProduction: Boolean)
    begin
        TestIsProduction := NewIsProduction;
    end;

    /// <summary>
    /// Sets the Application Family that of the current application when the subscription is bound.
    /// Uses <see cref="OnBeforeApplicationFamily"/> event.
    /// </summary>
    /// <param name="NewApplicationFamily">The desired new Application Family.</param>
    procedure SetApplicationFamily(NewApplicationFamily: Text)
    begin
        TestApplicationFamily := NewApplicationFamily;
    end;

    /// <summary>
    /// Overwrite the current App ID.
    /// </summary>
    /// <param name="AppId">The current App ID.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Information Impl.", 'OnBeforeGetApplicationIdentifier', '', false, false)]
    local procedure SetAppIdOnBeforeGetApplicationIdentifier(var AppId: Text)
    begin
        AppId := TestAppId;
    end;

    /// <summary>
    /// Overwrite the current Application Family
    /// </summary>
    /// <param name="ApplicationFamily">The current Application Family.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Information Impl.", 'OnBeforeApplicationFamily', '', false, false)]
    local procedure SetApplicationFamilyOnBeforeApplicationFamily(var TestMode; var ApplicationFamily: Text)
    begin
        TestMode := true
        ApplicationFamily := TestApplicationFamily;
    end;

    /// <summary>
    /// Overwrite Is SaaS Infrastructure.
    /// </summary>
    /// <param name="TestMode">Sets Test Mode</param>
    /// <param name="IsSaaSInfrastructure">The current Is SaaS Infrastructure.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Information Impl.", 'OnBeforeIsSaaSInfrastructure', '', false, false)]
    local procedure SetIsSaaSInfrastructureOnBeforeIsSaaSInfrastructure(var TestMode: Boolean; var IsSaaSInfrastructure: Boolean)
    begin
        TestMode := true
        IsSaaSInfrastructure := TestIsSaaSInfrastructure
    end;

    /// <summary>
    /// Overwrite the current Version Installed.
    /// </summary>
    /// <param name="TestMode">Sets Test Mode</param>
    /// <param name="VersionInstalled">The current Version Installed</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Information Impl.", 'OnBeforeVersionInstalled', '', false, false)]
    local procedure SetVersionInstalledOnBeforeVersionInstalled(var TestMode: Boolean; var VersionInstalled: Boolean)
    begin
        TestMode := true
        VersionInstalled := TestVersionInstalled
    end;

    /// <summary>
    /// Overwrite the current Is SaaS.
    /// </summary>
    /// <param name="TestMode">Sets Test Mode</param>
    /// <param name="IsSaaS">The current Is SaaS</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Information Impl.", 'OnBeforeIsSaaS', '', false, false)]
    local procedure SetIsSaaSOnBeforeIsSaaS(var TestMode: Boolean; var IsSaaS: Boolean)
    begin
        TestMode := true
        IsSaaS := TestIsSaaS
    end;

    /// <summary>
    /// Overwrite the current Environment Name.
    /// </summary>
    /// <param name="TestMode">Sets Test Mode</param>
    /// <param name="EnvironmentName">The current Environment Name.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Information Impl.", 'OnBeforeEnvironmentName', '', false, false)]
    local procedure SetEnvironmentNameOnBeforeEnvironmentName(var TestMode: Boolean; var EnvironmentName: Boolean)
    begin
        TestMode := true
        EnvironmentName := TestEnvironmentName
    end;

    /// <summary>
    /// Overwrite the current Is Sandbox.
    /// </summary>
    /// <param name="TestMode">Sets Test Mode</param>
    /// <param name="IsSandbox">The current Is Sandbox.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Information Impl.", 'OnBeforeIsSandbox', '', false, false)]
    local procedure SetIsSandboxOnBeforeIsSandbox(var TestMode: Boolean; var IsSandbox: Boolean)
    begin
        TestMode := true
        IsSandbox := TestIsSandbox
    end;

    /// <summary>
    /// Overwrite the current Is Production.
    /// </summary>
    /// <param name="TestMode">Sets Test Mode</param>
    /// <param name="IsSandbox">The current Is Sandbox.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Information Impl.", 'OnBeforeIsProduction', '', false, false)]
    local procedure SetIsProductionOnBeforeIsProduction(var TestMode: Boolean; var IsProduction: Boolean)
    begin
        TestMode := true
        IsProduction := TestIsProduction
    end;
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System;

/// <summary>
/// Store the authorization information for the AOAI service.
/// </summary>
codeunit 7767 "AOAI Authorization"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        [NonDebuggable]
        Endpoint: Text;
        [NonDebuggable]
        Deployment: Text;
        [NonDebuggable]
        ApiKey: SecretText;
        [NonDebuggable]
        ManagedResourceDeployment: Text;
        [NonDebuggable]
        AOAIAccountName: Text;
        ResourceUtilization: Enum "AOAI Resource Utilization";

    [NonDebuggable]
    procedure IsConfigured(CallerModule: ModuleInfo): Boolean
    var
        CurrentModule: ModuleInfo;
        ALCopilotFunctions: DotNet ALCopilotFunctions;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModule);

        case ResourceUtilization of
            Enum::"AOAI Resource Utilization"::"First Party":
                exit((ManagedResourceDeployment <> '') and ALCopilotFunctions.IsPlatformAuthorizationConfigured(CallerModule.Publisher(), CurrentModule.Publisher()));
            Enum::"AOAI Resource Utilization"::"Self-Managed":
                exit((Deployment <> '') and (Endpoint <> '') and (not ApiKey.IsEmpty()));
            Enum::"AOAI Resource Utilization"::"Microsoft Managed":
                exit(ManagedResourceDeployment <> '');
        end;

        exit(false);
    end;

#if not CLEAN26
    [NonDebuggable]
    procedure SetMicrosoftManagedAuthorization(NewEndpoint: Text; NewDeployment: Text; NewApiKey: SecretText; NewManagedResourceDeployment: Text)
    begin
        ClearVariables();

        ResourceUtilization := Enum::"AOAI Resource Utilization"::"Microsoft Managed";
        Endpoint := NewEndpoint;
        Deployment := NewDeployment;
        ApiKey := NewApiKey;
        ManagedResourceDeployment := NewManagedResourceDeployment;
    end;
#endif

    [NonDebuggable]
    procedure SetMicrosoftManagedAuthorization(NewManagedResourceDeployment: Text)
    begin
        ClearVariables();

        ResourceUtilization := Enum::"AOAI Resource Utilization"::"Microsoft Managed";
        ManagedResourceDeployment := NewManagedResourceDeployment;
    end;

    [NonDebuggable]
    procedure SetSelfManagedAuthorization(NewEndpoint: Text; NewDeployment: Text; NewApiKey: SecretText)
    begin
        ClearVariables();

        ResourceUtilization := Enum::"AOAI Resource Utilization"::"Self-Managed";
        Endpoint := NewEndpoint;
        Deployment := NewDeployment;
        ApiKey := NewApiKey;
    end;

    [NonDebuggable]
    procedure SetFirstPartyAuthorization(NewDeployment: Text)
    begin
        ClearVariables();

        ResourceUtilization := Enum::"AOAI Resource Utilization"::"First Party";
        ManagedResourceDeployment := NewDeployment;
    end;

    [NonDebuggable]
    procedure GetEndpoint(): SecretText
    begin
        exit(Endpoint);
    end;

    [NonDebuggable]
    procedure GetDeployment(): SecretText
    begin
        exit(Deployment);
    end;

    [NonDebuggable]
    procedure GetApiKey(): SecretText
    begin
        exit(ApiKey);
    end;

    [NonDebuggable]
    procedure GetManagedResourceDeployment(): SecretText
    begin
        exit(ManagedResourceDeployment);
    end;

    procedure GetResourceUtilization(): Enum "AOAI Resource Utilization"
    begin
        exit(ResourceUtilization);
    end;

    local procedure ClearVariables()
    begin
        Clear(Endpoint);
        Clear(ApiKey);
        Clear(Deployment);
        Clear(AOAIAccountName);
        Clear(ManagedResourceDeployment);
        Clear(ResourceUtilization);
    end;
}
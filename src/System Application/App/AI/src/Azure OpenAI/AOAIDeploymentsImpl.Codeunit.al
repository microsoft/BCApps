// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System.Telemetry;

codeunit 7769 "AOAI Deployments Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        Telemetry: Codeunit Telemetry;
        GPT41LatestLbl: Label 'gpt-41-latest', Locked = true;
        GPT41PreviewLbl: Label 'gpt-41-preview', Locked = true;
        GPT41MiniLatestLbl: Label 'gpt-41-mini-latest', Locked = true;
        GPT41MiniPreviewLbl: Label 'gpt-41-mini-preview', Locked = true;
        GPT53ChatLatestLbl: Label 'gpt-53-chat-latest', Locked = true;
        GPT53ChatPreviewLbl: Label 'gpt-53-chat-preview', Locked = true;
        GPT55ChatLatestLbl: Label 'gpt-55-chat-latest', Locked = true;
        GPT55ChatPreviewLbl: Label 'gpt-55-chat-preview', Locked = true;
        DeprecatedDeployments: Dictionary of [Text, Date];
        DeprecationDatesInitialized: Boolean;
        DeprecationMessageLbl: Label 'We detected usage of the Azure OpenAI deployment "%1". This model is obsoleted starting %2 and the quality of your results might vary after that date. Check out codeunit 7768 AOAI Deployments to find the supported deployments.', Comment = 'Telemetry message where %1 is the name of the deployment and %2 is the date of deprecation';

    procedure GetGPT41Preview(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT41PreviewLbl));
    end;

    procedure GetGPT41Latest(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT41LatestLbl));
    end;

    procedure GetGPT41MiniPreview(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT41MiniPreviewLbl));
    end;

    procedure GetGPT41MiniLatest(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT41MiniLatestLbl));
    end;

    procedure GetGPT53ChatLatest(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT53ChatLatestLbl));
    end;

    procedure GetGPT53ChatPreview(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT53ChatPreviewLbl));
    end;

    procedure GetGPT55ChatLatest(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT55ChatLatestLbl));
    end;

    procedure GetGPT55ChatPreview(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT55ChatPreviewLbl));
    end;

    // Initializes dictionary of deprecated models
    local procedure InitializeDeploymentDeprecationDates()
    begin
        if DeprecationDatesInitialized then
            exit;

        // Add deprecated deployments with their deprecation dates here:
        DeprecationDatesInitialized := true;
    end;

    // Application Insights telemetry on deprecated models
    local procedure LogDeprecationTelemetry(DeploymentName: Text)
    var
        CustomDimensions: Dictionary of [Text, Text];
        IsDeprecated: Boolean;
        DeprecatedDate: Date;
    begin
        InitializeDeploymentDeprecationDates();
        IsDeprecated := DeprecatedDeployments.ContainsKey(DeploymentName);
        if IsDeprecated then begin
            DeprecatedDate := DeprecatedDeployments.Get(DeploymentName);
            CustomDimensions.Add('DeploymentName', DeploymentName);
            CustomDimensions.Add('DeprecationDate', Format(DeprecatedDate));
            Telemetry.LogMessage('0000AD1',
                StrSubstNo(DeprecationMessageLbl, DeploymentName, DeprecatedDate),
                Verbosity::Warning,
                DataClassification::SystemMetadata,
                Enum::"AL Telemetry Scope"::All,
                CustomDimensions);
        end;
    end;

    local procedure GetDeploymentName(DeploymentName: Text): Text
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        LogDeprecationTelemetry(DeploymentName);

        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);

        exit(DeploymentName);
    end;
}
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

#if not CLEAN25
using System.Environment;
#endif
using System.Telemetry;

codeunit 7769 "AOAI Deployments Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        Telemetry: Codeunit Telemetry;
#if not CLEAN27
        GPT4oLatestLbl: Label 'gpt-4o-latest', Locked = true;
        GPT4oPreviewLbl: Label 'gpt-4o-preview', Locked = true;
        GPT4oMiniLatestLbl: Label 'gpt-4o-mini-latest', Locked = true;
        GPT4oMiniPreviewLbl: Label 'gpt-4o-mini-preview', Locked = true;
#endif
        GPT41LatestLbl: Label 'gpt-41-latest', Locked = true;
        GPT41PreviewLbl: Label 'gpt-41-preview', Locked = true;
        GPT41MiniLatestLbl: Label 'gpt-41-mini-latest', Locked = true;
        GPT41MiniPreviewLbl: Label 'gpt-41-mini-preview', Locked = true;
        DeprecatedDeployments: Dictionary of [Text, Date];
        DeprecationDatesInitialized: Boolean;
        DeprecationMessageLbl: Label 'We detected usage of the Azure OpenAI deployment "%1". This model is obsoleted starting %2 and the quality of your results might vary after that date. Check out codeunit 7768 AOAI Deployments to find the supported deployments.', Comment = 'Telemetry message where %1 is the name of the deployment and %2 is the date of deprecation';
#if not CLEAN25
        GPT4LatestLbl: Label 'gpt-4-latest', Locked = true;
        GPT4PreviewLbl: Label 'gpt-4-preview', Locked = true;
        GPT35TurboLatestLbl: Label 'gpt-35-turbo-latest', Locked = true;
        GPT35TurboPreviewLbl: Label 'gpt-35-turbo-preview', Locked = true;
        Turbo0301SaasLbl: Label 'turbo-0301', Locked = true;
        GPT40613SaasLbl: Label 'gpt4-0613', Locked = true;
        Turbo0613SaasLbl: Label 'turbo-0613', Locked = true;
        Turbo0301Lbl: Label 'chatGPT_GPT35-turbo-0301', Locked = true;
        GPT40613Lbl: Label 'gpt-4-32k', Locked = true;
        Turbo031316kLbl: Label 'gpt-35-turbo-16k', Locked = true;

    procedure GetTurbo0301(CallerModuleInfo: ModuleInfo): Text
    var
        EnviromentInformation: Codeunit "Environment Information";
    begin
        if EnviromentInformation.IsSaaS() then
            exit(GetDeploymentName(Turbo0301SaasLbl));

        exit(Turbo0301Lbl);
    end;

    procedure GetGPT40613(CallerModuleInfo: ModuleInfo): Text
    var
        EnviromentInformation: Codeunit "Environment Information";
    begin
        if EnviromentInformation.IsSaaS() then
            exit(GetDeploymentName(GPT40613SaasLbl));

        exit(GPT40613Lbl);
    end;

    procedure GetTurbo0613(CallerModuleInfo: ModuleInfo): Text
    var
        EnviromentInformation: Codeunit "Environment Information";
    begin
        if EnviromentInformation.IsSaaS() then
            exit(GetDeploymentName(Turbo0613SaasLbl));

        exit(Turbo031316kLbl);
    end;

    procedure GetGPT35TurboPreview(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT35TurboPreviewLbl));
    end;

    procedure GetGPT35TurboLatest(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT35TurboLatestLbl));
    end;

    procedure GetGPT4Preview(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT4PreviewLbl));
    end;

    procedure GetGPT4Latest(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT4LatestLbl));
    end;
#endif
#if not CLEAN27
    procedure GetGPT4oPreview(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT4oPreviewLbl));
    end;

    procedure GetGPT4oLatest(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT4oLatestLbl));
    end;

    procedure GetGPT4oMiniPreview(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT4oMiniPreviewLbl));
    end;

    procedure GetGPT4oMiniLatest(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT4oMiniLatestLbl));
    end;
#endif
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

    // Initializes dictionary of deprecated models
    local procedure InitializeDeploymentDeprecationDates()
    begin
        if DeprecationDatesInitialized then
            exit;

        // Add deprecated deployments with their deprecation dates here:
#if not CLEAN25
        DeprecatedDeployments.Add(GPT4LatestLbl, DMY2Date(1, 11, 2024));
        DeprecatedDeployments.Add(GPT4PreviewLbl, DMY2Date(1, 11, 2024));
        DeprecatedDeployments.Add(GPT35TurboLatestLbl, DMY2Date(1, 11, 2024));
        DeprecatedDeployments.Add(GPT35TurboPreviewLbl, DMY2Date(1, 11, 2024));
        DeprecatedDeployments.Add(Turbo0301SaasLbl, DMY2Date(1, 11, 2024));
        DeprecatedDeployments.Add(GPT40613SaasLbl, DMY2Date(1, 11, 2024));
        DeprecatedDeployments.Add(Turbo0613SaasLbl, DMY2Date(1, 11, 2024));
#endif
#if not CLEAN27
        DeprecatedDeployments.Add(GPT4oLatestLbl, DMY2Date(15, 7, 2025));
        DeprecatedDeployments.Add(GPT4oPreviewLbl, DMY2Date(15, 7, 2025));
        DeprecatedDeployments.Add(GPT4oMiniLatestLbl, DMY2Date(15, 7, 2025));
        DeprecatedDeployments.Add(GPT4oMiniPreviewLbl, DMY2Date(15, 7, 2025));
#endif
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
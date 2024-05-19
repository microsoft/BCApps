// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

#if not CLEAN25
using System.Environment;
#endif

codeunit 7769 "AOAI Deployments Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        UnableToGetDeploymentNameErr: Label 'Unable to get deployment name, if this is a third party capability you must specify your own deployment name. You may need to contact your partner.';
        GPT4LatestLbl: Label 'gpt-4-latest', Locked = true;
        GPT4PreviewLbl: Label 'gpt-4-preview', Locked = true;
        GPT35TurboLatestLbl: Label 'gpt-35-turbo-latest', Locked = true;
        GPT35TurboPreviewLbl: Label 'gpt-35-turbo-preview', Locked = true;
#if not CLEAN25
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
            exit(GetDeploymentName(Turbo0301SaasLbl, CallerModuleInfo));

        exit(Turbo0301Lbl);
    end;

    procedure GetGPT40613(CallerModuleInfo: ModuleInfo): Text
    var
        EnviromentInformation: Codeunit "Environment Information";
    begin
        if EnviromentInformation.IsSaaS() then
            exit(GetDeploymentName(GPT40613SaasLbl, CallerModuleInfo));

        exit(GPT40613Lbl);
    end;

    procedure GetTurbo0613(CallerModuleInfo: ModuleInfo): Text
    var
        EnviromentInformation: Codeunit "Environment Information";
    begin
        if EnviromentInformation.IsSaaS() then
            exit(GetDeploymentName(Turbo0613SaasLbl, CallerModuleInfo));

        exit(Turbo031316kLbl);
    end;
#endif

    procedure GetGPT35TurboPreview(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT35TurboPreviewLbl, CallerModuleInfo));
    end;

    procedure GetGPT35TurboLatest(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT35TurboLatestLbl, CallerModuleInfo));
    end;

    procedure GetGPT4Preview(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT4PreviewLbl, CallerModuleInfo));
    end;

    procedure GetGPT4Latest(CallerModuleInfo: ModuleInfo): Text
    begin
        exit(GetDeploymentName(GPT4LatestLbl, CallerModuleInfo));
    end;

    local procedure GetDeploymentName(DeploymentName: Text; CallerModuleInfo: ModuleInfo): Text
    var
        AzureOpenAiImpl: Codeunit "Azure OpenAI Impl";
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if (CallerModuleInfo.Publisher <> CurrentModuleInfo.Publisher) and not AzureOpenAiImpl.IsTenantAllowlistedForFirstPartyCopilotCalls() then
            Error(UnableToGetDeploymentNameErr);

        exit(DeploymentName);
    end;
}
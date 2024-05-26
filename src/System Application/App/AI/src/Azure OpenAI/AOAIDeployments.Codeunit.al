// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// This codeunit is used to get the AOAI deployment names.
/// </summary>
codeunit 7768 "AOAI Deployments"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AOAIDeploymentsImpl: Codeunit "AOAI Deployments Impl";

#if not CLEAN25
    /// <summary>
    /// Returns the name of the AOAI deployment model Turbo 0301.
    /// </summary>
    /// <returns>The deployment name.</returns>
    [Obsolete('Specific deployment names are no longer supported. Use GetGPT35TurboLatest and GetGPT4Latest instead (or GetGPT35TurboPreview and GetGPT4Preview for testing upcoming versions).', '25.0')]
    procedure GetTurbo0301(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetTurbo0301(CallerModuleInfo));
    end;

    /// <summary>
    /// Returns the name of the AOAI deployment model GPT4 0613.
    /// </summary>
    /// <returns>The deployment name.</returns>
    [Obsolete('Specific deployment names are no longer supported. Use GetGPT35TurboLatest and GetGPT4Latest instead (or GetGPT35TurboPreview and GetGPT4Preview for testing upcoming versions).', '25.0')]
    procedure GetGPT40613(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT40613(CallerModuleInfo));
    end;

    /// <summary>
    /// Returns the name of the AOAI deployment model Turbo 0613.
    /// </summary>
    /// <returns>The deployment name.</returns>
    [Obsolete('Specific deployment names are no longer supported. Use GetGPT35TurboLatest and GetGPT4Latest instead (or GetGPT35TurboPreview and GetGPT4Preview for testing upcoming versions).', '25.0')]
    procedure GetTurbo0613(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetTurbo0613(CallerModuleInfo));
    end;
#endif

    /// <summary>
    /// Returns the name of the latest AOAI deployment model of GPT3.5 Turbo.
    /// </summary>
    /// <returns>The deployment name.</returns>
    procedure GetGPT35TurboLatest(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT35TurboLatest(CallerModuleInfo));
    end;

    /// <summary>
    /// Returns the name of preview AOAI deployment model of GPT3.5 Turbo.
    /// </summary>
    /// <returns>The deployment name.</returns>
    procedure GetGPT35TurboPreview(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT35TurboPreview(CallerModuleInfo));
    end;

    /// <summary>
    /// Returns the name of the latest AOAI deployment model of GPT4.
    /// </summary>
    /// <returns>The deployment name.</returns>
    procedure GetGPT4Latest(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT4Latest(CallerModuleInfo));
    end;

    /// <summary>
    /// Returns the name of preview AOAI deployment model of GPT4.
    /// </summary>
    /// <returns>The deployment name.</returns>
    procedure GetGPT4Preview(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT4Preview(CallerModuleInfo));
    end;
}
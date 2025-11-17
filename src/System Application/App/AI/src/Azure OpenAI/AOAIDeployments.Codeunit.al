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

#if not CLEAN27
    /// <summary>
    /// Returns the name of the latest AOAI deployment model of GPT4o.
    /// </summary>
    /// <returns>The deployment name.</returns>
    [Obsolete('GPT4o deployment name is no longer supported from 15 July 2025. Use GetGPT41Latest instead (or GetGPT41Preview for testing upcoming versions).', '27.0')]
    procedure GetGPT4oLatest(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT4oLatest(CallerModuleInfo));
    end;

    /// <summary>
    /// Returns the name of preview AOAI deployment model of GPT4o.
    /// </summary>
    /// <returns>The deployment name.</returns>
    [Obsolete('GPT4o deployment name is no longer supported from 15 July 2025. Use GetGPT41Latest instead (or GetGPT41Preview for testing upcoming versions).', '27.0')]
    procedure GetGPT4oPreview(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT4oPreview(CallerModuleInfo));
    end;

    /// <summary>
    /// Returns the name of the latest AOAI deployment model of GPT4o-Mini.
    /// </summary>
    /// <returns>The deployment name.</returns>
    [Obsolete('GPT4o mini deployment name is no longer supported from 15 July 2025. Use GetGPT41Latest instead (or GetGPT41Preview for testing upcoming versions).', '27.0')]
    procedure GetGPT4oMiniLatest(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT4oMiniLatest(CallerModuleInfo));
    end;

    /// <summary>
    /// Returns the name of preview AOAI deployment model of GPT4o-Mini.
    /// </summary>
    /// <returns>The deployment name.</returns>
    [Obsolete('GPT4o mini deployment name is no longer supported from 15 July 2025. Use GetGPT41Latest instead (or GetGPT41Preview for testing upcoming versions).', '27.0')]
    procedure GetGPT4oMiniPreview(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT4oMiniPreview(CallerModuleInfo));
    end;
#endif

    /// <summary>
    /// Returns the name of the latest AOAI deployment model of GPT-4.1.
    /// </summary>
    /// <returns>The deployment name.</returns>
    procedure GetGPT41Latest(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT41Latest(CallerModuleInfo));
    end;

    /// <summary>
    /// Returns the name of the preview AOAI deployment model of GPT-4.1.
    /// </summary>
    /// <returns>The deployment name.</returns>
    procedure GetGPT41Preview(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT41Preview(CallerModuleInfo));
    end;

    /// <summary>
    /// Returns the name of the latest AOAI deployment model of GPT-4.1 mini.
    /// </summary>
    /// <returns>The deployment name.</returns>
    procedure GetGPT41MiniLatest(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT41MiniLatest(CallerModuleInfo));
    end;

    /// <summary>
    /// Returns the name of the preview AOAI deployment model of GPT-4.1 mini.
    /// </summary>
    /// <returns>The deployment name.</returns>
    procedure GetGPT41MiniPreview(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT41MiniPreview(CallerModuleInfo));
    end;
}
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

    /// <summary>
    /// Returns the name of the latest AOAI deployment model of GPT-5.3 chat.
    /// </summary>
    /// <returns>The deployment name.</returns>
    procedure GetGPT53ChatLatest(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT53ChatLatest(CallerModuleInfo));
    end;

    /// <summary>
    /// Returns the name of the preview AOAI deployment model of GPT-5.3 chat.
    /// </summary>
    /// <returns>The deployment name.</returns>
    procedure GetGPT53ChatPreview(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT53ChatPreview(CallerModuleInfo));
    end;

#if not CLEAN30
    /// <summary>
    /// Returns the name of the latest AOAI deployment model of GPT-5.5 chat.
    /// </summary>
    /// <returns>The deployment name.</returns>
    [Obsolete('GPT-5.5 chat deployment name is no longer supported from 11 September 2026. Use GetGPT56ChatLatest instead (or GetGPT56ChatPreview for testing upcoming versions).', '30.0')]
    procedure GetGPT55ChatLatest(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT55ChatLatest(CallerModuleInfo));
    end;

    /// <summary>
    /// Returns the name of the preview AOAI deployment model of GPT-5.5 chat.
    /// </summary>
    /// <remarks>Use GetGPT56ChatPreview when the chat messages contain file content parts.</remarks>
    /// <returns>The deployment name.</returns>
    [Obsolete('GPT-5.5 chat deployment name is no longer supported from 11 September 2026. Use GetGPT56ChatLatest instead (or GetGPT56ChatPreview for testing upcoming versions).', '30.0')]
    procedure GetGPT55ChatPreview(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT55ChatPreview(CallerModuleInfo));
    end;
#endif

    /// <summary>
    /// Returns the name of the latest AOAI deployment model of GPT-5.6 chat.
    /// </summary>
    /// <returns>The deployment name.</returns>
    procedure GetGPT56ChatLatest(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT56ChatLatest(CallerModuleInfo));
    end;

    /// <summary>
    /// Returns the name of the preview AOAI deployment model of GPT-5.6 chat.
    /// </summary>
    /// <remarks>Use this deployment when the chat messages contain file content parts.</remarks>
    /// <returns>The deployment name.</returns>
    procedure GetGPT56ChatPreview(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT56ChatPreview(CallerModuleInfo));
    end;
}
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

    /// <summary>
    /// Returns the name of the AOAI deployment model Turbo 0301.
    /// </summary>
    /// <returns>The deployment name.</returns>
    [NonDebuggable]
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
    [NonDebuggable]
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
    [NonDebuggable]
    procedure GetTurbo0613(): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetTurbo0613(CallerModuleInfo));
    end;

    /// <summary>
    /// Returns the name of the latest AOAI deployment model of GPT3.5 Turbo.
    /// </summary>
    /// <returns>The deployment name.</returns>
    [NonDebuggable]
    procedure GetGPT35Turbo(ModelVersion: Enum "AOAI Deployment Version"): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT35Turbo(CallerModuleInfo));
    end;

    /// <summary>
    /// Returns the name of preview or latest AOAI deployment model of GPT3.5 Turbo.
    /// </summary>
    /// <param name="Preview">If true, returns the name of the preview deployment model.
    /// Otherwise, returns the name of the latest deployment model.</param>
    /// <returns>The deployment name.</returns>
    [NonDebuggable]
    procedure GetGPT35Turbo(ModelVersion: Enum "AOAI Deployment Version"; Preview: Boolean): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT35Turbo(CallerModuleInfo, Preview));
    end;

    /// <summary>
    /// Returns the name of the latest AOAI deployment model of GPT4.
    /// </summary>
    /// <returns>The deployment name.</returns>
    [NonDebuggable]
    procedure GetGPT4(ModelVersion: Enum "AOAI Deployment Version"): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT4(CallerModuleInfo));
    end;

    /// <summary>
    /// Returns the name of preview or latest AOAI deployment model of GPT4.
    /// </summary>
    /// <param name="Preview">If true, returns the name of the preview deployment model.
    /// Otherwise, returns the name of the latest deployment model.</param>
    /// <returns>The deployment name.</returns>
    [NonDebuggable]
    procedure GetGPT4(ModelVersion: Enum "AOAI Deployment Version"; Preview: Boolean): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AOAIDeploymentsImpl.GetGPT4(CallerModuleInfo, Preview));
    end;
}
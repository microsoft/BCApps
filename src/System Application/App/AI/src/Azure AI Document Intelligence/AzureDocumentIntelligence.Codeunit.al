// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI.DocumentIntelligence;

using System.AI;

/// <summary>
/// Provides functionality to invoke Azure Document Intelligence services.
/// </summary>
codeunit 7780 "Azure Document Intelligence"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AzureDIImpl: Codeunit "Azure DI Impl.";

    /// <summary>
    /// Analyze the invoice.
    /// </summary>
    /// <param name="Base64Data">Data to analyze.</param>
    /// <returns>The analyzed result.</returns>
    [Scope('OnPrem')]
    procedure AnalyzeInvoice(Base64Data: Text): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AzureDIImpl.AnalyzeInvoice(Base64Data, CallerModuleInfo));
    end;

    /// <summary>
    /// Analyze the Receipt.
    /// </summary>
    /// <param name="Base64Data">Data to analyze.</param>
    /// <returns>The analyzed result.</returns>
    [Scope('OnPrem')]
    procedure AnalyzeReceipt(Base64Data: Text): Text
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(AzureDIImpl.AnalyzeReceipt(Base64Data, CallerModuleInfo));
    end;

    /// <summary>
    /// Register a capability for Azure Document Intelligence.
    /// </summary>
    /// <param name="CopilotCapability">The capability.</param>
    /// <param name="CopilotAvailability">The availability.</param>
    /// <param name="LearnMoreUrl">The learn more url.</param>
    procedure RegisterCopilotCapability(CopilotCapability: Enum "Copilot Capability"; CopilotAvailability: Enum "Copilot Availability"; LearnMoreUrl: Text[2048])
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        AzureDIImpl.RegisterCopilotCapability(CopilotCapability, CopilotAvailability, LearnMoreUrl, CallerModuleInfo);
    end;

    /// <summary>
    /// Sets the copilot capability that the API is running for.
    /// </summary>
    /// <param name="CopilotCapability">The copilot capability to set.</param>
    procedure SetCopilotCapability(CopilotCapability: Enum "Copilot Capability")
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        AzureDIImpl.SetCopilotCapability(CopilotCapability, CallerModuleInfo);
    end;

}
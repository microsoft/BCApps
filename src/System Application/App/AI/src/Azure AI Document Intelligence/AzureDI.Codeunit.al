// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Azure.DI;

using System.AI;

/// <summary>
/// Azure Document Intelligence implementation.
/// </summary>
codeunit 7780 "Azure DI"
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
    /// Sets the copilot capability that the API is running for.
    /// </summary>
    /// <param name="CopilotCapability">The copilot capability to set.</param>
    [NonDebuggable]
    procedure SetCopilotCapability(CopilotCapability: Enum "Copilot Capability")
    var
        CopilotCapabilityImpl: Codeunit "Copilot Capability Impl";
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CopilotCapabilityImpl.SetCopilotCapability(CopilotCapability, CallerModuleInfo, AzureDIImpl.GetAzureAIDocumentIntelligenceCategory());
    end;

}
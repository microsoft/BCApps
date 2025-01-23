// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Azure.DI;

/// <summary>
/// Azure Document Intelligence implementation.
/// </summary>
codeunit 9970 "Azure DI"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AzureOpenAIImpl: Codeunit "Azure DI Impl.";


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
        exit(AzureOpenAIImpl.AnalyzeInvoice(Base64Data, CallerModuleInfo));
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
        exit(AzureOpenAIImpl.AnalyzeReceipt(Base64Data, CallerModuleInfo));
    end;


}
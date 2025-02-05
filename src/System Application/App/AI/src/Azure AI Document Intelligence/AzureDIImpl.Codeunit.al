// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI.DocumentIntelligence;

using System.Privacy;
using System.Telemetry;
using System;
using System.AI;

/// <summary>
/// Azure Document Intelligence implementation.
/// </summary>
codeunit 7779 "Azure DI Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CopilotCapabilityImpl: Codeunit "Copilot Capability Impl";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        AzureDocumentIntelligenceCapabilityTok: Label 'ADI', Locked = true;
        TelemetryAnalyzeInvoiceFailureLbl: Label 'Analyze invoice failed.', Locked = true;
        TelemetryAnalyzeInvoiceCompletedLbl: Label 'Analyze invoice completed.', Locked = true;
        TelemetryAnalyzeReceiptFailureLbl: Label 'Analyze receipt failed.', Locked = true;
        TelemetryAnalyzeReceiptCompletedLbl: Label 'Analyze receipt completed.', Locked = true;
        GenerateRequestFailedErr: Label 'The request did not return a success status code.';
        AzureAiDocumentIntelligenceTxt: Label 'Azure AI Document Intelligence', Locked = true;


    procedure SetCopilotCapability(Capability: Enum "Copilot Capability"; CallerModuleInfo: ModuleInfo; AzureAIServiceName: Text)
    begin
        CopilotCapabilityImpl.SetCopilotCapability(Capability, CallerModuleInfo, AzureAIServiceName);
    end;

    /// <summary>
    /// Analyze a single invoice.
    /// </summary>
    /// <param name="Base64Data">Data to analyze.</param>
    /// <param name="CallerModuleInfo">The module info of the caller.</param>
    /// <returns>The analyzed result.</returns>
    procedure AnalyzeInvoice(Base64Data: Text; CallerModuleInfo: ModuleInfo) Result: Text
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CopilotCapabilityImpl.CheckCapabilitySet();
        CopilotCapabilityImpl.CheckEnabled(CallerModuleInfo, Enum::"Azure AI Service Type"::"Azure Document Intelligence");
        CopilotCapabilityImpl.AddTelemetryCustomDimensions(CustomDimensions, CallerModuleInfo);

        if not SendRequest(Base64Data, Enum::"ADI Model Type"::Invoice, CallerModuleInfo, Result) then begin
            FeatureTelemetry.LogError('0000OLK', AzureDocumentIntelligenceCapabilityTok, TelemetryAnalyzeInvoiceFailureLbl, GetLastErrorText(), '', Enum::"AL Telemetry Scope"::All, CustomDimensions);
            exit;
        end;

        FeatureTelemetry.LogUsage('0000OLM', AzureDocumentIntelligenceCapabilityTok, TelemetryAnalyzeInvoiceCompletedLbl, Enum::"AL Telemetry Scope"::All, CustomDimensions);

    end;

    /// <summary>
    /// Analyze a single receipt.
    /// </summary>
    /// <param name="Base64Data">Data to analyze.</param>
    /// <param name="CallerModuleInfo">The module info of the caller.</param>
    /// <returns>The analyzed result.</returns>
    procedure AnalyzeReceipt(Base64Data: Text; CallerModuleInfo: ModuleInfo) Result: Text
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CopilotCapabilityImpl.CheckCapabilitySet();
        CopilotCapabilityImpl.CheckEnabled(CallerModuleInfo, Enum::"Azure AI Service Type"::"Azure Document Intelligence");
        CopilotCapabilityImpl.AddTelemetryCustomDimensions(CustomDimensions, CallerModuleInfo);

        if not SendRequest(Base64Data, Enum::"ADI Model Type"::Receipt, CallerModuleInfo, Result) then begin
            FeatureTelemetry.LogError('0000OLL', AzureDocumentIntelligenceCapabilityTok, TelemetryAnalyzeReceiptFailureLbl, GetLastErrorText(), '', Enum::"AL Telemetry Scope"::All, CustomDimensions);
            exit;
        end;

        FeatureTelemetry.LogUsage('0000OLN', AzureDocumentIntelligenceCapabilityTok, TelemetryAnalyzeReceiptCompletedLbl, Enum::"AL Telemetry Scope"::All, CustomDimensions);
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure SendRequest(Base64Data: Text; ModelType: Enum "ADI Model Type"; CallerModuleInfo: ModuleInfo; var Result: Text)
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        ALCopilotCapability: DotNet ALCopilotCapability;
        ALCopilotResponse: DotNet ALCopilotOperationResponse;
        ErrorMsg: Text;
    begin
        ClearLastError();
        ALCopilotCapability := ALCopilotCapability.ALCopilotCapability(CallerModuleInfo.Publisher(), CallerModuleInfo.Id(), Format(CallerModuleInfo.AppVersion()), AzureDocumentIntelligenceCapabilityTok);
        case ModelType of
            Enum::"ADI Model Type"::Invoice:
                ALCopilotResponse := ALCopilotFunctions.GenerateInvoiceIntelligence(GenerateJsonForSingleInput(Base64Data), ALCopilotCapability);
            Enum::"ADI Model Type"::Receipt:
                ALCopilotResponse := ALCopilotFunctions.GenerateReceiptIntelligence(GenerateJsonForSingleInput(Base64Data), ALCopilotCapability);
        end;
        ErrorMsg := ALCopilotResponse.ErrorText();
        if ErrorMsg <> '' then
            Error(ErrorMsg);

        if not ALCopilotResponse.IsSuccess() then
            Error(GenerateRequestFailedErr);

        Result := ALCopilotResponse.Result();
    end;

    local procedure GenerateJsonForSingleInput(Base64: Text): Text
    var
        JsonObject: JsonObject;
        InputsObject: JsonObject;
        InnerObject: JsonObject;
        JsonText: Text;
    begin
        // Create the inner object with the base64Encoded property  
        InnerObject.Add('base64_encoded', Base64);
        // Create the inputs object and add the inner object to it  
        InputsObject.Add('1', InnerObject);
        // Create the main JSON object and add the inputs object to it  
        JsonObject.Add('inputs', InputsObject);
        // Convert the JSON object to text  
        JsonObject.WriteTo(JsonText);
        // Return the JSON text  
        exit(JsonText);
    end;

    procedure GetAzureAIDocumentIntelligenceCategory(): Code[50]
    begin
        exit(AzureAiDocumentIntelligenceTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Privacy Notice", OnRegisterPrivacyNotices, '', false, false)]
    local procedure CreatePrivacyNoticeRegistrations(var TempPrivacyNotice: Record "Privacy Notice" temporary)
    begin
        TempPrivacyNotice.Init();
        TempPrivacyNotice.ID := GetAzureAIDocumentIntelligenceCategory();
        TempPrivacyNotice."Integration Service Name" := GetAzureAIDocumentIntelligenceCategory();
        if not TempPrivacyNotice.Insert() then;
    end;



}
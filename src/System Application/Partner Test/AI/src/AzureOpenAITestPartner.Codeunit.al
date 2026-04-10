// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Partner.Test.AI;

using System.AI;
using System.Privacy;
using System.TestLibraries.AI;
using System.TestLibraries.Utilities;

codeunit 139021 "Azure OpenAI Test Partner"
{
    Subtype = Test;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        LibraryAssert: Codeunit "Library Assert";
        Any: Codeunit Any;
        AzureOpenAiTxt: Label 'Azure OpenAI', Locked = true;
        EndpointTxt: Label 'https://resourcename.openai.azure.com/', Locked = true;
        DeploymentTxt: Label 'deploymentid', Locked = true;
        ManagedResourceDeploymentTxt: Label 'Managed AI Resource', Locked = true;
        LearMoreUrlLbl: Label 'http://LearnMore.com', Locked = true;
        BillingTypeAuthorizationErr: Label 'Usage of AI resources not authorized with chosen billing type, Capability: %1, Billing Type: %2. Please contact your system administrator.', Comment = '%1 is the capability name, %2 is the billing type';

    [Test]
    [Scope('OnPrem')]
    procedure GenerateTextCompletionsBillingTypeAuthorizationErr()
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        PrivacyNotice: Codeunit "Privacy Notice";
        CopilotSettingsTestLibrary: Codeunit "Copilot Settings Test Library";
        CurrentModuleInfo: ModuleInfo;
        Metaprompt: Text;
        ErrorMessage: Text;
    begin
        // Initialize the Copilot Settings Test Library
        CopilotSettingsTestLibrary.DeleteAll();

        // [SCENARIO] GenerateTextCompletion returns an error when generate complete is called

        // [GIVEN] The privacy notice is agreed to
        // [GIVEN] The authorization key is set
        PrivacyNotice.SetApprovalState(AzureOpenAITxt, "Privacy Notice Approval State"::Agreed);
        //AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Text Completions", EndpointTxt, DeploymentTxt, Any.AlphanumericText(10));
        AzureOpenAI.SetManagedResourceAuthorization(Enum::"AOAI Model Type"::"Text Completions", ManagedResourceDeploymentTxt);

        // [GIVEN] Capability is set
        RegisterCapabilityWithBillingType(Enum::"Copilot Capability"::"Text Partner Capability", Enum::"Copilot Availability"::"Preview", Enum::"Copilot Billing Type"::"Custom Billed");
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Text Partner Capability");

        // [THEN] Copilot capability is registered
        LibraryAssert.IsTrue(CopilotSettingsTestLibrary.FindFirst(), 'Copilot capability should be registered');
        LibraryAssert.AreEqual(Enum::"Copilot Capability"::"Text Partner Capability", CopilotSettingsTestLibrary.GetCapability(), 'Copilot capability is not "Text Capability"');
        LibraryAssert.AreEqual(Enum::"Copilot Billing Type"::"Custom Billed", CopilotSettingsTestLibrary.GetBillingType(), 'Billing type is not "Custom Billed"');

        // [THEN] Registered capability is associated with the current module
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        LibraryAssert.AreEqual(CurrentModuleInfo.Id(), CopilotSettingsTestLibrary.GetAppId(), 'App Id is different from the current module');
        LibraryAssert.AreEqual(CurrentModuleInfo.Publisher(), CopilotSettingsTestLibrary.GetPublisher(), 'Publisher is different from the current module');
        LibraryAssert.AreEqual(CurrentModuleInfo.Publisher(), 'Partner', 'CurrentModule Publisher is Microsoft');

        Metaprompt := 'metaprompt';

        // [WHEN] GenerateTextCompletion is called
        AzureOpenAI.GenerateTextCompletion(Metaprompt, Any.AlphanumericText(10), AOAIOperationResponse);

        // [THEN] GenerateTextCompletion returns an error [CAPI with Partner Billed - Not allowed for Partner published capabilities]
        LibraryAssert.AreEqual(AOAIOperationResponse.IsSuccess(), false, 'AOAI Operation Response should be an error');
        ErrorMessage := StrSubstNo(BillingTypeAuthorizationErr, Enum::"Copilot Capability"::"Text Partner Capability", Enum::"Copilot Billing Type"::"Custom Billed");
        LibraryAssert.ExpectedError(ErrorMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateEmbeddingsBillingTypeAuthorizationErr()
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        PrivacyNotice: Codeunit "Privacy Notice";
        ErrorMessage: Text;
    begin
        // [SCENARIO] GenerateEmbeddings returns an error when generate complete is called

        // [GIVEN] The privacy notice is agreed to
        // [GIVEN] The authorization key is set
        PrivacyNotice.SetApprovalState(AzureOpenAITxt, "Privacy Notice Approval State"::Agreed);
        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::Embeddings, EndpointTxt, DeploymentTxt, Any.AlphanumericText(10));

        // [GIVEN] Capability is set
        RegisterCapabilityWithBillingType(Enum::"Copilot Capability"::"Embedding Partner Capability", Enum::"Copilot Availability"::"Preview", Enum::"Copilot Billing Type"::"Microsoft Billed");
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Embedding Partner Capability");

        // [WHEN] GenerateEmbeddings is called
        AzureOpenAI.GenerateEmbeddings(Any.AlphanumericText(10), AOAIOperationResponse);

        // [THEN] GenerateEmbeddings returns an error [BYO with Microsoft Billed - Not allowed for Partner published capabilities]
        LibraryAssert.AreEqual(AOAIOperationResponse.IsSuccess(), false, 'AOAI Operation Response should be an error');
        ErrorMessage := StrSubstNo(BillingTypeAuthorizationErr, Enum::"Copilot Capability"::"Embedding Partner Capability", Enum::"Copilot Billing Type"::"Microsoft Billed");
        LibraryAssert.ExpectedError(ErrorMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateChatCompletionBillingTypeAuthorizationErr()
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        PrivacyNotice: Codeunit "Privacy Notice";
        ErrorMessage: Text;
    begin
        // [SCENARIO] GenerateEmbeddings returns an error when generate chat complete is called

        // [GIVEN] The authorization key is set
        PrivacyNotice.SetApprovalState(AzureOpenAITxt, "Privacy Notice Approval State"::Agreed);
        AzureOpenAI.SetManagedResourceAuthorization(Enum::"AOAI Model Type"::"Chat Completions", ManagedResourceDeploymentTxt);

        // [GIVEN] Capability is set
        RegisterCapabilityWithBillingType(Enum::"Copilot Capability"::"Chat Partner Capability", Enum::"Copilot Availability"::"Generally Available", Enum::"Copilot Billing Type"::"Not Billed");
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Chat Partner Capability");

        // [WHEN] GenerateChatCompletion is called
        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIOperationResponse);

        // [THEN] GenerateChatCompletion fails [CAPI with Free billing type - Not allowed for Partner published capabilities]
        LibraryAssert.AreEqual(AOAIOperationResponse.IsSuccess(), false, 'AOAI Operation Response should be an error');
        ErrorMessage := StrSubstNo(BillingTypeAuthorizationErr, Enum::"Copilot Capability"::"Chat Partner Capability", Enum::"Copilot Billing Type"::"Not Billed");
        LibraryAssert.ExpectedError(ErrorMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateChatCompletionWoAOAIBillingTypeAuthErr()
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        PrivacyNotice: Codeunit "Privacy Notice";
        ErrorMessage: Text;
    begin
        // [SCENARIO] GenerateEmbeddings returns an error when generate chat complete is called

        // [GIVEN] The authorization key is set
        PrivacyNotice.SetApprovalState(AzureOpenAITxt, "Privacy Notice Approval State"::Agreed);
        AzureOpenAI.SetManagedResourceAuthorization(Enum::"AOAI Model Type"::"Chat Completions", ManagedResourceDeploymentTxt);

        // [GIVEN] Capability is set
        RegisterCapabilityWithBillingType(Enum::"Copilot Capability"::"Chat Partner Capability", Enum::"Copilot Availability"::"Generally Available", Enum::"Copilot Billing Type"::"Not Billed");
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Chat Partner Capability");

        // [WHEN] GenerateChatCompletion is called
        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIOperationResponse);

        // [THEN] GenerateChatCompletion fails [CAPI with Free billing type - Not allowed for Partner published capabilities]
        LibraryAssert.AreEqual(AOAIOperationResponse.IsSuccess(), false, 'AOAI Operation Response should be an error');
        ErrorMessage := StrSubstNo(BillingTypeAuthorizationErr, Enum::"Copilot Capability"::"Chat Partner Capability", Enum::"Copilot Billing Type"::"Not Billed");
        LibraryAssert.ExpectedError(ErrorMessage);
    end;

    local procedure RegisterCapabilityWithBillingType(Capability: Enum "Copilot Capability"; Availability: Enum "Copilot Availability"; BillingType: Enum "Copilot Billing Type")
    var
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        if CopilotCapability.IsCapabilityRegistered(Capability) then
            exit;

        CopilotCapability.RegisterCapability(Capability, Availability, BillingType, LearMoreUrlLbl);
    end;
}
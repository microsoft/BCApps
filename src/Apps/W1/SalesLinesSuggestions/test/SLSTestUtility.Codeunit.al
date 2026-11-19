namespace Microsoft.Sales.Document.Test;

using Microsoft.Sales.Document;
using Microsoft.Sales.Document.Attachment;
using System.AI;
using System.TestLibraries.AI;
using System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;
codeunit 139785 "SLS Test Utility"
{
    Access = Internal;

    // JSON parsing functions
    local procedure GetFunctionToken(AnswerJson: JsonObject): JsonToken;
    var
        ToolsArrayToken: JsonToken;
        ToolType: JsonToken;
        Tool: JsonToken;
        Function: JsonToken;
    begin
        if AnswerJson.Get('tool_calls', ToolsArrayToken) then
            foreach Tool in ToolsArrayToken.AsArray() do begin
                Tool.AsObject().Get('type', ToolType);
                if ToolType.AsValue().asText() = 'function' then begin
                    Tool.AsObject().Get('function', Function);
                    exit(Function);
                end;
            end
    end;

    local procedure GetFunctionArray(AnswerJson: JsonObject) FunctionArray: JsonArray
    var
        ToolsArrayToken: JsonToken;
        ToolType: JsonToken;
        Tool: JsonToken;
        Function: JsonToken;
    begin
        if AnswerJson.Get('tool_calls', ToolsArrayToken) then
            foreach Tool in ToolsArrayToken.AsArray() do begin
                Tool.AsObject().Get('type', ToolType);
                if ToolType.AsValue().asText() = 'function' then begin
                    Tool.AsObject().Get('function', Function);
                    FunctionArray.Add(Function);
                end;
            end
    end;

    internal procedure GetFunctionToken(AnswerText: Text) result: JsonToken;
    var
        AnswerJson: JsonObject;
    begin
        AnswerJson.ReadFrom(AnswerText);
        exit(GetFunctionToken(AnswerJson));
    end;

    internal procedure GetFunctionArray(AnswerText: Text) result: JsonArray;
    var
        AnswerJson: JsonObject;
    begin
        AnswerJson.ReadFrom(AnswerText);
        exit(GetFunctionArray(AnswerJson));
    end;

    // Completion functions
    [TryFunction]
    local procedure TryGetCompletion(var CompletionAnswerTxt: Text; UserSearchTest: Text)
    var
        TempSalesLineAISuggestions: Record "Sales Line AI Suggestions" temporary;
        SalesHeader: Record "Sales Header";
        SalesLineAISuggestionImpl: Codeunit "Sales Lines Suggestions Impl.";
        Prompt: Codeunit "SLS Prompts";
        IntentSystemPrompt: SecretText;
        SearchStyle: Enum "Search Style";
    begin
        IntentSystemPrompt := Prompt.GetSLSSystemPrompt();
        CompletionAnswerTxt := SalesLineAISuggestionImpl.AICall(IntentSystemPrompt, UserSearchTest, SearchStyle, SalesHeader, TempSalesLineAISuggestions);
    end;

    [TryFunction]
    local procedure TryGetCompletionForAttachment(var CompletionAnswerTxt: Text; UserSearchTest: Text)
    var
        SalesLineAISuggestionImpl: Codeunit "Sales Lines Suggestions Impl.";
        LookupItemsFromCsvFunction: Codeunit "Lookup Items From Csv Function";
        Prompt: Codeunit "SLS Prompts";
        IntentSystemPrompt: SecretText;
    begin
        IntentSystemPrompt := Prompt.GetAttachmentSystemPrompt();
        SalesLineAISuggestionImpl.AICall(IntentSystemPrompt, UserSearchTest, LookupItemsFromCsvFunction, CompletionAnswerTxt);
    end;

    internal procedure RepeatAtMost3TimesToFetchCompletion(var CompletionAnswerTxt: Text; UserSearchTest: Text)
    var
        i: Integer;
    begin
        while not TryGetCompletion(CompletionAnswerTxt, UserSearchTest) do begin
            Sleep(100);
            i += 1;
            if i > 3 then
                Error('Cannot get completion answer with 3 tries');
        end;
    end;

    procedure RepeatAtMost3TimesToFetchCompletionForAttachment(var CompletionAnswerTxt: Text; UserSearchTest: Text)
    var
        i: Integer;
    begin
        while not TryGetCompletionForAttachment(CompletionAnswerTxt, UserSearchTest) do begin
            Sleep(100);
            i += 1;
            if i > 3 then
                Error('Cannot get completion answer with 3 tries');
        end;
    end;

    internal procedure GetFunctionName(CompletionAnswerText: Text): Text
    var
        Utility: Codeunit "SLS Test Utility";
        Function: JsonToken;
        FunctionName: JsonToken;
    begin
        Function := Utility.GetFunctionToken(CompletionAnswerText);
        Function.AsObject().Get('name', FunctionName);
        exit(FunctionName.AsValue().AsText());
    end;

    internal procedure CheckMagicFunction(CompletionAnswerTxt: Text);
    var
        Utility: Codeunit "SLS Test Utility";
        Function: JsonToken;
        FunctionName: JsonToken;
    begin
        Function := Utility.GetFunctionToken(CompletionAnswerTxt);
        Function.AsObject().Get('name', FunctionName);
        Assert.AreEqual('magic_function', FunctionName.AsValue().AsText(), 'Function name is not correct');
    end;

    internal procedure RegisterCopilotCapability()
    begin
        CopilotTestLibrary.RegisterCopilotCapabilityWithAppId(Enum::"Copilot Capability"::"Sales Lines Suggestions", GetSalesLineSuggestionAppId());
    end;

    internal procedure EvaluateItemExtraction(CustomerRequest: Text; ReferenceItems: JsonArray; ActualItems: JsonArray): JsonObject
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIDeployments: Codeunit "AOAI Deployments";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        Input: JsonObject;
        Evaluation: JsonObject;
        ResultToken: JsonToken;
        CurrentModuleInfo: ModuleInfo;
        Deployment: Text;
        InputText: Text;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        CopilotTestLibrary.RegisterCopilotCapabilityWithAppId(Enum::"Copilot Capability"::"Sales Lines Suggestions", CurrentModuleInfo.Id());

        // Select the judge separately from the app's model configuration.
        Deployment := AOAIDeployments.GetGPT56CeresLatest();
        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", Deployment);
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Sales Lines Suggestions");
        AOAIChatCompletionParams.SetMaxTokens(1500);
        AOAIChatCompletionParams.SetTemperature(0);
        AOAIChatCompletionParams.SetJsonMode(true);
        AOAIChatMessages.SetPrimarySystemMessage(NavApp.GetResourceAsText('SLSExtractionEvaluatorPrompt.md', TextEncoding::UTF8));

        Input.Add('customer_request', CustomerRequest);
        Input.Add('reference_items', ReferenceItems);
        Input.Add('actual_items', ActualItems);
        Input.WriteTo(InputText);
        AOAIChatMessages.AddUserMessage(InputText);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);
        if not AOAIOperationResponse.IsSuccess() then
            Error('Semantic evaluator failed: %1', AOAIOperationResponse.GetError());

        if not Evaluation.ReadFrom(AOAIChatMessages.GetLastMessage()) then
            Error('Semantic evaluator returned invalid JSON.');
        Assert.IsTrue(Evaluation.Get('passed', ResultToken), 'Semantic evaluator did not return a verdict.');
        Evaluation.Replace('passed', ResultToken.AsValue().AsBoolean());
        Assert.IsTrue(Evaluation.Get('reason', ResultToken), 'Semantic evaluator did not return a reason.');
        Assert.AreNotEqual('', ResultToken.AsValue().AsText(), 'Semantic evaluator returned an empty reason.');
        Assert.IsTrue(Evaluation.Get('item_mapping', ResultToken), 'Semantic evaluator did not return an item mapping.');
        Assert.IsTrue(ResultToken.IsArray(), 'Semantic evaluator item mapping must be an array.');
        Evaluation.Add('deployment', Deployment);
        Evaluation.Add('rubric_version', 1);
        exit(Evaluation);
    end;

    internal procedure LogExtractionEvaluation(CustomerRequest: Text; CompletionAnswer: Text; Evaluation: JsonObject)
    var
        AITestContext: Codeunit "AIT Test Context";
        TestOutputJson: Codeunit "Test Output Json";
        EvaluationText: Text;
    begin
        Evaluation.WriteTo(EvaluationText);
        TestOutputJson.Initialize();
        TestOutputJson.Add('answer', CompletionAnswer);
        TestOutputJson.Add('query', CustomerRequest);
        TestOutputJson.Add('semantic_evaluation', EvaluationText);
        AITestContext.SetTestOutput(TestOutputJson);
    end;

    local procedure GetSalesLineSuggestionAppId(): Text
    begin
        exit('dd3f226b-40bf-4b3c-9988-9b1e0f74edd8');
    end;

    var
        Assert: Codeunit Assert;
        CopilotTestLibrary: Codeunit "Copilot Test Library";
}
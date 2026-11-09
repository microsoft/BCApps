namespace System.Text.Test;

using System.AI;

codeunit 133554 "MT Prompt Evaluator"
{
    Access = Internal;

    procedure Evaluate(ResourcePath: Text; Context: Text; Response: Text)
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIDeployments: Codeunit "AOAI Deployments";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        ResourceStream: InStream;
        PromptBuilder: TextBuilder;
        PromptLine: Text;
        PromptText: Text;
        SystemPrompt: Text;
        UserPrompt: Text;
        Output: JsonObject;
    begin
        NavApp.GetResource(ResourcePath, ResourceStream, TextEncoding::UTF8);
        while not ResourceStream.EOS() do begin
            ResourceStream.ReadText(PromptLine);
            PromptBuilder.AppendLine(PromptLine);
        end;
        PromptText := PromptBuilder.ToText();
        this.RenderPrompt(PromptText, Context, Response, SystemPrompt, UserPrompt);

        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", AOAIDeployments.GetGPT56CeresLatest());
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Marketing Text Evaluation");
        AOAIChatCompletionParams.SetTemperature(0);
        AOAIChatCompletionParams.SetMaxTokens(800);
        AOAIChatCompletionParams.SetJsonMode(true);
        AOAIChatMessages.SetPrimarySystemMessage(SystemPrompt);
        AOAIChatMessages.AddUserMessage(UserPrompt);
        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);
        if not AOAIOperationResponse.IsSuccess() then
            Error(EvaluationRequestErr, AOAIOperationResponse.GetStatusCode(), AOAIOperationResponse.GetError());

        Output.ReadFrom(AOAIChatMessages.GetLastMessage());
        this.ValidateEvaluation(Output, ResourcePath);
    end;

    internal procedure RenderPrompt(PromptText: Text; Context: Text; Response: Text; var SystemPrompt: Text; var UserPrompt: Text)
    var
        SystemText: TextBuilder;
        UserText: TextBuilder;
        PromptLine: Text;
        Segment: Text;
        UserTemplate: Text;
        HeaderDelimiters: Integer;
        InSystem: Boolean;
        InUser: Boolean;
        FirstSegment: Boolean;
        NewLine: Char;
    begin
        NewLine := 10;
        HeaderDelimiters := 0;
        foreach PromptLine in PromptText.Split(NewLine) do
            if HeaderDelimiters < 2 then begin
                if PromptLine.Trim() = '---' then
                    HeaderDelimiters += 1;
            end else
                case PromptLine.Trim() of
                    'system:':
                        InSystem := true;
                    'user:':
                        begin
                            InSystem := false;
                            InUser := true;
                        end;
                    else
                        if InSystem then
                            SystemText.AppendLine(PromptLine)
                        else
                            if InUser then
                                UserText.AppendLine(PromptLine);
                end;

        SystemPrompt := SystemText.ToText().Trim();
        UserTemplate := UserText.ToText().Trim();
        if (SystemPrompt = '') or (UserTemplate = '') then
            Error(InvalidPromptErr);

        Clear(UserText);
        FirstSegment := true;
        // Split before substitution so placeholders in input data remain literal.
        foreach Segment in UserTemplate.Split('{{response}}') do begin
            if not FirstSegment then
                UserText.Append(Response);
            UserText.Append(Segment.Replace('{{context}}', Context));
            FirstSegment := false;
        end;
        UserPrompt := UserText.ToText();
    end;

    internal procedure ValidateEvaluation(Output: JsonObject; EvaluationPrompt: Text)
    var
        OutputToken: JsonToken;
        EvaluationScore: Integer;
        EvaluationExplanation: Text;
    begin
        Output.Get('score', OutputToken);
        EvaluationScore := OutputToken.AsValue().AsInteger();
        Output.Get('explanation', OutputToken);
        EvaluationExplanation := OutputToken.AsValue().AsText();
        if (EvaluationScore < 1) or (EvaluationScore > 5) then
            Error(InvalidScoreErr, EvaluationScore);
        if EvaluationScore < 4 then
            Error(EvaluationErr, EvaluationPrompt, EvaluationScore, EvaluationExplanation);
    end;

    var
        InvalidPromptErr: Label 'The evaluation prompt must contain system and user messages after its metadata header.';
        InvalidScoreErr: Label 'The evaluation score %1 must be between 1 and 5.', Comment = '%1 = Evaluation score';
        EvaluationErr: Label '%1 validation failed. Score: %2, Explanation: %3', Comment = '%1 = Evaluation prompt, %2 = Evaluation score, %3 = Evaluation explanation';
        EvaluationRequestErr: Label 'The evaluation request failed with status %1: %2', Comment = '%1 = HTTP status code, %2 = Error message';
}

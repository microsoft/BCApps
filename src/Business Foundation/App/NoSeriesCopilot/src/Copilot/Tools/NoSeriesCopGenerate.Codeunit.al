// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.AI;

codeunit 339 "No. Series Cop. Generate" implements "AOAI Function"
{
    Access = Internal;

    var
        FunctionNameLbl: Label 'GenerateNumberSeries', Locked = true;

    procedure GetName(): Text
    begin
        exit(FunctionNameLbl);
    end;

    [NonDebuggable]
    procedure GetPrompt() Function: JsonObject;
    begin
        Function.ReadFrom(GetTool3Definition());
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        NotificationManager: Codeunit "No. Ser. Cop. Notific. Manager";
        NoSeriesJArray: JsonArray;
        Completion: Text;
    begin
        if not GetNumberSeriesJsonArray(Arguments, NoSeriesJArray) then begin
            NotificationManager.SendNotification(GetLastErrorText());
            exit(Completion);
        end;

        NoSeriesJArray.WriteTo(Completion);
        exit(Completion);
    end;

    procedure GetDefaultToolChoice(): Text
    begin
        exit('{"type": "function", "function": {"name": "GenerateNumberSeries"}}');
    end;


    [NonDebuggable]
    local procedure GetTool3Definition(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool definition. The tool should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool3DefinitionFromIsolatedStorage())
    end;

    [TryFunction]
    local procedure GetNumberSeriesJsonArray(Arguments: JsonObject; var NoSeriesJArray: JsonArray)
    var
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
        JToken: JsonToken;
    begin
        if not Arguments.Get('noSeries', JToken) then
            Error(NoSeriesCopilotImpl.GetChatCompletionResponseErr());

        if not JToken.IsArray() then
            Error(NoSeriesCopilotImpl.GetChatCompletionResponseErr());

        NoSeriesJArray := JToken.AsArray();
    end;
}
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.AI;
using System.Reflection;
using System.Utilities;

codeunit 339 "No. Series Cop. Generate" implements "AOAI Function"
{
    Access = Internal;

    var
        ToolsImpl: Codeunit "No. Series Cop. Tools Impl.";
        ArgumentIsMissingErr: Label '%1 is missing.', Comment = '%1 = name of the argument';
        ArgumentIsNotArrayErr: Label '%1 is not an array.', Comment = '%1 = name of the argument';

    procedure GetName(): Text
    begin
        exit('GenerateNumberSeries');
    end;

    procedure GetPrompt() Function: JsonObject;
    begin
        Function.ReadFrom(GetTool3Definition());
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        NoSeriesJArray: JsonArray;
        JToken: JsonToken;
        Completion: Text;
    begin
        if not Arguments.Get('noSeries', JToken) then
            Error(ArgumentIsMissingErr, 'noSeries');

        if not JToken.IsArray() then
            Error(ArgumentIsNotArrayErr, 'noSeries');

        JToken.AsArray().WriteTo(Completion);
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
}
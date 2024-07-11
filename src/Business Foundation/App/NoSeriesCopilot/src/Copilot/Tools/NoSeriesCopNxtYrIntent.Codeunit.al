// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.AI;
using System.Reflection;
using System.Utilities;

codeunit 349 "No. Series Cop. Nxt Yr. Intent" implements "AOAI Function"
{
    Access = Internal;

    var
        ToolsImpl: Codeunit "No. Series Cop. Tools Impl.";
        FunctionNameLbl: Label 'GenerateNextYearNumberSeries', Locked = true;

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
        ChangeNoSeriesIntent: Codeunit "No. Series Cop. Change Intent";
    begin
        ChangeNoSeriesIntent.SetUpdateForNextYear(true);
        exit(ChangeNoSeriesIntent.Execute(Arguments));
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
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.AI;
using System.Azure.KeyVault;
using System.Telemetry;

codeunit 339 "No. Series Cop. Generate" implements "AOAI Function"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    var
        Telemetry: Codeunit Telemetry;
        FunctionNameLbl: Label 'GenerateNumberSeries', Locked = true;
        TelemetryTool4DefinitionRetrievalErr: Label 'Unable to retrieve the definition for No. Series Copilot Tool 4 from Azure Key Vault.', Locked = true;
        ToolLoadingErr: Label 'Unable to load the No. Series Copilot Tool 4. Please try again later.';

    procedure GetName(): Text
    begin
        exit(FunctionNameLbl);
    end;

    [NonDebuggable]
    procedure GetPrompt() Function: JsonObject;
    begin
        Function.ReadFrom(GetTool4Definition());
    end;

    procedure Execute(Arguments: JsonObject): Variant
    var
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
        NoSeriesJArray: JsonArray;
        Completion: Text;
    begin
        if not GetNumberSeriesJsonArray(Arguments, NoSeriesJArray) then begin
            NoSeriesCopilotImpl.SendNotification(GetLastErrorText());
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
    local procedure GetTool4Definition() Definition: Text
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret('NoSeriesCopilotTool4Definition', Definition) then begin
            Telemetry.LogMessage('0000ND8', TelemetryTool4DefinitionRetrievalErr, Verbosity::Error, DataClassification::SystemMetadata);
            Error(ToolLoadingErr);
        end;
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
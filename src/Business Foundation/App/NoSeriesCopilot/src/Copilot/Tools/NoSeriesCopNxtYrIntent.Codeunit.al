// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.AI;
using System.Azure.KeyVault;
using System.Telemetry;

codeunit 349 "No. Series Cop. Nxt Yr. Intent" implements "AOAI Function"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    var
        Telemetry: Codeunit Telemetry;
        FunctionNameLbl: Label 'PrepareNextYearNumberSeries', Locked = true;
        TelemetryTool3DefinitionRetrievalErr: Label 'Unable to retrieve the definition for No. Series Copilot Tool 3 from Azure Key Vault.', Locked = true;
        ToolLoadingErr: Label 'Unable to load the No. Series Copilot Tool 3. Please try again later.';

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
    local procedure GetTool3Definition() Definition: Text
    var
        // start of <todo>
        // TODO: Remove this once the semantic search is implemented in production.
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
        // end of <todo>
        AzureKeyVault: Codeunit "Azure Key Vault";
    begin
        // start of <todo>
        // TODO: Remove this once the semantic search is implemented in production.
        // This is a temporary solution to get the tool definition. The tool should be retrieved from the Azure Key Vault.
        if NoSeriesCopilotSetup.Get() then
            exit(NoSeriesCopilotSetup.GetTool3DefinitionFromIsolatedStorage())
        else
            // end of <todo>
            if not AzureKeyVault.GetAzureKeyVaultSecret('NoSeriesCopilotTool3DefinitionV2', Definition) then begin
                Telemetry.LogMessage('0000ND9', TelemetryTool3DefinitionRetrievalErr, Verbosity::Error, DataClassification::SystemMetadata);
                Error(ToolLoadingErr);
            end;
    end;
}
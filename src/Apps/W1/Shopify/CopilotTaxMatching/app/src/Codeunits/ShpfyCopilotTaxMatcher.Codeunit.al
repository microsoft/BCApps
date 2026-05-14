namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.SalesTax;
using Microsoft.Inventory.Item;
using System.AI;
using System.Telemetry;

/// <summary>
/// Codeunit Shpfy Copilot Tax Matcher (ID 30471).
/// Core LLM matching logic: gathers tax lines, queries jurisdictions, calls AOAI, parses results.
/// </summary>
codeunit 30471 "Shpfy Copilot Tax Matcher"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    procedure MatchTaxLines(var OrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"; var MatchedJurisdictions: List of [Code[10]]; var MatchLog: JsonArray): Boolean
    var
        OrderLine: Record "Shpfy Order Line";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        TaxLinesArray: JsonArray;
        JurisdictionsArray: JsonArray;
        AddressObj: JsonObject;
        JurisdictionObj: JsonObject;
        UserPrompt: Text;
        TaxLinesText: Text;
        JurisdictionsText: Text;
        AddressText: Text;
    begin
        FeatureTelemetry.LogUptake('', CopilotTaxRegister.FeatureName(), Enum::"Feature Uptake Status"::Used);

        // Gather unmatched tax lines
        OrderLine.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        if not OrderLine.FindSet() then
            exit(false);

        repeat
            OrderTaxLine.SetRange("Parent Id", OrderLine."Line Id");
            OrderTaxLine.SetRange("Tax Jurisdiction Code", '');
            if OrderTaxLine.FindSet() then
                repeat
                    TaxLinesArray.Add(BuildTaxLineJson(OrderTaxLine));
                until OrderTaxLine.Next() = 0;
        until OrderLine.Next() = 0;

        if TaxLinesArray.Count() = 0 then
            exit(false);

        // Gather all Tax Jurisdictions
        if TaxJurisdiction.FindSet() then
            repeat
                Clear(JurisdictionObj);
                JurisdictionObj.Add('code', TaxJurisdiction.Code);
                JurisdictionObj.Add('description', TaxJurisdiction.Description);
                JurisdictionsArray.Add(JurisdictionObj);
            until TaxJurisdiction.Next() = 0;

        // Build address context
        AddressObj.Add('country', OrderHeader."Ship-to Country/Region Code");
        AddressObj.Add('state', OrderHeader."Ship-to County");
        AddressObj.Add('city', OrderHeader."Ship-to City");

        // Build user prompt
        TaxLinesArray.WriteTo(TaxLinesText);
        JurisdictionsArray.WriteTo(JurisdictionsText);
        AddressObj.WriteTo(AddressText);
        UserPrompt := StrSubstNo(UserPromptTok, TaxLinesText, JurisdictionsText, AddressText,
            Format(Shop."Auto Create Tax Jurisdictions"));

        // Call LLM and process results
        exit(CallLLMAndApplyMatches(OrderHeader, Shop, UserPrompt, MatchedJurisdictions, MatchLog));
    end;

    // [NonDebuggable]
    local procedure CallLLMAndApplyMatches(var OrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"; UserPrompt: Text; var MatchedJurisdictions: List of [Code[10]]; var MatchLog: JsonArray): Boolean
    var
        AzureOpenAI: Codeunit "Azure OpenAi";
        AOAIDeployments: Codeunit "AOAI Deployments";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        TaxMatchFunction: Codeunit "Shpfy Tax Match Function";
        SystemPromptTxt: SecretText;
        MatchResults: JsonObject;
    begin
        SystemPromptTxt := GetSystemPrompt();

        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", AOAIDeployments.GetGPT41Latest());
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Shpfy Tax Matching");

        AOAIChatCompletionParams.SetMaxTokens(4096);
        AOAIChatCompletionParams.SetTemperature(0);

        AOAIChatMessages.AddTool(TaxMatchFunction);
        AOAIChatMessages.SetFunctionAsToolChoice(TaxMatchFunction.GetName());

        AOAIChatMessages.SetPrimarySystemMessage(SystemPromptTxt);
        AOAIChatMessages.AddUserMessage(UserPrompt);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

        if not AOAIOperationResponse.IsSuccess() then begin
            Session.LogMessage('', StrSubstNo(NotSuccessfulRequestErr, AOAIOperationResponse.GetStatusCode(), AOAIOperationResponse.GetError()),
                Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', CopilotTaxRegister.FeatureName());
            exit(false);
        end;

        if not AOAIOperationResponse.IsFunctionCall() then begin
            Session.LogMessage('', NoFunctionCallErr,
                Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', CopilotTaxRegister.FeatureName());
            exit(false);
        end;

        AOAIFunctionResponse := AOAIOperationResponse.GetFunctionResponses().Get(1);
        if not AOAIFunctionResponse.IsSuccess() then begin
            Session.LogMessage('', StrSubstNo(FunctionCallErr, AOAIFunctionResponse.GetFunctionName()),
                Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', CopilotTaxRegister.FeatureName());
            exit(false);
        end;

        MatchResults := AOAIFunctionResponse.GetResult();
        exit(ApplyMatches(OrderHeader, Shop, MatchResults, MatchedJurisdictions, MatchLog));
    end;

    local procedure ApplyMatches(var OrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"; MatchResults: JsonObject; var MatchedJurisdictions: List of [Code[10]]; var MatchLog: JsonArray): Boolean
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        MatchesToken: JsonToken;
        MatchToken: JsonToken;
        MatchObj: JsonObject;
        TaxLineIdToken: JsonToken;
        JurisdictionCodeToken: JsonToken;
        ConfidenceToken: JsonToken;
        ReasonToken: JsonToken;
        TaxLineId: Text;
        JurisdictionCode: Code[10];
        Confidence: Text;
        Reason: Text;
        ParentId: BigInteger;
        LineNo: Integer;
        Parts: List of [Text];
        JurisdictionValid: Boolean;
        AnyMatched: Boolean;
    begin
        if not MatchResults.Get('matches', MatchesToken) then
            exit(false);

        foreach MatchToken in MatchesToken.AsArray() do begin
            MatchObj := MatchToken.AsObject();

            MatchObj.Get('tax_line_id', TaxLineIdToken);
            MatchObj.Get('jurisdiction_code', JurisdictionCodeToken);
            MatchObj.Get('confidence', ConfidenceToken);

            TaxLineId := TaxLineIdToken.AsValue().AsText();
            JurisdictionCode := CopyStr(JurisdictionCodeToken.AsValue().AsText(), 1, MaxStrLen(JurisdictionCode));
            Confidence := ConfidenceToken.AsValue().AsText();

            Reason := '';
            if MatchObj.Get('reason', ReasonToken) then
                if ReasonToken.IsValue() then
                    Reason := ReasonToken.AsValue().AsText();

            if (JurisdictionCode = '') or ((Confidence = 'low') and not Shop."Auto Create Tax Jurisdictions") then
                Session.LogMessage('', StrSubstNo(SkippedLowConfidenceMsg, TaxLineId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', CopilotTaxRegister.FeatureName())
            else begin
                // Parse tax line ID (format: ParentId-LineNo)
                Parts := TaxLineId.Split('-');
                if (Parts.Count() >= 2) and Evaluate(ParentId, Parts.Get(1)) and Evaluate(LineNo, Parts.Get(2)) then begin
                    // Validate jurisdiction exists (or create if allowed)
                    JurisdictionValid := TaxJurisdiction.Get(JurisdictionCode);
                    if not JurisdictionValid then
                        if not Shop."Auto Create Tax Jurisdictions" then
                            Session.LogMessage('', StrSubstNo(JurisdictionNotFoundMsg, JurisdictionCode), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', CopilotTaxRegister.FeatureName())
                        else begin
                            CreateTaxJurisdiction(TaxJurisdiction, JurisdictionCode, OrderHeader);
                            JurisdictionValid := true;
                        end;

                    if JurisdictionValid then
                        if OrderTaxLine.Get(ParentId, LineNo) then begin
                            OrderTaxLine."Tax Jurisdiction Code" := JurisdictionCode;
                            OrderTaxLine.Modify();
                            AnyMatched := true;

                            if not MatchedJurisdictions.Contains(JurisdictionCode) then
                                MatchedJurisdictions.Add(JurisdictionCode);

                            MatchLog.Add(BuildMatchLogEntry(ParentId, LineNo, JurisdictionCode, Capitalize(Confidence), Reason));

                            EnsureTaxDetail(OrderHeader, OrderTaxLine, TaxJurisdiction, GetItemTaxGroupCode(OrderTaxLine));
                            if Shop."Shipping Charges Account" <> '' then
                                EnsureTaxDetail(OrderHeader, OrderTaxLine, TaxJurisdiction, GetShippingTaxGroupCode(Shop));
                        end;
                end;
            end;
        end;

        // Fix up Report-to Jurisdiction for auto-created jurisdictions
        if AnyMatched and (MatchedJurisdictions.Count() > 1) then
            FixReportToJurisdictions(MatchedJurisdictions);

        exit(AnyMatched);
    end;

    local procedure CreateTaxJurisdiction(var TaxJurisdiction: Record "Tax Jurisdiction"; JurisdictionCode: Code[10]; OrderHeader: Record "Shpfy Order Header")
    begin
        TaxJurisdiction.Init();
        TaxJurisdiction.Code := JurisdictionCode;
        TaxJurisdiction.Description := CopyStr(JurisdictionCode, 1, MaxStrLen(TaxJurisdiction.Description));
        Evaluate(TaxJurisdiction."Country/Region", OrderHeader."Ship-to Country/Region Code");
        TaxJurisdiction.Insert(true);
    end;

    local procedure FixReportToJurisdictions(MatchedJurisdictions: List of [Code[10]])
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        StateJurisdictionCode: Code[10];
        JurisdictionCode: Code[10];
    begin
        // First jurisdiction in the list = highest level (state)
        StateJurisdictionCode := MatchedJurisdictions.Get(1);

        foreach JurisdictionCode in MatchedJurisdictions do
            if TaxJurisdiction.Get(JurisdictionCode) then
                if TaxJurisdiction."Report-to Jurisdiction" <> StateJurisdictionCode then begin
                    TaxJurisdiction."Report-to Jurisdiction" := StateJurisdictionCode;
                    TaxJurisdiction.Modify();
                end;
    end;

    local procedure EnsureTaxDetail(OrderHeader: Record "Shpfy Order Header"; OrderTaxLine: Record "Shpfy Order Tax Line"; TaxJurisdiction: Record "Tax Jurisdiction"; TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
    begin
        // Find the latest Tax Detail valid as of the order's effective date — that's the
        // bracket BC will use when posting tax for this order. If one exists, leave it alone:
        // the matcher's job is to seed initial tax data when none exists, not to override
        // admin-maintained rates. If Shopify's rate differs from the existing bracket's rate
        // we emit a telemetry signal (event 0000SHK) rather than inserting a new bracket —
        // auto-inserting would propagate the new rate to every order posting after this date,
        // which is admin territory.
        TaxDetail.SetRange("Tax Jurisdiction Code", TaxJurisdiction.Code);
        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
        TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Sales and Use Tax");
        TaxDetail.SetFilter("Effective Date", '<=%1', OrderHeader."Document Date");
        if TaxDetail.FindLast() then begin
            if TaxDetail."Tax Below Maximum" <> OrderTaxLine."Rate %" then
                Session.LogMessage('',
                    StrSubstNo(TaxDetailRateMismatchMsg, TaxJurisdiction.Code, TaxGroupCode, TaxDetail."Tax Below Maximum", OrderTaxLine."Rate %"),
                    Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All,
                    'Category', CopilotTaxRegister.FeatureName());
            exit;
        end;

        TaxDetail.Init();
        TaxDetail."Tax Jurisdiction Code" := TaxJurisdiction.Code;
        TaxDetail."Tax Group Code" := TaxGroupCode;
        TaxDetail."Tax Type" := TaxDetail."Tax Type"::"Sales and Use Tax";
        TaxDetail."Effective Date" := OrderHeader."Document Date";
        TaxDetail."Tax Below Maximum" := OrderTaxLine."Rate %";
        TaxDetail.Insert(true);
    end;

    local procedure GetItemTaxGroupCode(OrderTaxLine: Record "Shpfy Order Tax Line"): Code[20]
    var
        OrderLine: Record "Shpfy Order Line";
        Item: Record Item;
    begin
        OrderLine.SetRange("Line Id", OrderTaxLine."Parent Id");
        if OrderLine.FindFirst() then
            if Item.Get(OrderLine."Item No.") then
                exit(Item."Tax Group Code");

        exit('');
    end;

    local procedure GetShippingTaxGroupCode(Shop: Record "Shpfy Shop"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        if Shop."Shipping Charges Account" = '' then
            exit('');
        if not GLAccount.Get(Shop."Shipping Charges Account") then
            exit('');
        exit(GLAccount."Tax Group Code");
    end;

    local procedure BuildTaxLineJson(OrderTaxLine: Record "Shpfy Order Tax Line"): JsonObject
    var
        TaxLineObj: JsonObject;
    begin
        TaxLineObj.Add('id', StrSubstNo(TaxLineIdTok, OrderTaxLine."Parent Id", OrderTaxLine."Line No."));
        TaxLineObj.Add('title', OrderTaxLine.Title);
        TaxLineObj.Add('rate_pct', OrderTaxLine."Rate %");
        TaxLineObj.Add('channel_liable', OrderTaxLine."Channel Liable");
        exit(TaxLineObj);
    end;

    [NonDebuggable]
    local procedure GetSystemPrompt(): SecretText
    begin
        exit(NavApp.GetResourceAsText('Prompts/ShpfyCopilotTaxMatching-SystemPrompt.md', TextEncoding::UTF8));
    end;

    internal procedure Capitalize(Confidence: Text): Text
    begin
        // Activity Log Builder.SetConfidence requires exactly 'Low' | 'Medium' | 'High' and errors otherwise.
        case LowerCase(Confidence) of
            'low':
                exit('Low');
            'medium':
                exit('Medium');
            'high':
                exit('High');
            else
                exit('Low');
        end;
    end;

    local procedure BuildMatchLogEntry(ParentId: BigInteger; LineNo: Integer; JurisdictionCode: Code[10]; Confidence: Text; Reason: Text): JsonObject
    var
        Entry: JsonObject;
    begin
        // Allocate a fresh JsonObject per call. Reusing a single instance with Clear/Add across
        // a loop and appending references to a JsonArray collapses every array slot onto the
        // last-cleared object, silently dropping all but the final entry.
        Entry.Add('parentId', ParentId);
        Entry.Add('lineNo', LineNo);
        Entry.Add('jurisdictionCode', JurisdictionCode);
        Entry.Add('confidence', Confidence);
        Entry.Add('reason', Reason);
        exit(Entry);
    end;

    var
        TaxLineIdTok: Label '%1-%2', Locked = true;
        UserPromptTok: Label 'Match the following Shopify tax lines to BC Tax Jurisdictions.\n\nTax lines:\n%1\n\nAvailable Tax Jurisdictions:\n%2\n\nShip-to address:\n%3\n\nAuto Create Tax Jurisdictions: %4\nIf auto-create is enabled (Yes) and no existing jurisdiction matches, suggest a new jurisdiction code derived from the tax line title (max 10 chars, no spaces). Use standard abbreviations (e.g. NYSTAX, NYCTAX, MTATAX).', Locked = true;
        NotSuccessfulRequestErr: Label 'Shopify Tax Matching Chat Completion Status Code: %1, Error: %2', Locked = true;
        NoFunctionCallErr: Label 'Shopify Tax Matching: tool_calls not found in the completion answer', Locked = true;
        FunctionCallErr: Label 'Shopify Tax Matching: Function call to %1 failed', Locked = true, Comment = '%1 = Function name';
        SkippedLowConfidenceMsg: Label 'Shopify Tax Matching: Skipped low-confidence match for tax line %1', Locked = true, Comment = '%1 = Tax line ID';
        JurisdictionNotFoundMsg: Label 'Shopify Tax Matching: Jurisdiction %1 not found and auto-create disabled', Locked = true, Comment = '%1 = Jurisdiction code';
        TaxDetailRateMismatchMsg: Label 'Shopify Tax Matching: Existing Tax Detail for jurisdiction %1, tax group %2 has rate %3, but Shopify reported %4. Existing detail left untouched.', Locked = true, Comment = '%1 = jurisdiction code, %2 = tax group code, %3 = BC rate, %4 = Shopify rate';
}

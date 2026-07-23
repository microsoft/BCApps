namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.SalesTax;
using Microsoft.Inventory.Item;
using System.AI;
using System.Azure.KeyVault;
using System.Telemetry;

/// <summary>
/// Codeunit Shpfy TMA Matcher (ID 30471).
/// Core LLM matching logic: gathers tax lines, queries jurisdictions, calls AOAI, parses results.
/// </summary>
codeunit 30471 "Shpfy TMA Matcher"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        TaxLineIdTok: Label '%1-%2', Locked = true;
        UserPromptTok: Label 'Match the following Shopify tax lines to BC Tax Jurisdictions.\n\nTax lines:\n%1\n\nAvailable Tax Jurisdictions:\n%2\n\nShip-to address:\n%3\n\nAuto Create Tax Jurisdictions: %4\nIf auto-create is enabled (Yes) and no existing jurisdiction matches, suggest a new jurisdiction code derived from the tax line title (max 10 chars, no spaces). Use standard abbreviations (e.g. NYSTAX, NYCTAX, MTATAX).', Locked = true;
        NotSuccessfulRequestErr: Label 'Shopify Tax Matching Chat Completion Status Code: %1, Error: %2', Locked = true;
        NoFunctionCallErr: Label 'Shopify Tax Matching: tool_calls not found in the completion answer', Locked = true;
        FunctionCallErr: Label 'Shopify Tax Matching: Function call to %1 failed', Locked = true, Comment = '%1 = Function name';
        SkippedLowConfidenceMsg: Label 'Shopify Tax Matching: Skipped low-confidence match for tax line %1', Locked = true, Comment = '%1 = Tax line ID';
        JurisdictionNotFoundMsg: Label 'Shopify Tax Matching: Jurisdiction %1 not found and auto-create disabled', Locked = true, Comment = '%1 = Jurisdiction code';
        TaxDetailRateMismatchMsg: Label 'Shopify Tax Matching: Existing Tax Detail for jurisdiction %1, tax group %2 has rate %3, but Shopify reported %4. Existing detail left untouched.', Locked = true, Comment = '%1 = jurisdiction code, %2 = tax group code, %3 = BC rate, %4 = Shopify rate';
        RateConflictReasonTok: Label 'Shopify charged %1%, but Business Central has a Tax Detail rate of %2% for tax group %3. Business Central will post at its own rate unless you correct the Tax Detail.', Comment = '%1 = Shopify rate, %2 = existing BC rate, %3 = tax group code';
        SecurityPromptSecretNameTok: Label 'ShopifyTaxMatchingAgentSecurityPrompt', Locked = true;
        KeyVaultPromptErr: Label 'There was an error preparing the Shopify tax matching request. Log a Business Central support request about this.';

    procedure MatchTaxLines(var OrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"; var MatchedJurisdictions: List of [Code[10]]; var MatchLog: JsonArray; var HasRateConflict: Boolean): Boolean
    var
        OrderLine: Record "Shpfy Order Line";
        ShippingCharge: Record "Shpfy Order Shipping Charges";
        TaxJurisdiction: Record "Tax Jurisdiction";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TMARegister: Codeunit "Shpfy TMA Register";
        TaxLinesArray: JsonArray;
        JurisdictionsArray: JsonArray;
        AddressObj: JsonObject;
        JurisdictionObj: JsonObject;
        UserPrompt: Text;
        TaxLinesText: Text;
        JurisdictionsText: Text;
        AddressText: Text;
    begin
        HasRateConflict := false;
        FeatureTelemetry.LogUptake('0000UML', TMARegister.FeatureName(), Enum::"Feature Uptake Status"::Used);

        // Gather the order's tax lines — both product-line tax lines (Parent Id = order line
        // "Line Id") and shipping-charge tax lines (Parent Id = "Shopify Shipping Line Id"). Lines
        // without a jurisdiction go to the LLM; lines already assigned on a prior run are carried
        // into MatchedJurisdictions so the Tax Area is built from the order's complete jurisdiction
        // set. Product lines are gathered first (in line order) so the state -> ... -> city
        // ordering the Tax Area Builder relies on is preserved; shipping jurisdictions typically
        // duplicate product ones and are de-duplicated.
        OrderLine.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        if OrderLine.FindSet() then
            repeat
                GatherTaxLines(OrderLine."Line Id", TaxLinesArray, MatchedJurisdictions);
            until OrderLine.Next() = 0;

        ShippingCharge.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        if ShippingCharge.FindSet() then
            repeat
                GatherTaxLines(ShippingCharge."Shopify Shipping Line Id", TaxLinesArray, MatchedJurisdictions);
            until ShippingCharge.Next() = 0;

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

        // Call LLM and process results. HasRateConflict is accumulated per line inside
        // ApplyMatches -> ApplyAssignedJurisdiction, then stored on the order by the caller as the
        // single source of truth.
        exit(CallLLMAndApplyMatches(OrderHeader, Shop, UserPrompt, MatchedJurisdictions, MatchLog, HasRateConflict));
    end;

    // [NonDebuggable]
    local procedure CallLLMAndApplyMatches(var OrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"; UserPrompt: Text; var MatchedJurisdictions: List of [Code[10]]; var MatchLog: JsonArray; var HasRateConflict: Boolean): Boolean
    var
        AzureOpenAI: Codeunit "Azure OpenAi";
        AOAIDeployments: Codeunit "AOAI Deployments";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        TMARegister: Codeunit "Shpfy TMA Register";
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
            Session.LogMessage('0000UMM', StrSubstNo(NotSuccessfulRequestErr, AOAIOperationResponse.GetStatusCode(), AOAIOperationResponse.GetError()),
                Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TMARegister.FeatureName());
            exit(false);
        end;

        if not AOAIOperationResponse.IsFunctionCall() then begin
            Session.LogMessage('0000UMN', NoFunctionCallErr,
                Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TMARegister.FeatureName());
            exit(false);
        end;

        AOAIFunctionResponse := AOAIOperationResponse.GetFunctionResponses().Get(1);
        if not AOAIFunctionResponse.IsSuccess() then begin
            Session.LogMessage('0000UMO', StrSubstNo(FunctionCallErr, AOAIFunctionResponse.GetFunctionName()),
                Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TMARegister.FeatureName());
            exit(false);
        end;

        MatchResults := AOAIFunctionResponse.GetResult();
        exit(ApplyMatches(OrderHeader, Shop, MatchResults, MatchedJurisdictions, MatchLog, HasRateConflict));
    end;

    local procedure ApplyMatches(var OrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"; MatchResults: JsonObject; var MatchedJurisdictions: List of [Code[10]]; var MatchLog: JsonArray; var HasRateConflict: Boolean): Boolean
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        TMARegister: Codeunit "Shpfy TMA Register";
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
                Session.LogMessage('0000UMP', StrSubstNo(SkippedLowConfidenceMsg, TaxLineId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TMARegister.FeatureName())
            else begin
                // Parse tax line ID (format: ParentId-LineNo)
                Parts := TaxLineId.Split('-');
                if (Parts.Count() >= 2) and Evaluate(ParentId, Parts.Get(1)) and Evaluate(LineNo, Parts.Get(2)) then begin
                    // Validate jurisdiction exists (or create if allowed)
                    JurisdictionValid := TaxJurisdiction.Get(JurisdictionCode);
                    if not JurisdictionValid then
                        if not Shop."Auto Create Tax Jurisdictions" then
                            Session.LogMessage('0000UMQ', StrSubstNo(JurisdictionNotFoundMsg, JurisdictionCode), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TMARegister.FeatureName())
                        else begin
                            CreateTaxJurisdiction(TaxJurisdiction, JurisdictionCode, OrderHeader);
                            JurisdictionValid := true;
                        end;

                    if JurisdictionValid and OrderTaxLine.Get(ParentId, LineNo) then begin
                        AnyMatched := true;
                        ApplyAssignedJurisdiction(OrderHeader, Shop, OrderTaxLine, TaxJurisdiction, Capitalize(Confidence), Reason, MatchedJurisdictions, MatchLog, HasRateConflict);
                    end;
                end;
            end;
        end;

        // Point matched jurisdictions with a blank Report-to at the top-level (state) jurisdiction
        // so the Tax Area rolls up correctly. Jurisdictions with an existing (admin-maintained)
        // Report-to are left untouched.
        if AnyMatched and (MatchedJurisdictions.Count() > 1) then
            FixReportToJurisdictions(MatchedJurisdictions);

        exit(AnyMatched);
    end;

    /// <summary>
    /// Applies one matched jurisdiction to a tax line and records the effect on the shared
    /// state (MatchedJurisdictions, MatchLog, HasRateConflict). Works for both product-line and
    /// shipping-charge tax lines — the applicable Tax Group is resolved per line (item tax group
    /// vs the shop's shipping-charges-account tax group). The jurisdiction is always assigned. If
    /// BC already has a Tax Detail for this jurisdiction + tax group whose rate differs from
    /// Shopify's, the order is flagged as a rate conflict (held for review) and the existing
    /// admin-maintained rate is left untouched; otherwise a missing bracket is seeded at Shopify's
    /// rate.
    /// </summary>
    local procedure ApplyAssignedJurisdiction(var OrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"; var OrderTaxLine: Record "Shpfy Order Tax Line"; TaxJurisdiction: Record "Tax Jurisdiction"; Confidence: Text; Reason: Text; var MatchedJurisdictions: List of [Code[10]]; var MatchLog: JsonArray; var HasRateConflict: Boolean)
    var
        TMARegister: Codeunit "Shpfy TMA Register";
        TaxGroupCode: Code[20];
        ExistingRate: Decimal;
        BracketExists: Boolean;
    begin
        TaxGroupCode := GetTaxGroupCodeForTaxLine(OrderTaxLine, Shop);
        BracketExists := TryFindEffectiveTaxDetail(OrderHeader, TaxJurisdiction, TaxGroupCode, ExistingRate);

        OrderTaxLine."Tax Jurisdiction Code" := TaxJurisdiction.Code;
        OrderTaxLine.Modify();

        if not MatchedJurisdictions.Contains(TaxJurisdiction.Code) then
            MatchedJurisdictions.Add(TaxJurisdiction.Code);

        if BracketExists and (ExistingRate <> OrderTaxLine."Rate %") then begin
            // Jurisdiction is correct, but BC's existing Tax Detail rate differs from Shopify's.
            // Keep the assignment (and build the Tax Area) but flag the order so it is always held
            // for review: the reviewer sees Shopify's rate next to BC's on the review page and
            // decides whether to accept BC's rate or fix the Tax Detail. The existing rate is not
            // overwritten. This applies equally to product-line and shipping-charge tax lines.
            HasRateConflict := true;
            Session.LogMessage('0000UMR',
                StrSubstNo(TaxDetailRateMismatchMsg, TaxJurisdiction.Code, TaxGroupCode, ExistingRate, OrderTaxLine."Rate %"),
                Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TMARegister.FeatureName());
            MatchLog.Add(BuildMatchLogEntry(OrderTaxLine."Parent Id", OrderTaxLine."Line No.", TaxJurisdiction.Code, Confidence,
                StrSubstNo(RateConflictReasonTok, OrderTaxLine."Rate %", ExistingRate, TaxGroupCode), true));
        end else begin
            MatchLog.Add(BuildMatchLogEntry(OrderTaxLine."Parent Id", OrderTaxLine."Line No.", TaxJurisdiction.Code, Confidence, Reason, false));
            if not BracketExists then
                InsertTaxDetail(OrderHeader, OrderTaxLine, TaxJurisdiction, TaxGroupCode);
        end;
    end;

    /// <summary>
    /// Re-applies the tax match from the jurisdiction codes currently assigned on the order's
    /// tax lines (e.g. after a human edited or completed them on the review page). Runs the same
    /// per-line seeding/conflict logic as the LLM path but takes the human's jurisdictions as
    /// given, then reports whether any assigned rate still conflicts with BC. The caller builds
    /// the Tax Area from the returned MatchedJurisdictions.
    /// </summary>
    procedure ReapplyFromAssignedLines(var OrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"; var MatchedJurisdictions: List of [Code[10]]; var MatchLog: JsonArray; var HasRateConflict: Boolean): Boolean
    var
        OrderLine: Record "Shpfy Order Line";
        ShippingCharge: Record "Shpfy Order Shipping Charges";
        AnyMatched: Boolean;
    begin
        HasRateConflict := false;

        // Re-apply from the jurisdictions currently on both product-line and shipping-charge tax
        // lines. Product lines first (in line order) to preserve the state -> ... -> city ordering
        // the Tax Area Builder relies on; shipping jurisdictions typically duplicate product ones.
        OrderLine.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        if OrderLine.FindSet() then
            repeat
                if ReapplyTaxLinesForParent(OrderHeader, Shop, OrderLine."Line Id", MatchedJurisdictions, MatchLog, HasRateConflict) then
                    AnyMatched := true;
            until OrderLine.Next() = 0;

        ShippingCharge.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        if ShippingCharge.FindSet() then
            repeat
                if ReapplyTaxLinesForParent(OrderHeader, Shop, ShippingCharge."Shopify Shipping Line Id", MatchedJurisdictions, MatchLog, HasRateConflict) then
                    AnyMatched := true;
            until ShippingCharge.Next() = 0;

        // Set the rollup Report-to on any matched jurisdiction that still has a blank one (existing
        // admin-maintained hierarchies are left untouched).
        if AnyMatched and (MatchedJurisdictions.Count() > 1) then
            FixReportToJurisdictions(MatchedJurisdictions);

        exit(AnyMatched);
    end;

    local procedure ReapplyTaxLinesForParent(var OrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"; ParentId: BigInteger; var MatchedJurisdictions: List of [Code[10]]; var MatchLog: JsonArray; var HasRateConflict: Boolean): Boolean
    var
        OrderTaxLine: Record "Shpfy Order Tax Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
        AnyMatched: Boolean;
    begin
        OrderTaxLine.SetRange("Parent Id", ParentId);
        if OrderTaxLine.FindSet() then
            repeat
                if OrderTaxLine."Tax Jurisdiction Code" <> '' then
                    if TaxJurisdiction.Get(OrderTaxLine."Tax Jurisdiction Code") then begin
                        AnyMatched := true;
                        ApplyAssignedJurisdiction(OrderHeader, Shop, OrderTaxLine, TaxJurisdiction, 'High', '', MatchedJurisdictions, MatchLog, HasRateConflict);
                    end;
            until OrderTaxLine.Next() = 0;
        exit(AnyMatched);
    end;

    /// <summary>
    /// Returns the Business Central Tax Detail rate that would apply to a tax line's item, given
    /// the jurisdiction currently assigned to the line and the order's effective date. Used by
    /// the review page to show BC's rate next to Shopify's and highlight a difference. Returns
    /// false when no jurisdiction is assigned or no effective bracket exists.
    /// </summary>
    procedure TryGetEffectiveItemRate(OrderTaxLine: Record "Shpfy Order Tax Line"; var BCRate: Decimal): Boolean
    var
        OrderHeader: Record "Shpfy Order Header";
        TaxJurisdiction: Record "Tax Jurisdiction";
        Shop: Record "Shpfy Shop";
        TaxGroupCode: Code[20];
    begin
        Clear(BCRate);
        if OrderTaxLine."Tax Jurisdiction Code" = '' then
            exit(false);
        if not TaxJurisdiction.Get(OrderTaxLine."Tax Jurisdiction Code") then
            exit(false);
        if not TryGetOrderHeaderForTaxLine(OrderTaxLine, OrderHeader) then
            exit(false);
        if not Shop.Get(OrderHeader."Shop Code") then
            exit(false);
        TaxGroupCode := GetTaxGroupCodeForTaxLine(OrderTaxLine, Shop);
        exit(TryFindEffectiveTaxDetail(OrderHeader, TaxJurisdiction, TaxGroupCode, BCRate));
    end;

    /// <summary>
    /// Creates — or, when one already exists on the order's document date, updates — a Tax Detail
    /// for the tax line's Tax Jurisdiction and resolved tax group so Business Central posts the rate
    /// Shopify charged, effective the order's document date. This mutates shared BC tax setup: it is
    /// NOT scoped to a single order, so it affects every document that posts that jurisdiction and
    /// tax group on or after that date. Used by the review page to let a reviewer resolve a rate
    /// conflict by deliberately adopting Shopify's rate over the existing Business Central rate.
    /// Returns false when the line has no jurisdiction assigned or the owning order/shop cannot be
    /// resolved.
    /// </summary>
    procedure SeedTaxDetailFromShopifyRate(OrderTaxLine: Record "Shpfy Order Tax Line"): Boolean
    var
        OrderHeader: Record "Shpfy Order Header";
        Shop: Record "Shpfy Shop";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
        TaxGroupCode: Code[20];
    begin
        if OrderTaxLine."Tax Jurisdiction Code" = '' then
            exit(false);
        if not TaxJurisdiction.Get(OrderTaxLine."Tax Jurisdiction Code") then
            exit(false);
        if not TryGetOrderHeaderForTaxLine(OrderTaxLine, OrderHeader) then
            exit(false);
        if not Shop.Get(OrderHeader."Shop Code") then
            exit(false);
        TaxGroupCode := GetTaxGroupCodeForTaxLine(OrderTaxLine, Shop);

        // A Tax Detail is keyed by jurisdiction + tax group + tax type + effective date. Adopt
        // Shopify's rate on the order's document date: modify a bracket that already exists on that
        // exact date, otherwise seed a new one. Later brackets (if any) are left untouched.
        TaxDetail.SetRange("Tax Jurisdiction Code", TaxJurisdiction.Code);
        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
        TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Sales and Use Tax");
        TaxDetail.SetRange("Effective Date", OrderHeader."Document Date");
        if TaxDetail.FindFirst() then begin
            TaxDetail."Tax Below Maximum" := OrderTaxLine."Rate %";
            TaxDetail.Modify(true);
        end else
            InsertTaxDetail(OrderHeader, OrderTaxLine, TaxJurisdiction, TaxGroupCode);
        exit(true);
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
        // First matched jurisdiction in the list = highest level (state). Set the Report-to on
        // every matched jurisdiction whose Report-to is still BLANK (this covers jurisdictions
        // auto-created this run and pre-existing ones that never had a rollup target, including
        // the state itself, which reports to itself). A jurisdiction that already has a Report-to
        // is an admin-maintained hierarchy and is left untouched.
        StateJurisdictionCode := MatchedJurisdictions.Get(1);

        foreach JurisdictionCode in MatchedJurisdictions do
            if TaxJurisdiction.Get(JurisdictionCode) then
                if TaxJurisdiction."Report-to Jurisdiction" = '' then begin
                    TaxJurisdiction."Report-to Jurisdiction" := StateJurisdictionCode;
                    TaxJurisdiction.Modify();
                end;
    end;

    local procedure TryFindEffectiveTaxDetail(OrderHeader: Record "Shpfy Order Header"; TaxJurisdiction: Record "Tax Jurisdiction"; TaxGroupCode: Code[20]; var ExistingRate: Decimal): Boolean
    var
        TaxDetail: Record "Tax Detail";
    begin
        // Returns the latest Tax Detail bracket valid as of the order's effective date — that's
        // the bracket BC uses when posting tax for this order. Read-only: callers decide what to
        // do with the result (seed when absent, block/warn on a rate mismatch).
        TaxDetail.SetRange("Tax Jurisdiction Code", TaxJurisdiction.Code);
        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
        TaxDetail.SetRange("Tax Type", TaxDetail."Tax Type"::"Sales and Use Tax");
        TaxDetail.SetFilter("Effective Date", '<=%1', OrderHeader."Document Date");
        if not TaxDetail.FindLast() then
            exit(false);
        ExistingRate := TaxDetail."Tax Below Maximum";
        exit(true);
    end;

    local procedure InsertTaxDetail(OrderHeader: Record "Shpfy Order Header"; OrderTaxLine: Record "Shpfy Order Tax Line"; TaxJurisdiction: Record "Tax Jurisdiction"; TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
    begin
        // Pure seeding: only called when no bracket exists for this jurisdiction + tax group as
        // of the order date, so the posted Sales Document computes a non-zero tax rate.
        TaxDetail.Init();
        TaxDetail."Tax Jurisdiction Code" := TaxJurisdiction.Code;
        TaxDetail."Tax Group Code" := TaxGroupCode;
        TaxDetail."Tax Type" := TaxDetail."Tax Type"::"Sales and Use Tax";
        TaxDetail."Effective Date" := OrderHeader."Document Date";
        TaxDetail."Tax Below Maximum" := OrderTaxLine."Rate %";
        TaxDetail.Insert(true);
    end;

    local procedure GatherTaxLines(ParentId: BigInteger; var TaxLinesArray: JsonArray; var MatchedJurisdictions: List of [Code[10]])
    var
        OrderTaxLine: Record "Shpfy Order Tax Line";
    begin
        OrderTaxLine.SetRange("Parent Id", ParentId);
        if OrderTaxLine.FindSet() then
            repeat
                if OrderTaxLine."Tax Jurisdiction Code" = '' then
                    TaxLinesArray.Add(BuildTaxLineJson(OrderTaxLine))
                else
                    if not MatchedJurisdictions.Contains(OrderTaxLine."Tax Jurisdiction Code") then
                        MatchedJurisdictions.Add(OrderTaxLine."Tax Jurisdiction Code");
            until OrderTaxLine.Next() = 0;
    end;

    /// <summary>
    /// Resolves the BC Tax Group Code that applies to a tax line, depending on what it is charged
    /// on: a product line's tax line uses the order line item's Tax Group Code; a shipping-charge
    /// tax line (Parent Id = "Shopify Shipping Line Id") uses the shop's shipping-charges-account
    /// Tax Group Code. Returns blank when the owner or item/account has no tax group.
    /// </summary>
    local procedure GetTaxGroupCodeForTaxLine(OrderTaxLine: Record "Shpfy Order Tax Line"; Shop: Record "Shpfy Shop"): Code[20]
    var
        OrderLine: Record "Shpfy Order Line";
        ShippingCharge: Record "Shpfy Order Shipping Charges";
        Item: Record Item;
    begin
        OrderLine.SetRange("Line Id", OrderTaxLine."Parent Id");
        if OrderLine.FindFirst() then begin
            if Item.Get(OrderLine."Item No.") then
                exit(Item."Tax Group Code");
            exit('');
        end;
        if ShippingCharge.Get(OrderTaxLine."Parent Id") then
            exit(GetShippingTaxGroupCode(Shop));
        exit('');
    end;

    /// <summary>
    /// Resolves the originating order header for a tax line via its owner — a product order line
    /// (Parent Id = "Line Id") or a shipping charge (Parent Id = "Shopify Shipping Line Id").
    /// </summary>
    local procedure TryGetOrderHeaderForTaxLine(OrderTaxLine: Record "Shpfy Order Tax Line"; var OrderHeader: Record "Shpfy Order Header"): Boolean
    var
        OrderLine: Record "Shpfy Order Line";
        ShippingCharge: Record "Shpfy Order Shipping Charges";
    begin
        OrderLine.SetRange("Line Id", OrderTaxLine."Parent Id");
        if OrderLine.FindFirst() then
            exit(OrderHeader.Get(OrderLine."Shopify Order Id"));
        if ShippingCharge.Get(OrderTaxLine."Parent Id") then
            exit(OrderHeader.Get(ShippingCharge."Shopify Order Id"));
        exit(false);
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
    var
        MatchingPrompt: Text;
    begin
        MatchingPrompt := NavApp.GetResourceAsText('Prompts/ShpfyTaxMatchingAgent-SystemPrompt.md', TextEncoding::UTF8);
        exit(SecretStrSubstNo('%1%2', MatchingPrompt, GetSecurityPrompt()));
    end;

    [NonDebuggable]
    local procedure GetSecurityPrompt(): SecretText
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        SecurityPrompt: SecretText;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret(SecurityPromptSecretNameTok, SecurityPrompt) then
            Error(KeyVaultPromptErr);
        exit(SecurityPrompt);
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

    local procedure BuildMatchLogEntry(ParentId: BigInteger; LineNo: Integer; JurisdictionCode: Code[10]; Confidence: Text; Reason: Text; Conflict: Boolean): JsonObject
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
        Entry.Add('conflict', Conflict);
        exit(Entry);
    end;
}

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Sales.Document;
using System.AI;

/// <summary>
/// Codeunit Shpfy TMA Events (ID 30473).
/// Subscribes to OnAfterMapShopifyOrder to trigger Tax Matching Agent, and to
/// OnAfterCreateSalesHeader to propagate the Tax Matching Agent marker onto
/// the resulting BC Sales Header so a human can review what the Tax Matching Agent did.
/// </summary>
codeunit 30473 "Shpfy TMA Events"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        StartingMatchMsg: Label 'Starting tax match for order', Locked = true;
        ReviewRequiredErr: Label 'The Sales Document for Shopify order %1 cannot be created until the tax match has been approved. Open the order, choose Review Tax Match, and approve the match on the review page — or change the shop''s Tax Match Review Mode.', Comment = '%1 = Shopify Order No.';
        RateConflictBlockErr: Label 'The Sales Document for Shopify order %1 cannot be created because a matched tax rate differs from Business Central. Open the order, choose Review Tax Match, and either approve the match to accept Business Central''s rates or correct the Tax Detail rate or Tax Jurisdiction, on the review page.', Comment = '%1 = Shopify Order No.';
        IncompleteBlockErr: Label 'The Sales Document for Shopify order %1 cannot be created because the Tax Matching Agent could not resolve one or more tax lines to a Tax Jurisdiction. Open the order, choose Review Tax Match, assign a Tax Jurisdiction to every tax line, and approve the match on the review page.', Comment = '%1 = Shopify Order No.';
        SecurityPromptUnavailableMsg: Label 'Security prompt unavailable from Key Vault; tax matching skipped for this order.', Locked = true;
        MarkerSetMsg: Label 'Tax match marker set on order', Locked = true;
        HeldRateConflictMsg: Label 'Order held for review pending rate conflict resolution', Locked = true;
        HeldUnresolvedMsg: Label 'Order held for review pending unresolved tax line', Locked = true;
        TaxLinesMatchedMsg: Label 'Tax lines matched for order', Locked = true;
        CreationBlockedMsg: Label 'Sales Document creation blocked pending tax match review', Locked = true;
        MarkerPropagatedMsg: Label 'Tax match marker propagated to Sales Header', Locked = true;
        ShopifyOrderIdDimTok: Label 'ShopifyOrderId', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnAfterMapShopifyOrder, '', false, false)]
    local procedure OnAfterMapShopifyOrder(var ShopifyOrderHeader: Record "Shpfy Order Header"; Result: Boolean)
    var
        Shop: Record "Shpfy Shop";
        CopilotCapability: Codeunit "Copilot Capability";
        TMAMatcher: Codeunit "Shpfy TMA Matcher";
        TaxAreaBuilder: Codeunit "Shpfy Tax Area Builder";
        CTActivityLog: Codeunit "Shpfy TMA Activity Log";
        TMARegister: Codeunit "Shpfy TMA Register";
        MatchedJurisdictions: List of [Code[10]];
        MatchLog: JsonArray;
        ResolvedTaxAreaCode: Code[20];
        TaxAreaWasCreated: Boolean;
        HasRateConflict: Boolean;
        HasUnresolvedLine: Boolean;
        HasLowConfidenceMatch: Boolean;
        MatchApplied: Boolean;
        SecurityPrompt: SecretText;
    begin
        if not Result then
            exit;

        if not Shop.Get(ShopifyOrderHeader."Shop Code") then
            exit;

        if not ShouldAttemptMatch(ShopifyOrderHeader, Shop) then
            exit;

        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Shopify Tax Matching Agent") then
            exit;

        if not CopilotCapability.IsCapabilityActive(Enum::"Copilot Capability"::"Shopify Tax Matching Agent") then
            exit;

        if not TMAMatcher.TryGetGuardrailPrompt(SecurityPrompt) then begin
            Session.LogMessage('0000UNV', SecurityPromptUnavailableMsg,
                Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TMARegister.FeatureName());
            exit;
        end;

        // Reset markers before re-matching (e.g. when a user manually cleared Tax Area Code to force a re-run).
        if ShopifyOrderHeader."Tax Match Applied" or ShopifyOrderHeader."Tax Match Reviewed" or ShopifyOrderHeader."Tax Rate Conflict" or ShopifyOrderHeader."Tax Match Incomplete" or ShopifyOrderHeader."Tax Match Low Confidence" then begin
            ShopifyOrderHeader."Tax Match Applied" := false;
            ShopifyOrderHeader."Tax Match Reviewed" := false;
            ShopifyOrderHeader."Tax Rate Conflict" := false;
            ShopifyOrderHeader."Tax Match Incomplete" := false;
            ShopifyOrderHeader."Tax Match Low Confidence" := false;
            ShopifyOrderHeader.Modify();
        end;

        Session.LogMessage('0000UMK', StartingMatchMsg,
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TMARegister.FeatureName(), ShopifyOrderIdDimTok, Format(ShopifyOrderHeader."Shopify Order Id"));

        MatchApplied := TMAMatcher.MatchTaxLines(ShopifyOrderHeader, Shop, SecurityPrompt, MatchedJurisdictions, MatchLog, HasRateConflict, HasUnresolvedLine, HasLowConfidenceMatch);
        if not MatchApplied then
            exit;

        // A matched jurisdiction may carry a rate that conflicts with BC (HasRateConflict), or one
        // or more tax lines may be unresolved (HasUnresolvedLine — the model returned UNKNOWN and
        // the line was left unmatched). The matched jurisdictions are still correct, so the Tax Area
        // is built as usual from them; either flag is recorded on the order so the review gate always
        // holds it — the reviewer accepts BC's rate, corrects the Tax Detail, or assigns the missing
        // Tax Jurisdiction before a Sales Document is created.
        if MatchedJurisdictions.Count() > 0 then
            if TaxAreaBuilder.FindOrCreateTaxArea(ShopifyOrderHeader, Shop, MatchedJurisdictions, ResolvedTaxAreaCode, TaxAreaWasCreated) then begin
                ShopifyOrderHeader."Tax Match Applied" := true;
                ShopifyOrderHeader."Tax Rate Conflict" := HasRateConflict;
                ShopifyOrderHeader."Tax Match Incomplete" := HasUnresolvedLine;
                ShopifyOrderHeader."Tax Match Low Confidence" := HasLowConfidenceMatch;
                ShopifyOrderHeader.Modify();
                Session.LogMessage('0000UMG', MarkerSetMsg,
                    Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TMARegister.FeatureName(), ShopifyOrderIdDimTok, Format(ShopifyOrderHeader."Shopify Order Id"));
                if HasRateConflict then
                    Session.LogMessage('0000UMF', HeldRateConflictMsg,
                        Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TMARegister.FeatureName(), ShopifyOrderIdDimTok, Format(ShopifyOrderHeader."Shopify Order Id"));
                if HasUnresolvedLine then
                    Session.LogMessage('0000UNT', HeldUnresolvedMsg,
                        Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TMARegister.FeatureName(), ShopifyOrderIdDimTok, Format(ShopifyOrderHeader."Shopify Order Id"));

                CTActivityLog.LogPerLineEntries(ShopifyOrderHeader, MatchLog);
                CTActivityLog.LogTaxAreaEntry(ShopifyOrderHeader, ResolvedTaxAreaCode, TaxAreaWasCreated, MatchedJurisdictions);
            end;

        Session.LogMessage('0000UMH', TaxLinesMatchedMsg,
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TMARegister.FeatureName(), ShopifyOrderIdDimTok, Format(ShopifyOrderHeader."Shopify Order Id"));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnBeforeCreateSalesHeader, '', false, false)]
    local procedure OnBeforeCreateSalesHeaderSubscriber(ShopifyOrderHeader: Record "Shpfy Order Header"; var SalesHeader: Record "Sales Header"; var LastCreatedDocumentId: Guid; var Handled: Boolean)
    var
        Shop: Record "Shpfy Shop";
        TMARegister: Codeunit "Shpfy TMA Register";
    begin
        if Handled then
            exit;

        if not Shop.Get(ShopifyOrderHeader."Shop Code") then
            exit;

        if not IsSalesDocumentCreationHeld(ShopifyOrderHeader, Shop) then
            exit;

        Handled := true;
        Session.LogMessage('0000UMI', CreationBlockedMsg,
            Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TMARegister.FeatureName(), ShopifyOrderIdDimTok, Format(ShopifyOrderHeader."Shopify Order Id"));

        if ShopifyOrderHeader."Tax Rate Conflict" then
            Error(RateConflictBlockErr, ShopifyOrderHeader."Shopify Order No.")
        else
            if ShopifyOrderHeader."Tax Match Incomplete" then
                Error(IncompleteBlockErr, ShopifyOrderHeader."Shopify Order No.")
            else
                Error(ReviewRequiredErr, ShopifyOrderHeader."Shopify Order No.");
    end;

    /// <summary>
    /// Business guards deciding whether Tax Matching Agent should run for an order: the shop
    /// must have the feature enabled, the order must not already have a Tax Area (idempotency —
    /// e.g. address-based MapTaxArea already resolved one, or this is a re-import), and the order
    /// must not be tax exempt. Capability-registration/active checks are evaluated separately in
    /// the subscriber. Exposed as internal so the guards can be tested without the connector flow.
    /// </summary>
    internal procedure ShouldAttemptMatch(ShopifyOrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"): Boolean
    begin
        if not Shop."Tax Matching Agent Enabled" then
            exit(false);
        if ShopifyOrderHeader."Tax Area Code" <> '' then
            exit(false);
        if ShopifyOrderHeader."Tax Exempt" then
            exit(false);
        exit(true);
    end;

    /// <summary>
    /// Decides whether Sales Document creation must be held for a agent-matched order. Held
    /// when the order was matched, is not yet approved, and either the shop's review mode requires
    /// it (see IsHeldForReviewPreference), the order carries a rate conflict, or the match is
    /// incomplete (one or more tax lines unresolved — the stored Tax Rate Conflict / Tax Match
    /// Incomplete flags are the single source of truth). A rate conflict or an incomplete match
    /// holds the order regardless of the review mode, so a human sees the difference or assigns the
    /// missing jurisdiction before a Sales Document is created. Exposed as internal so the gate
    /// decision can be tested without driving the connector's create-document flow.
    /// </summary>
    internal procedure IsSalesDocumentCreationHeld(ShopifyOrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"): Boolean
    begin
        if not ShopifyOrderHeader."Tax Match Applied" then
            exit(false);
        if ShopifyOrderHeader."Tax Match Reviewed" then
            exit(false);
        exit(IsHeldForReviewPreference(ShopifyOrderHeader, Shop) or ShopifyOrderHeader."Tax Rate Conflict" or ShopifyOrderHeader."Tax Match Incomplete");
    end;

    /// <summary>
    /// Evaluates only the shop's review-mode preference for an order (independent of the hard
    /// rate-conflict / incomplete gates and of the Applied/Reviewed markers). Always holds; Never
    /// does not; Low Confidence Only holds when the order carries at least one non-high-confidence
    /// match (Tax Match Low Confidence — which includes a match to a provisional, agent-created
    /// jurisdiction that was forced low). Shared by the gate and the order/review UI so the hold
    /// decision is computed in exactly one place.
    /// </summary>
    internal procedure IsHeldForReviewPreference(ShopifyOrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"): Boolean
    begin
        case Shop."Tax Match Review Mode" of
            Shop."Tax Match Review Mode"::Always:
                exit(true);
            Shop."Tax Match Review Mode"::Never:
                exit(false);
            Shop."Tax Match Review Mode"::"Low Confidence Only":
                exit(ShopifyOrderHeader."Tax Match Low Confidence");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnAfterCreateSalesHeader, '', false, false)]
    local procedure OnAfterCreateSalesHeaderSubscriber(OrderHeader: Record "Shpfy Order Header"; var SalesHeader: Record "Sales Header")
    begin
        HandleSalesHeaderCreated(OrderHeader, SalesHeader);
    end;

    /// <summary>
    /// Propagates the Tax Match Applied marker from the originating Shopify Order
    /// Header onto the BC Sales Header. Exposed as internal so tests can drive the
    /// propagation without going through the connector's CreateHeaderFromShopifyOrder path.
    /// The Sales Order review prompt is derived live from this marker plus the order's
    /// Tax Match Reviewed flag — nothing is queued here.
    /// </summary>
    internal procedure HandleSalesHeaderCreated(OrderHeader: Record "Shpfy Order Header"; var SalesHeader: Record "Sales Header")
    var
        TMARegister: Codeunit "Shpfy TMA Register";
    begin
        if not OrderHeader."Tax Match Applied" then
            exit;

        SalesHeader."Shpfy Tax Match Applied" := true;
        SalesHeader.Modify();

        Session.LogMessage('0000UMJ', MarkerPropagatedMsg,
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TMARegister.FeatureName(), ShopifyOrderIdDimTok, Format(OrderHeader."Shopify Order Id"));
    end;
}

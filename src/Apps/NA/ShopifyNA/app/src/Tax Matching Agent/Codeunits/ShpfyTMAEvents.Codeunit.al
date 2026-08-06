namespace Microsoft.Integration.Shopify;

using Microsoft.Sales.Document;
using System.AI;
using System.Telemetry;

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
        StartingMatchMsg: Label 'Shopify Tax Matching Agent: Starting match for order %1', Locked = true, Comment = '%1 = Shopify Order Id';
        ReviewRequiredErr: Label 'The Sales Document for Shopify order %1 cannot be created until the tax match has been approved. Open the order, choose Review Tax Match, and approve the match on the review page — or clear Tax Match Review Required on the Shopify Shop Card.', Comment = '%1 = Shopify Order No.';
        RateConflictBlockErr: Label 'The Sales Document for Shopify order %1 cannot be created because a matched tax rate differs from Business Central. Open the order, choose Review Tax Match, and either approve the match to accept Business Central''s rates or correct the Tax Detail rate or Tax Jurisdiction, on the review page.', Comment = '%1 = Shopify Order No.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnAfterMapShopifyOrder, '', false, false)]
    local procedure OnAfterMapShopifyOrder(var ShopifyOrderHeader: Record "Shpfy Order Header"; Result: Boolean)
    var
        Shop: Record "Shpfy Shop";
        CopilotCapability: Codeunit "Copilot Capability";
        TMAMatcher: Codeunit "Shpfy TMA Matcher";
        TaxAreaBuilder: Codeunit "Shpfy Tax Area Builder";
        CTActivityLog: Codeunit "Shpfy TMA Activity Log";
        TMARegister: Codeunit "Shpfy TMA Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        MatchedJurisdictions: List of [Code[10]];
        MatchLog: JsonArray;
        ResolvedTaxAreaCode: Code[20];
        TaxAreaWasCreated: Boolean;
        HasRateConflict: Boolean;
        MatchApplied: Boolean;
    begin
        if not Result then
            exit;

        if not Shop.Get(ShopifyOrderHeader."Shop Code") then
            exit;

        if not ShouldAttemptMatch(ShopifyOrderHeader, Shop) then
            exit;

        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Shpfy Tax Matching") then
            exit;

        if not CopilotCapability.IsCapabilityActive(Enum::"Copilot Capability"::"Shpfy Tax Matching") then
            exit;

        // Reset markers before re-matching (e.g. when a user manually cleared Tax Area Code to force a re-run).
        if ShopifyOrderHeader."Tax Match Applied" or ShopifyOrderHeader."Tax Match Reviewed" or ShopifyOrderHeader."Tax Rate Conflict" then begin
            ShopifyOrderHeader."Tax Match Applied" := false;
            ShopifyOrderHeader."Tax Match Reviewed" := false;
            ShopifyOrderHeader."Tax Rate Conflict" := false;
            ShopifyOrderHeader.Modify();
        end;

        Session.LogMessage('0000UMK', StrSubstNo(StartingMatchMsg, ShopifyOrderHeader."Shopify Order Id"),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TMARegister.FeatureName());

        MatchApplied := TMAMatcher.MatchTaxLines(ShopifyOrderHeader, Shop, MatchedJurisdictions, MatchLog, HasRateConflict);
        if not MatchApplied then
            exit;

        // A matched jurisdiction may carry a rate that conflicts with BC (HasRateConflict). The
        // jurisdiction is still correct, so the Tax Area is built as usual; the conflict is
        // recorded on the order so the review gate always holds it — the reviewer accepts BC's
        // rate or corrects the Tax Detail before a Sales Document is created.
        if MatchedJurisdictions.Count() > 0 then
            if TaxAreaBuilder.FindOrCreateTaxArea(ShopifyOrderHeader, Shop, MatchedJurisdictions, ResolvedTaxAreaCode, TaxAreaWasCreated) then begin
                ShopifyOrderHeader."Tax Match Applied" := true;
                ShopifyOrderHeader."Tax Rate Conflict" := HasRateConflict;
                ShopifyOrderHeader.Modify();
                FeatureTelemetry.LogUsage('0000UMG', TMARegister.FeatureName(), 'tax match marker set on order');
                if HasRateConflict then
                    FeatureTelemetry.LogUsage('0000UMF', TMARegister.FeatureName(), 'tax match held pending rate conflict resolution');

                CTActivityLog.LogPerLineEntries(ShopifyOrderHeader, MatchLog);
                CTActivityLog.LogTaxAreaEntry(ShopifyOrderHeader, ResolvedTaxAreaCode, TaxAreaWasCreated, MatchedJurisdictions);
            end;

        FeatureTelemetry.LogUsage('0000UMH', TMARegister.FeatureName(), 'Tax lines matched');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnBeforeCreateSalesHeader, '', false, false)]
    local procedure OnBeforeCreateSalesHeaderSubscriber(ShopifyOrderHeader: Record "Shpfy Order Header"; var SalesHeader: Record "Sales Header"; var LastCreatedDocumentId: Guid; var Handled: Boolean)
    var
        Shop: Record "Shpfy Shop";
        TMARegister: Codeunit "Shpfy TMA Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if Handled then
            exit;

        if not Shop.Get(ShopifyOrderHeader."Shop Code") then
            exit;

        if not IsSalesDocumentCreationHeld(ShopifyOrderHeader, Shop) then
            exit;

        Handled := true;
        FeatureTelemetry.LogUsage('0000UMI', TMARegister.FeatureName(), 'Sales Document creation blocked pending tax match review');

        // In an interactive session surface a clear error so the user knows what to do.
        // In background flows (job queue, webhook) silently set Handled := true so the
        // pending order is just skipped this cycle without polluting the error log. The
        // message depends on which condition holds the order: a rate conflict cannot be
        // cleared from the Shop Card, so only the review-required case mentions that toggle.
        if GuiAllowed() then
            if ShopifyOrderHeader."Tax Rate Conflict" then
                Error(RateConflictBlockErr, ShopifyOrderHeader."Shopify Order No.")
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
    /// when the order was matched, is not yet approved, and either the shop requires review or the
    /// order carries a rate conflict (the stored Tax Rate Conflict flag — the single
    /// source of truth). A rate conflict holds the order regardless of the review-required toggle,
    /// so a human sees the difference before a Sales Document is created. Exposed as internal so
    /// the gate decision can be tested without driving the connector's create-document flow.
    /// </summary>
    internal procedure IsSalesDocumentCreationHeld(ShopifyOrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"): Boolean
    begin
        if not ShopifyOrderHeader."Tax Match Applied" then
            exit(false);
        if ShopifyOrderHeader."Tax Match Reviewed" then
            exit(false);
        exit(Shop."Tax Match Review Required" or ShopifyOrderHeader."Tax Rate Conflict");
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
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if not OrderHeader."Tax Match Applied" then
            exit;

        SalesHeader."Tax Match Applied" := true;
        SalesHeader.Modify();

        FeatureTelemetry.LogUsage('0000UMJ', TMARegister.FeatureName(), 'tax match marker propagated to Sales Header');
    end;
}

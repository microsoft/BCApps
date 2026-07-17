namespace Microsoft.Integration.Shopify;

using Microsoft.Sales.Document;
using System.AI;
using System.Telemetry;

/// <summary>
/// Codeunit Shpfy Copilot Tax Events (ID 30473).
/// Subscribes to OnAfterMapShopifyOrder to trigger Copilot tax matching, and to
/// OnAfterCreateSalesHeader to propagate the Copilot tax matching marker onto
/// the resulting BC Sales Header so a human can review what Copilot did.
/// </summary>
codeunit 30473 "Shpfy Copilot Tax Events"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        StartingMatchMsg: Label 'Shopify Copilot Tax Matching: Starting match for order %1', Locked = true, Comment = '%1 = Shopify Order Id';
        ReviewRequiredErr: Label 'The Sales Document for Shopify order %1 cannot be created until the Copilot tax match has been approved. Open the order, choose Review Copilot Tax Match, and approve the match on the review page — or clear Copilot Tax Match Review Required on the Shopify Shop Card.', Comment = '%1 = Shopify Order No.';
        RateConflictBlockErr: Label 'The Sales Document for Shopify order %1 cannot be created because a matched tax rate differs from Business Central. Open the order, choose Review Copilot Tax Match, and either approve the match to accept Business Central''s rates or correct the Tax Detail rate or Tax Jurisdiction, on the review page.', Comment = '%1 = Shopify Order No.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnAfterMapShopifyOrder, '', false, false)]
    local procedure OnAfterMapShopifyOrder(var ShopifyOrderHeader: Record "Shpfy Order Header"; Result: Boolean)
    var
        Shop: Record "Shpfy Shop";
        CopilotCapability: Codeunit "Copilot Capability";
        CopilotTaxMatcher: Codeunit "Shpfy Copilot Tax Matcher";
        TaxAreaBuilder: Codeunit "Shpfy Tax Area Builder";
        CTActivityLog: Codeunit "Shpfy CT Activity Log";
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
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

        if ShopifyOrderHeader."Tax Area Code" <> '' then
            exit;

        if ShopifyOrderHeader."Tax Exempt" then
            exit;

        if not Shop.Get(ShopifyOrderHeader."Shop Code") then
            exit;

        if not Shop."Copilot Tax Matching Enabled" then
            exit;

        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Shpfy Tax Matching") then
            exit;

        if not CopilotCapability.IsCapabilityActive(Enum::"Copilot Capability"::"Shpfy Tax Matching") then
            exit;

        // Reset markers before re-matching (e.g. when a user manually cleared Tax Area Code to force a re-run).
        if ShopifyOrderHeader."Copilot Tax Match Applied" or ShopifyOrderHeader."Copilot Tax Match Reviewed" or ShopifyOrderHeader."Copilot Tax Rate Conflict" then begin
            ShopifyOrderHeader."Copilot Tax Match Applied" := false;
            ShopifyOrderHeader."Copilot Tax Match Reviewed" := false;
            ShopifyOrderHeader."Copilot Tax Rate Conflict" := false;
            ShopifyOrderHeader.Modify();
        end;

        Session.LogMessage('0000UMK', StrSubstNo(StartingMatchMsg, ShopifyOrderHeader."Shopify Order Id"),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', CopilotTaxRegister.FeatureName());

        MatchApplied := CopilotTaxMatcher.MatchTaxLines(ShopifyOrderHeader, Shop, MatchedJurisdictions, MatchLog, HasRateConflict);
        if not MatchApplied then
            exit;

        // A matched jurisdiction may carry a rate that conflicts with BC (HasRateConflict). The
        // jurisdiction is still correct, so the Tax Area is built as usual; the conflict is
        // recorded on the order so the review gate always holds it — the reviewer accepts BC's
        // rate or corrects the Tax Detail before a Sales Document is created.
        if MatchedJurisdictions.Count() > 0 then
            if TaxAreaBuilder.FindOrCreateTaxArea(ShopifyOrderHeader, Shop, MatchedJurisdictions, ResolvedTaxAreaCode, TaxAreaWasCreated) then begin
                ShopifyOrderHeader."Copilot Tax Match Applied" := true;
                ShopifyOrderHeader."Copilot Tax Rate Conflict" := HasRateConflict;
                ShopifyOrderHeader.Modify();
                FeatureTelemetry.LogUsage('0000UMG', CopilotTaxRegister.FeatureName(), 'Copilot tax marker set on order');
                if HasRateConflict then
                    FeatureTelemetry.LogUsage('0000UMF', CopilotTaxRegister.FeatureName(), 'Copilot tax match held pending rate conflict resolution');

                CTActivityLog.LogPerLineEntries(ShopifyOrderHeader, MatchLog);
                CTActivityLog.LogTaxAreaEntry(ShopifyOrderHeader, ResolvedTaxAreaCode, TaxAreaWasCreated, MatchedJurisdictions);
            end;

        FeatureTelemetry.LogUsage('0000UMH', CopilotTaxRegister.FeatureName(), 'Tax lines matched');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnBeforeCreateSalesHeader, '', false, false)]
    local procedure OnBeforeCreateSalesHeaderSubscriber(ShopifyOrderHeader: Record "Shpfy Order Header"; var SalesHeader: Record "Sales Header"; var LastCreatedDocumentId: Guid; var Handled: Boolean)
    var
        Shop: Record "Shpfy Shop";
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if Handled then
            exit;

        if not Shop.Get(ShopifyOrderHeader."Shop Code") then
            exit;

        if not IsSalesDocumentCreationHeld(ShopifyOrderHeader, Shop) then
            exit;

        Handled := true;
        FeatureTelemetry.LogUsage('0000UMI', CopilotTaxRegister.FeatureName(), 'Sales Document creation blocked pending Copilot tax match review');

        // In an interactive session surface a clear error so the user knows what to do.
        // In background flows (job queue, webhook) silently set Handled := true so the
        // pending order is just skipped this cycle without polluting the error log. The
        // message depends on which condition holds the order: a rate conflict cannot be
        // cleared from the Shop Card, so only the review-required case mentions that toggle.
        if GuiAllowed() then
            if ShopifyOrderHeader."Copilot Tax Rate Conflict" then
                Error(RateConflictBlockErr, ShopifyOrderHeader."Shopify Order No.")
            else
                Error(ReviewRequiredErr, ShopifyOrderHeader."Shopify Order No.");
    end;

    /// <summary>
    /// Decides whether Sales Document creation must be held for a Copilot-matched order. Held
    /// when the order was matched, is not yet approved, and either the shop requires review or the
    /// order carries a rate conflict (the stored Copilot Tax Rate Conflict flag — the single
    /// source of truth). A rate conflict holds the order regardless of the review-required toggle,
    /// so a human sees the difference before a Sales Document is created. Exposed as internal so
    /// the gate decision can be tested without driving the connector's create-document flow.
    /// </summary>
    internal procedure IsSalesDocumentCreationHeld(ShopifyOrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"): Boolean
    begin
        if not ShopifyOrderHeader."Copilot Tax Match Applied" then
            exit(false);
        if ShopifyOrderHeader."Copilot Tax Match Reviewed" then
            exit(false);
        exit(Shop."Tax Match Review Required" or ShopifyOrderHeader."Copilot Tax Rate Conflict");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnAfterCreateSalesHeader, '', false, false)]
    local procedure OnAfterCreateSalesHeaderSubscriber(OrderHeader: Record "Shpfy Order Header"; var SalesHeader: Record "Sales Header")
    begin
        HandleSalesHeaderCreated(OrderHeader, SalesHeader);
    end;

    /// <summary>
    /// Propagates the Copilot Tax Match Applied marker from the originating Shopify Order
    /// Header onto the BC Sales Header. Exposed as internal so tests can drive the
    /// propagation without going through the connector's CreateHeaderFromShopifyOrder path.
    /// The Sales Order review prompt is derived live from this marker plus the order's
    /// Copilot Tax Match Reviewed flag — nothing is queued here.
    /// </summary>
    internal procedure HandleSalesHeaderCreated(OrderHeader: Record "Shpfy Order Header"; var SalesHeader: Record "Sales Header")
    var
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if not OrderHeader."Copilot Tax Match Applied" then
            exit;

        SalesHeader."Copilot Tax Match Applied" := true;
        SalesHeader.Modify();

        FeatureTelemetry.LogUsage('0000UMJ', CopilotTaxRegister.FeatureName(), 'Copilot tax marker propagated to Sales Header');
    end;
}

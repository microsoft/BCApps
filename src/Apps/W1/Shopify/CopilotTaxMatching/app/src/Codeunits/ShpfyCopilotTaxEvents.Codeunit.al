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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnAfterMapShopifyOrder, '', false, false)]
    local procedure OnAfterMapShopifyOrder(var ShopifyOrderHeader: Record "Shpfy Order Header"; Result: Boolean)
    var
        Shop: Record "Shpfy Shop";
        CopilotCapability: Codeunit "Copilot Capability";
        TaxMatcher: Codeunit "Shpfy Copilot Tax Matcher";
        TaxAreaBuilder: Codeunit "Shpfy Tax Area Builder";
        ActivityLog: Codeunit "Shpfy CT Activity Log";
        ShpfyCopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        MatchedJurisdictions: List of [Code[10]];
        MatchLog: JsonArray;
        ResolvedTaxAreaCode: Code[20];
        TaxAreaWasCreated: Boolean;
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

        // Reset marker before re-matching (e.g. when a user manually cleared Tax Area Code to force a re-run).
        if ShopifyOrderHeader."Copilot Tax Match Applied" then begin
            ShopifyOrderHeader."Copilot Tax Match Applied" := false;
            ShopifyOrderHeader.Modify();
        end;

        Session.LogMessage('0000SH8', StrSubstNo(StartingMatchMsg, ShopifyOrderHeader."Shopify Order Id"),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', ShpfyCopilotTaxRegister.FeatureName());

        if TaxMatcher.MatchTaxLines(ShopifyOrderHeader, Shop, MatchedJurisdictions, MatchLog) then begin
            if MatchedJurisdictions.Count() > 0 then
                if TaxAreaBuilder.FindOrCreateTaxArea(ShopifyOrderHeader, Shop, MatchedJurisdictions, ResolvedTaxAreaCode, TaxAreaWasCreated) then begin
                    ShopifyOrderHeader."Copilot Tax Match Applied" := true;
                    ShopifyOrderHeader.Modify();
                    FeatureTelemetry.LogUsage('0000SHA', ShpfyCopilotTaxRegister.FeatureName(), 'Copilot tax marker set on order');

                    ActivityLog.LogPerLineEntries(ShopifyOrderHeader, MatchLog);
                    ActivityLog.LogTaxAreaEntry(ShopifyOrderHeader, ResolvedTaxAreaCode, TaxAreaWasCreated, MatchedJurisdictions);
                end;

            FeatureTelemetry.LogUsage('0000SH9', ShpfyCopilotTaxRegister.FeatureName(), 'Tax lines matched');
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Order Events", OnAfterCreateSalesHeader, '', false, false)]
    local procedure OnAfterCreateSalesHeaderSubscriber(OrderHeader: Record "Shpfy Order Header"; var SalesHeader: Record "Sales Header")
    begin
        HandleSalesHeaderCreated(OrderHeader, SalesHeader);
    end;

    /// <summary>
    /// Propagates the Copilot Tax Match Applied marker from the originating Shopify Order
    /// Header onto the BC Sales Header, and queues the review notification. Exposed as
    /// internal so tests can drive the propagation without going through the connector's
    /// CreateHeaderFromShopifyOrder path.
    /// </summary>
    internal procedure HandleSalesHeaderCreated(OrderHeader: Record "Shpfy Order Header"; var SalesHeader: Record "Sales Header")
    var
        Notify: Codeunit "Shpfy Copilot Tax Notify";
        ShpfyCopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if not OrderHeader."Copilot Tax Match Applied" then
            exit;

        SalesHeader."Copilot Tax Match Applied" := true;
        SalesHeader.Modify();

        FeatureTelemetry.LogUsage('0000SHB', ShpfyCopilotTaxRegister.FeatureName(), 'Copilot tax marker propagated to Sales Header');

        Notify.QueueNotificationFor(SalesHeader, OrderHeader);
    end;

    var
        StartingMatchMsg: Label 'Shopify Copilot Tax Matching: Starting match for order %1', Locked = true, Comment = '%1 = Shopify Order Id';
}

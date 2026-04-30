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
    local procedure OnAfterMapShopifyOrder(var OrderHeader: Record "Shpfy Order Header"; Result: Boolean)
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
    begin
        if not Result then
            exit;

        if OrderHeader."Tax Area Code" <> '' then
            exit;

        if OrderHeader."Tax Exempt" then
            exit;

        if not Shop.Get(OrderHeader."Shop Code") then
            exit;

        if not Shop."Copilot Tax Matching Enabled" then
            exit;

        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Shpfy Tax Matching") then
            exit;

        if not CopilotCapability.IsCapabilityActive(Enum::"Copilot Capability"::"Shpfy Tax Matching") then
            exit;

        // Reset marker before re-matching (e.g. when a user manually cleared Tax Area Code to force a re-run).
        if OrderHeader."Copilot Tax Match Applied" then begin
            OrderHeader."Copilot Tax Match Applied" := false;
            OrderHeader.Modify();
        end;

        Session.LogMessage('', StrSubstNo(StartingMatchMsg, OrderHeader."Shopify Order Id"),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', CopilotTaxRegister.FeatureName());

        if CopilotTaxMatcher.MatchTaxLines(OrderHeader, Shop, MatchedJurisdictions, MatchLog) then begin
            if MatchedJurisdictions.Count() > 0 then
                if TaxAreaBuilder.FindOrCreateTaxArea(OrderHeader, Shop, MatchedJurisdictions, ResolvedTaxAreaCode, TaxAreaWasCreated) then begin
                    OrderHeader."Copilot Tax Match Applied" := true;
                    OrderHeader.Modify();
                    FeatureTelemetry.LogUsage('', CopilotTaxRegister.FeatureName(), 'Copilot tax marker set on order');

                    CTActivityLog.LogPerLineEntries(OrderHeader, MatchLog);
                    CTActivityLog.LogTaxAreaEntry(OrderHeader, ResolvedTaxAreaCode, TaxAreaWasCreated, MatchedJurisdictions);
                end;

            FeatureTelemetry.LogUsage('', CopilotTaxRegister.FeatureName(), 'Tax lines matched');
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
        CopilotTaxNotify: Codeunit "Shpfy Copilot Tax Notify";
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if not OrderHeader."Copilot Tax Match Applied" then
            exit;

        SalesHeader."Copilot Tax Match Applied" := true;
        SalesHeader.Modify();

        FeatureTelemetry.LogUsage('', CopilotTaxRegister.FeatureName(), 'Copilot tax marker propagated to Sales Header');

        CopilotTaxNotify.QueueNotificationFor(SalesHeader, OrderHeader);
    end;

    var
        StartingMatchMsg: Label 'Shopify Copilot Tax Matching: Starting match for order %1', Locked = true, Comment = '%1 = Shopify Order Id';
}

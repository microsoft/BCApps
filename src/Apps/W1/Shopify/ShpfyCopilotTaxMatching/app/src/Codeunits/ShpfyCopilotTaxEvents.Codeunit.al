namespace Microsoft.Integration.Shopify;

using System.AI;
using System.Telemetry;

/// <summary>
/// Codeunit Shpfy Copilot Tax Events (ID 30473).
/// Subscribes to OnAfterMapShopifyOrder to trigger Copilot tax matching.
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
        ShpfyCopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        MatchedJurisdictions: List of [Code[10]];
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

        Session.LogMessage('0000SH8', StrSubstNo(StartingMatchMsg, ShopifyOrderHeader."Shopify Order Id"),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', ShpfyCopilotTaxRegister.FeatureName());

        if TaxMatcher.MatchTaxLines(ShopifyOrderHeader, Shop, MatchedJurisdictions) then begin
            if MatchedJurisdictions.Count() > 0 then
                TaxAreaBuilder.FindOrCreateTaxArea(ShopifyOrderHeader, Shop, MatchedJurisdictions);

            FeatureTelemetry.LogUsage('0000SH9', ShpfyCopilotTaxRegister.FeatureName(), 'Tax lines matched');
        end;
    end;

    var
        StartingMatchMsg: Label 'Shopify Copilot Tax Matching: Starting match for order %1', Locked = true, Comment = '%1 = Shopify Order Id';
}

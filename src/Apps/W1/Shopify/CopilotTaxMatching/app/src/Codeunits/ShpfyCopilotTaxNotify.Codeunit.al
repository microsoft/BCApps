namespace Microsoft.Integration.Shopify;

using Microsoft.Sales.Document;
using System.Environment.Configuration;
using System.Telemetry;

/// <summary>
/// Codeunit Shpfy Copilot Tax Notify (ID 30476).
/// Owns the Copilot tax review notifications (on the BC Sales Order and the Shopify Order)
/// and the review-page drills. The notifications are stateless: whether to prompt is
/// derived live from the Sales Header marker, the originating Shopify order's
/// Copilot Tax Match Reviewed flag, and the per-user My Notifications toggle — there is no
/// dedicated notification table.
/// </summary>
codeunit 30476 "Shpfy Copilot Tax Notify"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    /// <summary>
    /// Fires the review prompt on the Sales Order when Copilot populated its tax fields and
    /// the originating Shopify order has not yet been reviewed. Stateless — whether to prompt
    /// comes from the order's Copilot Tax Match Reviewed flag plus the per-user My
    /// Notifications toggle, so no per-user row is stored.
    /// </summary>
    procedure SendForCurrentSalesHeader(SalesHeader: Record "Sales Header")
    var
        OrderHeader: Record "Shpfy Order Header";
        MyNotifications: Record "My Notifications";
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Notif: Notification;
    begin
        if not GuiAllowed() then
            exit;
        if not FindOrderForReview(SalesHeader, OrderHeader) then
            exit;
        if OrderHeader."Copilot Tax Match Reviewed" then
            exit;

        if MyNotifications.WritePermission() then
            MyNotifications.InsertDefault(GetFeatureNotificationId(), MyNotificationCaptionLbl, MyNotificationDescriptionLbl, true);
        if not MyNotifications.IsEnabled(GetFeatureNotificationId()) then
            exit;

        Notif.Id := GetFeatureNotificationId();
        Notif.Message(StrSubstNo(NotifMsgLbl, SalesHeader."Tax Area Code"));
        Notif.Scope := NotificationScope::LocalScope;
        Notif.SetData('SalesHeaderSystemId', Format(SalesHeader.SystemId));
        Notif.AddAction(ShowDecisionsActionLbl, Codeunit::"Shpfy Copilot Tax Notify", 'OpenShopifyOrder');
        Notif.AddAction(MarkReviewedActionLbl, Codeunit::"Shpfy Copilot Tax Notify", 'MarkReviewed');
        Notif.AddAction(DisableActionLbl, Codeunit::"Shpfy Copilot Tax Notify", 'DisableForUser');
        Notif.Send();

        FeatureTelemetry.LogUsage('', CopilotTaxRegister.FeatureName(), 'Copilot tax notification sent');
    end;

    procedure OpenShopifyOrder(Notif: Notification)
    var
        SalesHeader: Record "Sales Header";
        OrderMgt: Codeunit "Shpfy Order Mgt.";
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        VariantRec: Variant;
    begin
        if not TryGetSalesHeader(Notif, SalesHeader) then
            exit;

        // Prefer the Copilot Tax Match Review page; fall back to the raw Shopify order.
        if not RunReviewForSalesHeader(SalesHeader) then begin
            VariantRec := SalesHeader;
            OrderMgt.ShowShopifyOrder(VariantRec);
        end;

        FeatureTelemetry.LogUsage('', CopilotTaxRegister.FeatureName(), 'Copilot tax review opened');
    end;

    /// <summary>
    /// Sends the actionable review prompt on the Shopify order itself, once per order per
    /// page session. Clicking Review opens the Copilot Tax Match Review page.
    /// </summary>
    procedure SendOrderReviewNotification(OrderHeader: Record "Shpfy Order Header")
    var
        MyNotifications: Record "My Notifications";
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Notif: Notification;
    begin
        if not GuiAllowed() then
            exit;

        if MyNotifications.WritePermission() then
            MyNotifications.InsertDefault(GetOrderNotificationId(), OrderMyNotifCaptionLbl, OrderMyNotifDescriptionLbl, true);
        if not MyNotifications.IsEnabled(GetOrderNotificationId()) then
            exit;

        Notif.Id := GetOrderNotificationId();
        Notif.Message(StrSubstNo(OrderNotifMsgLbl, OrderHeader."Tax Area Code"));
        Notif.Scope := NotificationScope::LocalScope;
        Notif.SetData('ShpfyOrderSystemId', Format(OrderHeader.SystemId));
        Notif.AddAction(OrderReviewActionLbl, Codeunit::"Shpfy Copilot Tax Notify", 'OpenReviewForOrder');
        Notif.AddAction(DisableActionLbl, Codeunit::"Shpfy Copilot Tax Notify", 'DisableOrderNotifForUser');
        Notif.Send();

        FeatureTelemetry.LogUsage('', CopilotTaxRegister.FeatureName(), 'Copilot tax order review notification sent');
    end;

    procedure OpenReviewForOrder(Notif: Notification)
    var
        OrderHeader: Record "Shpfy Order Header";
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SystemIdText: Text;
        OrderSystemId: Guid;
    begin
        SystemIdText := Notif.GetData('ShpfyOrderSystemId');
        if SystemIdText = '' then
            exit;
        if not Evaluate(OrderSystemId, SystemIdText) then
            exit;
        if not OrderHeader.GetBySystemId(OrderSystemId) then
            exit;

        RunReviewPage(OrderHeader);

        FeatureTelemetry.LogUsage('', CopilotTaxRegister.FeatureName(), 'Copilot tax order review opened');
    end;

    procedure DisableOrderNotifForUser(Notif: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        if MyNotifications.WritePermission() then
            if not MyNotifications.Disable(GetOrderNotificationId()) then
                MyNotifications.InsertDefault(GetOrderNotificationId(), OrderMyNotifCaptionLbl, OrderMyNotifDescriptionLbl, false);
    end;

    /// <summary>
    /// Opens the Copilot Tax Match Review page for the Shopify order that produced the given
    /// Sales Header (resolved via Shpfy Order Header."Sales Order No."). Returns false when no
    /// such order exists, so callers can fall back to another surface.
    /// </summary>
    internal procedure RunReviewForSalesHeader(SalesHeader: Record "Sales Header"): Boolean
    var
        OrderHeader: Record "Shpfy Order Header";
    begin
        if not FindOrderForReview(SalesHeader, OrderHeader) then
            exit(false);

        RunReviewPage(OrderHeader);
        exit(true);
    end;

    /// <summary>
    /// The single entry point that opens the Copilot Tax Match Review page for a Shopify
    /// order. All review surfaces (order-page action, order-page notification, Sales Order
    /// action, Sales Order notification) resolve their Shpfy Order Header and route through
    /// here, so the page is opened one consistent way.
    /// </summary>
    internal procedure RunReviewPage(var OrderHeader: Record "Shpfy Order Header")
    begin
        OrderHeader.SetRecFilter();
        Page.Run(Page::"Shpfy Copilot Tax Review", OrderHeader);
    end;

    procedure MarkReviewed(Notif: Notification)
    var
        SalesHeader: Record "Sales Header";
        OrderHeader: Record "Shpfy Order Header";
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if not TryGetSalesHeader(Notif, SalesHeader) then
            exit;
        if not FindOrderForReview(SalesHeader, OrderHeader) then
            exit;
        if OrderHeader."Copilot Tax Match Reviewed" then
            exit;

        OrderHeader."Copilot Tax Match Reviewed" := true;
        OrderHeader.Modify();

        FeatureTelemetry.LogUsage('', CopilotTaxRegister.FeatureName(), 'Copilot tax notification marked reviewed');
    end;

    procedure DisableForUser(Notif: Notification)
    var
        MyNotifications: Record "My Notifications";
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if MyNotifications.WritePermission() then
            if not MyNotifications.Disable(GetFeatureNotificationId()) then
                MyNotifications.InsertDefault(GetFeatureNotificationId(), MyNotificationCaptionLbl, MyNotificationDescriptionLbl, false);
        MarkReviewed(Notif);

        FeatureTelemetry.LogUsage('', CopilotTaxRegister.FeatureName(), 'Copilot tax notification disabled per user');
    end;

    /// <summary>
    /// Resolves the originating Shopify order for a Sales Header via
    /// Shpfy Order Header."Sales Order No.". Returns false when the Sales Header has no
    /// number or no linked Shopify order.
    /// </summary>
    local procedure FindOrderForReview(SalesHeader: Record "Sales Header"; var OrderHeader: Record "Shpfy Order Header"): Boolean
    begin
        if SalesHeader."No." = '' then
            exit(false);
        OrderHeader.SetRange("Sales Order No.", SalesHeader."No.");
        exit(OrderHeader.FindFirst());
    end;

    local procedure TryGetSalesHeader(Notif: Notification; var SalesHeader: Record "Sales Header"): Boolean
    var
        SystemIdText: Text;
        SystemId: Guid;
    begin
        SystemIdText := Notif.GetData('SalesHeaderSystemId');
        if SystemIdText = '' then
            exit(false);
        if not Evaluate(SystemId, SystemIdText) then
            exit(false);
        exit(SalesHeader.GetBySystemId(SystemId));
    end;

    local procedure GetFeatureNotificationId(): Guid
    var
        FeatureNotificationId: Guid;
    begin
        Evaluate(FeatureNotificationId, FeatureNotificationIdLbl);
        exit(FeatureNotificationId);
    end;

    local procedure GetOrderNotificationId(): Guid
    var
        OrderNotificationId: Guid;
    begin
        Evaluate(OrderNotificationId, OrderNotificationIdLbl);
        exit(OrderNotificationId);
    end;

    var
        FeatureNotificationIdLbl: Label '{e9d8c7b6-a5f4-4e32-9d10-cb87a65f43e2}', Locked = true;
        OrderNotificationIdLbl: Label '{a7c3f1e2-9b4d-4c8a-8e6f-2d1b0a9c8e7d}', Locked = true;
        NotifMsgLbl: Label 'Copilot set Tax Area %1 on this Shopify order. Review before posting.', Comment = '%1 = Tax Area Code';
        OrderNotifMsgLbl: Label 'Copilot set Tax Area %1 on this Shopify order. Review the matched tax jurisdictions.', Comment = '%1 = Tax Area Code';
        ShowDecisionsActionLbl: Label 'Show Copilot Tax Decisions';
        OrderReviewActionLbl: Label 'Review';
        MarkReviewedActionLbl: Label 'Mark as reviewed';
        DisableActionLbl: Label 'Don''t show again';
        MyNotificationCaptionLbl: Label 'Shopify Copilot Tax Matching review prompt';
        MyNotificationDescriptionLbl: Label 'Shows a one-time prompt on each Sales Order where Copilot populated tax fields from a Shopify order, so you can review the AI-generated decisions before posting.';
        OrderMyNotifCaptionLbl: Label 'Shopify Copilot Tax Matching order review prompt';
        OrderMyNotifDescriptionLbl: Label 'Shows a prompt on a Shopify order whose tax was matched by Copilot, so you can review and approve the AI-generated tax match.';
}

namespace Microsoft.Integration.Shopify;

using Microsoft.Sales.Document;
using System.Environment.Configuration;
using System.Telemetry;

/// <summary>
/// Codeunit Shpfy Copilot Tax Notify (ID 30476).
/// Owns the non-blocking review notification that fires once when a user opens a Sales
/// Order whose tax fields were populated by Copilot. The notification queue is recorded
/// in the Shpfy Copilot Tax Notification table so the prompt can be replayed across
/// sessions until the user marks it reviewed or suppresses the feature notification.
/// </summary>
codeunit 30476 "Shpfy Copilot Tax Notify"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    procedure QueueNotificationFor(SalesHeader: Record "Sales Header"; OrderHeader: Record "Shpfy Order Header")
    var
        CopilotTaxNotification: Record "Shpfy Copilot Tax Notification";
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if CopilotTaxNotification.Get(SalesHeader.SystemId, UserId()) then
            exit;

        CopilotTaxNotification.Init();
        CopilotTaxNotification."Sales Header SystemId" := SalesHeader.SystemId;
        CopilotTaxNotification."User Id" := CopyStr(UserId(), 1, MaxStrLen(CopilotTaxNotification."User Id"));
        CopilotTaxNotification."Notification ID" := GetFeatureNotificationId();
        CopilotTaxNotification.Created := CurrentDateTime();
        CopilotTaxNotification."Tax Area Code" := SalesHeader."Tax Area Code";
        CopilotTaxNotification.Reviewed := false;
        if CopilotTaxNotification.Insert() then
            FeatureTelemetry.LogUsage('', CopilotTaxRegister.FeatureName(), 'Copilot tax notification queued');
    end;

    procedure SendForCurrentSalesHeader(SalesHeader: Record "Sales Header")
    var
        CopilotTaxNotification: Record "Shpfy Copilot Tax Notification";
        MyNotifications: Record "My Notifications";
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Notif: Notification;
    begin
        if not GuiAllowed() then
            exit;

        if not CopilotTaxNotification.Get(SalesHeader.SystemId, UserId()) then
            exit;
        if CopilotTaxNotification.Reviewed then
            exit;

        if MyNotifications.WritePermission() then
            MyNotifications.InsertDefault(GetFeatureNotificationId(), MyNotificationCaptionLbl, MyNotificationDescriptionLbl, true);
        if not MyNotifications.IsEnabled(GetFeatureNotificationId()) then
            exit;

        Notif.Id := CopilotTaxNotification."Notification ID";
        Notif.Message(StrSubstNo(NotifMsgLbl, CopilotTaxNotification."Tax Area Code"));
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

        VariantRec := SalesHeader;
        OrderMgt.ShowShopifyOrder(VariantRec);

        FeatureTelemetry.LogUsage('', CopilotTaxRegister.FeatureName(), 'Copilot tax review opened');
    end;

    procedure MarkReviewed(Notif: Notification)
    var
        CopilotTaxNotification: Record "Shpfy Copilot Tax Notification";
        SalesHeader: Record "Sales Header";
        CopilotTaxRegister: Codeunit "Shpfy Copilot Tax Register";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if not TryGetSalesHeader(Notif, SalesHeader) then
            exit;
        if not CopilotTaxNotification.Get(SalesHeader.SystemId, UserId()) then
            exit;

        CopilotTaxNotification.Reviewed := true;
        CopilotTaxNotification.Modify();

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

    var
        FeatureNotificationIdLbl: Label '{e9d8c7b6-a5f4-4e32-9d10-cb87a65f43e2}', Locked = true;
        NotifMsgLbl: Label 'Copilot set Tax Area %1 on this Shopify order. Review before posting.', Comment = '%1 = Tax Area Code';
        ShowDecisionsActionLbl: Label 'Show Copilot Tax Decisions';
        MarkReviewedActionLbl: Label 'Mark as reviewed';
        DisableActionLbl: Label 'Don''t show again';
        MyNotificationCaptionLbl: Label 'Shopify Copilot Tax Matching review prompt';
        MyNotificationDescriptionLbl: Label 'Shows a one-time prompt on each Sales Order where Copilot populated tax fields from a Shopify order, so you can review the AI-generated decisions before posting.';
}

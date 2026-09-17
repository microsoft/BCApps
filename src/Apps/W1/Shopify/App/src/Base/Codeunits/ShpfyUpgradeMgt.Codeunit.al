// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Integration;
using System.Upgrade;

/// <summary>
/// Codeunit Shpfy Upgrade Mgt. (ID 30106).
/// </summary>
codeunit 30106 "Shpfy Upgrade Mgt."
{
    Access = Internal;
    Subtype = Upgrade;
    Permissions = tabledata "Shpfy Shop" = RM,
                  tabledata "Shpfy Tax Area" = rimd,
                  tabledata "Webhook Subscription" = rimd;

    trigger OnUpgradePerDatabase()
    begin
        WebhookSubscriptionUpgrade();
    end;

    trigger OnUpgradePerCompany()
    begin
        SetAllowOutgoingRequests();
        LoggingModeUpgrade();
        LocationUpgrade();
        SyncPricesWithProductsUpgrade();
        SendShippingConfirmationUpgrade();
        OrderAttributeValueUpgrade();
        CreditMemoCanBeCreatedUpgrade();
        ArchiveProcessedOrdersUpgrade();
        SetShopifyCatalogsType();
        CreateInvoicesFromOrdersUpgrade();
        OrderTransactionShopCodeUpgrade();
        HasAdvancedShopifyPlanUpgrade();
        ItalianSardinianProvinceRenameUpgrade();
    end;







    local procedure SetAllowOutgoingRequests()
    var
        Shop: Record "Shpfy Shop";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetAllowOutgoingRequestseUpgradeTag()) then
            exit;

        Shop.SetFilter(SystemCreatedAt, '<%1', GetDateBeforeFeature());
        if Shop.FindSet() then
            repeat
                if not Shop."Allow Outgoing Requests" then begin
                    Shop."Allow Outgoing Requests" := true;
                    Shop.Modify();
                end;
            until Shop.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetAllowOutgoingRequestseUpgradeTag());
    end;



    local procedure LoggingModeUpgrade()
    var
        Shop: Record "Shpfy Shop";
        UpgradeTag: Codeunit "Upgrade Tag";
        ShopDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(GetLoggingModeUpgradeTag()) then
            exit;

        ShopDataTransfer.SetTables(Database::"Shpfy Shop", Database::"Shpfy Shop");
        ShopDataTransfer.AddConstantValue("Shpfy Logging Mode"::All, Shop.FieldNo("Logging Mode"));
        ShopDataTransfer.UpdateAuditFields := false;
        ShopDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(GetLoggingModeUpgradeTag());
    end;

    local procedure LocationUpgrade()
    var
        ShopLocation: Record "Shpfy Shop Location";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetLocationUpgradeTag()) then
            exit;

        if ShopLocation.FindSet(true) then
            repeat
                ShopLocation."Default Product Location" := true;
                ShopLocation.Modify();
            until ShopLocation.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetLocationUpgradeTag());
    end;

    local procedure SyncPricesWithProductsUpgrade()
    var
        Shop: Record "Shpfy Shop";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetSyncPricesWithProductsUpgradeTag()) then
            exit;

        if Shop.FindSet(true) then
            repeat
                Shop."Sync Prices" := true;
                Shop.Modify();
            until Shop.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetSyncPricesWithProductsUpgradeTag());
    end;

    internal procedure SetAutoReleaseSalesOrder()
    var
        ShpfyShop: Record "Shpfy Shop";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetAutoReleaseSalesOrderTag()) then
            exit;
        ShpfyShop.ModifyAll("Auto Release Sales Orders", true);
        UpgradeTag.SetUpgradeTag(GetAutoReleaseSalesOrderTag());
    end;

    local procedure SendShippingConfirmationUpgrade()
    var
        Shop: Record "Shpfy Shop";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetSendShippingConfirmationUpgradeTag()) then
            exit;

        if Shop.FindSet(true) then
            repeat
                Shop."Send Shipping Confirmation" := true;
                Shop.Modify();
            until Shop.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetSendShippingConfirmationUpgradeTag());
    end;

    local procedure OrderAttributeValueUpgrade()
    var
        OrderAttribute: Record "Shpfy Order Attribute";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetOrderAttributeValueUpgradeTag()) then
            exit;

        if not OrderAttribute.IsEmpty() then begin
        end;

        UpgradeTag.SetUpgradeTag(GetOrderAttributeValueUpgradeTag());
    end;

    local procedure CreditMemoCanBeCreatedUpgrade()
    var
        RefundHeader: Record "Shpfy Refund Header";
        UpgradeTag: Codeunit "Upgrade Tag";
        HeadersInFilter, MaxHeadersInFilter : Integer;
        RefundIdFilter: Text;
    begin
        if UpgradeTag.HasUpgradeTag(GetCreditMemoCanBeCreatedUpgradeTag()) then
            exit;

        MaxHeadersInFilter := 100;
        RefundHeader.SetFilter("Total Refunded Amount", '>%1', 0);
        if RefundHeader.FindSet() then
            repeat
                if RefundIdFilter <> '' then
                    RefundIdFilter += '|';
                RefundIdFilter += Format(RefundHeader."Refund Id");
                HeadersInFilter += 1;
                if HeadersInFilter >= MaxHeadersInFilter then begin
                    SetCanCreateCreditMemoInRefundLines(RefundIdFilter);
                    RefundIdFilter := '';
                    HeadersInFilter := 0;
                end;
            until RefundHeader.Next() = 0;
        if RefundIdFilter <> '' then
            SetCanCreateCreditMemoInRefundLines(RefundIdFilter);

        UpgradeTag.SetUpgradeTag(GetCreditMemoCanBeCreatedUpgradeTag());
    end;

    local procedure SetCanCreateCreditMemoInRefundLines(RefundIdFilter: Text)
    var
        RefundLine: Record "Shpfy Refund Line";
        RefundLineDataTransfer: DataTransfer;
    begin
        RefundLineDataTransfer.SetTables(Database::"Shpfy Refund Line", Database::"Shpfy Refund Line");
        RefundLineDataTransfer.AddSourceFilter(RefundLine.FieldNo("Refund Id"), RefundIdFilter);
        RefundLineDataTransfer.AddConstantValue(true, RefundLine.FieldNo("Can Create Credit Memo"));
        RefundLineDataTransfer.UpdateAuditFields(false);
        RefundLineDataTransfer.CopyFields();
    end;

    local procedure WebhookSubscriptionUpgrade()
    var
        WebhookSubscription: Record "Webhook Subscription";
        UpgradeTag: Codeunit "Upgrade Tag";
        WebhookTopic: Enum "Shpfy Webhook Topic";
    begin
        if UpgradeTag.HasUpgradeTag(GetWebhookSubscriptionUpgradeTag()) then
            exit;

        WebhookTopic := WebhookTopic::BULK_OPERATIONS_FINISH;
        WebhookSubscription.SetRange(Endpoint, WebhookTopic.Names.Get(WebhookTopic.Ordinals.IndexOf(WebhookTopic.AsInteger())));
        if WebhookSubscription.FindSet() then
            repeat
                UpdateWebhookSubscriptionTopic(WebhookSubscription, WebhookTopic);
            until WebhookSubscription.Next() = 0;

        WebhookTopic := WebhookTopic::ORDERS_CREATE;
        WebhookSubscription.SetRange(Endpoint, WebhookTopic.Names.Get(WebhookTopic.Ordinals.IndexOf(WebhookTopic.AsInteger())));
        if WebhookSubscription.FindSet() then
            repeat
                UpdateWebhookSubscriptionTopic(WebhookSubscription, WebhookTopic);
            until WebhookSubscription.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetWebhookSubscriptionUpgradeTag());
    end;

    local procedure UpdateWebhookSubscriptionTopic(var WebhookSubscription: Record "Webhook Subscription"; WebhookTopic: Enum "Shpfy Webhook Topic")
    var
        NewWebhookSubscription: Record "Webhook Subscription";
    begin
        if NewWebhookSubscription.Get(WebhookSubscription."Subscription ID", Format(WebhookTopic)) then
            NewWebhookSubscription.Delete();

        NewWebhookSubscription := WebhookSubscription;
        NewWebhookSubscription."Endpoint" := Format(WebhookTopic);
        NewWebhookSubscription.Insert();
        WebhookSubscription.Delete();
    end;

    local procedure ArchiveProcessedOrdersUpgrade()
    var
        Shop: Record "Shpfy Shop";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetArchiveProcessedOrdersUpgradeTag()) then
            exit;

        if not Shop.IsEmpty() then
            Shop.ModifyAll("Archive Processed Orders", true);

        UpgradeTag.SetUpgradeTag(GetArchiveProcessedOrdersUpgradeTag());
    end;

    local procedure SetShopifyCatalogsType()
    var
        Catalog: Record "Shpfy Catalog";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetShopifyCatalogsTypeUpgradeTag()) then
            exit;

        Catalog.SetRange("Catalog Type", Catalog."Catalog Type"::" ");
        Catalog.ModifyAll("Catalog Type", Catalog."Catalog Type"::"Company", false);

        UpgradeTag.SetUpgradeTag(GetShopifyCatalogsTypeUpgradeTag());
    end;

    local procedure CreateInvoicesFromOrdersUpgrade()
    var
        Shop: Record "Shpfy Shop";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetCreateInvoicesFromOrdersUpgradeTag()) then
            exit;

        if not Shop.IsEmpty() then
            Shop.ModifyAll("Create Invoices From Orders", true);

        UpgradeTag.SetUpgradeTag(GetCreateInvoicesFromOrdersUpgradeTag());
    end;

    local procedure OrderTransactionShopCodeUpgrade()
    var
        OrderTransaction: Record "Shpfy Order Transaction";
        OrderHeader: Record "Shpfy Order Header";
        UpgradeTag: Codeunit "Upgrade Tag";
        OrderTransactionDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(GetOrderTransactionShopCodeUpgradeTag()) then
            exit;

        OrderTransactionDataTransfer.SetTables(Database::"Shpfy Order Header", Database::"Shpfy Order Transaction");
        OrderTransactionDataTransfer.AddFieldValue(OrderHeader.FieldNo("Shop Code"), OrderTransaction.FieldNo("Shop"));
        OrderTransactionDataTransfer.AddJoin(OrderHeader.FieldNo("Shopify Order Id"), OrderTransaction.FieldNo("Shopify Order Id"));
        OrderTransactionDataTransfer.UpdateAuditFields := false;
        OrderTransactionDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(GetOrderTransactionShopCodeUpgradeTag());
    end;

    local procedure HasAdvancedShopifyPlanUpgrade()
    var
        Shop: Record "Shpfy Shop";
        UpgradeTag: Codeunit "Upgrade Tag";
        ShopDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(GetHasAdvancedShopifyPlanUpgradeTag()) then
            exit;

        ShopDataTransfer.SetTables(Database::"Shpfy Shop", Database::"Shpfy Shop");
        ShopDataTransfer.AddSourceFilter(Shop.FieldNo("B2B Enabled"), '=%1', true);
        ShopDataTransfer.AddConstantValue(true, Shop.FieldNo("Advanced Shopify Plan"));
        ShopDataTransfer.UpdateAuditFields := false;
        ShopDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(GetHasAdvancedShopifyPlanUpgradeTag());
    end;

    internal procedure GetAllowOutgoingRequestseUpgradeTag(): Code[250]
    begin
        exit('MS-445989-AllowOutgoingRequestseUpgradeTag-20220816');
    end;

    internal procedure GetNewAvailabilityCalculationTag(): Code[250]
    begin
        exit('MS-454264-NewAvailabilityCalculationTag-20221121');
    end;

    internal procedure GetAutoReleaseSalesOrderTag(): code[250]
    begin
        exit('MS-459849-AutoReleaseSalesOrderTag-20230106')
    end;

    internal procedure GetPriceCalculationUpgradeTag(): Code[250]
    begin
        exit('MS-460298-PriceCalculationUpgradeTag-20221201');
    end;

    local procedure GetLoggingModeUpgradeTag(): Code[250]
    begin
        exit('MS-447972-LoggingMode-20230425');
    end;

    internal procedure GetLocationUpgradeTag(): Code[250]
    begin
        exit('MS-472953-LocationUpgradeTag-20230525');
    end;

    internal procedure GetSyncPricesWithProductsUpgradeTag(): Code[250]
    begin
        exit('MS-480542-SyncPricesWithProductsUpgradeTag-20230814');
    end;

    local procedure GetSendShippingConfirmationUpgradeTag(): Code[250]
    begin
        exit('MS-495193-SendShippingConfirmationUpgradeTag-20231221');
    end;

    local procedure GetOrderAttributeValueUpgradeTag(): Code[250]
    begin
        exit('MS-497909-OrderAttributeValueUpgradeTag-20240125');
    end;

    local procedure GetCreditMemoCanBeCreatedUpgradeTag(): Code[250]
    begin
        exit('MS-471880-CreditMemoCanBeCreatedUpgradeTag-20240201');
    end;

    local procedure GetWebhookSubscriptionUpgradeTag(): Code[250]
    begin
        exit('MS-574620-WebHookSubscriptionUpgradeTag-20250419');
    end;

    local procedure GetArchiveProcessedOrdersUpgradeTag(): Code[250]
    begin
        exit('MS-593841-ArchiveProcessedOrdersUpgradeTag-20250731');
    end;

    local procedure GetShopifyCatalogsTypeUpgradeTag(): Code[250]
    begin
        exit('MS-581129-ShopifyCatalogsTypeUpgradeTag-20250807');
    end;

    local procedure GetCreateInvoicesFromOrdersUpgradeTag(): Code[250]
    begin
        exit('MS-604148-CreateInvoicesFromOrdersUpgradeTag-20250922');
    end;

    local procedure GetOrderTransactionShopCodeUpgradeTag(): Code[250]
    begin
        exit('MS-610671-OrderTransactionShopCodeUpgrade-20251022');
    end;

    local procedure GetHasAdvancedShopifyPlanUpgradeTag(): Code[250]
    begin
        exit('MS-630316-HasAdvancedShopifyPlanUpgrade-20260408');
    end;

    local procedure ItalianSardinianProvinceRenameUpgrade()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetItalianSardinianProvinceRenameUpgradeTag()) then
            exit;

        RenameItalianProvince('IT', 'Olbia-Tempio', 'Gallura Nord-Est Sardegna');
        RenameItalianProvince('IT', 'Carbonia-Iglesias', 'Sulcis Iglesiente');

        UpgradeTag.SetUpgradeTag(GetItalianSardinianProvinceRenameUpgradeTag());
    end;

    local procedure RenameItalianProvince(CountryRegionCode: Code[20]; OldName: Text[50]; NewName: Text[50])
    var
        OldShpfyTaxArea: Record "Shpfy Tax Area";
        NewShpfyTaxArea: Record "Shpfy Tax Area";
    begin
        if not OldShpfyTaxArea.Get(CountryRegionCode, OldName) then
            exit;

        // If the new name already exists (e.g. a tenant manually pre-seeded it before this
        // upgrade ran), leave both rows in place: the new row carries the user's intended
        // configuration, and the old row is harmless because Shopify no longer sends the
        // pre-2026-05-14 name -- no lookup will match it. Admins can clean up the stale row
        // from the Shopify Tax Areas page if desired. Auto-deleting would risk discarding
        // user-configured Tax Area Code / VAT Bus. Posting Group values on the old row.
        if NewShpfyTaxArea.Get(CountryRegionCode, NewName) then
            exit;

        OldShpfyTaxArea.Rename(CountryRegionCode, NewName);
    end;

    local procedure GetItalianSardinianProvinceRenameUpgradeTag(): Code[250]
    begin
        exit('MS-638035-ItalianSardinianProvinceRenameUpgrade-20260609');
    end;

    local procedure GetDateBeforeFeature(): DateTime
    begin
        exit(CreateDateTime(DMY2Date(1, 8, 2022), 0T));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetAllowOutgoingRequestseUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPriceCalculationUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewAvailabilityCalculationTag());
        PerCompanyUpgradeTags.Add(GetAutoReleaseSalesOrderTag());
        PerCompanyUpgradeTags.Add(GetLoggingModeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetLocationUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSyncPricesWithProductsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetArchiveProcessedOrdersUpgradeTag());
        PerCompanyUpgradeTags.Add(GetShopifyCatalogsTypeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCreateInvoicesFromOrdersUpgradeTag());
        PerCompanyUpgradeTags.Add(GetOrderTransactionShopCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetHasAdvancedShopifyPlanUpgradeTag());
        PerCompanyUpgradeTags.Add(GetItalianSardinianProvinceRenameUpgradeTag());
    end;
}

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Inventory.Item;

/// <summary>
/// Codeunit Shpfy Order Mapping (ID 30163).
/// </summary>
codeunit 30163 "Shpfy Order Mapping"
{
    Access = Internal;
    Permissions =
        tabledata Item = rim,
        tabledata "Item Variant" = rim;

    var
        OrderEvents: Codeunit "Shpfy Order Events";
        BillToCustomerIssueTok: Label 'BillToCustomer', Locked = true;
        GiftCardAccountIssueTok: Label 'GiftCardAccount', Locked = true;
        ItemLineIssuePrefixTok: Label 'ItemLine:', Locked = true;
        MappingErr: Label 'Not everything can be mapped.', Locked = true;
        SellToCustomerIssueTok: Label 'SellToCustomer', Locked = true;
        TipAccountIssueTok: Label 'TipAccount', Locked = true;

    /// <summary> 
    /// Description for DoMapping.
    /// </summary>
    /// <param name="OrderHeader">Parameter of type Record "Shopify Order Header".</param>
    internal procedure DoMapping(var OrderHeader: Record "Shpfy Order Header") Result: Boolean
    var
        MissingIssues: List of [Text];
    begin
        exit(DoMappingWithIssues(OrderHeader, MissingIssues, 'Mapping'));
    end;

    internal procedure DoMappingWithIssues(var OrderHeader: Record "Shpfy Order Header"; var MissingIssues: List of [Text]; ExecutionMode: Text[20]) Result: Boolean
    var
        CustomerTemplate: Record "Shpfy Customer Template";
        OrderLine: Record "Shpfy Order Line";
        Shop: Record "Shpfy Shop";
        LineMapped: Boolean;
    begin
        Clear(MissingIssues);
        Shop.Get(OrderHeader."Shop Code");

        if not OrderHeader.B2B then begin
            if CustomerTemplate.Get(OrderHeader."Shop Code", OrderHeader."Ship-to Country/Region Code") then begin
                if CustomerTemplate."Default Customer No." <> '' then begin
                    OrderHeader."Bill-to Customer No." := CustomerTemplate."Default Customer No.";
                    OrderHeader."Sell-to Customer No." := CustomerTemplate."Default Customer No.";
                    OrderHeader.Modify();
                end;
            end else
                if Shop."Customer Import From Shopify" = Shop."Customer Import From Shopify"::None then begin
                    if OrderHeader."Bill-to Customer No." = '' then
                        OrderHeader."Bill-to Customer No." := Shop."Default Customer No.";
                    if OrderHeader."Sell-to Customer No." = '' then
                        OrderHeader."Sell-to Customer No." := Shop."Default Customer No.";
                    OrderHeader.Modify();
                end
        end else
            if Shop."Company Import From Shopify" = Shop."Company Import From Shopify"::None then begin
                if OrderHeader."Bill-to Customer No." = '' then
                    OrderHeader."Bill-to Customer No." := Shop."Default Company No.";
                if OrderHeader."Sell-to Customer No." = '' then
                    OrderHeader."Sell-to Customer No." := Shop."Default Company No.";
                OrderHeader.Modify();
            end;

        if not OrderHeader.B2B then
            Result := MapHeaderFields(OrderHeader, Shop, Shop."Auto Create Unknown Customers" and (Shop."Customer Import From Shopify" <> "Shpfy Customer Import Range"::None))
        else
            Result := MapB2BHeaderFields(OrderHeader, Shop, Shop."Auto Create Unknown Companies" and (Shop."Company Import From Shopify" <> "Shpfy Company Import Range"::None));

        if OrderHeader."Sell-to Customer No." = '' then begin
            AddUniqueIssue(MissingIssues, SellToCustomerIssueTok);
            Result := false;
        end;
        if OrderHeader."Bill-to Customer No." = '' then begin
            AddUniqueIssue(MissingIssues, BillToCustomerIssueTok);
            Result := false;
        end;

        OrderLine.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
        OrderLine.SetLoadFields("Shopify Order Id", "Line Id", "Gift Card", Tip, "Shopify Variant Id", "Shopify Product Id", "Item No.", "Variant Code", "Unit of Measure Code");
        if OrderLine.FindSet(true) then
            repeat
                if OrderLine.Tip then begin
                    if Shop."Tip Account" = '' then begin
                        AddUniqueIssue(MissingIssues, TipAccountIssueTok);
                        Result := false;
                    end;
                end else
                    if OrderLine."Gift Card" then begin
                        if Shop."Sold Gift Card Account" = '' then begin
                            AddUniqueIssue(MissingIssues, GiftCardAccountIssueTok);
                            Result := false;
                        end;
                    end else begin
                        LineMapped := MapVariant(OrderLine, Shop);
                        if not LineMapped then begin
                            MissingIssues.Add(ItemLineIssuePrefixTok + Format(OrderLine."Line Id", 0, 9));
                            Result := false;
                        end;
                    end;
            until OrderLine.Next() = 0;

        OrderEvents.OnAfterMapShopifyOrder(OrderHeader, Result);
        LogMappingIssues(MissingIssues, ExecutionMode);
    end;

    local procedure LogMappingIssues(MissingIssues: List of [Text]; ExecutionMode: Text[20])
    var
        Categories: List of [Text];
        Category: Text;
        Dimensions: Dictionary of [Text, Text];
        Issue: Text;
        MappingTelemetryMsg: Label 'Shopify order mapping is incomplete.', Locked = true;
    begin
        foreach Issue in MissingIssues do begin
            if Issue.StartsWith(ItemLineIssuePrefixTok) then
                Category := 'Item'
            else
                Category := Issue;
            if not Categories.Contains(Category) then begin
                Categories.Add(Category);
                Clear(Dimensions);
                Dimensions.Add('Category', Category);
                Dimensions.Add('Mode', ExecutionMode);
                Session.LogMessage('SHPCOMPLETENESS', MappingTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
            end;
        end;
    end;

    internal procedure GetMappingErrorMessage(MissingIssues: List of [Text]): Text
    var
        BillToCustomerMissingErr: Label 'Bill-to Customer No. is missing.';
        ErrorBuilder: TextBuilder;
        GiftCardAccountMissingErr: Label 'Sold Gift Card Account must have a value in Shopify Shop.';
        ItemLineId: Text;
        ItemLineMissingErr: Label 'Item No. is missing on Shopify order line %1.', Comment = '%1 = Shopify order line ID';
        MissingIssue: Text;
        SellToCustomerMissingErr: Label 'Sell-to Customer No. is missing.';
        TipAccountMissingErr: Label 'Tip Account must have a value in Shopify Shop.';
    begin
        ErrorBuilder.AppendLine(MappingErr);
        foreach MissingIssue in MissingIssues do
            if MissingIssue.StartsWith(ItemLineIssuePrefixTok) then begin
                ItemLineId := CopyStr(MissingIssue, StrLen(ItemLineIssuePrefixTok) + 1);
                ErrorBuilder.AppendLine(StrSubstNo(ItemLineMissingErr, ItemLineId));
            end else
                case MissingIssue of
                    SellToCustomerIssueTok:
                        ErrorBuilder.AppendLine(SellToCustomerMissingErr);
                    BillToCustomerIssueTok:
                        ErrorBuilder.AppendLine(BillToCustomerMissingErr);
                    TipAccountIssueTok:
                        ErrorBuilder.AppendLine(TipAccountMissingErr);
                    GiftCardAccountIssueTok:
                        ErrorBuilder.AppendLine(GiftCardAccountMissingErr);
                end;

        exit(ErrorBuilder.ToText());
    end;

    internal procedure PersistMappingError(var OrderHeader: Record "Shpfy Order Header"; MissingIssues: List of [Text])
    begin
        if OrderHeader."Has Error" and not IsMappingError(OrderHeader."Error Message") then
            exit;

        SetMappingError(OrderHeader, MissingIssues);
    end;

    internal procedure PersistMappingErrorMessage(var OrderHeader: Record "Shpfy Order Header"; ErrorMessage: Text)
    begin
        if OrderHeader."Has Error" and not IsMappingError(OrderHeader."Error Message") then
            exit;

        OrderHeader."Has Error" := true;
        OrderHeader."Error Message" := CopyStr(Format(Time) + ' ' + ErrorMessage, 1, MaxStrLen(OrderHeader."Error Message"));
        OrderHeader.Modify();
    end;

    internal procedure SetMappingError(var OrderHeader: Record "Shpfy Order Header"; MissingIssues: List of [Text])
    var
        ErrorMessage: Text;
    begin
        ErrorMessage := Format(Time) + ' ' + GetMappingErrorMessage(MissingIssues);
        OrderHeader."Has Error" := true;
        OrderHeader."Error Message" := CopyStr(ErrorMessage, 1, MaxStrLen(OrderHeader."Error Message"));
        OrderHeader.Modify();
    end;

    internal procedure ClearMappingError(var OrderHeader: Record "Shpfy Order Header")
    begin
        if not IsMappingError(OrderHeader."Error Message") then
            exit;

        OrderHeader."Has Error" := false;
        OrderHeader."Error Message" := '';
        OrderHeader.Modify();
    end;

    internal procedure IsMappingError(ErrorMessage: Text): Boolean
    var
        ErrorTime: Time;
        MappingErrorPosition: Integer;
        TimestampText: Text;
    begin
        if ErrorMessage.StartsWith(MappingErr) then
            exit(true);

        MappingErrorPosition := StrPos(ErrorMessage, MappingErr);
        if MappingErrorPosition <= 2 then
            exit(false);
        if CopyStr(ErrorMessage, MappingErrorPosition - 1, 1) <> ' ' then
            exit(false);

        TimestampText := CopyStr(ErrorMessage, 1, MappingErrorPosition - 2);
        exit(Evaluate(ErrorTime, TimestampText));
    end;

    local procedure AddUniqueIssue(var MissingIssues: List of [Text]; Issue: Text)
    begin
        if not MissingIssues.Contains(Issue) then
            MissingIssues.Add(Issue);
    end;

    /// <summary> 
    /// Description for MapHeaderFields.
    /// </summary>
    /// <param name="OrderHeader">Parameter of type Record "Shopify Order Header".</param>
    /// <param name="Shop">Parameter of type Record "Shopify Shop".</param>
    /// <param name="AllowCreateCustomer">Parameter of type Boolean.</param>
    /// <returns>Return variable "Boolean".</returns>
    internal procedure MapHeaderFields(var OrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"; AllowCreateCustomer: Boolean): Boolean
    var
        CustomerMapping: Codeunit "Shpfy Customer Mapping";
        CustomerTemplateCode: Code[20];
        IsHandled: Boolean;
        JCustomer: JsonObject;
    begin
        CustomerTemplateCode := OrderHeader."Customer Templ. Code";
        CustomerMapping.SetShop(OrderHeader."Shop Code");
        if OrderHeader."Bill-to Customer No." = '' then begin
            OrderEvents.OnBeforeMapCustomer(OrderHeader, IsHandled);
            if not IsHandled then begin
                if OrderHeader."Sell-to Customer No." = '' then begin
                    JCustomer.Add('Name', OrderHeader."Sell-to Customer Name");
                    JCustomer.Add('Name2', OrderHeader."Sell-to Customer Name 2");
                    JCustomer.Add('Address', OrderHeader."Sell-to Address");
                    JCustomer.Add('Address2', OrderHeader."Sell-to Address 2");
                    JCustomer.Add('PostCode', OrderHeader."Sell-to Post Code");
                    JCustomer.Add('City', OrderHeader."Sell-to City");
                    JCustomer.Add('County', OrderHeader."Sell-to County");
                    JCustomer.Add('CountryCode', OrderHeader."Sell-to Country/Region Code");
                    OrderHeader."Sell-to Customer No." := CustomerMapping.DoMapping(OrderHeader."Customer Id", JCustomer, OrderHeader."Shop Code", CustomerTemplateCode, AllowCreateCustomer);
                end;

                Clear(JCustomer);
                JCustomer.Add('Name', OrderHeader."Bill-to Name");
                JCustomer.Add('Name2', OrderHeader."Bill-to Name 2");
                JCustomer.Add('Address', OrderHeader."Bill-to Address");
                JCustomer.Add('Address2', OrderHeader."Bill-to Address 2");
                JCustomer.Add('PostCode', OrderHeader."Bill-to Post Code");
                JCustomer.Add('City', OrderHeader."Bill-to City");
                JCustomer.Add('County', OrderHeader."Bill-to County");
                JCustomer.Add('CountryCode', OrderHeader."Bill-to Country/Region Code");
                OrderHeader."Bill-to Customer No." := CustomerMapping.DoMapping(OrderHeader."Customer Id", JCustomer, OrderHeader."Shop Code", CustomerTemplateCode, AllowCreateCustomer);
                if (OrderHeader."Bill-to Customer No." = '') and (Shop."Default Customer No." <> '') then
                    OrderHeader."Bill-to Customer No." := Shop."Default Customer No.";

                if OrderHeader."Sell-to Customer No." = '' then
                    OrderHeader."Sell-to Customer No." := OrderHeader."Bill-to Customer No.";
                if OrderHeader."Bill-to Customer No." = '' then
                    OrderHeader."Bill-to Customer No." := OrderHeader."Sell-to Customer No.";

                if OrderHeader."Bill-to Customer No." <> Shop."Default Customer No." then
                    OrderHeader."Bill-to Contact No." := FindContactNo(OrderHeader."Bill-to Contact Name", OrderHeader."Bill-to Customer No.");
                if OrderHeader."Sell-to Customer No." <> Shop."Default Customer No." then
                    OrderHeader."Sell-to Contact No." := FindContactNo(OrderHeader."Sell-to Contact Name", OrderHeader."Sell-to Customer No.");
                OrderHeader."Ship-to Contact No." := FindContactNo(OrderHeader."Ship-to Contact Name", OrderHeader."Sell-to Customer No.");

                OrderEvents.OnAfterMapCustomer(OrderHeader);
            end;
        end;

        MapShippingMethodCode(OrderHeader);
        MapShippingAgent(OrderHeader);
        MapPaymentMethodCode(OrderHeader);
        MapTaxArea(OrderHeader);
        OrderHeader.Modify();
        exit((OrderHeader."Bill-to Customer No." <> '') and (OrderHeader."Sell-to Customer No." <> ''));
    end;

    internal procedure MapB2BHeaderFields(var OrderHeader: Record "Shpfy Order Header"; Shop: Record "Shpfy Shop"; AllowCreateCompany: Boolean): Boolean
    var
        CompanyMapping: Codeunit "Shpfy Company Mapping";
        CustomerTemplateCode: Code[20];
        IsHandled: Boolean;
        MappedFromLocation: Boolean;
    begin
        CustomerTemplateCode := OrderHeader."Customer Templ. Code";

        CompanyMapping.SetShop(OrderHeader."Shop Code");
        if OrderHeader."Bill-to Customer No." = '' then begin
            OrderEvents.OnBeforeMapCompany(OrderHeader, IsHandled);
            if not IsHandled then begin
                if OrderHeader."Company Location Id" <> 0 then
                    MappedFromLocation := MapSellToBillToCustomersFromCompanyLocation(OrderHeader);

                if not MappedFromLocation then begin
                    OrderHeader."Sell-to Customer No." := CompanyMapping.DoMapping(OrderHeader."Company Id", CustomerTemplateCode, AllowCreateCompany);
                    OrderHeader."Bill-to Customer No." := OrderHeader."Sell-to Customer No.";
                end;

                if (OrderHeader."Bill-to Customer No." = '') and (Shop."Default Company No." <> '') then
                    OrderHeader."Bill-to Customer No." := Shop."Default Company No.";
                if OrderHeader."Sell-to Customer No." = '' then
                    OrderHeader."Sell-to Customer No." := OrderHeader."Bill-to Customer No.";

                if OrderHeader."Bill-to Customer No." <> Shop."Default Company No." then
                    OrderHeader."Bill-to Contact No." := FindContactNo(OrderHeader."Bill-to Contact Name", OrderHeader."Bill-to Customer No.");
                if OrderHeader."Sell-to Customer No." <> Shop."Default Company No." then
                    OrderHeader."Sell-to Contact No." := FindContactNo(OrderHeader."Sell-to Contact Name", OrderHeader."Sell-to Customer No.");

                OrderHeader."Ship-to Contact No." := FindContactNo(OrderHeader."Ship-to Contact Name", OrderHeader."Sell-to Customer No.");
                OrderEvents.OnAfterMapCompany(OrderHeader);
            end;
        end;

        MapShippingMethodCode(OrderHeader);
        MapShippingAgent(OrderHeader);
        MapPaymentMethodCode(OrderHeader);
        MapLocationCode(OrderHeader);
        MapTaxArea(OrderHeader);
        OrderHeader.Modify();
        exit((OrderHeader."Bill-to Customer No." <> '') and (OrderHeader."Sell-to Customer No." <> ''));
    end;

    /// <summary>
    /// Description for MapVariant.
    /// </summary>
    /// <param name="ShopifyOrderLine">Parameter of type Record "Shopify Order Line".</param>
    /// <param name="SHop">Parameter of type Record "Shopify Shop".</param>
    /// <returns>Return variable "Boolean".</returns>
    local procedure MapVariant(var ShopifyOrderLine: Record "Shpfy Order Line"; SHop: Record "Shpfy Shop"): Boolean
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyVariant: Record "Shpfy Variant";
        ProductImport: Codeunit "Shpfy Product Import";
    begin
        if not ShopifyVariant.Get(ShopifyOrderLine."Shopify Variant Id") or IsNullGuid(ShopifyVariant."Item SystemId") then begin
            ProductImport.SetShop(Shop);
            ProductImport.SetProduct(ShopifyOrderLine."Shopify Product Id");
            ProductImport.Run();
        end;

        if ShopifyVariant.Get(ShopifyOrderLine."Shopify Variant Id") then begin
            if (not IsNullGuid(ShopifyVariant."Item SystemId")) and Item.GetBySystemId(ShopifyVariant."Item SystemId") then
                ShopifyOrderLine."Item No." := Item."No.";
            if (not IsNullGuid(ShopifyVariant."Item Variant SystemId")) and ItemVariant.GetBySystemId(ShopifyVariant."Item Variant SystemId") then
                ShopifyOrderLine."Variant Code" := ItemVariant.Code;
            case ShopifyVariant."UoM Option Id" of
                1:
                    if StrLen(ShopifyVariant."Option 1 Value") <= MaxStrLen(ShopifyOrderLine."Unit of Measure Code") then
                        ShopifyOrderLine."Unit of Measure Code" := CopyStr(ShopifyVariant."Option 1 Value", 1, MaxStrLen(ShopifyOrderLine."Unit of Measure Code"));
                2:
                    if StrLen(ShopifyVariant."Option 2 Value") <= MaxStrLen(ShopifyOrderLine."Unit of Measure Code") then
                        ShopifyOrderLine."Unit of Measure Code" := CopyStr(ShopifyVariant."Option 2 Value", 1, MaxStrLen(ShopifyOrderLine."Unit of Measure Code"));
                3:
                    if StrLen(ShopifyVariant."Option 3 Value") <= MaxStrLen(ShopifyOrderLine."Unit of Measure Code") then
                        ShopifyOrderLine."Unit of Measure Code" := CopyStr(ShopifyVariant."Option 3 Value", 1, MaxStrLen(ShopifyOrderLine."Unit of Measure Code"));
            end;
        end;
        if (ShopifyOrderLine."Unit of Measure Code" = '') and (ShopifyOrderLine."Item No." <> '') then
            if Item.Get(ShopifyOrderLine."Item No.") then
                ShopifyOrderLine."Unit of Measure Code" := Item."Sales Unit of Measure";
        ShopifyOrderLine.Modify();
        exit(ShopifyOrderLine."Item No." <> '');
    end;

    internal procedure FindContactNo(ContactName: Text[100]; CustomerNo: Code[20]): Code[20]
    var
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        if ContactName = '' then
            exit('');
        ContactBusinessRelation.SetRange("Link to Table", "Contact Business Relation Link To Table"::Customer);
        ContactBusinessRelation.SetRange("No.", CustomerNo);
        if ContactBusinessRelation.FindFirst() then begin
            Contact.SetRange(Type, "contact Type"::Person);
            Contact.SetRange("Company No.", ContactBusinessRelation."Contact No.");
            Contact.SetFilter(Name, '''@' + ContactName.Replace('''', '''''') + '''');
            if Contact.FindFirst() then
                exit(Contact."No.");
        end;
    end;

    local procedure MapShippingMethodCode(var OrderHeader: Record "Shpfy Order Header")
    var
        OrderShippingCharges: Record "Shpfy Order Shipping Charges";
        ShipmentMethodMapping: Record "Shpfy Shipment Method Mapping";
        IsHandled: Boolean;
    begin
        if OrderHeader."Shipping Method Code" = '' then begin
            OrderEvents.OnBeforeMapShipmentMethod(OrderHeader, IsHandled);
            if not IsHandled then begin
                OrderShippingCharges.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
                if OrderShippingCharges.FindFirst() then
                    if ShipmentMethodMapping.Get(OrderHeader."Shop Code", OrderShippingCharges.Title) then
                        OrderHeader."Shipping Method Code" := ShipmentMethodMapping."Shipment Method Code";
                OrderEvents.OnAfterMapShipmentMethod(OrderHeader);
            end;
        end;
    end;

    local procedure MapShippingAgent(var OrderHeader: Record "Shpfy Order Header")
    var
        OrderShippingCharges: Record "Shpfy Order Shipping Charges";
        ShipmentMethodMapping: Record "Shpfy Shipment Method Mapping";
        IsHandled: Boolean;
    begin
        if OrderHeader."Shipping Agent Code" = '' then begin
            OrderEvents.OnBeforeMapShipmentAgent(OrderHeader, IsHandled);
            if not IsHandled then begin
                OrderShippingCharges.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
                if OrderShippingCharges.FindFirst() then
                    if ShipmentMethodMapping.Get(OrderHeader."Shop Code", OrderShippingCharges.Title) then begin
                        OrderHeader."Shipping Agent Code" := ShipmentMethodMapping."Shipping Agent Code";
                        OrderHeader."Shipping Agent Service Code" := ShipmentMethodMapping."Shipping Agent Service Code";
                    end;
                OrderEvents.OnAfterMapShipmentAgent(OrderHeader);
            end;
        end;
    end;

    local procedure MapPaymentMethodCode(var OrderHeader: Record "Shpfy Order Header")
    var
        OrderTransaction: Record "Shpfy Order Transaction";
        IsHandled: Boolean;
        PaymentMethods: List of [Code[10]];
    begin
        if OrderHeader."Payment Method Code" = '' then begin
            OrderEvents.OnBeforeMapPaymentMethod(OrderHeader, IsHandled);
            if not IsHandled then begin
                OrderTransaction.SetAutoCalcFields("Payment Method");
                OrderTransaction.SetRange("Shopify Order Id", OrderHeader."Shopify Order Id");
                OrderTransaction.SetRange(Status, "Shpfy Transaction Status"::Success);
                OrderTransaction.SetFilter(Type, '%1|%2|%3', "Shpfy Transaction Type"::Sale, "Shpfy Transaction Type"::Capture, "Shpfy Transaction Type"::Authorization);
                if OrderTransaction.FindSet() then begin
                    repeat
                        if not PaymentMethods.Contains(OrderTransaction."Payment Method") then
                            PaymentMethods.Add(OrderTransaction."Payment Method");

                        if PaymentMethods.Count > 1 then begin
                            OrderEvents.OnAfterMapPaymentMethod(OrderHeader);
                            exit;
                        end;
                    until OrderTransaction.Next() = 0;
                    OrderHeader."Payment Method Code" := PaymentMethods.Get(1);
                end;
            end;
            OrderEvents.OnAfterMapPaymentMethod(OrderHeader);
        end;
    end;

    local procedure MapLocationCode(OrderHeader: Record "Shpfy Order Header")
    var
        ShopifyCompany: Record "Shpfy Company";
        CompanyLocation: Record "Shpfy Company Location";
        CompanyAPI: Codeunit "Shpfy Company API";
    begin
        if OrderHeader."Company Location Id" = 0 then
            exit;

        if not ShopifyCompany.Get(OrderHeader."Company Id") then
            exit;

        CompanyLocation.ReadIsolation := IsolationLevel::ReadUncommitted;
        CompanyLocation.SetRange(Id, OrderHeader."Company Location Id");
        if not CompanyLocation.IsEmpty() then
            exit;

        CompanyAPI.SetShop(OrderHeader."Shop Code");
        CompanyAPI.UpdateShopifyCompanyLocation(ShopifyCompany, OrderHeader."Company Location Id");
    end;

    local procedure MapSellToBillToCustomersFromCompanyLocation(var OrderHeader: Record "Shpfy Order Header"): Boolean
    var
        Company: Record "Shpfy Company";
        CompanyLocation: Record "Shpfy Company Location";
    begin
        if not Company.Get(OrderHeader."Company Id") then
            exit(false);

        Company.CalcFields("Customer No.");

        if not CompanyLocation.Get(OrderHeader."Company Location Id") then
            exit(false);

        if (Company."Customer No." <> '') and (CompanyLocation."Sell-to Customer No." = '') and (CompanyLocation."Bill-to Customer No." = '') then begin
            OrderHeader."Sell-to Customer No." := Company."Customer No.";
            OrderHeader."Bill-to Customer No." := Company."Customer No.";
        end;
        if (Company."Customer No." <> '') and (CompanyLocation."Sell-to Customer No." <> '') and (CompanyLocation."Bill-to Customer No." = '') then begin
            OrderHeader."Sell-to Customer No." := CompanyLocation."Sell-to Customer No.";
            OrderHeader."Bill-to Customer No." := CompanyLocation."Sell-to Customer No.";
        end;
        if (Company."Customer No." <> '') and (CompanyLocation."Sell-to Customer No." <> '') and (CompanyLocation."Bill-to Customer No." <> '') then begin
            OrderHeader."Sell-to Customer No." := CompanyLocation."Sell-to Customer No.";
            OrderHeader."Bill-to Customer No." := CompanyLocation."Bill-to Customer No.";
        end;

        exit((OrderHeader."Bill-to Customer No." <> '') and (OrderHeader."Sell-to Customer No." <> ''));
    end;

    local procedure MapTaxArea(var OrderHeader: Record "Shpfy Order Header")
    var
        ShopifyTaxArea: Record "Shpfy Tax Area";
        OrderMgt: Codeunit "Shpfy Order Mgt.";
    begin
        if OrderHeader."Tax Area Code" <> '' then
            exit;

        if OrderMgt.FindTaxArea(OrderHeader, ShopifyTaxArea) and (ShopifyTaxArea."Tax Area Code" <> '') then begin
            OrderHeader."Tax Area Code" := ShopifyTaxArea."Tax Area Code";
            if not OrderHeader."Tax Exempt" then
                OrderHeader."Tax Liable" := ShopifyTaxArea."Tax Liable";
        end;
    end;
}

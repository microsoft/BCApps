// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy Discover Payment Methods (ID 30432).
/// </summary>
codeunit 30432 "Shpfy Discover Payment Methods"
{
    var
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        JsonHelper: Codeunit "Shpfy Json Helper";
        InsertFailedErr: Label 'A payment method discovery value could not be inserted.';

    internal procedure Discover(ShopCode: Code[20]; var HasOrders: Boolean; var CreatedMappingCount: Integer)
    var
        JOrders: JsonArray;
        JTransactions: JsonArray;
        JOrder: JsonToken;
        JResponse: JsonToken;
        JTransaction: JsonToken;
        ManualPaymentGatewayValues: List of [Boolean];
        TransactionCount: Integer;
        CreditCardCompanyKeys: List of [Text];
        CreditCardCompanyLookupNames: List of [Text];
        GatewayKeys: List of [Text];
        ResponseShapeErr: Label 'The response from Shopify is missing payment method discovery data.';
    begin
        CommunicationMgt.SetShop(ShopCode);
        JResponse := CommunicationMgt.ExecuteGraphQL(Enum::"Shpfy GraphQL Type"::Payments_GetRecentOrderTransactions);

        if not JsonHelper.GetJsonArray(JResponse, JOrders, 'data.orders.nodes') then
            Error(ResponseShapeErr);
        HasOrders := JOrders.Count() > 0;

        foreach JOrder in JOrders do begin
            if not JsonHelper.GetJsonArray(JOrder, JTransactions, 'transactions') then
                Error(ResponseShapeErr);

            TransactionCount := 0;
            foreach JTransaction in JTransactions do
                if TransactionCount < 5 then begin
                    TransactionCount += 1;
                    StageTransaction(JTransaction, GatewayKeys, CreditCardCompanyKeys, ManualPaymentGatewayValues, CreditCardCompanyLookupNames);
                end;
        end;

        CreateMissingLookups(GatewayKeys, CreditCardCompanyLookupNames);
        CreateMissingMappings(ShopCode, GatewayKeys, CreditCardCompanyKeys, ManualPaymentGatewayValues, CreatedMappingCount);
    end;

    local procedure StageTransaction(JTransaction: JsonToken; var GatewayKeys: List of [Text]; var CreditCardCompanyKeys: List of [Text]; var ManualPaymentGatewayValues: List of [Boolean]; var CreditCardCompanyLookupNames: List of [Text])
    var
        Index: Integer;
        CreditCardCompany: Text;
        CreditCardCompanyKey: Text[30];
        CreditCardCompanyLookupName: Text[50];
        Gateway: Text[30];
    begin
        Gateway := CopyStr(JsonHelper.GetValueAsText(JTransaction, 'gateway'), 1, MaxStrLen(Gateway));
        if Gateway = '' then
            exit;

        CreditCardCompany := JsonHelper.GetValueAsText(JTransaction, 'paymentDetails.company');
        CreditCardCompanyKey := CopyStr(CreditCardCompany, 1, MaxStrLen(CreditCardCompanyKey));
        CreditCardCompanyLookupName := CopyStr(CreditCardCompany, 1, MaxStrLen(CreditCardCompanyLookupName));

        if CreditCardCompanyLookupName <> '' then
            AddUniqueCreditCardCompany(CreditCardCompanyLookupName, CreditCardCompanyLookupNames);

        for Index := 1 to GatewayKeys.Count() do
            if (GatewayKeys.Get(Index) = Gateway) and (CreditCardCompanyKeys.Get(Index) = CreditCardCompanyKey) then
                exit;

        GatewayKeys.Add(Gateway);
        CreditCardCompanyKeys.Add(CreditCardCompanyKey);
        ManualPaymentGatewayValues.Add(JsonHelper.GetValueAsBoolean(JTransaction, 'manualPaymentGateway'));
    end;

    local procedure AddUniqueCreditCardCompany(CreditCardCompanyName: Text; var CreditCardCompanyLookupNames: List of [Text])
    var
        ExistingName: Text;
    begin
        foreach ExistingName in CreditCardCompanyLookupNames do
            if ExistingName = CreditCardCompanyName then
                exit;
        CreditCardCompanyLookupNames.Add(CreditCardCompanyName);
    end;

    local procedure CreateMissingLookups(GatewayKeys: List of [Text]; CreditCardCompanyLookupNames: List of [Text])
    var
        CreditCardCompany: Record "Shpfy Credit Card Company";
        TransactionGateway: Record "Shpfy Transaction Gateway";
        CreditCardCompanyName: Text;
        Gateway: Text;
    begin
        foreach Gateway in GatewayKeys do
            if not TransactionGateway.Get(Gateway) then begin
                TransactionGateway.Init();
                TransactionGateway.Name := CopyStr(Gateway, 1, MaxStrLen(TransactionGateway.Name));
                if not TransactionGateway.Insert(false) then
                    if not TransactionGateway.Get(TransactionGateway.Name) then
                        Error(InsertFailedErr);
            end;

        foreach CreditCardCompanyName in CreditCardCompanyLookupNames do
            if not CreditCardCompany.Get(CreditCardCompanyName) then begin
                CreditCardCompany.Init();
                CreditCardCompany.Name := CopyStr(CreditCardCompanyName, 1, MaxStrLen(CreditCardCompany.Name));
                if not CreditCardCompany.Insert(false) then
                    if not CreditCardCompany.Get(CreditCardCompany.Name) then
                        Error(InsertFailedErr);
            end;
    end;

    local procedure CreateMissingMappings(ShopCode: Code[20]; GatewayKeys: List of [Text]; CreditCardCompanyKeys: List of [Text]; ManualPaymentGatewayValues: List of [Boolean]; var CreatedMappingCount: Integer)
    var
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
        Index: Integer;
    begin
        CreatedMappingCount := 0;
        for Index := 1 to GatewayKeys.Count() do
            if not PaymentMethodMapping.Get(ShopCode, GatewayKeys.Get(Index), CreditCardCompanyKeys.Get(Index)) then begin
                PaymentMethodMapping.Init();
                PaymentMethodMapping."Shop Code" := ShopCode;
                PaymentMethodMapping.Gateway := CopyStr(GatewayKeys.Get(Index), 1, MaxStrLen(PaymentMethodMapping.Gateway));
                PaymentMethodMapping."Credit Card Company" := CopyStr(CreditCardCompanyKeys.Get(Index), 1, MaxStrLen(PaymentMethodMapping."Credit Card Company"));
                PaymentMethodMapping."Manual Payment Gateway" := ManualPaymentGatewayValues.Get(Index);
                if not PaymentMethodMapping.Insert(false) then begin
                    if not PaymentMethodMapping.Get(ShopCode, PaymentMethodMapping.Gateway, PaymentMethodMapping."Credit Card Company") then
                        Error(InsertFailedErr);
                end else
                    CreatedMappingCount += 1;
            end;
    end;
}
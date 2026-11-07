// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy Payment Method Mapping Mgt. (ID 30431).
/// </summary>
codeunit 30431 "Shpfy Pay. Method Mapp. Mgt."
{
    Access = Internal;

    internal procedure FindMapping(ShopCode: Code[20]; Gateway: Text; CreditCardCompany: Text; var PaymentMethodMapping: Record "Shpfy Payment Method Mapping"): Boolean
    var
        CreditCardCompanyKey: Text[30];
        GatewayKey: Text[30];
    begin
        GatewayKey := CopyStr(Gateway, 1, MaxStrLen(GatewayKey));
        CreditCardCompanyKey := CopyStr(CreditCardCompany, 1, MaxStrLen(CreditCardCompanyKey));

        PaymentMethodMapping.Reset();
        PaymentMethodMapping.SetRange("Shop Code", ShopCode);
        PaymentMethodMapping.SetRange(Gateway, GatewayKey);
        PaymentMethodMapping.SetRange("Credit Card Company", CreditCardCompanyKey);
        exit(PaymentMethodMapping.FindFirst());
    end;

    internal procedure GetPaymentMethodCode(ShopCode: Code[20]; Gateway: Text; CreditCardCompany: Text): Code[10]
    var
        PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
    begin
        if FindMapping(ShopCode, Gateway, CreditCardCompany, PaymentMethodMapping) then
            exit(PaymentMethodMapping."Payment Method Code");
    end;
}
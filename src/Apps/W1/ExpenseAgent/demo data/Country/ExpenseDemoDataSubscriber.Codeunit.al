// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;

codeunit 8299 "Expense Demo Data Subscriber"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Contoso Expense Agent", OnBeforeValidateCurrencyCodeInExpense, '', false, false)]
    local procedure OnBeforeValidateCurrencyCodeInExpense(var CurrencyCode: Code[10])
    var
        CreateCurrency: Codeunit "Create Currency";
    begin
        case CountryCode of
            'AT', 'BE', 'DE', 'ES', 'FI', 'FR', 'IT', 'NL':
                if CurrencyCode = CreateCurrency.EUR() then
                    CurrencyCode := CreateCurrency.USD();
            'DK':
                if CurrencyCode = CreateCurrency.DKK() then
                    CurrencyCode := '';
        end;
    end;

    procedure SetCountryCode(NewCountryCode: Code[10])
    begin
        CountryCode := NewCountryCode;
    end;

    var
        CountryCode: Code[10];
}
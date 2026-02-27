// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Page Shpfy Filter Transactions (ID 30176).
/// </summary>
page 30176 "Shpfy Filter Transactions"
{
    Caption = 'Filter Postable Transactions';
    PageType = StandardDialog;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Gateway; Gateway)
            {
                Caption = 'Gateway';
                ToolTip = 'Specifies the transaction gateway to filter transactions by. Leave blank to include all gateways.';
                Editable = false;

                trigger OnAssistEdit()
                var
                    PaymentMethodMapping: Record "Shpfy Payment Method Mapping";
                begin
                    PaymentMethodMapping.SetRange("Post Automatically", true);
                    if Page.RunModal(0, PaymentMethodMapping) = Action::LookupOK then begin
                        ShopCode := PaymentMethodMapping."Shop Code";
                        Gateway := PaymentMethodMapping.Gateway;
                        CreditCardCompany := PaymentMethodMapping."Credit Card Company";
                    end;
                end;
            }
            field(StartDate; StartDate)
            {
                Caption = 'Start Date';
                ToolTip = 'Specifies the earliest transaction creation date to include in the filter. Leave blank to include all transactions from the beginning.';
            }
            field(EndDate; EndDate)
            {
                Caption = 'End Date';
                ToolTip = 'Specifies the latest transaction creation date to include in the filter. Leave blank to include all transactions.';
            }
        }
    }

    var
        ShopCode: Code[20];
        Gateway: Text[30];
        CreditCardCompany: Text[50];
        StartDate: Date;
        EndDate: Date;

    internal procedure GetParameters(var NewShopCode: Code[20]; var NewGateway: Text[30]; var NewCreditCardCompany: Text[50]; var NewStartDate: DateTime; var NewEndDate: DateTime)
    begin
        NewShopCode := ShopCode;
        NewGateway := Gateway;
        NewCreditCardCompany := CreditCardCompany;
        NewStartDate := CreateDateTime(StartDate, 0T);
        NewEndDate := CreateDateTime(EndDate, 0T);
    end;
}
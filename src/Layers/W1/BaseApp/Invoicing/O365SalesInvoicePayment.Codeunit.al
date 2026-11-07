// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
codeunit 2105 "O365 Sales Invoice Payment"
{
    trigger OnRun()
    begin
    end;

    procedure CollectRemainingPayments(SalesInvoiceDocumentNo: Code[20]; var PaymentRegistrationBuffer: Record "Payment Registration Buffer"): Boolean
    begin
        PaymentRegistrationBuffer.PopulateTable();
        PaymentRegistrationBuffer.SetRange("Document Type", PaymentRegistrationBuffer."Document Type"::Invoice);
        PaymentRegistrationBuffer.SetRange("Document No.", SalesInvoiceDocumentNo);
        exit(PaymentRegistrationBuffer.FindFirst());
    end;

    procedure UpdatePaymentServicesForInvoicesQuotesAndOrders()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetFilter("Document Type", '%1|%2|%3', SalesHeader."Document Type"::Invoice,
          SalesHeader."Document Type"::Quote, SalesHeader."Document Type"::Order);

        if SalesHeader.FindSet(true) then
            repeat
                SalesHeader.SetDefaultPaymentServices();
                SalesHeader.Modify(true);
            until SalesHeader.Next() = 0;
    end;
}

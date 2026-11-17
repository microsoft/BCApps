// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.Purchases;

using Microsoft.DemoData.Foundation;
using Microsoft.Purchases.Document;
using System.Environment.Configuration;

codeunit 13435 "Create Purchase Order FI"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        UpdateInvoiceMessage();
    end;

    procedure UpdateInvoiceMessage()
    var
        PurchHeader: Record "Purchase Header";
        CreateVendor: Codeunit "Create Vendor";
        CreatePaymentTerms: Codeunit "Create Payment Terms";
#if not CLEAN30
        FeatureManagementFacade: Codeunit "Feature Management Facade";
#endif
    begin
        if PurchHeader.FindSet() then
            repeat
#if not CLEAN30
                if not FeatureManagementFacade.IsEnabled('BankingAndPaymentsFI') then begin
#pragma warning disable AL0432
                    PurchHeader.Validate("Message Type", PurchHeader."Message Type"::Message);
                    PurchHeader.Validate("Invoice Message", PurchHeader."No.");
#pragma warning restore AL0432
                end else
#endif
                begin
                    PurchHeader.Validate("Bank Message Type", PurchHeader."Bank Message Type"::Message);
                    PurchHeader.Validate("Payment Message", PurchHeader."No.");
                end;

                if PurchHeader."Buy-from Vendor No." = CreateVendor.DomesticFirstUp() then
                    PurchHeader.Validate("Payment Terms Code", CreatePaymentTerms.PaymentTermsDAYS30());

                PurchHeader.Modify(true);
            until PurchHeader.Next() = 0;
    end;
}

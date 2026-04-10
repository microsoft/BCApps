// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Purchases.History;

page 9971 "Posted Purchase Invoice API"
{
    APIVersion = 'v1.0';
    APIGroup = 'automate';
    APIPublisher = 'microsoft';
    EntityCaption = 'Posted Purchase Invoice';
    EntitySetCaption = 'Posted Purchase Invoices';
    ChangeTrackingAllowed = true;
    EntityName = 'postedPurchaseInvoice';
    EntitySetName = 'postedPurchaseInvoices';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "Purch. Inv. Header";
    Extensible = false;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataAccessIntent = ReadOnly;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                }
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(apiId; APIId)
                {
                    Caption = 'API Id';
                }
                field(invoiceDate; Rec."Document Date")
                {
                    Caption = 'Invoice Date';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field(dueDate; Rec."Due Date")
                {
                    Caption = 'Due Date';
                }
                field(vendorInvoiceNumber; Rec."Vendor Invoice No.")
                {
                    Caption = 'Vendor Invoice No.';
                }
                field(customerPurchaseOrderReference; Rec."Your Reference")
                {
                    Caption = 'Customer Purchase Order Reference';
                }
                field(vendorNumber; Rec."Buy-from Vendor No.")
                {
                    Caption = 'Vendor No.';
                }
                field(vendorName; Rec."Buy-from Vendor Name")
                {
                    Caption = 'Vendor Name';
                }
                field(payToName; Rec."Pay-to Name")
                {
                    Caption = 'Pay-To Name';
                }
                field(payToContact; Rec."Pay-to Contact")
                {
                    Caption = 'Pay-To Contact';
                }
                field(payToVendorNumber; Rec."Pay-to Vendor No.")
                {
                    Caption = 'Pay-To Vendor No.';
                }
                field(shipToName; Rec."Ship-to Name")
                {
                    Caption = 'Ship-To Name';
                }
                field(shipToContact; Rec."Ship-to Contact")
                {
                    Caption = 'Ship-To Contact';
                }
                field(buyFromAddressLine1; Rec."Buy-from Address")
                {
                    Caption = 'Buy-from Address Line 1';
                }
                field(buyFromAddressLine2; Rec."Buy-from Address 2")
                {
                    Caption = 'Buy-from Address Line 2';
                }
                field(buyFromCity; Rec."Buy-from City")
                {
                    Caption = 'Buy-from City';
                }
                field(buyFromCountry; Rec."Buy-from Country/Region Code")
                {
                    Caption = 'Buy-from Country/Region Code';
                }
                field(buyFromState; Rec."Buy-from County")
                {
                    Caption = 'Buy-from State';
                }
                field(buyFromPostCode; Rec."Buy-from Post Code")
                {
                    Caption = 'Buy-from Post Code';
                }
                field(shipToAddressLine1; Rec."Ship-to Address")
                {
                    Caption = 'Ship-to Address Line 1';
                }
                field(shipToAddressLine2; Rec."Ship-to Address 2")
                {
                    Caption = 'Ship-to Address Line 2';
                }
                field(shipToCity; Rec."Ship-to City")
                {
                    Caption = 'Ship-to City';
                }
                field(shipToCountry; Rec."Ship-to Country/Region Code")
                {
                    Caption = 'Ship-to Country/Region Code';
                }
                field(shipToState; Rec."Ship-to County")
                {
                    Caption = 'Ship-to State';
                }
                field(shipToPostCode; Rec."Ship-to Post Code")
                {
                    Caption = 'Ship-to Post Code';
                }
                field(shipToPhoneNo; Rec."Ship-to Phone No.")
                {
                    Caption = 'Ship-to Phone No.';
                }
                field(payToAddressLine1; Rec."Pay-to Address")
                {
                    Caption = 'Pay To Address Line 1';
                }
                field(payToAddressLine2; Rec."Pay-to Address 2")
                {
                    Caption = 'Pay To Address Line 2';
                }
                field(payToCity; Rec."Pay-to City")
                {
                    Caption = 'Pay To City';
                }
                field(payToCountry; Rec."Pay-to Country/Region Code")
                {
                    Caption = 'Pay To Country/Region Code';
                }
                field(payToState; Rec."Pay-to County")
                {
                    Caption = 'Pay To State';
                }
                field(payToPostCode; Rec."Pay-to Post Code")
                {
                    Caption = 'Pay To Post Code';
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(orderNumber; Rec."Order No.")
                {
                    Caption = 'Order No.';
                }
                field(paymentTermsCode; Rec."Payment Terms Code")
                {
                    Caption = 'Payment Terms Code';
                }
                field(shipmentMethodCode; Rec."Shipment Method Code")
                {
                    Caption = 'Shipment Method Code';
                }
                field(pricesIncludeTax; Rec."Prices Including VAT")
                {
                    Caption = 'Prices Include Tax';
                }
                field(discountAmount; Rec."Invoice Discount Amount")
                {
                    Caption = 'Discount Amount';
                }
                field(totalAmountExcludingTax; Rec.Amount)
                {
                    Caption = 'Total Amount Excluding Tax';
                }
                field(totalAmountIncludingTax; Rec."Amount Including VAT")
                {
                    Caption = 'Total Amount Including Tax';
                }
            }
        }
    }

    var
        APIId: Guid;

    trigger OnAfterGetRecord()
    begin
        if IsNullGuid(Rec."Draft Invoice SystemId") then
            APIId := Rec.SystemId
        else
            APIId := Rec."Draft Invoice SystemId";
    end;
}
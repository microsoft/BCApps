// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Sales.History;

page 9970 "Posted Sales Invoice API"
{
    APIVersion = 'v1.0';
    APIGroup = 'automate';
    APIPublisher = 'microsoft';
    EntityCaption = 'Posted Sales Invoice';
    EntitySetCaption = 'Posted Sales Invoices';
    ChangeTrackingAllowed = true;
    EntityName = 'postedSalesInvoice';
    EntitySetName = 'postedSalesInvoices';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "Sales Invoice Header";
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
                field(externalDocumentNumber; Rec."External Document No.")
                {
                    Caption = 'External Document No.';
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
                field(customerPurchaseOrderReference; Rec."Your Reference")
                {
                    Caption = 'Customer Purchase Order Reference';
                }
                field(customerNumber; Rec."Sell-to Customer No.")
                {
                    Caption = 'Customer No.';
                }
                field(customerName; Rec."Sell-to Customer Name")
                {
                    Caption = 'Customer Name';
                }
                field(billToName; Rec."Bill-to Name")
                {
                    Caption = 'Bill-To Name';
                }
                field(billToCustomerNumber; Rec."Bill-to Customer No.")
                {
                    Caption = 'Bill-To Customer No.';
                }
                field(shipToName; Rec."Ship-to Name")
                {
                    Caption = 'Ship-to Name';
                }
                field(shipToContact; Rec."Ship-to Contact")
                {
                    Caption = 'Ship-to Contact';
                }
                field(sellToAddressLine1; Rec."Sell-to Address")
                {
                    Caption = 'Sell-to Address Line 1';
                }
                field(sellToAddressLine2; Rec."Sell-to Address 2")
                {
                    Caption = 'Sell-to Address Line 2';
                }
                field(sellToCity; Rec."Sell-to City")
                {
                    Caption = 'Sell-to City';
                }
                field(sellToCountry; Rec."Sell-to Country/Region Code")
                {
                    Caption = 'Sell-to Country/Region Code';
                }
                field(sellToState; Rec."Sell-to County")
                {
                    Caption = 'Sell-to State';
                }
                field(sellToPostCode; Rec."Sell-to Post Code")
                {
                    Caption = 'Sell-to Post Code';
                }
                field(billToAddressLine1; Rec."Bill-To Address")
                {
                    Caption = 'Bill-to Address Line 1';
                }
                field(billToAddressLine2; Rec."Bill-To Address 2")
                {
                    Caption = 'Bill-to Address Line 2';
                }
                field(billToCity; Rec."Bill-To City")
                {
                    Caption = 'Bill-to City';
                }
                field(billToCountry; Rec."Bill-To Country/Region Code")
                {
                    Caption = 'Bill-to Country/Region Code';
                }
                field(billToState; Rec."Bill-To County")
                {
                    Caption = 'Bill-to State';
                }
                field(billToPostCode; Rec."Bill-To Post Code")
                {
                    Caption = 'Bill-to Post Code';
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
                field(salesperson; Rec."Salesperson Code")
                {
                    Caption = 'Salesperson';
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
                field(phoneNumber; Rec."Sell-to Phone No.")
                {
                    Caption = 'Phone No.';
                }
                field(email; Rec."Sell-to E-Mail")
                {
                    Caption = 'Email';
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
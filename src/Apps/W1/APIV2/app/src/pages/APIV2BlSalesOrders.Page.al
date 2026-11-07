// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.API.V2;

using Microsoft.Sales.Document;

page 30058 "APIV2 - Bl. Sales Orders"
{
    APIVersion = 'v2.0';
    EntityCaption = 'Blanket Sales Order';
    EntitySetCaption = 'Blanket Sales Orders';
    ChangeTrackingAllowed = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    EntityName = 'blanketSalesOrder';
    EntitySetName = 'blanketSalesOrders';
    ODataKeyFields = SystemId;
    PageType = API;
    SourceTable = "Sales Header";
    SourceTableView = where("Document Type" = const("Blanket Order"));
    Extensible = false;
    AboutText = 'Exposes blanket sales order documents for long-term customer agreements, including customer details, order status, delivery and payment information, addresses, and currency. Supports read-only (GET) operations for framework customer contracts and sales planning with external platforms.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                    Editable = false;
                }
                field(externalDocumentNumber; Rec."External Document No.")
                {
                    Caption = 'External Document No.';
                }
                field(documentDate; Rec."Document Date")
                {
                    Caption = 'Document Date';
                }
                field(postingDate; Rec."Posting Date")
                {
                    Caption = 'Posting Date';
                }
                field(dueDate; Rec."Due Date")
                {
                    Caption = 'Due Date';
                }
                field(sellToCustomerNumber; Rec."Sell-to Customer No.")
                {
                    Caption = 'Sell-to Customer No.';
                }
                field(sellToCustomerName; Rec."Sell-to Customer Name")
                {
                    Caption = 'Sell-to Customer Name';
                    Editable = false;
                }
                field(billToName; Rec."Bill-to Name")
                {
                    Caption = 'Bill-to Name';
                }
                field(billToCustomerNumber; Rec."Bill-to Customer No.")
                {
                    Caption = 'Bill-to Customer No.';
                }
                field(shipToName; Rec."Ship-to Name")
                {
                    Caption = 'Ship-to Name';
                }
                field(shipToContact; Rec."Ship-to Contact")
                {
                    Caption = 'Ship-to Contact';
                }
                field(sellToAddress; Rec."Sell-to Address")
                {
                    Caption = 'Sell-to Address';
                }
                field(sellToAddress2; Rec."Sell-to Address 2")
                {
                    Caption = 'Sell-to Address 2';
                }
                field(sellToCity; Rec."Sell-to City")
                {
                    Caption = 'Sell-to City';
                }
                field(sellToCountryRegionCode; Rec."Sell-to Country/Region Code")
                {
                    Caption = 'Sell-to Country/Region Code';
                }
                field(sellToCounty; Rec."Sell-to County")
                {
                    Caption = 'Sell-to County';
                }
                field(sellToPostCode; Rec."Sell-to Post Code")
                {
                    Caption = 'Sell-to Post Code';
                }
                field(shipToAddress; Rec."Ship-to Address")
                {
                    Caption = 'Ship-to Address';
                }
                field(shipToAddress2; Rec."Ship-to Address 2")
                {
                    Caption = 'Ship-to Address 2';
                }
                field(shipToCity; Rec."Ship-to City")
                {
                    Caption = 'Ship-to City';
                }
                field(shipToCountryRegionCode; Rec."Ship-to Country/Region Code")
                {
                    Caption = 'Ship-to Country/Region Code';
                }
                field(shipToCounty; Rec."Ship-to County")
                {
                    Caption = 'Ship-to County';
                }
                field(shipToPostCode; Rec."Ship-to Post Code")
                {
                    Caption = 'Ship-to Post Code';
                }
                field(billToAddress; Rec."Bill-to Address")
                {
                    Caption = 'Bill-to Address';
                }
                field(billToAddress2; Rec."Bill-to Address 2")
                {
                    Caption = 'Bill-to Address 2';
                }
                field(billToCity; Rec."Bill-to City")
                {
                    Caption = 'Bill-to City';
                }
                field(billToCountryRegionCode; Rec."Bill-to Country/Region Code")
                {
                    Caption = 'Bill-to Country/Region Code';
                }
                field(billToCounty; Rec."Bill-to County")
                {
                    Caption = 'Bill-to County';
                }
                field(billToPostCode; Rec."Bill-to Post Code")
                {
                    Caption = 'Bill-to Post Code';
                }
                field(currencyCode; Rec."Currency Code")
                {
                    Caption = 'Currency Code';
                }
                field(pricesIncludingVAT; Rec."Prices Including VAT")
                {
                    Caption = 'Prices Including VAT';
                }
                field(paymentTermsCode; Rec."Payment Terms Code")
                {
                    Caption = 'Payment Terms Code';
                }
                field(shipmentMethodCode; Rec."Shipment Method Code")
                {
                    Caption = 'Shipment Method Code';
                }
                field(salespersonCode; Rec."Salesperson Code")
                {
                    Caption = 'Salesperson Code';
                }
                field(orderDate; Rec."Order Date")
                {
                    Caption = 'Order Date';
                }
                field(requestedDeliveryDate; Rec."Requested Delivery Date")
                {
                    Caption = 'Requested Delivery Date';
                }
                field(yourReference; Rec."Your Reference")
                {
                    Caption = 'Your Reference';
                }
                field(quoteNumber; Rec."Quote No.")
                {
                    Caption = 'Quote No.';
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(customerPostingGroup; Rec."Customer Posting Group")
                {
                    Caption = 'Customer Posting Group';
                }
                field(genBusPostingGroup; Rec."Gen. Bus. Posting Group")
                {
                    Caption = 'Gen. Bus. Posting Group';
                }
                field(vatBusPostingGroup; Rec."VAT Bus. Posting Group")
                {
                    Caption = 'VAT Bus. Posting Group';
                }
                field(sellToContact; Rec."Sell-to Contact")
                {
                    Caption = 'Sell-to Contact';
                }
                field(billToContact; Rec."Bill-to Contact")
                {
                    Caption = 'Bill-to Contact';
                }
                field(responsibilityCenter; Rec."Responsibility Center")
                {
                    Caption = 'Responsibility Center';
                }
                field(status; Rec.Status)
                {
                    Caption = 'Status';
                    Editable = false;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                    Editable = false;
                }
                part(dimensionSetLines; "APIV2 - Dimension Set Lines")
                {
                    Caption = 'Dimension Set Lines';
                    EntityName = 'dimensionSetLine';
                    EntitySetName = 'dimensionSetLines';
                    SubPageLink = "Parent Id" = field(SystemId), "Parent Type" = const("Blanket Sales Order");
                }
                part(blanketSalesOrderLines; "APIV2 - Bl. Sales Ord. Lines")
                {
                    Caption = 'Lines';
                    EntityName = 'blanketSalesOrderLine';
                    EntitySetName = 'blanketSalesOrderLines';
                    SubPageLink = "Document No." = field("No."), "Document Type" = const("Blanket Order");
                }
                part(pdfDocument; "APIV2 - PDF Document")
                {
                    Caption = 'PDF Document';
                    Multiplicity = ZeroOrOne;
                    EntityName = 'pdfDocument';
                    EntitySetName = 'pdfDocument';
                    SubPageLink = "Document Id" = field(SystemId), "Document Type" = const("Blanket Sales Order");
                }
                part(attachments; "APIV2 - Attachments")
                {
                    Caption = 'Attachments';
                    EntityName = 'attachment';
                    EntitySetName = 'attachments';
                    SubPageLink = "Document Id" = field(SystemId), "Document Type" = const("Blanket Sales Order");
                }
                part(documentAttachments; "APIV2 - Document Attachments")
                {
                    Caption = 'Document Attachments';
                    EntityName = 'documentAttachment';
                    EntitySetName = 'documentAttachments';
                    SubPageLink = "Document Id" = field(SystemId), "Document Type" = const("Blanket Sales Order");
                }
            }
        }
    }
}

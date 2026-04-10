// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Sales.Document;

page 6402 "Sales Document Entity"
{
    Caption = 'workflowSalesDocuments', Locked = true;
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    SourceTable = "Sales Header";
    PageType = List;

    layout
    {
        area(content)
        {
            group(General)
            {
                field(id; Rec.SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                }
                field(documentType; Rec."Document Type")
                {
                    ApplicationArea = All;
                    Caption = 'Document Type', Locked = true;
                }
                field(sellToCustomerNumber; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Customer No.', Locked = true;
                }
                field(number; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.', Locked = true;
                }
                field(billToCustomerNumber; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Customer No.', Locked = true;
                }
                field(billToName; Rec."Bill-to Name")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Name', Locked = true;
                }
                field(billToName2; Rec."Bill-to Name 2")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Name 2', Locked = true;
                }
                field(billToAddress; Rec."Bill-to Address")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Address', Locked = true;
                }
                field(billToAddress2; Rec."Bill-to Address 2")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Address 2', Locked = true;
                }
                field(billToCity; Rec."Bill-to City")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to City', Locked = true;
                }
                field(billToContact; Rec."Bill-to Contact")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Contact', Locked = true;
                }
                field(yourReference; Rec."Your Reference")
                {
                    ApplicationArea = All;
                    Caption = 'Your Reference', Locked = true;
                }
                field(shipToCode; Rec."Ship-to Code")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Code', Locked = true;
                }
                field(shipToName; Rec."Ship-to Name")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Name', Locked = true;
                }
                field(shipToName2; Rec."Ship-to Name 2")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Name 2', Locked = true;
                }
                field(shipToAddress; Rec."Ship-to Address")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Address', Locked = true;
                }
                field(shipToAddress2; Rec."Ship-to Address 2")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Address 2', Locked = true;
                }
                field(shipToCity; Rec."Ship-to City")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to City', Locked = true;
                }
                field(shipToContact; Rec."Ship-to Contact")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Contact', Locked = true;
                }
                field(orderDate; Rec."Order Date")
                {
                    ApplicationArea = All;
                    Caption = 'Order Date', Locked = true;
                }
                field(postingDate; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Date', Locked = true;
                }
                field(shipmentDate; Rec."Shipment Date")
                {
                    ApplicationArea = All;
                    Caption = 'Shipment Date', Locked = true;
                }
                field(postingDescription; Rec."Posting Description")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Description', Locked = true;
                }
                field(paymentTermsCode; Rec."Payment Terms Code")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Terms Code', Locked = true;
                }
                field(dueDate; Rec."Due Date")
                {
                    ApplicationArea = All;
                    Caption = 'Due Date', Locked = true;
                }
                field(paymentDiscountPercent; Rec."Payment Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Discount %', Locked = true;
                }
                field(pmtDiscountDate; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = All;
                    Caption = 'Pmt. Discount Date', Locked = true;
                }
                field(shipmentMethodCode; Rec."Shipment Method Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shipment Method Code', Locked = true;
                }
                field(locationCode; Rec."Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'Location Code', Locked = true;
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shortcut Dimension 1 Code', Locked = true;
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shortcut Dimension 2 Code', Locked = true;
                }
                field(customerPostingGroup; Rec."Customer Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Posting Group', Locked = true;
                }
                field(currencyCode; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Caption = 'Currency Code', Locked = true;
                }
                field(currencyFactor; Rec."Currency Factor")
                {
                    ApplicationArea = All;
                    Caption = 'Currency Factor', Locked = true;
                }
                field(customerPriceGroup; Rec."Customer Price Group")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Price Group', Locked = true;
                }
                field(pricesIncludingVat; Rec."Prices Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'Prices Including VAT', Locked = true;
                }
                field(invoiceDiscCode; Rec."Invoice Disc. Code")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice Disc. Code', Locked = true;
                }
                field(customerDiscGroup; Rec."Customer Disc. Group")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Disc. Group', Locked = true;
                }
                field(languageCode; Rec."Language Code")
                {
                    ApplicationArea = All;
                    Caption = 'Language Code', Locked = true;
                }
                field(salespersonCode; Rec."Salesperson Code")
                {
                    ApplicationArea = All;
                    Caption = 'Salesperson Code', Locked = true;
                }
                field(orderClass; Rec."Order Class")
                {
                    ApplicationArea = All;
                    Caption = 'Order Class', Locked = true;
                }
                field(comment; Rec.Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comment', Locked = true;
                }
                field(numberPrinted; Rec."No. Printed")
                {
                    ApplicationArea = All;
                    Caption = 'No. Printed', Locked = true;
                }
                field(onHold; Rec."On Hold")
                {
                    ApplicationArea = All;
                    Caption = 'On Hold', Locked = true;
                }
                field(appliesToDocType; Rec."Applies-to Doc. Type")
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to Doc. Type', Locked = true;
                }
                field(appliesToDocNumber; Rec."Applies-to Doc. No.")
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to Doc. No.', Locked = true;
                }
                field(balAccountNumber; Rec."Bal. Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Account No.', Locked = true;
                }
                field(recalculateInvoiceDisc; Rec."Recalculate Invoice Disc.")
                {
                    ApplicationArea = All;
                    Caption = 'Recalculate Invoice Disc.', Locked = true;
                }
                field(ship; Rec.Ship)
                {
                    ApplicationArea = All;
                    Caption = 'Ship', Locked = true;
                }
                field(invoice; Rec.Invoice)
                {
                    ApplicationArea = All;
                    Caption = 'Invoice', Locked = true;
                }
                field(printPostedDocuments; Rec."Print Posted Documents")
                {
                    ApplicationArea = All;
                    Caption = 'Print Posted Documents', Locked = true;
                }
                field(amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Amount', Locked = true;
                }
                field(amountIncludingVAT; Rec."Amount Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'Amount Including VAT', Locked = true;
                }
                field(shippingNumber; Rec."Shipping No.")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping No.', Locked = true;
                }
                field(postingNumber; Rec."Posting No.")
                {
                    ApplicationArea = All;
                    Caption = 'Posting No.', Locked = true;
                }
                field(lastShippingNumber; Rec."Last Shipping No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Shipping No.', Locked = true;
                }
                field(lastPostingNumber; Rec."Last Posting No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Posting No.', Locked = true;
                }
                field(prepaymentNumber; Rec."Prepayment No.")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment No.', Locked = true;
                }
                field(lastPrepaymentNumber; Rec."Last Prepayment No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Prepayment No.', Locked = true;
                }
                field(premptCrMemoNumber; Rec."Prepmt. Cr. Memo No.")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Cr. Memo No.', Locked = true;
                }
                field(lastPremtCrMemoNumber; Rec."Last Prepmt. Cr. Memo No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Prepmt. Cr. Memo No.', Locked = true;
                }
                field(vatRegistrationNumber; Rec."VAT Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Registration No.', Locked = true;
                }
                field(combineShipments; Rec."Combine Shipments")
                {
                    ApplicationArea = All;
                    Caption = 'Combine Shipments', Locked = true;
                }
                field(reasonCode; Rec."Reason Code")
                {
                    ApplicationArea = All;
                    Caption = 'Reason Code', Locked = true;
                }
                field(genBusPostingGroup; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Gen. Bus. Posting Group', Locked = true;
                }
                field(eu3PartyTrade; Rec."EU 3-Party Trade")
                {
                    ApplicationArea = All;
                    Caption = 'EU 3-Party Trade', Locked = true;
                }
                field(transactionType; Rec."Transaction Type")
                {
                    ApplicationArea = All;
                    Caption = 'Transaction Type', Locked = true;
                }
                field(transportMethod; Rec."Transport Method")
                {
                    ApplicationArea = All;
                    Caption = 'Transport Method', Locked = true;
                }
                field(vatCountryRegionCode; Rec."VAT Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Country/Region Code', Locked = true;
                }
                field(sellToCustomerName; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Customer Name', Locked = true;
                }
                field(sellToCustomerName2; Rec."Sell-to Customer Name 2")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Customer Name 2', Locked = true;
                }
                field(sellToAddress; Rec."Sell-to Address")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Address', Locked = true;
                }
                field(sellToAddress2; Rec."Sell-to Address 2")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Address 2', Locked = true;
                }
                field(sellToCity; Rec."Sell-to City")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to City', Locked = true;
                }
                field(sellToContact; Rec."Sell-to Contact")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Contact', Locked = true;
                }
                field(billToPostCode; Rec."Bill-to Post Code")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Post Code', Locked = true;
                }
                field(billToCounty; Rec."Bill-to County")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to County', Locked = true;
                }
                field(billToCountryRegionCode; Rec."Bill-to Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Country/Region Code', Locked = true;
                }
                field(sellToPostCode; Rec."Sell-to Post Code")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Post Code', Locked = true;
                }
                field(sellToCounty; Rec."Sell-to County")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to County', Locked = true;
                }
                field(sellToCountryRegionCode; Rec."Sell-to Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Country/Region Code', Locked = true;
                }
                field(shipToPostCode; Rec."Ship-to Post Code")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Post Code', Locked = true;
                }
                field(shipToCounty; Rec."Ship-to County")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to County', Locked = true;
                }
                field(shipToCountryRegionCode; Rec."Ship-to Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Country/Region Code', Locked = true;
                }
                field(shipToPhoneNo; Rec."Ship-to Phone No.")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Phone No.', Locked = true;
                }
                field(balAccountType; Rec."Bal. Account Type")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Account Type', Locked = true;
                }
                field(exitPoint; Rec."Exit Point")
                {
                    ApplicationArea = All;
                    Caption = 'Exit Point', Locked = true;
                }
                field(correction; Rec.Correction)
                {
                    ApplicationArea = All;
                    Caption = 'Correction', Locked = true;
                }
                field(documentDate; Rec."Document Date")
                {
                    ApplicationArea = All;
                    Caption = 'Document Date', Locked = true;
                }
                field(externalDocumentNumber; Rec."External Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'External Document No.', Locked = true;
                }
                field("area"; Rec.Area)
                {
                    ApplicationArea = All;
                    Caption = 'Area', Locked = true;
                }
                field(transactionSpecification; Rec."Transaction Specification")
                {
                    ApplicationArea = All;
                    Caption = 'Transaction Specification', Locked = true;
                }
                field(paymentMethodCode; Rec."Payment Method Code")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Method Code', Locked = true;
                }
                field(shippingAgentCode; Rec."Shipping Agent Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping Agent Code', Locked = true;
                }
                field(packageTrackingNumber; Rec."Package Tracking No.")
                {
                    ApplicationArea = All;
                    Caption = 'Package Tracking No.', Locked = true;
                }
                field(numberSeries; Rec."No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'No. Series', Locked = true;
                }
                field(postingNumberSeries; Rec."Posting No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Posting No. Series', Locked = true;
                }
                field(shippingNumberSeries; Rec."Shipping No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping No. Series', Locked = true;
                }
                field(taxAreaCode; Rec."Tax Area Code")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Area Code', Locked = true;
                }
                field(taxLiable; Rec."Tax Liable")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Liable', Locked = true;
                }
                field(vatBusPostingGroup; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Bus. Posting Group', Locked = true;
                }
                field(reserve; Rec.Reserve)
                {
                    ApplicationArea = All;
                    Caption = 'Reserve', Locked = true;
                }
                field(appliesToId; Rec."Applies-to ID")
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to ID', Locked = true;
                }
                field(vatBaseDiscountPercent; Rec."VAT Base Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Base Discount %', Locked = true;
                }
                field(status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status', Locked = true;
                }
                field(invoiceDiscountCalculation; Rec."Invoice Discount Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice Discount Calculation', Locked = true;
                }
                field(invoiceDiscountValue; Rec."Invoice Discount Value")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice Discount Value', Locked = true;
                }
                field(sendIcDocument; Rec."Send IC Document")
                {
                    ApplicationArea = All;
                    Caption = 'Send IC Document', Locked = true;
                }
                field(icStatus; Rec."IC Status")
                {
                    ApplicationArea = All;
                    Caption = 'IC Status', Locked = true;
                }
                field(sellToIcPartnerCode; Rec."Sell-to IC Partner Code")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to IC Partner Code', Locked = true;
                }
                field(billToIcPartnerCode; Rec."Bill-to IC Partner Code")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to IC Partner Code', Locked = true;
                }
                field(icDirection; Rec."IC Direction")
                {
                    ApplicationArea = All;
                    Caption = 'IC Direction', Locked = true;
                }
                field(prepaymentPercent; Rec."Prepayment %")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment %', Locked = true;
                }
                field(prepaymentNumberSeries; Rec."Prepayment No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment No. Series', Locked = true;
                }
                field(compressPrepayment; Rec."Compress Prepayment")
                {
                    ApplicationArea = All;
                    Caption = 'Compress Prepayment', Locked = true;
                }
                field(prepaymentDueDate; Rec."Prepayment Due Date")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment Due Date', Locked = true;
                }
                field(prepmtCrMemoNumberSeries; Rec."Prepmt. Cr. Memo No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Cr. Memo No. Series', Locked = true;
                }
                field(prepmtPostingDescription; Rec."Prepmt. Posting Description")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Posting Description', Locked = true;
                }
                field(prepmtPmtDiscountDate; Rec."Prepmt. Pmt. Discount Date")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Pmt. Discount Date', Locked = true;
                }
                field(prepmtPaymentTermsCode; Rec."Prepmt. Payment Terms Code")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Payment Terms Code', Locked = true;
                }
                field(prepmtPaymentDiscountPercent; Rec."Prepmt. Payment Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Payment Discount %', Locked = true;
                }
                field(quoteNumber; Rec."Quote No.")
                {
                    ApplicationArea = All;
                    Caption = 'Quote No.', Locked = true;
                }
                field(quoteValidUntilDate; Rec."Quote Valid Until Date")
                {
                    ApplicationArea = All;
                    Caption = 'Quote Valid Until Date', Locked = true;
                }
                field(quoteSentToCustomer; Rec."Quote Sent to Customer")
                {
                    ApplicationArea = All;
                    Caption = 'Quote Sent to Customer', Locked = true;
                }
                field(quoteAccepted; Rec."Quote Accepted")
                {
                    ApplicationArea = All;
                    Caption = 'Quote Accepted', Locked = true;
                }
                field(quoteAcceptedDate; Rec."Quote Accepted Date")
                {
                    ApplicationArea = All;
                    Caption = 'Quote Accepted Date', Locked = true;
                }
                field(jobQueueStatus; Rec."Job Queue Status")
                {
                    ApplicationArea = All;
                    Caption = 'Job Queue Status', Locked = true;
                }
                field(jobQueueEntryId; Rec."Job Queue Entry ID")
                {
                    ApplicationArea = All;
                    Caption = 'Job Queue Entry ID', Locked = true;
                }
                field(incomingDocumentEntryNumber; Rec."Incoming Document Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Incoming Document Entry No.', Locked = true;
                }
                field(workDescription; Rec."Work Description")
                {
                    ApplicationArea = All;
                    Caption = 'Work Description', Locked = true;
                }
                field(amountShippedNotInvoicedInclVat; Rec."Amt. Ship. Not Inv. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Amount Shipped Not Invoiced (LCY) Incl. VAT', Locked = true;
                }
                field(amountShippedNotInvoiced; Rec."Amt. Ship. Not Inv. (LCY) Base")
                {
                    ApplicationArea = All;
                    Caption = 'Amount Shipped Not Invoiced (LCY)', Locked = true;
                }
                field(dimensionSetId; Rec."Dimension Set ID")
                {
                    ApplicationArea = All;
                    Caption = 'Dimension Set ID', Locked = true;
                }
                field(paymentServiceSetId; Rec."Payment Service Set ID")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Service Set ID', Locked = true;
                }
                field(directDebitMandateId; Rec."Direct Debit Mandate ID")
                {
                    ApplicationArea = All;
                    Caption = 'Direct Debit Mandate ID', Locked = true;
                }
                field(invoiceDiscountAmount; Rec."Invoice Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice Discount Amount', Locked = true;
                }
                field(numberOfArchivedVersions; Rec."No. of Archived Versions")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Archived Versions', Locked = true;
                }
                field(docNumberOccurrence; Rec."Doc. No. Occurrence")
                {
                    ApplicationArea = All;
                    Caption = 'Doc. No. Occurrence', Locked = true;
                }
                field(campaignNumber; Rec."Campaign No.")
                {
                    ApplicationArea = All;
                    Caption = 'Campaign No.', Locked = true;
                }
                field(sellToContactNumber; Rec."Sell-to Contact No.")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Contact No.', Locked = true;
                }
                field(billToContactNumber; Rec."Bill-to Contact No.")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Contact No.', Locked = true;
                }
                field(opportunityNumber; Rec."Opportunity No.")
                {
                    ApplicationArea = All;
                    Caption = 'Opportunity No.', Locked = true;
                }
                field(responsibilityCenter; Rec."Responsibility Center")
                {
                    ApplicationArea = All;
                    Caption = 'Responsibility Center', Locked = true;
                }
                field(shippingAdvice; Rec."Shipping Advice")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping Advice', Locked = true;
                }
                field(shippedNotInvoiced; Rec."Shipped Not Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Shipped Not Invoiced', Locked = true;
                }
                field(completelyShipped; Rec."Completely Shipped")
                {
                    ApplicationArea = All;
                    Caption = 'Completely Shipped', Locked = true;
                }
                field(postingFromWhseRef; Rec."Posting from Whse. Ref.")
                {
                    ApplicationArea = All;
                    Caption = 'Posting from Whse. Ref.', Locked = true;
                }
                field(locationFilter; Rec."Location Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Location Filter', Locked = true;
                }
                field(shipped; Rec.Shipped)
                {
                    ApplicationArea = All;
                    Caption = 'Shipped', Locked = true;
                }
                field(requestedDeliveryDate; Rec."Requested Delivery Date")
                {
                    ApplicationArea = All;
                    Caption = 'Requested Delivery Date', Locked = true;
                }
                field(promisedDeliveryDate; Rec."Promised Delivery Date")
                {
                    ApplicationArea = All;
                    Caption = 'Promised Delivery Date', Locked = true;
                }
                field(shippingTime; Rec."Shipping Time")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping Time', Locked = true;
                }
                field(outboundWhseHandlingTime; Rec."Outbound Whse. Handling Time")
                {
                    ApplicationArea = All;
                    Caption = 'Outbound Whse. Handling Time', Locked = true;
                }
                field(shippingAgentServiceCode; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping Agent Service Code', Locked = true;
                }
                field(lateOrderShipping; Rec."Late Order Shipping")
                {
                    ApplicationArea = All;
                    Caption = 'Late Order Shipping', Locked = true;
                }
                field(receive; Rec.Receive)
                {
                    ApplicationArea = All;
                    Caption = 'Receive', Locked = true;
                }
                field(returnReceiptNumber; Rec."Return Receipt No.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Receipt No.', Locked = true;
                }
                field(returnReceiptNumberSeries; Rec."Return Receipt No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Return Receipt No. Series', Locked = true;
                }
                field(lastReturnReceiptNumber; Rec."Last Return Receipt No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Return Receipt No.', Locked = true;
                }
                field(allowLineDisc; Rec."Allow Line Disc.")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Line Disc.', Locked = true;
                }
                field(getShipmentUsed; Rec."Get Shipment Used")
                {
                    ApplicationArea = All;
                    Caption = 'Get Shipment Used', Locked = true;
                }

                field(assignedUserId; Rec."Assigned User ID")
                {
                    ApplicationArea = All;
                    Caption = 'Assigned User ID', Locked = true;
                }
                part(workflowSalesDocumentLines; "Sales Document Line Entity")
                {
                    ApplicationArea = All;
                    Caption = 'Lines', Locked = true;
                    SubPageLink = "Document Type" = field("Document Type"),
                                  "Document No." = field("No.");
                    EntityName = 'line';
                    EntitySetName = 'lines';
                }
            }
        }
    }

    actions
    {
    }
}


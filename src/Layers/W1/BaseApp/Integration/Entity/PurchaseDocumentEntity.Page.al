// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Purchases.Document;

page 6404 "Purchase Document Entity"
{
    Caption = 'workflowPurchaseDocuments', Locked = true;
    DelayedInsert = true;
    SourceTable = "Purchase Header";
    PageType = List;
    ODataKeyFields = SystemId;

    layout
    {
        area(content)
        {
            repeater(Group)
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
                field(buyFromVendorNumber; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Vendor No.', Locked = true;
                }
                field(number; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.', Locked = true;
                }
                field(payToVendorNumber; Rec."Pay-to Vendor No.")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Vendor No.', Locked = true;
                }
                field(payToName; Rec."Pay-to Name")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Name', Locked = true;
                }
                field(payToName2; Rec."Pay-to Name 2")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Name 2', Locked = true;
                }
                field(payToAddress; Rec."Pay-to Address")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Address', Locked = true;
                }
                field(payToAddress2; Rec."Pay-to Address 2")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Address 2', Locked = true;
                }
                field(payToCity; Rec."Pay-to City")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to City', Locked = true;
                }
                field(payToContact; Rec."Pay-to Contact")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Contact', Locked = true;
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
                field(expectedReceiptDate; Rec."Expected Receipt Date")
                {
                    ApplicationArea = All;
                    Caption = 'Expected Receipt Date', Locked = true;
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
                field(vendorPostingGroup; Rec."Vendor Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Posting Group', Locked = true;
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
                field(languageCode; Rec."Language Code")
                {
                    ApplicationArea = All;
                    Caption = 'Language Code', Locked = true;
                }
                field(purchaserCode; Rec."Purchaser Code")
                {
                    ApplicationArea = All;
                    Caption = 'Purchaser Code', Locked = true;
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
                field(receive; Rec.Receive)
                {
                    ApplicationArea = All;
                    Caption = 'Receive', Locked = true;
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
                field(amountIncludingVat; Rec."Amount Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'Amount Including VAT', Locked = true;
                }
                field(receivingNumber; Rec."Receiving No.")
                {
                    ApplicationArea = All;
                    Caption = 'Receiving No.', Locked = true;
                }
                field(postingNumber; Rec."Posting No.")
                {
                    ApplicationArea = All;
                    Caption = 'Posting No.', Locked = true;
                }
                field(lastReceivingNumber; Rec."Last Receiving No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Receiving No.', Locked = true;
                }
                field(lastPostingNumber; Rec."Last Posting No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Posting No.', Locked = true;
                }
                field(vendorOrderNumber; Rec."Vendor Order No.")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Order No.', Locked = true;
                }
                field(vendorShipmentNumber; Rec."Vendor Shipment No.")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Shipment No.', Locked = true;
                }
                field(vendorInvoiceNumber; Rec."Vendor Invoice No.")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Invoice No.', Locked = true;
                }
                field(vendorCrMemoNumber; Rec."Vendor Cr. Memo No.")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Cr. Memo No.', Locked = true;
                }
                field(vatRegistrationNumber; Rec."VAT Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Registration No.', Locked = true;
                }
                field(sellToCustomerNumber; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Customer No.', Locked = true;
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
                field(buyFromVendorName; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Vendor Name', Locked = true;
                }
                field(buyFromVendorName2; Rec."Buy-from Vendor Name 2")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Vendor Name 2', Locked = true;
                }
                field(buyFromAddress; Rec."Buy-from Address")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Address', Locked = true;
                }
                field(buyFromAddress2; Rec."Buy-from Address 2")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Address 2', Locked = true;
                }
                field(buyFromCity; Rec."Buy-from City")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from City', Locked = true;
                }
                field(buyFromContact; Rec."Buy-from Contact")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Contact', Locked = true;
                }
                field(payToPostCode; Rec."Pay-to Post Code")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Post Code', Locked = true;
                }
                field(payToCounty; Rec."Pay-to County")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to County', Locked = true;
                }
                field(payToCountryRegionCode; Rec."Pay-to Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Country/Region Code', Locked = true;
                }
                field(buyFromPostCode; Rec."Buy-from Post Code")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Post Code', Locked = true;
                }
                field(buyFromCounty; Rec."Buy-from County")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from County', Locked = true;
                }
                field(buyFromCountryRegionCode; Rec."Buy-from Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Country/Region Code', Locked = true;
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
                field(orderAddressCode; Rec."Order Address Code")
                {
                    ApplicationArea = All;
                    Caption = 'Order Address Code', Locked = true;
                }
                field(entryPoint; Rec."Entry Point")
                {
                    ApplicationArea = All;
                    Caption = 'Entry Point', Locked = true;
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
                field(receivingNumberSeries; Rec."Receiving No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Receiving No. Series', Locked = true;
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
                field(buyFromIcPartnerCode; Rec."Buy-from IC Partner Code")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from IC Partner Code', Locked = true;
                }
                field(payToIcPartnerCode; Rec."Pay-to IC Partner Code")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to IC Partner Code', Locked = true;
                }
                field(icDirection; Rec."IC Direction")
                {
                    ApplicationArea = All;
                    Caption = 'IC Direction', Locked = true;
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
                field(prepmtCrMemoNumber; Rec."Prepmt. Cr. Memo No.")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Cr. Memo No.', Locked = true;
                }
                field(lastPrepmtCrMemoNumber; Rec."Last Prepmt. Cr. Memo No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Prepmt. Cr. Memo No.', Locked = true;
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
                field(creditorNumber; Rec."Creditor No.")
                {
                    ApplicationArea = All;
                    Caption = 'Creditor No.', Locked = true;
                }
                field(paymentReference; Rec."Payment Reference")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Reference', Locked = true;
                }
                field(aRcdNotInvExVatLcy; Rec."A. Rcd. Not Inv. Ex. VAT (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'A. Rcd. Not Inv. Ex. VAT (LCY)', Locked = true;
                }
                field(amtRcdNotInvoicedLcy; Rec."Amt. Rcd. Not Invoiced (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Amt. Rcd. Not Invoiced (LCY)', Locked = true;
                }
                field(dimensionSetId; Rec."Dimension Set ID")
                {
                    ApplicationArea = All;
                    Caption = 'Dimension Set ID', Locked = true;
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
                field(buyFromContactNumber; Rec."Buy-from Contact No.")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from Contact No.', Locked = true;
                }
                field(payToContactNumber; Rec."Pay-to Contact No.")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Contact No.', Locked = true;
                }
                field(responsibilityCenter; Rec."Responsibility Center")
                {
                    ApplicationArea = All;
                    Caption = 'Responsibility Center', Locked = true;
                }
                field(completelyReceived; Rec."Completely Received")
                {
                    ApplicationArea = All;
                    Caption = 'Completely Received', Locked = true;
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
                field(requestedReceiptDate; Rec."Requested Receipt Date")
                {
                    ApplicationArea = All;
                    Caption = 'Requested Receipt Date', Locked = true;
                }
                field(promisedReceiptDate; Rec."Promised Receipt Date")
                {
                    ApplicationArea = All;
                    Caption = 'Promised Receipt Date', Locked = true;
                }
                field(leadTimeCalculation; Rec."Lead Time Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'Lead Time Calculation', Locked = true;
                }
                field(inboundWhseHandlingTime; Rec."Inbound Whse. Handling Time")
                {
                    ApplicationArea = All;
                    Caption = 'Inbound Whse. Handling Time', Locked = true;
                }
                field(vendorAuthorizationNumber; Rec."Vendor Authorization No.")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Authorization No.', Locked = true;
                }
                field(returnShipmentNumber; Rec."Return Shipment No.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Shipment No.', Locked = true;
                }
                field(returnShipmentNumberSeries; Rec."Return Shipment No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Return Shipment No. Series', Locked = true;
                }
                field(ship; Rec.Ship)
                {
                    ApplicationArea = All;
                    Caption = 'Ship', Locked = true;
                }
                field(lastReturnShipmentNumber; Rec."Last Return Shipment No.")
                {
                    ApplicationArea = All;
                    Caption = 'Last Return Shipment No.', Locked = true;
                }
                field(assignedUserId; Rec."Assigned User ID")
                {
                    ApplicationArea = All;
                    Caption = 'Assigned User ID', Locked = true;
                }
                field(pendingApprovals; Rec."Pending Approvals")
                {
                    ApplicationArea = All;
                    Caption = 'Pending Approvals', Locked = true;
                }
                part(workflowPurchaseDocumentLines; "Purchase Document Line Entity")
                {
                    ApplicationArea = All;
                    Caption = 'Lines', Locked = true;
                    SubPageLink = "Document Type" = field("Document Type"),
                                  "Document No." = field("No.");
                    EntityName = 'puchaseDocumentLine';
                    EntitySetName = 'purchaseDocumentLines';
                }
            }
        }
    }

    actions
    {
    }
}


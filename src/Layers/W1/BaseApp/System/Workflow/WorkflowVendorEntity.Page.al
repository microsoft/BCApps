namespace System.Automation;

using Microsoft.Purchases.Vendor;

page 6410 "Workflow - Vendor Entity"
{
    Caption = 'workflowVendors', Locked = true;
    DelayedInsert = true;
    SourceTable = Vendor;
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
                field(number; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.', Locked = true;
                }
                field(name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name', Locked = true;
                }
                field(searchName; Rec."Search Name")
                {
                    ApplicationArea = All;
                    Caption = 'Search Name', Locked = true;
                }
                field(name2; Rec."Name 2")
                {
                    ApplicationArea = All;
                    Caption = 'Name 2', Locked = true;
                }
                field(address; Rec.Address)
                {
                    ApplicationArea = All;
                    Caption = 'Address', Locked = true;
                }
                field(address2; Rec."Address 2")
                {
                    ApplicationArea = All;
                    Caption = 'Address 2', Locked = true;
                }
                field(city; Rec.City)
                {
                    ApplicationArea = All;
                    Caption = 'City', Locked = true;
                }
                field(contact; Rec.Contact)
                {
                    ApplicationArea = All;
                    Caption = 'Contact', Locked = true;
                }
                field(phoneNumber; Rec."Phone No.")
                {
                    ApplicationArea = All;
                    Caption = 'Phone No.', Locked = true;
                }
                field(telexNumber; Rec."Telex No.")
                {
                    ApplicationArea = All;
                    Caption = 'Telex No.', Locked = true;
                }
                field(ourAccountNumber; Rec."Our Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'Our Account No.', Locked = true;
                }
                field(territoryCode; Rec."Territory Code")
                {
                    ApplicationArea = All;
                    Caption = 'Territory Code', Locked = true;
                }
                field(globalDimension1Code; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Global Dimension 1 Code', Locked = true;
                }
                field(globalDimension2Code; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Global Dimension 2 Code', Locked = true;
                }
                field(budgetedAmount; Rec."Budgeted Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Budgeted Amount', Locked = true;
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
                field(languageCode; Rec."Language Code")
                {
                    ApplicationArea = All;
                    Caption = 'Language Code', Locked = true;
                }
                field(statisticsGroup; Rec."Statistics Group")
                {
                    ApplicationArea = All;
                    Caption = 'Statistics Group', Locked = true;
                }
                field(paymentTermsCode; Rec."Payment Terms Code")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Terms Code', Locked = true;
                }
                field(finChargeTermsCode; Rec."Fin. Charge Terms Code")
                {
                    ApplicationArea = All;
                    Caption = 'Fin. Charge Terms Code', Locked = true;
                }
                field(purchaserCode; Rec."Purchaser Code")
                {
                    ApplicationArea = All;
                    Caption = 'Purchaser Code', Locked = true;
                }
                field(shipmentMethodCode; Rec."Shipment Method Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shipment Method Code', Locked = true;
                }
                field(shippingAgentCode; Rec."Shipping Agent Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping Agent Code', Locked = true;
                }
                field(invoiceDiscCode; Rec."Invoice Disc. Code")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice Disc. Code', Locked = true;
                }
                field(countryRegionCode; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Country/Region Code', Locked = true;
                }
                field(comment; Rec.Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comment', Locked = true;
                }
                field(blocked; Rec.Blocked)
                {
                    ApplicationArea = All;
                    Caption = 'Blocked', Locked = true;
                }
                field(payToVendorNumber; Rec."Pay-to Vendor No.")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Vendor No.', Locked = true;
                }
                field(priority; Rec.Priority)
                {
                    ApplicationArea = All;
                    Caption = 'Priority', Locked = true;
                }
                field(paymentMethodCode; Rec."Payment Method Code")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Method Code', Locked = true;
                }
                field(lastModifiedDateTime; Rec."Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'Last Modified Date Time', Locked = true;
                }
                field(lastDateModified; Rec."Last Date Modified")
                {
                    ApplicationArea = All;
                    Caption = 'Last Date Modified', Locked = true;
                }
                field(dateFilter; Rec."Date Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Date Filter', Locked = true;
                }
                field(globalDimension1Filter; Rec."Global Dimension 1 Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Global Dimension 1 Filter', Locked = true;
                }
                field(globalDimension2Filter; Rec."Global Dimension 2 Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Global Dimension 2 Filter', Locked = true;
                }
                field(balance; Rec.Balance)
                {
                    ApplicationArea = All;
                    Caption = 'Balance', Locked = true;
                }
                field(balanceLcy; Rec."Balance (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Balance (LCY)', Locked = true;
                }
                field(netChange; Rec."Net Change")
                {
                    ApplicationArea = All;
                    Caption = 'Net Change', Locked = true;
                }
                field(netChangeLcy; Rec."Net Change (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Net Change (LCY)', Locked = true;
                }
                field(purchasesLcy; Rec."Purchases (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Purchases (LCY)', Locked = true;
                }
                field(invDiscountsLcy; Rec."Inv. Discounts (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Inv. Discounts (LCY)', Locked = true;
                }
                field(pmtDiscountsLcy; Rec."Pmt. Discounts (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Pmt. Discounts (LCY)', Locked = true;
                }
                field(balanceDue; Rec."Balance Due")
                {
                    ApplicationArea = All;
                    Caption = 'Balance Due', Locked = true;
                }
                field(balanceDueLcy; Rec."Balance Due (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Balance Due (LCY)', Locked = true;
                }
                field(payments; Rec.Payments)
                {
                    ApplicationArea = All;
                    Caption = 'Payments', Locked = true;
                }
                field(invoiceAmounts; Rec."Invoice Amounts")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice Amounts', Locked = true;
                }
                field(crMemoAmounts; Rec."Cr. Memo Amounts")
                {
                    ApplicationArea = All;
                    Caption = 'Cr. Memo Amounts', Locked = true;
                }
                field(financeChargeMemoAmounts; Rec."Finance Charge Memo Amounts")
                {
                    ApplicationArea = All;
                    Caption = 'Finance Charge Memo Amounts', Locked = true;
                }
                field(paymentsLcy; Rec."Payments (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Payments (LCY)', Locked = true;
                }
                field(invAmountsLcy; Rec."Inv. Amounts (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Inv. Amounts (LCY)', Locked = true;
                }
                field(crMemoAmountsLcy; Rec."Cr. Memo Amounts (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Cr. Memo Amounts (LCY)', Locked = true;
                }
                field(finChargeMemoAmountsLcy; Rec."Fin. Charge Memo Amounts (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Fin. Charge Memo Amounts (LCY)', Locked = true;
                }
                field(outstandingOrders; Rec."Outstanding Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Orders', Locked = true;
                }
                field(amtRcdNotInvoiced; Rec."Amt. Rcd. Not Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Amt. Rcd. Not Invoiced', Locked = true;
                }
                field(applicationMethod; Rec."Application Method")
                {
                    ApplicationArea = All;
                    Caption = 'Application Method', Locked = true;
                }
                field(pricesIncludingVat; Rec."Prices Including VAT")
                {
                    ApplicationArea = All;
                    Caption = 'Prices Including VAT', Locked = true;
                }
                field(faxNumber; Rec."Fax No.")
                {
                    ApplicationArea = All;
                    Caption = 'Fax No.', Locked = true;
                }
                field(telexAnswerBack; Rec."Telex Answer Back")
                {
                    ApplicationArea = All;
                    Caption = 'Telex Answer Back', Locked = true;
                }
                field(vatRegistrationNumber; Rec."VAT Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Registration No.', Locked = true;
                }
                field(genBusPostingGroup; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Gen. Bus. Posting Group', Locked = true;
                }
                field(gln; Rec.GLN)
                {
                    ApplicationArea = All;
                    Caption = 'GLN', Locked = true;
                }
                field(postCode; Rec."Post Code")
                {
                    ApplicationArea = All;
                    Caption = 'Post Code', Locked = true;
                }
                field(county; Rec.County)
                {
                    ApplicationArea = All;
                    Caption = 'County', Locked = true;
                }
                field(debitAmount; Rec."Debit Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Debit Amount', Locked = true;
                }
                field(creditAmount; Rec."Credit Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Credit Amount', Locked = true;
                }
                field(debitAmountLcy; Rec."Debit Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Debit Amount (LCY)', Locked = true;
                }
                field(creditAmountLcy; Rec."Credit Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Credit Amount (LCY)', Locked = true;
                }
                field(eMail; Rec."E-Mail")
                {
                    ApplicationArea = All;
                    Caption = 'E-Mail', Locked = true;
                }
                field(homePage; Rec."Home Page")
                {
                    ApplicationArea = All;
                    Caption = 'Home Page', Locked = true;
                }
                field(reminderAmounts; Rec."Reminder Amounts")
                {
                    ApplicationArea = All;
                    Caption = 'Reminder Amounts', Locked = true;
                }
                field(reminderAmountsLcy; Rec."Reminder Amounts (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Reminder Amounts (LCY)', Locked = true;
                }
                field(numberSeries; Rec."No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'No. Series', Locked = true;
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
                field(currencyFilter; Rec."Currency Filter")
                {
                    ApplicationArea = All;
                    Caption = 'Currency Filter', Locked = true;
                }
                field(outstandingOrdersLcy; Rec."Outstanding Orders (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Orders (LCY)', Locked = true;
                }
                field(amtRcdNotInvoicedLcy; Rec."Amt. Rcd. Not Invoiced (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Amt. Rcd. Not Invoiced (LCY)', Locked = true;
                }
                field(blockPaymentTolerance; Rec."Block Payment Tolerance")
                {
                    ApplicationArea = All;
                    Caption = 'Block Payment Tolerance', Locked = true;
                }
                field(pmtDiscToleranceLcy; Rec."Pmt. Disc. Tolerance (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Pmt. Disc. Tolerance (LCY)', Locked = true;
                }
                field(pmtToleranceLcy; Rec."Pmt. Tolerance (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Pmt. Tolerance (LCY)', Locked = true;
                }
                field(icPartnerCode; Rec."IC Partner Code")
                {
                    ApplicationArea = All;
                    Caption = 'IC Partner Code', Locked = true;
                }
                field(refunds; Rec.Refunds)
                {
                    ApplicationArea = All;
                    Caption = 'Refunds', Locked = true;
                }
                field(refundsLcy; Rec."Refunds (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Refunds (LCY)', Locked = true;
                }
                field(otherAmounts; Rec."Other Amounts")
                {
                    ApplicationArea = All;
                    Caption = 'Other Amounts', Locked = true;
                }
                field(otherAmountsLcy; Rec."Other Amounts (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Other Amounts (LCY)', Locked = true;
                }
                field(prepaymentPercent; Rec."Prepayment %")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment %', Locked = true;
                }
                field(outstandingInvoices; Rec."Outstanding Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Invoices', Locked = true;
                }
                field(outstandingInvoicesLcy; Rec."Outstanding Invoices (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Invoices (LCY)', Locked = true;
                }
                field(payToNumberOfArchivedDoc; Rec."Pay-to No. Of Archived Doc.")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. Of Archived Doc.', Locked = true;
                }
                field(buyFromNumberOfArchivedDoc; Rec."Buy-from No. Of Archived Doc.")
                {
                    ApplicationArea = All;
                    Caption = 'Buy-from No. Of Archived Doc.', Locked = true;
                }
                field(partnerType; Rec."Partner Type")
                {
                    ApplicationArea = All;
                    Caption = 'Partner Type', Locked = true;
                }
                field(image; Rec.Image)
                {
                    ApplicationArea = All;
                    Caption = 'Image', Locked = true;
                }
                field(creditorNumber; Rec."Creditor No.")
                {
                    ApplicationArea = All;
                    Caption = 'Creditor No.', Locked = true;
                }
                field(preferredBankAccountCode; Rec."Preferred Bank Account Code")
                {
                    ApplicationArea = All;
                    Caption = 'Preferred Bank Account Code', Locked = true;
                }
                field(cashFlowPaymentTermsCode; Rec."Cash Flow Payment Terms Code")
                {
                    ApplicationArea = All;
                    Caption = 'Cash Flow Payment Terms Code', Locked = true;
                }
                field(primaryContactNumber; Rec."Primary Contact No.")
                {
                    ApplicationArea = All;
                    Caption = 'Primary Contact No.', Locked = true;
                }
                field(responsibilityCenter; Rec."Responsibility Center")
                {
                    ApplicationArea = All;
                    Caption = 'Responsibility Center', Locked = true;
                }
                field(locationCode; Rec."Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'Location Code', Locked = true;
                }
                field(leadTimeCalculation; Rec."Lead Time Calculation")
                {
                    ApplicationArea = All;
                    Caption = 'Lead Time Calculation', Locked = true;
                }
                field(numberOfPstdReceipts; Rec."No. of Pstd. Receipts")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Pstd. Receipts', Locked = true;
                }
                field(numberOfPstdInvoices; Rec."No. of Pstd. Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Pstd. Invoices', Locked = true;
                }
                field(numberOfPstdReturnShipments; Rec."No. of Pstd. Return Shipments")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Pstd. Return Shipments', Locked = true;
                }
                field(numberOfPstdCreditMemos; Rec."No. of Pstd. Credit Memos")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Pstd. Credit Memos', Locked = true;
                }
                field(payToNumberOfOrders; Rec."Pay-to No. of Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Orders', Locked = true;
                }
                field(payToNumberOfInvoices; Rec."Pay-to No. of Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Invoices', Locked = true;
                }
                field(payToNumberOfReturnOrders; Rec."Pay-to No. of Return Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Return Orders', Locked = true;
                }
                field(payToNumberOfCreditMemos; Rec."Pay-to No. of Credit Memos")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Credit Memos', Locked = true;
                }
                field(payToNumberOfPstdReceipts; Rec."Pay-to No. of Pstd. Receipts")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Pstd. Receipts', Locked = true;
                }
                field(payToNumberOfPstdInvoices; Rec."Pay-to No. of Pstd. Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Pstd. Invoices', Locked = true;
                }
                field(payToNumberOfPstdReturnS; Rec."Pay-to No. of Pstd. Return S.")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Pstd. Return S.', Locked = true;
                }
                field(payToNumberOfPstdCrMemos; Rec."Pay-to No. of Pstd. Cr. Memos")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Pstd. Cr. Memos', Locked = true;
                }
                field(numberOfQuotes; Rec."No. of Quotes")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Quotes', Locked = true;
                }
                field(numberOfBlanketOrders; Rec."No. of Blanket Orders")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Blanket Orders', Locked = true;
                }
                field(numberOfOrders; Rec."No. of Orders")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Orders', Locked = true;
                }
                field(numberOfInvoices; Rec."No. of Invoices")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Invoices', Locked = true;
                }
                field(numberOfReturnOrders; Rec."No. of Return Orders")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Return Orders', Locked = true;
                }
                field(numberOfCreditMemos; Rec."No. of Credit Memos")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Credit Memos', Locked = true;
                }
                field(numberOfOrderAddresses; Rec."No. of Order Addresses")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Order Addresses', Locked = true;
                }
                field(payToNumberOfQuotes; Rec."Pay-to No. of Quotes")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Quotes', Locked = true;
                }
                field(payToNumberOfBlanketOrders; Rec."Pay-to No. of Blanket Orders")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to No. of Blanket Orders', Locked = true;
                }
                field(numberOfIncomingDocuments; Rec."No. of Incoming Documents")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Incoming Documents', Locked = true;
                }
                field(baseCalendarCode; Rec."Base Calendar Code")
                {
                    ApplicationArea = All;
                    Caption = 'Base Calendar Code', Locked = true;
                }
                field(documentSendingProfile; Rec."Document Sending Profile")
                {
                    ApplicationArea = All;
                    Caption = 'Document Sending Profile', Locked = true;
                }
                field(validateEuVatRegNumber; Rec."Validate EU Vat Reg. No.")
                {
                    ApplicationArea = All;
                    Caption = 'Validate EU Vat Reg. No.', Locked = true;
                }
                field(copyBuyFromAddToQteFrom; Rec."Copy Buy-from Add. to Qte From")
                {
                    ApplicationArea = All;
                    Caption = 'Copy Buy-from Addr. to Qte From', Locked = true;
                }
                field(currencyId; Rec."Currency Id")
                {
                    ApplicationArea = All;
                    Caption = 'Currency Id', Locked = true;
                }
                field(paymentTermsId; Rec."Payment Terms Id")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Terms Id', Locked = true;
                }
                field(paymentMethodId; Rec."Payment Method Id")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Method Id', Locked = true;
                }
            }
        }
    }

    actions
    {
    }
}


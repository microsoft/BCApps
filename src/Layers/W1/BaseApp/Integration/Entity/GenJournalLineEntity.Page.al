// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Finance.GeneralLedger.Journal;

page 6407 "Gen. Journal Line Entity"
{
    Caption = 'workflowGenJournalLines', Locked = true;
    DelayedInsert = true;
    ODataKeyFields = SystemId;
    PageType = List;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(journalTemplateName; Rec."Journal Template Name")
                {
                    ApplicationArea = All;
                    Caption = 'Journal Template Name', Locked = true;
                }
                field(lineNumber; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Line No.', Locked = true;
                }
                field(accountType; Rec."Account Type")
                {
                    ApplicationArea = All;
                    Caption = 'Account Type', Locked = true;
                }
                field(accountNumber; Rec."Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'Account No.', Locked = true;
                }
                field(postingDate; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Date', Locked = true;
                }
                field(documentType; Rec."Document Type")
                {
                    ApplicationArea = All;
                    Caption = 'Document Type', Locked = true;
                }
                field(documentNumber; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Document No.', Locked = true;
                }
                field(description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description', Locked = true;
                }
                field(vatPercent; Rec."VAT %")
                {
                    ApplicationArea = All;
                    Caption = 'VAT %', Locked = true;
                }
                field(balAccountNumber; Rec."Bal. Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Account No.', Locked = true;
                }
                field(currencyCode; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Caption = 'Currency Code', Locked = true;
                }
                field(amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    Caption = 'Amount', Locked = true;
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
                field(amountLcy; Rec."Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Amount (LCY)', Locked = true;
                }
                field(balanceLcy; Rec."Balance (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Balance (LCY)', Locked = true;
                }
                field(currencyFactor; Rec."Currency Factor")
                {
                    ApplicationArea = All;
                    Caption = 'Currency Factor', Locked = true;
                }
                field(salesPurchLcy; Rec."Sales/Purch. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Sales/Purch. (LCY)', Locked = true;
                }
                field(profitLcy; Rec."Profit (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Profit (LCY)', Locked = true;
                }
                field(invDiscountLcy; Rec."Inv. Discount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Inv. Discount (LCY)', Locked = true;
                }
                field(billToPayToNumber; Rec."Bill-to/Pay-to No.")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to/Pay-to No.', Locked = true;
                }
                field(postingGroup; Rec."Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Group', Locked = true;
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
                field(salespersPurchCode; Rec."Salespers./Purch. Code")
                {
                    ApplicationArea = All;
                    Caption = 'Salespers./Purch. Code', Locked = true;
                }
                field(sourceCode; Rec."Source Code")
                {
                    ApplicationArea = All;
                    Caption = 'Source Code', Locked = true;
                }
                field(systemCreatedEntry; Rec."System-Created Entry")
                {
                    ApplicationArea = All;
                    Caption = 'System-Created Entry', Locked = true;
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
                field(dueDate; Rec."Due Date")
                {
                    ApplicationArea = All;
                    Caption = 'Due Date', Locked = true;
                }
                field(pmtDiscountDate; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = All;
                    Caption = 'Pmt. Discount Date', Locked = true;
                }
                field(paymentDiscountPercent; Rec."Payment Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Discount %', Locked = true;
                }
                field(jobNumber; Rec."Job No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job No.', Locked = true;
                }
                field(quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity', Locked = true;
                }
                field(vatAmount; Rec."VAT Amount")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Amount', Locked = true;
                }
                field(vatPosting; Rec."VAT Posting")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Posting', Locked = true;
                }
                field(paymentTermsCode; Rec."Payment Terms Code")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Terms Code', Locked = true;
                }
                field(appliesToId; Rec."Applies-to ID")
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to ID', Locked = true;
                }
                field(businessUnitCode; Rec."Business Unit Code")
                {
                    ApplicationArea = All;
                    Caption = 'Business Unit Code', Locked = true;
                }
                field(journalBatchName; Rec."Journal Batch Name")
                {
                    ApplicationArea = All;
                    Caption = 'Journal Batch Name', Locked = true;
                }
                field(reasonCode; Rec."Reason Code")
                {
                    ApplicationArea = All;
                    Caption = 'Reason Code', Locked = true;
                }
                field(recurringMethod; Rec."Recurring Method")
                {
                    ApplicationArea = All;
                    Caption = 'Recurring Method', Locked = true;
                }
                field(expirationDate; Rec."Expiration Date")
                {
                    ApplicationArea = All;
                    Caption = 'Expiration Date', Locked = true;
                }
                field(recurringFrequency; Rec."Recurring Frequency")
                {
                    ApplicationArea = All;
                    Caption = 'Recurring Frequency', Locked = true;
                }
                field(allocatedAmtLcy; Rec."Allocated Amt. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Allocated Amt. (LCY)', Locked = true;
                }
                field(genPostingType; Rec."Gen. Posting Type")
                {
                    ApplicationArea = All;
                    Caption = 'Gen. Posting Type', Locked = true;
                }
                field(genBusPostingGroup; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Gen. Bus. Posting Group', Locked = true;
                }
                field(genProdPostingGroup; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Gen. Prod. Posting Group', Locked = true;
                }
                field(vatCalculationType; Rec."VAT Calculation Type")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Calculation Type', Locked = true;
                }
                field(eu3PartyTrade; Rec."EU 3-Party Trade")
                {
                    ApplicationArea = All;
                    Caption = 'EU 3-Party Trade', Locked = true;
                }
                field(allowApplication; Rec."Allow Application")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Application', Locked = true;
                }
                field(balAccountType; Rec."Bal. Account Type")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Account Type', Locked = true;
                }
                field(balGenPostingType; Rec."Bal. Gen. Posting Type")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Gen. Posting Type', Locked = true;
                }
                field(balGenBusPostingGroup; Rec."Bal. Gen. Bus. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Gen. Bus. Posting Group', Locked = true;
                }
                field(balGenProdPostingGroup; Rec."Bal. Gen. Prod. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Gen. Prod. Posting Group', Locked = true;
                }
                field(balVatCalculationType; Rec."Bal. VAT Calculation Type")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT Calculation Type', Locked = true;
                }
                field(balVatPercent; Rec."Bal. VAT %")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT %', Locked = true;
                }
                field(balVatAmount; Rec."Bal. VAT Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT Amount', Locked = true;
                }
                field(bankPaymentType; Rec."Bank Payment Type")
                {
                    ApplicationArea = All;
                    Caption = 'Bank Payment Type', Locked = true;
                }
                field(vatBaseAmount; Rec."VAT Base Amount")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Base Amount', Locked = true;
                }
                field(balVatBaseAmount; Rec."Bal. VAT Base Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT Base Amount', Locked = true;
                }
                field(correction; Rec.Correction)
                {
                    ApplicationArea = All;
                    Caption = 'Correction', Locked = true;
                }
                field(checkPrinted; Rec."Check Printed")
                {
                    ApplicationArea = All;
                    Caption = 'Check Printed', Locked = true;
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
                field(sourceType; Rec."Source Type")
                {
                    ApplicationArea = All;
                    Caption = 'Source Type', Locked = true;
                }
                field(sourceNumber; Rec."Source No.")
                {
                    ApplicationArea = All;
                    Caption = 'Source No.', Locked = true;
                }
                field(postingNumberSeries; Rec."Posting No. Series")
                {
                    ApplicationArea = All;
                    Caption = 'Posting No. Series', Locked = true;
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
                field(taxGroupCode; Rec."Tax Group Code")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Group Code', Locked = true;
                }
                field(useTax; Rec."Use Tax")
                {
                    ApplicationArea = All;
                    Caption = 'Use Tax', Locked = true;
                }
                field(balTaxAreaCode; Rec."Bal. Tax Area Code")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Tax Area Code', Locked = true;
                }
                field(balTaxLiable; Rec."Bal. Tax Liable")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Tax Liable', Locked = true;
                }
                field(balTaxGroupCode; Rec."Bal. Tax Group Code")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Tax Group Code', Locked = true;
                }
                field(balUseTax; Rec."Bal. Use Tax")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. Use Tax', Locked = true;
                }
                field(vatBusPostingGroup; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Bus. Posting Group', Locked = true;
                }
                field(vatProdPostingGroup; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Prod. Posting Group', Locked = true;
                }
                field(balVatBusPostingGroup; Rec."Bal. VAT Bus. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT Bus. Posting Group', Locked = true;
                }
                field(balVatProdPostingGroup; Rec."Bal. VAT Prod. Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT Prod. Posting Group', Locked = true;
                }
                field(additionalCurrencyPosting; Rec."Additional-Currency Posting")
                {
                    ApplicationArea = All;
                    Caption = 'Additional-Currency Posting', Locked = true;
                }
                field(faAddCurrencyFactor; Rec."FA Add.-Currency Factor")
                {
                    ApplicationArea = All;
                    Caption = 'FA Add.-Currency Factor', Locked = true;
                }
                field(sourceCurrencyCode; Rec."Source Currency Code")
                {
                    ApplicationArea = All;
                    Caption = 'Source Currency Code', Locked = true;
                }
                field(sourceCurrencyAmount; Rec."Source Currency Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Source Currency Amount', Locked = true;
                }
                field(sourceCurrVatBaseAmount; Rec."Source Curr. VAT Base Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Source Curr. VAT Base Amount', Locked = true;
                }
                field(sourceCurrVatAmount; Rec."Source Curr. VAT Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Source Curr. VAT Amount', Locked = true;
                }
                field(vatBaseDiscountPercent; Rec."VAT Base Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Base Discount %', Locked = true;
                }
                field(vatAmountLcy; Rec."VAT Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Amount (LCY)', Locked = true;
                }
                field(vatBaseAmountLcy; Rec."VAT Base Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Base Amount (LCY)', Locked = true;
                }
                field(balVatAmountLcy; Rec."Bal. VAT Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT Amount (LCY)', Locked = true;
                }
                field(balVatBaseAmountLcy; Rec."Bal. VAT Base Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT Base Amount (LCY)', Locked = true;
                }
                field(reversingEntry; Rec."Reversing Entry")
                {
                    ApplicationArea = All;
                    Caption = 'Reversing Entry', Locked = true;
                }
                field(allowZeroAmountPosting; Rec."Allow Zero-Amount Posting")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Zero-Amount Posting', Locked = true;
                }
                field(shipToOrderAddressCode; Rec."Ship-to/Order Address Code")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to/Order Address Code', Locked = true;
                }
                field(vatDifference; Rec."VAT Difference")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Difference', Locked = true;
                }
                field(balVatDifference; Rec."Bal. VAT Difference")
                {
                    ApplicationArea = All;
                    Caption = 'Bal. VAT Difference', Locked = true;
                }
                field(icPartnerCode; Rec."IC Partner Code")
                {
                    ApplicationArea = All;
                    Caption = 'IC Partner Code', Locked = true;
                }
                field(icDirection; Rec."IC Direction")
                {
                    ApplicationArea = All;
                    Caption = 'IC Direction', Locked = true;
                }
                field(icPartnerTransactionNumber; Rec."IC Partner Transaction No.")
                {
                    ApplicationArea = All;
                    Caption = 'IC Partner Transaction No.', Locked = true;
                }
                field(icAccountType; Rec."IC Account Type")
                {
                    ApplicationArea = All;
                    Caption = 'IC Account Type', Locked = true;
                    ToolTip = 'Specifies the type of the account that you want to use for the transaction with your IC partner.';
                }
                field(icAccountNo; Rec."IC Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'IC Account No.', Locked = true;
                    ToolTip = 'Specifies the number of the general ledger or bank account that the IC transaction is posted to.';
                }
                field(sellToBuyFromNumber; Rec."Sell-to/Buy-from No.")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to/Buy-from No.', Locked = true;
                }
                field(vatRegistrationNumber; Rec."VAT Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Registration No.', Locked = true;
                }
                field(countryRegionCode; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    Caption = 'Country/Region Code', Locked = true;
                }
                field(prepayment; Rec.Prepayment)
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment', Locked = true;
                }
                field(financialVoid; Rec."Financial Void")
                {
                    ApplicationArea = All;
                    Caption = 'Financial Void', Locked = true;
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
                field(paymentMethodCode; Rec."Payment Method Code")
                {
                    ApplicationArea = All;
                    Caption = 'Payment Method Code', Locked = true;
                }
                field(appliesToExtDocNumber; Rec."Applies-to Ext. Doc. No.")
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to Ext. Doc. No.', Locked = true;
                }
                field(recipientBankAccount; Rec."Recipient Bank Account")
                {
                    ApplicationArea = All;
                    Caption = 'Recipient Bank Account', Locked = true;
                }
                field(messageToRecipient; Rec."Message to Recipient")
                {
                    ApplicationArea = All;
                    Caption = 'Message to Recipient', Locked = true;
                }
                field(exportedToPaymentFile; Rec."Exported to Payment File")
                {
                    ApplicationArea = All;
                    Caption = 'Exported to Payment File', Locked = true;
                }
                field(hasPaymentExportError; Rec."Has Payment Export Error")
                {
                    ApplicationArea = All;
                    Caption = 'Has Payment Export Error', Locked = true;
                }
                field(dimensionSetId; Rec."Dimension Set ID")
                {
                    ApplicationArea = All;
                    Caption = 'Dimension Set ID', Locked = true;
                }
                field(jobTaskNumber; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job Task No.', Locked = true;
                }
                field(jobUnitPriceLcy; Rec."Job Unit Price (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Unit Price (LCY)', Locked = true;
                }
                field(jobTotalPriceLcy; Rec."Job Total Price (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Total Price (LCY)', Locked = true;
                }
                field(jobQuantity; Rec."Job Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Job Quantity', Locked = true;
                }
                field(jobUnitCostLcy; Rec."Job Unit Cost (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Unit Cost (LCY)', Locked = true;
                }
                field(jobLineDiscountPercent; Rec."Job Line Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Discount %', Locked = true;
                }
                field(jobLineDiscAmountLcy; Rec."Job Line Disc. Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Disc. Amount (LCY)', Locked = true;
                }
                field(jobUnitOfMeasureCode; Rec."Job Unit Of Measure Code")
                {
                    ApplicationArea = All;
                    Caption = 'Job Unit Of Measure Code', Locked = true;
                }
                field(jobLineType; Rec."Job Line Type")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Type', Locked = true;
                }
                field(jobUnitPrice; Rec."Job Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'Job Unit Price', Locked = true;
                }
                field(jobTotalPrice; Rec."Job Total Price")
                {
                    ApplicationArea = All;
                    Caption = 'Job Total Price', Locked = true;
                }
                field(jobUnitCost; Rec."Job Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Job Unit Cost', Locked = true;
                }
                field(jobTotalCost; Rec."Job Total Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Job Total Cost', Locked = true;
                }
                field(jobLineDiscountAmount; Rec."Job Line Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Discount Amount', Locked = true;
                }
                field(jobLineAmount; Rec."Job Line Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Amount', Locked = true;
                }
                field(jobTotalCostLcy; Rec."Job Total Cost (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Total Cost (LCY)', Locked = true;
                }
                field(jobLineAmountLcy; Rec."Job Line Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Amount (LCY)', Locked = true;
                }
                field(jobCurrencyFactor; Rec."Job Currency Factor")
                {
                    ApplicationArea = All;
                    Caption = 'Job Currency Factor', Locked = true;
                }
                field(jobCurrencyCode; Rec."Job Currency Code")
                {
                    ApplicationArea = All;
                    Caption = 'Job Currency Code', Locked = true;
                }
                field(jobPlanningLineNumber; Rec."Job Planning Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job Planning Line No.', Locked = true;
                }
                field(jobRemainingQty; Rec."Job Remaining Qty.")
                {
                    ApplicationArea = All;
                    Caption = 'Job Remaining Qty.', Locked = true;
                }
                field(directDebitMandateId; Rec."Direct Debit Mandate ID")
                {
                    ApplicationArea = All;
                    Caption = 'Direct Debit Mandate ID', Locked = true;
                }
                field(dataExchEntryNumber; Rec."Data Exch. Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Data Exch. Entry No.', Locked = true;
                }
                field(payerInformation; Rec."Payer Information")
                {
                    ApplicationArea = All;
                    Caption = 'Payer Information', Locked = true;
                }
                field(transactionInformation; Rec."Transaction Information")
                {
                    ApplicationArea = All;
                    Caption = 'Transaction Information', Locked = true;
                }
                field(dataExchLineNumber; Rec."Data Exch. Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Data Exch. Line No.', Locked = true;
                }
                field(appliedAutomatically; Rec."Applied Automatically")
                {
                    ApplicationArea = All;
                    Caption = 'Applied Automatically', Locked = true;
                }
                field(deferralCode; Rec."Deferral Code")
                {
                    ApplicationArea = All;
                    Caption = 'Deferral Code', Locked = true;
                }
                field(deferralLineNumber; Rec."Deferral Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Deferral Line No.', Locked = true;
                }
                field(campaignNumber; Rec."Campaign No.")
                {
                    ApplicationArea = All;
                    Caption = 'Campaign No.', Locked = true;
                }
                field(prodOrderNumber; Rec."Prod. Order No.")
                {
                    ApplicationArea = All;
                    Caption = 'Prod. Order No.', Locked = true;
                }
                field(faPostingDate; Rec."FA Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'FA Posting Date', Locked = true;
                }
                field(faPostingType; Rec."FA Posting Type")
                {
                    ApplicationArea = All;
                    Caption = 'FA Posting Type', Locked = true;
                }
                field(depreciationBookCode; Rec."Depreciation Book Code")
                {
                    ApplicationArea = All;
                    Caption = 'Depreciation Book Code', Locked = true;
                }
                field(salvageValue; Rec."Salvage Value")
                {
                    ApplicationArea = All;
                    Caption = 'Salvage Value', Locked = true;
                }
                field(numberOfDepreciationDays; Rec."No. of Depreciation Days")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Depreciation Days', Locked = true;
                }
                field(deprUntilFaPostingDate; Rec."Depr. until FA Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Depr. until FA Posting Date', Locked = true;
                }
                field(deprAcquisitionCost; Rec."Depr. Acquisition Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Depr. Acquisition Cost', Locked = true;
                }
                field(maintenanceCode; Rec."Maintenance Code")
                {
                    ApplicationArea = All;
                    Caption = 'Maintenance Code', Locked = true;
                }
                field(insuranceNumber; Rec."Insurance No.")
                {
                    ApplicationArea = All;
                    Caption = 'Insurance No.', Locked = true;
                }
                field(budgetedFaNumber; Rec."Budgeted FA No.")
                {
                    ApplicationArea = All;
                    Caption = 'Budgeted FA No.', Locked = true;
                }
                field(duplicateInDepreciationBook; Rec."Duplicate in Depreciation Book")
                {
                    ApplicationArea = All;
                    Caption = 'Duplicate in Depreciation Book', Locked = true;
                }
                field(useDuplicationList; Rec."Use Duplication List")
                {
                    ApplicationArea = All;
                    Caption = 'Use Duplication List', Locked = true;
                }
                field(faReclassificationEntry; Rec."FA Reclassification Entry")
                {
                    ApplicationArea = All;
                    Caption = 'FA Reclassification Entry', Locked = true;
                }
                field(faErrorEntryNumber; Rec."FA Error Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'FA Error Entry No.', Locked = true;
                }
                field(indexEntry; Rec."Index Entry")
                {
                    ApplicationArea = All;
                    Caption = 'Index Entry', Locked = true;
                }
                field(sourceLineNumber; Rec."Source Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Source Line No.', Locked = true;
                }
                field(comment; Rec.Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comment', Locked = true;
                }
                field(checkExported; Rec."Check Exported")
                {
                    ApplicationArea = All;
                    Caption = 'Check Exported', Locked = true;
                }
                field(checkTransmitted; Rec."Check Transmitted")
                {
                    ApplicationArea = All;
                    Caption = 'Check Transmitted', Locked = true;
                }
                field(id; Rec.SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'Id', Locked = true;
                }
                field(accountId; Rec."Account Id")
                {
                    ApplicationArea = All;
                    Caption = 'Account Id', Locked = true;
                }
                field(customerId; Rec."Customer Id")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Id', Locked = true;
                }
                field(appliesToInvoiceId; Rec."Applies-to Invoice Id")
                {
                    ApplicationArea = All;
                    Caption = 'Applies-to Invoice Id', Locked = true;
                }
                field(contactGraphId; Rec."Contact Graph Id")
                {
                    ApplicationArea = All;
                    Caption = 'Contact Graph Id', Locked = true;
                }
                field(lastModifiedDatetime; Rec."Last Modified DateTime")
                {
                    ApplicationArea = All;
                    Caption = 'Last Modified DateTime', Locked = true;
                }
                field(journalBatchId; Rec."Journal Batch Id")
                {
                    ApplicationArea = All;
                    Caption = 'Journal Batch Id', Locked = true;
                }
            }
        }
    }

    actions
    {
    }
}


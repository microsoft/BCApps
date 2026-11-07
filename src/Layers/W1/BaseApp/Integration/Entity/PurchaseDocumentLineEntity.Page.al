// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Foundation.ExtendedText;
using Microsoft.Purchases.Document;

page 6405 "Purchase Document Line Entity"
{
    Caption = 'Purchase Document Line Entity', Locked = true;
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Purchase Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
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
                field(documentNumber; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Document No.', Locked = true;
                }
                field(lineNumber; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Line No.', Locked = true;
                }
                field(type; Rec.Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type', Locked = true;
                }
                field(number; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.', Locked = true;

                    trigger OnValidate()
                    begin
                        EntityChanged := true;
                    end;
                }
                field(locationCode; Rec."Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'Location Code', Locked = true;
                }
                field(postingGroup; Rec."Posting Group")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Group', Locked = true;
                }
                field(expectedReceiptDate; Rec."Expected Receipt Date")
                {
                    ApplicationArea = All;
                    Caption = 'Expected Receipt Date', Locked = true;
                }
                field(description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description', Locked = true;
                }
                field(description2; Rec."Description 2")
                {
                    ApplicationArea = All;
                    Caption = 'Description 2', Locked = true;
                }
                field(unitOfMeasure; Rec."Unit of Measure")
                {
                    ApplicationArea = All;
                    Caption = 'Unit of Measure', Locked = true;
                }
                field(quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity', Locked = true;
                }
                field(outstandingQuantity; Rec."Outstanding Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Quantity', Locked = true;
                }
                field(qtyToInvoice; Rec."Qty. to Invoice")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Invoice', Locked = true;
                }
                field(qtyToReceive; Rec."Qty. to Receive")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Receive', Locked = true;
                }
                field(directUnitCost; Rec."Direct Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Direct Unit Cost', Locked = true;
                }
                field(unitCostLcy; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Cost (LCY)', Locked = true;
                }
                field(vatPercent; Rec."VAT %")
                {
                    ApplicationArea = All;
                    Caption = 'VAT %', Locked = true;
                }
                field(lineDiscountPercent; Rec."Line Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'Line Discount %', Locked = true;
                }
                field(lineDiscountAmount; Rec."Line Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Line Discount Amount', Locked = true;
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
                field(unitPriceLcy; Rec."Unit Price (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Price (LCY)', Locked = true;
                }
                field(allowInvoiceDisc; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Invoice Disc.', Locked = true;
                }
                field(grossWeight; Rec."Gross Weight")
                {
                    ApplicationArea = All;
                    Caption = 'Gross Weight', Locked = true;
                }
                field(netWeight; Rec."Net Weight")
                {
                    ApplicationArea = All;
                    Caption = 'Net Weight', Locked = true;
                }
                field(unitsPerParcel; Rec."Units per Parcel")
                {
                    ApplicationArea = All;
                    Caption = 'Units per Parcel', Locked = true;
                }
                field(unitVolume; Rec."Unit Volume")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Volume', Locked = true;
                }
                field(applToItemEntry; Rec."Appl.-to Item Entry")
                {
                    ApplicationArea = All;
                    Caption = 'Appl.-to Item Entry', Locked = true;
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
                field(jobNumber; Rec."Job No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job No.', Locked = true;
                }
                field(indirectCostPercent; Rec."Indirect Cost %")
                {
                    ApplicationArea = All;
                    Caption = 'Indirect Cost %', Locked = true;
                }
                field(recalculateInvoiceDisc; Rec."Recalculate Invoice Disc.")
                {
                    ApplicationArea = All;
                    Caption = 'Recalculate Invoice Disc.', Locked = true;
                }
                field(outstandingAmount; Rec."Outstanding Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Amount', Locked = true;
                }
                field(qtyRcdNotInvoiced; Rec."Qty. Rcd. Not Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Rcd. Not Invoiced', Locked = true;
                }
                field(amtRcdNotInvoiced; Rec."Amt. Rcd. Not Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Amt. Rcd. Not Invoiced', Locked = true;
                }
                field(quantityReceived; Rec."Quantity Received")
                {
                    ApplicationArea = All;
                    Caption = 'Quantity Received', Locked = true;
                }
                field(quantityInvoiced; Rec."Quantity Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Quantity Invoiced', Locked = true;
                }
                field(receiptNumber; Rec."Receipt No.")
                {
                    ApplicationArea = All;
                    Caption = 'Receipt No.', Locked = true;
                }
                field(receiptLineNumber; Rec."Receipt Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Receipt Line No.', Locked = true;
                }
                field(profitPercent; Rec."Profit %")
                {
                    ApplicationArea = All;
                    Caption = 'Profit %', Locked = true;
                }
                field(payToVendorNumber; Rec."Pay-to Vendor No.")
                {
                    ApplicationArea = All;
                    Caption = 'Pay-to Vendor No.', Locked = true;
                }
                field(invDiscountAmount; Rec."Inv. Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Inv. Discount Amount', Locked = true;
                }
                field(vendorItemNumber; Rec."Vendor Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Vendor Item No.', Locked = true;
                }
                field(salesOrderNumber; Rec."Sales Order No.")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Order No.', Locked = true;
                }
                field(salesOrderLineNumber; Rec."Sales Order Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Sales Order Line No.', Locked = true;
                }
                field(dropShipment; Rec."Drop Shipment")
                {
                    ApplicationArea = All;
                    Caption = 'Drop Shipment', Locked = true;
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
                field(attachedToLineNumber; Rec."Attached to Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Attached to Line No.', Locked = true;
                }
                field(entryPoint; Rec."Entry Point")
                {
                    ApplicationArea = All;
                    Caption = 'Entry Point', Locked = true;
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
                field(currencyCode; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    Caption = 'Currency Code', Locked = true;
                }
                field(outstandingAmountLcy; Rec."Outstanding Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Amount (LCY)', Locked = true;
                }
                field(amtRcdNotInvoicedLcy; Rec."Amt. Rcd. Not Invoiced (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Amt. Rcd. Not Invoiced (LCY)', Locked = true;
                }
                field(reservedQuantity; Rec."Reserved Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Reserved Quantity', Locked = true;
                }
                field(blanketOrderNumber; Rec."Blanket Order No.")
                {
                    ApplicationArea = All;
                    Caption = 'Blanket Order No.', Locked = true;
                }
                field(blanketOrderLineNumber; Rec."Blanket Order Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Blanket Order Line No.', Locked = true;
                }
                field(vatBaseAmount; Rec."VAT Base Amount")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Base Amount', Locked = true;
                }
                field(unitCost; Rec."Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Cost', Locked = true;
                }
                field(systemCreatedEntry; Rec."System-Created Entry")
                {
                    ApplicationArea = All;
                    Caption = 'System-Created Entry', Locked = true;
                }
                field(lineAmount; Rec."Line Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Line Amount', Locked = true;
                }
                field(vatDifference; Rec."VAT Difference")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Difference', Locked = true;
                }
                field(invDiscAmountToInvoice; Rec."Inv. Disc. Amount to Invoice")
                {
                    ApplicationArea = All;
                    Caption = 'Inv. Disc. Amount to Invoice', Locked = true;
                }
                field(vatIdentifier; Rec."VAT Identifier")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Identifier', Locked = true;
                }
                field(icPartnerRefType; Rec."IC Partner Ref. Type")
                {
                    ApplicationArea = All;
                    Caption = 'IC Partner Ref. Type', Locked = true;
                }
                field(icPartnerReference; Rec."IC Partner Reference")
                {
                    ApplicationArea = All;
                    Caption = 'IC Partner Reference', Locked = true;
                }
                field(prepaymentPercent; Rec."Prepayment %")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment %', Locked = true;
                }
                field(prepmtLineAmount; Rec."Prepmt. Line Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Line Amount', Locked = true;
                }
                field(prepmtAmtInv; Rec."Prepmt. Amt. Inv.")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Amt. Inv.', Locked = true;
                }
                field(prepmtAmtInclVat; Rec."Prepmt. Amt. Incl. VAT")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Amt. Incl. VAT', Locked = true;
                }
                field(prepaymentAmount; Rec."Prepayment Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment Amount', Locked = true;
                }
                field(prepmtVatBaseAmt; Rec."Prepmt. VAT Base Amt.")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. VAT Base Amt.', Locked = true;
                }
                field(prepaymentVatPercent; Rec."Prepayment VAT %")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment VAT %', Locked = true;
                }
                field(prepmtVatCalcType; Rec."Prepmt. VAT Calc. Type")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. VAT Calc. Type', Locked = true;
                }
                field(prepaymentVatIdentifier; Rec."Prepayment VAT Identifier")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment VAT Identifier', Locked = true;
                }
                field(prepaymentTaxAreaCode; Rec."Prepayment Tax Area Code")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment Tax Area Code', Locked = true;
                }
                field(prepaymentTaxLiable; Rec."Prepayment Tax Liable")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment Tax Liable', Locked = true;
                }
                field(prepaymentTaxGroupCode; Rec."Prepayment Tax Group Code")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment Tax Group Code', Locked = true;
                }
                field(prepmtAmtToDeduct; Rec."Prepmt Amt to Deduct")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt Amt to Deduct', Locked = true;
                }
                field(prepmtAmtDeducted; Rec."Prepmt Amt Deducted")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt Amt Deducted', Locked = true;
                }
                field(prepaymentLine; Rec."Prepayment Line")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment Line', Locked = true;
                }
                field(prepmtAmountInvInclVat; Rec."Prepmt. Amount Inv. Incl. VAT")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Amount Inv. Incl. VAT', Locked = true;
                }
                field(prepmtAmountInvLcy; Rec."Prepmt. Amount Inv. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. Amount Inv. (LCY)', Locked = true;
                }
                field(icPartnerCode; Rec."IC Partner Code")
                {
                    ApplicationArea = All;
                    Caption = 'IC Partner Code', Locked = true;
                }
                field(prepmtVatAmountInvLcy; Rec."Prepmt. VAT Amount Inv. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt. VAT Amount Inv. (LCY)', Locked = true;
                }
                field(prepaymentVatDifference; Rec."Prepayment VAT Difference")
                {
                    ApplicationArea = All;
                    Caption = 'Prepayment VAT Difference', Locked = true;
                }
                field(prepmtVatDiffToDeduct; Rec."Prepmt VAT Diff. to Deduct")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt VAT Diff. to Deduct', Locked = true;
                }
                field(prepmtVatDiffDeducted; Rec."Prepmt VAT Diff. Deducted")
                {
                    ApplicationArea = All;
                    Caption = 'Prepmt VAT Diff. Deducted', Locked = true;
                }
                field(outstandingAmtExVatLcy; Rec."Outstanding Amt. Ex. VAT (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Amt. Ex. VAT (LCY)', Locked = true;
                }
                field(aRcdNotInvExVatLcy; Rec."A. Rcd. Not Inv. Ex. VAT (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'A. Rcd. Not Inv. Ex. VAT (LCY)', Locked = true;
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
                field(jobLineAmount; Rec."Job Line Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Amount', Locked = true;
                }
                field(jobLineDiscountAmount; Rec."Job Line Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Discount Amount', Locked = true;
                }
                field(jobLineDiscountPercent; Rec."Job Line Discount %")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Discount %', Locked = true;
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
                field(jobLineAmountLcy; Rec."Job Line Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Amount (LCY)', Locked = true;
                }
                field(jobLineDiscAmountLcy; Rec."Job Line Disc. Amount (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Line Disc. Amount (LCY)', Locked = true;
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
                field(jobRemainingQtyBase; Rec."Job Remaining Qty. (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Job Remaining Qty. (Base)', Locked = true;
                }
                field(deferralCode; Rec."Deferral Code")
                {
                    ApplicationArea = All;
                    Caption = 'Deferral Code', Locked = true;
                }
                field(returnsDeferralStartDate; Rec."Returns Deferral Start Date")
                {
                    ApplicationArea = All;
                    Caption = 'Returns Deferral Start Date', Locked = true;
                }
                field(variantCode; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant Code', Locked = true;
                }
                field(binCode; Rec."Bin Code")
                {
                    ApplicationArea = All;
                    Caption = 'Bin Code', Locked = true;
                }
                field(qtyPerUnitOfMeasure; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. per Unit of Measure', Locked = true;
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Caption = 'Unit of Measure Code', Locked = true;
                }
                field(quantityBase; Rec."Quantity (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Quantity (Base)', Locked = true;
                }
                field(outstandingQtyBase; Rec."Outstanding Qty. (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Outstanding Qty. (Base)', Locked = true;
                }
                field(qtyToInvoiceBase; Rec."Qty. to Invoice (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Invoice (Base)', Locked = true;
                }
                field(qtyToReceiveBase; Rec."Qty. to Receive (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Receive (Base)', Locked = true;
                }
                field(qtyRcdNotInvoicedBase; Rec."Qty. Rcd. Not Invoiced (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Rcd. Not Invoiced (Base)', Locked = true;
                }
                field(qtyReceivedBase; Rec."Qty. Received (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Received (Base)', Locked = true;
                }
                field(qtyInvoicedBase; Rec."Qty. Invoiced (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Invoiced (Base)', Locked = true;
                }
                field(reservedQtyBase; Rec."Reserved Qty. (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Reserved Qty. (Base)', Locked = true;
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
                field(responsibilityCenter; Rec."Responsibility Center")
                {
                    ApplicationArea = All;
                    Caption = 'Responsibility Center', Locked = true;
                }
                field(itemReferenceNumber; Rec."Item Reference No.")
                {
                    ApplicationArea = All;
                    Caption = 'Item Reference No.', Locked = true;
                    Tooltip = 'Specifies item reference number.';
                }
                field(itemRefUnitOfMeasure; Rec."Item Reference Unit of Measure")
                {
                    ApplicationArea = All;
                    Caption = 'Item Reference Unit of Measure', Locked = true;
                    Tooltip = 'Specifies item reference unit of measure code.';
                }
                field(itemReferenceType; Rec."Item Reference Type")
                {
                    ApplicationArea = All;
                    Caption = 'Item Reference Type', Locked = true;
                    Tooltip = 'Specifies item reference type.';
                }
                field(itemReferenceTypeNumber; Rec."Item Reference Type No.")
                {
                    ApplicationArea = All;
                    Caption = 'Item Reference Type No.', Locked = true;
                    Tooltip = 'Specifies item reference type number.';
                }
                field(itemCategoryCode; Rec."Item Category Code")
                {
                    ApplicationArea = All;
                    Caption = 'Item Category Code', Locked = true;
                }
                field(nonstock; Rec.Nonstock)
                {
                    ApplicationArea = All;
                    Caption = 'Catalog', Locked = true;
                }
                field(purchasingCode; Rec."Purchasing Code")
                {
                    ApplicationArea = All;
                    Caption = 'Purchasing Code', Locked = true;
                }
                field(specialOrder; Rec."Special Order")
                {
                    ApplicationArea = All;
                    Caption = 'Special Order', Locked = true;
                }
                field(specialOrderSalesNumber; Rec."Special Order Sales No.")
                {
                    ApplicationArea = All;
                    Caption = 'Special Order Sales No.', Locked = true;
                }
                field(specialOrderSalesLineNumber; Rec."Special Order Sales Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Special Order Sales Line No.', Locked = true;
                }
                field(whseOutstandingQtyBase; Rec."Whse. Outstanding Qty. (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Whse. Outstanding Qty. (Base)', Locked = true;
                }
                field(completelyReceived; Rec."Completely Received")
                {
                    ApplicationArea = All;
                    Caption = 'Completely Received', Locked = true;
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
                field(plannedReceiptDate; Rec."Planned Receipt Date")
                {
                    ApplicationArea = All;
                    Caption = 'Planned Receipt Date', Locked = true;
                }
                field(orderDate; Rec."Order Date")
                {
                    ApplicationArea = All;
                    Caption = 'Order Date', Locked = true;
                }
                field(allowItemChargeAssignment; Rec."Allow Item Charge Assignment")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Item Charge Assignment', Locked = true;
                }
                field(qtyToAssign; Rec."Qty. to Assign")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Assign', Locked = true;
                }
                field(qtyAssigned; Rec."Qty. Assigned")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Assigned', Locked = true;
                }
                field(returnQtyToShip; Rec."Return Qty. to Ship")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. to Ship', Locked = true;
                }
                field(returnQtyToShipBase; Rec."Return Qty. to Ship (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. to Ship (Base)', Locked = true;
                }
                field(returnQtyShippedNotInvd; Rec."Return Qty. Shipped Not Invd.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. Shipped Not Invd.', Locked = true;
                }
                field(retQtyShpdNotInvdBase; Rec."Ret. Qty. Shpd Not Invd.(Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Ret. Qty. Shpd Not Invd.(Base)', Locked = true;
                }
                field(returnShpdNotInvd; Rec."Return Shpd. Not Invd.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Shpd. Not Invd.', Locked = true;
                }
                field(returnShpdNotInvdLcy; Rec."Return Shpd. Not Invd. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Return Shpd. Not Invd. (LCY)', Locked = true;
                }
                field(returnQtyShipped; Rec."Return Qty. Shipped")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. Shipped', Locked = true;
                }
                field(returnQtyShippedBase; Rec."Return Qty. Shipped (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. Shipped (Base)', Locked = true;
                }
                field(returnShipmentNumber; Rec."Return Shipment No.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Shipment No.', Locked = true;
                }
                field(returnShipmentLineNumber; Rec."Return Shipment Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Shipment Line No.', Locked = true;
                }
                field(returnReasonCode; Rec."Return Reason Code")
                {
                    ApplicationArea = All;
                    Caption = 'Return Reason Code', Locked = true;
                }
                field(subtype; Rec.Subtype)
                {
                    ApplicationArea = All;
                    Caption = 'Subtype', Locked = true;
                }
                field(overheadRate; Rec."Overhead Rate")
                {
                    ApplicationArea = All;
                    Caption = 'Overhead Rate', Locked = true;
                }
                field(mpsOrder; Rec."MPS Order")
                {
                    ApplicationArea = All;
                    Caption = 'MPS Order', Locked = true;
                }
                field(planningFlexibility; Rec."Planning Flexibility")
                {
                    ApplicationArea = All;
                    Caption = 'Planning Flexibility', Locked = true;
                }
                field(safetyLeadTime; Rec."Safety Lead Time")
                {
                    ApplicationArea = All;
                    Caption = 'Safety Lead Time', Locked = true;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if InsertExtendedText() then
            exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if EntityChanged then
            if InsertExtendedText() then
                exit(false);
    end;

    var
        EntityChanged: Boolean;

    local procedure InsertExtendedText(): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        if TransferExtendedText.PurchCheckIfAnyExtText(Rec, false) then begin
            if PurchaseLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.") then
                Rec.Modify(true)
            else
                Rec.Insert(true);
            Commit();
            TransferExtendedText.InsertPurchExtText(Rec);
            exit(true);
        end;
        exit(false);
    end;
}

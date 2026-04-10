// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Foundation.ExtendedText;
using Microsoft.Sales.Document;

page 6403 "Sales Document Line Entity"
{
    Caption = 'Sales Document Line Entity', Locked = true;
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Sales Line";

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
                field(sellToCustomerNumber; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'Sell-to Customer No.', Locked = true;
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
                field(shipmentDate; Rec."Shipment Date")
                {
                    ApplicationArea = All;
                    Caption = 'Shipment Date', Locked = true;
                }
                field(description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description', Locked = true;
                    Lookup = false;
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
                field(qtyToShip; Rec."Qty. to Ship")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Ship', Locked = true;
                }
                field(unitPrice; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Price', Locked = true;
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
                field(customerPriceGroup; Rec."Customer Price Group")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Price Group', Locked = true;
                }
                field(jobNumber; Rec."Job No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job No.', Locked = true;
                }
                field(workTypeCode; Rec."Work Type Code")
                {
                    ApplicationArea = All;
                    Caption = 'Work Type Code', Locked = true;
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
                field(qtyShippedNotInvoiced; Rec."Qty. Shipped Not Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Shipped Not Invoiced', Locked = true;
                }
                field(shippedNotInvoiced; Rec."Shipped Not Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Shipped Not Invoiced', Locked = true;
                }
                field(quantityShipped; Rec."Quantity Shipped")
                {
                    ApplicationArea = All;
                    Caption = 'Quantity Shipped', Locked = true;
                }
                field(quantityInvoiced; Rec."Quantity Invoiced")
                {
                    ApplicationArea = All;
                    Caption = 'Quantity Invoiced', Locked = true;
                }
                field(shipmentNumber; Rec."Shipment No.")
                {
                    ApplicationArea = All;
                    Caption = 'Shipment No.', Locked = true;
                }
                field(shipmentLineNumber; Rec."Shipment Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Shipment Line No.', Locked = true;
                }
                field(profitPercent; Rec."Profit %")
                {
                    ApplicationArea = All;
                    Caption = 'Profit %', Locked = true;
                }
                field(billToCustomerNumber; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'Bill-to Customer No.', Locked = true;
                }
                field(invDiscountAmount; Rec."Inv. Discount Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Inv. Discount Amount', Locked = true;
                }
                field(purchaseOrderNumber; Rec."Purchase Order No.")
                {
                    ApplicationArea = All;
                    Caption = 'Purchase Order No.', Locked = true;
                }
                field(purchOrderLineNumber; Rec."Purch. Order Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Purch. Order Line No.', Locked = true;
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
                field(exitPoint; Rec."Exit Point")
                {
                    ApplicationArea = All;
                    Caption = 'Exit Point', Locked = true;
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
                field(taxCategory; Rec."Tax Category")
                {
                    ApplicationArea = All;
                    Caption = 'Tax Category', Locked = true;
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
                field(vatClauseCode; Rec."VAT Clause Code")
                {
                    ApplicationArea = All;
                    Caption = 'VAT Clause Code', Locked = true;
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
                field(shippedNotInvoicedLcy; Rec."Shipped Not Invoiced (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Shipped Not Invoiced (LCY)', Locked = true;
                }
                field(shippedNotInvLcyNoVat; Rec."Shipped Not Inv. (LCY) No VAT")
                {
                    ApplicationArea = All;
                    Caption = 'Shipped Not Inv. (LCY) No VAT', Locked = true;
                }
                field(reservedQuantity; Rec."Reserved Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Reserved Quantity', Locked = true;
                }
                field(reserve; Rec.Reserve)
                {
                    ApplicationArea = All;
                    Caption = 'Reserve', Locked = true;
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
                field(dimensionSetId; Rec."Dimension Set ID")
                {
                    ApplicationArea = All;
                    Caption = 'Dimension Set ID', Locked = true;
                }
                field(qtyToAssembleToOrder; Rec."Qty. to Assemble to Order")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Assemble to Order', Locked = true;
                }
                field(qtyToAsmToOrderBase; Rec."Qty. to Asm. to Order (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Asm. to Order (Base)', Locked = true;
                }
                field(atoWhseOutstandingQty; Rec."ATO Whse. Outstanding Qty.")
                {
                    ApplicationArea = All;
                    Caption = 'ATO Whse. Outstanding Qty.', Locked = true;
                }
                field(atoWhseOutstdQtyBase; Rec."ATO Whse. Outstd. Qty. (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'ATO Whse. Outstd. Qty. (Base)', Locked = true;
                }
                field(jobTaskNumber; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job Task No.', Locked = true;
                }
                field(jobContractEntryNumber; Rec."Job Contract Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job Contract Entry No.', Locked = true;
                }
                field(postingDate; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Date', Locked = true;
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
                field(planned; Rec.Planned)
                {
                    ApplicationArea = All;
                    Caption = 'Planned', Locked = true;
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
                field(qtyToShipBase; Rec."Qty. to Ship (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. to Ship (Base)', Locked = true;
                }
                field(qtyShippedNotInvdBase; Rec."Qty. Shipped Not Invd. (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Shipped Not Invd. (Base)', Locked = true;
                }
                field(qtyShippedBase; Rec."Qty. Shipped (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Qty. Shipped (Base)', Locked = true;
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
                field(depreciationBookCode; Rec."Depreciation Book Code")
                {
                    ApplicationArea = All;
                    Caption = 'Depreciation Book Code', Locked = true;
                }
                field(deprUntilFaPostingDate; Rec."Depr. until FA Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Depr. until FA Posting Date', Locked = true;
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
                field(outOfStockSubstitution; Rec."Out-of-Stock Substitution")
                {
                    ApplicationArea = All;
                    Caption = 'Out-of-Stock Substitution', Locked = true;
                }
                field(substitutionAvailable; Rec."Substitution Available")
                {
                    ApplicationArea = All;
                    Caption = 'Substitution Available', Locked = true;
                }
                field(originallyOrderedNumber; Rec."Originally Ordered No.")
                {
                    ApplicationArea = All;
                    Caption = 'Originally Ordered No.', Locked = true;
                }
                field(originallyOrderedVarCode; Rec."Originally Ordered Var. Code")
                {
                    ApplicationArea = All;
                    Caption = 'Originally Ordered Var. Code', Locked = true;
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
                field(specialOrderPurchaseNumber; Rec."Special Order Purchase No.")
                {
                    ApplicationArea = All;
                    Caption = 'Special Order Purchase No.', Locked = true;
                }
                field(specialOrderPurchLineNumber; Rec."Special Order Purch. Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Special Order Purch. Line No.', Locked = true;
                }
                field(whseOutstandingQty; Rec."Whse. Outstanding Qty.")
                {
                    ApplicationArea = All;
                    Caption = 'Whse. Outstanding Qty.', Locked = true;
                }
                field(whseOutstandingQtyBase; Rec."Whse. Outstanding Qty. (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Whse. Outstanding Qty. (Base)', Locked = true;
                }
                field(completelyShipped; Rec."Completely Shipped")
                {
                    ApplicationArea = All;
                    Caption = 'Completely Shipped', Locked = true;
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
                field(plannedDeliveryDate; Rec."Planned Delivery Date")
                {
                    ApplicationArea = All;
                    Caption = 'Planned Delivery Date', Locked = true;
                }
                field(plannedShipmentDate; Rec."Planned Shipment Date")
                {
                    ApplicationArea = All;
                    Caption = 'Planned Shipment Date', Locked = true;
                }
                field(shippingAgentCode; Rec."Shipping Agent Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping Agent Code', Locked = true;
                }
                field(shippingAgentServiceCode; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shipping Agent Service Code', Locked = true;
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
                field(returnQtyToReceive; Rec."Return Qty. to Receive")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. to Receive', Locked = true;
                }
                field(returnQtyToReceiveBase; Rec."Return Qty. to Receive (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. to Receive (Base)', Locked = true;
                }
                field(returnQtyRcdNotInvd; Rec."Return Qty. Rcd. Not Invd.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. Rcd. Not Invd.', Locked = true;
                }
                field(retQtyRcdNotInvdBase; Rec."Ret. Qty. Rcd. Not Invd.(Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Ret. Qty. Rcd. Not Invd.(Base)', Locked = true;
                }
                field(returnRcdNotInvd; Rec."Return Rcd. Not Invd.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Rcd. Not Invd.', Locked = true;
                }
                field(returnRcdNotInvdLcy; Rec."Return Rcd. Not Invd. (LCY)")
                {
                    ApplicationArea = All;
                    Caption = 'Return Rcd. Not Invd. (LCY)', Locked = true;
                }
                field(returnQtyReceived; Rec."Return Qty. Received")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. Received', Locked = true;
                }
                field(returnQtyReceivedBase; Rec."Return Qty. Received (Base)")
                {
                    ApplicationArea = All;
                    Caption = 'Return Qty. Received (Base)', Locked = true;
                }
                field(applFromItemEntry; Rec."Appl.-from Item Entry")
                {
                    ApplicationArea = All;
                    Caption = 'Appl.-from Item Entry', Locked = true;
                }
                field(bomItemNumber; Rec."BOM Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'BOM Item No.', Locked = true;
                }
                field(returnReceiptNumber; Rec."Return Receipt No.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Receipt No.', Locked = true;
                }
                field(returnReceiptLineNumber; Rec."Return Receipt Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Return Receipt Line No.', Locked = true;
                }
                field(returnReasonCode; Rec."Return Reason Code")
                {
                    ApplicationArea = All;
                    Caption = 'Return Reason Code', Locked = true;
                }
                field(allowLineDisc; Rec."Allow Line Disc.")
                {
                    ApplicationArea = All;
                    Caption = 'Allow Line Disc.', Locked = true;
                }
                field(customerDiscGroup; Rec."Customer Disc. Group")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Disc. Group', Locked = true;
                }
                field(subtype; Rec.Subtype)
                {
                    ApplicationArea = All;
                    Caption = 'Subtype', Locked = true;
                }
                field(priceDescription; Rec."Price description")
                {
                    ApplicationArea = All;
                    Caption = 'Price description', Locked = true;
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
        SalesLine: Record "Sales Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        if TransferExtendedText.SalesCheckIfAnyExtText(Rec, false) then begin
            if SalesLine.Get(Rec."Document Type", Rec."Document No.", Rec."Line No.") then
                Rec.Modify(true)
            else
                Rec.Insert(true);
            Commit();
            TransferExtendedText.InsertSalesExtText(Rec);
            exit(true);
        end;
        exit(false);
    end;
}

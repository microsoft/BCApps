// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Setup;

using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.RoleCenters;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Privacy;

codeunit 1763 "Purchases-Data Classification"
{
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classification Eval. Data", 'OnCreateEvaluationDataOnAfterClassifyTablesToNormal', '', false, false)]
    local procedure OnClassifyTables()
    begin
        ClassifyTables();
    end;

    local procedure ClassifyTables()
    begin
        ClassifyMyVendor();
        ClassifyPurchaseLineArchive();
        ClassifyPurchaseHeaderArchive();
        ClassifyDetailedVendorLedgEntry();
        ClassifyOrderAddress();
        ClassifyPayableVendorLedgerEntry();
        ClassifyReturnShipmentLine();
        ClassifyReturnShipmentHeader();
        ClassifyPurchCrMemoLine();
        ClassifyPurchCrMemoHdr();
        ClassifyPurchInvLine();
        ClassifyPurchInvHeader();
        ClassifyPurchRcptLine();
        ClassifyPurchRcptHeader();
        ClassifyPurchaseLine();
        ClassifyPurchaseHeader();
        ClassifyVendorLedgerEntry();
        ClassifyVendor();
        ClassifyVendorBankAccount();
        ClassifyRemitToAddress();

        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Vendor Invoice Disc.");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Purchase Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Purch. Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Vendor Posting Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Alt. Vendor Posting Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Standard Purchase Code");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Standard Purchase Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Standard Vendor Purchase Code");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Vendor Amount");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Purchases & Payables Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Purchase Prepayment %");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Vendor Templ.");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Purch. Comment Line Archive");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Charge Assignment (Purch)");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Purchase Price");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Purchase Line Discount");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Purchase Cue");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Over-Receipt Code");
    end;

    local procedure ClassifyMyVendor()
    var
        DummyMyVendor: Record "My Vendor";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"My Vendor";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyMyVendor.FieldNo("Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyMyVendor.FieldNo(Name));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyMyVendor.FieldNo("User ID"));
    end;

    local procedure ClassifyPurchaseLineArchive()
    var
        DummyPurchaseLineArchive: Record "Purchase Line Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purchase Line Archive";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseLineArchive.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyPurchaseHeaderArchive()
    var
        DummyPurchaseHeaderArchive: Record "Purchase Header Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purchase Header Archive";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Assigned User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Archived By"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Ship-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Buy-from County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Buy-from Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Pay-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Pay-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Buy-from Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Buy-from City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Buy-from Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Buy-from Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Buy-from Vendor Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Buy-from Vendor Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Ship-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Ship-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Pay-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Pay-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Pay-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Pay-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Pay-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeaderArchive.FieldNo("Pay-to Name"));
    end;

    local procedure ClassifyDetailedVendorLedgEntry()
    var
        DummyDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Detailed Vendor Ledg. Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Ledger Entry Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Application No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Tax Jurisdiction Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Max. Payment Tolerance"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Remaining Pmt. Disc. Possible"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Unapplied by Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo(Unapplied));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Applied Vend. Ledger Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Initial Document Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("VAT Prod. Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("VAT Bus. Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Use Tax"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Gen. Prod. Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Gen. Bus. Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Initial Entry Global Dim. 2"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Initial Entry Global Dim. 1"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Initial Entry Due Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Credit Amount (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Debit Amount (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Credit Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Debit Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Reason Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Journal Batch Name"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Transaction No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Source Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyDetailedVendorLedgEntry.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Currency Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Vendor No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Amount (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo(Amount));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Document Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Entry Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Vendor Ledger Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedVendorLedgEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyPayableVendorLedgerEntry()
    var
        DummyPayableVendorLedgerEntry: Record "Payable Vendor Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Payable Vendor Ledger Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo(Future));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo(Positive));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo("Currency Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo("Amount (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo(Amount));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo("Vendor Ledg. Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo("Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo("Vendor No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyPayableVendorLedgerEntry.FieldNo(Priority));
    end;

    local procedure ClassifyOrderAddress()
    var
        DummyOrderAddress: Record "Order Address";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Order Address";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("Home Page"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("Fax No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("Telex Answer Back"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("Telex No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo(Contact));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo("Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyOrderAddress.FieldNo(Name));
    end;

    local procedure ClassifyReturnShipmentLine()
    var
        DummyReturnShipmentLine: Record "Return Shipment Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Return Shipment Line";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyReturnShipmentHeader()
    var
        DummyReturnShipmentHeader: Record "Return Shipment Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Return Shipment Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Ship-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Buy-from County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Buy-from Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Pay-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Pay-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Buy-from Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Buy-from City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Buy-from Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Buy-from Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Buy-from Vendor Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Buy-from Vendor Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Ship-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Ship-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Pay-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Pay-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Pay-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Pay-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Pay-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnShipmentHeader.FieldNo("Pay-to Name"));
    end;

    local procedure ClassifyPurchCrMemoLine()
    var
        DummyPurchCrMemoLine: Record "Purch. Cr. Memo Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purch. Cr. Memo Line";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyPurchCrMemoHdr()
    var
        DummyPurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purch. Cr. Memo Hdr.";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Ship-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Buy-from County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Buy-from Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Pay-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Pay-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Buy-from Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Buy-from City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Buy-from Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Buy-from Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Buy-from Vendor Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Buy-from Vendor Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Ship-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Ship-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Pay-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Pay-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Pay-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Pay-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Pay-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchCrMemoHdr.FieldNo("Pay-to Name"));
    end;

    local procedure ClassifyPurchInvLine()
    var
        DummyPurchInvLine: Record "Purch. Inv. Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purch. Inv. Line";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyPurchInvHeader()
    var
        DummyPurchInvHeader: Record "Purch. Inv. Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purch. Inv. Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Creditor No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Ship-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Buy-from County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Buy-from Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Pay-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Pay-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Buy-from Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Buy-from City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Buy-from Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Buy-from Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Buy-from Vendor Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Buy-from Vendor Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Ship-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Ship-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Pay-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Pay-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Pay-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Pay-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Pay-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchInvHeader.FieldNo("Pay-to Name"));
    end;

    local procedure ClassifyPurchRcptLine()
    var
        DummyPurchRcptLine: Record "Purch. Rcpt. Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purch. Rcpt. Line";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyPurchRcptHeader()
    var
        DummyPurchRcptHeader: Record "Purch. Rcpt. Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purch. Rcpt. Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Ship-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Buy-from County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Buy-from Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Pay-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Pay-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Buy-from Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Buy-from City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Buy-from Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Buy-from Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Buy-from Vendor Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Buy-from Vendor Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Ship-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Ship-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Pay-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Pay-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Pay-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Pay-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Pay-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchRcptHeader.FieldNo("Pay-to Name"));
    end;

    local procedure ClassifyPurchaseLine()
    var
        DummyPurchaseLine: Record "Purchase Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purchase Line";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyPurchaseHeader()
    var
        DummyPurchaseHeader: Record "Purchase Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purchase Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Assigned User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Creditor No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Ship-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Buy-from County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Buy-from Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Pay-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Pay-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Buy-from Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Buy-from City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Buy-from Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Buy-from Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Buy-from Vendor Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Buy-from Vendor Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Ship-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Ship-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Pay-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Pay-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Pay-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Pay-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Pay-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPurchaseHeader.FieldNo("Pay-to Name"));
    end;

    local procedure ClassifyVendorLedgerEntry()
    var
        DummyVendorLedgerEntry: Record "Vendor Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Vendor Ledger Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Applies-to Ext. Doc. No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Payment Method Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Payment Reference"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Creditor No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Dimension Set ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Exported to Payment File"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Message to Recipient"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Recipient Bank Account"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo(Prepayment));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Reversed Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Reversed by Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo(Reversed));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Applying Entry"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("IC Partner Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Amount to Apply"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Pmt. Tolerance (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Accepted Pmt. Disc. Tolerance"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Accepted Payment Tolerance"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Max. Payment Tolerance"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Pmt. Disc. Tolerance Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Remaining Pmt. Disc. Possible"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Original Currency Factor"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Adjusted Currency Factor"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Closed by Currency Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Closed by Currency Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("No. Series"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("External Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Document Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Closed by Amount (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Transaction No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Bal. Account No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Bal. Account Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Reason Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Journal Batch Name"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Applies-to ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Closed by Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Closed at Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Closed by Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo(Positive));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Pmt. Disc. Rcd.(LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Original Pmt. Disc. Possible"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Pmt. Discount Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Due Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo(Open));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Applies-to Doc. No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Applies-to Doc. Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("On Hold"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Source Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorLedgerEntry.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Purchaser Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Global Dimension 2 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Global Dimension 1 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Vendor Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Buy-from Vendor No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Inv. Discount (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Purchase (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Currency Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Document Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Vendor No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendorLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyVendor()
    var
        DummyVendor: Record Vendor;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Vendor;
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Creditor No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo(Image));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyVendor.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Home Page"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo("E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo(GLN));
        DataClassificationMgt.SetFieldToSensitive(TableNo, DummyVendor.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Telex Answer Back"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Fax No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Telex No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo(Contact));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo("Search Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendor.FieldNo(Name));
    end;

    local procedure ClassifyVendorBankAccount()
    var
        DummyVendorBankAccount: Record "Vendor Bank Account";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Vendor Bank Account";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo(IBAN));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Home Page"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Language Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Telex Answer Back"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Fax No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Country/Region Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Transit No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Bank Account No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Bank Branch No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Telex No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo(Contact));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo("Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyVendorBankAccount.FieldNo(Name));
    end;

    local procedure ClassifyRemitToAddress()
    var
        RemitAddress: Record "Remit Address";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Remit Address";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, RemitAddress.FieldNo(Name));
        DataClassificationMgt.SetFieldToPersonal(TableNo, RemitAddress.FieldNo("Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, RemitAddress.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(TableNo, RemitAddress.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, RemitAddress.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(TableNo, RemitAddress.FieldNo(Contact));
        DataClassificationMgt.SetFieldToPersonal(TableNo, RemitAddress.FieldNo("Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, RemitAddress.FieldNo("Country/Region Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, RemitAddress.FieldNo("Fax No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, RemitAddress.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, RemitAddress.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(TableNo, RemitAddress.FieldNo("E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, RemitAddress.FieldNo("Home Page"));
    end;


}

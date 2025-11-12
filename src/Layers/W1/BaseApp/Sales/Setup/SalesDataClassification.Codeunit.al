// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Setup;

using Microsoft.Sales.Analysis;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.RoleCenters;
using Microsoft.Utilities;
using System.Privacy;

codeunit 1762 "Sales-Data Classification"
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
        ClassifyMyCustomer();
        ClassifySalesLineArchive();
        ClassifySalesHeaderArchive();
        ClassifyDetailedCustLedgEntry();
        ClassifyReminderFinChargeEntry();
        ClassifyIssuedFinChargeMemoHeader();
        ClassifyFinanceChargeMemoHeader();
        ClassifyIssuedReminderHeader();
        ClassifyReminderHeader();
        ClassifySalesCrMemoLine();
        ClassifySalesCrMemoHeader();
        ClassifySalesInvoiceLine();
        ClassifySalesInvoiceHeader();
        ClassifySalesShipmentLine();
        ClassifySalesShipmentHeader();
        ClassifyCustLedgerEntry();
        ClassifyCustomer();
        ClassifyCustomerBankAccount();
        ClassifyReturnReceiptLine();
        ClassifyReturnReceiptHeader();
        ClassifyShiptoAddress();
        ClassifySalesLine();
        ClassifySalesHeader();

        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Alt. Customer Posting Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Customer Price Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Cust. Invoice Disc.");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Customer Amount");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Customer Posting Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Finance Charge Terms");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Sales Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Sales Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Standard Sales Code");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Standard Sales Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Standard Customer Sales Code");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Reminder Attachment Text");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Reminder Attachment Text Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Reminder Email Text");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Reminder Terms");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Reminder Level");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Reminder Text");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Reminder Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Issued Reminder Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Reminder Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Reminder Action Group");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Reminder Action");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Create Reminders Setup");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Issue Reminders Setup");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Send Reminders Setup");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Reminder Automation Error");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Reminder Action Group Log");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Reminder Action Log");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Finance Charge Text");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Finance Charge Memo Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Issued Fin. Charge Memo Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Fin. Charge Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Sales & Receivables Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Currency for Fin. Charge Terms");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Currency for Reminder Level");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Customer Discount Group");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Sales Prepayment %");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Additional Fee Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Sorting Table");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Reminder Terms Translation");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Line Fee Note on Report Hist.");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Sales Document Icon");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Customer Templ.");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Sales Price");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Sales Line Discount");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Sales Price Worksheet");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Sales Comment Line Archive");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Sales Cue");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Sales by Cust. Grp.Chart Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Dispute Status");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Item Charge Assignment (Sales)");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Returns-Related Document");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Sales Planning Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Finance Charge Interest Rate");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Trailing Sales Orders Setup");


    end;

    local procedure ClassifyMyCustomer()
    var
        DummyMyCustomer: Record "My Customer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"My Customer";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyMyCustomer.FieldNo("Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyMyCustomer.FieldNo(Name));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyMyCustomer.FieldNo("User ID"));
    end;

    local procedure ClassifySalesLineArchive()
    var
        DummySalesLineArchive: Record "Sales Line Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Line Archive";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesLineArchive.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifySalesHeaderArchive()
    var
        DummySalesHeaderArchive: Record "Sales Header Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Header Archive";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Assigned User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Archived By"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Ship-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Sell-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Sell-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Bill-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Bill-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Sell-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Sell-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Sell-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Sell-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Sell-to Customer Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Sell-to Customer Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Ship-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Ship-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Bill-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Bill-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Bill-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Bill-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Bill-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeaderArchive.FieldNo("Bill-to Name"));
    end;

    local procedure ClassifyDetailedCustLedgEntry()
    var
        DummyDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Detailed Cust. Ledg. Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Ledger Entry Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Application No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Tax Jurisdiction Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Max. Payment Tolerance"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Remaining Pmt. Disc. Possible"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Unapplied by Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo(Unapplied));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Applied Cust. Ledger Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Initial Document Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("VAT Prod. Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("VAT Bus. Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Use Tax"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Gen. Prod. Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Gen. Bus. Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Initial Entry Global Dim. 2"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Initial Entry Global Dim. 1"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Initial Entry Due Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Credit Amount (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Debit Amount (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Credit Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Debit Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Reason Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Journal Batch Name"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Transaction No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Source Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyDetailedCustLedgEntry.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Currency Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Customer No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Amount (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo(Amount));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Document Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Entry Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Cust. Ledger Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyDetailedCustLedgEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifySalesShipmentLine()
    var
        DummySalesShipmentLine: Record "Sales Shipment Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Shipment Line";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyIssuedFinChargeMemoHeader()
    var
        DummyIssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Issued Fin. Charge Memo Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo(Contact));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo("Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedFinChargeMemoHeader.FieldNo(Name));
    end;

    local procedure ClassifyFinanceChargeMemoHeader()
    var
        DummyFinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Finance Charge Memo Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo("Assigned User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo(Contact));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo("Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyFinanceChargeMemoHeader.FieldNo(Name));
    end;

    local procedure ClassifyIssuedReminderHeader()
    var
        DummyIssuedReminderHeader: Record "Issued Reminder Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Issued Reminder Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo(Contact));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo("Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyIssuedReminderHeader.FieldNo(Name));
    end;

    local procedure ClassifyReminderHeader()
    var
        DummyReminderHeader: Record "Reminder Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Reminder Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo("Assigned User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo(Contact));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo("Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReminderHeader.FieldNo(Name));
    end;

    local procedure ClassifyReminderFinChargeEntry()
    var
        DummyReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Reminder/Fin. Charge Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Due Date"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReminderFinChargeEntry.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Customer No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Remaining Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Document Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Customer Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Interest Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Interest Posted"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Document Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Reminder Level"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo(Type));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyReminderFinChargeEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifySalesCrMemoLine()
    var
        DummySalesCrMemoLine: Record "Sales Cr.Memo Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Cr.Memo Line";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifySalesCrMemoHeader()
    var
        DummySalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Cr.Memo Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Ship-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Sell-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Sell-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Bill-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Bill-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Sell-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Sell-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Sell-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Sell-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Sell-to Customer Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Sell-to Customer Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Ship-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Ship-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Bill-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Bill-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Bill-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Bill-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Bill-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesCrMemoHeader.FieldNo("Bill-to Name"));
    end;

    local procedure ClassifySalesInvoiceLine()
    var
        DummySalesInvoiceLine: Record "Sales Invoice Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Invoice Line";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifySalesInvoiceHeader()
    var
        DummySalesInvoiceHeader: Record "Sales Invoice Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Invoice Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Ship-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Sell-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Sell-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Bill-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Bill-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Sell-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Sell-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Sell-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Sell-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Sell-to Customer Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Sell-to Customer Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Ship-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Ship-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Bill-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Bill-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Bill-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Bill-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Bill-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesInvoiceHeader.FieldNo("Bill-to Name"));
    end;

    local procedure ClassifySalesShipmentHeader()
    var
        DummySalesShipmentHeader: Record "Sales Shipment Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Shipment Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Ship-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Sell-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Sell-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Bill-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Bill-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Sell-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Sell-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Sell-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Sell-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Sell-to Customer Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Sell-to Customer Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Ship-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Ship-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Bill-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Bill-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Bill-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Bill-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Bill-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesShipmentHeader.FieldNo("Bill-to Name"));
    end;

    local procedure ClassifyCustLedgerEntry()
    var
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cust. Ledger Entry";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Applies-to Ext. Doc. No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Payment Method Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Direct Debit Mandate ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Dimension Set ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Exported to Payment File"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Message to Recipient"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Recipient Bank Account"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo(Prepayment));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Reversed Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Reversed by Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo(Reversed));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Applying Entry"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("IC Partner Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Amount to Apply"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Pmt. Tolerance (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Accepted Pmt. Disc. Tolerance"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Accepted Payment Tolerance"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Last Issued Reminder Level"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Max. Payment Tolerance"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Pmt. Disc. Tolerance Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Remaining Pmt. Disc. Possible"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Original Currency Factor"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Adjusted Currency Factor"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Closed by Currency Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Closed by Currency Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("No. Series"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Closing Interest Calculated"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Calculate Interest"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("External Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Document Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Closed by Amount (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Transaction No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Bal. Account No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Bal. Account Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Reason Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Journal Batch Name"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Applies-to ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Closed by Amount"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Closed at Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Closed by Entry No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo(Positive));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Pmt. Disc. Given (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Original Pmt. Disc. Possible"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Pmt. Discount Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Due Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo(Open));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Applies-to Doc. No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Applies-to Doc. Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("On Hold"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Source Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustLedgerEntry.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Salesperson Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Global Dimension 2 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Global Dimension 1 Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Customer Posting Group"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Sell-to Customer No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Inv. Discount (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Profit (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Sales (LCY)"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Currency Code"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo(Description));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Document No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Document Type"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Posting Date"));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Customer No."));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyCustomer()
    var
        DummyCustomer: Record Customer;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Customer;
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo(Image));
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, DummyCustomer.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Home Page"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo(GLN));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Telex Answer Back"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Fax No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Telex No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo(Contact));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo("Search Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomer.FieldNo(Name));
    end;

    local procedure ClassifySalesHeader()
    var
        DummySalesHeader: Record "Sales Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Assigned User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Ship-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Sell-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Sell-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Bill-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Bill-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Sell-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Sell-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Sell-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Sell-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Sell-to Customer Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Sell-to Customer Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Ship-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Ship-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Bill-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Bill-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Bill-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Bill-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Bill-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesHeader.FieldNo("Bill-to Name"));
    end;

    local procedure ClassifySalesLine()
    var
        DummySalesLine: Record "Sales Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Line";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummySalesLine.FieldNo("Tax Area Code"));
    end;

    local procedure ClassifyShiptoAddress()
    var
        DummyShipToAddress: Record "Ship-to Address";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Ship-to Address";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Home Page"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Fax No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Telex Answer Back"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Telex No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo(Contact));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo("Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyShipToAddress.FieldNo(Name));
    end;

    local procedure ClassifyCustomerBankAccount()
    var
        DummyCustomerBankAccount: Record "Customer Bank Account";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Customer Bank Account";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo(IBAN));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Home Page"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("E-Mail"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Telex Answer Back"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Fax No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo(County));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Country/Region Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Transit No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Bank Account No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Bank Branch No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Telex No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Phone No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo(Contact));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo(City));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo(Address));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo("Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyCustomerBankAccount.FieldNo(Name));
    end;

    local procedure ClassifyReturnReceiptHeader()
    var
        DummyReturnReceiptHeader: Record "Return Receipt Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Return Receipt Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Tax Area Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("User ID"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Ship-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Sell-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Sell-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Bill-to County"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Bill-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Sell-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Sell-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Sell-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Sell-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Sell-to Customer Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Sell-to Customer Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("VAT Registration No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Ship-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Ship-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Bill-to Contact"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Bill-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Bill-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Bill-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Bill-to Name 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptHeader.FieldNo("Bill-to Name"));
    end;

    local procedure ClassifyReturnReceiptLine()
    var
        DummyReturnReceiptLine: Record "Return Receipt Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Return Receipt Line";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyReturnReceiptLine.FieldNo("Tax Area Code"));
    end;


}

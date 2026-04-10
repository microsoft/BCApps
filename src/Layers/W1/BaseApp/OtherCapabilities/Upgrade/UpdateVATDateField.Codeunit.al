// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Purchases.History;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using System.Upgrade;

codeunit 104051 "Update VAT Date Field"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
        UpdateVATEntries();
        UpdateGLEntries();
        UpdatePurchSalesEntries();
        UpdateIssuedDocsEntries();

        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldVATEntriesBlankUpgrade()) then begin
            UpdateBlankVATEntries();
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldVATEntriesBlankUpgrade());
        end;

        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldGLEntriesBlankUpgrade()) then begin
            UpdateBlankGLEntries();
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldGLEntriesBlankUpgrade());
        end;

        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldSalesPurchBlankUpgrade()) then begin
            UpdatePurchSalesBlankEntries();
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldSalesPurchBlankUpgrade());
        end;

        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldIssuedDocsBlankUpgrade()) then begin
            UpdateIssuedDocsBlankEntries();
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldIssuedDocsBlankUpgrade());
        end;


    end;

    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        BlankDate: Date;

    local procedure UpdateBlankVATEntries()
    var
        VATEntry: Record "VAT Entry";
        GLSetup: Record "General Ledger Setup";
        VATDateDataTransfer: DataTransfer;
    begin
        if not GLSetup.Get() then
            exit;

        VATEntry.SetRange("VAT Reporting Date", 0D);
        if VATEntry.IsEmpty() then
            exit;

        // Only update entries that has blank VAT Reporting Date
        VATDateDataTransfer.SetTables(Database::"VAT Entry", Database::"VAT Entry");
        VATDateDataTransfer.AddSourceFilter(VATEntry.FieldNo("VAT Reporting Date"), '=%1', 0D);
        if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Posting Date" then
            VATDateDataTransfer.AddFieldValue(VATEntry.FieldNo("Posting Date"), VATEntry.FieldNo("VAT Reporting Date"))
        else
            VATDateDataTransfer.AddFieldValue(VATEntry.FieldNo("Document Date"), VATEntry.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields := false;
        VATDateDataTransfer.CopyFields();
    end;

    local procedure UpdateBlankGLEntries()
    var
        GLEntry: Record "G/L Entry";
        GLSetup: Record "General Ledger Setup";
        VATDateDataTransfer: DataTransfer;
    begin
        if not GLSetup.Get() then
            exit;

        GLEntry.SetRange("VAT Reporting Date", 0D);
        if GLEntry.IsEmpty() then
            exit;

        // Only update entries that has blank VAT Reporting Date
        VATDateDataTransfer.SetTables(Database::"G/L Entry", Database::"G/L Entry");
        VATDateDataTransfer.AddSourceFilter(GLEntry.FieldNo("VAT Reporting Date"), '=%1', 0D);
        if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Posting Date" then
            VATDateDataTransfer.AddFieldValue(GLEntry.FieldNo("Posting Date"), GLEntry.FieldNo("VAT Reporting Date"))
        else
            VATDateDataTransfer.AddFieldValue(GLEntry.FieldNo("Document Date"), GLEntry.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields := false;
        VATDateDataTransfer.CopyFields();
    end;

    local procedure UpdateVATEntries()
    var
        VATEntry: Record "VAT Entry";
        VATDateDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldVATEntriesUpgrade()) then
            exit;

        VATEntry.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not VATEntry.IsEmpty then
            exit;

        VATDateDataTransfer.SetTables(Database::"VAT Entry", Database::"VAT Entry");
        VATDateDataTransfer.AddFieldValue(VATEntry.FieldNo("Posting Date"), VATEntry.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldVATEntriesUpgrade());
    end;

    local procedure UpdateGLEntries()
    var
        GLEntry: Record "G/L Entry";
        TotalRows: Integer;
        FromNo, ToNo : Integer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldGLEntriesUpgrade()) then
            exit;

        GLEntry.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not GLEntry.IsEmpty() then
            exit;

        GLEntry.Reset();
        TotalRows := GLEntry.Count();
        ToNo := 0;

        while ToNo < TotalRows do begin
            // Batch size 5 million
            FromNo := ToNo + 1;
            ToNo := FromNo + 5000000;

            if ToNo > TotalRows then
                ToNo := TotalRows;

            DataTransferGLEntries(FromNo, ToNo);
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldGLEntriesUpgrade());
    end;

    local procedure DataTransferGLEntries(FromEntryNo: Integer; ToEntryNo: Integer)
    var
        GLEntry: Record "G/L Entry";
        VATDateDataTransfer: DataTransfer;
    begin
        VATDateDataTransfer.SetTables(Database::"G/L Entry", Database::"G/L Entry");
        VATDateDataTransfer.AddSourceFilter(GLEntry.FieldNo("Entry No."), '%1..%2', FromEntryNo, ToEntryNo);
        VATDateDataTransfer.AddFieldValue(GLEntry.FieldNo("Posting Date"), GLEntry.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);
    end;

    local procedure UpdatePurchSalesEntries()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        VATDateDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldSalesPurchUpgrade()) then
            exit;

        SalesInvHeader.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not SalesInvHeader.IsEmpty then
            exit;

        SalesCrMemoHeader.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not SalesCrMemoHeader.IsEmpty then
            exit;

        PurchInvHeader.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not PurchInvHeader.IsEmpty then
            exit;

        PurchCrMemoHeader.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not PurchCrMemoHeader.IsEmpty then
            exit;

        VATDateDataTransfer.SetTables(Database::"Sales Invoice Header", Database::"Sales Invoice Header");
        VATDateDataTransfer.AddFieldValue(SalesInvHeader.FieldNo("Posting Date"), SalesInvHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        VATDateDataTransfer.SetTables(Database::"Sales Cr.Memo Header", Database::"Sales Cr.Memo Header");
        VATDateDataTransfer.AddFieldValue(SalesCrMemoHeader.FieldNo("Posting Date"), SalesCrMemoHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        VATDateDataTransfer.SetTables(Database::"Purch. Inv. Header", Database::"Purch. Inv. Header");
        VATDateDataTransfer.AddFieldValue(PurchInvHeader.FieldNo("Posting Date"), PurchInvHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        VATDateDataTransfer.SetTables(Database::"Purch. Cr. Memo Hdr.", Database::"Purch. Cr. Memo Hdr.");
        VATDateDataTransfer.AddFieldValue(PurchCrMemoHeader.FieldNo("Posting Date"), PurchCrMemoHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldSalesPurchUpgrade());
    end;

    local procedure UpdatePurchSalesBlankEntries()
    var
        GLSetup: Record "General Ledger Setup";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        VATDateDataTransfer: DataTransfer;
    begin
        if not GLSetup.Get() then
            exit;

        // Only update entries that has blank VAT Reporting Date
        VATDateDataTransfer.SetTables(Database::"Sales Invoice Header", Database::"Sales Invoice Header");
        VATDateDataTransfer.AddSourceFilter(SalesInvHeader.FieldNo("VAT Reporting Date"), '=%1', 0D);
        if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Posting Date" then
            VATDateDataTransfer.AddFieldValue(SalesInvHeader.FieldNo("Posting Date"), SalesInvHeader.FieldNo("VAT Reporting Date"))
        else
            VATDateDataTransfer.AddFieldValue(SalesInvHeader.FieldNo("Document Date"), SalesInvHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields := false;
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        // Only update entries that has blank VAT Reporting Date
        VATDateDataTransfer.SetTables(Database::"Sales Cr.Memo Header", Database::"Sales Cr.Memo Header");
        VATDateDataTransfer.AddSourceFilter(SalesCrMemoHeader.FieldNo("VAT Reporting Date"), '=%1', 0D);
        if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Posting Date" then
            VATDateDataTransfer.AddFieldValue(SalesCrMemoHeader.FieldNo("Posting Date"), SalesCrMemoHeader.FieldNo("VAT Reporting Date"))
        else
            VATDateDataTransfer.AddFieldValue(SalesCrMemoHeader.FieldNo("Document Date"), SalesCrMemoHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields := false;
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        // Only update entries that has blank VAT Reporting Date
        VATDateDataTransfer.SetTables(Database::"Purch. Inv. Header", Database::"Purch. Inv. Header");
        VATDateDataTransfer.AddSourceFilter(PurchInvHeader.FieldNo("VAT Reporting Date"), '=%1', 0D);
        if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Posting Date" then
            VATDateDataTransfer.AddFieldValue(PurchInvHeader.FieldNo("Posting Date"), PurchInvHeader.FieldNo("VAT Reporting Date"))
        else
            VATDateDataTransfer.AddFieldValue(PurchInvHeader.FieldNo("Document Date"), PurchInvHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields := false;
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        // Only update entries that has blank VAT Reporting Date
        VATDateDataTransfer.SetTables(Database::"Purch. Cr. Memo Hdr.", Database::"Purch. Cr. Memo Hdr.");
        VATDateDataTransfer.AddSourceFilter(PurchCrMemoHeader.FieldNo("VAT Reporting Date"), '=%1', 0D);
        if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Posting Date" then
            VATDateDataTransfer.AddFieldValue(PurchCrMemoHeader.FieldNo("Posting Date"), PurchCrMemoHeader.FieldNo("VAT Reporting Date"))
        else
            VATDateDataTransfer.AddFieldValue(PurchCrMemoHeader.FieldNo("Document Date"), PurchCrMemoHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields := false;
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);
    end;

    local procedure UpdateIssuedDocsEntries()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        VATDateDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldIssuedDocsUpgrade()) then
            exit;

        IssuedReminderHeader.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not IssuedReminderHeader.IsEmpty then
            exit;

        IssuedFinChargeMemoHeader.SetFilter("VAT Reporting Date", '<>%1', BlankDate);
        if not IssuedFinChargeMemoHeader.IsEmpty then
            exit;

        VATDateDataTransfer.SetTables(Database::"Issued Reminder Header", Database::"Issued Reminder Header");
        VATDateDataTransfer.AddFieldValue(IssuedReminderHeader.FieldNo("Posting Date"), IssuedReminderHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        VATDateDataTransfer.SetTables(Database::"Issued Fin. Charge Memo Header", Database::"Issued Fin. Charge Memo Header");
        VATDateDataTransfer.AddFieldValue(IssuedFinChargeMemoHeader.FieldNo("Posting Date"), IssuedFinChargeMemoHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields(false);
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetVATDateFieldIssuedDocsUpgrade());
    end;

    local procedure UpdateIssuedDocsBlankEntries()
    var
        GLSetup: Record "General Ledger Setup";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        VATDateDataTransfer: DataTransfer;
    begin
        if not GLSetup.Get() then
            exit;

        // Only update entries that has blank VAT Reporting Date
        VATDateDataTransfer.SetTables(Database::"Issued Reminder Header", Database::"Issued Reminder Header");
        VATDateDataTransfer.AddSourceFilter(IssuedReminderHeader.FieldNo("VAT Reporting Date"), '=%1', 0D);
        if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Posting Date" then
            VATDateDataTransfer.AddFieldValue(IssuedReminderHeader.FieldNo("Posting Date"), IssuedReminderHeader.FieldNo("VAT Reporting Date"))
        else
            VATDateDataTransfer.AddFieldValue(IssuedReminderHeader.FieldNo("Document Date"), IssuedReminderHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields := false;
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);

        // Only update entries that has blank VAT Reporting Date
        VATDateDataTransfer.SetTables(Database::"Issued Fin. Charge Memo Header", Database::"Issued Fin. Charge Memo Header");
        VATDateDataTransfer.AddSourceFilter(IssuedFinChargeMemoHeader.FieldNo("VAT Reporting Date"), '=%1', 0D);
        if GLSetup."VAT Reporting Date" = GLSetup."VAT Reporting Date"::"Posting Date" then
            VATDateDataTransfer.AddFieldValue(IssuedFinChargeMemoHeader.FieldNo("Posting Date"), IssuedFinChargeMemoHeader.FieldNo("VAT Reporting Date"))
        else
            VATDateDataTransfer.AddFieldValue(IssuedFinChargeMemoHeader.FieldNo("Document Date"), IssuedFinChargeMemoHeader.FieldNo("VAT Reporting Date"));
        VATDateDataTransfer.UpdateAuditFields := false;
        VATDateDataTransfer.CopyFields();
        Clear(VATDateDataTransfer);
    end;


}
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Preview;

using Microsoft.Bank.Ledger;
using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.Navigate;
using Microsoft.HumanResources.Payables;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Warehouse.Ledger;

/// <summary>
/// Event handler for capturing and managing posting preview entries across all ledger types.
/// Intercepts posting operations to create temporary entries for preview display without database commits.
/// </summary>
/// <remarks>
/// <para>
/// <b>Core Functionality:</b>
/// Subscribes to posting events from various posting codeunits to capture entries in temporary tables.
/// Manages entry aggregation, display formatting, and transaction consistency validation.
/// </para>
/// <para>
/// <b>Supported Entry Types:</b>
/// Handles all major ledger entry types including G/L, customer, vendor, item, VAT, bank, and resource entries.
/// Provides specialized handling for document entries and navigation support.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Offers integration events for custom entry types and specialized preview display requirements.
/// Supports custom entry modification and filtering through event subscribers.
/// </para>
/// </remarks>
codeunit 20 "Posting Preview Event Handler"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempGLEntry: Record "G/L Entry" temporary;
        TempVATEntry: Record "VAT Entry" temporary;
        TempValueEntry: Record "Value Entry" temporary;
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
        TempFALedgEntry: Record "FA Ledger Entry" temporary;
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        TempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary;
        TempVendLedgEntry: Record "Vendor Ledger Entry" temporary;
        TempDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary;
        TempEmplLedgEntry: Record "Employee Ledger Entry" temporary;
        TempDtldEmplLedgEntry: Record "Detailed Employee Ledger Entry" temporary;
        TempBankAccLedgerEntry: Record "Bank Account Ledger Entry" temporary;
        TempResLedgerEntry: Record "Res. Ledger Entry" temporary;
        TempMaintenanceLedgerEntry: Record "Maintenance Ledger Entry" temporary;
        TempJobLedgerEntry: Record "Job Ledger Entry" temporary;
        TempExchRateAdjmtLedgEntry: Record "Exch. Rate Adjmt. Ledg. Entry" temporary;
        TempWarehouseEntry: Record "Warehouse Entry" temporary;
        TempPhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry" temporary;
        CommitPrevented: Boolean;
        ShowDocNo: Boolean;
        TransactionConsistent: Boolean;
        DocumentMaskTok: Label '***', Locked = true;

    /// <summary>
    /// Retrieves captured preview entries for the specified table type.
    /// Returns temporary records containing all entries captured during preview processing.
    /// </summary>
    /// <param name="TableNo">Table number identifying the entry type to retrieve</param>
    /// <param name="RecRef">Output record reference containing the captured preview entries</param>
    procedure GetEntries(TableNo: Integer; var RecRef: RecordRef)
    begin
        case TableNo of
            Database::"G/L Entry":
                RecRef.GetTable(TempGLEntry);
            Database::"Cust. Ledger Entry":
                RecRef.GetTable(TempCustLedgEntry);
            Database::"Detailed Cust. Ledg. Entry":
                RecRef.GetTable(TempDtldCustLedgEntry);
            Database::"Vendor Ledger Entry":
                RecRef.GetTable(TempVendLedgEntry);
            Database::"Detailed Vendor Ledg. Entry":
                RecRef.GetTable(TempDtldVendLedgEntry);
            Database::"Employee Ledger Entry":
                RecRef.GetTable(TempEmplLedgEntry);
            Database::"Detailed Employee Ledger Entry":
                RecRef.GetTable(TempDtldEmplLedgEntry);
            Database::"VAT Entry":
                RecRef.GetTable(TempVATEntry);
            Database::"Value Entry":
                RecRef.GetTable(TempValueEntry);
            Database::"Item Ledger Entry":
                RecRef.GetTable(TempItemLedgerEntry);
            Database::"FA Ledger Entry":
                RecRef.GetTable(TempFALedgEntry);
            Database::"Bank Account Ledger Entry":
                RecRef.GetTable(TempBankAccLedgerEntry);
            Database::"Res. Ledger Entry":
                RecRef.GetTable(TempResLedgerEntry);
            Database::"Maintenance Ledger Entry":
                RecRef.GetTable(TempMaintenanceLedgerEntry);
            Database::"Job Ledger Entry":
                RecRef.GetTable(TempJobLedgerEntry);
            Database::"Exch. Rate Adjmt. Ledg. Entry":
                RecRef.GetTable(TempExchRateAdjmtLedgEntry);
            Database::"Warehouse Entry":
                RecRef.GetTable(TempWarehouseEntry);
            Database::"Phys. Inventory Ledger Entry":
                RecRef.GetTable(TempPhysInventoryLedgerEntry);
            else
                OnGetEntries(TableNo, RecRef);
        end
    end;

    /// <summary>
    /// Determines whether the posting preview transaction maintained consistency.
    /// Validates that all preview operations completed without transaction errors or rollbacks.
    /// </summary>
    /// <returns>True if transaction remained consistent throughout preview processing</returns>
    procedure IsTransactionConsistent(): Boolean
    begin
        exit(TransactionConsistent);
    end;

    /// <summary>
    /// Displays detailed entries for the specified table type in appropriate preview pages.
    /// Opens specialized preview pages showing captured entries for comprehensive analysis.
    /// </summary>
    /// <param name="TableNo">Table number identifying the entry type to display</param>
    procedure ShowEntries(TableNo: Integer)
    var
        CustLedgEntriesPreview: Page "Cust. Ledg. Entries Preview";
        VendLedgEntriesPreview: Page "Vend. Ledg. Entries Preview";
        ItemLedgerEntriesPreview: Page "Item Ledger Entries Preview";
        EmplLedgerEntriesPreview: Page "Empl. Ledger Entries Preview";
    begin
        case TableNo of
            Database::"G/L Entry":
                Page.Run(Page::"G/L Entries Preview", TempGLEntry);
            Database::"Cust. Ledger Entry":
                begin
                    CustLedgEntriesPreview.Set(TempCustLedgEntry, TempDtldCustLedgEntry);
                    CustLedgEntriesPreview.Run();
                    Clear(CustLedgEntriesPreview);
                end;
            Database::"Detailed Cust. Ledg. Entry":
                Page.Run(Page::"Det. Cust. Ledg. Entr. Preview", TempDtldCustLedgEntry);
            Database::"Vendor Ledger Entry":
                begin
                    VendLedgEntriesPreview.Set(TempVendLedgEntry, TempDtldVendLedgEntry);
                    VendLedgEntriesPreview.Run();
                    Clear(VendLedgEntriesPreview);
                end;
            Database::"Detailed Vendor Ledg. Entry":
                Page.Run(Page::"Detailed Vend. Entries Preview", TempDtldVendLedgEntry);
            Database::"Employee Ledger Entry":
                begin
                    EmplLedgerEntriesPreview.Set(TempEmplLedgEntry, TempDtldEmplLedgEntry);
                    EmplLedgerEntriesPreview.Run();
                    Clear(EmplLedgerEntriesPreview);
                end;
            Database::"Detailed Employee Ledger Entry":
                Page.Run(Page::"Detailed Empl. Entries Preview", TempDtldEmplLedgEntry);
            Database::"VAT Entry":
                Page.Run(Page::"VAT Entries Preview", TempVATEntry);
            Database::"Value Entry":
                Page.Run(Page::"Value Entries Preview", TempValueEntry);
            Database::"Item Ledger Entry":
                begin
                    ItemLedgerEntriesPreview.Set(TempItemLedgerEntry, TempValueEntry);
                    ItemLedgerEntriesPreview.Run();
                    Clear(ItemLedgerEntriesPreview);
                end;
            Database::"FA Ledger Entry":
                Page.Run(Page::"FA Ledger Entries Preview", TempFALedgEntry);
            Database::"Bank Account Ledger Entry":
                Page.Run(Page::"Bank Acc. Ledg. Entr. Preview", TempBankAccLedgerEntry);
            Database::"Res. Ledger Entry":
                Page.Run(Page::"Resource Ledg. Entries Preview", TempResLedgerEntry);
            Database::"Maintenance Ledger Entry":
                Page.Run(Page::"Maint. Ledg. Entries Preview", TempMaintenanceLedgerEntry);
            Database::"Job Ledger Entry":
                Page.Run(Page::"Job Ledger Entries Preview", TempJobLedgerEntry);
            Database::"Exch. Rate Adjmt. Ledg. Entry":
                Page.Run(Page::"Exch.Rate Adjmt. Ledg.Entries", TempExchRateAdjmtLedgEntry);
            Database::"Warehouse Entry":
                Page.Run(Page::"Warehouse Entries", TempWarehouseEntry);
            Database::"Phys. Inventory Ledger Entry":
                Page.Run(Page::"Phys. Inventory Ledger Entries", TempPhysInventoryLedgerEntry);
            else
                OnAfterShowEntries(TableNo);
        end;
    end;

    /// <summary>
    /// Fills the temporary Document Entry table with all posted entries from the preview transaction.
    /// </summary>
    /// <param name="TempDocumentEntry">Temporary table to populate with document entry records.</param>
    procedure FillDocumentEntry(var TempDocumentEntry: Record "Document Entry" temporary)
    begin
        TempDocumentEntry.DeleteAll();
        InsertDocumentEntry(TempGLEntry, TempDocumentEntry);
        InsertDocumentEntry(TempVATEntry, TempDocumentEntry);
        InsertDocumentEntry(TempValueEntry, TempDocumentEntry);
        InsertDocumentEntry(TempItemLedgerEntry, TempDocumentEntry);
        InsertDocumentEntry(TempCustLedgEntry, TempDocumentEntry);
        InsertDocumentEntry(TempDtldCustLedgEntry, TempDocumentEntry);
        InsertDocumentEntry(TempVendLedgEntry, TempDocumentEntry);
        InsertDocumentEntry(TempDtldVendLedgEntry, TempDocumentEntry);
        InsertDocumentEntry(TempEmplLedgEntry, TempDocumentEntry);
        InsertDocumentEntry(TempDtldEmplLedgEntry, TempDocumentEntry);
        InsertDocumentEntry(TempFALedgEntry, TempDocumentEntry);
        InsertDocumentEntry(TempBankAccLedgerEntry, TempDocumentEntry);
        InsertDocumentEntry(TempResLedgerEntry, TempDocumentEntry);
        InsertDocumentEntry(TempMaintenanceLedgerEntry, TempDocumentEntry);
        InsertDocumentEntry(TempJobLedgerEntry, TempDocumentEntry);
        InsertDocumentEntry(TempExchRateAdjmtLedgEntry, TempDocumentEntry);
        InsertDocumentEntry(TempWarehouseEntry, TempDocumentEntry);
        InsertDocumentEntry(TempPhysInventoryLedgerEntry, TempDocumentEntry);

        OnAfterFillDocumentEntry(TempDocumentEntry);
    end;

    /// <summary>
    /// Inserts a single preview entry into the temporary Document Entry table.
    /// </summary>
    /// <param name="RecVar">Source record variant to insert as document entry.</param>
    /// <param name="TempDocumentEntry">Temporary table to insert the document entry into.</param>
    procedure InsertDocumentEntry(RecVar: Variant; var TempDocumentEntry: Record "Document Entry" temporary)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);

        if RecRef.IsEmpty() then
            exit;

        TempDocumentEntry.Init();
        TempDocumentEntry."Entry No." := RecRef.Number;
        TempDocumentEntry."Table ID" := RecRef.Number;
        TempDocumentEntry."Table Name" := RecRef.Caption;
        TempDocumentEntry."No. of Records" := RecRef.Count();
        TempDocumentEntry.Insert();
    end;

    /// <summary>
    /// Prevents database commits during preview operations to maintain preview-only transaction state.
    /// </summary>
    procedure PreventCommit()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if CommitPrevented then
            exit;

        // Mark any table as inconsistent as long as it is not made consistent later in the transaction
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader.Consistent(false);
        CommitPrevented := true;
    end;

    /// <summary>
    /// Controls whether document numbers are displayed in preview results.
    /// </summary>
    /// <param name="NewShowDocNo">True to show document numbers, false to hide them.</param>
    procedure SetShowDocumentNo(NewShowDocNo: Boolean)
    begin
        ShowDocNo := NewShowDocNo;
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertGLEntry(var Rec: Record "G/L Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempGLEntry := Rec;
        if not ShowDocNo then
            TempGLEntry."Document No." := DocumentMaskTok;
        TempGLEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyGLEntry(var Rec: Record "G/L Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempGLEntry := Rec;
        if not ShowDocNo then
            TempGLEntry."Document No." := DocumentMaskTok;

        OnBeforeModifyTempGLEntry(Rec, TempGLEntry);

        if TempGLEntry.Modify() then
            PreventCommit();
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertVATEntry(var Rec: Record "VAT Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempVATEntry := Rec;
        if not ShowDocNo then
            TempVATEntry."Document No." := DocumentMaskTok;
        TempVATEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyVATEntry(var Rec: Record "VAT Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempVATEntry := Rec;
        if not ShowDocNo then
            TempVATEntry."Document No." := DocumentMaskTok;

        OnBeforeModifyTempVATEntry(Rec, TempVATEntry);

        if TempVATEntry.Modify() then
            PreventCommit();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Value Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertValueEntry(var Rec: Record "Value Entry")
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempValueEntry := Rec;
        if not ShowDocNo then
            TempValueEntry."Document No." := DocumentMaskTok;
        TempValueEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Value Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyValueEntry(var Rec: Record "Value Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempValueEntry := Rec;
        if not ShowDocNo then
            TempValueEntry."Document No." := DocumentMaskTok;

        OnBeforeModifyTempValueEntry(Rec, TempValueEntry);

        if TempValueEntry.Modify() then
            PreventCommit();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertItemLedgerEntry(var Rec: Record "Item Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempItemLedgerEntry := Rec;
        if not ShowDocNo then
            TempItemLedgerEntry."Document No." := DocumentMaskTok;
        TempItemLedgerEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyItemLedgerEntry(var Rec: Record "Item Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempItemLedgerEntry := Rec;
        if not ShowDocNo then
            TempItemLedgerEntry."Document No." := DocumentMaskTok;

        OnBeforeModifyTempItemLedgerEntry(Rec, TempItemLedgerEntry);

        if TempItemLedgerEntry.Modify() then
            PreventCommit();
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Ledger Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertFALedgEntry(var Rec: Record "FA Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempFALedgEntry := Rec;
        if not ShowDocNo then
            TempFALedgEntry."Document No." := DocumentMaskTok;
        TempFALedgEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"FA Ledger Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyFALedgEntry(var Rec: Record "FA Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempFALedgEntry := Rec;
        if not ShowDocNo then
            TempFALedgEntry."Document No." := DocumentMaskTok;

        OnBeforeModifyTempFALedgEntry(Rec, TempFALedgEntry);

        if TempFALedgEntry.Modify() then
            PreventCommit();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertCustLedgerEntry(var Rec: Record "Cust. Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempCustLedgEntry := Rec;
        if not ShowDocNo then
            TempCustLedgEntry."Document No." := DocumentMaskTok;
        TempCustLedgEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyCustLedgerEntry(var Rec: Record "Cust. Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempCustLedgEntry := Rec;
        if not ShowDocNo then
            TempCustLedgEntry."Document No." := DocumentMaskTok;

        OnBeforeModifyTempCustLedgEntry(Rec, TempCustLedgEntry);

        if TempCustLedgEntry.Modify() then
            PreventCommit();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Detailed Cust. Ledg. Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertDetailedCustLedgEntry(var Rec: Record "Detailed Cust. Ledg. Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempDtldCustLedgEntry := Rec;
        if not ShowDocNo then
            TempDtldCustLedgEntry."Document No." := DocumentMaskTok;
        TempDtldCustLedgEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Detailed Cust. Ledg. Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyDetailedCustLedgerEntry(var Rec: Record "Detailed Cust. Ledg. Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempDtldCustLedgEntry := Rec;
        if not ShowDocNo then
            TempDtldCustLedgEntry."Document No." := DocumentMaskTok;

        OnBeforeModifyTempDtldCustLedgEntry(Rec, TempDtldCustLedgEntry);

        if TempDtldCustLedgEntry.Modify() then
            PreventCommit();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertVendorLedgerEntry(var Rec: Record "Vendor Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempVendLedgEntry := Rec;
        if not ShowDocNo then
            TempVendLedgEntry."Document No." := DocumentMaskTok;
        TempVendLedgEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyVendorLedgerEntry(var Rec: Record "Vendor Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempVendLedgEntry := Rec;
        if not ShowDocNo then
            TempVendLedgEntry."Document No." := DocumentMaskTok;

        OnBeforeModifyTempVendLedgEntry(Rec, TempVendLedgEntry);

        if TempVendLedgEntry.Modify() then
            PreventCommit();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Detailed Vendor Ledg. Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertDetailedVendorLedgEntry(var Rec: Record "Detailed Vendor Ledg. Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempDtldVendLedgEntry := Rec;
        if not ShowDocNo then
            TempDtldVendLedgEntry."Document No." := DocumentMaskTok;
        TempDtldVendLedgEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Detailed Vendor Ledg. Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyDetailedVendorLedgerEntry(var Rec: Record "Detailed Vendor Ledg. Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempDtldVendLedgEntry := Rec;
        if not ShowDocNo then
            TempDtldVendLedgEntry."Document No." := DocumentMaskTok;

        OnBeforeModifyTempDtldVendLedgEntry(Rec, TempDtldVendLedgEntry);

        if TempDtldVendLedgEntry.Modify() then
            PreventCommit();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Employee Ledger Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertEmployeeLedgerEntry(var Rec: Record "Employee Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempEmplLedgEntry := Rec;
        if not ShowDocNo then
            TempEmplLedgEntry."Document No." := DocumentMaskTok;
        TempEmplLedgEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Employee Ledger Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyEmployeeLedgerEntry(var Rec: Record "Employee Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempEmplLedgEntry := Rec;
        if not ShowDocNo then
            TempEmplLedgEntry."Document No." := DocumentMaskTok;

        OnBeforeModifyTempEmplLedgEntry(Rec, TempEmplLedgEntry);

        if TempEmplLedgEntry.Modify() then
            PreventCommit();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Detailed Employee Ledger Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertDetailedEmployeeLedgerEntry(var Rec: Record "Detailed Employee Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempDtldEmplLedgEntry := Rec;
        if not ShowDocNo then
            TempDtldEmplLedgEntry."Document No." := DocumentMaskTok;
        TempDtldEmplLedgEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Detailed Employee Ledger Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyDetailedEmployeeLedgerEntry(var Rec: Record "Detailed Employee Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempDtldEmplLedgEntry := Rec;
        if not ShowDocNo then
            TempDtldEmplLedgEntry."Document No." := DocumentMaskTok;

        OnBeforeModifyTempDtldEmplLedgEntry(Rec, TempDtldEmplLedgEntry);

        if TempDtldEmplLedgEntry.Modify() then
            PreventCommit();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account Ledger Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertBankAccountLedgerEntry(var Rec: Record "Bank Account Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempBankAccLedgerEntry := Rec;
        if not ShowDocNo then
            TempBankAccLedgerEntry."Document No." := DocumentMaskTok;
        TempBankAccLedgerEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account Ledger Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyBankAccountLedgerEntry(var Rec: Record "Bank Account Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempBankAccLedgerEntry := Rec;
        if not ShowDocNo then
            TempBankAccLedgerEntry."Document No." := DocumentMaskTok;

        OnBeforeModifyTempBankAccLedgerEntry(Rec, TempBankAccLedgerEntry);

        if TempBankAccLedgerEntry.Modify() then
            PreventCommit();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Res. Ledger Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertResourceLedgerEntry(var Rec: Record "Res. Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempResLedgerEntry := Rec;
        if not ShowDocNo then
            TempResLedgerEntry."Document No." := DocumentMaskTok;
        TempResLedgerEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Res. Ledger Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyResLedgerEntry(var Rec: Record "Res. Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempResLedgerEntry := Rec;
        if not ShowDocNo then
            TempResLedgerEntry."Document No." := DocumentMaskTok;

        OnBeforeModifyTempResLedgerEntry(Rec, TempResLedgerEntry);

        if TempResLedgerEntry.Modify() then
            PreventCommit();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Maintenance Ledger Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertMaintenanceLedgerEntry(var Rec: Record "Maintenance Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempMaintenanceLedgerEntry := Rec;
        if not ShowDocNo then
            TempMaintenanceLedgerEntry."Document No." := DocumentMaskTok;
        TempMaintenanceLedgerEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Maintenance Ledger Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyMaintenanceLedgerEntry(var Rec: Record "Maintenance Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempMaintenanceLedgerEntry := Rec;
        if not ShowDocNo then
            TempMaintenanceLedgerEntry."Document No." := DocumentMaskTok;

        OnBeforeModifyTempMaintenanceLedgerEntry(Rec, TempMaintenanceLedgerEntry);

        if TempMaintenanceLedgerEntry.Modify() then
            PreventCommit();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Ledger Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertJobLedgEntry(var Rec: Record "Job Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempJobLedgerEntry := Rec;
        if not ShowDocNo then
            TempJobLedgerEntry."Document No." := DocumentMaskTok;
        TempJobLedgerEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Ledger Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyJobLedgEntry(var Rec: Record "Job Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempJobLedgerEntry := Rec;
        if not ShowDocNo then
            TempJobLedgerEntry."Document No." := DocumentMaskTok;

        OnBeforeModifyTempJobLedgerEntry(Rec, TempJobLedgerEntry);

        if TempJobLedgerEntry.Modify() then
            PreventCommit();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Exch. Rate Adjmt. Ledg. Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertExchRateAdjmtLedgEntry(var Rec: Record "Exch. Rate Adjmt. Ledg. Entry")
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempExchRateAdjmtLedgEntry := Rec;
        if not ShowDocNo then
            TempExchRateAdjmtLedgEntry."Document No." := DocumentMaskTok;
        TempExchRateAdjmtLedgEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Exch. Rate Adjmt. Ledg. Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyExchRateAdjmtLedgEntry(var Rec: Record "Exch. Rate Adjmt. Ledg. Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempExchRateAdjmtLedgEntry := Rec;
        if not ShowDocNo then
            TempExchRateAdjmtLedgEntry."Document No." := DocumentMaskTok;

        OnBeforeModifyTempExchRateAdjmtLedgEntry(Rec, TempExchRateAdjmtLedgEntry);

        if TempExchRateAdjmtLedgEntry.Modify() then
            PreventCommit();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertWarehouseEntry(var Rec: Record "Warehouse Entry")
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempWarehouseEntry := Rec;
        if not ShowDocNo then
            TempWarehouseEntry."Whse. Document No." := DocumentMaskTok;
        TempWarehouseEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyWarehouseEntry(var Rec: Record "Warehouse Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempWarehouseEntry := Rec;
        if not ShowDocNo then
            TempWarehouseEntry."Whse. Document No." := DocumentMaskTok;

        OnBeforeModifyTempWarehouseEntry(Rec, TempWarehouseEntry);

        if TempWarehouseEntry.Modify() then
            PreventCommit();
    end;


    [EventSubscriber(ObjectType::Table, Database::"Phys. Inventory Ledger Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertPhysInventoryLedgerEntry(var Rec: Record "Phys. Inventory Ledger Entry")
    begin
        if Rec.IsTemporary() then
            exit;

        PreventCommit();
        TempPhysInventoryLedgerEntry := Rec;
        if not ShowDocNo then
            TempPhysInventoryLedgerEntry."Document No." := DocumentMaskTok;
        TempPhysInventoryLedgerEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Phys. Inventory Ledger Entry", OnAfterModifyEvent, '', false, false)]
    local procedure OnModifyPhysInventoryLedgerEntry(var Rec: Record "Phys. Inventory Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempPhysInventoryLedgerEntry := Rec;
        if not ShowDocNo then
            TempPhysInventoryLedgerEntry."Document No." := DocumentMaskTok;

        OnBeforeModifyTempPhysInventoryLedgerEntry(Rec, TempPhysInventoryLedgerEntry);

        if TempPhysInventoryLedgerEntry.Modify() then
            PreventCommit();
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnAfterFinishPosting, '', false, false)]
    local procedure OnAfterGenJnlPostLineFinishPosting(var GlobalGLEntry: Record "G/L Entry"; var GLRegister: Record "G/L Register"; var IsTransactionConsistent: Boolean; var GenJournalLine: Record "Gen. Journal Line")
    begin
        TransactionConsistent := IsTransactionConsistent;
    end;

    /// <summary>
    /// Raised after a document entry is populated during preview processing.
    /// Allows customization of document entry data for preview display.
    /// </summary>
    /// <param name="DocumentEntry">The document entry record being filled.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFillDocumentEntry(var DocumentEntry: Record "Document Entry")
    begin
    end;

    /// <summary>
    /// Raised when retrieving preview entries for a specific table during preview processing.
    /// Allows customization of which entries are included in preview display.
    /// </summary>
    /// <param name="TableNo">The table number for which entries are being retrieved.</param>
    /// <param name="RecRef">Record reference to the table being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetEntries(TableNo: Integer; var RecRef: RecordRef)
    begin
    end;

    /// <summary>
    /// Raised after preview entries have been displayed for a specific table.
    /// Allows post-display processing and cleanup for custom preview entries.
    /// </summary>
    /// <param name="TableNo">The table number whose entries were displayed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterShowEntries(TableNo: Integer)
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary G/L Entry record during preview processing.
    /// Allows customization of G/L entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The G/L Entry record being modified.</param>
    /// <param name="TempCustLedgerEntry">The temporary G/L Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempGLEntry(var Rec: Record "G/L Entry"; var TempCustLedgerEntry: Record "G/L Entry")
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary Customer Ledger Entry record during preview processing.
    /// Allows customization of customer ledger entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The Customer Ledger Entry record being modified.</param>
    /// <param name="TempCustLedgerEntry">The temporary Customer Ledger Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempCustLedgEntry(var Rec: Record "Cust. Ledger Entry"; var TempCustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary Detailed Customer Ledger Entry record during preview processing.
    /// Allows customization of detailed customer ledger entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The Detailed Customer Ledger Entry record being modified.</param>
    /// <param name="TempCustLedgerEntry">The temporary Detailed Customer Ledger Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempDtldCustLedgEntry(var Rec: Record "Detailed Cust. Ledg. Entry"; var TempCustLedgerEntry: Record "Detailed Cust. Ledg. Entry")
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary Vendor Ledger Entry record during preview processing.
    /// Allows customization of vendor ledger entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The Vendor Ledger Entry record being modified.</param>
    /// <param name="TempVendLedgerEntry">The temporary Vendor Ledger Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempVendLedgEntry(var Rec: Record "Vendor Ledger Entry"; var TempVendLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary Detailed Vendor Ledger Entry record during preview processing.
    /// Allows customization of detailed vendor ledger entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The Detailed Vendor Ledger Entry record being modified.</param>
    /// <param name="TempVendLedgerEntry">The temporary Detailed Vendor Ledger Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempDtldVendLedgEntry(var Rec: Record "Detailed Vendor Ledg. Entry"; var TempVendLedgerEntry: Record "Detailed Vendor Ledg. Entry")
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary VAT Entry record during preview processing.
    /// Allows customization of VAT entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The VAT Entry record being modified.</param>
    /// <param name="TempVATEntry">The temporary VAT Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempVATEntry(var Rec: Record "VAT Entry"; var TempVATEntry: Record "VAT Entry")
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary Value Entry record during preview processing.
    /// Allows customization of value entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The Value Entry record being modified.</param>
    /// <param name="TempValueEntry">The temporary Value Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempValueEntry(var Rec: Record "Value Entry"; var TempValueEntry: Record "Value Entry")
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary Item Ledger Entry record during preview processing.
    /// Allows customization of item ledger entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The Item Ledger Entry record being modified.</param>
    /// <param name="TempItemLedgerEntry">The temporary Item Ledger Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempItemLedgerEntry(var Rec: Record "Item Ledger Entry"; var TempItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary Fixed Asset Ledger Entry record during preview processing.
    /// Allows customization of FA ledger entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The FA Ledger Entry record being modified.</param>
    /// <param name="TempFALedgEntry">The temporary FA Ledger Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempFALedgEntry(var Rec: Record "FA Ledger Entry"; var TempFALedgEntry: Record "FA Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary Employee Ledger Entry record during preview processing.
    /// Allows customization of employee ledger entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The Employee Ledger Entry record being modified.</param>
    /// <param name="TempEmplLedgEntry">The temporary Employee Ledger Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempEmplLedgEntry(var Rec: Record "Employee Ledger Entry"; var TempEmplLedgEntry: Record "Employee Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary Bank Account Ledger Entry record during preview processing.
    /// Allows customization of bank account ledger entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The Bank Account Ledger Entry record being modified.</param>
    /// <param name="TempBankAccLedgerEntry">The temporary Bank Account Ledger Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempBankAccLedgerEntry(var Rec: Record "Bank Account Ledger Entry"; var TempBankAccLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary Resource Ledger Entry record during preview processing.
    /// Allows customization of resource ledger entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The Resource Ledger Entry record being modified.</param>
    /// <param name="TempResLedgerEntry">The temporary Resource Ledger Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempResLedgerEntry(var Rec: Record "Res. Ledger Entry"; var TempResLedgerEntry: Record "Res. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary Maintenance Ledger Entry record during preview processing.
    /// Allows customization of maintenance ledger entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The Maintenance Ledger Entry record being modified.</param>
    /// <param name="TempMaintenanceLedgerEntry">The temporary Maintenance Ledger Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempMaintenanceLedgerEntry(var Rec: Record "Maintenance Ledger Entry"; var TempMaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary Job Ledger Entry record during preview processing.
    /// Allows customization of job ledger entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The Job Ledger Entry record being modified.</param>
    /// <param name="TempJobLedgerEntry">The temporary Job Ledger Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempJobLedgerEntry(var Rec: Record "Job Ledger Entry"; var TempJobLedgerEntry: Record "Job Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary Exchange Rate Adjustment Ledger Entry record during preview processing.
    /// Allows customization of exchange rate adjustment entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The Exchange Rate Adjustment Ledger Entry record being modified.</param>
    /// <param name="TempExchRateAdjmtLedgEntry">The temporary Exchange Rate Adjustment Ledger Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempExchRateAdjmtLedgEntry(var Rec: Record "Exch. Rate Adjmt. Ledg. Entry"; var TempExchRateAdjmtLedgEntry: Record "Exch. Rate Adjmt. Ledg. Entry")
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary Warehouse Entry record during preview processing.
    /// Allows customization of warehouse entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The Warehouse Entry record being modified.</param>
    /// <param name="TempWarehouseEntry">The temporary Warehouse Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempWarehouseEntry(var Rec: Record "Warehouse Entry"; var TempWarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary Physical Inventory Ledger Entry record during preview processing.
    /// Allows customization of physical inventory entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The Physical Inventory Ledger Entry record being modified.</param>
    /// <param name="TempPhysInventoryLedgerEntry">The temporary Physical Inventory Ledger Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempPhysInventoryLedgerEntry(var Rec: Record "Phys. Inventory Ledger Entry"; var TempPhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry")
    begin
    end;

    /// <summary>
    /// Raised before modifying a temporary Detailed Employee Ledger Entry record during preview processing.
    /// Allows customization of detailed employee ledger entry data before it's stored in the preview cache.
    /// </summary>
    /// <param name="Rec">The Detailed Employee Ledger Entry record being modified.</param>
    /// <param name="TempDtldEmplLedgEntry">The temporary Detailed Employee Ledger Entry record to be modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyTempDtldEmplLedgEntry(var Rec: Record "Detailed Employee Ledger Entry"; var TempDtldEmplLedgEntry: Record "Detailed Employee Ledger Entry" temporary)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", OnSystemSetPostingPreviewActive, '', false, false)]
    local procedure SetTrueOnSystemSetPostingPreviewActive(var Result: Boolean)
    begin
        Result := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Bank. Acc. Recon. Post Preview", OnSystemSetPostingPreviewActive, '', false, false)]
    local procedure SetTrueOnSystemSetPostingPreviewActiveBankRecon(var Result: Boolean)
    begin
        Result := true;
    end;

}


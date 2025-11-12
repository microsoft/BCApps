// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Setup;
using Microsoft.CashFlow.Worksheet;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Receivables;
using Microsoft.Warehouse.Ledger;
using System.Utilities;

codeunit 361 MoveEntries
{
    Permissions = TableData "G/L Entry" = rm,
                  TableData "Cust. Ledger Entry" = rm,
                  tabledata "Detailed Cust. Ledg. Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  tabledata "Detailed Vendor Ledg. Entry" = rm,
                  TableData "Item Ledger Entry" = rm,
                  TableData "Job Ledger Entry" = rm,
                  TableData "Res. Ledger Entry" = rm,
                  TableData "Bank Account Ledger Entry" = rm,
                  TableData "Check Ledger Entry" = rm,
                  TableData "Reminder/Fin. Charge Entry" = rm,
                  TableData "Value Entry" = rm,
                  TableData "Avg. Cost Adjmt. Entry Point" = rd,
                  TableData "Inventory Adjmt. Entry (Order)" = rm,
                  TableData "Warehouse Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot delete %1 %2 because it has ledger entries in a fiscal year that has not been closed yet.';
        Text001: Label 'You cannot delete %1 %2 because there are one or more open ledger entries.';
        Text002: Label 'There are item entries that have not been adjusted for item %1. ';
#pragma warning restore AA0470
        Text003: Label 'If you delete this item the inventory valuation will be incorrect. ';
#pragma warning disable AA0470
        Text004: Label 'Use the %2 batch job before deleting the item.';
#pragma warning restore AA0470
        Text005: Label 'Adjust Cost - Item Entries';
#pragma warning disable AA0470
        Text006: Label 'You cannot delete %1 %2 because it has ledger entries.';
        Text007: Label 'You cannot delete %1 %2 because there are outstanding purchase order lines.';
        Text008: Label 'There are item entries that have not been completely invoiced for item %1. ';
#pragma warning restore AA0470
        Text009: Label 'Invoice all item entries before deleting the item.';
#pragma warning restore AA0074
        AccountingPeriod: Record "Accounting Period";
        GLEntry: Record "G/L Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        CheckLedgEntry: Record "Check Ledger Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        ResLedgEntry: Record "Res. Ledger Entry";
        JobLedgEntry: Record "Job Ledger Entry";
        PurchOrderLine: Record "Purchase Line";
        ReminderEntry: Record "Reminder/Fin. Charge Entry";
        ValueEntry: Record "Value Entry";
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        CannotDeleteGLBudgetEntriesErr: Label 'You cannot delete G/L account %1 because it contains budget ledger entries after %2 for G/L budget name %3.', Comment = '%1 - G/L Account No., %2 - Date, %3 - G/L Budget Name. You cannot delete G/L Account 1000 because it has budget ledger entries\ after 25/01/2018 in G/L Budget Name = Budget_2018.';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text015: Label 'You cannot delete %1 %2 because there are outstanding purchase return order lines.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        TimeSheetLinesErr: Label 'You cannot delete project %1 because it has open or submitted time sheet lines.', Comment = 'You cannot delete project PROJECT001 because it has open or submitted time sheet lines.';
#pragma warning restore AA0470
        GLAccDeleteClosedPeriodsQst: Label 'Note that accounting regulations may require that you save accounting data for a certain number of years. Are you sure you want to delete the G/L account?';
        CannotDeleteGLAccountWithEntriesInOpenFiscalYearErr: Label 'You cannot delete G/L account %1 because it has ledger entries in a fiscal year that has not been closed yet.', Comment = '%1 - G/L Account No. You cannot delete G/L Account 1000 because it has ledger entries in a fiscal year that has not been closed yet.';
        CannotDeleteGLAccountWithEntriesAfterDateErr: Label 'You cannot delete G/L account %1 because it has ledger entries posted after %2.', Comment = '%1 - G/L Account No., %2 - Date. You cannot delete G/L Account 1000 because it has ledger entries posted after 01-01-2010.';

    procedure MoveGLEntries(GLAcc: Record "G/L Account")
    var
        GLSetup: Record "General Ledger Setup";
        CalcGLAccWhereUsed: Codeunit "Calc. G/L Acc. Where-Used";
        NewGLAccNo: Code[20];
    begin
        OnBeforeMoveGLEntries(GLAcc, NewGLAccNo, GLEntry);

        GLSetup.Get();

        CheckGLAccountEntries(GLAcc, GLSetup);

        if GLSetup."Check G/L Account Usage" then
            CalcGLAccWhereUsed.DeleteGLNo(GLAcc."No.");

        GLEntry.Reset();
        GLEntry.SetCurrentKey("G/L Account No.");
        GLEntry.SetRange("G/L Account No.", GLAcc."No.");
        GLEntry.ModifyAll("G/L Account No.", NewGLAccNo);

        OnAfterMoveGLEntries(GLAcc, GLEntry);
    end;

    procedure MoveCustEntries(Cust: Record Customer)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
#if not CLEAN25
        ServLedgEntry: Record Microsoft.Service.Ledger."Service Ledger Entry";
        WarrantyLedgEntry: Record Microsoft.Service.Ledger."Warranty Ledger Entry";
#endif
        NewCustNo: Code[20];
    begin
        OnBeforeMoveCustEntries(Cust, NewCustNo);

        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
        CustLedgEntry.SetRange("Customer No.", Cust."No.");
        SetCustLedgEntryFilterByAccPeriod();
        if not CustLedgEntry.IsEmpty() then begin
            OnMoveCustEntriesOnBeforeError(Cust);
            Error(
              Text000,
              Cust.TableCaption(), Cust."No.");
        end;

        CustLedgEntry.Reset();
        if not CustLedgEntry.SetCurrentKey("Customer No.", Open) then
            CustLedgEntry.SetCurrentKey("Customer No.");
        CustLedgEntry.SetRange("Customer No.", Cust."No.");
        CustLedgEntry.SetRange(Open, true);
        if not CustLedgEntry.IsEmpty() then
            Error(
              Text001,
              Cust.TableCaption(), Cust."No.");

        ReminderEntry.Reset();
        ReminderEntry.SetCurrentKey("Customer No.");
        ReminderEntry.SetRange("Customer No.", Cust."No.");
        ReminderEntry.ModifyAll("Customer No.", NewCustNo);

        CustLedgEntry.SetRange(Open);
        CustLedgEntry.ModifyAll("Customer No.", NewCustNo);

        DetailedCustLedgEntry.SetRange("Customer No.", Cust."No.");
        DetailedCustLedgEntry.ModifyAll("Customer No.", NewCustNo);

        OnMoveCustEntriesOnAfterModifyCustLedgEntries(Cust, NewCustNo);

#if not CLEAN25
        ServLedgEntry.SetRange("Customer No.", Cust."No.");
        WarrantyLedgEntry.SetRange("Customer No.", Cust."No.");

        OnAfterMoveCustEntries(Cust, CustLedgEntry, ReminderEntry, ServLedgEntry, WarrantyLedgEntry);
#endif
    end;

    local procedure SetCustLedgEntryFilterByAccPeriod()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetCustLedgEntryFilterByAccPeriod(CustLedgEntry, IsHandled);
        if IsHandled then
            exit;

        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            CustLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
    end;

    procedure MoveVendorEntries(Vend: Record Vendor)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
#if not CLEAN25
        WarrantyLedgEntry: Record Microsoft.Service.Ledger."Warranty Ledger Entry";
#endif
        NewVendNo: Code[20];
    begin
        OnBeforeMoveVendEntries(Vend, NewVendNo);

        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date");
        VendLedgEntry.SetRange("Vendor No.", Vend."No.");
        SetVendLedgEntryFilterByAccPeriod();
        if not VendLedgEntry.IsEmpty() then
            Error(
              Text000,
              Vend.TableCaption(), Vend."No.");

        VendLedgEntry.Reset();
        if not VendLedgEntry.SetCurrentKey("Vendor No.", Open) then
            VendLedgEntry.SetCurrentKey("Vendor No.");
        VendLedgEntry.SetRange("Vendor No.", Vend."No.");
        VendLedgEntry.SetRange(Open, true);
        if not VendLedgEntry.IsEmpty() then
            Error(
              Text001,
              Vend.TableCaption(), Vend."No.");

        VendLedgEntry.SetRange(Open);
        VendLedgEntry.ModifyAll("Vendor No.", NewVendNo);

        DetailedVendorLedgEntry.SetRange("Vendor No.", Vend."No.");
        DetailedVendorLedgEntry.ModifyAll("Vendor No.", NewVendNo);

        OnMoveVendEntriesOnAfterModifyVendLedgEntries(Vend, NewVendNo);
#if not CLEAN25
        WarrantyLedgEntry.SetRange("Vendor No.", Vend."No.");
        OnAfterMoveVendorEntries(Vend, VendLedgEntry, WarrantyLedgEntry);
#endif
    end;

    local procedure SetVendLedgEntryFilterByAccPeriod()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetVendLedgEntryFilterByAccPeriod(VendLedgEntry, IsHandled);
        if IsHandled then
            exit;

        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            VendLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
    end;

    procedure MoveBankAccEntries(BankAcc: Record "Bank Account")
    var
        NewBankAccNo: Code[20];
    begin
        OnBeforeMoveBankAccEntries(BankAcc, NewBankAccNo);

        BankAccLedgEntry.Reset();
        BankAccLedgEntry.SetCurrentKey("Bank Account No.", "Posting Date");
        BankAccLedgEntry.SetRange("Bank Account No.", BankAcc."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            BankAccLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not BankAccLedgEntry.IsEmpty() then
            Error(
              Text000,
              BankAcc.TableCaption(), BankAcc."No.");

        BankAccLedgEntry.Reset();
        if not BankAccLedgEntry.SetCurrentKey("Bank Account No.", Open) then
            BankAccLedgEntry.SetCurrentKey("Bank Account No.");
        BankAccLedgEntry.SetRange("Bank Account No.", BankAcc."No.");
        BankAccLedgEntry.SetRange(Open, true);
        if not BankAccLedgEntry.IsEmpty() then
            Error(
              Text001,
              BankAcc.TableCaption(), BankAcc."No.");

        BankAccLedgEntry.SetRange(Open);
        BankAccLedgEntry.ModifyAll("Bank Account No.", '');
        CheckLedgEntry.SetCurrentKey("Bank Account No.");
        CheckLedgEntry.SetRange("Bank Account No.", BankAcc."No.");
        CheckLedgEntry.ModifyAll("Bank Account No.", NewBankAccNo);

        OnAfterMoveBankAccEntries(BankAcc, BankAccLedgEntry, CheckLedgEntry);
    end;

    procedure MoveItemEntries(Item: Record Item)
    var
#if not CLEAN25
        ServiceLedgerEntry: Record Microsoft.Service.Ledger."Service Ledger Entry";
        WarrantyLedgerEntry: Record Microsoft.Service.Ledger."Warranty Ledger Entry";
#endif
        WarehouseEntry: Record "Warehouse Entry";
        AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
        NewItemNo: Code[20];
    begin
        OnBeforeMoveItemEntries(Item, NewItemNo);

        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.");
        ItemLedgEntry.SetRange("Item No.", Item."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            ItemLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ItemLedgEntry.IsEmpty() then
            Error(
              Text000,
              Item.TableCaption(), Item."No.");

        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.");
        ItemLedgEntry.SetRange("Item No.", Item."No.");
        ItemLedgEntry.SetRange("Completely Invoiced", false);
        if not ItemLedgEntry.IsEmpty() then
            Error(
              Text008 +
              Text003 +
              Text009, Item."No.");
        ItemLedgEntry.SetRange("Completely Invoiced");

        ItemLedgEntry.SetCurrentKey("Item No.", Open);
        ItemLedgEntry.SetRange(Open, true);
        OnMoveItemEntriesOnBeforeCheckForOpenEtries(ItemLedgEntry);
        if not ItemLedgEntry.IsEmpty() then
            Error(
              Text001,
              Item.TableCaption(), Item."No.");

        ItemLedgEntry.SetCurrentKey("Item No.", "Applied Entry to Adjust");
        ItemLedgEntry.SetRange(Open, false);
        ItemLedgEntry.SetRange("Applied Entry to Adjust", true);
        if not ItemLedgEntry.IsEmpty() then
            Error(
              Text002 +
              Text003 +
              Text004,
              Item."No.", Text005);
        ItemLedgEntry.SetRange("Applied Entry to Adjust");

        if Item."Costing Method" = Item."Costing Method"::Average then
            if not AvgCostEntryPointHandler.IsEntriesAdjusted(Item."No.", 0D) then
                Error(
                  Text002 +
                  Text003 +
                  Text004,
                  Item."No.", Text005);

        ItemLedgEntry.SetRange(Open);
        ItemLedgEntry.ModifyAll("Item No.", NewItemNo);

        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item No.");
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.ModifyAll("Item No.", NewItemNo);

        AvgCostEntryPointHandler.DeleteBuffer(Item."No.", 0D);

        InvtAdjmtEntryOrder.Reset();
        InvtAdjmtEntryOrder.SetRange("Item No.", Item."No.");
        InvtAdjmtEntryOrder.SetRange("Order Type", InvtAdjmtEntryOrder."Order Type"::Production);
        InvtAdjmtEntryOrder.ModifyAll("Cost is Adjusted", true);
        InvtAdjmtEntryOrder.SetRange("Order Type");
        InvtAdjmtEntryOrder.ModifyAll("Item No.", NewItemNo);

        OnMoveItemEntriesOnAfterModifyItemLedgerEntries(Item, NewItemNo);

#if not CLEAN25
        ServiceLedgerEntry.SetRange(Type, ServiceLedgerEntry.Type::Item);
        ServiceLedgerEntry.SetRange("No.", Item."No.");
        WarrantyLedgerEntry.SetRange(Type, WarrantyLedgerEntry.Type::Item);
        WarrantyLedgerEntry.SetRange("No.", Item."No.");

        OnAfterMoveItemEntries(Item, ItemLedgEntry, ValueEntry, ServiceLedgerEntry, WarrantyLedgerEntry, InvtAdjmtEntryOrder);
#endif

        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.ModifyAll("Item No.", NewItemNo);
    end;

    procedure MoveResEntries(Res: Record Resource)
    var
#if not CLEAN25
        ServiceLedgerEntry: Record Microsoft.Service.Ledger."Service Ledger Entry";
        WarrantyLedgerEntry: Record Microsoft.Service.Ledger."Warranty Ledger Entry";
#endif
        NewResNo: Code[20];
    begin
        OnBeforeMoveResEntries(Res, NewResNo);

        ResLedgEntry.Reset();
        ResLedgEntry.SetCurrentKey("Resource No.", "Posting Date");
        ResLedgEntry.SetRange("Resource No.", Res."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            ResLedgEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ResLedgEntry.IsEmpty() then
            Error(
              Text000,
              Res.TableCaption(), Res."No.");

        ResLedgEntry.Reset();
        ResLedgEntry.SetCurrentKey("Resource No.");
        ResLedgEntry.SetRange("Resource No.", Res."No.");
        ResLedgEntry.ModifyAll("Resource No.", NewResNo);

        OnMoveResEntriesOnAfterModifyResLedgerEntries(Res, NewResNo);
#if not CLEAN25
        ServiceLedgerEntry.Reset();
        ServiceLedgerEntry.SetRange(Type, ServiceLedgerEntry.Type::Resource);
        ServiceLedgerEntry.SetRange("No.", Res."No.");
        WarrantyLedgerEntry.LockTable();
        WarrantyLedgerEntry.SetRange(Type, WarrantyLedgerEntry.Type::Resource);
        WarrantyLedgerEntry.SetRange("No.", Res."No.");

        OnAfterMoveResEntries(Res, ResLedgEntry, ServiceLedgerEntry, WarrantyLedgerEntry);
#endif
    end;

    procedure MoveJobEntries(Job: Record Job)
    var
        TimeSheetLine: Record "Time Sheet Line";
#if not CLEAN25
        ServiceLedgerEntry: Record Microsoft.Service.Ledger."Service Ledger Entry";
#endif
        NewJobNo: Code[20];
    begin
        OnBeforeMoveJobEntries(Job, NewJobNo);

        JobLedgEntry.SetCurrentKey("Job No.");
        JobLedgEntry.SetRange("Job No.", Job."No.");
        if not JobLedgEntry.IsEmpty() then
            Error(
              Text006,
              Job.TableCaption(), Job."No.");

        TimeSheetLine.SetRange(Type, TimeSheetLine.Type::Job);
        TimeSheetLine.SetRange("Job No.", Job."No.");
        TimeSheetLine.SetFilter(Status, '%1|%2', TimeSheetLine.Status::Open, TimeSheetLine.Status::Submitted);
        if not TimeSheetLine.IsEmpty() then
            Error(TimeSheetLinesErr, Job."No.");

        PurchOrderLine.SetCurrentKey("Document Type");
        PurchOrderLine.SetFilter(
          "Document Type", '%1|%2',
          PurchOrderLine."Document Type"::Order,
          PurchOrderLine."Document Type"::"Return Order");
        PurchOrderLine.SetRange("Job No.", Job."No.");
        if PurchOrderLine.FindFirst() then begin
            if PurchOrderLine."Document Type" = PurchOrderLine."Document Type"::Order then
                Error(Text007, Job.TableCaption(), Job."No.");
            if PurchOrderLine."Document Type" = PurchOrderLine."Document Type"::"Return Order" then
                Error(Text015, Job.TableCaption(), Job."No.");
        end;

        OnMoveJobEntriesOnAfterModifyJobLedgerEntries(Job, NewJobNo);
#if not CLEAN25
        ServiceLedgerEntry.SetRange("Job No.", Job."No.");
        OnAfterMoveJobEntries(Job, JobLedgEntry, TimeSheetLine, ServiceLedgerEntry);
#endif
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit ServMoveEntries', '25.0')]
    procedure MoveServiceItemLedgerEntries(ServiceItem: Record Microsoft.Service.Item."Service Item")
    var
        ServMoveEntries: Codeunit "Serv. Move Entries";
    begin
        ServMoveEntries.MoveServiceItemLedgerEntries(ServiceItem);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit ServMoveEntries', '25.0')]
    procedure MoveServContractLedgerEntries(ServiceContractHeader: Record Microsoft.Service.Contract."Service Contract Header")
    var
        ServMoveEntries: Codeunit "Serv. Move Entries";
    begin
        ServMoveEntries.MoveServContractLedgerEntries(ServiceContractHeader);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit ServMoveEntries', '25.0')]
    procedure MoveServiceCostLedgerEntries(ServiceCost: Record Microsoft.Service.Pricing."Service Cost")
    var
        ServMoveEntries: Codeunit "Serv. Move Entries";
    begin
        ServMoveEntries.MoveServiceCostLedgerEntries(ServiceCost);
    end;
#endif

    procedure MoveCashFlowEntries(CashFlowAccount: Record "Cash Flow Account")
    var
        CFForecastEntry: Record "Cash Flow Forecast Entry";
        CFSetup: Record "Cash Flow Setup";
        CFWorksheetLine: Record "Cash Flow Worksheet Line";
        NewAccountNo: Code[20];
    begin
        OnBeforeMoveCashFlowEntries(CashFlowAccount, NewAccountNo);

        CashFlowAccount.LockTable();

        if CashFlowAccount."Account Type" = CashFlowAccount."Account Type"::Entry then begin
            CashFlowAccount.CalcFields(Amount);
            CashFlowAccount.TestField(Amount, 0);
        end;

        CFForecastEntry.Reset();
        CFForecastEntry.SetCurrentKey("Cash Flow Account No.");
        CFForecastEntry.SetRange("Cash Flow Account No.", CashFlowAccount."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            CFForecastEntry.SetFilter("Cash Flow Date", '>%1', AccountingPeriod."Starting Date");
        if not CFForecastEntry.IsEmpty() then
            Error(
              Text000,
              CashFlowAccount.TableCaption(), CashFlowAccount."No.");

        CFSetup.Get();
        if CFSetup."Receivables CF Account No." = CashFlowAccount."No." then
            CFSetup.ModifyAll("Receivables CF Account No.", '');

        if CFSetup."Payables CF Account No." = CashFlowAccount."No." then
            CFSetup.ModifyAll("Payables CF Account No.", '');

        if CFSetup."Sales Order CF Account No." = CashFlowAccount."No." then
            CFSetup.ModifyAll("Sales Order CF Account No.", '');

        if CFSetup."Purch. Order CF Account No." = CashFlowAccount."No." then
            CFSetup.ModifyAll("Purch. Order CF Account No.", '');

        if CFSetup."FA Budget CF Account No." = CashFlowAccount."No." then
            CFSetup.ModifyAll("FA Budget CF Account No.", '');

        if CFSetup."FA Disposal CF Account No." = CashFlowAccount."No." then
            CFSetup.ModifyAll("FA Disposal CF Account No.", '');

        CFWorksheetLine.Reset();
        CFWorksheetLine.SetRange("Cash Flow Account No.", CashFlowAccount."No.");
        CFWorksheetLine.ModifyAll("Cash Flow Account No.", '');

        CFForecastEntry.Reset();
        CFForecastEntry.SetCurrentKey("Cash Flow Forecast No.");
        CFForecastEntry.SetRange("Cash Flow Account No.", CashFlowAccount."No.");
        CFForecastEntry.ModifyAll("Cash Flow Account No.", '');

        OnAfterMoveCashFlowEntries(CashFlowAccount, CFSetup);
    end;

    procedure MoveDocRelatedEntries(TableNo: Integer; DocNo: Code[20])
    var
        ItemLedgEntry2: Record "Item Ledger Entry";
        ValueEntry2: Record "Value Entry";
        CostCalcMgt: Codeunit "Cost Calculation Management";
    begin
        OnBeforeMoveDocRelatedEntries(TableNo, DocNo);

        ItemLedgEntry2.LockTable();
        ItemLedgEntry2.SetCurrentKey("Document No.");
        ItemLedgEntry2.SetRange("Document No.", DocNo);
        ItemLedgEntry2.SetRange("Document Type", CostCalcMgt.GetDocType(TableNo));
        ItemLedgEntry2.SetFilter("Document Line No.", '<>0');
        ItemLedgEntry2.ModifyAll("Document Line No.", 0);

        ValueEntry2.LockTable();
        ValueEntry2.SetCurrentKey("Document No.");
        ValueEntry2.SetRange("Document No.", DocNo);
        ValueEntry2.SetRange("Document Type", CostCalcMgt.GetDocType(TableNo));
        ValueEntry2.SetFilter("Document Line No.", '<>0');
        ValueEntry2.ModifyAll("Document Line No.", 0);

        OnAfterMoveDocRelatedEntries(TableNo, DocNo);
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit ServMoveEntries', '25.0')]
    procedure CheckIfServiceItemCanBeDeleted(var ServiceLedgerEntry: Record Microsoft.Service.Ledger."Service Ledger Entry"; ServiceItemNo: Code[20]): Text
    var
        ServMoveEntries: Codeunit "Serv. Move Entries";
    begin
        exit(ServMoveEntries.CheckIfServiceItemCanBeDeleted(ServiceLedgerEntry, ServiceItemNo));
    end;
#endif

    local procedure CheckGLAccountEntries(GLAccount: Record "G/L Account"; var GeneralLedgerSetup: Record "General Ledger Setup")
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        ConfirmManagement: Codeunit "Confirm Management";
        HasGLEntries: Boolean;
        HasGLBudgetEntries: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLAccountEntries(GLEntry, GeneralLedgerSetup, GLAccount, IsHandled);
        if IsHandled then
            exit;

        if GLAccount."Account Type" = GLAccount."Account Type"::Posting then begin
            GLAccount.CalcFields(Balance);
            GLAccount.TestField(Balance, 0);
        end;

        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            GLEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not GLEntry.IsEmpty() then
            Error(CannotDeleteGLAccountWithEntriesInOpenFiscalYearErr, GLAccount."No.");

        AccountingPeriod.SetRange(Closed, true);
        if AccountingPeriod.IsEmpty() then
            exit;

        GeneralLedgerSetup.TestField("Block Deletion of G/L Accounts", false);
        GeneralLedgerSetup.TestField("Allow G/L Acc. Deletion Before");

        GLEntry.SetFilter("Posting Date", '>=%1', GeneralLedgerSetup."Allow G/L Acc. Deletion Before");

        GLBudgetEntry.LockTable();
        GLBudgetEntry.SetCurrentKey("Budget Name", "G/L Account No.", Date);
        GLBudgetEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLBudgetEntry.SetFilter(Date, '>=%1', GeneralLedgerSetup."Allow G/L Acc. Deletion Before");

        HasGLEntries := not GLEntry.IsEmpty();
        HasGLBudgetEntries := GLBudgetEntry.FindFirst();

        if HasGLEntries or HasGLBudgetEntries then begin
            if ConfirmManagement.GetResponseOrDefault(GLAccDeleteClosedPeriodsQst, true) then
                exit;

            if HasGLEntries then
                Error(
                  CannotDeleteGLAccountWithEntriesAfterDateErr,
                  GLAccount."No.", GeneralLedgerSetup."Allow G/L Acc. Deletion Before");
            if HasGLBudgetEntries then
                Error(
                  CannotDeleteGLBudgetEntriesErr,
                  GLAccount."No.", GeneralLedgerSetup."Allow G/L Acc. Deletion Before", GLBudgetEntry."Budget Name");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveGLEntries(GLAccount: Record "G/L Account"; var GLEntry: Record "G/L Entry")
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnMoveCustEntriesOnAfterModifyCustLedgEntries', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveCustEntries(Customer: Record Customer; var CustLedgerEntry: Record "Cust. Ledger Entry"; var ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry"; var ServiceLedgerEntry: Record Microsoft.Service.Ledger."Service Ledger Entry"; var WarrantyLedgerEntry: Record Microsoft.Service.Ledger."Warranty Ledger Entry")
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by event OnMoveVendEntriesOnAfterModifyVendLedgEntries', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveVendorEntries(Vendor: Record Vendor; var VendorLedgerEntry: Record "Vendor Ledger Entry"; var WarrantyLedgerEntry: Record Microsoft.Service.Ledger."Warranty Ledger Entry")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveBankAccEntries(BankAccount: Record "Bank Account"; var BankAccountLedgerEntry: Record "Bank Account Ledger Entry"; var CheckLedgerEntry: Record "Check Ledger Entry")
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnMoveItemEntriesOnAfterModifyItemLedgEntries', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveItemEntries(Item: Record Item; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"; var ServiceLedgerEntry: Record Microsoft.Service.Ledger."Service Ledger Entry"; var WarrantyLedgerEntry: Record Microsoft.Service.Ledger."Warranty Ledger Entry"; var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by event OnMoveResEntriesOnAfterModifyResLedgEntries', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveResEntries(Resource: Record Resource; var ResLedgerEntry: Record "Res. Ledger Entry"; var ServiceLedgerEntry: Record Microsoft.Service.Ledger."Service Ledger Entry"; var WarrantyLedgerEntry: Record Microsoft.Service.Ledger."Warranty Ledger Entry")
    begin
    end;
#endif

#if not CLEAN25
    [Obsolete('Replaced by event OnMoveJobEntriesOnAfterModifyJobLedgEntries', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveJobEntries(Job: Record Job; var JobLedgerEntry: Record "Job Ledger Entry"; var TimeSheetLine: Record "Time Sheet Line"; var ServiceLedgerEntry: Record Microsoft.Service.Ledger."Service Ledger Entry")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterMoveServiceItemLedgerEntries(ServiceItem: Record Microsoft.Service.Item."Service Item")
    begin
        OnAfterMoveServiceItemLedgerEntries(ServiceItem);
    end;

    [Obsolete('Moved to codeunit ServMoveEntries', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveServiceItemLedgerEntries(ServiceItem: Record Microsoft.Service.Item."Service Item")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterMoveServContractLedgerEntries(ServiceContractHeader: Record Microsoft.Service.Contract."Service Contract Header")
    begin
        OnAfterMoveServContractLedgerEntries(ServiceContractHeader);
    end;

    [Obsolete('Moved to codeunit ServMoveEntries', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveServContractLedgerEntries(ServiceContractHeader: Record Microsoft.Service.Contract."Service Contract Header")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterMoveServiceCostLedgerEntries(ServiceCost: Record Microsoft.Service.Pricing."Service Cost")
    begin
        OnAfterMoveServiceCostLedgerEntries(ServiceCost);
    end;

    [Obsolete('Moved to codeunit ServMoveEntries', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveServiceCostLedgerEntries(ServiceCost: Record Microsoft.Service.Pricing."Service Cost")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveCashFlowEntries(CashFlowAccount: Record "Cash Flow Account"; CashFlowSetup: Record "Cash Flow Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveDocRelatedEntries(TableNo: Integer; DocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAccountEntries(var GLEntry: Record "G/L Entry"; var GLSetup: Record "General Ledger Setup"; var GLAccount: Record "G/L Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCustLedgEntryFilterByAccPeriod(var CustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetVendLedgEntryFilterByAccPeriod(var VendLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveGLEntries(GLAccount: Record "G/L Account"; var GLAccNo: Code[20]; var GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveCustEntries(Customer: Record Customer; var NewCustNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveVendEntries(Vendor: Record Vendor; var NewVendNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveBankAccEntries(BankAccount: Record "Bank Account"; var NewBankAccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveItemEntries(Item: Record Item; var NewItemNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveResEntries(Resource: Record Resource; var NewResNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveJobEntries(Job: Record Job; var NewJobNo: Code[20])
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeMoveServiceItemLedgerEntries(ServiceItem: Record Microsoft.Service.Item."Service Item"; var NewServiceItemNo: Code[20])
    begin
        OnBeforeMoveServiceItemLedgerEntries(ServiceItem, NewServiceItemNo);
    end;

    [Obsolete('Moved to codeunit ServMoveEntries', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveServiceItemLedgerEntries(ServiceItem: Record Microsoft.Service.Item."Service Item"; var NewServiceItemNo: Code[20])
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeMoveServContractLedgerEntries(ServiceContractHeader: Record Microsoft.Service.Contract."Service Contract Header"; var NewContractNo: Code[20])
    begin
        OnBeforeMoveServContractLedgerEntries(ServiceContractHeader, NewContractNo);
    end;

    [Obsolete('Moved to codeunit ServMoveEntries', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveServContractLedgerEntries(ServiceContractHeader: Record Microsoft.Service.Contract."Service Contract Header"; var NewContractNo: Code[20])
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeMoveServiceCostLedgerEntries(ServiceCost: Record Microsoft.Service.Pricing."Service Cost"; var NewCostCode: Code[10])
    begin
        OnBeforeMoveServiceCostLedgerEntries(ServiceCost, NewCostCode);
    end;

    [Obsolete('Moved to codeunit ServMoveEntries', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveServiceCostLedgerEntries(ServiceCost: Record Microsoft.Service.Pricing."Service Cost"; var NewCostCode: Code[10])
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveCashFlowEntries(CashFlowAccount: Record "Cash Flow Account"; var NewAccountNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveDocRelatedEntries(TableNo: Integer; DocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMoveItemEntriesOnBeforeCheckForOpenEtries(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMoveCustEntriesOnBeforeError(var Cust: Record Customer)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnMoveItemEntriesOnAfterResetServLedgEntry(var ServiceLedgerEntry: Record Microsoft.Service.Ledger."Service Ledger Entry")
    begin
        OnMoveItemEntriesOnAfterResetServLedgEntry(ServiceLedgerEntry);
    end;

    [Obsolete('Moved to codeunit ServMoveEntries', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnMoveItemEntriesOnAfterResetServLedgEntry(var ServiceLedgerEntry: Record Microsoft.Service.Ledger."Service Ledger Entry")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnMoveCustEntriesOnAfterModifyCustLedgEntries(var Customer: Record Customer; NewCustNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMoveVendEntriesOnAfterModifyVendLedgEntries(var Vendor: Record Vendor; NewVendNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMoveItemEntriesOnAfterModifyItemLedgerEntries(var Item: Record Item; NewItemNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMoveResEntriesOnAfterModifyResLedgerEntries(var Resource: Record Resource; NewResNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMoveJobEntriesOnAfterModifyJobLedgerEntries(var Job: Record Job; NewJobNo: Code[20])
    begin
    end;
}


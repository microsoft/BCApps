// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Setup;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Service.Contract;
using Microsoft.Service.Ledger;
using Microsoft.Service.Item;
using Microsoft.Service.Pricing;

codeunit 6492 "Serv. Move Entries"
{
    Permissions = TableData "Service Ledger Entry" = rm,
                  TableData "Warranty Ledger Entry" = rm,
                  TableData "Service Contract Header" = rm;

    var
        AccountingPeriod: Record "Accounting Period";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
        ServiceItem: Record "Service Item";
        ServiceItemComponent: Record "Service Item Component";
        ServContract: Record "Service Contract Header";
#if not CLEAN25
        MoveEntries: Codeunit MoveEntries;
#endif
        CannotDeleteLedgerEntriesInFiscalYearErr: Label 'You cannot delete %1 %2 because it has ledger entries in a fiscal year that has not been closed yet.', Comment = '%1 - table caption, %2 - customer number';
        CannotDeleteOpenLedgerEntriesErr: Label 'You cannot delete %1 %2 because there are one or more open ledger entries.', Comment = '%1 - table caption, %2 - customer number';
        CannotDeletePrepaidContractEntriesErr: Label 'You cannot delete %1 because prepaid contract entries exist in %2.', Comment = '%1 - table caption, %2 - contract number';
        CannotDeleteOpenPrepaidContractEntriesErr: Label 'You cannot delete %1, because open prepaid contract entries exist in %2.', Comment = '%1 - table caption, %2 - customer number';
        CannotDeleteBecauseServiceContractErr: Label 'You cannot delete customer %1 because there is at least one not cancelled Service Contract for this customer.', Comment = '%1 - Customer No.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::MoveEntries, 'OnMoveCustEntriesOnAfterModifyCustLedgEntries', '', false, false)]
    local procedure OnMoveCustEntriesOnAfterModifyCustLedgEntries(var Customer: Record Customer; NewCustNo: Code[20])
    begin
        ServiceLedgerEntry.Reset();
        ServiceLedgerEntry.SetRange("Customer No.", Customer."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            ServiceLedgerEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServiceLedgerEntry.IsEmpty() then
            Error(CannotDeleteLedgerEntriesInFiscalYearErr, Customer.TableCaption(), Customer."No.");

        ServiceLedgerEntry.SetRange("Posting Date");
        ServiceLedgerEntry.SetRange(Open, true);
        if not ServiceLedgerEntry.IsEmpty() then
            Error(CannotDeleteOpenLedgerEntriesErr, Customer.TableCaption(), Customer."No.");

        ServiceLedgerEntry.SetRange(Open);
        ServiceLedgerEntry.ModifyAll("Customer No.", NewCustNo);

        ServiceLedgerEntry.Reset();
        ServiceLedgerEntry.SetRange("Bill-to Customer No.", Customer."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            ServiceLedgerEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServiceLedgerEntry.IsEmpty() then
            Error(CannotDeleteLedgerEntriesInFiscalYearErr, Customer.TableCaption(), Customer."No.");

        ServiceLedgerEntry.SetRange("Posting Date");
        ServiceLedgerEntry.SetRange(Open, true);
        if not ServiceLedgerEntry.IsEmpty() then
            Error(CannotDeleteOpenLedgerEntriesErr, Customer.TableCaption(), Customer."No.");

        ServiceLedgerEntry.SetRange(Open);
        ServiceLedgerEntry.ModifyAll("Bill-to Customer No.", NewCustNo);

        WarrantyLedgerEntry.LockTable();
        WarrantyLedgerEntry.SetRange("Customer No.", Customer."No.");
        WarrantyLedgerEntry.ModifyAll("Customer No.", NewCustNo);

        WarrantyLedgerEntry.SetRange("Customer No.");
        WarrantyLedgerEntry.SetRange("Bill-to Customer No.", Customer."No.");
        WarrantyLedgerEntry.ModifyAll("Bill-to Customer No.", NewCustNo);

        ServContract.SetFilter(Status, '<>%1', ServContract.Status::Cancelled);
        ServContract.SetRange("Customer No.", Customer."No.");
        if not ServContract.IsEmpty() then
            Error(CannotDeleteBecauseServiceContractErr, Customer."No.");

        ServContract.SetRange(Status);
        ServContract.ModifyAll("Customer No.", NewCustNo);

        ServContract.Reset();
        ServContract.SetFilter(Status, '<>%1', ServContract.Status::Cancelled);
        ServContract.SetRange("Bill-to Customer No.", Customer."No.");
        if not ServContract.IsEmpty() then
            Error(CannotDeleteBecauseServiceContractErr, Customer."No.");

        ServContract.SetRange(Status);
        ServContract.ModifyAll("Bill-to Customer No.", NewCustNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::MoveEntries, 'OnMoveVendEntriesOnAfterModifyVendLedgEntries', '', false, false)]
    local procedure OnMoveVendEntriesOnAfterModifyVendLedgEntries(var Vendor: Record Vendor; NewVendNo: Code[20])
    begin
        WarrantyLedgerEntry.LockTable();
        WarrantyLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        WarrantyLedgerEntry.ModifyAll("Vendor No.", NewVendNo);

        ServiceItem.SetRange("Vendor No.", Vendor."No.");
        if not ServiceItem.IsEmpty() then
            ServiceItem.ModifyAll("Vendor No.", NewVendNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::MoveEntries, 'OnMoveItemEntriesOnAfterModifyItemLedgerEntries', '', false, false)]
    local procedure OnMoveItemEntriesOnAfterModifyItemLedgerEntries(var Item: Record Item; NewItemNo: Code[20])
    begin
        ServiceLedgerEntry.Reset();
        OnMoveItemEntriesOnAfterResetServLedgEntry(ServiceLedgerEntry);
        ServiceLedgerEntry.SetRange("Item No. (Serviced)", Item."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            ServiceLedgerEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServiceLedgerEntry.IsEmpty() then
            Error(
              CannotDeleteLedgerEntriesInFiscalYearErr,
              Item.TableCaption(), Item."No.");

        ServiceLedgerEntry.SetRange("Posting Date");
        ServiceLedgerEntry.SetRange(Open, true);
        if not ServiceLedgerEntry.IsEmpty() then
            Error(
              CannotDeleteOpenLedgerEntriesErr,
              Item.TableCaption(), Item."No.");

        ServiceLedgerEntry.SetRange(Open);
        ServiceLedgerEntry.ModifyAll("Item No. (Serviced)", NewItemNo);

        ServiceLedgerEntry.SetRange("Item No. (Serviced)");
        ServiceLedgerEntry.SetRange(Type, ServiceLedgerEntry.Type::Item);
        ServiceLedgerEntry.SetRange("No.", Item."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            ServiceLedgerEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServiceLedgerEntry.IsEmpty() then
            Error(
              CannotDeleteLedgerEntriesInFiscalYearErr,
              Item.TableCaption(), Item."No.");

        ServiceLedgerEntry.SetRange("Posting Date");
        ServiceLedgerEntry.SetRange(Open, true);
        if not ServiceLedgerEntry.IsEmpty() then
            Error(
              CannotDeleteOpenLedgerEntriesErr,
              Item.TableCaption(), Item."No.");

        ServiceLedgerEntry.SetRange(Open);
        ServiceLedgerEntry.ModifyAll("No.", NewItemNo);

        WarrantyLedgerEntry.LockTable();
        WarrantyLedgerEntry.SetRange("Item No. (Serviced)", Item."No.");
        WarrantyLedgerEntry.ModifyAll("Item No. (Serviced)", NewItemNo);

        WarrantyLedgerEntry.SetRange("Item No. (Serviced)");
        WarrantyLedgerEntry.SetRange(Type, WarrantyLedgerEntry.Type::Item);
        WarrantyLedgerEntry.SetRange("No.", Item."No.");
        WarrantyLedgerEntry.ModifyAll("No.", NewItemNo);

        ServiceItem.Reset();
        ServiceItem.SetRange("Item No.", Item."No.");
        if not ServiceItem.IsEmpty() then
            ServiceItem.ModifyAll("Item No.", NewItemNo, true);

        ServiceItemComponent.Reset();
        ServiceItemComponent.SetRange(Type, ServiceItemComponent.Type::Item);
        ServiceItemComponent.SetRange("No.", Item."No.");
        if not ServiceItemComponent.IsEmpty() then
            ServiceItemComponent.ModifyAll("No.", NewItemNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMoveItemEntriesOnAfterResetServLedgEntry(var ServiceLedgerEntry: Record "Service Ledger Entry")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::MoveEntries, 'OnMoveResEntriesOnAfterModifyResLedgerEntries', '', false, false)]
    local procedure OnMoveResEntriesOnAfterModifyResLedgerEntries(var Resource: Record Resource; NewResNo: Code[20])
    begin
        ServiceLedgerEntry.Reset();
        ServiceLedgerEntry.SetRange(Type, ServiceLedgerEntry.Type::Resource);
        ServiceLedgerEntry.SetRange("No.", Resource."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            ServiceLedgerEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServiceLedgerEntry.IsEmpty() then
            Error(CannotDeleteLedgerEntriesInFiscalYearErr, Resource.TableCaption(), Resource."No.");

        ServiceLedgerEntry.SetRange("Posting Date");
        ServiceLedgerEntry.SetRange(Open, true);
        if not ServiceLedgerEntry.IsEmpty() then
            Error(CannotDeleteOpenLedgerEntriesErr, Resource.TableCaption(), Resource."No.");

        ServiceLedgerEntry.SetRange(Open);
        ServiceLedgerEntry.ModifyAll("No.", NewResNo);

        WarrantyLedgerEntry.LockTable();
        WarrantyLedgerEntry.SetRange(Type, WarrantyLedgerEntry.Type::Resource);
        WarrantyLedgerEntry.SetRange("No.", Resource."No.");
        WarrantyLedgerEntry.ModifyAll("No.", NewResNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::MoveEntries, 'OnMoveJobEntriesOnAfterModifyJobLedgerEntries', '', false, false)]
    local procedure OnMoveJobEntriesOnAfterModifyJobLedgerEntries(var Job: Record Job; NewJobNo: Code[20])
    begin
        ServiceLedgerEntry.Reset();
        ServiceLedgerEntry.SetRange("Job No.", Job."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            ServiceLedgerEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServiceLedgerEntry.IsEmpty() then
            Error(
              CannotDeleteLedgerEntriesInFiscalYearErr,
              Job.TableCaption(), Job."No.");

        ServiceLedgerEntry.SetRange("Posting Date");
        ServiceLedgerEntry.SetRange(Open, true);
        if not ServiceLedgerEntry.IsEmpty() then
            Error(
              CannotDeleteOpenLedgerEntriesErr,
              Job.TableCaption(), Job."No.");

        ServiceLedgerEntry.SetRange(Open);
        ServiceLedgerEntry.ModifyAll("Job No.", NewJobNo);
    end;

    procedure CheckIfServiceItemCanBeDeleted(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceItemNo: Code[20]): Text
    var
        ServiceItem: Record "Service Item";
    begin
        ServiceLedgerEntry.Reset();
        ServiceLedgerEntry.SetCurrentKey("Service Item No. (Serviced)");
        ServiceLedgerEntry.SetRange("Service Item No. (Serviced)", ServiceItemNo);
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            ServiceLedgerEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServiceLedgerEntry.IsEmpty() then
            exit(StrSubstNo(CannotDeleteLedgerEntriesInFiscalYearErr, ServiceItem.TableCaption(), ServiceItemNo));

        ServiceLedgerEntry.SetRange("Posting Date");
        ServiceLedgerEntry.SetRange(Open, true);
        if not ServiceLedgerEntry.IsEmpty() then
            exit(StrSubstNo(CannotDeleteOpenLedgerEntriesErr, ServiceItem.TableCaption(), ServiceItemNo));

        ServiceLedgerEntry.SetRange(Open);
        exit('');
    end;

    procedure MoveServiceItemLedgerEntries(ServiceItem: Record "Service Item")
    var
        ResultDescription: Text;
        NewServiceItemNo: Code[20];
    begin
        OnBeforeMoveServiceItemLedgerEntries(ServiceItem, NewServiceItemNo);
#if not CLEAN25
        MoveEntries.RunOnBeforeMoveServiceItemLedgerEntries(ServiceItem, NewServiceItemNo);
#endif
        ServiceLedgerEntry.LockTable();

        ResultDescription := CheckIfServiceItemCanBeDeleted(ServiceLedgerEntry, ServiceItem."No.");
        if ResultDescription <> '' then
            Error(ResultDescription);

        ServiceLedgerEntry.ModifyAll("Service Item No. (Serviced)", NewServiceItemNo);

        WarrantyLedgerEntry.LockTable();
        WarrantyLedgerEntry.SetRange("Service Item No. (Serviced)", ServiceItem."No.");
        WarrantyLedgerEntry.ModifyAll("Service Item No. (Serviced)", NewServiceItemNo);

        OnAfterMoveServiceItemLedgerEntries(ServiceItem);
#if not CLEAN25
        MoveEntries.RunOnAfterMoveServiceItemLedgerEntries(ServiceItem);
#endif
    end;

    procedure MoveServContractLedgerEntries(ServiceContractHeader: Record "Service Contract Header")
    var
        NewContractNo: Code[20];
    begin
        OnBeforeMoveServContractLedgerEntries(ServiceContractHeader, NewContractNo);
#if not CLEAN25
        MoveEntries.RunOnBeforeMoveServContractLedgerEntries(ServiceContractHeader, NewContractNo);
#endif

        if ServiceContractHeader.Prepaid then begin
            ServiceLedgerEntry.Reset();
            ServiceLedgerEntry.SetCurrentKey(Type, "No.");
            ServiceLedgerEntry.SetRange(Type, ServiceLedgerEntry.Type::"Service Contract");
            ServiceLedgerEntry.SetRange("No.", ServiceContractHeader."Contract No.");
            ServiceLedgerEntry.SetRange(Prepaid, true);
            ServiceLedgerEntry.SetRange("Moved from Prepaid Acc.", false);
            ServiceLedgerEntry.SetRange(Open, false);
            if not ServiceLedgerEntry.IsEmpty() then
                Error(CannotDeletePrepaidContractEntriesErr, ServiceContractHeader.TableCaption(), NewContractNo);
            ServiceLedgerEntry.SetRange(Open, true);
            if not ServiceLedgerEntry.IsEmpty() then
                Error(CannotDeleteOpenPrepaidContractEntriesErr, ServiceContractHeader.TableCaption(), NewContractNo);
        end;

        ServiceLedgerEntry.Reset();
        ServiceLedgerEntry.SetRange("Service Contract No.", ServiceContractHeader."Contract No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            ServiceLedgerEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServiceLedgerEntry.IsEmpty() then
            Error(
              CannotDeleteLedgerEntriesInFiscalYearErr,
              ServiceContractHeader.TableCaption(), ServiceContractHeader."Contract No.");

        ServiceLedgerEntry.SetRange("Posting Date");
        ServiceLedgerEntry.SetRange(Open, true);
        if not ServiceLedgerEntry.IsEmpty() then
            Error(
              CannotDeleteOpenLedgerEntriesErr,
              ServiceContractHeader.TableCaption(), ServiceContractHeader."Contract No.");

        ServiceLedgerEntry.SetRange(Open);
        ServiceLedgerEntry.ModifyAll("Service Contract No.", NewContractNo);

        ServiceLedgerEntry.SetRange("Service Contract No.");
        ServiceLedgerEntry.SetRange(Type, ServiceLedgerEntry.Type::"Service Contract");
        ServiceLedgerEntry.SetRange("No.", ServiceContractHeader."Contract No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            ServiceLedgerEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServiceLedgerEntry.IsEmpty() then
            Error(
              CannotDeleteLedgerEntriesInFiscalYearErr,
              ServiceContractHeader.TableCaption(), ServiceContractHeader."Contract No.");

        ServiceLedgerEntry.SetRange("Posting Date");
        ServiceLedgerEntry.SetRange(Open, true);
        if not ServiceLedgerEntry.IsEmpty() then
            Error(
              CannotDeleteOpenLedgerEntriesErr,
              ServiceContractHeader.TableCaption(), ServiceContractHeader."Contract No.");

        ServiceLedgerEntry.SetRange(Open);
        ServiceLedgerEntry.ModifyAll("No.", NewContractNo);

        WarrantyLedgerEntry.LockTable();
        WarrantyLedgerEntry.SetRange("Service Contract No.", ServiceContractHeader."Contract No.");
        WarrantyLedgerEntry.ModifyAll("Service Contract No.", NewContractNo);

        OnAfterMoveServContractLedgerEntries(ServiceContractHeader);
#if not CLEAN25
        MoveEntries.RunOnAfterMoveServContractLedgerEntries(ServiceContractHeader);
#endif
    end;

    procedure MoveServiceCostLedgerEntries(ServiceCost: Record "Service Cost")
    var
        NewCostCode: Code[10];
    begin
        OnBeforeMoveServiceCostLedgerEntries(ServiceCost, NewCostCode);
#if not CLEAN25
        MoveEntries.RunOnBeforeMoveServiceCostLedgerEntries(ServiceCost, NewCostCode);
#endif

        ServiceLedgerEntry.Reset();
        ServiceLedgerEntry.SetRange(Type, ServiceLedgerEntry.Type::"Service Cost");
        ServiceLedgerEntry.SetRange("No.", ServiceCost.Code);
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            ServiceLedgerEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if not ServiceLedgerEntry.IsEmpty() then
            Error(
              CannotDeleteLedgerEntriesInFiscalYearErr,
              ServiceCost.TableCaption(), ServiceCost.Code);

        ServiceLedgerEntry.SetRange("Posting Date");
        ServiceLedgerEntry.SetRange(Open, true);
        if not ServiceLedgerEntry.IsEmpty() then
            Error(
              CannotDeleteOpenLedgerEntriesErr,
              ServiceCost.TableCaption(), ServiceCost.Code);

        ServiceLedgerEntry.SetRange(Open);
        ServiceLedgerEntry.ModifyAll("No.", NewCostCode);

        WarrantyLedgerEntry.LockTable();
        WarrantyLedgerEntry.SetRange(Type, WarrantyLedgerEntry.Type::"Cost");
        WarrantyLedgerEntry.SetRange("No.", ServiceCost.Code);
        WarrantyLedgerEntry.ModifyAll("No.", NewCostCode);

        OnAfterMoveServiceCostLedgerEntries(ServiceCost);
#if not CLEAN25
        MoveEntries.RunOnAfterMoveServiceCostLedgerEntries(ServiceCost);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveServiceItemLedgerEntries(ServiceItem: Record Microsoft.Service.Item."Service Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveServContractLedgerEntries(ServiceContractHeader: Record Microsoft.Service.Contract."Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveServiceCostLedgerEntries(ServiceCost: Record Microsoft.Service.Pricing."Service Cost")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveServiceItemLedgerEntries(ServiceItem: Record Microsoft.Service.Item."Service Item"; var NewServiceItemNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveServContractLedgerEntries(ServiceContractHeader: Record Microsoft.Service.Contract."Service Contract Header"; var NewContractNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveServiceCostLedgerEntries(ServiceCost: Record Microsoft.Service.Pricing."Service Cost"; var NewCostCode: Code[10])
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::MoveEntries, 'OnAfterMoveCashFlowEntries', '', false, false)]
    local procedure OnAfterMoveCashFlowEntries(CashFlowAccount: Record "Cash Flow Account"; CashFlowSetup: Record "Cash Flow Setup")
    begin
        if CashFlowSetup."Service CF Account No." = CashFlowAccount."No." then
            CashFlowSetup.ModifyAll("Service CF Account No.", '');
    end;
}

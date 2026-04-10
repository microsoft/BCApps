// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Threading;

codeunit 5350 "CRM Statistics Job"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        UpdateStatisticsAndInvoices(Rec.GetLastLogEntryNo());
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";

        ConnectionNotEnabledErr: Label 'The %1 connection is not enabled.', Comment = '%1 = CRM product name';
        RecordFoundTxt: Label '%1 %2 was not found.', Comment = '%1 is a table name, e.g. Customer, %2 is a number, e.g. Customer 12344 was not found.';
        AccountStatisticsUpdatedMsg: Label 'Updated account statistics. ';
        InvoiceStatusUpdatedMsg: Label 'Updated payment status of sales invoices.';
        StartingToRefreshCustomerStatisticsMsg: Label 'Starting to refresh customer statistics based on ledger entry and lines activity.', Locked = true;
        StartingInitialUploadCustomerStatisticsMsg: Label 'Starting the initial upload of customer statistics.', Locked = true;
        FinishedRefreshingCustomerStatisticsMsg: Label 'Finished refreshing customer statistics based on ledger entry and lines activity.', Locked = true;
        FinishedInitialUploadCustomerStatisticsMsg: Label 'Finished the initial upload of customer statistics.', Locked = true;
        UnexpectedErrorWhenGettingInvoiceErr: Label 'Unexpected error when trying to get the CRM Invoice %1: %2', Locked = true;
        UnexpectedErrorsDetectedErr: Label 'Unexpected errors detected while updating CRM Invoices. Not moving the last processed ledger entry number.', Locked = true;
        TelemetryCategoryTok: Label 'AL CRM Integration';
        DeleteAccountStatisticsFailedMsg: Label 'Failed to delete account statistics: %1', Locked = true;
        CustomerRecordDeletedMsg: Label 'The local customer record have been deleted.', Locked = true;

    local procedure UpdateStatisticsAndInvoices(JobLogEntryNo: Integer)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionName: Text;
    begin
        CRMConnectionSetup.Get();
        if not CRMConnectionSetup."Is Enabled" then
            Error(ConnectionNotEnabledErr, CRMProductName.FULL());

        ConnectionName := Format(CreateGuid());
        CRMConnectionSetup.RegisterConnectionWithName(ConnectionName);
        SetDefaultTableConnection(
          TABLECONNECTIONTYPE::CRM, CRMConnectionSetup.GetDefaultCRMConnection(ConnectionName));

        UpdateAccountStatistics(JobLogEntryNo);

        UpdateInvoices(JobLogEntryNo);

        CRMConnectionSetup.UnregisterConnectionWithName(ConnectionName);
    end;

    local procedure UpdateAccountStatistics(JobLogEntryNo: Integer)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSynchStatus: Record "CRM Synch Status";
        Customer: Record Customer;
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        RecRef: array[2] of RecordRef;
        ErrorText: Text;
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete;
        CustomerNumbers: List of [Code[20]];
        CRMIntegrationRecordSystemIds: List of [Guid];
        CRMIntegrationRecordSystemId: Guid;
        CustomerNo: Code[20];
        NewCustomerStatisticsSynchTime: DateTime;
    begin
        IntegrationTableSynch.BeginIntegrationSynchJobLoging(
          TABLECONNECTIONTYPE::CRM, CODEUNIT::"CRM Statistics Job", JobLogEntryNo, DATABASE::Customer);

        InitializeCustomerStatisticsSynchronizationTime();

        // upload customer statistics for the coupled, non-skipped customers who never had them uploaded once
        Session.LogMessage('0000DZ7', StartingInitialUploadCustomerStatisticsMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        CRMIntegrationRecord.SetRange("Table ID", DATABASE::Customer);
        CRMIntegrationRecord.SetRange(Skipped, false);
        CRMIntegrationRecord.SetRange("Statistics Uploaded", false);
        if not CRMIntegrationRecord.IsEmpty() then
            if CRMIntegrationRecord.FindSet() then
                repeat
                    CRMIntegrationRecordSystemIds.Add(CRMIntegrationRecord.SystemId)
                until CRMIntegrationRecord.Next() = 0;

        foreach CRMIntegrationRecordSystemId in CRMIntegrationRecordSystemIds do begin
            Clear(RecRef);
            SynchActionType := UpdateCRMAccountStatisticsForCoupledCustomer(CRMIntegrationRecordSystemId, RecRef[1], RecRef[2], ErrorText);
            CRMIntegrationRecord.GetBySystemId(CRMIntegrationRecordSystemId);
            if SynchActionType = SynchActionType::Fail then begin
                CRMIntegrationRecord."Last Synch. CRM Job ID" := IntegrationTableSynch.LogSynchError(RecRef[1], RecRef[2], ErrorText);
                CRMIntegrationRecord."Last Synch. CRM Result" := CRMIntegrationRecord."Last Synch. CRM Result"::Failure;
                CRMIntegrationRecord.Skipped := true;
                CRMIntegrationRecord.Modify();
            end else begin
                CRMIntegrationRecord."Statistics Uploaded" := true;
                CRMIntegrationRecord.Modify();
                IntegrationTableSynch.IncrementSynchJobCounters(SynchActionType);
            end;
        end;
        Session.LogMessage('0000DZ8', FinishedInitialUploadCustomerStatisticsMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);

        // Refresh Customer Statistics based on ledger entry and lines activity
        if CRMSynchStatus.Get() then begin
            NewCustomerStatisticsSynchTime := CurrentDateTime();

            Session.LogMessage('0000DZ9', StartingToRefreshCustomerStatisticsMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);

            AddCustomersWithLedgerEntryActivity(CRMSynchStatus."Cust. Statistics Synch. Time", CustomerNumbers);
            AddCustomersWithLinesActivity(CRMSynchStatus."Cust. Statistics Synch. Time", CustomerNumbers);
            foreach CustomerNo in CustomerNumbers do
                if Customer.Get(CustomerNo) then begin
                    CRMIntegrationRecord.Reset();
                    CRMIntegrationRecord.SetRange("Table ID", DATABASE::Customer);
                    CRMIntegrationRecord.SetRange(Skipped, false);
                    CRMIntegrationRecord.SetRange("Integration ID", Customer.SystemId);
                    if CRMIntegrationRecord.FindFirst() then begin
                        SynchActionType := UpdateCRMAccountStatisticsForCoupledCustomer(CRMIntegrationRecord.SystemId, RecRef[1], RecRef[2], ErrorText);
                        if SynchActionType = SynchActionType::Fail then begin
                            CRMIntegrationRecord."Last Synch. CRM Job ID" := IntegrationTableSynch.LogSynchError(RecRef[1], RecRef[2], ErrorText);
                            CRMIntegrationRecord."Last Synch. CRM Result" := CRMIntegrationRecord."Last Synch. CRM Result"::Failure;
                            CRMIntegrationRecord.Skipped := true;
                            CRMIntegrationRecord.Modify();
                        end else begin
                            if CRMIntegrationRecord."Statistics Uploaded" = false then begin
                                CRMIntegrationRecord."Statistics Uploaded" := true;
                                CRMIntegrationRecord.Modify();
                            end;
                            IntegrationTableSynch.IncrementSynchJobCounters(SynchActionType);
                        end;
                    end;
                end;

            if CRMSynchStatus.Get() then begin
                CRMSynchStatus."Cust. Statistics Synch. Time" := NewCustomerStatisticsSynchTime;
                CRMSynchStatus.Modify();
            end;

            Session.LogMessage('0000DZA', FinishedRefreshingCustomerStatisticsMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        end;

        IntegrationTableSynch.EndIntegrationSynchJobWithMsg(GetAccStatsUpdateFinalMessage());
    end;

    local procedure InitializeCustomerStatisticsSynchronizationTime()
    var
        CRMSynchStatus: Record "CRM Synch Status";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CRMIntegrationManagement.InitializeCRMSynchStatus(CRMSynchStatus);

        if CRMSynchStatus."Cust. Statistics Synch. Time" = 0DT then begin
            CRMSynchStatus."Cust. Statistics Synch. Time" := CurrentDateTime();
            CRMSynchStatus.Modify();
            Commit();
        end;
    end;

    local procedure AddCustomersWithLedgerEntryActivity(StartDateTime: DateTime; var CustomerNumbers: List of [Code[20]]);
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if StartDateTime = 0DT then
            exit;

        CustLedgerEntry.SetFilter(SystemModifiedAt, '>' + Format(StartDateTime));
        if CustLedgerEntry.FindSet() then
            repeat
                if not CustomerNumbers.Contains(CustLedgerEntry."Customer No.") then
                    CustomerNumbers.Add(CustLedgerEntry."Customer No.");
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure AddCustomersWithLinesActivity(StartDateTime: DateTime; var CustomerNumbers: List of [Code[20]]);
    var
        SalesLine: Record "Sales Line";
    begin
        if StartDateTime = 0DT then
            exit;

        SalesLine.SetFilter(SystemModifiedAt, '>' + Format(StartDateTime));
        if SalesLine.FindSet() then
            repeat
                if not CustomerNumbers.Contains(SalesLine."Sell-to Customer No.") then
                    CustomerNumbers.Add(SalesLine."Sell-to Customer No.");
            until SalesLine.Next() = 0;

        OnAfterAddCustomersWithLinesActivity(StartDateTime, CustomerNumbers);
    end;

    local procedure UpdateInvoices(JobLogEntryNo: Integer)
    var
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete;
        Counter: Integer;
    begin
        IntegrationTableSynch.BeginIntegrationSynchJobLoging(
          TABLECONNECTIONTYPE::CRM, CODEUNIT::"CRM Statistics Job", JobLogEntryNo, DATABASE::Customer);

        Counter := UpdateStatusOfPaidInvoices('');
        IntegrationTableSynch.UpdateSynchJobCounters(SynchActionType::Modify, Counter);

        IntegrationTableSynch.EndIntegrationSynchJobWithMsg(GetInvStatusUpdateFinalMessage());
    end;

    local procedure UpdateCRMAccountStatisticsForCoupledCustomer(CRMIntegrationRecordSystemId: Guid; var CustomerRecRef: RecordRef; var CRMAccountRecRef: RecordRef; var ErrorText: Text): Integer
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecId: RecordId;
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete;
        CustomerExists: Boolean;
        CRMAccountExists: Boolean;
    begin
        CRMIntegrationRecord.GetBySystemId(CRMIntegrationRecordSystemId);
        CRMIntegrationRecord.FindRecordId(RecId);
        CustomerExists := CustomerRecRef.Get(RecId);
        if CustomerExists then
            CustomerRecRef.SetTable(Customer);
        CRMAccountExists := CRMAccount.Get(CRMIntegrationRecord."CRM ID");
        if CRMAccountExists then
            CRMAccountRecRef.GetTable(CRMAccount);
        if CustomerExists and CRMAccountExists then
            exit(CreateOrUpdateCRMAccountStatistics(Customer, CRMAccount));

        if not CRMAccountExists then
            ErrorText := StrSubstNo(RecordFoundTxt, CRMAccount.TableCaption(), CRMIntegrationRecord."CRM ID");
        if not CustomerExists then
            ErrorText := StrSubstNo(RecordFoundTxt, Customer.TableCaption(), RecId);

        exit(SynchActionType::Fail);
    end;

    procedure CreateOrUpdateCRMAccountStatistics(Customer: Record Customer; var CRMAccount: Record "CRM Account"): Integer
    var
        CRMAccountStatistics: Record "CRM Account Statistics";
        xCRMAccountStatistics: Record "CRM Account Statistics";
        LcyCRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete;
    begin
        FindCRMAccountStatistics(CRMAccountStatistics, CRMAccount);
        xCRMAccountStatistics := CRMAccountStatistics;
        Customer.CalcFields("Balance (LCY)", "Outstanding Orders (LCY)", "Shipped Not Invoiced (LCY)", "Outstanding Invoices (LCY)");
        CRMAccountStatistics.Name := Customer.Name;
        CRMAccountStatistics."Customer No" := Customer."No.";
        CRMAccountStatistics."Balance (LCY)" := Customer."Balance (LCY)";
        CRMAccountStatistics."Outstanding Orders (LCY)" := Customer."Outstanding Orders (LCY)";
        CRMAccountStatistics."Shipped Not Invoiced (LCY)" := Customer."Shipped Not Invoiced (LCY)";
        CRMAccountStatistics."Outstanding Invoices (LCY)" := Customer."Outstanding Invoices (LCY)";
        CRMAccountStatistics."Total (LCY)" := Customer.GetTotalAmountLCY();
        CRMAccountStatistics."Credit Limit (LCY)" := Customer."Credit Limit (LCY)";
        CRMAccountStatistics."Overdue Amounts (LCY)" := Customer.CalcOverdueBalance();
        CRMAccountStatistics."Overdue Amounts As Of Date" := WorkDate();
        CRMAccountStatistics."Total Sales (LCY)" := Customer.GetSalesLCY();
        CRMAccountStatistics."Invd Prepayment Amount (LCY)" := Customer.GetInvoicedPrepmtAmountLCY();
        CRMAccountStatistics.TransactionCurrencyId := CRMSynchHelper.FindNAVLocalCurrencyInCRM(LcyCRMTransactioncurrency);
        OnCreateOrUpdateCRMAccountStatisticsOnBeforeModify(CRMAccountStatistics, Customer);
        if xCRMAccountStatistics."Customer No" = '' then begin
            CRMAccountStatistics.Modify();
            exit(SynchActionType::Insert);
        end;
        if IsCRMAccountStatisticsModified(xCRMAccountStatistics, CRMAccountStatistics) then begin
            CRMAccountStatistics.Modify();
            exit(SynchActionType::Modify);
        end;
        exit(SynchActionType::IgnoreUnchanged);
    end;

    procedure GetAccStatsUpdateFinalMessage(): Text
    begin
        exit(AccountStatisticsUpdatedMsg);
    end;

    procedure GetInvStatusUpdateFinalMessage(): Text
    begin
        exit(InvoiceStatusUpdatedMsg);
    end;

    local procedure IsCRMAccountStatisticsModified(xCRMAccountStatistics: Record "CRM Account Statistics"; CRMAccountStatistics: Record "CRM Account Statistics"): Boolean
    var
        RecRef: array[2] of RecordRef;
        FieldRef: array[2] of FieldRef;
        I: Integer;
    begin
        RecRef[1].GetTable(xCRMAccountStatistics);
        RecRef[2].GetTable(CRMAccountStatistics);
        for I := 1 to RecRef[1].FieldCount do begin
            FieldRef[1] := RecRef[1].FieldIndex(I);
            if FieldRef[1].Number >= CRMAccountStatistics.FieldNo(Name) then begin // non system CRM fields starts from Name
                FieldRef[2] := RecRef[2].FieldIndex(I);
                if FieldRef[1].Value <> FieldRef[2].Value then
                    exit(true);
            end;
        end;
        RecRef[1].Close();
        RecRef[2].Close();
    end;

    local procedure InitCRMAccountStatistics(var CRMAccountStatistics: Record "CRM Account Statistics")
    begin
        CRMAccountStatistics.Init();
        CRMAccountStatistics.AccountStatisticsId := CreateGuid();
        // Set all Money type fields to 1 temporarily, because if they have always been zero they show as '--' in CRM
        CRMAccountStatistics."Balance (LCY)" := 1;
        CRMAccountStatistics."Total (LCY)" := 1;
        CRMAccountStatistics."Credit Limit (LCY)" := 1;
        CRMAccountStatistics."Overdue Amounts (LCY)" := 1;
        CRMAccountStatistics."Total Sales (LCY)" := 1;
        CRMAccountStatistics."Invd Prepayment Amount (LCY)" := 1;
        CRMAccountStatistics."Outstanding Orders (LCY)" := 1;
        CRMAccountStatistics."Shipped Not Invoiced (LCY)" := 1;
        CRMAccountStatistics."Outstanding Invoices (LCY)" := 1;
        CRMAccountStatistics."Outstanding Serv Orders (LCY)" := 1;
        CRMAccountStatistics."Serv Shipped Not Invd (LCY)" := 1;
        CRMAccountStatistics."Outstd Serv Invoices (LCY)" := 1;
        CRMAccountStatistics.Insert();
    end;

    local procedure FindCRMAccountStatistics(var CRMAccountStatistics: Record "CRM Account Statistics"; var CRMAccount: Record "CRM Account")
    begin
        if IsNullGuid(CRMAccount.AccountStatiticsId) then begin
            InitCRMAccountStatistics(CRMAccountStatistics);
            CRMAccount.AccountStatiticsId := CRMAccountStatistics.AccountStatisticsId;
            ModifyCRMAccount(CRMAccount);
        end else
            CRMAccountStatistics.Get(CRMAccount.AccountStatiticsId);
    end;

    local procedure ModifyCRMAccount(var CRMAccount: Record "CRM Account")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if not CRMIntegrationRecord.IsModifiedAfterLastSynchonizedCRMRecord(CRMAccount.AccountId, DATABASE::Customer, CRMAccount.ModifiedOn) then begin
            CRMAccount.Modify();
            CRMIntegrationRecord.SetLastSynchCRMModifiedOn(CRMAccount.AccountId, DATABASE::Customer, CRMAccount.ModifiedOn);
        end else
            CRMAccount.Modify();
    end;

    procedure UpdateStatusOfPaidInvoices(CustomerNo: Code[20]) UpdatedInvoiceCounter: Integer
    var
        CRMSynchStatus: Record "Crm Synch Status";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CurrCLENo: Integer;
        ForAllCustomers: Boolean;
        UnexpectedErrorDetected: Boolean;
    begin
        CRMIntegrationManagement.InitializeCRMSynchStatus(CRMSynchStatus);

        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Posting Date");
        DtldCustLedgEntry.SetFilter("Entry No.", '>%1', CRMSynchStatus."Last Update Invoice Entry No.");
        ForAllCustomers := CustomerNo = '';
        if not ForAllCustomers then
            DtldCustLedgEntry.SetRange("Customer No.", CustomerNo);
        if DtldCustLedgEntry.FindSet() then begin
            CurrCLENo := DtldCustLedgEntry."Cust. Ledger Entry No.";
            repeat
                if CurrCLENo <> DtldCustLedgEntry."Cust. Ledger Entry No." then begin
                    UpdatedInvoiceCounter += UpdateInvoice(CurrCLENo, UnexpectedErrorDetected);
                    CurrCLENo := DtldCustLedgEntry."Cust. Ledger Entry No.";
                end;
            until DtldCustLedgEntry.Next() = 0;
            UpdatedInvoiceCounter += UpdateInvoice(CurrCLENo, UnexpectedErrorDetected);
            if ForAllCustomers then
                if not UnexpectedErrorDetected then
                    CRMSynchStatus.UpdateLastUpdateInvoiceEntryNo()
                else
                    Session.LogMessage('0000EC8', StrSubstno(UnexpectedErrorsDetectedErr), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        end;
    end;

    local procedure UpdateInvoice(CustLedgEntryNo: Integer; var UnexpectedErrorDetected: Boolean): Integer
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMInvoice: Record "CRM Invoice";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
    begin
        if CustLedgerEntry.Get(CustLedgEntryNo) then
            if CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Invoice then
                if SalesInvoiceHeader.Get(CustLedgerEntry."Document No.") then
                    if SalesInvoiceHeader.CalcFields(Cancelled) then
                        if CRMIntegrationRecord.FindByRecordID(SalesInvoiceHeader.RecordId) then
                            if TryGetCRMInvoice(CRMInvoice, CRMIntegrationRecord."CRM ID", UnexpectedErrorDetected) then
                                if SalesInvoiceHeader.Cancelled then
                                    exit(CRMSynchHelper.CancelCRMInvoice(CRMInvoice))
                                else
                                    exit(CRMSynchHelper.UpdateCRMInvoiceStatusFromEntry(CRMInvoice, CustLedgerEntry));
    end;

    local procedure TryGetCRMInvoice(var CRMInvoice: Record "CRM Invoice"; CRMId: Guid; var UnexpectedErrorDetected: Boolean): Boolean
    var
        invoiceFound: Boolean;
    begin
        // no unhandled exceptions thrown in the try function - return the result
        if GetCRMInvoice(CRMInvoice, CrmId, invoiceFound) then
            exit(invoiceFound);

        UnexpectedErrorDetected := true;
        Session.LogMessage('0000EC9', StrSubstno(UnexpectedErrorWhenGettingInvoiceErr, Format(CrmId), GetLastErrorText()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    [TryFunction]
    local procedure GetCRMInvoice(var CRMInvoice: Record "CRM Invoice"; CRMId: Guid; var invoiceFound: Boolean)
    begin
        invoiceFound := CRMInvoice.Get(CRMId);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnFindingIfJobNeedsToBeRun', '', false, false)]
    local procedure OnFindingIfJobNeedsToBeRun(var Sender: Record "Job Queue Entry"; var Result: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMSynchStatus: Record "CRM Synch Status";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        if Result then
            exit;

        if (Sender."Object Type to Run" = Sender."Object Type to Run"::Codeunit) and (Sender."Object ID to Run" = CODEUNIT::"CRM Statistics Job") then
            if CRMConnectionSetup.Get() and CRMConnectionSetup."Is Enabled" and CRMSynchStatus.Get() then
                if DetailedCustLedgEntry.FindLast() then
                    if CRMSynchStatus."Last Update Invoice Entry No." < DetailedCustLedgEntry."Entry No." then
                        Result := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Int. Rec. Uncouple Invoke", 'OnAfterUncoupleRecord', '', false, false)]
    local procedure DeleteAccountStatisticsOnAfterUncoupleRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var IntegrationRecordRef: RecordRef; var LocalRecordRef: RecordRef)
    var
        Customer: Record Customer;
    begin
        if not ((IntegrationTableMapping."Table ID" = Database::Customer) and (IntegrationTableMapping."Integration Table ID" = Database::"CRM Account")) then
            exit;

        if LocalRecordRef.Number <> Database::Customer then begin
            Session.LogMessage('0000MI1', CustomerRecordDeletedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            exit;
        end;

        if not TryDeleteAccountStatistics(LocalRecordRef.Field(Customer.FieldNo("No.")).Value) then
            Session.LogMessage('0000MHS', StrSubstNo(DeleteAccountStatisticsFailedMsg, GetLastErrorText()), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    [TryFunction]
    local procedure TryDeleteAccountStatistics(CustomerNo: Code[20])
    var
        CRMAccountStatistics: Record "CRM Account Statistics";
    begin
        CRMAccountStatistics.SetRange("Customer No", CustomerNo);
        if CRMAccountStatistics.FindFirst() then
            CRMAccountStatistics.Delete();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddCustomersWithLinesActivity(StartDateTime: DateTime; var CustomerNumbers: List of [Code[20]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOrUpdateCRMAccountStatisticsOnBeforeModify(var CRMAccountStatistics: Record "CRM Account Statistics"; var Customer: Record Customer)
    begin
    end;
}


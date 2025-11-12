// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.Telemetry;
using System.Threading;
using System.Utilities;

codeunit 5341 "CRM Int. Table. Subscriber"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        CRMProductName: Codeunit "CRM Product Name";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";

        CannotFindSyncedProductErr: Label 'Cannot find a synchronized product for %1.', Comment = '%1=product identifier';
        CannotSynchOnlyLinesErr: Label 'Cannot synchronize invoice lines separately.';
        CannotSynchProductErr: Label 'Cannot synchronize the product %1.', Comment = '%1=product identification';
        CannotSynchResourceErr: Label 'Cannot synchronize the resource %1.', Comment = '%1=resource identification';
        RecordNotFoundErr: Label 'Cannot find %1 in table %2.', Comment = '%1 = The lookup value when searching for the source record, %2 = Source table caption';
        ContactsMustBeRelatedToCompanyErr: Label 'The contact %1 must have a contact company that has a business relation to a customer.', Comment = '%1 = Contact No.';
        ContactMissingCompanyErr: Label 'The contact cannot be synchronized because the company does not exist.';
        CRMUnitGroupExistsAndIsInactiveErr: Label 'The %1 %2 already exists in %3, but it cannot be synchronized, because it is inactive.', Comment = '%1=table caption: Unit Group,%2=The name of the indicated Unit Group;%3=product name';
        CRMUnitGroupContainsMoreThanOneUoMErr: Label 'The %4 %1 %2 contains more than one %3. This setup cannot be used for synchronization.', Comment = '%1=table caption: Unit Group,%2=The name of the indicated Unit Group,%3=table caption: Unit., %4 = Dataverse service name';
        CustomerHasChangedErr: Label 'Cannot create the invoice in %2. The customer from the original %2 sales order %1 was changed or is no longer coupled.', Comment = '%1=CRM sales order number, %2 = Dataverse service name';
        ItemUnitOfMeasureDoesNotExistErr: Label 'Cannot create the invoice in %1. The item unit of measure %2 does not exist.', Comment = '%1= Dataverse service name, %2=item unit of measure code';
        NotCoupledItemUoMErr: Label 'Cannot create the invoice in %1. The item unit of measure %2 is not coupled to a %1 unit.', Comment = '%1= ataverse service name", %2=item unit of measure code';
        ResourceUnitOfMeasureDoesNotExistErr: Label 'Cannot create the invoice in %1. The resource unit of measure %2 does not exist.', Comment = '%1= Dataverse service name, %2=resource unit of measure code';
        NotCoupledResourceUoMErr: Label 'Cannot create the invoice in %1. The resource unit of measure %2 is not coupled to a %1 unit.', Comment = '%1= ataverse service name", %2=resource unit of measure code';
        NoCoupledSalesInvoiceHeaderErr: Label 'Cannot find the coupled %1 invoice header.', Comment = '%1 = Dataverse service name';
        RecordMustBeCoupledErr: Label '%1 %2 must be coupled to a record in %3.', Comment = '%1 =field caption, %2 = field value, %3 - product name ';
        CurrencyExchangeRateMissingErr: Label 'Cannot create or update the currency %1 in %2, because there is no exchange rate defined for it.', Comment = '%1 - currency code, %2 - Dataverse service name';
        NewCodePatternTxt: Label 'SP NO. %1', Locked = true;
        SalespersonPurchaserCodeFilterLbl: Label 'SP NO. 0*', Locked = true;
        SourceDestCodePatternTxt: Label '%1-%2', Locked = true;
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        UpdateContactParentCompanyTxt: Label 'Updating contact parent company.', Locked = true;
        UpdateContactParentCompanyFailedTxt: Label 'Updating contact parent company failed. Parent Customer ID: %1', Locked = true, Comment = '%1 - parent customer id';
        UpdateContactParentCompanySuccessfulTxt: Label 'Updated contact parent company successfully.', Locked = true;
        ItemUnitGroupNotFoundErr: Label 'Item Unit Group for Item %1 is not found.', Comment = '%1 - item number';
        ResourceUnitGroupNotFoundErr: Label 'Resource Unit Group for Resource %1 is not found.', Comment = '%1 - resource number';
        CRMUnitGroupNotFoundErr: Label 'CRM Unit Group %1 does not exist.', Comment = '%1 - unit group name';
        CRMUnitNotFoundErr: Label 'CRM Unit %1 with Unit Group Id %2 does not exist.', Comment = '%1 - unit name, %2 - unit group id';
        SynchingSalesSpecificEntityTxt: Label 'Synching a %1 specific entity.', Locked = true;
        FailedToGetPostedSalesInvoiceTxt: Label 'Failed to get posted sales invoice %1 from SQL database.', Locked = true;
        FailedToGetPostedSalesInvoiceLinesTxt: Label 'Failed to get lines for posted sales invoice %1 from SQL database.', Locked = true;
        SalesInvoiceNotCommittedErr: Label 'Posted sales invoice %1 is not committed in the SQL database yet. It will be synchronized by the next scheduled synchronization run.', Comment = '%1 - invoice number';
        SalesInvoiceLinesNotCommittedErr: Label 'The lines of posted sales invoice %1 are not committed in the SQL database yet. The invoice will be synchronized by the next scheduled synchronization run.', Comment = '%1 - invoice number';
        NotCoupledCRMUomErr: Label 'The %2 unit %1 is not coupled to a unit of measure.', Comment = '%1 = Unit name, %2 = Dataverse service name';
        OrderPriceListLbl: Label 'Business Central Order %1 Price List', Locked = true, Comment = '%1 - Order No.';
        SalesHeaderNotCoupledErr: Label 'Sales header is not coupled.';
        WriteInProductErr: Label 'Sales line contains a write-in product. You must choose the default write-in product in Sales & Receivables Setup window.';
        UnitOfMeasureNotCoupledErr: Label 'Unit of measure %1 is not coupled.', Comment = '%1 - unit of measure code';
        ItemUnitOfMeasureNotCoupledErr: Label 'Item unit of measure %1 is not coupled.', Comment = '%1 - unit of measure code';
        ResourceUnitOfMeasureNotCoupledErr: Label 'Resource unit of measure %1 is not coupled.', Comment = '%1 - unit of measure code';
        ItemUomDoesNotExistErr: Label 'The item unit of measure %1 does not exist.', Comment = '%1= item unit of measure code';
        ResourceUomDoesNotExistErr: Label 'The resource unit of measure %1 does not exist.', Comment = '%1= resource unit of measure code';

    procedure ClearCache()
    begin
        CRMSynchHelper.ClearCache();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Start Codeunit", 'OnAfterRun', '', false, false)]
    local procedure OnAfterJobQueueEntryRun(var JobQueueEntry: Record "Job Queue Entry")
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        if IsJobQueueEntryCRMIntegrationJob(JobQueueEntry, IntegrationTableMapping) then
            if IntegrationSynchJob.HaveJobsBeenIdle(JobQueueEntry.GetLastLogEntryNo()) then begin
                if JobQueueEntry."Recurring Job" then
                    JobQueueEntry.Status := JobQueueEntry.Status::"On Hold with Inactivity Timeout"
            end else
                JobQueueEntry.Status := JobQueueEntry.Status::Ready;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterDeleteAfterPosting', '', false, false)]
    local procedure DeleteCouplingOnAfterDeleteAfterPosting(SalesHeader: Record "Sales Header"; SalesInvoiceHeader: Record "Sales Invoice Header"; SalesCrMemoHeader: Record "Sales Cr.Memo Header"; CommitIsSuppressed: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
            exit;
        if IsNullGuid(SalesHeader.SystemId) then
            exit;
        CRMIntegrationRecord.SetRange("Integration ID", SalesHeader.SystemId);
        CRMIntegrationRecord.SetRange("Table ID", Database::"Sales Header");
        if not CRMIntegrationRecord.IsEmpty() then
            CRMIntegrationRecord.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnFindingIfJobNeedsToBeRun', '', false, false)]
    local procedure OnFindingIfJobNeedsToBeRun(var Sender: Record "Job Queue Entry"; var Result: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
        RecRef: RecordRef;
        ConnectionID: Guid;
    begin
        if Result then
            exit;

        if IsJobQueueEntryCRMIntegrationJob(Sender, IntegrationTableMapping) and
           CRMIntegrationManagement.IsCRMTable(IntegrationTableMapping."Integration Table ID")
        then begin
            CRMConnectionSetup.Get();
            if CRMConnectionSetup."Is Enabled" or CDSIntegrationImpl.IsIntegrationEnabled() then begin
                JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
                JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"In Process");
                if not JobQueueEntry.IsEmpty() then begin
                    Result := false;
                    exit;
                end;
                ConnectionID := Format(CreateGuid());
                if CDSIntegrationImpl.IsIntegrationEnabled() then begin
                    CDSIntegrationImpl.RegisterConnection(ConnectionID);
                    SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, ConnectionID, false)
                end else
                    CRMConnectionSetup.RegisterConnectionWithName(ConnectionID);
                RecRef.Open(IntegrationTableMapping."Integration Table ID");
                IntegrationTableMapping.SetIntRecordRefFilter(RecRef);
                if not RecRef.IsEmpty() then
                    Result := true;
                RecRef.Close();
                if CDSIntegrationImpl.IsIntegrationEnabled() then
                    CDSIntegrationImpl.UnregisterConnection(ConnectionID)
                else
                    CRMConnectionSetup.UnregisterConnectionWithName(ConnectionID);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Job Queue Log Entries", 'OnShowDetails', '', false, false)]
    local procedure OnShowDetailedLog(JobQueueLogEntry: Record "Job Queue Log Entry")
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        if (JobQueueLogEntry."Object Type to Run" = JobQueueLogEntry."Object Type to Run"::Codeunit) and
           (JobQueueLogEntry."Object ID to Run" in [CODEUNIT::"Integration Synch. Job Runner", CODEUNIT::"CRM Statistics Job", CODEUNIT::"Int. Uncouple Job Runner", CODEUNIT::"Int. Coupling Job Runner"])
        then begin
            IntegrationSynchJob.SetRange("Job Queue Log Entry No.", JobQueueLogEntry."Entry No.");
            PAGE.RunModal(PAGE::"Integration Synch. Job List", IntegrationSynchJob);
        end;
    end;

    local procedure IsJobQueueEntryCRMIntegrationJob(JobQueueEntry: Record "Job Queue Entry"; var IntegrationTableMapping: Record "Integration Table Mapping"): Boolean
    var
        RecRef: RecordRef;
    begin
        Clear(IntegrationTableMapping);
        if JobQueueEntry."Object Type to Run" <> JobQueueEntry."Object Type to Run"::Codeunit then
            exit(false);
        case JobQueueEntry."Object ID to Run" of
            CODEUNIT::"CRM Statistics Job":
                exit(true);
            CODEUNIT::"Integration Synch. Job Runner":
                begin
                    if not RecRef.Get(JobQueueEntry."Record ID to Process") then
                        exit(false);
                    if RecRef.Number() = DATABASE::"Integration Table Mapping" then begin
                        RecRef.SetTable(IntegrationTableMapping);
                        exit(IntegrationTableMapping."Synch. Codeunit ID" = CODEUNIT::"CRM Integration Table Synch.");
                    end;
                end;
            CODEUNIT::"Int. Uncouple Job Runner":
                begin
                    if not RecRef.Get(JobQueueEntry."Record ID to Process") then
                        exit(false);
                    if RecRef.Number() = DATABASE::"Integration Table Mapping" then begin
                        RecRef.SetTable(IntegrationTableMapping);
                        exit(IntegrationTableMapping."Uncouple Codeunit ID" = Codeunit::"CDS Int. Table Uncouple");
                    end;
                end;
            CODEUNIT::"Int. Coupling Job Runner":
                begin
                    if not RecRef.Get(JobQueueEntry."Record ID to Process") then
                        exit(false);
                    if RecRef.Number() = DATABASE::"Integration Table Mapping" then begin
                        RecRef.SetTable(IntegrationTableMapping);
                        exit(IntegrationTableMapping."Coupling Codeunit ID" = Codeunit::"CDS Int. Table Couple");
                    end;
                end;
            Codeunit::"CRM Archived Sales Orders Job":
                exit(true);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnCleanupAfterJobExecution(var Rec: Record "Job Queue Entry"; RunTrigger: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecordID: RecordID;
        RecRef: RecordRef;
    begin
        if Rec.IsTemporary() then
            exit;

        RecordID := Rec."Record ID to Process";
        if RecordID.TableNo() = DATABASE::"Integration Table Mapping" then begin
            RecRef := RecordID.GetRecord();
            RecRef.SetTable(IntegrationTableMapping);
            if IntegrationTableMapping.Get(IntegrationTableMapping.Name) then
                if IntegrationTableMapping."Delete After Synchronization" then
                    IntegrationTableMapping.Delete(true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnBeforeTransferRecordFields', '', false, false)]
    procedure OnBeforeTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Sales Invoice Header-CRM Invoice':
                CheckItemOrResourceIsNotBlocked(SourceRecordRef);
            'Sales Line-CRM Salesorderdetail':
                AddSalesOrderIdToCRMSalesorderdetail(SourceRecordRef, DestinationRecordRef);
            'CRM Salesorderdetail-Sales Line':
                begin
                    AddDocumentNoToSalesOrderLine(SourceRecordRef, DestinationRecordRef);
                    AddTypeToSalesOrderLine(SourceRecordRef, DestinationRecordRef);
                end;
            'CRM Salesorder-Sales Header':
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then begin
                    DestinationRecordRef.SetTable(SalesHeader);
                    SalesHeader.Status := SalesHeader.Status::Open;
                    DestinationRecordRef.GetTable(SalesHeader);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Record Synch.", 'OnTransferFieldData', '', false, false)]
    procedure OnTransferFieldData(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant; var IsValueFound: Boolean; var NeedsConversion: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
        IntegrationTableMapping: Record "Integration Table Mapping";
        Item: Record Item;
        Resource: Record Resource;
        PriceListLine: Record "Price List Line";
        SalesLine: Record "Sales Line";
        CRMProduct: Record "CRM Product";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CRMTransactionCurrency: Record "CRM Transactioncurrency";
        OptionValue: Integer;
        TableValue: Text;
        TransactionCurrencyId: Guid;
    begin
        if IsValueFound then
            exit;

        if not (CRMIntegrationManagement.IsCDSIntegrationEnabled() or CRMIntegrationManagement.IsCRMIntegrationEnabled()) then
            exit;

        if SourceFieldRef.Number() = DestinationFieldRef.Number() then
            if SourceFieldRef.Record().Number() = DestinationFieldRef.Record().Number() then
                exit;

        if CRMIntegrationManagement.IsCDSIntegrationEnabled() then
            if (SourceFieldRef.Record().Number() in [Database::Customer, Database::Vendor, Database::Currency, Database::Contact, Database::"Salesperson/Purchaser"]) or
                (DestinationFieldRef.Record().Number() in [Database::Customer, Database::Vendor, Database::Currency, Database::Contact, Database::"Salesperson/Purchaser"]) then
                exit;

        if (SourceFieldRef.Record().Number() = Database::"CRM Salesorderdetail") and (DestinationFieldRef.Record().Number() = Database::"Sales Line") and (DestinationFieldRef.Number() = SalesLine.FieldNo("No.")) then
            if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
                if AddWriteInProductNo(SourceFieldRef, NewValue) then begin
                    IsValueFound := true;
                    NeedsConversion := false;
                    exit;
                end;

        if (SourceFieldRef.Name() = SalesLine.FieldName(SalesLine."Currency Code")) and (DestinationFieldRef.Name() = CRMTransactionCurrency.FieldName(TransactionCurrencyId)) then
            if Format(SourceFieldRef.Value()) = '' then
                if CDSConnectionSetup.Get() then
                    if CDSConnectionSetup.BaseCurrencyCode <> '' then begin
                        GeneralLedgerSetup.Get();
                        if GeneralLedgerSetup."LCY Code" <> CDSConnectionSetup.BaseCurrencyCode then begin
                            CRMTransactionCurrency.SetRange(ISOCurrencyCode, CopyStr(GeneralLedgerSetup."LCY Code", 1, MaxStrLen(CRMTransactionCurrency.ISOCurrencyCode)));
                            if CRMTransactionCurrency.FindFirst() then begin
                                NewValue := CRMTransactionCurrency.TransactionCurrencyId;
                                IsValueFound := true;
                                NeedsConversion := false;
                                exit;
                            end;
                        end;
                    end;

        if (SourceFieldRef.Name() = CRMTransactionCurrency.FieldName(TransactionCurrencyId)) and (DestinationFieldRef.Name() = SalesLine.FieldName(SalesLine."Currency Code")) then
            if CDSConnectionSetup.Get() then
                if CDSConnectionSetup.BaseCurrencyCode <> '' then begin
                    GeneralLedgerSetup.Get();
                    if GeneralLedgerSetup."LCY Code" <> CDSConnectionSetup.BaseCurrencyCode then begin
                        Evaluate(TransactionCurrencyId, Format(SourceFieldRef.Value()));
                        if CRMTransactionCurrency.Get(TransactionCurrencyId) then
                            if Format(CRMTransactionCurrency.ISOCurrencyCode) = Format(GeneralLedgerSetup."LCY Code") then begin
                                NewValue := '';
                                IsValueFound := true;
                                NeedsConversion := false;
                                exit;
                            end;
                    end;
                end;

        if (DestinationFieldRef.Record().Number() = Database::"CRM Salesorderdetail") and (SourceFieldRef.Number() = SalesLine.FieldNo("No.")) then
            if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
                if AddWriteInSalesorderdetail(SourceFieldRef, NewValue) then begin
                    IsValueFound := true;
                    NeedsConversion := false;
                    exit;
                end;

        if (DestinationFieldRef.Record().Number() = Database::"CRM Salesorder") and (DestinationFieldRef.Name() = 'OwnerId') then
            if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then begin
                CDSConnectionSetup.Get();
                case CDSConnectionSetup."Ownership Model" of
                    CDSConnectionSetup."Ownership Model"::Team:
                        begin
                            // in case of field mapping to OwnerId, if ownership model is Team, we don't change the value if Salesperson changes
                            NewValue := DestinationFieldRef.Value();
                            IsValueFound := true;
                            NeedsConversion := false;
                            exit;
                        end;
                    CDSConnectionSetup."Ownership Model"::Person:
                        begin
                            // in case of field mapping to OwnerId, if ownership model is Person, we should find the user mapped to the Salesperson/Purchaser
                            NewValue := CRMSynchHelper.GetCoupledCDSUserId(SourceFieldRef.Record());
                            IsValueFound := true;
                            NeedsConversion := false;
                            exit;
                        end;
                end;
            end;

        if CRMSynchHelper.ConvertTableToOption(SourceFieldRef, DestinationFieldRef, OptionValue) then begin
            NewValue := OptionValue;
            IsValueFound := true;
            NeedsConversion := true;
            exit;
        end;

        if CRMSynchHelper.ConvertOptionToTable(SourceFieldRef, DestinationFieldRef, TableValue) then begin
            NewValue := TableValue;
            IsValueFound := true;
            NeedsConversion := false;
            exit;
        end;

        if ShouldKeepOldValue(DestinationFieldRef) then begin
            NewValue := DestinationFieldRef.Value();
            IsValueFound := true;
            NeedsConversion := false;
            exit;
        end;

        if CRMSynchHelper.FindNewValueForSpecialMapping(SourceFieldRef, DestinationFieldRef, NewValue) then begin
            IsValueFound := true;
            NeedsConversion := false;
            exit;
        end;

        if CRMIntegrationManagement.IsUnitGroupMappingEnabled() then begin
            if ((SourceFieldRef.Record().Number() = Database::Item) and (SourceFieldRef.Number() = Item.FieldNo("Base Unit of Measure"))) or
            ((SourceFieldRef.Record().Number() = Database::Resource) and (SourceFieldRef.Number() = Resource.FieldNo("Base Unit of Measure"))) or
            ((SourceFieldRef.Record().Number() = Database::"Price List Line") and (SourceFieldRef.Number() = PriceListLine.FieldNo("Unit of Measure Code"))) then begin
                CRMSynchHelper.ConvertBaseUnitOfMeasureToUomId(SourceFieldRef, DestinationFieldRef, NewValue);
                IsValueFound := true;
                NeedsConversion := false;
                exit;
            end;
            if (SourceFieldRef.Record().Number() = Database::"CRM Product") and (SourceFieldRef.Number() = CRMProduct.FieldNo(DefaultUoMId)) then begin
                CRMSynchHelper.ConvertUomIdToBaseUnitOfMeasure(SourceFieldRef, DestinationFieldRef, NewValue);
                IsValueFound := true;
                NeedsConversion := false;
                exit;
            end;
            if SourceFieldRef.Record().Number() = Database::"Unit Group" then begin
                CRMSynchHelper.PrefixUnitGroupCode(SourceFieldRef, NewValue);
                IsValueFound := true;
                NeedsConversion := false;
            end;
        end;

        if CRMSynchHelper.AreFieldsRelatedToMappedTables(SourceFieldRef, DestinationFieldRef, IntegrationTableMapping) then
            if FindNewValueForCoupledRecordPK(IntegrationTableMapping, SourceFieldRef, DestinationFieldRef, NewValue) then begin
                IsValueFound := true;
                NeedsConversion := false;
            end;
    end;

    local procedure ShouldKeepOldValue(DestinationFieldRef: FieldRef): Boolean
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        TempCRMOpportunity: Record "CRM Opportunity" temporary;
    begin
        // in case of field mapping to OwnerId, if ownership model is Team, we don't change the value if Salesperson changes
        if DestinationFieldRef.Name() = TempCRMOpportunity.FieldName(OwnerId) then
            if CRMIntegrationManagement.IsCDSIntegrationEnabled() then
                if CRMIntegrationManagement.IsCRMTable(DestinationFieldRef.Record().Number()) then begin
                    CDSConnectionSetup.Get();
                    exit(CDSConnectionSetup."Ownership Model" = CDSConnectionSetup."Ownership Model"::Team);
                end;
        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterTransferRecordFields', '', false, false)]
    procedure OnAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var AdditionalFieldsWereModified: Boolean; DestinationIsInserted: Boolean)
    var
        IsHandled: Boolean;
    begin
        OnBeforeGetSourceDestCodeOnAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef, AdditionalFieldsWereModified, DestinationIsInserted, IsHandled);
        if IsHandled then
            exit;

        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'CRM Account-Customer':
                if UpdateCustomerBlocked(SourceRecordRef, DestinationRecordRef) then
                    AdditionalFieldsWereModified := true;
            'Sales Price-CRM Productpricelevel':
                if UpdateCRMProductPricelevelAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef) then
                    AdditionalFieldsWereModified := true;
            'Price List Line-CRM Productpricelevel':
                if UpdateCRMProductPricelevelAfterTransferRecordFieldsPriceListLine(SourceRecordRef, DestinationRecordRef) then
                    AdditionalFieldsWereModified := true;
            'Currency-CRM Transactioncurrency':
                if UpdateCRMTransactionCurrencyAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef) then
                    AdditionalFieldsWereModified := true;
            'Item-CRM Product',
            'Resource-CRM Product':
                if UpdateCRMProductAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef, DestinationIsInserted) then
                    AdditionalFieldsWereModified := true;
            'CRM Product-Item':
                if UpdateItemAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef) then
                    AdditionalFieldsWereModified := true;
            'CRM Product-Resource':
                if UpdateResourceAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef) then
                    AdditionalFieldsWereModified := true;
            'Unit of Measure-CRM Uomschedule':
                if UpdateCRMUoMScheduleAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef) then
                    AdditionalFieldsWereModified := true;
            'Unit Group-CRM Uomschedule':
                CheckCRMUoMScheduleAfterTransferRecordFields(DestinationRecordRef);
            'Item Unit of Measure-CRM Uom':
                if UpdateCRMUomFromItemAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef) then
                    AdditionalFieldsWereModified := true;
            'Resource Unit of Measure-CRM Uom':
                if UpdateCRMUomFromResourceAfterTransferRecordFields(SourceRecordRef, DestinationRecordRef) then
                    AdditionalFieldsWereModified := true;
            'Sales Line-CRM Salesorderdetail':
                if UpdateCRMSalesorderdetailUom(SourceRecordRef, DestinationRecordRef) then
                    AdditionalFieldsWereModified := true;
            'CRM Salesorderdetail-Sales Line':
                if UpdateSalesLineUnitOfMeasure(SourceRecordRef, DestinationRecordRef) then begin
                    UpdateSalesLinePriceOverride(SourceRecordRef, DestinationRecordRef);
                    AdditionalFieldsWereModified := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnBeforeInsertRecord', '', false, false)]
    procedure OnBeforeInsertRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSIntTableSubscriber: Codeunit "CDS Int. Table. Subscriber";
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'CRM Contact-Contact':
                UpdateContactParentCompany(SourceRecordRef, DestinationRecordRef);
            'Contact-CRM Contact':
                UpdateCRMContactParentCustomerId(SourceRecordRef, DestinationRecordRef);
            'Currency-CRM Transactioncurrency':
                UpdateCRMTransactionCurrencyBeforeInsertRecord(DestinationRecordRef);
            'Customer Price Group-CRM Pricelevel':
                UpdateCRMPricelevelBeforeInsertRecord(SourceRecordRef, DestinationRecordRef);
            'Price List Header-CRM Pricelevel':
                UpdateCRMPricelevelBeforeInsertPriceListHeader(SourceRecordRef, DestinationRecordRef);
            'Item-CRM Product',
            'Resource-CRM Product':
                UpdateCRMProductBeforeInsertRecord(DestinationRecordRef);
            'Sales Invoice Header-CRM Invoice':
                begin
                    CheckSalesInvoiceLineItemsAreCoupled(SourceRecordRef);
                    UpdateCRMInvoiceBeforeInsertRecord(SourceRecordRef, DestinationRecordRef);
                end;
            'Opportunity-CRM Opportunity':
                UpdateCRMOpportunityBeforeInsertRecord(DestinationRecordRef);
            'Sales Invoice Line-CRM Invoicedetail':
                UpdateCRMInvoiceDetailsBeforeInsertRecord(SourceRecordRef, DestinationRecordRef);
            'Sales Header-CRM Salesorder':
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then begin
                    UpdateCRMSalesOrderPriceList(SourceRecordRef, DestinationRecordRef);
                    SetCompanyId(DestinationRecordRef);
                    SetCRMOrderName(SourceRecordRef, DestinationRecordRef);
                    SetDocOccurenceNumber(SourceRecordRef, DestinationRecordRef);
                    CDSIntTableSubscriber.SetOwnerId(SourceRecordRef, DestinationRecordRef);
                end;
            'CRM Salesorder-Sales Header':
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
                    UpdateSalesOrderQuoteNo(SourceRecordRef, DestinationRecordRef);
            'Sales Line-CRM Salesorderdetail':
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then begin
                    SetWriteInProduct(SourceRecordRef, DestinationRecordRef);
                    ApplySalesLineTax(SourceRecordRef, DestinationRecordRef);
                end;
        end;

        case DestinationRecordRef.Number() of
            Database::"Salesperson/Purchaser":
                UpdateSalesPersOnBeforeInsertRecord(DestinationRecordRef);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterInsertRecord', '', false, false)]
    procedure OnAfterInsertRecord(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        SourceDestCode: Text;
    begin
        SourceDestCode := GetSourceDestCode(SourceRecordRef, DestinationRecordRef);
        case SourceDestCode of
            'Customer Price Group-CRM Pricelevel':
                ResetCRMProductpricelevelFromCustomerPriceGroup(SourceRecordRef);
            'Price List Header-CRM Pricelevel':
                ResetCRMProductpricelevelFromPriceListHeader(SourceRecordRef);
            'Item-CRM Product',
            'Resource-CRM Product':
                UpdateCRMProductAfterInsertRecord(DestinationRecordRef);
            'Sales Invoice Header-CRM Invoice':
                begin
                    UpdateCRMInvoiceAfterInsertRecord(SourceRecordRef, DestinationRecordRef);
                    UpdatePricesIncludeVATRounding(SourceRecordRef, DestinationRecordRef);
                end;
            'Sales Invoice Line-CRM Invoicedetail':
                UpdateCRMInvoiceDetailsAfterInsertRecord(SourceRecordRef, DestinationRecordRef);
            'Item Unit of Measure-CRM Uom':
                UpdateCRMUomFromItemAfterInsertRecord(SourceRecordRef, DestinationRecordRef);
            'Resource Unit of Measure-CRM Uom':
                UpdateCRMUomFromResourceAfterInsertRecord(SourceRecordRef, DestinationRecordRef);
            'Sales Header-CRM Salesorder':
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then begin
                    ResetCRMSalesorderdetailFromSalesOrderLine(SourceRecordRef, DestinationRecordRef);
                    SetCRMSalesOrderStateCode(SourceRecordRef, DestinationRecordRef);
                end;
            'CRM Salesorder-Sales Header':
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then begin
                    ResetSalesOrderLineFromCRMSalesorderdetail(SourceRecordRef, DestinationRecordRef);
                    ApplySalesOrderDiscounts(SourceRecordRef, DestinationRecordRef);
                    CreateFreightLines(SourceRecordRef, DestinationRecordRef);
                    SetSalesOrderStatus(DestinationRecordRef);
                    SetOrderNumberAndDocOccurenceNumber(SourceRecordRef, DestinationRecordRef);
                    CreateSalesOrderNotes(SourceRecordRef, DestinationRecordRef);
                end;
            'CRM Product-Item':
                CreateUnitGroupAndItemUnitOfMeasure(SourceRecordRef, DestinationRecordRef);
            'CRM Product-Resource':
                CreateUnitGroupAndResourceUnitOfMeasure(SourceRecordRef, DestinationRecordRef);
            'CRM Salesorderdetail-Sales Line':
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
                    AutoReserveSalesLine(DestinationRecordRef);
        end;
    end;

    local procedure CreateUnitGroupAndItemUnitOfMeasure(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMProduct: Record "CRM Product";
        Item: Record Item;
        UnitGroup: Record "Unit Group";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        UnitGroupRecordRef: RecordRef;
        ItemUnitOfMeasureRecordRef: RecordRef;
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Table ID", Database::"Unit Group");
        IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Uomschedule");
        if IntegrationTableMapping.FindFirst() then
            if not IntegrationTableMapping."Synch. Only Coupled Records" then begin
                IntegrationTableMapping.SetRange("Table ID", Database::"Item Unit of Measure");
                IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Uom");
                if IntegrationTableMapping.FindFirst() then
                    if not IntegrationTableMapping."Synch. Only Coupled Records" then begin
                        SourceRecordRef.SetTable(CRMProduct);
                        DestinationRecordRef.SetTable(Item);

                        if UnitGroup.Get(UnitGroup."Source Type"::Item, Item.SystemId) then begin
                            CRMIntegrationRecord.CoupleRecordIdToCRMID(UnitGroup.RecordId, CRMProduct.DefaultUoMScheduleId);
                            UnitGroup.SetRange(SystemId, UnitGroup.SystemId);
                            UnitGroupRecordRef.GetTable(UnitGroup);
                            CRMIntegrationTableSynch.SynchRecordsToIntegrationTable(UnitGroupRecordRef, false, false);
                        end;

                        if not ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure") then begin
                            ItemUnitOfMeasure.Init();
                            ItemUnitOfMeasure.Validate("Item No.", Item."No.");
                            ItemUnitOfMeasure.Validate(Code, Item."Base Unit of Measure");
                            ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
                            ItemUnitOfMeasure.Insert();

                            CRMIntegrationRecord.CoupleRecordIdToCRMID(ItemUnitOfMeasure.RecordId, CRMProduct.DefaultUoMId);
                            ItemUnitOfMeasure.SetRange(SystemId, ItemUnitOfMeasure.SystemId);
                            ItemUnitOfMeasureRecordRef.GetTable(ItemUnitOfMeasure);
                            CRMIntegrationTableSynch.SynchRecordsToIntegrationTable(ItemUnitOfMeasureRecordRef, false, false);
                        end;
                    end;
            end;
    end;

    local procedure CreateUnitGroupAndResourceUnitOfMeasure(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMProduct: Record "CRM Product";
        Resource: Record Resource;
        UnitGroup: Record "Unit Group";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        UnitGroupRecordRef: RecordRef;
        ResourceUnitOfMeasureRecordRef: RecordRef;
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Table ID", Database::"Unit Group");
        IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Uomschedule");
        if IntegrationTableMapping.FindFirst() then
            if not IntegrationTableMapping."Synch. Only Coupled Records" then begin
                IntegrationTableMapping.SetRange("Table ID", Database::"Resource Unit of Measure");
                IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Uom");
                if IntegrationTableMapping.FindFirst() then
                    if not IntegrationTableMapping."Synch. Only Coupled Records" then begin
                        SourceRecordRef.SetTable(CRMProduct);
                        DestinationRecordRef.SetTable(Resource);

                        if UnitGroup.Get(UnitGroup."Source Type"::Resource, Resource.SystemId) then begin
                            CRMIntegrationRecord.CoupleRecordIdToCRMID(UnitGroup.RecordId, CRMProduct.DefaultUoMScheduleId);
                            UnitGroup.SetRange(SystemId, UnitGroup.SystemId);
                            UnitGroupRecordRef.GetTable(UnitGroup);
                            CRMIntegrationTableSynch.SynchRecordsToIntegrationTable(UnitGroupRecordRef, false, false);
                        end;

                        if not ResourceUnitOfMeasure.Get(Resource."No.", Resource."Base Unit of Measure") then begin
                            ResourceUnitOfMeasure.Init();
                            ResourceUnitOfMeasure.Validate("Resource No.", Resource."No.");
                            ResourceUnitOfMeasure.Validate(Code, Resource."Base Unit of Measure");
                            ResourceUnitOfMeasure."Qty. per Unit of Measure" := 1;
                            ResourceUnitOfMeasure.Insert();

                            CRMIntegrationRecord.CoupleRecordIdToCRMID(ResourceUnitOfMeasure.RecordId, CRMProduct.DefaultUoMId);
                            ResourceUnitOfMeasure.SetRange(SystemId, ResourceUnitOfMeasure.SystemId);
                            ResourceUnitOfMeasureRecordRef.GetTable(ResourceUnitOfMeasure);
                            CRMIntegrationTableSynch.SynchRecordsToIntegrationTable(ResourceUnitOfMeasureRecordRef, false, false);
                        end;
                    end;
            end;
    end;

    local procedure ChangeSalesOrderStateCode(var SourceRecordRef: RecordRef; NewStateCode: Option)
    var
        CRMSalesorder: Record "CRM Salesorder";
        ChangedCRMSalesOrder: Record "CRM Salesorder";
    begin
        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit;

        SourceRecordRef.SetTable(CRMSalesorder);
        ChangedCRMSalesOrder.SetAutoCalcFields(CreatedByName, ModifiedByName, TransactionCurrencyIdName);
        ChangedCRMSalesOrder.Get(CRMSalesorder.SalesOrderId);
        if ChangedCRMSalesOrder.StateCode = NewStateCode then
            exit;
        ChangedCRMSalesOrder.StateCode := NewStateCode;
        ChangedCRMSalesOrder.Modify();
    end;

    local procedure ChangeSalesOrderStatus(var SourceRecordRef: RecordRef; NewStatus: Enum "Sales Document Status")
    var
        SalesHeader: Record "Sales Header";
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
            exit;

        SalesHeader.GetBySystemId(SourceRecordRef.Field(SourceRecordRef.SystemIdNo).Value());

        OnChangeSalesOrderStatusOnBeforeCompareStatus(SalesHeader, NewStatus);
        if SalesHeader.Status = NewStatus then
            exit;
        SalesHeader.Status := NewStatus;
        SalesHeader.Modify();

        SourceRecordRef.GetTable(SalesHeader);
    end;

    local procedure SetSalesOrderStatus(var SourceRecordRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        NewStatus: Enum "Sales Document Status";
    begin
        SourceRecordRef.SetTable(SalesHeader);
        if SalesHeader."Prepayment %" > 0 then
            NewStatus := SalesHeader.Status::Open
        else
            NewStatus := SalesHeader.Status::Released;

        ChangeValidateSalesOrderStatus(SourceRecordRef, NewStatus);
    end;

    local procedure SetCRMSalesOrderStateCode(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        CRMSalesorder: Record "CRM Salesorder";
    begin
        SourceRecordRef.SetTable(SalesHeader);
        DestinationRecordRef.SetTable(CRMSalesorder);
        SalesHeader.CalcFields("Completely Shipped");
        if SalesHeader."Completely Shipped" then
            CRMSynchHelper.FulfillSalesOrder(CRMSalesorder.SalesOrderId)
        else
            ChangeSalesOrderStateCode(DestinationRecordRef, CRMSalesorder.StateCode::Submitted);
    end;

    local procedure SubmitOrInvoiceSalesOrder(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesDocumentPostingMgt: Codeunit "CRM Sales Document Posting Mgt";
    begin
        SourceRecordRef.SetTable(SalesHeader);
        if CRMSalesDocumentPostingMgt.IsSalesOrderFullyInvoiced(SalesHeader) then
            ChangeSalesOrderStateCode(DestinationRecordRef, CRMSalesorder.StateCode::Invoiced)
        else
            ChangeSalesOrderStateCode(DestinationRecordRef, CRMSalesorder.StateCode::Submitted);
    end;

    local procedure ChangeValidateSalesOrderStatus(var SourceRecordRef: RecordRef; NewStatus: Enum "Sales Document Status")
    var
        SalesHeader: Record "Sales Header";
        CRMConnectionSetup: Record "CRM Connection Setup";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
    begin
        if not CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
            exit;

        SalesHeader.GetBySystemId(SourceRecordRef.Field(SourceRecordRef.SystemIdNo).Value());

        OnChangeSalesOrderStatusOnBeforeCompareStatus(SalesHeader, NewStatus);
        if SalesHeader.Status = NewStatus then
            exit;

        if NewStatus = SalesHeader.Status::Released then
            ReleaseSalesDocument.PerformManualRelease(SalesHeader)
        else
            ReleaseSalesDocument.PerformManualReopen(SalesHeader);

        SourceRecordRef.GetTable(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnBeforeModifyRecord', '', false, false)]
    procedure OnBeforeModifyRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMSalesOrder: Record "CRM Salesorder";
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'CRM Contact-Contact':
                UpdateContactParentCompany(SourceRecordRef, DestinationRecordRef);
            'Contact-CRM Contact':
                UpdateCRMContactParentCustomerId(SourceRecordRef, DestinationRecordRef);
            'Customer Price Group-CRM Pricelevel':
                UpdateCRMPricelevelBeforeModifyRecord(SourceRecordRef, DestinationRecordRef);
            'Price List Header-CRM Pricelevel':
                UpdateCRMPricelevelBeforeModifyPriceListHeader(SourceRecordRef, DestinationRecordRef);
            'Item-CRM Product',
            'Resource-CRM Product',
            'Opportunity-CRM Opportunity',
            'Sales Invoice Header-CRM Invoice':
                SetCompanyId(DestinationRecordRef);
            'Sales Header-CRM Salesorder':
                begin
                    if not CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
                        ChangeSalesOrderStateCode(DestinationRecordRef, CRMSalesOrder.StateCode::Active)
                    else
                        UpdateCRMSalesOrderPriceList(SourceRecordRef, DestinationRecordRef);
                    SetCompanyId(DestinationRecordRef);
                end;
            'Sales Line-CRM Salesorderdetail':
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
                    ApplySalesLineTax(SourceRecordRef, DestinationRecordRef);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterModifyRecord', '', false, false)]
    procedure OnAfterModifyRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Customer Price Group-CRM Pricelevel':
                ResetCRMProductpricelevelFromCustomerPriceGroup(SourceRecordRef);
            'Price List Header-CRM Pricelevel':
                ResetCRMProductpricelevelFromPriceListHeader(SourceRecordRef);
            'Sales Header-CRM Salesorder':
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then begin
                    ResetCRMSalesorderdetailFromSalesOrderLine(SourceRecordRef, DestinationRecordRef);
                    SetCRMSalesOrderStateCode(SourceRecordRef, DestinationRecordRef);
                end else
                    SubmitOrInvoiceSalesOrder(SourceRecordRef, DestinationRecordRef);
            'CRM Salesorder-Sales Header':
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then begin
                    ResetSalesOrderLineFromCRMSalesorderdetail(SourceRecordRef, DestinationRecordRef);
                    ApplySalesOrderDiscounts(SourceRecordRef, DestinationRecordRef);
                    CreateFreightLines(SourceRecordRef, DestinationRecordRef);
                    SetSalesOrderStatus(DestinationRecordRef);
                    CreateSalesOrderNotes(SourceRecordRef, DestinationRecordRef);
                end;
        end;

        if DestinationRecordRef.Number() = DATABASE::Customer then
            CRMSynchHelper.UpdateContactOnModifyCustomer(DestinationRecordRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterUnchangedRecordHandled', '', false, false)]
    procedure OnAfterUnchangedRecordHandled(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        SalesHeader: Record "Sales Header";
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Customer Price Group-CRM Pricelevel':
                ResetCRMProductpricelevelFromCustomerPriceGroup(SourceRecordRef);
            'Price List Header-CRM Pricelevel':
                ResetCRMProductpricelevelFromPriceListHeader(SourceRecordRef);
            'Sales Header-CRM Salesorder':
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
                    ResetCRMSalesorderdetailFromSalesOrderLine(SourceRecordRef, DestinationRecordRef);
            'CRM Salesorder-Sales Header':
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then begin
                    ChangeSalesOrderStatus(DestinationRecordRef, SalesHeader.Status::Open);
                    ResetSalesOrderLineFromCRMSalesorderdetail(SourceRecordRef, DestinationRecordRef);
                    CreateFreightLines(SourceRecordRef, DestinationRecordRef);
                    SetSalesOrderStatus(DestinationRecordRef);
                    CreateSalesOrderNotes(SourceRecordRef, DestinationRecordRef);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnBeforeIgnoreUnchangedRecordHandled', '', false, false)]
    local procedure OnBeforeIgnoreUnchangedRecordHandled(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        OnHandleOnBeforeIgnoreUnchangedRecordHandled(SourceRecordRef, DestinationRecordRef, IsHandled);
        if IsHandled then
            exit;

        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Sales Header-CRM Salesorder':
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
                    ResetCRMSalesorderdetailFromSalesOrderLine(SourceRecordRef, DestinationRecordRef);
            'CRM Salesorder-Sales Header':
                if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then begin
                    ChangeSalesOrderStatus(DestinationRecordRef, SalesHeader.Status::Open);
                    ResetSalesOrderLineFromCRMSalesorderdetail(SourceRecordRef, DestinationRecordRef);
                    SetSalesOrderStatus(DestinationRecordRef);
                    CreateSalesOrderNotes(SourceRecordRef, DestinationRecordRef);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Table Synch.", 'OnQueryPostFilterIgnoreRecord', '', false, false)]
    procedure OnQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    begin
        if IgnoreRecord then
            exit;

        case SourceRecordRef.Number() of
            DATABASE::Contact:
                HandleContactQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
            DATABASE::Opportunity:
                HandleOpportunityQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
            DATABASE::"Sales Invoice Line":
                Error(CannotSynchOnlyLinesErr);
            DATABASE::Item:
                HandleItemQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
            DATABASE::Resource:
                HandleResourceQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
            DATABASE::"Sales Invoice Header":
                IgnoreReadOnlyInvoiceOnQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
            Database::"Sales Header":
                IgnoreArchievedSalesOrdersOnQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
            Database::"CRM Salesorder":
                IgnoreArchievedCRMSalesordersOnQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
        end;

        OnAfterHandlePostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
    end;

    local procedure IgnoreArchievedSalesOrdersOnQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        SalesHeader: Record "Sales Header";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if IgnoreRecord then
            exit;

        SourceRecordRef.SetTable(SalesHeader);

        if not CRMIntegrationRecord.FindByRecordID(SalesHeader.RecordId) then
            exit;

        if CRMIntegrationRecord."Archived Sales Order" then
            if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
                IgnoreRecord := true;
    end;

    local procedure IgnoreArchievedCRMSalesordersOnQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if IgnoreRecord then
            exit;

        SourceRecordRef.SetTable(CRMSalesorder);

        if not CRMIntegrationRecord.FindByCRMID(CRMSalesorder.SalesOrderId) then
            exit;

        if CRMIntegrationRecord."Archived Sales Order" then
            if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
                IgnoreRecord := true;
    end;

    local procedure IgnoreReadOnlyInvoiceOnQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        CRMInvoice: Record "CRM Invoice";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMInvoiceID: Guid;
    begin
        if IgnoreRecord then
            exit;

        if not CRMIntegrationRecord.FindIDFromRecordRef(SourceRecordRef, CRMInvoiceID) then
            exit;

        if not CRMInvoice.Get(CRMInvoiceID) then
            exit;

        if CRMInvoice.StateCode <> CRMInvoice.StateCode::Active then
            IgnoreRecord := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnFindUncoupledDestinationRecord', '', false, false)]
    procedure OnFindUncoupledDestinationRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var DestinationIsDeleted: Boolean; var DestinationFound: Boolean)
    begin
        if DestinationFound then
            exit;

        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            if not CRMIntegrationManagement.IsCDSIntegrationEnabled() then
                exit;

        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Unit of Measure-CRM Uomschedule':
                if CRMUoMScheduleFindUncoupledDestinationRecord(SourceRecordRef, DestinationRecordRef) then
                    DestinationFound := true;
            'Currency-CRM Transactioncurrency':
                if CRMTransactionCurrencyFindUncoupledDestinationRecord(SourceRecordRef, DestinationRecordRef) then
                    DestinationFound := true;
        end;

        case SourceRecordRef.Number() of
            DATABASE::"Sales Price":
                if CRMPriceListLineFindUncoupledDestinationRecord(SourceRecordRef, DestinationRecordRef) then
                    DestinationFound := true;
            DATABASE::"Price List Line":
                if CRMExtPriceListLineFindUncoupledDestinationRecord(SourceRecordRef, DestinationRecordRef) then
                    DestinationFound := true;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Integration Table Mapping", 'OnAfterDeleteEvent', '', false, false)]
    procedure OnAfterDeleteIntegrationTableMapping(var Rec: Record "Integration Table Mapping"; RunTrigger: Boolean)
    var
        JobQueueEntry: record "Job Queue Entry";
    begin
        if Rec.IsTemporary() then
            exit;

        if Rec.Type <> Rec.Type::Dataverse then
            exit;

        JobQueueEntry.LockTable(true);
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetFilter("Object ID to Run", '%1|%2|%3', Codeunit::"Integration Synch. Job Runner", Codeunit::"Int. Uncouple Job Runner", Codeunit::"Int. Coupling Job Runner");
        JobQueueEntry.SetRange("Record ID to Process", Rec.RecordId());
        JobQueueEntry.DeleteTasks();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Table Synch.", 'OnAfterInitSynchJob', '', true, true)]
    local procedure LogTelemetryOnAfterInitSynchJob(ConnectionType: TableConnectionType; IntegrationTableID: Integer)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        IntegrationRecordRef: RecordRef;
        TelemetryCategories: Dictionary of [Text, Text];
        IntegrationTableName: Text;
    begin
        if ConnectionType <> TableConnectionType::CRM then
            exit;
        if IntegrationTableID in [
                Database::"CRM Salesorder",
                Database::"CRM Invoice",
                Database::"CRM Quote",
                Database::"CRM Opportunity",
                Database::"CRM Pricelevel",
                Database::"CRM Product",
                Database::"CRM Productpricelevel",
                Database::"CRM Uom",
                Database::"CRM Uomschedule",
                Database::"CRM Account Statistics"] then begin
            TelemetryCategories.Add('Category', CategoryTok);
            TelemetryCategories.Add('IntegrationTableID', Format(IntegrationTableID));
            if TryCalculateTableName(IntegrationRecordRef, IntegrationTableID, IntegrationTableName) then
                TelemetryCategories.Add('IntegrationTableName', IntegrationTableName);

            Session.LogMessage('0000FME', StrSubstNo(SynchingSalesSpecificEntityTxt, CRMProductName.SHORT()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryCategories);
            FeatureTelemetry.LogUptake('0000H7F', 'Dynamics 365 Sales', Enum::"Feature Uptake Status"::Used);
            FeatureTelemetry.LogUsage('0000H7G', 'Dynamics 365 Sales', 'Sales entity synch');
        end;
    end;

    [TryFunction]
    local procedure TryCalculateTableName(var IntegrationRecordRef: RecordRef; TableId: Integer; var TableName: Text)
    begin
        IntegrationRecordRef.Open(TableId);
        TableName := IntegrationRecordRef.Name();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Int. Rec. Uncouple Invoke", 'OnAfterUncoupleRecord', '', false, false)]
    local procedure HandleOnAfterUncoupleRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef)
    begin
        RemoveChildCouplings(LocalRecordRef, IntegrationRecordRef);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure HandleOnAfterDeleteAfterPosting(var Rec: Record "Sales Header")
    begin
        if Rec.IsTemporary() then
            exit;

        MarkArchivedSalesOrder(Rec);
    end;

    procedure MarkArchivedSalesOrder(SalesHeader: Record "Sales Header")
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        CRMIntegrationRecord.SetRange("Table ID", Database::"Sales Header");
        CRMIntegrationRecord.SetRange("Integration ID", SalesHeader.SystemId);
        if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
            if CRMIntegrationRecord.FindFirst() then begin
                CRMIntegrationRecord."Archived Sales Order" := true;
                CRMIntegrationRecord.Modify();
            end;
    end;

    local procedure RemoveChildCouplings(var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef)
    var
        SalesLineList: List of [Guid];
    begin
        if GetCoupledSalesLines(LocalRecordRef, IntegrationRecordRef, SalesLineList) then
            CRMIntegrationManagement.RemoveCoupling(Database::"Sales Line", SalesLineList, false);
    end;

    local procedure GetCoupledSalesLines(var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef; var SalesLineList: List of [Guid]): Boolean
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CRMSalesorder: Record "CRM Salesorder";
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if IntegrationRecordRef.Number() <> Database::"CRM Salesorder" then
            exit(false);

        IntegrationRecordRef.SetTable(CRMSalesorder);
        if IsNullGuid(CRMSalesorder.SalesOrderId) then
            exit(false);

        LocalRecordRef.SetTable(SalesHeader);
        if IsNullGuid(SalesHeader.SystemId) then
            exit(false);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        if SalesLine.FindSet() then
            repeat
                if CRMIntegrationRecord.IsRecordCoupled(SalesLine.RecordId) then
                    SalesLineList.Add(SalesLine.SystemId);
            until SalesLine.Next() = 0;

        exit(SalesLineList.Count() > 0);
    end;

    local procedure UpdateOwnerIdAndCompanyId(var DestinationRecordRef: RecordRef)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if CDSIntegrationImpl.IsIntegrationEnabled() then begin
            if not CDSIntegrationImpl.CheckCompanyIdNoTelemetry(DestinationRecordRef) then
                CDSIntegrationImpl.SetCompanyId(DestinationRecordRef);
            CDSConnectionSetup.Get();
            if CDSConnectionSetup."Ownership Model" = CDSConnectionSetup."Ownership Model"::Team then
                CDSIntegrationImpl.SetOwningTeam(DestinationRecordRef);
        end;
    end;

    local procedure SetCompanyId(var DestinationRecordRef: RecordRef)
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        if CDSIntegrationImpl.CheckCompanyIdNoTelemetry(DestinationRecordRef) then
            exit;

        CDSIntegrationImpl.SetCompanyId(DestinationRecordRef);
    end;

    local procedure GetSourceDestCode(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Text
    begin
        if (SourceRecordRef.Number() <> 0) and (DestinationRecordRef.Number() <> 0) then
            exit(StrSubstNo(SourceDestCodePatternTxt, SourceRecordRef.Name(), DestinationRecordRef.Name()));
        exit('');
    end;

    local procedure UpdateCustomerBlocked(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef): Boolean
    var
        Customer: Record Customer;
        CRMAccount: Record "CRM Account";
        DestinationFieldRef: FieldRef;
        SourceFieldRef: FieldRef;
        OptionValue: Integer;
    begin
        // Blocked - we're only handling from Active > Inactive meaning Blocked::"" > Blocked::"All"
        SourceFieldRef := SourceRecordRef.Field(CRMAccount.FieldNo(StatusCode));
        OptionValue := SourceFieldRef.Value();
        if OptionValue = CRMAccount.StatusCode::Inactive then begin
            DestinationFieldRef := DestinationRecordRef.Field(Customer.FieldNo(Blocked));
            OptionValue := DestinationFieldRef.Value();
            if OptionValue = Customer.Blocked::" ".AsInteger() then begin
                DestinationFieldRef.Value := Customer.Blocked::All;
                exit(true);
            end;
        end;
    end;

    local procedure UpdateContactParentCompany(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMContact: Record "CRM Contact";
        SourceFieldRef: FieldRef;
        ParentCustomerId: Guid;
    begin
        Session.LogMessage('0000ECA', UpdateContactParentCompanyTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        // When updating we also want to set the company contact id
        // We only allow updating contacts if the company has already been created
        SourceFieldRef := SourceRecordRef.Field(CRMContact.FieldNo(ParentCustomerId));
        ParentCustomerId := SourceFieldRef.Value();
        if not CRMSynchHelper.SetContactParentCompany(ParentCustomerId, DestinationRecordRef) then begin
            Session.LogMessage('0000ECB', StrSubstNo(UpdateContactParentCompanyFailedTxt, ParentCustomerId), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            if not CRMSynchHelper.IsContactBusinessRelationOptional() then
                Error(ContactMissingCompanyErr);
            exit;
        end;
        Session.LogMessage('0000ECH', UpdateContactParentCompanySuccessfulTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
    end;

    local procedure HandleContactQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        if IgnoreRecord then
            exit;

        if CRMSynchHelper.IsContactBusinessRelationOptional() then
            exit;

        if CRMSynchHelper.FindContactRelatedCustomer(SourceRecordRef, ContactBusinessRelation) then
            exit;

        if CRMIntegrationManagement.IsCDSIntegrationEnabled() then
            if CRMSynchHelper.FindContactRelatedVendor(SourceRecordRef, ContactBusinessRelation) then
                exit;

        IgnoreRecord := true;
    end;

    local procedure HandleItemQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Item: Record Item;
    begin
        if IgnoreRecord then
            exit;

        if not SalesReceivablesSetup.Get() then
            exit;

        SourceRecordRef.SetTable(Item);
        if SalesReceivablesSetup."Write-in Product No." <> Item."No." then
            exit;

        IgnoreRecord := true;
    end;

    local procedure HandleResourceQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Resource: Record Resource;
    begin
        if IgnoreRecord then
            exit;

        if not SalesReceivablesSetup.Get() then
            exit;

        SourceRecordRef.SetTable(Resource);
        if SalesReceivablesSetup."Write-in Product No." <> Resource."No." then
            exit;

        IgnoreRecord := true;
    end;

    local procedure HandleOpportunityQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        Opportunity: Record Opportunity;
        Contact: Record Contact;
        CDSConnectionSetup: Record "CDS Connection Setup";
        ContactRecordRef: RecordRef;
    begin
        if IgnoreRecord then
            exit;

        if not CRMIntegrationManagement.IsCDSIntegrationEnabled() then
            exit;

        CDSConnectionSetup.Get();
        if CDSConnectionSetup."Ownership Model" = CDSConnectionSetup."Ownership Model"::Person then
            exit;

        SourceRecordRef.SetTable(Opportunity);
        if not Contact.Get(Opportunity."Contact No.") then
            exit;

        ContactRecordRef.GetTable(Contact);
        if (Contact.Type <> Contact.Type::Person) or (Contact."Company No." = '') then
            IgnoreRecord := true;

        HandleContactQueryPostFilterIgnoreRecord(ContactRecordRef, IgnoreRecord);
    end;

    local procedure UpdateSalesPersOnBeforeInsertRecord(var DestinationRecordRef: RecordRef)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        DestinationFieldRef: FieldRef;
        NewCode: Text;
    begin
        if not (CRMIntegrationManagement.IsCDSIntegrationEnabled() or CRMIntegrationManagement.IsCRMIntegrationEnabled()) then
            exit;

        if CRMIntegrationManagement.IsCDSIntegrationEnabled() then
            exit;

        // We need to create a new code for this SP.
        // To do so we just do a SP NO. A
        SalespersonPurchaser.SetFilter(Code, SalespersonPurchaserCodeFilterLbl);
        if SalespersonPurchaser.FindLast() then
            NewCode := IncStr(SalespersonPurchaser.Code)
        else
            NewCode := StrSubstNo(NewCodePatternTxt, '00001');

        DestinationFieldRef := DestinationRecordRef.Field(SalespersonPurchaser.FieldNo(Code));
        DestinationFieldRef.Value := NewCode;
    end;

    local procedure UpdateCRMContactParentCustomerId(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMContact: Record "CRM Contact";
        ParentCustomerIdFieldRef: FieldRef;
        AccountId: Guid;
        Silent: Boolean;
    begin
        if CRMIntegrationManagement.IsCDSIntegrationEnabled() then
            exit;

        Silent := CRMSynchHelper.IsContactBusinessRelationOptional();
        if FindParentCRMAccountForContact(SourceRecordRef, Silent, AccountId) then begin
            // Tranfer the parent company id to the ParentCustomerId
            ParentCustomerIdFieldRef := DestinationRecordRef.Field(CRMContact.FieldNo(ParentCustomerId));
            ParentCustomerIdFieldRef.Value := AccountId;
        end;
    end;

    local procedure CheckSalesInvoiceLineItemsAreCoupled(SourceRecordRef: RecordRef)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SourceRecordRef.SetTable(SalesInvoiceHeader);

        // lock the posted sales invoice and lines tables in order not to read uncommitted records from SQL Server
        // it is OK to lock these tables, because we are going to release the locks in this method either with an error or a commit
        SalesInvoiceHeader.LockTable();
        if not SalesInvoiceHeader.Get(SalesInvoiceHeader."No.") then begin
            Session.LogMessage('0000GF4', StrSubstNo(FailedToGetPostedSalesInvoiceTxt, Format(SalesInvoiceHeader.SystemId)), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            Error(SalesInvoiceNotCommittedErr, SalesInvoiceHeader."No.");
        end;

        SalesInvoiceLine.LockTable();
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if SalesInvoiceLine.IsEmpty() then begin
            Session.LogMessage('0000GF5', StrSubstNo(FailedToGetPostedSalesInvoiceLinesTxt, Format(SalesInvoiceHeader.SystemId)), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            Error(SalesInvoiceLinesNotCommittedErr, SalesInvoiceHeader."No.");
        end;

        // this commit will release the lock on posted sales invoice tables, right after the IsEmpty.
        // it is justifiable to do this commit, because before raising OnBeforeInsert event,
        // codeunit "Integration Rec. Synch. Invoke" doesn't make a single attempt to write to the database. it just reads before this event.
        // It hasn't yet called Dynamics 365 Sales to insert the entity or attempted to couple it in Business Central.
        // on top of that, OnAfterInsert event starts with a commit, so subscribers to OnBeforeInsert should never attempt to write into the Business Central database
        Commit();

        // the lines have been committed to SQL database, it is OK to read them.
        // no if - let it throw an error if FindSet fails. in this case invoice will be synchronized with next scheduled job
        SalesInvoiceLine.FindSet();
        repeat
            // this call will throw an error if the Sales Invoice Line has an uncoupled product, thus avoiding the creation of the Dynamics 365 Sales invoice
            // at this point we haven't even called Dynamics 365 Sales to insert the invoice and we haven't even attempted to couple the invoice
            if SalesInvoiceLine."No." <> '' then
                FindCRMProductId(SalesInvoiceLine);
        until SalesInvoiceLine.Next() = 0;
    end;

    local procedure UpdateCRMInvoiceAfterInsertRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CRMInvoice: Record "CRM Invoice";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        DocumentTotals: Codeunit "Document Totals";
        SourceLinesRecordRef: RecordRef;
        TaxAmount: Decimal;
    begin
        Commit();
        SourceRecordRef.SetTable(SalesInvoiceHeader);
        DestinationRecordRef.SetTable(CRMInvoice);

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        if not SalesInvoiceLine.IsEmpty() then begin
            SourceLinesRecordRef.GetTable(SalesInvoiceLine);
            CRMIntegrationTableSynch.SynchRecordsToIntegrationTable(SourceLinesRecordRef, false, false);

            SalesInvoiceLine.CalcSums("Line Discount Amount");
            CRMInvoice.TotalLineItemDiscountAmount := SalesInvoiceLine."Line Discount Amount";
        end;

        CRMConnectionSetup.Get();

        if CRMConnectionSetup."Is S.Order Integration Enabled" or CRMConnectionSetup."Bidirectional Sales Order Int." then begin
            DocumentTotals.CalculatePostedSalesInvoiceTotals(SalesInvoiceHeader, TaxAmount, SalesInvoiceLine);
            CRMInvoice.TotalAmount := SalesInvoiceHeader."Amount Including VAT";
            CRMInvoice.TotalTax := TaxAmount;
            CRMInvoice.TotalAmountLessFreight := CRMInvoice.TotalAmount - CRMInvoice.TotalTax;
            CRMInvoice.TotalDiscountAmount := SalesInvoiceHeader."Invoice Discount Amount";
        end else begin
            CRMInvoice.FreightAmount := 0;
            CRMInvoice.DiscountPercentage := 0;
            CRMInvoice.TotalTax := CRMInvoice.TotalAmount - CRMInvoice.TotalAmountLessFreight;
            CRMInvoice.TotalDiscountAmount := CRMInvoice.DiscountAmount + CRMInvoice.TotalLineItemDiscountAmount;
        end;
        CRMInvoice.Modify();
        CRMSynchHelper.UpdateCRMInvoiceStatus(CRMInvoice, SalesInvoiceHeader);
        Commit();
    end;

    local procedure UpdatePricesIncludeVATRounding(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CRMInvoice: Record "CRM Invoice";
        CRMInvoicedetail: Record "CRM Invoicedetail";
        WriteInCRMInvoicedetail: Record "CRM Invoicedetail";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        DifferenceAmount: Decimal;
    begin
        SourceRecordRef.SetTable(SalesInvoiceHeader);
        DestinationRecordRef.SetTable(CRMInvoice);

        if SalesInvoiceHeader."Prices Including VAT" then begin
            SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
            if SalesInvoiceLine.FindSet() then begin
                CRMInvoicedetail.SetRange(InvoiceId, CRMInvoice.InvoiceId);
                CRMInvoicedetail.SetRange(IsProductOverridden, true);
                CRMInvoicedetail.SetRange(ProductDescription, 'Rounding');
                if not CRMInvoicedetail.IsEmpty() then
                    exit;
                CRMInvoicedetail.Reset();

                repeat
                    CRMInvoicedetail.SetRange(InvoiceId, CRMInvoice.InvoiceId);
                    CRMInvoicedetail.SetRange(LineItemNumber, SalesInvoiceLine."Line No.");
                    if CRMInvoicedetail.FindFirst() then
                        DifferenceAmount += SalesInvoiceLine."Amount Including VAT" - ((CRMInvoicedetail.PricePerUnit * CRMInvoicedetail.Quantity) + CRMInvoicedetail.Tax - CRMInvoicedetail.ManualDiscountAmount);
                until SalesInvoiceLine.Next() = 0;

                if DifferenceAmount <> 0 then begin
                    WriteInCRMInvoicedetail.Init();
                    WriteInCRMInvoicedetail.InvoiceId := CRMInvoice.InvoiceId;
                    WriteInCRMInvoicedetail.Quantity := 1;
                    WriteInCRMInvoicedetail.PricePerUnit := DifferenceAmount;
                    WriteInCRMInvoicedetail.IsProductOverridden := true;
                    WriteInCRMInvoicedetail.ProductDescription := 'Rounding';
                    WriteInCRMInvoicedetail.Insert();
                end;
            end;
        end;
    end;

    local procedure UpdateCRMInvoiceBeforeInsertRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMInvoice: Record "CRM Invoice";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMSalesorder: Record "CRM Salesorder";
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ShipmentMethod: Record "Shipment Method";
        CRMSalesOrderToSalesOrder: Codeunit "CRM Sales Order to Sales Order";
        OutStream: OutStream;
        AccountId: Guid;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCRMInvoiceBeforeInsertRecord(SourceRecordRef, DestinationRecordRef, IsHandled);
        if IsHandled then
            exit;

        SourceRecordRef.SetTable(SalesInvoiceHeader);
        DestinationRecordRef.SetTable(CRMInvoice);

        if not CRMInvoice.Description.HasValue() then
            // Shipment Method Code -> go to table Shipment Method, and from there extract the description and add it to
            if ShipmentMethod.Get(SalesInvoiceHeader."Shipment Method Code") then begin
                CRMInvoice.Description.CreateOutStream(OutStream, TEXTENCODING::UTF16);
                OutStream.WriteText(ShipmentMethod.Description);
            end;

        if CRMSalesOrderToSalesOrder.GetCRMSalesOrder(CRMSalesorder, SalesInvoiceHeader."Your Reference") then begin
            CRMInvoice.OpportunityId := CRMSalesorder.OpportunityId;
            CRMInvoice.SalesOrderId := CRMSalesorder.SalesOrderId;
            CRMInvoice.PriceLevelId := CRMSalesorder.PriceLevelId;
            CRMInvoice.Name := CRMSalesorder.Name;

            if not CRMSalesOrderToSalesOrder.GetCoupledCustomer(CRMSalesorder, Customer) then begin
                if not CRMSalesOrderToSalesOrder.GetCRMAccountOfCRMSalesOrder(CRMSalesorder, CRMAccount) then
                    Error(CustomerHasChangedErr, CRMSalesorder.OrderNumber, CRMProductName.CDSServiceName());
                if not CRMSynchHelper.SynchRecordIfMappingExists(Database::Customer, Database::"CRM Account", CRMAccount.AccountId) then
                    Error(CustomerHasChangedErr, CRMSalesorder.OrderNumber, CRMProductName.CDSServiceName());
            end;
            if Customer."No." <> SalesInvoiceHeader."Sell-to Customer No." then
                Error(CustomerHasChangedErr, CRMSalesorder.OrderNumber, CRMProductName.CDSServiceName());
            CRMInvoice.CustomerId := CRMSalesorder.CustomerId;
            CRMInvoice.CustomerIdType := CRMSalesorder.CustomerIdType;
            OnUpdateCRMInvoiceBeforeInsertRecordOnBeforeDestinationRecordRefGetTable(CRMInvoice, SalesInvoiceHeader);
            DestinationRecordRef.GetTable(CRMInvoice);
            if CRMSalesorder.OwnerIdType = CRMSalesorder.OwnerIdType::systemuser then
                CDSIntegrationImpl.SetOwningUser(DestinationRecordRef, CRMSalesOrder.OwnerId, true)
            else
                CDSIntegrationImpl.SetOwningTeam(DestinationRecordRef, CRMSalesorder.OwnerId, true);
            SetCompanyId(DestinationRecordRef);
        end else begin
            CRMInvoice.Name := SalesInvoiceHeader."No.";
            Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");

            if not CRMIntegrationRecord.FindIDFromRecordID(Customer.RecordId(), AccountId) then
                if not CRMSynchHelper.SynchRecordIfMappingExists(Database::Customer, Database::"CRM Account", Customer.RecordId()) then
                    Error(CustomerHasChangedErr, CRMSalesorder.OrderNumber, CRMProductName.CDSServiceName())
                else
                    if not CRMIntegrationRecord.FindIDFromRecordID(Customer.RecordId(), AccountId) then
                        Error(RecordMustBeCoupledErr, Customer.TableCaption(), Customer."No.", CRMProductName.CDSServiceName());

            CRMInvoice.CustomerId := AccountId;
            CRMInvoice.CustomerIdType := CRMInvoice.CustomerIdType::account;
            if not CRMSynchHelper.FindCRMPriceListByCurrencyCode(CRMPricelevel, SalesInvoiceHeader."Currency Code") then
                CRMSynchHelper.CreateCRMPricelevelInCurrency(
                  CRMPricelevel, SalesInvoiceHeader."Currency Code", SalesInvoiceHeader."Currency Factor");
            CRMInvoice.PriceLevelId := CRMPricelevel.PriceLevelId;
            DestinationRecordRef.GetTable(CRMInvoice);
            UpdateOwnerIdAndCompanyId(DestinationRecordRef);
        end;
    end;

    local procedure UpdateCRMInvoiceDetailsAfterInsertRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CRMInvoicedetail: Record "CRM Invoicedetail";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SourceRecordRef.SetTable(SalesInvoiceLine);
        DestinationRecordRef.SetTable(CRMInvoicedetail);

        CRMInvoicedetail.VolumeDiscountAmount := 0;
        CRMInvoicedetail.ManualDiscountAmount := SalesInvoiceLine."Line Discount Amount";
        CRMInvoicedetail.Tax := SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount;
        CRMInvoicedetail.BaseAmount :=
          SalesInvoiceLine.Amount + SalesInvoiceLine."Inv. Discount Amount" + SalesInvoiceLine."Line Discount Amount";
        CRMInvoicedetail.ExtendedAmount :=
          SalesInvoiceLine."Amount Including VAT" + SalesInvoiceLine."Inv. Discount Amount";
        CRMInvoicedetail.Modify();

        DestinationRecordRef.GetTable(CRMInvoicedetail);
    end;

    local procedure UpdateCRMInvoiceDetailsBeforeInsertRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMInvoicedetail: Record "CRM Invoicedetail";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSalesInvoiceHeaderId: Guid;
    begin
        SourceRecordRef.SetTable(SalesInvoiceLine);
        DestinationRecordRef.SetTable(CRMInvoicedetail);

        // Get the NAV and CRM invoice headers
        if not SalesInvoiceHeader.Get(SalesInvoiceLine."Document No.") then begin
            // if the Get fails, wait for 5 seconds, flush the cache and retry once more
            // this is necessary because lines synch is done in a separate thread from invoice synch, and invoice may not be in the SQL database yet
            Session.LogMessage('0000G8C', StrSubstNo(FailedToGetPostedSalesInvoiceTxt, SalesInvoiceLine."Document No."), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            Sleep(5000);
            Database.SelectLatestVersion();
            SalesInvoiceHeader.Get(SalesInvoiceLine."Document No.");
        end;
        if not CRMIntegrationRecord.FindIDFromRecordID(SalesInvoiceHeader.RecordId(), CRMSalesInvoiceHeaderId) then
            Error(NoCoupledSalesInvoiceHeaderErr, CRMProductName.CDSServiceName());

        // Initialize the CRM invoice lines
        InitializeCRMInvoiceLineFromCRMHeader(CRMInvoicedetail, CRMSalesInvoiceHeaderId);
        InitializeCRMInvoiceLineFromSalesInvoiceHeader(CRMInvoicedetail, SalesInvoiceHeader);
        InitializeCRMInvoiceLineFromSalesInvoiceLine(CRMInvoicedetail, SalesInvoiceLine);
        InitializeCRMInvoiceLineFromSalesInvoiceHeaderAndLine(CRMInvoicedetail, SalesInvoiceHeader, SalesInvoiceLine);
        InitializeCRMInvoiceLineWithProductDetails(CRMInvoicedetail, SalesInvoiceLine);

        CRMSynchHelper.CreateCRMProductpriceIfAbsent(CRMInvoicedetail);

        DestinationRecordRef.GetTable(CRMInvoicedetail);
    end;

    local procedure UpdateCRMPricelevelBeforeInsertRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMPricelevel: Record "CRM Pricelevel";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CustomerPriceGroup: Record "Customer Price Group";
        DestinationFieldRef: FieldRef;
        OutStream: OutStream;
    begin
        SourceRecordRef.SetTable(CustomerPriceGroup);
        CheckCustPriceGroupForSync(CRMTransactioncurrency, CustomerPriceGroup);

        DestinationFieldRef := DestinationRecordRef.Field(CRMPricelevel.FieldNo(TransactionCurrencyId));
        CRMSynchHelper.UpdateCRMCurrencyIdIfChanged(CRMTransactioncurrency.ISOCurrencyCode, DestinationFieldRef);

        DestinationRecordRef.SetTable(CRMPricelevel);
        CRMPricelevel.Description.CreateOutStream(OutStream, TEXTENCODING::UTF16);
        OutStream.WriteText(CustomerPriceGroup.Description);
        DestinationRecordRef.GetTable(CRMPricelevel);

        SetCompanyId(DestinationRecordRef);
    end;

    local procedure UpdateCRMPricelevelBeforeInsertPriceListHeader(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMPricelevel: Record "CRM Pricelevel";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        PriceListHeader: Record "Price List Header";
        DestinationFieldRef: FieldRef;
        OutStream: OutStream;
    begin
        SourceRecordRef.SetTable(PriceListHeader);
        CheckPriceListHeaderForSync(CRMTransactioncurrency, PriceListHeader);

        DestinationFieldRef := DestinationRecordRef.Field(CRMPricelevel.FieldNo(TransactionCurrencyId));
        CRMSynchHelper.UpdateCRMCurrencyIdIfChanged(CRMTransactioncurrency.ISOCurrencyCode, DestinationFieldRef);

        DestinationRecordRef.SetTable(CRMPricelevel);
        CRMPricelevel.Description.CreateOutStream(OutStream, TEXTENCODING::UTF16);
        OutStream.WriteText(PriceListHeader.Description);

        if PriceListHeader.Status = PriceListHeader.Status::Active then
            CRMPricelevel.StateCode := CRMPricelevel.StateCode::Active
        else
            CRMPricelevel.StateCode := CRMPricelevel.StateCode::Inactive;
        DestinationRecordRef.GetTable(CRMPricelevel);

        SetCompanyId(DestinationRecordRef);
    end;

    local procedure UpdateCRMOpportunityBeforeInsertRecord(var DestinationRecordRef: RecordRef)
    begin
        UpdateOwnerIdAndCompanyId(DestinationRecordRef);
    end;

    local procedure UpdateCRMPricelevelBeforeModifyRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMPricelevel: Record "CRM Pricelevel";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        SourceRecordRef.SetTable(CustomerPriceGroup);
        CheckCustPriceGroupForSync(CRMTransactioncurrency, CustomerPriceGroup);

        DestinationRecordRef.SetTable(CRMPricelevel);
        CRMPricelevel.TestField(TransactionCurrencyId, CRMTransactioncurrency.TransactionCurrencyId);

        SetCompanyId(DestinationRecordRef);
    end;

    local procedure UpdateCRMPricelevelBeforeModifyPriceListHeader(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMPricelevel: Record "CRM Pricelevel";
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        PriceListHeader: Record "Price List Header";
    begin
        SourceRecordRef.SetTable(PriceListHeader);
        CheckPriceListHeaderForSync(CRMTransactioncurrency, PriceListHeader);

        DestinationRecordRef.SetTable(CRMPricelevel);
        CRMPricelevel.TestField(TransactionCurrencyId, CRMTransactioncurrency.TransactionCurrencyId);

        SetCompanyId(DestinationRecordRef);
    end;

    local procedure ResetCRMProductpricelevelFromCustomerPriceGroup(SourceRecordRef: RecordRef)
    var
        CustomerPriceGroup: Record "Customer Price Group";
        SalesPrice: Record "Sales Price";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        SalesPriceRecordRef: RecordRef;
    begin
        SourceRecordRef.SetTable(CustomerPriceGroup);

        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"Customer Price Group");
        SalesPrice.SetRange("Sales Code", CustomerPriceGroup.Code);
        if not SalesPrice.IsEmpty() then begin
            SalesPriceRecordRef.GetTable(SalesPrice);
            CRMIntegrationTableSynch.SynchRecordsToIntegrationTable(SalesPriceRecordRef, false, false);
        end;
    end;

    local procedure ResetCRMProductpricelevelFromPriceListHeader(SourceRecordRef: RecordRef)
    var
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        SalesPriceRecordRef: RecordRef;
    begin
        SourceRecordRef.SetTable(PriceListHeader);

        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        if not PriceListLine.IsEmpty() then begin
            SalesPriceRecordRef.GetTable(PriceListLine);
            CRMIntegrationTableSynch.SynchRecordsToIntegrationTable(SalesPriceRecordRef, false, false);
        end;
    end;

    local procedure ResetCRMSalesorderdetailFromSalesOrderLine(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        CRMSalesorderdetail2: Record "CRM Salesorderdetail";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        SalesLineRecordRef: RecordRef;
    begin
        SourceRecordRef.SetTable(SalesHeader);
        DestinationRecordRef.SetTable(CRMSalesorder);

        CRMSalesorderdetail.SetRange(SalesOrderId, CRMSalesorder.SalesOrderId);
        if CRMSalesorderdetail.FindSet() then
            repeat
                CRMIntegrationRecord.SetRange("CRM ID", CRMSalesorderdetail.SalesOrderDetailId);
                CRMIntegrationRecord.SetRange("Table ID", Database::"Sales Line");
                if CRMIntegrationRecord.FindFirst() then begin
                    SalesLine.SetRange(SystemId, CRMIntegrationRecord."Integration ID");
                    if SalesLine.IsEmpty() then begin
                        CRMIntegrationRecord.Delete();
                        CRMSalesorderdetail2.Get(CRMSalesorderdetail.SalesOrderDetailId);
                        CRMSalesorderdetail2.Delete();
                    end;
                end;
            until CRMSalesorderdetail.Next() = 0;

        IntegrationTableMapping.FindMapping(Database::"Sales Line", Database::"CRM Salesorderdetail");

        SalesLine.Reset();
        SalesLine.SetView(IntegrationTableMapping.GetTableFilter());
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        if not SalesLine.IsEmpty() then begin
            SalesLineRecordRef.GetTable(SalesLine);
            CRMIntegrationTableSynch.SynchRecordsToIntegrationTable(SalesLineRecordRef, false, false);

            SalesLine.CalcSums("Line Discount Amount");
            if CRMSalesorder.TotalLineItemDiscountAmount <> SalesLine."Line Discount Amount" then begin
                CRMSalesorder.TotalLineItemDiscountAmount := SalesLine."Line Discount Amount";
                CRMSalesorder.Modify();
            end;
        end;
    end;

    local procedure ResetSalesOrderLineFromCRMSalesorderdetail(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Salesline2: Record "Sales Line";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSalesorder: Record "CRM Salesorder";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        CRMSalesorderdetail2: Record "CRM Salesorderdetail";
        CRMProduct: Record "CRM Product";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        CRMSalesorderdetailRecordRef: RecordRef;
        CRMSalesorderdetailId: Guid;
        CRMSalesorderdetailIdList: List of [Guid];
        CRMSalesorderdetailIdFilter: Text;
    begin
        SourceRecordRef.SetTable(CRMSalesorder);
        DestinationRecordRef.SetTable(SalesHeader);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        if SalesLine.FindSet() then
            repeat
                CRMIntegrationRecord.SetRange("Integration ID", SalesLine.SystemId);
                CRMIntegrationRecord.SetRange("Table ID", Database::"Sales Line");
                if CRMIntegrationRecord.FindFirst() then begin
                    CRMSalesorderdetail.SetRange(SalesOrderDetailId, CRMIntegrationRecord."CRM ID");
                    if CRMSalesorderdetail.IsEmpty() then begin
                        CRMIntegrationRecord.Delete();
                        SalesLine2.GetBySystemId(SalesLine.SystemId);
                        SalesLine2.Delete(true);
                    end;
                end;
            until SalesLine.Next() = 0;

        IntegrationTableMapping.FindMapping(Database::"Sales Line", Database::"CRM Salesorderdetail");

        CRMSalesorderdetail.Reset();
        CRMSalesorderdetail.SetView(IntegrationTableMapping.GetIntegrationTableFilter());
        CRMSalesorderdetail.SetRange(SalesOrderId, CRMSalesorder.SalesOrderId);
        if CRMSalesorderdetail.FindSet() then begin
            repeat
                if IsNullGuid(CRMSalesorderdetail.ProductId) then
                    CRMSalesorderdetailIdList.Add(CRMSalesorderdetail.SalesOrderDetailId)
                else begin
                    CRMProduct.Get(CRMSalesorderdetail.ProductId);
                    if CRMProduct.ProductTypeCode in [CRMProduct.ProductTypeCode::SalesInventory, CRMProduct.ProductTypeCode::Services] then
                        CRMSalesorderdetailIdList.Add(CRMSalesorderdetail.SalesOrderDetailId);
                end;
            until CRMSalesorderdetail.Next() = 0;

            foreach CRMSalesorderdetailId in CRMSalesorderdetailIdList do
                CRMSalesorderdetailIdFilter += CRMSalesorderdetailId + '|';
            CRMSalesorderdetailIdFilter := CRMSalesorderdetailIdFilter.TrimEnd('|');

            CRMSalesorderdetail2.SetFilter(SalesOrderDetailId, CRMSalesorderdetailIdFilter);
            CRMSalesorderdetailRecordRef.GetTable(CRMSalesorderdetail2);
            CRMIntegrationTableSynch.SynchRecordsFromIntegrationTable(CRMSalesorderdetailRecordRef, Database::"Sales Line", false, false);
        end;
    end;

    local procedure ApplySalesLineTax(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        SalesLine: Record "Sales Line";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        IsHandled: Boolean;
    begin
        SourceRecordRef.SetTable(SalesLine);
        DestinationRecordRef.SetTable(CRMSalesorderdetail);

        IsHandled := false;
        OnApplySalesLineTaxOnBeforeSetTax(CRMSalesorderdetail, SalesLine, IsHandled);
        if IsHandled then
            exit;

        CRMSalesorderdetail.Tax := SalesLine."Amount Including VAT" - SalesLine.Amount;

        DestinationRecordRef.GetTable(CRMSalesorderdetail);
    end;

    local procedure ApplySalesOrderDiscounts(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        ChangedSalesHeader: Record "Sales Header";
        CRMSalesorder: Record "CRM Salesorder";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        CRMDiscountAmount: Decimal;
    begin
        SourceRecordRef.SetTable(CRMSalesorder);
        DestinationRecordRef.SetTable(SalesHeader);

        if (CRMSalesorder.DiscountAmount = 0) and (CRMSalesorder.DiscountPercentage = 0) then
            exit;

        CRMDiscountAmount := CRMSalesorder.TotalLineItemAmount - CRMSalesorder.TotalAmountLessFreight;
        ChangedSalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(CRMDiscountAmount, ChangedSalesHeader);

        DestinationRecordRef.GetTable(ChangedSalesHeader);
    end;

    local procedure CreateFreightLines(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CRMSalesorder: Record "CRM Salesorder";
    begin
        SourceRecordRef.SetTable(CRMSalesorder);
        DestinationRecordRef.SetTable(SalesHeader);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindFirst() then
            SalesLine.InsertFreightLine(CRMSalesorder.FreightAmount);
    end;

    local procedure UpdateCRMProductPricelevelAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) UoMHasBeenChanged: Boolean
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
        SalesPrice: Record "Sales Price";
        CRMUom: Record "CRM Uom";
    begin
        DestinationRecordRef.SetTable(CRMProductpricelevel);
        SourceRecordRef.SetTable(SalesPrice);
        FindCRMUoMIdForSalesPrice(Enum::"Price Asset Type"::Item, SalesPrice."Item No.", SalesPrice."Unit of Measure Code", CRMUom);
        if CRMProductpricelevel.UoMId <> CRMUom.UoMId then begin
            CRMProductpricelevel.UoMId := CRMUom.UoMId;
            CRMProductpricelevel.UoMScheduleId := CRMUom.UoMScheduleId;
            UoMHasBeenChanged := true;
        end;
        DestinationRecordRef.GetTable(CRMProductpricelevel);
    end;

    local procedure UpdateCRMProductPricelevelAfterTransferRecordFieldsPriceListLine(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) UoMHasBeenChanged: Boolean
    var
        CRMProductpricelevel: Record "CRM Productpricelevel";
        PriceListLine: Record "Price List Line";
        CRMUom: Record "CRM Uom";
    begin
        DestinationRecordRef.SetTable(CRMProductpricelevel);
        SourceRecordRef.SetTable(PriceListLine);
        FindCRMUoMIdForSalesPrice(PriceListLine."Asset Type", PriceListLine."Asset No.", PriceListLine."Unit of Measure Code", CRMUom);
        if CRMProductpricelevel.UoMScheduleId <> CRMUom.UoMScheduleId then begin
            CRMProductpricelevel.UoMScheduleId := CRMUom.UoMScheduleId;
            UoMHasBeenChanged := true;
        end;
        if CRMProductpricelevel.UoMId <> CRMUom.UoMId then begin
            CRMProductpricelevel.UoMId := CRMUom.UoMId;
            UoMHasBeenChanged := true;
        end;
        DestinationRecordRef.GetTable(CRMProductpricelevel);
    end;

    local procedure UpdateCRMProductAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; DestinationIsInserted: Boolean) AdditionalFieldsWereModified: Boolean
    var
        Item: Record Item;
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DestinationFieldRef: FieldRef;
        UnitOfMeasureCodeFieldRef: FieldRef;
        UnitOfMeasureCode: Code[10];
        ProductTypeCode: Option;
        Blocked: Boolean;
    begin
        // Update CRM UoM ID, UoMSchedule Id. The CRM UoM Name and UoMScheduleName will be cascade-updated from their IDs by CRM
        if SourceRecordRef.Number() = DATABASE::Item then begin
            Blocked := SourceRecordRef.Field(Item.FieldNo(Blocked)).Value();
            OnUpdateCRMProductAfterTransferRecordFieldsOnAfterCalcItemBlocked(SourceRecordRef, Blocked);
            UnitOfMeasureCodeFieldRef := SourceRecordRef.Field(Item.FieldNo("Base Unit of Measure"));
            ProductTypeCode := CRMProduct.ProductTypeCode::SalesInventory;
        end;

        if SourceRecordRef.Number() = DATABASE::Resource then begin
            Blocked := SourceRecordRef.Field(Resource.FieldNo(Blocked)).Value();
            UnitOfMeasureCodeFieldRef := SourceRecordRef.Field(Resource.FieldNo("Base Unit of Measure"));
            ProductTypeCode := CRMProduct.ProductTypeCode::Services;
        end;

        // Update CRM Currency Id (if changed)
        GeneralLedgerSetup.Get();
        DestinationFieldRef := DestinationRecordRef.Field(CRMProduct.FieldNo(TransactionCurrencyId));
        if CRMSynchHelper.UpdateCRMCurrencyIdIfChanged(Format(GeneralLedgerSetup."LCY Code"), DestinationFieldRef) then
            AdditionalFieldsWereModified := true;

        DestinationRecordRef.SetTable(CRMProduct);
        if not CRMIntegrationManagement.IsUnitGroupMappingEnabled() then begin
            UnitOfMeasureCodeFieldRef.TestField();
            UnitOfMeasureCode := Format(UnitOfMeasureCodeFieldRef.Value());
            if CRMSynchHelper.UpdateCRMProductUoMFieldsIfChanged(CRMProduct, UnitOfMeasureCode) then
                AdditionalFieldsWereModified := true;
        end else
            if CRMSynchHelper.UpdateCRMProductUomscheduleId(CRMProduct, SourceRecordRef) then
                AdditionalFieldsWereModified := true;

        // If the CRMProduct price is negative, update it to zero (CRM doesn't allow negative prices)
        if CRMSynchHelper.UpdateCRMProductPriceIfNegative(CRMProduct) then
            AdditionalFieldsWereModified := true;

        // If the CRM Quantity On Hand is negative, update it to zero
        if CRMSynchHelper.UpdateCRMProductQuantityOnHandIfNegative(CRMProduct) then
            AdditionalFieldsWereModified := true;

        // Create or update the default price list
        if not CRMIntegrationManagement.IsUnitGroupMappingEnabled() then begin
            if CRMSynchHelper.UpdateCRMPriceListItem(CRMProduct) then
                AdditionalFieldsWereModified := true;
        end else
            if CRMSynchHelper.UpdateCRMPriceListItems(CRMProduct) then
                AdditionalFieldsWereModified := true;


        // Update the Vendor Name
        if CRMSynchHelper.UpdateCRMProductVendorNameIfChanged(CRMProduct) then
            AdditionalFieldsWereModified := true;

        // Set the ProductTypeCode, to later know if this product came from an item or from a resource
        if CRMSynchHelper.UpdateCRMProductTypeCodeIfChanged(CRMProduct, ProductTypeCode) then
            AdditionalFieldsWereModified := true;

        if DestinationIsInserted then
            if CRMSynchHelper.UpdateCRMProductStateCodeIfChanged(CRMProduct, Blocked) then
                AdditionalFieldsWereModified := true;

        if AdditionalFieldsWereModified then
            DestinationRecordRef.GetTable(CRMProduct);
    end;

    local procedure UpdateCRMProductAfterInsertRecord(var DestinationRecordRef: RecordRef)
    var
        CRMProduct: Record "CRM Product";
    begin
        DestinationRecordRef.SetTable(CRMProduct);
        if not CRMIntegrationManagement.IsUnitGroupMappingEnabled() then
            CRMSynchHelper.UpdateCRMPriceListItem(CRMProduct)
        else
            CRMSynchHelper.UpdateCRMPriceListItems(CRMProduct);
        CRMSynchHelper.SetCRMProductStateToActive(CRMProduct);
        CRMProduct.Modify();
        DestinationRecordRef.GetTable(CRMProduct);
    end;

    local procedure UpdateCRMUomFromItemAfterInsertRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMProduct: Record "CRM Product";
        CRMUom: Record "CRM Uom";
        ItemRecordRef: RecordRef;
        SourceFieldRef: FieldRef;
        CRMProductId: Guid;
    begin
        SourceFieldRef := SourceRecordRef.Field(ItemUnitOfMeasure.FieldNo("Item No."));
        Item.Get(Format(SourceFieldRef.Value()));
        ItemRecordRef.GetTable(Item);
        DestinationRecordRef.SetTable(CRMUom);
        if CRMIntegrationRecord.FindIDFromRecordRef(ItemRecordRef, CRMProductId) then
            if CRMProduct.Get(CRMProductId) then
                CRMSynchHelper.UpdateCRMPriceListItemForUom(CRMProduct, CRMUom);
    end;

    local procedure UpdateCRMUomFromResourceAfterInsertRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        Resource: Record Resource;
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMProduct: Record "CRM Product";
        CRMUom: Record "CRM Uom";
        ResourceRecordRef: RecordRef;
        SourceFieldRef: FieldRef;
        CRMProductId: Guid;
    begin
        SourceFieldRef := SourceRecordRef.Field(ResourceUnitOfMeasure.FieldNo("Resource No."));
        Resource.Get(Format(SourceFieldRef.Value()));
        ResourceRecordRef.GetTable(Resource);
        DestinationRecordRef.SetTable(CRMUom);
        if CRMIntegrationRecord.FindIDFromRecordRef(ResourceRecordRef, CRMProductId) then
            if CRMProduct.Get(CRMProductId) then
                CRMSynchHelper.UpdateCRMPriceListItemForUom(CRMProduct, CRMUom)
    end;

    local procedure UpdateCRMProductBeforeInsertRecord(var DestinationRecordRef: RecordRef)
    var
        CRMProduct: Record "CRM Product";
    begin
        DestinationRecordRef.SetTable(CRMProduct);
        CRMSynchHelper.SetCRMDecimalsSupportedValue(CRMProduct);
        CRMSynchHelper.SetCRMDefaultPriceListOnProduct(CRMProduct);
        DestinationRecordRef.GetTable(CRMProduct);
        SetCompanyId(DestinationRecordRef);
    end;

    local procedure UpdateItemAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) AdditionalFieldsWereModified: Boolean
    var
        Item: Record Item;
        CRMProduct: Record "CRM Product";
        Blocked: Boolean;
    begin
        SourceRecordRef.SetTable(CRMProduct);
        DestinationRecordRef.SetTable(Item);

        Blocked := CRMProduct.StateCode <> CRMProduct.StateCode::Active;
        if CRMSynchHelper.UpdateItemBlockedIfChanged(Item, Blocked) then begin
            DestinationRecordRef.GetTable(Item);
            AdditionalFieldsWereModified := true;
        end;
    end;

    local procedure UpdateResourceAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) AdditionalFieldsWereModified: Boolean
    var
        Resource: Record Resource;
        CRMProduct: Record "CRM Product";
        Blocked: Boolean;
    begin
        SourceRecordRef.SetTable(CRMProduct);
        DestinationRecordRef.SetTable(Resource);

        Blocked := CRMProduct.StateCode <> CRMProduct.StateCode::Active;
        if CRMSynchHelper.UpdateResourceBlockedIfChanged(Resource, Blocked) then begin
            DestinationRecordRef.GetTable(Resource);
            AdditionalFieldsWereModified := true;
        end;
    end;

    local procedure UpdateCRMTransactionCurrencyBeforeInsertRecord(var DestinationRecordRef: RecordRef)
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        DestinationCurrencyPrecisionFieldRef: FieldRef;
    begin
        // Fill in the target currency precision, taken from CRM precision defaults
        DestinationCurrencyPrecisionFieldRef := DestinationRecordRef.Field(CRMTransactioncurrency.FieldNo(CurrencyPrecision));
        DestinationCurrencyPrecisionFieldRef.Value := CRMSynchHelper.GetCRMCurrencyDefaultPrecision();
    end;

    local procedure UpdateCRMTransactionCurrencyAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) AdditionalFieldsWereModified: Boolean
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        Currency: Record Currency;
        CurrencyCodeFieldRef: FieldRef;
        DestinationExchangeRateFieldRef: FieldRef;
        LatestExchangeRate: Decimal;
    begin
        // Fill-in the target currency Exchange Rate
        CurrencyCodeFieldRef := SourceRecordRef.Field(Currency.FieldNo(Code));
        DestinationExchangeRateFieldRef := DestinationRecordRef.Field(CRMTransactioncurrency.FieldNo(ExchangeRate));
        LatestExchangeRate := CRMSynchHelper.GetCRMLCYToFCYExchangeRate(Format(CurrencyCodeFieldRef.Value()));
        if LatestExchangeRate = 0 then
            Error(CurrencyExchangeRateMissingErr, Format(CurrencyCodeFieldRef.Value()), CRMProductName.CDSServiceName());
        if CRMSynchHelper.UpdateFieldRefValueIfChanged(
             DestinationExchangeRateFieldRef,
             Format(LatestExchangeRate))
        then
            AdditionalFieldsWereModified := true;
    end;

    local procedure CRMTransactionCurrencyFindUncoupledDestinationRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) DestinationFound: Boolean
    var
        Currency: Record Currency;
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        CurrencyCodeFieldRef: FieldRef;
    begin
        // Attempt to match currencies between NAV and CRM, on NAVCurrency.Code = CRMCurrency.ISOCode
        CurrencyCodeFieldRef := SourceRecordRef.Field(Currency.FieldNo(Code));

        // Find destination record
        CRMTransactioncurrency.SetRange(ISOCurrencyCode, Format(CurrencyCodeFieldRef.Value()));
        // A match between the selected NAV currency and a CRM currency was found
        if CRMTransactioncurrency.FindFirst() then
            DestinationFound := DestinationRecordRef.Get(CRMTransactioncurrency.RecordId());
    end;

    local procedure CRMPriceListLineFindUncoupledDestinationRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) DestinationFound: Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        CRMUom: Record "CRM Uom";
        CustomerPriceGroup: Record "Customer Price Group";
        Item: Record Item;
        SalesPrice: Record "Sales Price";
    begin
        // Look for a line with the same combination of ProductId,UoMId
        SourceRecordRef.SetTable(SalesPrice);
        CustomerPriceGroup.Get(SalesPrice."Sales Code");
        if CRMIntegrationRecord.FindByRecordID(CustomerPriceGroup.RecordId()) then begin
            CRMProductpricelevel.SetRange(PriceLevelId, CRMIntegrationRecord."CRM ID");
            FindCRMUoMIdForSalesPrice(Enum::"Price Asset Type"::Item, SalesPrice."Item No.", SalesPrice."Unit of Measure Code", CRMUom);
            CRMProductpricelevel.SetRange(UoMId, CRMUom.UoMId);
            Item.Get(SalesPrice."Item No.");
            CRMIntegrationRecord.FindByRecordID(Item.RecordId());
            CRMProductpricelevel.SetRange(ProductId, CRMIntegrationRecord."CRM ID");
            DestinationFound := CRMProductpricelevel.FindFirst();
            DestinationRecordRef.GetTable(CRMProductpricelevel);
        end;
    end;

    local procedure CRMExtPriceListLineFindUncoupledDestinationRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) DestinationFound: Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMProductpricelevel: Record "CRM Productpricelevel";
        CRMUom: Record "CRM Uom";
        Item: Record Item;
        Resource: Record Resource;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // Look for a line with the same combination of ProductId,UoMId
        SourceRecordRef.SetTable(PriceListLine);
        PriceListHeader.Get(PriceListLine."Price List Code");
        if CRMIntegrationRecord.FindByRecordID(PriceListHeader.RecordId()) then begin
            CRMProductpricelevel.SetRange(PriceLevelId, CRMIntegrationRecord."CRM ID");
            FindCRMUoMIdForSalesPrice(PriceListLine."Asset Type", PriceListLine."Asset No.", PriceListLine."Unit of Measure Code", CRMUom);
            CRMProductpricelevel.SetRange(UoMId, CRMUom.UoMId);
            case PriceListLine."Asset Type" of
                PriceListLine."Asset Type"::Item:
                    begin
                        Item.Get(PriceListLine."Asset No.");
                        CRMIntegrationRecord.FindByRecordID(Item.RecordId());
                    end;
                PriceListLine."Asset Type"::Resource:
                    begin
                        Resource.Get(PriceListLine."Asset No.");
                        CRMIntegrationRecord.FindByRecordID(Resource.RecordId());
                    end;
            end;
            CRMProductpricelevel.SetRange(ProductId, CRMIntegrationRecord."CRM ID");
            DestinationFound := CRMProductpricelevel.FindFirst();
            DestinationRecordRef.GetTable(CRMProductpricelevel);
        end;
    end;

    local procedure UpdateCRMUoMScheduleAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) AdditionalFieldsWereModified: Boolean
    var
        CRMUomschedule: Record "CRM Uomschedule";
        DestinationFieldRef: FieldRef;
        UnitNameWasUpdated: Boolean;
        CRMUomScheduleName: Text[200];
        CRMUomScheduleStateCode: Option;
        UnitGroupName: Text[200];
        UnitOfMeasureName: Text[100];
        CRMID: Guid;
    begin
        // Prefix with NAV
        UnitOfMeasureName := CRMSynchHelper.GetUnitOfMeasureName(SourceRecordRef);
        UnitGroupName := CRMSynchHelper.GetUnitGroupName(UnitOfMeasureName); // prefix with "NAV "
        DestinationFieldRef := DestinationRecordRef.Field(CRMUomschedule.FieldNo(Name));
        CRMUomScheduleName := Format(DestinationFieldRef.Value());
        if CRMUomScheduleName <> UnitGroupName then begin
            DestinationFieldRef.Value := UnitGroupName;
            AdditionalFieldsWereModified := true;
        end;

        // Get the State Code
        DestinationFieldRef := DestinationRecordRef.Field(CRMUomschedule.FieldNo(StateCode));
        CRMUomScheduleStateCode := DestinationFieldRef.Value();

        DestinationFieldRef := DestinationRecordRef.Field(CRMUomschedule.FieldNo(UoMScheduleId));
        CRMID := DestinationFieldRef.Value();
        if not ValidateCRMUoMSchedule(CRMUomScheduleName, CRMUomScheduleStateCode, CRMID, UnitOfMeasureName, UnitNameWasUpdated) then
            exit;

        if UnitNameWasUpdated then
            AdditionalFieldsWereModified := true;
    end;

    local procedure CheckCRMUoMScheduleAfterTransferRecordFields(var DestinationRecordRef: RecordRef)
    var
        CRMUomschedule: Record "CRM Uomschedule";
        DestinationFieldRef: FieldRef;
        CRMUomScheduleName: Text[200];
        CRMUomScheduleStateCode: Option;
    begin
        DestinationFieldRef := DestinationRecordRef.Field(CRMUomschedule.FieldNo(StateCode));
        CRMUomScheduleStateCode := DestinationFieldRef.Value();
        DestinationFieldRef := DestinationRecordRef.Field(CRMUomschedule.FieldNo(Name));
        CRMUomScheduleName := Format(DestinationFieldRef.Value());
        if CRMUomScheduleStateCode = CRMUomschedule.StateCode::Inactive then
            Error(CRMUnitGroupExistsAndIsInactiveErr, CRMUomschedule.TableCaption(), CRMUomScheduleName, CRMProductName.CDSServiceName());
    end;

    local procedure UpdateCRMUomFromItemAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef): Boolean
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitGroup: Record "Unit Group";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMUom: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
        CRMProduct: Record "CRM Product";
        ItemRecordRef: RecordRef;
        SourceFieldRef: FieldRef;
        DestinationFieldRef: FieldRef;
        CRMUomscheduleId: Guid;
        CRMProductId: Guid;
        AdditionalFieldsWereModified: Boolean;
    begin
        DestinationFieldRef := DestinationRecordRef.Field(CRMUom.FieldNo(UoMScheduleId));
        SourceFieldRef := SourceRecordRef.Field(ItemUnitOfMeasure.FieldNo("Item No."));

        Item.Get(Format(SourceFieldRef.Value()));

        UnitGroup.SetRange("Source Id", Item.SystemId);
        UnitGroup.SetRange("Source Type", UnitGroup."Source Type"::Item);
        if not UnitGroup.FindFirst() then
            Error(ItemUnitGroupNotFoundErr, Item."No.");

        CRMUomscheduleId := DestinationFieldRef.Value();
        CRMUomschedule.SetRange(Name, UnitGroup.GetCode());
        if not CRMUomschedule.FindFirst() then begin
            CoupleAndSyncUnitGroup(UnitGroup);
            CRMUomschedule.FindFirst();
        end;
        if CRMUomscheduleId <> CRMUomschedule.UoMScheduleId then begin
            DestinationFieldRef.Value := CRMUomschedule.UoMScheduleId;
            AdditionalFieldsWereModified := true;
        end;

        ItemRecordRef.GetTable(Item);
        DestinationRecordRef.SetTable(CRMUom);
        if CRMIntegrationRecord.FindIDFromRecordRef(ItemRecordRef, CRMProductId) then
            if CRMProduct.Get(CRMProductId) then
                if CRMSynchHelper.UpdateCRMPriceListItemForUom(CRMProduct, CRMUom) then
                    AdditionalFieldsWereModified := true;

        exit(AdditionalFieldsWereModified);
    end;

    local procedure UpdateCRMUomFromResourceAfterTransferRecordFields(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef): Boolean
    var
        Resource: Record Resource;
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        UnitGroup: Record "Unit Group";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMUom: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
        CRMProduct: Record "CRM Product";
        ResourceRecordRef: RecordRef;
        SourceFieldRef: FieldRef;
        DestinationFieldRef: FieldRef;
        CRMUomscheduleId: Guid;
        CRMProductId: Guid;
        AdditionalFieldsWereModified: Boolean;
    begin
        DestinationFieldRef := DestinationRecordRef.Field(CRMUom.FieldNo(UoMScheduleId));
        SourceFieldRef := SourceRecordRef.Field(ResourceUnitOfMeasure.FieldNo("Resource No."));

        Resource.Get(Format(SourceFieldRef.Value()));

        UnitGroup.SetRange("Source Id", Resource.SystemId);
        UnitGroup.SetRange("Source Type", UnitGroup."Source Type"::Resource);
        if not UnitGroup.FindFirst() then
            Error(ResourceUnitGroupNotFoundErr, Resource."No.");

        CRMUomscheduleId := DestinationFieldRef.Value();
        CRMUomschedule.SetRange(Name, UnitGroup.GetCode());
        if not CRMUomschedule.FindFirst() then begin
            CoupleAndSyncUnitGroup(UnitGroup);
            CRMUomschedule.FindFirst();
        end;
        if CRMUomscheduleId <> CRMUomschedule.UoMScheduleId then begin
            DestinationFieldRef.Value := CRMUomschedule.UoMScheduleId;
            AdditionalFieldsWereModified := true;
        end;

        ResourceRecordRef.GetTable(Resource);
        DestinationRecordRef.SetTable(CRMUom);
        if CRMIntegrationRecord.FindIDFromRecordRef(ResourceRecordRef, CRMProductId) then
            if CRMProduct.Get(CRMProductId) then
                if CRMSynchHelper.UpdateCRMPriceListItemForUom(CRMProduct, CRMUom) then
                    AdditionalFieldsWereModified := true;

        exit(AdditionalFieldsWereModified);
    end;

    local procedure CoupleAndSyncUnitGroup(var UnitGroup: Record "Unit Group")
    var
        CRMIntegrationTableSynch: Codeunit "CRM Integration Table Synch.";
        UnitGroupRecordRef: RecordRef;
    begin
        UnitGroupRecordRef.GetTable(UnitGroup);
        CRMIntegrationTableSynch.SynchRecordsToIntegrationTable(UnitGroupRecordRef, false, true);
    end;

    local procedure CRMUoMScheduleFindUncoupledDestinationRecord(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef) DestinationFound: Boolean
    var
        CRMUomschedule: Record "CRM Uomschedule";
        UnitFieldWasUpdated: Boolean;
    begin
        // A match between the selected NAV Unit of Measure and a CRM <Unit Group, Unit> tuple was found
        if FindValidCRMUoMSchedule(CRMUomschedule, SourceRecordRef, UnitFieldWasUpdated) then
            DestinationFound := DestinationRecordRef.Get(CRMUomschedule.RecordId());
    end;

    local procedure FindValidCRMUoMSchedule(var CRMUomschedule: Record "CRM Uomschedule"; SourceRecordRef: RecordRef; var UnitNameWasUpdated: Boolean): Boolean
    var
        UnitGroupName: Text[200];
        UnitOfMeasureName: Text[100];
    begin
        UnitOfMeasureName := CRMSynchHelper.GetUnitOfMeasureName(SourceRecordRef);
        UnitGroupName := CRMSynchHelper.GetUnitGroupName(UnitOfMeasureName); // prefix with "NAV "

        // If the CRM Unit Group does not exist, exit
        CRMUomschedule.SetRange(Name, UnitGroupName);
        if not CRMUomschedule.FindFirst() then
            exit(false);

        ValidateCRMUoMSchedule(
          CRMUomschedule.Name, CRMUomschedule.StateCode, CRMUomschedule.UoMScheduleId, UnitOfMeasureName, UnitNameWasUpdated);

        exit(true);
    end;

    local procedure ValidateCRMUoMSchedule(CRMUomScheduleName: Text[200]; CRMUomScheduleStateCode: Option; CRMUomScheduleId: Guid; UnitOfMeasureName: Text[100]; var UnitNameWasUpdated: Boolean): Boolean
    var
        CRMUom: Record "CRM Uom";
        CRMUomschedule: Record "CRM Uomschedule";
    begin
        // If the CRM Unit Group is not active throw and error
        if CRMUomScheduleStateCode = CRMUomschedule.StateCode::Inactive then
            Error(CRMUnitGroupExistsAndIsInactiveErr, CRMUomschedule.TableCaption(), CRMUomScheduleName, CRMProductName.CDSServiceName());

        // If the CRM Unit Group contains > 1 Units, fail
        CRMUom.SetRange(UoMScheduleId, CRMUomScheduleId);
        if CRMUom.Count() > 1 then
            Error(
              CRMUnitGroupContainsMoreThanOneUoMErr, CRMUomschedule.TableCaption(), CRMUomScheduleName, CRMUom.TableCaption(),
              CRMProductName.CDSServiceName());

        // If the CRM Unit Group contains zero Units, then exit (no match found)
        if not CRMUom.FindFirst() then
            exit(false);

        // Verify the CRM Unit name is correct, else update it
        if CRMUom.Name <> UnitOfMeasureName then begin
            CRMUom.Name := UnitOfMeasureName;
            CRMUom.Modify();
            UnitNameWasUpdated := true;
        end;

        exit(true);
    end;

    local procedure FindParentCRMAccountForContact(SourceRecordRef: RecordRef; Silent: Boolean; var AccountId: Guid): Boolean
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
        Customer: Record Customer;
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if CRMSynchHelper.FindContactRelatedCustomer(SourceRecordRef, ContactBusinessRelation) then begin
            if Customer.Get(ContactBusinessRelation."No.") then begin
                CRMIntegrationRecord.FindIDFromRecordID(Customer.RecordId(), AccountId);
                exit(true);
            end;
            if not Silent then
                Error(RecordNotFoundErr, Customer.TableCaption(), ContactBusinessRelation."No.");
            exit(false);
        end;
        if not Silent then
            Error(ContactsMustBeRelatedToCompanyErr, SourceRecordRef.Field(Contact.FieldNo("No.")).Value());
        exit(false);
    end;

    local procedure InitializeCRMInvoiceLineFromCRMHeader(var CRMInvoicedetail: Record "CRM Invoicedetail"; CRMInvoiceId: Guid)
    var
        CRMInvoice: Record "CRM Invoice";
    begin
        CRMInvoice.Get(CRMInvoiceId);
        CRMInvoicedetail.ActualDeliveryOn := CRMInvoice.DateDelivered;
        CRMInvoicedetail.TransactionCurrencyId := CRMInvoice.TransactionCurrencyId;
        CRMInvoicedetail.ExchangeRate := CRMInvoice.ExchangeRate;
        CRMInvoicedetail.InvoiceId := CRMInvoice.InvoiceId;
        CRMInvoicedetail.ShipTo_City := CRMInvoice.ShipTo_City;
        CRMInvoicedetail.ShipTo_Country := CRMInvoice.ShipTo_Country;
        CRMInvoicedetail.ShipTo_Line1 := CRMInvoice.ShipTo_Line1;
        CRMInvoicedetail.ShipTo_Line2 := CRMInvoice.ShipTo_Line2;
        CRMInvoicedetail.ShipTo_Line3 := CRMInvoice.ShipTo_Line3;
        CRMInvoicedetail.ShipTo_Name := CRMInvoice.ShipTo_Name;
        CRMInvoicedetail.ShipTo_PostalCode := CRMInvoice.ShipTo_PostalCode;
        CRMInvoicedetail.ShipTo_StateOrProvince := CRMInvoice.ShipTo_StateOrProvince;
        CRMInvoicedetail.ShipTo_Fax := CRMInvoice.ShipTo_Fax;
        CRMInvoicedetail.ShipTo_Telephone := CRMInvoice.ShipTo_Telephone;
    end;

    local procedure InitializeCRMInvoiceLineFromSalesInvoiceHeader(var CRMInvoicedetail: Record "CRM Invoicedetail"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        CRMInvoicedetail.TransactionCurrencyId := CRMSynchHelper.GetCRMTransactioncurrency(SalesInvoiceHeader."Currency Code");
        if SalesInvoiceHeader."Currency Factor" = 0 then
            CRMInvoicedetail.ExchangeRate := 1
        else
            CRMInvoicedetail.ExchangeRate := Round(1 / SalesInvoiceHeader."Currency Factor");
    end;

    local procedure InitializeCRMInvoiceLineFromSalesInvoiceLine(var CRMInvoicedetail: Record "CRM Invoicedetail"; SalesInvoiceLine: Record "Sales Invoice Line")
    begin
        CRMInvoicedetail.LineItemNumber := SalesInvoiceLine."Line No.";
        CRMInvoicedetail.Tax := SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount;
    end;

    local procedure InitializeCRMInvoiceLineFromSalesInvoiceHeaderAndLine(var CRMInvoicedetail: Record "CRM Invoicedetail"; SalesInvoiceHeader: Record "Sales Invoice Header"; SalesInvoiceLine: Record "Sales Invoice Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if SalesInvoiceHeader."Prices Including VAT" then
            if SalesInvoiceLine.Quantity <> 0 then
                CRMInvoicedetail.PricePerUnit := SalesInvoiceLine."Unit Price" -
                                    Round((SalesInvoiceLine."Amount Including VAT" - SalesInvoiceLine.Amount) / SalesInvoiceLine.Quantity, GeneralLedgerSetup."Unit-Amount Rounding Precision");
    end;

    local procedure InitializeCRMInvoiceLineWithProductDetails(var CRMInvoicedetail: Record "CRM Invoicedetail"; SalesInvoiceLine: Record "Sales Invoice Line")
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        CRMProduct: Record "CRM Product";
        CRMIntegrationRecord: Record "CRM Integration Record";
        ItemUnitOfMeasureRecordRef: RecordRef;
        ResourceUnitOfMeasureRecordRef: RecordRef;
        CRMProductId: Guid;
        CRMUoMId: Guid;
    begin
        CRMProductId := FindCRMProductId(SalesInvoiceLine);
        if IsNullGuid(CRMProductId) then begin
            // This will be created as a CRM write-in product
            CRMInvoicedetail.IsProductOverridden := true;
            CRMInvoicedetail.ProductDescription :=
              StrSubstNo('%1 %2.', Format(SalesInvoiceLine."No."), Format(SalesInvoiceLine.Description));
        end else begin
            // There is a coupled product or resource in CRM, transfer data from there
            CRMProduct.Get(CRMProductId);
            CRMInvoicedetail.ProductId := CRMProduct.ProductId;
            if CRMIntegrationManagement.IsUnitGroupMappingEnabled() then
                case SalesInvoiceLine.Type of
                    SalesInvoiceLine.Type::Item:
                        begin
                            if not ItemUnitOfMeasure.Get(SalesInvoiceLine."No.", SalesInvoiceLine."Unit of Measure Code") then
                                Error(ItemUnitOfMeasureDoesNotExistErr, CRMProductName.CDSServiceName(), SalesInvoiceLine."Unit of Measure Code");

                            ItemUnitOfMeasureRecordRef.GetTable(ItemUnitOfMeasure);
                            if not CRMIntegrationRecord.FindIDFromRecordRef(ItemUnitOfMeasureRecordRef, CRMUoMId) then
                                Error(NotCoupledItemUoMErr, CRMProductName.CDSServiceName(), SalesInvoiceLine."Unit of Measure Code");

                            CRMInvoicedetail.UoMId := CRMUoMId;
                        end;
                    SalesInvoiceLine.Type::Resource:
                        begin
                            if not ResourceUnitOfMeasure.Get(SalesInvoiceLine."No.", SalesInvoiceLine."Unit of Measure Code") then
                                Error(ResourceUnitOfMeasureDoesNotExistErr, CRMProductName.CDSServiceName(), SalesInvoiceLine."Unit of Measure Code");

                            ResourceUnitOfMeasureRecordRef.GetTable(ResourceUnitOfMeasure);
                            if not CRMIntegrationRecord.FindIDFromRecordRef(ResourceUnitOfMeasureRecordRef, CRMUoMId) then
                                Error(NotCoupledResourceUoMErr, CRMProductName.CDSServiceName(), SalesInvoiceLine."Unit of Measure Code");

                            CRMInvoicedetail.UoMId := CRMUoMId;
                        end;
                end
            else
                CRMInvoicedetail.UoMId := CRMProduct.DefaultUoMId;
        end;
    end;

    local procedure FindCRMProductId(SalesInvoiceLine: Record "Sales Invoice Line") CRMID: Guid
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Resource: Record Resource;
    begin
        Clear(CRMID);
        SalesReceivablesSetup.Get();
        // if this is the item that represents the Write-In product from CDS, there is no CRMID
        if SalesReceivablesSetup."Write-in Product No." = SalesInvoiceLine."No." then
            exit;
        case SalesInvoiceLine.Type of
            SalesInvoiceLine.Type::Item:
                CRMID := FindCRMProductIdForItem(SalesInvoiceLine."No.");
            SalesInvoiceLine.Type::Resource:
                begin
                    Resource.Get(SalesInvoiceLine."No.");
                    if not CRMIntegrationRecord.FindIDFromRecordID(Resource.RecordId(), CRMID) then begin
                        if not CRMSynchHelper.SynchRecordIfMappingExists(Database::Resource, Database::"CRM Product", Resource.RecordId()) then
                            Error(CannotSynchProductErr, Resource."No.");
                        if not CRMIntegrationRecord.FindIDFromRecordID(Resource.RecordId(), CRMID) then
                            Error(CannotFindSyncedProductErr);
                    end;
                end;
        end;
    end;

    local procedure FindCRMProductIdForItem(ItemNo: Code[20]) CRMID: Guid
    var
        Item: Record Item;
        FilterItem: Record Item;
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        Item.Get(ItemNo);
        if not CRMIntegrationRecord.FindIDFromRecordID(Item.RecordId(), CRMID) then
            if IntegrationTableMapping.FindMapping(Database::Item, Database::"CRM Product") then begin
                FilterItem.SetView(IntegrationTableMapping.GetTableFilter());
                FilterItem.SetRange("No.", ItemNo);
                if not FilterItem.IsEmpty() then begin
                    if not CRMSynchHelper.SynchRecordIfMappingExists(Database::Item, Database::"CRM Product", Item.RecordId()) then
                        Error(CannotSynchProductErr, Item."No.");
                    if not CRMIntegrationRecord.FindIDFromRecordID(Item.RecordId(), CRMID) then
                        Error(CannotFindSyncedProductErr);
                end;
            end;
    end;

    local procedure FindCRMProductIdForResource(ResourceNo: Code[20]) CRMID: Guid
    var
        Resource: Record Resource;
        FilterResource: Record Resource;
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        Resource.Get(ResourceNo);
        if not CRMIntegrationRecord.FindIDFromRecordID(Resource.RecordId(), CRMID) then
            if IntegrationTableMapping.FindMapping(Database::Resource, Database::"CRM Product") then begin
                FilterResource.SetView(IntegrationTableMapping.GetTableFilter());
                FilterResource.SetRange("No.", ResourceNo);
                if not FilterResource.IsEmpty() then begin
                    if not CRMSynchHelper.SynchRecordIfMappingExists(Database::Resource, Database::"CRM Product", Resource.RecordId()) then
                        Error(CannotSynchResourceErr, Resource."No.");
                    if not CRMIntegrationRecord.FindIDFromRecordID(Resource.RecordId(), CRMID) then
                        Error(CannotFindSyncedProductErr);
                end;
            end;
    end;

    local procedure FindCRMUoMIdForSalesPrice(AssetType: Enum "Price Asset Type"; AssetNo: Code[20];
                                                             UoMCode: Code[10]; var CRMUom: Record "CRM Uom")
    var
        Item: Record Item;
        Resource: Record Resource;
        UnitGroup: Record "Unit Group";
        CRMUomschedule: Record "CRM Uomschedule";
    begin
        case AssetType of
            AssetType::Item:
                begin
                    Item.Get(AssetNo);
                    if UoMCode = '' then
                        UoMCode := Item."Base Unit of Measure";
                end;
            AssetType::Resource:
                begin
                    Resource.Get(AssetNo);
                    if UoMCode = '' then
                        UoMCode := Resource."Base Unit of Measure";
                end;
            else
                if UoMCode = '' then
                    exit;
        end;

        if not CRMIntegrationManagement.IsUnitGroupMappingEnabled() then
            CRMSynchHelper.GetValidCRMUnitOfMeasureRecords(CRMUom, CRMUomschedule, UoMCode)
        else begin
            if not IsNullGuid(Item.SystemId) then
                UnitGroup.Get(UnitGroup."Source Type"::Item, Item.SystemId)
            else
                UnitGroup.Get(UnitGroup."Source Type"::Resource, Resource.SystemId);
            CRMUomschedule.SetRange(Name, UnitGroup.GetCode());
            if not CRMUomschedule.FindFirst() then
                Error(CRMUnitGroupNotFoundErr, UnitGroup.GetCode());

            CRMUom.SetRange(Name, UoMCode);
            CRMUom.SetRange(UoMScheduleId, CRMUomschedule.UoMScheduleId);
            if not CRMUom.FindFirst() then
                Error(CRMUnitNotFoundErr, UoMCode, CRMUomschedule.UoMScheduleId);
        end;
    end;

    local procedure CheckSalesPricesForSync(CustomerPriceGroupCode: Code[10]; ExpectedCurrencyCode: Code[10])
    var
        SalesPrice: Record "Sales Price";
        CRMUom: Record "CRM Uom";
    begin
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"Customer Price Group");
        SalesPrice.SetRange("Sales Code", CustomerPriceGroupCode);
        if SalesPrice.FindSet() then
            repeat
                SalesPrice.TestField("Currency Code", ExpectedCurrencyCode);
                FindCRMProductIdForItem(SalesPrice."Item No.");
                FindCRMUoMIdForSalesPrice(Enum::"Price Asset Type"::Item, SalesPrice."Item No.", SalesPrice."Unit of Measure Code", CRMUom);
            until SalesPrice.Next() = 0;
    end;

    local procedure CheckPriceListLinesForSync(PriceListCode: Code[20]; ExpectedCurrencyCode: Code[10])
    var
        PriceListLine: Record "Price List Line";
        CRMUom: Record "CRM Uom";
    begin
        PriceListLine.SetRange("Price List Code", PriceListCode);
        if PriceListLine.FindSet() then
            repeat
                PriceListLine.TestField("Currency Code", ExpectedCurrencyCode);
                case PriceListLine."Asset Type" of
                    PriceListLine."Asset Type"::Item:
                        FindCRMProductIdForItem(PriceListLine."Asset No.");
                    PriceListLine."Asset Type"::Resource:
                        FindCRMProductIdForResource(PriceListLine."Asset No.");
                end;
                FindCRMUoMIdForSalesPrice(PriceListLine."Asset Type", PriceListLine."Asset No.", PriceListLine."Unit of Measure Code", CRMUom);
            until PriceListLine.Next() = 0;
    end;

    local procedure CheckCustPriceGroupForSync(var CRMTransactioncurrency: Record "CRM Transactioncurrency"; CustomerPriceGroup: Record "Customer Price Group")
    var
        SalesPrice: Record "Sales Price";
    begin
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"Customer Price Group");
        SalesPrice.SetRange("Sales Code", CustomerPriceGroup.Code);
        if SalesPrice.FindFirst() then begin
            CRMTransactioncurrency.Get(CRMSynchHelper.GetCRMTransactioncurrency(SalesPrice."Currency Code"));
            CheckSalesPricesForSync(CustomerPriceGroup.Code, SalesPrice."Currency Code");
        end else
            CRMSynchHelper.FindNAVLocalCurrencyInCRM(CRMTransactioncurrency);
    end;

    local procedure CheckPriceListHeaderForSync(var CRMTransactioncurrency: Record "CRM Transactioncurrency"; PriceListHeader: Record "Price List Header")
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Price List Code", PriceListHeader.Code);
        if PriceListLine.FindFirst() then begin
            CRMTransactioncurrency.Get(CRMSynchHelper.GetCRMTransactioncurrency(PriceListLine."Currency Code"));
            CheckPriceListLinesForSync(PriceListHeader.Code, PriceListLine."Currency Code");
        end else
            CRMSynchHelper.FindNAVLocalCurrencyInCRM(CRMTransactioncurrency);
    end;

    local procedure CheckItemOrResourceIsNotBlocked(SourceRecordRef: RecordRef)
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        Item: Record Item;
        Resource: Record Resource;
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMInvoiceId: Guid;
    begin
        SourceRecordRef.SetTable(SalesInvHeader);

        // if invoice is coupled already, then skip this check
        if CRMIntegrationRecord.FindIDFromRecordID(SalesInvHeader.RecordId(), CRMInvoiceId) then
            exit;

        SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
        SalesInvLine.SetFilter(Type, '%1|%2', SalesInvLine.Type::Item, SalesInvLine.Type::Resource);
        if SalesInvLine.FindSet() then
            repeat
                if SalesInvLine.Type = SalesInvLine.Type::Item then begin
                    Item.Get(SalesInvLine."No.");
                    Item.TestField(Blocked, false);
                end else begin
                    Resource.Get(SalesInvLine."No.");
                    Resource.TestField(Blocked, false);
                end;
                OnCheckItemOrResourceIsNotBlockedOnAfterSalesInvLineLoop(SalesInvLine);
            until SalesInvLine.Next() = 0;
    end;

    local procedure AddSalesOrderIdToCRMSalesorderdetail(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSalesorderId: Guid;
    begin
        if not CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
            exit;
        SourceRecordRef.SetTable(SalesLine);
        DestinationRecordRef.SetTable(CRMSalesorderdetail);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");
        if not CRMIntegrationRecord.FindIDFromRecordID(SalesHeader.RecordId, CRMSalesorderId) then
            Error(SalesHeaderNotCoupledErr);
        CRMSalesorderdetail.SalesOrderId := CRMSalesorderId;
        DestinationRecordRef.GetTable(CRMSalesorderdetail);
    end;

    local procedure AddDocumentNoToSalesOrderLine(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CRMIntegrationRecord: Record "CRM Integration Record";
        SalesOrderRecordId: RecordId;
    begin
        if not CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
            exit;
        SourceRecordRef.SetTable(CRMSalesorderdetail);
        DestinationRecordRef.SetTable(SalesLine);
        if not CRMIntegrationRecord.FindRecordIDFromID(CRMSalesorderdetail.SalesOrderId, Database::"Sales Header", SalesOrderRecordId) then
            Error(SalesHeaderNotCoupledErr);
        SalesHeader.Get(SalesOrderRecordId);
        SalesLine."Document No." := SalesHeader."No.";
        DestinationRecordRef.GetTable(SalesLine);
    end;

    local procedure AddWriteInProductNo(SourceFieldRef: FieldRef; var NewValue: Variant): Boolean
    var
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SourceFieldRef.Record().SetTable(CRMSalesorderdetail);
        if IsNullGuid(CRMSalesorderdetail.ProductId) then begin
            SalesReceivablesSetup.Get();
            if SalesReceivablesSetup."Write-in Product No." = '' then
                Error(WriteInProductErr);
            SalesReceivablesSetup.Validate("Write-in Product No.");
            NewValue := SalesReceivablesSetup."Write-in Product No.";
            exit(true);
        end;
    end;

    local procedure AddWriteInSalesorderdetail(SourceFieldRef: FieldRef; var NewValue: Variant): Boolean
    var
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        EmptyGuid: Guid;
    begin
        SourceFieldRef.Record().SetTable(SalesLine);
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Write-in Product No." = SalesLine."No." then begin
            NewValue := EmptyGuid;
            exit(true);
        end;
    end;

    local procedure CreateSalesOrderNotes(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        CRMSalesorder: Record "CRM Salesorder";
        CRMAnnotation: Record "CRM Annotation";
        RecordLink: Record "Record Link";
        RecordLink2: Record "Record Link";
        CRMAnnotationCoupling: Record "CRM Annotation Coupling";
    begin
        SourceRecordRef.SetTable(CRMSalesorder);
        DestinationRecordRef.SetTable(SalesHeader);

        RecordLink.SetRange("Record ID", SalesHeader.RecordId);
        if RecordLink.FindSet() then
            repeat
                CRMAnnotationCoupling.SetRange("Record Link Record ID", RecordLink.RecordId);
                if CRMAnnotationCoupling.FindFirst() then begin
                    CRMAnnotation.SetRange(AnnotationId, CRMAnnotationCoupling."CRM Annotation ID");
                    if CRMAnnotation.IsEmpty() then begin
                        CRMAnnotationCoupling.Delete();
                        RecordLink2.GetBySystemId(RecordLink.SystemId);
                        RecordLink2.Delete();
                    end;
                end;
            until RecordLink.Next() = 0;

        CRMAnnotation.Reset();
        CRMAnnotation.SetRange(ObjectId, CRMSalesorder.SalesOrderId);
        CRMAnnotation.SetRange(IsDocument, false);
        CRMAnnotation.SetRange(FileSize, 0);
        if CRMAnnotation.FindSet() then
            repeat
                if not CRMAnnotationCoupling.FindByCRMId(CRMAnnotation.AnnotationId) then begin
                    CreateNote(SalesHeader, CRMAnnotation, RecordLink);
                    CRMAnnotationCoupling.CoupleRecordLinkToCRMAnnotation(RecordLink, CRMAnnotation);
                end;
            until CRMAnnotation.Next() = 0;
    end;

    local procedure CreateNote(SalesHeader: Record "Sales Header"; CRMAnnotation: Record "CRM Annotation"; var RecordLink: Record "Record Link")
    var
        CRMAnnotationCoupling: Record "CRM Annotation Coupling";
        RecordLinkManagement: Codeunit "Record Link Management";
        NoteInStream: InStream;
        AnnotationText: Text;
    begin
        Clear(RecordLink);
        RecordLink."Record ID" := SalesHeader.RecordId;
        RecordLink.Type := RecordLink.Type::Note;
        RecordLink.Description := CRMAnnotation.Subject;
        CRMAnnotation.CalcFields(NoteText);
        CRMAnnotation.NoteText.CreateInStream(NoteInStream, TextEncoding::UTF16);
        NoteInStream.Read(AnnotationText);
        AnnotationText := CRMAnnotationCoupling.ExtractNoteText(AnnotationText);
        RecordLinkManagement.WriteNote(RecordLink, AnnotationText);
        RecordLink.Created := CRMAnnotation.CreatedOn;
        RecordLink.Company := CopyStr(CompanyName, 1, MaxStrLen(RecordLink.Company));
        RecordLink.Insert();
    end;

    local procedure AddTypeToSalesOrderLine(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        CRMProduct: Record "CRM Product";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        if not CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
            exit;
        SourceRecordRef.SetTable(CRMSalesorderdetail);
        DestinationRecordRef.SetTable(SalesLine);

        if IsNullGuid(CRMSalesorderdetail.ProductId) then begin
            SalesReceivablesSetup.Get();
            if SalesReceivablesSetup."Write-in Product No." = '' then
                Error(WriteInProductErr);
            SalesReceivablesSetup.Validate("Write-in Product No.");
            case SalesReceivablesSetup."Write-in Product Type" of
                SalesReceivablesSetup."Write-in Product Type"::Item:
                    SalesLine.Type := SalesLine.Type::Item;
                SalesReceivablesSetup."Write-in Product Type"::Resource:
                    SalesLine.Type := SalesLine.Type::Resource;
            end;
        end else begin
            CRMProduct.Get(CRMSalesorderdetail.ProductId);
            case CRMProduct.ProductTypeCode of
                CRMProduct.ProductTypeCode::SalesInventory:
                    SalesLine.Type := SalesLine.Type::Item;
                CRMProduct.ProductTypeCode::Services:
                    SalesLine.Type := SalesLine.Type::Resource;
            end;
        end;
        DestinationRecordRef.GetTable(SalesLine);
    end;

    local procedure UpdateSalesLineUnitOfMeasure(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        CRMProduct: Record "CRM Product";
        SalesLine: Record "Sales Line";
        NAVItemUomRecordId: RecordID;
        NAVResourceUomRecordId: RecordID;
    begin
        if not CRMIntegrationManagement.IsUnitGroupMappingEnabled() then
            exit;

        SourceRecordRef.SetTable(CRMSalesorderdetail);
        DestinationRecordRef.SetTable(SalesLine);

        if IsNullGuid(CRMSalesorderdetail.ProductId) then
            exit;

        CRMProduct.Get(CRMSalesorderdetail.ProductId);
        case CRMProduct.ProductTypeCode of
            CRMProduct.ProductTypeCode::SalesInventory:
                begin
                    if not CRMIntegrationRecord.FindRecordIDFromID(CRMSalesorderdetail.UoMId, Database::"Item Unit of Measure", NAVItemUomRecordId) then
                        Error(NotCoupledCRMUomErr, CRMSalesorderdetail.UoMIdName, CRMProductName.CDSServiceName());

                    if not ItemUnitOfMeasure.Get(NAVItemUomRecordId) then
                        Error(ItemUomDoesNotExistErr, CRMSalesorderdetail.UoMIdName);

                    SalesLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
                end;
            CRMProduct.ProductTypeCode::Services:
                begin
                    if not CRMIntegrationRecord.FindRecordIDFromID(CRMSalesorderdetail.UoMId, Database::"Resource Unit of Measure", NAVResourceUomRecordId) then
                        Error(NotCoupledCRMUomErr, CRMSalesorderdetail.UoMIdName, CRMProductName.CDSServiceName());

                    if not ResourceUnitOfMeasure.Get(NAVResourceUomRecordId) then
                        Error(ResourceUomDoesNotExistErr, CRMSalesorderdetail.UoMIdName);

                    SalesLine.Validate("Unit of Measure Code", ResourceUnitOfMeasure.Code);
                end;
        end;
        DestinationRecordRef.GetTable(SalesLine);
        exit(true);
    end;

    local procedure UpdateSalesLinePriceOverride(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Boolean
    var
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesLine: Record "Sales Line";
    begin
        SourceRecordRef.SetTable(CRMSalesorderdetail);
        DestinationRecordRef.SetTable(SalesLine);

        if SalesLine."Unit Price" <> CRMSalesorderdetail.PricePerUnit then
            SalesLine.Validate("Unit Price", CRMSalesorderdetail.PricePerUnit);

        DestinationRecordRef.GetTable(SalesLine);
    end;

    local procedure UpdateCRMSalesorderdetailUom(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Boolean
    var
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesLine: Record "Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMUom: Record "CRM Uom";
        CRMUomscheduleId: Guid;
        CRMUomId: Guid;
    begin
        SourceRecordRef.SetTable(SalesLine);
        DestinationRecordRef.SetTable(CRMSalesorderdetail);

        if IsNullGuid(CRMSalesorderdetail.ProductId) then
            exit;

        if not CRMIntegrationManagement.IsUnitGroupMappingEnabled() then begin
            UnitOfMeasure.Get(SalesLine."Unit of Measure Code");
            if not CRMIntegrationRecord.FindIDFromRecordID(UnitOfMeasure.RecordId, CRMUomscheduleId) then
                Error(UnitOfMeasureNotCoupledErr, UnitOfMeasure.Code);

            CRMUom.SetRange(UoMScheduleId, CRMUomscheduleId);
            CRMUom.SetRange(Name, UnitOfMeasure.Code);
            if CRMUom.FindFirst() then
                CRMSalesorderdetail.UoMId := CRMUom.UoMId;
        end else
            case SalesLine.Type of
                SalesLine.Type::Item:
                    begin
                        ItemUnitOfMeasure.Get(SalesLine."No.", SalesLine."Unit of Measure Code");
                        if not CRMIntegrationRecord.FindIDFromRecordID(ItemUnitOfMeasure.RecordId, CRMUomId) then
                            Error(ItemUnitOfMeasureNotCoupledErr, ItemUnitOfMeasure.Code);
                        CRMSalesorderdetail.UoMId := CRMUomId;
                    end;
                SalesLine.Type::Resource:
                    begin
                        ResourceUnitOfMeasure.Get(SalesLine."No.", SalesLine."Unit of Measure Code");
                        if not CRMIntegrationRecord.FindIDFromRecordID(ResourceUnitOfMeasure.RecordId, CRMUomId) then
                            Error(ResourceUnitOfMeasureNotCoupledErr, ResourceUnitOfMeasure.Code);
                        CRMSalesorderdetail.UoMId := CRMUomId;
                    end;
            end;
        DestinationRecordRef.GetTable(CRMSalesorderdetail);
    end;

    local procedure UpdateCRMSalesOrderPriceList(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
        CRMPricelevel: Record "CRM Pricelevel";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        SourceRecordRef.SetTable(SalesHeader);
        DestinationRecordRef.SetTable(CRMSalesorder);

        if not PriceCalculationMgt.IsExtendedPriceCalculationEnabled() then begin
            if IsNullGuid(CRMSalesorder.PriceLevelId) then begin
                if not CRMSynchHelper.FindCRMPriceListByCurrencyCode(CRMPricelevel, SalesHeader."Currency Code") then
                    CRMSynchHelper.CreateCRMPricelevelInCurrency(CRMPricelevel, SalesHeader."Currency Code", SalesHeader."Currency Factor");
                CRMSalesorder.PriceLevelId := CRMPricelevel.PriceLevelId;
                DestinationRecordRef.GetTable(CRMSalesorder);
            end;
            CRMSynchHelper.UpdateCRMPriceList(SalesHeader, CRMSalesorder.PriceLevelId);
        end else
            if IsNullGuid(CRMSalesorder.PriceLevelId) then begin
                CRMPricelevel.SetRange(Name, StrSubstNo(OrderPriceListLbl, SalesHeader."No."));
                if not CRMPricelevel.FindFirst() then
                    CRMSynchHelper.CreateCRMPriceList(SalesHeader, CRMPricelevel)
                else
                    CRMSynchHelper.UpdateCRMPriceList(SalesHeader, CRMPricelevel.PriceLevelId);
                CRMSalesorder.PriceLevelId := CRMPricelevel.PriceLevelId;
                DestinationRecordRef.GetTable(CRMSalesorder);
            end else
                CRMSynchHelper.UpdateCRMPriceList(SalesHeader, CRMSalesorder.PriceLevelId);
    end;

    local procedure SetCRMOrderName(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
    begin
        SourceRecordRef.SetTable(SalesHeader);
        DestinationRecordRef.SetTable(CRMSalesorder);

        CRMSalesorder.Name := SalesHeader."Sell-to Customer Name";
        DestinationRecordRef.GetTable(CRMSalesorder);
    end;

    local procedure SetDocOccurenceNumber(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
    begin
        SourceRecordRef.SetTable(SalesHeader);
        DestinationRecordRef.SetTable(CRMSalesorder);

        SetDocOccurenceNumber(CRMSalesorder, SalesHeader);

        DestinationRecordRef.GetTable(CRMSalesorder);
    end;

    procedure SetDocOccurenceNumber(var CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header")
    var
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        SalesHeaderArchive.SetRange("Document Type", SalesHeaderArchive."Document Type"::Order);
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.SetCurrentKey("Doc. No. Occurrence");
        SalesHeaderArchive.SetAscending("Doc. No. Occurrence", true);
        if SalesHeaderArchive.FindLast() then
            if SalesHeaderArchive."Document Date" = SalesHeader."Document Date" then
                CRMSalesorder.BusinessCentralDocumentOccurrenceNumber := SalesHeaderArchive."Doc. No. Occurrence"
            else
                CRMSalesorder.BusinessCentralDocumentOccurrenceNumber := SalesHeaderArchive."Doc. No. Occurrence" + 1
        else
            CRMSalesorder.BusinessCentralDocumentOccurrenceNumber := 1;
    end;

    local procedure SetOrderNumberAndDocOccurenceNumber(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CRMSalesorder: Record "CRM Salesorder";
        ChangedCRMSalesorder: Record "CRM Salesorder";
        SalesHeader: Record "Sales Header";
    begin
        SourceRecordRef.SetTable(CRMSalesorder);
        DestinationRecordRef.SetTable(SalesHeader);

        ChangedCRMSalesorder.Get(CRMSalesorder.SalesOrderId);
        SetDocOccurenceNumber(ChangedCRMSalesorder, SalesHeader);
        ChangedCRMSalesorder.BusinessCentralOrderNumber := SalesHeader."No.";
        ChangedCRMSalesorder.Modify();
    end;

    local procedure SetWriteInProduct(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SourceRecordRef.SetTable(SalesLine);
        DestinationRecordRef.SetTable(CRMSalesorderdetail);

        if IsNullGuid(CRMSalesorderdetail.ProductId) then begin
            SalesReceivablesSetup.Get();
            CRMSalesorderdetail.IsProductOverridden := true;
            CRMSalesorderdetail.ProductDescription := SalesLine.Description;
        end;

        DestinationRecordRef.GetTable(CRMSalesorderdetail);
    end;

    local procedure UpdateSalesOrderQuoteNo(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMQuote: Record "CRM Quote";
        SalesHeader: Record "Sales Header";
        QuoteSalesHeader: Record "Sales Header";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        SourceRecordRef.SetTable(CRMSalesorder);
        DestinationRecordRef.SetTable(SalesHeader);

        if not IsNullGuid(CRMSalesorder.QuoteId) then
            if CRMQuote.Get(CRMSalesOrder.QuoteId) then begin
                QuoteSalesHeader.SetRange("Your Reference", CRMQuote.QuoteNumber);

                OnBeforeFindQuoteSalesHeader(QuoteSalesHeader);
                if QuoteSalesHeader.FindLast() then begin
                    SalesHeader."Quote No." := QuoteSalesHeader."No.";
                    ArchiveManagement.ArchSalesDocumentNoConfirm(QuoteSalesHeader);
                    OnAfterArchSalesDocumentNoConfirm(QuoteSalesHeader);
                end;
            end;
        DestinationRecordRef.GetTable(SalesHeader);
    end;

    local procedure FindNewValueForCoupledRecordPK(IntegrationTableMapping: Record "Integration Table Mapping"; SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant) IsValueFound: Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecID: RecordID;
        CRMID: Guid;
    begin
        OnFindNewValueForCoupledRecordPK(IntegrationTableMapping, SourceFieldRef, DestinationFieldRef, NewValue, IsValueFound);
        if IsValueFound then
            exit(true);
        if CRMSynchHelper.FindNewValueForSpecialMapping(SourceFieldRef, NewValue) then
            exit(true);
        case IntegrationTableMapping.Direction of
            IntegrationTableMapping.Direction::ToIntegrationTable:
                if Format(SourceFieldRef.Value()) = '' then begin
                    NewValue := CRMID; // Blank GUID
                    IsValueFound := true;
                end else begin
                    if CRMSynchHelper.FindRecordIDByPK(IntegrationTableMapping."Table ID", SourceFieldRef.Value(), RecID) then
                        if CRMIntegrationRecord.FindIDFromRecordID(RecID, NewValue) then
                            exit(true);
                    if CRMSynchHelper.IsClearValueOnFailedSync(SourceFieldRef, DestinationFieldRef) then begin
                        NewValue := CRMID;
                        exit(true);
                    end;
                    Error(RecordMustBeCoupledErr, SourceFieldRef.Caption(), SourceFieldRef.Value(), CRMProductName.CDSServiceName());
                end;
            IntegrationTableMapping.Direction::FromIntegrationTable:
                begin
                    CRMID := SourceFieldRef.Value();
                    if IsNullGuid(CRMID) then begin
                        NewValue := '';
                        IsValueFound := true;
                    end else begin
                        if CRMIntegrationRecord.FindRecordIDFromID(CRMID, IntegrationTableMapping."Table ID", RecID) then
                            if CRMSynchHelper.FindPKByRecordID(RecID, NewValue) then
                                exit(true);
                        if CRMSynchHelper.IsClearValueOnFailedSync(DestinationFieldRef, SourceFieldRef) then begin
                            NewValue := '';
                            exit(true);
                        end;
                        Error(RecordMustBeCoupledErr, SourceFieldRef.Caption(), CRMID, PRODUCTNAME.Short());
                    end;
                end;
        end;
    end;

    local procedure AutoReserveSalesLine(var DestinationRecordRef: RecordRef)
    var
        SalesLine: Record "Sales Line";
    begin
        DestinationRecordRef.SetTable(SalesLine);
        if (SalesLine.Type = SalesLine.Type::Item) and (SalesLine.Reserve = SalesLine.Reserve::Always) then
            SalesLine.AutoReserve();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnIsCRMIntegrationRecord', '', false, false)]
    local procedure HandleOnIsCRMIntegrationRecord(TableID: Integer; var isIntegrationRecord: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if TableID = Database::"Sales Header Archive" then
            if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
                isIntegrationRecord := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnIsIntegrationRecordChild', '', false, false)]
    local procedure HandleOnIsIntegrationRecordChild(TableId: Integer; var Handled: Boolean; var ReturnValue: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not CRMConnectionSetup.IsEnabled() then
            exit;

        if TableId = Database::"Sales Line" then
            if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then begin
                Handled := true;
                ReturnValue := false;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Int. Table Couple", 'OnBeforeSetMatchingFilter', '', false, false)]
    local procedure HandleOnBeforeSetMatchingFilter(var IntegrationRecordRef: RecordRef; var MatchingIntegrationRecordFieldRef: FieldRef; var LocalRecordRef: RecordRef; var MatchingLocalFieldRef: FieldRef; var SetMatchingFilterHandled: Boolean)
    var
        UnitGroup: Record "Unit Group";
        Item: Record Item;
        Resource: Record Resource;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        CRMUomschedule: Record "CRM Uomschedule";
        CRMUom: Record "CRM Uom";
        AdditionalFieldRef: FieldRef;
    begin
        if (IntegrationRecordRef.Number = Database::"CRM Uomschedule") and (LocalRecordRef.Number = Database::"Unit Group") then
            if (MatchingIntegrationRecordFieldRef.Number = CRMUomschedule.FieldNo(Name)) and (MatchingLocalFieldRef.Number = UnitGroup.FieldNo("Source No.")) then begin
                LocalRecordRef.SetTable(UnitGroup);
                MatchingIntegrationRecordFieldRef.SetRange(UnitGroup.GetCode());
                SetMatchingFilterHandled := true;
            end;

        if (IntegrationRecordRef.Number = Database::"CRM Uom") and ((LocalRecordRef.Number = Database::"Item Unit of Measure") or (LocalRecordRef.Number = Database::"Resource Unit of Measure")) then
            if (MatchingIntegrationRecordFieldRef.Number = CRMUom.FieldNo(Name)) and ((MatchingLocalFieldRef.Number = ItemUnitOfMeasure.FieldNo("Code")) or (MatchingLocalFieldRef.Number = ResourceUnitOfMeasure.FieldNo("Code"))) then begin
                if LocalRecordRef.Number = Database::"Item Unit of Measure" then begin
                    LocalRecordRef.SetTable(ItemUnitOfMeasure);
                    if Item.Get(ItemUnitOfMeasure."Item No.") then
                        UnitGroup.Get(UnitGroup."Source Type"::Item, Item.SystemId);
                end;

                if LocalRecordRef.Number = Database::"Resource Unit of Measure" then begin
                    LocalRecordRef.SetTable(ResourceUnitOfMeasure);
                    if Resource.Get(ResourceUnitOfMeasure."Resource No.") then
                        UnitGroup.Get(UnitGroup."Source Type"::Resource, Resource.SystemId);
                end;

                CRMUomschedule.SetRange(Name, UnitGroup.GetCode());
                if CRMUomschedule.FindFirst() then begin
                    AdditionalFieldRef := IntegrationRecordRef.Field(CRMUom.FieldNo(UoMScheduleId));
                    AdditionalFieldRef.SetRange(CRMUomschedule.UoMScheduleId);
                end;
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCRMInvoiceBeforeInsertRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemOrResourceIsNotBlockedOnAfterSalesInvLineLoop(SalesInvLine: Record "Sales Invoice Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindNewValueForCoupledRecordPK(IntegrationTableMapping: Record "Integration Table Mapping"; SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant; var IsValueFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCRMProductAfterTransferRecordFieldsOnAfterCalcItemBlocked(SourceRecordRef: RecordRef; var Blocked: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceDestCodeOnAfterTransferRecordFields(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var AdditionalFieldsWereModified: Boolean; DestinationIsInserted: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleOnBeforeIgnoreUnchangedRecordHandled(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeSalesOrderStatusOnBeforeCompareStatus(var SalesHeader: Record "Sales Header"; var NewSalesDocumentStatus: Enum "Sales Document Status")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCRMInvoiceBeforeInsertRecordOnBeforeDestinationRecordRefGetTable(var CRMInvoice: Record "CRM Invoice"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplySalesLineTaxOnBeforeSetTax(var CRMSalesorderdetail: Record "CRM Salesorderdetail"; var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterArchSalesDocumentNoConfirm(var QuoteSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindQuoteSalesHeader(var QuoteSalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandlePostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    begin
    end;
}


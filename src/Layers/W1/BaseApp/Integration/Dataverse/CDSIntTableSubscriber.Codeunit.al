// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System;
using System.Environment;
using System.Environment.Configuration;
using System.IO;
using System.Telemetry;

codeunit 7205 "CDS Int. Table. Subscriber"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        UserCDSSetupTxt: Label 'Dataverse User Setup';
        CannotResolveUserFromConnectionSetupErr: Label 'The integration user that is specified in the Dataverse connection setup does not exist.';
        RecordMustBeCoupledErr: Label '%1 %2 must be coupled to a Dataverse row.', Comment = '%1 = table caption, %2 = primary key value';
        RecordMustBeCoupledExtErr: Label '%1 %2 must be coupled to a %3 row.', Comment = '%1 = BC table caption, %2 = primary key value, %3 - Dataverse table caption';
        RecordNotFoundErr: Label 'Cannot find %1 in table %2.', Comment = '%1 = The lookup value when searching for the source record, %2 = Source table caption';
        ContactMustBeRelatedToCustomerOrVendorErr: Label 'The contact %1 must have a contact company that has a business relation to a customer or vendor.', Comment = '%1 = Contact No.';
        NewCodePatternTxt: Label 'SP NO. %1', Locked = true;
        SalespersonPurchaserCodeFilterLbl: Label 'SP NO. 0*', Locked = true;
        CouplingsNeedToBeResetQst: Label 'Dataverse integration is enabled, and records have been coupled for this company. Before you delete this company, you should delete its couplings so that other companies can access the coupled records. You can delete the couplings on the %1 page. Do you want to proceed without deleting the couplings?', Comment = '%1 = page caption of Integration Table Mappings';
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        UpdateContactParentCompanyTxt: Label 'Updating contact parent company.', Locked = true;
        UpdateContactParentCompanyFailedTxt: Label 'Updating contact parent company failed. Parent Customer ID: %1', Locked = true, Comment = '%1 - parent customer id';
        UpdateContactParentCompanySuccessfulTxt: Label 'Contact parent company has successfully been updated.', Locked = true;
        UpdateContactParentCompanyAlreadySetTxt: Label 'Contact parent company has already been set correctly.', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnInitCDSConnection', '', true, true)]
    local procedure HandleOnInitCDSConnection(var ConnectionName: Text; var handled: Boolean)
    begin
        if handled then
            exit;

        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        if not CDSIntegrationImpl.RegisterConnection() then
            exit;

        if CDSIntegrationImpl.ActivateConnection() then begin
            handled := true;
            ConnectionName := CDSIntegrationImpl.GetConnectionDefaultName();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnCloseCDSConnection', '', true, true)]
    local procedure HandleOnCloseCDSConnection(ConnectionName: Text; var handled: Boolean)
    begin
        if handled then
            exit;

        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        if CDSIntegrationImpl.UnregisterConnection(ConnectionName) then
            handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnTestCDSConnection', '', true, true)]
    local procedure HandleOnTestCDSConnection(var handled: Boolean)
    begin
        if handled then
            exit;

        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        handled := true;
        CDSIntegrationImpl.TestSystemUsersAvailability();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnGetCDSIntegrationUserId', '', true, true)]
    local procedure HandleOnGetCDSIntegrationUserId(var IntegrationUserId: Guid; var handled: Boolean)
    begin
        if handled then
            exit;

        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        IntegrationUserId := FindIntegrationUserId();

        handled := true;
        if IsNullGuid(IntegrationUserId) then
            ShowError(UserCDSSetupTxt, CannotResolveUserFromConnectionSetupErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnGetCDSServerAddress', '', true, true)]
    local procedure HandleOnGetCDSServerAddress(var CDSServerAddress: Text; var handled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if handled then
            exit;

        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        CDSConnectionSetup.Get();
        CDSServerAddress := CDSConnectionSetup."Server Address";
        handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterInsertRecord', '', false, false)]
    local procedure HandleOnAfterInsertRecord(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        Customer: Record Customer;
    begin
        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'CRM Account-Customer',
            'CRM Account-Vendor':
                begin
                    SetCompanyIdOnCRMAccount(SourceRecordRef);
                    UpdateChildContactsParentCompany(SourceRecordRef);
                end;
            'CRM Contact-Contact':
                begin
                    FixPrimaryContactNo(SourceRecordRef, DestinationRecordRef);
                    SetCompanyIdOnCRMContact(SourceRecordRef);
                end;
            'Contact-CRM Contact':
                FixPrimaryContactIdInCDS(SourceRecordRef, DestinationRecordRef);
            'CRM Systemuser-Salesperson/Purchaser':
                AddCoupledUserToDefaultOwningTeam(SourceRecordRef);
            'Customer-CRM Account':
                begin
                    SourceRecordRef.SetTable(Customer);
                    IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
                    IntegrationTableMapping.SetRange("Delete After Synchronization", false);
                    IntegrationTableMapping.SetRange("Table ID", Database::Contact);
                    IntegrationTableMapping.SetRange("Integration Table ID", Database::"CRM Contact");
                    if IntegrationTableMapping.FindFirst() then
                        if IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." > Customer.SystemCreatedAt then begin
                            IntegrationTableMapping."Synch. Int. Tbl. Mod. On Fltr." := Customer.SystemCreatedAt;
                            IntegrationTableMapping.Modify();
                        end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Salesperson/Purchaser", 'OnAfterDeleteEvent', '', false, false)]
    local procedure DeleteCouplingOnAfterDeleteSalesperson(var Rec: Record "Salesperson/Purchaser"; RunTrigger: Boolean)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if Rec.IsTemporary() then
            exit;

        CRMIntegrationRecord.SetCurrentKey("Integration ID");
        CRMIntegrationRecord.SetRange("Integration ID", Rec.SystemId);
        if CRMIntegrationRecord.FindFirst() then
            CRMIntegrationRecord.Delete();
    end;

    [TryFunction]
    local procedure AddCoupledUserToDefaultOwningTeam(SourceRecordRef: RecordRef)
    var
        CRMSystemuser: Record "CRM Systemuser";
        CDSConnectionSetup: Record "CDS Connection Setup";
        CrmHelper: DotNet CrmHelper;
        AdminUser: Text;
        AdminPassword: SecretText;
        AccessToken: SecretText;
        AdminADDomain: Text;
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        if not CDSConnectionSetup.Get() then
            exit;
        if CDSConnectionSetup."Authentication Type" <> CDSConnectionSetup."Authentication Type"::Office365 then
            exit;

        SourceRecordRef.SetTable(CRMSystemuser);
        if CRMSystemuser.IsEmpty() then
            exit;

        if CDSIntegrationImpl.SignInCDSAdminUser(CDSConnectionSetup, CrmHelper, AdminUser, AdminPassword, AccessToken, AdminADDomain, true) then
            if not AccessToken.IsEmpty() then
                CDSIntegrationImpl.AddUsersToDefaultOwningTeam(CDSConnectionSetup, CrmHelper, CRMSystemuser);
    end;

    local procedure SetCompanyIdOnCRMContact(var SourceRecordRef: RecordRef)
    var
        CRMContact: Record "CRM Contact";
        RecRef: RecordRef;
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        // if the CDS entity already has a correct company id, do nothing
        if CDSIntegrationImpl.CheckCompanyIdNoTelemetry(SourceRecordRef) then
            exit;

        SourceRecordRef.SetTable(CRMContact);
        // it is required to calculate these fields, otherwise CDS fails to modify the entity
        if (CRMContact.CreatedByName = '') or (CRMContact.ModifiedByName = '') or (CRMContact.TransactionCurrencyIdName = '') then begin
            CRMContact.SetAutoCalcFields(CreatedByName, ModifiedByName, TransactionCurrencyIdName);
            CRMContact.Find();
        end;
        RecRef.GetTable(CRMContact);
        SetCompanyId(RecRef);
        RecRef.Modify();
        CRMContact.Find();
        SourceRecordRef.GetTable(CRMContact);
    end;

    local procedure SetCompanyIdOnCRMAccount(var SourceRecordRef: RecordRef)
    var
        CRMAccount: Record "CRM Account";
        RecRef: RecordRef;
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        // if the CDS entity already has a correct company id, do nothing
        if CDSIntegrationImpl.CheckCompanyIdNoTelemetry(SourceRecordRef) then
            exit;

        SourceRecordRef.SetTable(CRMAccount);
        // it is required to calculate these fields, otherwise CDS fails to modify the entity
        if (CRMAccount.CreatedByName = '') or (CRMAccount.ModifiedByName = '') or (CRMAccount.TransactionCurrencyIdName = '') then begin
            CRMAccount.SetAutoCalcFields(CreatedByName, ModifiedByName, TransactionCurrencyIdName);
            CRMAccount.Find();
        end;
        RecRef.GetTable(CRMAccount);
        SetCompanyId(RecRef);
        RecRef.Modify();
        CRMAccount.Find();
        SourceRecordRef.GetTable(CRMAccount);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Record Synch.", 'OnTransferFieldData', '', false, false)]
    local procedure OnTransferFieldData(SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant; var IsValueFound: Boolean; var NeedsConversion: Boolean)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CDSConnectionSetup: Record "CDS Connection Setup";
        Item: Record Item;
        Resource: Record Resource;
        Contact: Record Contact;
        PriceListLine: Record "Price List Line";
        CRMProduct: Record "CRM Product";
        SalesLine: Record "Sales Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CRMTransactionCurrency: Record "CRM Transactioncurrency";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        DestinationRecRef: RecordRef;
        TransactionCurrencyId: Guid;
        OriginalDestinationFieldValue: Variant;
        IsClearValueOnFailedSync: Boolean;
        OptionValue: Integer;
        EmptyGuid: Guid;
        TableValue: Text;
        SourceValue: Text;
        CoupledSalespersonPurchaserCode: Code[20];
        ContactNo: Code[20];
    begin
        if IsValueFound then
            exit;

        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        if SourceFieldRef.Number() = DestinationFieldRef.Number() then
            if SourceFieldRef.Record().Number() = DestinationFieldRef.Record().Number() then
                exit;

        if DestinationFieldRef.Name() = 'OwnerId' then begin
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

        if SourceFieldRef.Name() = 'OwnerId' then begin
            CDSConnectionSetup.Get();
            case CDSConnectionSetup."Ownership Model" of
                CDSConnectionSetup."Ownership Model"::Team:
                    begin
                        // in case of field mapping to OwnerId, if ownership model is Team, we don't change the value of Salesperson code
                        NewValue := DestinationFieldRef.Value();
                        IsValueFound := true;
                        NeedsConversion := false;
                        exit;
                    end;
                CDSConnectionSetup."Ownership Model"::Person:
                    begin
                        // in case of field mapping to OwnerId, if ownership model is Person, we should find the SalesPerson/Purchaser mapped to the user
                        CoupledSalespersonPurchaserCode := GetCoupledSalespersonPurchaserCode(SourceFieldRef.Record());
                        if CoupledSalespersonPurchaserCode <> '' then
                            NewValue := CoupledSalespersonPurchaserCode
                        else
                            NewValue := DestinationFieldRef.Value();
                        IsValueFound := true;
                        NeedsConversion := false;
                        exit;
                    end;
            end;
        end;

        OriginalDestinationFieldValue := DestinationFieldRef.Value();
        if DestinationFieldRef.Name() = 'Primary Contact No.' then begin
            SourceValue := Format(SourceFieldRef.Value());
            if (SourceValue = '') or (SourceValue = Format(EmptyGuid)) then begin
                // in case of bringing in a blank value for a field that is marked as "Clear Value on Failed Sync", keep the Destination value
                // except if the original contact is coupled. in this case, we know that the Primary Contact No. was updated, so this change (blanking it) is valid
                ContactNo := OriginalDestinationFieldValue;
                if Contact.Get(ContactNo) then
                    if not CRMIntegrationRecord.FindByRecordID(Contact.RecordId) then begin
                        NewValue := OriginalDestinationFieldValue;
                        IsValueFound := true;
                        NeedsConversion := false;
                        exit;
                    end;
            end;
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

        if CRMSynchHelper.ConvertTableToOption(SourceFieldRef, DestinationFieldRef, OptionValue) then begin
            NewValue := OptionValue;
            IsValueFound := true;
            NeedsConversion := true;
        end else
            if CRMSynchHelper.ConvertOptionToTable(SourceFieldRef, DestinationFieldRef, TableValue) then begin
                NewValue := TableValue;
                IsValueFound := true;
                NeedsConversion := false;
            end else
                if CRMSynchHelper.AreFieldsRelatedToMappedTables(SourceFieldRef, DestinationFieldRef, IntegrationTableMapping) then begin
                    IsValueFound := FindNewValueForCoupledRecordPK(IntegrationTableMapping, SourceFieldRef, DestinationFieldRef, NewValue);
                    if IsValueFound then begin
                        if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::ToIntegrationTable then
                            IsClearValueOnFailedSync := CRMSynchHelper.IsClearValueOnFailedSync(SourceFieldRef, DestinationFieldRef)
                        else
                            if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::FromIntegrationTable then
                                IsClearValueOnFailedSync := CRMSynchHelper.IsClearValueOnFailedSync(DestinationFieldRef, SourceFieldRef);

                        if IsClearValueOnFailedSync then begin
                            DestinationRecRef := DestinationFieldRef.Record();
                            DestinationFieldRef.SetRange(OriginalDestinationFieldValue);
                            if DestinationRecRef.IsEmpty() then
                                NewValue := OriginalDestinationFieldValue;
                        end;
                    end;
                    NeedsConversion := false;
                end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnBeforeInsertRecord', '', false, false)]
    local procedure HandleOnBeforeInsertRecord(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
        ConfigTemplateCode: Code[10];
        SourceDestCode: Text;
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        SourceDestCode := GetSourceDestCode(SourceRecordRef, DestinationRecordRef);

        if SourceDestCode = 'Contact-CRM Contact' then
            UpdateCRMContactParentCustomerId(SourceRecordRef, DestinationRecordRef);

        if SourceRecordRef.Number in [Database::"CRM Account", Database::"CRM Product"] then begin
            IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
            IntegrationTableMapping.SetRange("Table ID", DestinationRecordRef.Number);
            IntegrationTableMapping.SetRange("Integration Table ID", SourceRecordRef.Number);
            if IntegrationTableMapping.FindFirst() then
                ConfigTemplateCode := IntegrationRecSynchInvoke.FindTableConfigTemplate(IntegrationTableMapping, SourceRecordRef);
        end;

        case SourceDestCode of
            'Customer-CRM Account',
            'Contact-CRM Contact',
            'Vendor-CRM Account':
                begin
                    SetCompanyId(DestinationRecordRef);
                    SetOwnerId(SourceRecordRef, DestinationRecordRef);
                end;
            'Currency-CRM Transactioncurrency':
                SetDefaultSymbolOnCRMTransactioncurrencyIfEmpty(DestinationRecordRef);
            'CRM Account-Customer':
                if ConfigTemplateCode <> '' then
                    if ConfigTemplateHeader.Get(ConfigTemplateCode) then
                        CustomerTemplMgt.FillCustomerKeyFromInitSeries(DestinationRecordRef, ConfigTemplateHeader);
            'CRM Account-Vendor':
                if ConfigTemplateCode <> '' then
                    if ConfigTemplateHeader.Get(ConfigTemplateCode) then
                        VendorTemplMgt.FillVendorKeyFromInitSeries(DestinationRecordRef, ConfigTemplateHeader);
            'CRM Product-Item':
                if ConfigTemplateCode <> '' then
                    if ConfigTemplateHeader.Get(ConfigTemplateCode) then
                        ItemTemplMgt.FillItemKeyFromInitSeries(DestinationRecordRef, ConfigTemplateHeader);
        end;

        if DestinationRecordRef.Number() = DATABASE::"Salesperson/Purchaser" then
            UpdateSalesPersOnBeforeInsertRecord(DestinationRecordRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnBeforeModifyRecord', '', false, false)]
    local procedure HandleOnBeforeModifyRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        SourceDestCode: Text;
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        SourceDestCode := GetSourceDestCode(SourceRecordRef, DestinationRecordRef);

        if SourceDestCode = 'Contact-CRM Contact' then
            UpdateCRMContactParentCustomerId(SourceRecordRef, DestinationRecordRef);

        case SourceDestCode of
            'Customer-CRM Account',
            'Contact-CRM Contact',
            'Vendor-CRM Account':
                SetCompanyId(DestinationRecordRef);
            'Currency-CRM Transactioncurrency':
                SetDefaultSymbolOnCRMTransactioncurrencyIfEmpty(DestinationRecordRef);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterModifyRecord', '', false, false)]
    local procedure HandleOnAfterModifyRecord(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        if DestinationRecordRef.Number() = Database::Vendor then
            CRMSynchHelper.UpdateContactOnModifyVendor(DestinationRecordRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Int. Option Synch. Invoke", 'OnAfterModifyOption', '', false, false)]
    local procedure HandleOnAfterModifyOption(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        RecRef: RecordRef;
        OptionLabel: Text;
        DocumentType: Option "Order","Quote","Invoice";
    begin
        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit;

        if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::FromIntegrationTable then begin
            RecRef := SourceRecordRef;
            if CRMOptionMapping.IsCRMRecordRefMapped(SourceRecordRef, CRMOptionMapping) then
                OptionLabel := CRMOptionMapping.GetRecordRefOptionValue(SourceRecordRef);
        end else begin
            RecRef := DestinationRecordRef;
            CRMOptionMapping.SetRange("Record ID", SourceRecordRef.RecordId);
            if CRMOptionMapping.FindFirst() then
                OptionLabel := CRMOptionMapping.GetRecordRefOptionValue(DestinationRecordRef);
        end;

        if OptionLabel <> '' then begin
            UpdateOrInsertDocumentOptionSet(CRMOptionMapping, RecRef, DocumentType::Order, OptionLabel);
            UpdateOrInsertDocumentOptionSet(CRMOptionMapping, RecRef, DocumentType::Quote, OptionLabel);
            UpdateOrInsertDocumentOptionSet(CRMOptionMapping, RecRef, DocumentType::Invoice, OptionLabel);
        end;
    end;

    local procedure UpdateOrInsertDocumentOptionSet(CRMOptionMapping: Record "CRM Option Mapping"; RecRef: RecordRef; DocumentType: Option "Order","Quote","Invoice"; OptionLabel: Text);
    var
        EntityName: Text;
        FieldName: Text;
        OptionSetMetadataDictionary: Dictionary of [Integer, Text];
    begin
        CRMOptionMapping.GetDocumentMetadataInfo(RecRef, DocumentType, EntityName, FieldName);
        if (EntityName <> '') and (FieldName <> '') then begin
            OptionSetMetadataDictionary := CDSIntegrationMgt.GetOptionSetMetadata(EntityName, FieldName);
            if not OptionSetMetadataDictionary.ContainsKey(CRMOptionMapping."Option Value") then
                CDSIntegrationMgt.InsertOptionSetMetadataWithOptionValue(EntityName, FieldName, OptionLabel, CRMOptionMapping."Option Value")
            else
                if OptionSetMetadataDictionary.Get(CRMOptionMapping."Option Value") <> OptionLabel then
                    CDSIntegrationMgt.UpdateOptionSetMetadata(EntityName, FieldName, CRMOptionMapping."Option Value", OptionLabel);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Int. Option Synch. Invoke", 'OnAfterInsertOption', '', false, false)]
    local procedure HandleOnAfterInsertOption(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        RecRef: RecordRef;
        OptionLabel: Text;
        DocumentType: Option "Order","Quote","Invoice";
    begin
        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit;

        if IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::FromIntegrationTable then begin
            RecRef := SourceRecordRef;
            if CRMOptionMapping.IsCRMRecordRefMapped(SourceRecordRef, CRMOptionMapping) then
                OptionLabel := CRMOptionMapping.GetRecordRefOptionValue(SourceRecordRef);
        end else begin
            RecRef := DestinationRecordRef;
            CRMOptionMapping.SetRange("Record ID", SourceRecordRef.RecordId);
            if CRMOptionMapping.FindFirst() then
                OptionLabel := CRMOptionMapping.GetRecordRefOptionValue(DestinationRecordRef);
        end;

        if OptionLabel <> '' then begin
            UpdateOrInsertDocumentOptionSet(CRMOptionMapping, RecRef, DocumentType::Order, OptionLabel);
            UpdateOrInsertDocumentOptionSet(CRMOptionMapping, RecRef, DocumentType::Quote, OptionLabel);
            UpdateOrInsertDocumentOptionSet(CRMOptionMapping, RecRef, DocumentType::Invoice, OptionLabel);
        end;
    end;

    procedure SyncDocumentOptionSets()
    var
        CRMOptionMapping: Record "CRM Option Mapping";
        OrderPaymentTermsOptionSetMetadataDictionary: Dictionary of [Integer, Text];
        OrderFreightTermsOptionSetMetadataDictionary: Dictionary of [Integer, Text];
        OrderShippingMethodOptionSetMetadataDictionary: Dictionary of [Integer, Text];
        QuotePaymentTermsOptionSetMetadataDictionary: Dictionary of [Integer, Text];
        QuoteFreightTermsOptionSetMetadataDictionary: Dictionary of [Integer, Text];
        QuoteShippingMethodOptionSetMetadataDictionary: Dictionary of [Integer, Text];
        InvoicePaymentTermsOptionSetMetadataDictionary: Dictionary of [Integer, Text];
        InvoiceShippingMethodOptionSetMetadataDictionary: Dictionary of [Integer, Text];
        OptionLabel: Text;
        OrderEntityName: Text;
        QuoteEntityName: Text;
        InvoiceEntityName: Text;
        PaymentTermsFieldName: Text;
        FreightTermsFieldName: Text;
        ShippingMethodFieldName: Text;
    begin
        if CRMOptionMapping.FindSet() then begin
            OrderEntityName := 'salesorder';
            QuoteEntityName := 'quote';
            InvoiceEntityName := 'invoice';
            PaymentTermsFieldName := 'paymenttermscode';
            FreightTermsFieldName := 'freighttermscode';
            ShippingMethodFieldName := 'shippingmethodcode';

            OrderPaymentTermsOptionSetMetadataDictionary := CDSIntegrationMgt.GetOptionSetMetadata(OrderEntityName, PaymentTermsFieldName);
            OrderFreightTermsOptionSetMetadataDictionary := CDSIntegrationMgt.GetOptionSetMetadata(OrderEntityName, FreightTermsFieldName);
            OrderShippingMethodOptionSetMetadataDictionary := CDSIntegrationMgt.GetOptionSetMetadata(OrderEntityName, ShippingMethodFieldName);

            QuotePaymentTermsOptionSetMetadataDictionary := CDSIntegrationMgt.GetOptionSetMetadata(QuoteEntityName, PaymentTermsFieldName);
            QuoteFreightTermsOptionSetMetadataDictionary := CDSIntegrationMgt.GetOptionSetMetadata(QuoteEntityName, FreightTermsFieldName);
            QuoteShippingMethodOptionSetMetadataDictionary := CDSIntegrationMgt.GetOptionSetMetadata(QuoteEntityName, ShippingMethodFieldName);

            InvoicePaymentTermsOptionSetMetadataDictionary := CDSIntegrationMgt.GetOptionSetMetadata(InvoiceEntityName, PaymentTermsFieldName);
            InvoiceShippingMethodOptionSetMetadataDictionary := CDSIntegrationMgt.GetOptionSetMetadata(InvoiceEntityName, ShippingMethodFieldName);

            repeat
                OptionLabel := CRMOptionMapping."Option Value Caption";
                if OptionLabel <> '' then
                    case CRMOptionMapping."Table ID" of
                        Database::"Payment Terms":
                            begin
                                if not OrderPaymentTermsOptionSetMetadataDictionary.ContainsKey(CRMOptionMapping."Option Value") then
                                    CDSIntegrationMgt.InsertOptionSetMetadataWithOptionValue(OrderEntityName, PaymentTermsFieldName, OptionLabel, CRMOptionMapping."Option Value")
                                else
                                    if OrderPaymentTermsOptionSetMetadataDictionary.Get(CRMOptionMapping."Option Value") <> OptionLabel then
                                        CDSIntegrationMgt.UpdateOptionSetMetadata(OrderEntityName, PaymentTermsFieldName, CRMOptionMapping."Option Value", OptionLabel);

                                if not QuotePaymentTermsOptionSetMetadataDictionary.ContainsKey(CRMOptionMapping."Option Value") then
                                    CDSIntegrationMgt.InsertOptionSetMetadataWithOptionValue(QuoteEntityName, PaymentTermsFieldName, OptionLabel, CRMOptionMapping."Option Value")
                                else
                                    if QuotePaymentTermsOptionSetMetadataDictionary.Get(CRMOptionMapping."Option Value") <> OptionLabel then
                                        CDSIntegrationMgt.UpdateOptionSetMetadata(QuoteEntityName, PaymentTermsFieldName, CRMOptionMapping."Option Value", OptionLabel);

                                if not InvoicePaymentTermsOptionSetMetadataDictionary.ContainsKey(CRMOptionMapping."Option Value") then
                                    CDSIntegrationMgt.InsertOptionSetMetadataWithOptionValue(InvoiceEntityName, PaymentTermsFieldName, OptionLabel, CRMOptionMapping."Option Value")
                                else
                                    if InvoicePaymentTermsOptionSetMetadataDictionary.Get(CRMOptionMapping."Option Value") <> OptionLabel then
                                        CDSIntegrationMgt.UpdateOptionSetMetadata(InvoiceEntityName, PaymentTermsFieldName, CRMOptionMapping."Option Value", OptionLabel);
                            end;
                        Database::"Shipment Method":
                            begin
                                if not OrderFreightTermsOptionSetMetadataDictionary.ContainsKey(CRMOptionMapping."Option Value") then
                                    CDSIntegrationMgt.InsertOptionSetMetadataWithOptionValue(OrderEntityName, FreightTermsFieldName, OptionLabel, CRMOptionMapping."Option Value")
                                else
                                    if OrderFreightTermsOptionSetMetadataDictionary.Get(CRMOptionMapping."Option Value") <> OptionLabel then
                                        CDSIntegrationMgt.UpdateOptionSetMetadata(OrderEntityName, FreightTermsFieldName, CRMOptionMapping."Option Value", OptionLabel);

                                if not QuoteFreightTermsOptionSetMetadataDictionary.ContainsKey(CRMOptionMapping."Option Value") then
                                    CDSIntegrationMgt.InsertOptionSetMetadataWithOptionValue(QuoteEntityName, FreightTermsFieldName, OptionLabel, CRMOptionMapping."Option Value")
                                else
                                    if QuoteFreightTermsOptionSetMetadataDictionary.Get(CRMOptionMapping."Option Value") <> OptionLabel then
                                        CDSIntegrationMgt.UpdateOptionSetMetadata(QuoteEntityName, FreightTermsFieldName, CRMOptionMapping."Option Value", OptionLabel);
                            end;
                        Database::"Shipping Agent":
                            begin
                                if not OrderShippingMethodOptionSetMetadataDictionary.ContainsKey(CRMOptionMapping."Option Value") then
                                    CDSIntegrationMgt.InsertOptionSetMetadataWithOptionValue(OrderEntityName, ShippingMethodFieldName, OptionLabel, CRMOptionMapping."Option Value")
                                else
                                    if OrderShippingMethodOptionSetMetadataDictionary.Get(CRMOptionMapping."Option Value") <> OptionLabel then
                                        CDSIntegrationMgt.UpdateOptionSetMetadata(OrderEntityName, ShippingMethodFieldName, CRMOptionMapping."Option Value", OptionLabel);

                                if not QuoteShippingMethodOptionSetMetadataDictionary.ContainsKey(CRMOptionMapping."Option Value") then
                                    CDSIntegrationMgt.InsertOptionSetMetadataWithOptionValue(QuoteEntityName, ShippingMethodFieldName, OptionLabel, CRMOptionMapping."Option Value")
                                else
                                    if QuoteShippingMethodOptionSetMetadataDictionary.Get(CRMOptionMapping."Option Value") <> OptionLabel then
                                        CDSIntegrationMgt.UpdateOptionSetMetadata(QuoteEntityName, ShippingMethodFieldName, CRMOptionMapping."Option Value", OptionLabel);

                                if not InvoiceShippingMethodOptionSetMetadataDictionary.ContainsKey(CRMOptionMapping."Option Value") then
                                    CDSIntegrationMgt.InsertOptionSetMetadataWithOptionValue(InvoiceEntityName, ShippingMethodFieldName, OptionLabel, CRMOptionMapping."Option Value")
                                else
                                    if InvoiceShippingMethodOptionSetMetadataDictionary.Get(CRMOptionMapping."Option Value") <> OptionLabel then
                                        CDSIntegrationMgt.UpdateOptionSetMetadata(InvoiceEntityName, ShippingMethodFieldName, CRMOptionMapping."Option Value", OptionLabel);
                            end;
                    end;
            until CRMOptionMapping.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Integration Mgt.", 'OnHasCompanyIdField', '', false, false)]
    local procedure HandleOnHasCompanyIdField(TableId: Integer; var HasField: Boolean)
    begin
        case TableId of
            Database::"CRM Account",
            Database::"CRM Contact",
            Database::"CRM Invoice",
            Database::"CRM Quote",
            Database::"CRM Salesorder",
            Database::"CRM Opportunity",
            Database::"CRM Product",
            Database::"CRM Productpricelevel":
                HasField := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Int. Rec. Uncouple Invoke", 'OnBeforeUncoupleRecord', '', false, false)]
    local procedure HandleOnBeforeUncoupleRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef)
    var
        HasField: Boolean;
    begin
        CDSIntegrationMgt.OnHasCompanyIdField(IntegrationRecordRef.Number(), HasField);
        if not HasField then
            exit;

        if IntegrationRecordRef.IsEmpty() then
            exit;

        CDSIntegrationMgt.ResetCompanyId(IntegrationRecordRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Int. Rec. Uncouple Invoke", 'OnAfterUncoupleRecord', '', false, false)]
    local procedure HandleOnAfterUncoupleRecord(IntegrationTableMapping: Record "Integration Table Mapping"; var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef)
    begin
        RemoveChildCouplings(LocalRecordRef, IntegrationRecordRef);
    end;

    local procedure RemoveChildCouplings(var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef)
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ChildContactList: List of [Guid];
    begin
        if GetCoupledChildContacts(LocalRecordRef, IntegrationRecordRef, ChildContactList) then
            CRMIntegrationManagement.RemoveCoupling(Database::Contact, ChildContactList, false);
    end;

    local procedure GetCoupledChildContacts(var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef; var ChildContactList: List of [Guid]): Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMID: Guid;
    begin
        if IntegrationRecordRef.Number() <> Database::"CRM Account" then
            exit(false);

        IntegrationRecordRef.SetTable(CRMAccount);
        if IsNullGuid(CRMAccount.AccountId) then
            exit(false);

        case LocalRecordRef.Number() of
            Database::Customer:
                begin
                    LocalRecordRef.SetTable(Customer);
                    if IsNullGuid(Customer.SystemId) then
                        exit(false);
                    ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                    ContBusRel.SetRange("No.", Customer."No.");
                end;
            Database::Vendor:
                begin
                    LocalRecordRef.SetTable(Vendor);
                    if IsNullGuid(Vendor.SystemId) then
                        exit(false);
                    ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Vendor);
                    ContBusRel.SetRange("No.", Vendor."No.");
                end;
            else
                exit(false);
        end;

        // Get the Company Contact for this Customer or Vendor
        ContBusRel.SetCurrentKey("Link to Table", "No.");
        if ContBusRel.FindFirst() then begin
            // Get all Person Contacts under it
            Contact.SetCurrentKey("Company Name", "Company No.", Type, Name);
            Contact.SetRange("Company No.", ContBusRel."Contact No.");
            Contact.SetRange(Type, Contact.Type::Person);
            if Contact.FindSet() then
                // Collect coupled CRM Contacts under the CRM Account the Customer or Vendor is coupled to
                repeat
                    if CRMIntegrationRecord.FindIDFromRecordID(Contact.RecordId(), CRMID) then begin
                        CRMContact.Get(CRMID);
                        if CRMContact.ParentCustomerId = CRMAccount.AccountId then
                            ChildContactList.Add(Contact.SystemId);
                    end;
                until Contact.Next() = 0;
        end;
        exit(ChildContactList.Count > 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Management", 'OnIsCDSIntegrationEnabled', '', false, false)]
    local procedure HandleOnIsCDSIntegrationEnabled(var isEnabled: Boolean)
    begin
        if isEnabled then
            exit;

        if CDSIntegrationMgt.IsIntegrationEnabled() then
            isEnabled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Synch. Helper", 'OnGetCDSBaseCurrencyId', '', false, false)]
    local procedure HandleOnGetCDSBaseCurrencyId(var BaseCurrencyId: Guid; var handled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if handled then
            exit;

        if not CDSConnectionSetup.Get() then
            exit;

        if not CDSConnectionSetup."Is Enabled" then
            exit;

        BaseCurrencyId := CDSConnectionSetup.BaseCurrencyId;
        handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Synch. Helper", 'OnGetCDSBaseCurrencySymbol', '', false, false)]
    local procedure HandleOnGetCDSBaseCurrencySymbol(var BaseCurrencySymbol: Text[5]; var handled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if handled then
            exit;

        if not CDSConnectionSetup.Get() then
            exit;

        if not CDSConnectionSetup."Is Enabled" then
            exit;

        BaseCurrencySymbol := CDSConnectionSetup.BaseCurrencySymbol;
        handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Synch. Helper", 'OnGetCDSBaseCurrencyPrecision', '', false, false)]
    local procedure HandleOnGetCDSBaseCurrencyPrecision(var BaseCurrencyPrecision: Integer; var handled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if handled then
            exit;

        if not CDSConnectionSetup.Get() then
            exit;

        if not CDSConnectionSetup."Is Enabled" then
            exit;

        BaseCurrencyPrecision := CDSConnectionSetup.BaseCurrencyPrecision;
        handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Synch. Helper", 'OnGetCDSCurrencyDecimalPrecision', '', false, false)]
    local procedure HandleOnGetCDSCurrencyDecimalPrecision(var CurrencyDecimalPrecision: Integer; var handled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if handled then
            exit;

        if not CDSConnectionSetup.Get() then
            exit;

        if not CDSConnectionSetup."Is Enabled" then
            exit;

        CurrencyDecimalPrecision := CDSConnectionSetup.CurrencyDecimalPrecision;
        handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Synch. Helper", 'OnGetCDSOwnershipModel', '', false, false)]
    local procedure HandleOnGetCDSOwnershipModel(var OwnershipModel: Option; var handled: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
    begin
        if handled then
            exit;

        if not CDSConnectionSetup.Get() then
            exit;

        if not CDSConnectionSetup."Is Enabled" then
            exit;

        OwnershipModel := CDSConnectionSetup."Ownership Model";
        handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Synch. Helper", 'OnGetVendorSyncEnabled', '', false, false)]
    local procedure HandleOnGetVendorSyncEnabled(var Enabled: Boolean)
    begin
        if Enabled then
            exit;

        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        Enabled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Copy Company", 'OnAfterCreatedNewCompanyByCopyCompany', '', false, false)]
    local procedure HandleOnAfterCreatedNewCompanyByCopyCompany(NewCompanyName: Text[30])
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMConnectionSetup: Record "CRM Connection Setup";
        CDSIntegrationRecord: Record "CRM Integration Record";
    begin
        CDSConnectionSetup.ChangeCompany(NewCompanyName);
        CDSConnectionSetup.DeleteAll();
        CRMConnectionSetup.ChangeCompany(NewCompanyName);
        CRMConnectionSetup.DeleteAll();
        CDSIntegrationRecord.ChangeCompany(NewCompanyName);
        CDSIntegrationRecord.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Table, Database::Company, 'OnBeforeDeleteEvent', '', false, false)]
    local procedure DeleteCouplingOnBeforeDeleteCompany(var Rec: Record Company; RunTrigger: Boolean)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMIntegrationRecord: Record "CRM Integration Record";
        TenantLicenseState: Codeunit "Tenant License State";
        IntegrationTableMappingList: Page "Integration Table Mapping List";
        EnumTenantLicenseState: Enum "Tenant License State";
    begin
        if Rec.IsTemporary() then
            exit;

        if CDSConnectionSetup.ChangeCompany(Rec.Name) then
            if CDSConnectionSetup.Get() then
                if CDSConnectionSetup."Is Enabled" then
                    if CRMIntegrationRecord.ChangeCompany(Rec.Name) then
                        if not CRMIntegrationRecord.IsEmpty() then begin
                            if not GuiAllowed() then
                                if TenantLicenseState.GetLicenseState() in [
                                    EnumTenantLicenseState::Suspended,
                                    EnumTenantLicenseState::Deleted,
                                    EnumTenantLicenseState::LockedOut]
                                then
                                    exit;
                            if GuiAllowed() then
                                if not Confirm(StrSubstNo(CouplingsNeedToBeResetQst, IntegrationTableMappingList.Caption())) then
                                    Error('');
                        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", 'OnAfterUnchangedRecordHandled', '', false, false)]
    local procedure OnAfterUnchangedRecordHandled(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMContact: Record "CRM Contact";
        EmptyGuid: Guid;
    begin
        if not CDSConnectionSetup.Get() then
            exit;

        if not CDSConnectionSetup."Is Enabled" then
            exit;

        case GetSourceDestCode(SourceRecordRef, DestinationRecordRef) of
            'Contact-CRM Contact':
                begin
                    DestinationRecordRef.SetTable(CRMContact);
                    if CRMContact.ParentCustomerId = EmptyGuid then begin
                        UpdateCRMContactParentCustomerId(SourceRecordRef, DestinationRecordRef);
                        DestinationRecordRef.Modify();
                    end
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Integration Table Synch.", 'OnQueryPostFilterIgnoreRecord', '', false, false)]
    procedure OnQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    begin
        if IgnoreRecord then
            exit;

        if SourceRecordRef.Number() = Database::Contact then
            HandleContactQueryPostFilterIgnoreRecord(SourceRecordRef, IgnoreRecord);
    end;

    local procedure HandleContactQueryPostFilterIgnoreRecord(SourceRecordRef: RecordRef; var IgnoreRecord: Boolean)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        if IgnoreRecord then
            exit;

        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        if CRMSynchHelper.IsContactBusinessRelationOptional() then
            exit;

        if CRMSynchHelper.FindContactRelatedCustomer(SourceRecordRef, ContactBusinessRelation) then
            exit;

        if CRMSynchHelper.FindContactRelatedVendor(SourceRecordRef, ContactBusinessRelation) then
            exit;

        IgnoreRecord := true;
    end;

    local procedure UpdateCRMContactParentCustomerId(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CRMContact: Record "CRM Contact";
        ParentCustomerIdFieldRef: FieldRef;
        AccountId: Guid;
        Silent: Boolean;
    begin
        if not CDSIntegrationImpl.IsIntegrationEnabled() then
            exit;

        Silent := CRMSynchHelper.IsContactBusinessRelationOptional();
        if FindParentCRMAccountForContact(SourceRecordRef, Silent, AccountId) then begin
            // Transfer the parent company id to the ParentCustomerId
            ParentCustomerIdFieldRef := DestinationRecordRef.Field(CRMContact.FieldNo(ParentCustomerId));
            ParentCustomerIdFieldRef.Value := AccountId;
        end;
    end;

    local procedure FindParentCRMAccountForContact(SourceRecordRef: RecordRef; Silent: Boolean; var AccountId: Guid) Result: Boolean
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
        Customer: Record Customer;
        Vendor: Record Vendor;
        CRMIntegrationRecord: Record "CRM Integration Record";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindParentCRMAccountForContact(SourceRecordRef, Silent, AccountId, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if CRMSynchHelper.FindContactRelatedCustomer(SourceRecordRef, ContactBusinessRelation) then begin
            if Customer.Get(ContactBusinessRelation."No.") then begin
                CRMIntegrationRecord.FindIDFromRecordID(Customer.RecordId(), AccountId);
                exit(true);
            end;
            if not Silent then
                Error(RecordNotFoundErr, Customer.TableCaption(), ContactBusinessRelation."No.");
            exit(false);
        end;

        if CRMSynchHelper.FindContactRelatedVendor(SourceRecordRef, ContactBusinessRelation) then begin
            if Vendor.Get(ContactBusinessRelation."No.") then begin
                CRMIntegrationRecord.FindIDFromRecordID(Vendor.RecordId(), AccountId);
                exit(true);
            end;
            if not Silent then
                Error(RecordNotFoundErr, Vendor.TableCaption(), ContactBusinessRelation."No.");
            exit(false);
        end;

        if not Silent then
            Error(ContactMustBeRelatedToCustomerOrVendorErr, SourceRecordRef.Field(Contact.FieldNo("No.")).Value());
        exit(false);
    end;

    local procedure FixPrimaryContactNo(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef) Result: Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        RecRef: RecordRef;
        RecordModifiedAfterLastSync: Boolean;
    begin
        DestinationRecordRef.SetTable(Contact);
        SourceRecordRef.SetTable(CRMContact);

        if CRMContact.ParentCustomerIdType <> CRMContact.ParentCustomerIdType::account then
            exit(false);

        if IsNullGuid(CRMContact.ParentCustomerId) then
            exit(false);

        if FindCustomerByAccountId(CRMContact.ParentCustomerId, Customer) then
            if Customer."Primary Contact No." = '' then
                if IntegrationTableMapping.FindMapping(Database::Customer, Database::"CRM Account") then
                    if IntegrationTableMapping.IsFieldMappingEnabled(Customer.FieldNo("Primary Contact No."), CRMAccount.FieldNo(PrimaryContactId), IntegrationTableMapping.Direction::FromIntegrationTable) then begin
                        RecRef.GetTable(Customer);
                        RecordModifiedAfterLastSync := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, RecRef);
                        Customer."Primary Contact No." := Contact."No.";
                        if Contact.Type = Contact.Type::Person then
                            Customer.Contact := Contact.Name;
                        Customer.Modify();
                        if not RecordModifiedAfterLastSync then begin
                            CRMIntegrationRecord.SetRange("Integration ID", Customer.SystemId);
                            if CRMIntegrationRecord.FindFirst() then begin
                                CRMIntegrationRecord."Last Synch. Modified On" := Customer.SystemModifiedAt;
                                CRMIntegrationRecord.Modify();
                            end;
                        end;
                        exit(true);
                    end;

        if FindVendorByAccountId(CRMContact.ParentCustomerId, Vendor) then
            if Vendor."Primary Contact No." = '' then
                if IntegrationTableMapping.FindMapping(Database::Vendor, Database::"CRM Account") then
                    if IntegrationTableMapping.IsFieldMappingEnabled(Vendor.FieldNo("Primary Contact No."), CRMAccount.FieldNo(PrimaryContactId), IntegrationTableMapping.Direction::FromIntegrationTable) then begin
                        RecRef.GetTable(Vendor);
                        RecordModifiedAfterLastSync := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, RecRef);
                        Vendor."Primary Contact No." := Contact."No.";
                        if Contact.Type = Contact.Type::Person then
                            Vendor.Contact := Contact.Name;
                        Vendor.Modify();
                        if not RecordModifiedAfterLastSync then begin
                            CRMIntegrationRecord.SetRange("Integration ID", Vendor.SystemId);
                            if CRMIntegrationRecord.FindFirst() then begin
                                CRMIntegrationRecord."Last Synch. Modified On" := Vendor.SystemModifiedAt;
                                CRMIntegrationRecord.Modify();
                            end;
                        end;
                        exit(true);
                    end;

        Result := false;
        OnAfterFixPrimaryContactNo(SourceRecordRef, DestinationRecordRef, Result);
    end;

    local procedure UpdateChildContactsParentCompany(CRMAccountRecordRef: RecordRef)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        Contact: Record Contact;
        ContactRecordRef: RecordRef;
        CRMContactRecordRef: RecordRef;
        CompanyId: Guid;
    begin
        CRMAccountRecordRef.SetTable(CRMAccount);
        case CRMAccount.CustomerTypeCode of
            CRMAccount.CustomerTypeCode::Customer:
                if not IntegrationTableMapping.FindMapping(Database::Customer, Database::"CRM Account") then
                    exit;
            CRMAccount.CustomerTypeCode::Vendor:
                if not IntegrationTableMapping.FindMapping(Database::Vendor, Database::"CRM Account") then
                    exit;
            else
                exit;
        end;

        if not (IntegrationTableMapping.Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::FromIntegrationTable]) then
            exit;

        Contact.SetRange("Company No.", '');
        if Contact.IsEmpty() then
            exit; // all contacts have parent company set

        if not CDSIntegrationImpl.TryGetCompanyId(CompanyId) then
            exit;

        // find and process already synced child contacts
        CRMContact.SetRange(ParentCustomerIdType, CRMContact.ParentCustomerIdType::account);
        CRMContact.SetRange(ParentCustomerId, CRMAccount.AccountId);
        CRMContact.SetRange(CompanyId, CompanyId);
        if CRMContact.FindSet() then
            repeat
                if CRMIntegrationRecord.FindByCRMID(CRMContact.ContactId) then begin
                    CRMContactRecordRef.GetTable(CRMContact);
                    ContactRecordRef.Open(Database::Contact);
                    if ContactRecordRef.GetBySystemId(CRMIntegrationRecord."Integration ID") then begin
                        FixPrimaryContactNo(CRMContactRecordRef, ContactRecordRef);
                        UpdateContactParentCompany(CRMAccount.AccountId, ContactRecordRef);
                    end;
                    ContactRecordRef.Close();
                end;
            until CRMContact.Next() = 0;
    end;

    local procedure UpdateContactParentCompany(AccountId: Guid; var ContactRecordRef: RecordRef)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        Contact: Record Contact;
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        RecordModifiedAfterLastSync: Boolean;
        OldCompanyNo: Code[20];
        NewCompanyNo: Code[20];
    begin
        if not IntegrationTableMapping.FindMapping(Database::Contact, Database::"CRM Contact") then
            exit;

        if not (IntegrationTableMapping.Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::FromIntegrationTable]) then
            exit;

        Session.LogMessage('0000EOB', UpdateContactParentCompanyTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);

        RecordModifiedAfterLastSync := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, ContactRecordRef);
        OldCompanyNo := ContactRecordRef.Field(Contact.FieldNo("Company No.")).Value();

        if not CRMSynchHelper.SetContactParentCompany(AccountId, ContactRecordRef) then begin
            Session.LogMessage('0000EOC', StrSubstNo(UpdateContactParentCompanyFailedTxt, AccountId), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit;
        end;

        NewCompanyNo := ContactRecordRef.Field(Contact.FieldNo("Company No.")).Value();
        if NewCompanyNo = OldCompanyNo then begin
            Session.LogMessage('0000EOD', UpdateContactParentCompanyAlreadySetTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            exit;
        end;

        ContactRecordRef.Modify();
        if not RecordModifiedAfterLastSync then begin
            ContactRecordRef.SetTable(Contact);
            CRMIntegrationRecord.SetRange("Integration ID", Contact.SystemId);
            if CRMIntegrationRecord.FindFirst() then begin
                CRMIntegrationRecord."Last Synch. Modified On" := Contact.SystemModifiedAt;
                CRMIntegrationRecord.Modify();
            end;
        end;

        Session.LogMessage('0000EOE', UpdateContactParentCompanySuccessfulTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
    end;

    local procedure FindNewValueForCoupledRecordPK(IntegrationTableMapping: Record "Integration Table Mapping"; SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValue: Variant) IsValueFound: Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecID: RecordID;
        CRMID: Guid;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindNewValueForCoupledRecordPK(IntegrationTableMapping, SourceFieldRef, DestinationFieldRef, NewValue, IsValueFound, IsHandled);
        if IsHandled then
            exit(IsValueFound);

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
                    Error(RecordMustBeCoupledErr, SourceFieldRef.Name(), SourceFieldRef.Value());
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
                        Error(RecordMustBeCoupledErr, SourceFieldRef.Name(), CRMID);
                    end;
                end;
        end;
    end;

    local procedure FixPrimaryContactIdInCDS(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Boolean
    var
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
        CRMAccount: Record "CRM Account";
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationRecord: Record "CRM Integration Record";
        IntegrationRecSynchInvoke: Codeunit "Integration Rec. Synch. Invoke";
        CRMRecordRef: RecordRef;
        CRMAccountModifiedAfterLastSync: Boolean;
    begin
        DestinationRecordRef.SetTable(CRMContact);
        SourceRecordRef.SetTable(Contact);

        if CRMContact.ParentCustomerIdType <> CRMContact.ParentCustomerIdType::account then
            exit(false);

        if IsNullGuid(CRMContact.ParentCustomerId) then
            exit(false);

        if not CRMAccount.Get(CRMContact.ParentCustomerId) then
            exit(false);

        if not IsNullGuid(CRMAccount.PrimaryContactId) then
            exit(false);

        case CRMAccount.CustomerTypeCode of
            CRMAccount.CustomerTypeCode::Customer:
                if not IntegrationTableMapping.FindMapping(Database::Customer, Database::"CRM Account") then
                    exit(false);
            CRMAccount.CustomerTypeCode::Vendor:
                if not IntegrationTableMapping.FindMapping(Database::Vendor, Database::"CRM Account") then
                    exit(false);
        end;

        if not (IntegrationTableMapping.Direction in [IntegrationTableMapping.Direction::Bidirectional, IntegrationTableMapping.Direction::ToIntegrationTable]) then
            exit(false);

        CRMRecordRef.GetTable(CRMAccount);
        CRMAccountModifiedAfterLastSync := IntegrationRecSynchInvoke.WasModifiedAfterLastSynch(IntegrationTableMapping, CRMRecordRef);
        CRMAccount.PrimaryContactId := CRMContact.ContactId;
        CRMAccount.Modify();
        if not CRMAccountModifiedAfterLastSync then begin
            CRMIntegrationRecord.SetRange("CRM ID", CRMAccount.AccountId);
            if CRMIntegrationRecord.FindFirst() then begin
                CRMIntegrationRecord."Last Synch. CRM Modified On" := CRMAccount.ModifiedOn;
                CRMIntegrationRecord.Modify();
            end;
        end;
        exit(true);
    end;

    local procedure FindCustomerByAccountId(AccountId: Guid; var Customer: Record Customer): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CustomerRecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(AccountId, DATABASE::Customer, CustomerRecordID) then
            exit(Customer.Get(CustomerRecordID));

        exit(false);
    end;

    local procedure FindVendorByAccountId(AccountId: Guid; var Vendor: Record Vendor): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        VendorRecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(AccountId, DATABASE::Vendor, VendorRecordID) then
            exit(Vendor.Get(VendorRecordID));

        exit(false);
    end;

    local procedure SetDefaultSymbolOnCRMTransactioncurrencyIfEmpty(var DestinationRecordRef: RecordRef)
    var
        TempCRMTransactionCurrency: Record "CRM Transactioncurrency" temporary;
        CurrencySymbol: Text[10];
    begin
        CurrencySymbol := DestinationRecordRef.Field(TempCRMTransactionCurrency.FieldNo(CurrencySymbol)).Value();
        if CurrencySymbol = '' then
            DestinationRecordRef.Field(TempCRMTransactionCurrency.FieldNo(CurrencySymbol)).Value := DestinationRecordRef.Field(TempCRMTransactionCurrency.FieldNo(ISOCurrencyCode)).Value();
    end;

    local procedure UpdateSalesPersOnBeforeInsertRecord(var DestinationRecordRef: RecordRef)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        DestinationFieldRef: FieldRef;
        NewCode: Text;
    begin
        if not (CRMIntegrationManagement.IsCDSIntegrationEnabled() or CRMIntegrationManagement.IsCRMIntegrationEnabled()) then
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Table Synch.", 'OnAfterInitSynchJob', '', true, true)]
    local procedure LogTelemetryOnAfterInitSynchJob(ConnectionType: TableConnectionType; IntegrationTableID: Integer)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        IntegrationRecordRef: RecordRef;
        TelemetryCategories: Dictionary of [Text, Text];
        IntegrationTableName: Text;
    begin
        if ConnectionType <> TableConnectionType::CRM then
            exit;
        FeatureTelemetry.LogUptake('0000H7M', 'Dataverse', Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000H7N', 'Dataverse', 'Entity sync');
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetRange("Multi Company Synch. Enabled", true);
        IntegrationTableMapping.SetRange("Table ID", IntegrationTableID);
        if not IntegrationTableMapping.IsEmpty() then begin
            FeatureTelemetry.LogUptake('0000LCO', 'Dataverse Multi-Company Synch', Enum::"Feature Uptake Status"::Used);
            FeatureTelemetry.LogUsage('0000LCQ', 'Dataverse Multi-Company Synch', 'Entity sync');
            Session.LogMessage('0000LCS', 'Multi-Company Synch Enabled', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        end;
        IntegrationTableMapping.SetRange("Table ID");
        IntegrationTableMapping.SetRange("Integration Table ID", IntegrationTableID);
        if not IntegrationTableMapping.IsEmpty() then begin
            FeatureTelemetry.LogUptake('0000LCP', 'Dataverse Multi-Company Synch', Enum::"Feature Uptake Status"::Used);
            FeatureTelemetry.LogUsage('0000LCR', 'Dataverse Multi-Company Synch', 'Entity sync');
            Session.LogMessage('0000LCT', 'Multi-Company Synch Enabled', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
        end;

        TelemetryCategories.Add('Category', CategoryTok);
        TelemetryCategories.Add('IntegrationTableID', Format(IntegrationTableID));
        if TryCalculateTableName(IntegrationRecordRef, IntegrationTableID, IntegrationTableName) then
            TelemetryCategories.Add('IntegrationTableName', IntegrationTableName);

        if IntegrationTableID in [
                Database::"CRM Account",
                Database::"CRM Contact",
                Database::"CRM Transactioncurrency",
                Database::"CRM Systemuser"] then begin
            Session.LogMessage('0000FMC', 'Synching a base entity.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryCategories);
            FeatureTelemetry.LogUsage('0000H7O', 'Dataverse', 'Base entity synch');
            FeatureTelemetry.LogUsage('0000IIL', 'Dataverse Base Entities', 'Base entity synch');
            FeatureTelemetry.LogUptake('0000KMT', 'Dataverse Base Entities', Enum::"Feature Uptake Status"::Used);
            exit;
        end;
        if IntegrationTableID > MinCustomTableId() then begin
            Session.LogMessage('0000FMD', 'Synching a custom entity.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryCategories);
            FeatureTelemetry.LogUsage('0000H7P', 'Dataverse', 'Custom entity synch');
        end;
    end;

    [TryFunction]
    local procedure TryCalculateTableName(var IntegrationRecordRef: RecordRef; TableId: Integer; var TableName: Text)
    begin
        IntegrationRecordRef.Open(TableId);
        TableName := IntegrationRecordRef.Name();
    end;

    local procedure MinCustomTableId(): Integer
    begin
        exit(50000);
    end;

    [Scope('OnPrem')]
    procedure SetCompanyId(DestinationRecordRef: RecordRef)
    begin
        if CDSIntegrationImpl.CheckCompanyIdNoTelemetry(DestinationRecordRef) then
            exit;

        CDSIntegrationMgt.SetCompanyId(DestinationRecordRef);
    end;

    [Scope('OnPrem')]
    procedure SetOwnerId(var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        UserId: Guid;
    begin
        CDSConnectionSetup.Get();
        case CDSConnectionSetup."Ownership Model" of
            CDSConnectionSetup."Ownership Model"::Team:
                CDSIntegrationMgt.SetOwningTeam(DestinationRecordRef);
            CDSConnectionSetup."Ownership Model"::Person:
                begin
                    UserId := CRMSynchHelper.GetCoupledCDSUserId(SourceRecordRef);
                    if not IsNullGuid(UserId) then
                        CDSIntegrationMgt.SetOwningUser(DestinationRecordRef, UserId, true)
                    else
                        CDSIntegrationMgt.SetOwningTeam(DestinationRecordRef);
                end;
        end;
    end;

    local procedure GetCoupledSalespersonPurchaserCode(SourceRecordRef: RecordRef): Code[20]
    var
        CRMAccount: Record "CRM Account";
        CRMContact: Record "CRM Contact";
        CRMSystemuser: Record "CRM Systemuser";
        CRMIntegrationRecord: Record "CRM Integration Record";
        SalesPersonPurchaser: Record "Salesperson/Purchaser";
        CDSUserId: Guid;
    begin
        case SourceRecordRef.Number() of
            Database::"CRM Account":
                begin
                    SourceRecordRef.SetTable(CRMAccount);
                    if CRMAccount.OwnerIdType <> CRMAccount.OwnerIdType::systemuser then
                        exit('');
                    CDSUserId := CRMAccount.OwnerId;
                end;
            Database::"CRM Contact":
                begin
                    SourceRecordRef.SetTable(CRMContact);
                    if CRMContact.OwnerIdType <> CRMContact.OwnerIdType::systemuser then
                        exit('');
                    CDSUserId := CRMContact.OwnerId;
                end;
            else
                exit('');
        end;

        if not CRMIntegrationRecord.FindByCRMID(CDSUserId) then
            Error(RecordMustBeCoupledExtErr, CRMSystemuser.TableCaption(), CDSUserId, SalesPersonPurchaser.TableCaption());

        if not SalesPersonPurchaser.GetBySystemId(CRMIntegrationRecord."Integration ID") then
            exit('');

        exit(SalesPersonPurchaser.Code);
    end;

    local procedure GetSourceDestCode(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef): Text
    begin
        if (SourceRecordRef.Number() <> 0) and (DestinationRecordRef.Number() <> 0) then
            exit(StrSubstNo('%1-%2', SourceRecordRef.Name(), DestinationRecordRef.Name()));
        exit('');
    end;

    local procedure ShowError(ActivityDescription: Text[128]; ErrorMessage: Text)
    var
        MyNotifications: Record "My Notifications";
        SystemInitialization: Codeunit "System Initialization";
    begin
        if (not SystemInitialization.IsInProgress()) and (GetExecutionContext() = ExecutionContext::Normal) then
            Error(ErrorMessage);

        MyNotifications.InsertDefault(GetCDSNotificationId(), ActivityDescription, ErrorMessage, true);
    end;

    local procedure GetCDSNotificationId(): Guid
    begin
        exit('877d4577-dafa-4b91-9a03-9f7c6402d883');
    end;

    local procedure FindIntegrationUserId(): Guid
    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CRMSystemuser: Record "CRM Systemuser";
        IntegrationUserId: Guid;
    begin
        CDSConnectionSetup.Get();
        case CDSConnectionSetup."Authentication Type" of
            CDSConnectionSetup."Authentication Type"::Office365, CDSConnectionSetup."Authentication Type"::OAuth:
                CRMSystemuser.SetRange(InternalEMailAddress, CDSConnectionSetup."User Name");
            CDSConnectionSetup."Authentication Type"::AD, CDSConnectionSetup."Authentication Type"::IFD:
                CRMSystemuser.SetRange(DomainName, CDSConnectionSetup."User Name");
        end;

        if CRMSystemuser.FindFirst() then
            IntegrationUserId := CRMSystemuser.SystemUserId;

        exit(IntegrationUserId);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFixPrimaryContactNo(SourceRecordRef: RecordRef; DestinationRecordRef: RecordRef; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindParentCRMAccountForContact(SourceRecordRef: RecordRef; Silent: Boolean; var AccountId: Guid; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindNewValueForCoupledRecordPK(IntegrationTableMapping: Record "Integration Table Mapping"; SourceFieldRef: FieldRef; DestinationFieldRef: FieldRef; var NewValueVariant: Variant; var IsValueFound: Boolean; var IsHandled: Boolean)
    begin
    end;
}
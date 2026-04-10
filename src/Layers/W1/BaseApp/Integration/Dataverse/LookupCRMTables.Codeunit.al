// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;
using System.Reflection;

codeunit 5332 "Lookup CRM Tables"
{

    trigger OnRun()
    begin
    end;

    procedure Lookup(CRMTableID: Integer; NAVTableId: Integer; SavedCRMId: Guid; var CRMId: Guid): Boolean
    var
        IntTableFilter: Text;
        Handled: Boolean;
    begin
        IntTableFilter := GetIntegrationTableFilter(CRMTableID, NAVTableId);

        OnLookupCRMTables(CRMTableID, NAVTableId, SavedCRMId, CRMId, IntTableFilter, Handled);
        if Handled then
            exit(true);

        case CRMTableID of
            DATABASE::"CRM Account":
                exit(LookupCRMAccount(SavedCRMId, CRMId, IntTableFilter));
            DATABASE::"CRM Contact":
                exit(LookupCRMContact(SavedCRMId, CRMId, IntTableFilter));
            DATABASE::"CRM Systemuser":
                exit(LookupCRMSystemuser(SavedCRMId, CRMId, IntTableFilter));
            DATABASE::"CRM Transactioncurrency":
                exit(LookupCRMCurrency(SavedCRMId, CRMId, IntTableFilter));
            DATABASE::"CRM Pricelevel":
                exit(LookupCRMPriceList(SavedCRMId, CRMId, IntTableFilter));
            DATABASE::"CRM Product":
                exit(LookupCRMProduct(SavedCRMId, CRMId, IntTableFilter));
            DATABASE::"CRM Uomschedule":
                exit(LookupCRMUomschedule(SavedCRMId, CRMId, IntTableFilter));
            DATABASE::"CRM Opportunity":
                exit(LookupCRMOpportunity(SavedCRMId, CRMId, IntTableFilter));
            DATABASE::"CRM Quote":
                exit(LookupCRMQuote(SavedCRMId, CRMId, IntTableFilter));
            DATABASE::"CRM Uom":
                exit(LookupCRMUom(SavedCRMId, CRMId, IntTableFilter));
            DATABASE::"CRM Salesorder":
                exit(LookupCRMSalesorder(SavedCRMId, CRMId, IntTableFilter));
        end;
        exit(false);
    end;

    procedure LookupOptions(CRMTableID: Integer; NAVTableId: Integer; SavedCRMOptionId: Integer; var CRMOptionId: Integer; var CRMOptionCode: Text[250]): Boolean
    var
        IntTableFilter: Text;
        Handled: Boolean;
    begin
        IntTableFilter := GetIntegrationTableFilter(CRMTableID, NAVTableId);

        OnLookupCRMOption(CRMTableID, NAVTableId, SavedCRMOptionId, CRMOptionId, CRMOptionCode, IntTableFilter, Handled);
        if Handled then
            exit(true);

        case CRMTableID of
            DATABASE::"CRM Payment Terms":
                exit(LookupCRMPaymentTerm(SavedCRMOptionId, CRMOptionId, CRMOptionCode, IntTableFilter));
            DATABASE::"CRM Freight Terms":
                exit(LookupCRMFreightTerm(SavedCRMOptionId, CRMOptionId, CRMOptionCode, IntTableFilter));
            DATABASE::"CRM Shipping Method":
                exit(LookupCRMShippingMethod(SavedCRMOptionId, CRMOptionId, CRMOptionCode, IntTableFilter));
        end;
        exit(false);
    end;

    local procedure LookupCRMAccount(SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text): Boolean
    var
        CRMAccount: Record "CRM Account";
        OriginalCRMAccount: Record "CRM Account";
        CRMAccountList: Page "CRM Account List";
    begin
        if not IsNullGuid(CRMId) then begin
            if CRMAccount.Get(CRMId) then
                CRMAccountList.SetRecord(CRMAccount);
            if not IsNullGuid(SavedCRMId) then
                if OriginalCRMAccount.Get(SavedCRMId) then
                    CRMAccountList.SetCurrentlyCoupledCRMAccount(OriginalCRMAccount);
        end;
        CRMAccount.SetView(IntTableFilter);
        CRMAccountList.SetTableView(CRMAccount);
        CRMAccountList.LookupMode(true);
        Commit();
        if CRMAccountList.RunModal() = ACTION::LookupOK then begin
            CRMAccountList.GetRecord(CRMAccount);
            CRMId := CRMAccount.AccountId;
            exit(true);
        end;
        exit(false);
    end;

    local procedure LookupCRMContact(SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text): Boolean
    var
        CRMContact: Record "CRM Contact";
        OriginalCRMContact: Record "CRM Contact";
        CRMContactList: Page "CRM Contact List";
    begin
        if not IsNullGuid(CRMId) then begin
            if CRMContact.Get(CRMId) then
                CRMContactList.SetRecord(CRMContact);
            if not IsNullGuid(SavedCRMId) then
                if OriginalCRMContact.Get(SavedCRMId) then
                    CRMContactList.SetCurrentlyCoupledCRMContact(OriginalCRMContact);
        end;
        CRMContact.SetView(IntTableFilter);
        CRMContactList.SetTableView(CRMContact);
        CRMContactList.LookupMode(true);
        Commit();
        if CRMContactList.RunModal() = ACTION::LookupOK then begin
            CRMContactList.GetRecord(CRMContact);
            CRMId := CRMContact.ContactId;
            exit(true);
        end;
        exit(false);
    end;

    local procedure LookupCRMSystemuser(SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text): Boolean
    var
        CRMSystemuser: Record "CRM Systemuser";
        OriginalCRMSystemuser: Record "CRM Systemuser";
        CRMSystemuserList: Page "CRM Systemuser List";
    begin
        if not IsNullGuid(CRMId) then begin
            if CRMSystemuser.Get(CRMId) then
                CRMSystemuserList.SetRecord(CRMSystemuser);
            if not IsNullGuid(SavedCRMId) then
                if OriginalCRMSystemuser.Get(SavedCRMId) then
                    CRMSystemuserList.SetCurrentlyCoupledCRMSystemuser(OriginalCRMSystemuser);
        end;
        CRMSystemuser.SetView(IntTableFilter);
        CRMSystemuserList.SetTableView(CRMSystemuser);
        CRMSystemuserList.LookupMode(true);
        Commit();
        if CRMSystemuserList.RunModal() = ACTION::LookupOK then begin
            CRMSystemuserList.GetRecord(CRMSystemuser);
            CRMId := CRMSystemuser.SystemUserId;
            exit(true);
        end;
        exit(false);
    end;

    local procedure LookupCRMCurrency(SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text): Boolean
    var
        CRMTransactioncurrency: Record "CRM Transactioncurrency";
        OriginalCRMTransactioncurrency: Record "CRM Transactioncurrency";
        CRMTransactionCurrencyList: Page "CRM TransactionCurrency List";
    begin
        if not IsNullGuid(CRMId) then begin
            if CRMTransactioncurrency.Get(CRMId) then
                CRMTransactionCurrencyList.SetRecord(CRMTransactioncurrency);
            if not IsNullGuid(SavedCRMId) then
                if OriginalCRMTransactioncurrency.Get(SavedCRMId) then
                    CRMTransactionCurrencyList.SetCurrentlyCoupledCRMTransactioncurrency(OriginalCRMTransactioncurrency);
        end;
        CRMTransactioncurrency.SetView(IntTableFilter);
        CRMTransactionCurrencyList.SetTableView(CRMTransactioncurrency);
        CRMTransactionCurrencyList.LookupMode(true);
        Commit();
        if CRMTransactionCurrencyList.RunModal() = ACTION::LookupOK then begin
            CRMTransactionCurrencyList.GetRecord(CRMTransactioncurrency);
            CRMId := CRMTransactioncurrency.TransactionCurrencyId;
            exit(true);
        end;
        exit(false);
    end;

    local procedure LookupCRMPriceList(SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text): Boolean
    var
        CRMPricelevel: Record "CRM Pricelevel";
        OriginalCRMPricelevel: Record "CRM Pricelevel";
        CRMPricelevelList: Page "CRM Pricelevel List";
    begin
        if not IsNullGuid(CRMId) then begin
            if CRMPricelevel.Get(CRMId) then
                CRMPricelevelList.SetRecord(CRMPricelevel);
            if not IsNullGuid(SavedCRMId) then
                if OriginalCRMPricelevel.Get(SavedCRMId) then
                    CRMPricelevelList.SetCurrentlyCoupledCRMPricelevel(OriginalCRMPricelevel);
        end;
        CRMPricelevel.SetView(IntTableFilter);
        CRMPricelevelList.SetTableView(CRMPricelevel);
        CRMPricelevelList.LookupMode(true);
        Commit();
        if CRMPricelevelList.RunModal() = ACTION::LookupOK then begin
            CRMPricelevelList.GetRecord(CRMPricelevel);
            CRMId := CRMPricelevel.PriceLevelId;
            exit(true);
        end;
        exit(false);
    end;

    local procedure LookupCRMProduct(SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text): Boolean
    var
        CRMProduct: Record "CRM Product";
        OriginalCRMProduct: Record "CRM Product";
        CRMProductList: Page "CRM Product List";
    begin
        if not IsNullGuid(CRMId) then begin
            if CRMProduct.Get(CRMId) then
                CRMProductList.SetRecord(CRMProduct);
            if not IsNullGuid(SavedCRMId) then
                if OriginalCRMProduct.Get(SavedCRMId) then
                    CRMProductList.SetCurrentlyCoupledCRMProduct(OriginalCRMProduct);
        end;
        CRMProduct.SetView(IntTableFilter);
        CRMProductList.SetTableView(CRMProduct);
        CRMProductList.LookupMode(true);
        Commit();
        if CRMProductList.RunModal() = ACTION::LookupOK then begin
            CRMProductList.GetRecord(CRMProduct);
            CRMId := CRMProduct.ProductId;
            exit(true);
        end;
        exit(false);
    end;

    local procedure LookupCRMUomschedule(SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text): Boolean
    var
        CRMUomschedule: Record "CRM Uomschedule";
        OriginalCRMUomschedule: Record "CRM Uomschedule";
        CRMUnitGroupList: Page "CRM UnitGroup List";
    begin
        if not IsNullGuid(CRMId) then begin
            if CRMUomschedule.Get(CRMId) then
                CRMUnitGroupList.SetRecord(CRMUomschedule);
            if not IsNullGuid(SavedCRMId) then
                if OriginalCRMUomschedule.Get(SavedCRMId) then
                    CRMUnitGroupList.SetCurrentlyCoupledCRMUomschedule(OriginalCRMUomschedule);
        end;
        CRMUomschedule.SetView(IntTableFilter);
        CRMUnitGroupList.SetTableView(CRMUomschedule);
        CRMUnitGroupList.LookupMode(true);
        Commit();
        if CRMUnitGroupList.RunModal() = ACTION::LookupOK then begin
            CRMUnitGroupList.GetRecord(CRMUomschedule);
            CRMId := CRMUomschedule.UoMScheduleId;
            exit(true);
        end;
        exit(false);
    end;

    local procedure LookupCRMOpportunity(SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text): Boolean
    var
        CRMOpportunity: Record "CRM Opportunity";
        OriginalCRMOpportunity: Record "CRM Opportunity";
        CRMOpportunityList: Page "CRM Opportunity List";
    begin
        if not IsNullGuid(CRMId) then begin
            if CRMOpportunity.Get(CRMId) then
                CRMOpportunityList.SetRecord(CRMOpportunity);
            if not IsNullGuid(SavedCRMId) then
                if OriginalCRMOpportunity.Get(SavedCRMId) then
                    CRMOpportunityList.SetCurrentlyCoupledCRMOpportunity(OriginalCRMOpportunity);
        end;
        CRMOpportunity.SetView(IntTableFilter);
        CRMOpportunityList.SetTableView(CRMOpportunity);
        CRMOpportunityList.LookupMode(true);
        Commit();
        if CRMOpportunityList.RunModal() = ACTION::LookupOK then begin
            CRMOpportunityList.GetRecord(CRMOpportunity);
            CRMId := CRMOpportunity.OpportunityId;
            exit(true);
        end;
        exit(false);
    end;

    local procedure LookupCRMQuote(SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text): Boolean
    var
        CRMQuote: Record "CRM Quote";
        OriginalCRMQuote: Record "CRM Quote";
        CRMSalesQuoteList: Page "CRM Sales Quote List";
    begin
        if not IsNullGuid(CRMId) then begin
            if CRMQuote.Get(CRMId) then
                CRMSalesQuoteList.SetRecord(CRMQuote);
            if not IsNullGuid(SavedCRMId) then
                if OriginalCRMQuote.Get(SavedCRMId) then
                    CRMSalesQuoteList.SetCurrentlyCoupledCRMQuote(OriginalCRMQuote);
        end;
        CRMQuote.SetView(IntTableFilter);
        CRMSalesQuoteList.SetTableView(CRMQuote);
        CRMSalesQuoteList.LookupMode(true);
        Commit();
        if CRMSalesQuoteList.RunModal() = ACTION::LookupOK then begin
            CRMSalesQuoteList.GetRecord(CRMQuote);
            CRMId := CRMQuote.QuoteId;
            exit(true);
        end;
        exit(false);
    end;

    local procedure LookupCRMUom(SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text): Boolean
    var
        CRMUom: Record "CRM Uom";
        OriginalCRMUom: Record "CRM Uom";
        CRMUnitList: Page "CRM Unit List";
    begin
        if not IsNullGuid(CRMId) then begin
            if CRMUom.Get(CRMId) then
                CRMUnitList.SetRecord(CRMUom);
            if not IsNullGuid(SavedCRMId) then
                if OriginalCRMUom.Get(SavedCRMId) then
                    CRMUnitList.SetCurrentlyCoupledCRMUnit(OriginalCRMUom);
        end;
        CRMUom.SetView(IntTableFilter);
        CRMUnitList.SetTableView(CRMUom);
        CRMUnitList.LookupMode(true);
        Commit();
        if CRMUnitList.RunModal() = ACTION::LookupOK then begin
            CRMUnitList.GetRecord(CRMUom);
            CRMId := CRMUom.UoMId;
            exit(true);
        end;
        exit(false);
    end;

    local procedure LookupCRMSalesorder(SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text): Boolean
    var
        CRMSalesorder: Record "CRM Salesorder";
        OriginalCRMSalesorder: Record "CRM Salesorder";
        CRMSalesOrderList: Page "CRM Sales Order List";
    begin
        if not IsNullGuid(CRMId) then begin
            if CRMSalesorder.Get(CRMId) then
                CRMSalesOrderList.SetRecord(CRMSalesorder);
            if not IsNullGuid(SavedCRMId) then
                if OriginalCRMSalesorder.Get(SavedCRMId) then
                    CRMSalesOrderList.SetCurrentlyCoupledCRMSalesorder(OriginalCRMSalesorder);
        end;
        CRMSalesorder.SetView(IntTableFilter);
        CRMSalesOrderList.SetTableView(CRMSalesorder);
        CRMSalesOrderList.LookupMode(true);
        Commit();
        if CRMSalesOrderList.RunModal() = ACTION::LookupOK then begin
            CRMSalesOrderList.GetRecord(CRMSalesorder);
            CRMId := CRMSalesorder.SalesOrderId;
            exit(true);
        end;
        exit(false);
    end;

    local procedure LookupCRMPaymentTerm(SavedCRMId: Integer; var CRMOptionId: Integer; var CRMOptionCode: Text[250]; IntTableFilter: Text): Boolean
    var
        CRMPaymentTerms: Record "CRM Payment Terms";
        OriginalCRMPaymentTerms: Record "CRM Payment Terms";
        CRMPaymentTermsList: Page "CRM Payment Terms List";
    begin
        if CRMOptionId <> 0 then begin
            CRMPaymentTermsList.LoadRecords();
            CRMPaymentTerms := CRMPaymentTermsList.GetRec(CRMOptionId);
            if CRMPaymentTerms."Option Id" <> 0 then
                CRMPaymentTermsList.SetRecord(CRMPaymentTerms);
            if SavedCRMId <> 0 then begin
                OriginalCRMPaymentTerms := CRMPaymentTermsList.GetRec(SavedCRMId);
                if OriginalCRMPaymentTerms."Option Id" <> 0 then
                    CRMPaymentTermsList.SetCurrentlyMappedCRMPaymentTermOptionId(SavedCRMId);
            end;
        end;
        CRMPaymentTerms.SetView(IntTableFilter);
        CRMPaymentTermsList.SetTableView(CRMPaymentTerms);
        CRMPaymentTermsList.LookupMode(true);
        Commit();
        if CRMPaymentTermsList.RunModal() = ACTION::LookupOK then begin
            CRMPaymentTermsList.GetRecord(CRMPaymentTerms);
            CRMOptionId := CRMPaymentTerms."Option Id";
            CRMOptionCode := CRMPaymentTerms."Code";
            exit(true);
        end;
        exit(false);
    end;

    local procedure LookupCRMFreightTerm(SavedCRMId: Integer; var CRMOptionId: Integer; var CRMOptionCode: Text[250]; IntTableFilter: Text): Boolean
    var
        CRMFreightTerms: Record "CRM Freight Terms";
        OriginalCRMFreightTerms: Record "CRM Freight Terms";
        CRMFreightTermsList: Page "CRM Freight Terms List";
    begin
        if CRMOptionId <> 0 then begin
            CRMFreightTermsList.LoadRecords();
            CRMFreightTerms := CRMFreightTermsList.GetRec(CRMOptionId);
            if CRMFreightTerms."Option Id" <> 0 then
                CRMFreightTermsList.SetRecord(CRMFreightTerms);
            if SavedCRMId <> 0 then begin
                OriginalCRMFreightTerms := CRMFreightTermsList.GetRec(SavedCRMId);
                if OriginalCRMFreightTerms."Option Id" <> 0 then
                    CRMFreightTermsList.SetCurrentlyMappedCRMFreightTermOptionId(SavedCRMId);
            end;
        end;
        CRMFreightTerms.SetView(IntTableFilter);
        CRMFreightTermsList.SetTableView(CRMFreightTerms);
        CRMFreightTermsList.LookupMode(true);
        Commit();
        if CRMFreightTermsList.RunModal() = ACTION::LookupOK then begin
            CRMFreightTermsList.GetRecord(CRMFreightTerms);
            CRMOptionId := CRMFreightTerms."Option Id";
            CRMOptionCode := CRMFreightTerms."Code";
            exit(true);
        end;
        exit(false);
    end;

    local procedure LookupCRMShippingMethod(SavedCRMId: Integer; var CRMOptionId: Integer; var CRMOptionCode: Text[250]; IntTableFilter: Text): Boolean
    var
        CRMShippingMethod: Record "CRM Shipping Method";
        OriginalCRMShippingMethod: Record "CRM Shipping Method";
        CRMShippingMethodList: Page "CRM Shipping Method List";
    begin
        if CRMOptionId <> 0 then begin
            CRMShippingMethodList.LoadRecords();
            CRMShippingMethod := CRMShippingMethodList.GetRec(CRMOptionId);
            if CRMShippingMethod."Option Id" <> 0 then
                CRMShippingMethodList.SetRecord(CRMShippingMethod);
            if SavedCRMId <> 0 then begin
                OriginalCRMShippingMethod := CRMShippingMethodList.GetRec(SavedCRMId);
                if OriginalCRMShippingMethod."Option Id" <> 0 then
                    CRMShippingMethodList.SetCurrentlyMappedCRMPShippingMethodOptionId(SavedCRMId);
            end;
        end;
        CRMShippingMethod.SetView(IntTableFilter);
        CRMShippingMethodList.SetTableView(CRMShippingMethod);
        CRMShippingMethodList.LookupMode(true);
        Commit();
        if CRMShippingMethodList.RunModal() = ACTION::LookupOK then begin
            CRMShippingMethodList.GetRecord(CRMShippingMethod);
            CRMOptionId := CRMShippingMethod."Option Id";
            CRMOptionCode := CRMShippingMethod."Code";
            exit(true);
        end;
        exit(false);
    end;

    procedure GetIntegrationTableFilter(CRMTableId: Integer; NAVTableId: Integer): Text
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Synch. Codeunit ID", CODEUNIT::"CRM Integration Table Synch.");
        IntegrationTableMapping.SetRange("Table ID", NAVTableId);
        IntegrationTableMapping.SetRange("Integration Table ID", CRMTableId);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        if IntegrationTableMapping.FindFirst() then
            exit(IntegrationTableMapping.GetIntegrationTableFilter());
        exit('');
    end;

    procedure GetIntegrationTableMappingView(TableId: Integer): Text
    var
        "Field": Record "Field";
        IntegrationTableMapping: Record "Integration Table Mapping";
        RecRef: array[2] of RecordRef;
        FieldRef: array[2] of FieldRef;
        FieldFilter: array[2] of Text;
        NoFilter: Dictionary of [Integer, Boolean];
    begin
        RecRef[1].Open(TableId);
        RecRef[2].Open(TableId);

        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Synch. Codeunit ID", CODEUNIT::"CRM Integration Table Synch.");
        IntegrationTableMapping.SetRange("Integration Table ID", TableId);
        IntegrationTableMapping.SetRange("Delete After Synchronization", false);
        IntegrationTableMapping.SetRange("Int. Table UID Field Type", Field.Type::GUID);
        if IntegrationTableMapping.FindSet() then
            repeat
                FieldFilter[2] := IntegrationTableMapping.GetIntegrationTableFilter();
                if FieldFilter[2] <> '' then begin
                    RecRef[2].SetView(FieldFilter[2]);

                    Field.SetRange(TableNo, TableId);
                    Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
                    if Field.FindSet() then
                        repeat
                            if not NoFilter.ContainsKey(Field."No.") then begin
                                FieldRef[1] := RecRef[1].Field(Field."No.");
                                FieldRef[2] := RecRef[2].Field(Field."No.");

                                FieldFilter[1] := FieldRef[1].GetFilter;
                                FieldFilter[2] := FieldRef[2].GetFilter;

                                if FieldFilter[2] <> '' then
                                    if FieldFilter[1] = '' then
                                        FieldRef[1].SetFilter(FieldFilter[2])
                                    else
                                        FieldRef[1].SetFilter(StrSubstNo('%1|%2', FieldFilter[1], FieldFilter[2]))
                                else begin
                                    NoFilter.Add(Field."No.", true);
                                    FieldRef[1].SetFilter('');
                                end;
                            end;
                        until Field.Next() = 0;
                end;
            until IntegrationTableMapping.Next() = 0;

        exit(RecRef[1].GetView(false));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupCRMTables(CRMTableID: Integer; NAVTableId: Integer; SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupCRMOption(CRMTableID: Integer; NAVTableId: Integer; SavedCRMOptionId: Integer; var CRMOptionId: Integer; var CRMOptionCode: Text[250]; IntTableFilter: Text; var Handled: Boolean)
    begin
    end;
}

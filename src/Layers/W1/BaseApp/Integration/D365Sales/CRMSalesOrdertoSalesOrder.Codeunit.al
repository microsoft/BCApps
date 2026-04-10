// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Assembly.Document;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.Utilities;

codeunit 5343 "CRM Sales Order to Sales Order"
{
    TableNo = "CRM Salesorder";

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateInNAV(Rec, SalesHeader);
    end;

    var
        CRMSynchHelper: Codeunit "CRM Synch. Helper";
        CRMProductName: Codeunit "CRM Product Name";
        LastSalesLineNo: Integer;

        CannotCreateSalesOrderInNAVTxt: Label 'The sales order cannot be created.';
        NoCRMAccountForOrderErr: Label 'Sales order %1 is created for %2 %3, which doesn''t correspond to an account in %4.', Comment = '%1=Dataverse Sales Order Name, %2 - customer id type, %3 customer id, %4 - Dataverse service name';
        ItemDoesNotExistErr: Label '%1 The item %2 does not exist.', Comment = '%1= the text: "The sales order cannot be created.", %2=product name';
        ItemUnitOfMeasureDoesNotExistErr: Label '%1 The item unit of measure %2 does not exist.', Comment = '%1= the text: "The sales order cannot be created.", %2=item unit of measure name';
        ResourceUnitOfMeasureDoesNotExistErr: Label '%1 The resource unit of measure %2 does not exist.', Comment = '%1= the text: "The sales order cannot be created.", %2=resource unit of measure name';
        NoCustomerErr: Label '%1 There is no potential customer defined on the %3 sales order %2.', Comment = '%1= the text: "The sales order cannot be created.", %2=sales order title, %3 - Dataverse service name';
        NotCoupledCustomerErr: Label '%1 There is no customer coupled to %3 account %2.', Comment = '%1= the text: "The sales order cannot be created.", %2=account name, %3 - Dataverse service name';
        NotCoupledCRMProductErr: Label '%1 The %3 product %2 is not coupled to an item.', Comment = '%1= the text: "The sales order cannot be created.", %2=product name, %3 - Dataverse service name';
        NotCoupledCRMResourceErr: Label '%1 The %3 resource %2 is not coupled to a resource.', Comment = '%1= the text: "The sales order cannot be created.", %2=resource name, %3 - Dataverse service name';
        NotCoupledCRMSalesOrderErr: Label 'The %2 sales order %1 is not coupled.', Comment = '%1=sales order number, %2 - Dataverse service name';
        NotCoupledSalesHeaderErr: Label 'The sales order %1 is not coupled to %2.', Comment = '%1=sales order number, %2 - Dataverse service name';
        NotCoupledCRMUomErr: Label '%1 The %3 unit %2 is not coupled to a unit of measure.', Comment = '%1= the text: "The sales order cannot be created.", %2=unit name, %3 - Dataverse service name';
        AccountNotCustomerErr: Label '%1 The selected type of the %2 %3 account is not customer.', Comment = '%1= the text: "The sales order cannot be created.", %2=account name, %3=Dataverse service name';
        AccountNotCustomerTelemetryMsg: Label '%1 The selected type of the %2 %3 account is not customer.', Locked = true;
        OverwriteCRMDiscountQst: Label 'There is a discount on the %2 sales order, which will be overwritten by %1 settings. You will have the possibility to update the discounts directly on the sales order, after it is created. Do you want to continue?', Comment = '%1 - product name, %2 - Dataverse service name';
        ResourceDoesNotExistErr: Label '%1 The resource %2 does not exist.', Comment = '%1= the text: "The sales order cannot be created.", %2=product name';
        UnexpectedProductTypeErr: Label '%1 Unexpected value of product type code for product %2. The supported values are: sales inventory, services.', Comment = '%1= the text: "The sales order cannot be created.", %2=product name';
        ZombieCouplingErr: Label 'Although the coupling from %2 exists, the sales order had been manually deleted. If needed, please use the menu to create it again in %1.', Comment = '%1 - product name, %2 - Dataverse service name';
        MissingWriteInProductNoErr: Label '%1 %2 %3 contains a write-in product. You must choose the default write-in product in Sales & Receivables Setup window.', Comment = '%1 - Dataverse service name,%2 - document type (order or quote), %3 - document number';
        MisingWriteInProductTelemetryMsg: Label 'The user is missing a default write-in product when creating a sales order from a %1 order.', Locked = true;
        CrmTelemetryCategoryTok: Label 'AL CRM Integration', Locked = true;
        SuccessfullyCoupledSalesOrderTelemetryMsg: Label 'Successfully coupled sales order %2 to %1 order %3.', Locked = true;
        SuccessfullyCreatedSalesOrderHeaderTelemetryMsg: Label 'Successfully created order header %2 from %1 order %3.', Locked = true;
        SuccessfullyCreatedSalesOrderNotesTelemetryMsg: Label 'Successfully created notes for sales order %2 from %1 order %3.', Locked = true;
        SuccessfullyCreatedSalesOrderLinesTelemetryMsg: Label 'Successfully created lines for sales order %2 from %1 order %3.', Locked = true;
        SuccessfullyAppliedSalesOrderDiscountsTelemetryMsg: Label 'Successfully applied discounts from %1 order %3 to sales order %2.', Locked = true;
        SuccessfullySetLastBackOfficeSubmitTelemetryMsg: Label 'Successfully set lastbackofficesubmit on %1 order %2 to the following date: %3.', Locked = true;
        StartingToCreateSalesOrderHeaderTelemetryMsg: Label 'Starting to create order header from %1 order %2.', Locked = true;
        StartingToCreateSalesOrderLinesTelemetryMsg: Label 'Starting to create order lines from %1 order %2.', Locked = true;
        StartingToCreateSalesOrderNotesTelemetryMsg: Label 'Starting to create order lines from %1 order %2.', Locked = true;
        StartingToApplySalesOrderDiscountsTelemetryMsg: Label 'Starting to appliy discounts from %1 order %3 to sales order %2.', Locked = true;
        StartingToSetLastBackOfficeSubmitTelemetryMsg: Label 'Starting to set lastbackofficesubmit on %1 order %2 to the following date: %3.', Locked = true;
        SkippingCreateSalesOrderHeaderConnectionDisabledMsg: Label 'Skipping creation of order header from %1 order %2. The %1 integration is not enabled.', Locked = true;
        NoLinesFoundInSalesOrderTelemetryMsg: Label 'No lines found in %1 order %2.', Locked = true;
        NoNotesFoundInSalesOrderTelemetryMsg: Label 'No notes found in %1 order %2.', Locked = true;
        StartingToUncoupleSalesOrderTelemetryMsg: Label 'Starting to uncouple sales order %2 from %1 order %3.', Locked = true;
        SuccessfullyUncoupledSalesOrderTelemetryMsg: Label 'Successfully uncoupled sales order %2 from %1 order %3.', Locked = true;
        FailedToUncoupleSalesOrderTelemetryMsg: Label 'Failed to uncouple sales order %2 from %1 order %3.', Locked = true;
        CRMSalesOrderNotFoundTxt: Label '%1 sales order %2 is not found.', Locked = true;
        SuccessfullyResetLastBackofficeSubmitOnCRMSalesOrderTxt: Label 'Successfully reset last backoffice submit time on %1 sales order %2.', Locked = true;
        FailedToResetLastBackofficeSubmitOnCRMSalesOrderTxt: Label 'Failed to reset last backoffice submit time on %1 sales order %2.', Locked = true;
        SalesOrderAlreadyCoupledToSalesOrderTxt: Label 'This %1 order is already coupled to sales order %2.', Comment = '%1 - Dataverse service name, %2 - sales order number.';
        SalesOrderAlreadyCoupledToPostedSalesInvoiceTxt: Label 'This %1 order is already coupled, posted and turned into posted sales invoice %2.', Comment = '%1 - Dataverse service name, %2 - posted sales invoice number.';
        SalesOrderAlreadyCoupledToSalesOrderTelemetryTxt: Label '%1 order %2 is already coupled to sales order %3.', Locked = true;
        SalesOrderAlreadyCoupledToPostedSalesInvoiceTelemetryTxt: Label '%1 order %2 is already coupled, posted and turned into posted sales invoice %3.', Locked = true;

    local procedure ApplySalesOrderDiscounts(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header")
    var
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        CRMDiscountAmount: Decimal;
    begin
        // No discounts to apply
        if (CRMSalesorder.DiscountAmount = 0) and (CRMSalesorder.DiscountPercentage = 0) then
            exit;

        Session.LogMessage('0000DEV', StrSubstNo(StartingToApplySalesOrderDiscountsTelemetryMsg, CRMProductName.CDSServiceName(), SalesHeader.SystemId, CRMSalesorder.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);

        // Attempt to set the discount, if NAV general and customer settings allow it
        // Using CRM discounts
        CRMDiscountAmount := CRMSalesorder.TotalLineItemAmount - CRMSalesorder.TotalAmountLessFreight;
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(CRMDiscountAmount, SalesHeader);

        // NAV settings (in G/L Setup as well as per-customer discounts) did not allow using the CRM discounts
        // Using NAV discounts
        // But the user will be able to manually update the discounts after the order is created in NAV
        if GuiAllowed() then
            if not HideSalesOrderDiscountsDialog() then
                if not Confirm(StrSubstNo(OverwriteCRMDiscountQst, PRODUCTNAME.Short(), CRMProductName.CDSServiceName()), true) then
                    Error('');

        Session.LogMessage('0000DEW', StrSubstNo(SuccessfullyAppliedSalesOrderDiscountsTelemetryMsg, CRMProductName.CDSServiceName(), SalesHeader.SystemId, CRMSalesorder.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
    end;

    local procedure HideSalesOrderDiscountsDialog() Hide: Boolean;
    begin
        OnHideSalesOrderDiscountsDialog(Hide);
    end;

    local procedure CopyCRMOptionFields(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header")
    var
        CRMAccount: Record "CRM Account";
        CRMOptionMapping: Record "CRM Option Mapping";
    begin
        if CRMOptionMapping.FindRecordID(
             DATABASE::"CRM Account", CRMAccount.FieldNo(Address1_ShippingMethodCodeEnum), CRMSalesorder.ShippingMethodCodeEnum.AsInteger())
        then
            SalesHeader.Validate(
              "Shipping Agent Code",
              CopyStr(CRMOptionMapping.GetRecordKeyValue(), 1, MaxStrLen(SalesHeader."Shipping Agent Code")));

        if CRMOptionMapping.FindRecordID(
             DATABASE::"CRM Account", CRMAccount.FieldNo(PaymentTermsCodeEnum), CRMSalesorder.PaymentTermsCodeEnum.AsInteger())
        then
            SalesHeader.Validate(
              "Payment Terms Code",
              CopyStr(CRMOptionMapping.GetRecordKeyValue(), 1, MaxStrLen(SalesHeader."Payment Terms Code")));

        if CRMOptionMapping.FindRecordID(
             DATABASE::"CRM Account", CRMAccount.FieldNo(Address1_FreightTermsCodeEnum), CRMSalesorder.FreightTermsCodeEnum.AsInteger())
        then
            SalesHeader.Validate(
              "Shipment Method Code",
              CopyStr(CRMOptionMapping.GetRecordKeyValue(), 1, MaxStrLen(SalesHeader."Shipment Method Code")));
    end;

    local procedure CopyBillToInformationIfNotEmpty(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyBillToInformationIfNotEmpty(CRMSalesorder, SalesHeader, IsHandled);
        if IsHandled then
            exit;

        // If the Bill-To fields in CRM are all empty, then let NAV keep its standard behavior (takes Bill-To from the Customer information)
        if ((CRMSalesorder.BillTo_Line1 = '') and
            (CRMSalesorder.BillTo_Line2 = '') and
            (CRMSalesorder.BillTo_City = '') and
            (CRMSalesorder.BillTo_PostalCode = '') and
            (CRMSalesorder.BillTo_Country = '') and
            (CRMSalesorder.BillTo_StateOrProvince = ''))
        then
            exit;

        SalesHeader.Validate("Bill-to Address", CopyStr(CRMSalesorder.BillTo_Line1, 1, MaxStrLen(SalesHeader."Bill-to Address")));
        SalesHeader.Validate("Bill-to Address 2", CopyStr(CRMSalesorder.BillTo_Line2, 1, MaxStrLen(SalesHeader."Bill-to Address 2")));
        SalesHeader.Validate("Bill-to Post Code", CopyStr(CRMSalesorder.BillTo_PostalCode, 1, MaxStrLen(SalesHeader."Bill-to Post Code")));
        SalesHeader.Validate("Bill-to City", CopyStr(CRMSalesorder.BillTo_City, 1, MaxStrLen(SalesHeader."Bill-to City")));
        IsHandled := false;
        OnCopyBillToInformationIfNotEmptyOnBeforeValidateBillToCountryRegionCode(SalesHeader, CRMSalesorder, IsHandled);
        if not IsHandled then
            SalesHeader.Validate(
              "Bill-to Country/Region Code", CopyStr(CRMSalesorder.BillTo_Country, 1, MaxStrLen(SalesHeader."Bill-to Country/Region Code")));
        SalesHeader.Validate("Bill-to County", CopyStr(CRMSalesorder.BillTo_StateOrProvince, 1, MaxStrLen(SalesHeader."Bill-to County")));
    end;

    local procedure CopyShipToInformationIfNotEmpty(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        // If the Ship-To fields in CRM are all empty, then let NAV keep its standard behavior (takes Bill-To from the Customer information)
        if ((CRMSalesorder.ShipTo_Line1 = '') and
            (CRMSalesorder.ShipTo_Line2 = '') and
            (CRMSalesorder.ShipTo_City = '') and
            (CRMSalesorder.ShipTo_PostalCode = '') and
            (CRMSalesorder.ShipTo_Country = '') and
            (CRMSalesorder.ShipTo_StateOrProvince = ''))
        then
            exit;

        SalesHeader.Validate("Ship-to Address", CopyStr(CRMSalesorder.ShipTo_Line1, 1, MaxStrLen(SalesHeader."Ship-to Address")));
        SalesHeader.Validate("Ship-to Address 2", CopyStr(CRMSalesorder.ShipTo_Line2, 1, MaxStrLen(SalesHeader."Ship-to Address 2")));
        SalesHeader.Validate("Ship-to Post Code", CopyStr(CRMSalesorder.ShipTo_PostalCode, 1, MaxStrLen(SalesHeader."Ship-to Post Code")));
        SalesHeader.Validate("Ship-to City", CopyStr(CRMSalesorder.ShipTo_City, 1, MaxStrLen(SalesHeader."Ship-to City")));
        IsHandled := false;
        OnCopyShipToInformationIfNotEmptyOnBeforeValidateShipToCountryRegionCode(SalesHeader, CRMSalesorder, IsHandled);
        if not IsHandled then
            SalesHeader.Validate(
              "Ship-to Country/Region Code", CopyStr(CRMSalesorder.ShipTo_Country, 1, MaxStrLen(SalesHeader."Ship-to Country/Region Code")));
        SalesHeader.Validate("Ship-to County", CopyStr(CRMSalesorder.ShipTo_StateOrProvince, 1, MaxStrLen(SalesHeader."Ship-to County")));
        OnAfterCopyShipToInformationIfNotEmpty(CRMSalesorder, SalesHeader);
    end;

    local procedure SetLineDescription(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var CRMSalesorderdetail: Record "CRM Salesorderdetail")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LineDescriptionInStream: InStream;
        CRMSalesOrderLineDescription: Text;
        ExtendedDescription: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetLineDescription(SalesHeader, SalesLine, CRMSalesorderdetail, IsHandled);
        if IsHandled then
            exit;

        CRMSalesorderdetail.CalcFields(Description);
        CRMSalesorderdetail.Description.CreateInStream(LineDescriptionInStream, TEXTENCODING::UTF16);
        LineDescriptionInStream.ReadText(CRMSalesOrderLineDescription);

        if CRMSalesOrderLineDescription = '' then
            CRMSalesOrderLineDescription := CRMSalesorderdetail.ProductDescription;

        ExtendedDescription := CRMSalesOrderLineDescription;

        // in case of write-in product - write the description directly in the main sales line description
        if SalesReceivablesSetup.Get() then
            if SalesLine."No." = SalesReceivablesSetup."Write-in Product No." then begin
                SalesLine.Description := CopyStr(CRMSalesOrderLineDescription, 1, MaxStrLen(SalesLine.Description));
                if StrLen(CRMSalesOrderLineDescription) > MaxStrLen(SalesLine.Description) then
                    ExtendedDescription := CopyStr(CRMSalesOrderLineDescription, MaxStrLen(SalesLine.Description) + 1)
                else
                    ExtendedDescription := '';
            end;

        if ExtendedDescription = SalesLine.Description then
            exit;

        // in case of inventory item - write the item name in the main line and create extended lines with the extended description
        CreateExtendedDescriptionOrderLines(SalesHeader, ExtendedDescription, SalesLine."Line No.");

        // in case of line descriptions with multple lines, add all lines of the line descirption
        while not LineDescriptionInStream.EOS() do begin
            LineDescriptionInStream.ReadText(ExtendedDescription);
            CreateExtendedDescriptionOrderLines(SalesHeader, ExtendedDescription, SalesLine."Line No.");
        end;
    end;

    local procedure CoupledSalesHeaderExists(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header"): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        NAVSalesHeaderRecordId: RecordID;
    begin
        if not IsNullGuid(CRMSalesorder.SalesOrderId) then
            if CRMIntegrationRecord.FindRecordIDFromID(CRMSalesorder.SalesOrderId, DATABASE::"Sales Header", NAVSalesHeaderRecordId) then
                exit(SalesHeader.Get(NAVSalesHeaderRecordId));

        exit(false);
    end;

    local procedure ReferencedSalesInvoiceHeaderExists(CRMSalesorder: Record "CRM Salesorder"; var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    begin
        if not IsNullGuid(CRMSalesorder.SalesOrderId) then begin
            SalesInvoiceHeader.SetRange("Your Reference", CopyStr(CRMSalesorder.OrderNumber, 1, MaxStrLen(SalesInvoiceHeader."Your Reference")));
            exit(SalesInvoiceHeader.FindFirst())
        end;

        exit(false);
    end;

    procedure CreateInNAV(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header"): Boolean
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        IsHandled: Boolean;
    begin
        if not CRMConnectionSetup.IsEnabled() then begin
            Session.LogMessage('0000EU9', StrSubstNo(SkippingCreateSalesOrderHeaderConnectionDisabledMsg, CRMProductName.SHORT(), CRMSalesorder.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
            exit;
        end;

        IsHandled := false;
        OnCreateInNAVOnBeforeCheckState(CRMSalesorder, IsHandled);
        if not IsHandled then
            CRMSalesorder.TestField(StateCode, CRMSalesorder.StateCode::Submitted);
        exit(CreateNAVSalesOrder(CRMSalesorder, SalesHeader));
    end;

    local procedure CreateNAVSalesOrder(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header"): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if IsNullGuid(CRMSalesorder.SalesOrderId) then
            exit;

        // the order can already be coupled as a result of processing the Won quote from which the order was created in Dynamics 365 sales
        // in this case, we don't need to create one more order - it is already coupled
        if not CRMIntegrationRecord.FindByCRMID(CRMSalesorder.SalesOrderId) then begin
            CreateSalesOrderHeader(CRMSalesorder, SalesHeader);
            CRMIntegrationRecord.CoupleRecordIdToCRMID(SalesHeader.RecordId, CRMSalesorder.SalesOrderId);
            CreateSalesOrderNotes(CRMSalesorder, SalesHeader);
            CreateSalesOrderLines(CRMSalesorder, SalesHeader);
            ApplySalesOrderDiscounts(CRMSalesorder, SalesHeader);

            SetCompanyId(CrmSalesOrder);
            SetLastBackOfficeSubmit(CRMSalesorder, Today);
            OnCreateNAVSalesOrderOnAfterSetLastBackOfficeSubmit(SalesHeader, CRMSalesorder);
            Session.LogMessage('000083B', StrSubstNo(SuccessfullyCoupledSalesOrderTelemetryMsg, CRMProductName.CDSServiceName(), SalesHeader.SystemId, CRMSalesorder.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
        end else begin
            if CoupledSalesHeaderExists(CRMSalesorder, SalesHeader) then begin
                if GuiAllowed() then
                    Message(StrSubstNo(SalesOrderAlreadyCoupledToSalesOrderTxt, CRMProductName.CDSServiceName(), SalesHeader."No."));
                Session.LogMessage('0000EDU', StrSubstNo(SalesOrderAlreadyCoupledToSalesOrderTelemetryTxt, CRMProductName.CDSServiceName(), CRMSalesorder.SalesOrderId, SalesHeader."No."), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
                exit(true);
            end;

            if ReferencedSalesInvoiceHeaderExists(CRMSalesorder, SalesInvoiceHeader) then begin
                if GuiAllowed() then
                    Message(StrSubstNo(SalesOrderAlreadyCoupledToPostedSalesInvoiceTxt, CRMProductName.CDSServiceName(), SalesInvoiceHeader."No."));
                Session.LogMessage('0000EDV', StrSubstNo(SalesOrderAlreadyCoupledToPostedSalesInvoiceTelemetryTxt, CRMProductName.CDSServiceName(), CRMSalesorder.SalesOrderId, SalesInvoiceHeader."No."), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
                exit(true);
            end
        end;

        OnAfterCreateNAVSalesOrder(CRMSalesorder, SalesHeader, SalesInvoiceHeader);
        exit(true);
    end;

    local procedure SetCompanyId(var CRMSalesorder: Record "CRM Salesorder")
    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        CDSIntTableSubscriber: Codeunit "CDS Int. Table. Subscriber";
        DestinationRecordRef: RecordRef;
    begin
        if CDSIntegrationImpl.IsIntegrationEnabled() then begin
            DestinationRecordRef.GetTable(CRMSalesorder);
            CRMSalesorder.StateCode := CRMSalesorder.StateCode::Active;
            CRMSalesorder.Modify();
            CDSIntTableSubscriber.SetCompanyId(DestinationRecordRef);
            DestinationRecordRef.Modify();
            CRMSalesorder.StateCode := CRMSalesorder.StateCode::Submitted;
            CRMSalesorder.Modify();
        end;
    end;

    [TryFunction]
    local procedure TryResetLastBackofficeSubmitOnCRMSalesOrder(CRMSalesOrderId: Guid)
    var
        CRMSalesorder: Record "CRM Salesorder";
    begin
        CRMSalesOrder.SetAutoCalcFields(CreatedByName, ModifiedByName, TransactionCurrencyIdName);
        if not CRMSalesOrder.Get(CRMSalesOrderId) then begin
            Session.LogMessage('0000ER9', StrSubstNo(CRMSalesOrderNotFoundTxt, CRMProductName.CDSServiceName(), CRMSalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
            exit;
        end;
        CRMSalesorder.StateCode := CRMSalesOrder.StateCode::Active;
        CRMSalesorder.StatusCode := CRMSalesorder.StatusCode::Pending;
        CRMSalesOrder.Modify();
        CRMSalesOrder.LastBackofficeSubmit := 0D;
        CRMSalesOrder.Modify();
        if CRMSalesOrder.LastBackofficeSubmit = 0D then
            Session.LogMessage('0000ERA', StrSubstNo(SuccessfullyResetLastBackofficeSubmitOnCRMSalesOrderTxt, CRMProductName.CDSServiceName(), CRMSalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok)
        else
            Session.LogMessage('0000ERC', StrSubstNo(FailedToResetLastBackofficeSubmitOnCRMSalesOrderTxt, CRMProductName.CDSServiceName(), CRMSalesOrderId), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure RemoveCouplingToCRMSalesOrderOnSalesHeaderDelete(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMSalesOrderId: Guid;
    begin
        if Rec.IsTemporary then
            exit;

        // RunTrigger is expected to be false when deleting Sales Header after posting.
        // In this case, we should not change CRM Salesorder state here.
        if not RunTrigger then
            exit;

        if not (Rec."Document Type" = Rec."Document Type"::Order) then
            exit;

        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit;

        if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
            exit;

        if not CRMIntegrationRecord.FindIDFromRecordID(Rec.RecordId, CRMSalesOrderId) then
            exit;

        Session.LogMessage('0000DEX', StrSubstNo(StartingToUncoupleSalesOrderTelemetryMsg, CRMProductName.CDSServiceName(), Rec.SystemId, CRMSalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);

        if not CRMIntegrationManagement.IsWorkingConnection() then begin
            Session.LogMessage('0000DI9', StrSubstNo(FailedToUncoupleSalesOrderTelemetryMsg, CRMProductName.CDSServiceName(), Rec.SystemId, CRMSalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
            exit;
        end;

        if CRMIntegrationManagement.RemoveCoupling(Rec.RecordId(), false) then begin
            Session.LogMessage('0000DEY', StrSubstNo(SuccessfullyUncoupledSalesOrderTelemetryMsg, CRMProductName.CDSServiceName(), Rec.SystemId, CRMSalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
            if not TryResetLastBackofficeSubmitOnCRMSalesOrder(CRMSalesOrderId) then
                Session.LogMessage('0000ERB', StrSubstNo(FailedToResetLastBackofficeSubmitOnCRMSalesOrderTxt, CRMProductName.CDSServiceName(), CRMSalesOrderId), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
        end else
            Session.LogMessage('0000DEZ', StrSubstNo(FailedToUncoupleSalesOrderTelemetryMsg, CRMProductName.CDSServiceName(), Rec.SystemId, CRMSalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Assemble-to-Order Link", 'OnBeforeSalesLineCheckAvailShowWarning', '', false, false)]
    local procedure OnBeforeSalesLineCheckAvailShowWarning(SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    var
        SalesHeader: Record "Sales Header";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if SalesLine."Document Type" <> SalesLine."Document Type"::Order then
            exit;

        if SalesLine.Type <> SalesLine.Type::Item then
            exit;

        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit;

        if not SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then
            exit;

        if not CRMIntegrationRecord.IsRecordCoupled(SalesHeader.RecordId()) then
            exit;

        IsHandled := true;
    end;

    local procedure CreateSalesOrderHeader(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        QuoteSalesHeader: Record "Sales header";
        CRMQuote: Record "CRM Quote";
        ArchiveManagement: Codeunit ArchiveManagement;
        IntegrationRecordSynch: Codeunit "Integration Record Synch.";
        SourceRecordRef: RecordRef;
        DestinationRecordRef: RecordRef;
        SourceFieldRef: FieldRef;
        DestinationFieldRef: FieldRef;
        IsHandled: Boolean;
    begin
        Session.LogMessage('0000DF0', StrSubstNo(StartingToCreateSalesOrderHeaderTelemetryMsg, CRMProductName.CDSServiceName(), CRMSalesorder.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Validate(Status, SalesHeader.Status::Open);
        SalesHeader.InitInsert();
        GetCoupledCustomer(CRMSalesorder, Customer);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Validate("Sell-to Contact No.");
        SalesHeader.Validate("Your Reference", CopyStr(CRMSalesorder.OrderNumber, 1, MaxStrLen(SalesHeader."Your Reference")));
        SalesHeader.Validate("Currency Code", CRMSynchHelper.GetNavCurrencyCode(CRMSalesorder.TransactionCurrencyId));
        SalesHeader.Validate("Requested Delivery Date", CRMSalesorder.RequestDeliveryBy);
        CopyBillToInformationIfNotEmpty(CRMSalesorder, SalesHeader);
        CopyShipToInformationIfNotEmpty(CRMSalesorder, SalesHeader);
        CopyCRMOptionFields(CRMSalesorder, SalesHeader);
        OnSetSalesHeaderPaymentDiscountFromCRM(SalesHeader, CRMSalesOrder, IsHandled);
        if not IsHandled then
            SalesHeader.Validate("Payment Discount %", CRMSalesorder.DiscountPercentage);
        SalesHeader.Validate("External Document No.", CopyStr(CRMSalesorder.Name, 1, MaxStrLen(SalesHeader."External Document No.")));
        SourceRecordRef.GetTable(CRMSalesorder);
        DestinationRecordRef.GetTable(SalesHeader);
        SourceFieldRef := SourceRecordRef.Field(CRMSalesorder.FieldNo(Description));
        DestinationFieldRef := DestinationRecordRef.Field(SalesHeader.FieldNo("Work Description"));
        IntegrationRecordSynch.SetTextValue(DestinationFieldRef, IntegrationRecordSynch.GetTextValue(SourceFieldRef));
        DestinationRecordRef.SetTable(SalesHeader);

        // if this order was made out of a won quote, and that won quote is coupled, set the Quote No. on the Sales header too
        if not IsNullGuid(CRMSalesorder.QuoteId) then
            if CRMQuote.Get(CRMSalesOrder.QuoteId) then begin
                QuoteSalesHeader.SetRange("Your Reference", CRMQuote.QuoteNumber);
                if QuoteSalesHeader.FindLast() then begin
                    SalesHeader."Quote No." := QuoteSalesHeader."No.";
                    ArchiveManagement.ArchSalesDocumentNoConfirm(QuoteSalesHeader);
                end;
            end;

        OnCreateSalesOrderHeaderOnBeforeSalesHeaderInsert(SalesHeader, CRMSalesorder);
        SalesHeader.Insert();
        Session.LogMessage('0000DF1', StrSubstNo(SuccessfullyCreatedSalesOrderHeaderTelemetryMsg, CRMProductName.CDSServiceName(), SalesHeader.SystemId, CRMSalesorder.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
    end;

    local procedure CreateSalesOrderNotes(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header")
    var
        CRMAnnotation: Record "CRM Annotation";
        RecordLink: Record "Record Link";
        CRMAnnotationCoupling: Record "CRM Annotation Coupling";
    begin
        Session.LogMessage('0000DF2', StrSubstNo(StartingToCreateSalesOrderNotesTelemetryMsg, CRMProductName.CDSServiceName(), CRMSalesorder.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
        CRMAnnotation.SetRange(ObjectId, CRMSalesorder.SalesOrderId);
        CRMAnnotation.SetRange(IsDocument, false);
        CRMAnnotation.SetRange(FileSize, 0);
        if CRMAnnotation.FindSet() then begin
            repeat
                CreateNote(SalesHeader, CRMAnnotation, RecordLink);
                CRMAnnotationCoupling.CoupleRecordLinkToCRMAnnotation(RecordLink, CRMAnnotation);
            until CRMAnnotation.Next() = 0;
            Session.LogMessage('0000DF3', StrSubstNo(SuccessfullyCreatedSalesOrderNotesTelemetryMsg, CRMProductName.CDSServiceName(), SalesHeader.SystemId, CRMSalesorder.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok)
        end else
            Session.LogMessage('0000DF4', StrSubstNo(NoNotesFoundInSalesOrderTelemetryMsg, CRMProductName.CDSServiceName(), CRMSalesorder.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
    end;

    [Scope('OnPrem')]
    procedure CreateNote(SalesHeader: Record "Sales Header"; CRMAnnotation: Record "CRM Annotation"; var RecordLink: Record "Record Link")
    var
        CRMAnnotationCoupling: Record "CRM Annotation Coupling";
        RecordLinkManagement: Codeunit "Record Link Management";
        InStream: InStream;
        AnnotationText: Text;
    begin
        Clear(RecordLink);
        RecordLink."Record ID" := SalesHeader.RecordId;
        RecordLink.Type := RecordLink.Type::Note;
        RecordLink.Description := CRMAnnotation.Subject;
        CRMAnnotation.CalcFields(NoteText);
        CRMAnnotation.NoteText.CreateInStream(InStream, TEXTENCODING::UTF16);
        InStream.Read(AnnotationText);
        AnnotationText := CRMAnnotationCoupling.ExtractNoteText(AnnotationText);
        RecordLinkManagement.WriteNote(RecordLink, AnnotationText);
        RecordLink.Created := CRMAnnotation.CreatedOn;
        RecordLink.Company := CompanyName;
        RecordLink.Insert();
    end;

    local procedure CreateSalesOrderLines(CRMSalesorder: Record "CRM Salesorder"; SalesHeader: Record "Sales Header")
    var
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        SalesLine: Record "Sales Line";
    begin
        Session.LogMessage('0000DF5', StrSubstNo(StartingToCreateSalesOrderLinesTelemetryMsg, CRMProductName.CDSServiceName(), CRMSalesorder.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);

        // If any of the products on the lines are not found in NAV, err
        CRMSalesorderdetail.SetRange(SalesOrderId, CRMSalesorder.SalesOrderId); // Get all sales order lines
        CRMSalesorderdetail.SetCurrentKey(SequenceNumber);
        CRMSalesorderdetail.Ascending(true);

        if CRMSalesorderdetail.FindSet() then begin
            repeat
                InitializeSalesOrderLine(CRMSalesorderdetail, SalesHeader, SalesLine);
                OnCreateSalesOrderLinesOnBeforeSalesLineInsert(SalesLine, CRMSalesorderdetail);
                SalesLine.Insert(true);
                if SalesLine."Qty. to Assemble to Order" <> 0 then
                    SalesLine.Validate("Qty. to Assemble to Order");
            until CRMSalesorderdetail.Next() = 0;
            Session.LogMessage('0000DF6', StrSubstNo(SuccessfullyCreatedSalesOrderLinesTelemetryMsg, CRMProductName.CDSServiceName(), SalesHeader.SystemId, CRMSalesorder.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
        end else begin
            SalesLine.Validate("Document Type", SalesHeader."Document Type");
            SalesLine.Validate("Document No.", SalesHeader."No.");
            Session.LogMessage('0000DF7', StrSubstNo(NoLinesFoundInSalesOrderTelemetryMsg, CRMProductName.CDSServiceName(), CRMSalesorder.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
        end;

        SalesLine.InsertFreightLine(CRMSalesorder.FreightAmount);
    end;

    procedure CreateExtendedDescriptionOrderLines(SalesHeader: Record "Sales Header"; FullDescription: Text; SalesLineNo: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        while StrLen(FullDescription) > 0 do begin
            InitNewSalesLine(SalesHeader, SalesLine);

            SalesLine.Validate(Description, CopyStr(FullDescription, 1, MaxStrLen(SalesLine.Description)));
            SalesLine."Attached to Line No." := SalesLineNo;
            SalesLine.Insert();
            FullDescription := CopyStr(FullDescription, MaxStrLen(SalesLine.Description) + 1);
        end;
    end;

    [Scope('OnPrem')]
    procedure CRMIsCoupledToValidRecord(CRMSalesorder: Record "CRM Salesorder"; NAVTableID: Integer): Boolean
    var
        SalesHeader: Record "Sales Header";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        exit(CRMIntegrationManagement.IsCRMIntegrationEnabled() and
          CRMCouplingManagement.IsRecordCoupledToNAV(CRMSalesorder.SalesOrderId, NAVTableID) and
          CoupledSalesHeaderExists(CRMSalesorder, SalesHeader));
    end;

    procedure GetCRMSalesOrder(var CRMSalesorder: Record "CRM Salesorder"; YourReference: Text[35]): Boolean
    begin
        CRMSalesorder.SetRange(OrderNumber, YourReference);
        exit(CRMSalesorder.FindFirst());
    end;

    procedure GetCoupledCRMSalesorder(SalesHeader: Record "Sales Header"; var CRMSalesorder: Record "CRM Salesorder")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CoupledCRMId: Guid;
    begin
        if SalesHeader.IsEmpty() then
            Error(NotCoupledSalesHeaderErr, SalesHeader."No.", CRMProductName.CDSServiceName());

        if not CRMIntegrationRecord.FindIDFromRecordID(SalesHeader.RecordId, CoupledCRMId) then
            Error(NotCoupledSalesHeaderErr, SalesHeader."No.", CRMProductName.CDSServiceName());

        if CRMSalesorder.Get(CoupledCRMId) then
            exit;

        // If we reached this point, a zombie coupling exists but the sales order most probably was deleted manually by the user.
        CRMIntegrationManagement.RemoveCoupling(Database::"Sales Header", Database::"CRM Salesorder", CoupledCRMId, false);
        Error(ZombieCouplingErr, PRODUCTNAME.Short(), CRMProductName.CDSServiceName());
    end;

    procedure GetCoupledCustomer(CRMSalesorder: Record "CRM Salesorder"; var Customer: Record Customer) Result: Boolean
    var
        CRMAccount: Record "CRM Account";
        CRMIntegrationRecord: Record "CRM Integration Record";
        NAVCustomerRecordId: RecordID;
        CRMAccountId: Guid;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCoupledCustomer(CRMSalesorder, Customer, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if IsNullGuid(CRMSalesorder.CustomerId) then
            Error(NoCustomerErr, CannotCreateSalesOrderInNAVTxt, CRMSalesorder.Description, CRMProductName.CDSServiceName());

        // Get the ID of the CRM Account associated to the sales order. Works for both CustomerType(s): account, contact
        if not GetCRMAccountOfCRMSalesOrder(CRMSalesorder, CRMAccount) then
            Error(NoCRMAccountForOrderErr, CRMSalesorder.Name, CRMSalesorder.CustomerIdType, CRMSalesorder.CustomerId, CRMProductName.CDSServiceName());
        CRMAccountId := CRMAccount.AccountId;

        if not CRMIntegrationRecord.FindRecordIDFromID(CRMAccountId, DATABASE::Customer, NAVCustomerRecordId) then
            Error(NotCoupledCustomerErr, CannotCreateSalesOrderInNAVTxt, CRMAccount.Name, CRMProductName.CDSServiceName());

        exit(Customer.Get(NAVCustomerRecordId));
    end;

    procedure GetCoupledSalesHeader(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header"): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        NAVSalesHeaderRecordId: RecordID;
    begin
        if IsNullGuid(CRMSalesorder.SalesOrderId) then
            Error(NotCoupledCRMSalesOrderErr, CRMSalesorder.OrderNumber, CRMProductName.CDSServiceName());

        // Attempt to find the coupled sales header
        if not CRMIntegrationRecord.FindRecordIDFromID(CRMSalesorder.SalesOrderId, DATABASE::"Sales Header", NAVSalesHeaderRecordId) then
            Error(NotCoupledCRMSalesOrderErr, CRMSalesorder.OrderNumber, CRMProductName.CDSServiceName());

        if SalesHeader.Get(NAVSalesHeaderRecordId) then
            exit(true);

        // If we reached this point, a zombie coupling exists but the sales order most probably was deleted manually by the user.
        CRMIntegrationManagement.RemoveCoupling(Database::"Sales Header", Database::"CRM Salesorder", CRMSalesorder.SalesOrderId, false);
        Error(ZombieCouplingErr, PRODUCTNAME.Short(), CRMProductName.CDSServiceName());
    end;

    procedure GetCRMAccountOfCRMSalesOrder(CRMSalesorder: Record "CRM Salesorder"; var CRMAccount: Record "CRM Account") Result: Boolean
    var
        CRMContact: Record "CRM Contact";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCRMAccountOfCRMSalesOrder(CRMSalesorder, CRMAccount, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if CRMSalesorder.CustomerIdType = CRMSalesorder.CustomerIdType::account then
            if CRMAccount.Get(CRMSalesorder.CustomerId) then
                if CRMAccount.CustomerTypeCode <> CRMAccount.CustomerTypeCode::Customer then begin
                    Session.LogMessage('0000DMP', StrSubstNo(AccountNotCustomerTelemetryMsg, CannotCreateSalesOrderInNAVTxt, CRMSalesorder.CustomerId, CRMProductName.CDSServiceName()), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::All, 'Category', CrmTelemetryCategoryTok);
                    Error(AccountNotCustomerErr, CannotCreateSalesOrderInNAVTxt, CRMAccount.Name, CRMProductName.CDSServiceName());
                end else
                    exit(true);



        if CRMSalesorder.CustomerIdType = CRMSalesorder.CustomerIdType::contact then
            if CRMContact.Get(CRMSalesorder.CustomerId) then
                exit(CRMAccount.Get(CRMContact.ParentCustomerId));
        exit(false);
    end;

    procedure GetCRMContactOfCRMSalesOrder(CRMSalesorder: Record "CRM Salesorder"; var CRMContact: Record "CRM Contact"): Boolean
    begin
        if CRMSalesorder.CustomerIdType = CRMSalesorder.CustomerIdType::contact then
            exit(CRMContact.Get(CRMSalesorder.CustomerId));
    end;

    local procedure InitNewSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        LastSalesLineNo := LastSalesLineNo + 10000;
        SalesLine.Validate("Line No.", LastSalesLineNo);
    end;

    local procedure InitializeSalesOrderLine(CRMSalesorderdetail: Record "CRM Salesorderdetail"; SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        CRMProduct: Record "CRM Product";
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        UnitPrice: Decimal;
        UpdateItemUnitPriceNeeded: Boolean;
        IsHandled: Boolean;
    begin
        InitNewSalesLine(SalesHeader, SalesLine);

        if IsNullGuid(CRMSalesorderdetail.ProductId) then begin
            OnInitializeSalesOrderLineOnBeforeInitializeWriteInOrderLine(SalesLine, CRMSalesorderdetail, IsHandled);
            if IsHandled then
                exit;
            InitializeWriteInOrderLine(SalesLine)
        end else begin
            CRMProduct.Get(CRMSalesorderdetail.ProductId);
            CRMProduct.TestField(StateCode, CRMProduct.StateCode::Active);
            case CRMProduct.ProductTypeCode of
                CRMProduct.ProductTypeCode::SalesInventory:
                    InitializeSalesOrderLineFromItem(CRMProduct, SalesLine);
                CRMProduct.ProductTypeCode::Services:
                    InitializeSalesOrderLineFromResource(CRMProduct, SalesLine);
                else begin
                    IsHandled := false;
                    OnInitializeSalesOrderLineOnBeforeUnexpectedProductTypeErr(CRMSalesorderdetail, CRMProduct, SalesLine, SalesHeader, IsHandled);
                    if not IsHandled then
                        Error(UnexpectedProductTypeErr, CannotCreateSalesOrderInNAVTxt, CRMProduct.ProductNumber);
                end;
            end;
        end;

        SetLineDescription(SalesHeader, SalesLine, CRMSalesorderdetail);

        if CRMIntegrationManagement.IsUnitGroupMappingEnabled() then
            UpdateSalesLineUnitOfMeasure(CRMSalesorderdetail, CRMProduct, SalesLine);

        SalesLine.Validate(Quantity, CRMSalesorderdetail.Quantity);
        UnitPrice := CRMSalesorderdetail.PricePerUnit;
        GeneralLedgerSetup.Get();
        UpdateItemUnitPriceNeeded := CRMProduct.ProductTypeCode = CRMProduct.ProductTypeCode::SalesInventory;
        OnInitializeSalesOrderLineOnAfterCalcUpdateItemUnitPriceNeeded(CRMSalesorderdetail, CRMProduct, SalesLine, SalesHeader, UpdateItemUnitPriceNeeded);
        if UpdateItemUnitPriceNeeded then
            if Item.GET(SalesLine."No.") then
                if (Item."Price Includes VAT") and (Item."VAT Bus. Posting Gr. (Price)" <> '') then
                    if SalesLine."VAT Bus. Posting Group" = Item."VAT Bus. Posting Gr. (Price)" then
                        if VATPostingSetup.GET(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group") then
                            UnitPrice :=
                                ROUND(CRMSalesorderdetail.PricePerUnit / (1 + VATPostingSetup."VAT %" / 100), GeneralLedgerSetup."Unit-Amount Rounding Precision");
        SalesLine.VALIDATE("Unit Price", UnitPrice);

        SalesLine.Validate(
            "Line Discount Amount",
            CRMSalesorderdetail.Quantity * CRMSalesorderdetail.VolumeDiscountAmount +
            CRMSalesorderdetail.ManualDiscountAmount);
    end;

    local procedure UpdateSalesLineUnitOfMeasure(CRMSalesorderdetail: Record "CRM Salesorderdetail"; CRMProduct: Record "CRM Product"; var SalesLine: Record "Sales Line")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        NAVItemUomRecordId: RecordID;
        NAVResourceUomRecordId: RecordID;
    begin
        if IsNullGuid(CRMProduct.ProductId) then
            exit;

        case CRMProduct.ProductTypeCode of
            CRMProduct.ProductTypeCode::SalesInventory:
                begin
                    if not CRMIntegrationRecord.FindRecordIDFromID(CRMSalesorderdetail.UoMId, Database::"Item Unit of Measure", NAVItemUomRecordId) then
                        Error(NotCoupledCRMUomErr, CannotCreateSalesOrderInNAVTxt, CRMSalesorderdetail.UoMIdName, CRMProductName.CDSServiceName());

                    if not ItemUnitOfMeasure.Get(NAVItemUomRecordId) then
                        Error(ItemUnitOfMeasureDoesNotExistErr, CannotCreateSalesOrderInNAVTxt, CRMSalesorderdetail.UoMIdName);

                    SalesLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
                end;
            CRMProduct.ProductTypeCode::Services:
                begin
                    if not CRMIntegrationRecord.FindRecordIDFromID(CRMSalesorderdetail.UoMId, Database::"Resource Unit of Measure", NAVResourceUomRecordId) then
                        Error(NotCoupledCRMUomErr, CannotCreateSalesOrderInNAVTxt, CRMSalesorderdetail.UoMIdName, CRMProductName.CDSServiceName());

                    if not ResourceUnitOfMeasure.Get(NAVResourceUomRecordId) then
                        Error(ResourceUnitOfMeasureDoesNotExistErr, CannotCreateSalesOrderInNAVTxt, CRMSalesorderdetail.UoMIdName);

                    SalesLine.Validate("Unit of Measure Code", ResourceUnitOfMeasure.Code);
                end;
        end;
    end;

    local procedure InitializeSalesOrderLineFromItem(CRMProduct: Record "CRM Product"; var SalesLine: Record "Sales Line")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        Item: Record Item;
        NAVItemRecordID: RecordID;
    begin
        // Attempt to find the coupled item
        if not CRMIntegrationRecord.FindRecordIDFromID(CRMProduct.ProductId, DATABASE::Item, NAVItemRecordID) then
            Error(NotCoupledCRMProductErr, CannotCreateSalesOrderInNAVTxt, CRMProduct.Name, CRMProductName.CDSServiceName());

        if not Item.Get(NAVItemRecordID) then
            Error(ItemDoesNotExistErr, CannotCreateSalesOrderInNAVTxt, CRMProduct.ProductNumber);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", Item."No.");
    end;

    local procedure InitializeSalesOrderLineFromResource(CRMProduct: Record "CRM Product"; var SalesLine: Record "Sales Line")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        Resource: Record Resource;
        NAVResourceRecordID: RecordID;
    begin
        // Attempt to find the coupled resource
        if not CRMIntegrationRecord.FindRecordIDFromID(CRMProduct.ProductId, DATABASE::Resource, NAVResourceRecordID) then
            Error(NotCoupledCRMResourceErr, CannotCreateSalesOrderInNAVTxt, CRMProduct.Name, CRMProductName.CDSServiceName());

        if not Resource.Get(NAVResourceRecordID) then
            Error(ResourceDoesNotExistErr, CannotCreateSalesOrderInNAVTxt, CRMProduct.ProductNumber);
        SalesLine.Validate(Type, SalesLine.Type::Resource);
        SalesLine.Validate("No.", Resource."No.");
    end;

    local procedure InitializeWriteInOrderLine(var SalesLine: Record "Sales Line")
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        if SalesSetup."Write-in Product No." = '' then begin
            Session.LogMessage('000083C', StrSubstNo(MisingWriteInProductTelemetryMsg, CRMProductName.CDSServiceName()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
            Error(MissingWriteInProductNoErr, CRMProductName.CDSServiceName(), SalesLine."Document Type", SalesLine.GetSalesHeader()."Your Reference");
        end;
        SalesSetup.Validate("Write-in Product No.");
        case SalesSetup."Write-in Product Type" of
            SalesSetup."Write-in Product Type"::Item:
                SalesLine.Validate(Type, SalesLine.Type::Item);
            SalesSetup."Write-in Product Type"::Resource:
                SalesLine.Validate(Type, SalesLine.Type::Resource);
        end;
        SalesLine.Validate("No.", SalesSetup."Write-in Product No.");
    end;

    [Scope('OnPrem')]
    procedure SetLastBackOfficeSubmit(var CRMSalesorder: Record "CRM Salesorder"; NewDate: Date)
    begin
        if CRMSalesorder.LastBackofficeSubmit <> NewDate then begin
            Session.LogMessage('0000DF8', StrSubstNo(StartingToSetLastBackOfficeSubmitTelemetryMsg, CRMProductName.CDSServiceName(), CRMSalesorder.SalesOrderId, Format(NewDate)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
            CRMSalesorder.StateCode := CRMSalesorder.StateCode::Active;
            CRMSalesorder.Modify(true);
            CRMSalesorder.LastBackofficeSubmit := NewDate;
            CRMSalesorder.Modify(true);
            CRMSalesorder.StateCode := CRMSalesorder.StateCode::Submitted;
            CRMSalesorder.Modify(true);
            Session.LogMessage('0000DF9', StrSubstNo(SuccessfullySetLastBackOfficeSubmitTelemetryMsg, CRMProductName.CDSServiceName(), CRMSalesorder.SalesOrderId, Format(NewDate)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyShipToInformationIfNotEmpty(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCoupledCustomer(CRMSalesorder: Record "CRM Salesorder"; var Customer: Record Customer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetLineDescription(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var CRMSalesorderdetail: Record "CRM Salesorderdetail"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCRMAccountOfCRMSalesOrder(CRMSalesorder: Record "CRM Salesorder"; var CRMAccount: Record "CRM Account"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesOrderHeaderOnBeforeSalesHeaderInsert(var SalesHeader: Record "Sales Header"; CRMSalesorder: Record "CRM Salesorder")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesOrderLinesOnBeforeSalesLineInsert(var SalesLine: Record "Sales Line"; CRMSalesorderdetail: Record "CRM Salesorderdetail")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInNAVOnBeforeCheckState(CRMSalesorder: Record "CRM Salesorder"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateNAVSalesOrderOnAfterSetLastBackOfficeSubmit(var SalesHeader: Record "Sales Header"; CRMSalesorder: Record "CRM Salesorder")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHideSalesOrderDiscountsDialog(var Hide: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitializeSalesOrderLineOnBeforeUnexpectedProductTypeErr(CRMSalesorderdetail: Record "CRM Salesorderdetail"; CRMProduct: Record "CRM Product"; SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitializeSalesOrderLineOnAfterCalcUpdateItemUnitPriceNeeded(CRMSalesorderdetail: Record "CRM Salesorderdetail"; CRMProduct: Record "CRM Product"; SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var UpdateItemUnitPriceNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyBillToInformationIfNotEmptyOnBeforeValidateBillToCountryRegionCode(var SalesHeader: Record "Sales Header"; CRMSalesorder: Record "CRM Salesorder"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyShipToInformationIfNotEmptyOnBeforeValidateShipToCountryRegionCode(var SalesHeader: Record "Sales Header"; CRMSalesorder: Record "CRM Salesorder"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetSalesHeaderPaymentDiscountFromCRM(var SalesHeader: Record "Sales Header"; var CRMSalesOrder: Record "CRM Salesorder"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyBillToInformationIfNotEmpty(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitializeSalesOrderLineOnBeforeInitializeWriteInOrderLine(var SalesLine: Record "Sales Line"; var CRMSalesorderdetail: Record "CRM Salesorderdetail"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateNAVSalesOrder(CRMSalesorder: Record "CRM Salesorder"; var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;
}

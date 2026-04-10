// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Foundation.UOM;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Document;
using System.Threading;

codeunit 5366 "CRM Archived Sales Orders Job"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        UpdateOrders(Rec.GetLastLogEntryNo());
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";
        ConnectionNotEnabledErr: Label 'The %1 connection is not enabled.', Comment = '%1 = CRM product name';
        BidirectionalSyncNotEnabledErr: Label 'Bidirectional sales order synchronization is not enabled.';
        ArchivedOrdersUpdatedMsg: Label 'Archived sales orders have been synchronized.';

    local procedure UpdateOrders(JobLogEntryNo: Integer)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionName: Text;
    begin
        CRMConnectionSetup.Get();
        if not CRMConnectionSetup."Is Enabled" then
            Error(ConnectionNotEnabledErr, CRMProductName.FULL());

        if not CRMConnectionSetup."Bidirectional Sales Order Int." then
            Error(BidirectionalSyncNotEnabledErr);

        ConnectionName := Format(CreateGuid());
        CRMConnectionSetup.RegisterConnectionWithName(ConnectionName);
        SetDefaultTableConnection(
          TableConnectionType::CRM, CRMConnectionSetup.GetDefaultCRMConnection(ConnectionName));

        UpdateArchivedOrders(JobLogEntryNo);

        CRMConnectionSetup.UnregisterConnectionWithName(ConnectionName);
    end;

    local procedure UpdateArchivedOrders(JobLogEntryNo: Integer)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationRecord2: Record "CRM Integration Record";
        SalesHeaderArchive: Record "Sales Header Archive";
        CRMSalesorder: Record "CRM Salesorder";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete;
        ModifyCounter: Integer;
    begin
        IntegrationTableSynch.BeginIntegrationSynchJobLoging(TableConnectionType::CRM, Codeunit::"CRM Archived Sales Orders Job", JobLogEntryNo, Database::"Sales Header");

        CRMIntegrationRecord.SetRange("Archived Sales Order", true);
        CRMIntegrationRecord.SetRange("Archived Sales Order Updated", false);
        if CRMIntegrationRecord.FindSet() then
            repeat
                if CRMSalesorder.Get(CRMIntegrationRecord."CRM ID") then
                    if (CRMSalesorder.BusinessCentralOrderNumber <> '') and (CRMSalesorder.BusinessCentralDocumentOccurrenceNumber <> 0) then begin
                        SalesHeaderArchive.SetRange("No.", CRMSalesorder.BusinessCentralOrderNumber);
                        SalesHeaderArchive.SetRange("Doc. No. Occurrence", CRMSalesorder.BusinessCentralDocumentOccurrenceNumber);
                        SalesHeaderArchive.SetCurrentKey("Version No.");
                        SalesHeaderArchive.SetAscending("Version No.", true);
                        if SalesHeaderArchive.FindLast() then
                            if UpdateFromSalesHeader(SalesHeaderArchive, CRMSalesorder) then begin
                                ModifyCounter += 1;
                                CRMIntegrationRecord2.GetBySystemId(CRMIntegrationRecord.SystemId);
                                CRMIntegrationRecord2."Archived Sales Order Updated" := true;
                                CRMIntegrationRecord2.Modify();
                                if SalesHeaderArchive.Invoice then
                                    SetCRMSalesOrderStateAsInvoiced(CRMSalesorder);
                            end;
                    end;
            until CRMIntegrationRecord.Next() = 0;

        IntegrationTableSynch.UpdateSynchJobCounters(SynchActionType::Modify, ModifyCounter);
        IntegrationTableSynch.EndIntegrationSynchJobWithMsg(ArchivedOrdersUpdatedMsg);
    end;

    [TryFunction]
    local procedure UpdateFromSalesHeader(SalesHeaderArchive: Record "Sales Header Archive"; var CRMSalesorder: Record "CRM Salesorder")
    begin
        CRMSalesorder.DateFulfilled := SalesHeaderArchive."Shipment Date";
        if CRMSalesorder.DiscountPercentage <> SalesHeaderArchive."Payment Discount %" then
            CRMSalesorder.DiscountPercentage := SalesHeaderArchive."Payment Discount %";
        CRMSalesorder.Modify();

        UncoupleDeletedSalesLines(SalesHeaderArchive, CRMSalesorder);
        ResetCRMSalesorderdetailFromSalesOrderLine(SalesHeaderArchive, CRMSalesorder);
    end;

    local procedure SetCRMSalesOrderStateAsInvoiced(var CRMSalesorder: Record "CRM Salesorder")
    begin
        CRMSalesorder.StateCode := CRMSalesorder.StateCode::Invoiced;
        CRMSalesorder.StatusCode := CRMSalesorder.StatusCode::Invoiced;
        CRMSalesorder.Modify();
    end;

    local procedure UncoupleDeletedSalesLines(SalesHeaderArchive: Record "Sales Header Archive"; CRMSalesorder: Record "CRM Salesorder")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        CRMSalesorderdetail2: Record "CRM Salesorderdetail";
        SalesLineArchive: Record "Sales Line Archive";
    begin
        CRMSalesorderdetail.SetRange(SalesOrderId, CRMSalesorder.SalesOrderId);
        if CRMSalesorderdetail.FindSet() then
            repeat
                CRMIntegrationRecord.SetRange("CRM ID", CRMSalesorderdetail.SalesOrderDetailId);
                CRMIntegrationRecord.SetRange("Table ID", Database::"Sales Line");
                if CRMIntegrationRecord.FindFirst() then begin
                    SalesLineArchive.SetRange("Document Type", SalesLineArchive."Document Type"::Order);
                    SalesLineArchive.SetRange("Document No.", SalesHeaderArchive."No.");
                    SalesLineArchive.SetRange("Doc. No. Occurrence", SalesHeaderArchive."Doc. No. Occurrence");
                    SalesLineArchive.SetRange("Version No.", SalesHeaderArchive."Version No.");
                    if SalesLineArchive.IsEmpty() then begin
                        CRMIntegrationRecord.Delete();
                        CRMSalesorderdetail2.Get(CRMSalesorderdetail.SalesOrderDetailId);
                        CRMSalesorderdetail2.Delete();
                    end;
                end;
            until CRMSalesorderdetail.Next() = 0;
    end;

    local procedure ResetCRMSalesorderdetailFromSalesOrderLine(SalesHeaderArchive: Record "Sales Header Archive"; CRMSalesorder: Record "CRM Salesorder")
    var
        SalesLineArchive: Record "Sales Line Archive";
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
    begin
        SalesLineArchive.SetRange("Document Type", SalesLineArchive."Document Type"::Order);
        SalesLineArchive.SetRange("Document No.", SalesHeaderArchive."No.");
        SalesLineArchive.SetRange("Doc. No. Occurrence", SalesHeaderArchive."Doc. No. Occurrence");
        SalesLineArchive.SetRange("Version No.", SalesHeaderArchive."Version No.");
        if SalesLineArchive.FindSet() then
            repeat
                CRMSalesorderdetail.SetRange(SalesOrderId, CRMSalesorder.SalesOrderId);
                CRMSalesorderdetail.SetRange(BusinessCentralLineNumber, SalesLineArchive."Line No.");
                if CRMSalesorderdetail.FindFirst() then
                    UpdateCRMSalesorderdetail(SalesLineArchive, CRMSalesorderdetail)
                else
                    CreateCRMSalesorderdetail(SalesLineArchive, CRMSalesorder);
            until SalesLineArchive.Next() = 0;
    end;

    local procedure UpdateCRMSalesorderdetail(SalesLineArchive: Record "Sales Line Archive"; var CRMSalesorderdetail: Record "CRM Salesorderdetail")
    var
        Modified: Boolean;
    begin
        if SalesLineArchive.Quantity <> CRMSalesorderdetail.Quantity then begin
            CRMSalesorderdetail.Quantity := SalesLineArchive.Quantity;
            Modified := true;
        end;

        if SalesLineArchive."Quantity Shipped" <> CRMSalesorderdetail.QuantityShipped then begin
            CRMSalesorderdetail.QuantityShipped := SalesLineArchive."Quantity Shipped";
            Modified := true;
        end;

        if SalesLineArchive."Line Discount Amount" <> CRMSalesorderdetail.ManualDiscountAmount then begin
            CRMSalesorderdetail.ManualDiscountAmount := SalesLineArchive."Line Discount Amount";
            Modified := true;
        end;

        if SalesLineArchive.Amount <> CRMSalesorderdetail.BaseAmount then begin
            CRMSalesorderdetail.BaseAmount := SalesLineArchive.Amount;
            Modified := true;
        end;

        if SalesLineArchive."Amount Including VAT" <> CRMSalesorderdetail.ExtendedAmount then begin
            CRMSalesorderdetail.ExtendedAmount := SalesLineArchive."Amount Including VAT";
            Modified := true;
        end;

        OnUpdateCRMSalesorderdetailOnBeforeModify(CRMSalesorderdetail, SalesLineArchive);

        if Modified then
            CRMSalesorderdetail.Modify();
    end;

    local procedure CreateCRMSalesorderdetail(SalesLineArchive: Record "Sales Line Archive"; CRMSalesorder: Record "CRM Salesorder")
    var
        CRMSalesorderdetail: Record "CRM Salesorderdetail";
        CRMUom: Record "CRM Uom";
        Item: Record Item;
        Resource: Record Resource;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ResourceUnitOfMeasure: Record "Resource Unit of Measure";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        RecId: RecordId;
        CRMId: Guid;
    begin
        CRMSalesorderdetail.Init();

        CRMSalesorderdetail.SalesOrderId := CRMSalesorder.SalesOrderId;
        CRMSalesorderdetail.ProductTypeCode := CRMSalesorderdetail.ProductTypeCode::Product;

        case SalesLineArchive.Type of
            "Sales Line Type"::Item:
                begin
                    Item.Get(SalesLineArchive."No.");
                    RecId := Item.RecordId;
                end;
            "Sales Line Type"::Resource:
                begin
                    Resource.Get(SalesLineArchive."No.");
                    RecId := Resource.RecordId;
                end;
        end;

        if not CRMIntegrationRecord.FindIDFromRecordID(RecId, CRMId) then
            exit;

        CRMSalesorderdetail.ProductId := CRMId;
        CRMSalesorderdetail.BusinessCentralLineNumber := SalesLineArchive."Line No.";
        CRMSalesorderdetail.Quantity := SalesLineArchive.Quantity;
        CRMSalesorderdetail.QuantityShipped := SalesLineArchive."Quantity Shipped";
        CRMSalesorderdetail.ManualDiscountAmount := SalesLineArchive."Line Discount Amount";
        CRMSalesorderdetail.IsPriceOverridden := true;
        CRMSalesorderdetail.PricePerUnit := SalesLineArchive."Unit Price";
        CRMSalesorderdetail.BaseAmount := SalesLineArchive.Amount;
        CRMSalesorderdetail.ExtendedAmount := SalesLineArchive."Amount Including VAT";

        if not CRMIntegrationManagement.IsUnitGroupMappingEnabled() then begin
            UnitOfMeasure.Get(SalesLineArchive."Unit of Measure Code");
            if not CRMIntegrationRecord.FindIDFromRecordID(UnitOfMeasure.RecordId, CRMId) then
                exit;

            CRMUom.SetRange(UoMScheduleId, CRMId);
            CRMUom.SetRange(Name, UnitOfMeasure.Code);
            if CRMUom.FindFirst() then
                CRMSalesorderdetail.UoMId := CRMUom.UoMId;
        end else begin
            case SalesLineArchive.Type of
                "Sales Line Type"::Item:
                    begin
                        ItemUnitOfMeasure.Get(SalesLineArchive."No.", SalesLineArchive."Unit of Measure Code");
                        RecId := ItemUnitOfMeasure.RecordId;
                    end;
                "Sales Line Type"::Resource:
                    begin
                        ResourceUnitOfMeasure.Get(SalesLineArchive."No.", SalesLineArchive."Unit of Measure Code");
                        RecId := ResourceUnitOfMeasure.RecordId;
                    end;
            end;

            if not CRMIntegrationRecord.FindIDFromRecordID(RecId, CRMId) then
                exit;
            CRMSalesorderdetail.UoMId := CRMId;
        end;

        CRMSalesorderdetail.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCRMSalesorderdetailOnBeforeModify(var CRMSalesorderdetail: Record "CRM Salesorderdetail"; SalesLineArchive: Record "Sales Line Archive")
    begin
    end;
}
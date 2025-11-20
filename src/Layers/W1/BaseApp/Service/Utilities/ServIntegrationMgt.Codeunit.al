// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Reporting;
using Microsoft.Integration.D365Sales;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Availability;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Archive;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Resources;
using Microsoft.Service.Setup;
using Microsoft.Projects.Resources.Analysis;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Journal;
using Microsoft.Projects.Resources.Resource;
using System.DataAdministration;
using System.Email;

codeunit 6450 "Serv. Integration Mgt."
{
    var
        ServiceItemQtyErr: Label 'The value of %1 field must be a whole number for the item included in the service item group if the %2 field in the Service Item Groups window contains a check mark.', Comment = '%1 - service item, %2 - field caption';
        CustomerDeletionQst: Label 'Deleting the %1 %2 will cause the %3 to be deleted for the associated Service Items. Do you want to continue?', Comment = '%1 - table caption, %2 - customer no., %3 - field caption';
        CannotDeleteCustomerErr: Label 'Cannot delete customer.';
        ServiceDocumentExistErr: Label 'You cannot delete customer %1 because there is at least one outstanding Service %2 for this customer.', Comment = '%1 - customer no., %2 - service document type.';
        NoFiltersErr: Label 'No filters were set on table %1, %2. Please contact your Microsoft Partner for assistance.', Comment = '%1 = a id of a table (integer), %2 = the caption of the table.';

    // Table Customer

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterDeleteRelatedData', '', false, false)]
    local procedure CustomerOnAfterDelete(Customer: Record Customer)
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ConfirmManagement: Codeunit System.Utilities."Confirm Management";
    begin
        ServiceItem.SetRange("Customer No.", Customer."No.");
        if ServiceItem.FindFirst() then
            if ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(CustomerDeletionQst, Customer.TableCaption(), Customer."No.", ServiceItem.FieldCaption("Customer No.")), true)
            then
                ServiceItem.ModifyAll("Customer No.", '')
            else
                Error(CannotDeleteCustomerErr);

        ServiceHeader.SetCurrentKey("Customer No.", "Order Date");
        ServiceHeader.SetRange("Customer No.", Customer."No.");
        if ServiceHeader.FindFirst() then
            Error(ServiceDocumentExistErr, Customer."No.", ServiceHeader."Document Type");

        ServiceHeader.SetRange("Customer No.");
        ServiceHeader.SetRange("Bill-to Customer No.", Customer."No.");
        if ServiceHeader.FindFirst() then
            Error(ServiceDocumentExistErr, Customer."No.", ServiceHeader."Document Type");
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnGetTotalAmountLCYOnAfterCalcFields', '', false, false)]
    local procedure OnGetTotalAmountLCYOnAfterCalcFields(var Customer: Record Customer)
    begin
        Customer.CalcFields("Outstanding Serv. Orders (LCY)", "Serv Shipped Not Invoiced(LCY)", "Outstanding Serv.Invoices(LCY)");
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnGetTotalAmountLCYUIOnAfterSetAutoCalcFields', '', false, false)]
    local procedure OnGetTotalAmountLCYUIOnAfterSetAutoCalcFields(var Customer: Record Customer)
    begin
        Customer.SetAutoCalcFields("Outstanding Serv. Orders (LCY)", "Serv Shipped Not Invoiced(LCY)", "Outstanding Serv.Invoices(LCY)");
    end;

    [EventSubscriber(ObjectType::Table, Database::Customer, 'OnAfterGetTotalAmountLCYCommon', '', false, false)]
    local procedure OnAfterGetTotalAmountLCYCommon(var Customer: Record Customer; var TotalAmountLCY: Decimal)
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        ServiceLine: Record "Service Line";
        ServiceInvoiceOutstandingAmountLCYForInvoicingShippedOrders: Decimal;
    begin
        Customer.CalcFields("Outstanding Serv. Orders (LCY)", "Serv Shipped Not Invoiced(LCY)", "Outstanding Serv.Invoices(LCY)");

        // Sum up "Outstanding Amount (LCY)" of service invoices for invoicing shipped orders. This amount is already included in "Service Shipped Not Invoiced (LCY)", and should be subtracted from outstanding invoices.
        ServiceInvoiceOutstandingAmountLCYForInvoicingShippedOrders := ServiceLine.OutstandingInvoiceAmountFromShipment(Customer."No.");

        TotalAmountLCY +=
            Customer."Outstanding Serv. Orders (LCY)"
            + Customer."Serv Shipped Not Invoiced(LCY)"
            + Customer."Outstanding Serv.Invoices(LCY)" - ServiceInvoiceOutstandingAmountLCYForInvoicingShippedOrders;
    end;

    // Table Cust. Ledger Entry

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", 'OnBeforeShowDoc', '', false, false)]
    local procedure CustLedgerEntryOnBeforeShowDoc(CustLedgerEntry: Record "Cust. Ledger Entry"; var IsPageOpened: Boolean; var IsHandled: Boolean)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case CustLedgerEntry."Document Type" of
            CustLedgerEntry."Document Type"::Invoice:
                if ServiceInvoiceHeader.Get(CustLedgerEntry."Document No.") then begin
                    Page.Run(PAGE::"Posted Service Invoice", ServiceInvoiceHeader);
                    IsPageOpened := true;
                    IsHandled := true;
                end;
            CustLedgerEntry."Document Type"::"Credit Memo":
                if ServiceCrMemoHeader.Get(CustLedgerEntry."Document No.") then begin
                    Page.Run(PAGE::"Posted Service Credit Memo", ServiceCrMemoHeader);
                    IsPageOpened := true;
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", 'OnAfterShowPostedDocAttachment', '', false, false)]
    local procedure CustLedgerEntryOnAfterShowPostedDocAttachment(CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentFound: Boolean)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        if DocumentFound then
            exit;

        case CustLedgerEntry."Document Type" of
            CustLedgerEntry."Document Type"::Invoice:
                if ServiceInvoiceHeader.Get(CustLedgerEntry."Document No.") then
                    OpenDocumentAttachmentDetails(ServiceInvoiceHeader);
            CustLedgerEntry."Document Type"::"Credit Memo":
                if ServiceCrMemoHeader.Get(CustLedgerEntry."Document No.") then
                    OpenDocumentAttachmentDetails(ServiceCrMemoHeader);
        end;
    end;

    local procedure OpenDocumentAttachmentDetails("Record": Variant)
    var
        DocumentAttachmentDetails: Page "Document Attachment Details";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Record);
        DocumentAttachmentDetails.OpenForRecRef(RecRef);
        DocumentAttachmentDetails.RunModal();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", 'OnAfterHasPostedDocAttachment', '', false, false)]
    local procedure CustLedgerEntryOnAfterHasPostedDocAttachment(CustLedgerEntry: Record "Cust. Ledger Entry"; var HasPostedDocumentAttachment: Boolean)
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        ServiceInvoiceHeader: Record "Service Invoice Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        DocumentAttachment: Record "Document Attachment";
    begin
        case CustLedgerEntry."Document Type" of
            CustLedgerEntry."Document Type"::Invoice:
                if ServiceInvoiceHeader.ReadPermission() then
                    if ServiceInvoiceHeader.Get(CustLedgerEntry."Document No.") then
                        HasPostedDocumentAttachment := DocumentAttachment.HasPostedDocumentAttachment(ServiceInvoiceHeader);
            CustLedgerEntry."Document Type"::"Credit Memo":
                if ServiceCrMemoHeader.ReadPermission() then
                    if ServiceCrMemoHeader.Get(CustLedgerEntry."Document No.") then
                        HasPostedDocumentAttachment := DocumentAttachment.HasPostedDocumentAttachment(ServiceCrMemoHeader);
        end;
    end;

    // Table Sales Line

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnCheckServItemCreation', '', false, false)]
    local procedure SalesLineOnCheckServItemCreation(SalesLine: Record "Sales Line")
    begin
        CheckServItemCreation(SalesLine);
    end;

    local procedure CheckServItemCreation(SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        ServItemGroup: Record "Service Item Group";
    begin
        Item.Get(SalesLine."No.");
        if Item."Service Item Group" = '' then
            exit;
        if ServItemGroup.Get(Item."Service Item Group") then
            if ServItemGroup."Create Service Item" then
                if SalesLine."Qty. to Ship (Base)" <> Round(SalesLine."Qty. to Ship (Base)", 1) then
                    Error(
                      ServiceItemQtyErr,
                      SalesLine.FieldCaption("Qty. to Ship (Base)"),
                      ServItemGroup.FieldCaption("Create Service Item"));
    end;

    // Table Sales Shipment Line

    [EventSubscriber(ObjectType::Table, Database::"Sales Shipment Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure SalesShipmentLineOnAfterDelete(Rec: Record "Sales Shipment Line"; RunTrigger: Boolean)
    var
        ServiceItem: Record "Service Item";
    begin
        if Rec.IsTemporary() or (not RunTrigger) then
            exit;

        ServiceItem.Reset();
        ServiceItem.SetCurrentKey("Sales/Serv. Shpt. Document No.", "Sales/Serv. Shpt. Line No.");
        ServiceItem.SetRange("Sales/Serv. Shpt. Document No.", Rec."Document No.");
        ServiceItem.SetRange("Sales/Serv. Shpt. Line No.", Rec."Line No.");
        ServiceItem.SetRange("Shipment Type", ServiceItem."Shipment Type"::Sales);
        if ServiceItem.Find('-') then
            repeat
                ServiceItem.Validate("Sales/Serv. Shpt. Document No.", '');
                ServiceItem.Validate("Sales/Serv. Shpt. Line No.", 0);
                ServiceItem.Modify(true);
            until ServiceItem.Next() = 0;
    end;

    // Table Item

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterDeleteRelatedData', '', false, false)]
    local procedure ItemOnAfterDeleteRelatedData(Item: Record Item)
    var
        TroubleshootingSetup: Record "Troubleshooting Setup";
        ResourceSkillMgt: Codeunit "Resource Skill Mgt.";
    begin
        TroubleshootingSetup.Reset();
        TroubleshootingSetup.SetRange(Type, "Troubleshooting Item Type"::Item);
        TroubleshootingSetup.SetRange("No.", Item."No.");
        TroubleshootingSetup.DeleteAll();

        ResourceSkillMgt.DeleteItemResSkills(Item."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnGetOrderTypeService', '', false, false)]
    local procedure OnGetOrderTypeService(var OrderType: Enum "Inventory Order Type")
    begin
        OrderType := Microsoft.Foundation.Enums."Inventory Order Type"::Service;
    end;

    // Table Resource

    [EventSubscriber(ObjectType::Table, Database::Resource, 'OnAfterDeleteEvent', '', false, false)]
    local procedure ResourceOnAfterDelete(var Rec: Record Resource; RunTrigger: Boolean)
    var
        ResourceSkill: Record "Resource Skill";
        ResourceLocation: Record "Resource Location";
        ResourceServiceZone: Record "Resource Service Zone";
    begin
        if Rec.IsTemporary() or (not RunTrigger) then
            exit;

        ResourceSkill.Reset();
        ResourceSkill.SetRange(Type, "Resource Skill Type"::Resource);
        ResourceSkill.SetRange("No.", Rec."No.");
        ResourceSkill.DeleteAll();

        ResourceLocation.Reset();
        ResourceLocation.SetCurrentKey("Resource No.", "Starting Date");
        ResourceLocation.SetRange("Resource No.", Rec."No.");
        ResourceLocation.DeleteAll();

        ResourceServiceZone.Reset();
        ResourceServiceZone.SetRange("Resource No.", Rec."No.");
        ResourceServiceZone.DeleteAll();
    end;

    // Codeunit "Data Privacy Mgmt"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::System.Privacy."Data Privacy Mgmt", 'OnAfterIsContactPersonTable', '', false, false)]
    local procedure OnAfterIsContactPersonTable(TableNo: Integer; var Result: Boolean)
    begin
        Result := Result or
                    (TableNo in [
                                Database::"Service Header",
                                Database::"Service Contract Header",
                                Database::"Service Shipment Header",
                                Database::"Service Invoice Header",
                                Database::"Service Cr.Memo Header",
                                Database::"Filed Service Contract Header",
                                Database::"Service Header Archive"]);
    end;

    // Codeunit "Calendar Management"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calendar Management", 'OnFillSourceRec', '', false, false)]
    local procedure CalendarManagementOnFillSourceRec(var CustomCalendarChange: Record "Customized Calendar Change"; RecRef: RecordRef)
    begin
        if RecRef.Number = Database::"Service Mgt. Setup" then
            SetSourceServiceMgtSetup(RecRef, CustomCalendarChange);
    end;

    local procedure SetSourceServiceMgtSetup(RecRef: RecordRef; var CustomCalendarChange: Record "Customized Calendar Change")
    var
        ServMgtSetup: Record "Service Mgt. Setup";
    begin
        RecRef.SetTable(ServMgtSetup);
        CustomCalendarChange.SetSource(CustomCalendarChange."Source Type"::Service, '', '', ServMgtSetup."Base Calendar Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calendar Management", 'OnCreateWhereUsedEntries', '', false, false)]
    local procedure OnCreateWhereUsedEntries(BaseCalendarCode: Code[10]; sender: Codeunit "Calendar Management")
    var
        ServMgtSetup: Record "Service Mgt. Setup";
        WhereUsedBaseCalendar: Record "Where Used Base Calendar";
    begin
        if ServMgtSetup.Get() then
            if ServMgtSetup."Base Calendar Code" = BaseCalendarCode then begin
                WhereUsedBaseCalendar.Init();
                WhereUsedBaseCalendar."Base Calendar Code" := ServMgtSetup."Base Calendar Code";
                WhereUsedBaseCalendar."Source Type" := WhereUsedBaseCalendar."Source Type"::Service;
                WhereUsedBaseCalendar."Source Name" := CopyStr(ServMgtSetup.TableCaption(), 1, MaxStrLen(WhereUsedBaseCalendar."Source Name"));
                WhereUsedBaseCalendar."Customized Changes Exist" := sender.CustomizedChangesExist(ServMgtSetup);
                WhereUsedBaseCalendar.Insert();
            end;
    end;

    // Table "Customized Calendar Change"

    [EventSubscriber(ObjectType::Table, Database::"Customized Calendar Change", 'OnAfterCalcCalendarCode', '', false, false)]
    local procedure OnAfterCalcCalendarCode(var CustomizedCalendarChange: Record "Customized Calendar Change")
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        if CustomizedCalendarChange."Source Type" = CustomizedCalendarChange."Source Type"::Service then
            if ServiceMgtSetup.Get() then
                CustomizedCalendarChange."Base Calendar Code" := ServiceMgtSetup."Base Calendar Code";
    end;

    // Table "Customized Calendar Entry"

    [EventSubscriber(ObjectType::Table, Database::"Customized Calendar Entry", 'OnGetCaptionOnCaseElse', '', false, false)]
    local procedure OnGetCaptionOnCaseElse(var CustomizedCalendarEntry: Record "Customized Calendar Entry"; var TableCaption: Text[250])
    var
        ServMgtSetup: Record "Service Mgt. Setup";
    begin
        if CustomizedCalendarEntry."Source Type" = CustomizedCalendarEntry."Source Type"::Service then
            if ServMgtSetup.Get() then
                TableCaption := CustomizedCalendarEntry."Source Code" + ' ' + ServMgtsetup.TableCaption();
    end;

    // Codeunit "CRM Statistics Job"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Statistics Job", 'OnAfterAddCustomersWithLinesActivity', '', false, false)]
    local procedure OnAfterAddCustomersWithLinesActivity(StartDateTime: DateTime; var CustomerNumbers: List of [Code[20]])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetFilter(SystemModifiedAt, '>' + Format(StartDateTime));
        if ServiceLine.FindSet() then
            repeat
                if not CustomerNumbers.Contains(ServiceLine."Customer No.") then
                    CustomerNumbers.Add(ServiceLine."Customer No.");
            until ServiceLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Statistics Job", 'OnCreateOrUpdateCRMAccountStatisticsOnBeforeModify', '', false, false)]
    local procedure OnCreateOrUpdateCRMAccountStatisticsOnBeforeModify(var CRMAccountStatistics: Record "CRM Account Statistics"; var Customer: Record Customer)
    begin
        Customer.CalcFields(
            "Outstanding Serv. Orders (LCY)", "Serv Shipped Not Invoiced(LCY)", "Outstanding Serv.Invoices(LCY)");
        CRMAccountStatistics."Outstanding Serv Orders (LCY)" := Customer."Outstanding Serv. Orders (LCY)";
        CRMAccountStatistics."Serv Shipped Not Invd (LCY)" := Customer."Serv Shipped Not Invoiced(LCY)";
        CRMAccountStatistics."Outstd Serv Invoices (LCY)" := Customer."Outstanding Serv.Invoices(LCY)";
    end;

    // Codeunit "Email Scenario Mapping"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::System.EMail."Email Scenario Mapping", 'OnAfterFromReportSelectionUsage', '', false, false)]
    local procedure OnAfterFromReportSelectionUsage(ReportSelectionUsage: Enum "Report Selection Usage"; var EmailScenario: Enum "Email Scenario")
    begin
        case ReportSelectionUsage of
            ReportSelectionUsage::"SM.Quote":
                EmailScenario := EmailScenario::"Service Quote";
            ReportSelectionUsage::"SM.Order":
                EmailScenario := EmailScenario::"Service Order";
            ReportSelectionUsage::"SM.Invoice":
                EmailScenario := EmailScenario::"Service Invoice";
            ReportSelectionUsage::"SM.Credit Memo":
                EmailScenario := EmailScenario::"Service Credit Memo";
        end;
    end;

    // Codeunit "Calc. Item Plan - Plan Wksh."

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Microsoft.Manufacturing.Planning."Calc. Item Plan - Plan Wksh.", 'OnPlanThisItemOnBeforeExitMPS', '', false, false)]
    local procedure OnPlanThisItemOnBeforeExitMPS(var Item: Record Item; var LinesExist: Boolean)
    var
        ServiceLine: Record "Service Line";
    begin
        LinesExist := ServiceLine.LinesWithItemToPlanExist(Item);
    end;

    // Codeunit "Instruction Mgt."

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Instruction Mgt.", 'OnShowPostedDocumentOnBeforePageRun', '', false, false)]
    local procedure OnShowPostedDocumentOnBeforePageRun(RecVariant: Variant; var PageId: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVariant);
        case RecRef.Number of
            DataBase::"Service Invoice Header":
                PageId := Page::"Posted Service Invoice";
            DataBase::"Service Cr.Memo Header":
                PageId := Page::"Posted Service Credit Memo";
        end;
    end;

    // Table "Error Handling Parameters"

    [EventSubscriber(ObjectType::Table, Database::"Error Handling Parameters", 'OnAfterFromArgs', '', false, false)]
    local procedure OnAfterFromArgs(var ErrorHandlingParameters: Record "Error Handling Parameters" temporary; var Args: Dictionary of [Text, Text])
    begin
        ErrorHandlingParameters."Service Document Type" := GetServiceDocTypeParameterValue(Args, ErrorHandlingParameters.FieldName("Service Document Type"));
    end;

    local procedure GetServiceDocTypeParameterValue(Args: Dictionary of [Text, Text]; ParameterName: Text) ServiceDocType: Enum "Service Document Type"
    var
        ParamValueAsText: Text;
    begin
        ParamValueAsText := Args.Get(ParameterName);
        Evaluate(ServiceDocType, ParamValueAsText);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Error Handling Parameters", 'OnAfterToArgs', '', false, false)]
    local procedure OnAfterToArgs(var ErrorHandlingParameters: Record "Error Handling Parameters" temporary; var Args: Dictionary of [Text, Text])
    begin
        Args.Add(ErrorHandlingParameters.FieldName("Service Document Type"), Format(ErrorHandlingParameters."Service Document Type"));
    end;

    // Table "Certificate of Supply"

    [EventSubscriber(ObjectType::Table, Database::"Certificate of Supply", 'OnBeforeInitRecord', '', false, false)]
    local procedure CertificateofSupplyOnBeforeInitRecord(var CertificateOfSupply: Record "Certificate of Supply"; DocumentType: Option; DocumentNo: Code[20]; var IsHandled: Boolean)
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        case Microsoft.Foundation.Enums."Supply Document Type".FromInteger(DocumentType) of
            CertificateOfSupply."Document Type"::"Service Shipment":
                begin
                    ServiceShipmentHeader.Get(DocumentNo);
                    ServiceShipmentHeader.InitCertificateOfSupply(CertificateOfSupply);
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Certificate of Supply", 'OnPrint', '', false, false)]
    local procedure CertificateofSupplyOnPrint(var CertificateOfSupply: Record "Certificate of Supply")
    begin
        if CertificateOfSupply."Document Type" = CertificateOfSupply."Document Type"::"Service Shipment" then
            Report.RunModal(Report::"Service Certificate of Supply", true, false, CertificateOfSupply);
    end;

    // Codeunit "Report Selection Mgt."
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Selection Mgt.", 'OnBeforeInitReportSelectionServ', '', false, false)]
    local procedure OnBeforeInitReportSelectionServ()
    var
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
    begin
        ReportSelectionMgt.InitReportSelection("Report Selection Usage"::"SM.Quote");
        ReportSelectionMgt.InitReportSelection("Report Selection Usage"::"SM.Order");
        ReportSelectionMgt.InitReportSelection("Report Selection Usage"::"SM.Invoice");
        ReportSelectionMgt.InitReportSelection("Report Selection Usage"::"SM.Credit Memo");
        ReportSelectionMgt.InitReportSelection("Report Selection Usage"::"SM.Shipment");
        ReportSelectionMgt.InitReportSelection("Report Selection Usage"::"SM.Contract Quote");
        ReportSelectionMgt.InitReportSelection("Report Selection Usage"::"SM.Contract");
        ReportSelectionMgt.InitReportSelection("Report Selection Usage"::"SM.Test");
        ReportSelectionMgt.InitReportSelection("Report Selection Usage"::"SM.Item WorkSheet");
    end;

    // Codeunit AvailabilityManagement

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnAfterShouldCalculateAvailableToPromise', '', false, false)]
    local procedure OnAfterShouldCalculateAvailableToPromise(var OrderPromisingLine: Record "Order Promising Line"; var ShouldCalculate: Boolean)
    begin
        ShouldCalculate := ShouldCalculate or (OrderPromisingLine."Source Type" = OrderPromisingLine."Source Type"::"Service Order");
    end;

    // Codeunit "Available Management"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Available Management", 'OnCalcAvailableQtyOnAfterCalculation', '', false, false)]
    local procedure OnCalcAvailableQtyOnAfterCalculation(var CopyOfItem: Record Item; var AvailableQty: Decimal)
    begin
        CopyOfItem.CalcFields("Qty. on Service Order");
        AvailableQty -= CopyOfItem."Qty. on Service Order";
    end;

    // Codeunit "Available To Promise"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Available to Promise", 'OnAfterCalcGrossRequirement', '', false, false)]
    local procedure OnAfterCalcGrossRequirement(var Item: Record Item; var GrossRequirement: Decimal)
    begin
        Item.CalcFields("Qty. on Service Order");
        GrossRequirement += Item."Qty. on Service Order";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Available to Promise", 'OnAfterCalcReservedRequirement', '', false, false)]
    local procedure OnAfterCalcReservedRequirement(var Item: Record Item; var ReservedRequirement: Decimal)
    begin
        Item.CalcFields("Res. Qty. on Service Orders");
        ReservedRequirement += Item."Res. Qty. on Service Orders";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Available to Promise", 'OnAfterCalcReservedRequirement', '', false, false)]
    local procedure OnCalcAllItemFieldsOnAfterItemCalcFields(var Item: Record Item)
    begin
        Item.CalcFields("Qty. on Service Order", "Res. Qty. on Service Orders");
    end;

    // Codeunit "Calc. Availability Overview"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnAfterCalcDemandRunningTotal', '', false, false)]
    local procedure OnAfterCalcDemandRunningTotal(var Item: Record Item; var DemandRunningTotal: Decimal)
    begin
        Item.CalcFields("Qty. on Service Order", "Res. Qty. on Service Orders");
        DemandRunningTotal -= (Item."Qty. on Service Order" + Item."Res. Qty. on Service Orders");
    end;

    // Codeunit "Item Availability Forms Mgt"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Availability Forms Mgt", 'OnCalculateNeedOnAfterCalcGrossRequirement', '', false, false)]
    local procedure OnCalculateNeedOnAfterCalcGrossRequirement(var Item: Record Item; var GrossRequirement: Decimal)
    begin
        GrossRequirement += Item."Qty. on Service Order";
    end;

    // Page "Item Availability Line List"

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnItemCalcFields', '', false, false)]
    local procedure OnItemCalcFields(var Item: Record Item)
    begin
        Item.CalcFields("Qty. on Service Order");
    end;

    // Page "Item Availability Lines"

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Lines", 'OnAfterCalcAvailQuantities', '', false, false)]
    local procedure OnAfterCalcAvailQuantities(var Item: Record Item; var ItemAvailabilityBuffer: Record "Item Availability Buffer")
    begin
        ItemAvailabilityBuffer."Qty. on Service Order" := Item."Qty. on Service Order";
    end;

    // Page "Res. Availability Lines"

    [EventSubscriber(ObjectType::Page, Page::"Res. Availability Lines", 'OnAfterCalcLine', '', false, false)]
    local procedure ResAvailabilityLinesOnAfterCalcLine(var Resource: Record Resource; var ResAvailabilityBuffer: Record "Res. Availability Buffer"; var NetAvailability: Decimal)
    begin
        Resource.CalcFields("Qty. on Service Order");
        ResAvailabilityBuffer."Qty. on Service Order" := Resource."Qty. on Service Order";
        ResAvailabilityBuffer."Net Availability" -= Resource."Qty. on Service Order";
        NetAvailability -= Resource."Qty. on Service Order";
    end;

    // Page "Res. Availability Lines"

    [EventSubscriber(ObjectType::Page, Page::"Res. Gr. Availability Lines", 'OnAfterCalcLine', '', false, false)]
    local procedure ResGrAvailabilityLinesOnAfterCalcLine(var ResourceGroup: Record "Resource Group"; var ResGrAvailabilityBuffer: Record "Res. Gr. Availability Buffer")
    begin
        ResourceGroup.CalcFields("Qty. on Service Order");
        ResGrAvailabilityBuffer."Availability After Orders" -= ResourceGroup."Qty. on Service Order";
        ResGrAvailabilityBuffer."Qty. on Service Order" := ResourceGroup."Qty. on Service Order";
    end;

    // Codeunit "Config. Management"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::System.IO."Config. Management", 'OnFindPage', '', false, false)]
    local procedure OnFindPage(TableID: Integer; var PageID: Integer)
    begin
        case TableID of
            Database::Microsoft.Service.Setup."Service Mgt. Setup":
                PageID := Page::Microsoft.Service.Setup."Service Mgt. Setup";
            Database::Microsoft.Service.Item."Service Item":
                PageID := Page::Microsoft.Service.Item."Service Item List";
            Database::Microsoft.Service.Contract."Service Hour":
                PageID := Page::Microsoft.Service.Contract."Default Service Hours";
            Database::Microsoft.Service.Setup."Work-Hour Template":
                PageID := Page::Microsoft.Service.Setup."Work-Hour Templates";
            Database::Microsoft.Service.Resources."Resource Service Zone":
                PageID := Page::Microsoft.Service.Resources."Resource Service Zones";
            Database::Microsoft.Service.Loaner.Loaner:
                PageID := Page::Microsoft.Service.Loaner."Loaner List";
            Database::Microsoft.Service.Setup."Skill Code":
                PageID := Page::Microsoft.Service.Setup."Skill Codes";
            Database::Microsoft.Service.Maintenance."Fault Reason Code":
                PageID := Page::Microsoft.Service.Maintenance."Fault Reason Codes";
            Database::Microsoft.Service.Pricing."Service Cost":
                PageID := Page::Microsoft.Service.Pricing."Service Costs";
            Database::Microsoft.Service.Setup."Service Zone":
                PageID := Page::Microsoft.Service.Setup."Service Zones";
            Database::Microsoft.Service.Setup."Service Order Type":
                PageID := Page::Microsoft.Service.Setup."Service Order Types";
            Database::Microsoft.Service.Item."Service Item Group":
                PageID := Page::Microsoft.Service.Item."Service Item Groups";
            Database::Microsoft.Service.Setup."Service Shelf":
                PageID := Page::Microsoft.Service.Setup."Service Shelves";
            Database::Microsoft.Service.Document."Service Status Priority Setup":
                PageID := Page::Microsoft.Service.Document."Service Order Status Setup";
            Database::Microsoft.Service.Maintenance."Repair Status":
                PageID := Page::Microsoft.Service.Maintenance."Repair Status Setup";
            Database::Microsoft.Service.Pricing."Service Price Group":
                PageID := Page::Microsoft.Service.Pricing."Service Price Groups";
            Database::Microsoft.Service.Pricing."Serv. Price Group Setup":
                PageID := Page::Microsoft.Service.Pricing."Serv. Price Group Setup";
            Database::Microsoft.Service.Pricing."Service Price Adjustment Group":
                PageID := Page::Microsoft.Service.Pricing."Serv. Price Adjmt. Group";
            Database::Microsoft.Service.Pricing."Serv. Price Adjustment Detail":
                PageID := Page::Microsoft.Service.Pricing."Serv. Price Adjmt. Detail";
            Database::Microsoft.Service.Maintenance."Resolution Code":
                PageID := Page::Microsoft.Service.Maintenance."Resolution Codes";
            Database::Microsoft.Service.Maintenance."Fault Area":
                PageID := Page::Microsoft.Service.Maintenance."Fault Areas";
            Database::Microsoft.Service.Maintenance."Symptom Code":
                PageID := Page::Microsoft.Service.Maintenance."Symptom Codes";
            Database::Microsoft.Service.Maintenance."Fault Code":
                PageID := Page::Microsoft.Service.Maintenance."Fault Codes";
            Database::Microsoft.Service.Maintenance."Fault/Resol. Cod. Relationship":
                PageID := Page::Microsoft.Service.Maintenance."Fault/Resol. Cod. Relationship";
            Database::Microsoft.Service.Contract."Contract Group":
                PageID := Page::Microsoft.Service.Contract."Service Contract Groups";
            Database::Microsoft.Service.Contract."Service Contract Template":
                PageID := Page::Microsoft.Service.Contract."Service Contract Template";
            Database::Microsoft.Service.Contract."Service Contract Account Group":
                PageID := Page::Microsoft.Service.Contract."Serv. Contract Account Groups";
            Database::Microsoft.Service.Maintenance."Troubleshooting Header":
                PageID := Page::Microsoft.Service.Maintenance.Troubleshooting;
        end;
    end;

    // Codeunit "Sales Availability Mgt."

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Availability Mgt.", 'OnOpenPageOnSetSourceOnAfterSetShouldExit', '', false, false)]
    local procedure OnOpenPageOnSetSourceOnAfterSetShouldExit(CrntSourceType: Enum "Order Promising Line Source Type"; var ShouldExit: Boolean)
    begin
        ShouldExit := ShouldExit or (CrntSourceType = "Order Promising Line Source Type"::"Service Order");
    end;

    // Codeunit "Apply Retention Policy"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Apply Retention Policy", 'OnApplyRetentionPolicyIndirectPermissionRequired', '', true, true)]
    local procedure DeleteRecordsWithIndirectPermissionsOnApplyRetentionPolicyIndirectPermissionRequired(var RecRef: RecordRef; var Handled: Boolean)
    var
        RetentionPolicyLog: Codeunit "Retention Policy Log";
    begin
        // if someone else took it, exit
        if Handled then
            exit;

        // check if we can handle the table
        if not (RecRef.Number in [
            Database::"Filed Service Contract Header",
            Database::"Service Header Archive"])
        then
            exit;

        // if no filters have been set, something is wrong.
        if (RecRef.GetFilters() = '') or (not RecRef.MarkedOnly()) then
            RetentionPolicyLog.LogError(LogCategory(), StrSubstNo(NoFiltersErr, RecRef.Number, RecRef.Name));

        // delete all remaining records
        RecRef.DeleteAll(true);

        // set handled
        Handled := true;
    end;

    local procedure LogCategory(): Enum "Retention Policy Log Category"
    var
        RetentionPolicyLogCategory: Enum "Retention Policy Log Category";
    begin
        exit(RetentionPolicyLogCategory::"Retention Policy - Apply");
    end;

    // Page extension "Reten. Pol. Setup Lines Ext." extends "Retention Policy Setup Lines"

    [EventSubscriber(ObjectType::Page, Page::"Retention Policy Setup Lines", 'OnAfterSetIsDocumentArchiveTable', '', true, true)]
    local procedure SetIsDocumentArchiveTable_OnAfterSetIsDocumentArchiveTable(TableId: Integer; var IsDocumentArchiveTable: Boolean)
    begin
        IsDocumentArchiveTable := IsDocumentArchiveTable or (TableId in [Database::"Filed Service Contract Header", Database::"Service Header Archive"]);
    end;

    // Codeunit "Reten. Pol. Doc. Arch. Fltrng."

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reten. Pol. Doc. Arch. Fltrng.", 'OnIsMaxArchivedVersionOnCaseElse', '', true, true)]
    local procedure ServiceArchive_OnIsMaxArchivedVersionOnCaseElse(RecRef: RecordRef; var VersionFieldRef: FieldRef; var MaxVersionFieldRef: FieldRef; var MatchingTableFound: Boolean)
    var
        FiledServiceContractHeader: Record "Filed Service Contract Header";
        ServiceHeaderArchive: Record "Service Header Archive";
    begin
        case RecRef.Number() of
            Database::"Filed Service Contract Header":
                begin
                    VersionFieldRef := RecRef.Field(FiledServiceContractHeader.FieldNo("Entry No."));
                    MaxVersionFieldRef := RecRef.Field(FiledServiceContractHeader.FieldNo("No. of Filed Versions"));
                    MatchingTableFound := true;
                end;
            Database::"Service Header Archive":
                begin
                    VersionFieldRef := RecRef.Field(ServiceHeaderArchive.FieldNo("Version No."));
                    MaxVersionFieldRef := RecRef.Field(ServiceHeaderArchive.FieldNo("No. of Archived Versions"));
                    MatchingTableFound := true;
                end;
        end;
    end;

    // Codeunit "Reten. Pol. Install - BaseApp"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reten. Pol. Install - BaseApp", 'OnAfterAddDocumentArchiveTablesToAllowedTables', '', true, true)]
    local procedure InstallRetentionPolicies_OnAfterAddDocumentArchiveTablesToAllowedTables()
    var
        FiledServiceContractHeader: Record "Filed Service Contract Header";
        ServiceHeaderArchive: Record "Service Header Archive";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        RecRef: RecordRef;
        TableFilters: JsonArray;
    begin
        FiledServiceContractHeader.SetRange("Source Contract Exists", true);
        RecRef.GetTable(FiledServiceContractHeader);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"Never Delete", FiledServiceContractHeader.FieldNo("Last Filed DateTime"), true, true, RecRef); // locked
        FiledServiceContractHeader.Reset();
        RetenPolAllowedTables.AddAllowedTable(Database::"Filed Service Contract Header", FiledServiceContractHeader.FieldNo("Last Filed DateTime"), 0, "Reten. Pol. Filtering"::"Document Archive Filtering", "Reten. Pol. Deleting"::Default, TableFilters);

        Clear(TableFilters);
        ServiceHeaderArchive.SetRange("Source Doc. Exists", true);
        RecRef.GetTable(ServiceHeaderArchive);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"Never Delete", ServiceHeaderArchive.FieldNo("Last Archived Date"), true, true, RecRef); // locked
        ServiceHeaderArchive.Reset();
        ServiceHeaderArchive.SetRange("Interaction Exist", true);
        RecRef.GetTable(ServiceHeaderArchive);
        RetenPolAllowedTables.AddTableFilterToJsonArray(TableFilters, "Retention Period Enum"::"Never Delete", ServiceHeaderArchive.FieldNo("Last Archived Date"), true, false, RecRef); // not locked
        RetenPolAllowedTables.AddAllowedTable(Database::"Service Header Archive", ServiceHeaderArchive.FieldNo("Last Archived Date"), 0, "Reten. Pol. Filtering"::"Document Archive Filtering", "Reten. Pol. Deleting"::Default, TableFilters);
    end;
}

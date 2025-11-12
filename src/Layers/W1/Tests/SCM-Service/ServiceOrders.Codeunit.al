// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Service.Analysis;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Loaner;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Posting;
using Microsoft.Service.Pricing;
using Microsoft.Service.Reports;
using Microsoft.Service.Resources;
using Microsoft.Service.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.IO;
using System.Security.User;
using System.TestLibraries.Utilities;

codeunit 136101 "Service Orders"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Service]
        IsInitialized := false;
    end;

    var
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryResource: Codeunit "Library - Resource";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryDimension: Codeunit "Library - Dimension";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryTemplates: Codeunit "Library - Templates";
        IsInitialized: Boolean;
        UnknownErr: Label 'Unknown error: %1', Comment = '%1 = error message';
        OrderTypeMandatoryTxt: Label 'You have not specified the Service Order Type for Service Header Document Type=%1, No.=%2.', Comment = '%1 = doc. type, %2 = doc. no.';
        CustomerDeletionErr: Label 'You cannot delete customer %1 because there is at least one outstanding Service Order for this customer.', Comment = '%1 = customer no.';
        ServItemDeletionErr: Label 'You cannot delete Service Item %1,because it is attached to a service order.', Comment = '%1 = item no.';
        RecordExistErr: Label '%1 %2 : %3 must not exist.', Comment = '%1=Table name,%2= Field name,%3=Field value';
        ServiceItemLineExistErr: Label '%1 must not exist.', Comment = '%1 = Service Item Line table name';
        TotalAmountErr: Label 'Total Amount must be %1 in %2 table for %3 field : %4.', Comment = '%1 = amount,%2 = table name,%3 = field name,%4 = expected value';
        GlAccountTotalAmountErr: Label 'Total Amount must be  %1 in %2 table for %3=%4,%5=%6', Comment = '%2=G/L Entry;%3=Document No.;%5=G/L Account No.';
        DiscountAmountErr: Label '%1 must be %2 in %3.', Comment = '%1 = field name,%2 = value,%3 = table name';
        ServiceLineCountErr: Label 'Service Line count not matched.';
        VATAmountErr: Label '%1 must be equal to ''%2''  in %3: %4=%5. Current value is ''%6''.', Comment = '%1=Field name,%2=Field value,%3=Table name,%4=Field name,%5=Field value,%6=Field value';
        NoOfLinesErr: Label 'No. of lines in %1 must be %2.', Comment = '%1=Table name,%2=Value';
        WrongValueErr: Label '%1 must be %2 in %3.', Comment = '%1=Field Caption,%2=Field Value,%3=Table Caption';
        NextInvoicePeriodTxt: Label '%1 to %2', Comment = '%1 = Starting Date,%2 = Ending Date';
        PriceUpdatePeriodErr: Label 'Price Update Period cannot be less than Invoice Period';
        ServiceItemNoErr: Label 'Service Item No. must exist on Service Item Line.';
        VendorNoErr: Label 'Vendor No. must have a value in Service Item Line:';
        ServiceLineErr: Label 'Service Line must exists with Service Item No. %1.', Comment = '%1 = service item no.';
        ServiceLineLineNoErr: Label 'Service Line must exist with %1 value = %2', Comment = '%1 = field, %2 = value';
        NoOfEntriesMsg: Label 'Number of entries must be equal.';
        ServShiptItemLineWrongCountErr: Label 'Wrong Service Shipment Item Line count.';
        LoanerEntryDoesNotExistErr: Label 'Loaner Entry does not exist.';
        LoanerEntryExistsErr: Label 'Loaner Entry exists.';
        LoanerNoIsNotEmptyErr: Label 'Loaner No. is not empty.';
        ThereIsNotEnoughSpaceToInsertErr: Label 'There is not enough space to insert %1.', Comment = '%1 = field';
        PostedDocsToPrintCreatedMsg: Label 'One or more related posted documents have been generated during deletion to fill gaps in the posting number series. You can view or print the documents from the respective document archive.';
        EmptyGenProdPostingGroupErr: Label 'Gen. Prod. Posting Group must have a value in Item Template';
        EmptyInventoryPostingGroupErr: Label 'Inventory Posting Group must have a value in Item Template';
        RoundingTo0Err: Label 'Rounding of the field';
        RoundingErr: Label 'is of lower precision than expected';
        RoundingBalanceErr: Label 'This will cause the quantity and base quantity fields to be out of balance.';
        UnitCostErr: Label 'Unit Cost are Not equal.';
        AvailableExpectedQuantityErr: Label 'Available expected quantity must be %1.', Comment = '%1=Value';
        VATCountryRegionLbl: Label 'VAT Country/Region Code must be %1', Comment = '%1 = Country/Region Code';
        ServiceOrderErr: Label 'Service Order does not exist.';
        ServiceOrderStatusShouldChangedErr: Label 'Service Header Status should have changed when adding Service Item';

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderType()
    var
        ServiceHeader: Record "Service Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // Covers document number TC0117 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test error occurs on Posting Service Order with "Service Order Type Mandatory" True on Service Management Setup.

        // [GIVEN] Set "Service Order Type Mandatory" field True on Service Management Setup.
        Initialize();
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Service Order Type Mandatory", true);
        ServiceMgtSetup.Modify(true);

        // [WHEN] Create Service Order.
        CreateServiceOrder(ServiceHeader, '');

        // [THEN] Verify that the Service Order shows "Service Order Type" Mandatory error when we Post it as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        Assert.AreEqual(
          StrSubstNo(OrderTypeMandatoryTxt, ServiceHeader."Document Type", ServiceHeader."No."), GetLastErrorText,
          StrSubstNo(UnknownErr, GetLastErrorText));

        // 4. Teardown: Rollback "Service Order Type Mandatory" field as false on Service Management Setup.
        ServiceMgtSetup.Validate("Service Order Type Mandatory", false);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderStart()
    var
        ServiceHeader: Record "Service Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // Covers document number TC0117 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test error occurs on Posting Service Order with "Service Order Start Mandatory" True on Service Management Setup.

        // [GIVEN] Set "Service Order Start Mandatory" field True on Service Management Setup.
        Initialize();
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Service Order Start Mandatory", true);
        ServiceMgtSetup.Modify(true);

        // [WHEN] Create Service Order.
        CreateServiceOrder(ServiceHeader, '');

        // [THEN] Verify that the Service Order shows "Service Order Starting Date" Mandatory error when we Post it as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        Assert.ExpectedTestFieldError(ServiceHeader.FieldCaption("Starting Date"), '');

        // 4. Teardown: Rollback "Service Order Start Mandatory" field as false on Service Management Setup.
        ServiceMgtSetup.Validate("Service Order Start Mandatory", false);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderFinish()
    var
        ServiceHeader: Record "Service Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // Covers document number TC0117 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test error occurs on Posting Service Order with "Service Order Finish Mandatory" True on Service Management Setup.

        // [GIVEN] Set "Service Order Finish Mandatory" field True on Service Management Setup.
        Initialize();
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Service Order Finish Mandatory", true);
        ServiceMgtSetup.Modify(true);

        // [WHEN] Create Service Order.
        CreateServiceOrder(ServiceHeader, '');

        // [THEN] Verify that the Service Order shows "Service Order Finishing Date" Mandatory error when we Post it as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        Assert.ExpectedTestFieldError(ServiceHeader.FieldCaption("Finishing Date"), '');

        // 4. Teardown: Rollback "Service Order Finish Mandatory" field as false on Service Management Setup.
        ServiceMgtSetup.Validate("Service Order Finish Mandatory", false);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FaultReasonCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceItemLine: Record "Service Item Line";
        ServiceItemLineNo: Integer;
    begin
        // Covers document number TC0117 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test error occurs on Posting Service Order with "Fault Reason Code Mandatory" True on Service Management Setup.

        // [GIVEN] Set "Fault Reason Code Mandatory" field True on Service Management Setup.
        Initialize();
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Fault Reason Code Mandatory", true);
        ServiceMgtSetup.Modify(true);

        // [WHEN] Create Service Order.
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader, '');

        // [THEN] Verify that the Service Order shows "Fault Reason Code" Mandatory error when we Post it as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        Assert.ExpectedTestFieldError(ServiceItemLine.FieldCaption("Fault Reason Code"), '');

        // 4. Teardown: Rollback "Fault Reason Code Mandatory" field as false on Service Management Setup.
        ServiceMgtSetup.Validate("Fault Reason Code Mandatory", false);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPersonCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number TC0117 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test error occurs on Posting Service Order with "Salesperson Mandatory" True on Service Management Setup.

        // [GIVEN] Set "Salesperson Mandatory" field True on Service Management Setup.
        Initialize();
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Salesperson Mandatory", true);
        ServiceMgtSetup.Modify(true);

        // [WHEN] Create Service Order, Update Salesperson Code on Service Header.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        ServiceHeader.Validate("Salesperson Code", '');
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        // [THEN] Verify that the Service Order shows "Salesperson" Mandatory error when we Post it as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        Assert.ExpectedTestFieldError(ServiceHeader.FieldCaption("Salesperson Code"), '');

        // 4. Teardown: Rollback "Salesperson Mandatory" field as false on Service Management Setup.
        ServiceMgtSetup.Validate("Salesperson Mandatory", false);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkTypeCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        Resource: Record Resource;
        ServiceItemLineNo: Integer;
    begin
        // Covers document number TC0117 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test error occurs on Posting Service Order with "Work Type Code Mandatory" True on Service Management Setup.

        // [GIVEN] Set "Work Type Code Mandatory" field True on Service Management Setup.
        Initialize();
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Work Type Code Mandatory", true);
        ServiceMgtSetup.Modify(true);

        // [WHEN] Create Service Order.
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader, '');

        LibraryResource.FindResource(Resource);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.");
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLineNo);

        // [THEN] Verify that the Service Order shows "Work Type Code" Mandatory error when we Post it as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        Assert.ExpectedTestFieldError(ServiceLine.FieldCaption("Work Type Code"), '');

        // 4. Teardown: Rollback "Work Type Code Mandatory" field as false on Service Management Setup.
        ServiceMgtSetup.Validate("Work Type Code Mandatory", false);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitOfMeasureCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceItemLineNo: Integer;
    begin
        // Covers document number TC0117 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test error occurs on Posting Service Order with "Unit of Measure Mandatory" True on Service Management Setup.

        // [GIVEN] Set "Unit of Measure Mandatory" field True on Service Management Setup, Create Service Order.
        Initialize();
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Unit of Measure Mandatory", true);
        ServiceMgtSetup.Modify(true);
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, '');
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLineNo);

        // [WHEN] Update Unit of Measure Code on Service Line.
        ServiceLine.Validate("Unit of Measure Code", '');
        ServiceLine.Modify(true);

        // [THEN] Verify that the Service Order shows "Unit of Measure Code" Mandatory error when we Post it as Ship.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        Assert.ExpectedTestFieldError(ServiceLine.FieldCaption("Unit of Measure Code"), '');

        // 4. Teardown: Rollback "Unit of Measure Mandatory" field as false on Service Management Setup.
        ServiceMgtSetup.Validate("Unit of Measure Mandatory", false);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderNoSetWhilePostingServInvCreatedByGetShipmentLines()
    var
        ServiceHeader: Record "Service Header";
        ServiceHeaderInvoice: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        LinkServiceToServiceItem: Boolean;
    begin
        // [SCENARIO] Order No. is set on the posted Service Invoice Header when all the Service Invoice lines are linked to the same order.

        // [GIVEN] Set "Link Service to Service Item" field to false on Service Management Setup.
        Initialize();
        ServiceMgtSetup.Get();
        LinkServiceToServiceItem := ServiceMgtSetup."Link Service to Service Item";
        ServiceMgtSetup.Validate("Link Service to Service Item", false);
        ServiceMgtSetup.Modify(true);

        // [GIVEN] Create Service Order and create Service Line with a quantity.
        CreateServiceOrder(ServiceHeader, '');
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, '', 10);

        // [GIVEN] Post 4 shipments for the Service Order.
        // Shipment 1
        ServiceLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        ServiceLine.Validate("Qty. to Ship", 2);
        ServiceLine.Validate("Qty. to Invoice", 0);
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // Shipment 2
        ServiceLine.Find();
        ServiceLine.Validate("Qty. to Ship", 2);
        ServiceLine.Validate("Qty. to Invoice", 0);
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // Shipment 3
        ServiceLine.Find();
        ServiceLine.Validate("Qty. to Ship", 2);
        ServiceLine.Validate("Qty. to Invoice", 0);
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // Shipment 4
        ServiceLine.Find();
        ServiceLine.Validate("Qty. to Ship", 4);
        ServiceLine.Validate("Qty. to Invoice", 0);
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [GIVEN] Create Service Invoice and create Service Lines by running GetShipmentLines method.
        GetServiceShipmentLines(ServiceHeaderInvoice, ServiceHeader."No.", ServiceHeader."Customer No.");

        // [WHEN] Post Service Invoice.
        LibraryService.PostServiceOrder(ServiceHeaderInvoice, true, false, true);

        // [THEN] Posted Service Invoice Header has the 'Order No.' field set.
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        Assert.RecordCount(ServiceInvoiceHeader, 1);

        // [CLENAUP] Rollback "Link Service to Service Item" field as false on Service Management Setup.
        ServiceMgtSetup.Validate("Link Service to Service Item", LinkServiceToServiceItem);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandlerForFalse')]
    [Scope('OnPrem')]
    procedure ContractResponseTimeMandatory()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number TC0117 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test error occurs on Signing Service Contract with "Contract Rsp. Time Mandatory" True on Service Management Setup.

        // [GIVEN] Set "Contract Rsp. Time Mandatory" field True on Service Management Setup, Create and Update Response Time on Service Item.
        Initialize();
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Contract Rsp. Time Mandatory", true);
        ServiceMgtSetup.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, '');
        ServiceItem.Validate("Response Time (Hours)", 0);  // Use 0 to blank Response Time (Hours).
        ServiceItem.Modify(true);
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);

        // [WHEN] Create Service Contract Quote.
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, ServiceItem."Customer No.");
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", ServiceContractAccountGroup.Code);
        ServiceContractHeader.Modify(true);

        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(100));  // Use Random to select Random Line Value.
        ServiceContractLine.Modify(true);
        UpdateServiceContract(ServiceContractHeader);

        // [THEN] Verify that the Service Contract Quote shows "Contract Response Time" Mandatory error when we Make Contract from Quote.
        asserterror SignServContractDoc.SignContractQuote(ServiceContractHeader);
        Assert.ExpectedTestFieldError(ServiceContractLine.FieldCaption("Response Time (Hours)"), '');

        // 4. Teardown: Rollback "Contract Rsp. Time Mandatory" field as false on Service Management Setup.
        ServiceMgtSetup.Validate("Contract Rsp. Time Mandatory", false);
        ServiceMgtSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ShipToCodeOnServiceShipment()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ShipToAddress: Record "Ship-to Address";
        ServiceItem: Record "Service Item";
    begin
        // Covers document number TC0121 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test Ship to Code on Service Shipment Line after Post Service Order as Ship.

        // [GIVEN] Create Service Order with Different Ship to code on Service Item Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        ServiceItem.Validate("Ship-to Code", ShipToAddress.Code);
        ServiceItem.Modify(true);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        SelectDifferentShiptoCode(ShipToAddress);

        Clear(ServiceItem);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        ServiceItem.Validate("Ship-to Code", ShipToAddress.Code);
        ServiceItem.Modify(true);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        Clear(ServiceItem);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLine."Line No.");

        // [WHEN] Post Service Order as Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Verify that the Ship to Code on Service Shipment Item Line is Ship to Code on Service Item on Service Shipment Item Line.
        VerifyShiptoCode(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteQuoteAfterChangeCustomer()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        Item: Record Item;
        ServiceQuoteNo: Code[20];
    begin
        // Covers document number TC0123, TC0124 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test Delete Service Quote after Change Customer No. on Service Quote.

        // [GIVEN] Create Service Quote.
        Initialize();
        CreateServiceDocumentWithServiceItem(ServiceHeader, ServiceItemLine, ServiceHeader."Document Type"::Quote, '');
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate("Item No.", Item."No.");
        ServiceItemLine.Modify(true);

        Item.Next();
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLine."Line No.");

        // [WHEN] Change Customer No. on Service Quote, Delete Service Quote.
        ChangeCustomerOnServiceQuote(ServiceHeader);
        ServiceQuoteNo := ServiceHeader."No.";
        ServiceHeader.Delete(true);

        // [THEN] Verify that the Service Quote not Exist.
        Assert.IsFalse(
          ServiceHeader.Get(ServiceHeader."Document Type"::Quote, ServiceQuoteNo),
          StrSubstNo(RecordExistErr, ServiceHeader.TableCaption(), ServiceHeader.FieldCaption("No."), ServiceQuoteNo));
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CommentsOnServiceOrder()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        TempServiceCommentLine: Record "Service Comment Line" temporary;
        ServiceItemNo: Code[20];
    begin
        // Covers document number TC0122 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test Comments on Service Order create from Service Quote after receiving Loaner on Created Service Order

        // [GIVEN] Create Service Quote and Assign Loaner on Service Quote, Create Comments on Service Quote.
        Initialize();
        CreateServiceDocWithLoaner(ServiceHeader, ServiceItemLine, ServiceHeader."Document Type"::Quote);
        CreateCommentsOnServiceQuote(ServiceItemLine);
        ServiceItemNo := ServiceItemLine."Service Item No.";
        SaveComments(TempServiceCommentLine, ServiceItemLine);

        // [WHEN] Create Service Order from Service Quote, Receive Loaner on Created Service Order.
        CODEUNIT.Run(CODEUNIT::"Service-Quote to Order", ServiceHeader);
        ReceiveLoanerOnServiceOrder(ServiceItemLine, ServiceItemNo);

        // [THEN] Verify that the Comments on Service Order is Comments assign on Service Quote.
        VerifyComments(TempServiceCommentLine, ServiceItemLine);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateHandler')]
    [Scope('OnPrem')]
    procedure CreateCustomerFromServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServOrderManagement: Codeunit ServOrderManagement;
    begin
        // Covers document number TC0118 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test error occurs on Deletion of Customer attached on Service Order.

        // [GIVEN] Create Customer Template.
        Initialize();
        CreateCustomerTemplate();

        // [WHEN] Create Customer from Service Order.
        CreateServiceHeaderWithName(ServiceHeader);
        Commit();
        ServOrderManagement.CreateNewCustomer(ServiceHeader);
        ServiceHeader.Modify(true);

        // [THEN] Verify that the "Outstanding Service Order Exist" error occurs when we delete Customer of Service Order.
        Customer.Get(ServiceHeader."Customer No.");
        asserterror Customer.Delete(true);
        Assert.AreEqual(
          StrSubstNo(CustomerDeletionErr, ServiceHeader."Customer No."), GetLastErrorText,
          StrSubstNo(UnknownErr, GetLastErrorText));
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateServiceItemFromOrder()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServItemManagement: Codeunit ServItemManagement;
    begin
        // Covers document number TC0118 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test error occurs on Deletion of Service Item attached on Service Order.

        // [GIVEN] Create Service Order - Service Header, Service Item Line with Description.
        CreateServItemLineDescription(ServiceItemLine);

        // [WHEN] Create Service Item from Service Order.
        ServItemManagement.CreateServItemOnServItemLine(ServiceItemLine);
        ServiceItemLine.Modify(true);

        // [THEN] Verify that the "Outstanding Service Order Exist" error occurs when we delete Service Item of Service Order.
        ServiceItem.Get(ServiceItemLine."Service Item No.");
        asserterror ServiceItem.Delete(true);
        Assert.AreEqual(
          StrSubstNo(ServItemDeletionErr, ServiceItemLine."Service Item No."), GetLastErrorText,
          StrSubstNo(UnknownErr, GetLastErrorText));
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateHandler')]
    [Scope('OnPrem')]
    procedure DeleteCustomerFromServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServOrderManagement: Codeunit ServOrderManagement;
        CustomerNo: Code[20];
    begin
        // Covers document number TC0118, TC0119 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test Customer delete after deletion of attached Service Order.

        // [GIVEN] Create Customer Template, Create Customer from service Order.
        Initialize();
        CreateCustomerTemplate();
        CreateServiceHeaderWithName(ServiceHeader);
        Commit();
        ServOrderManagement.CreateNewCustomer(ServiceHeader);
        ServiceHeader.Modify(true);

        CustomerNo := ServiceHeader."Customer No.";

        // [WHEN] Delete Service Order, Delete Customer.
        ServiceHeader.Delete(true);
        Customer.Get(ServiceHeader."Customer No.");
        Customer.Delete(true);

        // [THEN] Verify that the Customer not Exist.
        Assert.IsFalse(
          Customer.Get(CustomerNo), StrSubstNo(RecordExistErr, Customer.TableCaption(), Customer.FieldCaption("No."), CustomerNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DescriptionOnPostedInvoiceLine()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [SCENARIO 173928] Test Description correctly populated on Posted Invoice Line.

        // [GIVEN] Create Service Header and Service Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateMultipleServiceLine(ServiceHeader, CreateServiceOrder(ServiceHeader, Customer."No."));
        GetServiceLine(ServiceLine, ServiceHeader);
        CopyServiceLine(TempServiceLine, ServiceLine);

        // [WHEN] Post Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Verify Description on Posted Invoice Line.
        VerifyDescOnPostedInvoiceLine(TempServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteServiceItemFromOrder()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServItemManagement: Codeunit ServItemManagement;
        ServiceItemNo: Code[20];
    begin
        // Covers document number TC0118, TC0119 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test Service Item delete after deletion of attached Service Order.

        // [GIVEN] Create Service Item from Service Order.
        CreateServItemLineDescription(ServiceItemLine);
        ServItemManagement.CreateServItemOnServItemLine(ServiceItemLine);
        ServiceItemLine.Modify(true);

        ServiceItemNo := ServiceItemLine."Service Item No.";

        // [WHEN] Delete Service Order, Delete Service Item.
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        ServiceHeader.Delete(true);
        ServiceItem.Get(ServiceItemNo);
        ServiceItem.Delete(true);

        // [THEN] Verify that the Service Item not Exist.
        Assert.IsFalse(
          ServiceItem.Get(ServiceItemNo),
          StrSubstNo(RecordExistErr, ServiceItem.TableCaption(), ServiceItem.FieldCaption("No."), ServiceItemNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderResponseTimeReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceOrderResponseTime: Report "Service Order - Response Time";
        FilePath: Text[1024];
    begin
        // Covers document number TC0125 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test Service Order - Response Time Report.

        // [GIVEN] Create Service Order - Service Header, Service Item Line, Service Line and Post it as Ship.
        CreateServiceHeaderRespCenter(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [WHEN] Save Service Order - Response Time Report as XML and XLSX in local Temp folder.
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.SetRange("Responsibility Center", ServiceHeader."Responsibility Center");
        ServiceShipmentHeader.FindFirst();
        Clear(ServiceOrderResponseTime);
        ServiceOrderResponseTime.SetTableView(ServiceShipmentHeader);
        FilePath := TemporaryPath + Format(ServiceShipmentHeader."No.") + ServiceShipmentHeader."Responsibility Center" + '.xlsx';
        ServiceOrderResponseTime.SaveAsExcel(FilePath);

        // [THEN] Verify that Saved file has some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemLineLabelsReport()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItemLineLabels: Report "Service Item Line Labels";
        FilePath: Text[1024];
    begin
        // Covers document number TC0125 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test Service Item Line Labels Report.

        // [GIVEN] Create Service Order - Service Header, Service Item and Service Item Line.
        Initialize();
        CreateServiceOrderWithServiceItem(ServiceItemLine);

        // [WHEN] Save Service Item Line Labels Report as XML and XLSX in local Temp folder.
        Clear(ServiceItemLineLabels);
        ServiceItemLineLabels.SetTableView(ServiceItemLine);
        FilePath := TemporaryPath + Format(ServiceItemLine."Document Type") + ServiceItemLine."Document No." + '.xlsx';
        ServiceItemLineLabels.SaveAsExcel(FilePath);

        // [THEN] Verify that Saved file has some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceProfitRespCentersReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceProfitRespCenters: Report "Service Profit (Resp. Centers)";
        FilePath: Text[1024];
    begin
        // Covers document number TC0125 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test Service Profit(Resp. Centers) Report.

        // [GIVEN] Create Service Order - Service Header, Service Item Line, Service Line and Post it as Ship and Invoice.
        CreateServiceHeaderRespCenter(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Save Service Profit(Resp. Centers) Report as XML and XLSX in local Temp folder.
        Clear(ServiceProfitRespCenters);
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.SetRange("Responsibility Center", ServiceHeader."Responsibility Center");
        ServiceShipmentHeader.FindFirst();
        ServiceProfitRespCenters.SetTableView(ServiceShipmentHeader);
        FilePath := TemporaryPath + Format(ServiceShipmentHeader."No.") + ServiceShipmentHeader."Responsibility Center" + '.xlsx';
        ServiceProfitRespCenters.SaveAsExcel(FilePath);

        // [THEN] Verify that Saved file has some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceProfitServOrdersReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceProfitServOrders: Report "Service Profit (Serv. Orders)";
        FilePath: Text[1024];
    begin
        // Covers document number TC0125 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test Service Profit(Serv. Orders) Report.

        // [GIVEN] Create Service Order - Service Header, Service Item Line, Service Line and Post it as Ship and Invoice.
        CreateServiceHeaderRespCenter(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Save Service Profit(Serv. Orders) Report as XML and XLSX in local Temp folder.
        Clear(ServiceProfitServOrders);
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.SetRange("Responsibility Center", ServiceHeader."Responsibility Center");
        ServiceShipmentHeader.FindFirst();
        ServiceProfitServOrders.SetTableView(ServiceShipmentHeader);
        FilePath := TemporaryPath + Format(ServiceShipmentHeader."No.") + ServiceShipmentHeader."Responsibility Center" + '.xlsx';
        ServiceProfitServOrders.SaveAsExcel(FilePath);

        // [THEN] Verify that Saved file has some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceTasksReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        Item: Record Item;
        ServiceTasks: Report "Service Tasks";
        FilePath: Text[1024];
    begin
        // Covers document number TC0125 - refer to TFS ID 21728.
        // [SCENARIO 21728] Test Service Tasks Report.

        // [GIVEN] Create Service Order - Service Header and Service Item Line.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate("Item No.", Item."No.");
        ServiceItemLine.Validate(Priority, ServiceItemLine.Priority::High);
        ServiceItemLine.Modify(true);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        // [WHEN] Save Service Tasks Report as XML and XLSX in local Temp folder.
        Clear(ServiceTasks);
        ServiceTasks.SetTableView(ServiceItemLine);
        FilePath := TemporaryPath + Format(ServiceItemLine."Document Type") + ServiceItemLine."Document No." + '.xlsx';
        ServiceTasks.SaveAsExcel(FilePath);

        // [THEN] Verify that Saved file has some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure CommentsOnOrderFromQuote()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        TempServiceCommentLine: Record "Service Comment Line" temporary;
    begin
        // Covers document number CU5901 - refer to TFS ID 167035.
        // [SCENARIO 167035] Test Comments on Service Order create from Service Quote.

        // [GIVEN] Create Service Quote and Assign Loaner on Service Quote, Create Comments on Service Quote.
        CreateServiceQuoteWithComments(ServiceItemLine);
        SaveComments(TempServiceCommentLine, ServiceItemLine);

        // [WHEN] Create Service Order from Service Quote.
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        LibraryService.CreateOrderFromQuote(ServiceHeader);

        // [THEN] Verify that the Comments on Service Order is Comments assign on Service Quote.
        ServiceItemLine.SetRange("Service Item No.", ServiceItemLine."Service Item No.");
        ServiceItemLine.FindFirst();
        VerifyComments(TempServiceCommentLine, ServiceItemLine);

        // 4. Teardown: Receive Loaner.
        ReceiveLoanerOnServiceOrder(ServiceItemLine, ServiceItemLine."Service Item No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure PostedServiceShipment()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number CU5901, CU5906-1 - refer to TFS ID 167035.
        // [SCENARIO 167035] Test Loaner Entry and Service Document Log from Posted Service Shipment.

        // [GIVEN] Create Service Quote and Assign Loaner on Service Quote, Create Comments on Service Quote, Make Order from Quote.
        CreateServiceQuoteWithComments(ServiceItemLine);
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        LibraryService.CreateOrderFromQuote(ServiceHeader);

        // [WHEN] Post Service Order as Ship and Receive Loaner on service Shipment Header.
        ServiceItemLine.SetRange("Service Item No.", ServiceItemLine."Service Item No.");
        ServiceItemLine.FindFirst();
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        ReceiveLoanerOnServiceShipment(ServiceHeader."No.");

        // [THEN] Verify Loaner Entry and Service Document Log for Loaner.
        VerifyLoanerEntry(ServiceItemLine);

        // The value 8 is the event number for Receive Loaner.
        VerifyServiceDocumentLog(ServiceItemLine."Document No.", ServiceItemLine."Loaner No.", 8);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ContractTemplateHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemAndDocumentLog()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServItemManagement: Codeunit ServItemManagement;
    begin
        // Covers document number CU5906-1 - refer to TFS ID 167035.
        // [SCENARIO 167035] Test Service Item Log and Service Document Log after create Service Item form Order.

        // [GIVEN] Create and Sign Service Contract, Create Service Header and Assign Contract No. on Header.
        Initialize();
        InitServiceContractWithOrderScenario(ServiceHeader, ServiceContractHeader);

        // [WHEN] Create Service Item from Service Order and Assign Loaner on Service Item Line.
        CreateServiceItemLine(ServiceItemLine, ServiceHeader);
        ServItemManagement.CreateServItemOnServItemLine(ServiceItemLine);
        ServiceItemLine.Modify(true);
        AssignLoanerOnServiceItemLine(ServiceItemLine);

        // [THEN] Verify Service Item Log and Service Document Log.
        // [THEN] The value 11,13,2 is the event number for Customer No., Item No. changed and Automatically created on Service Item Log and
        // [THEN] 7,11 is the event number for Loaner lent and Contract No. Changed on Service Document Log.
        VerifyServiceItemLog(ServiceItemLine."Service Item No.", ServiceItemLine."Customer No.", 11);
        VerifyServiceItemLog(ServiceItemLine."Service Item No.", ServiceItemLine."Item No.", 13);
        VerifyServiceItemLogExist(ServiceItemLine."Service Item No.", 2);
        VerifyServiceDocumentLog(ServiceItemLine."Document No.", ServiceItemLine."Loaner No.", 7);
        VerifyServiceDocumentLog(ServiceItemLine."Document No.", ServiceContractHeader."Contract No.", 11);

        // 4. Teardown: Receive Loaner.
        ReceiveLoanerOnServiceOrder(ServiceItemLine, ServiceItemLine."Service Item No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ContractTemplateHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemDocumentLogOnPost()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        Resource: Record Resource;
        ServiceLine: Record "Service Line";
        ServItemManagement: Codeunit ServItemManagement;
    begin
        // Covers document number CU5906-1 - refer to TFS ID 167035.
        // [SCENARIO 167035] Test Service Item Log and Service Document Log after Posting Service Order.

        // [GIVEN] Create and Sign Service Contract, Create Service Header and Assign Contract No. on Header,
        Initialize();
        InitServiceContractWithOrderScenario(ServiceHeader, ServiceContractHeader);

        // [GIVEN] Create Service Item from Service Order and Assign Loaner on Service Item Line.
        CreateServiceItemLine(ServiceItemLine, ServiceHeader);
        ServItemManagement.CreateServItemOnServItemLine(ServiceItemLine);
        ServiceItemLine.Modify(true);
        AssignLoanerOnServiceItemLine(ServiceItemLine);

        // [WHEN] Create Service Line with Type Resource and Post Service Order as Ship.
        LibraryResource.FindResource(Resource);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.");
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLine."Line No.");

        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Verify Service Item Log and Service Document Log after Posting Service Order.
        // [THEN] The value 11,13,2 is the event number for Customer No., Item No. changed and Automatically created on Service Item Log
        // [THEN] 7,11,6 is the event number for Loaner lent, Contract No. Changed and Shipment Created on Service Document Log.
        VerifyServiceItemLog(ServiceItemLine."Service Item No.", ServiceItemLine."Customer No.", 11);
        VerifyServiceItemLog(ServiceItemLine."Service Item No.", ServiceItemLine."Item No.", 13);
        VerifyServiceItemLogExist(ServiceItemLine."Service Item No.", 2);
        VerifyServiceDocumentLog(ServiceItemLine."Document No.", ServiceItemLine."Loaner No.", 7);
        VerifyServiceDocumentLog(ServiceItemLine."Document No.", ServiceContractHeader."Contract No.", 11);
        VerifyServiceDocumentShipment(FindServiceShipmentHeader(ServiceHeader."No."), 6);

        // 4. Teardown: Receive Loaner.
        ReceiveLoanerOnServiceOrder(ServiceItemLine, ServiceItemLine."Service Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocumentLogRepairStatus()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceItemLine2: Record "Service Item Line";
        RepairStatus: Record "Repair Status";
    begin
        // Covers document number CU5906-1 - refer to TFS ID 167035.
        // [SCENARIO 167035] Test Service Document Log created after change Repair Status code on Service Item Line.

        // [GIVEN] Create Service Header and Service Item Line.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        // [WHEN] Create Repair Status Code and Update it on Service Item Line.
        CreateRepairStatusCodeFinish(RepairStatus);
        ServiceItemLine2.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.", ServiceItemLine."Line No.");
        ServiceItemLine.Validate("Repair Status Code", RepairStatus.Code);
        ServiceItemLine.UpdateServiceOrderChangeLog(ServiceItemLine2);
        ServiceItemLine.Modify(true);

        // [THEN] Verify Service Document Log for Repair Status.
        // [THEN] The value 14 is the event number for Repair Status Change.
        VerifyServiceDocumentLog(ServiceItemLine."Document No.", RepairStatus.Code, 14);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocumentLogStatus()
    var
        ServiceHeader: Record "Service Header";
        ServiceHeader2: Record "Service Header";
    begin
        // Covers document number CU5906-1 - refer to TFS ID 167035.
        // [SCENARIO 167035] Test Service Document Log created after change Status on Service Header.

        // [GIVEN] Create Service Header.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');

        // [WHEN] Change Status to In Process on Service Header.
        ServiceHeader2.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.Validate(Status, ServiceHeader.Status::"In Process");
        ServiceHeader.UpdateServiceOrderChangeLog(ServiceHeader2);
        ServiceHeader.Modify(true);

        // [THEN] Verify Service Document Log for Status.
        VerifyServiceDocumentLogExist(ServiceHeader."No.", 2);  // The value 2 is the event number for Status Change.
    end;

    [Test]
    [HandlerFunctions('FormHandlerResourceAllocation')]
    [Scope('OnPrem')]
    procedure ResourceAllocation()
    var
        ServiceItemLine: Record "Service Item Line";
        Resource: Record Resource;
    begin
        // Covers document number CU5906-1 - refer to TFS ID 167035.
        // [SCENARIO 167035] Test Service Document Log created after Resource Allocation on Service Header.

        // [GIVEN] Create Service Header, Service Item and Service Item Line.
        Initialize();
        CreateServiceOrderWithServiceItem(ServiceItemLine);

        // [WHEN] Allocate Resource on Service Order.
        AllocateResource(Resource, ServiceItemLine);

        // [THEN] Verify Service Document Log for Resource Allocation.
        VerifyServiceDocumentLog(ServiceItemLine."Document No.", Resource."No.", 4);  // The value 4 is the event number for REsource Allocation.
    end;

    [Test]
    [HandlerFunctions('FormHandlerResourceAllocation,FormHandlerCancelAllocation')]
    [Scope('OnPrem')]
    procedure CancelResourceAllocation()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Resource: Record Resource;
        ServiceDocumentLog: Record "Service Document Log";
        ServiceOrderAllocation: Record "Service Order Allocation";
        ResourceNo: Code[20];
    begin
        // Covers document number CU5906-1 - refer to TFS ID 167035.
        // [SCENARIO 167035] Test Service Document Log created after Change Resource Allocation on Service Header.

        // [GIVEN] Create Service Header, Service Item and Service Item Line and Allocate Resource on Service Order.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, '');
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        CreateServiceItemLineRepair(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        AllocateResource(Resource, ServiceItemLine);
        ResourceNo := Resource."No.";

        // [WHEN] Change Resource No. on Service Order Allocation.
        ServiceOrderAllocation.Get(LibraryVariableStorage.DequeueInteger());
        Resource.Next();
        ServiceOrderAllocation.Validate("Resource No.", Resource."No.");

        // [THEN] Verify Service Document Log for Change Resource Allocation.
        ServiceDocumentLog.SetRange("Document Type", ServiceDocumentLog."Document Type"::Order);
        ServiceDocumentLog.SetRange("Document No.", ServiceHeader."No.");
        ServiceDocumentLog.SetRange(After, ResourceNo);
        ServiceDocumentLog.FindLast();
        ServiceDocumentLog.TestField("Event No.", 5);  // The value 5 is the event number for Cancel Resource Allocation.
    end;

    [Test]
    [HandlerFunctions('FormHandlerResourceAllocation,FormHandlerRelAllocation')]
    [Scope('OnPrem')]
    procedure ResourceReAllocation()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Resource: Record Resource;
        ServiceDocumentLog: Record "Service Document Log";
        ServiceOrderAllocation: Record "Service Order Allocation";
        ServAllocationManagement: Codeunit ServAllocationManagement;
    begin
        // Covers document number CU5906-1 - refer to TFS ID 167035.
        // [SCENARIO 167035] Test Service Document Log created after Cancel Resource Allocation on Service Header.

        // [GIVEN] Create Service Header, Service Item and Service Item Line and Allocate Resource on Service Order.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, '');
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        CreateServiceItemLineRepair(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        AllocateResource(Resource, ServiceItemLine);

        // [WHEN] Cancel Resource Allocation.
        ServiceOrderAllocation.Get(LibraryVariableStorage.DequeueInteger());
        ServAllocationManagement.CancelAllocation(ServiceOrderAllocation);

        // [THEN] Verify Service Document Log for Cancel Resource Allocation.
        ServiceDocumentLog.SetRange("Document Type", ServiceDocumentLog."Document Type"::Order);
        ServiceDocumentLog.SetRange("Document No.", ServiceHeader."No.");
        ServiceDocumentLog.SetRange(After, Resource."No.");
        ServiceDocumentLog.FindLast();
        ServiceDocumentLog.TestField("Event No.", 17);  // The value 17 is the event number for Reallocation Needed.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number CU5906-1 - refer to TFS ID 167035.
        // [SCENARIO 167035] Test Service Item Log created after Delete service Order.

        // [GIVEN] Create Service Header, Service Item and Service Item Line.
        Initialize();
        CreateServiceDocumentWithServiceItem(
          ServiceHeader, ServiceItemLine, ServiceHeader."Document Type"::Order, '');

        // [WHEN] Delete Service Order.
        ServiceHeader.Delete(true);

        // [THEN] Verify Service Document Log for Delete service Order.
        VerifyServiceItemLogExist(ServiceItemLine."Service Item No.", 7);  // The value 7 is the event number for delete Service Order.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineExtendedText()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceTransferExtText: Codeunit "Service Transfer Ext. Text";
        Description: Text[50];
    begin
        // Covers document number CU5912-2 - refer to TFS ID 167035.
        // [SCENARIO 167035] Test Extended Text created on Service Line.

        // [GIVEN] Create Item, Extended Text for Item, Service Order - Service Header and Service Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Description := CreateExtendedTextForItem(Item."No.");

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        ServiceLine."Document Type" := ServiceHeader."Document Type";
        ServiceLine."Document No." := ServiceHeader."No.";
        ServiceLine.Type := ServiceLine.Type::Item;
        ServiceLine."No." := Item."No.";

        // [WHEN] Add Extended Text to the Service Line by Insert Extended Text function.
        ServiceTransferExtText.ServCheckIfAnyExtText(ServiceLine, true);
        ServiceTransferExtText.InsertServExtText(ServiceLine);

        // [THEN] Verify Extended Text on Service Line.
        GetServiceLine(ServiceLine, ServiceHeader);
        ServiceLine.TestField(Description, Description);
    end;

    [Test]
    [HandlerFunctions('CustomerTemplateHandler')]
    [Scope('OnPrem')]
    procedure CreationCustomerFromOrder()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ServOrderManagement: Codeunit ServOrderManagement;
    begin
        // Covers document number CU-5988-1-2 - refer to TFS ID 172910.
        // [SCENARIO 172910] Test Create Customer from Service Order.

        // [GIVEN] Create Customer Template.
        Initialize();
        CreateCustomerTemplate();

        // [WHEN] Create Customer from Service Order.
        CreateServiceHeaderWithName(ServiceHeader);
        Commit();
        ServOrderManagement.CreateNewCustomer(ServiceHeader);
        ServiceHeader.Modify(true);

        // [THEN] Verify values on Created Customer is values on Service Header.
        Customer.Get(ServiceHeader."Customer No.");
        Customer.TestField(Name, ServiceHeader.Name);
        Customer.TestField(Address, ServiceHeader.Address);
        Customer.TestField("Post Code", ServiceHeader."Post Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreationServiceItemFromOrder()
    var
        ServiceItemLine: Record "Service Item Line";
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServItemManagement: Codeunit ServItemManagement;
    begin
        // Covers document number CU-5988-1-3 - refer to TFS ID 172910.
        // [SCENARIO 172910] Test Create Service Item from Service Order.

        // [GIVEN] Create Service Order - Service Header, Service Item Line with Description and attach Item on Service Item Line.
        CreateServItemLineDescription(ServiceItemLine);
        LibraryInventory.CreateItem(Item);
        ServiceItemLine.Validate("Item No.", Item."No.");
        ServiceItemLine.Modify(true);

        // [WHEN] Create Service Item from Service Order.
        ServItemManagement.CreateServItemOnServItemLine(ServiceItemLine);
        ServiceItemLine.Modify(true);

        // [THEN] Verify values on Created Service Item is values on Service Item Line.
        ServiceItem.Get(ServiceItemLine."Service Item No.");
        ServiceItem.TestField("Customer No.", ServiceItemLine."Customer No.");
        ServiceItem.TestField("Item No.", Item."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ContractTemplateHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ShipOrderServiceContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number CU5988-1-9 - refer to TFS ID 172911.
        // [SCENARIO 172911] Test Service Ledger Entry after Posting Service Order as Ship with Service Contract No.

        // [GIVEN] Create and Sign Service Contract, Create Service Order with Contract No. on Header.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
        CreateOrderWithContract(ServiceHeader, ServiceLine, ServiceContractHeader);

        // [WHEN] Post Service Order as Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Verify Service Ledger Entry after Posting Service Order.
        VerifyServiceLedgerEntry(
          ServiceLine."No.", FindServiceShipmentHeader(ServiceHeader."No."), ServiceContractHeader."Contract No.",
          ServiceLedgerEntry."Entry Type"::Usage, ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ContractTemplateHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ConsumeServiceOrderContract()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Covers document number CU5988-1-14 - refer to TFS ID 172911.
        // [SCENARIO 172911] Test Service Ledger Entry after Posting Service Order as Ship and Consume with Service Contract No.

        // [GIVEN] Create and Sign Service Contract, Create Service Order with Contract No. on Header and update Qty. to Consume on
        // Service Line.
        Initialize();
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
        CreateOrderWithContract(ServiceHeader, ServiceLine, ServiceContractHeader);
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
        ServiceLine.Modify(true);

        // [WHEN] Post Service Order as Ship and Consume.
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // [THEN] Verify Service Ledger Entry after Posting Service Order.
        VerifyServiceLedgerEntry(
          ServiceLine."No.", FindServiceShipmentHeader(ServiceHeader."No."), ServiceContractHeader."Contract No.",
          ServiceLedgerEntry."Entry Type"::Usage, ServiceLine."Qty. to Consume");
        VerifyServiceLedgerEntry(
          ServiceLine."No.", FindServiceShipmentHeader(ServiceHeader."No."), ServiceContractHeader."Contract No.",
          ServiceLedgerEntry."Entry Type"::Consume, -ServiceLine."Qty. to Consume");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteServiceItemLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number CU5988-1-15 - refer to TFS ID 172912.
        // [SCENARIO 172912] Test Deletion of Service Item Line.

        // [GIVEN] Create Service Item, Service Header and Service Item Line.
        Initialize();
        CreateServiceDocumentWithServiceItem(ServiceHeader, ServiceItemLine, ServiceHeader."Document Type"::Order, '');

        // [WHEN] Delete Service Item Line.
        ServiceItemLine.Delete(true);

        // [THEN] Verify Service Item Line successfully deleted.
        Assert.IsFalse(
          ServiceItemLine.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.", ServiceItemLine."Line No."),
          StrSubstNo(ServiceItemLineExistErr, ServiceItemLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ModalFormHandlerLookupOK')]
    [Scope('OnPrem')]
    procedure ServiceItemLogReplaceComponent()
    begin
        // [SCENARIO 202377] Test Service item log After posting the Service Order Line with string menu option Replace Components.

        ServiceItemLogOnPost(1);  // Use for Choose the First option of the string menu.
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemLogNewComponent()
    begin
        // [SCENARIO 202377] Test Service item log After posting the Service Order Line with string menu option New Components.

        ServiceItemLogOnPost(2);  // Use for Choose the second option of the string menu.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithResolutionCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
    begin
        // [SCENARIO 146033] Test Create a Service Order with Resolution Code.

        // [GIVEN] Create New Service Item.
        Initialize();
        CreateServiceItemWithGroup(ServiceItem, LibrarySales.CreateCustomerNo());

        // [GIVEN] Create a new Service Order.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");

        // [GIVEN] Insert Service Item Line 1 with Resolution Code, Service Item No., Item No. and Service Item Group Code.
        CreateItemLineResolution(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [WHEN] Insert Service Item  Line 2,3 and 4 with Resolution Code.
        CreateItemLineResolution(ServiceItemLine, ServiceHeader, '');
        CreateItemLineResolution(ServiceItemLine, ServiceHeader, '');
        CreateItemLineResolution(ServiceItemLine, ServiceHeader, '');
        UpdationOfServiceItemGroup(ServiceItemLine);

        // [THEN] Verify Service Item  Line 4 created without any error message also allows to enter Service Item Group Code values.
        VerifyServiceItemGroup(ServiceHeader."No.", ServiceHeader."Document Type");
    end;

    local procedure ServiceItemLogOnPost(StringMenuOption: Integer)
    var
        ServiceItem: Record "Service Item";
        Item: Record Item;
        ServiceItemComponent: Record "Service Item Component";
        DocumentNo: Code[20];
    begin
        // 1. Setup: Find Customer and Item,Create Service Item and Service Item Component.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateServiceItem(ServiceItem, LibrarySales.CreateCustomerNo(), Item."No.");
        LibraryService.CreateServiceItemComponent(ServiceItemComponent, ServiceItem."No.", ServiceItemComponent.Type::Item, Item."No.");

        // 2. Exercise: Create and Post Service Order.
        // Set StringMenuOption For String Menu Handler.
        LibraryVariableStorage.Enqueue(StringMenuOption);
        LibraryVariableStorage.Enqueue(ServiceItem."No.");
        DocumentNo := CreateAndPostServiceOrder(ServiceItem);

        // 3. Verify: Verify Service Item Log Entries.
        // The value 5 and 16 is the event number for Service item component and Added to service order.
        VerifyServiceItemLogEntry(DocumentNo, 5);
        VerifyServiceItemLogEntry(DocumentNo, 16);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceDiscountZero()
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 203760] Test Resource Ledger Entry after Posting Service Order with Invoice Discount % as boundary value 0 on Customer.

        PostWithInvoiceDiscount(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DiscountBetweenFiftyHundred()
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 203760] Test Resource Ledger Entry after Posting Service Order with Invoice Discount % between 50 and 60 on Customer.

        PostWithInvoiceDiscount(50 + LibraryRandom.RandDec(10, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceDiscountHundred()
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 203760] Test Resource Ledger Entry after Posting Service Order with Invoice Discount % as boundary value 100 on Customer.

        PostWithInvoiceDiscount(100);
    end;

    local procedure PostWithInvoiceDiscount(DiscountPct: Decimal)
    var
        Customer: Record Customer;
        Item: Record Item;
        Resource: Record Resource;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ResLedgerEntry: Record "Res. Ledger Entry";
        ServiceItem: Record "Service Item";
        TotalPrice: Decimal;
    begin
        // 1. Setup: Create Customer, Customer Invoice Discount, Update Sales & Receivable Setup with Calc. Inv. Discount as True, Service
        // Item, Service Header with Document Type as Order, Service Item Line and Service Line with Type Resource.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        CreateCustomerInvoiceDiscount(Customer."No.", DiscountPct, 0);  // Take Zero for Service Charge.
        CreateServiceItem(ServiceItem, Customer."No.", Item."No.");
        LibrarySales.SetCalcInvDiscount(true);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryResource.FindResource(Resource);

        // Use 1 for Quantity required for Test Case.
        CreateAndUpdateServiceLine(ServiceHeader, ServiceLine.Type::Resource, Resource."No.", 1, ServiceItemLine."Line No.", 0);  // Use zero for Line Discount.
        GetServiceLine(ServiceLine, ServiceHeader);
        TotalPrice := Round(ServiceLine."Unit Price" - (ServiceLine."Unit Price" * DiscountPct / 100));

        // 2. Exercise: Post Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify Resource Ledger Entry for both Entry Type Sale and Usage.
        VerifyResourceLedgerEntry(
          ServiceLine."No.", FindServiceInvoiceHeader(ServiceHeader."No."), ResLedgerEntry."Entry Type"::Sale, -ServiceLine.Quantity,
          -TotalPrice);

        VerifyResourceLedgerEntry(
          ServiceLine."No.", FindServiceShipmentHeader(ServiceHeader."No."), ResLedgerEntry."Entry Type"::Usage, ServiceLine.Quantity,
          TotalPrice);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderCreditLimitWarning()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Credit Limit] [UI]
        // [SCENARIO 202516] Test to verify that credit limit warning comes once when creating a Service Order through Customer Card.

        // [GIVEN] Set Credit Warnings to Both warnings, find Item, create Customer, create Sales Order and post it.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.SetCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"Both Warnings");

        LibraryVariableStorage.Enqueue(Customer."No.");
        CreateAndPostSalesOrder(Customer."No.");

        // [WHEN] Create Service Order from Customer Card.
        CustomerCard.OpenView();
        CustomerCard.FILTER.SetFilter("No.", Customer."No.");
        CustomerCard.NewServiceOrder.Invoke();

        // [THEN] Verify through the SendNotificationHandler.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountInclusiveVATOnServiceLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 235565] Test calculation of Amount Including VAT on Service Line when Price Including VAT is True.

        // [GIVEN] Find VAT Posting Setup and create Item.
        Initialize();
        LibraryERM.SetVATRoundingType('=');
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateAndUpdateServiceHeader(ServiceHeader, VATPostingSetup."VAT Bus. Posting Group");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        // [WHEN] Create Service Order, use Random value for Quantity.
        CreateAndUpdateServiceLine(
          ServiceHeader, ServiceLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2), ServiceItemLine."Line No.", 0);  // Use zero for Line Discount.

        // [THEN] Verify the correct Amount updated on Amount Including VAT on Service Line.
        VerifyAmountIncludingVATOnServiceLine(ServiceHeader, VATPostingSetup."VAT %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnGLEntryAfterPostingServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
    begin
        // [SCENARIO 235565] Test calculation of VAT Amount on GL Entry after posting Service Order.

        // [GIVEN] Find VAT Posting Setup and create Item, create Service Order with Random Quantity.
        Initialize();
        LibraryERM.SetVATRoundingType('=');
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateAndUpdateServiceHeader(ServiceHeader, VATPostingSetup."VAT Bus. Posting Group");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateAndUpdateServiceLine(
          ServiceHeader, ServiceLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2), ServiceItemLine."Line No.", 0);  // Use zero for Line Discount.
        GetServiceLine(ServiceLine, ServiceHeader);
        VATAmount := -Round(ServiceLine.Quantity * ServiceLine."Unit Price" * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));

        // [WHEN] Post Service Order.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Verify the VAT Amount on GL Entry after posting Service Order.
        VerifyVATAmountOnGLEntry(ServiceHeader."No.", VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponsibilityCenterOnServiceOrder()
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        UserSetup: Record "User Setup";
        ServiceItemLineNo: Integer;
        ResponsibilityCenterCode: Code[10];
    begin
        // [SCENARIO 203169] Check Responsibility Center on Service Order.

        // [GIVEN] Create User Setup.
        Initialize();
        ResponsibilityCenterCode := CreateResponsibilityCenterAndUserSetup();
        LibrarySales.CreateCustomer(Customer);

        // 2. Exercise.
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader, Customer."No.");
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLineNo);

        // [THEN] Validate Responsibility Center on Service Order.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.TestField("Responsibility Center", ResponsibilityCenterCode);

        // 4. Tear Down.
        DeleteUserSetup(UserSetup, ResponsibilityCenterCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponsibilityCenterOnPostedServiceDocument()
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        UserSetup: Record "User Setup";
        ServiceItemLineNo: Integer;
        ResponsibilityCenterCode: Code[10];
    begin
        // [SCENARIO 203169] Check Responsibility Center on Service Document.

        // [GIVEN] Create User Setup, Service Order and Service Line.
        Initialize();
        ResponsibilityCenterCode := CreateResponsibilityCenterAndUserSetup();
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader, Customer."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLineNo);

        // 2. Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Validate Responsibility Center on Service Document.
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceHeader.TestField("Responsibility Center", ResponsibilityCenterCode);

        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindFirst();
        ServiceShipmentHeader.TestField("Responsibility Center", ResponsibilityCenterCode);

        // 4. Tear Down.
        DeleteUserSetup(UserSetup, ResponsibilityCenterCode);
    end;

    [Test]
    [HandlerFunctions('PageHandlerServiceLines')]
    [Scope('OnPrem')]
    procedure PostingDateOnServiceLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
    begin
        // [SCENARIO 259505] Check Posting Date on the Service lines same as Service Item Worksheet.

        // [GIVEN] Create Service Order and update the Posting Date on the Service Item Worksheet.
        Initialize();
        CreateServiceOrderWithUpdatedPostingDate(ServiceHeader, ServiceLine);
        LibraryVariableStorage.Enqueue(ServiceLine."Posting Date");

        // 2. Exercise.
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", ServiceHeader."No.");
        ServiceOrder.ServItemLines."Service Lines".Invoke();

        // [THEN] Validate Posting Date on Service Line.
        // Verification done in Page Handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLedgerEntryWithUpdatedPostingDate()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        // [SCENARIO 259505] Check Posting Date on the Service Ledger Entry same as Service Item Worksheet.

        // [GIVEN] Create Service Order and update the Posting Date on the Service Item Worksheet.
        Initialize();
        CreateServiceOrderWithUpdatedPostingDate(ServiceHeader, ServiceLine);

        // 2. Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Validate Service Ledger Entry.
        VerifyPostingDateOnServiceLedgerEntry(ServiceLine, ServiceLedgerEntry."Document Type"::Shipment, ServiceLine.Quantity);
        VerifyPostingDateOnServiceLedgerEntry(ServiceLine, ServiceLedgerEntry."Document Type"::Invoice, -ServiceLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderUsingPaymentMethodWithBalanceAccount()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // [SCENARIO 265765] Test General Ledger, Customer Ledger and Detailed Customer ledger entries after Posting Service Order with Currency and Payment method with a balance account.

        // [GIVEN] Modify General Ledger Setup, create Customer with Payment Method Code with a balance account and create Service Order.
        Initialize();
        LibraryERM.SetApplnRoundingPrecision(LibraryRandom.RandDec(10, 2));  // Taken Random value for Application Rounding Precision.
        CreateAndModifyCustomer(Customer, Customer."Application Method"::Manual, FindPaymentMethodWithBalanceAccount(), 0);  // Taken Zero value for Currency Application Rounding Precision.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLine."Line No.");

        // 2. Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Verify GL, Customer and Detailed Customer ledger entries.
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        VerifyEntriesAfterPostingServiceDocument(
          CustLedgerEntry."Document Type"::Payment, ServiceInvoiceHeader."No.", ServiceInvoiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocumentUsingApplicationMethodApplyToOldest()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Item: Record Item;
        PaymentMethod: Record "Payment Method";
        ServiceHeader: Record "Service Header";
        ServiceHeader2: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [SCENARIO 265766] Test General Ledger, Customer Ledger and Detailed Customer ledger entries after posting Service documents with Currency and Apply to Oldest Application Method.

        // [GIVEN] Modify General Ledger Setup, create Customer with Apply to Oldest Application Method, create and post Service Invoice and create Service Credit Memo.
        Initialize();
        LibraryERM.SetApplnRoundingPrecision(LibraryRandom.RandDec(10, 2));  // Taken Random value for Application Rounding Precision.
        LibraryERM.FindPaymentMethod(PaymentMethod);
        CreateAndModifyCustomer(
          Customer, Customer."Application Method"::"Apply to Oldest", PaymentMethod.Code,
          LibraryRandom.RandDec(5, 2));  // Taken Random value for Currency Application Rounding Precision.
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandIntInRange(10, 20);
        UnitPrice := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.", Item."No.", Quantity, UnitPrice);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        CreateServiceDocument(ServiceHeader2, ServiceHeader2."Document Type"::"Credit Memo", Customer."No.", Item."No.", Quantity, UnitPrice);

        // [WHEN] Post Service Credit Memo.
        LibraryService.PostServiceOrder(ServiceHeader2, true, false, true);

        // [THEN] Verify GL, Customer and Detailed Customer ledger entries.
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", ServiceHeader2."No.");
        ServiceCrMemoHeader.FindFirst();
        VerifyEntriesAfterPostingServiceDocument(
          CustLedgerEntry."Document Type"::"Credit Memo", ServiceInvoiceHeader."No.", ServiceCrMemoHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithInvoiceDiscount()
    var
        Customer: Record Customer;
        Item: Record Item;
        GeneralPostingSetup: Record "General Posting Setup";
        ServiceCost: Record "Service Cost";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DiscountPct: Decimal;
        DiscountAmount: Decimal;
    begin
        // [SCENARIO 259506] Test Discount Amount after Posting Service Order with Invoice Discount %.

        // [GIVEN] Modify Sales Receivables Setup, Create Customer, Item, Customer Invoice Discount, Service Order And Calculate Invoice Discount.
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        GeneralPostingSetup.Get(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        DiscountPct := LibraryRandom.RandDec(10, 2);  // Generate Random Value for Discount Percent.
        CreateCustomerInvoiceDiscount(Customer."No.", DiscountPct, 0);  // Take Zero for Service Charge.
        CreateServiceItem(ServiceItem, Customer."No.", Item."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.FindServiceCost(ServiceCost);
        CreateAndUpdateServiceLine(ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code, 1, ServiceItemLine."Line No.", 0);  // Take 1 for Quantity and 0 for Line Discount.
        GetServiceLine(ServiceLine, ServiceHeader);
        CODEUNIT.Run(CODEUNIT::"Service-Calc. Discount", ServiceLine);
        DiscountAmount := (ServiceLine.Amount * DiscountPct / 100);

        // 2. Exercise.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Verify Discount Amount after Posting.
        VerifyDiscountAmount(ServiceHeader."No.", DiscountAmount, GeneralPostingSetup."Sales Inv. Disc. Account");
    end;

    [Test]
    [HandlerFunctions('ServiceItemWorksheetHandler,ServiceLinesSequenceHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderVerificationWithMultipleLines()
    var
        TempServiceLine: Record "Service Line" temporary;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
    begin
        // [SCENARIO 245322] Verify the sequence of Service Lines after entering on the Service Order.

        // [GIVEN] Create Service Order, open Service Item Worksheet and save data to a temporary table.
        Initialize();
        CreateServiceOrder(ServiceHeader, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        OpenServiceOrderPage(ServiceOrder, ServiceHeader."No.");
        ServiceOrder.ServItemLines."Service Item Worksheet".Invoke();
        GetServiceLine(ServiceLine, ServiceHeader);
        CopyServiceLine(TempServiceLine, ServiceLine);
        ServiceOrder.OK().Invoke();

        // [WHEN] Open Service Lines page.
        OpenServiceOrderPage(ServiceOrder, ServiceHeader."No.");
        ServiceOrder.ServItemLines."Service Lines".Invoke();

        // [THEN] Verify sequence of lines in ServiceLinesSequenceHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipPartialServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO 259256] Test Service Charge Line is generated after Partial shipment of Service Order.

        // [GIVEN] Modify Sales Receivables Setup, Create Service Order.
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);
        CreateServiceDocumentWithInvoiceDiscount(ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, ServiceLine."Document No.");

        // [WHEN] Post Service Order.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify.
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        Assert.IsTrue(ServiceLine.Count > 1, ServiceLineCountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipServiceOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO 259256] Test Service Charge Line is not generated after shipping remaining quantity on Service Order.

        // [GIVEN] Modify Sales Receivables Setup, Create Service Order.
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);
        CreateServiceDocumentWithInvoiceDiscount(ServiceLine);
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, ServiceLine."Document No.");

        // [WHEN] Post Service Order.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify.
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        Assert.IsTrue(ServiceLine.Count > 1, ServiceLineCountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithFullDiscountOnServiceLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        Resource: Record Resource;
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        // [SCENARIO 281469] Verify Resource Ledger Entry for Sale is created when posting a Resource line having 100% discount from a Service Order.

        // [GIVEN] Create Service Order with Resource with 100 % discount.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateServiceItem(ServiceItem, Customer."No.", LibraryInventory.CreateItem(Item));
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryResource.FindResource(Resource);
        CreateAndUpdateServiceLine(
          ServiceHeader, ServiceLine.Type::Resource, Resource."No.", LibraryRandom.RandInt(10), ServiceItemLine."Line No.", 100);  // Use 100 for Full Discount and Random value for Quantity..
        GetServiceLine(ServiceLine, ServiceHeader);

        // [WHEN] Post Service Order.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Verify Resource Ledger Entry for both Entry Type Sale and Usage.
        VerifyResourceLedgerEntry(
          ServiceLine."No.", FindServiceInvoiceHeader(ServiceHeader."No."), ResLedgerEntry."Entry Type"::Sale, -ServiceLine.Quantity, 0);  // Total Price must be 0 in case of Full Discount.
        VerifyResourceLedgerEntry(
          ServiceLine."No.", FindServiceShipmentHeader(ServiceHeader."No."), ResLedgerEntry."Entry Type"::Usage, ServiceLine.Quantity, 0);  // Total Price must be 0 in case of Full Discount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithMultipleLinesOfSameAccount()
    var
        Item: Record Item;
        GLAccount: Record "G/L Account";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        Counter: Integer;
        VATAmount: Decimal;
    begin
        // [SCENARIO 281474] Verify that VAT Amount and also that only one VAT Entry is created after posting the Service Order with Multiple Line having same Account and same Dimensions and same Posting groups.
        Initialize();

        // [GIVEN] Set ServiceSetup."Copy Line Descr. to G/L Entry" = "No"
        SetServiceSetupCopyLineDescrToGLEntry(false);
        // [GIVEN] Create Service Order with multiple line having same Account and same Dimensions and same Posting groups.
        VATPostingSetup.SetFilter("Unrealized VAT Type", '=''''');
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateServiceItem(
          ServiceItem, CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"), LibraryInventory.CreateItem(Item));
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        GLAccount.Get(CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"));
        // Use Random value to create multiple lines with zero Line Discount and Random Quantity..
        for Counter := 1 to 1 + LibraryRandom.RandInt(5) do
            CreateAndUpdateServiceLine(
              ServiceHeader, ServiceLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandInt(10), ServiceItemLine."Line No.", 0);
        VATAmount := CalculateVATForMultipleServiceLines(ServiceHeader, VATPostingSetup."VAT %");

        // [WHEN] Post Service Order.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Verify VAT Entry.
        VATEntry.SetRange("Document No.", FindServiceInvoiceHeader(ServiceHeader."No."));
        Assert.AreEqual(1, VATEntry.Count, StrSubstNo(NoOfLinesErr, VATEntry.TableCaption(), 1));  // Only one VAT Entry should be created.
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          -VATAmount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(
            VATAmountErr, VATEntry.FieldCaption(Amount), VATEntry.Amount, VATEntry.TableCaption(), VATEntry.FieldCaption("Entry No."),
            VATEntry."Entry No.", VATAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPostingVATAmtStatistics()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        VATAmount: Decimal;
    begin
        // [SCENARIO 280212] Verify that VAT Amount calculated correctly in Posted Invoice Statistics in case of partial posting

        // [GIVEN] Get VAT Posting Setup, Modify Sales Receivables Setup
        Initialize();
        LibrarySales.SetInvoiceRounding(true);

        // [WHEN] Create and post Service Order
        CreateAndPostPartialServiceOrder(ServiceHeader, ServiceLine, VATPostingSetup);

        // [THEN] Verify Posted Invoice Statistics.
        VATAmount := Round(ServiceLine."Qty. to Invoice" * ServiceLine."Unit Price" * VATPostingSetup."VAT %" / 100);
        VerifyVATAmountOnPostInvStatistics(ServiceHeader."No.", VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPostingVATGLEntry()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvHeader: Record "Service Invoice Header";
        VATAmount: Decimal;
    begin
        // [SCENARIO 280212] Verify that VAT Amount calculated correctly in G/L Entry in case of partial posting

        // [GIVEN] Get VAT Posting Setup, Modify Sales Receivables Setup
        Initialize();
        LibrarySales.SetInvoiceRounding(true);

        // [WHEN] Create and post Service Order
        CreateAndPostPartialServiceOrder(ServiceHeader, ServiceLine, VATPostingSetup);

        // [THEN] G/L Entries Amount By Document No. and VAT Account.
        VATAmount := Round(ServiceLine."Qty. to Invoice" * ServiceLine."Unit Price" * VATPostingSetup."VAT %" / 100);
        ServiceInvHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvHeader.FindLast();
        VerifyGLEntriesByAccount(ServiceInvHeader."No.", VATPostingSetup."Sales VAT Account", -VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPostingVATEntry()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvHeader: Record "Service Invoice Header";
        VATAmount: Decimal;
    begin
        // [SCENARIO 280212] Verify that VAT Amount calculated correctly in VAT Entry in case of partial posting

        // [GIVEN] Get VAT Posting Setup, Modify Sales Receivables Setup
        Initialize();
        LibrarySales.SetInvoiceRounding(true);

        // [WHEN] Create and post Service Order
        CreateAndPostPartialServiceOrder(ServiceHeader, ServiceLine, VATPostingSetup);

        // [THEN] Verify VAT Entries Amount Dy Document No.
        VATAmount := Round(ServiceLine."Qty. to Invoice" * ServiceLine."Unit Price" * VATPostingSetup."VAT %" / 100);
        ServiceInvHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvHeader.FindLast();
        VerifyVATEntries(ServiceInvHeader."No.", -VATAmount);
    end;

    [Test]
    [HandlerFunctions('ServiceItemListHandler')]
    [Scope('OnPrem')]
    procedure NewServiceItemFromOrderUsingLookUp()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceOrderPage: TestPage "Service Order";
    begin
        // [SCENARIO 283776] New Service Item is created by LookUp from Order line
        // 1. Setup.
        Initialize();

        // Create Service Order.
        CreateServItemLineDescription(ServiceItemLine);

        // [WHEN] Open Service Order Page.
        ServiceOrderPage.OpenEdit();
        ServiceOrderPage.FILTER.SetFilter("No.", ServiceItemLine."Document No.");
        ServiceOrderPage.First();
        ServiceOrderPage.ServItemLines.ServiceItemNo.Lookup();

        // [THEN] Verification of new Service Item on the created Service Line through the look up button.
        ServiceItem.Get(LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarrantyLedgerEntryAsOpenFalse()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
    begin
        // [SCENARIO 294774] Create and Post Service Order and Verify Open field as False in Warranty Ledger Entry.

        // [GIVEN] Create Service Item and Service Order .
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, '');
        ServiceItem.Validate("Warranty Starting Date (Parts)", WorkDate());
        ServiceItem.Modify(true);
        CreateServiceOrderWithWarranty(ServiceHeader, ServiceItem);

        // [WHEN] Post Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Verify Warranty Ledger Entry field Open as False.
        VerifyWarrantyLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutStandingAmountOnServiceLines()
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        Item: Record Item;
        Quantity: Decimal;
        UnitPrice: Decimal;
    begin
        // [SCENARIO 309583] Create Service Order and Verify OutStanding Amount on Service Lines.

        // [GIVEN] Create Service Item and Item .
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        UnitPrice := LibraryRandom.RandDec(100, 2);
        LibraryService.CreateServiceItem(ServiceItem, '');
        LibraryInventory.CreateItem(Item);

        // [WHEN] Create Service order.
        CreateServiceOrderWithMultipleLines(ServiceHeader, ServiceItem."Customer No.", ServiceItem."No.", Item."No.", Quantity, UnitPrice);

        // [THEN] Verify OutStanding Amount on Service Line.
        VerifyOutstandingAmountOnServiceLines(ServiceHeader."No.", Quantity, UnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutStandingAmountOnGLEntries()
    var
        ServiceItem: Record "Service Item";
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        OrderNo: Code[20];
        TotalOutStandingAmount: Decimal;
    begin
        // [SCENARIO 309583] Create and Post Service Order and Verify OutStanding Amount on Service Lines.

        // [GIVEN] Create Service Item and Item and Service Order.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, '');
        LibraryInventory.CreateItem(Item);
        CreateServiceOrderWithMultipleLines(
          ServiceHeader, ServiceItem."Customer No.", ServiceItem."No.", Item."No.", LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(100, 2));
        OrderNo := ServiceHeader."No.";
        TotalOutStandingAmount := GetOutstandingAmountForServiceLines(ServiceHeader);

        // [WHEN] Post Service order.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Verify Outstanding Amount On GL Entries.
        VerifyOutstandingAmountOnGLEntry(FindServiceInvoiceHeader(OrderNo), -1 * TotalOutStandingAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ContractTemplateHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractWithInvoicePeriodYear()
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [SCENARIO 312261] Verify Amount Per Period and Next Invoice Date on Service Contract Header When Invoice Period is Year.
        VerifyNextInvoiceDateAndAmountToPeriod(ServiceContractHeader."Invoice Period"::Year, 1, CalcDate('<CY+1Y>', WorkDate()));  // Amount Per Period for Year calculated using Amount divided by 1.
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ContractTemplateHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractWithInvoicePeriodMonth()
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [SCENARIO 312261] Verify Amount Per Period and Next Invoice Date on Service Contract Header When Invoice Period is Month.
        VerifyNextInvoiceDateAndAmountToPeriod(ServiceContractHeader."Invoice Period"::Month, 12, CalcDate('<CY+1M>', WorkDate()));  // Amount Per Period for Month calculated using Amount divided by 12.
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ContractTemplateHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractWithInvoicePeriodQuarter()
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [SCENARIO 312261] Verify Amount Per Period and Next Invoice Date on Service Contract Header When Invoice Period is Quarter.
        VerifyNextInvoiceDateAndAmountToPeriod(ServiceContractHeader."Invoice Period"::Quarter, 4, CalcDate('<CY+3M>', WorkDate()));  // Amount Per Period for Quarter calculated using Amount divided by 4.
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ContractTemplateHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractWithPriceUpdatePeriod()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        PriceUpdatePeriod: DateFormula;
    begin
        // [SCENARIO 316447] Test error occurs on validating Price Update Period less than Invoice Period on Service Contract.

        // [GIVEN] Create Service Contract Header.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        ServiceContractHeader.Validate("Starting Date", CalcDate('<CY+1D>', WorkDate()));  // Starting Date should be First Day of the Next Year.
        ServiceContractHeader.Validate("Invoice Period", ServiceContractHeader."Invoice Period"::Year);
        ServiceContractHeader.Modify(true);
        Evaluate(PriceUpdatePeriod, StrSubstNo('<%1M>', LibraryRandom.RandInt(11)));

        // [WHEN] Try to set Price Update Period Less than 12M.
        asserterror ServiceContractHeader.Validate("Price Update Period", PriceUpdatePeriod);

        // [THEN] Verify error message on Service Contract Header.
        Assert.ExpectedError(PriceUpdatePeriodErr);
    end;

    [Test]
    [HandlerFunctions('ResGrAvailabilityServiceHandler,ResGrAvailServMatrixHandler')]
    [Scope('OnPrem')]
    procedure CheckServiceResourceGroupAvailability()
    var
        ServiceItemLine: Record "Service Item Line";
        ResourceAllocations: TestPage "Resource Allocations";
    begin
        // [SCENARIO 324493] Check that program does not populate error while displaying matrix in Resource Group Availability window.

        // [GIVEN] Create Service Order.
        Initialize();
        CreateServiceOrderWithServiceItem(ServiceItemLine);
        ResourceAllocations.OpenEdit();
        ResourceAllocations.FILTER.SetFilter("Document No.", ServiceItemLine."Document No.");
        ResourceAllocations.FILTER.SetFilter("Service Item No.", ServiceItemLine."Service Item No.");

        // [WHEN] Call "Res.Group Availability" action on Resource Allocations page.
        ResourceAllocations.ResGroupAvailability.Invoke();

        // [THEN] Verify as no error occurs when Showmatrix is call in ResGrAvailabilityServiceHandler.
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderWithRepSysProdOrderAndWarrantyTrue()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 331971] Verify Service Item No. created on Service Item Line when Item Replenishment System is Prod. Order and Warranty is True for Service Order.
        ServiceItemNoCreatedOnServiceItemLine(ServiceHeader."Document Type"::Order, true, Item."Replenishment System"::"Prod. Order");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderWithRepSysProdOrderAndWarrantyFalse()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 331971] Verify Service Item No. created on Service Item Line when Item Replenishment System is Prod. Order and Warranty is False for Service Order.
        ServiceItemNoCreatedOnServiceItemLine(ServiceHeader."Document Type"::Order, false, Item."Replenishment System"::"Prod. Order");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceQuoteWithRepSysProdOrderAndWarrantyTrue()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 331971] Verify Service Item No. created on Service Item Line when Item Replenishment System is Prod. Order and Warranty is True for Service Quote.
        ServiceItemNoCreatedOnServiceItemLine(ServiceHeader."Document Type"::Quote, true, Item."Replenishment System"::"Prod. Order");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceQuoteWithRepSysProdOrderAndWarrantyFalse()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 331971] Verify Service Item No. created on Service Item Line when Item Replenishment System is Prod. Order and Warranty is False for Service Quote.
        ServiceItemNoCreatedOnServiceItemLine(ServiceHeader."Document Type"::Quote, false, Item."Replenishment System"::"Prod. Order");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderWithRepSysPurchaseAndWarrantyFalse()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 331971] Verify Service Item No. created on Service Item Line when Item Replenishment System is Purchase and Warranty is False for Service Order.
        ServiceItemNoCreatedOnServiceItemLine(ServiceHeader."Document Type"::Order, false, Item."Replenishment System"::Purchase);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceQuoteWithRepSysPurchaseAndWarrantyFalse()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 331971] Verify Service Item No. created on Service Item Line when Item Replenishment System is Purchase and Warranty is False for Service Quote.
        ServiceItemNoCreatedOnServiceItemLine(ServiceHeader."Document Type"::Quote, false, Item."Replenishment System"::Purchase);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderWithRepSysPurchaseAndWarrantyTrue()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 331971] Verify Error message while Creating Service Item when Item Replenishment System is Purchase and Warranty is True for Service Order.
        VendorErrorMessageWhileCreatingServiceItem(ServiceHeader."Document Type"::Order, true, Item."Replenishment System"::Purchase);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceQuoteWithRepSysPurchaseAndWarrantyTrue()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 331971] Verify Error message while Creating Service Item when Item Replenishment System is Purchase and Warranty is True for Service Quote.
        VendorErrorMessageWhileCreatingServiceItem(ServiceHeader."Document Type"::Quote, true, Item."Replenishment System"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDefaultBinCodeOnServiceLine()
    var
        Bin: Record Bin;
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO 332644] Verify that Bin Code exist on Service Invoice Line,When re-enter Item No. removes the default Bin.

        // [GIVEN] Create Service Document with Bin Code.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateBinAndBinContent(Bin, Item);
        CreateServiceDocumentWithLocation(ServiceLine, Item."No.", Bin."Location Code");

        // [WHEN] Re-enter Item No.
        ServiceLine.Validate("No.", Item."No.");

        // [THEN] Verify Bin Code exist on Service Line.
        ServiceLine.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    [HandlerFunctions('ServiceStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyVATAmountOnServiceInvoiceStatistics()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 333709] Verify VAT Amount on Service Invoice Statistics when Invoice Rounding Precision updated .
        VerifyVATAmountOnServiceStatistics(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ServiceStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyVATAmountOnServiceCreditMemoStatistics()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 333709] Verify VAT Amount on Service Credit Memo Statistics when Invoice Rounding Precision updated .
        VerifyVATAmountOnServiceStatistics(ServiceHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyVATAmountOnPostedServiceCreditMemoStatistics()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 333709] Verify Amount Excl. VAT on Service Credit Memo Statistics when Invoice Rounding Precision updated.

        // [GIVEN] Modify General Ledger Setup and Create Service Credit Memo.
        Initialize();
        InitServDocWithInvRoundingPrecisionScenario(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");

        // [WHEN] Post Service Order.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Verify "Amount Excluding VAT" on Posted Credit Memo Statistics,
        VerifyAmountExclVATOnPostedCrMemoStatistics(ServiceHeader."Customer No.");
    end;

    [Test]
    [HandlerFunctions('ServiceOrderSubformPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyServiceLinesAsPerServiceItem()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
    begin
        // [SCENARIO 6749] Verify Service Lines are shown per Service Item.

        // [GIVEN] Create Multiple Service Item Lines with Service Line.
        Initialize();
        CreateServiceOrderWithMultipleServiceItemLines(ServiceHeader);
        GetServiceLine(ServiceLine, ServiceHeader);
        OpenServiceOrderPage(ServiceOrder, ServiceHeader."No.");
        LibraryVariableStorage.Enqueue(ServiceOrder.ServItemLines.ServiceItemNo.Value);
        LibraryVariableStorage.Enqueue(ServiceLine."No.");

        // [WHEN] Invoke Service Lines.
        ServiceOrder.ServItemLines."Service Lines".Invoke();

        // [THEN] Verification done in ServiceLinesSubformHandler.
    end;

    [Test]
    [HandlerFunctions('ServiceOrderSubformPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyServiceLinesWithOutServiceItem()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
    begin
        // [SCENARIO 6749] Verify Service Line should be blank when Service Item Line created without Service Item.

        // [GIVEN] Create Multiple Service Item Lines with Service Line and One Service Item Line Without Service Item.
        Initialize();
        CreateServiceOrderWithMultipleServiceItemLines(ServiceHeader);
        CreateServiceItemLine(ServiceItemLine, ServiceHeader);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLine."Line No.");
        OpenServiceOrderPage(ServiceOrder, ServiceHeader."No.");
        ServiceOrder.ServItemLines.FILTER.SetFilter(Description, ServiceItemLine.Description);
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(Item."No.");

        // [WHEN] Invoke Balnk Service Item Service Lines.
        ServiceOrder.ServItemLines."Service Lines".Invoke();

        // [THEN] Verification done in ServiceLinesSubformHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckNoOverFlowErrorExistOnServiceLine()
    var
        ServiceHeader: Record "Service Header";
        Item: Record Item;
    begin
        // [SCENARIO 116417] Verify that no Overflow error on service line with more ranges.

        // [GIVEN]
        Initialize();

        // [WHEN] Create Service order with large random values.
        CreateServiceDocument(
          ServiceHeader, ServiceHeader."Document Type"::Order,
          LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItem(Item),
          LibraryRandom.RandIntInRange(10000000, 2147483647),
          LibraryRandom.RandDecInRange(0, 1, 3));

        // [THEN] Verifying service line amount.
        VerifyServiceLineAmount(ServiceHeader."Document Type", ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ContractTemplateHandler')]
    [Scope('OnPrem')]
    procedure CheckServiceLedgerEntriesWithInvoicePeriodYear()
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [SCENARIO 55518] Check the service ledger entry with Invoice Period Year.
        ServiceContractWithInvoicePeriod(ServiceContractHeader."Invoice Period"::Year, 12);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ContractTemplateHandler')]
    [Scope('OnPrem')]
    procedure CheckServiceLedgerEntriesWithInvoicePeriodMonth()
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [SCENARIO 55518] Check the service ledger entry with Invoice Period Month.
        ServiceContractWithInvoicePeriod(ServiceContractHeader."Invoice Period"::Month, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,ContractTemplateHandler')]
    [Scope('OnPrem')]
    procedure CheckServiceLedgerEntriesWithInvoicePeriodQuarter()
    var
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // [SCENARIO 55518] Check the service ledger entry with Invoice Period Quarter.
        ServiceContractWithInvoicePeriod(ServiceContractHeader."Invoice Period"::Quarter, 3);
    end;

    local procedure ServiceContractWithInvoicePeriod(InvoicePeriod: Enum "Service Contract Header Invoice Period"; NoOfEntries: Integer)
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractLine2: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
        SavedDate: Date;
    begin
        // Setup: Create and signed service contract.
        Initialize();
        SavedDate := WorkDate();
        WorkDate := CalcDate('<CY+1D>', WorkDate()); // First day of the year.
        CreateServiceContractHeader(ServiceContractHeader, InvoicePeriod);
        CreateServiceContractLineWithPriceUpdatePeriod(ServiceContractHeader, ServiceContractLine);
        CreateServiceContractLineWithPriceUpdatePeriod(ServiceContractHeader, ServiceContractLine2);
        UpdateServiceContract(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");

        // Exercise: Create and Post Service Invoice.
        CreateAndPostServiceInvoice(ServiceContractHeader);

        // Verify : Verifying Service Ledger Entry with Invoice period.
        VerifyServiceLedgerEntryWithUnitPrice(ServiceContractLine, NoOfEntries);
        VerifyServiceLedgerEntryWithUnitPrice(ServiceContractLine2, NoOfEntries);

        // Tear Down:
        WorkDate := SavedDate;
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,GetServiceShipmentLinesHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CheckCreditLimitCustomerTotalAmount()
    var
        ServiceHeader: Record "Service Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // [FEATURE] [Credit Limit] [UI]
        // [SCENARIO 352311] Verify Total Amount on Check Credit Limit page when having Invoice with Get Shipment Lines.

        // [GIVEN] Set StockOut warning and Credit Warnings, Create Customer and Item.
        Initialize();
        UpdateSalesReceivablesSetup();

        CreateDocWithLineAndGetShipmentLine(ServiceHeader);
        // [WHEN] Open Service Order page with New Order
        OpenServiceOrderPageWithNewOrder(ServiceHeader."Customer No.");
        // [THEN] Verification of the Total Amount is done in CheckCreditLimitHandlerTotal.

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,GetServiceShipmentLinesHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CheckCreditLimitCustomerTotalAmountFromLine()
    var
        ServiceHeader: Record "Service Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // [FEATURE] [Credit Limit] [UI]
        // [SCENARIO 353097] Verify Total Amount on Check Credit Limit page when having Invoice with Get Shipment Lines in case of Unit Price line validation

        // [GIVEN] Set StockOut warning and Credit Warnings, Create Customer and Item.
        Initialize();
        UpdateSalesReceivablesSetup();

        CreateDocWithLineAndGetShipmentLine(ServiceHeader);
        // [WHEN] Validate "Unit Price" on Service Invoice page
        OpenServiceInvoicePageAndValidateUnitPrice(ServiceHeader."No.");
        // [THEN] Verification of the Total Amount is done in CheckCreditLimitHandlerTotal.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ServiceLinesValidateUnitPrice_MPH,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CheckCreditLimitCustomerServiceLine_Negative()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ServiceOrder: TestPage "Service Order";
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Credit Limit] [UI]
        // [SCENARIO 378637] Credit limit warning page is opened when validate Service Line with exceeded amount
        Initialize();
        UpdateSalesReceivablesSetup();

        // [GIVEN] Customer "C" with "Credit Limit" = "A"
        // [GIVEN] Service Order for customer "C" with total amount = "A". Service Line "Quantity" = 1, "Unit Price" = "X"
        CreateServiceOrderWithItem(ServiceHeader, LibrarySales.CreateCustomerNo(), '', LibraryInventory.CreateItemNo(), 1);
        UpdateCustomerCreditLimit(
          ServiceHeader."Customer No.", CalcTotalLineAmount(ServiceHeader."Document Type", ServiceHeader."No."));
        GetServiceLine(ServiceLine, ServiceHeader);

        // [GIVEN] Modify Service Line "Unit Price" = "X" + 0.01 (through the Service Line page)
        LibraryVariableStorage.Enqueue(ServiceLine."Unit Price" + LibraryERM.GetAmountRoundingPrecision());
        LibraryVariableStorage.Enqueue(ServiceHeader."Customer No.");
        UnitPrice := ServiceLine."Unit Price";
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceOrder.Close();
        // [GIVEN] Credit Limit warning page is opened for customer "C"
        // "CheckCreditLimit_ReplyYes_MPH" handler

        // [WHEN] Close credit limit warning page with "OK" action.
        // [THEN] No error occurs and Service Line "Unit Price" = "X" + 0.01
        ServiceLine.Find();
        Assert.AreEqual(
          UnitPrice + LibraryERM.GetAmountRoundingPrecision(),
          ServiceLine."Unit Price",
          ServiceLine.FieldCaption("Unit Price"));
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CheckCreditLimitCustomerServiceLine_Negative_UT()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServCheckCreditLimit: Codeunit "Serv. Check Credit Limit";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // [FEATURE] [Credit Limit] [UT]
        // [SCENARIO 378637] Error is shown after close Credit limit warning page with "No" action after validate Service Line with exceeded amount
        Initialize();
        UpdateSalesReceivablesSetup();

        // [GIVEN] Customer "C" with "Credit Limit" = "A"
        // [GIVEN] Service Order for customer "C" with total amount = "A". Service Line "Quantity" = 1, "Unit Price" = "X"
        CreateServiceOrderWithItem(ServiceHeader, LibrarySales.CreateCustomerNo(), '', LibraryInventory.CreateItemNo(), 1);
        UpdateCustomerCreditLimit(
          ServiceHeader."Customer No.", CalcTotalLineAmount(ServiceHeader."Document Type", ServiceHeader."No."));
        // [GIVEN] Modify Service Line "Unit Price" = "X" + 0.01
        GetServiceLine(ServiceLine, ServiceHeader);
        UpdateServiceLine(
          ServiceLine, ServiceLine."Service Item Line No.", 1, ServiceLine."Unit Price" + LibraryERM.GetAmountRoundingPrecision());
        // [GIVEN] Credit Limit warning page is opened for customer "C"
        // "CheckCreditLimitHandler" handler

        // [WHEN] Close credit limit warning page with "NO" action.
        // [THEN] Error occurs: "The update has been interrupted to respect the warning."
        LibraryVariableStorage.Enqueue(ServiceHeader."Customer No.");
        ServCheckCreditLimit.ServiceLineCheck(ServiceLine);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ServiceLinesValidateUnitPrice_MPH')]
    [Scope('OnPrem')]
    procedure CheckCreditLimitCustomerServiceLine_Positive()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        UnitPrice: Decimal;
    begin
        // [FEATURE] [Credit Limit]
        // [SCENARIO 378637] Credit limit warning page is not opened when validate Service Line with max amount
        Initialize();
        UpdateSalesReceivablesSetup();

        // [GIVEN] Customer "C" with "Credit Limit" = "A"
        // [GIVEN] Service Order for customer "C" with total amount = "A". Service Line "Quantity" = 1, "Unit Price" = "X"
        CreateServiceOrderWithItem(ServiceHeader, LibrarySales.CreateCustomerNo(), '', LibraryInventory.CreateItemNo(), 1);
        UpdateCustomerCreditLimit(
          ServiceHeader."Customer No.", CalcTotalLineAmount(ServiceHeader."Document Type", ServiceHeader."No."));
        // [GIVEN] Modify Service Line "Unit Price" = 0
        GetServiceLine(ServiceLine, ServiceHeader);
        UnitPrice := ServiceLine."Unit Price";
        UpdateServiceLine(ServiceLine, ServiceLine."Service Item Line No.", 1, 0);

        // [WHEN] Modify Service Line "Unit Price" = "X" (through the Service Line page)
        LibraryVariableStorage.Enqueue(UnitPrice);
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceOrder.Close();

        // [THEN] Credit Limit warning page is not opened and ServiceLine."Unit Price" = "X"
        ServiceLine.Find();
        Assert.AreEqual(UnitPrice, ServiceLine."Unit Price", ServiceLine.FieldCaption("Unit Price"));
    end;

    [Test]
    [HandlerFunctions('ServiceLinesValidateQuantity_MPH,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CheckCreditLimitCustomerServiceLine_Quantity()
    var
        Location: Record Location;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        ServiceOrder: TestPage "Service Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Credit Limit] [UI]
        // [SCENARIO 378946] Credit limit warning page is opened once when validate Service Line with exceeded Quantity
        Initialize();
        UpdateSalesReceivablesSetup();

        // [GIVEN] Customer with Credit Limit
        // [GIVEN] Service Order (used Location with "Require Shipment" = TRUE). Service Line "Quantity" = 1.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        CreateServiceOrderWithItem(ServiceHeader, LibrarySales.CreateCustomerNo(), Location.Code, LibraryInventory.CreateItemNo(), 1);
        UpdateCustomerCreditLimit(
          ServiceHeader."Customer No.", CalcTotalLineAmount(ServiceHeader."Document Type", ServiceHeader."No."));
        GetServiceLine(ServiceLine, ServiceHeader);
        Quantity := ServiceLine.Quantity;
        // [GIVEN] Modify Service Line "Quantity" = 2 (through the Service Line page)
        LibraryVariableStorage.Enqueue(Quantity + LibraryERM.GetAmountRoundingPrecision());
        LibraryVariableStorage.Enqueue(ServiceHeader."Customer No.");
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        ServiceOrder.ServItemLines."Service Lines".Invoke();
        ServiceOrder.Close();
        // [GIVEN] Credit Limit warning page is opened

        // [WHEN] Close credit limit warning page with "OK" action.
        // "CheckCreditLimit_ReplyYes_MPH" handler

        // [THEN] No error occurs and Service Line "Quantity" = 2. No more credit limit warning page is shown.
        ServiceLine.Find();
        Assert.AreEqual(
          Quantity + LibraryERM.GetAmountRoundingPrecision(),
          ServiceLine.Quantity,
          ServiceLine.FieldCaption("Unit Price"));
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure CreateDocWithLineAndGetShipmentLine(var NewServiceHeader: Record "Service Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceHeader: Record "Service Header";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        CreditLimit: Decimal;
        TotalAmount: Decimal;
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CustomerNo := CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        // Create and Ship Service Order. Set Unit Price more than Credit Limit.
        CreateServiceOrderWithItem(ServiceHeader, CustomerNo, '', ItemNo, 1);
        CreditLimit := CalcTotalLineAmount(ServiceHeader."Document Type", ServiceHeader."No.") - LibraryERM.GetAmountRoundingPrecision();
        UpdateCustomerCreditLimit(ServiceHeader."Customer No.", CreditLimit);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        TotalAmount := CalcTotalLineAmount(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryVariableStorage.Enqueue(TotalAmount);

        // Create Service Invoice and Get Shipment Lines.
        CreateServiceDocument(
          NewServiceHeader, NewServiceHeader."Document Type"::Invoice, CustomerNo,
          ItemNo, LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandDecInRange(1000, 2000, 2));

        TotalAmount += CalcTotalLineAmount(NewServiceHeader."Document Type", NewServiceHeader."No.");
        LibraryVariableStorage.Enqueue(TotalAmount);
        OpenServiceInvoicePage(NewServiceHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckServiceOrderPostedWithLastCommentLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Resource: Record Resource;
        ServiceItemLineNo: Integer;
        PrevAutomaticCostPosting: Boolean;
    begin
        // [SCENARIO 354415] Check that Service Order having last Service Line with comment only can be posted.

        // 1. Setup.
        Initialize();
        PrevAutomaticCostPosting := UpdateAutomaticCostPosting(true);

        // 2. Exercise.
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader, '');
        LibraryResource.FindResource(Resource);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.");
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLineNo);
        CreateDescriptionServiceLine(ServiceHeader, ServiceLine.Type::" ", '', ServiceItemLineNo);

        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify.
        VerifyServiceShipmentItemLineCount(ServiceHeader."No.", 1);

        // 4. Teardown
        UpdateAutomaticCostPosting(PrevAutomaticCostPosting);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandlerWithAnswer')]
    [Scope('OnPrem')]
    procedure ValidateBillToCustomerNoInServiceHeader()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Customer1: Record Customer;
        Customer2: Record Customer;
    begin
        // [SCENARIO 363375] "VAT Bus. Posting Group" should not be updated if "Bill-to Customer No." update is not confirmed.
        Initialize();
        // Setup for test
        LibraryERM.SetBillToSellToVATCalc(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");
        // [GIVEN] Service Order ("SO") for "Bill-to Customer No." = "C1", "VAT Bus. Posting Group" = "V1"
        CreateCustomerWithVATBusPostGroup(Customer1);
        // [GIVEN] Customer "C2", where "VAT Bus. Posting Group" = "V2"
        CreateCustomerWithVATBusPostGroup(Customer2);
        CreateServiceInvoiceWithServiceLine(ServiceHeader, ServiceLine, Customer1."No.");
        // [WHEN] Change Customer "C1" to "C2" in "SO". Confirm update of "SO"."Sell-to Customer No." and cancel update of "SO"."Bill-to Customer No."
        ChangeCustomerNo(ServiceHeader, Customer2."No.");
        // [THEN] "Service Header"."VAT Bus. Posting Group" = "V1"
        // [THEN] "Service Line"."VAT Bus. Posting Group" = "V1"
        VerifyVATBusPostGroupServiceOrder(ServiceHeader, ServiceLine, Customer1."VAT Bus. Posting Group");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ValidateLoanerOnServiceItemLineWithDelayedInsert()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
    begin
        // [SCENARIO 360806] Loaner Entry is inserted when Loaner No. change is confirmed

        // [GIVEN] Service Order
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, '');
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        // [GIVEN] Service Item Line with Loaner to be inserted
        ServiceItemLine.Init();
        ServiceItemLine.Validate("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.Validate("Document No.", ServiceHeader."No.");
        ServiceItemLine.Validate("Service Item No.", ServiceItem."No.");
        ServiceItemLine.Validate("Loaner No.", CreateLoaner());

        // [WHEN] Answer yes on the confirmation dialog when inserting Service Item Line
        ServiceItemLine.Insert(true);

        // [THEN] Loaner Entry is created
        VerifyLoanerEntryExists(ServiceItemLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeLoanerOnServiceItemLine()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 360806] Loaner entry is created if change Loaner No.

        // [GIVEN] Service Order with "Loaner No." = "A"
        Initialize();
        CreateServiceDocWithLoaner(ServiceHeader, ServiceItemLine, ServiceHeader."Document Type"::Order);
        // [GIVEN] Receive Loaner "A"
        ReceiveLoanerOnServiceOrder(ServiceItemLine, ServiceItemLine."Service Item No.");

        // [GIVEN] Change Loaner No. from "A" to "B"
        ServiceItemLine.Validate("Loaner No.", CreateLoaner());

        // [WHEN] Answer yes on the confirmation dialog "Do you want to lend?"
        ServiceItemLine.Modify(true);

        // [THEN] Loaner Entry is created for Loaner "B"
        VerifyLoanerEntryExists(ServiceItemLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandlerForFalse')]
    [Scope('OnPrem')]
    procedure EmptyLoanerWhenCancelLendConfirmation()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 360806] Loaner Entry is not inserted when Loaner No. change is not confirmed
        Initialize();

        // [GIVEN] Service Order with Loaner
        CreateServiceDocWithLoaner(ServiceHeader, ServiceItemLine, ServiceHeader."Document Type"::Order);

        // [WHEN] Confirmation is canceled by ConfirmMessageHandlerForFalse

        // [THEN] Loaner No. is empty and Loaner Entry is not created
        Assert.AreEqual('', ServiceItemLine."Loaner No.", LoanerNoIsNotEmptyErr);
        VerifyLoanerEntryDoesNotExist(ServiceItemLine);
    end;

    [Test]
    [HandlerFunctions('ServiceItemWorksheetHandlerOneLine')]
    [Scope('OnPrem')]
    procedure ServiceItemWrkshLineInsertMultiple()
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        Customer: Record Customer;
        ServiceOrder: TestPage "Service Order";
        i: Integer;
        NoOfServiceItemLines: Integer;
    begin
        // [SCENARIO 120370] Check possibility of creation Service Line for each of >16 Service Item Lines
        // [GIVEN] Service Order with 16 Service Item Lines
        Initialize();
        NoOfServiceItemLines := 16;
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        for i := 1 to NoOfServiceItemLines do
            LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        OpenServiceOrderPage(ServiceOrder, ServiceHeader."No.");
        // [WHEN] User adds Service Line for each Service Item Line
        for i := 1 to NoOfServiceItemLines do begin
            ServiceOrder.ServItemLines."Service Item Worksheet".Invoke();
            ServiceOrder.ServItemLines.Next();
        end;
        ServiceOrder.OK().Invoke();
        // [THEN] No error message appears and Service Line linked with last Service Item Line exists
        VerifyLinkedServiceLineExists(
          ServiceHeader."Document Type", ServiceHeader."No.",
          FindLastServiceItemLineNo(ServiceHeader."Document Type", ServiceHeader."No."));
    end;

    [Test]
    [HandlerFunctions('InsertTravelFeePageHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemWrkshLineInsertFee()
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        NoOfInsertFees: Integer;
    begin
        // [SCENARIO 121069] Check error message appears after Inserting 16 Fees in Service Item Worksheet
        // [GIVEN] Service Order with Service Line
        Initialize();
        CreateServiceItemWithZone(ServiceItem);
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        OpenServiceOrderPage(ServiceOrder, ServiceHeader."No.");
        NoOfInsertFees := 16;
        LibraryVariableStorage.Enqueue(NoOfInsertFees);
        // [WHEN] User inserts 16 Travel Fees, 16th Line "Line No." should have value of already existing line
        asserterror ServiceOrder.ServItemLines."Service Item Worksheet".Invoke();
        // [THEN] Error message appears that user cannot anymore insert lines at current position, not that the line already exists
        Assert.ExpectedError(StrSubstNo(ThereIsNotEnoughSpaceToInsertErr, ServiceLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineInsertAfterLastLine()
    begin
        // [SCENARIO 361240] 1 Service Line. Insert new Service Line after 1st line
        CheckServiceLineInsertion(1, true, false, 20000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineInsertAfterLastLinePrevFocusOnFirst()
    begin
        // [SCENARIO 364477] 2 Service Lines. Set focus on 1st line. Insert new Service Line after 2nd line
        CheckServiceLineInsertion(1, true, true, 30000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineInsertBetweenLines()
    begin
        // [SCENARIO 361240] 2 Service Lines. Insert new Service Line after 1st line
        CheckServiceLineInsertion(2, false, true, 15000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineInsertBeforeFirstLine()
    begin
        // [SCENARIO 361240] 1 Service Line. Insert new Service Line before 1st line
        CheckServiceLineInsertion(1, false, false, 5000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineNoLinesInsertNew()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLineBeforeAfterInsert: Record "Service Line";
    begin
        // [SCENARIO 120370] User is able to insert new Service Line to the empty Service Item Worksheet
        CreateServiceOrderWithServiceItem(ServiceItemLine);
        ServiceLineBeforeAfterInsert.Init();

        VerifyServiceLineInsertLineNo(
          ServiceItemLine."Document Type", ServiceItemLine."Document No.",
          ServiceLineBeforeAfterInsert, false, 10000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderFromQuoteCustomerLocationCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        Customer: Record Customer;
        Location: Record Location;
    begin
        // [SCENARIO 121634] Make Order should Create Service Order with Location Code value taken from Customer
        Initialize();
        // [GIVEN] Customer with defined Location Code
        CreateCustomerWithLocationCode(Customer, Location);
        // [GIVEN] Service Quote
        CreateServiceDocumentWithServiceItem(ServiceHeader, ServiceItemLine, ServiceHeader."Document Type"::Quote, Customer."No.");
        // [WHEN] Run Make Order action
        LibraryService.CreateOrderFromQuote(ServiceHeader);
        // [THEN] Service Order created with ServiceOrder."Location Code" = Customer."Location Code"
        VerifyServiceDocumentLocationCode(ServiceHeader."Document Type"::Order, Customer."No.", Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderPostWithItemExtText()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemNo: array[2] of Code[20];
        ItemExtText: array[2] of Text[50];
        i: Integer;
    begin
        // [SCENARIO 123182] Item's extended text line is not inserted into posted Service Invoice when "Qty. To Invoice" = 0
        Initialize();

        // [GIVEN] Item "X" with extended text "ETX"
        // [GIVEN] Item "Y" with extended text "ETY"
        for i := 1 to 2 do begin
            ItemNo[i] := LibraryInventory.CreateItemNo();
            ItemExtText[i] := CreateExtendedTextForItem(ItemNo[i]);
        end;

        // [GIVEN] Service order with items "X", "Y"
        CreateServiceOrderWithItem(
          ServiceHeader, LibrarySales.CreateCustomerNo(), '', ItemNo[1], LibraryRandom.RandIntInRange(10, 20));
        AddServiceLine(ServiceLine, ServiceHeader, ItemNo[2]);

        // [GIVEN] Insert "X", "Y" extended texts into service order lines
        InsertExtendedTextForServiceLines(ServiceHeader);

        // [GIVEN] Set "Qty. To Ship" and "Qty. To Invoice" = 0 for item "Y"
        UpdateServiceLineQtyToShipInvoice(ServiceLine, 0);

        // [WHEN] Post service order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true); // Ship & Invoice

        // [THEN] Posted service invoice contains only item "X" line and description line "ETX"
        VerifyServiceInvoiceLineItemWithExtendedText(ServiceHeader."No.", ItemNo[1], ItemExtText[1]);
    end;

    [Test]
    [HandlerFunctions('ServiceItemWorksheet_ValidateFaultReasonCode_MPH')]
    [Scope('OnPrem')]
    procedure ValidateFaultReasonCodeWithContractDiscount()
    var
        ServiceLine: Record "Service Line";
        FaultReasonCode: Record "Fault Reason Code";
        LineDiscountPercent: Decimal;
    begin
        // [FEATURE] [Line Discount] [UI]
        // [SCENARIO 362453] "Line Discount %" should not be changed by "Fault Reason Code" with "Exclude Contract Discount"
        Initialize();

        // [GIVEN] Service Order with Service Line with Line Discount % = 50
        CreateSimpleServiceOrder(ServiceLine, LineDiscountPercent);
        // [GIVEN] Fault Reason Code "C" excluding contract discount
        LibraryService.CreateFaultReasonCode(FaultReasonCode, false, true);

        // [WHEN] Fault Reason Code "C" set into Service Line through page
        LibraryVariableStorage.Enqueue(FaultReasonCode.Code);
        OpenServiceItemWorksheetPage(ServiceLine."Document No.");

        // [THEN] Line Discount must be equal to 50. (must not be changed)
        ServiceLine.Find();
        Assert.AreEqual(LineDiscountPercent, ServiceLine."Line Discount %", ServiceLine.FieldCaption("Line Discount %"));
    end;

    [Test]
    [HandlerFunctions('ServiceItemWorksheet_ValidateFaultReasonCode_MPH')]
    [Scope('OnPrem')]
    procedure ValidateFaultReasonCodeWithoutContractDiscount()
    var
        ServiceLine: Record "Service Line";
        FaultReasonCode: Record "Fault Reason Code";
        LineDiscountPercent: Decimal;
    begin
        // [FEATURE] [Line Discount] [UI]
        // [SCENARIO 362453] "Line Discount %" should be blanked by "Fault Reason Code" with "Exclude Contract Discount"
        Initialize();

        // [GIVEN] Service Order with Service Line with Line Discount % = 50
        CreateSimpleServiceOrder(ServiceLine, LineDiscountPercent);
        // [GIVEN] Fault Reason Code "C" including contract discount
        LibraryService.CreateFaultReasonCode(FaultReasonCode, false, false);

        // [WHEN] Fault Reason Code "C" set into Service Line through page
        LibraryVariableStorage.Enqueue(FaultReasonCode.Code);
        OpenServiceItemWorksheetPage(ServiceLine."Document No.");

        // [THEN] Line Discount must be equal to 0. (must be reset)
        ServiceLine.Find();
        Assert.AreEqual(0, ServiceLine."Line Discount %", ServiceLine.FieldCaption("Line Discount %"));
    end;

    [Test]
    [HandlerFunctions('ServiceItemWorksheet_EnableExcludeContractDiscount_MPH,ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ValidateExcludeContractDiscount()
    var
        ServiceLine: Record "Service Line";
        LineDiscountPercent: Decimal;
    begin
        // [FEATURE] [Line Discount] [UI]
        // [SCENARIO 379169] "Line Discount %" should be blanked by enable "Exclude Contract Discount" field
        Initialize();

        // [GIVEN] Service Order with Service Line with Line Discount % = 50
        CreateSimpleServiceOrder(ServiceLine, LineDiscountPercent);

        // [WHEN] Enable Service Line "Exclude Contract Discount" through page
        OpenServiceItemWorksheetPage(ServiceLine."Document No.");

        // [THEN] Line Discount must be equal to 0. (must be reset)
        ServiceLine.Find();
        Assert.AreEqual(0, ServiceLine."Line Discount %", ServiceLine.FieldCaption("Line Discount %"));
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure GenBusinessPostingGroupInLinesUpdated()
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378255] Field "Gen. Bus. Posting Group" is updated in lines when user changes it in the document header and Gen. Bus. Posting Group has "Auto Insert Default" = False

        // [GIVEN] Gen. Bus. Posting Group "B" with "Auto Insert Default" = False,
        Initialize();
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        GenBusPostingGroup."Auto Insert Default" := false;
        GenBusPostingGroup.Modify();
        // [GIVEN] Customer with  Gen. Bus. Posting Group = "X",
        // [GIVEN] Service Order for Customer with one line
        CreateOrderCheckVATSetup(ServiceHeader, ServiceLine);

        // [WHEN] Validate field "Gen. Bus. Posting Group" = "B" in Service Order header
        ServiceHeader.Validate("Gen. Bus. Posting Group", GenBusPostingGroup.Code);

        // [THEN] Field "Gen. Bus. Posting Group" in Service Order line is "B"
        ServiceLine.Find();
        ServiceLine.TestField("Gen. Bus. Posting Group", GenBusPostingGroup.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandlerForFalse')]
    [Scope('OnPrem')]
    procedure GenBusinessPostingGroupInLinesNotUpdated()
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        OldGenBusPostingGroup: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 378255] Field "Gen. Bus. Posting Group" is updated in lines when user changes it in the document header and chooses "No" in Confirm dialog

        // [GIVEN] Gen. Bus. Posting Group "B" with "Auto Insert Default" = False,
        Initialize();
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        GenBusPostingGroup."Auto Insert Default" := false;
        GenBusPostingGroup.Modify();
        // [GIVEN] Customer with  "Gen. Bus. Posting Group" = "X",
        // [GIVEN] Service Order for Customer with one line
        CreateOrderCheckVATSetup(ServiceHeader, ServiceLine);
        OldGenBusPostingGroup := ServiceLine."Gen. Bus. Posting Group";
        Commit();

        // [WHEN] Validating field "Gen. Bus. Posting Group" = "B" in Service Order header
        asserterror ServiceHeader.Validate("Gen. Bus. Posting Group", GenBusPostingGroup.Code);

        // [THEN] Field "Gen. Bus. Posting Group" in Service Order line is not changed because of error message
        Assert.AreEqual('', GetLastErrorText, 'Unexpected error');
        ServiceLine.Find();
        ServiceLine.TestField("Gen. Bus. Posting Group", OldGenBusPostingGroup);
    end;

    [Test]
    [HandlerFunctions('ExactMessageHandler')]
    [Scope('OnPrem')]
    procedure PostedDocToPrintMessageRaisedWhenDeleteServInWithNoInPostedInvoiceNos()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServHeader: Record "Service Header";
        GLSetup: Record "General Ledger Setup";
    begin
        // [SCENARIO 379123] Message raised when delete Service Invoice with "Posted Invoice Nos." = "Invoice Nos." in Service Setup

        Initialize();
        // [GIVEN] "Posted Invoice Nos." = "Invoice Nos." in Service Setup
        SetPostedInvoiceNosEqualInvoiceNosInServSetup(ServiceMgtSetup);

        // [GIVEN] Service Invoice
        GLSetup.Get();
        LibraryService.CreateServiceHeader(
          ServHeader, ServHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        if GLSetup."Journal Templ. Name Mandatory" then
            ServHeader.Validate("Posting No.", LibraryUtility.GenerateGUID())
        else begin
            ServHeader.Validate("No. Series", ServiceMgtSetup."Posted Service Invoice Nos.");
            ServHeader.Validate("Posting No. Series", ServiceMgtSetup."Service Invoice Nos.");
        end;
        ServHeader.Modify(true);
        LibraryVariableStorage.Enqueue(PostedDocsToPrintCreatedMsg);

        // [WHEN] Delete Service Invoice
        ServHeader.Delete(true);

        // [THEN] Message "One or more documents have been posted during deletion which you can print" was raised
        // Verification done in ExactMessageHandler
    end;

    [Test]
    [HandlerFunctions('ServiceLinesNewLine_MPH')]
    [Scope('OnPrem')]
    procedure NewServiceLineNo()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: array[4] of Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        i: Integer;
    begin
        // [FEATURE] [Order] [UI]
        // [SCENARIO 379469] Service Line get a unique "Line No." when there is no room to insert a line between two adjacent lines.
        Initialize();

        // [GIVEN] Service Order with 4 Service Item Lines: "A", "B", "C", "D".
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        for i := 1 to ArrayLen(ServiceItemLine) do
            CreateServiceItemLineWithServiceItem(ServiceItemLine[i], ServiceHeader);

        // [GIVEN] Service Line for Service Item Line "A". Service Line "Line No." = 10000.
        // [GIVEN] Service Line for Service Item Line "B". Service Line "Line No." = 20000.
        // [GIVEN] Service Line for Service Item Line "C". Service Line "Line No." = 10001.
        CreateServiceLineWithLineNoSet(ServiceLine, ServiceHeader, ServiceItemLine[1], 10000);
        CreateServiceLineWithLineNoSet(ServiceLine, ServiceHeader, ServiceItemLine[2], 20000);
        CreateServiceLineWithLineNoSet(ServiceLine, ServiceHeader, ServiceItemLine[3], 10001);

        // [WHEN] Open "Service Lines" page for Service Item Line "D" (Service Order -> Lines -> Order -> Service Lines)
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        ServiceOrder.ServItemLines.GotoRecord(ServiceItemLine[4]);
        ServiceOrder.ServItemLines."Service Lines".Invoke();

        // [WHEN] Create a new Service Line through the page.
        // ServiceLinesNewLine_MPH

        // [THEN] New Service Line "Line No." = 30000
        FindServiceLineByServiceItemLineNo(ServiceLine, ServiceHeader, ServiceItemLine[4]."Line No.");
        Assert.AreEqual(30000, ServiceLine."Line No.", ServiceLine.FieldCaption("Line No."));
    end;

    [Test]
    [HandlerFunctions('ServiceQuoteLinesNewLine_MPH')]
    [Scope('OnPrem')]
    procedure NewServiceQuoteLineNo()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: array[3] of Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceQuote: TestPage "Service Quote";
        i: Integer;
    begin
        // [FEATURE] [Quote] [UI]
        // [SCENARIO 379469] Service Line gets an intermediate line no. if inserted between two adjacent lines.
        Initialize();

        // [GIVEN] Service Quote with 3 Service Item Lines: "A", "B", "C".
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());
        for i := 1 to ArrayLen(ServiceItemLine) do
            CreateServiceItemLineWithServiceItem(ServiceItemLine[i], ServiceHeader);

        // [GIVEN] Service Line for Service Item Line "A". Service Line "Line No." = 10000.
        // [GIVEN] Service Line for Service Item Line "B". Service Line "Line No." = 20000.
        CreateServiceLineWithLineNoSet(ServiceLine, ServiceHeader, ServiceItemLine[1], 10000);
        CreateServiceLineWithLineNoSet(ServiceLine, ServiceHeader, ServiceItemLine[2], 20000);

        // [WHEN] Open "Service Quote Lines" page for Service Item Line "C" (Service Quote -> Lines -> Quote -> Service Lines)
        ServiceQuote.OpenEdit();
        ServiceQuote.GotoRecord(ServiceHeader);
        ServiceQuote.ServItemLine.GotoRecord(ServiceItemLine[3]);
        ServiceQuote.ServItemLine.ServiceLines.Invoke();

        // [WHEN] Create a new Service Line through the page.
        // ServiceQuoteLinesNewLine_MPH

        // [THEN] New Service Line "Line No." = 15000
        FindServiceLineByServiceItemLineNo(ServiceLine, ServiceHeader, ServiceItemLine[3]."Line No.");
        Assert.AreEqual(15000, ServiceLine."Line No.", ServiceLine.FieldCaption("Line No."));
    end;

    [Test]
    [HandlerFunctions('ServiceLinesNewLineWithExtendedText')]
    [Scope('OnPrem')]
    procedure NewServiceLineWithExtendedText()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
    begin
        // [FEATURE] [Order] [UI]
        // [SCENARIO 379758] When standard text with extended text is inserted between 2 Service Lines, extended text line is placed after standard text and not after the last line
        Initialize();

        // [GIVEN] Service Order with Service Item Lines
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateServiceItemLineWithServiceItem(ServiceItemLine, ServiceHeader);

        // [GIVEN] Service Line for Service Item Line. Service Line "Line No." = 10000
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItemLine."Service Item No.");
        // [GIVEN] Service Line for Service Item Line. Service Line "Line No." = 20000
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItemLine."Service Item No.");

        // [GIVEN] Open "Service Lines" page for Service Item Line for Service Line with "Line No." = 20000 (Service Order -> Lines -> Order -> Service Lines)
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        ServiceOrder.ServItemLines.GotoRecord(ServiceItemLine);

        // [WHEN] Create a new Service Line Standard Text with Extended Text through the page Service Lines
        ServiceOrder.ServItemLines."Service Lines".Invoke();

        // [THEN] Extended Text Line No. = 15000
        FindServiceLineWithExtText(ServiceLine, ServiceHeader, ServiceItemLine."Line No.");
        ServiceLine.TestField("Line No.", 15000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendToPostBlankServiceHeader()
    var
        ServiceHeader: Record "Service Header";
        ServicePostYesNo: Codeunit "Service-Post (Yes/No)";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 379956] Throw error "There is nothing to post" without intermediate confirmations when send to post blank Service Header
        ServiceHeader.Init();

        asserterror ServicePostYesNo.PostDocument(ServiceHeader);

        Assert.ExpectedError('There is nothing to post');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplaceServiceLineStandardTextWithExtText()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        StandardText: Record "Standard Text";
        ExtendedText: Text;
    begin
        // [FEATURE] [Standard Text] [Extended Text]
        // [SCENARIO 380579] Replacing of Service Line's Standard Text Code updates attached Extended Text lines
        Initialize();

        // [GIVEN] Standard Text (Code = "ST1", Description = "SD1") with Extended Text "ET1".
        // [GIVEN] Standard Text (Code = "ST2", Description = "SD2") with Extended Text "ET2".
        // [GIVEN] Service Order with line: "Type" = "", "No." = "ST1"
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        MockServiceLine(ServiceLine, ServiceHeader);
        ValidateServiceLineStandardCode(ServiceLine, LibrarySales.CreateStandardTextWithExtendedText(StandardText, ExtendedText));

        // [WHEN] Validate Service Line "No." = "ST2"
        ValidateServiceLineStandardCode(ServiceLine, LibrarySales.CreateStandardTextWithExtendedText(StandardText, ExtendedText));

        // [THEN] There are two Service lines:
        // [THEN] Line1: Type = "", "No." = "ST2", Description = "SD2"
        // [THEN] Line2: Type = "", "No." = "", Description = "ET2"
        VerifyServiceLineCount(ServiceHeader, 2);
        VerifyServiceLineDescription(ServiceLine, ServiceLine.Type::" ", StandardText.Code, StandardText.Description);
        ServiceLine.Next();
        VerifyServiceLineDescription(ServiceLine, ServiceLine.Type::" ", '', ExtendedText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentDateNotUpdatedAfterCreationOfServOrderFromQuote()
    var
        ServiceHeader: Record "Service Header";
        DocDate: Date;
    begin
        // [SCENARIO 381308] "Document Date" should not be updated after creation of Service Order from Service Quote
        Initialize();

        // [GIVEN] Service Quote with "Document Date" = 01.07.16
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());
        DocDate := LibraryRandom.RandDate(100);
        ServiceHeader."Document Date" := DocDate;
        ServiceHeader.Modify();

        // [WHEN] Create Service Order from Service Quote on WORKDATE = 15.07.16
        LibraryService.CreateOrderFromQuote(ServiceHeader);

        // [THEN] Service Order has "Document Date" of 01.07.16
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.SetRange("Quote No.", ServiceHeader."No.");
        ServiceHeader.FindFirst();

        ServiceHeader.TestField("Document Date", DocDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,NonstockItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ShowNonstockItem()
    var
        ItemTempl: Record "Item Templ.";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        NonstockItem: Record "Nonstock Item";
    begin
        // [FEATURE] [Nonstock Item]
        // [SCENARIO 203155] It should be possible to add Nonstock Item having populated "Item Template Code" to the Service Order - Service Lines using the Action for Non Stock Items
        Initialize();

        // [GIVEN] Nonstock Item "I" having Item Template with populated "Gen. Prod. Posting Group" and "Inventory Posting Group"
        LibraryTemplates.CreateItemTemplateWithData(ItemTempl);
        LibraryInventory.CreateNonStockItemWithItemTemplateCode(NonstockItem, ItemTempl.Code);

        // [GIVEN] Service Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryVariableStorage.Enqueue(NonstockItem."Entry No.");

        // [GIVEN] Service Line with "Type" = Item
        MockServiceLineWithTypeItem(ServiceLine, ServiceHeader);

        // [WHEN] Call the "Nonstock Item" action from the service line and select item "I".
        ServiceLine.ShowNonstock();

        // [THEN] The value of "No." in the service line is populated with new Nonstock Item's "No."
        ServiceLine.TestField("No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,NonstockItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ShowNonstockItemWithNoGenProdPostingGroup()
    var
        ItemTempl: Record "Item Templ.";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        NonstockItem: Record "Nonstock Item";
    begin
        // [FEATURE] [Nonstock Item]
        // [SCENARIO 203155] It should not be possible to add Nonstock Item having Item Template with blank "Gen. Prod. Posting Group"
        Initialize();

        // [GIVEN] Nonstock Item with blank "Gen. Prod. Posting Group"
        LibraryTemplates.CreateItemTemplateWithData(ItemTempl);
        LibraryInventory.CreateNonStockItemWithItemTemplateCode(NonstockItem, ItemTempl.Code);
        ItemTempl.Get(NonstockItem."Item Templ. Code");
        ItemTempl."Gen. Prod. Posting Group" := '';
        ItemTempl.Modify(true);

        // [GIVEN] Service Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryVariableStorage.Enqueue(NonstockItem."Entry No.");

        // [GIVEN] Service Line with "Type" = Item
        MockServiceLineWithTypeItem(ServiceLine, ServiceHeader);

        // [WHEN] Call "Nonstock Item" action
        asserterror ServiceLine.ShowNonstock();

        // [THEN] "Default Value must have a value in Config." error appears
        Assert.ExpectedError(EmptyGenProdPostingGroupErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,NonstockItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure ShowNonstockItemWithNoInventoryPostingGroup()
    var
        ItemTempl: Record "Item Templ.";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        NonstockItem: Record "Nonstock Item";
    begin
        // [FEATURE] [Nonstock Item]
        // [SCENARIO 203155] It should not be possible to add Nonstock Item having Item Template with blank "Inventory Posting Group"
        Initialize();

        // [GIVEN] Nonstock Item with blank "Inventory Posting Group"
        LibraryTemplates.CreateItemTemplateWithData(ItemTempl);
        LibraryInventory.CreateNonStockItemWithItemTemplateCode(NonstockItem, ItemTempl.Code);
        ItemTempl.Get(NonstockItem."Item Templ. Code");
        ItemTempl."Inventory Posting Group" := '';
        ItemTempl.Modify(true);

        // [GIVEN] Service Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryVariableStorage.Enqueue(NonstockItem."Entry No.");

        // [GIVEN] Service Line with "Type" = Item
        MockServiceLineWithTypeItem(ServiceLine, ServiceHeader);

        // [WHEN] Call "Nonstock Item" action
        asserterror ServiceLine.ShowNonstock();

        // [THEN] "Default Value must have a value in Config." error appears
        Assert.ExpectedError(EmptyInventoryPostingGroupErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderFromQuoteCustomerWithResponsibilityCenter()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ResponsibilityCenterCode: Code[10];
    begin
        // [SCENARIO 215838] System gets responsibility center from customer when it is specified for customer on making service order from quote.
        Initialize();
        // [GIVEN] Customer "X" where"Responsibility Center" = "RC1"
        CreateCustomerWithResponsibilityCenter(Customer);
        ResponsibilityCenterCode := Customer."Responsibility Center";
        // [GIVEN] Service Quote "Q" for "X" where "Responsibility Center" = "RC2"
        CreateServiceQuote(ServiceHeader, Customer."No.");
        LibrarySales.SetStockoutWarning(false);
        // [WHEN] Create Service Order "O" from "Q"
        LibraryService.CreateOrderFromQuote(ServiceHeader);
        // [THEN] O."Responsibility Center" = "RC2"
        VerifyServiceDocumentResponsibilityCenter(ServiceHeader."Document Type"::Order, Customer."No.", ResponsibilityCenterCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderFromQuoteCustomerWithoutResponsibilityCenter()
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ResponsibilityCenterCode: Code[10];
    begin
        // [SCENARIO 215838] System gets responsibility center from service quote when it does not specified for customer on making order from quote.
        // [GIVEN] Customer "X" without "Responsibility Center"
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Responsibility Center", '');
        Customer.Modify(true);
        // [GIVEN] Service Quote "Q" for "X" where "Responsibility Center" = "RC2"
        CreateServiceHeaderRespCenter(ServiceHeader, ServiceHeader."Document Type"::Quote, Customer."No.");
        ResponsibilityCenterCode := ServiceHeader."Responsibility Center";
        LibrarySales.SetStockoutWarning(false);
        // [WHEN] Create Service Order "O" from "Q"
        LibraryService.CreateOrderFromQuote(ServiceHeader);
        // [THEN] O."Responsibility Center" = "RC1"
        VerifyServiceDocumentResponsibilityCenter(ServiceHeader."Document Type"::Order, Customer."No.", ResponsibilityCenterCode);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    [Scope('OnPrem')]
    procedure ShipServiceOrderUsingPageWithAppliedFilter()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 218581] Service Order's "Customer No." is not blanked after Ship through the Service Order page being applied with filter "Completely Shipped" = FALSE
        Initialize();

        // [GIVEN] Service Order for Customer "X"
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateServiceDocumentWithServiceItem(
          ServiceHeader, ServiceItemLine, ServiceHeader."Document Type"::Order, CustomerNo);
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItemLine."Service Item No.");
        UpdateServiceLineQtyToShipInvoice(ServiceLine, ServiceLine.Quantity);

        // [GIVEN] Open Service Order page and apply filter "Completely Shipped" = "No"
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", ServiceHeader."No.");
        ServiceOrder.FILTER.SetFilter("Completely Shipped", 'No');

        // [WHEN] Ship the Service Order
        LibraryVariableStorage.Enqueue(1); // Post = Ship
        ServiceOrder.Post.Invoke();

        // [THEN] Service Order's "Customer No." = "X"
        ServiceHeader.Find();
        ServiceHeader.TestField("Customer No.", CustomerNo);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandlerWithCustVerification,AmountsOnCrLimitNotificationDetailsModalPageHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure OrderOutstandingAmountOnCreditLimitDetails()
    var
        ServHeader: Record "Service Header";
        ServLine: Record "Service Line";
        ServCheckCreditLimit: Codeunit "Serv. Check Credit Limit";
    begin
        // [FEATURE] [Credit Limit]
        // [SCENARIO 217740] "Outstanding Amount" of Service Order is correct on "Credit Limit Details" page

        // [GIVEN] Customer with "Credit Limit" = 100
        // [GIVEN] Service Order with Customer and "Amount Including VAT" = 350
        Initialize();
        CreateServiceDocWithCrLimitCustomer(ServHeader, ServLine, ServHeader."Document Type"::Order);

        // [WHEN] Check Credit Limit on Service Order
        ServCheckCreditLimit.ServiceHeaderCheck(ServHeader);

        // [THEN] "Credit Limit Notification" shown and subpage "Credit Limit Details" has "Outstanding Amount" and "Total Amount" equal 350
        // Amounts enqueued in AmountsOnCrLimitNotificationDetailsModalPageHandler
        VerifyAmountInclVATOfCreditLimitDetails(ServLine."Amount Including VAT");

        LibraryNotificationMgt.RecallNotificationsForRecord(ServHeader);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandlerWithCustVerification,AmountsOnCrLimitNotificationDetailsModalPageHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure InvOutstandingAmountOnCreditLimitDetails()
    var
        ServHeader: Record "Service Header";
        ServLine: Record "Service Line";
        ServCheckCreditLimit: Codeunit "Serv. Check Credit Limit";
    begin
        // [FEATURE] [Credit Limit]
        // [SCENARIO 217740] "Outstanding Amount" of Service Invoice is correct on "Credit Limit Details" page

        // [GIVEN] Customer with "Credit Limit" = 100
        // [GIVEN] Service Invoice with Customer and "Amount Including VAT" = 350
        Initialize();
        CreateServiceDocWithCrLimitCustomer(ServHeader, ServLine, ServHeader."Document Type"::Invoice);

        // [WHEN] Check Credit Limit on Service Invoice
        ServCheckCreditLimit.ServiceHeaderCheck(ServHeader);

        // [THEN] "Credit Limit Notification" shown and subpage "Credit Limit Details" has "Outstanding Amount" and "Total Amount" equal 350
        // Amounts enqueued in AmountsOnCrLimitNotificationDetailsModalPageHandler
        VerifyAmountInclVATOfCreditLimitDetails(ServLine."Amount Including VAT");

        LibraryNotificationMgt.RecallNotificationsForRecord(ServHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithLinesWithoutServiceItemNoIsDeletedAfterPosting()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [FEATURE] [Service Item Line]
        // [SCENARIO 226470] Service Order is deleted after posting if there are not posted Service Item Lines with "Service Item No." = ''
        Initialize();

        // [GIVEN] Service Order "SO" with Service Item Line with Service Line
        CreateServiceOrderWithItem(
          ServiceHeader, LibrarySales.CreateCustomerNo(), '', LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));

        // [GIVEN] Service Item Line with "Service Item No." = '' for "SO"
        CreateServiceItemLineWithServiceItemNo(ServiceItemLine, ServiceHeader, '');

        // [WHEN] Post Service Order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Service Order is deleted
        VerifyServiceOrderNotExist(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderServiceLinesDimSetIDUpdatedAfterRecreate()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ResponsibilityCenter: Record "Responsibility Center";
        DimensionSetID: Integer;
    begin
        // [FEATURE] [Service Item Line] [Service Line] [Dimension]
        // [SCENARIO 228572] Service Line Dimension Set ID remains the same when Service Lines are recreated
        Initialize();

        // [GIVEN] Service Header with Service Line "SL"
        CreateServiceOrderWithServiceItemLineAndServiceLines(ServiceHeader, false);
        GetServiceLine(ServiceLine, ServiceHeader);

        // [GIVEN] Dimension Set "DS" in "SL"."Dimension Set ID"
        CreateServiceLineDimSet(ServiceLine);
        DimensionSetID := ServiceLine."Dimension Set ID";

        // [WHEN] Change Service Order Responsibility Center with validation (run Service Line recreation)
        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter);
        ServiceHeader.Validate("Responsibility Center", ResponsibilityCenter.Code);
        ServiceHeader.Modify(true);

        // [THEN] Recreated "SL"."Dimension Set ID" = "DS"
        GetServiceLine(ServiceLine, ServiceHeader);
        ServiceLine.TestField("Dimension Set ID", DimensionSetID);
    end;

    [Test]
    [HandlerFunctions('GetServiceShipmentLinesHandler')]
    [Scope('OnPrem')]
    procedure CreateServiceInvoiceLineFromServiseShipmentLinePostingDate()
    var
        ServiceOrderHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Invoice] [Service Line] [UI]
        // [SCENARIO 229340] Service Invoice Lines created from Service Shipment Lines take Posting Date from Service Invoice
        Initialize();
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Shipped Service Order with Posting Date "PD1"
        CreateAndShipServiceOrderWithPostingDate(ServiceOrderHeader, CustomerNo, LibraryRandom.RandDate(0));

        // [GIVEN] Service Invoice with Posting Date "PD2"
        LibraryService.CreateServiceHeader(ServiceInvoiceHeader, ServiceInvoiceHeader."Document Type"::Invoice, CustomerNo);
        ServiceInvoiceHeader.Validate("Posting Date", LibraryRandom.RandDate(10));
        ServiceInvoiceHeader.Modify(true);

        // [WHEN] Run Create Service Invoice Lines from Service Shipment Lines
        OpenServiceInvoicePage(ServiceInvoiceHeader."No.");

        // [THEN] Service Invoice Line Posting Date is equal to "PD2"
        VerifyServiceLinePostingDate(ServiceInvoiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultLocationCodeFromCustomerOnValidateAndInsert()
    var
        Customer: Record Customer;
        Location: Record Location;
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Customer] [Location] [UT]
        // [SCENARIO 255036] "Location Code" in Service Document must be copied from Customer when the Service Header is inserted after validating "Customer No."
        Initialize();

        // [GIVEN] Customer "10000" with Location "BLUE"
        CreateCustomerWithLocationCode(Customer, Location);

        // [WHEN] Validate "Sell-to Customer No." with "10000" in new Service Order
        ServiceHeader.Validate("Customer No.", Customer."No.");
        ServiceHeader.Insert(true);

        // [THEN] "Location Code" = "BLUE" in the Service Order
        ServiceHeader.TestField("Location Code", Customer."Location Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure DefaultLocationCodeFromCustomerOnRevalidatingBuyFromVendor()
    var
        Customer: Record Customer;
        Location: Record Location;
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Customer] [Location] [UT]
        // [SCENARIO 255036] "Location Code" in Service Document must be copied from Customer when "Customer No." is set and then revalidated with a new value
        Initialize();

        // [GIVEN] Customer "10000" with Location "BLUE"
        CreateCustomerWithLocationCode(Customer, Location);

        // [GIVEN] Service Order with "Sell-to Customer No." = "10000"
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Customer "20000" with Location "RED"
        CreateCustomerWithLocationCode(Customer, Location);

        // [WHEN] Validate "Customer No." with "20000" in the Service Order
        ServiceHeader.Validate("Customer No.", Customer."No.");

        // [THEN] "Location Code" = "RED" in the Service Order
        ServiceHeader.TestField("Location Code", Customer."Location Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandlerWithAnswer')]
    [Scope('OnPrem')]
    procedure CancelChangeBillToCustomerNoWhenValidateSellToCustomerNoService()
    var
        ServiceHeader: Record "Service Header";
        BillToCustNo: Code[20];
    begin
        // [FEATURE] [UI] [UT] [Bill-to Customer]
        // [SCENARIO 288106] Stan validates Sell-to Cust No in Service Document and cancels change of Bill-to Customer No
        Initialize();

        // [GIVEN] Service Invoice with a line
        CreateServiceInvoiceSimple(ServiceHeader);

        // [GIVEN] Stan confirmed change of Bill-to Customer No. and line recalculation in Service Invoice
        BillToCustNo := LibrarySales.CreateCustomerNo();
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        ServiceHeader.Validate("Bill-to Customer No.", BillToCustNo);
        ServiceHeader.Modify(true);

        // [GIVEN] Stan validated Sell-to Customer No. in Service Invoice
        LibraryVariableStorage.Enqueue(false);
        ServiceHeader.Validate("Customer No.");

        // [WHEN] Stan cancels change of Bill-to Customer No.
        // done in ConfirmMessageHandlerWithAnswer

        // [THEN] Bill-to Customer No. is not changed
        ServiceHeader.TestField("Bill-to Customer No.", BillToCustNo);

        // [THEN] No other confirmations pop up and no errors
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDocumentLineDescriptionToGLEntry()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [FEATURE] [G/L Entry] [Description]
        // [SCENARIO 300843] G/L account type document line Description is copied to G/L entry when ServiceSetup."Copy Line Descr. to G/L Entry" = "Yes"
        Initialize();

        // [GIVEN] Set ServiceSetup."Copy Line Descr. to G/L Entry" = "Yes"
        SetServiceSetupCopyLineDescrToGLEntry(true);

        // [GIVEN] Create service invoice with 5 "G/L Account" type lines with unique descriptions "Descr1" - "Descr5"
        CreateServiceInvoiceWithUniqueDescriptionLines(ServiceHeader, TempServiceLine, TempServiceLine.Type::"G/L Account");

        // [WHEN] Service invoice is being posted
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] G/L entries created with descriptions "Descr1" - "Descr5"
        VerifyGLEntriesDescription(TempServiceLine, ServiceHeader."Customer No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendCopyDocumentLineDescriptionToGLEntry()
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
        ServiceOrders: Codeunit "Service Orders";
    begin
        // [FEATURE] [G/L Entry] [Description]
        // [SCENARIO 300843] Event InvoicePostBuffer.OnAfterInvPostBufferPrepareService can be used to copy document line Description for line type Item
        Initialize();

        // [GIVEN] Subscribe on InvoicePostBuffer.OnAfterInvPostBufferPrepareService
        BINDSUBSCRIPTION(ServiceOrders);

        // [GIVEN] Set ServiceSetup."Copy Line Descr. to G/L Entry" = "No"
        SetServiceSetupCopyLineDescrToGLEntry(false);

        // [GIVEN] Create service invoice with 5 "Item" type lines with unique descriptions "Descr1" - "Descr5"
        CreateServiceInvoiceWithUniqueDescriptionLines(ServiceHeader, TempServiceLine, TempServiceLine.Type::Item);

        // [WHEN] Service invoice is being posted
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] G/L entries created with descriptions "Descr1" - "Descr5"
        VerifyGLEntriesDescription(TempServiceLine, ServiceHeader."Customer No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcServTimeSameDayBeforeServiceHoursUT()
    var
        ServiceHour: Record "Service Hour";
        ServOrderManagement: Codeunit ServOrderManagement;
        StartingTime: Time;
        ActualResponseHours: Decimal;
    begin
        // [FEATURE] [UT] [Actual Response Hours]
        // [SCENARIO 313678] Actual Response Hours calculation is based on service hours when starting time is before service hours with the same date
        Initialize();
        ServiceHour.DeleteAll();
        CheckWorkDateIsWorkingDate();

        // [GIVEN] Service hours defined for WORKDAY
        LibraryService.CreateDefaultServiceHour(ServiceHour, Date2DWY(WorkDate(), 1) - 1);
        // [GIVEN] Service Order's "Starting Time" is on the same day before starting hours
        StartingTime := 000000T + LibraryRandom.RandInt(ServiceHour."Starting Time" - 000000T);

        // [WHEN] Calculating Actual Response Hours
        ActualResponseHours := ServOrderManagement.CalcServTime(WorkDate(), StartingTime, WorkDate(), ServiceHour."Ending Time", '', false);

        // [THEN] Only service hours are counted
        Assert.AreEqual(Round((ServiceHour."Ending Time" - ServiceHour."Starting Time") / 3600000, 0.01), ActualResponseHours, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcServTimeSameDayDuringServiceHoursUT()
    var
        ServiceHour: Record "Service Hour";
        ServOrderManagement: Codeunit ServOrderManagement;
        StartingTime: Time;
        ActualResponseHours: Decimal;
    begin
        // [FEATURE] [UT] [Actual Response Hours]
        // [SCENARIO 313678] Actual Response Hours calculation is based on starting time when starting time is during service hours with the same date
        Initialize();
        ServiceHour.DeleteAll();
        CheckWorkDateIsWorkingDate();

        // [GIVEN] Service hours defined for WORKDAY
        LibraryService.CreateDefaultServiceHour(ServiceHour, Date2DWY(WorkDate(), 1) - 1);
        // [GIVEN] Service Order's "Starting Time" is on the same day during starting hours
        StartingTime := 000000T + LibraryRandom.RandIntInRange(ServiceHour."Starting Time" - 000000T, ServiceHour."Ending Time" - 000000T);

        // [WHEN] Calculating Actual Response Hours
        ActualResponseHours := ServOrderManagement.CalcServTime(WorkDate(), StartingTime, WorkDate(), ServiceHour."Ending Time", '', false);

        // [THEN] Only service hours are counted
        Assert.AreEqual(Round((ServiceHour."Ending Time" - StartingTime) / 3600000, 0.01), ActualResponseHours, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcServTimeNextDayBeforeServiceHoursUT()
    var
        ServiceHour: Record "Service Hour";
        ServOrderManagement: Codeunit ServOrderManagement;
        StartingTime: Time;
        ActualResponseHours: Decimal;
    begin
        // [FEATURE] [UT] [Actual Response Hours]
        // [SCENARIO 313678] Actual Response Hours calculation is based on service hours when starting time is before service hours with different dates
        Initialize();
        ServiceHour.DeleteAll();
        CheckWorkDateIsWorkingDate();

        // [GIVEN] Service hours defined for WORKDAY
        LibraryService.CreateDefaultServiceHour(ServiceHour, Date2DWY(WorkDate(), 1) - 1);

        // [GIVEN] Service Order's "Starting Time" and "Finishing Time" are before service hours
        StartingTime := 000000T + LibraryRandom.RandInt(ServiceHour."Starting Time" - 000000T);

        // [WHEN] Calculating Actual Response Hours, finishing time doesn't matter
        ActualResponseHours := ServOrderManagement.CalcServTime(WorkDate(), StartingTime, CalcDate('<+1D>', WorkDate()), StartingTime, '', false);

        // [THEN] Only service hours are counted
        Assert.AreEqual(Round((ServiceHour."Ending Time" - ServiceHour."Starting Time") / 3600000, 0.01), ActualResponseHours, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcServTimeNextDayDuringServiceHoursUT()
    var
        ServiceHour: Record "Service Hour";
        ServOrderManagement: Codeunit ServOrderManagement;
        StartingTime: Time;
        ActualResponseHours: Decimal;
    begin
        // [FEATURE] [UT] [Actual Response Hours]
        // [SCENARIO 313678] Actual Response Hours calculation is based on starting time when starting time is during service hours with different dates
        Initialize();
        ServiceHour.DeleteAll();
        CheckWorkDateIsWorkingDate();

        // [GIVEN] Service hours defined for WORKDAY
        LibraryService.CreateDefaultServiceHour(ServiceHour, Date2DWY(WorkDate(), 1) - 1);
        // [GIVEN] Service Order's "Starting Time" is on the same day during starting hours
        StartingTime := 000000T + LibraryRandom.RandIntInRange(ServiceHour."Starting Time" - 000000T, ServiceHour."Ending Time" - 000000T);

        // [WHEN] Calculating Actual Response Hours, finishing time doesn't matter
        ActualResponseHours := ServOrderManagement.CalcServTime(WorkDate(), StartingTime, CalcDate('<+1D>', WorkDate()), StartingTime, '', false);

        // [THEN] Only service hours are counted
        Assert.AreEqual(Round((ServiceHour."Ending Time" - StartingTime) / 3600000, 0.01), ActualResponseHours, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipToRegionCodeDoesNotAffectVat()
    var
        CountryRegion: array[2] of Record "Country/Region";
        Customer: array[2] of Record Customer;
        GLSetup: Record "General Ledger Setup";
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Ship-To] [VAT]
        // [SCENARIO 317562] Changing "Ship-to Country/Region Code" on a Service document doesn't affect "VAT Country/Region Code"
        Initialize();
        GLSetup.Get();
        GLSetup.Validate("Bill-to/Sell-to VAT Calc.", GLSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");
        GLSetup.Modify();

        // [GIVEN] Created two Customers with different Country/Region codes
        CreateCustomerWithCountryRegion(CountryRegion[1], Customer[1]);
        CreateCustomerWithCountryRegion(CountryRegion[2], Customer[2]);

        // [GIVEN] Created a Service document for the first Customer
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer[1]."No.");

        // [WHEN] Change "Ship-to Country/Region Code" on a Service Header to the second Country/Region code
        ServiceHeader.Validate("Ship-to Country/Region Code", CountryRegion[2].Code);
        ServiceHeader.Modify(true);

        // [THEN] "VAT Country/Region Code" on a Service Header is still from the first Customer
        Assert.AreEqual(Customer[1]."Country/Region Code", ServiceHeader."VAT Country/Region Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullDocTypeName()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] Get full document type and name
        // [GIVEN] Service Header of type "Order"
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Order;

        // [WHEN] GetFullDocTypeTxt is called
        // [THEN] 'Service Order' is returned
        Assert.AreEqual('Service Order', ServiceHeader.GetFullDocTypeTxt(), 'The expected full document type is incorrect');

        // [GIVEN] Service Header of type "Invoice"
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Invoice;

        // [WHEN] GetFullDocTypeTxt is called
        // [THEN] 'Service Invoice' is returned
        Assert.AreEqual('Service Invoice', ServiceHeader.GetFullDocTypeTxt(), 'The expected full document type is incorrect');

        // [GIVEN] Service Header of type "Credit Memo"
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::"Credit Memo";

        // [WHEN] GetFullDocTypeTxt is called
        // [THEN] 'Service Credit Memo' is returned
        Assert.AreEqual('Service Credit Memo', ServiceHeader.GetFullDocTypeTxt(), 'The expected full document type is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetLineNoReturnsLastServiceLineNo()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service Line] [UT]
        // [SCENARIO 335496] "GetLineNo" function returns next line no. after the last service line and "Line No." = 10000 if no service line exists.
        Initialize();

        ServiceHeader.Init();
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Order;
        ServiceHeader."No." := LibraryUtility.GenerateGUID();
        ServiceHeader.Insert();

        ServiceLine.Init();
        ServiceLine."Document Type" := ServiceHeader."Document Type";
        ServiceLine."Document No." := ServiceHeader."No.";
        ServiceLine."Line No." := ServiceLine.GetLineNo();
        ServiceLine.Insert();
        ServiceLine.TestField("Line No.", 10000);

        ServiceLine.Init();
        ServiceLine."Document Type" := ServiceHeader."Document Type";
        ServiceLine."Document No." := ServiceHeader."No.";
        ServiceLine."Line No." := ServiceLine.GetLineNo();

        ServiceLine.TestField("Line No.", 20000);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmMessageHandler')]
    procedure RecreateServiceCommentLines()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCommentLine: Record "Service Comment Line";
    begin
        // [FEATURE] [Service Comment Line] [UT]
        // [SCENARIO 351187] The Service Comment Lines must be copied after Service Lines have been recreated
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, "Service Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, "Service Line Type"::Item, LibraryInventory.CreateItemNo());
        LibraryService.CreateServiceCommentLine(
            ServiceCommentLine, ServiceCommentLine."Table Name"::"Service Header",
            ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", ServiceCommentLine.Type::General, ServiceLine."Line No.");

        ServiceHeader.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());
        // [SCENARIO 360476] No duplicate Comment Lines inserted
        Commit();

        VerifyCountServiceCommentLine(ServiceCommentLine."Table Name"::"Service Header",
            ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", 10000);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmMessageHandler')]
    procedure RecreateServiceCommentLineForServiceLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCommentLine: Record "Service Comment Line";
    begin
        // [FEATURE] [Service Comment Line] [UT]
        // [SCENARIO 399071] The Service Comment Lines must be copied after Service Lines have been recreated if Service Line No. < 10000
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, "Service Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        CreateServiceLineSimple(ServiceLine, ServiceHeader, 5000);
        LibraryService.CreateServiceCommentLine(
            ServiceCommentLine, ServiceCommentLine."Table Name"::"Service Header",
            ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", ServiceCommentLine.Type::General, ServiceLine."Line No.");
        LibraryService.CreateServiceCommentLine(
            ServiceCommentLine, ServiceCommentLine."Table Name"::"Service Header",
            ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", ServiceCommentLine.Type::General, 0);

        ServiceHeader.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());
        Commit();

        VerifyCountServiceCommentLine(ServiceCommentLine."Table Name"::"Service Header",
            ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", 10000);
        VerifyCountServiceCommentLine(ServiceCommentLine."Table Name"::"Service Header",
            ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectCalculationLineDiscountForServiceLineWithSalesPrice()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        Item: Record Item;
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [FEATURE] [Line Discount] [Sales Price] [Warranty]
        // [SCENARIO 348944] Change "Exclude Warranty" to True in Service Line
        Initialize();
        // [GIVEN] Customer and Item 
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Service Header for Customer
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Sales Price with Item for Customer 
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", "Sales Price Type"::Customer, Customer."No.", WorkDate(), '', '', '', 0, LibraryRandom.RandInt(20));
        SalesPrice.Validate("Allow Line Disc.", false);
        SalesPrice.Modify(true);

        // [GIVEN] Sales Line Discount with Item for Customer with "Line Discount %"
        CreateSalesLineDiscount(SalesLineDiscount, Customer."No.", Item."No.");
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandInt(25));
        SalesLineDiscount.Modify(true);

        // [GIVEN] Service Item and Service Item Line
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Service Line with Item , "Line Discount %" and "Line Discount %" are equal to 0
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItem."No.");
        ServiceLine.Validate("No.", Item."No.");
        ServiceLine.TestField("Line Discount %", 0);
        ServiceLine.TestField("Line Discount Amount", 0);

        // [WHEN] Set "Exclude Warranty" to True
        ServiceLine.Validate("Exclude Warranty", true);

        // [THEN] "Line Discount %" is equal to 0
        // [THEN] "Line Discount Amount" is equal to 0
        ServiceLine.TestField("Line Discount %", 0);
        ServiceLine.TestField("Line Discount Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ThereIsNoPaymentGLEntriesAfterPostingServiceOrderWithEmptyPaymentMethodCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
        GLEntry: Record "G/L Entry";
        ServiceItemLineNo: Integer;
    begin
        // [SCENARIO 369667] Posting Service Order with empty "Payment Method Code" did not create G/L Entries with "Payment" type
        // [SCENARIO 369667] even if "Payment Method Code" filled in Customer table
        Initialize();

        // [GIVEN] Create Customer With "Payment Method Code"
        CreateAndModifyCustomer(Customer, Customer."Application Method"::Manual, FindPaymentMethodWithBalanceAccount(), 0);

        // [GIVEN] Create Service Order
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLineNo);

        // [GIVEN] Changed "Payment Method Code" to empty in Service Header
        ServiceHeader.Validate("Payment Method Code", '');

        // [WHEN] Post Service Order as "Ship + Invoice"
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] There is no created G/L Entries with "Document Type" = Payment
        GLEntry.SetRange("External Document No.", ServiceHeader."No.");
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        Assert.IsTrue(GLEntry.IsEmpty, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ThereIsNoPaymentCustLedEntriesAfterPostingServiceOrderWithEmptyPaymentMethodCode()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ServiceItemLineNo: Integer;
    begin
        // [SCENARIO 369667] Posting Service Order with empty "Payment Method Code" did not create Customer Ledger Entries with "Payment" type
        // [SCENARIO 369667] even if "Payment Method Code" filled in Customer table
        Initialize();

        // [GIVEN] Create Customer With "Payment Method Code"
        CreateAndModifyCustomer(Customer, Customer."Application Method"::Manual, FindPaymentMethodWithBalanceAccount(), 0);

        // [GIVEN] Create Service Order
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLineNo);

        // [GIVEN] Changed "Payment Method Code" to empty in Service Header
        ServiceHeader.Validate("Payment Method Code", '');

        // [WHEN] Post Service Order as "Ship + Invoice"
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] There is no created Customer Ledger Entries with "Document Type" = Payment
        CustLedgerEntry.SetRange("External Document No.", ServiceHeader."No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        Assert.IsTrue(CustLedgerEntry.IsEmpty, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidationOfPaymentMethodCodeByEmptyValue()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
        ServiceItemLineNo: Integer;
    begin
        // [SCENARIO 369667] Validate "Payment Method Code" in Service Header to empty space and "Bal. Account No." should changed to empty space too
        Initialize();

        // [GIVEN] Created Customer with "Payment Method Code"
        CreateAndModifyCustomer(Customer, Customer."Application Method"::Manual, FindPaymentMethodWithBalanceAccount(), 0);

        // [GIVEN] Created Service Order with lines
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader, Customer."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLineNo);

        // [WHEN] Change "Payment Method Code" to empty
        ServiceHeader.Validate("Payment Method Code", '');

        // [THEN] The "Bal. Account No." reset to empty value too
        ServiceHeader.TestField("Bal. Account No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateQtyToShipAndQtyToInvoiceOnValidateQuantityWarehousing()
    var
        ServiceHeader: Record "Service Header";
        ServiceLineForItem: Record "Service Line";
        ServiceLineForResource: Record "Service Line";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        Location: Record Location;
        ServiceItemLineNo: Integer;
        RandQty: Integer;
        QtyNotUpdatedErr: Label 'Quantity is not updated correctly for item type %1', Comment = '%1 = Resource';
    begin
        // [SCENARIO] Qty. to Ship and Qty. to Invoice should be updated when updating the quantity for a relevant item types when require shipment or require receive.

        // [GIVEN] Service Order with Service lines and Location with require shipment and require receive.
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, true, true);
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Modify(true);
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader, '');
        ServiceHeader.Validate("Location Code", Location.Code);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(ServiceLineForItem, ServiceHeader, ServiceLineForItem.Type::Item, '');
        LibraryService.CreateServiceLine(ServiceLineForResource, ServiceHeader, ServiceLineForResource.Type::Resource, '');

        // [WHEN] Update Quantity on Resource Line
        RandQty := LibraryRandom.RandInt(10);
        ServiceLineForResource.Validate(Quantity, RandQty);

        // [THEN] The quantity fields should be updated correctly
        Assert.AreEqual(RandQty, ServiceLineForResource."Qty. to Ship", StrSubstNo(QtyNotUpdatedErr, ServiceLineForResource.Type::Resource));
        Assert.AreEqual(RandQty, ServiceLineForResource."Qty. to Invoice", StrSubstNo(QtyNotUpdatedErr, ServiceLineForResource.Type::Resource));
        Assert.AreEqual(RandQty, ServiceLineForResource."Outstanding Quantity", StrSubstNo(QtyNotUpdatedErr, ServiceLineForResource.Type::Resource));
        Assert.AreEqual(RandQty, ServiceLineForResource."Quantity (Base)", StrSubstNo(QtyNotUpdatedErr, ServiceLineForResource.Type::Resource));
        Assert.AreEqual(RandQty, ServiceLineForResource."Qty. to Ship (Base)", StrSubstNo(QtyNotUpdatedErr, ServiceLineForResource.Type::Resource));
        Assert.AreEqual(RandQty, ServiceLineForResource."Qty. to Invoice (Base)", StrSubstNo(QtyNotUpdatedErr, ServiceLineForResource.Type::Resource));
        Assert.AreEqual(RandQty, ServiceLineForResource."Outstanding Qty. (Base)", StrSubstNo(QtyNotUpdatedErr, ServiceLineForResource.Type::Resource));

        // [WHEN] Update Quantity on Item Line
        RandQty := LibraryRandom.RandInt(10);
        ServiceLineForItem.Validate(Quantity, RandQty);

        // [THEN] The quantity fields should be updated correctly.
        // Warehouse documents will update the Qty. to Ship/Receive fields for inventoriable type and document type order.
        Assert.AreEqual(0, ServiceLineForItem."Qty. to Ship", StrSubstNo(QtyNotUpdatedErr, ServiceLineForItem.Type::Resource));
        Assert.AreEqual(0, ServiceLineForItem."Qty. to Invoice", StrSubstNo(QtyNotUpdatedErr, ServiceLineForItem.Type::Resource));
        Assert.AreEqual(RandQty, ServiceLineForItem."Outstanding Quantity", StrSubstNo(QtyNotUpdatedErr, ServiceLineForItem.Type::Resource));
        Assert.AreEqual(RandQty, ServiceLineForItem."Quantity (Base)", StrSubstNo(QtyNotUpdatedErr, ServiceLineForItem.Type::Resource));
        Assert.AreEqual(0, ServiceLineForItem."Qty. to Ship (Base)", StrSubstNo(QtyNotUpdatedErr, ServiceLineForItem.Type::Resource));
        Assert.AreEqual(0, ServiceLineForItem."Qty. to Invoice (Base)", StrSubstNo(QtyNotUpdatedErr, ServiceLineForItem.Type::Resource));
        Assert.AreEqual(RandQty, ServiceLineForItem."Outstanding Qty. (Base)", StrSubstNo(QtyNotUpdatedErr, ServiceLineForResource.Type::Resource));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingErrorThrownWhenInvalidQuantityEntered0OnServiceLine()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] A rounding error should be thrown if the entered base quantity does not match the rounding precision.

        // [GIVEN] A service line using base UoM with rounding precision of 0.01.
        SetupForUoMTest(Item, ServiceLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 3, 0.01);
        ServiceLine.Validate("Unit of Measure Code", ItemUOM.Code);

        // [WHEN] Setting the quantity to 0.33.
        ServiceLine.Validate(Quantity, 0.33);

        // [THEN] No error is thrown an base qty is 0.33.
        Assert.AreEqual(0.33, ServiceLine."Quantity (Base)", 'Expected quantity to be 0.33');

        // [WHEN] Setting the quantity to 0.333.
        asserterror ServiceLine.Validate(Quantity, 0.333);

        // [THEN] An rounding error is thrown.
        Assert.ExpectedError(RoundingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenQuantityIsRoundedTo0OnServiceLine()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] A rounding to 0 error should be thrown if the entered non-base quantity converted to the 
        // base quantity is rounded to zero.

        // [GIVEN] A service line using non-base UoM with rounding precision of 0.01.
        SetupForUoMTest(Item, ServiceLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 3, 0.01);
        ServiceLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);

        // [WHEN] Setting the quantity to 1/3.
        ServiceLine.Validate(Quantity, 1 / 3);

        // [THEN] Base quantity is 1 and no error is thrown.
        Assert.AreEqual(1, ServiceLine."Quantity (Base)", 'Expected quantity to be 1.');

        // [WHEN] Setting the quantity to 1/611 (1/611 = 0.00164 * 3 = 0.00492, which gets rounded to 0).
        asserterror ServiceLine.Validate(Quantity, 1 / 611);

        // [THEN] A rounding to zero error is thrown.
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineQuantityIsRoundedWithRoundingPrecisionSpecified()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] When converting to base UoM the specified rounding precision should be used.

        // [GIVEN] A service line using non-base UoM with rounding precision of 0.01.
        SetupForUoMTest(Item, ServiceLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 3, 0.01);
        ServiceLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);

        // [WHEN] Setting the quantity to 1/30 (1/30 = 0.03333 * 3 = 0.09999, which gets rounded to 0.1).
        ServiceLine.Validate(Quantity, 1 / 30);

        // [THEN] The base quantity is rounded to 0.1.
        Assert.AreEqual(0.1, ServiceLine."Quantity (Base)", 'Expected value to be rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingErrorThrownWhenInvalidQtyToShipEntered0OnServiceLine()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] A rounding error should be thrown if the entered base quantity does not match the rounding precision.

        // [GIVEN] A service line using base UoM with rounding precision of 0.01.
        SetupForUoMTest(Item, ServiceLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 3, 0.01);
        ServiceLine.Validate("Unit of Measure Code", ItemUOM.Code);

        // [WHEN] Setting the quantity to 0.33.
        ServiceLine.Validate(Quantity, 0.33);
        ServiceLine.Validate("Qty. to Ship", 0.33);

        // [THEN] No error is thrown an base qty is 0.33.
        Assert.AreEqual(0.33, ServiceLine."Qty. to Ship (Base)", 'Expected quantity to be 0.33');

        // [WHEN] Setting the quantity to 0.331.
        asserterror ServiceLine.Validate("Qty. to Ship", 0.331);

        // [THEN] An rounding error is thrown.
        Assert.ExpectedError(RoundingBalanceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenQtyToShipIsRoundedTo0OnServiceLine()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] A rounding to 0 error should be thrown if the entered non-base quantity converted to the 
        // base quantity is rounded to zero.

        // [GIVEN] A service line using non-base UoM with rounding precision of 0.01.
        SetupForUoMTest(Item, ServiceLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 3, 0.01);
        ServiceLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);

        // [WHEN] Setting the quantity to 1/3.
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Validate("Qty. to Ship", 1 / 3);

        // [THEN] Base quantity is 1 and no error is thrown.
        Assert.AreEqual(1, ServiceLine."Qty. to Ship (Base)", 'Expected quantity to be 1.');

        // [WHEN] Setting the quantity to 1/611 (1/611 = 0.00164 * 3 = 0.00492, which gets rounded to 0).
        asserterror ServiceLine.Validate("Qty. to Ship", 1 / 611);

        // [THEN] A rounding to zero error is thrown.
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineQtyToShipIsRoundedWithRoundingPrecisionSpecified()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] When converting to base UoM the specified rounding precision should be used.

        // [GIVEN] A service line using non-base UoM with rounding precision of 0.01.
        SetupForUoMTest(Item, ServiceLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 3, 0.01);
        ServiceLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);

        // [WHEN] Setting the quantity to 1/30 (1/30 = 0.03333 * 3 = 0.09999, which gets rounded to 0.1).
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Validate("Qty. to Ship", 1 / 30);

        // [THEN] The base quantity is rounded to 0.1.
        Assert.AreEqual(0.1, ServiceLine."Qty. to Ship (Base)", 'Expected value to be rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingErrorThrownWhenInvalidQtyToInvoiceEntered0OnServiceLine()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] A rounding error should be thrown if the entered base quantity does not match the rounding precision.

        // [GIVEN] A service line using base UoM with rounding precision of 0.01.
        SetupForUoMTest(Item, ServiceLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 3, 0.01);
        ServiceLine.Validate("Unit of Measure Code", ItemUOM.Code);

        // [WHEN] Setting the quantity to 0.33.
        ServiceLine.Validate(Quantity, 0.33);
        ServiceLine.Validate("Qty. to Invoice", 0.33);

        // [THEN] No error is thrown an base qty is 0.33.
        Assert.AreEqual(0.33, ServiceLine."Qty. to Invoice (Base)", 'Expected quantity to be 0.33');

        // [WHEN] Setting the quantity to 0.331.
        asserterror ServiceLine.Validate("Qty. to Invoice", 0.331);

        // [THEN] An rounding error is thrown.
        Assert.ExpectedError(RoundingBalanceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenQtyToInvoiceIsRoundedTo0OnServiceLine()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] A rounding to 0 error should be thrown if the entered non-base quantity converted to the 
        // base quantity is rounded to zero.

        // [GIVEN] A service line using non-base UoM with rounding precision of 0.01.
        SetupForUoMTest(Item, ServiceLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 3, 0.01);
        ServiceLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);

        // [WHEN] Setting the quantity to 1/3.
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Validate("Qty. to Invoice", 1 / 3);

        // [THEN] Base quantity is 1 and no error is thrown.
        Assert.AreEqual(1, ServiceLine."Qty. to Invoice (Base)", 'Expected quantity to be 1.');

        // [WHEN] Setting the quantity to 1/611 (1/611 = 0.00164 * 3 = 0.00492, which gets rounded to 0).
        asserterror ServiceLine.Validate("Qty. to Invoice", 1 / 611);

        // [THEN] A rounding to zero error is thrown.
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineQtyToInvoiceIsRoundedWithRoundingPrecisionSpecified()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] When converting to base UoM the specified rounding precision should be used.

        // [GIVEN] A service line using non-base UoM with rounding precision of 0.01.
        SetupForUoMTest(Item, ServiceLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 3, 0.01);
        ServiceLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);

        // [WHEN] Setting the quantity to 1/30 (1/30 = 0.03333 * 3 = 0.09999, which gets rounded to 0.1).
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Validate("Qty. to Invoice", 1 / 30);

        // [THEN] The base quantity is rounded to 0.1.
        Assert.AreEqual(0.1, ServiceLine."Qty. to Invoice (Base)", 'Expected value to be rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingErrorThrownWhenInvalidQtyToConsumeEntered0OnServiceLine()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] A rounding error should be thrown if the entered base quantity does not match the rounding precision.

        // [GIVEN] A service line using base UoM with rounding precision of 0.01.
        SetupForUoMTest(Item, ServiceLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 3, 0.01);
        ServiceLine.Validate("Unit of Measure Code", ItemUOM.Code);

        // [WHEN] Setting the quantity to 0.33.
        ServiceLine.Validate(Quantity, 0.33);
        ServiceLine.Validate("Qty. to Consume", 0.33);

        // [THEN] No error is thrown an base qty is 0.33.
        Assert.AreEqual(0.33, ServiceLine."Qty. to Consume (Base)", 'Expected quantity to be 0.33');

        // [WHEN] Setting the quantity to 0.331.
        asserterror ServiceLine.Validate("Qty. to Consume", 0.331);

        // [THEN] An rounding error is thrown.
        Assert.ExpectedError(RoundingBalanceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorThrownWhenQtyToConsumeIsRoundedTo0OnServiceLine()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] A rounding to 0 error should be thrown if the entered non-base quantity converted to the 
        // base quantity is rounded to zero.

        // [GIVEN] A service line using non-base UoM with rounding precision of 0.01.
        SetupForUoMTest(Item, ServiceLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 3, 0.01);
        ServiceLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);

        // [WHEN] Setting the quantity to 1/3.
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Validate("Qty. to Consume", 1 / 3);

        // [THEN] Base quantity is 1 and no error is thrown.
        Assert.AreEqual(1, ServiceLine."Qty. to Consume (Base)", 'Expected quantity to be 1.');

        // [WHEN] Setting the quantity to 1/611 (1/611 = 0.00164 * 3 = 0.00492, which gets rounded to 0).
        asserterror ServiceLine.Validate("Qty. to Consume", 1 / 611);

        // [THEN] A rounding to zero error is thrown.
        Assert.ExpectedError(RoundingTo0Err);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineQtyToConsumeIsRoundedWithRoundingPrecisionSpecified()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
    begin
        // [SCENARIO] When converting to base UoM the specified rounding precision should be used.

        // [GIVEN] A service line using non-base UoM with rounding precision of 0.01.
        SetupForUoMTest(Item, ServiceLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 3, 0.01);
        ServiceLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);

        // [WHEN] Setting the quantity to 1/30 (1/30 = 0.03333 * 3 = 0.09999, which gets rounded to 0.1).
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Validate("Qty. to Consume", 1 / 30);

        // [THEN] The base quantity is rounded to 0.1.
        Assert.AreEqual(0.1, ServiceLine."Qty. to Consume (Base)", 'Expected value to be rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineSplitQuantityBetweenShipAndConsumeNoLeftoverQuantityFromRounding()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [SCENARIO] It should be possible to split up the service line quantity between invoice and consume 
        // without any imbalance.

        // [GIVEN] A service line using non-base UoM with rounding precision of 0.01.
        SetupForUoMTest(Item, ServiceLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 3, 0.01);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ServiceLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);

        // [GIVEN] A quantity of 1.
        ServiceLine.Validate(Quantity, 1);

        // [WHEN] Setting the quantity to ship to 1/3 and post ship.
        ServiceLine.Validate("Qty. to Ship", 1 / 3);
        ServiceLine.Modify(true);
        TempServiceLine := ServiceLine;
        TempServiceLine.Insert();
        LibraryService.PostServiceOrderWithPassedLines(ServiceHeader, TempServiceLine, true, false, false);

        // [THEN] Outstanding quantity base is 2 and shipped quantity base is 1.
        ServiceLine.Find();
        Assert.AreEqual(2, ServiceLine."Outstanding Qty. (Base)", 'Expected value to be rounded correctly.');
        Assert.AreEqual(1, ServiceLine."Qty. Shipped (Base)", 'Expected value to be rounded correctly.');

        // [WHEN] Setting the quantity to consume to 2/3 and post ship and consume.
        ServiceLine.Validate("Qty. to Consume", 2 / 3);
        ServiceLine.Modify(true);
        TempServiceLine.Delete();
        TempServiceLine := ServiceLine;
        TempServiceLine.Insert();
        LibraryService.PostServiceOrderWithPassedLines(ServiceHeader, TempServiceLine, true, true, false);

        // [THEN] Quantity consumed base is 2 and oustanding quantity base is 0.
        ServiceLine.Find();
        Assert.AreEqual(2, ServiceLine."Qty. Consumed (Base)", 'Expected value to be rounded correctly.');
        Assert.AreEqual(0, ServiceLine."Outstanding Qty. (Base)", 'Expected value to be rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineErrorQtyShipImbalanceWhenUpdateQtyConsume()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemUOM: Record "Item Unit of Measure";
        ItemNonBaseUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        TempServiceLine: Record "Service Line" temporary;
    begin
        // [SCENARIO] Quantity to ship should be validated when updating quantity to consume.
        Initialize();

        // [GIVEN] A service line using non-base UoM with rounding precision of 1.
        SetupForUoMTest(Item, ServiceLine, BaseUOM, NonBaseUOM, ItemUOM, ItemNonBaseUOM, 1, 3, 1);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        ServiceLine.Validate("Unit of Measure Code", ItemNonBaseUOM.Code);

        // [GIVEN] A quantity of 1.
        ServiceLine.Validate(Quantity, 1);

        // [WHEN] Setting the quantity to ship to 1/3 and post ship.
        ServiceLine.Validate("Qty. to Ship", 1 / 3);
        ServiceLine.Modify(true);
        TempServiceLine := ServiceLine;
        TempServiceLine.Insert();
        LibraryService.PostServiceOrderWithPassedLines(ServiceHeader, TempServiceLine, true, false, false);

        // [WHEN] Setting the quantity to ship to 1/3 (remaining 0.66666) and post ship again.
        ServiceLine.Find();
        ServiceLine.Validate("Qty. to Ship", 1 / 3);
        ServiceLine.Modify(true);
        TempServiceLine := ServiceLine;
        TempServiceLine.Modify();
        LibraryService.PostServiceOrderWithPassedLines(ServiceHeader, TempServiceLine, true, false, false);

        // [WHEN] Setting the quantity to consume to 1/3 (remaining is 0.33334).
        ServiceLine.Find();
        asserterror ServiceLine.Validate("Qty. to Consume", 1 / 3);

        // [THEN] Error thrown as quantity to ship is out of balance.
        Assert.ExpectedError(RoundingBalanceErr);
    end;

    [Test]
    procedure BinCodeNotAllowedForNonInventoryItems()
    var
        Item: Record Item;
        NonInventoryItem: Record Item;
        ServiceItem: Record "Service Item";
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO] On service lines, bin code should only be possible to set for inventory items.
        Initialize();

        // [GIVEN] An item, A non-inventory item and a service item.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        // [GIVEN] A location and a bin.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        LibraryWarehouse.CreateBinContent(
            BinContent, Bin."Location Code", '', Bin.Code, Item."No.", '', Item."Base Unit of Measure"
        );

        // [GIVEN] A service order with a service item containing a service line.
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");

        // [WHEN] Setting bin code on inventory item.
        ServiceLine.Validate("No.", Item."No.");
        ServiceLine.Validate("Location Code", Location.Code);
        ServiceLine.Validate("Bin Code", Bin.Code);

        // [THEN] No error is thrown.

        // [WHEN] Setting bin code on non-inventory items.
        ServiceLine.Validate("No.", NonInventoryItem."No.");
        ServiceLine.Validate("Location Code", Location.Code);
        asserterror ServiceLine.Validate("Bin Code", Bin.Code);

        // [THEN] An error is thrown.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemLineWith100PctLineDiscount()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ServiceItemLineNo: Integer;
    begin
        // [SCENARIO 426011] Service order with 100% line discount can be posted
        Initialize();

        // [GIVEN] Customer "C" with "Payment Method Code" = "GIRO"
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Method Code", FindPaymentMethodWithBalanceAccount());
        Customer.Modify();

        // [GIVEN] Service Order for customer "C"
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader, Customer."No.");
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLineNo);
        // [GIVEN] Sales line has 100% line discount
        ServiceLine.Validate("Line Discount %", 100);
        ServiceLine.Modify(true);

        // [WHEN] Post ship and invoice service order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Service order posted
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.SetRange("Document Type", "Gen. Journal Document Type"::Invoice);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField(Amount, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmMessageHandler')]
    procedure RecreateServiceCommentLineForServiceItemLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCommentLine: Record "Service Comment Line";
    begin
        // [FEATURE] [Service Comment Line] [UT]
        // [SCENARIO 433493] The Service Comment Lines related to service item line are not deleted after recreate service lines
        Initialize();

        // [GIVEN] Service Order "SO" with Service Item Line with Service Line "1" for customer "C1"
        CreateServiceOrderWithItem(
          ServiceHeader, LibrarySales.CreateCustomerNo(), '', LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        // [GIVEN] Create service line "2"
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        // [GIVEN] Delete service line "1"
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.FindFirst();
        ServiceLine.Delete(true);

        // [GIVEN] Create comment line for service item line (with type Fault)
        LibraryService.CreateServiceCommentLine(
            ServiceCommentLine, ServiceCommentLine."Table Name"::"Service Header",
            ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", ServiceCommentLine.Type::Fault, 10000);

        // [WHEN] Change "Bill-to Customer No." to "C2" to cuase recreate service lines
        ServiceHeader.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());
        Commit();

        // [THEN] Service comment line is not deleted
        VerifyCountServiceCommentLine(ServiceCommentLine."Table Name"::"Service Header",
            ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", 10000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceQuoteMakeOrderDimensions()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
        DimensionSetID: Integer;
        DimensionValueCode: array[2] of Code[20];
    begin
        // [SCENARIO 438614] Service Quote "Make Order" should Create Service Order with Dimensions copied from initial document
        Initialize();

        // [GIVEN] Service Quote with "Dimension Set ID" = DSI, "Shortcut Dimension 1 Code" = SD1C, "Shortcut Dimension 2 Code" = SD2C
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, Customer."No.");
        GLSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GLSetup."Shortcut Dimension 1 Code");
        DimensionValueCode[1] := DimensionValue.Code;
        ServiceHeader.Validate("Shortcut Dimension 1 Code", DimensionValueCode[1]);
        LibraryDimension.FindDimensionValue(DimensionValue, GLSetup."Shortcut Dimension 2 Code");
        DimensionValueCode[2] := DimensionValue.Code;
        ServiceHeader.Validate("Shortcut Dimension 2 Code", DimensionValueCode[2]);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        DimensionSetID :=
          LibraryDimension.CreateDimSet(ServiceHeader."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code);
        ServiceHeader.Validate("Dimension Set ID", DimensionSetID);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [WHEN] Run Make Order action
        LibraryService.CreateOrderFromQuote(ServiceHeader);

        // [THEN] Service Order created with "Dimension Set ID" = DSI, "Shortcut Dimension 1 Code" = SD1C, "Shortcut Dimension 2 Code" = SD2C
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.SetRange("Customer No.", Customer."No.");
        ServiceHeader.FindFirst();
        ServiceHeader.TestField("Dimension Set ID", DimensionSetID);
        ServiceHeader.TestField("Shortcut Dimension 1 Code", DimensionValueCode[1]);
        ServiceHeader.TestField("Shortcut Dimension 2 Code", DimensionValueCode[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceQuoteMakeOrderPostInvoice()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        Resource: Record Resource;
        ServiceItem: Record "Service Item";
        NoSeries: Record "No. Series";
        Customer: Record Customer;
        NoSeriesUpdated: Boolean;
    begin
        // [SCENARIO 341380] Service Quote "Make Order" should Create Service Order; During the posting process, system will copy Quote No. on posted document
        Initialize();

        // [GIVEN] New customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] New Service Quote with Service Item Line 
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, Customer."No.");
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] New Resource as a Service Line
        LibraryResource.FindResource(Resource);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.");
        UpdateServiceLine(ServiceLine, ServiceItemLine."Line No.", LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Created Service Order from Service Quote
        LibraryService.CreateOrderFromQuote(ServiceHeader);
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.SetRange("Customer No.", Customer."No.");
        ServiceHeader.FindFirst();
        ServiceHeader.TestField("Quote No.");

        //IT layer issue    
        ServiceHeader.TestField("Posting No. Series");
        NoSeries.Get(ServiceHeader."Posting No. Series");
        if not NoSeries."Date Order" then begin
            NoSeriesUpdated := true;
            NoSeries."Date Order" := true;
            NoSeries.Modify();
        end;

        // [WHEN] Post Service Order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Service Invoice and Service Shipment created with Quote No.
        ServiceInvoiceHeader.SetCurrentKey("Order No.");
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindLast();
        ServiceInvoiceHeader.TestField("Quote No.", ServiceHeader."Quote No.");

        ServiceShipmentHeader.SetCurrentKey("Order No.");
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindLast();
        ServiceShipmentHeader.TestField("Quote No.", ServiceHeader."Quote No.");

        if NoSeriesUpdated then begin
            NoSeries.Get(NoSeries.Code);
            NoSeries."Date Order" := false;
            NoSeries.Modify();
        end;
    end;

    [Test]
    procedure NonInventoryItemsWithReqLocation()
    var
        Item: Record Item;
        NonInventoryItem: Record Item;
        ServiceItem: Record "Service Item";
        Location: Record Location;
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO] On service lines, Location can be set or be empty on Non Inventory Items.
        Initialize();

        // [GIVEN] A non-inventory item and a service item.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);

        // [GIVEN] Mandatory location.
        LibraryInventory.SetLocationMandatory(true);

        // [GIVEN] A service order with a service item containing a service line.
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, 1);
        // [WHEN] Setting Location on Non-inventory item.
        ServiceLine.Validate("No.", Item."No.");
        ServiceLine.Validate("Location Code", Location.Code);
        ServiceLine.Modify(true);

        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // [THEN] No error is thrown.
        LibraryService.ReopenServiceDocument(ServiceHeader);

        // [WHEN] Setting Location to non mandatory and Removing Location on non-inventory items.
        LibraryInventory.SetLocationMandatory(false);
        ServiceLine.Validate("No.", NonInventoryItem."No.");
        ServiceLine.Validate("Location Code", '');
        ServiceLine.Modify(true);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // [THEN] No error is thrown.
        LibraryService.ReopenServiceDocument(ServiceHeader);

        // [GIVEN] No Mandatory Location using Location on Non Inventory item

        // [WHEN] Setting Location to non mandatory and Setting Location on non-inventory items.
        LibraryInventory.SetLocationMandatory(false);
        ServiceLine.Validate("No.", NonInventoryItem."No.");
        ServiceLine.Validate("Location Code", Location.Code);
        ServiceLine.Modify(true);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // [THEN] No error is thrown.
        LibraryService.ReopenServiceDocument(ServiceHeader);

    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyInvoiceDiscCodeInCustomerTemplateWhenDelete()
    var
        Customer: Record Customer;
        CustomerTemplate: Record "Customer Templ.";
        CustomerTemplCard: TestPage "Customer Templ. Card";
    begin
        // [SCENARIO 449496] Invoice Disc. Code can be empty without error when trying to delete Invoice Disc. Code from Customer Template
        Initialize();

        // [GIVEN] Create Customer Template.
        LibrarySales.CreateCustomer(Customer);
        LibraryTemplates.CreateCustomerTemplate(CustomerTemplate);
        CustomerTemplate.Validate("Invoice Disc. Code", Customer."Invoice Disc. Code");
        CustomerTemplate.Modify();

        // [WHEN] Open customer template card and delete the Invoice Disc Code
        CustomerTemplCard.OpenEdit();
        CustomerTemplCard.Filter.SetFilter(Code, CustomerTemplate.Code);

        // [THEN] Invoice Disc. Code can be set as empty without error
        CustomerTemplCard."Invoice Disc. Code".SetValue('');
        CustomerTemplCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyUnitCostOnServiceLineFromServiceQuote()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
    begin
        // [SCENARIO 443766] Unit Cost on a Service Quote Service line appears as $0.00 when new Sales Pricing Feature is Enabled
        Initialize();

        // [GIVEN] Create Item and update unit cost to verify same on Service Line
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        Item.Modify();

        // [GIVEN] Create Service quote with Service Item Line.
        CreateServiceQuoteWithServiceItem(ServiceItemLine);
        ServiceHeader.Get(ServiceItemLine."Document Type"::Quote, ServiceItemLine."Document No.");

        // [GIVEN] Create Service Line and validate Item on "No." field.
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");

        // [VERIFY] Verify the Unit cost on Service line will be same as on Item Card.
        Assert.AreEqual(Item."Unit Cost", ServiceLine."Unit Cost", UnitCostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyItemAvailabilityByEventOnServiceLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLineFactBox: TestPage "Service Line FactBox";
        ExpectedAvailabilityQty: Integer;
    begin
        // [SCENARIO 464013] At service lines level, item availability by event is wrong compared to item availability by event at sales lines level.

        // [GIVEN] Create Service Order and update the Posting Date on the Service Item Worksheet.
        Initialize();
        CreateServiceOrderWithUpdatedPostingDate(ServiceHeader, ServiceLine);

        // [THEN] Post Inventory for service item
        PostPositiveAdjustment(ServiceLine."No.", (ServiceLine.Quantity * 4));

        // [GIVEN] Create Sales Order for service item
        CreateSalesOrder(ServiceHeader."Customer No.", ServiceLine."No.", ServiceLine.Quantity);
        ExpectedAvailabilityQty := ServiceLine.Quantity * 2;

        // [THEN] Verify: Quantity availablity from service line item
        ServiceLineFactBox.OpenView();
        ServiceLineFactBox.Filter.SetFilter("Document Type", Format(ServiceLine."Document Type"));
        ServiceLineFactBox.Filter.SetFilter("Document No.", Format(ServiceLine."Document No."));
        ServiceLineFactBox.Filter.SetFilter("Line No.", Format(ServiceLine."Line No."));
        Assert.AreEqual(
            Format(ExpectedAvailabilityQty),
            ServiceLineFactBox."StrSubstNo('%1',ServInfoPaneMgt.CalcAvailability(Rec))".Value,
            StrSubstNo(AvailableExpectedQuantityErr, ExpectedAvailabilityQty));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderValidateShippingServiceAgentUpdateServiceOrderLines()
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgent2: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        ShippingAgentServices2: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
    begin
        // [FEATURE] [Shipping Agent Service]
        Initialize();

        // [GIVEN] Create two Shipping Agent Services with two different Shipping Agents
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);
        LibraryInventory.CreateShippingAgent(ShippingAgent2);
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices2, ShippingAgent2.Code, ShippingTime);

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Shipping Agent Code", ShippingAgent.Code);
        Customer.Validate("Shipping Agent Service Code", ShippingAgentServices.Code);
        Customer.Modify(true);

        // [GIVEN] Create Items
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Service Order with lines
        CreateServiceOrderWithMultipleLines(
          ServiceHeader, Customer."No.", ServiceItem."No.", Item."No.", LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(100, 2));

        // [GIVEN] Set first Shipping Agent Service on Service Order
        ServiceHeader.Validate("Shipping Agent Code", ShippingAgentServices."Shipping Agent Code");
        ServiceHeader.Validate("Shipping Agent Service Code", ShippingAgentServices.Code);

        // [WHEN] Validate second Shipping Agent Service Code on Sales Header when lines have not the same Shipping Agent Code
        // Without validation of Shipping Agent Code to make sure that lines aren't updated
        ServiceHeader."Shipping Agent Code" := ShippingAgentServices2."Shipping Agent Code";
        ServiceHeader.Validate("Shipping Agent Service Code", ShippingAgentServices2.Code);

        // [THEN] Verify new Shipping Agent and Shipping Agent Service Code on the lines
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.TestField("Shipping Agent Code", ShippingAgentServices2."Shipping Agent Code");
            ServiceLine.TestField("Shipping Agent Service Code", ShippingAgentServices2.Code);
        until ServiceLine.Next() = 0;
    end;

    [HandlerFunctions('MessageHandler,ServiceQuoteLinesWithCatalogItem')]
    [Test]
    procedure ServiceQuoteMakeOrderWithAttachedCatalogItem()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        Customer: Record Customer;
        ItemTempl: Record "Item Templ.";
        NonstockItem: Record "Nonstock Item";
        ServiceQuote: TestPage "Service Quote";
    begin
        // [SCENARIO 556739] Service Quote "Make Order" should Create Service Order when Service Line has Catalog Item
        Initialize();

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Nonstock Item having Item Template
        LibraryTemplates.CreateItemTemplateWithData(ItemTempl);
        LibraryInventory.CreateNonStockItemWithItemTemplateCode(NonstockItem, ItemTempl.Code);

        // [GIVEN] Create Service Header
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, Customer."No.");

        // [GIVEN] Create Service Item and Service Item Line
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryVariableStorage.Enqueue(NonstockItem."Item No.");

        // [GIVEN] Open Service Quote Lines page for Service Item Line(Service Quote -> Lines -> Quote -> Service Lines)
        ServiceQuote.OpenEdit();
        ServiceQuote.GotoRecord(ServiceHeader);
        ServiceQuote.ServItemLine.GotoRecord(ServiceItemLine);
        ServiceQuote.ServItemLine.ServiceLines.Invoke();

        // [WHEN] Run Make Order action
        LibraryService.CreateOrderFromQuote(ServiceHeader);

        // [THEN] Verify Service Order created successfully.
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.SetRange("Customer No.", Customer."No.");
        Assert.IsTrue(ServiceHeader.FindFirst(), ServiceOrderErr);
    end;

    [Test]
    procedure AlternativePostingGroupIsNotUsingTheCorrectGLAccountsForPostingInServiceManagement()
    var
        AltCustPostGrp: Record "Alt. Customer Posting Group";
        Customer: Record Customer;
        CustPostGroup: Record "Customer Posting Group";
        FindCustPostGroup: Record "Customer Posting Group";
        GLEntry: Record "G/L Entry";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ServicemanagementSetup: Record "Service Mgt. Setup";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 575185] Alternative Posting Group is not using the correct G/L Accounts for posting in Service Management
        Initialize();

        // Activate "Allow Multiple Posting Groups" true in Sales & Receivables Setup and Service Mgmt Setup
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Allow Multiple Posting Groups" := true;
        SalesReceivablesSetup.Modify();
        ServicemanagementSetup.Get();
        ServicemanagementSetup."Allow Multiple Posting Groups" := true;
        ServicemanagementSetup.Modify();

        // [GIVEN] Create Customer with "Allow Multiple Posting Groups" true.
        LibrarySales.CreateCustomer(Customer);
        Customer."Allow Multiple Posting Groups" := true;
        Customer.Modify();

        // [GIVEN] Create a Customer Posting Group and add Alternate Posting Group
        LibrarySales.CreateCustomerPostingGroup(CustPostGroup);
        AltCustPostGrp.Init();
        AltCustPostGrp."Customer Posting Group" := Customer."Customer Posting Group";
        AltCustPostGrp.Validate("Alt. Customer Posting Group", CustPostGroup.Code);
        AltCustPostGrp.Insert();

        // [GIVEN] Create and Post Service Invoice with Customer Posting Group 
        InvoiceNo := CreateAndPostServiceInvoiceWithCustomerPostingGroup(Customer."No.", CustPostGroup.Code, WorkDate());

        // [THEN] Check GL Entry Created With Service Header Customer Posting Group
        ServiceInvoiceHeader.Get(InvoiceNo);
        FindCustPostGroup.Get(ServiceInvoiceHeader."Customer Posting Group");
        GLEntry.SetRange("Document No.", InvoiceNo);
        GLEntry.SetRange("G/L Account No.", FindCustPostGroup."Receivables Account");
        if GLEntry.FindFirst() then
            Assert.AreEqual(CustPostGroup."Receivables Account", GLEntry."G/L Account No.", '');
    end;

    [Test]
    procedure ValidatingCustomerNoInitializesNewServiceOrder()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service Order] [UT]
        // [SCENARIO 575369] Validating "Customer No." initializes new Service Order.
        Initialize();

        ServiceHeader.Init();
        ServiceHeader.Validate("Customer No.", LibrarySales.CreateCustomerNo());

        ServiceHeader.TestField("Document Date", WorkDate());
        ServiceHeader.TestField("Posting Date", WorkDate());
    end;

    [Test]
    procedure NonBlankDocumentAndPostingDatesOnServiceOrderAreNotReset()
    var
        ServiceHeader: Record "Service Header";
        NewDate: Date;
    begin
        // [FEATURE] [Service Order] [UT]
        // [SCENARIO 575369] Non-blank "Document Date" and "Posting Date" on Service Order are not reset on insert.
        Initialize();
        NewDate := WorkDate() + 1;

        ServiceHeader.Init();
        ServiceHeader.Validate("Customer No.", LibrarySales.CreateCustomerNo());
        ServiceHeader.Validate("Document Date", NewDate);
        ServiceHeader.Validate("Posting Date", NewDate);

        ServiceHeader.Insert(true);

        ServiceHeader.TestField("Document Date", NewDate);
        ServiceHeader.TestField("Posting Date", NewDate);
    end;

    [Test]
    procedure ServiceOrderShippingFieldsBlankWhenNoDefaults()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 540299] Service Order shipping fields are left blank when neither Customer nor Ship-to Address have defaults
        Initialize();

        // [GIVEN] Create Customer without shipping defaults
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Create Service Order without Ship-to Code and no Customer defaults
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");

        // [THEN] Verify shipping fields are blank
        ServiceHeader.TestField("Shipment Method Code", '');
        ServiceHeader.TestField("Shipping Agent Code", '');
        ServiceHeader.TestField("Shipping Agent Service Code", '');
    end;

    [Test]
    procedure ServiceOrderShippingFieldsFromCustomerDefaults()
    var
        Customer: Record Customer;
        ShipmentMethod: Record "Shipment Method";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        ServiceHeader: Record "Service Header";
        ShippingTime: DateFormula;
    begin
        // [SCENARIO 540299] Service Order shipping fields are assigned from Customer defaults when Ship-to Address has no defaults
        Initialize();

        // [GIVEN] Create Shipment Method and Shipping Agent with Service
        CreateShipmentMethod(ShipmentMethod);
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        Evaluate(ShippingTime, '<1W>');
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);

        // [GIVEN] Create Customer with shipping defaults
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Shipment Method Code", ShipmentMethod.Code);
        Customer.Validate("Shipping Agent Code", ShippingAgent.Code);
        Customer.Validate("Shipping Agent Service Code", ShippingAgentServices.Code);
        Customer.Modify(true);

        // [WHEN] Create Service Order without Ship-to Code (uses Customer defaults)
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");

        // [THEN] Verify shipping fields are assigned from Customer defaults
        ServiceHeader.TestField("Shipment Method Code", Customer."Shipment Method Code");
        ServiceHeader.TestField("Shipping Agent Code", Customer."Shipping Agent Code");
        ServiceHeader.TestField("Shipping Agent Service Code", Customer."Shipping Agent Service Code");
    end;

    [Test]
    procedure ServiceOrderShippingFieldsFromShipToAddressDefaults()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        ShipmentMethod: Record "Shipment Method";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        ServiceHeader: Record "Service Header";
        ShippingTime: DateFormula;
    begin
        // [SCENARIO 540299] Service Order shipping fields are assigned from Ship-to Address defaults when defined
        Initialize();

        // [GIVEN] Create Shipment Method and Shipping Agent with Service
        CreateShipmentMethod(ShipmentMethod);
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        Evaluate(ShippingTime, '<1W>');
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);

        // [GIVEN] Create Customer without shipping defaults
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Ship-to Address with shipping defaults
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        ShipToAddress.Validate("Shipment Method Code", ShipmentMethod.Code);
        ShipToAddress.Validate("Shipping Agent Code", ShippingAgent.Code);
        ShipToAddress.Validate("Shipping Agent Service Code", ShippingAgentServices.Code);
        ShipToAddress.Modify(true);

        // [WHEN] Create Service Order with Ship-to Code
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceHeader.Validate("Ship-to Code", ShipToAddress.Code);
        ServiceHeader.Modify(true);

        // [THEN] Verify shipping fields are assigned from Ship-to Address
        ServiceHeader.TestField("Shipment Method Code", ShipToAddress."Shipment Method Code");
        ServiceHeader.TestField("Shipping Agent Code", ShipToAddress."Shipping Agent Code");
        ServiceHeader.TestField("Shipping Agent Service Code", ShipToAddress."Shipping Agent Service Code");
    end;

    [Test]
    procedure ServiceOrderShippingFieldsShipToAddressOverridesCustomer()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        ShipmentMethod: array[2] of Record "Shipment Method";
        ShippingAgent: array[2] of Record "Shipping Agent";
        ShippingAgentServices: array[2] of Record "Shipping Agent Services";
        ServiceHeader: Record "Service Header";
        ShippingTime: DateFormula;
    begin
        // [SCENARIO 540299] Service Order shipping fields from Ship-to Address override Customer defaults when both are defined
        Initialize();

        // [GIVEN] Create two sets of Shipment Methods and Shipping Agents with Services
        CreateShipmentMethod(ShipmentMethod[1]);
        CreateShipmentMethod(ShipmentMethod[2]);
        LibraryInventory.CreateShippingAgent(ShippingAgent[1]);
        LibraryInventory.CreateShippingAgent(ShippingAgent[2]);
        Evaluate(ShippingTime, '<1W>');
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices[1], ShippingAgent[1].Code, ShippingTime);
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices[2], ShippingAgent[2].Code, ShippingTime);

        // [GIVEN] Create Customer with shipping defaults (set 1)
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Shipment Method Code", ShipmentMethod[1].Code);
        Customer.Validate("Shipping Agent Code", ShippingAgent[1].Code);
        Customer.Validate("Shipping Agent Service Code", ShippingAgentServices[1].Code);
        Customer.Modify(true);

        // [GIVEN] Create Ship-to Address with different shipping defaults (set 2)
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        ShipToAddress.Validate("Shipment Method Code", ShipmentMethod[2].Code);
        ShipToAddress.Validate("Shipping Agent Code", ShippingAgent[2].Code);
        ShipToAddress.Validate("Shipping Agent Service Code", ShippingAgentServices[2].Code);
        ShipToAddress.Modify(true);

        // [WHEN] Create Service Order with Ship-to Code
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceHeader.Validate("Ship-to Code", ShipToAddress.Code);
        ServiceHeader.Modify(true);

        // [THEN] Verify shipping fields are assigned from Ship-to Address (set 2), not Customer (set 1)
        ServiceHeader.TestField("Shipment Method Code", ShipToAddress."Shipment Method Code");
        ServiceHeader.TestField("Shipping Agent Code", ShipToAddress."Shipping Agent Code");
        ServiceHeader.TestField("Shipping Agent Service Code", ShipToAddress."Shipping Agent Service Code");

        // [THEN] Verify they are NOT the Customer defaults
        Assert.AreNotEqual(Customer."Shipment Method Code", ServiceHeader."Shipment Method Code", 'Ship-to should override Customer Shipment Method');
        Assert.AreNotEqual(Customer."Shipping Agent Code", ServiceHeader."Shipping Agent Code", 'Ship-to should override Customer Shipping Agent');
        Assert.AreNotEqual(Customer."Shipping Agent Service Code", ServiceHeader."Shipping Agent Service Code", 'Ship-to should override Customer Shipping Agent Service');
    end;

    [Test]
    procedure ServiceOrderShippingFieldsPartialShipToAddressDefaults()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        ShipmentMethod: Record "Shipment Method";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        ServiceHeader: Record "Service Header";
        ShippingTime: DateFormula;
    begin
        // [SCENARIO 540299] Service Order shipping fields use Ship-to defaults where defined, Customer defaults for others
        Initialize();

        // [GIVEN] Create Shipment Methods and Shipping Agent with Service
        CreateShipmentMethod(ShipmentMethod);
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        Evaluate(ShippingTime, '<1W>');
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);

        // [GIVEN] Create Customer with Shipment Method but no Shipping Agent
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Shipment Method Code", ShipmentMethod.Code);
        Customer.Modify(true);

        // [GIVEN] Create Ship-to Address with only Shipping Agent and Service
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        ShipToAddress.Validate("Shipping Agent Code", ShippingAgent.Code);
        ShipToAddress.Validate("Shipping Agent Service Code", ShippingAgentServices.Code);
        ShipToAddress.Modify(true);

        // [WHEN] Create Service Order with Ship-to Code
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceHeader.Validate("Ship-to Code", ShipToAddress.Code);
        ServiceHeader.Modify(true);

        // [THEN] Verify Shipment Method comes from Customer
        ServiceHeader.TestField("Shipment Method Code", Customer."Shipment Method Code");
        // [THEN] Verify Shipping Agent fields come from Ship-to Address
        ServiceHeader.TestField("Shipping Agent Code", ShipToAddress."Shipping Agent Code");
        ServiceHeader.TestField("Shipping Agent Service Code", ShipToAddress."Shipping Agent Service Code");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Orders");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Orders");

        // Create Demonstration Database.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryService.SetupServiceMgtNoSeries();
        LibrarySales.DisableWarningOnCloseUnpostedDoc();
        UpdateCustNoSeries();
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        LibraryTemplates.EnableTemplatesFeature();
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Orders");
    end;

    local procedure CheckWorkDateIsWorkingDate()
    begin
        if Date2DWY(WorkDate(), 1) in [6, 7] then
            WorkDate(WorkDate() + 2);
    end;

    local procedure CreateCustomerWithCountryRegion(var CountryRegion: Record "Country/Region"; var Customer: Record Customer)
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Modify(true);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandlerTRUE')]
    procedure ShippingInvoicingServiceOrderWithPostingPolicy()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        InstructionMgt: Codeunit "Instruction Mgt.";
        ShipInvoiceConfirmQst: Label 'Do you want to post the shipment and invoice?';
    begin
        // [FEATURE] [Posting Selection] [Order]
        // [SCENARIO 480943] Shipping and invoicing service order with "Prohibited" and "Mandatory" settings of invoice posting policy.
        Initialize();

        // [GIVEN] new Customer 
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] new Service Item
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        // [GIVEN] new Service Order with Service Item Line
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLineToShipAndInvoice(ServiceLine, ServiceHeader, ServiceItem."No.");
        ServiceHeader.SetRange("No.", ServiceHeader."No.");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");

        // [GIVEN] user allowed just to ship
        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Prohibited);

        // [GIVEN] posting shipment 
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.ShowPostedConfirmationMessageCode());
        LibraryVariableStorage.Enqueue(1); //ship
        OpenServiceOrderPageAndPost(ServiceHeader, true);

        // [GIVEN] user allowed just to ship and invoice
        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Mandatory);

        // [WHEN] posting shipment and invoice
        LibraryVariableStorage.Enqueue(ShipInvoiceConfirmQst);
        OpenServiceOrderPageAndPost(ServiceHeader, false);

        // [THEN] All Service Line posted
        Assert.IsFalse(ServiceLine.Find(), '');

        LibraryVariableStorage.AssertEmpty();

        InstructionMgt.EnableMessageForCurrentUser(InstructionMgt.ShowPostedConfirmationMessageCode());
        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Allowed);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    procedure ShippingInvoicingServiceOrderWithPostingPolicyMandatory()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        InstructionMgt: Codeunit "Instruction Mgt.";
        ShipInvoiceConfirmQst: Label 'Do you want to post the shipment and invoice?';
    begin
        // [FEATURE] [Posting Selection] [Order]
        // [SCENARIO 480943] Shipping and invoicing service order with "Prohibited" and "Mandatory" settings of invoice posting policy.
        Initialize();

        // [GIVEN] new Customer 
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] new Service Item
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        // [GIVEN] new Service Order with Service Item Line
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLineToShipAndInvoice(ServiceLine, ServiceHeader, ServiceItem."No.");
        ServiceHeader.SetRange("No.", ServiceHeader."No.");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");

        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.ShowPostedConfirmationMessageCode());
        // [GIVEN] user allowed just to ship and invoice
        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Mandatory);

        // [WHEN] posting shipment and invoice
        LibraryVariableStorage.Enqueue(ShipInvoiceConfirmQst);
        OpenServiceOrderPageAndPost(ServiceHeader, false);

        // [THEN] All Service Line posted
        Assert.IsFalse(ServiceLine.Find(), '');
        LibraryVariableStorage.AssertEmpty();

        InstructionMgt.EnableMessageForCurrentUser(InstructionMgt.ShowPostedConfirmationMessageCode());
        CreateUserSetupWithPostingPolicy("Invoice Posting Policy"::Allowed);
    end;

    [Test]
    procedure ReleasingOfServiceOrderHavingServiceLineWithoutUOMGivesError()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO 522444] When run Release action from a Service Order having a Service Line without 
        // Unit of Measure Code, then it gives error and the document is not released.
        Initialize();

        // [GIVEN] Craete a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create a Service Item.
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");

        // [GIVEN] Craete a Service Order with Service Item Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Create a Service Line.
        CreateServiceLineToShipAndInvoice(ServiceLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Find Service Header and Service Line.
        ServiceHeader.SetRange("No.", ServiceHeader."No.");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");

        // [WHEN] Validate Unit of Measure Code in Service Line.
        ServiceLine.Validate("Unit of Measure Code", '');
        ServiceLine.Modify(true);

        // [THEN] Error is shown and the Service Order is not released.
        asserterror LibraryService.ReleaseServiceDocument(ServiceHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    procedure VATCountryRegionCodeHasValueWhenBilltoSelltoVATCalcIsSelltoBuyfromNo()
    var
        CountryRegion: array[2] of Record "Country/Region";
        Customer: array[2] of Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 560573] "VAT Country/Region Code" is populated when Bill-to/Sell-to VAT Calc. field on the General Ledger Setup
        // is set to Sell-to/Buy-from No.
        Initialize();

        // [GIVEN] Set GeneralLedgerSetup "Bill-to/Sell-to VAT Calc." to "Sell-to/Buy-from No.";
        LibraryERM.SetBillToSellToVATCalc(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");

        // [GIVEN] Create two Customers with different Country/Region codes.
        CreateCustomerWithCountryRegion(CountryRegion[1], Customer[1]);
        CreateCustomerWithCountryRegion(CountryRegion[2], Customer[2]);

        // [GIVEN] Create a Service Order for the first Customer.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer[1]."No.");

        // [GIVEN] "VAT Country/Region Code" on a Service Header is equals to first Customer Country/Region code.
        Assert.AreEqual(Customer[1]."Country/Region Code", ServiceHeader."VAT Country/Region Code", VATCountryRegionLbl);

        // [WHEN] Change to second Customer No.
        ServiceHeader.Validate("Customer No.", Customer[2]."No.");
        ServiceHeader.Modify(true);

        // [THEN] "VAT Country/Region Code" on a Service Header is equals to second Customer Country/Region code.
        Assert.AreEqual(Customer[2]."Country/Region Code", ServiceHeader."VAT Country/Region Code", VATCountryRegionLbl);
    end;

    [Test]
    [HandlerFunctions('ServiceOrderReportRequestPageHandler')]
    procedure PrintServiceOrderWithWorkDescription()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceOrder: TestPage "Service Order";
    begin
        // [SCENARIO 575369] Verify Printing Service Order with Work Description does not throw error.
        Initialize();

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Service Order with Work Description
        LibraryService.CreateServiceItem(ServiceItem, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");

        // [WHEN] Open Service Order Card and click Print
        CreateCustomReportSelectionForCustomer(ServiceHeader."Customer No.", "Report Selection Usage"::"SM.Order", 5900);
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        ServiceOrder.WorkDescription.SetValue(LibraryRandom.RandText(20));
        ServiceOrder."&Print".Invoke();

        // [THEN] Verify no transaction error should occur.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceStatisticsShouldZeroWIth100PctLineDiscount()
    var
        Customer: Record Customer;
        Resource: Record Resource;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoice: TestPage "Service Invoice";
        ServiceStatistics: TestPage "Service Statistics";
    begin
        // [SCENARIO 575012] Negative invoice amount when posting a service invoice with 100% line discount
        Initialize();

        // [GIVEN] Create new customer and resource
        LibrarySales.CreateCustomer(Customer);
        LibraryResource.CreateResourceNew(Resource);

        // [GIVEN] Create Service Header with Document Type = Invoice
        CreateServiceDocumentWithResourceWith100PctDisc(
            ServiceHeader, ServiceLine, ServiceHeader."Document Type"::Invoice, Customer."No.",
            Resource."No.", LibraryRandom.RandIntInRange(1, 1), LibraryRandom.RandDecInDecimalRange(0.01, 0.01, 2));

        // [WHEN] Invoke Service Invoice Statistics page and Goto Record
        ServiceInvoice.OpenEdit();
        ServiceInvoice.GotoRecord(ServiceHeader);
        ServiceStatistics.Trap();
        ServiceInvoice.ServiceStatistics.Invoke();

        // [THEN] Service Invoice Statistics Lines Sub form tab where "Line Amount" and "Amount Including VAT" = 0.00
        ServiceStatistics.SubForm."Line Amount".AssertEquals(0);
        ServiceStatistics.SubForm."Amount Including VAT".AssertEquals(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoUpdateServiceHeaderStatusOnServiceItemLineAdd()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        Customer: Record Customer;
        ServiceOrderPage: TestPage "Service Order";
        InitialStatus: Enum "Service Document Status";
        FinalStatus: Enum "Service Document Status";
    begin
        // [SCENARIO 582114] Test that Service Header Status changes automatically when adding Service Item to Finished Service Order

        // [GIVEN] Initialize and create test data
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");

        // [GIVEN] Create a Service Order and set status to Finished
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceHeader.Validate(Status, ServiceHeader.Status::Finished);
        ServiceHeader.Modify(true);
        InitialStatus := ServiceHeader.Status;

        // [WHEN] Open Service Order page and add Service Item Line (simulating user action)
        ServiceOrderPage.OpenEdit();
        ServiceOrderPage.Filter.SetFilter("No.", ServiceHeader."No.");

        // [THEN] Verify initial status is Finished
        ServiceOrderPage.Status.AssertEquals(ServiceHeader.Status::Finished);

        // [GIVEN] Add Service Item to the Service Item Lines subform
        ServiceOrderPage.ServItemLines.New();
        ServiceOrderPage.ServItemLines.ServiceItemNo.SetValue(ServiceItem."No.");
        ServiceOrderPage.ServItemLines.Next(); // Move focus to trigger validation

        // [THEN] Verify that Service Header Status has changed automatically
        ServiceOrderPage.Status.AssertEquals(ServiceHeader.Status::Pending); // Expected new status based on repair status priority

        // [THEN] Verify the change was logged in Service Document Log
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        FinalStatus := ServiceHeader.Status;

        // [THEN] Verify status actually changed
        Assert.AreNotEqual(InitialStatus, FinalStatus, ServiceOrderStatusShouldChangedErr);
        ServiceOrderPage.Close();
    end;

    local procedure CreateServiceDocumentWithResourceWith100PctDisc(
       var ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type";
       CustomerNo: Code[20]; ResourceNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Unit Price", UnitPrice);
        ServiceLine.Validate("Line Discount %", 100);
        ServiceLine.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(StrPos(Question, ExpectedMessage) > 0, Question);
        Reply := true;
    end;

    local procedure CreateUserSetupWithPostingPolicy(InvoicePostingPolicy: Enum "Invoice Posting Policy")
    var
        UserSetup: Record "User Setup";
    begin
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Service Invoice Posting Policy", InvoicePostingPolicy);
        UserSetup.Modify(true);
    end;

    local procedure OpenServiceOrderPageAndPost(var ServiceHeader: Record "Service Header"; ClosePage: Boolean)
    var
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        ServiceOrder.Post.Invoke();
        if ClosePage then
            ServiceOrder.Close();
    end;

    [Scope('OnPrem')]
    procedure ClearConfigTemplateEntry(ItemTemplateCode: Code[10]; FieldNo: Integer)
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateLine.SetRange("Data Template Code", ItemTemplateCode);
        ConfigTemplateLine.SetRange("Table ID", DATABASE::Item);
        ConfigTemplateLine.SetRange("Field ID", FieldNo);
        ConfigTemplateLine.FindFirst();
        ConfigTemplateLine."Default Value" := '';
        ConfigTemplateLine.Modify();
    end;

    local procedure InitServiceContractWithOrderScenario(var ServiceHeader: Record "Service Header"; var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        CreateServiceContract(ServiceContractHeader, ServiceContractLine, ServiceContractHeader."Contract Type"::Contract);
        ModifyServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceContractHeader."Customer No.");
        UpdateContractOnServiceHeader(ServiceHeader, ServiceContractHeader."Contract No.");
    end;

    local procedure InitServDocWithInvRoundingPrecisionScenario(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    var
        Customer: Record Customer;
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.SetInvRoundingPrecisionLCY(
          LibraryRandom.RandInt(5) + LibraryUtility.GenerateRandomFraction());
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        CreateServiceDocument(ServiceHeader, DocumentType, Customer."No.", Item."No.",
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandDecInRange(1000, 2000, 2));
    end;

    local procedure UpdateAutomaticCostPosting(NewValue: Boolean) Result: Boolean
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        Result := InventorySetup."Automatic Cost Posting";
        if Result = NewValue then
            exit;
        InventorySetup.Validate("Automatic Cost Posting", NewValue);
        InventorySetup.Modify(true);
    end;

    local procedure AllocateResource(var Resource: Record Resource; ServiceItemLine: Record "Service Item Line")
    var
        ServiceOrderSubform: Page "Service Order Subform";
    begin
        LibraryResource.FindResource(Resource);
        LibraryVariableStorage.Enqueue(Resource."No.");
        Clear(ServiceOrderSubform);
        ServiceOrderSubform.SetRecord(ServiceItemLine);
        ServiceOrderSubform.AllocateResource();
    end;

    local procedure AssignLoanerOnServiceItemLine(var ServiceItemLine: Record "Service Item Line")
    var
        Loaner: Record Loaner;
        RecordRef: RecordRef;
    begin
        Loaner.Init();
        RecordRef.GetTable(Loaner);
        LibraryUtility.FindRecord(RecordRef);
        RecordRef.SetTable(Loaner);
        ServiceItemLine.Validate("Loaner No.", Loaner."No.");
        ServiceItemLine.Modify(true);
    end;

    local procedure CalculateVATForMultipleServiceLines(ServiceHeader: Record "Service Header"; VATPct: Decimal): Decimal
    var
        ServiceLine: Record "Service Line";
        TotalAmount: Decimal;
    begin
        GetServiceLine(ServiceLine, ServiceHeader);
        repeat
            TotalAmount += ServiceLine."Unit Price" * ServiceLine.Quantity;
        until ServiceLine.Next() = 0;
        exit(Round(TotalAmount * VATPct / 100));
    end;

    local procedure CheckServiceLineInsertion(InsertBeforeAfterLineNo: Integer; IsInsertAfter: Boolean; InsertAdditionalServiceLine: Boolean; CheckLineNoValue: Integer)
    var
        ServiceHeader: Record "Service Header";
        ServiceLineBeforeAfterInsert: Record "Service Line";
    begin
        Initialize();
        CreateServiceOrderWithServiceItemLineAndServiceLines(ServiceHeader, InsertAdditionalServiceLine);
        FindServiceLineByOrder(ServiceHeader, InsertBeforeAfterLineNo, ServiceLineBeforeAfterInsert);

        VerifyServiceLineInsertLineNo(
          ServiceHeader."Document Type", ServiceHeader."No.",
          ServiceLineBeforeAfterInsert, IsInsertAfter, CheckLineNoValue);
    end;

    local procedure CreateBinAndBinContent(var Bin: Record Bin; Item: Record Item)
    var
        BinContent: Record "Bin Content";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateBin(Bin, CreateLocationWithBinMandatory(), LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Bin."Location Code", '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
    end;

    local procedure CreateLocationWithBinMandatory(): Code[10]
    var
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreateAndModifyCustomer(var Customer: Record Customer; ApplicationMethod: Enum "Application Method"; PaymentMethodCode: Code[10]; ApplyRoundingPrecision: Decimal)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Method Code", PaymentMethodCode);
        Customer.Validate("Application Method", ApplicationMethod);
        Customer.Validate("Currency Code", CreateCurrency(ApplyRoundingPrecision));
        Customer.Modify(true);
    end;

    local procedure CreateAndPostSalesOrder(No: Code[20])
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, No);

        // Use random value for Quantity.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostServiceOrder(ServiceItem: Record "Service Item") DocumentNo: Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        DocumentNo := ServiceHeader."No.";
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItem."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);
    end;

    local procedure CreateAndShipServiceOrderWithPostingDate(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; PostingDate: Date)
    begin
        CreateServiceOrderWithItem(ServiceHeader, CustomerNo, '', LibraryInventory.CreateItemNo(), 1);
        ServiceHeader.Validate("Posting Date", PostingDate);
        ServiceHeader.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
    end;

    local procedure CreateAndUpdateServiceHeader(var ServiceHeader: Record "Service Header"; VATBusPostingGroup: Code[20])
    begin
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomerWithVATBusPostingGroup(VATBusPostingGroup));
        ServiceHeader.Validate("Prices Including VAT", true);
        ServiceHeader.Modify(true);
    end;

    local procedure CreateAndPostServiceInvoice(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceHeader: Record "Service Header";
        ServContractManagement: Codeunit ServContractManagement;
    begin
        ServContractManagement.InitCodeUnit();
        ServContractManagement.CreateInvoice(ServiceContractHeader);
        ServContractManagement.FinishCodeunit();

        ServiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceHeader.FindFirst();
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure CreateAndUpdateServiceLine(ServiceHeader: Record "Service Header"; Type: Enum "Service Line Type"; No: Code[20]; Quantity: Decimal; ServiceItemLineNo: Integer; LineDiscount: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);

        // Use Random because value is not important in case where Type is not blank.
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        ServiceLine.Validate("Line Discount %", LineDiscount);
        ServiceLine.Modify(true);
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(100));  // Using RANDOM value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateCurrency(ApplnRoundingPrecision: Decimal): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Appln. Rounding Precision", ApplnRoundingPrecision);
        Currency.Modify(true);

        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateLoaner(): Code[20]
    var
        Loaner: Record Loaner;
    begin
        LibraryService.CreateLoaner(Loaner);
        exit(Loaner."No.");
    end;

    local procedure CreateDescriptionServiceLine(var ServiceHeader: Record "Service Header"; Type: Enum "Service Line Type"; No: Code[20]; ServiceItemLineNo: Integer)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Description, Format(ServiceHeader."Document Type") + Format(ServiceHeader."No."));
        ServiceLine.Modify(true);
    end;

    local procedure CreateCustomerInvoiceDiscount(CustomerNo: Code[20]; DiscountPct: Decimal; ServiceCharge: Decimal)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);  // Take Blank for Currency Code And 0 for Minimum Amount.
        CustInvoiceDisc.Validate("Discount %", DiscountPct);
        CustInvoiceDisc.Validate("Service Charge", ServiceCharge);
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreateCustomerWithLocationCode(var Customer: Record Customer; var Location: Record Location)
    var
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateLocation(Location);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Location Code", Location.Code);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithResponsibilityCenter(var Customer: Record Customer)
    var
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        LibrarySales.CreateCustomer(Customer);
        ResponsibilityCenter.FindFirst();
        Customer.Validate("Responsibility Center", ResponsibilityCenter.Code);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerTemplate()
    var
        Customer: Record Customer;
        CustomerTemplate: Record "Customer Templ.";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryTemplates.CreateCustomerTemplate(CustomerTemplate);
        CustomerTemplate.Validate("Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
        CustomerTemplate.Validate("Customer Posting Group", Customer."Customer Posting Group");
        CustomerTemplate.Modify(true);
    end;

    local procedure CreateCustomerWithVATBusPostingGroup(VATBusinessPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithZoneCode(ServiceZoneCode: Code[10]; VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomerWithVATBusPostingGroup(VATBusPostingGroupCode));
        Customer.Validate("Service Zone Code", ServiceZoneCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithVATBusPostGroup(var Customer: Record Customer)
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup.Code);
        Customer.Modify(true);
    end;

    local procedure CreateExtendedTextForItem(ItemNo: Code[20]): Text[50]
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, ItemNo);
        ExtendedTextHeader.Validate("Starting Date", WorkDate());
        ExtendedTextHeader.Validate("All Language Codes", true);
        ExtendedTextHeader.Modify(true);

        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, LibraryUtility.GenerateRandomCode(ExtendedTextLine.FieldNo(Text), DATABASE::"Extended Text Line"));
        ExtendedTextLine.Modify(true);
        exit(ExtendedTextLine.Text);
    end;

    local procedure CreateItemWithReplenishmentSystem(ReplenishmentSystem: Enum "Replenishment System"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateMultipleServiceLine(var ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer)
    var
        Item: Record Item;
        Resource: Record Resource;
        ServiceLine: Record "Service Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryResource.FindResource(Resource);

        // Create Service Line with type as Item, use random for Quantity.
        CreateAndUpdateServiceLine(
          ServiceHeader, ServiceLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2), ServiceItemLineNo, 0);  // Take zero for Line Discount.

        // Create Service Line with type as Resource, use random for Quantity.
        CreateAndUpdateServiceLine(
          ServiceHeader, ServiceLine.Type::Resource, Resource."No.", LibraryRandom.RandDec(100, 2),
          ServiceItemLineNo, 0);  // Take zero for Line Discount.

        // Create Service Line with type as Blank.
        CreateDescriptionServiceLine(ServiceHeader, ServiceLine.Type::" ", '', ServiceItemLineNo);
    end;

    local procedure CreateOrderWithContract(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceContractHeader."Customer No.");
        UpdateContractOnServiceHeader(ServiceHeader, ServiceContractHeader."Contract No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLine."Line No.");
    end;

    local procedure CreateRepairStatusCodeFinish(var RepairStatus: Record "Repair Status")
    begin
        RepairStatus.SetRange(Finished, true);
        if not RepairStatus.FindFirst() then begin
            LibraryService.CreateRepairStatus(RepairStatus);
            RepairStatus.Validate(Finished, true);
            RepairStatus.Modify(true);
        end;
    end;

    local procedure CreateServiceContract(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line"; ContractType: Enum "Service Contract Type")
    begin
        // Create Service Item, Service Contract Header, Service Contract Line.
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ContractType, '');
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
    end;

    local procedure CreateServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header"; InvoicePeriod: Enum "Service Contract Header Invoice Period")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        ServiceContractHeader.Validate("Invoice Period", InvoicePeriod);
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceContractLine(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Cost", LibraryRandom.RandInt(10));  // Use Random because value is not important.
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandInt(10));  // Use Random because value is not important.
        ServiceContractLine.Modify(true);
    end;

    local procedure CreateServiceContractLineWithPriceUpdatePeriod(ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line")
    var
        ServiceItem: Record "Service Item";
        PriceUpdatePeriod: DateFormula;
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        Evaluate(PriceUpdatePeriod, StrSubstNo('<%1M>', LibraryRandom.RandInt(11)));
        ServiceContractLine.Validate("Line Value", 12 * LibraryRandom.RandDecInRange(50, 100, 2));
        ServiceContractLine.Validate("Next Planned Service Date", WorkDate());
        ServiceContractLine.Validate("Starting Date", WorkDate());
        ServiceContractLine.Validate("Service Period", PriceUpdatePeriod);
        ServiceContractLine.Modify(true);
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Unit Price", UnitPrice);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceDocumentWithServiceItem(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20])
    var
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    var
        Item: Record Item;
        Quantity: Decimal;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        Quantity := LibraryRandom.RandInt(10);  // Use Random For Quantity and Quantity to Consume.
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Qty. to Consume", Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineToShipAndInvoice(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    var
        Item: Record Item;
        Quantity: Decimal;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        Quantity := LibraryRandom.RandInt(10);  // Use Random For Quantity and Quantity to Consume.
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineWithLineNoSet(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemLine: Record "Service Item Line"; LineNo: Integer)
    begin
        Clear(ServiceLine);
        ServiceLine.Init();
        ServiceLine.Validate("Document Type", ServiceHeader."Document Type");
        ServiceLine.Validate("Document No.", ServiceHeader."No.");
        ServiceLine.Validate("Line No.", LineNo);
        ServiceLine.Validate("Service Item No.", ServiceItemLine."Service Item No.");
        ServiceLine.Insert(true);
    end;

    local procedure CreateServiceLineDimSet(var ServiceLine: Record "Service Line")
    var
        DimensionValue: Record "Dimension Value";
        DimensionSetID: Integer;
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        DimensionSetID :=
          LibraryDimension.CreateDimSet(ServiceLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code);
        ServiceLine.Validate("Dimension Set ID", DimensionSetID);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceItem(var ServiceItem: Record "Service Item"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Item No.", ItemNo);
        ServiceItem.Modify(true);
    end;

    local procedure CreateServiceItemLine(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header")
    var
        Item: Record Item;
    begin
        // Create Service Order - Service Header and Service Item Line with Item.
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate("Item No.", Item."No.");
        ServiceItemLine.Validate(Description, Item."No.");
        ServiceItemLine.Modify(true);
    end;

    local procedure CreateServiceItemLineWithServiceItemNo(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    begin
        CreateServiceItemLine(ServiceItemLine, ServiceHeader);
        ServiceItemLine.Validate("Service Item No.", ServiceItemNo);
        ServiceItemLine.Modify(true);
    end;

    local procedure CreateServiceItemLineWithServiceItem(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header")
    var
        ServiceItem: Record "Service Item";
    begin
        CreateServiceItem(ServiceItem, ServiceHeader."Customer No.", LibraryInventory.CreateItemNo());
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure CreateItemLineResolution(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    var
        ResolutionCode: Record "Resolution Code";
    begin
        LibraryService.FindResolutionCode(ResolutionCode);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);
        ServiceItemLine.Validate("Resolution Code", ResolutionCode.Code);
        ServiceItemLine.Modify(true);
    end;

    local procedure CreateServiceItemWithGroup(var ServiceItem: Record "Service Item"; CustomerNo: Code[20])
    var
        ServiceItemGroup: Record "Service Item Group";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryService.FindServiceItemGroup(ServiceItemGroup);
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Item No.", Item."No.");
        ServiceItem.Validate("Service Item Group Code", ServiceItemGroup.Code);
        ServiceItem.Modify(true);
    end;

    local procedure CreateServiceItemWithZone(var ServiceItem: Record "Service Item")
    var
        ServiceZone: Record "Service Zone";
        ServiceCost: Record "Service Cost";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetup(VATPostingSetup);
        LibraryService.CreateServiceZone(ServiceZone);
        CreateServiceCost(ServiceCost, ServiceZone.Code, VATPostingSetup."VAT Prod. Posting Group");
        LibraryService.CreateServiceItem(
          ServiceItem, CreateCustomerWithZoneCode(ServiceZone.Code, VATPostingSetup."VAT Bus. Posting Group"));
    end;

    local procedure CreateServiceItemLineRepair(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    var
        RepairStatus: Record "Repair Status";
    begin
        LibraryService.CreateRepairStatus(RepairStatus);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);
        ServiceItemLine.Validate("Repair Status Code", RepairStatus.Code);
        ServiceItemLine.Modify(true);
    end;

    local procedure CreateServiceItemFromDocument(ServiceItemLine: Record "Service Item Line")
    var
        ServiceOrderSubform: Page "Service Order Subform";
    begin
        ServiceOrderSubform.SetRecord(ServiceItemLine);
        ServiceOrderSubform.CreateServiceItem();
    end;

    local procedure CreateServiceHeaderWithName(var ServiceHeader: Record "Service Header")
    var
        PostCode: Record "Post Code";
    begin
        ServiceHeader.Init();
        ServiceHeader.Validate("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.Insert(true);

        FindPostCode(PostCode);
        ServiceHeader.Validate(Name, Format(ServiceHeader."Document Type") + ServiceHeader."No.");
        ServiceHeader.Validate(Address, Format(ServiceHeader."Document Type") + ServiceHeader."No." + PostCode.City);
        ServiceHeader.Validate("Post Code", PostCode.Code);
        ServiceHeader.Validate(City, PostCode.City);
        ServiceHeader.Modify(true);
    end;

    local procedure CreateServItemLineDescription(var ServiceItemLine: Record "Service Item Line")
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
    begin
        // Create Service Order - Service Header and Service Item Line with description.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate(
          Description, Format(ServiceItemLine."Document Type") + ServiceItemLine."Document No." + Format(ServiceItemLine."Line No."));
        ServiceItemLine.Modify(true);
    end;

    local procedure CreateServiceCost(var ServiceCost: Record "Service Cost"; ServiceZoneCode: Code[10]; VATProdPostingGroupCode: Code[20])
    var
        GLAccount: Record "G/L Account";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProdPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup.Code);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        GLAccount.Modify(true);
        LibraryService.CreateServiceCost(ServiceCost);
        ServiceCost.Validate("Cost Type", ServiceCost."Cost Type"::Travel);
        ServiceCost.Validate("Account No.", GLAccount."No.");
        ServiceCost.Validate("Service Zone Code", ServiceZoneCode);
        ServiceCost.Validate("Default Quantity", LibraryRandom.RandDecInRange(10, 100, 2));
        ServiceCost.Modify(true);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]): Integer
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        exit(ServiceItemLine."Line No.");
    end;

    local procedure CreateServiceQuote(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]): Integer
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        exit(ServiceItemLine."Line No.");
    end;

    local procedure CreateServiceHeaderRespCenter(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20])
    var
        Item: Record Item;
        ResponsibilityCenter: Record "Responsibility Center";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Create Service Header with Responsibility Center, Create Service Item Line and Service Line.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        ResponsibilityCenter.FindFirst();
        ServiceHeader.Validate("Responsibility Center", ResponsibilityCenter.Code);
        ServiceHeader.Modify(true);

        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryInventory.CreateItem(Item);

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLine."Line No.");
    end;

    local procedure CreateServiceOrderWithWarranty(var ServiceHeader: Record "Service Header"; ServiceItem: Record "Service Item")
    var
        ServiceItemLine: Record "Service Item Line";
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item No.", ServiceItemLine."Service Item No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrderWithServiceItemLineAndServiceLines(var ServiceHeader: Record "Service Header"; AdditionalLine: Boolean)
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        CreateServiceOrderWithItem(ServiceHeader, Customer."No.", '', Item."No.", 1);
        if AdditionalLine then begin
            LibraryService.CreateServiceLine(
              ServiceLine, ServiceHeader,
              ServiceLine.Type::Item, Item."No.");
            UpdateServiceLineWithRandomQtyAndPrice(
              ServiceLine,
              FindLastServiceItemLineNo(ServiceHeader."Document Type"::Order, ServiceHeader."No."));
        end;
    end;

    local procedure CreateServiceQuoteWithComments(var ServiceItemLine: Record "Service Item Line")
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
    begin
        // Create Service Item, Service Header with Document Type Quote, Service Item Line, Assign Loaner No. on Service Item Line,
        // Create Service Line with Type Item and Create Commnet on Service Quote.
        Initialize();
        LibrarySales.SetStockoutWarning(false);
        CreateServiceDocWithLoaner(ServiceHeader, ServiceItemLine, ServiceHeader."Document Type"::Quote);
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLine."Line No.");
        CreateCommentsOnServiceQuote(ServiceItemLine);
    end;

    local procedure CreateServiceOrderWithServiceItem(var ServiceItemLine: Record "Service Item Line")
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure CreateServiceOrderWithItem(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        ServiceHeader.Validate("Location Code", LocationCode);
        ServiceHeader.Modify(true);

        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        UpdateServiceLine(
          ServiceLine, ServiceItemLine."Line No.", Quantity, LibraryRandom.RandDecInRange(1000, 2000, 2));
    end;

    local procedure CreateServiceInvoiceSimple(var ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        CreateServiceInvoiceWithServiceLine(ServiceHeader, ServiceLine, LibrarySales.CreateCustomerNo());
    end;

    local procedure CreateServiceInvoiceWithServiceLine(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; CustomerNo: Code[20])
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
    end;

    local procedure CreateServiceInvoiceWithUniqueDescriptionLines(var ServiceHeader: record "Service Header"; var TempServiceLine: Record "Service Line" temporary; Type: Enum "Service Line Type")
    var
        ServiceLine: Record "Service Line";
        i: Integer;
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        for i := 1 to LibraryRandom.RandIntInRange(3, 7) do begin
            case Type of
                ServiceLine.Type::"G/L Account":
                    LibraryService.CreateServiceLine(
                      ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
                ServiceLine.Type::Item:
                    LibraryService.CreateServiceLine(
                      ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
            end;
            ServiceLine.Description :=
              COPYSTR(
                LibraryUtility.GenerateRandomAlphabeticText(MAXSTRLEN(ServiceLine.Description), 1),
                1,
                MAXSTRLEN(ServiceLine.Description));
            ServiceLine.VALIDATE(Quantity, LibraryRandom.RandInt(100));
            ServiceLine.VALIDATE("Unit Price", LibraryRandom.RandDec(10, 2));
            ServiceLine.Modify();
            TempServiceLine := ServiceLine;
            TempServiceLine.Insert();
        end;
    end;

    local procedure CreateServiceDocumentWithLocation(var ServiceLine: Record "Service Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, '');
        ServiceHeader.Validate("Location Code", LocationCode);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceDocWithCrLimitCustomer(var ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; DocType: Enum "Service Document Type")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CustNo: Code[20];
        CreditLimit: Decimal;
    begin
        LibrarySales.SetCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"Credit Limit");
        CreditLimit := LibraryRandom.RandDec(10, 2);
        CustNo := LibrarySales.CreateCustomerNo();
        UpdateCustomerCreditLimit(CustNo, CreditLimit);
        CreateServiceDocWithIncreasedAmount(ServHeader, ServLine, DocType, CustNo, CreditLimit);
        LibraryVariableStorage.Enqueue(CustNo);
    end;

    local procedure CreateServiceDocWithIncreasedAmount(var ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; DocType: Enum "Service Document Type"; CustNo: Code[20]; Amount: Decimal)
    begin
        LibraryService.CreateServiceHeader(ServHeader, DocType, CustNo);
        LibraryService.CreateServiceLine(ServLine, ServHeader, ServLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        ServLine.Validate(Quantity, 1);
        ServLine.Validate("Unit Price", Amount + LibraryRandom.RandDec(100, 2));
        ServLine.Modify(true);
    end;

    local procedure CreateStandardTextWithExtendedText(): Code[20]
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        StandardText: Record "Standard Text";
    begin
        StandardText.Init();
        StandardText.Code := LibraryUtility.GenerateRandomCode(StandardText.FieldNo(Code), DATABASE::"Standard Text");
        StandardText.Insert(true);
        LibrarySmallBusiness.CreateExtendedTextHeader(ExtendedTextHeader, "Extended Text Table Name"::"Standard Text", StandardText.Code);
        LibrarySmallBusiness.CreateExtendedTextLine(ExtendedTextLine, ExtendedTextHeader);
        exit(StandardText.Code);
    end;

    local procedure ChangeCustomerOnServiceQuote(var ServiceHeader: Record "Service Header")
    begin
        // Select different Customer from Service Header Customer No.
        ServiceHeader.Validate("Customer No.", LibrarySales.CreateCustomerNo());
        ServiceHeader.Modify(true);
    end;

    local procedure CreateCommentsOnServiceQuote(ServiceItemLine: Record "Service Item Line")
    var
        ServiceCommentLine: Record "Service Comment Line";
    begin
        LibraryService.CreateCommentLineForServHeader(ServiceCommentLine, ServiceItemLine, ServiceCommentLine.Type::Fault);
        LibraryService.CreateCommentLineForServHeader(ServiceCommentLine, ServiceItemLine, ServiceCommentLine.Type::Resolution);
        LibraryService.CreateCommentLineForServHeader(ServiceCommentLine, ServiceItemLine, ServiceCommentLine.Type::Accessory);
        LibraryService.CreateCommentLineForServHeader(ServiceCommentLine, ServiceItemLine, ServiceCommentLine.Type::Internal);
        LibraryService.CreateCommentLineForServHeader(ServiceCommentLine, ServiceItemLine, ServiceCommentLine.Type::"Service Item Loaner");
    end;

    local procedure CreateResponsibilityCenterAndUserSetup(): Code[10]
    var
        Location: Record Location;
        UserSetup: Record "User Setup";
        ResponsibilityCenter: Record "Responsibility Center";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter);
        ResponsibilityCenter.Validate("Location Code", LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location));
        ResponsibilityCenter.Modify(true);
        UserSetup.Validate("Service Resp. Ctr. Filter", ResponsibilityCenter.Code);
        UserSetup.Modify(true);
        exit(ResponsibilityCenter.Code);
    end;

    local procedure CreateServiceOrderWithUpdatedPostingDate(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceItemLineNo: Integer;
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader, Customer."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLineNo);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.Validate("Posting Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));  // Use Random for Date.
        ServiceHeader.Modify(true);
        ServiceLine.Get(ServiceLine."Document Type", ServiceLine."Document No.", ServiceLine."Line No.");
        ServiceLine.Validate("Posting Date", ServiceHeader."Posting Date");
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrderWithMultipleLines(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; ServiceItemNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        i: Integer;
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItemNo);
        for i := 1 to LibraryRandom.RandIntInRange(3, 6) do begin
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
            ServiceLine.Validate("Service Item No.", ServiceItemLine."Service Item No.");
            ServiceLine.Validate(Quantity, Quantity);
            ServiceLine.Validate("Unit Price", UnitPrice);
            ServiceLine.Modify(true);
        end;
    end;

    local procedure CreateServiceLinesOnPage(var ServiceItemWorksheet: TestPage "Service Item Worksheet"; Type: Enum "Service Line Type"; ItemNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceItemWorksheet.ServInvLines.Type.SetValue(Type);
        ServiceItemWorksheet.ServInvLines."No.".SetValue(ItemNo);
        ServiceItemWorksheet.ServInvLines.Description.SetValue(
          LibraryUtility.GenerateRandomCode(ServiceLine.FieldNo(Description), DATABASE::"Service Line"));
        ServiceItemWorksheet.ServInvLines.New();
    end;

    local procedure CreateServiceDocumentWithInvoiceDiscount(var ServiceLine: Record "Service Line") ServiceCharge: Decimal
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Create Customer, Item, Customer Invoice Discount, Service Order.
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        ServiceCharge := LibraryRandom.RandDec(10, 2);  // Generate Random Value for Service Charge.
        CreateCustomerInvoiceDiscount(Customer."No.", LibraryRandom.RandDec(10, 2), ServiceCharge);  // Generate Random Value for Discount Percent.
        CreateServiceItem(ServiceItem, Customer."No.", Item."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateAndUpdateServiceLine(
          ServiceHeader, ServiceLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2),
          ServiceItemLine."Line No.", 0);  // Take RANDOM Value for Quantity and zero for Line Discount.
        GetServiceLine(ServiceLine, ServiceHeader);
        ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity / 2);  // For Partial Shipping.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceDoumentLine(var ServiceItemLine: Record "Service Item Line"; DocumentType: Enum "Service Document Type")
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
    end;

    local procedure CreateSimpleServiceOrder(var ServiceLine: Record "Service Line"; var LineDiscountPercent: Decimal)
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLineNo: Integer;
    begin
        LineDiscountPercent := LibraryRandom.RandInt(100);
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader, '');
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLineNo);
        ServiceLine.Validate("Line Discount %", LineDiscountPercent);
        ServiceLine.Modify(true);
    end;

    local procedure CreateAndPostPartialServiceOrder(var ServiceHeader: Record "Service Header"; var ItemServiceLine: Record "Service Line"; var VATPostingSetup: Record "VAT Posting Setup")
    var
        Resource: Record Resource;
        ResourceServiceLine: Record "Service Line";
        ServiceItemLineNo: Integer;
    begin
        // Create and post (Ship + Invoice partially) Service Order with item/resource lines

        // 1. Exercise: Get VAT Posting Setup, VAT Rate
        VATPostingSetup.SetFilter("Unrealized VAT Type", '=''''');
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // 2. Exercise: Create Service Order.
        ServiceItemLineNo :=
          CreateServiceOrder(ServiceHeader, CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));

        // 3. Exercise: Create Item and Resource service lines, set Qty. To Invoice and Post.
        LibraryService.CreateServiceLine(
          ItemServiceLine, ServiceHeader, ItemServiceLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        UpdateServiceLineWithRandomQtyAndPrice(ItemServiceLine, ServiceItemLineNo);

        LibraryResource.FindResource(Resource);
        LibraryService.CreateServiceLine(ResourceServiceLine, ServiceHeader, ResourceServiceLine.Type::Resource, Resource."No.");
        UpdateServiceLine(ResourceServiceLine, ServiceItemLineNo, LibraryRandom.RandIntInRange(10, 20), 0);

        // 4. Exercise: Post Service Order - Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 5. Exercise: Set Qty. To. Invoice to 1 for Item Line and to 0 for Resource Line.
        ItemServiceLine.Get(ItemServiceLine."Document Type", ItemServiceLine."Document No.", ItemServiceLine."Line No."); // Update line after posting.
        ItemServiceLine.Validate("Qty. to Invoice", LibraryRandom.RandInt(ItemServiceLine.Quantity));
        ItemServiceLine.Modify(true);
        ResourceServiceLine.Get(ResourceServiceLine."Document Type", ResourceServiceLine."Document No.", ResourceServiceLine."Line No."); // Update line after posting.
        ResourceServiceLine.Validate("Qty. to Invoice", 0);
        ResourceServiceLine.Modify(true);

        // 6. Exercise: Post Service Order - Invoice.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, true);
    end;

    local procedure CreateServiceOrderWithMultipleServiceItemLines(var ServiceHeader: Record "Service Header")
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        Counter: Integer;
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        for Counter := 1 to LibraryRandom.RandIntInRange(3, 6) do begin
            Clear(ServiceItem);
            LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
            LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, '');
            UpdateServiceLineWithRandomQtyAndPrice(ServiceLine, ServiceItemLine."Line No.");
        end;
    end;

    local procedure CreateServiceDocWithLoaner(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; DocType: Enum "Service Document Type")
    var
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceItem(ServiceItem, '');
        LibraryService.CreateServiceHeader(ServiceHeader, DocType, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ServiceItemLine.Validate("Loaner No.", CreateLoaner());
        ServiceItemLine.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);
    end;

    local procedure MockServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine."Document Type" := ServiceHeader."Document Type";
        ServiceLine."Document No." := ServiceHeader."No.";
        ServiceLine."Line No." := LibraryUtility.GetNewRecNo(ServiceLine, ServiceLine.FieldNo("Line No."));
        ServiceLine.Insert();
    end;

    local procedure MockServiceLineWithTypeItem(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        MockServiceLine(ServiceLine, ServiceHeader);
        ServiceLine.Type := ServiceLine.Type::Item;
    end;

    local procedure AddServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ItemNo: Code[20])
    begin
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader,
          ServiceLine.Type::Item, ItemNo);
        UpdateServiceLineWithRandomQtyAndPrice(
          ServiceLine, FindLastServiceItemLineNo(ServiceHeader."Document Type", ServiceHeader."No."));
    end;

    local procedure ValidateServiceLineStandardCode(var ServiceLine: Record "Service Line"; StandardTextCode: Code[20])
    var
        ServiceTransferExtText: Codeunit "Service Transfer Ext. Text";
    begin
        ServiceLine.Validate("No.", StandardTextCode);
        ServiceLine.Modify(true);
        ServiceTransferExtText.ServCheckIfAnyExtText(ServiceLine, false);
        ServiceTransferExtText.InsertServExtText(ServiceLine);
    end;

    local procedure OpenServiceOrderPageWithNewOrder(CustomerNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        OpenServiceOrderPage(ServiceOrder, ServiceHeader."No.");
    end;

    local procedure OpenServiceOrderPage(var ServiceOrder: TestPage "Service Order"; DocumentNo: Code[20])
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", DocumentNo);
    end;

    local procedure OpenServiceInvoicePage(No: Code[20])
    var
        ServiceInvoice: TestPage "Service Invoice";
    begin
        ServiceInvoice.OpenEdit();
        ServiceInvoice.FILTER.SetFilter("No.", No);
        ServiceInvoice.ServLines.GetShipmentLines.Invoke();
        ServiceInvoice.OK().Invoke();
    end;

    local procedure ChangeCustomerNo(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        ServiceHeader.Validate("Customer No.", CustomerNo);
    end;

    local procedure OpenServiceInvoicePageAndValidateUnitPrice(No: Code[20])
    var
        ServiceInvoice: TestPage "Service Invoice";
    begin
        ServiceInvoice.OpenEdit();
        ServiceInvoice.FILTER.SetFilter("No.", No);
        ServiceInvoice.ServLines."Unit Price".SetValue(ServiceInvoice.ServLines."Unit Price".Value);
    end;

    local procedure CopyServiceLine(var ServiceLineOld: Record "Service Line"; var ServiceLine: Record "Service Line")
    begin
        repeat
            ServiceLineOld := ServiceLine;
            ServiceLineOld.Insert();
            LibraryVariableStorage.Enqueue(ServiceLine.Description);
        until ServiceLine.Next() = 0;
    end;

    local procedure DeleteUserSetup(var UserSetup: Record "User Setup"; ResponsibilityCenterCode: Code[10])
    begin
        UserSetup.SetRange("Service Resp. Ctr. Filter", ResponsibilityCenterCode);
        UserSetup.FindFirst();
        UserSetup.Delete(true);
    end;

    local procedure CreateGLAccount(VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.FindGenBusinessPostingGroup(GenBusinessPostingGroup);
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure OpenServiceItemWorksheetPage(ServiceOrderNo: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, ServiceOrderNo);
        ServiceOrder.OpenEdit();
        ServiceOrder.GotoRecord(ServiceHeader);
        ServiceOrder.ServItemLines."Service Item Worksheet".Invoke();
    end;

    local procedure FindDetailedCustLedgerEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; EntryType: Enum "Detailed CV Ledger Entry Type")
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Document Type", DocumentType);
        DetailedCustLedgEntry.FindSet();
    end;

    local procedure FindPostCode(var PostCode: Record "Post Code")
    begin
        PostCode.SetFilter(City, '<>%1', '');
        PostCode.SetFilter("Country/Region Code", '<>%1', '');
        LibraryERM.FindPostCode(PostCode);
    end;

    local procedure FindPaymentMethodWithBalanceAccount(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetFilter("Bal. Account No.", '<>''''');
        PaymentMethod.FindFirst();
        exit(PaymentMethod.Code);
    end;

    local procedure FindServiceDocumentLog(var ServiceDocumentLog: Record "Service Document Log"; DocumentType: Enum "Service Log Document Type"; DocumentNo: Code[20])
    begin
        ServiceDocumentLog.SetRange("Document Type", DocumentType);
        ServiceDocumentLog.SetRange("Document No.", DocumentNo);
        ServiceDocumentLog.FindFirst();
    end;

    local procedure FindServiceShipmentHeader(OrderNo: Code[20]): Code[20]
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindFirst();
        exit(ServiceShipmentHeader."No.");
    end;

    local procedure FindServiceInvoiceHeader(OrderNo: Code[20]): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure FindLastServiceItemLineNo(DocumentType: Enum "Service Document Type"; DocumentNo: Code[20]): Integer
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceItemLine.SetRange("Document Type", DocumentType);
        ServiceItemLine.SetRange("Document No.", DocumentNo);
        ServiceItemLine.FindLast();
        exit(ServiceItemLine."Line No.");
    end;

    local procedure FindServiceLineByOrder(ServiceHeader: Record "Service Header"; ServiceLineOrderNo: Integer; var ServiceLine: Record "Service Line")
    begin
        GetServiceLine(ServiceLine, ServiceHeader);
        ServiceLine.Next(ServiceLineOrderNo - 1);
    end;

    local procedure FindServiceLineByServiceItemLineNo(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer)
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.FindFirst();
    end;

    local procedure FindServiceLineWithExtText(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer)
    begin
        ServiceLine.SetRange(Type, ServiceLine.Type::" ");
        FindServiceLineByServiceItemLineNo(ServiceLine, ServiceHeader, ServiceItemLineNo);
    end;

    local procedure GetServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
    end;

    local procedure ModifyServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Validate("Price Update Period", ServiceContractHeader."Service Period");
        ServiceContractHeader.Modify(true);
    end;

    local procedure InsertExtendedTextForServiceLines(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        ServiceTransferExtText: Codeunit "Service Transfer Ext. Text";
    begin
        GetServiceLine(ServiceLine, ServiceHeader);
        repeat
            ServiceTransferExtText.ServCheckIfAnyExtText(ServiceLine, true);
            ServiceTransferExtText.InsertServExtText(ServiceLine);
        until ServiceLine.Next() = 0;
    end;

    local procedure ReceiveLoanerOnServiceShipment(OrderNo: Code[20])
    var
        ServiceShipmentItemLine: Record "Service Shipment Item Line";
        PostedServiceShptSubform: Page "Posted Service Shpt. Subform";
    begin
        ServiceShipmentItemLine.SetRange("No.", FindServiceShipmentHeader(OrderNo));
        ServiceShipmentItemLine.FindFirst();
        Clear(PostedServiceShptSubform);
        PostedServiceShptSubform.SetTableView(ServiceShipmentItemLine);
        PostedServiceShptSubform.SetRecord(ServiceShipmentItemLine);
        PostedServiceShptSubform.ReceiveLoaner();
    end;

    local procedure ReceiveLoanerOnServiceOrder(var ServiceItemLine: Record "Service Item Line"; ServiceItemNo: Code[20])
    var
        ServLoanerManagement: Codeunit ServLoanerManagement;
    begin
        ServiceItemLine.SetRange("Service Item No.", ServiceItemNo);
        ServiceItemLine.FindFirst();
        ServLoanerManagement.ReceiveLoaner(ServiceItemLine);
    end;

    local procedure SaveComments(var ServiceCommentLineOld: Record "Service Comment Line"; ServiceItemLine: Record "Service Item Line")
    var
        ServiceCommentLine: Record "Service Comment Line";
    begin
        ServiceCommentLine.SetRange("Table Name", ServiceCommentLine."Table Name"::"Service Header");
        ServiceCommentLine.SetRange("Table Subtype", ServiceItemLine."Document Type");
        ServiceCommentLine.SetRange("No.", ServiceItemLine."Document No.");
        ServiceCommentLine.FindSet();
        repeat
            ServiceCommentLineOld := ServiceCommentLine;
            ServiceCommentLineOld.Insert();
        until ServiceCommentLine.Next() = 0;
    end;

    local procedure SelectDifferentShiptoCode(var ShipToAddress: Record "Ship-to Address")
    var
        ShipToAddress2: Record "Ship-to Address";
    begin
        ShipToAddress2.SetRange("Customer No.", ShipToAddress."Customer No.");
        ShipToAddress2.SetFilter(Code, '<>%1', ShipToAddress.Code);
        if not ShipToAddress2.FindFirst() then
            LibrarySales.CreateShipToAddress(ShipToAddress2, ShipToAddress."Customer No.");
        ShipToAddress := ShipToAddress2;
    end;

    local procedure ServiceItemNoCreatedOnServiceItemLine(DocumentType: Enum "Service Document Type"; Warranty: Boolean; ReplenishmentSystem: Enum "Replenishment System")
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        // Setup: Create Service Order and Update Service Item Line with Item No.,Warranty.
        Initialize();
        CreateServiceDoumentLine(ServiceItemLine, DocumentType);
        UpdateItemAndWarrantyOnServiceItemLine(ServiceItemLine, Warranty, ReplenishmentSystem);

        // Exercise: Create Service Item on Service Item Line.
        CreateServiceItemFromDocument(ServiceItemLine);

        // Verify: Verify Service Item No. field filled with value Service Item Line.
        VerifyServiceItemLineExistServiceItemNo(ServiceItemLine."Item No.");
    end;

    local procedure SetServiceSetupCopyLineDescrToGLEntry(CopyDescrToGLEntry: Boolean)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup."Copy Line Descr. to G/L Entry" := CopyDescrToGLEntry;
        ServiceMgtSetup.Modify();
    end;

    local procedure GetOutstandingAmountForServiceLines(ServiceHeader: Record "Service Header"): Decimal
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetCurrentKey("Document Type", "Bill-to Customer No.", "Currency Code");
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Bill-to Customer No.", ServiceHeader."Bill-to Customer No.");
        ServiceLine.SetRange("Currency Code", ServiceHeader."Currency Code");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.CalcSums("Outstanding Amount");
        exit(ServiceLine."Outstanding Amount");
    end;

    local procedure CalcTotalLineAmount(DocType: Enum "Service Document Type"; DocNo: Code[20]): Decimal
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", DocType);
        ServiceLine.SetRange("Document No.", DocNo);
        ServiceLine.CalcSums("Amount Including VAT");
        exit(ServiceLine."Amount Including VAT");
    end;

    local procedure UpdateItemAndWarrantyOnServiceItemLine(var ServiceItemLine: Record "Service Item Line"; Warranty: Boolean; ReplenishmentSystem: Enum "Replenishment System")
    begin
        ServiceItemLine.Validate("Item No.", CreateItemWithReplenishmentSystem(ReplenishmentSystem));
        ServiceItemLine.Validate(Warranty, Warranty);
        ServiceItemLine.Modify(true);
    end;

    local procedure UpdateContractOnServiceHeader(var ServiceHeader: Record "Service Header"; ContractNo: Code[20])
    var
        ServiceHeader2: Record "Service Header";
    begin
        ServiceHeader2.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.Validate("Contract No.", ContractNo);
        ServiceHeader.UpdateServiceOrderChangeLog(ServiceHeader2);
        ServiceHeader.Modify(true);
    end;

    local procedure UpdateServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Modify(true);
    end;

    local procedure UpdateServiceLineWithRandomQtyAndPrice(var ServiceLine: Record "Service Line"; ServiceItemLineNo: Integer)
    begin
        UpdateServiceLine(
          ServiceLine, ServiceItemLineNo,
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandDecInRange(1000, 2000, 2));
    end;

    local procedure UpdateServiceLine(var ServiceLine: Record "Service Line"; ServiceItemLineNo: Integer; Quantity: Decimal; UnitPrice: Decimal)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Unit Price", UnitPrice);
        ServiceLine.Modify(true);
    end;

    local procedure UpdationOfServiceItemGroup(var ServiceItemLine: Record "Service Item Line")
    var
        ServiceItemGroup: Record "Service Item Group";
    begin
        LibraryService.FindServiceItemGroup(ServiceItemGroup);
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.SetRange("Item No.", '');
        if ServiceItemLine.FindSet() then
            repeat
                ServiceItemLine.Validate("Service Item Group Code", ServiceItemGroup.Code);
                ServiceItemLine.Modify(true);
                ServiceItemGroup.Next();
            until ServiceItemLine.Next() = 0;
    end;

    local procedure UpdateSalesReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibrarySales.SetCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"Credit Limit");
        LibrarySales.SetStockoutWarning(false);
    end;

    local procedure UpdateServiceLineQtyToShipInvoice(var ServiceLine: Record "Service Line"; QtyToShipInvoice: Decimal)
    begin
        ServiceLine.Validate("Qty. to Invoice", QtyToShipInvoice);
        ServiceLine.Validate("Qty. to Ship", QtyToShipInvoice);
        ServiceLine.Modify();
    end;

    local procedure UpdateCustNoSeries()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Customer Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);
    end;

    local procedure UpdateCustomerCreditLimit(CustomerNo: Code[20]; NewCreditLimitAmount: Decimal)
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("Credit Limit (LCY)", NewCreditLimitAmount);
        Customer.Modify(true);
    end;

    local procedure SetPostedInvoiceNosEqualInvoiceNosInServSetup(var ServiceMgtSetup: Record "Service Mgt. Setup")
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Posted Service Invoice Nos.", LibraryERM.CreateNoSeriesCode());
        ServiceMgtSetup.Validate("Service Invoice Nos.", ServiceMgtSetup."Posted Service Invoice Nos.");
        ServiceMgtSetup.Modify(true);
    end;

    local procedure CreateServiceLineSimple(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; LineNo: Integer)
    begin
        ServiceLine.Init();
        ServiceLine.Validate("Document Type", ServiceHeader."Document Type");
        ServiceLine.Validate("Document No.", ServiceHeader."No.");
        ServiceLine.Validate("Line No.", LineNo);
        ServiceLine.Insert(true);
    end;

    local procedure VendorErrorMessageWhileCreatingServiceItem(DocumentType: Enum "Service Document Type"; Warranty: Boolean; ReplenishmentSystem: Enum "Replenishment System")
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        // Setup: Create Service Order and Update Service Item Line with Item No.,Warranty.
        Initialize();
        CreateServiceDoumentLine(ServiceItemLine, DocumentType);
        UpdateItemAndWarrantyOnServiceItemLine(ServiceItemLine, Warranty, ReplenishmentSystem);

        // Exercise: Create Service Item on Service Item Line.
        asserterror CreateServiceItemFromDocument(ServiceItemLine);

        // Verify: Verify Error message will occur while Creating Service Item.
        Assert.ExpectedError(VendorNoErr);
    end;

    local procedure VerifyAmountIncludingVATOnServiceLine(ServiceHeader: Record "Service Header"; VATPercentage: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        GetServiceLine(ServiceLine, ServiceHeader);
        ServiceLine.TestField("VAT %", VATPercentage);
        ServiceLine.TestField("Amount Including VAT", Round(ServiceLine.Quantity * ServiceLine."Unit Price"));
    end;

    local procedure VerifyComments(var ServiceCommentLineOld: Record "Service Comment Line"; ServiceItemLine: Record "Service Item Line")
    var
        ServiceCommentLine: Record "Service Comment Line";
    begin
        ServiceCommentLineOld.FindFirst();
        ServiceCommentLine.SetRange("Table Name", ServiceCommentLine."Table Name"::"Service Header");
        ServiceCommentLine.SetRange("No.", ServiceItemLine."Document No.");
        ServiceCommentLine.SetRange("Table Line No.", ServiceItemLine."Line No.");
        ServiceCommentLine.FindSet();
        repeat
            ServiceCommentLine.TestField(Type, ServiceCommentLineOld.Type);
            ServiceCommentLine.TestField(Comment, ServiceCommentLineOld.Comment);
            ServiceCommentLineOld.Next();
        until ServiceCommentLine.Next() = 0;
    end;

    local procedure VerifyDescOnPostedInvoiceLine(var ServiceLine: Record "Service Line")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", ServiceLine."Document No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceLine.FindSet();
        repeat
            ServiceInvoiceLine.Get(ServiceInvoiceHeader."No.", ServiceLine."Line No.");
            ServiceInvoiceLine.TestField(Description, ServiceLine.Description);
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyDetailedLedgerEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        TotalAmount: Decimal;
    begin
        FindDetailedCustLedgerEntry(DetailedCustLedgEntry, DocumentNo, DocumentType, DetailedCustLedgEntry."Entry Type"::Application);
        repeat
            TotalAmount += DetailedCustLedgEntry.Amount;
        until DetailedCustLedgEntry.Next() = 0;
        Assert.AreEqual(
          0, TotalAmount,
          StrSubstNo(
            TotalAmountErr, 0, DetailedCustLedgEntry.TableCaption(), DetailedCustLedgEntry.FieldCaption("Entry Type"),
            DetailedCustLedgEntry."Entry Type"));
    end;

    local procedure VerifyEntriesAfterPostingServiceDocument(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        CustLedgerEntry.TestField(Open, false);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo2);
        CustLedgerEntry.TestField(Open, false);
        VerifyGLEntries(DocumentNo2);
        VerifyDetailedLedgerEntry(DocumentNo2, DocumentType);
    end;

    local procedure VerifyGLEntries(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        TotalAmount: Decimal;
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
        repeat
            TotalAmount += GLEntry.Amount;
        until GLEntry.Next() = 0;
        Assert.AreEqual(
          0, TotalAmount, StrSubstNo(TotalAmountErr, 0, GLEntry.TableCaption(), GLEntry.FieldCaption("Document No."), GLEntry."Document No."));
    end;

    local procedure VerifyGLEntriesByAccount(DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        TotalAmount: Decimal;
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindSet();
        repeat
            TotalAmount += GLEntry.Amount;
        until GLEntry.Next() = 0;
        Assert.AreEqual(
          ExpectedAmount, TotalAmount,
          StrSubstNo(
            GlAccountTotalAmountErr, 0, GLEntry.TableCaption(), GLEntry.FieldCaption("Document No."), GLEntry."Document No.",
            GLEntry.FieldCaption("G/L Account No."), GLEntry."G/L Account No."));
    end;

    local procedure VerifyOutstandingAmountOnServiceLines(DocumentNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    var
        ServiceLine: Record "Service Line";
        OutStandingAmount: Decimal;
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindSet();
        OutStandingAmount := OutStandingAmount + (OutStandingAmount * ServiceLine."VAT %" / 100);
        repeat
            OutStandingAmount := (1 + ServiceLine."VAT %" / 100) * Quantity * UnitPrice;
            Assert.AreNearlyEqual(
              OutStandingAmount, ServiceLine."Outstanding Amount", LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(WrongValueErr, ServiceLine.FieldCaption("Outstanding Amount"), OutStandingAmount, ServiceLine.TableCaption()));
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyOutstandingAmountOnGLEntry(DocumentNo: Code[20]; TotalOutStandingAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        GLAmt: Decimal;
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocumentNo);
        if TotalOutStandingAmount > 0 then
            GLEntry.SetFilter(Amount, '>0')
        else
            GLEntry.SetFilter(Amount, '<0');
        if GLEntry.FindSet() then
            repeat
                GLAmt += GLEntry.Amount;
            until GLEntry.Next() = 0;
        Assert.AreNearlyEqual(
          TotalOutStandingAmount, GLAmt, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(WrongValueErr, GLEntry.FieldCaption(Amount), GLAmt, GLEntry.TableCaption()));
    end;

    local procedure VerifyVATEntries(DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
        TotalAmount: Decimal;
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindSet();
        repeat
            TotalAmount += VATEntry.Amount;
        until VATEntry.Next() = 0;
        Assert.AreEqual(
          ExpectedAmount, TotalAmount,
          StrSubstNo(TotalAmountErr, ExpectedAmount, VATEntry.TableCaption(), VATEntry.FieldCaption("Document No."), VATEntry."Document No."));
    end;

    local procedure VerifyVATAmountOnServiceStatistics(DocumentType: Enum "Service Document Type")
    var
        ServiceHeader: Record "Service Header";
    begin
        // Setup: Modify General Ledger Setup and Create Service Document.
        Initialize();
        InitServDocWithInvRoundingPrecisionScenario(ServiceHeader, DocumentType);

        // Exercise: Open Service Statistics.
        Commit();
        PAGE.RunModal(PAGE::"Service Statistics", ServiceHeader);

        // Verify: Verify VAT Amount and "Amount Including VAT" on VAT Amount Lines and VAT Amount on Service Statistics using ServiceStatisticsPageHandler .
    end;

    local procedure VerifyDiscountAmount(DocumentNo: Code[20]; DiscountAmount: Decimal; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", DocumentNo);
        ServiceInvoiceHeader.FindFirst();
        GLEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          DiscountAmount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(DiscountAmountErr, GLEntry.FieldCaption(Amount), DiscountAmount, GLEntry.TableCaption()));
    end;

    local procedure VerifyLinkedServiceLineExists(DocumentType: Enum "Service Document Type"; DocumentNo: Code[20]; ServiceItemLineNo: Integer)
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", DocumentType);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.SetRange("Service Item Line No.", ServiceItemLineNo);
        Assert.IsFalse(
          ServiceLine.IsEmpty,
          StrSubstNo(ServiceLineLineNoErr, ServiceLine.FieldCaption("Service Item Line No."), ServiceItemLineNo));
    end;

    local procedure VerifyLoanerEntry(ServiceItemLine: Record "Service Item Line")
    var
        LoanerEntry: Record "Loaner Entry";
    begin
        LoanerEntry.SetRange("Loaner No.", ServiceItemLine."Loaner No.");
        LoanerEntry.FindFirst();
        LoanerEntry.TestField("Document No.", ServiceItemLine."Document No.");
        LoanerEntry.TestField("Service Item Line No.", ServiceItemLine."Line No.");
        LoanerEntry.TestField("Service Item No.", ServiceItemLine."Service Item No.");
        LoanerEntry.TestField(Lent, false);
        LoanerEntry.TestField("Customer No.", ServiceItemLine."Customer No.");
    end;

    local procedure VerifyResourceLedgerEntry(ResourceNo: Code[20]; DocumentNo: Code[20]; EntryType: Enum "Res. Journal Line Entry Type"; Quantity: Decimal; TotalPrice: Decimal)
    var
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        ResLedgerEntry.SetRange("Resource No.", ResourceNo);
        ResLedgerEntry.SetRange("Document No.", DocumentNo);
        ResLedgerEntry.SetRange("Entry Type", EntryType);
        ResLedgerEntry.FindFirst();
        ResLedgerEntry.TestField(Quantity, Quantity);
        ResLedgerEntry.TestField("Total Price", TotalPrice);
    end;

    local procedure VerifyShiptoCode(ServiceOrderNo: Code[20])
    var
        ServiceShipmentItemLine: Record "Service Shipment Item Line";
        ServiceItem: Record "Service Item";
    begin
        // Verify that the Ship to Code on Service Shipment Item Line is Ship to Code on Service Item on Service Shipment Item Line.
        ServiceShipmentItemLine.SetRange("No.", FindServiceShipmentHeader(ServiceOrderNo));
        ServiceShipmentItemLine.FindSet();
        repeat
            ServiceItem.Get(ServiceShipmentItemLine."Service Item No.");
            ServiceShipmentItemLine.TestField("Ship-to Code", ServiceItem."Ship-to Code");
        until ServiceShipmentItemLine.Next() = 0;
    end;

    local procedure VerifyServiceDocumentLocationCode(DocumentType: Enum "Service Document Type"; CustomerNo: Code[20]; LocationCode: Code[10])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetRange("Document Type", DocumentType);
        ServiceHeader.SetRange("Customer No.", CustomerNo);
        ServiceHeader.FindFirst();
        Assert.AreEqual(
          LocationCode, ServiceHeader."Location Code",
          StrSubstNo(WrongValueErr, ServiceHeader.FieldCaption("Location Code"), LocationCode, ServiceHeader.TableCaption));
    end;

    local procedure VerifyServiceDocumentResponsibilityCenter(DocumentType: Enum "Service Document Type"; CustomerNo: Code[20]; ResponsibilityCenter: Code[10])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetRange("Document Type", DocumentType);
        ServiceHeader.SetRange("Customer No.", CustomerNo);
        ServiceHeader.FindFirst();
        ServiceHeader.TestField("Responsibility Center", ResponsibilityCenter);
    end;

    local procedure VerifyServiceShipmentItemLineCount(ServiceOrderNo: Code[20]; ExpectedCount: Integer)
    var
        ServiceShipmentItemLine: Record "Service Shipment Item Line";
    begin
        ServiceShipmentItemLine.SetRange("No.", FindServiceShipmentHeader(ServiceOrderNo));
        Assert.AreEqual(ExpectedCount, ServiceShipmentItemLine.Count, ServShiptItemLineWrongCountErr);
    end;

    local procedure VerifyServiceDocumentLog(DocumentNo: Code[20]; After: Text[50]; EventNo: Integer)
    var
        ServiceDocumentLog: Record "Service Document Log";
    begin
        ServiceDocumentLog.SetRange(After, After);
        ServiceDocumentLog.SetRange("Event No.", EventNo);
        FindServiceDocumentLog(ServiceDocumentLog, ServiceDocumentLog."Document Type"::Order, DocumentNo);
    end;

    local procedure VerifyServiceDocumentLogExist(DocumentNo: Code[20]; EventNo: Integer)
    var
        ServiceDocumentLog: Record "Service Document Log";
    begin
        ServiceDocumentLog.SetRange("Event No.", EventNo);
        FindServiceDocumentLog(ServiceDocumentLog, ServiceDocumentLog."Document Type"::Order, DocumentNo);
    end;

    local procedure VerifyServiceDocumentShipment(DocumentNo: Code[20]; EventNo: Integer)
    var
        ServiceDocumentLog: Record "Service Document Log";
    begin
        FindServiceDocumentLog(ServiceDocumentLog, ServiceDocumentLog."Document Type"::Shipment, DocumentNo);
        ServiceDocumentLog.TestField("Event No.", EventNo);
    end;

    local procedure VerifyServiceOrderNotExist(ServiceHeaderCode: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetRange("No.", ServiceHeaderCode);
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        Assert.RecordIsEmpty(ServiceHeader);
    end;

    local procedure VerifyServiceItemLog(ServiceItemNo: Code[20]; After: Text[50]; EventNo: Integer)
    var
        ServiceItemLog: Record "Service Item Log";
    begin
        ServiceItemLog.SetRange("Service Item No.", ServiceItemNo);
        ServiceItemLog.SetRange(After, After);
        ServiceItemLog.FindFirst();
        ServiceItemLog.TestField("Event No.", EventNo);
    end;

    local procedure VerifyServiceItemLogEntry(DocumentNo: Code[20]; EventNo: Integer)
    var
        ServiceItemLog: Record "Service Item Log";
    begin
        ServiceItemLog.SetRange("Document No.", DocumentNo);
        ServiceItemLog.SetRange("Document Type", ServiceItemLog."Document Type"::Order);
        ServiceItemLog.SetRange("Event No.", EventNo);
        ServiceItemLog.FindFirst();
    end;

    local procedure VerifyServiceItemLogExist(ServiceItemNo: Code[20]; EventNo: Integer)
    var
        ServiceItemLog: Record "Service Item Log";
    begin
        ServiceItemLog.SetRange("Service Item No.", ServiceItemNo);
        ServiceItemLog.SetRange("Event No.", EventNo);
        ServiceItemLog.FindFirst();
    end;

    local procedure VerifyServiceLedgerEntry(No: Code[20]; DocumentNo: Code[20]; ServiceContractNo: Code[20]; EntryType: Enum "Service Ledger Entry Entry Type"; Quantity: Decimal)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Shipment);
        ServiceLedgerEntry.SetRange("Entry Type", EntryType);
        ServiceLedgerEntry.SetRange("Document No.", DocumentNo);
        ServiceLedgerEntry.FindFirst();
        ServiceLedgerEntry.TestField("No.", No);
        ServiceLedgerEntry.TestField("Service Contract No.", ServiceContractNo);
        ServiceLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyServiceLedgerEntryWithUnitPrice(ServiceContractLine: Record "Service Contract Line"; ExpectedNoOfEntries: Integer)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ActualNoOfEntries: Integer;
    begin
        ServiceLedgerEntry.SetRange("Service Contract No.", ServiceContractLine."Contract No.");
        ServiceLedgerEntry.SetRange("Service Item No. (Serviced)", ServiceContractLine."Service Item No.");
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Invoice);
        ServiceLedgerEntry.FindSet();
        ActualNoOfEntries := ServiceLedgerEntry.Count;
        repeat
            ServiceLedgerEntry.TestField("Unit Price", -ServiceContractLine."Line Value" / 12);
        until ServiceLedgerEntry.Next() = 0;
        Assert.AreEqual(ExpectedNoOfEntries, ActualNoOfEntries, NoOfEntriesMsg);
    end;

    local procedure VerifyServiceItemGroup(DocumentNo: Code[20]; DocumentType: Enum "Service Document Type")
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceItemLine.SetRange("Document Type", DocumentType);
        ServiceItemLine.SetRange("Document No.", DocumentNo);
        if ServiceItemLine.FindSet() then
            repeat
                ServiceItemLine.TestField("Service Item Group Code");
            until ServiceItemLine.Next() = 0;
    end;

    local procedure VerifyVATAmountOnGLEntry(OrderNo: Code[20]; VATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        GLEntry.SetRange("VAT Amount", VATAmount);
        GLEntry.FindFirst();
    end;

    local procedure VerifyPostingDateOnServiceLedgerEntry(ServiceLine: Record "Service Line"; DocumentType: Enum "Service Ledger Entry Document Type"; Quantity: Decimal)
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Service Order No.", ServiceLine."Document No.");
        ServiceLedgerEntry.SetRange("Document Type", DocumentType);
        ServiceLedgerEntry.FindFirst();
        ServiceLedgerEntry.TestField("Posting Date", ServiceLine."Posting Date");
        ServiceLedgerEntry.TestField("No.", ServiceLine."No.");
        ServiceLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarrantyLedgerEntry(ServiceOrderNo: Code[20])
    var
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
    begin
        WarrantyLedgerEntry.SetRange("Service Order No.", ServiceOrderNo);
        WarrantyLedgerEntry.FindFirst();
        WarrantyLedgerEntry.TestField(Open, false);
    end;

    local procedure VerifyVATAmountOnPostInvStatistics(ServiceDocNo: Code[20]; VATAmount: Decimal)
    var
        ServiceInvHeader: Record "Service Invoice Header";
        ServiceInvStatistics: TestPage "Service Invoice Statistics";
    begin
        // Verify first line of Posted Service Invoice
        ServiceInvHeader.SetRange("Order No.", ServiceDocNo);
        ServiceInvHeader.FindLast();

        ServiceInvStatistics.OpenView();
        ServiceInvStatistics.GotoRecord(ServiceInvHeader);

        ServiceInvStatistics.VATAmount.AssertEquals(VATAmount);
        ServiceInvStatistics.Close();
    end;

    local procedure VerifyAmountExclVATOnPostedCrMemoStatistics(CustomerNo: Code[20])
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCreditMemoStatistics: TestPage "Service Credit Memo Statistics";
    begin
        ServiceCrMemoHeader.SetRange("Customer No.", CustomerNo);
        ServiceCrMemoHeader.FindFirst();

        ServiceCreditMemoStatistics.OpenView();
        ServiceCreditMemoStatistics.GotoRecord(ServiceCrMemoHeader);

        ServiceCreditMemoStatistics.Subform.First();
        ServiceCreditMemoStatistics.Subform.FILTER.SetFilter("VAT Amount", '>0');
    end;

    local procedure VerifyNextInvoiceDateAndAmountToPeriod(ServiceInvoicePeriod: Enum "Service Contract Header Invoice Period"; Formula: Integer; EndingDate: Date)
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
        ServiceContract: TestPage "Service Contract";
        Amount: Decimal;
    begin
        // Setup: Create Service Item and Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        // Exercise: Create Service Contract Header With Expiration Date.
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, ServiceItem."Customer No.");
        ServiceContractHeader.Validate("Starting Date", CalcDate('<CY+1D>', WorkDate()));  // Starting Date should be First Day of the Next Year.
        ServiceContractHeader.Validate("Expiration Date", CalcDate('<CY+1D>', ServiceContractHeader."Starting Date"));
        ServiceContractHeader.Modify(true);
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // Verify: Verify Amount Per Period and Next Invoice Date on Service Contract Header After Changing Line Value and Service Invoicce Period on Service Contract Lines.
        ServiceContract.OpenView();
        ServiceContract.FILTER.SetFilter("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContract.ServContractLines."Line Value".SetValue(Amount);
        ServiceContract.InvoicePeriod.SetValue(ServiceInvoicePeriod);
        ServiceContractHeader.Get(ServiceContractLine."Contract Type", ServiceContractLine."Contract No.");
        ServiceContract.NextInvoiceDate.AssertEquals(ServiceContractHeader."Starting Date");
        ServiceContract.NextInvoicePeriod.AssertEquals(
          StrSubstNo(NextInvoicePeriodTxt, ServiceContractHeader."Starting Date", EndingDate));
        ServiceContract.AmountPerPeriod.AssertEquals(Amount / Formula);
    end;

    local procedure VerifyServiceItemLineExistServiceItemNo(ItemNo: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceItemLine.SetRange("Item No.", ItemNo);
        ServiceItemLine.SetRange("Service Item No.", '');
        if not ServiceItemLine.IsEmpty() then
            Error(ServiceItemNoErr);
    end;

    local procedure VerifyServiceLineAmount(DocumentType: Enum "Service Document Type"; DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", DocumentType);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindFirst();
        Assert.AreEqual(Round(ServiceLine.Quantity * ServiceLine."Unit Price"), ServiceLine."Line Amount",
          StrSubstNo(WrongValueErr, ServiceLine.FieldCaption("Line Amount"), ServiceLine."Line Amount"));
    end;

    local procedure VerifyServiceLineInsertLineNo(DocumentType: Enum "Service Document Type"; DocumentNo: Code[20]; ServiceLineBeforeAfterInsert: Record "Service Line"; IsInsertAfter: Boolean; CheckLineNoValue: Integer)
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.Init();
        ServiceLine.Validate("Document Type", DocumentType);
        ServiceLine.Validate("Document No.", DocumentNo);

        Assert.AreEqual(
          CheckLineNoValue, ServiceLine.GetNextLineNo(ServiceLineBeforeAfterInsert, IsInsertAfter),
          StrSubstNo(ServiceLineLineNoErr, ServiceLine.FieldCaption("Line No."), CheckLineNoValue));
    end;

    local procedure VerifyLoanerEntryExists(ServiceItemLine: Record "Service Item Line")
    var
        LoanerEntry: Record "Loaner Entry";
    begin
        FilterLoanerEntryFromServiceItemLine(LoanerEntry, ServiceItemLine);
        Assert.IsFalse(LoanerEntry.IsEmpty, LoanerEntryDoesNotExistErr);
    end;

    local procedure VerifyLoanerEntryDoesNotExist(ServiceItemLine: Record "Service Item Line")
    var
        LoanerEntry: Record "Loaner Entry";
    begin
        FilterLoanerEntryFromServiceItemLine(LoanerEntry, ServiceItemLine);
        Assert.IsTrue(LoanerEntry.IsEmpty, LoanerEntryExistsErr);
    end;

    local procedure VerifyServiceInvoiceLineItemWithExtendedText(ServiceOrderNo: Code[20]; ExpItemNo: Code[20]; ExpExtendedText: Text[50])
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceLine.SetRange("Document No.", FindServiceInvoiceHeader(ServiceOrderNo));
        Assert.AreEqual(2, ServiceInvoiceLine.Count, StrSubstNo(NoOfLinesErr, ServiceInvoiceLine.TableCaption(), 2));

        ServiceInvoiceLine.SetRange(Type, ServiceInvoiceLine.Type::Item);
        ServiceInvoiceLine.FindFirst();
        Assert.AreEqual(ExpItemNo, ServiceInvoiceLine."No.", StrSubstNo(WrongValueErr, ServiceInvoiceLine.FieldCaption("No."), ExpItemNo, ServiceInvoiceLine.TableCaption));

        ServiceInvoiceLine.SetRange(Type, ServiceInvoiceLine.Type::" ");
        ServiceInvoiceLine.FindFirst();
        Assert.AreEqual(ExpExtendedText, ServiceInvoiceLine.Description, StrSubstNo(WrongValueErr, ServiceInvoiceLine.FieldCaption(Description), ExpExtendedText, ServiceInvoiceLine.TableCaption));
    end;

    local procedure VerifyVATBusPostGroupServiceOrder(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; VATBusPostingGroupCode: Code[20])
    begin
        Assert.AreEqual(
          VATBusPostingGroupCode, ServiceHeader."VAT Bus. Posting Group",
          ServiceHeader.FieldCaption("VAT Bus. Posting Group"));
        Assert.AreEqual(
          VATBusPostingGroupCode, ServiceLine."VAT Bus. Posting Group",
          ServiceLine.FieldCaption("VAT Bus. Posting Group"));
    end;

    local procedure VerifyServiceLineCount(ServiceHeader: Record "Service Header"; ExpectedCount: Integer)
    var
        DummyServiceLine: Record "Service Line";
    begin
        DummyServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        DummyServiceLine.SetRange("Document No.", ServiceHeader."No.");
        Assert.RecordCount(DummyServiceLine, ExpectedCount);
    end;

    local procedure VerifyServiceLineDescription(ServiceLine: Record "Service Line"; ExpectedType: Enum "Service Line Type"; ExpectedNo: Code[20]; ExpectedDescription: Text)
    begin
        Assert.AreEqual(ExpectedType, ServiceLine.Type, ServiceLine.FieldCaption(Type));
        Assert.AreEqual(ExpectedNo, ServiceLine."No.", ServiceLine.FieldCaption("No."));
        Assert.AreEqual(ExpectedDescription, ServiceLine.Description, ServiceLine.FieldCaption(Description));
    end;

    local procedure VerifyAmountInclVATOfCreditLimitDetails(ExpectedAmount: Decimal)
    begin
        Assert.AreEqual(
          ExpectedAmount, LibraryVariableStorage.DequeueDecimal(),
          'Incorrect outstanding amount on Credit Limit Details page');
        Assert.AreEqual(
          ExpectedAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect total amount on Credit Limit Details page');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure VerifyServiceLinePostingDate(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Customer No.", ServiceHeader."Customer No.");
        ServiceLine.FindFirst();
        ServiceLine.TestField("Posting Date", ServiceHeader."Posting Date");
    end;

    local procedure VerifyGLEntriesDescription(var TempServiceLine: Record "Service Line"; CustomerNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SETRANGE("Customer No.", CustomerNo);
        ServiceInvoiceHeader.FindFirst();

        GLEntry.SETRANGE("Document No.", ServiceInvoiceHeader."No.");
        TempServiceLine.FindSet();
        repeat
            GLEntry.SETRANGE(Description, TempServiceLine.Description);
            Assert.RecordIsNotEmpty(GLEntry);
        until TempServiceLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Post Invoice Events", 'OnAfterPrepareInvoicePostingBuffer', '', false, false)]
    local procedure OnAfterPrepareInvoicePostingBuffer(var ServiceLine: Record "Service Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        // Example of extending feature "Copy document line description to G/L entries" for lines with type = "Item"
        if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::Item then begin
            InvoicePostingBuffer."Fixed Asset Line No." := ServiceLine."Line No.";
            InvoicePostingBuffer."Entry Description" := ServiceLine.Description;
        end;
    end;

    local procedure FilterLoanerEntryFromServiceItemLine(var LoanerEntry: Record "Loaner Entry"; ServiceItemLine: Record "Service Item Line")
    begin
        LoanerEntry.SetRange("Loaner No.", ServiceItemLine."Loaner No.");
        LoanerEntry.SetRange("Document Type", LoanerEntry."Document Type"::Order);
        LoanerEntry.SetRange("Document No.", ServiceItemLine."Document No.");
        LoanerEntry.SetRange("Service Item No.", ServiceItemLine."Service Item No.");
    end;

    local procedure CreateOrderCheckVATSetup(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryInventory.CreateItem(Item);
        if not VATPostingSetup.Get(ServiceHeader."VAT Bus. Posting Group", Item."VAT Prod. Posting Group") then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, ServiceHeader."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
    end;

    local procedure CreateSalesLineDiscount(var SalesLineDiscount: Record "Sales Line Discount"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        SalesLineDiscount.Init();
        SalesLineDiscount.Validate(Type, SalesLineDiscount.Type::Item);
        SalesLineDiscount.Validate(Code, ItemNo);
        SalesLineDiscount.Validate("Sales Type", SalesLineDiscount."Sales Type"::Customer);
        SalesLineDiscount.Validate("Sales Code", CustomerNo);
        SalesLineDiscount.Insert(true);
    end;

    local procedure SetupForUoMTest(
        var Item: Record Item;
        var ServiceLine: Record "Service Line";
        var BaseUoM: Record "Unit of Measure";
        var NonBaseUOM: Record "Unit of Measure";
        var ItemUOM: Record "Item Unit of Measure";
        var ItemNonBaseUOM: Record "Item Unit of Measure";
        BaseQtyPerUOM: Integer;
        NonBaseQtyPerUOM: Integer;
        QtyRoundingPrecision: Decimal
    )
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");

        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);

        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);

        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, BaseQtyPerUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemNonBaseUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);

        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
    end;

    local procedure VerifyCountServiceCommentLine(TableName: Enum "Service Comment Table Name"; TableSubtype: Option; No: Code[20]; TableLineNo: Integer)
    var
        ServiceCommentLine: Record "Service Comment Line";
    begin
        ServiceCommentLine.SetRange("Table Name", TableName);
        ServiceCommentLine.SetRange("Table Subtype", TableSubtype);
        ServiceCommentLine.SetRange("No.", No);
        ServiceCommentLine.SetRange("Table Line No.", TableLineNo);
        Assert.RecordCount(ServiceCommentLine, 1);
    end;

    local procedure CreateServiceQuoteWithServiceItem(var ServiceItemLine: Record "Service Item Line")
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure CreateSalesOrder(No: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, No);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure PostPositiveAdjustment(ItemNo: Code[20]; Quantity: Decimal): Integer
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit(FindItemLedgEntryNo(ItemNo, ItemLedgerEntry."Entry Type"::"Positive Adjmt."));
    end;

    local procedure FindItemLedgEntryNo(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"): Integer
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Entry Type", EntryType);
        ItemLedgEntry.FindLast();
        exit(ItemLedgEntry."Entry No.");
    end;

    local procedure GetServiceShipmentLines(var ServiceHeader: Record "Service Header"; OrderNo: Text[20]; CustomerNo: Text[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
        ServiceGetShipment: Codeunit "Service-Get Shipment";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        ServiceShipmentLine.SetRange("Order No.", OrderNo);
        ServiceGetShipment.SetServiceHeader(ServiceHeader);
        ServiceGetShipment.CreateInvLines(ServiceShipmentLine);
    end;

    local procedure CreateAndPostServiceInvoiceWithCustomerPostingGroup(CustomerNo: Code[20]; CustPostGrp: Code[20]; PostingDate: Date): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        ServiceHeader.Validate("Posting Date", PostingDate);
        ServiceHeader.Validate("Customer Posting Group", CustPostGrp);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        if ServiceInvoiceHeader.FindFirst() then
            exit(ServiceInvoiceHeader."No.");
    end;

    local procedure CreateCustomReportSelectionForCustomer(CustomerNo: Code[20]; ReportSelectionUsage: Enum "Report Selection Usage"; ReportID: Integer)
    var
        CustomReportSelection: Record "Custom Report Selection";
        CustomReportLayout: Record "Custom Report Layout";
    begin
        CustomReportSelection.Init();
        CustomReportSelection.Validate("Source Type", Database::Customer);
        CustomReportSelection.Validate("Source No.", CustomerNo);
        CustomReportSelection.Validate(Usage, ReportSelectionUsage);
        CustomReportSelection.Validate(Sequence, 1);
        CustomReportSelection.Validate("Report ID", ReportID);
        CustomReportSelection.Validate("Use for Email Body", true);
        CustomReportSelection.Validate(
            "Email Body Layout Code", CustomReportLayout.InitBuiltInLayout(CustomReportSelection."Report ID", CustomReportLayout.Type::Word.AsInteger()));
        CustomReportSelection.Insert(true);
    end;

    local procedure CreateShipmentMethod(var ShipmentMethod: Record "Shipment Method")
    begin
        ShipmentMethod.Init();
        ShipmentMethod.Code := LibraryUtility.GenerateRandomCode(ShipmentMethod.FieldNo(Code), Database::"Shipment Method");
        ShipmentMethod.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandlerForFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandlerWithAnswer(Question: Text[1024]; var Reply: Boolean)
    var
        Answer: Variant;
    begin
        LibraryVariableStorage.Dequeue(Answer);
        Reply := Answer;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerTemplateHandler(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    begin
        SelectCustomerTemplList.First();
        SelectCustomerTemplList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContractTemplateHandler(var ServiceContractTemplateList: Page "Service Contract Template List"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Just for Handle the Message.
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FormHandlerResourceAllocation(var ResourceAllocations: Page "Resource Allocations")
    var
        ServiceOrderAllocation: Record "Service Order Allocation";
    begin
        ServiceOrderAllocation.Init();
        ResourceAllocations.GetRecord(ServiceOrderAllocation);
        ServiceOrderAllocation.Validate(
          "Resource No.", CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(ServiceOrderAllocation."Resource No.")));
        ServiceOrderAllocation.Validate("Allocation Date", WorkDate());
        ServiceOrderAllocation.Modify(true);

        LibraryVariableStorage.Enqueue(ServiceOrderAllocation."Entry No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FormHandlerCancelAllocation(var ReallocationEntryReasons: Page "Reallocation Entry Reasons"; var Response: Action)
    begin
        Response := ACTION::Yes;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FormHandlerRelAllocation(var CancelledAllocationReasons: Page "Cancelled Allocation Reasons"; var Response: Action)
    begin
        Response := ACTION::Yes;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerLookupOK(var ServiceItemComponentList: Page "Service Item Component List"; var Response: Action)
    var
        ServiceItemComponent: Record "Service Item Component";
    begin
        // Modal form handler. Return Action as LookupOK for first record found.
        ServiceItemComponent.SetRange("Parent Service Item No.", LibraryVariableStorage.DequeueText());
        ServiceItemComponent.FindFirst();
        ServiceItemComponentList.SetRecord(ServiceItemComponent);
        Response := ACTION::LookupOK;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PageHandlerServiceLines(var ServiceLines: TestPage "Service Lines")
    begin
        ServiceLines."Posting Date".AssertEquals(LibraryVariableStorage.DequeueDate());
        ServiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceItemWorksheetHandler(var ServiceItemWorksheet: TestPage "Service Item Worksheet")
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        CreateServiceLinesOnPage(ServiceItemWorksheet, ServiceLine.Type::" ", '');
        CreateServiceLinesOnPage(ServiceItemWorksheet, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
        CreateServiceLinesOnPage(ServiceItemWorksheet, ServiceLine.Type::" ", '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceItemWorksheetHandlerOneLine(var ServiceItemWorksheet: TestPage "Service Item Worksheet")
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        CreateServiceLinesOnPage(ServiceItemWorksheet, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceItemWorksheet_ValidateFaultReasonCode_MPH(var ServiceItemWorksheet: TestPage "Service Item Worksheet")
    begin
        ServiceItemWorksheet.ServInvLines."Fault Reason Code".SetValue(LibraryVariableStorage.DequeueText());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceItemWorksheet_EnableExcludeContractDiscount_MPH(var ServiceItemWorksheet: TestPage "Service Item Worksheet")
    begin
        ServiceItemWorksheet.ServInvLines."Exclude Contract Discount".SetValue(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceItemListHandler(var ServiceItemList: TestPage "Service Item List")
    var
        ServiceItemCardPage: TestPage "Service Item Card";
    begin
        ServiceItemCardPage.OpenNew();
        ServiceItemCardPage.Description.Activate();
        ServiceItemList.OK().Invoke();
        LibraryVariableStorage.Enqueue(ServiceItemCardPage."No.".Value); // Format required for Testpage variable.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesSequenceHandler(var ServiceLines: TestPage "Service Lines")
    begin
        // Verify sequence of Service Lines.
        repeat
            ServiceLines.Description.AssertEquals(LibraryVariableStorage.DequeueText());
        until ServiceLines.Next() = true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResGrAvailabilityServiceHandler(var ResGrAvailabilityService: TestPage "Res.Gr. Availability (Service)")
    var
        ViewBy: Option Day,Week,Month;
    begin
        ResGrAvailabilityService.PeriodType.SetValue(ViewBy::Month);
        ResGrAvailabilityService.ShowMatrix.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResGrAvailServMatrixHandler(var ResGrAvailServMatrix: TestPage "Res. Gr. Avail. (Serv.) Matrix")
    begin
        ResGrAvailServMatrix.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatisticsPageHandler(var ServiceStatistics: TestPage "Service Statistics")
    begin
        ServiceStatistics.SubForm.FILTER.SetFilter("VAT %", '0');
        ServiceStatistics.SubForm."Amount Including VAT".AssertEquals(ServiceStatistics.SubForm."Line Amount".Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderSubformPageHandler(var ServiceLines: TestPage "Service Lines")
    var
        ServiceItemNo: Variant;
        ItemNo: Variant;
        Counter: Integer;
    begin
        LibraryVariableStorage.Dequeue(ServiceItemNo);
        LibraryVariableStorage.Dequeue(ItemNo);
        ServiceLines."Service Item No.".AssertEquals(ServiceItemNo);
        ServiceLines."No.".AssertEquals(ItemNo);
        while ServiceLines.Next() do
            Counter := Counter + 1;
        Assert.AreEqual(1, Counter, StrSubstNo(ServiceLineErr, ServiceItemNo));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesValidateUnitPrice_MPH(var ServiceLines: TestPage "Service Lines")
    begin
        ServiceLines."Unit Price".SetValue(LibraryVariableStorage.DequeueDecimal());
        ServiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesValidateQuantity_MPH(var ServiceLines: TestPage "Service Lines")
    begin
        ServiceLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
        ServiceLines.OK().Invoke();
        LibraryVariableStorage.Enqueue(1); // dummy enqueue for handler call's count
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesNewLineWithExtendedText(var ServiceLines: TestPage "Service Lines")
    begin
        ServiceLines.New();
        ServiceLines."No.".SetValue(CreateStandardTextWithExtendedText());
        ServiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLinesNewLine_MPH(var ServiceLines: TestPage "Service Lines")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLines.New();
        ServiceLines.Type.SetValue(ServiceLine.Type::Item);
        ServiceLines."No.".SetValue(LibraryInventory.CreateItemNo());
        ServiceLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceQuoteLinesNewLine_MPH(var ServiceQuoteLines: TestPage "Service Quote Lines")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceQuoteLines.New();
        ServiceQuoteLines.Type.SetValue(ServiceLine.Type::Item);
        ServiceQuoteLines."No.".SetValue(LibraryInventory.CreateItemNo());
        ServiceQuoteLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetServiceShipmentLinesHandler(var GetServiceShipmentLines: TestPage "Get Service Shipment Lines")
    begin
        GetServiceShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InsertTravelFeePageHandler(var ServiceItemWorksheet: TestPage "Service Item Worksheet")
    var
        NoOfInsertFees: Variant;
        i: Integer;
        NoOfFeesToInsert: Integer;
    begin
        LibraryVariableStorage.Dequeue(NoOfInsertFees);
        NoOfFeesToInsert := NoOfInsertFees;
        for i := 1 to NoOfFeesToInsert do
            ServiceItemWorksheet.ServInvLines."Insert Travel Fee".Invoke();
    end;

    [ModalPageHandler]
    procedure ServiceQuoteLinesWithCatalogItem(var ServiceQuoteLines: TestPage "Service Quote Lines")
    var
        ServiceLine: Record "Service Line";
        NonStockItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(NonStockItemNo);
        ServiceQuoteLines.New();
        ServiceQuoteLines.Type.SetValue(ServiceLine.Type::Item);
        ServiceQuoteLines."No.".SetValue(NonStockItemNo);
        ServiceQuoteLines.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ExactMessageHandler(Message: Text)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NonstockItemListModalPageHandler(var NonstockItemList: TestPage "Catalog Item List")
    begin
        NonstockItemList.GotoKey(LibraryVariableStorage.DequeueText());
        NonstockItemList.OK().Invoke();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandlerWithCustVerification(var Notification: Notification): Boolean
    var
        ServCheckCreditLimit: Codeunit "Serv. Check Credit Limit";
    begin
        Assert.AreEqual(Notification.GetData('No.'), LibraryVariableStorage.DequeueText(), 'Customer No. was different than expected');
        ServCheckCreditLimit.ShowNotificationDetails(Notification);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AmountsOnCrLimitNotificationDetailsModalPageHandler(var CreditLimitNotification: TestPage "Credit Limit Notification")
    begin
        // Enqueue amounts from handler to verify in test body
        LibraryVariableStorage.Enqueue(CreditLimitNotification.CreditLimitDetails.OutstandingAmtLCY.Value);
        LibraryVariableStorage.Enqueue(CreditLimitNotification.CreditLimitDetails.TotalAmountLCY.Value);
    end;

    [RequestPageHandler]
    procedure ServiceOrderReportRequestPageHandler(var ServiceOrder: TestRequestPage "Service Order")
    begin
        ServiceOrder.Cancel().Invoke();
    end;
}


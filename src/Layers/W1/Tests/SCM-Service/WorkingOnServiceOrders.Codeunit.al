// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using System.TestLibraries.Utilities;
using Microsoft.Service.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.Contract;
using Microsoft.Service.History;
using Microsoft.Service.Comment;
using Microsoft.Service.Item;
using Microsoft.Inventory.Item;
using Microsoft.Service.Email;
using Microsoft.Service.Maintenance;
using Microsoft.Sales.Customer;
using Microsoft.Service.Pricing;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Setup;
using Microsoft.Inventory.Location;

codeunit 136112 "Working On Service Orders"
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
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        ServiceItemNoForReplacement: Code[20];
        StandServiceItemGroupCode: Code[10];
        IsInitialized: Boolean;
        ServiceItemError: Label 'The Service Mgt. Setup allows only one Service Item Line in each Service Header.';
        UnknownError: Label 'Unexpected Error.';
        StatusChangeError: Label 'You cannot change %1 to Finished in %2 %3.\\%4 %5 in %6 %7 line is preventing it.';
        QuoteStatusError: Label 'The Repair Status %1 cannot be used in service orders.';
        UnitPriceUpdationError: Label 'The %1 cannot be greater than the %2 set on the %3.';
        FaultResolCodesRlshipError: Label 'Occurence must be greater than 0.';
        NoOfLinesError: Label 'Number of lines must be %1.';
        ServiceCommentLineExistError: Label '%1 for %2 %3 must not exist.';
        UnexpectedFilterErr: Label 'Unexpected filter for ServiceHeader."No." when opened from %1 page';
        ExistErr: Label '%1 for %2 must not exist.';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the Report.', Comment = '%1 = Field Caption , %2 = Expected Value';
        ValueMustBlankErr: Label '%1 must blank.';
        DescriptionMustBeSame: Label 'Description must be same.';

    [Test]
    [Scope('OnPrem')]
    procedure CommentOnCopyCommentManual()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCommentLine: Record "Service Comment Line";
        SetupModified: Boolean;
    begin
        // Covers document number TC0152 - refer to TFS ID 21731.
        // Test No Comments Exist on Posted Service Shipment and Posted Service Invoice after Posting Service Order as Ship and Invoice with
        // "Copy Comments Order to Invoice" and "Copy Comments Order to Shpt." fields as False on Service Management Setup.

        // 1. Setup: Set "Copy Comments Order to Invoice" and "Copy Comments Order to Shpt." fields as False on Service Management Setup,
        // Create Service Order and Create Comments on Service Order.
        SetupModified := CreateServiceOrder(ServiceHeader, ServiceMgtSetup, false);

        // 2. Exercise: Post Service Order Partially as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify that the No Comments Exist on Posted Service Shipment and Posted Service Invoice.
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindFirst();
        ServiceCommentLine.SetRange("Table Name", ServiceCommentLine."Table Name"::"Service Shipment Header");
        ServiceCommentLine.SetRange("No.", ServiceShipmentHeader."No.");
        Assert.IsFalse(
          ServiceCommentLine.FindFirst(), StrSubstNo(ServiceCommentLineExistError, ServiceCommentLine.TableCaption(),
            ServiceShipmentHeader.TableCaption(), ServiceShipmentHeader."No."));

        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceCommentLine.SetRange("Table Name", ServiceCommentLine."Table Name"::"Service Invoice Header");
        ServiceCommentLine.SetRange("No.", ServiceInvoiceHeader."No.");
        Assert.IsFalse(
          ServiceCommentLine.FindFirst(), StrSubstNo(ServiceCommentLineExistError, ServiceCommentLine.TableCaption(),
            ServiceInvoiceHeader.TableCaption(), ServiceInvoiceHeader."No."));

        // 4. Teardown: Rollback "Copy Comments Order to Invoice" and "Copy Comments Order to Shpt." fields as True on Service Management
        // Setup.
        if SetupModified then
            ModifyServiceSetupCopyComment(ServiceMgtSetup, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CommentOnCopyCommentAutomatic()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceHeader: Record "Service Header";
        TempServiceCommentLine: Record "Service Comment Line" temporary;
        SetupModified: Boolean;
    begin
        // Covers document number TC0152 - refer to TFS ID 21731.
        // Test Comments on Posted Service Shipment and Posted Service Invoice after Posting Service Order as Ship and Invoice with
        // "Copy Comments Order to Invoice" and "Copy Comments Order to Shpt." fields as True on Service Management Setup.

        // 1. Setup: Set "Copy Comments Order to Invoice" and "Copy Comments Order to Shpt." fields as True on Service Management Setup,
        // Create Service Order and Create Comments on Service Order.
        SetupModified := CreateServiceOrder(ServiceHeader, ServiceMgtSetup, true);

        // 2. Exercise: Post Service Order Partially as Ship and Invoice.
        SaveComments(TempServiceCommentLine, ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify that the Comments on Posted Service Shipment and Posted Service Invoice are Comments on Service Order.
        VerifyCommentsOnPostedShipment(TempServiceCommentLine);
        VerifyCommentsOnPostedInvoice(TempServiceCommentLine);

        // 4. Teardown: Rollback "Copy Comments Order to Invoice" and "Copy Comments Order to Shpt." fields as False on Service Management
        // Setup.
        if SetupModified then
            ModifyServiceSetupCopyComment(ServiceMgtSetup, false);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerStandardCode')]
    [Scope('OnPrem')]
    procedure ServiceItemLinkServiceItemLine()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        SetupModified: Boolean;
    begin
        // Covers document number TC0151 - refer to TFS ID 21731.
        // Test Service Item No. on Service Line is Service Item No. on Service Item Line with "Link Service to Service Item" field
        // as True on Service Management Setup.

        // 1. Set "Link Service to Service Item" field as False on Service Management Setup, Create Standard Service Code, Create
        // Standard Service Line for Create Standard Service Code, Create Service Order - Service Header and Service Item Line,
        // Run Service Line Form.
        SetupModified := RunServiceLineForm(ServiceItemLine, ServiceMgtSetup, true);

        // 2. Verify: Verify that "Service Item No." on Service Line is Service Item No. on Service Item Line.
        ServiceLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceLine.FindFirst();
        ServiceLine.TestField("Service Item No.", ServiceItemLine."Service Item No.");

        // 3. Teardown: Rollback "Link Service to Service Item" field as True on Service Management Setup.
        if SetupModified then
            ModifySetupLinkServiceItem(ServiceMgtSetup, false);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerStandardCode')]
    [Scope('OnPrem')]
    procedure ServiceItemNoLinkServItemLine()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        SetupModified: Boolean;
    begin
        // Covers document number TC0151 - refer to TFS ID 21731.
        // Test Service Item No. blank on Service Line with "Link Service to Service Item" field as False on Service Management Setup.

        // 1. Set "Link Service to Service Item" field as False on Service Management Setup, Create Standard Service Code, Create
        // Standard Service Line for Create Standard Service Code, Create Service Order - Service Header and Service Item Line,
        // Run Service Line Form.
        SetupModified := RunServiceLineForm(ServiceItemLine, ServiceMgtSetup, false);

        // 2. Verify: Verify that "Service Item No." is blank on Service Line.
        ServiceLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceLine.FindFirst();
        ServiceLine.TestField("Service Item No.", '');

        // 3. Teardown: Rollback "Link Service to Service Item" field as True on Service Management Setup.
        if SetupModified then
            ModifySetupLinkServiceItem(ServiceMgtSetup, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneServiceItemLinePerOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number TC0150 - refer to TFS ID 21731.
        // Test error occurs on entering second Service Item Line with "One Service Item Line/Order" field True on Service Management Setup.

        // 1. Setup: Set "One Service Item Line/Order" field True on Service Management Setup.
        Initialize();
        SetOneServiceItemLinePerOrder(true);

        // 2. Exercise: Create Service Order with One Service Item Line.
        CreateServiceOrderWithOneLine(ServiceHeader, ServiceItemLine);

        // 3. Verify: Verify that Service Order Shows error "One Service Item Line per Order" on creation of second Service Item Line.
        asserterror LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        Assert.AreEqual(StrSubstNo(ServiceItemError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoServiceItemLinePerOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number TC0150 - refer to TFS ID 21731.
        // Test second Service Item Line Successfully Created with "One Service Item Line/Order" field False on Service Management Setup.

        // 1. Setup: Set "One Service Item Line/Order" field False on Service Management Setup.
        Initialize();
        SetOneServiceItemLinePerOrder(false);

        // 2. Exercise: Create Service Order with One Service Item Line.
        CreateServiceOrderWithOneLine(ServiceHeader, ServiceItemLine);

        // 3. Verify: Verify that the Second Service Item Line Successfully Created without any Error.
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        Assert.AreEqual(ServiceItemLine.Count, 2, StrSubstNo(NoOfLinesError, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneServiceItemLineAfterShip()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        Item: Record Item;
    begin
        // Covers document number TC0150 - refer to TFS ID 21731.
        // Test error occurs on entering second Service Item Line after Posting Service Order as Ship with "One Service Item Line/Order"
        // field True on Service Management Setup.

        // 1. Setup: Create Service Order with One Service Item Line.
        Initialize();
        CreateServiceOrderWithOneLine(ServiceHeader, ServiceItemLine);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
        UpdateQuantityOnServiceLine(ServiceLine, ServiceItemLine."Line No.");

        // 2. Exercise: Post Service Order with Ship Option, Set "One Service Item Line/Order" field True on Service Management Setup.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        SetOneServiceItemLinePerOrder(true);

        // 3. Verify: Verify that Service Order Shows error "One Service Item Line per Order" on creation of second Service Item Line.
        Clear(ServiceItemLine);
        asserterror LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        Assert.AreEqual(StrSubstNo(ServiceItemError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure CreateServiceContractOrdersOneItemPerOrder()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServicePeriodFormula: DateFormula;
        I: Integer;
    begin
        // [SCENARIO] "Create Contract Service Orders" creates separate order for each item if "One Service Item Line/Order" toggle in Service Mgt. Setup is on.

        Initialize();

        // [GIVEN] Enable the "One Service Item Line/Order" setting in Service Mgt. Setup
        SetOneServiceItemLinePerOrder(true);

        // [GIVEN] Create and sign a service contract with 3 service items
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, Enum::"Service Contract Type"::Contract, Customer."No.");

        Evaluate(ServicePeriodFormula, '<1M>');
        for I := 1 to 3 do begin
            Clear(ServiceItem);
            LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
            LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

            ServiceContractLine.Validate("Line Value", LibraryRandom.RandIntInRange(300, 500));
            ServiceContractLine.Validate("Line Cost", LibraryRandom.RandIntInRange(100, 200));
            ServiceContractLine.Validate("Next Planned Service Date", WorkDate());
            ServiceContractLine.Validate("Service Period", ServicePeriodFormula);
            ServiceContractLine.Modify(true);
        end;

        ServiceContractLine.UpdateContractAnnualAmount(false);
        LibraryService.SignContract(ServiceContractHeader, true);

        // [WHEN] Run the "Create Contract Service Orders" job
        ServiceContractHeader.SetRecFilter();
        CreateContractServiceOrders(ServiceContractHeader);

        // [THEN] 3 service orders are created, each with one service item line.
        ServiceHeader.SetRange("Document Type", Enum::"Service Document Type"::Order);
        ServiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        Assert.RecordCount(ServiceHeader, 3);

        ServiceHeader.FindSet();
        repeat
            ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
            ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
            Assert.RecordCount(ServiceItemLine, 1);
        until ServiceHeader.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure EmailQueueWithStatusChange()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceEmailQueue: Record "Service Email Queue";
    begin
        // Covers document number TC0149 - refer to TFS ID 21731.
        // Test Email Queue entries after Status change with "Notify Customer" value "By E-Mail" on Service Order.

        // 1. Setup: Create Service Order, Set "Notify Customer" value on Service Header.
        CreateServiceOrderWithNotify(ServiceHeader, ServiceItemLine);

        // 2. Exercise: Change Status on Service Header to Finished, Change Status on Service Header to "In Process" and again Change to
        // Finished.
        UpdateStatusOnServiceHeader(ServiceHeader, ServiceHeader.Status::Finished);
        UpdateStatusOnServiceHeader(ServiceHeader, ServiceHeader.Status::"In Process");
        UpdateStatusOnServiceHeader(ServiceHeader, ServiceHeader.Status::Finished);

        // 3. Verify: Verify that the Service Email Queue Entries Created.
        ServiceEmailQueue.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceEmailQueue.SetRange("Document No.", ServiceHeader."No.");
        Assert.AreEqual(ServiceEmailQueue.Count, 2, StrSubstNo(NoOfLinesError, 2));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure EmailRepairStatusChange()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceEmailQueue: Record "Service Email Queue";
        RepairStatus: Record "Repair Status";
    begin
        // Covers document number TC0149 - refer to TFS ID 21731.
        // Test Email Queue entries after Repair Status Code change on Service Item Line with "Notify Customer" value "By E-Mail" on
        // Service Order.

        // 1. Setup: Create Service Order, Set "Notify Customer" value on Service Header.
        CreateServiceOrderWithNotify(ServiceHeader, ServiceItemLine);
        CreateRepairStatusCodeFinish(RepairStatus);

        // 2. Exercise: Change Repair Status Code on Service Item Line to Finished.
        ServiceItemLine.Validate("Repair Status Code", RepairStatus.Code);
        ServiceItemLine.Modify(true);

        // 3. Verify: Verify that the Service Email Queue Entry Created.
        ServiceEmailQueue.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceEmailQueue.SetRange("Document No.", ServiceHeader."No.");
        ServiceEmailQueue.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StatusChangeToPending()
    var
        RepairStatus: Record "Repair Status";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number TC0148 - refer to TFS ID 21731.
        // Test Status on Service Header is Pending after changing Repair Status Code on first Service Item Line to Finished.

        // 1. Setup: Create Service Order with Three Service Item Lines with Service Item No., Item No. and Description.
        RepairStatusInitial(ServiceHeader, ServiceItemLine);
        CreateRepairStatusCodeFinish(RepairStatus);

        // 2. Exercise: Change Repair Status Code on First Service Item Line to Finished.
        UpdateRepairStatusOnFirstLine(ServiceHeader, RepairStatus.Code);

        // 3. Verify: Verify Status on Service Header is Pending.
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        ServiceHeader.TestField(Status, ServiceHeader.Status::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StatusChangeToFinished()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number TC0148 - refer to TFS ID 21731.
        // Test Status on Service Header is Finished after changing Repair Status Code on all Service Item Line to Finished.

        // 1. Setup: Create Service Order with Three Service Item Lines with Service Item No., Item No. and Description.
        RepairStatusInitial(ServiceHeader, ServiceItemLine);

        // 2. Exercise: Change Repair Status Code on All Service Item Line to Finished.
        UpdateRepairStatusFinished(ServiceItemLine);

        // 3. Verify: Verify Status on Service Header is Finished.
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        ServiceHeader.TestField(Status, ServiceHeader.Status::Finished);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RepairStatusChangeToPartly()
    var
        RepairStatus: Record "Repair Status";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number TC0148 - refer to TFS ID 21731.
        // Test Status on Service Header is Pending after changing Repair Status Code on first Service Item Line to Partly Served.

        // 1. Setup: Create Service Order with Three Service Item Lines with Service Item No., Item No. and Description,
        // Change Repair Status Code on All Service Item Line to Finished.
        RepairStatusInitial(ServiceHeader, ServiceItemLine);
        UpdateRepairStatusFinished(ServiceItemLine);

        // 2. Exercise: Change Repair Status Code on First Service Item Line to Partial.
        Clear(RepairStatus);
        CreateRepairStatusCodePartial(RepairStatus);
        UpdateRepairStatusOnFirstLine(ServiceHeader, RepairStatus.Code);

        // 3. Verify: Verify Status on Service Header is Pending.
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        ServiceHeader.TestField(Status, ServiceHeader.Status::Pending);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StatusChangeToInProcess()
    var
        RepairStatus: Record "Repair Status";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number TC0148 - refer to TFS ID 21731.
        // Test Status on Service Header is "In Process" after changing Repair Status Code on first Service Item Line to "In Process".

        // 1. Setup: Create Service Order with Three Service Item Lines with Service Item No., Item No. and Description,
        // Change Repair Status Code on All Service Item Line to Finished.
        RepairStatusInitial(ServiceHeader, ServiceItemLine);
        UpdateRepairStatusFinished(ServiceItemLine);

        // 2. Exercise: Change Repair Status Code on First Service Item Line to "In Process".
        CreateRepairStatusInProcess(RepairStatus);
        UpdateRepairStatusOnFirstLine(ServiceHeader, RepairStatus.Code);

        // 3. Verify: Verify Status on Service Header is "In Process".
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        ServiceHeader.TestField(Status, ServiceHeader.Status::"In Process");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RepairCodeManualStatusChange()
    var
        RepairStatus: Record "Repair Status";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number TC0148 - refer to TFS ID 21731.
        // Test Status on Service Header is "In Process" after changing Repair Status Code on second Service Item Line to "In Process" after
        // Changing Status on Service Header to Finished.

        // 1. Setup: Create Service Order with Three Service Item Lines with Service Item No., Item No. and Description,
        // Change Status on Service Header to finished.
        RepairStatusInitial(ServiceHeader, ServiceItemLine);
        UpdateStatusOnServiceHeader(ServiceHeader, ServiceHeader.Status::Finished);

        // 2. Exercise: Change Repair Status Code on Second Service Item Line to "In Process".
        CreateRepairStatusInProcess(RepairStatus);
        UpdateRepairStatusOnSecondLine(ServiceHeader, RepairStatus.Code);

        // 3. Verify: Verify Status on Service Header is "In Process".
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        ServiceHeader.TestField(Status, ServiceHeader.Status::"In Process");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StatusChangeToOnHold()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number TC0148 - refer to TFS ID 21731.
        // Test Status on Service Header is "On Hold" after changing Repair Status Code on all Service Item Line to "Spare Part" after
        // Changing Status on Service Header to Finished.

        // 1. Setup: Create Service Order with Three Service Item Lines with Service Item No., Item No. and Description,
        // Change Status on Service Header to Finished.
        RepairStatusInitial(ServiceHeader, ServiceItemLine);
        UpdateStatusOnServiceHeader(ServiceHeader, ServiceHeader.Status::Finished);

        // 2. Exercise: Change Repair Status Code on All Service Item Line to "Spare Part".
        UpdateRepairStatusSparePart(ServiceItemLine);

        // 3. Verify: Verify Status on Service Header is "On Hold".
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        ServiceHeader.TestField(Status, ServiceHeader.Status::"On Hold");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StatusNotChangeToFinished()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number TC0148 - refer to TFS ID 21731.
        // Test error occurs on changing Status on Service Header to Finished after changing Repair Status to "Spare Part" on all Service
        // Item Lines.

        // 1. Setup: Create Service Order with Three Service Item Lines with Service Item No., Item No. and Description.
        RepairStatusInitial(ServiceHeader, ServiceItemLine);

        // 2. Exercise: Change Repair Status Code on All Service Item Line to "Spare Part".
        UpdateRepairStatusSparePart(ServiceItemLine);

        // 3. Verify: Verify that Service Order shows Error "Status Cannot be Change" on changing the Status on Service Header to Finished.
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.FindFirst();
        asserterror UpdateStatusOnServiceHeader(ServiceHeader, ServiceHeader.Status::Finished);
        Assert.AreEqual(
          StrSubstNo(StatusChangeError, ServiceHeader.FieldCaption(Status), ServiceHeader.TableCaption(), ServiceHeader."No.",
            ServiceItemLine.FieldCaption("Repair Status Code"), ServiceItemLine."Repair Status Code", ServiceItemLine.TableCaption(),
            ServiceItemLine."Line No."), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RepairStatusChangeToQuote()
    var
        RepairStatus: Record "Repair Status";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number TC0148 - refer to TFS ID 21731.
        // Test error occurs on changing Repair Status to Quote on Service Item Line.

        // 1. Setup: Create Service Order with Three Service Item Lines with Service Item No., Item No. and Description.
        RepairStatusInitial(ServiceHeader, ServiceItemLine);

        // 2. Exercise: Change Repair Status Code on All Service Item Line to "Spare Part".
        UpdateRepairStatusSparePart(ServiceItemLine);

        // 3. Verify: Verify that Error "Quote Cannot be used" occurs on Changing Repair Status Code on Service Item Line to Quote.
        CreateRepairStatusQuote(RepairStatus);
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.FindFirst();
        asserterror ServiceItemLine.Validate("Repair Status Code", RepairStatus.Code);
        Assert.AreEqual(StrSubstNo(QuoteStatusError, RepairStatus.Code), GetLastErrorText, UnknownError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RepairStatusToInProcess()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number TC0148 - refer to TFS ID 21731.
        // Test Status on Service Header is "In Process" after changing Repair Status Code on all Service Item Line to "Spare Part" after
        // Changing Repair Status Code to Blank on all Service Item Lines.

        // 1. Setup: Create Service Order with Three Service Item Lines with Service Item No., Item No. and Description,
        // Change Repair Status Code on All Service Item Line to "Spare Part".
        RepairStatusInitial(ServiceHeader, ServiceItemLine);
        UpdateRepairStatusSparePart(ServiceItemLine);

        // 2. Exercise: Change Repair Status Code on All Service Item Line to Blank, change Repair Status Code on All Service Item Line to
        // "In Process".
        UpdateRepairStatusBlank(ServiceItemLine);
        UpdateRepairStatusInProcess(ServiceItemLine);

        // 3. Verify: Verify Status on Service Header is "In Process".
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        ServiceHeader.TestField(Status, ServiceHeader.Status::"In Process");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineStartingFee()
    var
        CostType: Option Travel,Support,Other;
    begin
        // Covers document number TC0147 - refer to TFS ID 21731.
        // Test values on Service Line after running Insert Fee with Service Cost Type Other.

        ServiceLineInsertFee(CostType::Other);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineTravelFee()
    var
        CostType: Option Travel,Support,Other;
    begin
        // Covers document number TC0147 - refer to TFS ID 21731.
        // Test values on Service Line after running Insert Fee with Service Cost Type Travel.

        ServiceLineInsertFee(CostType::Travel);
    end;

    local procedure ServiceLineInsertFee(CostType: Option Travel,Support,Other)
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        ServiceZone: Record "Service Zone";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServOrderManagement: Codeunit ServOrderManagement;
    begin
        // 1. Setup: Create Service Cost with Cost Type, Create a new Service Order - Service Header and Service Line.
        Initialize();
        Customer.Get(CreateCustomer());
        LibraryService.CreateServiceZone(ServiceZone);
        Customer.Validate("Service Zone Code", ServiceZone.Code);
        Customer.Modify(true);
        if CostType = CostType::Travel then
            CreateServiceCost(ServiceCost, ServiceCost."Cost Type"::Travel, Customer."Service Zone Code")
        else begin
            CreateServiceCost(ServiceCost, ServiceCost."Cost Type"::Other, '');
            ServiceMgtSetup.Get();
            ServiceMgtSetup.Validate("Service Order Starting Fee", ServiceCost.Code);
            ServiceMgtSetup.Modify(true);
        end;

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceLine.Validate("Document Type", ServiceHeader."Document Type");
        ServiceLine.Validate("Document No.", ServiceHeader."No.");

        // 2. Exercise: Add fee to the Service Line by Insert Starting Fee function.
        ServiceLine.Init();
        if CostType = CostType::Travel then
            ServOrderManagement.InsertServCost(ServiceLine, 0, false)
        else
            ServOrderManagement.InsertServCost(ServiceLine, 1, false);

        // 3. Verify: Verify that the values on the Service Line correspond to the values of the Service cost validated in the
        // Service Mgt. Setup.
        VerifyInsertFeeOnServiceLine(ServiceHeader, ServiceCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SplitServiceLineTypeItem()
    var
        Customer: Record Customer;
        ServiceCost: Record "Service Cost";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC0146 - refer to TFS ID 21731.
        // Test error occurs on running Split Resource Line with Type Item, Cost and G/L Account.

        // 1. Setup: Create Service Order with Service Item Line with Description.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        // 2. Exercise: Create Service Line with Type Item, Cost and G/L Account.
        LibraryService.FindServiceCost(ServiceCost);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        UpdateQuantityOnServiceLine(ServiceLine, ServiceItemLine."Line No.");

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code);
        UpdateQuantityOnServiceLine(ServiceLine, ServiceItemLine."Line No.");

        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        UpdateQuantityOnServiceLine(ServiceLine, ServiceItemLine."Line No.");
        Commit();

        // 3. Verify: Verify that Shows Error "Type must be Resource" on Split Resource line for all Service Lines.
        VerifySplitLineError(ServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure SplitServiceLineTypeResource()
    var
        Resource: Record Resource;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        LibraryResource: Codeunit "Library - Resource";
    begin
        // Covers document number TC0146 - refer to TFS ID 21731.
        // Test Split Resource Line on Service Line with Type Resource.

        // 1. Setup: Create Service Order with Two Service Item Line, Create Service Line with Type Resource.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryResource.FindResource(Resource);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.");
        UpdateQuantityOnServiceLine(ServiceLine, ServiceItemLine."Line No.");

        // 2. Exercise: Split Service Line.
        ServiceLine.SplitResourceLine();

        // 3. Verify: Verify that the Service Line Splited.
        VerifySplitLines(ServiceLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure SplitServiceLineAfterPosting()
    var
        Resource: Record Resource;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        LibraryResource: Codeunit "Library - Resource";
    begin
        // Covers document number TC0146 - refer to TFS ID 21731.
        // Test error occurs on running Split Resource Line after Posting Service Order as Ship.

        // 1. Setup: Create Service Order with Two Service Item Line, Create Service Line with Type Resource.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryResource.FindResource(Resource);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.");
        UpdateQuantityOnServiceLine(ServiceLine, ServiceItemLine."Line No.");

        // 2. Exercise: Split Service Line, Post Service Order as Ship.
        ServiceLine.SplitResourceLine();
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify that the Service Line Shows error "Quantity Shipped must be Zero" on Split Service Line.
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        asserterror ServiceLine.SplitResourceLine();
        Assert.ExpectedTestFieldError(ServiceLine.FieldCaption(Quantity), Format(0));
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler')]
    [Scope('OnPrem')]
    procedure UnitPriceSplitServiceLine()
    var
        Customer: Record Customer;
        Resource: Record Resource;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        LibraryResource: Codeunit "Library - Resource";
    begin
        // Covers document number TC0146 - refer to TFS ID 21731.
        // Test error occurs on updation Unit Price on Service Line greater than "Max. Labor Unit Price" on Service Header.

        // 1. Setup: Create Service Order with Two Service Item Line, Create Service Line with Type Resource.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryResource.FindResource(Resource);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceHeader.Validate("Max. Labor Unit Price", Resource."Unit Price" + LibraryRandom.RandInt(20));  // Use Random because value is not important.
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.");
        UpdateQuantityOnServiceLine(ServiceLine, ServiceItemLine."Line No.");

        // 2. Exercise: Split Service Line.
        ServiceLine.SplitResourceLine();

        // 3. Verify: Verify the Unit Price and Quantity on Splitted Service Line and shows error "Cannot be Greater" on entering
        // Unit Price value on Service Line Greater than "Max. Labor Unit Price" on service Header.
        VerifyUnitPrice(ServiceHeader, ServiceLine.Quantity, Resource."Unit Price");

        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        asserterror ServiceLine.Validate("Unit Price", ServiceHeader."Max. Labor Unit Price" + LibraryRandom.RandInt(10));
        Assert.AreEqual(
          StrSubstNo(
            UnitPriceUpdationError, ServiceLine.FieldCaption("Unit Price"),
            ServiceHeader.FieldCaption("Max. Labor Unit Price"),
            ServiceHeader.TableCaption()), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemCreated()
    var
        ServiceItem: Record "Service Item";
        ServiceItem2: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Covers document number TC0145 - refer to TFS ID 21731.
        // Test Service Item created after Posting Service Order as Ship with Service Item having Service Item Group with create New Service
        // Item True.

        // 1. Setup: Select Service Item Having Service Item Group Code with Create New Service Item True, Create Service Order.
        Initialize();
        SelectServiceItem(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ServiceItem."Item No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);
        ServiceLine.Validate("No.", ServiceItem."Item No.");
        ServiceLine.Modify(true);

        // 2. Exercise: Post Service Order as Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify that New Service Item Created.
        ServiceItem2.SetFilter("No.", '<>%1', ServiceItem."No.");
        ServiceItem2.SetRange("Item No.", ServiceItem."Item No.");
        ServiceItem2.SetRange("Customer No.", ServiceItem."Customer No.");
        ServiceItem2.SetRange(Status, ServiceItem2.Status::"Temporarily Installed");
        ServiceItem2.FindFirst();
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler,StringMenuHandler,ModalFormHandlerLookupOK')]
    [Scope('OnPrem')]
    procedure ServiceItemCompReplacement()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItemComponent: Record "Service Item Component";
        ParentServiceItemNo: Code[20];
    begin
        // Covers document number TC0145 - refer to TFS ID 21731.
        // Test Replaced Component on Service Item Component after Posting Service Order as Ship.

        // 1. Create Service Order, Create Service Item from Service Order, Create Service Item Components, Create Service Line with
        // "Item No." on Second Service Item Line choose "Replace Component", Post Service Order as Ship.
        CreateAndPostServiceOrder(ServiceItemLine, ParentServiceItemNo, 1);

        // 2. Verify: Verify that the First Service Item Component Replaced and Replaced Component with Active False.
        ServiceItemComponent.SetRange("Parent Service Item No.", ServiceItemNoForReplacement);
        ServiceItemComponent.SetRange(Active, true);
        ServiceItemComponent.FindFirst();
        ServiceItemComponent.TestField(Type, ServiceItemComponent.Type::Item);
        ServiceItemComponent.TestField("No.", ServiceItemLine."Item No.");

        ServiceItemComponent.SetRange(Active, false);
        ServiceItemComponent.FindFirst();
        ServiceItemComponent.TestField(Type, ServiceItemComponent.Type::"Service Item");
        ServiceItemComponent.TestField("No.", ServiceItemLine."Service Item No.");
        ServiceItemComponent.TestField("Service Order No.", ServiceItemLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmMessageHandler,MessageHandler,StringMenuHandlerForNew')]
    [Scope('OnPrem')]
    procedure NewServiceItemCompCreation()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItemComponent: Record "Service Item Component";
        Quantity: Decimal;
        ParentServiceItemNo: Code[20];
    begin
        // Covers document number TC0145 - refer to TFS ID 21731.
        // Test New Component on Service Item Component after Posting Service Order as Ship.

        // 1. Create Service Order, Create Service Item from Service Order, Create Service Item Components, Create Service Line with
        // "Item No." on Second Service Item Line choose "New Component", Post Service Order as Ship.
        Quantity := LibraryRandom.RandInt(10);
        CreateAndPostServiceOrder(ServiceItemLine, ParentServiceItemNo, Quantity);

        // 2. Verify: Verify that the New Service Item Component Created.
        ServiceItemComponent.SetRange("Parent Service Item No.", ParentServiceItemNo);
        ServiceItemComponent.SetRange(Active, true);
        ServiceItemComponent.SetRange(Type, ServiceItemComponent.Type::Item);
        Assert.AreEqual(ServiceItemComponent.Count, Quantity, StrSubstNo(NoOfLinesError, Quantity));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RepairStatusServiceQuote()
    var
        RepairStatus: Record "Repair Status";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number TC0144 - refer to TFS ID 21731.
        // Test Repair Status Code on Service Item Line Successfully changed to Quote on Service Quote.

        // 1. Setup: Create Service Header with Document Type Quote.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, CreateCustomer());
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");

        // 2. Exercise: Create Service Item Line with Service Item No., Change Repair Status Code on Service Item Line to Initial.
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        UpdateRepairStatusInitial(ServiceItemLine);

        // 3. Verify: Verify that Repair Status Code on Service Item Line to Quote is Successfully Changed.
        CreateRepairStatusQuote(RepairStatus);
        ServiceItemLine.Validate("Repair Status Code", RepairStatus.Code);
        ServiceItemLine.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RepairStatusToWaitCustomer()
    var
        RepairStatus: Record "Repair Status";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number TC0144 - refer to TFS ID 21731.
        // Test Repair Status Code on Service Item Line Successfully changed to "Wait Customer".

        // 1. Create Service Header with Document Type Order, Create Service Item Line with Service Item No., Change Repair Status
        // Code on Service Item Line to Initial.
        RepairStatusInitial(ServiceHeader, ServiceItemLine);

        // 2. Verify: Verify that Repair Status Code on Service Item Line to "Wait Customer" is Successfully Changed.
        CreateRepairStatusWaitCustomer(RepairStatus);
        ServiceItemLine.Validate("Repair Status Code", RepairStatus.Code);
        ServiceItemLine.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FaultCodeOnPostedDocument()
    var
        TempServiceItemLine: Record "Service Item Line" temporary;
    begin
        // Covers document number TC0144 - refer to TFS ID 21731.
        // Test Symptom Code and Resolution Code on Posted Service Shipment and Posted Service Invoice after Posting Service Order as Ship
        // and Invoice.

        // 1. Create Service Order, Create Fault Code and Resolution Code, Update Fault Area Code, Fault Code, Symptom Code
        // and Resolution Code on Service Item Line, Post Service Order as Ship and Invoice.
        PostServiceOrderFaultCode(TempServiceItemLine);

        // 2. Verify: Verify Symptom Code and Resolution Code on Posted Service Shipment and Posted Service Invoice.
        VerifyFaultCodePostedShipment(TempServiceItemLine);
        VerifyFaultCodeOnPostedInvoice(TempServiceItemLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FaultResolutionRelation()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        TempServiceItemLine: Record "Service Item Line" temporary;
        FaultCode: Record "Fault Code";
        FaultResolRelationCalculate: Codeunit "FaultResolRelation-Calculate";
    begin
        // Covers document number TC0144 - refer to TFS ID 21731.
        // Test Fault/Resolution Relationships entries after running Insert Fault/Resolution Relationships.

        // 1. Setup: Create Service Order, Create Fault Code and Resolution Code, Update Fault Area Code, Fault Code, Symptom Code
        // and Resolution Code on Service Item Line, Post Service Order as Ship and Invoice.
        PostServiceOrderFaultCode(TempServiceItemLine);

        // 2. Exercise: Create New Service Order with Same values on Service Item Line as on Previous Service Order,
        // Run Insert Fault/Resolution Relationships.
        Clear(ServiceHeader);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, TempServiceItemLine."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, TempServiceItemLine."Service Item No.");
        FaultCode.Get(TempServiceItemLine."Fault Area Code", TempServiceItemLine."Symptom Code", TempServiceItemLine."Fault Code");
        UpdateFaultResolution(ServiceItemLine, FaultCode, TempServiceItemLine."Resolution Code");

        FaultResolRelationCalculate.CopyResolutionRelationToTable(WorkDate(), WorkDate(), true, true);

        // 3. Verify: Verify Fault/Resolution Relationships Entry from Second Order.
        VerifyFaultResolutionRelation(TempServiceItemLine);
    end;

    [Test]
    [HandlerFunctions('UpdateQuantityPageHandler,BatchPostServiceOrdersHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OrdersBatchPostWithStatus()
    var
        SalesAndReceivablesSetup: Record "Sales & Receivables Setup";
        No: Code[20];
        No2: Code[20];
        PostingDate: Date;
    begin
        // Test the functionality of Batch Post Service Orders and verify that no Service Order exist for Status In Process and posted date.

        // 1. Setup: Create multiple Service Orders.
        Initialize();
        SalesAndReceivablesSetup.Get();
        LibrarySales.SetStockoutWarning(false);
        No := CreateServiceOrderWithPage();
        No2 := CreateServiceOrderWithPage();
        Commit();

        // 2. Exercise: Run the Batch Post Service Orders with any random date greater than WORKDATE through the handler.
        BatchPostOrders(No, No2);

        // 3. Verify: Verify that no Service Order exist for the Status In Process and the posted date.
        PostingDate := LibraryVariableStorage.DequeueDate();
        VerifyServiceOrdersStatus(No, PostingDate);
        VerifyServiceOrdersStatus(No2, PostingDate);

        // 4. Tear Down: Restore the original value of Stockout Warning.
        LibrarySales.SetStockoutWarning(SalesAndReceivablesSetup."Stockout Warning");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('UpdateQuantityPageHandler,BatchPostServiceOrdersHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrdersBatchPost()
    var
        SalesAndReceivablesSetup: Record "Sales & Receivables Setup";
        No: Code[20];
        No2: Code[20];
        PostingDate: Date;
    begin
        // Test the functionality of Batch Post Service Orders and verify that Posted Service Invoices exist for the Posting Date.

        // 1. Setup: Create multiple Service Orders.
        Initialize();
        SalesAndReceivablesSetup.Get();
        LibrarySales.SetStockoutWarning(false);
        No := CreateServiceOrderWithPage();
        No2 := CreateServiceOrderWithPage();
        SetBlueLocation(No, No2);
        Commit();

        // 2. Exercise: Run the Batch Post Service Orders with a random date greater than WORKDATE through the handler.
        BatchPostOrders(No, No2);

        // 3. Verify: Verify that Posted Service Invoice exist for the Posting Date.
        PostingDate := LibraryVariableStorage.DequeueDate();
        VerifyPostedServiceInvoice(No, PostingDate);
        VerifyPostedServiceInvoice(No2, PostingDate);

        // 4. Tear Down: Restore the original value of Stockout Warning.
        LibrarySales.SetStockoutWarning(SalesAndReceivablesSetup."Stockout Warning");
    end;

    [Test]
    [HandlerFunctions('BatchPostServiceOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrdersFiltersExposedIntoBatchPost()
    var
        ServiceHeader: array[3] of Record "Service Header";
        ServiceOrders: TestPage "Service Orders";
        ServiceOrder: TestPage "Service Order";
        Index: Integer;
        RangeText: Text;
    begin
        // [FEATURE] [UT] [UI] [Batch Post]
        // [SCENARIO 287474] Service Orders and Service Order pages filters are inherited into the "Batch Post Service Orders" report.
        Initialize();

        for Index := 1 to ArrayLen(ServiceHeader) do begin
            ServiceHeader[Index].Init();
            ServiceHeader[Index]."No." := LibraryUtility.GenerateGUID();
            ServiceHeader[Index].Status := ServiceHeader[Index].Status::Finished;
            ServiceHeader[Index].Insert();
        end;
        RangeText := StrSubstNo('%1..%2', ServiceHeader[1]."No.", ServiceHeader[ArrayLen(ServiceHeader)]."No.");

        Commit();
        ServiceOrders.OpenEdit();
        ServiceOrders.FILTER.SetFilter("No.", RangeText);
        ServiceOrders.PostBatch.Invoke();
        Assert.AreEqual(RangeText, LibraryVariableStorage.DequeueText(), StrSubstNo(UnexpectedFilterErr, ServiceOrders.Caption));
        ServiceOrders.Close();

        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", RangeText);
        ServiceOrder.PostBatch.Invoke();
        Assert.AreEqual(RangeText, LibraryVariableStorage.DequeueText(), StrSubstNo(UnexpectedFilterErr, ServiceOrder.Caption));
        ServiceOrder.Close();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CopyCommentLines_CreditMemo_WithQuote()
    var
        ServiceHeader: Record "Service Header";
        ServiceCommentLine: Record "Service Comment Line";
        ServOrderManagement: Codeunit ServOrderManagement;
        DocumentNo: Code[20];
        NewDocumentNo: Code[20];
        NewTableNameOption: Enum "Service Comment Table Name";
        CommentTxt: Text[80];
    begin
        // [FEATURE] [UT] [Service] [Comments]
        // [SCENARIO 257848] UT ServOrderManagement.CopyCommentLines for Service Credit Memo when there is Service Quote with the same Document No. and both do have comments.
        Initialize();

        CreateTwoServiceCommentLinesForDocs(
          ServiceHeader."Document Type"::Quote,
          ServiceHeader."Document Type"::"Credit Memo",
          DocumentNo, CommentTxt);

        NewDocumentNo := LibraryUtility.GenerateGUID();
        NewTableNameOption := ServiceCommentLine."Table Name"::"Service Cr.Memo Header";

        ServOrderManagement.CopyCommentLines(
          ServiceCommentLine."Table Name"::"Service Header".AsInteger(),
          NewTableNameOption.AsInteger(), DocumentNo, NewDocumentNo);

        VerifyServiceCommentLineExists(NewTableNameOption, 0, NewDocumentNo, CommentTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CopyCommentLines_Order_WithCreditMemo()
    var
        ServiceHeader: Record "Service Header";
        ServiceCommentLine: Record "Service Comment Line";
        ServOrderManagement: Codeunit ServOrderManagement;
        DocumentNo: Code[20];
        NewDocumentNo: Code[20];
        NewTableNameOption: Enum "Service Comment Table Name";
        CommentTxt: Text[80];
    begin
        // [FEATURE] [UT] [Service] [Comments]
        // [SCENARIO 257848] UT ServOrderManagement.CopyCommentLines for Service Order when there is Service Credit Memo with the same Document No. and both do have comments.
        Initialize();

        CreateTwoServiceCommentLinesForDocs(
          ServiceHeader."Document Type"::"Credit Memo",
          ServiceHeader."Document Type"::Order,
          DocumentNo, CommentTxt);

        NewDocumentNo := LibraryUtility.GenerateGUID();
        NewTableNameOption := ServiceCommentLine."Table Name"::"Service Shipment Header";

        ServOrderManagement.CopyCommentLines(
          ServiceCommentLine."Table Name"::"Service Header".AsInteger(),
          NewTableNameOption.AsInteger(), DocumentNo, NewDocumentNo);

        VerifyServiceCommentLineExists(NewTableNameOption, 0, NewDocumentNo, CommentTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CopyCommentLinesWithSubType_Order_WithInvoice()
    var
        ServiceHeader: Record "Service Header";
        ServiceCommentLine: Record "Service Comment Line";
        ServOrderManagement: Codeunit ServOrderManagement;
        DocumentNo: Code[20];
        NewDocumentNo: Code[20];
        NewTableNameOption: Enum "Service Comment Table Name";
        CommentTxt: Text[80];
    begin
        // [FEATURE] [UT] [Service] [Comments]
        // [SCENARIO 257848] UT ServOrderManagement.CopyCommentLinesWithSubType for Service Invoice when there is Service Order with the same Document No. and both do have comments.
        Initialize();

        CreateTwoServiceCommentLinesForDocs(
          ServiceHeader."Document Type"::Invoice,
          ServiceHeader."Document Type"::Order,
          DocumentNo, CommentTxt);

        NewDocumentNo := LibraryUtility.GenerateGUID();
        NewTableNameOption := ServiceCommentLine."Table Name"::"Service Invoice Header";

        ServOrderManagement.CopyCommentLinesWithSubType(
          ServiceCommentLine."Table Name"::"Service Header".AsInteger(),
          NewTableNameOption.AsInteger(), DocumentNo, NewDocumentNo,
          ServiceCommentLine."Table Subtype"::"1".AsInteger());

        VerifyServiceCommentLineExists(NewTableNameOption, 0, NewDocumentNo, CommentTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CopyCommentLinesWithSubType_Invoice_WithOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceCommentLine: Record "Service Comment Line";
        ServOrderManagement: Codeunit ServOrderManagement;
        DocumentNo: Code[20];
        NewDocumentNo: Code[20];
        NewTableNameOption: Enum "Service Comment Table Name";
        CommentTxt: Text[80];
    begin
        // [FEATURE] [UT] [Service] [Comments]
        // [SCENARIO 257848] UT ServOrderManagement.CopyCommentLinesWithSubType for Service Order when there is Service Invoice with the same Document No. and both do have comments.
        Initialize();

        CreateTwoServiceCommentLinesForDocs(
          ServiceHeader."Document Type"::Order,
          ServiceHeader."Document Type"::Invoice,
          DocumentNo, CommentTxt);

        NewDocumentNo := LibraryUtility.GenerateGUID();
        NewTableNameOption := ServiceCommentLine."Table Name"::"Service Invoice Header";

        ServOrderManagement.CopyCommentLinesWithSubType(
          ServiceCommentLine."Table Name"::"Service Header".AsInteger(),
          NewTableNameOption.AsInteger(), DocumentNo, NewDocumentNo,
          ServiceCommentLine."Table Subtype"::"2".AsInteger());

        VerifyServiceCommentLineExists(NewTableNameOption, 0, NewDocumentNo, CommentTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedServiceHeaderUpdateOnlyRelatedCommentLines()
    var
        ServiceHeader: Record "Service Header";
        ServiceCommentLine: Record "Service Comment Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CommentText: Text[80];
    begin
        // [SCENARIO 257848] Service Comment Lines updated only for posted Service Header document.
        Initialize();

        CommentText := LibraryUtility.GenerateGUID();

        // [GIVEN] "SCM" Service Credit Memo with a line and comment "SCM-TXT".
        CreateServiceCreditMemoWithComment(ServiceHeader, CommentText);

        // [GIVEN] Service Quote "SQ" with the same No. as "SCM" and with comment "SQ-TXT" which is the same to "SCM-TXT".
        MockServiceHeaderWithCommentLine(ServiceHeader."Document Type"::Quote, ServiceHeader."No.", CommentText);

        // [WHEN] "SCM" is posted.
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);
        Assert.IsFalse(
          ServiceHeader.Get(ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."No."),
          StrSubstNo(ExistErr, ServiceHeader.TableCaption(), ServiceHeader."No."));

        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceCrMemoHeader.FindFirst();

        // [THEN] "SCM-TXT" is updated to relate to "Service Cr.Memo Header" table.
        VerifyServiceCommentLineExists(
          ServiceCommentLine."Table Name"::"Service Cr.Memo Header", 0, ServiceCrMemoHeader."No.", CommentText);

        // [THEN] "SQ-TXT" is still exists.
        VerifyServiceCommentLineExists(
          ServiceCommentLine."Table Name"::"Service Header", ServiceHeader."Document Type"::Quote.AsInteger(), ServiceHeader."No.", CommentText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemForReplacementExistsErrorNotRaisedForBlankItem()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 339134] Stan can create several service lines with blank "No." for a service item line with no item attached to it.
        Initialize();

        CreateServiceOrderWithOneLine(ServiceHeader, ServiceItemLine);

        CreateServiceLineBlank(ServiceLine, ServiceHeader);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);

        CreateServiceLineBlank(ServiceLine, ServiceHeader);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");

        ServiceLine.TestField("No.", '');
    end;

    [Test]
    [HandlerFunctions('BatchPostServiceOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifySelectedServiceOrdersExposedIntoPostBatch()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrders: TestPage "Service Orders";
    begin
        // [SCENARIO 474287] Verify the selected Service Order should populate in the "Post Batch" report.
        Initialize();

        // [GIVEN] Create a Service Header.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Save the transaction.
        Commit();

        // [GIVEN] Open a Service Orders.
        ServiceOrders.OpenEdit();
        ServiceOrders.GoToRecord(ServiceHeader);

        // [WHEN] Post Batch Service Orders.
        ServiceOrders.PostBatch.Invoke();
        ServiceOrders.Close();

        // [Verify] Verify: The selected Service Order should populate in the "Post Batch" report.
        Assert.AreEqual(
            ServiceHeader."No.",
            LibraryVariableStorage.DequeueText(),
            StrSubstNo(ValueMustBeEqualErr, ServiceHeader.FieldCaption("No."), ServiceHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyVariantCodeClearedWhenSelectingNewItemOnServiceOrder()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [SCENARIO 483466] When user select item, previously selected variant code is no cleared: service item line
        Initialize();

        // [GIVEN] Create 2 Items "I1" and "I2", and Item Variant for "I1"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant.Modify(true);

        // [THEN] Create Service Order
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());

        // [THEN] Create Service Item Line for item "I1" update Item Variant "IV1" 
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate("Item No.", Item."No.");
        ServiceItemLine.Validate("Variant Code", ItemVariant.Code);
        ServiceItemLine.Modify(true);

        // [VERIFY] Verify: Changing Item No. on "Service Order Line" should be cleared the "Variant Code" field value
        ServiceItemLine.Validate("Item No.", Item2."No.");
        Assert.IsTrue(
            (ServiceItemLine."Variant Code" = ''),
            StrSubstNo(
                ValueMustBlankErr,
                ServiceItemLine.FieldCaption("Variant Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDescriptionAndDescription2OnServiceOrderLineWithItemVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [SCENARIO 483466] When user select item, previously selected variant code is no cleared: service item line
        Initialize();

        // [GIVEN] Create 2 Items "I1" and "I2", and Item Variant for "I1"
        // [GIVEN] Create Item with Item Variant. 
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant."Description 2" := LibraryUtility.GenerateRandomText(20);
        ItemVariant.Modify(true);

        // [THEN] Create Service Order
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());

        // [THEN] Create Service Item Line for item "I1" update Item Variant "IV1" 
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate("Item No.", Item."No.");
        ServiceItemLine.Validate("Variant Code", ItemVariant.Code);
        ServiceItemLine.Modify(true);

        // [VERIFY] Verify: Description/Description 2 of "Service Order Line" should be equal to "Item Variant" Description/Description 2
        Assert.AreEqual(ItemVariant.Description, ServiceItemLine.Description, DescriptionMustBeSame);
        Assert.AreEqual(ItemVariant."Description 2", ServiceItemLine."Description 2", DescriptionMustBeSame);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Working On Service Orders");
        Clear(LibraryService);
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Working On Service Orders");

        // Create Demonstration Database
        LibrarySales.DisableWarningOnCloseUnpostedDoc();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateAccountInServiceCosts();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.SaveServiceMgtSetup();
        IsInitialized := true;
        Commit();
        BindSubscription(LibraryJobQueue);
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Working On Service Orders");
    end;

    local procedure CreateAndPostServiceOrder(var ServiceItemLine: Record "Service Item Line"; var ParentServiceItemNo: Code[20]; Quantity: Decimal)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // 1. Setup: Create Service Order, Create Service Item from Service Order, Create Service Item Components,
        // Create Service Line with "Item No." on Second Service Item Line.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        CreateServiceItemLineWithItem(ServiceHeader);
        CreateServiceItemFromOrder(ServiceHeader);
        CreateServiceItemComponents(ServiceHeader);
        CreateServiceLineReplacement(ServiceLine, ServiceHeader);
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();
        ServiceItemNoForReplacement := ServiceItemLine."Service Item No.";
        ParentServiceItemNo := ServiceItemLine."Service Item No.";
        UpdateQuantityOnServiceLine(ServiceLine, ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Modify(true);
        ServiceItemLine.Next();
        ServiceLine.Validate("No.", ServiceItemLine."Item No.");

        // 2. Exercise: Post Service Order as Ship.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; var ServiceMgtSetup: Record "Service Mgt. Setup"; Modified: Boolean) SetupModified: Boolean
    begin
        Initialize();
        ServiceMgtSetup.Get();
        SetupModified := ModifyServiceSetupCopyComment(ServiceMgtSetup, Modified);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        CreateServiceItemLine(ServiceHeader);
        CreateCommentsOnServiceOrder(ServiceHeader);
        CreateServiceLineForItem(ServiceHeader);
        UpdatePartialQtyOnServiceLines(ServiceHeader);
    end;

    local procedure CreateServiceOrderWithOneLine(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line")
    var
        ServiceItem: Record "Service Item";
    begin
        LibraryService.CreateServiceItem(ServiceItem, CreateCustomer());
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure CreateServiceOrderWithNotify(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line")
    var
        Customer: Record Customer;
    begin
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Customer.Modify(true);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceHeader.Validate("Notify Customer", ServiceHeader."Notify Customer"::"By Email");
        ServiceHeader.Modify(true);
    end;

    local procedure CreateServiceCreditMemoWithComment(var ServiceHeader: Record "Service Header"; CommentText: Text[80])
    var
        ServiceLine: Record "Service Line";
        ServiceCommentLine: Record "Service Comment Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, '', LibraryRandom.RandInt(10));
        LibraryService.CreateServiceCommentLine(
          ServiceCommentLine, ServiceCommentLine."Table Name"::"Service Header",
          ServiceHeader."Document Type".AsInteger(), ServiceHeader."No.", ServiceCommentLine.Type::General, 0);
        ServiceCommentLine.Comment := CommentText;
        ServiceCommentLine.Modify();
    end;

    local procedure PostServiceOrderFaultCode(var TempServiceItemLine: Record "Service Item Line" temporary)
    var
        Customer: Record Customer;
        ServiceCost: Record "Service Cost";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        FaultCode: Record "Fault Code";
        ResolutionCode: Record "Resolution Code";
    begin
        // Create Service Order, Create Fault Code and Resolution Code, Update Fault Area Code, Fault Code, Symptom Code
        // and Resolution Code on Service Item Line, Post Service Order as Ship and Invoice.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.FindServiceCost(ServiceCost);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        UpdateRepairStatusInitial(ServiceItemLine);

        CreateFaultCode(FaultCode);
        if not ResolutionCode.FindFirst() then
            LibraryService.CreateResolutionCode(ResolutionCode);
        UpdateFaultResolution(ServiceItemLine, FaultCode, ResolutionCode.Code);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code);
        UpdateQuantityOnServiceLine(ServiceLine, ServiceItemLine."Line No.");
        TempServiceItemLine := ServiceItemLine;
        TempServiceItemLine.Insert();
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure RepairStatusInitial(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line")
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
    begin
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, CreateCustomer());
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate("Item No.", LibraryInventory.CreateItem(Item));
        ServiceItemLine.Modify(true);

        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        UpdateRepairStatusInitial(ServiceItemLine);
    end;

    local procedure RunServiceLineForm(var ServiceItemLine: Record "Service Item Line"; var ServiceMgtSetup: Record "Service Mgt. Setup"; Modified: Boolean) SetupModified: Boolean
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
    begin
        // 1. Setup: Set "Link Service to Service Item" field as False on Service Management Setup, Create Standard Service Code, Create
        // Standard Service Line for Create Standard Service Code, Create Service Order - Service Header and Service Item Line.
        Initialize();
        ServiceMgtSetup.Get();
        Customer.Get(CreateCustomer());
        SetupModified := ModifySetupLinkServiceItem(ServiceMgtSetup, Modified);
        LibraryService.CreateStandardServiceCode(StandardServiceCode);

        StandServiceItemGroupCode := StandardServiceCode.Code;
        LibraryService.CreateStandardServiceLine(StandardServiceLine, StandardServiceCode.Code);
        UpdateStandardServiceLine(StandardServiceLine, StandardServiceLine.Type::Item, LibraryInventory.CreateItem(Item));

        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        StandardServiceCode.Validate("Currency Code", ServiceHeader."Currency Code");
        StandardServiceCode.Modify(true);

        // 2. Exercise: Run Service Line Form.
        StandardServiceItemGrCode.InsertServiceLines(ServiceItemLine);
    end;

    local procedure CreateCommentsOnServiceOrder(ServiceHeader: Record "Service Header")
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceCommentLine: Record "Service Comment Line";
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();
        repeat
            LibraryService.CreateCommentLineForServHeader(ServiceCommentLine, ServiceItemLine, ServiceCommentLine.Type::Fault);
            LibraryService.CreateCommentLineForServHeader(ServiceCommentLine, ServiceItemLine, ServiceCommentLine.Type::Resolution);
            LibraryService.CreateCommentLineForServHeader(ServiceCommentLine, ServiceItemLine, ServiceCommentLine.Type::Accessory);
            LibraryService.CreateCommentLineForServHeader(ServiceCommentLine, ServiceItemLine, ServiceCommentLine.Type::Internal);
            LibraryService.CreateCommentLineForServHeader(
              ServiceCommentLine, ServiceItemLine, ServiceCommentLine.Type::"Service Item Loaner");
            LibraryService.CreateCommentLineForServHeader(ServiceCommentLine, ServiceItemLine, ServiceCommentLine.Type::General);
        until ServiceItemLine.Next() = 0;
    end;

    local procedure CreateContractServiceOrders(var ServiceContractHeader: Record "Service Contract Header")
    var
        CreateContractServOrders: Report "Create Contract Service Orders";
        CreateServOrders: Option "Create Service Order","Print Only";
    begin
        CreateContractServOrders.InitializeRequest(WorkDate(), WorkDate(), CreateServOrders::"Create Service Order");
        CreateContractServOrders.SetTableView(ServiceContractHeader);
        CreateContractServOrders.UseRequestPage(false);
        CreateContractServOrders.SetHideDialog(true);
        CreateContractServOrders.Run();
    end;

    local procedure CreateFaultCode(var FaultCode: Record "Fault Code")
    var
        FaultArea: Record "Fault Area";
        SymptomCode: Record "Symptom Code";
    begin
        if not FaultArea.FindFirst() then
            LibraryService.CreateFaultArea(FaultArea);

        if not SymptomCode.FindFirst() then
            LibraryService.CreateSymptomCode(SymptomCode);

        FaultCode.SetRange("Fault Area Code", FaultArea.Code);
        FaultCode.SetRange("Symptom Code", SymptomCode.Code);
        if not FaultCode.FindFirst() then
            LibraryService.CreateFaultCode(FaultCode, FaultArea.Code, SymptomCode.Code);
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

    local procedure CreateRepairStatusCodePartial(var RepairStatus: Record "Repair Status")
    begin
        RepairStatus.SetRange("Partly Serviced", true);
        if not RepairStatus.FindFirst() then begin
            LibraryService.CreateRepairStatus(RepairStatus);
            RepairStatus.Validate("Partly Serviced", true);
            RepairStatus.Modify(true);
        end;
    end;

    local procedure CreateRepairStatusInProcess(var RepairStatus: Record "Repair Status")
    begin
        RepairStatus.SetRange("In Process", true);
        if not RepairStatus.FindFirst() then begin
            LibraryService.CreateRepairStatus(RepairStatus);
            RepairStatus.Validate("In Process", true);
            RepairStatus.Modify(true);
        end;
    end;

    local procedure CreateRepairStatusQuote(var RepairStatus: Record "Repair Status")
    begin
        RepairStatus.SetRange("Quote Finished", true);
        if not RepairStatus.FindFirst() then begin
            LibraryService.CreateRepairStatus(RepairStatus);
            RepairStatus.Validate("Quote Finished", true);
            RepairStatus.Modify(true);
        end;
    end;

    local procedure CreateRepairStatusWaitCustomer(var RepairStatus: Record "Repair Status")
    begin
        RepairStatus.SetRange("Waiting for Customer", true);
        if not RepairStatus.FindFirst() then begin
            LibraryService.CreateRepairStatus(RepairStatus);
            RepairStatus.Validate("Waiting for Customer", true);
            RepairStatus.Modify(true);
        end;
    end;

    local procedure CreateServiceCost(var ServiceCost: Record "Service Cost"; CostType: Option; ServiceZoneCode: Code[10])
    begin
        ServiceCost.SetRange("Cost Type", CostType);
        ServiceCost.SetRange("Service Zone Code", ServiceZoneCode);
        if not ServiceCost.FindFirst() then begin
            LibraryService.CreateServiceCost(ServiceCost);
            ServiceCost.Validate("Cost Type", CostType);
            ServiceCost.Validate("Account No.", LibraryERM.CreateGLAccountWithSalesSetup());

            // Use Random because value is not important.
            ServiceCost.Validate("Default Quantity", LibraryRandom.RandInt(10));
            ServiceCost.Validate("Default Unit Cost", LibraryRandom.RandInt(10));
            ServiceCost.Validate("Service Zone Code", ServiceZoneCode);
            ServiceCost.Modify(true);
        end;
    end;

    local procedure CreateServiceItemLine(ServiceHeader: Record "Service Header")
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        Counter: Integer;
    begin
        // Create 2 to 10 Service Lines - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(8) do begin
            Clear(ServiceItem);
            LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
            LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        end;
    end;

    local procedure CreateServiceItemLineWithItem(ServiceHeader: Record "Service Header")
    var
        Item: Record Item;
        ServiceItemLine: Record "Service Item Line";
        Counter: Integer;
    begin
        // Create 2 to 10 Service Item Lines - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(8) do begin
            LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
            ServiceItemLine.Validate("Item No.", LibraryInventory.CreateItem(Item));
            ServiceItemLine.Validate(Description, Item."No.");
            ServiceItemLine.Modify(true);
        end;
    end;

    local procedure CreateServiceLineBlank(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        Clear(ServiceLine);
        ServiceLine.Init();
        ServiceLine.Validate("Document Type", ServiceHeader."Document Type");
        ServiceLine.Validate("Document No.", ServiceHeader."No.");
        ServiceLine.Validate("Line No.", LibraryUtility.GetNewRecNo(ServiceLine, ServiceLine.FieldNo("Line No.")));
        ServiceLine.Validate(Type, ServiceLine.Type::Item);
        ServiceLine.Insert(true);
    end;

    local procedure CreateServiceLineReplacement(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.Next(2);

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ServiceItemLine."Item No.");
    end;

    local procedure CreateServiceLineForItem(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        Item: Record Item;
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();
        repeat
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
            ServiceLine.Modify(true);
        until ServiceItemLine.Next() = 0;
    end;

    local procedure CreateServiceItemFromOrder(ServiceHeader: Record "Service Header")
    var
        ServiceItemLine: Record "Service Item Line";
        ServItemManagement: Codeunit ServItemManagement;
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();
        repeat
            ServItemManagement.CreateServItemOnServItemLine(ServiceItemLine);
        until ServiceItemLine.Next() = 0;
    end;

    local procedure CreateServiceItemComponents(ServiceHeader: Record "Service Header")
    var
        ServiceItemComponent: Record "Service Item Component";
        ServiceItemLine: Record "Service Item Line";
        ServiceItemNo: Code[20];
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindSet();
        ServiceItemNo := ServiceItemLine."Service Item No.";
        ServiceItemLine.Next();
        repeat
            LibraryService.CreateServiceItemComponent(
              ServiceItemComponent, ServiceItemNo, ServiceItemComponent.Type::"Service Item", ServiceItemLine."Service Item No.");
        until ServiceItemLine.Next() = 0;
    end;

    local procedure CreateCustomer(): Code[20]
    begin
        exit(LibrarySales.CreateCustomerNo());
    end;

    local procedure ModifyServiceSetupCopyComment(var ServiceMgtSetup: Record "Service Mgt. Setup"; ModifyValue: Boolean): Boolean
    begin
        if (ServiceMgtSetup."Copy Comments Order to Invoice" <> ModifyValue) or
           (ServiceMgtSetup."Copy Comments Order to Shpt." <> ModifyValue)
        then begin
            ServiceMgtSetup.Validate("Copy Comments Order to Invoice", ModifyValue);
            ServiceMgtSetup.Validate("Copy Comments Order to Shpt.", ModifyValue);
            ServiceMgtSetup.Modify(true);
            exit(true);
        end;
        exit(false);
    end;

    local procedure ModifySetupLinkServiceItem(var ServiceMgtSetup: Record "Service Mgt. Setup"; ModifyValue: Boolean): Boolean
    begin
        if ServiceMgtSetup."Link Service to Service Item" <> ModifyValue then begin
            ServiceMgtSetup.Validate("Link Service to Service Item", ModifyValue);
            ServiceMgtSetup.Modify(true);
            exit(true);
        end;
        exit(false);
    end;

    local procedure CreateTwoServiceCommentLinesForDocs(DocumentType: Enum "Service Document Type"; TargetDocumentType: Enum "Service Document Type"; var DocumentNo: Code[20]; var CommentTxt: Text[80])
    begin
        DocumentNo := LibraryUtility.GenerateGUID();
        CommentTxt := LibraryUtility.GenerateGUID();
        MockServiceHeaderWithCommentLine(DocumentType, DocumentNo, LibraryUtility.GenerateGUID());
        MockServiceHeaderWithCommentLine(TargetDocumentType, DocumentNo, CommentTxt);
    end;

    local procedure MockServiceHeaderWithCommentLine(DocumentType: Enum "Service Document Type"; DocumentNo: Code[20]; CommentText: Text[80])
    var
        ServiceHeader: Record "Service Header";
        ServiceCommentLine: Record "Service Comment Line";
    begin
        ServiceHeader."Document Type" := DocumentType;
        ServiceHeader."No." := DocumentNo;
        ServiceHeader.Insert();

        LibraryService.CreateServiceCommentLine(
          ServiceCommentLine, ServiceCommentLine."Table Name"::"Service Header",
          DocumentType.AsInteger(), DocumentNo, ServiceCommentLine.Type::General, 0);
        ServiceCommentLine.Comment := CommentText;
        ServiceCommentLine.Modify();
    end;

    local procedure SelectServiceItem(var ServiceItem: Record "Service Item")
    var
        Item: Record Item;
        ServiceItemGroup: Record "Service Item Group";
    begin
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroup.Validate("Create Service Item", true);
        ServiceItemGroup.Modify(true);

        LibraryService.CreateServiceItem(ServiceItem, CreateCustomer());
        ServiceItem.Validate("Item No.", LibraryInventory.CreateItem(Item));
        ServiceItem.Validate("Service Item Group Code", ServiceItemGroup.Code);
        ServiceItem.Modify(true);
    end;

    local procedure SaveComments(var TempServiceCommentLine: Record "Service Comment Line" temporary; ServiceHeader: Record "Service Header")
    var
        ServiceCommentLine: Record "Service Comment Line";
    begin
        ServiceCommentLine.SetRange("Table Name", ServiceCommentLine."Table Name"::"Service Header");
        ServiceCommentLine.SetRange("Table Subtype", ServiceHeader."Document Type");
        ServiceCommentLine.SetRange("No.", ServiceHeader."No.");
        ServiceCommentLine.FindSet();
        repeat
            TempServiceCommentLine := ServiceCommentLine;
            TempServiceCommentLine.Insert();
        until ServiceCommentLine.Next() = 0;
    end;

    local procedure SetOneServiceItemLinePerOrder(IsOneLinePerOrder: Boolean)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("One Service Item Line/Order", IsOneLinePerOrder);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure UpdateFaultResolution(var ServiceItemLine: Record "Service Item Line"; FaultCode: Record "Fault Code"; ResolutionCode: Code[10])
    begin
        ServiceItemLine.Validate("Fault Area Code", FaultCode."Fault Area Code");
        ServiceItemLine.Validate("Symptom Code", FaultCode."Symptom Code");
        ServiceItemLine.Validate("Fault Code", FaultCode.Code);
        ServiceItemLine.Validate("Resolution Code", ResolutionCode);
        ServiceItemLine.Modify(true);
    end;

    local procedure UpdatePartialQtyOnServiceLines(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
            ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure UpdateQuantityOnServiceLine(var ServiceLine: Record "Service Line"; ServiceItemLineLineNo: Integer)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineLineNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Random because value is not important.
        ServiceLine.Modify(true);
    end;

    local procedure UpdateRepairStatusOnFirstLine(ServiceHeader: Record "Service Header"; RepairStatusCode: Code[10])
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindFirst();
        ServiceItemLine.Validate("Repair Status Code", RepairStatusCode);
        ServiceItemLine.Modify(true);
    end;

    local procedure UpdateRepairStatusOnSecondLine(ServiceHeader: Record "Service Header"; RepairStatusCode: Code[10])
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.Next(2);
        ServiceItemLine.Validate("Repair Status Code", RepairStatusCode);
        ServiceItemLine.Modify(true);
    end;

    local procedure UpdateRepairStatusInitial(ServiceItemLine: Record "Service Item Line")
    var
        RepairStatus: Record "Repair Status";
    begin
        RepairStatus.SetRange(Initial, true);
        if not RepairStatus.FindFirst() then begin
            LibraryService.CreateRepairStatus(RepairStatus);
            RepairStatus.Validate(Initial, true);
            RepairStatus.Modify(true);
        end;
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.FindSet();
        repeat
            ServiceItemLine.Validate("Repair Status Code", RepairStatus.Code);
            ServiceItemLine.Modify(true);
        until ServiceItemLine.Next() = 0;
    end;

    local procedure UpdateRepairStatusFinished(ServiceItemLine: Record "Service Item Line")
    var
        RepairStatus: Record "Repair Status";
    begin
        RepairStatus.SetRange(Finished, true);
        if not RepairStatus.FindFirst() then begin
            LibraryService.CreateRepairStatus(RepairStatus);
            RepairStatus.Validate(Finished, true);
            RepairStatus.Modify(true);
        end;
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.FindSet();
        repeat
            ServiceItemLine.Validate("Repair Status Code", RepairStatus.Code);
            ServiceItemLine.Modify(true);
        until ServiceItemLine.Next() = 0;
    end;

    local procedure UpdateRepairStatusSparePart(ServiceItemLine: Record "Service Item Line")
    var
        RepairStatus: Record "Repair Status";
    begin
        RepairStatus.SetRange("Spare Part Ordered", true);
        if not RepairStatus.FindFirst() then begin
            LibraryService.CreateRepairStatus(RepairStatus);
            RepairStatus.Validate("Spare Part Ordered", true);
            RepairStatus.Modify(true);
        end;
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.FindSet();
        repeat
            ServiceItemLine.Validate("Repair Status Code", RepairStatus.Code);
            ServiceItemLine.Modify(true);
        until ServiceItemLine.Next() = 0;
    end;

    local procedure UpdateRepairStatusBlank(ServiceItemLine: Record "Service Item Line")
    begin
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.FindSet();
        repeat
            ServiceItemLine.Validate("Repair Status Code", '');
            ServiceItemLine.Modify(true);
        until ServiceItemLine.Next() = 0;
    end;

    local procedure UpdateRepairStatusInProcess(ServiceItemLine: Record "Service Item Line")
    var
        RepairStatus: Record "Repair Status";
    begin
        RepairStatus.SetRange("In Process", true);
        if not RepairStatus.FindFirst() then begin
            LibraryService.CreateRepairStatus(RepairStatus);
            RepairStatus.Validate("In Process", true);
            RepairStatus.Modify(true);
        end;
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.FindSet();
        repeat
            ServiceItemLine.Validate("Repair Status Code", RepairStatus.Code);
            ServiceItemLine.Modify(true);
        until ServiceItemLine.Next() = 0;
    end;

    local procedure UpdateStatusOnServiceHeader(var ServiceHeader: Record "Service Header"; Status: Enum "Service Document Status")
    begin
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.Validate(Status, Status);
        ServiceHeader.Modify(true);
    end;

    local procedure UpdateStandardServiceLine(var StandardServiceLine: Record "Standard Service Line"; Type: Enum "Service Line Type"; No: Code[20])
    begin
        StandardServiceLine.Validate(Type, Type);
        StandardServiceLine.Validate("No.", No);
        StandardServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Validating as random because value is not important.
        StandardServiceLine.Modify(true);
    end;

    local procedure BatchPostOrders(No: Code[20]; No2: Code[20])
    var
        ServiceHeader: Record "Service Header";
        BatchPostServiceOrders: Report "Batch Post Service Orders";
    begin
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.SetFilter("No.", '%1|%2', No, No2);
        Clear(BatchPostServiceOrders);
        BatchPostServiceOrders.SetTableView(ServiceHeader);
        BatchPostServiceOrders.Run();
    end;

    local procedure CreateServiceItemLineForOrder(No: Code[20])
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceOrder: TestPage "Service Order";
    begin
        Customer.Get(CreateCustomer());
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("Document Type", Format(ServiceHeader."Document Type"::Order));
        ServiceOrder.FILTER.SetFilter("No.", No);
        ServiceOrder."Customer No.".SetValue(Customer."No.");
        ServiceOrder.ServItemLines.ServiceItemNo.SetValue(ServiceItem."No.");
        ServiceOrder.ServItemLines.New();
        ServiceOrder.OK().Invoke();
    end;

    local procedure CreateServiceOrderWithPage() No: Code[20]
    begin
        No := LibraryService.CreateServiceOrderHeaderUsingPage();
        CreateServiceItemLineForOrder(No);
        OpenServiceLinePage(No);
    end;

    local procedure OpenServiceLinePage(No: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceOrder.OpenView();
        ServiceOrder.FILTER.SetFilter("Document Type", Format(ServiceHeader."Document Type"::Order));
        ServiceOrder.FILTER.SetFilter("No.", No);
        ServiceOrder.ServItemLines."Service Lines".Invoke();
    end;

    local procedure VerifyCommentsOnPostedShipment(var TempServiceCommentLine: Record "Service Comment Line" temporary)
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceCommentLine: Record "Service Comment Line";
    begin
        ServiceShipmentHeader.SetRange("Order No.", TempServiceCommentLine."No.");
        ServiceShipmentHeader.FindFirst();
        TempServiceCommentLine.FindSet();
        ServiceCommentLine.SetRange("Table Name", ServiceCommentLine."Table Name"::"Service Shipment Header");
        ServiceCommentLine.SetRange("No.", ServiceShipmentHeader."No.");
        ServiceCommentLine.FindSet();
        repeat
            ServiceCommentLine.TestField("Table Line No.", TempServiceCommentLine."Table Line No.");
            ServiceCommentLine.TestField("Line No.", TempServiceCommentLine."Line No.");
            ServiceCommentLine.TestField(Type, TempServiceCommentLine.Type);
            ServiceCommentLine.TestField(Comment, TempServiceCommentLine.Comment);
            TempServiceCommentLine.Next();
        until ServiceCommentLine.Next() = 0;
    end;

    local procedure VerifyCommentsOnPostedInvoice(var TempServiceCommentLine: Record "Service Comment Line" temporary)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCommentLine: Record "Service Comment Line";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", TempServiceCommentLine."No.");
        ServiceInvoiceHeader.FindFirst();
        TempServiceCommentLine.FindSet();
        ServiceCommentLine.SetRange("Table Name", ServiceCommentLine."Table Name"::"Service Invoice Header");
        ServiceCommentLine.SetRange("No.", ServiceInvoiceHeader."No.");
        ServiceCommentLine.FindSet();
        repeat
            ServiceCommentLine.TestField("Table Line No.", TempServiceCommentLine."Table Line No.");
            ServiceCommentLine.TestField("Line No.", TempServiceCommentLine."Line No.");
            ServiceCommentLine.TestField(Type, TempServiceCommentLine.Type);
            ServiceCommentLine.TestField(Comment, TempServiceCommentLine.Comment);
            TempServiceCommentLine.Next();
        until ServiceCommentLine.Next() = 0;
    end;

    local procedure VerifyFaultCodePostedShipment(var TempServiceItemLine: Record "Service Item Line" temporary)
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentItemLine: Record "Service Shipment Item Line";
    begin
        ServiceShipmentHeader.SetRange("Order No.", TempServiceItemLine."Document No.");
        ServiceShipmentHeader.FindFirst();
        ServiceShipmentItemLine.SetRange("No.", ServiceShipmentHeader."No.");
        ServiceShipmentItemLine.FindFirst();
        ServiceShipmentItemLine.TestField("Service Item No.", TempServiceItemLine."Service Item No.");
        ServiceShipmentItemLine.TestField("Fault Area Code", TempServiceItemLine."Fault Area Code");
        ServiceShipmentItemLine.TestField("Symptom Code", TempServiceItemLine."Symptom Code");
        ServiceShipmentItemLine.TestField("Fault Code", TempServiceItemLine."Fault Code");
        ServiceShipmentItemLine.TestField("Resolution Code", TempServiceItemLine."Resolution Code");
    end;

    local procedure VerifyFaultCodeOnPostedInvoice(var TempServiceItemLine: Record "Service Item Line" temporary)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", TempServiceItemLine."Document No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindFirst();
        ServiceInvoiceLine.TestField("Service Item No.", TempServiceItemLine."Service Item No.");
        ServiceInvoiceLine.TestField("Fault Area Code", TempServiceItemLine."Fault Area Code");
        ServiceInvoiceLine.TestField("Symptom Code", TempServiceItemLine."Symptom Code");
        ServiceInvoiceLine.TestField("Fault Code", TempServiceItemLine."Fault Code");
        ServiceInvoiceLine.TestField("Resolution Code", TempServiceItemLine."Resolution Code");
    end;

    local procedure VerifyFaultResolutionRelation(var TempServiceItemLine: Record "Service Item Line" temporary)
    var
        FaultResolCodRelationship: Record "Fault/Resol. Cod. Relationship";
    begin
        FaultResolCodRelationship.SetRange("Fault Area Code", TempServiceItemLine."Fault Area Code");
        FaultResolCodRelationship.SetRange("Fault Code", TempServiceItemLine."Fault Code");
        FaultResolCodRelationship.SetRange("Symptom Code", TempServiceItemLine."Symptom Code");
        FaultResolCodRelationship.FindFirst();
        FaultResolCodRelationship.TestField("Resolution Code", TempServiceItemLine."Resolution Code");
        Assert.IsTrue(FaultResolCodRelationship.Occurrences > 0, FaultResolCodesRlshipError);
    end;

    local procedure VerifyInsertFeeOnServiceLine(ServiceHeader: Record "Service Header"; ServiceCost: Record "Service Cost")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        ServiceLine.TestField("No.", ServiceCost.Code);
        ServiceLine.TestField(Quantity, ServiceCost."Default Quantity");
        ServiceLine.TestField("Unit Cost (LCY)", ServiceCost."Default Unit Cost");
    end;

    local procedure VerifyPostedServiceInvoice(OrderNo: Code[20]; PostingDate2: Date)
    var
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.FILTER.SetFilter("Order No.", OrderNo);
        PostedServiceInvoice."Posting Date".AssertEquals(PostingDate2);
    end;

    local procedure VerifyServiceOrdersStatus(No: Code[20]; PostingDate: Date)
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.SetRange("No.", No);
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.SetRange(Status, ServiceHeader.Status::"In Process");
        ServiceHeader.SetRange("Posting Date", PostingDate);
        Assert.RecordIsEmpty(ServiceHeader);
    end;

    local procedure VerifyServiceCommentLineExists(TableNameOption: Enum "Service Comment Table Name"; TableSubtype: Option; DocumentNo: Code[20]; CommentTxt: Text[80])
    var
        ServiceCommentLine: Record "Service Comment Line";
    begin
        ServiceCommentLine.SetRange("Table Name", TableNameOption);
        ServiceCommentLine.SetRange("Table Subtype", TableSubtype);
        ServiceCommentLine.SetRange("No.", DocumentNo);
        ServiceCommentLine.SetRange(Comment, CommentTxt);
        Assert.RecordIsNotEmpty(ServiceCommentLine);
    end;

    local procedure VerifySplitLines(ServiceLine: Record "Service Line")
    var
        ServiceLine2: Record "Service Line";
    begin
        ServiceLine2.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine2.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine2.FindSet();
        repeat
            ServiceLine2.TestField(Type, ServiceLine.Type);
            ServiceLine2.TestField("No.", ServiceLine."No.");
            ServiceLine2.TestField(Quantity, ServiceLine.Quantity / 2);  // Use 2 to Verify Split Line Quantity.
        until ServiceLine2.Next() = 0;
    end;

    local procedure VerifySplitLineError(ServiceLine: Record "Service Line")
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLine.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLine.FindSet();
        repeat
            asserterror ServiceLine.SplitResourceLine();
            Assert.ExpectedTestFieldError(ServiceLine.FieldCaption(Type), Format(ServiceLine.Type::Resource));
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyUnitPrice(ServiceHeader: Record "Service Header"; Quantity: Decimal; UnitPrice: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
        repeat
            ServiceLine.TestField("Unit Price", UnitPrice);
            ServiceLine.TestField(Quantity, Quantity / 2);
        until ServiceLine.Next() = 0;
    end;

    local procedure SetBlueLocation(No1: Code[20]; No2: Code[20])
    var
        ServiceLine: Record "Service Line";
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetFilter("Document No.", '%1|%2', No1, No2);
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate("Location Code", Location.Code);
            ServiceLine.Modify();
        until ServiceLine.Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostServiceOrdersHandler(var BatchPostServiceOrders: TestRequestPage "Batch Post Service Orders")
    var
        PostingDate: Date;
    begin
        BatchPostServiceOrders.Ship.SetValue(true);
        BatchPostServiceOrders.Invoice.SetValue(true);

        // Assign value to global variable using random value for date expression.
        PostingDate := LibraryRandom.RandDate(5);
        LibraryVariableStorage.Enqueue(PostingDate);
        BatchPostServiceOrders.PostingDate.SetValue(PostingDate);
        BatchPostServiceOrders.ReplacePostingDate_Option.SetValue(true);
        BatchPostServiceOrders.ReplaceDocumentDate_Option.SetValue(true);
        BatchPostServiceOrders.CalcInvDiscount.SetValue(true);
        BatchPostServiceOrders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchPostServiceOrderRequestPageHandler(var BatchPostServiceOrders: TestRequestPage "Batch Post Service Orders")
    begin
        LibraryVariableStorage.Enqueue(
          BatchPostServiceOrders."Service Header".GetFilter("No."));
        BatchPostServiceOrders.Cancel().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmMessageHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Question: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandler(var ServiceItemReplacement: Page "Service Item Replacement"; var Response: Action)
    begin
        Response := ACTION::OK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerLookupOK(var ServiceItemComponentList: Page "Service Item Component List"; var Response: Action)
    var
        ServiceItemComponent: Record "Service Item Component";
    begin
        // Modal form handler. Return Action as LookupOK for first record found.
        ServiceItemComponent.SetRange("Parent Service Item No.", ServiceItemNoForReplacement);
        ServiceItemComponent.FindFirst();
        ServiceItemComponentList.SetRecord(ServiceItemComponent);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerStandardCode(var StandardServItemGrCodes: Page "Standard Serv. Item Gr. Codes"; var Response: Action)
    var
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
    begin
        StandardServiceItemGrCode.SetRange(Code, StandServiceItemGroupCode);
        StandardServiceItemGrCode.FindFirst();
        StandardServItemGrCodes.SetRecord(StandardServiceItemGrCode);
        StandardServItemGrCodes.SetTableView(StandardServiceItemGrCode);
        Response := ACTION::LookupOK;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StringMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        // Choose the First option of the string menu.
        Choice := 1;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StringMenuHandlerForNew(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        // Choose the Second option of the string menu.
        Choice := 2;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UpdateQuantityPageHandler(var ServiceLines: TestPage "Service Lines")
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        ServiceLines.Type.SetValue(ServiceLine.Type::Item);
        ServiceLines."No.".SetValue(LibraryInventory.CreateItem(Item));

        // Use random value for Quantity as value is not important.
        ServiceLines.Quantity.SetValue(LibraryRandom.RandDec(100, 2));
        ServiceLines.OK().Invoke();
    end;
}


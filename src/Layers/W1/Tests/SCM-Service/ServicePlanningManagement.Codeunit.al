// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Service.Document;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Inventory.Item;
using Microsoft.Service.Resources;
using Microsoft.Service.Item;
using Microsoft.Service.Analysis;
using Microsoft.Service.Maintenance;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Requisition;
using Microsoft.Service.Setup;
using Microsoft.Service.Reports;
using Microsoft.Purchases.Document;
using Microsoft.Service.History;
using Microsoft.Projects.Resources.Ledger;

codeunit 136111 "Service Planning Management"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Resource] [Service]
        isInitialized := false;
    end;

    var
        ServiceOrderAllocation2: Record "Service Order Allocation";
        Resource2: Record Resource;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        ResourceSkillDeletionError: Label '%1 must not be deleted.';
        ResourceNo2: Code[20];
        ResourceGroupNo2: Code[20];
        AllocatedHours2: Decimal;
        AllocationDate2: Date;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Planning Management");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Planning Management");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        Commit();
        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Planning Management");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AssignSkillWithUpdate()
    var
        Item: Record Item;
        ResourceSkill: Record "Resource Skill";
        ServiceItem: Record "Service Item";
    begin
        // Covers document number TC0082 - refer to TFS ID 21724.
        // Test Skill code updated on Service Item and Item after assigning Skill Code to Service Item Groups with update on related Item
        // and Service Item as True.

        // 1. Setup: Create Service Item, Update Service Item Group Code, Create Resource Skill Codes and update it on the - Service Item,
        // Item.
        CreateServiceItemResourceSkill(ServiceItem, ResourceSkill, Item);

        // 2. Exercise: Create Resource Skill for Service Item Group.
        CreateResourceSkill(ResourceSkill, ResourceSkill.Type::"Service Item Group", ServiceItem."Service Item Group Code");

        // 3. Verify: Skill Codes are updated on Service Item and Item after Skill Code updated on Service Item Group with update all
        // Related Service Item and Item as True.
        ResourceSkill.Get(ResourceSkill.Type::"Service Item", ServiceItem."No.", ResourceSkill."Skill Code");
        ResourceSkill.Get(ResourceSkill.Type::Item, Item."No.", ResourceSkill."Skill Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure AssignSkillWithoutUpdate()
    var
        Item: Record Item;
        ResourceSkill: Record "Resource Skill";
        ServiceItem: Record "Service Item";
        Assert: Codeunit Assert;
    begin
        // Covers document number TC0082 - refer to TFS ID 21724.
        // Test Skill code not updated on Service Item and Item after assigning Skill Code to Service Item Groups with update on related
        // Item and Service Item as False.

        // 1. Setup: Create Service Item, Update Service Item Group Code, Create Resource Skill Codes and update it on the - Service Item,
        // Item.
        CreateServiceItemResourceSkill(ServiceItem, ResourceSkill, Item);

        // 2. Exercise: Create Resource Skill for Service Item Group.
        CreateResourceSkill(ResourceSkill, ResourceSkill.Type::"Service Item Group", ServiceItem."Service Item Group Code");

        // 3. Verify: Skill Codes are not updated on Service Item and Item after Skill Code updated on Service Item Group with update all
        // related Service Item and Item as False.
        Assert.IsFalse(
          ResourceSkill.Get(ResourceSkill.Type::"Service Item", ServiceItem."No.", ResourceSkill."Skill Code"),
          StrSubstNo(ResourceSkillDeletionError, ResourceSkill.TableCaption()));
        Assert.IsFalse(ResourceSkill.Get(ResourceSkill.Type::Item, Item."No.", ResourceSkill."Skill Code"),
          StrSubstNo(ResourceSkillDeletionError, ResourceSkill.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,StringMenuHandler')]
    [Scope('OnPrem')]
    procedure DeletingSkillWithDeleteRelated()
    var
        Item: Record Item;
        ResourceSkill: Record "Resource Skill";
        ServiceItem: Record "Service Item";
        Assert: Codeunit Assert;
    begin
        // Covers document number TC0083 - refer to TFS ID 21724.
        // Test Skill Codes deleted from Items, Service Items and Resources after deleting Service Item Groups with delete Related Skill.

        // 1. Setup: Create Service Item, Update Service Item Group Code, Create Skill Codes Update it on the - Service Item, Item,
        // Service Item Group with update option as True.
        CreateServiceItemResourceSkill(ServiceItem, ResourceSkill, Item);
        CreateResourceSkill(ResourceSkill, ResourceSkill.Type::"Service Item Group", ServiceItem."Service Item Group Code");

        // 2. Exercise: Delete Last assigned Skill Code from Service Item Group with Delete all Related Skill Code option Selected.
        DeleteSkillCode(ResourceSkill.Type::"Service Item Group", ServiceItem."Service Item Group Code", ResourceSkill."Skill Code");

        // 3. Verify: Skill Codes are deleted from Service Item and Item.
        Assert.IsFalse(
          ResourceSkill.Get(ResourceSkill.Type::"Service Item", ServiceItem."No.", ResourceSkill."Skill Code"),
          StrSubstNo(ResourceSkillDeletionError, ResourceSkill.TableCaption()));
        Assert.IsFalse(
          ResourceSkill.Get(ResourceSkill.Type::Item, Item."No.", ResourceSkill."Skill Code"),
          StrSubstNo(ResourceSkillDeletionError, ResourceSkill.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,StringMenuHandlerOptionTwo')]
    [Scope('OnPrem')]
    procedure DeletingSkillWithLeaveRelated()
    var
        Item: Record Item;
        ResourceSkill: Record "Resource Skill";
        ServiceItem: Record "Service Item";
    begin
        // Covers document number TC0083 - refer to TFS ID 21724.
        // Test Skill Codes not deleted from Items, Service Items and Resources after deleting Service Item Groups with leave Related Skill.

        // 1. Setup: Create Service Item, Update Service Item Group Code, Create Skill Codes Update it on the - Service Item, Item,
        // Service Item Group with update option as True.
        CreateServiceItemResourceSkill(ServiceItem, ResourceSkill, Item);
        CreateResourceSkill(ResourceSkill, ResourceSkill.Type::"Service Item Group", ServiceItem."Service Item Group Code");

        // 2. Exercise: Delete Last assigned Skill Code from Service Item Group with Leave all Related Skill Code option Selected.
        DeleteSkillCode(ResourceSkill.Type::"Service Item Group", ServiceItem."Service Item Group Code", ResourceSkill."Skill Code");

        // 3. Verify: Skill Codes are not deleted from Item and Service Item.
        ResourceSkill.Get(ResourceSkill.Type::Item, Item."No.", ResourceSkill."Skill Code");
        ResourceSkill.Get(ResourceSkill.Type::"Service Item", ServiceItem."No.", ResourceSkill."Skill Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceAllocationServiceOrder()
    var
        Resource: Record Resource;
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderAllocation: Record "Service Order Allocation";
    begin
        // Covers document number TC0084 - refer to TFS ID 21724.
        // Test Resource allocation on Service Item Lines directly.

        // 1. Setup: Create a new Service Order - Service Header, Service Item and Service Item Line.
        CreateServiceOrder(ServiceItemLine);

        // 2. Exercise: Update the Values on Service Allocation.
        LibraryResource.FindResource(Resource);
        // Required field - value is not important to test case.
        UpdateServiceOrderAllocation(ServiceOrderAllocation, ServiceItemLine."Document No.", Resource."No.", '', LibraryRandom.RandInt(10));

        // 3. Verify: Check Status on Service Allocation as Active, No of Allocation to the Service Order on Dispatch Board as one.
        VerifyStatusServiceAllocation(ServiceItemLine."Document No.", ServiceOrderAllocation.Status::Active);
        VerifyNoOfAllocations(ServiceItemLine."Document No.", 1);  // One Resource should be allocated.
    end;

    [Test]
    [HandlerFunctions('AllocationFormHandlerWithAvail,AvailabilityModalFormHandler')]
    [Scope('OnPrem')]
    procedure AllocateResourceWithAvail()
    var
        Resource: Record Resource;
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderAllocation: Record "Service Order Allocation";
    begin
        // Covers document number TC0085 - refer to TFS ID 21724.
        // Test Resource allocation using Resource Availability.

        // 1. Setup: Create a new Service Order - Service Header, Service Item and Service Item Line.
        CreateServiceOrder(ServiceItemLine);

        // 2. Exercise: Allocate Resource to the Service Line with Resource Availability Form.
        LibraryResource.FindResource(Resource);
        ResourceNo2 := Resource."No.";
        ResourceGroupNo2 := '';  // Global variable should be set to blank.
        AllocatedHours2 := LibraryRandom.RandInt(10);  // Required field - value is not important to test case.
        AllocationDate2 := WorkDate();
        RunResourceAllocationForm(ServiceItemLine);

        // 3. Verify: Check Status as Active and other Values on Service Allocation, Resource to be allocated to the Service Order.
        VerifyValuesServiceAllocation(
          ServiceItemLine, ServiceOrderAllocation.Status::Active, ResourceNo2, ResourceGroupNo2, AllocationDate2, AllocatedHours2);
        VerifyNoOfAllocations(ServiceItemLine."Document No.", 1);  // One Resource should be allocated.
    end;

    [Test]
    [HandlerFunctions('AllocationFormHandlerWithGroup,GroupAvailModalFormHandler')]
    [Scope('OnPrem')]
    procedure AllocateResourceGroupWODate()
    var
        ResourceGroup: Record "Resource Group";
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderAllocation: Record "Service Order Allocation";
    begin
        // Covers document number TC0085 - refer to TFS ID 21724.
        // Test Resource allocation using Resource Availability without Allocation Date.

        // 1. Setup: Create Resource Group, Service Order - Service Header, Service Item and Service Item Line.
        CreateServiceOrder(ServiceItemLine);
        LibraryResource.CreateResourceGroup(ResourceGroup);

        // 2. Exercise: Allocate Resource Group to the Service Line with Resource Availability Form Without specifying the Allocation Date.
        ResourceNo2 := '';  // Global variable should be set to blank.
        ResourceGroupNo2 := ResourceGroup."No.";
        AllocatedHours2 := LibraryRandom.RandInt(10);  // Required field - value is not important to test case.
        AllocationDate2 := 0D;
        RunResourceAllocationForm(ServiceItemLine);

        // 3. Verify: Check Status as Non Active and Updated Values, Resource Not to be allocated to the Service Order.
        VerifyValuesServiceAllocation(
          ServiceItemLine, ServiceOrderAllocation.Status::Nonactive, '', ResourceGroupNo2, AllocationDate2, AllocatedHours2);
        VerifyNoOfAllocations(ServiceItemLine."Document No.", 0);  // Zero Resource should be allocated.
    end;

    [Test]
    [HandlerFunctions('AllocationFormHandlerWithGroup,GroupAvailModalFormHandler')]
    [Scope('OnPrem')]
    procedure AllocateResourceGroupWithDate()
    var
        ResourceGroup: Record "Resource Group";
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderAllocation: Record "Service Order Allocation";
    begin
        // Covers document number TC0085 - refer to TFS ID 21724.
        // Test Resource Groups allocation using Resource Groups Availability with Allocation Date.

        // 1. Setup: Create Resource Group, Service Order - Service Header, Service Item and Service Item Line.
        CreateServiceOrder(ServiceItemLine);
        LibraryResource.CreateResourceGroup(ResourceGroup);

        // 2. Exercise: Allocate Resource Group to the Service Line with Resource Availability Form with specifying the Allocation Date.
        ResourceNo2 := '';  // Global variable should be set to blank.
        ResourceGroupNo2 := ResourceGroup."No.";
        AllocatedHours2 := LibraryRandom.RandInt(10);  // Required field - value is not important to test case.
        AllocationDate2 := WorkDate();
        RunResourceAllocationForm(ServiceItemLine);

        ServiceOrderAllocation.SetRange("Document Type", ServiceOrderAllocation."Document Type"::Order);
        ServiceOrderAllocation.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceOrderAllocation.FindFirst();
        ServiceOrderAllocation.Validate("Allocation Date", WorkDate());
        ServiceOrderAllocation.Modify(true);

        // 3. Verify: Check Status as Active and updated Values, Resource to be allocated to the Service Order.
        VerifyValuesServiceAllocation(
          ServiceItemLine, ServiceOrderAllocation.Status::Active, ResourceNo2, ResourceGroupNo2, AllocationDate2, AllocatedHours2);
        VerifyNoOfAllocations(ServiceItemLine."Document No.", 1);  // One Resource should be allocated.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AllocateResourceToAllItems()
    var
        Resource: Record Resource;
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderAllocation: Record "Service Order Allocation";
        ServAllocationManagement: Codeunit ServAllocationManagement;
        AllocatedHours: Decimal;
    begin
        // Covers document number TC0086 - refer to TFS ID 21724.
        // Test Resource allocation to all the Service Items Lines on the Service order.

        // 1. Setup: Create a new Service Order - Service Header, Service Item and Service Item Line.
        CreateServiceOrder(ServiceItemLine);

        // 2. Exercise: Allocate Resource to All the Service Items.
        AllocatedHours := LibraryRandom.RandInt(10);  // Required field - value is not important to test case.
        LibraryResource.FindResource(Resource);
        UpdateServiceOrderAllocation(ServiceOrderAllocation, ServiceItemLine."Document No.", Resource."No.", '', AllocatedHours);
        ServAllocationManagement.SplitAllocation(ServiceOrderAllocation);

        // 3. Verify; Values on all Service Items, No of Allocations is equal to the Number of Service Item on Dispatch Board.
        VerifyAllocationsOnServiceItem(
          ServiceItemLine."Document No.", ServiceOrderAllocation.Status::Active, Resource."No.", '', AllocatedHours);
        VerifyNoOfAllocations(ServiceItemLine."Document No.", ServiceOrderAllocation.Count);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AllocateResourceGroupToAllItem()
    var
        ResourceGroup: Record "Resource Group";
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderAllocation: Record "Service Order Allocation";
        ServAllocationManagement: Codeunit ServAllocationManagement;
        AllocatedHours: Decimal;
    begin
        // Covers document number TC0086 - refer to TFS ID 21724.
        // Test Resource Groups allocation to all the Service Item line on the Service order.

        // 1. Setup: Create Resource Group, Service Order - Service Header, Service Item and Service Item Line.
        CreateServiceOrder(ServiceItemLine);
        LibraryResource.CreateResourceGroup(ResourceGroup);

        // 2. Exercise: Allocate Resource Group to All the Service Items.
        AllocatedHours := LibraryRandom.RandInt(10);  // Required field - value is not important to test case.
        UpdateServiceOrderAllocation(ServiceOrderAllocation, ServiceItemLine."Document No.", '', ResourceGroup."No.", AllocatedHours);
        ServAllocationManagement.SplitAllocation(ServiceOrderAllocation);

        // 3. Verify; Status as Active and Other Values on all Service Items, No of Allocations is equal to the Number of Service Item on
        // Dispatch Board.
        VerifyAllocationsOnServiceItem(
          ServiceItemLine."Document No.", ServiceOrderAllocation.Status::Active, '', ResourceGroup."No.", AllocatedHours);
        VerifyNoOfAllocations(ServiceItemLine."Document No.", ServiceOrderAllocation.Count);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ResourceCancelModalFormHandler')]
    [Scope('OnPrem')]
    procedure CancellingAllocationOfResource()
    var
        Resource: Record Resource;
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderAllocation: Record "Service Order Allocation";
        ServAllocationManagement: Codeunit ServAllocationManagement;
        NoOfAllocationsBeforeCancel: Integer;
    begin
        // Covers document number TC0087 - refer to TFS ID 21724.
        // Test cancel Resource allocation.

        // 1. Setup: Create a new Service Order - Service Header, Service Item and Service Item Line.
        CreateServiceOrder(ServiceItemLine);

        // 2. Exercise: Allocate Resource to all the Service Items, Cancel Allocation on one Service Item.
        LibraryResource.FindResource(Resource);
        // Required field - value is not important to test case.
        UpdateServiceOrderAllocation(ServiceOrderAllocation, ServiceItemLine."Document No.", Resource."No.", '', LibraryRandom.RandInt(10));
        ServAllocationManagement.SplitAllocation(ServiceOrderAllocation);
        ServiceOrderAllocation.SetRange("Document Type", ServiceOrderAllocation."Document Type"::Order);
        ServiceOrderAllocation.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceOrderAllocation.FindSet();
        NoOfAllocationsBeforeCancel := ServiceOrderAllocation.Count();
        ServAllocationManagement.CancelAllocation(ServiceOrderAllocation);

        // 3. Verify: Status as Reallocation Needed and other values on all Service Items, No of Allocations is less than one to the number
        // of Service Item.
        VerifyStatusServiceAllocation(ServiceItemLine."Document No.", ServiceOrderAllocation.Status::"Reallocation Needed");
        VerifyNoOfAllocations(ServiceItemLine."Document No.", NoOfAllocationsBeforeCancel - 1);
    end;

    [Test]
    [HandlerFunctions('ResourceCancelModalFormHandler,ReAllocationModalFormHandler')]
    [Scope('OnPrem')]
    procedure ReAllocationOfResource()
    var
        Resource: Record Resource;
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderAllocation: Record "Service Order Allocation";
        ServAllocationManagement: Codeunit ServAllocationManagement;
        ResourceNo: Code[20];
        AllocatedHours: Decimal;
    begin
        // Covers document number TC0088 - refer to TFS ID 21724.
        // Test reallocation of Resource.

        // 1. Setup: Create a new Service Order - Service Header, Service Item and Service Item Line.
        CreateServiceOrder(ServiceItemLine);

        // 2. Exercise: Allocate Resource to all the Service Items with Resource Availability Form, Cancel Allocation
        // on one Service Item, Reallocation on the Service Item that was cancelled.
        AllocatedHours := LibraryRandom.RandInt(10);  // Required field - value is not important to test case.
        LibraryResource.FindResource(Resource);
        UpdateServiceOrderAllocation(ServiceOrderAllocation, ServiceItemLine."Document No.", Resource."No.", '', AllocatedHours);
        ServAllocationManagement.CancelAllocation(ServiceOrderAllocation);
        ResourceNo := Resource."No.";
        Resource.Next();
        ServiceOrderAllocation.Validate("Resource No.", Resource."No.");
        ServiceOrderAllocation.Modify(true);

        // 3. Verify: Status as Active and other values on all Service Items after Reallocation, Cancel Allocated Entries.
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type"::Order);
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemLine.FindFirst();
        VerifyValuesServiceAllocation(ServiceItemLine, ServiceOrderAllocation.Status::Active, Resource."No.", '', WorkDate(), AllocatedHours);
        VerifyCancelServiceAllocation(ServiceItemLine."Document No.", ServiceItemLine."Service Item No.", ResourceNo, AllocatedHours);
    end;

    [Test]
    [HandlerFunctions('ResourceCancelModalFormHandler')]
    [Scope('OnPrem')]
    procedure ChangeStatusAsCancel()
    var
        Resource: Record Resource;
        RepairStatus: Record "Repair Status";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderAllocation: Record "Service Order Allocation";
        ServAllocationManagement: Codeunit ServAllocationManagement;
    begin
        // Covers document number TC0089 - refer to TFS ID 21724.
        // Test Repair Status as Cancelled on Service Item Line after Cancel Allocation.

        // 1. Setup: Create a new Service Order - Service Header, Service Item, Service Item Line and set the Repair Status Code to Initial.
        CreateServiceOrderOneLine(ServiceHeader, ServiceItemLine);
        UpdateRepairStatusInitial(ServiceItemLine);

        // 2. Exercise: Update the values on Service Allocation, Cancel Allocation on one Service Item.
        LibraryResource.FindResource(Resource);
        // Required field - value is not important to test case.
        UpdateServiceOrderAllocation(ServiceOrderAllocation, ServiceItemLine."Document No.", Resource."No.", '', LibraryRandom.RandInt(10));
        ServAllocationManagement.CancelAllocation(ServiceOrderAllocation);

        // 3. Verify: Repair Status as Referred.
        ServiceItemLine.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.", ServiceItemLine."Line No.");
        RepairStatus.Get(ServiceItemLine."Repair Status Code");
        RepairStatus.TestField(Referred, true);
    end;

    [Test]
    [HandlerFunctions('ResourceCancelModalFormHandler')]
    [Scope('OnPrem')]
    procedure ChangeStatusAsPartlyServed()
    var
        Resource: Record Resource;
        RepairStatus: Record "Repair Status";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderAllocation: Record "Service Order Allocation";
        ServAllocationManagement: Codeunit ServAllocationManagement;
    begin
        // Covers document number TC0089 - refer to TFS ID 21724.
        // Test Repair Status as Partly Served on Service Item Line after Cancel Allocation.

        // 1. Setup: Create a new Service Order - Service Header, Service Item, Service Item Line and set the Repair Status Code to Initial.
        CreateServiceOrderOneLine(ServiceHeader, ServiceItemLine);
        UpdateRepairStatusInitial(ServiceItemLine);

        // 2. Exercise: Update the values on Service Allocation, Update Repair Status to In Process and Cancel Allocation on
        // Service Item.
        LibraryResource.FindResource(Resource);
        // Required field - value is not important to test case.
        UpdateServiceOrderAllocation(ServiceOrderAllocation, ServiceItemLine."Document No.", Resource."No.", '', LibraryRandom.RandInt(10));
        UpdateRepairStatusInProcess(ServiceItemLine);
        ServAllocationManagement.CancelAllocation(ServiceOrderAllocation);

        // 3. Verify: Repair Status as Partly Served on Service Item Line.
        ServiceItemLine.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.", ServiceItemLine."Line No.");
        RepairStatus.Get(ServiceItemLine."Repair Status Code");
        RepairStatus.TestField("Partly Serviced", true);
    end;

    [Test]
    [HandlerFunctions('ReAllocationModalFormHandler')]
    [Scope('OnPrem')]
    procedure ChangeStatusAsReallocation()
    var
        Resource: Record Resource;
        RepairStatus: Record "Repair Status";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderAllocation: Record "Service Order Allocation";
    begin
        // Covers document number TC0089 - refer to TFS ID 21724.
        // Test Repair Status as Reallocation on Service Item Line after Reallocation of Resource on Service Order Allocation.

        // 1. Setup: Create a new Service Order - Service Header, Service Item, Service Item Line and set the Repair Status Code to Initial.
        CreateServiceOrderOneLine(ServiceHeader, ServiceItemLine);
        UpdateRepairStatusInitial(ServiceItemLine);

        // 2. Exercise: Update the Values on Service Allocation, Change Recource On Service Allocation, Cancel Allocation on One
        // Service Item.
        LibraryResource.FindResource(Resource);
        // Required field - value is not important to test case.
        UpdateServiceOrderAllocation(ServiceOrderAllocation, ServiceItemLine."Document No.", Resource."No.", '', LibraryRandom.RandInt(10));
        Resource.Next();
        ServiceOrderAllocation.Validate("Resource No.", Resource."No.");
        ServiceOrderAllocation.Modify(true);

        // 3. Verify: Verify Repair Status as Referred on Service Item Line.
        ServiceItemLine.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.", ServiceItemLine."Line No.");
        RepairStatus.Get(ServiceItemLine."Repair Status Code");
        RepairStatus.TestField(Referred, true);
    end;

    [Test]
    [HandlerFunctions('ReAllocationModalFormHandler')]
    [Scope('OnPrem')]
    procedure ChangeStatusAsFinished()
    var
        Resource: Record Resource;
        RepairStatus: Record "Repair Status";
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderAllocation: Record "Service Order Allocation";
        ResourceNo: Code[20];
        AllocatedHours: Decimal;
    begin
        // Covers document number TC0089 - refer to TFS ID 21724.
        // Test Repair Status as Finished on Service Item Line after Reallocation of Resource on Service Order Allocation.

        // 1. Setup: Create a new Service Order - Service Header, Service Item, Service Item Line and set the Repair Status Code to Initial.
        CreateServiceOrderOneLine(ServiceHeader, ServiceItemLine);
        UpdateRepairStatusInitial(ServiceItemLine);
        AllocatedHours := LibraryRandom.RandInt(10);  // Required field - value is not important to test case.
        LibraryResource.FindResource(Resource);
        UpdateServiceOrderAllocation(ServiceOrderAllocation, ServiceItemLine."Document No.", Resource."No.", '', AllocatedHours);
        Resource.Next();
        ServiceOrderAllocation.Validate("Resource No.", Resource."No.");
        ServiceOrderAllocation.Modify(true);

        // 2. Exercise: Create New Service Item Line, Update Repair Status to Initial, Update Values on Service Allocation for the
        // New Service Item Line, Set the Repair Status Code to In Process On Service Item Line, Change the Resource on Service Allocation.
        // the Service Item Line.
        Clear(ServiceItem);
        LibraryService.CreateServiceItem(ServiceItem, ServiceItemLine."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        UpdateRepairStatusInitial(ServiceItemLine);
        Resource.Next();

        ResourceNo := Resource."No.";
        UpdateAllocationOnSecondLine(ServiceOrderAllocation, ServiceHeader."No.", Resource."No.", '', AllocatedHours);
        UpdateRepairStatusInProcess(ServiceItemLine);
        Resource.Next();
        ServiceOrderAllocation.Get(ServiceOrderAllocation."Entry No.");
        ServiceOrderAllocation.Validate("Resource No.", Resource."No.");
        ServiceOrderAllocation.Modify(true);

        // 3. Verify: There are two allocation entries for Service Item No with updated Values, Repair Status as Referred on Service Item
        // Line.
        VerifyChangeAllocationStatus(
          ServiceHeader."No.", ServiceItemLine."Service Item No.", ServiceOrderAllocation.Status::Finished, ResourceNo, AllocatedHours);
        VerifyChangeAllocationStatus(
          ServiceHeader."No.", ServiceItemLine."Service Item No.", ServiceOrderAllocation.Status::Active, Resource."No.", AllocatedHours);
        ServiceItemLine.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.", ServiceItemLine."Line No.");
        RepairStatus.Get(ServiceItemLine."Repair Status Code");
        RepairStatus.TestField("Partly Serviced", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeRepairStatusFinished()
    var
        Status: Option Finished,"Partly Serviced",Referred;
    begin
        // Covers document number TC0090 - refer to TFS ID 21724.
        // Test Repair Status as Finished on Service Order Allocation after updating of Repair Status on Service Item Line as
        // Finished.

        ChangeAndVerifyRepairStatus(Status::Finished);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeRepairStatusPartlyServed()
    var
        Status: Option Finished,"Partly Serviced",Referred;
    begin
        // Covers document number TC0090 - refer to TFS ID 21724.
        // Test Repair Status Reallocation Needed on Service Order Allocation after updating of Repair Status on Service Item Line as
        // Partly Served.

        ChangeAndVerifyRepairStatus(Status::"Partly Serviced");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeRepairStatusReferred()
    var
        Status: Option Finished,"Partly Serviced",Referred;
    begin
        // Covers document number TC0090 - refer to TFS ID 21724.
        // Test Repair Status Reallocation Needed on Service Order Allocation after updating of Repair Status on Service Item Line as
        // Referred.

        ChangeAndVerifyRepairStatus(Status::Referred);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DispatchBoardReportForOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number TC0091 - refer to TFS ID 21724.
        // Test Dispatch Board Report for Service Order.

        // 1. Setup: Create Service Order - Service Header, Service Item, Service Item Line.
        CreateServiceOrderOneLine(ServiceHeader, ServiceItemLine);

        GenerateVerifyDispatchReport(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DispatchBoardReportForQuote()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number TC0091 - refer to TFS ID 21724.
        // Test Dispatch Board Report for Service Quote.

        // 1. Setup: Create Service Quote - Service Item, Service Header and Service Item Line.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, '');
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        GenerateVerifyDispatchReport(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLoadLevelReport()
    var
        Resource: Record Resource;
        VATPostingSetup: Record "VAT Posting Setup";
        SelectionValue: Option Quantity,Cost,Price;
    begin
        // Covers document number TC0091 - refer to TFS ID 21724.
        // Test Service Load Level Report.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Resource and update Vat Prod. Posting Group.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryResource.CreateResource(Resource, VATPostingSetup."VAT Bus. Posting Group");

        // 3. Verify: Generation of Service Load Level Report with data.
        VerifyServiceLoadLevelReport(Resource."No.", SelectionValue::Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLoadLevelForQuantity()
    var
        SelectionValue: Option Quantity,Cost,Price;
    begin
        // Covers document number TC0091 - refer to TFS ID 21724.
        // Test Service Load Level Report for Quantity.

        GenerateServiceLoadLevelReport(SelectionValue::Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLoadLevelForCost()
    var
        SelectionValue: Option Quantity,Cost,Price;
    begin
        // Covers document number TC0091 - refer to TFS ID 21724.
        // Test Service Load Level Report for Cost.

        GenerateServiceLoadLevelReport(SelectionValue::Cost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLoadLevelForPrice()
    var
        SelectionValue: Option Quantity,Cost,Price;
    begin
        // Covers document number TC0091 - refer to TFS ID 21724.
        // Test Service Load Level Report for Price.

        GenerateServiceLoadLevelReport(SelectionValue::Price);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPlanningForService()
    var
        ServiceHeader: Record "Service Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // Check Quantity on Order Planning Worksheet for Service Order after running Calculate Plan.

        // Setup: Create Service Order for Item having Zero inventory.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        CreateServiceLineWithItem(ServiceHeader);

        // Exercise: Run Calculate Plan from Order Planning Worksheet.
        LibraryPlanning.CalculateOrderPlanService(RequisitionLine);

        // Verify: Verify that Requisition Line has same quantity as on Service Order.
        VerifyRequisitionLine(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderForServiceDemand()
    var
        ServiceHeader: Record "Service Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // Check Creation of Purchase Order after doing Make Order for Service Demand from Order Planning.

        // Setup: Create Service Order for Item having Zero inventory. Run Calculate Plan from Order Planning Worksheet.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        CreateServiceLineWithItem(ServiceHeader);
        LibraryPlanning.CalculateOrderPlanService(RequisitionLine);

        // Exercise: Make Order from Order Planning Worksheet.
        MakeSupplyOrdersActiveOrder(ServiceHeader."No.");

        // Verify: Verify that Purchase Order has been created with same quantity as on Service Line.
        VerifyPurchaseOrder(ServiceHeader."No.");

        // Tear Down: Delete the earlier created Manufacturing User Template.
        DeleteManufacturingUserTemplate();
    end;

    local procedure CreateItemWithVendorNo(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateResourceSkill(var ResourceSkill: Record "Resource Skill"; Type: Enum "Resource Skill Type"; No: Code[20])
    var
        SkillCode: Record "Skill Code";
    begin
        LibraryResource.CreateSkillCode(SkillCode);
        LibraryResource.CreateResourceSkill(ResourceSkill, Type, No, SkillCode.Code);
    end;

    local procedure CreateServiceLineWithItem(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItemWithVendorNo());
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Required field - value is not important.
        ServiceLine.Validate("Needed by Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));  // Used Random to calculate the Needed By Date.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineWithResource(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo());
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Required field - value is not important to test case.
        ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
        ServiceLine.Validate("Qty. to Consume", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceItemLine(var ServiceItemLine: Record "Service Item Line"; ServiceHeader: Record "Service Header")
    var
        ServiceItem: Record "Service Item";
        RepairStatus: Record "Repair Status";
        Counter: Integer;
    begin
        // Create 2 to 10 Service Item Lines - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(8) do begin
            Clear(ServiceItem);
            LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
            LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

            RepairStatus.Init();
            RepairStatus.SetRange(Initial, true);
            RepairStatus.FindFirst();
            ServiceItemLine.Validate("Repair Status Code", RepairStatus.Code);
            ServiceItemLine.Modify(true);
        end;
    end;

    local procedure CreateServiceItemResourceSkill(var ServiceItem: Record "Service Item"; var ResourceSkill: Record "Resource Skill"; var Item: Record Item)
    begin
        // Create Service Item, Update Service Item Group Code, Create Skill Codes Update it on the - Service Item, Item.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, '');
        UpdateServiceItemGroupCode(ServiceItem);
        CreateResourceSkill(ResourceSkill, ResourceSkill.Type::"Service Item", ServiceItem."No.");
        UpdateItemServiceItemGroup(Item, ServiceItem."Service Item Group Code");
        Item.Get(Item."No.");
        CreateResourceSkill(ResourceSkill, ResourceSkill.Type::Item, Item."No.");
    end;

    local procedure CreateServiceOrder(var ServiceItemLine: Record "Service Item Line")
    var
        ServiceHeader: Record "Service Header";
    begin
        // Create a new Service Order - Service Header, Service Item, Service Item Line.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, '');
        CreateServiceItemLine(ServiceItemLine, ServiceHeader);
    end;

    local procedure CreateServiceOrderOneLine(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line")
    var
        ServiceItem: Record "Service Item";
    begin
        // Create a new Service Item, Service Order - Service Header, One Service Item Line.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, '');
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure DeleteManufacturingUserTemplate()
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        ManufacturingUserTemplate.Get(UserId);
        ManufacturingUserTemplate.Delete(true);
    end;

    local procedure GenerateServiceLoadLevelReport(SelectionValue: Option Quantity,Cost,Price)
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // 1. Setup: Create a new Service Order - Service Header, Service Item Line and Service Line with Type Resource and Post as Ship and
        // Consume.
        CreateServiceOrderOneLine(ServiceHeader, ServiceItemLine);
        CreateServiceLineWithResource(ServiceLine, ServiceHeader, ServiceItemLine."Service Item No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // 2. Exercise: Modify Qty. to Ship Field on Service Line, Post Service Order as Ship and Invoice.
        ModifyQuantityToShip(ServiceHeader."No.");
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify that Resource Ledger Entry created after post Ship and Invoice and Service Load Level Report created with data.
        VerifyResourceLedgerEntry(ServiceHeader."No.");
        VerifyServiceLoadLevelReport(ServiceLine."No.", SelectionValue);
    end;

    local procedure GenerateVerifyDispatchReport(ServiceHeader: Record "Service Header")
    var
        DispatchBoard: Report "Dispatch Board";
        FilePath: Text[1024];
    begin
        // 2. Exercise: Save Dispatch Board Report as XML and XLSX in local Temp folder.
        DispatchBoard.SetTableView(ServiceHeader);
        FilePath := TemporaryPath + Format(ServiceHeader."Document Type") + ServiceHeader."No." + '.xlsx';
        DispatchBoard.SaveAsExcel(FilePath);

        // 3. Verify: Verify that Saved file has some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    local procedure ChangeAndVerifyRepairStatus(Status: Option Finished,"Partly Serviced",Referred)
    var
        Resource: Record Resource;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderAllocation: Record "Service Order Allocation";
        AllocatedHours: Decimal;
    begin
        // 1. Setup: Create a new Service Order - Service Header, Service Item, Service Item Line.
        CreateServiceOrderOneLine(ServiceHeader, ServiceItemLine);

        // 2. Exercise: Allocate Resource to All the Service Items with Resource Availability Form, Update Repair Status Code
        // on Service Item Line.
        AllocatedHours := LibraryRandom.RandInt(10);  // Required field - value is not important to test case.
        LibraryResource.FindResource(Resource);
        UpdateServiceOrderAllocation(ServiceOrderAllocation, ServiceItemLine."Document No.", Resource."No.", '', AllocatedHours);

        // 3. Verify: Verify Status other values on Service allocation.
        case Status of
            Status::Finished:
                begin
                    UpdateRepairStatusFinished(ServiceItemLine);
                    VerifyValuesServiceAllocation(
                      ServiceItemLine, ServiceOrderAllocation.Status::Finished, Resource."No.", '', WorkDate(), AllocatedHours);
                end;
            Status::"Partly Serviced":
                begin
                    UpdateRepairStatusPartlyServed(ServiceItemLine);
                    VerifyValuesServiceAllocation(
                      ServiceItemLine, ServiceOrderAllocation.Status::"Reallocation Needed", Resource."No.", '', WorkDate(), AllocatedHours);
                end;
            Status::Referred:
                begin
                    UpdateRepairStatusReferred(ServiceItemLine);
                    VerifyValuesServiceAllocation(
                      ServiceItemLine, ServiceOrderAllocation.Status::"Reallocation Needed", Resource."No.", '', WorkDate(), AllocatedHours);
                end;
        end;
    end;

    local procedure DeleteSkillCode(Type: Enum "Resource Skill Type"; No: Code[20]; SkillCode: Code[10])
    var
        ResourceSkill: Record "Resource Skill";
        ResourceSkillMgt: Codeunit "Resource Skill Mgt.";
    begin
        ResourceSkill.Get(Type, No, SkillCode);
        ResourceSkillMgt.PrepareRemoveMultipleResSkills(ResourceSkill);
        ResourceSkillMgt.RemoveResSkill(ResourceSkill);
        ResourceSkill.Delete(true);
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; DocumentNo: Code[20]; No: Code[20]; LocationCode: Code[10])
    begin
        RequisitionLine.SetRange("Demand Order No.", DocumentNo);
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.SetRange("Location Code", LocationCode);
        RequisitionLine.FindFirst();
    end;

    local procedure GetManufacturingUserTemplate(var ManufacturingUserTemplate: Record "Manufacturing User Template"; MakeOrder: Option)
    begin
        LibraryPlanning.CreateManufUserTemplate(
          ManufacturingUserTemplate, UserId, MakeOrder, ManufacturingUserTemplate."Create Purchase Order"::"Make Purch. Orders",
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned",
          ManufacturingUserTemplate."Create Transfer Order"::"Make Trans. Orders");
    end;

    local procedure MakeSupplyOrdersActiveOrder(DocumentNo: Code[20])
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Demand Order No.", DocumentNo);
        RequisitionLine.FindFirst();
        GetManufacturingUserTemplate(ManufacturingUserTemplate, ManufacturingUserTemplate."Make Orders"::"The Active Order");
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);
    end;

    local procedure ModifyQuantityToShip(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindSet();
        repeat
            ServiceLine.Validate("Qty. to Ship", ServiceLine."Qty. to Ship" * LibraryUtility.GenerateRandomFraction());
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure RunResourceAllocationForm(ServiceItemLine: Record "Service Item Line")
    var
        ServiceOrderAllocation: Record "Service Order Allocation";
        ResourceAllocations: Page "Resource Allocations";
    begin
        ServiceOrderAllocation.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceOrderAllocation.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceOrderAllocation.SetRange("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceOrderAllocation.FindFirst();
        Clear(ResourceAllocations);
        ResourceAllocations.SetTableView(ServiceOrderAllocation);
        ResourceAllocations.SetRecord(ServiceOrderAllocation);
        ResourceAllocations.Run();
    end;

    local procedure UpdateRepairStatusInitial(var ServiceItemLine: Record "Service Item Line")
    var
        RepairStatus: Record "Repair Status";
    begin
        RepairStatus.SetRange(Initial, true);
        if not RepairStatus.FindFirst() then begin
            LibraryService.CreateRepairStatus(RepairStatus);
            RepairStatus.Validate(Initial, true);
            RepairStatus.Modify(true);
        end;
        ServiceItemLine.Validate("Repair Status Code", RepairStatus.Code);
        ServiceItemLine.Modify(true);
    end;

    local procedure UpdateRepairStatusFinished(var ServiceItemLine: Record "Service Item Line")
    var
        RepairStatus: Record "Repair Status";
    begin
        RepairStatus.SetRange(Finished, true);
        if not RepairStatus.FindFirst() then begin
            LibraryService.CreateRepairStatus(RepairStatus);
            RepairStatus.Validate(Finished, true);
            RepairStatus.Modify(true);
        end;
        ServiceItemLine.Validate("Repair Status Code", RepairStatus.Code);
        ServiceItemLine.Modify(true);
    end;

    local procedure UpdateRepairStatusPartlyServed(var ServiceItemLine: Record "Service Item Line")
    var
        RepairStatus: Record "Repair Status";
    begin
        RepairStatus.SetRange("Partly Serviced", true);
        if not RepairStatus.FindFirst() then begin
            LibraryService.CreateRepairStatus(RepairStatus);
            RepairStatus.Validate("Partly Serviced", true);
            RepairStatus.Modify(true);
        end;
        ServiceItemLine.Validate("Repair Status Code", RepairStatus.Code);
        ServiceItemLine.Modify(true);
    end;

    local procedure UpdateRepairStatusReferred(var ServiceItemLine: Record "Service Item Line")
    var
        RepairStatus: Record "Repair Status";
    begin
        RepairStatus.SetRange(Referred, true);
        if not RepairStatus.FindFirst() then begin
            LibraryService.CreateRepairStatus(RepairStatus);
            RepairStatus.Validate(Referred, true);
            RepairStatus.Modify(true);
        end;
        ServiceItemLine.Validate("Repair Status Code", RepairStatus.Code);
        ServiceItemLine.Modify(true);
    end;

    local procedure UpdateRepairStatusInProcess(var ServiceItemLine: Record "Service Item Line")
    var
        RepairStatus: Record "Repair Status";
    begin
        RepairStatus.SetRange("In Process", true);
        if not RepairStatus.FindFirst() then begin
            LibraryService.CreateRepairStatus(RepairStatus);
            RepairStatus.Validate("In Process", true);
            RepairStatus.Modify(true);
        end;
        ServiceItemLine.Validate("Repair Status Code", RepairStatus.Code);
        ServiceItemLine.Modify(true);
    end;

    local procedure UpdateServiceItemGroupCode(var ServiceItem: Record "Service Item")
    var
        ServiceItemGroup: Record "Service Item Group";
    begin
        LibraryService.FindServiceItemGroup(ServiceItemGroup);
        ServiceItem.Validate("Service Item Group Code", ServiceItemGroup.Code);
        ServiceItem.Modify(true);
    end;

    local procedure UpdateServiceOrderAllocation(var ServiceOrderAllocation: Record "Service Order Allocation"; DocumentNo: Code[20]; ResourceNo: Code[20]; ResourceGroupNo: Code[20]; AllocatedHours: Decimal)
    begin
        ServiceOrderAllocation.SetRange("Document Type", ServiceOrderAllocation."Document Type"::Order);
        ServiceOrderAllocation.SetRange("Document No.", DocumentNo);
        ServiceOrderAllocation.FindFirst();
        UpdateValuesServiceAllocation(ServiceOrderAllocation, ResourceNo, ResourceGroupNo, AllocatedHours);
    end;

    local procedure UpdateAllocationOnSecondLine(var ServiceOrderAllocation: Record "Service Order Allocation"; DocumentNo: Code[20]; ResourceNo: Code[20]; ResourceGroupNo: Code[20]; AllocatedHours: Decimal)
    begin
        ServiceOrderAllocation.SetRange("Document Type", ServiceOrderAllocation."Document Type"::Order);
        ServiceOrderAllocation.SetRange("Document No.", DocumentNo);
        ServiceOrderAllocation.Next(2);
        UpdateValuesServiceAllocation(ServiceOrderAllocation, ResourceNo, ResourceGroupNo, AllocatedHours);
    end;

    local procedure UpdateValuesServiceAllocation(var ServiceOrderAllocation: Record "Service Order Allocation"; ResourceNo: Code[20]; ResourceGroupNo: Code[20]; AllocatedHours: Decimal)
    begin
        ServiceOrderAllocation.Validate("Resource No.", ResourceNo);
        ServiceOrderAllocation.Validate("Resource Group No.", ResourceGroupNo);
        ServiceOrderAllocation.Validate("Allocation Date", WorkDate());
        ServiceOrderAllocation.Validate("Allocated Hours", AllocatedHours);
        ServiceOrderAllocation.Modify(true);
    end;

    local procedure UpdateItemServiceItemGroup(var Item: Record Item; ServiceItemGroupCode: Code[10])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Service Item Group", ServiceItemGroupCode);
        Item.Modify(true);
    end;

    local procedure VerifyAllocationsOnServiceItem(DocumentNo: Code[20]; Status: Option; ResourceNo: Code[20]; ResourceGroupNo: Code[20]; AllocatedHours: Decimal)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderAllocation: Record "Service Order Allocation";
    begin
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type"::Order);
        ServiceItemLine.SetRange("Document No.", DocumentNo);
        ServiceItemLine.FindSet();
        ServiceOrderAllocation.SetRange("Document Type", ServiceOrderAllocation."Document Type"::Order);
        ServiceOrderAllocation.SetRange("Document No.", DocumentNo);
        AllocatedHours := Round(AllocatedHours / ServiceOrderAllocation.Count, 0.1);
        repeat
            ServiceOrderAllocation.SetRange("Service Item Line No.", ServiceItemLine."Line No.");
            ServiceOrderAllocation.FindFirst();
            ServiceOrderAllocation.TestField(Status, Status);
            ServiceOrderAllocation.TestField("Allocated Hours", AllocatedHours);
            ServiceOrderAllocation.TestField("Service Item No.", ServiceItemLine."Service Item No.");
            ServiceOrderAllocation.TestField("Allocation Date", WorkDate());
            ServiceOrderAllocation.TestField("Resource Group No.", ResourceGroupNo);
            ServiceOrderAllocation.TestField("Resource No.", ResourceNo);
        until ServiceItemLine.Next() = 0
    end;

    local procedure VerifyCancelServiceAllocation(DocumentNo: Code[20]; ServiceItemNo: Code[20]; ResourceNo: Code[20]; AllocatedHours: Decimal)
    var
        ServiceOrderAllocation: Record "Service Order Allocation";
    begin
        ServiceOrderAllocation.SetRange("Document Type", ServiceOrderAllocation."Document Type"::Order);
        ServiceOrderAllocation.SetRange("Document No.", DocumentNo);
        ServiceOrderAllocation.SetRange("Service Item No.", ServiceItemNo);
        ServiceOrderAllocation.SetRange(Status, ServiceOrderAllocation.Status::Canceled);
        ServiceOrderAllocation.FindFirst();
        ServiceOrderAllocation.TestField("Resource No.", ResourceNo);
        ServiceOrderAllocation.TestField("Allocation Date", WorkDate());
        ServiceOrderAllocation.TestField("Allocated Hours", AllocatedHours);
    end;

    local procedure VerifyChangeAllocationStatus(DocumentNo: Code[20]; ServiceItemNo: Code[20]; Status: Option; ResourceNo: Code[20]; AllocatedHours: Decimal)
    var
        ServiceOrderAllocation: Record "Service Order Allocation";
    begin
        ServiceOrderAllocation.SetRange("Document Type", ServiceOrderAllocation."Document Type"::Order);
        ServiceOrderAllocation.SetRange("Document No.", DocumentNo);
        ServiceOrderAllocation.SetRange("Service Item No.", ServiceItemNo);
        ServiceOrderAllocation.SetRange(Status, Status);
        ServiceOrderAllocation.SetRange("Resource No.", ResourceNo);
        ServiceOrderAllocation.SetRange("Allocation Date", WorkDate());
        ServiceOrderAllocation.SetRange("Allocated Hours", AllocatedHours);
        ServiceOrderAllocation.FindFirst();
    end;

    local procedure VerifyNoOfAllocations(DocumentNo: Code[20]; NoOfAllocations: Integer)
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(ServiceHeader."Document Type"::Order, DocumentNo);
        ServiceHeader.CalcFields("No. of Allocations");
        ServiceHeader.TestField("No. of Allocations", NoOfAllocations);
    end;

    local procedure VerifyPurchaseOrder(DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
        Item: Record Item;
    begin
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindFirst();
        Item.Get(ServiceLine."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ServiceLine."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Buy-from Vendor No.", Item."Vendor No.");
        PurchaseLine.TestField("Location Code", ServiceLine."Location Code");
        PurchaseLine.TestField(Quantity, ServiceLine.Quantity);
        PurchaseLine.TestField("Expected Receipt Date", ServiceLine."Needed by Date");
    end;

    local procedure VerifyRequisitionLine(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        RequisitionLine: Record "Requisition Line";
    begin
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindFirst();
        FindRequisitionLine(RequisitionLine, ServiceLine."Document No.", ServiceLine."No.", ServiceLine."Location Code");
        RequisitionLine.TestField("Due Date", ServiceLine."Needed by Date");
        RequisitionLine.TestField(Quantity, ServiceLine.Quantity);
        RequisitionLine.TestField("Demand Quantity", ServiceLine.Quantity);
        RequisitionLine.TestField("Needed Quantity", ServiceLine.Quantity);
    end;

    local procedure VerifyResourceLedgerEntry(OrderNo: Code[20])
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.SetRange(Type, ServiceInvoiceLine.Type::Resource);
        ServiceInvoiceLine.FindFirst();
        ResLedgerEntry.SetRange("Document No.", ServiceInvoiceLine."Document No.");
        ResLedgerEntry.FindFirst();
        ResLedgerEntry.TestField(Quantity, -ServiceInvoiceLine.Quantity);
        ResLedgerEntry.TestField("Order Type", ResLedgerEntry."Order Type"::Service);
        ResLedgerEntry.TestField("Order No.", ServiceInvoiceHeader."Order No.");
        ResLedgerEntry.TestField("Order Line No.", ServiceInvoiceLine."Line No.");
    end;

    local procedure VerifyServiceLoadLevelReport(ResourceNo: Code[20]; Selection: Option)
    var
        Resource: Record Resource;
        ServiceLoadLevel: Report "Service Load Level";
        FilePath: Text[1024];
    begin
        Resource.SetRange("No.", ResourceNo);
        Resource.Get(ResourceNo);
        ServiceLoadLevel.SetTableView(Resource);
        ServiceLoadLevel.InitializeRequest(Selection);
        FilePath := TemporaryPath + Format(Resource.Type) + ResourceNo + '.xlsx';
        ServiceLoadLevel.SaveAsExcel(FilePath);
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath)
    end;

    local procedure VerifyStatusServiceAllocation(DocumentNo: Code[20]; Status: Option)
    var
        ServiceOrderAllocation: Record "Service Order Allocation";
    begin
        ServiceOrderAllocation.SetRange("Document Type", ServiceOrderAllocation."Document Type"::Order);
        ServiceOrderAllocation.SetRange("Document No.", DocumentNo);
        ServiceOrderAllocation.FindFirst();
        ServiceOrderAllocation.TestField(Status, Status);
    end;

    local procedure VerifyValuesServiceAllocation(ServiceItemLine: Record "Service Item Line"; Status: Option; ResourceNo: Code[20]; ResourceGroupNo: Code[20]; AllocationDate: Date; AllocatedHours: Decimal)
    var
        ServiceOrderAllocation: Record "Service Order Allocation";
    begin
        ServiceOrderAllocation.SetRange("Document Type", ServiceOrderAllocation."Document Type"::Order);
        ServiceOrderAllocation.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceOrderAllocation.SetRange("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceOrderAllocation.FindFirst();
        ServiceOrderAllocation.TestField(Status, Status);
        ServiceOrderAllocation.TestField("Allocated Hours", AllocatedHours);
        ServiceOrderAllocation.TestField("Service Item No.", ServiceItemLine."Service Item No.");
        ServiceOrderAllocation.TestField("Allocation Date", AllocationDate);
        ServiceOrderAllocation.TestField("Resource Group No.", ResourceGroupNo);
        ServiceOrderAllocation.TestField("Resource No.", ResourceNo);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StringMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        // Choose the first option of the string menu.
        Choice := 1
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StringMenuHandlerOptionTwo(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        // Choose the Second option of the string menu.
        Choice := 2;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AllocationFormHandlerWithAvail(var ResourceAllocations: Page "Resource Allocations")
    var
        ResAvailabilityService: Page "Res. Availability (Service)";
    begin
        // Run the Res. Availability (Service) form from Resource Allocations form.
        ServiceOrderAllocation2.FindFirst();
        ResourceAllocations.GetRecord(ServiceOrderAllocation2);
        ResAvailabilityService.SetData(
          ServiceOrderAllocation2."Document Type".AsInteger(), ServiceOrderAllocation2."Document No.", ServiceOrderAllocation2."Service Item Line No.",
          ServiceOrderAllocation2."Entry No.");
        if ServiceOrderAllocation2."Resource No." <> '' then
            ResAvailabilityService.SetRecord(Resource2);
        ResAvailabilityService.RunModal();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure AllocationFormHandlerWithGroup(var ResourceAllocations: Page "Resource Allocations")
    var
        ResGrAvailabilityService: Page "Res.Gr. Availability (Service)";
    begin
        // Run the Res. Group Availability (Service) form from Resource Allocations form.
        ServiceOrderAllocation2.FindFirst();
        ResourceAllocations.GetRecord(ServiceOrderAllocation2);
        ResGrAvailabilityService.SetData(
          ServiceOrderAllocation2."Document Type".AsInteger(), ServiceOrderAllocation2."Document No.", ServiceOrderAllocation2."Entry No.");
        if ServiceOrderAllocation2."Resource No." <> '' then
            ResGrAvailabilityService.SetRecord(Resource2);
        ResGrAvailabilityService.RunModal();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailabilityModalFormHandler(var ResAvailabilityService: Page "Res. Availability (Service)"; var Response: Action)
    var
        ServAllocationManagement: Codeunit ServAllocationManagement;
    begin
        // Call the ServAllocationManagement code unit to allocate Resource.
        ServAllocationManagement.AllocateDate(
          ServiceOrderAllocation2."Document Type".AsInteger(), ServiceOrderAllocation2."Document No.", ServiceOrderAllocation2."Entry No.",
          ResourceNo2, ResourceGroupNo2, AllocationDate2, AllocatedHours2);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MakeSupplyOrdersPageHandler(var MakeSupplyOrders: Page "Make Supply Orders"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ResourceCancelModalFormHandler(var CancelledAllocationReasons: Page "Cancelled Allocation Reasons"; var Response: Action)
    begin
        Response := ACTION::Yes;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GroupAvailModalFormHandler(var ResGrAvailabilityService: Page "Res.Gr. Availability (Service)"; var Response: Action)
    var
        ServAllocationManagement: Codeunit ServAllocationManagement;
    begin
        // Call the ServAllocationManagement code unit to allocate Resource.
        ServAllocationManagement.AllocateDate(
          ServiceOrderAllocation2."Document Type".AsInteger(), ServiceOrderAllocation2."Document No.", ServiceOrderAllocation2."Entry No.",
          ResourceNo2, ResourceGroupNo2, AllocationDate2, AllocatedHours2);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReAllocationModalFormHandler(var ReallocationEntryReasons: Page "Reallocation Entry Reasons"; var Response: Action)
    begin
        Response := ACTION::Yes;
    end;
}


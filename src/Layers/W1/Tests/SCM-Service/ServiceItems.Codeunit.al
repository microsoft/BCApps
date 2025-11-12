// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Resources;
using Microsoft.Service.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.TestLibraries.Utilities;

codeunit 136103 "Service Items"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Service] [Service Item]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryERM: Codeunit "Library - ERM";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        ServiceItemNoForComponent: Code[20];
        ServiceItemCreationErr: Label 'The number of %1 created must match the Quantity of Item in Sales Line.';
        ServiceItemReplacedErr: Label 'The number of %1 replaced must be equal to %2 for %3 %4 and %5 %6.', Comment = '%1 = Table Caption,%2 = Field Value,%3 = Field Caption,%4 = Field Value,%5 = Field Caption,%6 = Field Value';
        ServiceItemDuplicateErr1: Label 'You cannot change the Customer No. in the service item because of the following outstanding service order line:';
        ServiceItemDuplicateErr2: Label 'Order %1, line %2, service item number %3, serial number %4, customer %5, ship-to code %6.', Comment = '%1 - Service Order No.;%2 - Serice Line No.;%3 - Service Item No.;%4 - Serial No.;%5 - Customer No.;%6 - Ship to Code.';
        RecordExistsErr: Label '%1 %2 must not exist after deletion.', Comment = '%1 = Table Caption,%2 = Field Value';
        SerialNo: Code[50];
        CopyComponentsFrom: Option;
        ItemTrackingLinesAssignment: Option "None",AssignSerialNo,AssignLotNo,SelectEntries,AssistEdit;
        Replacement: Option "Temporary",Permanent;
        isInitialized: Boolean;
        BOMComponentErr: Label 'No. of %1 must be %2.';
        ExpectedConfirmQst: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        ServiceItemCreationDuplicateErr: Label 'There are more than 1 Service Items with the same Serial No. %1';
        VATIdentifierErr: Label 'Wrong VAT Identifier value.';
        CheckIfCanBeDeletedServiceItemDatePeriodErr: Label 'You cannot delete %1 %2 because it has ledger entries in a fiscal year that has not been closed yet.', Comment = '.';
        CheckIfCanBeDeletedServiceItemOpenErr: Label 'You cannot delete %1 %2 because there are one or more open ledger entries.', Comment = '.';
        ParentServiceItemNoMustHaveValueErr: Label 'Parent Service Item No. must have a value in Service Item Component';
        IncorrectValueErr: Label 'Incorrect value of %1.%2.';
        GlobalVendorNo: Code[20];
        GlobalCustomerNo: Code[20];
        GlobalItemNo: Code[20];

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceItemValues()
    var
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // [SCENARIO] Verify that the value of the Parts Used field in the Service Item is the product of the Unit Cost applicable and the Quantity in the Service Line.
        // 1. Create a new Service Item with a random Customer and random Sales Unit Cost, Sales Unit Price, Default Contract Cost and
        // Default Contract Value.
        // 2. Create a Service Order for the Service Item - Create Service Header, Service Item Line and Service Line with random Item and
        // random Quantity. Post the Service Order as Ship and Invoice.
        // 3. Check that the values in the Service Item table are the same as Service Item Line table.
        // 4. Verify that the value of the Parts Used field in the Service Item is the product of the Unit Cost applicable and the Quantity in the Service Line.

        // [GIVEN] Setup demonstration data.
        Initialize();

        // [WHEN] Create and Post Service Order as Ship and Invoice.
        CreateServiceItemWithAmounts(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLineWithItem(ServiceLine, Item, ServiceHeader, ServiceItem."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Match values in Service Item table and the Service Item Line table. Match values in Service Item table and the Service Item Line table.
        VerifyServiceItemStatistics(ServiceLine, ServiceItem);
        VerifyServiceItemTrendscape(Item, ServiceLine, ServiceItem);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTroubleshootngAssgnmntItem()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        TroubleshootingLineNo: Code[20];
    begin
        // [SCENARIO] Verify that the Troubleshooting assigned to the Item has been populated on the Service Item linked to it.
        // 1. Find a random Item and create and assign Troubleshooting to it.
        // 2. Create a new Service Item with a random Customer and link Item to the Service Item.
        // 3. Verify that the Troubleshooting assigned to the Item has been populated on the Service Item linked to it.

        // [GIVEN] Setup demonstration data, create and assign Troubleshooting to the Item and create Service Item.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndAssignTroubleshooting(TroubleshootingLineNo, "Troubleshooting Item Type"::Item, Item."No.");
        CreateServiceItem(ServiceItem);

        // [WHEN] Attach Item to Service Item.
        ServiceItem.Validate("Item No.", Item."No.");
        ServiceItem.Modify(true);

        // [THEN] Check that the Troubleshooting assigned to the Item has been populated on the Service Item linked to it.
        VerifyTroubleshootingAssignment(ServiceItem, TroubleshootingLineNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTrblshtngAssgnmntServGroup()
    var
        ServiceItem: Record "Service Item";
        TroubleshootingLineNo: Code[20];
        ServiceItemGroupCode: Code[10];
    begin
        // [SCENARIO] Verify that the Troubleshooting assigned to the Service Item Group has been populated on the Service Item linked to it.
        // 1. Create a new Service Item Group and create and assign Troubleshooting to it.
        // 2. Create a new Service Item with a random Customer and link Service Item Group to it.
        // 3 Verify that the Troubleshooting assigned to the Service Item Group has been populated on the Service Item linked to it.

        // [GIVEN] Setup demonstration data, create Service Item Group and create and assign Troubleshooting to it. Create Service Item.
        Initialize();
        ServiceItemGroupCode := CreateServiceItemGroup();
        CreateAndAssignTroubleshooting(TroubleshootingLineNo, "Troubleshooting Item Type"::"Service Item Group", ServiceItemGroupCode);
        CreateServiceItem(ServiceItem);

        // [WHEN] Attach Service Item Group to Service Item.
        ServiceItem.Validate("Service Item Group Code", ServiceItemGroupCode);
        ServiceItem.Modify(true);

        // [THEN] Check that the Troubleshooting assigned to the Service Item Group has been populated on the Service Item linked to it.
        VerifyTroubleshootingAssignment(ServiceItem, TroubleshootingLineNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestServItemCreationFrmServOrd()
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServItemManagement: Codeunit ServItemManagement;
        Type: Option Item,"Service Item Group";
    begin
        // 1. Create a new Service Order with a random Customer - Create a Service Item Line with no Service Item and random Item.
        // 2. Create a new Service Item from Service Order.
        // 3. Check that the Service Item has the same Item No. as the Service Item Line.
        // [SCENARIO] Check that once Service Item has been created from the Service Item Line it cannot be created again.

        // [GIVEN] Setup demonstration data. Create Service Header and Service Item Line.
        Initialize();
        CreateServOrderForServItemCrea(ServiceItemLine, Type::Item);

        // [WHEN] Create Service Item from Service Order.
        ServItemManagement.CreateServItemOnServItemLine(ServiceItemLine);

        // [THEN] Check that the Service Item has the same Item No. as the Service Item Line.
        ServiceItem.Get(ServiceItemLine."Service Item No.");
        ServiceItem.TestField("Item No.", ServiceItemLine."Item No.");

        // [THEN] Verify that Service Item cannot be created from the Service Item Line again.
        asserterror ServItemManagement.CreateServItemOnServItemLine(ServiceItemLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestServItemCreationWithServGr()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServItemManagement: Codeunit ServItemManagement;
        Type: Option Item,"Service Item Group";
    begin
        // 1. Create a new Service Order with a random Customer - Create a Service Item Line with no Service Item.
        // 2. Create a new Service Item from Service Order.
        // 3. Check that the Service Item has the same Service Item Group Code as the Service Item Line.
        // [SCENARIO] Check that the Service Item has the same Service Item Group Code as the Service Item Line.

        // [GIVEN] Setup demonstration data.
        Initialize();

        // [GIVEN] Create Service Header, Service Line and Service Item Group. Assign Service Item Group to the Service Line.
        CreateServOrderForServItemCrea(ServiceItemLine, Type::"Service Item Group");

        // [WHEN] Create Service Item from Service Order.
        ServItemManagement.CreateServItemOnServItemLine(ServiceItemLine);

        // [THEN] Check that the Service Item has the same Service Item Group Code as the Service Item Line.
        ServiceItem.Get(ServiceItemLine."Service Item No.");
        ServiceItem.TestField("Service Item Group Code", ServiceItemLine."Service Item Group Code");

        // [THEN] Verify that Service Item cannot be created from the Service Item Line again.
        asserterror ServItemManagement.CreateServItemOnServItemLine(ServiceItemLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServItemCreatnfromSalesOrd()
    var
        SalesHeader: Record "Sales Header";
        ServiceItem: Record "Service Item";
        Item: Record Item;
        ServiceItemGroup: Record "Service Item Group";
        Assert: Codeunit Assert;
        Quantity: Decimal;
    begin
        // 1. Create a new Service Item Group with the field Create Service Item as TRUE.
        // 2. Create a new Item with the Service Item Group created earlier.
        // 3. Create a new Sales Header with a random Customer and a new Sales Line with random Quantity. Post it as Ship and Invoice.
        // [SCENARIO] Verify that the number of the Service Items created match the value of the Quantity of Item in Sales Line.
        // 5. Verify the Service Item.

        // [GIVEN] Setup demonstration data.
        Initialize();

        // [GIVEN] Create Service Item Group and create a new Item with it.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Service Item Group", CreateServiceGroupForAutoCreat());
        Item.Modify(true);

        // [WHEN] Create and Post Sales Order.
        CreateSalesHeaderNoLocation(SalesHeader);
        CreateSalesLine(Quantity, SalesHeader, Item."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify that the number of Service Items created matches the Quantity on the Sales Line.
        ServiceItem.SetRange("Item No.", Item."No.");
        Assert.AreEqual(Quantity, ServiceItem.Count, StrSubstNo(ServiceItemCreationErr, ServiceItem.TableCaption()));
        ServiceItem.FindFirst();
        ServiceItem.TestField("Service Item Group Code", Item."Service Item Group");
        ServiceItemGroup.Get(ServiceItem."Service Item Group Code");
        ServiceItem.TestField("Response Time (Hours)", ServiceItemGroup."Default Response Time (Hours)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,StrMenuHandler')]
    [Scope('OnPrem')]
    procedure TestServiceItemModification()
    var
        ServiceItem: Record "Service Item";
        ResourceSkill: Record "Resource Skill";
        ServiceItem2: Record "Service Item";
        ResourceSkill2: Record "Resource Skill";
        ServiceItemGroupCode: Code[10];
    begin
        // 1. Create a new Service Item Group.
        // 2. Create a new Service Item with a random Customer and Service Item Group created earlier in Step 1.
        // 3. Modify the Service Item Group Code on the Service Item.
        // [SCENARIO] Verify that the Resource Skill attached to the Service Item has been updated according to the Service Item Group changed.

        // [GIVEN] Setup demonstration data. Create Service Item Group with Skill and a new Service Item. Attach Service Item Group to Service Item.
        Initialize();
        CreateServiceItemGrpWithSkill(ServiceItemGroupCode, ResourceSkill);
        CreateServiceItem(ServiceItem);
        ServiceItem.Validate("Service Item Group Code", ServiceItemGroupCode);
        ServiceItem.Modify(true);

        // [GIVEN] Create Service Item Group with Skill.
        CreateServiceItemGrpWithSkill(ServiceItemGroupCode, ResourceSkill2);

        // Second variable is needed to get refreshed instance of the Service Item.
        ServiceItem2.Get(ServiceItem."No.");

        // [WHEN] Modify the Service Item to attach Service Item Group to it.
        ServiceItem2.Validate("Service Item Group Code", ServiceItemGroupCode);
        ServiceItem2.Modify(true);

        // [THEN] Check that the Resource Skill attached to the Service Item earlier has been deleted.
        VerifySkillCodeDeletion(ResourceSkill);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceItemDeletion()
    var
        ServiceItem: Record "Service Item";
        Assert: Codeunit Assert;
    begin
        // 1. Create a new Service Item with a random Customer.
        // 2. Delete the Service Item.
        // [SCENARIO] Verify that the Service Item does not exist in the Service Item table after deletion.

        // [GIVEN] Setup demonstration data and create a new Service Item.
        Initialize();
        CreateServiceItem(ServiceItem);

        // [WHEN] Delete the Service Item.
        ServiceItem.Delete(true);

        // [THEN] Check that the Service Item does not exist in the Service Item table after deletion.
        Assert.IsFalse(ServiceItem.Get(ServiceItem."No."), StrSubstNo(RecordExistsErr, ServiceItem.TableCaption(), ServiceItem."No."));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ModalFormHandlerLookupOK')]
    [Scope('OnPrem')]
    procedure TestCompListCreationManual()
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceItemComponent: Record "Service Item Component";
        ServiceItemComponent2: Record "Service Item Component";
        ServiceLine: Record "Service Line";
        ItemNo: Code[20];
    begin
        // 1. Create a new Service Item with a random Customer and create two new Service Item Components of Type as Item for it.
        // 2. Create a Service Order for the Service Item.
        // 3. Create a Service Line for the Service Item with an Item that is different from the Items selected as components.
        // 4. Select the Replace Component option in the String Menu dialog box that is generated, through a String Menu handler.
        // 5. Post the Service Order as Ship.
        // 6. Verify that the Replaced Component list for the second Item selected as component is empty.
        // [SCENARIO] Verify that the Replaced Component list for the first Item selected as component has exactly one line for manual creation of components.

        // [GIVEN] Setup demonstration data and create a new Service Item with Service Item Components. Create Service Header and Service Line.
        Initialize();
        CreateServiceItemWithTwoCompon(ServiceItem, ServiceItemComponent, ServiceItemComponent2, ItemNo);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ServiceItemNoForComponent := ServiceItem."No.";

        // [WHEN] Create a Service Line for the Service Item with an Item that is different from the Items selected as components.
        CreateServiceLine(ServiceLine, ItemNo, ServiceHeader, ServiceItem."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Verify that the Replaced Component list for the first Item selected as component is 1.
        VerifyNoOfReplacedComponents(ServiceItemComponent, 1);

        // [THEN] Verify that the Replaced Component list for the second Item selected as component is empty.
        VerifyNoOfReplacedComponents(ServiceItemComponent2, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ModalFormHandlerLookupOK')]
    [Scope('OnPrem')]
    procedure TestCompListCreationAutomatic()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemNo: Code[20];
    begin
        // 1. Create a new Service Item with a random Customer and a new Item that has two BOM Components.
        // 2. Create a Service Order for the Service Item.
        // 3. Create a Service Line for the Service Item with an Item that is different from the Item created above.
        // 4. Select the Replace Component option in the String Menu dialog box that is generated, through a String Menu handler.
        // 5. Post the Service Order as Ship.
        // 6. Verify that the Replaced Component list for the second Item selected as component is empty.
        // [SCENARIO] Verify that the Replaced Component list for the first Item selected as component has exactly one line for automatic creation of components.

        // [GIVEN] Setup demonstration data and create a new Service Item with an Item having two BOM Components. Create Service Header and Service Line.
        Initialize();
        CreateServiceItemWithBOMItem(ServiceHeader, ServiceItemNoForComponent, ItemNo);

        // [WHEN] Create a Service Line for the Service Item with an Item that is different from the Item created.
        CreateServiceLine(ServiceLine, ItemNo, ServiceHeader, ServiceItemNoForComponent);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Retrieve Component List and verify that the Replaced Component list is correct.
        RetrveAndChckCompLnForServItem(ServiceItemNoForComponent);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestContractValueCalcMthdNone()
    var
        ServiceItem: Record "Service Item";
        Currency: Record Currency;
        ContractValueCalcMethod: Option "None","Based on Unit Price","Based on Unit Cost";
        ContractValuePercentage: Decimal;
        ContractValueCalcMethodOld: Option;
    begin
        // 1. Setup Service Management with - Contract Value Calc. Method as None and Contract Value % as any random value.
        // 2. Create a new Service Item with random Sales Unit Cost and random Sales Unit Price.
        // 3. Verify that the value of the Default Contract Value is 0.
        // [SCENARIO] Verify that the value of the Default Contract Value is 0 when Contract Value Calc. Method as None and Contract Value % as any random value.

        // [GIVEN] Setup demonstration data and Service Management Setup.
        Initialize();
        ContractValuePercentage := LibraryRandom.RandInt(100);
        ContractValueCalcMethodOld := ServMgtSetupForContractValCalc(ContractValueCalcMethod::None, ContractValuePercentage);

        // [WHEN] Create a Service Item with random Sales Unit Cost and Sales Unit Price.
        CreateServItemWithSalesUnitAmt(ServiceItem);

        // [THEN] Verify that the value of the Default Contract Value is 0. Verify that the value of the Default Contract Cost is the
        // [THEN] product of the Sales Unit Cost field of the Service Item and the Contract Value % field of the Service Management Setup divided by 100.
        ServiceItem.TestField("Default Contract Value", 0);
        Currency.InitRoundingPrecision();
        ServiceItem.TestField(
          "Default Contract Cost",
          Round(ServiceItem."Sales Unit Cost" * ContractValuePercentage / 100, Currency."Unit-Amount Rounding Precision"));

        // Cleanup:
        ServMgtSetupForContractValCalc(ContractValueCalcMethodOld, ContractValuePercentage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestContrctValCalcMthdNoneZero()
    var
        ServiceItem: Record "Service Item";
        ContractValueCalcMethod: Option "None","Based on Unit Price","Based on Unit Cost";
        ContractValueCalcMethodOld: Option;
    begin
        // 1. Setup Service Management with - Contract Value Calc. Method as None and Contract Value % as 0 for boundary value testing.
        // 2. Create a new Service Item with random Sales Unit Cost and random Sales Unit Price.
        // [SCENARIO] Verify that the values of the Default Contract Value and Default Contract Cost are equal to 0.

        // [GIVEN] Setup demonstration data and Service Management Setup.
        Initialize();
        ContractValueCalcMethodOld := ServMgtSetupForContractValCalc(ContractValueCalcMethod::None, 0);

        // [WHEN] Create a Service Item with random Sales Unit Cost and Sales Unit Price.
        CreateServItemWithSalesUnitAmt(ServiceItem);

        // [THEN] Verify that the values of the Default Contract Value and Default Contract Cost are 0.
        ServiceItem.TestField("Default Contract Value", 0);
        ServiceItem.TestField("Default Contract Cost", 0);

        // Cleanup:
        ServMgtSetupForContractValCalc(ContractValueCalcMethodOld, LibraryRandom.RandInt(100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestContrctValCalcMthdNoneHund()
    var
        ServiceItem: Record "Service Item";
        ContractValueCalcMethod: Option "None","Based on Unit Price","Based on Unit Cost";
        ContractValueCalcMethodOld: Option;
    begin
        // 1. Setup Service Management with - Contract Value Calc. Method as None and Contract Value % as 100 for boundary value testing.
        // 2. Create a new Service Item with random Sales Unit Cost and random Sales Unit Price.
        // 3. Verify that the value of the Default Contract Value is 0.
        // [SCENARIO] Verify that the value of the Default Contract Cost is equal to the field Sales Unit Cost of the Service Item.

        // [GIVEN] Setup demonstration data and Service Management Setup.
        Initialize();
        ContractValueCalcMethodOld := ServMgtSetupForContractValCalc(ContractValueCalcMethod::None, 100);

        // [WHEN] Create a Service Item with random Sales Unit Cost and Sales Unit Price.
        CreateServItemWithSalesUnitAmt(ServiceItem);

        // [THEN] Verify that the value of the Default Contract Value is 0 and the value of the Default Contract Cost is equal to the field Sales Unit Cost of the Service Item.
        ServiceItem.TestField("Default Contract Value", 0);
        ServiceItem.TestField("Default Contract Cost", ServiceItem."Sales Unit Cost");

        // Cleanup:
        ServMgtSetupForContractValCalc(ContractValueCalcMethodOld, LibraryRandom.RandInt(100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCntrctValueCalcMthdUnitPri()
    var
        ServiceItem: Record "Service Item";
        Currency: Record Currency;
        ContractValueCalcMethod: Option "None","Based on Unit Price","Based on Unit Cost";
        ContractValuePercentage: Decimal;
        ContractValueCalcMethodOld: Option;
    begin
        // 1. Setup Service Management with - Contract Value Calc. Method as Based on Unit Price and Contract Value % as any random value.
        // 2. Create a Service Item with random Sales Unit Cost and random Sales Unit Price.
        // 3. Verify that the value of the Default Contract Value is the product of the Sales Unit Price field of the Service Item and the
        // Contract Value % field of the Service Management Setup divided by 100.
        // [SCENARIO] Verify that the value of the Default Contract Cost is the product of the Sales Unit Cost field of the Service Item and the Contract Value % field of the Service Management Setup divided by 100.

        // [GIVEN] Setup demonstration data and Service Management Setup.
        Initialize();
        ContractValuePercentage := LibraryRandom.RandInt(100);
        ContractValueCalcMethodOld :=
          ServMgtSetupForContractValCalc(ContractValueCalcMethod::"Based on Unit Price", ContractValuePercentage);

        // [WHEN] Create a Service Item with random Sales Unit Cost and Sales Unit Price.
        CreateServItemWithSalesUnitAmt(ServiceItem);

        // [THEN] Verify that the value of the Default Contract Value is the product of the Sales Unit Price field of the Service Item and
        // [THEN] the Contract Value % field of the Service Management Setup divided by 100.
        Currency.InitRoundingPrecision();
        ServiceItem.TestField(
          "Default Contract Value",
          Round(ServiceItem."Sales Unit Price" * ContractValuePercentage / 100, Currency."Unit-Amount Rounding Precision"));

        // [THEN] Verify that the value of the Default Contract Cost is the product of the Sales Unit Cost field of the Service Item and
        // [THEN] the Contract Value % field of the Service Management Setup divided by 100.
        ServiceItem.TestField(
          "Default Contract Cost",
          Round(ServiceItem."Sales Unit Cost" * ContractValuePercentage / 100, Currency."Unit-Amount Rounding Precision"));

        // Cleanup:
        ServMgtSetupForContractValCalc(ContractValueCalcMethodOld, ContractValuePercentage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCntrctValCalcMthdUnitPZero()
    var
        ServiceItem: Record "Service Item";
        ContractValueCalcMethod: Option "None","Based on Unit Price","Based on Unit Cost";
        ContractValueCalcMethodOld: Option;
    begin
        // 1. Setup Service Management with - Contract Value Calc. Method as Based on Unit Price and Contract Value % as 0 for boundary
        // value testing.
        // 2. Create a Service Item with random Sales Unit Cost and random Sales Unit Price.
        // [SCENARIO] Verify that the values of the Default Contract Value and Default Contract Cost are equal to 0 for Contract Value Calc. Method as Based on Unit Price.

        // [GIVEN] Setup demonstration data and Service Management Setup.
        Initialize();
        ContractValueCalcMethodOld := ServMgtSetupForContractValCalc(ContractValueCalcMethod::"Based on Unit Price", 0);

        // [WHEN] Create a Service Item with random Sales Unit Cost and Sales Unit Price.
        CreateServItemWithSalesUnitAmt(ServiceItem);

        // [THEN] Verify that the values of the Default Contract Value and Default Contract Cost are 0.
        ServiceItem.TestField("Default Contract Value", 0);
        ServiceItem.TestField("Default Contract Cost", 0);

        // Cleanup:
        ServMgtSetupForContractValCalc(ContractValueCalcMethodOld, LibraryRandom.RandInt(100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCntrctValCalcMthdUPHundred()
    var
        ServiceItem: Record "Service Item";
        ContractValueCalcMethod: Option "None","Based on Unit Price","Based on Unit Cost";
        ContractValueCalcMethodOld: Option;
    begin
        // 1. Setup Service Management with - Contract Value Calc. Method as Based on Unit Price and Contract Value % as 100 for boundary
        // value testing.
        // 2. Create a Service Item with random Sales Unit Cost and random Sales Unit Price.
        // 3. Verify that the value of the Default Contract Value is equal to the value of the field Sales Unit Price of the Service Item.
        // [SCENARIO] Verify that the value of the Default Contract Value is equal to the value of the field Sales Unit Price of the Service Item.

        // [GIVEN] Setup demonstration data and Service Management Setup.
        Initialize();
        ContractValueCalcMethodOld := ServMgtSetupForContractValCalc(ContractValueCalcMethod::"Based on Unit Price", 100);

        // [WHEN] Create a Service Item with random Sales Unit Cost and Sales Unit Price.
        CreateServItemWithSalesUnitAmt(ServiceItem);

        // [THEN] Verify that the value of the Default Contract Value is equal to the value of the field Sales Unit Price of the Service
        // [THEN] Item and the value of the Default Contract Cost is equal to the value of the field Sales Unit Cost of the Service Item.
        ServiceItem.TestField("Default Contract Value", ServiceItem."Sales Unit Price");
        ServiceItem.TestField("Default Contract Cost", ServiceItem."Sales Unit Cost");

        // Cleanup:
        ServMgtSetupForContractValCalc(ContractValueCalcMethodOld, LibraryRandom.RandInt(100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCntrctValueCalcMthdUnitCos()
    var
        Currency: Record Currency;
        ServiceItem: Record "Service Item";
        ContractValueCalcMethod: Option "None","Based on Unit Price","Based on Unit Cost";
        ContractValuePercentage: Decimal;
        ContractValueCalcMethodOld: Option;
    begin
        // 1. Setup Service Management with - Contract Value Calc. Method as Based on Unit Cost and Contract Value % as any random value.
        // 2. Create a Service Item with random Sales Unit Cost and random Sales Unit Price.
        // 3. Verify that the value of the Default Contract Value is equal to the value of the field Default Contract Cost of the Service
        // Item.
        // [SCENARIO] Verify that the value of the Default Contract Value is equal to the value of the field Default Contract Cost of the Service Item

        // [GIVEN] Setup demonstration data and Service Management Setup.
        Initialize();
        ContractValuePercentage := LibraryRandom.RandInt(100);
        ContractValueCalcMethodOld :=
          ServMgtSetupForContractValCalc(ContractValueCalcMethod::"Based on Unit Cost", ContractValuePercentage);

        // [WHEN] Create a Service Item with random Sales Unit Cost and Sales Unit Price.
        CreateServItemWithSalesUnitAmt(ServiceItem);

        // [THEN] Verify that the value of the Default Contract Value is 0.
        ServiceItem.TestField("Default Contract Value", ServiceItem."Default Contract Cost");

        // [THEN] Verify that the value of the Default Contract Cost is the product of the Sales Unit Cost field of the Service Item and
        // [THEN] the Contract Value % field of the Service Management Setup divided by 100.
        Currency.InitRoundingPrecision();
        ServiceItem.TestField(
          "Default Contract Cost",
          Round(ServiceItem."Sales Unit Cost" * ContractValuePercentage / 100, Currency."Unit-Amount Rounding Precision"));

        // Cleanup:
        ServMgtSetupForContractValCalc(ContractValueCalcMethodOld, ContractValuePercentage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCntrctValCalcMthdUntCosZer()
    var
        ServiceItem: Record "Service Item";
        ContractValueCalcMethod: Option "None","Based on Unit Price","Based on Unit Cost";
        ContractValueCalcMethodOld: Option;
    begin
        // 1. Setup Service Management with - Contract Value Calc. Method as Based on Unit Cost and Contract Value % as 0 for boundary
        // value testing.
        // 2. Create a Service Item with random Sales Unit Cost and random Sales Unit Price.
        // [SCENARIO] Verify that the values of the Default Contract Value and Default Contract Cost are 0.

        // [GIVEN] Setup demonstration data and Service Management Setup.
        Initialize();
        ContractValueCalcMethodOld := ServMgtSetupForContractValCalc(ContractValueCalcMethod::"Based on Unit Cost", 0);

        // [WHEN] Create a Service Item with random Sales Unit Cost and Sales Unit Price.
        CreateServItemWithSalesUnitAmt(ServiceItem);

        // [THEN] Verify that the values of the Default Contract Value and Default Contract Cost are 0.
        ServiceItem.TestField("Default Contract Value", 0);
        ServiceItem.TestField("Default Contract Cost", 0);

        // Cleanup:
        ServMgtSetupForContractValCalc(ContractValueCalcMethodOld, LibraryRandom.RandInt(100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCntrctValCalcMthdUntCosHun()
    var
        ServiceItem: Record "Service Item";
        ContractValueCalcMethod: Option "None","Based on Unit Price","Based on Unit Cost";
        ContractValueCalcMethodOld: Option;
    begin
        // 1. Setup Service Management with - Contract Value Calc. Method as Based on Unit Cost and Contract Value % as 100 for boundary
        // value testing.
        // 2. Create a Service Item with random Sales Unit Cost and random Sales Unit Price.
        // 3. Verify that the value of the Default Contract Value is equal to the value of the field Sales Unit Cost of the Service Item.
        // [SCENARIO] Verify that the value of the Default Contract Cost is equal to the value of the field Sales Unit Cost of the Service Item.

        // [GIVEN] Setup demonstration data and Service Management Setup.
        Initialize();
        ContractValueCalcMethodOld := ServMgtSetupForContractValCalc(ContractValueCalcMethod::"Based on Unit Cost", 100);

        // [WHEN] Create a Service Item with random Sales Unit Cost and Sales Unit Price.
        CreateServItemWithSalesUnitAmt(ServiceItem);

        // [THEN] Verify that the value of the Default Contract Value is equal to the value of the field Sales Unit Cost of the Service
        // [THEN] Item and the value of the Default Contract Cost is equal to the value of the field Sales Unit Cost of the Service Item.
        ServiceItem.TestField("Default Contract Value", ServiceItem."Sales Unit Cost");
        ServiceItem.TestField("Default Contract Cost", ServiceItem."Sales Unit Cost");

        // Cleanup:
        ServMgtSetupForContractValCalc(ContractValueCalcMethodOld, LibraryRandom.RandInt(100));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure TestServItemUpdtnOnCrtnServCon()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        // 1. Create a Service Item with random Sales Unit Cost and random Sales Unit Price.
        // 2. Create a Service Contract.
        // [SCENARIO] Verify that the field Service Contract on the Service Item has been updated as TRUE after creation of the Service Contract.

        // [GIVEN] Setup demonstration data and Service Management Setup. Create a Service Item with random Sales Unit Cost and Sales Unit Price.
        Initialize();
        CreateServItemWithSalesUnitAmt(ServiceItem);

        // [WHEN] Create Service Contract with the Service Item created.
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);
        CreateServiceContractHeader(ServiceContractHeader, ServiceItem."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // [THEN] Verify that the field Service Contract on the Service Item has been updated as TRUE after creation of the Service Contract.
        ServiceItem.CalcFields("Service Contracts");
        ServiceItem.TestField("Service Contracts", true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure TestServItemUpdtnOnDltnServCon()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // 1. Create a Service Item with random Sales Unit Cost and random Sales Unit Price.
        // 2. Create a Service Contract.
        // 3. Delete the Service Contract.
        // [SCENARIO] Verify that the field Service Contract on the Service Item has been updated as FALSE after deletion of the Service Contract.

        // [GIVEN] Setup demonstration data and Service Management Setup. Create a Service Item with random Sales Unit Cost and Sales Unit Price and a new Service Contract with the Service Item created.
        Initialize();
        CreateServItemWithSalesUnitAmt(ServiceItem);
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);
        CreateServiceContractHeader(ServiceContractHeader, ServiceItem."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // [WHEN] Delete the Service Contract.
        ServiceContractHeader.Delete(true);

        // [THEN] Verify that the field Service Contract on the Service Item has been updated as FALSE after deletion of the Service Contract.
        ServiceItem.CalcFields("Service Contracts");
        ServiceItem.TestField("Service Contracts", false);
    end;

    [Test]
    [HandlerFunctions('CommentSheetPageHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure AddCommentForServiceContractLine()
    var
        ServiceItem: Record "Service Item";
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceCommentLine: Record "Service Comment Line";
        PageServContractLineList: TestPage "Serv. Item List (Contract)";
        Comment: Text[80];
    begin
        // [SCENARIO 395348] Test adding a Comment on Service Item page.
        Initialize();

        // [GIVEN] Service Contract with one line Service Item created.
        CreateServItemWithSalesUnitAmt(ServiceItem);
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);
        CreateServiceContractHeader(ServiceContractHeader, ServiceItem."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // [WHEN] Add the comment 'X' to the service contract line
        Comment :=
            CopyStr(
                LibraryUtility.GenerateRandomCode(ServiceCommentLine.FieldNo(Comment), DATABASE::"Service Comment Line"),
                1, LibraryUtility.GetFieldLength(DATABASE::"Service Comment Line", ServiceCommentLine.FieldNo(Comment)));
        LibraryVariableStorage.Enqueue(Comment);

        PageServContractLineList.Trap();
        Page.Run(Page::"Serv. Item List (Contract)", ServiceContractLine);
        PageServContractLineList."Co&mments".Invoke(); // add comment by CommentSheetPageHandler

        // [THEN] Service Comment Line contains the 'General' comment 'X' for the Service Contract Line.
        ServiceCommentLine.SetRange("Table Name", "Service Comment Table Name"::"Service Contract");
        ServiceCommentLine.SetRange("Table Subtype", ServiceContractLine."Contract Type");
        ServiceCommentLine.SetRange("No.", ServiceContractLine."Contract No.");
        ServiceCommentLine.SetRange("Table Line No.", ServiceContractLine."Line No.");
        Assert.RecordCount(ServiceCommentLine, 1);
        ServiceCommentLine.FindFirst();
        ServiceCommentLine.TestField(Comment, Comment);
        ServiceCommentLine.TestField(Type, Enum::"Service Comment Line Type"::General);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServShpmntCreatedFrmSerOrd()
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // 1. Create a new Service Item with random Customer and random Sales Unit Cost, Sales Unit Price, Default Contract Cost and
        // Default Contract Value.
        // 2. Create a Service Order for the Service Item - Create Service Header, Service Item Line and Service Line with random Item
        // and random Quantity. Post the Service Order as Ship.
        // [SCENARIO] Check that the values in the Service Line table are the same as Service Shipment Line table.

        // [GIVEN] Setup demonstration data and Service Management.
        Initialize();

        // [WHEN] Create and Post Service Order as Ship.
        CreateServiceItemWithAmounts(ServiceItem);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLineWithItem(ServiceLine, Item, ServiceHeader, ServiceItem."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Match values in the Service Line table and the Service Shipment Line table.
        VerifyServLineWithServShptLine(ServiceLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServItemLogOnServItemCrtn()
    var
        ServiceItem: Record "Service Item";
    begin
        // 1. Create a Service Item with random Sales Unit Cost and random Sales Unit Price.
        // [SCENARIO] Check Service Item Log entry after the creation of Service Item.

        // [GIVEN] Setup demonstration data.
        Initialize();

        // [WHEN] Create a Service Item with random Sales Unit Cost and Sales Unit Price.
        LibraryService.CreateServiceItem(ServiceItem, '');

        // [THEN] Check the Service Item Log entry after creation of the Service Item.
        VerifyServiceItemLogEntry(ServiceItem."No.", 12);  // The value 1 is the event number for creation of Service Item.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServItemLogOnChangeCustom()
    var
        ServiceItem: Record "Service Item";
    begin
        // 1. Create a Service Item with random Sales Unit Cost and random Sales Unit Price.
        // [SCENARIO] Check Service Item Log entry after the Ship-to Code has been updated as a result of validating Customer.

        // [GIVEN] Setup demonstration data.
        Initialize();

        // [WHEN] Create a Service Item with random Sales Unit Cost and Sales Unit Price.
        CreateServItemWithSalesUnitAmt(ServiceItem);

        // [THEN] Check the Service Item Log entry after creation of the Service Item.
        VerifyServiceItemLogEntry(ServiceItem."No.", 12);  // The value 12 is the event number for Ship-to Code update.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure TestServItemLogOnCrtnServContr()
    var
        ServiceItem: Record "Service Item";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        // 1. Create a Service Item with random Sales Unit Cost and random Sales Unit Price.
        // 2. Create a Service Contract.
        // [SCENARIO] Check Service Item Log entry after the creation of the Service Contract.

        // [GIVEN] Setup demonstration data. Create a Service Item with random Sales Unit Cost and Sales Unit Price
        Initialize();
        CreateServItemWithSalesUnitAmt(ServiceItem);

        // [WHEN] Create Service Contract for the Service Item created above.
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);
        CreateServiceContractHeader(ServiceContractHeader, ServiceItem."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // [THEN] Check the Service Item Log entry after creation of the Service Order.
        VerifyServiceItemLogEntry(ServiceItem."No.", 3);  // The value 3 is the event number for creation of the Service Contract.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServItemLogOnCrtnServOrder()
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // 1. Create a Service Item with random Sales Unit Cost and random Sales Unit Price.
        // 2. Create a Service Order.
        // [SCENARIO] Check Service Item Log entry after the creation of the Service Order.

        // [GIVEN] Setup demonstration data. Create a Service Item with random Sales Unit Cost and Sales Unit Price
        Initialize();
        CreateServItemWithSalesUnitAmt(ServiceItem);

        // [WHEN] Create Service Order for the Service Item created above.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [THEN] Check the Service Item Log entry after creation of the Service Order.
        VerifyServiceItemLogEntry(ServiceItem."No.", 5);  // The value 5 is the event number for creation of the Service Order.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServItemLogOnCrtnServQuote()
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        // 1. Create a Service Item with random Sales Unit Cost and random Sales Unit Price.
        // 2. Create a Service Quote.
        // [SCENARIO] Check Service Item Log entry after the creation of the Service Quote.

        // [GIVEN] Setup demonstration data. Create a Service Item with random Sales Unit Cost and Sales Unit Price
        Initialize();
        CreateServItemWithSalesUnitAmt(ServiceItem);

        // [WHEN] Create Service Quote for the Service Item created above.
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [THEN] Check the Service Item Log entry after creation of the Service Quote.
        VerifyServiceItemLogEntry(ServiceItem."No.", 15);
        // The value 15 is the event number for addition of Service Item to Service Quote.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentLogOnQuoteCreation()
    var
        ServiceHeader: Record "Service Header";
        ServiceDocumentLog: Record "Service Document Log";
    begin
        // Covers document number CU5906-4 - refer to TFS ID 167035.
        // [SCENARIO] Test Service Document Log created on creation of Service Quote.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Quote.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());

        // 3. Verify: Verify Service document Log for Service Quote creation.
        // The value 13 is the event number for Service Quote creation.
        VerifyServiceDocumentLogEntry(ServiceHeader."No.", ServiceDocumentLog."Document Type"::Quote, 13);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentLogOnInvoiceCreation()
    var
        ServiceHeader: Record "Service Header";
        ServiceDocumentLog: Record "Service Document Log";
    begin
        // Covers document number CU5906-3 - refer to TFS ID 167035.
        // [SCENARIO] Test Service Document Log created on creation of Service Invoice.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Header of Document Type Invoice.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        // 3. Verify: Verify Service document Log for Service Invoice creation.
        // The value 20 is the event number for Service Invoice Creation.
        VerifyServiceDocumentLogEntry(ServiceHeader."No.", ServiceDocumentLog."Document Type"::Invoice, 20);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentLogOnInvoicePosting()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceDocumentLog: Record "Service Document Log";
    begin
        // Covers document number CU5906-3 - refer to TFS ID 167035.
        // [SCENARIO] Test Service Document Log created after Posting Service Invoice.

        // 1. Setup: Create Service Header with Document Type Invoice and Service Line of Type Item.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Randon because value is not important.
        ServiceLine.Modify(true);

        // 2. Exercise: Post Service Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // 3. Verify: Verify Service document Log for Posted Service Invoice.
        // The value 22, 20 is the event number for Service Invoice and Posted Invoice Creation.
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        VerifyServiceDocumentLogEntry(ServiceInvoiceHeader."No.", ServiceDocumentLog."Document Type"::"Posted Invoice", 22);
        VerifyServiceDocumentLogEntry(ServiceHeader."No.", ServiceDocumentLog."Document Type"::Invoice, 20);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentLogCreditMemoCreation()
    var
        ServiceHeader: Record "Service Header";
        ServiceDocumentLog: Record "Service Document Log";
    begin
        // Covers document number CU5906-2 - refer to TFS ID 167035.
        // [SCENARIO] Test Service Document Log created on creation of Service Credit Memo.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Service Header of Document Type Credit Memo.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());

        // 3. Verify: Verify Service document Log for Service Credit Memo creation.
        // The value 21 is the event number for Service Credit Memo Creation.
        VerifyServiceDocumentLogEntry(ServiceHeader."No.", ServiceDocumentLog."Document Type"::"Credit Memo", 21);
    end;

    [Test]
    [HandlerFunctions('InvoiceESConfirmHandler')]
    [Scope('OnPrem')]
    procedure DocumentLogOnCreditMemoPosting()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceDocumentLog: Record "Service Document Log";
    begin
        // Covers document number CU5906-2 - refer to TFS ID 167035.
        // [SCENARIO] Test Service Document Log created after Posting Service Credit Memo.

        // 1. Setup: Create Service Header with Document Type Credit Memo and Service Line of Type Item.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));  // Use Randon because value is not important.
        ServiceLine.Modify(true);

        // 2. Exercise: Post Service Credit Memo.
        ExecuteConfirmHandlerInvoiceES();
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // 3. Verify: Verify Service document Log for Posted Service Credit Memo.
        // The value 16, 21 is the event number for Service Credit Memo and Posted Credit Memo Creation.
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceCrMemoHeader.FindFirst();
        VerifyServiceDocumentLogEntry(ServiceCrMemoHeader."No.", ServiceDocumentLog."Document Type"::"Posted Credit Memo", 16);
        VerifyServiceDocumentLogEntry(ServiceHeader."No.", ServiceDocumentLog."Document Type"::"Credit Memo", 21);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemLogChangeItemNo()
    var
        ServiceItem: Record "Service Item";
    begin
        // Covers document number CU5906-1 - refer to TFS ID 167035.
        // [SCENARIO] Test Service Item Log created after Item No. changed on Service Item.

        // 1. Setup: Create Service Item.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, '');

        // 2. Exercise: Change Item No. on Service Item.
        ServiceItem.Validate("Item No.", LibraryInventory.CreateItemNo());
        ServiceItem.Modify(true);

        // 3. Verify: Verify Service Item Log for Item No. changed.
        VerifyServiceItemLogEntry(ServiceItem."No.", 13);  // The value 13 is the event number for Item No. changed.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemLogChangeSerialNo()
    var
        ServiceItem: Record "Service Item";
    begin
        // Covers document number CU5906-1 - refer to TFS ID 167035.
        // [SCENARIO] Test Service Item Log created after Serial No. changed on Service Item.

        // 1. Setup: Create Service Item.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, '');

        // 2. Exercise: Change Serial No. on Service Item.
        ServiceItem.Validate("Serial No.", LibraryUtility.GenerateRandomCode(ServiceItem.FieldNo("Serial No."), DATABASE::"Service Item"));
        ServiceItem.Modify(true);

        // 3. Verify: Verify Service Item Log for Serial No. changed.
        VerifyServiceItemLogEntry(ServiceItem."No.", 14);  // The value 14 is the event number for Serial No. changed.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemLogRenameServItem()
    var
        ServiceItem: Record "Service Item";
    begin
        // Covers document number CU5906-1 - refer to TFS ID 167035.
        // [SCENARIO] Test Service Item Log created after Renamed Service Item.

        // 1. Setup: Create Service Item.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, '');

        // 2. Exercise: Rename Service Item.
        ServiceItem.Rename(LibraryUtility.GenerateRandomCode(ServiceItem.FieldNo("No."), DATABASE::"Service Item"));

        // 3. Verify: Verify Service Item Log for Rename Service Item.
        VerifyServiceItemLogEntry(ServiceItem."No.", 18);  // The value 18 is the event number for Rename Service Item.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemLogChangeStatus()
    var
        ServiceItem: Record "Service Item";
    begin
        // Covers document number CU5906-1 - refer to TFS ID 167035.
        // [SCENARIO] Test Service Item Log created after Status Changing.

        // 1. Setup: Create Service Item.
        Initialize();
        LibraryService.CreateServiceItem(ServiceItem, '');

        // 2. Exercise: Change Status on Service Item.
        ServiceItem.Validate(Status, ServiceItem.Status::Installed);
        ServiceItem.Modify(true);

        // 3. Verify: Verify Service Item Log for Status Change of Service Item.
        VerifyServiceItemLogEntry(ServiceItem."No.", 12);  // The value 8 is the event number for Status Changed.
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ModalFormHandlerLookupOK')]
    [Scope('OnPrem')]
    procedure ReplaceComponent()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
    begin
        // Covers document number CU5920-1 - refer to TFS ID 167035.
        // [SCENARIO] Test Value Entry after Posting Service Order as Ship and Invoice.

        // 1. Setup: Create a new Service Item with an Item having two BOM Components and Create a Service Line with Selection of Replace
        // Component Option.
        Initialize();
        CreateServiceItemWithBOMItem(ServiceHeader, ServiceItemNoForComponent, ItemNo);
        CreateServiceLine(ServiceLine, ItemNo, ServiceHeader, ServiceItemNoForComponent);

        // 2. Exercise: Post Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify Value Entry after Posting Service Order.
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        VerifyValueEntry(ValueEntry."Document Type"::"Service Invoice", ServiceInvoiceHeader."No.", ItemNo, ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandlerForNew')]
    [Scope('OnPrem')]
    procedure NewComponent()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemNo: Code[20];
    begin
        // Covers document number CU5920-1 - refer to TFS ID 167035.
        // [SCENARIO] Test Item Ledger Entry after Posting Service Order as Ship and Invoice.

        // 1. Setup: Create a new Service Item with an Item having two BOM Components and Create a Service Line with Selection of New
        // Component Option.
        Initialize();
        CreateServiceItemWithBOMItem(ServiceHeader, ServiceItemNoForComponent, ItemNo);
        CreateServiceLine(ServiceLine, ItemNo, ServiceHeader, ServiceItemNoForComponent);

        // 2. Exercise: Post Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Verify Item Ledger Entry after Posting Service Order.
        VerifyItemLedgerEntry(ServiceHeader."No.", ItemNo, ServiceLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ItemWithSkillCode()
    var
        ResourceSkill: Record "Resource Skill";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
        ValueEntry: Record "Value Entry";
        Quantity: Decimal;
        ServiceItemGroupCode: Code[10];
        DocumentNo: Code[20];
    begin
        // Covers document number CU5920-2 - refer to TFS ID 167035.
        // [SCENARIO] Test Value Entry after Posting Sales Invoice.

        // 1. Setup: Create Service Item Group with Skill and a new Item. Attach Service Item Group to  Item, Create Sales Header with
        // Currency Code and Sales Line.
        Initialize();
        CreateServiceItemGrpWithSkill(ServiceItemGroupCode, ResourceSkill);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Service Item Group", ServiceItemGroupCode);
        Item.Modify(true);

        LibraryERM.FindCurrency(Currency);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Currency Code", Currency.Code);
        SalesHeader.Modify(true);
        CreateSalesLine(Quantity, SalesHeader, Item."No.");

        // 2. Exercise: Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // 3. Verify: Verify Value Entry after Posting Sales Invoice.
        VerifyValueEntry(ValueEntry."Document Type"::"Sales Invoice", DocumentNo, Item."No.", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderNoSeries()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ServiceHeader: Record "Service Header";
        NoSeries: Codeunit "No. Series";
        NextServiceOrderNo: Code[20];
    begin
        // Covers document number Test Case139849 - refer to TFS ID 168064.
        // [SCENARIO] Test Service Order No is incremented automatically as per the setup.

        // 1. Setup: Get next Service Order No from No Series.
        ServiceMgtSetup.Get();
        if ServiceMgtSetup."Service Order Nos." = '' then
            ServiceMgtSetup."Service Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        NextServiceOrderNo := NoSeries.PeekNextNo(ServiceMgtSetup."Service Order Nos.");

        // 2. Exercise: Find Customer and Create new Service Order.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // 3. Verify: Check that the Service Order No is not incremented automatically as per the setup.
        ServiceHeader.TestField("No.", NextServiceOrderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerInformationOnHeader()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Covers document number Test Case139849 - refer to TFS ID 168064.
        // [SCENARIO] Test the Customer information on Service Order.

        // [GIVEN]
        Initialize();

        // [WHEN] Find Customer and Create Service Header.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [THEN] Verifying the Customer.
        VerifyCustomer(ServiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemInformationOnLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Covers document number Test Case139849 - refer to TFS ID 168064.
        // [SCENARIO] Test the Service Item details on Service Item Line.

        // [GIVEN]
        Initialize();

        // [WHEN] Find Customer, create Service Header, create Service Item, create Service Item Line.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [THEN] Verify the Service Item Details.
        VerifyServiceItemLine(ServiceItemLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ModalFormItemReplacement')]
    [Scope('OnPrem')]
    procedure ServiceItemReplacementItemBOM()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // Covers document number CU-5988-1-4 - refer to TFS ID 172910.
        // [SCENARIO] Test Service Line after Service Item replacement with Copy Components from Item BOM.

        // 1. Setup: Create Service Order - Service Header, Service Item Line with Description and attach Item on Service Item Line,
        // Create Service Item from Service Item Line.
        Initialize();
        CreateServiceItemFromOrder(ServiceItemLine);

        // 2. Exercise: Create Service Line.
        CreateServiceLineReplacement(
          ServiceLine, ServiceItemLine, ServiceLine."Copy Components From"::"Item BOM", Replacement::"Temporary");

        // 3. Verify: Verify Service Line after Service Item replacement with Copy Components from Item BOM.
        ServiceLine.TestField("Copy Components From", CopyComponentsFrom);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ModalFormItemReplacement')]
    [Scope('OnPrem')]
    procedure ShipOrderReplacementItemBOM()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
    begin
        // Covers document number CU-5988-1-8 - refer to TFS ID 172911.
        // [SCENARIO] Test Service Item and Its components after Posting Service Order with Copy Components from Item BOM.

        // 1. Setup: Create Service Order - Service Header, Service Item Line with Description and attach Item on Service Item Line,
        // Create Service Item from Service Item Line.
        Initialize();
        CreateServiceItemFromOrder(ServiceItemLine);

        // 2. Exercise: Create Service Line and Post Service Order as Ship.
        CreateServiceLineReplacement(
          ServiceLine, ServiceItemLine, ServiceLine."Copy Components From"::"Item BOM", Replacement::"Temporary");
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify Service Ledger Entry, Created Service Item and Service Item Component of Created Service Item after Posting
        // Service Order.
        VerifyServiceLedgerEntry(ServiceLine);
        VerifyServiceItem(ServiceItemLine, ServiceItem.Status::"Temporarily Installed");
        VerifyServiceItemComponent(ServiceItemLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ModalFormItemReplacement')]
    [Scope('OnPrem')]
    procedure ItemReplacementOldItem()
    var
        ServiceLine: Record "Service Line";
    begin
        // Covers document number CU-5988-1-10 - refer to TFS ID 172911.
        // [SCENARIO] Test Service Line after Service Item replacement with Copy Components from Old Service Item.

        ServiceItemReplacement(ServiceLine."Copy Components From"::"Old Service Item");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ModalFormItemReplacement')]
    [Scope('OnPrem')]
    procedure ItemReplacementOldSerial()
    var
        ServiceLine: Record "Service Line";
    begin
        // Covers document number CU-5988-1-12 - refer to TFS ID 172911.
        // [SCENARIO] Test Service Line after Service Item replacement with Copy Components from Old Serv.Item w/o Serial No.

        ServiceItemReplacement(ServiceLine."Copy Components From"::"Old Serv.Item w/o Serial No.");
    end;

    local procedure ServiceItemReplacement(NewCopyComponentsFrom: Option)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceItemComponent: Record "Service Item Component";
    begin
        // 1. Setup: Create Service Order - Service Header, Service Item Line with Description and attach Item on Service Item Line,
        // Create Service Item from Service Item Line.
        Initialize();
        CreateServiceItemFromOrder(ServiceItemLine);

        // 2. Exercise: Create Component for Service Item and Create Service Line.
        LibraryService.CreateServiceItemComponent(
          ServiceItemComponent, ServiceItemLine."Service Item No.", ServiceItemComponent.Type::Item, FindDifferentItem());
        CreateServiceLineReplacement(ServiceLine, ServiceItemLine, NewCopyComponentsFrom, Replacement::"Temporary");

        // 3. Verify: Verify Service Line after Service Item replacement with Copy Components from as parameter.
        ServiceLine.TestField("Copy Components From", NewCopyComponentsFrom);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,ModalFormItemReplacement')]
    [Scope('OnPrem')]
    procedure ShipOrderReplacementOldItem()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        ServiceItemComponent: Record "Service Item Component";
    begin
        // Covers document number CU-5988-1-13 - refer to TFS ID 172911.
        // [SCENARIO] Test Service Item and Its components after Posting Service Order with Copy Components from Old Serv.Item w/o Serial No.

        // 1. Setup: Create Service Order - Service Header, Service Item Line with Description and attach Item on Service Item Line,
        // Create Service Item from Service Item Line.
        Initialize();
        CreateServiceItemFromOrder(ServiceItemLine);

        // 2. Exercise: Create Component for Service Item, Create Service Line and Post Service Order as Ship.
        LibraryService.CreateServiceItemComponent(
          ServiceItemComponent, ServiceItemLine."Service Item No.", ServiceItemComponent.Type::Item, FindDifferentItem());
        CreateServiceLineReplacement(
          ServiceLine, ServiceItemLine, ServiceLine."Copy Components From"::"Old Serv.Item w/o Serial No.", Replacement::Permanent);
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");

        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // 3. Verify: Verify Service Item and Its components after Posting Service Order with Copy Components from Old Serv.Item
        // w/o Serial No.
        VerifyServiceItem(ServiceItemLine, ServiceItem.Status::Installed);
        VerifyComponents(ServiceItemLine, ServiceItemComponent);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteServiceDocumentLog()
    var
        ServiceHeader: Record "Service Header";
        ServiceDocumentLog: Record "Service Document Log";
        DeleteServiceDocumentLog: Report "Delete Service Document Log";
    begin
        // [SCENARIO] Test deletion of Service Document Log created on creation of Service Order.

        // 1. Setup: Create Service Header of Document Type Order.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // 2. Exercise: Delete the Service Document log. The value 1 is the event number for Service Order Creation.
        FilterServiceDocumentLog(ServiceDocumentLog, ServiceHeader."Document Type", ServiceHeader."No.", 1);
        DeleteServiceDocumentLog.UseRequestPage(false);
        DeleteServiceDocumentLog.SetTableView(ServiceDocumentLog);
        DeleteServiceDocumentLog.Run();

        // 3. Verify: Verify Service Document Log has been deleted.
        Assert.AreEqual(
          0, ServiceDocumentLog.Count, StrSubstNo(RecordExistsErr, ServiceDocumentLog.TableCaption(), ServiceDocumentLog));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeletedOnlyTrueCurrentOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceDocumentLog: Record "Service Document Log";
        DeleteServiceDocumentLog: Report "Delete Service Document Log";
    begin
        // [SCENARIO] Test Service Document Log is not deleted for current document if Process Deleted Only option is TRUE.

        // 1. Setup: Create Service Header of Document Type Order.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // 2. Exercise: Try to delete the Service Document log with Process Deleted Only option as TRUE.
        // The value 1 is the event number for Service Order Creation.
        FilterServiceDocumentLog(ServiceDocumentLog, ServiceHeader."Document Type", ServiceHeader."No.", 1);
        DeleteServiceDocumentLog.UseRequestPage(false);
        DeleteServiceDocumentLog.SetProcessDeletedOnly(true);
        DeleteServiceDocumentLog.SetTableView(ServiceDocumentLog);
        DeleteServiceDocumentLog.Run();

        // 3. Verify: Verify Service Document Log still exists.
        ServiceDocumentLog.FindFirst();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeletedOnlyTruePostedOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceDocumentLog: Record "Service Document Log";
        DeleteServiceDocumentLog: Report "Delete Service Document Log";
    begin
        // [SCENARIO] Test Service Document Log is deleted for posted document if Process Deleted Only option is TRUE.

        // 1. Setup: Create Service Header of Document Type Order, Service Item, ServiceItem Line, multiple Service Lines.
        // Post the Document as Ship and Invoice.
        Initialize();
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateMultipleServiceLines(ServiceHeader, ServiceItemLine."Line No.");

        // The value 1 is the event number for Service Order Creation.
        FilterServiceDocumentLog(ServiceDocumentLog, ServiceHeader."Document Type", ServiceHeader."No.", 1);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 2. Exercise: Delete the Service Document log with Process Deleted Only option as TRUE.
        DeleteServiceDocumentLog.UseRequestPage(false);
        DeleteServiceDocumentLog.SetProcessDeletedOnly(true);
        DeleteServiceDocumentLog.SetTableView(ServiceDocumentLog);
        DeleteServiceDocumentLog.Run();

        // 3. Verify: Verify Service Document Log has been deleted.
        Assert.AreEqual(
          0, ServiceDocumentLog.Count, StrSubstNo(RecordExistsErr, ServiceDocumentLog.TableCaption(), ServiceDocumentLog));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateServiceItemManual()
    var
        ServiceItemNo: Code[20];
    begin
        // [SCENARIO] Test create Service Item and verify that the Service Item Created.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Create a new service Item.
        PageCreateServiceItem(ServiceItemNo);
        PageUpdateServiceItem(ServiceItemNo);

        // 3. Verify: Verify that Service Item created.
        VerifyServiceItemCreation(ServiceItemNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreateServiceItemAssignSkill()
    var
        ServiceItemNo: Code[20];
    begin
        // [SCENARIO] Test create Service Item and assign Skill Code of Item and Service Item Group Code to the Service Item.
        // Verify that the Service Item is being assigned with correct values.

        // 1. Setup: Create a Service Item.
        Initialize();
        PageCreateServiceItem(ServiceItemNo);
        PageUpdateServiceItem(ServiceItemNo);

        // 2. Exercise: Assign Skill Code of Item and Service Item Group Code to the Service Item created.
        AssignServiceItemGroupSkill(ServiceItemNo);

        // 3. Verify: Verify that Service Item values are populated.
        VerifyServiceItemValues(ServiceItemNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingForAssignAndSelectPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemAfterPostingItemJournal()
    var
        ItemJournalLine: Record "Item Journal Line";
        ServiceItem: Record "Service Item";
    begin
        // [SCENARIO] Test Service Item is not created after posting Item Journal.

        // 1. Setup.
        Initialize();

        // 2. Exercise: Post Item Journal.
        CreateAndPostItemJournalLine(ItemJournalLine);

        // 3. Verify: Verify Item Ledger Entry exists Item No. and Service Item Does Not exists Item No.
        VerifyPostingDateOnItemLedgerEntry(ItemJournalLine."Item No.", ItemJournalLine."Posting Date");
        asserterror ServiceItem.Get(ItemJournalLine."Item No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingForAssignAndSelectPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemAfterPostingSalesorder()
    var
        Customer: Record Customer;
        ItemJournalLine: Record "Item Journal Line";
        ServiceItem: Record "Service Item";
    begin
        // [SCENARIO] Test Service Item Status After Posting Sales Order.

        // 1. Setup: Create Item With Service Item Group.
        Initialize();
        CreateAndPostItemJournalLine(ItemJournalLine);

        // 2. Exercise: Post Item Journal.
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostSalesOrderWithItemTracking(Customer."No.", ItemJournalLine."Item No.", ItemJournalLine.Quantity);

        // 3. Verify: Verify Item Ledger Entry exists Item No. and Service Item Does Not exists Item No.
        VerifyPostingDateOnItemLedgerEntry(ItemJournalLine."Item No.", ItemJournalLine."Posting Date");
        VerifyCustomerNoAndStatusOnServiceItem(ItemJournalLine."Item No.", Customer."No.", ServiceItem.Status::Installed);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingForAssignAndSelectPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedSalesDocumentLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemAfterPostingSalesReturnorder()
    var
        ItemJournalLine: Record "Item Journal Line";
        ServiceItem: Record "Service Item";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Return Order]
        // [SCENARIO] Service Item doesn't exist After posting Sales Return Order.
        Initialize();
        UpdateNoSeries();
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Item With Service Item Group. Make positive Inventory Adjustment.
        CreateAndPostItemJournalLine(ItemJournalLine);
        // [GIVEN] Posted Sales Order.
        CreateAndPostSalesOrderWithItemTracking(CustomerNo, ItemJournalLine."Item No.", ItemJournalLine.Quantity);
        FindServiceItemByItemNo(ServiceItem, ItemJournalLine."Item No.");

        // [WHEN] Post Sales Return Order.
        CreateAndPostSalesReturnOrder(CustomerNo);

        // [THEN] Item Ledger Entry exists for Item No. and Service Item Does Not exist.
        Assert.IsFalse(ServiceItem.Find(), ServiceItem."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingForAssignAndSelectPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedSalesDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemAfterPostingSalesReturnOrderWithExistingOpenServiceEntry()
    var
        ItemJournalLine: Record "Item Journal Line";
        ServiceItem: Record "Service Item";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Return Order]
        // [SCENARIO 376221] System doesn't delete Service Item with Open Service Ledger Entries After posting Sales Return Order.
        Initialize();
        UpdateNoSeries();
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Item With Service Item Group. Make positive Inventory Adjustment.
        CreateAndPostItemJournalLine(ItemJournalLine);
        // [GIVEN] Posted Sales Order.
        CreateAndPostSalesOrderWithItemTracking(CustomerNo, ItemJournalLine."Item No.", ItemJournalLine.Quantity);
        // [GIVEN] Create Open Service Item Ledger Entry.
        FindServiceItemByItemNo(ServiceItem, ItemJournalLine."Item No.");
        MockServiceItemLedgerEntry(ServiceLedgerEntry, ServiceItem."No.", 0D, true);

        // [WHEN] Post Sales Return Order.
        CreateAndPostSalesReturnOrder(CustomerNo);

        // [THEN] Service Item exists and Service Item Status = ""
        VerifyCustomerNoAndStatusOnServiceItem(ItemJournalLine."Item No.", CustomerNo, ServiceItem.Status::" ");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingForAssignAndSelectPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,PostedSalesDocumentLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemWhenSalesOrderPostedAfterSalesReturnOrder()
    var
        Customer: Record Customer;
        ItemJournalLine: Record "Item Journal Line";
        ServiceItem: Record "Service Item";
    begin
        // [SCENARIO] Test Service Item Status when Sales Order is posted after Sales Return Order.

        // 1. Setup: Create Item With Service Item Group.
        Initialize();
        UpdateNoSeries();
        CreateAndPostItemJournalLine(ItemJournalLine);

        // 2. Exercise: Post Item Journal.
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostSalesOrderWithItemTracking(Customer."No.", ItemJournalLine."Item No.", ItemJournalLine.Quantity);
        CreateAndPostSalesReturnOrder(Customer."No.");
        CreateAndPostSalesOrderWithItemTracking(Customer."No.", ItemJournalLine."Item No.", ItemJournalLine.Quantity);

        // 3. Verify: Verify Item Ledger Entry exists Item No. and Service Item Does Not exists Item No.
        VerifyCustomerNoAndStatusOnServiceItem(ItemJournalLine."Item No.", Customer."No.", ServiceItem.Status::Installed);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVarintCodeValidation()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ServiceItem: Record "Service Item";
        ServiceItemForComponent: Record "Service Item";
        ServiceItemComponent: Record "Service Item Component";
    begin
        // [SCENARIO] Check that programm does not populate any error Message with validate of the Variant Code in an existing Component Service Item line.

        // [GIVEN] Create Service Item with variant.
        Initialize();
        LibraryInventory.CreateItemVariant(ItemVariant, LibraryInventory.CreateItem(Item));
        LibraryService.CreateServiceItem(ServiceItem, '');
        ServiceItem.Validate("Item No.", ItemVariant."Item No.");
        ServiceItem.Validate("Variant Code", ItemVariant.Code);
        ServiceItem.Modify(true);
        LibraryService.CreateServiceItem(ServiceItemForComponent, '');

        // [WHEN] Update variant code on second service item.
        LibraryService.CreateServiceItemComponent(
          ServiceItemComponent, ServiceItemForComponent."No.", ServiceItemComponent.Type::"Service Item", ServiceItem."No.");
        ServiceItemComponent.Validate("Variant Code", ItemVariant.Code);
        ServiceItemComponent.Modify(true);

        // [THEN] Verify as Varint Code exist on service ttem component line
        ServiceItemComponent.Get(
          ServiceItemComponent.Active, ServiceItemComponent."Parent Service Item No.", ServiceItemComponent."Line No.");
        ServiceItemComponent.TestField("Variant Code", ItemVariant.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingForAssignAndSelectPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ItemJournalTrackingLinesWithSelectEntries()
    begin
        // [SCENARIO] Test Sales Amount on Item Ledger Entry When Lot no. on Item Tracking Lines Selected with Select Entries Option.
        AssignLotNoOnItemTrackingLines(ItemTrackingLinesAssignment::SelectEntries);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingForAssignAndSelectPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ItemJournalTrackingLinesWithAssistEdit()
    begin
        // [SCENARIO] Test Sales Amount on Item Ledger Entry When Lot no. on Item Tracking Lines Selected with Assist Edit.
        AssignLotNoOnItemTrackingLines(ItemTrackingLinesAssignment::AssistEdit);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingForAssignAndSelectPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure TestUniqueSerialNoInServItemListWhenSalesMutipleItems()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ServiceItem: Record "Service Item";
        Customer: Record Customer;
        Assert: Codeunit Assert;
        SerialNo: array[100] of Text[50];
        i: Integer;
    begin
        // [SCENARIO] Verify that only 1 Service Item with the same Serial No. can be existed in Service Items List
        // [GIVEN] Create Item With Service Item Group, create and post Item Journal.
        Initialize();
        CreateAndPostMutipleItemJournalLine(ItemJournalLine);

        // [GIVEN] Create numbers of Service Items with Item No. and Serial No. matches the Quantity on the Item Journal.
        ItemLedgerEntry.SetRange("Item No.", ItemJournalLine."Item No.");
        ItemLedgerEntry.Find('-');

        for i := 1 to ItemJournalLine.Quantity do begin
            SerialNo[i] := ItemLedgerEntry."Serial No.";
            Clear(ServiceItem);
            ServiceItem.Insert(true);
            ServiceItem.Validate("Item No.", ItemJournalLine."Item No.");
            ServiceItem.Validate("Serial No.", SerialNo[i]);
            ServiceItem.Modify(true);
            ItemLedgerEntry.Next();
        end;

        // [WHEN] Create and Post Sales Order.
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostSalesOrderWithItemTracking(Customer."No.", ItemJournalLine."Item No.", ItemJournalLine.Quantity);

        // [THEN] Verify that the number of Service Items created matches the Quantity on the Sales Line.
        ServiceItem.SetRange("Item No.", ItemJournalLine."Item No.");
        Assert.AreEqual(ItemJournalLine.Quantity, ServiceItem.Count, StrSubstNo(ServiceItemCreationErr, ServiceItem.TableCaption()));

        // [THEN] Verify that only 1 Service Item with the same Serial No. can be existed in Service Items List
        for i := 1 to ItemJournalLine.Quantity do begin
            ServiceItem.SetRange("Serial No.", SerialNo[i]);
            ServiceItem.FindFirst();
            Assert.AreEqual(1, ServiceItem.Count, StrSubstNo(ServiceItemCreationDuplicateErr, SerialNo[i]));
            ServiceItem.TestField("Item No.", ItemJournalLine."Item No.");
            ServiceItem.TestField(Status, ServiceItem.Status::Installed);
        end;
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesWithShipmentPageHandler')]
    [Scope('OnPrem')]
    procedure CheckValuesOnSalesReturnOrderLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Verifying that Line Discount and prices are correctly populated on Sales Return Order Line when using "Get Posted Document Lines to Reverse".

        // [GIVEN] Create and post Sales Order and create Sales Return Order
        Initialize();
        CreateAndPostSalesOrder(SalesLine);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesLine."Sell-to Customer No.");

        // [WHEN] Get Posted Document Lines To Reverse.
        SalesHeader.GetPstdDocLinesToReverse();

        // [THEN] Verifying Line Discount and Line Amount on Sales Return Order Line.
        VerifySalesReturnOrderLine(SalesHeader, SalesLine."Line Amount", SalesLine."Line Discount %", SalesLine."Unit Price");
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesWithReceiptPageHandler')]
    [Scope('OnPrem')]
    procedure CheckValuesOnPurchaseReturnOrderLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Verifying that Line Discount and prices are correctly populated on Purchase Return Order Line when using "Get Posted Document Lines to Reverse".

        // [GIVEN] Create and post purchase order and create Purchase Return Order.
        Initialize();
        CreateAndPostPurchaseOrder(PurchaseLine);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", PurchaseLine."Buy-from Vendor No.");

        // [WHEN] Get Posted Document Lines To Reverse.
        PurchaseHeader.GetPstdDocLinesToReverse();

        // [THEN] Verifying Line Discount and Line Amount on Purchase Return Order Line.
        VerifyPurchaseReturnOrderLine(
          PurchaseHeader, PurchaseLine."Line Amount", PurchaseLine."Line Discount %", PurchaseLine."Unit Price (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATIdentifierWhenCopySalesShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        VATIdentifier: Code[20];
    begin
        // [SCENARIO 109048.1] Verify "VAT Identifier" is correctly copied when Copy Posted Sales Shipment
        Initialize();

        // [GIVEN] Create and Post Sales Order
        CreateAndPostSalesOrder(SalesLine);
        VATIdentifier := SalesLine."VAT Identifier";

        // [GIVEN] Create new Sales Return Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesLine."Sell-to Customer No.");

        // [WHEN] Copy Posted Sales Shipment
        CopyDocumentMgt.CopySalesDoc(
          "Sales Document Type From"::"Posted Shipment",
          FindPostedShipment(SalesLine."Sell-to Customer No.", SalesLine."Document No."),
          SalesHeader);

        // [THEN] Sales Line contains correct VAT Identifier
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        Assert.AreEqual(VATIdentifier, SalesLine."VAT Identifier", VATIdentifierErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATIdentifierWhenCopyPurchReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        VATIdentifier: Code[20];
    begin
        // [SCENARIO 109048.2] Verify "VAT Identifier" is correctly copied when Copy Posted Purchase Receipt
        Initialize();

        // [GIVEN] Create and Post Purchase Order
        CreateAndPostPurchaseOrder(PurchaseLine);
        VATIdentifier := PurchaseLine."VAT Identifier";

        // [GIVEN] Create new Purchase Return Order
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", PurchaseLine."Buy-from Vendor No.");

        // [WHEN] Copy Posted Purchase Receipt
        CopyDocumentMgt.CopyPurchDoc(
          "Purchase Document Type From"::"Posted Receipt",
          FindPostedReceipt(PurchaseLine."Buy-from Vendor No.", PurchaseLine."Document No."),
          PurchaseHeader);

        // [THEN] Purchase Line contains correct VAT Identifier
        FindPurchLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.AreEqual(VATIdentifier, PurchaseLine."VAT Identifier", VATIdentifierErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemAfterPostingDropShipmentPurchaseOrder()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        Qty: Integer;
    begin
        // [FEATURE] [Service Item] [Drop Shipment]
        // [SCENARIO 375379] Posting Drop Shipment Purchase Order job should create Service Item if Quantity to Ship on appropriate Sales Order is blank
        Initialize();

        // [GIVEN] Item "I" with Service Item Group where "Create Service Item" = TRUE
        CreateItemWithVendor(Item);

        // [GIVEN] Drop Shipment Sales Order for Item "I" with Quantity = "X" and "Quantity to Ship" = 0
        Qty := LibraryRandom.RandInt(10);
        CreateDropShipmentSalesOrder(SalesLine, Item."No.", Qty);

        // [GIVEN] Purchase Order for Item "I"
        CreateReqLineAndCarryOutWksh(SalesLine);

        // [WHEN] Post Purchase Order as Receipt
        FindPurchaseHeader(PurchaseHeader, Item."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Number of "X" Service Items are created for Item "I"
        ServiceItem.SetRange("Item No.", Item."No.");
        Assert.AreEqual(Qty, ServiceItem.Count, StrSubstNo(ServiceItemCreationErr, ServiceItem.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB5940_CheckIfCanBeDeleted_UT_Positive()
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceItem: Record "Service Item";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376221] TAB5940 CheckIfCanBeDeleted() returns empty result in positive case
        Initialize();

        CreateServiceItem(ServiceItem);
        MockServiceItemLedgerEntry(ServiceLedgerEntry, ServiceItem."No.", 0D, false);
        Assert.IsTrue(ServiceItem.CheckIfCanBeDeleted() = '', ServiceItem."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB5940_CheckIfCanBeDeleted_UT_Negative_ExistingServicedEntry()
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceItem: Record "Service Item";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376221] TAB5940 CheckIfCanBeDeleted() returns returns error text in case of existing Service Ledger Entry with Posting Date within Accounting Period
        Initialize();

        CreateServiceItem(ServiceItem);
        MockServiceItemLedgerEntry(ServiceLedgerEntry, ServiceItem."No.", LibraryFiscalYear.GetFirstPostingDate(false), false);
        Assert.ExpectedMessage(
          StrSubstNo(CheckIfCanBeDeletedServiceItemDatePeriodErr, ServiceItem.TableCaption(), ServiceItem."No."),
          ServiceItem.CheckIfCanBeDeleted());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TAB5940_CheckIfCanBeDeleted_UT_Negative_ExistingOpenEntry()
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceItem: Record "Service Item";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376221] TAB5940 CheckIfCanBeDeleted() returns error text in case of Open Service Ledger Entry
        Initialize();

        CreateServiceItem(ServiceItem);
        MockServiceItemLedgerEntry(ServiceLedgerEntry, ServiceItem."No.", 0D, true);

        Assert.ExpectedMessage(
          StrSubstNo(CheckIfCanBeDeletedServiceItemOpenErr, ServiceItem.TableCaption(), ServiceItem."No."),
          ServiceItem.CheckIfCanBeDeleted());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD361_CheckIfServiceItemCanBeDeleted_UT_Positive()
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceItem: Record "Service Item";
        ServMoveEntries: Codeunit "Serv. Move Entries";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376221] COD361 MoveEntries.CheckIfServiceItemCanBeDeleted() returns empty result in positive case
        Initialize();

        CreateServiceItem(ServiceItem);
        MockServiceItemLedgerEntry(ServiceLedgerEntry, ServiceItem."No.", 0D, false);

        Assert.IsTrue(ServMoveEntries.CheckIfServiceItemCanBeDeleted(ServiceLedgerEntry, ServiceItem."No.") = '', ServiceItem."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD361_CheckIfServiceItemCanBeDeleted_UT_Negative_ExistingServicedEntry()
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceItem: Record "Service Item";
        ServMoveEntries: Codeunit "Serv. Move Entries";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376221] COD361 MoveEntries.CheckIfServiceItemCanBeDeleted() returns error text in case of existing Service Ledger Entry with Posting Date within Accounting Period
        Initialize();

        CreateServiceItem(ServiceItem);
        MockServiceItemLedgerEntry(ServiceLedgerEntry, ServiceItem."No.", LibraryFiscalYear.GetFirstPostingDate(false), false);

        Assert.ExpectedMessage(
          StrSubstNo(CheckIfCanBeDeletedServiceItemDatePeriodErr, ServiceItem.TableCaption(), ServiceItem."No."),
          ServMoveEntries.CheckIfServiceItemCanBeDeleted(ServiceLedgerEntry, ServiceItem."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD361_CheckIfServiceItemCanBeDeleted_UT_Negative_ExistingOpenEntry()
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceItem: Record "Service Item";
        ServMoveEntries: Codeunit "Serv. Move Entries";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376221] COD361 MoveEntries.CheckIfServiceItemCanBeDeleted() returns error text in case of Open Service Ledger Entry
        Initialize();

        CreateServiceItem(ServiceItem);
        MockServiceItemLedgerEntry(ServiceLedgerEntry, ServiceItem."No.", 0D, true);

        Assert.ExpectedMessage(
          StrSubstNo(CheckIfCanBeDeletedServiceItemOpenErr, ServiceItem.TableCaption(), ServiceItem."No."),
          ServMoveEntries.CheckIfServiceItemCanBeDeleted(ServiceLedgerEntry, ServiceItem."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD361_MoveServiceItemLedgerEntries_UT_Positive()
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceItem: Record "Service Item";
        ServMoveEntries: Codeunit "Serv. Move Entries";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376221] COD361 MoveEntries.MoveServiceItemLedgerEntries() clears "Service Ledger Entry"."Service Item No. (Serviced)"
        Initialize();

        CreateServiceItem(ServiceItem);
        MockServiceItemLedgerEntry(ServiceLedgerEntry, ServiceItem."No.", 0D, false);
        ServMoveEntries.MoveServiceItemLedgerEntries(ServiceItem);

        ServiceLedgerEntry.Find();
        Assert.AreEqual(
          '',
          ServiceLedgerEntry."Service Item No. (Serviced)",
          ServiceLedgerEntry.FieldCaption("Service Item No. (Serviced)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD361_MoveServiceItemLedgerEntries_UT_Negative_ExistingServicedEntry()
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceItem: Record "Service Item";
        ServMoveEntries: Codeunit "Serv. Move Entries";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376221] COD361 MoveEntries.MoveServiceItemLedgerEntries() throws an error in case of existing Service Ledger Entry with Posting Date within Accounting Period
        Initialize();

        CreateServiceItem(ServiceItem);
        MockServiceItemLedgerEntry(ServiceLedgerEntry, ServiceItem."No.", LibraryFiscalYear.GetFirstPostingDate(false), false);
        asserterror ServMoveEntries.MoveServiceItemLedgerEntries(ServiceItem);

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(CheckIfCanBeDeletedServiceItemDatePeriodErr, ServiceItem.TableCaption(), ServiceItem."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD361_MoveServiceItemLedgerEntries_UT_Negative_ExistingOpenEntry()
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceItem: Record "Service Item";
        ServMoveEntries: Codeunit "Serv. Move Entries";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376221] COD361 MoveEntries.MoveServiceItemLedgerEntries() throws an error in case of Open Service Ledger Entry
        Initialize();

        CreateServiceItem(ServiceItem);
        MockServiceItemLedgerEntry(ServiceLedgerEntry, ServiceItem."No.", 0D, true);
        asserterror ServMoveEntries.MoveServiceItemLedgerEntries(ServiceItem);

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(CheckIfCanBeDeletedServiceItemOpenErr, ServiceItem.TableCaption(), ServiceItem."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeServiceItemCustomerNoIfServiceLineExist()
    var
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceHeader: Record "Service Header";
        ExpectedErrorString: Text;
    begin
        // [SCENARIO 169304] System does not allow to change Customer in Service Item when it has Service Item Lines
        Initialize();

        // [GIVEN] Service Item "SI1": serial number "SN1"
        // [GIVEN] Service order "O1": service line "L1"; Customer No. = "C1"
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [WHEN] Validate "C2" on "SI"."Customer No."
        asserterror ServiceItem.Validate("Customer No.", LibrarySales.CreateCustomerNo());

        // [THEN] First line of Error  "You cannot change the Customer No. in the service item because of the following outstanding service order line:" thrown.
        // [THEN] Second line of Error "Order "O1", line "L1", service item number "SI1", serial number "SN1", customer "C1", ship-to code "S1"." thrown.
        Assert.ExpectedError(ServiceItemDuplicateErr1);
        ExpectedErrorString :=
          StrSubstNo(
            ServiceItemDuplicateErr2,
            ServiceItemLine."Document No.", ServiceItemLine."Line No.", ServiceItemLine."Service Item No.",
            ServiceItemLine."Serial No.", ServiceItemLine."Customer No.", ServiceItemLine."Ship-to Code");
        Assert.ExpectedError(ExpectedErrorString);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAndWatchTroubleshootingSetupViaPageFromItem()
    var
        Item: Record Item;
        TroubleshootingHeader: Record "Troubleshooting Header";
        TroubleshootingSetupRec: Record "Troubleshooting Setup";
        ItemCard: TestPage "Item Card";
        TroubleshootingSetupPage1: TestPage "Troubleshooting Setup";
        TroubleshootingSetupPage2: TestPage "Troubleshooting Setup";
    begin
        // [FEATURE] [Troubleshooting Setup] [UI]
        // [SCENARIO 201242] Troubleshooting Setup created for an Item, should be shown in Troubleshooting setup page called for this Item

        Initialize();

        // [GIVEN] Item "III"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Item Card page open for "III"
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        // [GIVEN] Troubleshooting Setup open from Item Card
        TroubleshootingSetupPage1.Trap();
        ItemCard."Troubleshooting Setup".Invoke();

        // [GIVEN] Troubleshooting Header with "No." = "XXX"
        MockTroubleshootingHeader(TroubleshootingHeader);

        // [GIVEN] Troubleshooting Header "XXX" is set for Troubleshooting setup for Item "III"
        TroubleshootingSetupPage1."Troubleshooting No.".Value := TroubleshootingHeader."No.";
        TroubleshootingSetupPage1.Next();
        TroubleshootingSetupPage1.OK().Invoke();

        // [WHEN] Open Troubleshooting Setup for Item "III" again
        TroubleshootingSetupPage2.Trap();
        ItemCard."Troubleshooting Setup".Invoke();

        // [THEN] Troubleshooting Setup inserted for "III"
        TroubleshootingSetupRec.Init();
        TroubleshootingSetupRec.SetRange("No.", Item."No.");
        TroubleshootingSetupRec.SetRange("Troubleshooting No.", TroubleshootingHeader."No.");
        Assert.RecordIsNotEmpty(TroubleshootingSetupRec);

        TroubleshootingSetupPage2."Troubleshooting No.".AssertEquals(TroubleshootingHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckServiceItemNoIsShownOrHiddenOnTheCard()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        ServiceItemCard: TestPage "Service Item Card";
        OldServiceItemNoSeries: Code[20];
    begin
        // [SCENARIO 424764] System will hide No. field on Service Item card page if "Service Item Nos." is default without manual input
        Initialize();

        // [GIVEN] Number series related to "Service Item Nos." in "Service Mgt. Setup" table
        ServiceMgtSetup.Get();
        if ServiceMgtSetup."Service Item Nos." <> '' then
            OldServiceItemNoSeries := ServiceMgtSetup."Service Item Nos.";
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        ServiceMgtSetup.Validate("Service Item Nos.", NoSeries.Code);
        ServiceMgtSetup.Modify(true);

        // [WHEN] [THEN] init new service item and check if "No." field is hidden
        DocumentNoVisibility.ClearState();
        ServiceItemCard.OpenNew();
        Assert.IsFalse(ServiceItemCard."No.".Visible(), 'No. field should be hidden');

        // [WHEN] Service item no series is set to manual nos
        NoSeries.Get(ServiceMgtSetup."Service Item Nos.");
        NoSeries."Manual Nos." := true;
        NoSeries.Modify(true);

        // [THEN] init new service item and check if "No." field is visible
        DocumentNoVisibility.ClearState();
        Clear(ServiceItemCard);
        ServiceItemCard.OpenNew();
        Assert.IsTrue(ServiceItemCard."No.".Visible(), 'No. field should be visible');

        if OldServiceItemNoSeries <> '' then begin
            ServiceMgtSetup.Validate("Service Contract Nos.", OldServiceItemNoSeries);
            ServiceMgtSetup.Modify(true);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemComponentSplitLineNoPreventDuplication()
    var
        Item: array[2] of Record Item;
        ServiceItem: Record "Service Item";
        ServiceItemComponent: Record "Service Item Component";
    begin
        // [FEATURE] [Service Item Component] [UI]
        // [SCENARIO 221262] New Service Item Component is inserted with "Line No." = 20000 when only one component exists and for it Active = FALSE
        Initialize();

        // [GIVEN] Service Item "SI" and two Items "I1" and "I2"
        CreateServiceItem(ServiceItem);
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);

        // [GIVEN] "I1" is not Active "Service Item Component" of "SI"
        InsertServiceItemComponent(ServiceItemComponent, ServiceItem."No.", Item[1]."No.", 10000);

        // [WHEN] Insert "I2" as "Service Item Component" of "SI" through "Service Item Component List" page, and set not Active
        InsertServiceItemComponentOnPage(ServiceItem, Item[2]."No.");

        // [THEN] "I2" as "Service Item Component" has "Line No." = 20000
        FindServiceItemComponent(ServiceItemComponent, ServiceItem."No.", Item[2]."No.");
        ServiceItemComponent.TestField("Line No.", 20000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemComponentSplitLineNoSingleNewLine()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceItemComponent: Record "Service Item Component";
        LineNo: Integer;
    begin
        // [FEATURE] [Service Item Component] [UI] [UT]
        // [SCENARIO 221262] When single "Service Item Component" is inserted it has "Line No." = 10000
        Initialize();

        // [GIVEN] Service Item "SI" and Item "I"
        CreateServiceItem(ServiceItem);
        LibraryInventory.CreateItem(Item);

        // [WHEN] "I" is inserted as "Service Item Component" "SIC" of "SI"
        ServiceItemComponent.Validate("Parent Service Item No.", ServiceItem."No.");
        LineNo := ServiceItemComponent.SplitLineNo(ServiceItemComponent, true);

        // [THEN] "SIC" has "Line No." = 10000
        Assert.AreEqual(
          10000, LineNo, StrSubstNo(IncorrectValueErr, ServiceItemComponent.TableName, ServiceItemComponent.FieldName("Line No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemComponentSplitLineNoNewLineBeforeExistingLines()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceItemComponent: array[3] of Record "Service Item Component";
        LineNo: Integer;
        i: Integer;
    begin
        // [FEATURE] [Service Item Component] [UI] [UT]
        // [SCENARIO 221262] When new "Service Item Component" is inserted before existing lines it has "Line No." = 5000
        Initialize();

        // [GIVEN] Service Item "SI" and two Items "I1" and "I2" are Service Item Components "SIC1" and "SIC2"
        CreateServiceItem(ServiceItem);
        for i := 1 to 2 do begin
            LibraryInventory.CreateItem(Item);
            LineNo += 10000;
            InsertServiceItemComponent(ServiceItemComponent[i], ServiceItem."No.", Item."No.", LineNo);
        end;

        // [WHEN] Service Item Components "SIC3" is inserted before "SIC1" and "SIC2"
        ServiceItemComponent[3].Validate("Parent Service Item No.", ServiceItem."No.");
        LineNo := ServiceItemComponent[3].SplitLineNo(ServiceItemComponent[1], false);

        // [THEN] "SIC3" has "Line No." = 5000
        Assert.AreEqual(
          5000, LineNo, StrSubstNo(IncorrectValueErr, ServiceItemComponent[3].TableName, ServiceItemComponent[3].FieldName("Line No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemComponentSplitLineNoNewLineAfterExistingLines()
    var
        ServiceItem: Record "Service Item";
        ServiceItemComponent: array[3] of Record "Service Item Component";
        LineNo: Integer;
    begin
        // [FEATURE] [Service Item Component] [UI] [UT]
        // [SCENARIO 221262] When new "Service Item Component" is inserted after two existing lines it has "Line No." = 30000
        Initialize();

        // [GIVEN] Service Item "SI" and two Items "I1" and "I2" are Service Item Components "SIC1" and "SIC2"
        CreateServiceItem(ServiceItem);
        InsertServiceItemComponents(ServiceItemComponent, ServiceItem."No.");

        // [WHEN] Service Item Components "SIC3" is inserted after "SIC1" and "SIC2"
        ServiceItemComponent[3].Validate("Parent Service Item No.", ServiceItem."No.");
        LineNo := ServiceItemComponent[3].SplitLineNo(ServiceItemComponent[2], true);

        // [THEN] "SIC3" has "Line No." = 30000
        Assert.AreEqual(
          30000, LineNo, StrSubstNo(IncorrectValueErr, ServiceItemComponent[3].TableName, ServiceItemComponent[3].FieldName("Line No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemComponentSplitLineNoNewLineBetweenExistingLines()
    var
        ServiceItem: Record "Service Item";
        ServiceItemComponent: array[3] of Record "Service Item Component";
        LineNo: Integer;
    begin
        // [FEATURE] [Service Item Component] [UI] [UT]
        // [SCENARIO 221262] When new "Service Item Component" is inserted between two existing lines it has "Line No." = 15000
        Initialize();

        // [GIVEN] Service Item "SI" and two Items "I1" and "I2" are Service Item Components "SIC1" and "SIC2"
        CreateServiceItem(ServiceItem);
        InsertServiceItemComponents(ServiceItemComponent, ServiceItem."No.");

        // [WHEN] Service Item Components "SIC3" is inserted between "SIC1" and "SIC2"
        ServiceItemComponent[3].Validate("Parent Service Item No.", ServiceItem."No.");
        LineNo := ServiceItemComponent[3].SplitLineNo(ServiceItemComponent[2], false);

        // [THEN] "SIC3" has "Line No." = 15000
        Assert.AreEqual(
          15000, LineNo, StrSubstNo(IncorrectValueErr, ServiceItemComponent[3].TableName, ServiceItemComponent[3].FieldName("Line No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemComponentSplitLineBlankParentServiceItem()
    var
        ServiceItemComponent: Record "Service Item Component";
    begin
        // [FEATURE] [Service Item Component] [UI] [UT]
        // [SCENARIO 221262] If "Service Item Component" SplitLineNo called and "Parent Service Item No." is blank then error "Parent Service Item No. must have a value in Service Item Component" occurs.
        Initialize();

        // [WHEN] "Service Item Component" SplitLineNo called and "Parent Service Item No." is blank
        asserterror ServiceItemComponent.SplitLineNo(ServiceItemComponent, true);

        // [THEN] error "Parent Service Item No. must have a value in Service Item Component" occurs.
        Assert.ExpectedError(ParentServiceItemNoMustHaveValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemUpdateOnVendorDelete()
    var
        Vendor: Record Vendor;
        ServiceItem: Record "Service Item";
        ServiceItems: Codeunit "Service Items";
        NewVendorNo: Code[20];
    begin
        // [FEATURE] [Service Item] [UT]
        // [SCENARIO 322232] Service item Vendor No. could be updated during the vendor deletion
        Initialize();

        // [GIVEN] Vendor "V1"
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Service Item with Vendor No. = "V1"
        CreateServiceItem(ServiceItem);
        ServiceItem.Validate("Vendor No.", Vendor."No.");
        ServiceItem.Modify();

        // [GIVEN] Subsribe to OnBeforeMoveVendEntries to change Vendor No. to "V2"
        NewVendorNo := LibraryUtility.GenerateRandomCode20(Vendor.FieldNo("No."), Database::Vendor);
        BindSubscription(ServiceItems);
        ServiceItems.SetGlobalVendorNo(NewVendorNo);

        // [WHEN] Vendor "V1" is being deleted
        Vendor.delete(true);

        // [THEN] Service Item has Vendor No. = "V2"
        ServiceItem.Find();
        ServiceItem.TestField("Vendor No.", NewVendorNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure ServiceContractUpdateOnCustomerDelete()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceItems: Codeunit "Service Items";
        NewCustomerNo: Code[20];
    begin
        // [FEATURE] [Service Contract] [UT]
        // [SCENARIO 322232] Cancelled service contract Customer No. could be updated during the customer deletion
        Initialize();

        // [GIVEN] Cancelled Service Contract with Customer No. = "C1"
        CreateServiceContractHeader(ServiceContractHeader, LibrarySales.CreateCustomerNo());
        ServiceContractHeader.Status := "Service Contract Status"::Cancelled;
        ServiceContractHeader.Modify();

        // [GIVEN] Subsribe to OnBeforeMoveVendEntries to change Customer No. to "C2"
        NewCustomerNo := LibraryUtility.GenerateRandomCode20(Customer.FieldNo("No."), Database::Customer);
        BindSubscription(ServiceItems);
        ServiceItems.SetGlobalCustomerNo(NewCustomerNo);

        // [WHEN] Customer "C1" is being deleted
        Customer.Get(ServiceContractHeader."Customer No.");
        Customer.delete(true);

        // [THEN] Service Contract has Customer No. = "C2"
        ServiceContractHeader.Find();
        ServiceContractHeader.TestField("Customer No.", NewCustomerNo);
        ServiceContractHeader.TestField("Bill-to Customer No.", NewCustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemUpdateOnItemDelete()
    var
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceItems: Codeunit "Service Items";
        NewItemNo: Code[20];
    begin
        // [FEATURE] [Service Item] [UT]
        // [SCENARIO 322232] Service item Item No. could be updated during the Item deletion
        Initialize();

        // [GIVEN] Service Item with Item No. = "I1"
        CreateServiceItem(ServiceItem);
        ServiceItem."Item No." := LibraryInventory.CreateItemNo();
        ServiceItem.Modify();

        // [GIVEN] Subsribe to OnBeforeMoveVendEntries to change Item No. to "I2"
        NewItemNo := LibraryUtility.GenerateRandomCode20(Item.FieldNo("No."), Database::Item);
        BindSubscription(ServiceItems);
        ServiceItems.SetGlobalItemNo(NewItemNo);

        // [WHEN] Item "I1" is being deleted
        Item.Get(ServiceItem."Item No.");
        Item.delete(true);

        // [THEN] Service Item has Item No. = "I2"
        ServiceItem.Find();
        ServiceItem.TestField("Item No.", NewItemNo);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Items");
        // Lazy Setup.
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Items");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Items");
    end;

    local procedure AssignServiceItemGroupSkill(No: Code[20])
    var
        ServiceItemCard: TestPage "Service Item Card";
    begin
        ServiceItemCard.OpenEdit();
        ServiceItemCard.FILTER.SetFilter("No.", No);
        ServiceItemCard."Service Item Group Code".SetValue(ServiceItemGroupWithSkill());
        ServiceItemCard.OK().Invoke();
    end;

    local procedure AssignSerialNumberInItemJournal(ItemJournalLineBatchName: Code[10])
    var
        ItemJournal: TestPage "Item Journal";
    begin
        Commit();  // Commit required to avoid rollback of write transaction before opening Item Journal Item Tracking Lines.
        ItemJournal.OpenEdit();
        ItemJournal.CurrentJnlBatchName.SetValue(ItemJournalLineBatchName);
        LibraryVariableStorage.Enqueue(ItemTrackingLinesAssignment::AssignSerialNo);
        ItemJournal.ItemTrackingLines.Invoke();
    end;

    local procedure AssignTrackingOnItemJournalLines(JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.FindFirst();
        ItemJournalLine.OpenItemTrackingLines(false);
    end;

    local procedure PageCreateServiceItem(var ServiceItemNo: Code[20])
    var
        ServiceItemCard: TestPage "Service Item Card";
    begin
        ServiceItemCard.OpenNew();
        ServiceItemCard.Description.Activate();
        ServiceItemNo := ServiceItemCard."No.".Value();
    end;

    local procedure PageUpdateServiceItem(No: Code[20])
    var
        Item: Record Item;
        ServiceItemCard: TestPage "Service Item Card";
    begin
        LibraryInventory.CreateItem(Item);
        ServiceItemCard.OpenEdit();
        ServiceItemCard.FILTER.SetFilter("No.", No);
        ServiceItemCard."Item No.".SetValue(Item."No.");
        ServiceItemCard.OK().Invoke();
    end;

    local procedure ServiceItemGroupWithSkill(): Code[10]
    var
        ResourceSkill: Record "Resource Skill";
        ServiceItemGroup: Record "Service Item Group";
    begin
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        LibraryResource.CreateResourceSkill(
          ResourceSkill, ResourceSkill.Type::"Service Item Group", ServiceItemGroup.Code, CreateSkillCode());
        exit(ServiceItemGroup.Code);
    end;

    local procedure ServMgtSetupForContractValCalc(ContractValueCalcMethod: Option "None","Based on Unit Price","Based on Unit Cost"; ContractValuePercentage: Decimal) ContractValueCalcMethodOld: Integer
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // Setup the fields Contract Value Calc. Method and Contract Value % of the Service Management Setup.
        ServiceMgtSetup.Get();
        ContractValueCalcMethodOld := ServiceMgtSetup."Contract Value Calc. Method";
        ServiceMgtSetup.Validate("Contract Value Calc. Method", ContractValueCalcMethod);
        ServiceMgtSetup.Validate("Contract Value %", ContractValuePercentage);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure CreateBOMComponent(ParentItemNo: Code[20]; ItemNo: Code[20])
    var
        BOMComponent: Record "BOM Component";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RecRef: RecordRef;
    begin
        // Create BOM Component with random Unit of Measure.
        ItemUnitOfMeasure.Init();
        ItemUnitOfMeasure.SetRange("Item No.", ItemNo);
        RecRef.GetTable(ItemUnitOfMeasure);
        LibraryUtility.FindRecord(RecRef);
        RecRef.SetTable(ItemUnitOfMeasure);

        LibraryInventory.CreateBOMComponent(
          BOMComponent, ParentItemNo, BOMComponent.Type::Item, ItemNo, LibraryRandom.RandInt(10), ItemUnitOfMeasure.Code);
    end;

    local procedure CreateItemWithBOMComponents(): Code[20]
    var
        Item: Record Item;
        Item2: Record Item;
    begin
        // Create Item with two BOM Components.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        CreateBOMComponent(Item."No.", Item2."No.");
        LibraryInventory.CreateItem(Item2);
        CreateBOMComponent(Item."No.", Item2."No.");
        exit(Item."No.");
    end;

    local procedure CreateItemWithServiceItemGroup(ItemTrackingCode: Code[10]): Code[20]
    var
        Item: Record Item;
        ServiceItemGroup: Record "Service Item Group";
    begin
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroup.Validate("Create Service Item", true);
        ServiceItemGroup.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Service Item Group", ServiceItemGroup.Code);
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithTwoUnitsOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"): Code[10]
    var
        Item: Record Item;
    begin
        Item.Get(CreateItemWithServiceItemGroup(FindItemTrackingCode(true, false)));
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryUtility.GenerateRandomFraction());
        exit(Item."Base Unit of Measure");
    end;

    local procedure CreateMultipleServiceLines(ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer)
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
        Counter: Integer;
    begin
        // Create 2 to random number of lines.
        LibraryInventory.CreateItem(Item);
        for Counter := 1 to 1 + LibraryRandom.RandInt(10) do begin
            Clear(ServiceLine);
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
            ServiceLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));  // Input any random value.
            ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
            ServiceLine.Modify(true);
            Item.Next();
        end;
    end;

    local procedure CreateSalesHeaderNoLocation(var SalesHeader: Record "Sales Header")
    begin
        // Create Sales Header with any Customer that has no location.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; PostingDate: Date; ItemUnitOfMeasureCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Document No.",
          CopyStr(LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Document No."), DATABASE::"Item Journal Line"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Item Journal Line", ItemJournalLine.FieldNo("Document No."))));
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Validate("Unit of Measure Code", ItemUnitOfMeasureCode);
        ItemJournalLine.Validate(Amount, LibraryUtility.GenerateRandomFraction());
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemWithVendor(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Service Item Group", CreateServiceGroupForAutoCreat());
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateDropShipmentSalesOrder(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Qty: Integer)
    var
        SalesHeader: Record "Sales Header";
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);
    end;

    local procedure CreateReqLineAndCarryOutWksh(SalesLine: Record "Sales Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RetrieveDimensionsFrom: Option Item,"Sales Line";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, RetrieveDimensionsFrom::"Sales Line");
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure CreateSalesLine(var Quantity: Decimal; SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Line with any random Quantity.
        Quantity := LibraryRandom.RandInt(10);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateServiceItem(var ServiceItem: Record "Service Item")
    begin
        // Create new Service Item with random Customer.
        LibraryService.CreateServiceItem(ServiceItem, LibrarySales.CreateCustomerNo());
    end;

    local procedure CreateServiceItemFromOrder(var ServiceItemLine: Record "Service Item Line")
    var
        ServItemManagement: Codeunit ServItemManagement;
    begin
        CreateServiceItemLineWithItem(ServiceItemLine);
        ServItemManagement.CreateServItemOnServItemLine(ServiceItemLine);
        ServiceItemLine.Modify(true);
    end;

    local procedure CreateServiceItemGroup(): Code[10]
    var
        ServiceItemGroup: Record "Service Item Group";
    begin
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        exit(ServiceItemGroup.Code);
    end;

    local procedure CreateServiceItemLineWithItem(var ServiceItemLine: Record "Service Item Line")
    var
        ServiceHeader: Record "Service Header";
    begin
        // Create Service Order - Service Header and Service Item Line with description and Item No.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate("Item No.", CreateItemWithBOMComponents());
        ServiceItemLine.Validate(
          Description, Format(ServiceItemLine."Document Type") + ServiceItemLine."Document No." + Format(ServiceItemLine."Line No."));
        ServiceItemLine.Modify(true);
    end;

    local procedure CreateServiceGroupForAutoCreat(): Code[10]
    var
        ServiceItemGroup: Record "Service Item Group";
    begin
        // Create Service Item Group with the field Create Service Item as TRUE, to automatically register Items as Service Items on
        // Shipping through Sales Orders or Sales Invoices.
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroup.Validate("Create Service Item", true);
        ServiceItemGroup.Modify(true);
        exit(ServiceItemGroup.Code);
    end;

    local procedure CreateServiceItemGrpWithSkill(var ServiceItemGroupCode: Code[10]; var ResourceSkill: Record "Resource Skill")
    var
        ServiceItemGroup: Record "Service Item Group";
    begin
        LibraryService.CreateServiceItemGroup(ServiceItemGroup);
        ServiceItemGroupCode := ServiceItemGroup.Code;

        // Create Skill Code and validate in the Skill Code field of the Resource Skill.
        LibraryResource.CreateResourceSkill(ResourceSkill, ResourceSkill.Type::"Service Item Group", ServiceItemGroupCode, CreateSkillCode());
    end;

    local procedure CreateServiceItemWithAmounts(var ServiceItem: Record "Service Item")
    begin
        // Create new Service Item and validate random values for Sales Unit Price, Sales Unit Cost, Default Contract Cost and Default
        // Contract Value in the Service Item.
        CreateServItemWithSalesUnitAmt(ServiceItem);
        ServiceItem.Validate("Default Contract Cost", LibraryRandom.RandInt(100));
        ServiceItem.Validate("Default Contract Value", LibraryRandom.RandInt(100));
        ServiceItem.Modify(true);
    end;

    local procedure CreateServItemWithSalesUnitAmt(var ServiceItem: Record "Service Item")
    begin
        // Create new Service Item and validate random values for Sales Unit Price and Sales Unit Cost in the Service Item.
        CreateServiceItem(ServiceItem);
        ServiceItem.Validate("Sales Unit Price", LibraryRandom.RandInt(100));
        ServiceItem.Validate("Sales Unit Cost", LibraryRandom.RandInt(100));
        ServiceItem.Modify(true);
    end;

    local procedure CreateServiceItemWithBOMItem(var ServiceHeader: Record "Service Header"; var ServiceItemNo: Code[20]; var ItemNo: Code[20])
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Create a new Item having two BOM Components. Create a new Service Item and validate the Item in the
        // Item No. field of the Service Item.
        CreateServiceItem(ServiceItem);
        ServiceItem.Validate("Item No.", CreateItemWithBOMComponents());
        ServiceItem.Modify(true);

        // Copy Service Item Component from BOM to Service Item.
        CODEUNIT.Run(CODEUNIT::"ServComponent-Copy from BOM", ServiceItem);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // Find the next Item.
        ItemNo := LibraryInventory.CreateItemNo();
        ServiceItemNo := ServiceItem."No.";
    end;

    local procedure CreateServiceItemWithTwoCompon(var ServiceItem: Record "Service Item"; var ServiceItemComponent: Record "Service Item Component"; var ServiceItemComponent2: Record "Service Item Component"; var ItemNo: Code[20])
    begin
        // Create a new Service Item with any two random Service Item Components.
        CreateServiceItem(ServiceItem);
        LibraryService.CreateServiceItemComponent(
          ServiceItemComponent, ServiceItem."No.", ServiceItemComponent.Type::Item, LibraryInventory.CreateItemNo());
        LibraryService.CreateServiceItemComponent(
          ServiceItemComponent2, ServiceItem."No.", ServiceItemComponent.Type::Item, LibraryInventory.CreateItemNo());
        ItemNo := LibraryInventory.CreateItemNo();
    end;

    local procedure CreateServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header"; CustomerNo: Code[20])
    begin
        // Create a new Prepaid Service Header.
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CustomerNo);
        ServiceContractHeader.Validate(Prepaid, true);
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateServiceLineWithItem(var ServiceLine: Record "Service Line"; var Item: Record Item; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    begin
        // Create Service Line with any Item and random value for Quantity.
        LibraryInventory.CreateItem(Item);
        CreateServiceLine(ServiceLine, Item."No.", ServiceHeader, ServiceItemNo);
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ItemNo: Code[20]; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    begin
        // Create Service Line with random value for Quantity.
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));  // Integer is required for replacement of components.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineReplacement(var ServiceLine: Record "Service Line"; ServiceItemLine: Record "Service Item Line"; CopyComponentsFrom2: Option; Replacement2: Option)
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(ServiceItemLine."Document Type", ServiceItemLine."Document No.");

        // Assign Global Variables for Form Handler.
        SerialNo := ServiceHeader."No.";
        CopyComponentsFrom := CopyComponentsFrom2;
        Replacement := Replacement2;

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ServiceItemLine."Item No.");
        ServiceLine.Validate("Service Item No.", ServiceItemLine."Service Item No.");
        ServiceLine.Validate("No.", ServiceItemLine."Item No.");
        ServiceLine.Validate(Quantity, 1);  // Use 1 for Service Item Replacement.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServOrderForServItemCrea(var ServiceItemLine: Record "Service Item Line"; Type: Option Item,"Service Item Group")
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');

        if Type = Type::Item then
            ServiceItemLine.Validate("Item No.", LibraryInventory.CreateItemNo())
        else
            ServiceItemLine.Validate("Service Item Group Code", CreateServiceItemGroup());

        // Validate Description as Primary Key since the value is not important.
        if ServiceItemLine.Description = '' then
            ServiceItemLine.Validate(
              Description, Format(ServiceItemLine."Document Type") + ServiceItemLine."Document No." + Format(ServiceItemLine."Line No."));
        ServiceItemLine.Modify(true);
    end;

    local procedure CreateSkillCode(): Code[10]
    var
        SkillCode: Record "Skill Code";
    begin
        LibraryResource.CreateSkillCode(SkillCode);
        exit(SkillCode.Code);
    end;

    local procedure CreateAndAssignTroubleshooting(var TroubleshootingHeaderNo: Code[20]; Type: Enum "Troubleshooting Item Type"; No: Code[20])
    var
        TroubleshootingSetup: Record "Troubleshooting Setup";
        TroubleshootingLine: Record "Troubleshooting Line";
        TroubleshootingHeader: Record "Troubleshooting Header";
    begin
        LibraryService.CreateTroubleshootingHeader(TroubleshootingHeader);
        LibraryService.CreateTroubleshootingLine(TroubleshootingLine, TroubleshootingHeader."No.");

        // Create Troubleshooting Setup and assign the number of the Troubleshooting Header to it.
        LibraryService.CreateTroubleshootingSetup(TroubleshootingSetup, Type, No, TroubleshootingHeader."No.");
        TroubleshootingHeaderNo := TroubleshootingHeader."No.";
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line")
    var
        Item: Record Item;
    begin
        Item.Get(CreateItemWithServiceItemGroup(FindItemTrackingCode(false, true)));
        CreateItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase,
          WorkDate(), Item."Base Unit of Measure", Item."No.", LibraryRandom.RandInt(10));
        AssignSerialNumberInItemJournal(ItemJournalLine."Journal Batch Name");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostMutipleItemJournalLine(var ItemJournalLine: Record "Item Journal Line")
    var
        Item: Record Item;
    begin
        Item.Get(CreateItemWithServiceItemGroup(FindItemTrackingCode(false, true)));
        CreateItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase,
          WorkDate(), Item."Base Unit of Measure", Item."No.", LibraryRandom.RandIntInRange(2, 100));
        AssignSerialNumberInItemJournal(ItemJournalLine."Journal Batch Name");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line")
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateAndPostSalesOrder(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateAndPostSalesOrderWithItemTracking(CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingLinesAssignment::SelectEntries);
        SalesLine.OpenItemTrackingLines();
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesReturnOrder(CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustomerNo);
        SalesHeader.GetPstdDocLinesToReverse();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure ExecuteConfirmHandlerInvoiceES()
    begin
        if Confirm(StrSubstNo(ExpectedConfirmQst)) then;
    end;

    local procedure AssignLotNoOnItemTrackingLines(AssignedValue: Option)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // Create and Post Item Journal with Entry Type Purchase after assigning Lotno.
        // Create Item Journal with Entry Type Sale and Update Lot no. using Select Entries Or Assist Edit.
        Initialize();
        CreateItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, WorkDate(),
          CreateItemWithTwoUnitsOfMeasure(ItemUnitOfMeasure), ItemUnitOfMeasure."Item No.", LibraryRandom.RandDecInRange(11, 20, 2));
        LibraryVariableStorage.Enqueue(ItemTrackingLinesAssignment::AssignLotNo);
        AssignTrackingOnItemJournalLines(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        UpdateExpirationDateOnReservationEntry(ItemUnitOfMeasure."Item No.");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::Sale,
          CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(5)), WorkDate()), ItemUnitOfMeasure.Code, ItemUnitOfMeasure."Item No.",
          LibraryRandom.RandDecInRange(1, 10, 2));
        LibraryVariableStorage.Enqueue(AssignedValue);
        Commit();
        AssignTrackingOnItemJournalLines(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Post Item Journal.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Verify Sales Amount on Item Ledger Entry.
        VerifySalesAmountOnItemLedgerEntry(ItemJournalLine);
    end;

    local procedure MockServiceItemLedgerEntry(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceItemNo: Code[20]; PostingDate: Date; IsOpen: Boolean)
    begin
        ServiceLedgerEntry.Init();
        ServiceLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(ServiceLedgerEntry, ServiceLedgerEntry.FieldNo("Entry No."));
        ServiceLedgerEntry."Service Item No. (Serviced)" := ServiceItemNo;
        ServiceLedgerEntry."Posting Date" := PostingDate;
        ServiceLedgerEntry.Open := IsOpen;
        ServiceLedgerEntry.Insert();
    end;

    local procedure InsertServiceItemComponentOnPage(ServiceItem: Record "Service Item"; ItemNo: Code[20])
    var
        ServiceItemComponent: Record "Service Item Component";
        ServiceItemList: TestPage "Service Item List";
        ServiceItemComponentList: TestPage "Service Item Component List";
    begin
        ServiceItemList.OpenEdit();
        ServiceItemList.GotoRecord(ServiceItem);
        ServiceItemComponentList.Trap();
        ServiceItemList."Com&ponent List".Invoke();
        ServiceItemComponentList.First();
        ServiceItemComponentList.Next();
        ServiceItemComponentList.Type.SetValue(ServiceItemComponent.Type::Item);
        ServiceItemComponentList."No.".SetValue(ItemNo);
        ServiceItemComponentList.Close();
        ServiceItemList.Close();
    end;

    [Scope('OnPrem')]
    procedure InsertServiceItemComponent(var ServiceItemComponent: Record "Service Item Component"; ServiceItemNo: Code[20]; ItemNo: Code[20]; LineNo: Integer)
    begin
        ServiceItemComponent."Parent Service Item No." := ServiceItemNo;
        ServiceItemComponent."Line No." := LineNo;
        ServiceItemComponent.Validate(Type, ServiceItemComponent.Type::Item);
        ServiceItemComponent.Validate("No.", ItemNo);
        ServiceItemComponent.Insert();
    end;

    [Scope('OnPrem')]
    procedure InsertServiceItemComponents(var ServiceItemComponent: array[3] of Record "Service Item Component"; ServiceItemNo: Code[20])
    var
        Item: Record Item;
        LineNo: Integer;
        i: Integer;
    begin
        for i := 1 to 2 do begin
            LibraryInventory.CreateItem(Item);
            LineNo += 10000;
            InsertServiceItemComponent(ServiceItemComponent[i], ServiceItemNo, Item."No.", LineNo);
        end;
    end;

    local procedure FilterServiceDocumentLog(var ServiceDocumentLog: Record "Service Document Log"; DocumentType: Enum "Service Document Type"; DocumentNo: Code[20]; EventNo: Integer)
    begin
        ServiceDocumentLog.SetRange("Document Type", DocumentType);
        ServiceDocumentLog.SetRange("Document No.", DocumentNo);
        ServiceDocumentLog.SetRange("Event No.", EventNo);
    end;

    local procedure FindDifferentItem(): Code[20]
    begin
        exit(LibraryInventory.CreateItemNo());
    end;

    local procedure FindServiceItem(var ServiceItem: Record "Service Item"; ServiceItemLine: Record "Service Item Line")
    begin
        ServiceItem.SetRange("Item No.", ServiceItemLine."Item No.");
        ServiceItem.SetRange("Serial No.", ServiceItemLine."Document No.");
        ServiceItem.FindFirst();
    end;

    local procedure FindServiceItemByItemNo(var ServiceItem: Record "Service Item"; ItemNo: Code[20])
    begin
        ServiceItem.SetRange("Item No.", ItemNo);
        ServiceItem.FindFirst();
    end;

    local procedure FindItemTrackingCode(LotSpecific: Boolean; SNSpecific: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SNSpecific, LotSpecific);
        ItemTrackingCode.SetRange("Lot Sales Inbound Tracking", LotSpecific);
        ItemTrackingCode.SetRange("Lot Sales Outbound Tracking", LotSpecific);
        ItemTrackingCode.SetRange("SN Sales Inbound Tracking", SNSpecific);
        ItemTrackingCode.SetRange("SN Sales Outbound Tracking", SNSpecific);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.FindFirst();
    end;

    local procedure FindPostedShipment(CustNo: Code[20]; OrderNo: Code[20]): Code[20]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Sell-to Customer No.", CustNo);
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
        exit(SalesShipmentHeader."No.");
    end;

    local procedure FindPurchLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        PurchaseLine.FindFirst();
    end;

    local procedure FindPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
    end;

    local procedure FindPostedReceipt(VendNo: Code[20]; OrderNo: Code[20]): Code[20]
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader.SetRange("Buy-from Vendor No.", VendNo);
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        PurchRcptHeader.FindFirst();
        exit(PurchRcptHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure FindServiceItemComponent(var ServiceItemComponent: Record "Service Item Component"; ServiceItemNo: Code[20]; ItemNo: Code[20])
    begin
        ServiceItemComponent.SetRange("Parent Service Item No.", ServiceItemNo);
        ServiceItemComponent.SetRange("No.", ItemNo);
        ServiceItemComponent.FindFirst();
    end;

    local procedure GetRefinedUnitCost(Item: Record Item; ServiceLineUnitCostLCY: Decimal): Decimal
    begin
        // Find Unit Cost applicable for Service Line.
        if Item."Costing Method" = Item."Costing Method"::Standard then
            exit(Item."Unit Cost");
        exit(ServiceLineUnitCostLCY);
    end;

    local procedure MockTroubleshootingHeader(var TroubleshootingHeader: Record "Troubleshooting Header")
    begin
        TroubleshootingHeader.Init();
        TroubleshootingHeader."No." :=
          LibraryUtility.GenerateRandomCode(TroubleshootingHeader.FieldNo("No."), DATABASE::"Troubleshooting Header");
        TroubleshootingHeader.Insert();
    end;

    local procedure RetrveAndChckCompLnForServItem(ServiceItemNo: Code[20])
    var
        ServiceItemComponent: Record "Service Item Component";
    begin
        // Retrieve the first Service Item Component Line.
        ServiceItemComponent.SetRange(Active, true);
        ServiceItemComponent.SetRange("Parent Service Item No.", ServiceItemNo);
        ServiceItemComponent.FindSet();

        // Verify: Verify that the Replaced Component list for the first Item selected as component is 1.
        VerifyNoOfReplacedComponents(ServiceItemComponent, 1);
        ServiceItemComponent.Next();

        // Verify: Verify that the Replaced Component list for the second Item selected as component is empty.
        VerifyNoOfReplacedComponents(ServiceItemComponent, 0);
    end;

    procedure SetGlobalVendorNo(NewGlobalVendorNo: code[20])
    begin
        GlobalVendorNo := NewGlobalVendorNo;
    end;

    procedure SetGlobalCustomerNo(NewGlobalCustomerNo: code[20])
    begin
        GlobalCustomerNo := NewGlobalCustomerNo;
    end;

    procedure SetGlobalItemNo(NewGlobalItemNo: code[20])
    begin
        GlobalItemNo := NewGlobalItemNo;
    end;

    local procedure UpdateExpirationDateOnReservationEntry(ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst();
        ReservationEntry.Validate("Expiration Date", CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(5), WorkDate())));
        ReservationEntry.Modify(true);
    end;

    local procedure UpdateNoSeries()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        SalesReceivablesSetup.Get();
        NoSeries.Get(SalesReceivablesSetup."Return Order Nos.");
        NoSeries.Validate("Manual Nos.", true);
        NoSeries.Modify(true);
        Clear(DocumentNoVisibility);
    end;

    local procedure VerifyComponents(ServiceItemLine: Record "Service Item Line"; ServiceItemComponent: Record "Service Item Component")
    var
        ServiceItemComponent2: Record "Service Item Component";
        ServiceItem: Record "Service Item";
    begin
        FindServiceItem(ServiceItem, ServiceItemLine);
        ServiceItemComponent2.SetRange("Parent Service Item No.", ServiceItem."No.");
        ServiceItemComponent2.FindFirst();
        ServiceItemComponent2.TestField(Type, ServiceItemComponent.Type);
        ServiceItemComponent2.TestField("No.", ServiceItemComponent."No.");
    end;

    local procedure VerifyCustomer(ServiceHeader: Record "Service Header")
    var
        Customer: Record Customer;
    begin
        Customer.Get(ServiceHeader."Customer No.");
        ServiceHeader.TestField(Name, Customer.Name);
        ServiceHeader.TestField(Address, Customer.Address);
        ServiceHeader.TestField(City, Customer.City);
        ServiceHeader.TestField("Post Code", Customer."Post Code");
    end;

    local procedure VerifyItemLedgerEntry(OrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindFirst();
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Service Shipment");
        ItemLedgerEntry.SetRange("Document No.", ServiceShipmentHeader."No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Item No.", ItemNo);
        ItemLedgerEntry.TestField(Quantity, -Quantity);
        ItemLedgerEntry.TestField("Invoiced Quantity", -Quantity);
    end;

    local procedure VerifyPurchaseReturnOrderLine(PurchaseHeader: Record "Purchase Header"; LineAmount: Decimal; LineDiscount: Decimal; UnitPrice: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Line Amount", LineAmount);
        PurchaseLine.TestField("Line Discount %", LineDiscount);
        PurchaseLine.TestField("Unit Price (LCY)", UnitPrice);
    end;

    local procedure VerifySalesReturnOrderLine(SalesHeader: Record "Sales Header"; LineAmount: Decimal; LineDiscount: Decimal; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
        SalesLine.TestField("Line Discount %", LineDiscount);
        SalesLine.TestField("Line Amount", LineAmount);
        SalesLine.TestField("Unit Price", UnitPrice);
    end;

    local procedure VerifyServiceItem(ServiceItemLine: Record "Service Item Line"; Status: Enum "Service Item Status")
    var
        ServiceItem: Record "Service Item";
    begin
        FindServiceItem(ServiceItem, ServiceItemLine);
        ServiceItem.TestField("Customer No.", ServiceItemLine."Customer No.");
        ServiceItem.TestField(Status, Status);
    end;

    local procedure VerifyServiceItemComponent(ServiceItemLine: Record "Service Item Line")
    var
        ServiceItem: Record "Service Item";
        ServiceItemComponent: Record "Service Item Component";
        BOMComponent: Record "BOM Component";
        Assert: Codeunit Assert;
    begin
        FindServiceItem(ServiceItem, ServiceItemLine);
        BOMComponent.SetRange("Parent Item No.", ServiceItemLine."Item No.");
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        BOMComponent.FindSet();
        repeat
            ServiceItemComponent.SetRange("Parent Service Item No.", ServiceItem."No.");
            ServiceItemComponent.SetRange(Type, ServiceItemComponent.Type::Item);
            ServiceItemComponent.SetRange("No.", BOMComponent."No.");
            Assert.AreEqual(
              BOMComponent."Quantity per",
              ServiceItemComponent.Count,
              StrSubstNo(BOMComponentErr, ServiceItemComponent.TableCaption(), BOMComponent."Quantity per"));
        until BOMComponent.Next() = 0;
    end;

    local procedure VerifyServiceItemLine(ServiceItemLine: Record "Service Item Line")
    var
        ServiceItem: Record "Service Item";
    begin
        ServiceItem.Get(ServiceItemLine."Service Item No.");
        ServiceItemLine.TestField(Priority, ServiceItem.Priority);
        ServiceItemLine.TestField("Response Time (Hours)", ServiceItem."Response Time (Hours)");
        ServiceItemLine.TestField("Service Item Group Code", ServiceItem."Service Item Group Code");
    end;

    local procedure VerifyServiceItemStatistics(ServiceLine: Record "Service Line"; ServiceItem: Record "Service Item")
    begin
        // Verify and match the values in Service Item with the values in the Service Line.
        ServiceItem.SetRange("Type Filter", ServiceItem."Type Filter"::Item);
        ServiceItem.CalcFields("Total Quantity", "Total Qty. Invoiced", "Total Qty. Consumed");
        ServiceItem.TestField("Total Quantity", ServiceLine.Quantity);
        ServiceItem.TestField("Total Qty. Invoiced", ServiceLine."Qty. to Invoice");
        ServiceItem.TestField("Total Qty. Consumed", 0);
    end;

    local procedure VerifyServiceItemTrendscape(Item: Record Item; ServiceLine: Record "Service Line"; ServiceItem: Record "Service Item")
    var
        Currency: Record Currency;
    begin
        // Verify that the value of the Parts Used field in the Service item is the product of the Unit Cost applicable and the Quantity in
        // the Service Line.
        if ServiceLine."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else
            Currency.Get(ServiceLine."Currency Code");

        ServiceItem.SetRange("Type Filter", ServiceItem."Type Filter"::Item);
        ServiceItem.CalcFields("Parts Used");
        // Use GetRefinedCost to find the correct Unit Cost applicable.
        ServiceItem.TestField(
          "Parts Used",
          Round(GetRefinedUnitCost(Item, ServiceLine."Unit Cost (LCY)") * ServiceLine.Quantity, Currency."Amount Rounding Precision"));
    end;

    local procedure VerifyServiceLedgerEntry(ServiceLine: Record "Service Line")
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        ServiceLedgerEntry.SetRange("Service Order No.", ServiceLine."Document No.");
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Shipment);
        ServiceLedgerEntry.FindFirst();
        ServiceLedgerEntry.TestField("No.", ServiceLine."No.");
        ServiceLedgerEntry.TestField(Quantity, ServiceLine.Quantity);
    end;

    local procedure VerifySkillCodeDeletion(ResourceSkill: Record "Resource Skill")
    var
        Assert: Codeunit Assert;
    begin
        // Check that the Resource Skill attached to the Service Item earlier has been deleted.
        Assert.IsFalse(
          ResourceSkill.Get(ResourceSkill.Type::Item, ResourceSkill."No.", ResourceSkill."Skill Code"),
          StrSubstNo(RecordExistsErr, ResourceSkill.TableCaption(), Format(ResourceSkill)));
    end;

    local procedure VerifyNoOfReplacedComponents(ServiceItemComponent: Record "Service Item Component"; NumberofLinesReplaced: Integer)
    var
        ServiceItemComponent2: Record "Service Item Component";
        Assert: Codeunit Assert;
    begin
        // Verify number of replaced Service Item Components.
        ServiceItemComponent2.SetRange(Active, false);
        ServiceItemComponent2.SetRange("Parent Service Item No.", ServiceItemComponent."Parent Service Item No.");
        ServiceItemComponent2.SetRange("From Line No.", ServiceItemComponent."Line No.");
        Assert.AreEqual(
          NumberofLinesReplaced,
          ServiceItemComponent2.Count,
          StrSubstNo(
            ServiceItemReplacedErr, ServiceItemComponent.TableCaption(),
            NumberofLinesReplaced, ServiceItemComponent.FieldCaption("Parent Service Item No."),
            ServiceItemComponent."Parent Service Item No.", ServiceItemComponent.FieldCaption("Line No."),
            ServiceItemComponent."Line No."));
    end;

    local procedure VerifyServLineWithServShptLine(ServiceLine: Record "Service Line")
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        // Verify that the values in the Service Line flow correctly as the values in the Service Shipment Line after Posting.
        ServiceShipmentLine.SetRange("Order No.", ServiceLine."Document No.");
        ServiceShipmentLine.SetRange("Order Line No.", ServiceLine."Line No.");
        ServiceShipmentLine.FindFirst();
        ServiceShipmentLine.TestField(Type, ServiceLine.Type);
        ServiceShipmentLine.TestField("No.", ServiceLine."No.");
        ServiceShipmentLine.TestField(Quantity, ServiceLine.Quantity);
    end;

    local procedure VerifyServiceDocumentLogEntry(OrderNo: Code[20]; DocumentType: Enum "Service Log Document Type"; EventNo: Integer)
    var
        ServiceDocumentLog: Record "Service Document Log";
    begin
        // Verify Service Document Log entry contains the Event No. that corresponds to the event that occured due to a certain action.
        ServiceDocumentLog.SetRange("Document Type", DocumentType);
        ServiceDocumentLog.SetRange("Document No.", OrderNo);
        ServiceDocumentLog.FindFirst();
        ServiceDocumentLog.TestField("Event No.", EventNo);
    end;

    local procedure VerifyServiceItemLogEntry(ServiceItemNo: Code[20]; EventNo: Integer)
    var
        ServiceItemLog: Record "Service Item Log";
    begin
        // Verify Service Item Log entry contains the Event No. that corresponds to the event that occured due to a certain action.
        ServiceItemLog.SetRange("Service Item No.", ServiceItemNo);
        ServiceItemLog.FindLast();
        ServiceItemLog.TestField("Event No.", EventNo);
    end;

    local procedure VerifyTroubleshootingAssignment(ServiceItem: Record "Service Item"; TroubleshootingLineNo: Code[20])
    var
        ServiceItemCard: TestPage "Service Item Card";
        Troubleshooting: TestPage Troubleshooting;
    begin
        ServiceItemCard.OpenEdit();
        Troubleshooting.Trap();
        ServiceItemCard.GotoRecord(ServiceItem);
        ServiceItemCard."<Page Troubleshooting>".Invoke();
        Troubleshooting.FILTER.SetFilter("No.", TroubleshootingLineNo);
        Assert.AreEqual(TroubleshootingLineNo, Troubleshooting."No.".Value, 'Troubleshooting');
    end;

    local procedure VerifyValueEntry(DocumentType: Enum "Item Ledger Document Type"; DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange("Document Type", DocumentType);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Item No.", ItemNo);
        ValueEntry.TestField("Valued Quantity", -Quantity);
        ValueEntry.TestField("Invoiced Quantity", -Quantity);
    end;

    local procedure VerifyServiceItemCreation(No: Code[20])
    var
        ServiceItem: Record "Service Item";
        ServiceItemCard: TestPage "Service Item Card";
    begin
        ServiceItemCard.OpenView();
        ServiceItemCard.FILTER.SetFilter("No.", No);
        ServiceItem.Get(No);
        ServiceItemCard."Item No.".AssertEquals(ServiceItem."Item No.");
    end;

    local procedure VerifyServiceItemValues(No: Code[20])
    var
        ServiceItem: Record "Service Item";
        ServiceItemCard: TestPage "Service Item Card";
    begin
        ServiceItemCard.OpenView();
        ServiceItemCard.FILTER.SetFilter("No.", No);
        ServiceItem.Get(No);
        ServiceItemCard."Item No.".AssertEquals(ServiceItem."Item No.");
        ServiceItemCard.Priority.AssertEquals(ServiceItem.Priority);
        ServiceItemCard."Sales Unit Price".AssertEquals(ServiceItem."Sales Unit Price");
        ServiceItemCard."Service Item Group Code".AssertEquals(ServiceItem."Service Item Group Code");
    end;

    local procedure VerifyPostingDateOnItemLedgerEntry(ItemNo: Code[20]; PostingDate: Date)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Posting Date", PostingDate);
    end;

    local procedure VerifyCustomerNoAndStatusOnServiceItem(ItemNo: Code[20]; ExpectedCustomerNo: Code[20]; ExpectedStatus: Enum "Service Item Status")
    var
        ServiceItem: Record "Service Item";
    begin
        FindServiceItemByItemNo(ServiceItem, ItemNo);
        Assert.AreEqual(ExpectedCustomerNo, ServiceItem."Customer No.", ServiceItem.FieldCaption("Customer No."));
        Assert.AreEqual(ExpectedStatus, ServiceItem.Status, ServiceItem.FieldCaption(Status));
    end;

    local procedure VerifySalesAmountOnItemLedgerEntry(ItemJournalLine: Record "Item Journal Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Posting Date", ItemJournalLine."Posting Date");
        ItemLedgerEntry.SetRange("Item No.", ItemJournalLine."Item No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Sales Amount (Actual)");
        ItemLedgerEntry.TestField("Sales Amount (Actual)", ItemJournalLine.Amount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Confirm as TRUE.
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        // Confirm as FALSE.
        Reply := false;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        // Choose the first option of the string menu.
        Choice := 1;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandlerForNew(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        // Choose the second option of the string menu.
        Choice := 2;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(MessageHandler: Text[1024])
    begin
        // Handle message that are generated.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerLookupOK(var ServiceItemComponentList: Page "Service Item Component List"; var Response: Action)
    var
        ServiceItemComponent: Record "Service Item Component";
    begin
        // Modal form handler. Return Action as LookupOK for first record found.
        ServiceItemComponent.SetRange("Parent Service Item No.", ServiceItemNoForComponent);
        ServiceItemComponent.FindFirst();
        ServiceItemComponentList.SetRecord(ServiceItemComponent);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormItemReplacement(var ServiceItemReplacement: Page "Service Item Replacement"; var Response: Action)
    begin
        ServiceItemReplacement.SetParameters('', SerialNo, CopyComponentsFrom, Replacement);
        Response := ACTION::OK;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure InvoiceESConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := (Question = ExpectedConfirmQst);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingForAssignAndSelectPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        AssignValueForTracking: Variant;
        AssignedValue: Option "None",AssignSerialNo,AssignLotNo,SelectEntries,AssistEdit;
    begin
        LibraryVariableStorage.Dequeue(AssignValueForTracking);
        AssignedValue := AssignValueForTracking;
        case AssignedValue of
            AssignedValue::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            AssignedValue::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            AssignedValue::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            AssignedValue::AssistEdit:
                ItemTrackingLines."Lot No.".AssistEdit();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesPageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesWithShipmentPageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    var
        DocumentType: Option "Posted Shipments","Posted Invoices","Posted Return Receipts","Posted Cr. Memos";
    begin
        PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(DocumentType::"Posted Shipments"));
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinesWithReceiptPageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    var
        DocumentType: Option "Posted Receipts","Posted Invoices","Posted Return Shipments","Posted Cr. Memos";
    begin
        PostedPurchaseDocumentLines.PostedReceiptsBtn.SetValue(DocumentType::"Posted Receipts");
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [PageHandler]
    procedure CommentSheetPageHandler(var ServiceCommentSheet: TestPage "Service Comment Sheet")
    begin
        ServiceCommentSheet.Comment.SetValue(LibraryVariableStorage.DequeueText());
        ServiceCommentSheet.OK().Invoke();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::MoveEntries, 'OnBeforeMoveVendEntries', '', false, false)]
    local procedure OnBeforeMoveVendEntries(Vendor: Record Vendor; var NewVendNo: Code[20])
    begin
        NewVendNo := GlobalVendorNo;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::MoveEntries, 'OnBeforeMoveCustEntries', '', false, false)]
    local procedure OnBeforeMoveCustEntries(Customer: Record Customer; var NewCustNo: Code[20])
    begin
        NewCustNo := GlobalCustomerNo;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::MoveEntries, 'OnBeforeMoveItemEntries', '', false, false)]
    local procedure OnBeforeMoveItemEntries(Item: Record Item; var NewItemNo: Code[20])
    begin
        NewItemNo := GlobalItemNo;
    end;
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Assembly.Document;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Test.QualityManagement.TestLibraries;
using System.TestLibraries.Utilities;

codeunit 139968 "Qlty. Tests - Traversal"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        QltyTraversal: Codeunit "Qlty. Traversal";
        QltyTraversalMfg: Codeunit "Qlty. Traversal - Mfg.";
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure FindRelatedItem_Variant2()
    var
        Item: Record Item;
        FoundItem: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        EmptyRecordRef: RecordRef;
        RecordRef: RecordRef;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related item using variant parameter 2 in the traversal function

        // [GIVEN] An item is created
        LibraryInventory.CreateItem(Item);
        RecordRef.GetTable(Item);

        // [WHEN] Finding related item with item record in variant 2 position
        // [THEN] The traversal function successfully finds the item and returns the matching item number
        LibraryAssert.IsTrue(QltyTraversal.FindRelatedItem(FoundItem, EmptyRecordRef, RecordRef, EmptyVariant2, EmptyVariant3, EmptyVariant4), 'Should find item.');
        LibraryAssert.AreEqual(Item."No.", FoundItem."No.", 'Should be same item.');
    end;

    [Test]
    procedure FindRelatedItem_Variant3()
    var
        Item: Record Item;
        FoundItem: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        EmptyRecordRef: RecordRef;
        RecordRef: RecordRef;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related item using variant parameter 3 in the traversal function

        // [GIVEN] An item is created
        LibraryInventory.CreateItem(Item);
        RecordRef.GetTable(Item);

        // [WHEN] Finding related item with item record in variant 3 position
        // [THEN] The traversal function successfully finds the item and returns the matching item number
        LibraryAssert.IsTrue(QltyTraversal.FindRelatedItem(FoundItem, EmptyRecordRef, EmptyVariant2, RecordRef, EmptyVariant3, EmptyVariant4), 'Should find item.');
        LibraryAssert.AreEqual(Item."No.", FoundItem."No.", 'Should be same item.');
    end;

    [Test]
    procedure FindRelatedItem_Variant4()
    var
        Item: Record Item;
        FoundItem: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        EmptyRecordRef: RecordRef;
        RecordRef: RecordRef;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related item using variant parameter 4 in the traversal function

        // [GIVEN] An item is created
        LibraryInventory.CreateItem(Item);
        RecordRef.GetTable(Item);

        // [WHEN] Finding related item with item record in variant 4 position
        // [THEN] The traversal function successfully finds the item and returns the matching item number
        LibraryAssert.IsTrue(QltyTraversal.FindRelatedItem(FoundItem, EmptyRecordRef, EmptyVariant2, EmptyVariant3, RecordRef, EmptyVariant4), 'Should find item.');
        LibraryAssert.AreEqual(Item."No.", FoundItem."No.", 'Should be same item.');
    end;

    [Test]
    procedure FindRelatedItem_Variant5()
    var
        Item: Record Item;
        FoundItem: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        EmptyRecordRef: RecordRef;
        RecordRef: RecordRef;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related item using variant parameter 5 in the traversal function

        // [GIVEN] An item is created
        LibraryInventory.CreateItem(Item);
        RecordRef.GetTable(Item);

        // [WHEN] Finding related item with item record in variant 5 position
        // [THEN] The traversal function successfully finds the item and returns the matching item number
        LibraryAssert.IsTrue(QltyTraversal.FindRelatedItem(FoundItem, EmptyRecordRef, EmptyVariant2, EmptyVariant3, EmptyVariant4, RecordRef), 'Should find item.');
        LibraryAssert.AreEqual(Item."No.", FoundItem."No.", 'Should be same item.');
    end;

    [Test]
    procedure FindRelatedVendor_Variant2()
    var
        Vendor: Record Vendor;
        FoundVendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
        RecordRef: RecordRef;
        EmptyVariant1: Variant;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related vendor using variant parameter 2 in the traversal function

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);
        RecordRef.GetTable(Vendor);

        // [WHEN] Finding related vendor with vendor record in variant 2 position
        // [THEN] The traversal function successfully finds the vendor and returns the matching vendor number
        LibraryAssert.IsTrue(QltyTraversal.FindRelatedVendor(FoundVendor, EmptyVariant1, RecordRef, EmptyVariant2, EmptyVariant3, EmptyVariant4), 'Should find vendor.');
        LibraryAssert.AreEqual(Vendor."No.", FoundVendor."No.", 'Should be same vendor.');
    end;

    [Test]
    procedure FindRelatedVendor_Variant3()
    var
        Vendor: Record Vendor;
        FoundVendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
        RecordRef: RecordRef;
        EmptyVariant1: Variant;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related vendor using variant parameter 3 in the traversal function

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);
        RecordRef.GetTable(Vendor);

        // [WHEN] Finding related vendor with vendor record in variant 3 position
        // [THEN] The traversal function successfully finds the vendor and returns the matching vendor number
        LibraryAssert.IsTrue(QltyTraversal.FindRelatedVendor(FoundVendor, EmptyVariant1, EmptyVariant2, RecordRef, EmptyVariant3, EmptyVariant4), 'Should find vendor.');
        LibraryAssert.AreEqual(Vendor."No.", FoundVendor."No.", 'Should be same vendor.');
    end;

    [Test]
    procedure FindRelatedVendor_Variant4()
    var
        Vendor: Record Vendor;
        FoundVendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
        RecordRef: RecordRef;
        EmptyVariant1: Variant;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related vendor using variant parameter 4 in the traversal function

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);
        RecordRef.GetTable(Vendor);

        // [WHEN] Finding related vendor with vendor record in variant 4 position
        // [THEN] The traversal function successfully finds the vendor and returns the matching vendor number
        LibraryAssert.IsTrue(QltyTraversal.FindRelatedVendor(FoundVendor, EmptyVariant1, EmptyVariant2, EmptyVariant3, RecordRef, EmptyVariant4), 'Should find vendor.');
        LibraryAssert.AreEqual(Vendor."No.", FoundVendor."No.", 'Should be same vendor.');
    end;

    [Test]
    procedure FindRelatedVendor_Variant5()
    var
        Vendor: Record Vendor;
        FoundVendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
        RecordRef: RecordRef;
        EmptyVariant1: Variant;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related vendor using variant parameter 5 in the traversal function

        // [GIVEN] A vendor is created
        LibraryPurchase.CreateVendor(Vendor);
        RecordRef.GetTable(Vendor);

        // [WHEN] Finding related vendor with vendor record in variant 5 position
        // [THEN] The traversal function successfully finds the vendor and returns the matching vendor number
        LibraryAssert.IsTrue(QltyTraversal.FindRelatedVendor(FoundVendor, EmptyVariant1, EmptyVariant2, EmptyVariant3, EmptyVariant4, RecordRef), 'Should find vendor.');
        LibraryAssert.AreEqual(Vendor."No.", FoundVendor."No.", 'Should be same vendor.');
    end;

    [Test]
    procedure FindRelatedCustomer_Variant2()
    var
        Customer: Record Customer;
        FoundCustomer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        RecordRef: RecordRef;
        EmptyVariant1: Variant;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related customer using variant parameter 2 in the traversal function

        // [GIVEN] A customer is created
        LibrarySales.CreateCustomer(Customer);
        RecordRef.GetTable(Customer);

        // [WHEN] Finding related customer with customer record in variant 2 position
        // [THEN] The traversal function successfully finds the customer and returns the matching customer number
        LibraryAssert.IsTrue(QltyTraversal.FindRelatedCustomer(FoundCustomer, EmptyVariant1, RecordRef, EmptyVariant2, EmptyVariant3, EmptyVariant4), 'Should find customer.');
        LibraryAssert.AreEqual(Customer."No.", FoundCustomer."No.", 'Should be same customer.');
    end;

    [Test]
    procedure FindRelatedCustomer_Variant3()
    var
        Customer: Record Customer;
        FoundCustomer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        RecordRef: RecordRef;
        EmptyVariant1: Variant;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related customer using variant parameter 3 in the traversal function

        // [GIVEN] A customer is created
        LibrarySales.CreateCustomer(Customer);
        RecordRef.GetTable(Customer);

        // [WHEN] Finding related customer with customer record in variant 3 position
        // [THEN] The traversal function successfully finds the customer and returns the matching customer number
        LibraryAssert.IsTrue(QltyTraversal.FindRelatedCustomer(FoundCustomer, EmptyVariant1, EmptyVariant2, RecordRef, EmptyVariant3, EmptyVariant4), 'Should find customer.');
        LibraryAssert.AreEqual(Customer."No.", FoundCustomer."No.", 'Should be same customer.');
    end;

    [Test]
    procedure FindRelatedCustomer_Variant4()
    var
        Customer: Record Customer;
        FoundCustomer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        RecordRef: RecordRef;
        EmptyVariant1: Variant;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related customer using variant parameter 4 in the traversal function

        // [GIVEN] A customer is created
        LibrarySales.CreateCustomer(Customer);
        RecordRef.GetTable(Customer);

        // [WHEN] Finding related customer with customer record in variant 4 position
        // [THEN] The traversal function successfully finds the customer and returns the matching customer number
        LibraryAssert.IsTrue(QltyTraversal.FindRelatedCustomer(FoundCustomer, EmptyVariant1, EmptyVariant2, EmptyVariant3, RecordRef, EmptyVariant4), 'Should find customer.');
        LibraryAssert.AreEqual(Customer."No.", FoundCustomer."No.", 'Should be same customer.');
    end;

    [Test]
    procedure FindRelatedCustomer_Variant5()
    var
        Customer: Record Customer;
        FoundCustomer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        RecordRef: RecordRef;
        EmptyVariant1: Variant;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related customer using variant parameter 5 in the traversal function

        // [GIVEN] A customer is created
        LibrarySales.CreateCustomer(Customer);
        RecordRef.GetTable(Customer);

        // [WHEN] Finding related customer with customer record in variant 5 position
        // [THEN] The traversal function successfully finds the customer and returns the matching customer number
        LibraryAssert.IsTrue(QltyTraversal.FindRelatedCustomer(FoundCustomer, EmptyVariant1, EmptyVariant2, EmptyVariant3, EmptyVariant4, RecordRef), 'Should find customer.');
        LibraryAssert.AreEqual(Customer."No.", FoundCustomer."No.", 'Should be same customer.');
    end;

    [Test]
    procedure FindRelatedRouting_Variant2()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLink: Record "Routing Link";
        WorkCenter: Record "Work Center";
        Item: Record Item;
        FoundRoutingHeader: Record "Routing Header";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        RecordRef: RecordRef;
        EmptyVariant1: Variant;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related routing using variant parameter 2 in the traversal function

        // [GIVEN] An item, work center, routing link, and routing are created
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        LibraryManufacturing.CreateRouting(RoutingHeader, Item, RoutingLink.Code, 1.00);
        RecordRef.GetTable(RoutingHeader);

        // [WHEN] Finding related routing with routing record in variant 2 position
        // [THEN] The traversal function successfully finds the routing and returns the matching routing number
        LibraryAssert.IsTrue(QltyTraversalMfg.FindRelatedRouting(FoundRoutingHeader, EmptyVariant1, RecordRef, EmptyVariant2, EmptyVariant3, EmptyVariant4), 'Should find routing.');
        LibraryAssert.AreEqual(RoutingHeader."No.", FoundRoutingHeader."No.", 'Should be same routing.');
    end;

    [Test]
    procedure FindRelatedRouting_Variant3()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLink: Record "Routing Link";
        WorkCenter: Record "Work Center";
        Item: Record Item;
        FoundRoutingHeader: Record "Routing Header";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        RecordRef: RecordRef;
        EmptyVariant1: Variant;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related routing using variant parameter 3 in the traversal function

        // [GIVEN] An item, work center, routing link, and routing are created
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        LibraryManufacturing.CreateRouting(RoutingHeader, Item, RoutingLink.Code, 1.00);
        RecordRef.GetTable(RoutingHeader);

        // [WHEN] Finding related routing with routing record in variant 3 position
        // [THEN] The traversal function successfully finds the routing and returns the matching routing number
        LibraryAssert.IsTrue(QltyTraversalMfg.FindRelatedRouting(FoundRoutingHeader, EmptyVariant1, EmptyVariant2, RecordRef, EmptyVariant3, EmptyVariant4), 'Should find routing.');
        LibraryAssert.AreEqual(RoutingHeader."No.", FoundRoutingHeader."No.", 'Should be same routing.');
    end;

    [Test]
    procedure FindRelatedRouting_Variant4()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLink: Record "Routing Link";
        WorkCenter: Record "Work Center";
        Item: Record Item;
        FoundRoutingHeader: Record "Routing Header";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        RecordRef: RecordRef;
        EmptyVariant1: Variant;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related routing using variant parameter 4 in the traversal function

        // [GIVEN] An item, work center, routing link, and routing are created
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        LibraryManufacturing.CreateRouting(RoutingHeader, Item, RoutingLink.Code, 1.00);
        RecordRef.GetTable(RoutingHeader);

        // [WHEN] Finding related routing with routing record in variant 4 position
        // [THEN] The traversal function successfully finds the routing and returns the matching routing number
        LibraryAssert.IsTrue(QltyTraversalMfg.FindRelatedRouting(FoundRoutingHeader, EmptyVariant1, EmptyVariant2, EmptyVariant3, RecordRef, EmptyVariant4), 'Should find routing.');
        LibraryAssert.AreEqual(RoutingHeader."No.", FoundRoutingHeader."No.", 'Should be same routing.');
    end;

    [Test]
    procedure FindRelatedRouting_Variant5()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLink: Record "Routing Link";
        WorkCenter: Record "Work Center";
        Item: Record Item;
        FoundRoutingHeader: Record "Routing Header";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        RecordRef: RecordRef;
        EmptyVariant1: Variant;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related routing using variant parameter 5 in the traversal function

        // [GIVEN] An item, work center, routing link, and routing are created
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        LibraryManufacturing.CreateRouting(RoutingHeader, Item, RoutingLink.Code, 1.00);
        RecordRef.GetTable(RoutingHeader);

        // [WHEN] Finding related routing with routing record in variant 5 position
        // [THEN] The traversal function successfully finds the routing and returns the matching routing number
        LibraryAssert.IsTrue(QltyTraversalMfg.FindRelatedRouting(FoundRoutingHeader, EmptyVariant1, EmptyVariant2, EmptyVariant3, EmptyVariant4, RecordRef), 'Should find routing.');
        LibraryAssert.AreEqual(RoutingHeader."No.", FoundRoutingHeader."No.", 'Should be same routing.');
    end;

    [Test]
    procedure FindRelatedBOM_Variant2()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        FundProductionBOMHeader: Record "Production BOM Header";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        RecordRef: RecordRef;
        EmptyVariant1: Variant;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related BOM using variant parameter 2 in the traversal function

        // [GIVEN] An item and production BOM header are created
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        RecordRef.GetTable(ProductionBOMHeader);

        // [WHEN] Finding related BOM with BOM record in variant 2 position
        // [THEN] The traversal function successfully finds the BOM and returns the matching BOM number
        LibraryAssert.IsTrue(QltyTraversalMfg.FindRelatedBillOfMaterial(FundProductionBOMHeader, EmptyVariant1, RecordRef, EmptyVariant2, EmptyVariant3, EmptyVariant4), 'Should find BOM.');
        LibraryAssert.AreEqual(ProductionBOMHeader."No.", FundProductionBOMHeader."No.", 'Should be same BOM.');
    end;

    [Test]
    procedure FindRelatedBOM_Variant3()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        FundProductionBOMHeader: Record "Production BOM Header";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        RecordRef: RecordRef;
        EmptyVariant1: Variant;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related BOM using variant parameter 3 in the traversal function

        // [GIVEN] An item and production BOM header are created
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        RecordRef.GetTable(ProductionBOMHeader);

        // [WHEN] Finding related BOM with BOM record in variant 3 position
        // [THEN] The traversal function successfully finds the BOM and returns the matching BOM number
        LibraryAssert.IsTrue(QltyTraversalMfg.FindRelatedBillOfMaterial(FundProductionBOMHeader, EmptyVariant1, EmptyVariant2, RecordRef, EmptyVariant3, EmptyVariant4), 'Should find BOM.');
        LibraryAssert.AreEqual(ProductionBOMHeader."No.", FundProductionBOMHeader."No.", 'Should be same BOM.');
    end;

    [Test]
    procedure FindRelatedBOM_Variant4()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        FundProductionBOMHeader: Record "Production BOM Header";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        RecordRef: RecordRef;
        EmptyVariant1: Variant;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related BOM using variant parameter 4 in the traversal function

        // [GIVEN] An item and production BOM header are created
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        RecordRef.GetTable(ProductionBOMHeader);

        // [WHEN] Finding related BOM with BOM record in variant 4 position
        // [THEN] The traversal function successfully finds the BOM and returns the matching BOM number
        LibraryAssert.IsTrue(QltyTraversalMfg.FindRelatedBillOfMaterial(FundProductionBOMHeader, EmptyVariant1, EmptyVariant2, EmptyVariant3, RecordRef, EmptyVariant4), 'Should find BOM.');
        LibraryAssert.AreEqual(ProductionBOMHeader."No.", FundProductionBOMHeader."No.", 'Should be same BOM.');
    end;

    [Test]
    procedure FindRelatedBOM_Variant5()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        FundProductionBOMHeader: Record "Production BOM Header";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        RecordRef: RecordRef;
        EmptyVariant1: Variant;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
    begin
        // [SCENARIO] Find a related BOM using variant parameter 5 in the traversal function

        // [GIVEN] An item and production BOM header are created
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        RecordRef.GetTable(ProductionBOMHeader);

        // [WHEN] Finding related BOM with BOM record in variant 5 position
        // [THEN] The traversal function successfully finds the BOM and returns the matching BOM number
        LibraryAssert.IsTrue(QltyTraversalMfg.FindRelatedBillOfMaterial(FundProductionBOMHeader, EmptyVariant1, EmptyVariant2, EmptyVariant3, EmptyVariant4, RecordRef), 'Should find BOM.');
        LibraryAssert.AreEqual(ProductionBOMHeader."No.", FundProductionBOMHeader."No.", 'Should be same BOM.');
    end;

    [Test]
    procedure FindRelatedBOM_OnSourceConfig()
    var
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        ProductionBOMHeader: Record "Production BOM Header";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        FundProductionBOMHeader: Record "Production BOM Header";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        RecordRef: RecordRef;
        EmptyVariant1: Variant;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
        ConfigCode: Text;
    begin
        // [SCENARIO] Find a related BOM from an item using source configuration mapping

        // [GIVEN] A source configuration mapping from Item to Test with BOM field mapping
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(SpecificQltyInspectSourceConfig.Code), ConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Description := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Description));
        SpecificQltyInspectSourceConfig.Validate("From Table No.", Database::Item);
        SpecificQltyInspectSourceConfig."To Type" := SpecificQltyInspectSourceConfig."To Type"::Test;
        SpecificQltyInspectSourceConfig.Validate("To Table No.", Database::"Qlty. Inspection Test Header");
        SpecificQltyInspectSourceConfig.Insert();

        // [GIVEN] A field configuration mapping from Item's Production BOM No. to test header
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := Item.FieldNo("Production BOM No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Custom 1");
        SpecificQltyInspectSrcFldConf.Insert();

        // [WHEN] An item with a production BOM assigned
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        RecordRef.GetTable(Item);

        // [THEN] Finding related BOM from the item record using source configuration
        // [THEN] The traversal function successfully finds the BOM and returns the matching BOM number
        LibraryAssert.IsTrue(QltyTraversalMfg.FindRelatedBillOfMaterial(FundProductionBOMHeader, RecordRef, EmptyVariant1, EmptyVariant2, EmptyVariant3, EmptyVariant4), 'Should find BOM.');
        LibraryAssert.AreEqual(ProductionBOMHeader."No.", FundProductionBOMHeader."No.", 'Should be same BOM.');
    end;

    [Test]
    procedure FindRelatedRoutingLine_Variant2()
    var
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Item: Record Item;
        FoundProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        RecordRef: RecordRef;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
        EmptyVariant5: Variant;
    begin
        // [SCENARIO] Find a related production order routing line using variant parameter 2

        // [GIVEN] An item and production order with routing line are created
        QltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        RecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] Finding related routing line with routing line record in variant 2 position
        // [THEN] The traversal function successfully finds the routing line with matching key fields
        LibraryAssert.IsTrue(QltyTraversalMfg.FindRelatedProdOrderRoutingLine(FoundProdOrderRoutingLine, EmptyVariant2, RecordRef, EmptyVariant3, EmptyVariant4, EmptyVariant5), 'Should find routing line.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine.Status, FoundProdOrderRoutingLine.Status, 'Should be same status');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."No.", FoundProdOrderRoutingLine."No.", 'Should be same No.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."Prod. Order No.", FoundProdOrderRoutingLine."Prod. Order No.", 'Should be same Prod. Order No.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."Routing No.", FoundProdOrderRoutingLine."Routing No.", 'Should be same Routing No.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."Operation No.", FoundProdOrderRoutingLine."Operation No.", 'Should be same Operation No.');
    end;

    [Test]
    procedure FindRelatedRoutingLine_Variant3()
    var
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Item: Record Item;
        FoundProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        RecordRef: RecordRef;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
        EmptyVariant5: Variant;
    begin
        // [SCENARIO] Find a related production order routing line using variant parameter 3

        // [GIVEN] An item and production order with routing line are created
        QltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        RecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] Finding related routing line with routing line record in variant 3 position
        // [THEN] The traversal function successfully finds the routing line with matching key fields
        LibraryAssert.IsTrue(QltyTraversalMfg.FindRelatedProdOrderRoutingLine(FoundProdOrderRoutingLine, EmptyVariant2, EmptyVariant3, RecordRef, EmptyVariant4, EmptyVariant5), 'Should find routing line.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine.Status, FoundProdOrderRoutingLine.Status, 'Should be same status');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."No.", FoundProdOrderRoutingLine."No.", 'Should be same No.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."Prod. Order No.", FoundProdOrderRoutingLine."Prod. Order No.", 'Should be same Prod. Order No.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."Routing No.", FoundProdOrderRoutingLine."Routing No.", 'Should be same Routing No.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."Operation No.", FoundProdOrderRoutingLine."Operation No.", 'Should be same Operation No.');
    end;

    [Test]
    procedure FindRelatedRoutingLine_Variant4()
    var
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Item: Record Item;
        FoundProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        RecordRef: RecordRef;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
        EmptyVariant5: Variant;
    begin
        // [SCENARIO] Find a related production order routing line using variant parameter 4

        // [GIVEN] An item and production order with routing line are created
        QltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        RecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] Finding related routing line with routing line record in variant 4 position
        // [THEN] The traversal function successfully finds the routing line with matching key fields
        LibraryAssert.IsTrue(QltyTraversalMfg.FindRelatedProdOrderRoutingLine(FoundProdOrderRoutingLine, EmptyVariant2, EmptyVariant3, EmptyVariant4, RecordRef, EmptyVariant5), 'Should find routing line.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine.Status, FoundProdOrderRoutingLine.Status, 'Should be same status');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."No.", FoundProdOrderRoutingLine."No.", 'Should be same No.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."Prod. Order No.", FoundProdOrderRoutingLine."Prod. Order No.", 'Should be same Prod. Order No.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."Routing No.", FoundProdOrderRoutingLine."Routing No.", 'Should be same Routing No.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."Operation No.", FoundProdOrderRoutingLine."Operation No.", 'Should be same Operation No.');
    end;

    [Test]
    procedure FindRelatedRoutingLine_Variant5()
    var
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Item: Record Item;
        FoundProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        RecordRef: RecordRef;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
        EmptyVariant5: Variant;
    begin
        // [SCENARIO] Find a related production order routing line using variant parameter 5

        // [GIVEN] An item and production order with routing line are created
        QltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        RecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] Finding related routing line with routing line record in variant 5 position
        // [THEN] The traversal function successfully finds the routing line with matching key fields
        LibraryAssert.IsTrue(QltyTraversalMfg.FindRelatedProdOrderRoutingLine(FoundProdOrderRoutingLine, EmptyVariant2, EmptyVariant3, EmptyVariant4, EmptyVariant5, RecordRef), 'Should find routing line.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine.Status, FoundProdOrderRoutingLine.Status, 'Should be same status');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."No.", FoundProdOrderRoutingLine."No.", 'Should be same No.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."Prod. Order No.", FoundProdOrderRoutingLine."Prod. Order No.", 'Should be same Prod. Order No.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."Routing No.", FoundProdOrderRoutingLine."Routing No.", 'Should be same Routing No.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."Operation No.", FoundProdOrderRoutingLine."Operation No.", 'Should be same Operation No.');
    end;

    [Test]
    procedure FindRelatedItem_ParentRecord()
    var
        Location: Record Location;
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        AssemblyLine: Record "Assembly Line";
        AssemblyHeader: Record "Assembly Header";
        FoundItem: Record Item;
        TempComponentItem: Record Item temporary;
        TempUnusedResource: Record Resource temporary;
        InventoryPostingGroup: Record "Inventory Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        RecordRef: RecordRef;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
        EmptyVariant5: Variant;
        DueDate: Date;
        GenProdPostingGroup: Code[20];
        ConfigCode: Text;
    begin
        // [SCENARIO] Find a related item from assembly line by traversing to parent assembly header

        // [GIVEN] A source configuration for chained table mapping from Assembly Header to Assembly Line
        if not SpecificQltyInspectSourceConfig.IsEmpty() then
            SpecificQltyInspectSourceConfig.DeleteAll();
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(SpecificQltyInspectSourceConfig.Code), ConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Description := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Description));
        SpecificQltyInspectSourceConfig.Validate("From Table No.", Database::"Assembly Header");
        SpecificQltyInspectSourceConfig."To Type" := SpecificQltyInspectSourceConfig."To Type"::"Chained table";
        SpecificQltyInspectSourceConfig.Validate("To Table No.", Database::"Assembly Line");
        SpecificQltyInspectSourceConfig.Insert();

        // [GIVEN] Field configuration mapping assembly document number between header and line
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := AssemblyHeader.FieldNo("No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::"Chained table";
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Assembly Line";
        SpecificQltyInspectSrcFldConf."To Field No." := AssemblyLine.FieldNo("Document No.");
        SpecificQltyInspectSrcFldConf.Insert();

        // [GIVEN] Field configuration mapping assembly header item number to test header
        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := AssemblyHeader.FieldNo("Item No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Item No.");
        SpecificQltyInspectSrcFldConf.Insert();

        // [GIVEN] A second source configuration from Assembly Line to Test
        Clear(SpecificQltyInspectSourceConfig);
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(SpecificQltyInspectSourceConfig.Code), ConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Description := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Description));
        SpecificQltyInspectSourceConfig.Validate("From Table No.", Database::"Assembly Line");
        SpecificQltyInspectSourceConfig."To Type" := SpecificQltyInspectSourceConfig."To Type"::Test;
        SpecificQltyInspectSourceConfig.Validate("To Table No.", Database::"Qlty. Inspection Test Header");
        SpecificQltyInspectSourceConfig.Insert();

        // [GIVEN] Field configurations for assembly line to test header fields
        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := AssemblyLine.FieldNo("Document No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Document No.");
        SpecificQltyInspectSrcFldConf.Insert();
        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := AssemblyLine.FieldNo("Line No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Document Line No.");
        SpecificQltyInspectSrcFldConf.Insert();

        // [GIVEN] An assembly order with component line is created
        LibraryWarehouse.CreateLocation(Location);
        DueDate := CalcDate('<+10D>', WorkDate());
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, DueDate, Location.Code, 1);
        if not InventoryPostingGroup.FindFirst() then
            LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        LibraryERM.FindGeneralPostingSetupInvtToGL(GeneralPostingSetup);
        GenProdPostingGroup := GeneralPostingSetup."Gen. Prod. Posting Group";
        LibraryAssembly.SetupComponents(TempComponentItem, TempUnusedResource, Enum::"Costing Method"::Standard, 1, 0, GenProdPostingGroup, InventoryPostingGroup.Code);
        LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, Enum::"BOM Component Type"::Item, TempComponentItem."No.", TempComponentItem."Base Unit of Measure", 1, 1, '');
        RecordRef.GetTable(AssemblyLine);

        // [WHEN] Finding related item from assembly line by traversing to parent header
        // [THEN] The traversal function finds the item from the assembly header
        LibraryAssert.IsTrue(QltyTraversal.FindRelatedItem(FoundItem, RecordRef, EmptyVariant2, EmptyVariant3, EmptyVariant4, EmptyVariant5), 'Should find item.');
        LibraryAssert.AreEqual(AssemblyHeader."Item No.", FoundItem."No.", 'Should be same item.');
    end;

    [Test]
    procedure FindRelatedVendor_ParentRecord()
    var
        Location: Record Location;
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DummyReservationEntry: Record "Reservation Entry";
        Item: Record Item;
        Vendor: Record Vendor;
        FoundVendor: Record Vendor;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        RecordRef: RecordRef;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
        EmptyVariant5: Variant;
        ConfigCode: Text;
    begin
        // [SCENARIO] Find a related vendor from purchase line by traversing to parent purchase header

        // [GIVEN] Quality management setup is ensured
        if not SpecificQltyInspectSourceConfig.IsEmpty() then
            SpecificQltyInspectSourceConfig.DeleteAll();

        // [GIVEN] A source configuration for chained table mapping from Purchase Header to Purchase Line
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(SpecificQltyInspectSourceConfig.Code), ConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Description := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Description));
        SpecificQltyInspectSourceConfig.Validate("From Table No.", Database::"Purchase Header");
        SpecificQltyInspectSourceConfig."To Type" := SpecificQltyInspectSourceConfig."To Type"::"Chained table";
        SpecificQltyInspectSourceConfig.Validate("To Table No.", Database::"Purchase Line");
        SpecificQltyInspectSourceConfig.Insert();

        // [GIVEN] Field configurations mapping purchase document fields between header and line
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := PurchaseHeader.FieldNo("No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::"Chained table";
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Purchase Line";
        SpecificQltyInspectSrcFldConf."To Field No." := PurchaseLine.FieldNo("Document No.");
        SpecificQltyInspectSrcFldConf.Insert();
        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := PurchaseHeader.FieldNo("Document Type");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::"Chained table";
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Purchase Line";
        SpecificQltyInspectSrcFldConf."To Field No." := PurchaseLine.FieldNo("Document Type");
        SpecificQltyInspectSrcFldConf.Insert();
        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := PurchaseHeader.FieldNo("Buy-from Vendor No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Custom 1");
        SpecificQltyInspectSrcFldConf.Insert();

        // [GIVEN] A second source configuration from Purchase Line to Test with field mappings
        Clear(SpecificQltyInspectSourceConfig);
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(SpecificQltyInspectSourceConfig.Code), ConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Description := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Description));
        SpecificQltyInspectSourceConfig.Validate("From Table No.", Database::"Purchase Line");
        SpecificQltyInspectSourceConfig."To Type" := SpecificQltyInspectSourceConfig."To Type"::Test;
        SpecificQltyInspectSourceConfig.Validate("To Table No.", Database::"Qlty. Inspection Test Header");
        SpecificQltyInspectSourceConfig.Insert();
        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := PurchaseLine.FieldNo("Document No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Document No.");
        SpecificQltyInspectSrcFldConf.Insert();
        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := PurchaseLine.FieldNo("Line No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Document Line No.");
        SpecificQltyInspectSrcFldConf.Insert();

        // [GIVEN] A purchase order with vendor, item, and location is created
        LibraryWarehouse.CreateLocation(Location);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        QltyPurOrderGenerator.CreatePurchaseOrder(1, Location, Item, Vendor, '', PurchaseHeader, PurchaseLine, DummyReservationEntry);
        RecordRef.GetTable(PurchaseLine);

        // [WHEN] Finding related vendor from purchase line by traversing to parent header
        // [THEN] The traversal function finds the vendor from the purchase header
        LibraryAssert.IsTrue(QltyTraversal.FindRelatedVendor(FoundVendor, RecordRef, EmptyVariant2, EmptyVariant3, EmptyVariant4, EmptyVariant5), 'Should find vendor.');
        LibraryAssert.AreEqual(PurchaseHeader."Buy-from Vendor No.", FoundVendor."No.", 'Should be same vendor.');
    end;

    [Test]
    procedure FindRelatedCustomer_ParentRecord()
    var
        Location: Record Location;
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Customer: Record Customer;
        FoundCustomer: Record Customer;
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        RecordRef: RecordRef;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
        EmptyVariant5: Variant;
        ConfigCode: Text;
    begin
        // [SCENARIO] Find a related customer from sales line by traversing to parent sales header

        // [GIVEN] Source configuration for chained table mapping from Sales Header to Sales Line with field configurations
        if not SpecificQltyInspectSourceConfig.IsEmpty() then
            SpecificQltyInspectSourceConfig.DeleteAll();
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(SpecificQltyInspectSourceConfig.Code), ConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Description := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Description));
        SpecificQltyInspectSourceConfig.Validate("From Table No.", Database::"Sales Header");
        SpecificQltyInspectSourceConfig."To Type" := SpecificQltyInspectSourceConfig."To Type"::"Chained table";
        SpecificQltyInspectSourceConfig.Validate("To Table No.", Database::"Sales Line");
        SpecificQltyInspectSourceConfig.Insert();
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := SalesHeader.FieldNo("No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::"Chained table";
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Sales Line";
        SpecificQltyInspectSrcFldConf."To Field No." := SalesLine.FieldNo("Document No.");
        SpecificQltyInspectSrcFldConf.Insert();
        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := SalesHeader.FieldNo("Document Type");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::"Chained table";
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Sales Line";
        SpecificQltyInspectSrcFldConf."To Field No." := SalesLine.FieldNo("Document Type");
        SpecificQltyInspectSrcFldConf.Insert();
        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := SalesHeader.FieldNo("Sell-to Customer No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Custom 1");
        SpecificQltyInspectSrcFldConf.Insert();

        // [GIVEN] Source configuration from Sales Line to Test with field mappings
        Clear(SpecificQltyInspectSourceConfig);
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(SpecificQltyInspectSourceConfig.Code), ConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Description := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Description));
        SpecificQltyInspectSourceConfig.Validate("From Table No.", Database::"Sales Line");
        SpecificQltyInspectSourceConfig."To Type" := SpecificQltyInspectSourceConfig."To Type"::Test;
        SpecificQltyInspectSourceConfig.Validate("To Table No.", Database::"Qlty. Inspection Test Header");
        SpecificQltyInspectSourceConfig.Insert();
        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := SalesLine.FieldNo("Document No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Document No.");
        SpecificQltyInspectSrcFldConf.Insert();
        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := SalesLine.FieldNo("Line No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Document Line No.");
        SpecificQltyInspectSrcFldConf.Insert();

        // [GIVEN] A sales order with customer, item, and location is created
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        RecordRef.GetTable(SalesLine);

        // [WHEN] Finding related customer from sales line by traversing to parent header
        // [THEN] The traversal function finds the customer from the sales header
        LibraryAssert.IsTrue(QltyTraversal.FindRelatedCustomer(FoundCustomer, RecordRef, EmptyVariant2, EmptyVariant3, EmptyVariant4, EmptyVariant5), 'Should find customer.');
        LibraryAssert.AreEqual(SalesHeader."Sell-to Customer No.", FoundCustomer."No.", 'Should be same customer.');
    end;

    [Test]
    procedure FindRelatedRouting_ParentRecord()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Item: Record Item;
        FoundRoutingHeader: Record "Routing Header";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        RecordRef: RecordRef;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
        EmptyVariant5: Variant;
        ConfigCode: Text;
    begin
        // [SCENARIO] Find a related routing from production order routing line by traversing to parent production order

        // [GIVEN] Source configuration for chained table mapping from Production Order to Prod. Order Routing Line with field configurations
        if not SpecificQltyInspectSourceConfig.IsEmpty() then
            SpecificQltyInspectSourceConfig.DeleteAll();

        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(SpecificQltyInspectSourceConfig.Code), ConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Description := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Description));
        SpecificQltyInspectSourceConfig.Validate("From Table No.", Database::"Production Order");
        SpecificQltyInspectSourceConfig."To Type" := SpecificQltyInspectSourceConfig."To Type"::"Chained table";
        SpecificQltyInspectSourceConfig.Validate("To Table No.", Database::"Prod. Order Routing Line");
        SpecificQltyInspectSourceConfig.Insert();

        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := ProdProductionOrder.FieldNo("No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::"Chained table";
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Prod. Order Routing Line";
        SpecificQltyInspectSrcFldConf."To Field No." := ProdOrderRoutingLine.FieldNo("Prod. Order No.");
        SpecificQltyInspectSrcFldConf.Insert();

        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := ProdProductionOrder.FieldNo(Status);
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::"Chained table";
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Prod. Order Routing Line";
        SpecificQltyInspectSrcFldConf."To Field No." := ProdOrderRoutingLine.FieldNo(Status);
        SpecificQltyInspectSrcFldConf.Insert();

        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := ProdProductionOrder.FieldNo("Routing No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Custom 1");
        SpecificQltyInspectSrcFldConf.Insert();

        Clear(SpecificQltyInspectSourceConfig);
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(SpecificQltyInspectSourceConfig.Code), ConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Description := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Description));
        SpecificQltyInspectSourceConfig.Validate("From Table No.", Database::"Prod. Order Routing Line");
        SpecificQltyInspectSourceConfig."To Type" := SpecificQltyInspectSourceConfig."To Type"::Test;
        SpecificQltyInspectSourceConfig.Validate("To Table No.", Database::"Qlty. Inspection Test Header");
        SpecificQltyInspectSourceConfig.Insert();

        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := ProdOrderRoutingLine.FieldNo("Prod. Order No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Document No.");
        SpecificQltyInspectSrcFldConf.Insert();

        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := ProdOrderRoutingLine.FieldNo(Status);
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";

        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Sub Type");
        SpecificQltyInspectSrcFldConf.Insert();

        // [GIVEN] An item and production order with routing line are created
        QltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        RecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] Finding related routing from production order routing line by traversing to parent production order
        // [THEN] The traversal function finds the routing from the production order
        LibraryAssert.IsTrue(QltyTraversalMfg.FindRelatedRouting(FoundRoutingHeader, RecordRef, EmptyVariant2, EmptyVariant3, EmptyVariant4, EmptyVariant5), 'Should find routing.');
        LibraryAssert.AreEqual(ProdProductionOrder."Routing No.", FoundRoutingHeader."No.", 'Should be same routing.');
    end;

    [Test]
    procedure FindRelatedRoutingLine_ParentRecord()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderLine: Record "Prod. Order Line";
        Item: Record Item;
        FoundProdOrderRoutingLine: Record "Prod. Order Routing Line";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        RecordRef: RecordRef;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
        EmptyVariant5: Variant;
        ConfigCode: Text;
    begin
        // [SCENARIO] Find a related production order routing line from production order line by chained traversal

        // [GIVEN] Source configuration for chained table mapping from Prod. Order Line to Prod. Order Routing Line with field configurations
        if not SpecificQltyInspectSourceConfig.IsEmpty() then
            SpecificQltyInspectSourceConfig.DeleteAll();

        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(SpecificQltyInspectSourceConfig.Code), ConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Description := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Description));
        SpecificQltyInspectSourceConfig.Validate("From Table No.", Database::"Prod. Order Line");
        SpecificQltyInspectSourceConfig."To Type" := SpecificQltyInspectSourceConfig."To Type"::"Chained table";
        SpecificQltyInspectSourceConfig.Validate("To Table No.", Database::"Prod. Order Routing Line");
        SpecificQltyInspectSourceConfig.Insert();

        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := ProdOrderLine.FieldNo("Prod. Order No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::"Chained table";
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Prod. Order Routing Line";
        SpecificQltyInspectSrcFldConf."To Field No." := ProdOrderRoutingLine.FieldNo("Prod. Order No.");
        SpecificQltyInspectSrcFldConf.Insert();

        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := ProdOrderLine.FieldNo(Status);
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::"Chained table";
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Prod. Order Routing Line";
        SpecificQltyInspectSrcFldConf."To Field No." := ProdOrderRoutingLine.FieldNo(Status);
        SpecificQltyInspectSrcFldConf.Insert();

        Clear(SpecificQltyInspectSourceConfig);
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(SpecificQltyInspectSourceConfig.Code), ConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Description := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Description));
        SpecificQltyInspectSourceConfig.Validate("From Table No.", Database::"Prod. Order Routing Line");
        SpecificQltyInspectSourceConfig."To Type" := SpecificQltyInspectSourceConfig."To Type"::Test;
        SpecificQltyInspectSourceConfig.Validate("To Table No.", Database::"Qlty. Inspection Test Header");
        SpecificQltyInspectSourceConfig.Insert();

        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := ProdOrderRoutingLine.FieldNo("No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Document No.");
        SpecificQltyInspectSrcFldConf.Insert();

        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := ProdOrderRoutingLine.FieldNo(Status);
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Sub Type");
        SpecificQltyInspectSrcFldConf.Insert();

        // [GIVEN] An item and production order with routing line are created
        QltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdProductionOrder.Status, ProdProductionOrder."No.", 10000);
        RecordRef.GetTable(ProdOrderLine);
        Clear(ProdOrderRoutingLine);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdProductionOrder."No.");
        ProdOrderRoutingLine.SetRange(Status, ProdProductionOrder.Status);
        ProdOrderRoutingLine.FindFirst();

        // [WHEN] Finding related routing line from production order line by chained traversal
        // [THEN] The traversal function finds the routing line with matching key fields
        LibraryAssert.IsTrue(QltyTraversalMfg.FindRelatedProdOrderRoutingLine(FoundProdOrderRoutingLine, RecordRef, EmptyVariant2, EmptyVariant3, EmptyVariant4, EmptyVariant5), 'Should find routing line.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine.Status, FoundProdOrderRoutingLine.Status, 'Should be same status');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."No.", FoundProdOrderRoutingLine."No.", 'Should be same No.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."Prod. Order No.", FoundProdOrderRoutingLine."Prod. Order No.", 'Should be same Prod. Order No.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."Routing No.", FoundProdOrderRoutingLine."Routing No.", 'Should be same Routing No.');
        LibraryAssert.AreEqual(ProdOrderRoutingLine."Operation No.", FoundProdOrderRoutingLine."Operation No.", 'Should be same Operation No.');
    end;

    [Test]
    procedure FindRelatedBOM_ParentRecord()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        SpecificQltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        ProdProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderLine: Record "Prod. Order Line";
        Item: Record Item;
        FundProductionBOMHeader: Record "Production BOM Header";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        RecordRef: RecordRef;
        EmptyVariant2: Variant;
        EmptyVariant3: Variant;
        EmptyVariant4: Variant;
        EmptyVariant5: Variant;
        ConfigCode: Text;
    begin
        // [SCENARIO] Find a related production BOM from production order routing line by chained traversal

        // [GIVEN] Source configuration for chained table mapping from Prod. Order Line to Prod. Order Routing Line with field configurations
        if not SpecificQltyInspectSourceConfig.IsEmpty() then
            SpecificQltyInspectSourceConfig.DeleteAll();

        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(SpecificQltyInspectSourceConfig.Code), ConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Description := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Description));
        SpecificQltyInspectSourceConfig.Validate("From Table No.", Database::"Prod. Order Line");
        SpecificQltyInspectSourceConfig."To Type" := SpecificQltyInspectSourceConfig."To Type"::"Chained table";
        SpecificQltyInspectSourceConfig.Validate("To Table No.", Database::"Prod. Order Routing Line");
        SpecificQltyInspectSourceConfig.Insert();

        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := ProdOrderLine.FieldNo("Prod. Order No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::"Chained table";
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Prod. Order Routing Line";
        SpecificQltyInspectSrcFldConf."To Field No." := ProdOrderRoutingLine.FieldNo("Prod. Order No.");
        SpecificQltyInspectSrcFldConf.Insert();

        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := ProdOrderLine.FieldNo(Status);
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::"Chained table";
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Prod. Order Routing Line";
        SpecificQltyInspectSrcFldConf."To Field No." := ProdOrderRoutingLine.FieldNo(Status);
        SpecificQltyInspectSrcFldConf.Insert();

        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := Item.FieldNo("Production BOM No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Custom 1");
        SpecificQltyInspectSrcFldConf.Insert();

        Clear(SpecificQltyInspectSourceConfig);
        SpecificQltyInspectSourceConfig.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(SpecificQltyInspectSourceConfig.Code), ConfigCode);
        SpecificQltyInspectSourceConfig.Code := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Code));
        SpecificQltyInspectSourceConfig.Description := CopyStr(ConfigCode, 1, MaxStrLen(SpecificQltyInspectSourceConfig.Description));
        SpecificQltyInspectSourceConfig.Validate("From Table No.", Database::"Prod. Order Routing Line");
        SpecificQltyInspectSourceConfig."To Type" := SpecificQltyInspectSourceConfig."To Type"::Test;
        SpecificQltyInspectSourceConfig.Validate("To Table No.", Database::"Qlty. Inspection Test Header");
        SpecificQltyInspectSourceConfig.Insert();

        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := ProdOrderRoutingLine.FieldNo("Prod. Order No.");
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Document No.");
        SpecificQltyInspectSrcFldConf.Insert();
        Clear(SpecificQltyInspectSrcFldConf);
        SpecificQltyInspectSrcFldConf.Init();
        SpecificQltyInspectSrcFldConf.Code := SpecificQltyInspectSourceConfig.Code;
        SpecificQltyInspectSrcFldConf.InitLineNoIfNeeded();
        SpecificQltyInspectSrcFldConf."From Table No." := SpecificQltyInspectSourceConfig."From Table No.";
        SpecificQltyInspectSrcFldConf."From Field No." := ProdOrderRoutingLine.FieldNo(Status);
        SpecificQltyInspectSrcFldConf."To Type" := SpecificQltyInspectSrcFldConf."To Type"::Test;
        SpecificQltyInspectSrcFldConf."To Table No." := Database::"Qlty. Inspection Test Header";
        SpecificQltyInspectSrcFldConf."To Field No." := QltyInspectionTestHeader.FieldNo("Source Sub Type");
        SpecificQltyInspectSrcFldConf.Insert();

        // [GIVEN] An item and production order with routing line and production BOM are created
        QltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
        ProdOrderLine.Get(ProdProductionOrder.Status, ProdProductionOrder."No.", 10000);
        RecordRef.GetTable(ProdOrderRoutingLine);

        // [WHEN] Finding related BOM from production order routing line by chained traversal
        // [THEN] The traversal function finds the BOM from the production order line
        LibraryAssert.IsTrue(QltyTraversalMfg.FindRelatedBillOfMaterial(FundProductionBOMHeader, RecordRef, EmptyVariant2, EmptyVariant3, EmptyVariant4, EmptyVariant5), 'Should find BOM.');
        LibraryAssert.AreEqual(ProdOrderLine."Production BOM No.", FundProductionBOMHeader."No.", 'Should be same BOM.');
    end;
}

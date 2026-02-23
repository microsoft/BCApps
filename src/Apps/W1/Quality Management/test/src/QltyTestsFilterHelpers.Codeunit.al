// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Vendor;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Integration.Manufacturing.Routing;
using Microsoft.QualityManagement.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Test.QualityManagement.TestLibraries;
using Microsoft.Warehouse.Structure;
using System.Reflection;
using System.TestLibraries.Utilities;

codeunit 139962 "Qlty. Tests - Filter Helpers"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryAssert: Codeunit "Library Assert";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        Code20: Code[20];
        ZoneTok: Label 'PICK';
        FilterTok: Label 'WHERE(No.=FILTER(%1))', Comment = '%1=item no.';
        AttributeTok: Label '"Color"=Filter(Red),"ModelYear"=Filter(2019)';
        Attribute2Tok: Label '"%1"=Filter(%2)', Comment = '%1=Attribute Name, %2= Value';
        Attribute3Tok: Label '"%1"=Filter(%2),"%3"=Filter(%4)', Comment = '%1=Attribute Name, %2= Value, %3=Attribute Name, %4= Value';
        FilterExpressionTok: Label 'No.=01121212,Currency Code=USD';
        RecordRefFilterTok: Label 'No.: 01121212, Currency Code: USD';
        ObjectIdFilterTok: Label '0|32|83|5406|5409|39|37';
        InputWhereClauseTok: Label 'Lorem ipsum dolor sit amet, WHERE consectetuer adipiscing elit';
        CorrectOutputTok: Label 'WHERE consectetuer adipiscing elit';
        InputWhereClause2Tok: Label 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.';
        InputWhereClause400Tok: Label 'WHERE Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Nulla consequat massa quis enim. Donec pede justo, fringilla vel, aliquet nec, vulputate eget, arcu. In enim justo, rhoncus ut, imperdiet a, venenatis vitae, justo. Nullam dictum felis eu pede mollis pretium. Integer tincidunt. Cras dapibu';
        ViewTok: Label 'VERSION(1) SORTING("No.") WHERE("No."=FILTER(%1))', Comment = '%1=item no.';

    [Test]
    [HandlerFunctions('FilterBuilderPageHandler')]
    procedure BuildFilter_BlankFilter()
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        Value: Text;
        ClaimedFilterBuilt: Boolean;
    begin
        // [SCENARIO] Validate building a filter for item from scratch using the filter builder

        // [GIVEN] An item is created
        LibraryInventory.CreateItem(Item);
        Code20 := Item."No.";

        // [WHEN] BuildFilter is called with no existing filter
        ClaimedFilterBuilt := QltyInspectionUtility.BuildFilter(Database::Item, false, Value);

        // [THEN] A filter is successfully built
        LibraryAssert.IsTrue(ClaimedFilterBuilt, 'Should have made filter');
        // [THEN] The filter matches the item number
        LibraryAssert.AreEqual(StrSubstNo(FilterTok, Item."No."), Value, 'Filter should match item.');
    end;

    [Test]
    [HandlerFunctions('FilterBuilderPageHandler')]
    procedure BuildFilter_ExistingFilter()
    var
        Item: Record Item;
        SecondItem: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        Value: Text;
        ClaimedFilterBuilt: Boolean;
    begin
        // [SCENARIO] Validate building a filter when a preexisting filter already exists

        // [GIVEN] Two items are created
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(SecondItem);
        // [GIVEN] A filter is set for the first item
        Value := StrSubstNo(FilterTok, Item."No.");
        Code20 := SecondItem."No.";

        // [WHEN] BuildFilter is called with an existing filter
        ClaimedFilterBuilt := QltyInspectionUtility.BuildFilter(Database::Item, false, Value);

        // [THEN] A filter is successfully built
        LibraryAssert.IsTrue(ClaimedFilterBuilt, 'Should have made filter');
        // [THEN] The filter is replaced with the second item number
        LibraryAssert.AreEqual(StrSubstNo(FilterTok, SecondItem."No."), Value, '');
    end;

    [Test]
    [HandlerFunctions('LookupObjectsHandler_FirstRec')]
    procedure RunModalLookupTable_TableFilter_FirstRec()
    var
        ObjectId: Integer;
        ObjectIdFilter: Text;
        ObjectIDText: List of [Text];
        FirstObjectId: Integer;
    begin
        // [SCENARIO] Validate modal table lookup with a table filter returning the first record

        // [GIVEN] An object ID filter is set
        ObjectIdFilter := ObjectIdFilterTok;

        // [WHEN] RunModalLookupTable is called with the filter
        QltyInspectionUtility.RunModalLookupTable(ObjectId, ObjectIdFilter);

        // [THEN] The first object ID from the filter is returned
        ObjectIDText := ObjectIdFilter.Split('|');
        Evaluate(FirstObjectId, ObjectIDText.Get(2));
        LibraryAssert.AreEqual(ObjectId, FirstObjectId, '');
    end;

    [Test]
    [HandlerFunctions('LookupObjectsHandler_FirstRec')]
    procedure RunModalLookupTable_NoFilter_FirstRec()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ObjectId: Integer;
    begin
        // [SCENARIO] Validate modal table lookup without a filter returning the first table

        // [WHEN] RunModalLookupTable is called with no filter
        QltyInspectionUtility.RunModalLookupTable(ObjectId, '');

        // [THEN] The first table object is returned
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.FindFirst();
        LibraryAssert.AreEqual(AllObjWithCaption."Object ID", ObjectId, '');
    end;

    [Test]
    [HandlerFunctions('LookupObjectsHandler_FirstRec')]
    procedure RunModalLookupTableFromText_NoFilter_FirstRec()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TableReference: Text;
    begin
        // [SCENARIO] Validate modal table lookup from text without a filter

        // [WHEN] RunModalLookupTableFromText is called with no filter
        QltyInspectionUtility.RunModalLookupTableFromText(TableReference);

        // [THEN] The first table's name is returned
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.FindFirst();
        LibraryAssert.AreEqual(AllObjWithCaption."Object Name", TableReference, 'The object name should be the same.');
    end;

    [Test]
    [HandlerFunctions('LookupObjectsHandler_FilteredRec')]
    procedure RunModalLookupTableFromText_TableFilter_FilteredRec()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ChosenTableAllObjWithCaption: Record AllObjWithCaption;
        TableReference: Text;
    begin
        // [SCENARIO] Validate modal table lookup from text with a table filter

        // [GIVEN] A specific table object is selected (Qlty. Management Setup)
        ChosenTableAllObjWithCaption.Get(ChosenTableAllObjWithCaption."Object Type"::Table, Database::"Qlty. Management Setup");
        TableReference := Format(ChosenTableAllObjWithCaption."Object ID");

        // [WHEN] RunModalLookupTableFromText is called with the table filter
        QltyInspectionUtility.RunModalLookupTableFromText(TableReference);

        // [THEN] The correct table name is returned
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.FindFirst();
        LibraryAssert.AreEqual(AllObjWithCaption."Object Name", TableReference, 'The object name should be the same.');
    end;

    [Test]
    [HandlerFunctions('LookupObjectsHandler_FirstRec')]
    procedure RunModalLookupTableFromText_TableFilter_FirstRec()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        ChosenTableAllObjWithCaption: Record AllObjWithCaption;
        TableReference: Text;
    begin
        // [SCENARIO] Validate modal table lookup from text with a table filter returning first record

        // [GIVEN] A specific table object is selected (Qlty. Management Setup)
        ChosenTableAllObjWithCaption.Get(ChosenTableAllObjWithCaption."Object Type"::Table, Database::"Qlty. Management Setup");
        TableReference := Format(ChosenTableAllObjWithCaption."Object ID");

        // [WHEN] RunModalLookupTableFromText is called with the table ID filter
        QltyInspectionUtility.RunModalLookupTableFromText(TableReference);

        // [THEN] The first table's name matching the filter is returned
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.FindFirst();
        LibraryAssert.AreEqual(AllObjWithCaption."Object Name", TableReference, 'The object name should be the same.');
    end;

    [Test]
    [HandlerFunctions('LookupFieldsHandler_FirstRec')]
    procedure RunModalLookupFieldFromText_TableFilter_FirstRec()
    var
        TableAllObjWithCaption: Record AllObjWithCaption;
        ToLoadField: Record Field;
        TableReference: Text;
        FieldReference: Text;
    begin
        // [SCENARIO] Validate modal field lookup from text with table filter returning first field

        // [GIVEN] A specific table object is selected (Qlty. Management Setup)
        TableAllObjWithCaption.Get(TableAllObjWithCaption."Object Type"::Table, Database::"Qlty. Management Setup");
        TableReference := Format(TableAllObjWithCaption."Object ID");
        // [WHEN] RunModalLookupFieldFromText is called with the table reference
        QltyInspectionUtility.RunModalLookupFieldFromText(TableReference, FieldReference);

        // [THEN] The first field name from the table is returned
        ToLoadField.SetRange(TableNo, TableAllObjWithCaption."Object ID");
        ToLoadField.FindFirst();
        LibraryAssert.AreEqual(ToLoadField.FieldName, FieldReference, 'The field name should be the same.');
    end;

    [Test]
    [HandlerFunctions('LookupFieldsHandler_FirstRec')]
    procedure RunModalLookupFieldFromText_TableAndFieldFilter_FirstRec()
    var
        TableAllObjWithCaption: Record AllObjWithCaption;
        ToLoadField: Record Field;
        TableReference: Text;
        FieldReference: Text;
    begin
        // [SCENARIO] Validate modal field lookup from text with table and field filter

        // [GIVEN] A specific table and its last field are selected
        TableAllObjWithCaption.Get(TableAllObjWithCaption."Object Type"::Table, Database::"Qlty. Management Setup");
        ToLoadField.SetRange(TableNo, TableAllObjWithCaption."Object ID");
        ToLoadField.FindLast();
        TableReference := Format(TableAllObjWithCaption."Object ID");
        FieldReference := Format(ToLoadField."No.");

        // [WHEN] RunModalLookupFieldFromText is called with both table and field reference
        QltyInspectionUtility.RunModalLookupFieldFromText(TableReference, FieldReference);

        // [THEN] The first field from the filtered table is returned
        ToLoadField.Reset();
        ToLoadField.SetRange(TableNo, TableAllObjWithCaption."Object ID");
        ToLoadField.FindFirst();
        LibraryAssert.AreEqual(ToLoadField.FieldName, FieldReference, 'The field name should be the same.');
    end;

    [Test]
    procedure IdentifyTableIDFromText_TableNo()
    var
        TableAllObjWithCaption: Record AllObjWithCaption;
        TableReference: Text;
        CurrentTable: Integer;
    begin
        // [SCENARIO] Validate identifying a table ID from its table number

        // [GIVEN] A table object is retrieved and formatted as text
        TableAllObjWithCaption.SetRange("Object Type", TableAllObjWithCaption."Object Type"::Table);
        TableAllObjWithCaption.FindFirst();
        TableReference := Format(TableAllObjWithCaption."Object ID");

        // [WHEN] IdentifyTableIDFromText is called with the table number
        CurrentTable := QltyInspectionUtility.IdentifyTableIDFromText(TableReference);

        // [THEN] The correct table ID is identified
        LibraryAssert.AreEqual(TableAllObjWithCaption."Object ID", CurrentTable, 'The table no. should be the same.');
    end;

    [Test]
    procedure IdentifyTableIDFromText_TableName()
    var
        TableAllObjWithCaption: Record AllObjWithCaption;
        TableReference: Text;
        CurrentTable: Integer;
    begin
        // [SCENARIO] Validate identifying a table ID from its table name

        // [GIVEN] A table object is retrieved and its name is used
        TableAllObjWithCaption.SetRange("Object Type", TableAllObjWithCaption."Object Type"::Table);
        TableAllObjWithCaption.FindFirst();
        TableReference := TableAllObjWithCaption."Object Name";

        // [WHEN] IdentifyTableIDFromText is called with the table name
        CurrentTable := QltyInspectionUtility.IdentifyTableIDFromText(TableReference);

        // [THEN] The correct table ID is identified
        LibraryAssert.AreEqual(TableAllObjWithCaption."Object ID", CurrentTable, 'The table no. should be the same.');
    end;

    [Test]
    procedure IdentifyTableIDFromText_TableCaption()
    var
        TableAllObjWithCaption: Record AllObjWithCaption;
        TableReference: Text;
        CurrentTable: Integer;
    begin
        // [SCENARIO] Validate identifying a table ID from its table caption

        // [GIVEN] A table object is retrieved and its caption is used
        TableAllObjWithCaption.SetRange("Object Type", TableAllObjWithCaption."Object Type"::Table);
        TableAllObjWithCaption.FindFirst();
        TableReference := TableAllObjWithCaption."Object Caption";

        // [WHEN] IdentifyTableIDFromText is called with the table caption
        CurrentTable := QltyInspectionUtility.IdentifyTableIDFromText(TableReference);

        // [THEN] The correct table ID is identified
        LibraryAssert.AreEqual(TableAllObjWithCaption."Object ID", CurrentTable, 'The table no. should be the same.');
    end;

    [Test]
    procedure IdentifyTableIDFromText_FuzzyName()
    var
        TableAllObjWithCaption: Record AllObjWithCaption;
        TableReference: Text;
        CurrentTable: Integer;
    begin
        // [SCENARIO] Validate identifying a table ID using a partial fuzzy name search

        // [GIVEN] A table object is retrieved and its name is modified (substring from position 2)
        TableAllObjWithCaption.Get(TableAllObjWithCaption."Object Type"::Table, 6);
        TableReference := TableAllObjWithCaption."Object Name";
        TableReference := CopyStr(TableReference, 2, (MaxStrLen(TableReference) - 1));

        // [WHEN] IdentifyTableIDFromText is called with the partial name
        CurrentTable := QltyInspectionUtility.IdentifyTableIDFromText(TableReference);

        // [THEN] The correct table ID is identified through fuzzy matching
        LibraryAssert.AreEqual(TableAllObjWithCaption."Object ID", CurrentTable, 'The table no. should be the same.');
    end;

    [Test]
    procedure IdentifyTableIDFromText_TooShortFuzzyName_NoMatch()
    var
        TableAllObjWithCaption: Record AllObjWithCaption;
        TableReference: Text;
        CurrentTable: Integer;
    begin
        // [SCENARIO] Validate that too short fuzzy search returns no match

        // [GIVEN] A table object is retrieved and its name is shortened to first 5 characters
        TableAllObjWithCaption.Get(TableAllObjWithCaption."Object Type"::Table, 6);
        TableReference := TableAllObjWithCaption."Object Name";
        TableReference := CopyStr(TableReference, 1, 5);

        // [WHEN] IdentifyTableIDFromText is called with the too-short name
        CurrentTable := QltyInspectionUtility.IdentifyTableIDFromText(TableReference);

        // [THEN] No table is returned due to too many matches
        LibraryAssert.AreEqual(0, CurrentTable, 'There should be no table returned due to too many matches.');
    end;

    [Test]
    procedure IdentifyTableIDFromText_FuzzyCaption()
    var
        TableAllObjWithCaption: Record AllObjWithCaption;
        TableReference: Text;
        CurrentTable: Integer;
    begin
        // [SCENARIO] Validate identifying a table ID using a partial fuzzy caption search

        // [GIVEN] A table object is retrieved and its caption is modified (substring from position 2)
        TableAllObjWithCaption.Get(TableAllObjWithCaption."Object Type"::Table, 6);
        TableReference := TableAllObjWithCaption."Object Caption";
        TableReference := CopyStr(TableReference, 2, (MaxStrLen(TableReference) - 1));

        // [WHEN] IdentifyTableIDFromText is called with the partial caption
        CurrentTable := QltyInspectionUtility.IdentifyTableIDFromText(TableReference);

        // [THEN] The correct table ID is identified through fuzzy caption matching
        LibraryAssert.AreEqual(TableAllObjWithCaption."Object ID", CurrentTable, 'The table no. should be the same.');
    end;

    [Test]
    procedure IdentifyTableIDFromText_TooShortFuzzyCaption_NoMatch()
    var
        TableAllObjWithCaption: Record AllObjWithCaption;
        TableReference: Text;
        CurrentTable: Integer;
    begin
        // [SCENARIO] Validate that too short fuzzy caption search returns no match

        // [GIVEN] A table object is retrieved and its caption is shortened to first 5 characters
        TableAllObjWithCaption.Get(TableAllObjWithCaption."Object Type"::Table, 6);
        TableReference := TableAllObjWithCaption."Object Caption";
        TableReference := CopyStr(TableReference, 1, 5);

        // [WHEN] IdentifyTableIDFromText is called with the too-short caption
        CurrentTable := QltyInspectionUtility.IdentifyTableIDFromText(TableReference);

        // [THEN] No table is returned due to too many matches
        LibraryAssert.AreEqual(0, CurrentTable, 'There should be no table returned due to too many matches.');
    end;

    [Test]
    procedure IdentifyFieldIDFromText_FieldNo()
    var
        TableAllObjWithCaption: Record AllObjWithCaption;
        ToLoadField: Record Field;
        FieldReference: Text;
        FieldNumberNumber: Integer;
    begin
        // [SCENARIO] Validate identifying a field ID from its field number

        // [GIVEN] A table object is retrieved and field reference is set to '1'
        TableAllObjWithCaption.SetRange("Object Type", TableAllObjWithCaption."Object Type"::Table);
        TableAllObjWithCaption.FindFirst();

        FieldReference := '1';

        // [WHEN] IdentifyFieldIDFromText is called with the field number
        FieldNumberNumber := QltyInspectionUtility.IdentifyFieldIDFromText(TableAllObjWithCaption."Object ID", FieldReference);

        // [THEN] The correct field ID is identified
        ToLoadField.SetRange(TableNo, TableAllObjWithCaption."Object ID");
        ToLoadField.FindFirst();
        LibraryAssert.AreEqual(ToLoadField."No.", FieldNumberNumber, 'The field no. should be the same.');
    end;

    [Test]
    procedure IdentifyFieldIDFromText_FieldName()
    var
        TableAllObjWithCaption: Record AllObjWithCaption;
        ToLoadField: Record Field;
        FieldReference: Text;
        FieldNumber: Integer;
    begin
        // [SCENARIO] Validate identifying a field ID from its field name

        // [GIVEN] A table object is retrieved and its first field name is used
        TableAllObjWithCaption.SetRange("Object Type", TableAllObjWithCaption."Object Type"::Table);
        TableAllObjWithCaption.FindFirst();

        ToLoadField.SetRange(TableNo, TableAllObjWithCaption."Object ID");
        ToLoadField.FindFirst();
        FieldReference := ToLoadField.FieldName;

        // [WHEN] IdentifyFieldIDFromText is called with the field name
        FieldNumber := QltyInspectionUtility.IdentifyFieldIDFromText(TableAllObjWithCaption."Object ID", FieldReference);

        // [THEN] The correct field ID is identified
        LibraryAssert.AreEqual(ToLoadField."No.", FieldNumber, 'The field no. should be the same.');
    end;

    [Test]
    procedure IdentifyFieldIDFromText_FieldCaption()
    var
        TableAllObjWithCaption: Record AllObjWithCaption;
        ToLoadField: Record Field;
        FieldReference: Text;
        FieldNumber: Integer;
    begin
        // [SCENARIO] Validate identifying a field ID from its field caption

        // [GIVEN] A table object is retrieved and its first field caption is used
        TableAllObjWithCaption.SetRange("Object Type", TableAllObjWithCaption."Object Type"::Table);
        TableAllObjWithCaption.FindFirst();

        ToLoadField.SetRange(TableNo, TableAllObjWithCaption."Object ID");
        ToLoadField.FindFirst();
        FieldReference := ToLoadField."Field Caption";

        // [WHEN] IdentifyFieldIDFromText is called with the field caption
        FieldNumber := QltyInspectionUtility.IdentifyFieldIDFromText(TableAllObjWithCaption."Object ID", FieldReference);

        // [THEN] The correct field ID is identified
        LibraryAssert.AreEqual(ToLoadField."No.", FieldNumber, 'The field no. should be the same.');
    end;

    [Test]
    procedure IdentifyFieldIDFromText_FuzzyName()
    var
        ToLoadField: Record Field;
        FieldReference: Text;
        FieldNumber: Integer;
    begin
        // [SCENARIO] Validate identifying a field ID using a partial fuzzy name search

        // [GIVEN] A specific field is retrieved and its name is modified (substring from position 2)
        ToLoadField.Get(Database::"Payment Terms", 3);
        FieldReference := ToLoadField.FieldName;
        FieldReference := CopyStr(FieldReference, 2, (MaxStrLen(FieldReference) - 1));

        // [WHEN] IdentifyFieldIDFromText is called with the partial field name
        FieldNumber := QltyInspectionUtility.IdentifyFieldIDFromText(ToLoadField.TableNo, FieldReference);

        // [THEN] The correct field ID is identified through fuzzy matching
        LibraryAssert.AreEqual(ToLoadField."No.", FieldNumber, 'The field no. should be the same.');
    end;

    [Test]
    procedure IdentifyFieldIDFromText_TooShortFuzzyName_NoMatch()
    var
        ToLoadField: Record Field;
        FieldReference: Text;
        FieldNumber: Integer;
    begin
        // [SCENARIO] Validate that too short fuzzy field name search returns no match

        // [GIVEN] A specific field is retrieved and its name is shortened to first 3 characters
        ToLoadField.Get(Database::"Payment Terms", 3);
        FieldReference := ToLoadField.FieldName;
        FieldReference := CopyStr(FieldReference, 1, 3);

        // [WHEN] IdentifyFieldIDFromText is called with the too-short field name
        FieldNumber := QltyInspectionUtility.IdentifyFieldIDFromText(ToLoadField.TableNo, FieldReference);

        // [THEN] No field is returned due to too many matches
        LibraryAssert.AreEqual(0, FieldNumber, 'There should be no field returned due to too many matches.');
    end;

    [Test]
    procedure IdentifyFieldIDFromText_FuzzyCaption()
    var
        ToLoadField: Record Field;
        FieldReference: Text;
        FieldNumber: Integer;
    begin
        // [SCENARIO] Validate identifying a field ID using a partial fuzzy caption search

        // [GIVEN] A specific field is retrieved and its caption is modified (substring from position 2)
        ToLoadField.Get(Database::"Payment Terms", 3);
        FieldReference := ToLoadField."Field Caption";
        FieldReference := CopyStr(FieldReference, 2, (MaxStrLen(FieldReference) - 1));

        // [WHEN] IdentifyFieldIDFromText is called with the partial field caption
        FieldNumber := QltyInspectionUtility.IdentifyFieldIDFromText(ToLoadField.TableNo, FieldReference);

        // [THEN] The correct field ID is identified through fuzzy caption matching
        LibraryAssert.AreEqual(ToLoadField."No.", FieldNumber, 'The field no. should be the same.');
    end;

    [Test]
    procedure IdentifyFieldIDFromText_TooShortFuzzyCaption_NoMatch()
    var
        ToLoadField: Record Field;
        FieldReference: Text;
        FieldNumber: Integer;
    begin
        // [SCENARIO] Validate that too short fuzzy field caption search returns no match

        // [GIVEN] A specific field is retrieved and its caption is shortened to first 3 characters
        ToLoadField.Get(Database::"Payment Terms", 3);
        FieldReference := ToLoadField."Field Caption";
        FieldReference := CopyStr(FieldReference, 1, 3);

        // [WHEN] IdentifyFieldIDFromText is called with the too-short field caption
        FieldNumber := QltyInspectionUtility.IdentifyFieldIDFromText(ToLoadField.TableNo, FieldReference);

        // [THEN] No field is returned due to too many matches
        LibraryAssert.AreEqual(0, FieldNumber, 'There should be no field returned due to too many matches.');
    end;

    [Test]
    procedure SetFiltersByExpressionSyntax()
    var
        RecordRef: RecordRef;
        Filter: Text;
    begin
        // [SCENARIO] Validate expression syntax is converted to filter format

        // [GIVEN] A filter expression is set and a record reference is opened
        Filter := FilterExpressionTok;
        RecordRef.Open(Database::Customer);

        // [WHEN] SetFiltersByExpressionSyntax is called with the expression
        QltyInspectionUtility.SetFiltersByExpressionSyntax(RecordRef, Filter);
        Filter := RecordRef.GetFilters;

        // [THEN] Expression is converted to filter format
        LibraryAssert.AreEqual(RecordRefFilterTok, Filter, 'Expression should be converted to filter.');
    end;

    [Test]
    procedure LookupAnyField_NoTable()
    var
        FieldNumber: Integer;
    begin
        // [SCENARIO] Validate that no field is returned when no table is provided

        // [WHEN] RunModalLookupAnyField is called with no table (0)
        FieldNumber := QltyInspectionUtility.RunModalLookupAnyField(0, 0, '');

        // [THEN] No field is returned
        LibraryAssert.AreEqual(0, FieldNumber, 'There should be no field returned.');
    end;

    [Test]
    [HandlerFunctions('LookupFieldsHandler_FirstRec')]
    procedure LookupAnyField_TypeFilter()
    var
        TableAllObjWithCaption: Record AllObjWithCaption;
        ToLoadField: Record Field;
        FieldNumber: Integer;
    begin
        // [SCENARIO] Validate modal field lookup with a field type filter

        // [GIVEN] A table and its first field are retrieved
        TableAllObjWithCaption.SetRange("Object Type", TableAllObjWithCaption."Object Type"::Table);
        TableAllObjWithCaption.FindFirst();

        ToLoadField.SetRange(TableNo, TableAllObjWithCaption."Object ID");
        ToLoadField.FindFirst();

        // [WHEN] RunModalLookupAnyField is called with table number and field type
        FieldNumber := QltyInspectionUtility.RunModalLookupAnyField(ToLoadField.TableNo, ToLoadField.Type, '');

        // [THEN] The correct field number is returned
        LibraryAssert.AreEqual(ToLoadField."No.", FieldNumber, 'The field no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupFieldsHandler_FirstRec')]
    procedure LookupAnyField_NameFilter()
    var
        TableAllObjWithCaption: Record AllObjWithCaption;
        ToLoadField: Record Field;
        FieldNumber: Integer;
    begin
        // [SCENARIO] Validate modal field lookup with a field name filter

        // [GIVEN] A table and its first field are retrieved
        TableAllObjWithCaption.SetRange("Object Type", TableAllObjWithCaption."Object Type"::Table);
        TableAllObjWithCaption.FindFirst();

        ToLoadField.SetRange(TableNo, TableAllObjWithCaption."Object ID");
        ToLoadField.FindFirst();

        // [WHEN] RunModalLookupAnyField is called with table number and field name
        FieldNumber := QltyInspectionUtility.RunModalLookupAnyField(ToLoadField.TableNo, -1, ToLoadField.FieldName);

        // [THEN] The correct field number is returned
        LibraryAssert.AreEqual(ToLoadField."No.", FieldNumber, 'The field no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupZoneListHandler_FirstRec')]
    procedure EditZone_LocationAndZoneFilter_FirstRec()
    var
        Location: Record Location;
        Zone: Record Zone;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ZoneToUse: Code[20];
        FoundZone: Boolean;
    begin
        // [SCENARIO] Validate zone lookup with location and zone filters returning first record

        // [GIVEN] A full WMS location is created with zones
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        Zone.SetRange("Location Code", Location.Code);
        Zone.FindFirst();

        ZoneToUse := ZoneTok;

        // [WHEN] AssistEditZone is called with location and zone filter
        FoundZone := QltyInspectionUtility.AssistEditZone(Location.Code, ZoneToUse);

        // [THEN] A zone is found and the zone code matches
        LibraryAssert.IsTrue(FoundZone, 'Should claim found zone.');
        LibraryAssert.AreEqual(Zone.Code, ZoneToUse, 'The zone code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupZoneListHandler_FirstRec')]
    procedure EditZone_ZoneFilter_FirstRec()
    var
        Location: Record Location;
        Zone: Record Zone;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ZoneToUse: Code[20];
        LocationToUse: Code[10];
        FoundZone: Boolean;
    begin
        // [SCENARIO] Validate zone lookup with zone filter only returning first record

        // [GIVEN] A full WMS location is created with zones
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        Zone.SetRange("Location Code", Location.Code);
        Zone.FindFirst();

        ZoneToUse := ZoneTok;

        LocationToUse := '';
        // [WHEN] AssistEditZone is called with no location code and zone filter
        FoundZone := QltyInspectionUtility.AssistEditZone(LocationToUse, ZoneToUse);

        // [THEN] A zone is found and the zone code matches
        LibraryAssert.IsTrue(FoundZone, 'Should claim found zone.');
        LibraryAssert.AreEqual(Zone.Code, ZoneToUse, 'The zone code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupZoneListHandler_FirstRec')]
    procedure EditZone_LocationFilter_FirstRec()
    var
        Location: Record Location;
        Zone: Record Zone;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ZoneToUse: Code[20];
        FoundZone: Boolean;
    begin
        // [SCENARIO] Validate zone lookup with location filter only returning first record

        // [GIVEN] A full WMS location is created with zones
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        Zone.SetRange("Location Code", Location.Code);
        Zone.FindFirst();

        ZoneToUse := '';

        // [WHEN] AssistEditZone is called with location code only
        FoundZone := QltyInspectionUtility.AssistEditZone(Location.Code, ZoneToUse);

        // [THEN] A zone is found and the zone code matches
        LibraryAssert.IsTrue(FoundZone, 'Should claim found zone.');
        LibraryAssert.AreEqual(Zone.Code, ZoneToUse, 'The zone code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupZoneListHandler_FilteredRec')]
    procedure EditZone_LocationAndZoneFilter_FilteredRec()
    var
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ZoneToUse: Code[20];
        FoundZone: Boolean;
    begin
        // [SCENARIO] Validate zone lookup with location and zone filters returning filtered record

        // [GIVEN] A full WMS location is created with zones
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);

        ZoneToUse := ZoneTok;

        // [WHEN] AssistEditZone is called with location and zone filter
        FoundZone := QltyInspectionUtility.AssistEditZone(Location.Code, ZoneToUse);

        // [THEN] A zone is found and the zone code matches the filtered record
        LibraryAssert.IsTrue(FoundZone, 'Should claim found zone.');
        LibraryAssert.AreEqual(ZoneTok, ZoneToUse, 'The zone code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupZoneListHandler_FilteredRec')]
    procedure EditZone_ZoneFilter_FilteredRec()
    var
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ZoneToUse: Code[20];
        LocationToUse: Code[10];
        FoundZone: Boolean;
    begin
        // [SCENARIO] Validate zone lookup with zone filter only returning filtered record

        // [GIVEN] A full WMS location is created with zones
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);

        ZoneToUse := ZoneTok;

        LocationToUse := '';
        // [WHEN] AssistEditZone is called with no location code and zone filter
        FoundZone := QltyInspectionUtility.AssistEditZone(LocationToUse, ZoneToUse);

        // [THEN] A zone is found and the zone code matches the filtered record
        LibraryAssert.IsTrue(FoundZone, 'Should claim found zone.');
        LibraryAssert.AreEqual(ZoneTok, ZoneToUse, 'The zone code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupZoneListHandler_FilteredRec')]
    procedure EditZone_LocationFilter_FilteredRec()
    var
        Location: Record Location;
        Zone: Record Zone;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        ZoneToUse: Code[20];
        FoundZone: Boolean;
    begin
        // [SCENARIO] Validate zone lookup with location filter only returning filtered record

        // [GIVEN] A full WMS location is created with zones
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        Zone.SetRange("Location Code", Location.Code);
        Zone.FindFirst();

        ZoneToUse := '';

        // [WHEN] AssistEditZone is called with location code only
        FoundZone := QltyInspectionUtility.AssistEditZone(Location.Code, ZoneToUse);

        // [THEN] A zone is found and the zone code matches
        LibraryAssert.IsTrue(FoundZone, 'Should claim found zone.');
        LibraryAssert.AreEqual(Zone.Code, ZoneToUse, 'The zone code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupBinListHandler_FirstRec')]
    procedure EditBin_LocationZoneBinFilter_FirstRec()
    var
        Location: Record Location;
        Zone: Record Zone;
        Bin: Record Bin;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        BinToUse: Code[20];
        FoundBin: Boolean;
    begin
        // [SCENARIO] Validate bin lookup with location, zone, and bin filters returning first record

        // [GIVEN] A full WMS location is created with bins
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        Zone.SetRange("Location Code", Location.Code);
        Zone.SetRange(Code, ZoneTok);
        Zone.FindFirst();
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.FindLast();

        BinToUse := Bin.Code;

        // [WHEN] AssistEditBin is called with location, zone, and bin filters
        FoundBin := QltyInspectionUtility.AssistEditBin(Location.Code, Zone.Code, BinToUse);

        // [THEN] A bin is found and the bin code matches the first bin
        Bin.Reset();
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.FindFirst();
        LibraryAssert.IsTrue(FoundBin, 'Should claim found bin.');
        LibraryAssert.AreEqual(Bin.Code, BinToUse, 'The bin code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupBinListHandler_FirstRec')]
    procedure EditBin_LocationFilter_FirstRec()
    var
        Location: Record Location;

        Bin: Record Bin;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        BinToUse: Code[20];
        FoundBin: Boolean;
    begin
        // [SCENARIO] Validate bin lookup with location filter only returning first record

        // [GIVEN] A full WMS location is created with bins
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);

        // [WHEN] AssistEditBin is called with location code only
        FoundBin := QltyInspectionUtility.AssistEditBin(Location.Code, '', BinToUse);

        // [THEN] A bin is found and the bin code matches the first bin
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        LibraryAssert.IsTrue(FoundBin, 'Should claim found bin.');
        LibraryAssert.AreEqual(Bin.Code, BinToUse, 'The bin code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupBinListHandler_FirstRec')]
    procedure EditBin_ZoneFilter_FirstRec()
    var
        Location: Record Location;
        Zone: Record Zone;
        Bin: Record Bin;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        BinToUse: Code[20];
        FoundBin: Boolean;
    begin
        // [SCENARIO] Validate bin lookup with zone filter only returning first record

        // [GIVEN] A full WMS location is created with zones and bins
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        Zone.SetRange(Code, ZoneTok);
        Zone.FindFirst();

        // [WHEN] AssistEditBin is called with zone code only
        FoundBin := QltyInspectionUtility.AssistEditBin('', ZoneTok, BinToUse);

        // [THEN] A bin is found and the bin code matches the first bin
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.FindFirst();
        LibraryAssert.IsTrue(FoundBin, 'Should claim found bin.');
        LibraryAssert.AreEqual(Bin.Code, BinToUse, 'The bin code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupBinListHandler_FirstRec')]
    procedure EditBin_BinFilter_FirstRec()
    var
        Location: Record Location;
        Bin: Record Bin;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        BinToUse: Code[20];
        FoundBin: Boolean;
    begin
        // [SCENARIO] Validate bin lookup with bin filter only returning first record

        // [GIVEN] A full WMS location is created with bins
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        Bin.FindLast();

        BinToUse := Bin.Code;
        // [WHEN] AssistEditBin is called with bin code only
        FoundBin := QltyInspectionUtility.AssistEditBin('', '', BinToUse);

        // [THEN] A bin is found and the bin code matches the first bin
        Bin.FindFirst();
        LibraryAssert.IsTrue(FoundBin, 'Should claim found bin.');
        LibraryAssert.AreEqual(Bin.Code, BinToUse, 'The bin code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupBinListHandler_FilteredRec')]
    procedure EditBin_LocationZoneBinFilter_FilteredRec()
    var
        Location: Record Location;
        Zone: Record Zone;
        Bin: Record Bin;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        BinToUse: Code[20];
        FoundBin: Boolean;
    begin
        // [SCENARIO] Validate bin lookup with location, zone, and bin filters returning filtered record

        // [GIVEN] A full WMS location is created with bins
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        Zone.SetRange("Location Code", Location.Code);
        Zone.SetRange(Code, ZoneTok);
        Zone.FindFirst();
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.FindLast();

        BinToUse := Bin.Code;

        // [WHEN] AssistEditBin is called with location, zone, and bin filters
        FoundBin := QltyInspectionUtility.AssistEditBin(Location.Code, Zone.Code, BinToUse);

        // [THEN] A bin is found and the bin code matches the filtered record
        LibraryAssert.IsTrue(FoundBin, 'Should claim found bin.');
        LibraryAssert.AreEqual(Bin.Code, BinToUse, 'The bin code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupBinListHandler_FilteredRec')]
    procedure EditBin_LocationFilter_FilteredRec()
    var
        Location: Record Location;

        Bin: Record Bin;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        BinToUse: Code[20];
        FoundBin: Boolean;
    begin
        // [SCENARIO] Validate bin lookup with location filter only returning filtered record

        // [GIVEN] A full WMS location is created with bins
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);

        // [WHEN] AssistEditBin is called with location code only
        FoundBin := QltyInspectionUtility.AssistEditBin(Location.Code, '', BinToUse);

        // [THEN] A bin is found and the bin code matches the first bin
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        LibraryAssert.IsTrue(FoundBin, 'Should claim found bin.');
        LibraryAssert.AreEqual(Bin.Code, BinToUse, 'The bin code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupBinListHandler_FilteredRec')]
    procedure EditBin_ZoneFilter_FilteredRec()
    var
        Location: Record Location;
        Zone: Record Zone;
        Bin: Record Bin;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        BinToUse: Code[20];
        FoundBin: Boolean;
    begin
        // [SCENARIO] Validate bin lookup with zone filter only returning filtered record

        // [GIVEN] A full WMS location is created with zones and bins
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        Zone.SetRange(Code, ZoneTok);
        Zone.FindFirst();

        // [WHEN] AssistEditBin is called with zone code only
        FoundBin := QltyInspectionUtility.AssistEditBin('', ZoneTok, BinToUse);

        // [THEN] A bin is found and the bin code matches the first bin
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.FindFirst();
        LibraryAssert.IsTrue(FoundBin, 'Should claim found bin.');
        LibraryAssert.AreEqual(Bin.Code, BinToUse, 'The bin code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupBinListHandler_FilteredRec')]
    procedure EditBin_BinFilter_FilteredRec()
    var
        Location: Record Location;
        Bin: Record Bin;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        BinToUse: Code[20];
        FoundBin: Boolean;
    begin
        // [SCENARIO] Validate bin lookup with bin filter only returning filtered record

        // [GIVEN] A full WMS location is created with bins
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        Bin.FindLast();

        BinToUse := Bin.Code;
        // [WHEN] AssistEditBin is called with bin code only
        FoundBin := QltyInspectionUtility.AssistEditBin('', '', BinToUse);

        // [THEN] A bin is found and the bin code matches the filtered bin
        LibraryAssert.IsTrue(FoundBin, 'Should claim found bin.');
        LibraryAssert.AreEqual(Bin.Code, BinToUse, 'The bin code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupItemListHandler_FirstRec')]
    procedure EditItemNo_NoFilter_FirstRec()
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        ItemToUse: Code[20];
        FoundItem: Boolean;
    begin
        // [SCENARIO] Validate item lookup without a filter returning first record

        // [GIVEN] An item is created if none exist
        if not Item.FindFirst() then
            LibraryInventory.CreateItem(Item);

        // [WHEN] AssistEditItemNo is called with no filter
        FoundItem := QltyInspectionUtility.AssistEditItemNo(ItemToUse);

        // [THEN] An item is found and the item number matches
        LibraryAssert.IsTrue(FoundItem, 'Should claim found item.');
        LibraryAssert.AreEqual(Item."No.", ItemToUse, 'The item no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupItemListHandler_FirstRec')]
    procedure EditItemNo_ItemFilter_FirstRec()
    var
        Item: Record Item;
        SecondItem: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        ItemToUse: Code[20];
        FoundItem: Boolean;
    begin
        // [SCENARIO] Validate item lookup with item filter returning first record

        // [GIVEN] Two items are created
        if not Item.FindFirst() then
            LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(SecondItem);

        ItemToUse := SecondItem."No.";
        // [WHEN] AssistEditItemNo is called with item filter
        FoundItem := QltyInspectionUtility.AssistEditItemNo(ItemToUse);

        // [THEN] An item is found and the item number matches the first item
        LibraryAssert.IsTrue(FoundItem, 'Should claim found item.');
        LibraryAssert.AreEqual(Item."No.", ItemToUse, 'The item no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupItemListHandler_FilteredRec')]
    procedure EditItemNo_NoFilter_FilteredRec()
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        ItemToUse: Code[20];
        FoundItem: Boolean;
    begin
        // [SCENARIO] Validate item lookup without filter returning filtered record

        // [GIVEN] An item is created if none exist
        if not Item.FindFirst() then
            LibraryInventory.CreateItem(Item);

        // [WHEN] AssistEditItemNo is called with no filter
        FoundItem := QltyInspectionUtility.AssistEditItemNo(ItemToUse);

        // [THEN] An item is found and the item number matches
        LibraryAssert.IsTrue(FoundItem, 'Should claim found item.');
        LibraryAssert.AreEqual(Item."No.", ItemToUse, 'The item no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupItemListHandler_FilteredRec')]
    procedure EditItemNo_ItemFilter_FilteredRec()
    var
        Item: Record Item;
        SecondItem: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        ItemToUse: Code[20];
        FoundItem: Boolean;
    begin
        // [SCENARIO] Validate item lookup with item filter returning filtered record

        // [GIVEN] Two items are created
        if not Item.FindFirst() then
            LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(SecondItem);

        ItemToUse := SecondItem."No.";
        // [WHEN] AssistEditItemNo is called with item filter
        FoundItem := QltyInspectionUtility.AssistEditItemNo(ItemToUse);

        // [THEN] An item is found and the item number matches the second item
        LibraryAssert.IsTrue(FoundItem, 'Should claim found item.');
        LibraryAssert.AreEqual(SecondItem."No.", ItemToUse, 'The item no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupItemCategoriesHandler_FirstRec')]
    procedure EditItemCategory_NoFilter_FirstRec()
    var
        ItemCategory: Record "Item Category";
        LibraryInventory: Codeunit "Library - Inventory";
        ItemToUseCategoryToUse: Code[20];
        FoundItemCategory: Boolean;
    begin
        // [SCENARIO] Validate item category lookup without filter returning first record

        // [GIVEN] An item category is created if none exist
        if not ItemCategory.FindFirst() then
            LibraryInventory.CreateItemCategory(ItemCategory);

        // [WHEN] AssistEditItemCategory is called with no filter
        FoundItemCategory := QltyInspectionUtility.AssistEditItemCategory(ItemToUseCategoryToUse);

        // [THEN] An item category is found and the category code matches
        ItemCategory.SetRange("Parent Category", '');
        ItemCategory.FindFirst();
        LibraryAssert.IsTrue(FoundItemCategory, 'Should claim found item.');
        LibraryAssert.AreEqual(ItemCategory.Code, ItemToUseCategoryToUse, 'The item category should match.');
    end;

    [Test]
    [HandlerFunctions('LookupItemCategoriesHandler_FirstRec')]
    procedure EditItemCategory_CategoryFilter_FirstRec()
    var
        ItemCategory: Record "Item Category";
        SecondItemCategory: Record "Item Category";
        LibraryInventory: Codeunit "Library - Inventory";
        ItemToUseCategoryToUse: Code[20];
        FoundItemCategory: Boolean;
    begin
        // [SCENARIO] Validate item category lookup with category filter returning first record

        // [GIVEN] Two item categories are created
        if not ItemCategory.FindFirst() then
            LibraryInventory.CreateItemCategory(ItemCategory);
        LibraryInventory.CreateItemCategory(SecondItemCategory);

        ItemToUseCategoryToUse := SecondItemCategory.Code;
        // [WHEN] AssistEditItemCategory is called with category filter
        FoundItemCategory := QltyInspectionUtility.AssistEditItemCategory(ItemToUseCategoryToUse);

        // [THEN] An item category is found and the category code matches the first category
        ItemCategory.SetRange("Parent Category", '');
        ItemCategory.FindFirst();
        LibraryAssert.IsTrue(FoundItemCategory, 'Should claim found item.');
        LibraryAssert.AreEqual(ItemCategory.Code, ItemToUseCategoryToUse, 'The item category should match.');
    end;

    [Test]
    [HandlerFunctions('LookupItemCategoriesHandler_FilteredRec')]
    procedure EditItemCategory_NoFilter_FilteredRec()
    var
        ItemCategory: Record "Item Category";
        LibraryInventory: Codeunit "Library - Inventory";
        ItemToUseCategoryToUse: Code[20];
        FoundItemCategory: Boolean;
    begin
        // [SCENARIO] Validate item category lookup without filter returning filtered record

        // [GIVEN] An item category is created if none exist
        if not ItemCategory.FindFirst() then
            LibraryInventory.CreateItemCategory(ItemCategory);

        // [WHEN] AssistEditItemCategory is called with no filter
        FoundItemCategory := QltyInspectionUtility.AssistEditItemCategory(ItemToUseCategoryToUse);

        // [THEN] An item category is found and the category code matches
        ItemCategory.SetRange("Parent Category", '');
        ItemCategory.FindFirst();
        LibraryAssert.IsTrue(FoundItemCategory, 'Should claim found item.');
        LibraryAssert.AreEqual(ItemCategory.Code, ItemToUseCategoryToUse, 'The item category should match.');
    end;

    [Test]
    [HandlerFunctions('LookupItemCategoriesHandler_FilteredRec')]
    procedure EditItemCategory_CategoryFilter_FilteredRec()
    var
        ItemCategory: Record "Item Category";
        SecondItemCategory: Record "Item Category";
        LibraryInventory: Codeunit "Library - Inventory";
        ItemToUseCategoryToUse: Code[20];
        FoundItemCategory: Boolean;
    begin
        // [SCENARIO] Validate item category lookup with category filter returning filtered record

        // [GIVEN] Two item categories are created
        if not ItemCategory.FindFirst() then
            LibraryInventory.CreateItemCategory(ItemCategory);
        LibraryInventory.CreateItemCategory(SecondItemCategory);

        ItemToUseCategoryToUse := SecondItemCategory.Code;
        // [WHEN] AssistEditItemCategory is called with category filter
        FoundItemCategory := QltyInspectionUtility.AssistEditItemCategory(ItemToUseCategoryToUse);

        // [THEN] An item category is found and the category code matches the second category
        LibraryAssert.IsTrue(FoundItemCategory, 'Should claim found item.');
        LibraryAssert.AreEqual(SecondItemCategory.Code, ItemToUseCategoryToUse, 'The item category should match.');
    end;

    [Test]
    [HandlerFunctions('LookupInventoryPostingGroupsHandler_FirstRec')]
    procedure EditInventoryPostingGroups_NoFilter_FirstRec()
    var
        InvInventoryPostingGroup: Record "Inventory Posting Group";
        LibraryInventory: Codeunit "Library - Inventory";
        InvPostingGroup: Code[20];
        FoundInvPostingGroup: Boolean;
    begin
        // [SCENARIO] Validate inventory posting group lookup without filter returning first record

        // [GIVEN] An inventory posting group is created if none exist
        if not InvInventoryPostingGroup.FindFirst() then
            LibraryInventory.CreateInventoryPostingGroup(InvInventoryPostingGroup);

        // [WHEN] AssistEditInventoryPostingGroup is called with no filter
        FoundInvPostingGroup := QltyInspectionUtility.AssistEditInventoryPostingGroup(InvPostingGroup);

        // [THEN] An inventory posting group is found and the code matches
        LibraryAssert.IsTrue(FoundInvPostingGroup, 'Should claim found inventory posting group.');
        LibraryAssert.AreEqual(InvInventoryPostingGroup.Code, InvPostingGroup, 'The inventory posting group code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupInventoryPostingGroupsHandler_FirstRec')]
    procedure EditInventoryPostingGroups_GroupFilter_FirstRec()
    var
        InvInventoryPostingGroup: Record "Inventory Posting Group";
        InvSecondInventoryPostingGroup: Record "Inventory Posting Group";
        LibraryInventory: Codeunit "Library - Inventory";
        InvPostingGroup: Code[20];
        FoundInvPostingGroup: Boolean;
    begin
        // [SCENARIO] Validate inventory posting group lookup with group filter returning first record

        // [GIVEN] Two inventory posting groups are created
        if not InvInventoryPostingGroup.FindFirst() then
            LibraryInventory.CreateInventoryPostingGroup(InvInventoryPostingGroup);
        LibraryInventory.CreateInventoryPostingGroup(InvSecondInventoryPostingGroup);

        InvPostingGroup := InvSecondInventoryPostingGroup.Code;
        // [WHEN] AssistEditInventoryPostingGroup is called with group filter
        FoundInvPostingGroup := QltyInspectionUtility.AssistEditInventoryPostingGroup(InvPostingGroup);

        // [THEN] An inventory posting group is found and the code matches the first group
        LibraryAssert.IsTrue(FoundInvPostingGroup, 'Should claim found inventory posting group.');
        LibraryAssert.AreEqual(InvInventoryPostingGroup.Code, InvPostingGroup, 'The inventory posting group code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupInventoryPostingGroupsHandler_FilteredRec')]
    procedure EditInventoryPostingGroups_NoFilter_FilteredRec()
    var
        InvInventoryPostingGroup: Record "Inventory Posting Group";
        LibraryInventory: Codeunit "Library - Inventory";
        InvPostingGroup: Code[20];
        FoundInvPostingGroup: Boolean;
    begin
        // [SCENARIO] Validate inventory posting group lookup without filter returning filtered record

        // [GIVEN] An inventory posting group is created if none exist
        if not InvInventoryPostingGroup.FindFirst() then
            LibraryInventory.CreateInventoryPostingGroup(InvInventoryPostingGroup);

        // [WHEN] AssistEditInventoryPostingGroup is called with no filter
        FoundInvPostingGroup := QltyInspectionUtility.AssistEditInventoryPostingGroup(InvPostingGroup);

        // [THEN] An inventory posting group is found and the code matches
        LibraryAssert.IsTrue(FoundInvPostingGroup, 'Should claim found inventory posting group.');
        LibraryAssert.AreEqual(InvInventoryPostingGroup.Code, InvPostingGroup, 'The inventory posting group code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupInventoryPostingGroupsHandler_FilteredRec')]
    procedure EditInventoryPostingGroups_GroupFilter_FilteredRec()
    var
        InvInventoryPostingGroup: Record "Inventory Posting Group";
        InvSecondInventoryPostingGroup: Record "Inventory Posting Group";
        LibraryInventory: Codeunit "Library - Inventory";
        InvPostingGroup: Code[20];
        FoundInvPostingGroup: Boolean;
    begin
        // [SCENARIO] Validate inventory posting group lookup with group filter returning filtered record

        // [GIVEN] Two inventory posting groups are created
        if not InvInventoryPostingGroup.FindFirst() then
            LibraryInventory.CreateInventoryPostingGroup(InvInventoryPostingGroup);
        LibraryInventory.CreateInventoryPostingGroup(InvSecondInventoryPostingGroup);

        InvPostingGroup := InvSecondInventoryPostingGroup.Code;
        // [WHEN] AssistEditInventoryPostingGroup is called with group filter
        FoundInvPostingGroup := QltyInspectionUtility.AssistEditInventoryPostingGroup(InvPostingGroup);

        // [THEN] An inventory posting group is found and the code matches the second group
        LibraryAssert.IsTrue(FoundInvPostingGroup, 'Should claim found inventory posting group.');
        LibraryAssert.AreEqual(InvSecondInventoryPostingGroup.Code, InvPostingGroup, 'The inventory posting group code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupVendorListHandler_FirstRec')]
    procedure EditVendor_NoFilter_FirstRec()
    var
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
        VendorToUse: Code[20];
        FoundVendor: Boolean;
    begin
        // [SCENARIO] Validate vendor lookup without filter returning first record

        // [GIVEN] A vendor is created if none exist
        if not Vendor.FindFirst() then
            LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] AssistEditVendor is called with no filter
        FoundVendor := QltyInspectionUtility.AssistEditVendor(VendorToUse);

        // [THEN] A vendor is found and the vendor number matches
        LibraryAssert.IsTrue(FoundVendor, 'Should claim found vendor.');
        LibraryAssert.AreEqual(Vendor."No.", VendorToUse, 'The vendor no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupVendorListHandler_FirstRec')]
    procedure EditVendor_VendorFilter()
    var
        Vendor: Record Vendor;
        SecondVendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
        VendorToUse: Code[20];
        FoundVendor: Boolean;
    begin
        // [SCENARIO] Validate vendor lookup with vendor filter returning first record

        // [GIVEN] Two vendors are created
        if not Vendor.FindFirst() then
            LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendor(SecondVendor);

        VendorToUse := SecondVendor."No.";
        // [WHEN] AssistEditVendor is called with vendor filter
        FoundVendor := QltyInspectionUtility.AssistEditVendor(VendorToUse);

        // [THEN] A vendor is found and the vendor number matches the first vendor
        LibraryAssert.IsTrue(FoundVendor, 'Should claim found vendor.');
        LibraryAssert.AreEqual(Vendor."No.", VendorToUse, 'The vendor no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupVendorListHandler_FilteredRec')]
    procedure EditVendor_NoFilter_FilteredRec()
    var
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
        VendorToUse: Code[20];
        FoundVendor: Boolean;
    begin
        // [SCENARIO] Validate vendor lookup without filter returning filtered record

        // [GIVEN] A vendor is created if none exist
        if not Vendor.FindFirst() then
            LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] AssistEditVendor is called with no filter
        FoundVendor := QltyInspectionUtility.AssistEditVendor(VendorToUse);

        // [THEN] A vendor is found and the vendor number matches
        LibraryAssert.IsTrue(FoundVendor, 'Should claim found vendor.');
        LibraryAssert.AreEqual(Vendor."No.", VendorToUse, 'The vendor no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupVendorListHandler_FilteredRec')]
    procedure EditVendor_VendorFilter_FilteredRec()
    var
        Vendor: Record Vendor;
        SecondVendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
        VendorToUse: Code[20];
        FoundVendor: Boolean;
    begin
        // [SCENARIO] Validate vendor lookup with vendor filter returning filtered record

        // [GIVEN] Two vendors are created
        if not Vendor.FindFirst() then
            LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendor(SecondVendor);

        VendorToUse := SecondVendor."No.";
        // [WHEN] AssistEditVendor is called with vendor filter
        FoundVendor := QltyInspectionUtility.AssistEditVendor(VendorToUse);

        // [THEN] A vendor is found and the vendor number matches the second vendor
        LibraryAssert.IsTrue(FoundVendor, 'Should claim found vendor.');
        LibraryAssert.AreEqual(SecondVendor."No.", VendorToUse, 'The vendor no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupCustomerListHandler_FirstRec')]
    procedure EditCustomer_NoFilter_FirstRec()
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        CustomerToUse: Code[20];
        FoundCustomer: Boolean;
    begin
        // [SCENARIO] Validate customer lookup without filter returning first record

        // [GIVEN] A customer is created if none exist
        if not Customer.FindFirst() then
            LibrarySales.CreateCustomer(Customer);

        // [WHEN] AssistEditCustomer is called with no filter
        FoundCustomer := QltyInspectionUtility.AssistEditCustomer(CustomerToUse);

        // [THEN] A customer is found and the customer number matches
        LibraryAssert.IsTrue(FoundCustomer, 'Should claim found customer.');
        LibraryAssert.AreEqual(Customer."No.", CustomerToUse, 'The customer no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupCustomerListHandler_FirstRec')]
    procedure EditCustomer_CustomerFilter_FirstRec()
    var
        Customer: Record Customer;
        SecondCustomer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        CustomerToUse: Code[20];
        FoundCustomer: Boolean;
    begin
        // [SCENARIO] Validate customer lookup with customer filter returning first record

        // [GIVEN] Two customers are created
        if not Customer.FindFirst() then
            LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(SecondCustomer);

        CustomerToUse := Customer."No.";
        // [WHEN] AssistEditCustomer is called with customer filter
        FoundCustomer := QltyInspectionUtility.AssistEditCustomer(CustomerToUse);

        // [THEN] A customer is found and the customer number matches the first customer
        LibraryAssert.IsTrue(FoundCustomer, 'Should claim found customer.');
        LibraryAssert.AreEqual(Customer."No.", CustomerToUse, 'The customer no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupCustomerListHandler_FilteredRec')]
    procedure EditCustomer_NoFilter_FilteredRec()
    var
        Customer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        CustomerToUse: Code[20];
        FoundCustomer: Boolean;
    begin
        // [SCENARIO] Validate customer lookup without filter returning filtered record

        // [GIVEN] A customer is created if none exist
        if not Customer.FindFirst() then
            LibrarySales.CreateCustomer(Customer);

        // [WHEN] AssistEditCustomer is called with no filter
        FoundCustomer := QltyInspectionUtility.AssistEditCustomer(CustomerToUse);

        // [THEN] A customer is found and the customer number matches
        LibraryAssert.IsTrue(FoundCustomer, 'Should claim found customer.');
        LibraryAssert.AreEqual(Customer."No.", CustomerToUse, 'The customer no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupCustomerListHandler_FilteredRec')]
    procedure EditCustomer_CustomerFilter_FilteredRec()
    var
        Customer: Record Customer;
        SecondCustomer: Record Customer;
        LibrarySales: Codeunit "Library - Sales";
        CustomerToUse: Code[20];
        FoundCustomer: Boolean;
    begin
        // [SCENARIO] Validate customer lookup with customer filter returning filtered record

        // [GIVEN] Two customers are created
        if not Customer.FindFirst() then
            LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(SecondCustomer);

        CustomerToUse := SecondCustomer."No.";
        // [WHEN] AssistEditCustomer is called with customer filter
        FoundCustomer := QltyInspectionUtility.AssistEditCustomer(CustomerToUse);

        // [THEN] A customer is found and the customer number matches the second customer
        LibraryAssert.IsTrue(FoundCustomer, 'Should claim found customer.');
        LibraryAssert.AreEqual(SecondCustomer."No.", CustomerToUse, 'The customer no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupMachineCenterListHandler')]
    procedure EditMachine_NoFilter()
    var
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        Machine: Code[20];
        FoundMachine: Boolean;
    begin
        // [SCENARIO] Validate machine center lookup without filter

        // [GIVEN] A machine center is created if none exist
        if not MachineCenter.FindFirst() then begin
            if not WorkCenter.FindFirst() then
                LibraryManufacturing.CreateWorkCenter(WorkCenter);
            LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", 1);
        end;

        // [WHEN] AssistEditMachine is called with no filter
        FoundMachine := QltyInspectionUtility.AssistEditMachine(Machine);

        // [THEN] A machine is found and the machine number matches
        LibraryAssert.IsTrue(FoundMachine, 'Should claim found machine.');
        LibraryAssert.AreEqual(MachineCenter."No.", Machine, 'The machine no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupMachineCenterListHandler')]
    procedure EditMachine_MachineFilter()
    var
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        Machine: Code[20];
        FoundMachine: Boolean;
    begin
        // [SCENARIO] Validate machine center lookup with machine filter

        // [GIVEN] A machine center is created if none exist
        if not MachineCenter.FindFirst() then begin
            if not WorkCenter.FindFirst() then
                LibraryManufacturing.CreateWorkCenter(WorkCenter);
            LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", 1);
        end;

        Machine := MachineCenter."No.";
        // [WHEN] AssistEditMachine is called with machine filter
        FoundMachine := QltyInspectionUtility.AssistEditMachine(Machine);

        // [THEN] A machine is found and the machine number matches
        LibraryAssert.IsTrue(FoundMachine, 'Should claim found machine.');
        LibraryAssert.AreEqual(MachineCenter."No.", Machine, 'The machine no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupRoutingListHandler')]
    procedure EditRouting_NoFilter()
    var
        RoutingHeader: Record "Routing Header";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        Routing: Code[20];
        FoundRouting: Boolean;
    begin
        // [SCENARIO] Validate routing lookup without filter

        // [GIVEN] A routing header is created if none exist
        if not RoutingHeader.FindFirst() then
            LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // [WHEN] AssistEditRouting is called with no filter
        FoundRouting := QltyInspectionUtility.AssistEditRouting(Routing);

        // [THEN] A routing is found and the routing number matches
        LibraryAssert.IsTrue(FoundRouting, 'Should claim found routing.');
        LibraryAssert.AreEqual(RoutingHeader."No.", Routing, 'The routing no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupRoutingListHandler')]
    procedure EditRouting_RoutingFilter()
    var
        RoutingHeader: Record "Routing Header";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        Routing: Code[20];
        FoundRouting: Boolean;
    begin
        // [SCENARIO] Validate routing lookup with routing filter

        // [GIVEN] A routing header is created if none exist
        if not RoutingHeader.FindFirst() then
            LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        Routing := RoutingHeader."No.";
        // [WHEN] AssistEditRouting is called with routing filter
        FoundRouting := QltyInspectionUtility.AssistEditRouting(Routing);

        // [THEN] A routing is found and the routing number matches
        LibraryAssert.IsTrue(FoundRouting, 'Should claim found routing.');
        LibraryAssert.AreEqual(RoutingHeader."No.", Routing, 'The routing no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupQltyRoutingLineHandler')]
    procedure EditRoutingOperation_RoutingAndOperationFilter()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingVersion: Record "Routing Version";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        Version: Code[20];
        OperationNo: Code[10];
        OperationNo2: Code[20];
        No: Code[20];
        FoundRoutingOperation: Boolean;
    begin
        // [SCENARIO] Validate routing operation lookup with routing and operation number filters

        // [GIVEN] A routing header and routing line are created if none exist
        if not RoutingHeader.FindFirst() then
            LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        if not RoutingLine.FindFirst() then begin
            Version := LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Version Code"), Database::"Routing Line");
            LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingHeader."No.", Version);
            No := LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("No."), Database::"Routing Line");
            OperationNo := '';
            LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, Version, OperationNo, Enum::"Capacity Type Routing"::" ", No);
        end;
        OperationNo2 := RoutingLine."Operation No.";
        // [WHEN] AssistEditRoutingOperation is called with routing and operation number filters
        FoundRoutingOperation := QltyInspectionUtility.AssistEditRoutingOperation(RoutingHeader."No.", OperationNo2);

        // [THEN] A routing operation is found and the operation number matches
        LibraryAssert.IsTrue(FoundRoutingOperation, 'Should claim found routing operation.');
        LibraryAssert.AreEqual(RoutingLine."Operation No.", OperationNo2, 'The routing operation no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupQltyRoutingLineHandler')]
    procedure EditRoutingOperation_RoutingFilter()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingVersion: Record "Routing Version";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        Version: Code[20];
        OperationNo: Code[10];
        OperationNo2: Code[20];
        No: Code[20];
        FoundRoutingOperation: Boolean;
    begin
        // [SCENARIO] Validate routing operation lookup with routing filter

        // [GIVEN] A routing header and routing line are created if none exist
        if not RoutingHeader.FindFirst() then
            LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        if not RoutingLine.FindFirst() then begin
            Version := LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Version Code"), Database::"Routing Line");
            LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingHeader."No.", Version);
            No := LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("No."), Database::"Routing Line");
            OperationNo := '';
            LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, Version, OperationNo, Enum::"Capacity Type Routing"::" ", No);
        end;
        // [WHEN] AssistEditRoutingOperation is called with routing filter
        FoundRoutingOperation := QltyInspectionUtility.AssistEditRoutingOperation(RoutingHeader."No.", OperationNo2);

        // [THEN] A routing operation is found and the operation number matches
        LibraryAssert.IsTrue(FoundRoutingOperation, 'Should claim found routing operation.');
        LibraryAssert.AreEqual(RoutingLine."Operation No.", OperationNo2, 'The routing operation no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupQltyRoutingLineHandler')]
    procedure EditRoutingOperation_OperationFilter()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingVersion: Record "Routing Version";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        Version: Code[20];
        OperationNo: Code[10];
        OperationNo2: Code[20];
        No: Code[20];
        FoundRoutingOperation: Boolean;
    begin
        // [SCENARIO] Validate routing operation lookup with operation filter

        // [GIVEN] A routing header and routing line are created if none exist
        if not RoutingHeader.FindFirst() then
            LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        if not RoutingLine.FindFirst() then begin
            Version := LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Version Code"), Database::"Routing Line");
            LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingHeader."No.", Version);
            No := LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("No."), Database::"Routing Line");
            OperationNo := '';
            LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, Version, OperationNo, Enum::"Capacity Type Routing"::" ", No);
        end;
        OperationNo2 := OperationNo;
        // [WHEN] AssistEditRoutingOperation is called with operation filter
        FoundRoutingOperation := QltyInspectionUtility.AssistEditRoutingOperation('', OperationNo2);

        // [THEN] A routing operation is found and the operation number matches
        LibraryAssert.IsTrue(FoundRoutingOperation, 'Should claim found routing operation.');
        LibraryAssert.AreEqual(RoutingLine."Operation No.", OperationNo2, 'The routing operation no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupQltyRoutingLineHandler')]
    procedure EditRoutingOperation_NoFilter()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingVersion: Record "Routing Version";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        Version: Code[20];
        OperationNo: Code[10];
        OperationNo2: Code[20];
        No: Code[20];
        FoundRoutingOperation: Boolean;
    begin
        // [SCENARIO] Validate routing operation lookup without filter

        // [GIVEN] A routing header and routing line are created if none exist
        if not RoutingHeader.FindFirst() then
            LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        if not RoutingLine.FindFirst() then begin
            Version := LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Version Code"), Database::"Routing Line");
            LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingHeader."No.", Version);
            No := LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("No."), Database::"Routing Line");
            OperationNo := '';
            LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, Version, OperationNo, Enum::"Capacity Type Routing"::" ", No);
        end;
        // [WHEN] AssistEditRoutingOperation is called with no filter
        FoundRoutingOperation := QltyInspectionUtility.AssistEditRoutingOperation('', OperationNo2);

        // [THEN] A routing operation is found and the operation number matches the first routing line
        RoutingLine.Reset();
        RoutingLine.FindFirst();
        LibraryAssert.IsTrue(FoundRoutingOperation, 'Should claim found routing operation.');
        LibraryAssert.AreEqual(RoutingLine."Operation No.", OperationNo2, 'The routing operation no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupWorkCenterListHandler')]
    procedure EditWorkCenter_NoFilter()
    var
        WorkCenter: Record "Work Center";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        WorkCenterToUse: Code[20];
        FoundWorkCenter: Boolean;
    begin
        // [SCENARIO] Validate work center lookup without filter

        // [GIVEN] A work center is created if none exist
        if not WorkCenter.FindFirst() then
            LibraryManufacturing.CreateWorkCenter(WorkCenter);

        // [WHEN] AssistEditWorkCenter is called with no filter
        FoundWorkCenter := QltyInspectionUtility.AssistEditWorkCenter(WorkCenterToUse);

        // [THEN] A work center is found and the work center number matches
        LibraryAssert.IsTrue(FoundWorkCenter, 'Should claim found work center.');
        LibraryAssert.AreEqual(WorkCenter."No.", WorkCenterToUse, 'The work center no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupWorkCenterListHandler')]
    procedure EditWorkCenter_WorkCenterFilter()
    var
        WorkCenter: Record "Work Center";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        WorkCenterToUse: Code[20];
        FoundWorkCenter: Boolean;
    begin
        // [SCENARIO] Validate work center lookup with work center filter

        // [GIVEN] A work center is created if none exist
        if not WorkCenter.FindFirst() then
            LibraryManufacturing.CreateWorkCenter(WorkCenter);

        WorkCenterToUse := WorkCenter."No.";
        // [WHEN] AssistEditWorkCenter is called with work center filter
        FoundWorkCenter := QltyInspectionUtility.AssistEditWorkCenter(WorkCenterToUse);

        // [THEN] A work center is found and the work center number matches
        LibraryAssert.IsTrue(FoundWorkCenter, 'Should claim found work center.');
        LibraryAssert.AreEqual(WorkCenter."No.", WorkCenterToUse, 'The work center no. should match.');
    end;

    [Test]
    [HandlerFunctions('LookupPurchasingCodesHandler')]
    procedure EditPurchasingCodes_NoFilter()
    var
        Purchasing: Record Purchasing;
        LibraryPurchase: Codeunit "Library - Purchase";
        PurchasingToUse: Code[20];
        FoundPurchasing: Boolean;
    begin
        // [SCENARIO] Validate purchasing code lookup without filter

        // [GIVEN] A purchasing code is created if none exist
        if not Purchasing.FindFirst() then
            LibraryPurchase.CreatePurchasingCode(Purchasing);

        // [WHEN] AssistEditPurchasingCode is called with no filter
        FoundPurchasing := QltyInspectionUtility.AssistEditPurchasingCode(PurchasingToUse);

        // [THEN] A purchasing code is found and the code matches
        LibraryAssert.IsTrue(FoundPurchasing, 'Should claim found purchasing code.');
        LibraryAssert.AreEqual(Purchasing.Code, PurchasingToUse, 'The purchasing code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupPurchasingCodesHandler')]
    procedure EditPurchasingCodes_PurchasingCodeFilter()
    var
        Purchasing: Record Purchasing;
        LibraryPurchase: Codeunit "Library - Purchase";
        PurchasingToUse: Code[20];
        FoundPurchasing: Boolean;
    begin
        // [SCENARIO] Validate purchasing code lookup with purchasing code filter

        // [GIVEN] A purchasing code is created if none exist
        if not Purchasing.FindFirst() then
            LibraryPurchase.CreatePurchasingCode(Purchasing);

        PurchasingToUse := Purchasing.Code;
        // [WHEN] AssistEditPurchasingCode is called with purchasing code filter
        FoundPurchasing := QltyInspectionUtility.AssistEditPurchasingCode(PurchasingToUse);

        // [THEN] A purchasing code is found and the code matches
        LibraryAssert.IsTrue(FoundPurchasing, 'Should claim found purchasing code.');
        LibraryAssert.AreEqual(Purchasing.Code, PurchasingToUse, 'The purchasing code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupReturnReasonsHandler')]
    procedure EditReturnReasons_NoFilter()
    var
        ReturnReason: Record "Return Reason";
        LibraryUtility: Codeunit "Library - Utility";
        ReturnReasonToUse: Code[20];
        FoundReturnReason: Boolean;
    begin
        // [SCENARIO] Validate return reason code lookup without filter

        // [GIVEN] A return reason is created if none exist
        if not ReturnReason.FindFirst() then begin
            ReturnReason.Init();
            ReturnReason.Code := LibraryUtility.GenerateRandomCode(1, Database::"Reason Code");
            ReturnReason.Description := CopyStr(LibraryUtility.GenerateRandomText(25), 1, MaxStrLen(ReturnReason.Description));
            ReturnReason.Insert();
        end;

        // [WHEN] AssistEditReturnReasonCode is called with no filter
        FoundReturnReason := QltyInspectionUtility.AssistEditReturnReasonCode(ReturnReasonToUse);

        // [THEN] A return reason code is found and the code matches
        LibraryAssert.IsTrue(FoundReturnReason, 'Should claim found return reason code.');
        LibraryAssert.AreEqual(ReturnReason.Code, ReturnReasonToUse, 'The return reason code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupReturnReasonsHandler')]
    procedure EditReturnReasons_ReturnReasonCodeFilter()
    var
        ReturnReason: Record "Return Reason";
        LibraryUtility: Codeunit "Library - Utility";
        ReturnReasonToUse: Code[20];
        FoundReturnReason: Boolean;
    begin
        // [SCENARIO] Validate return reason code lookup with return reason code filter

        // [GIVEN] A return reason is created if none exist
        if not ReturnReason.FindFirst() then begin
            ReturnReason.Init();
            ReturnReason.Code := LibraryUtility.GenerateRandomCode(1, Database::"Reason Code");
            ReturnReason.Description := CopyStr(LibraryUtility.GenerateRandomText(25), 1, MaxStrLen(ReturnReason.Description));
            ReturnReason.Insert();
        end;

        ReturnReasonToUse := ReturnReason.Code;
        // [WHEN] AssistEditReturnReasonCode is called with return reason code filter
        FoundReturnReason := QltyInspectionUtility.AssistEditReturnReasonCode(ReturnReasonToUse);

        // [THEN] A return reason code is found and the code matches
        LibraryAssert.IsTrue(FoundReturnReason, 'Should claim found return reason code.');
        LibraryAssert.AreEqual(ReturnReason.Code, ReturnReasonToUse, 'The return reason code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupQltyInspectionTemplateListHandler')]
    procedure EditQltyInspectionTemplate_NoFilter()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Template: Code[20];
        FoundTemplate: Boolean;
    begin
        // [SCENARIO] Validate quality inspection template lookup without filter

        // [GIVEN] A quality inspection template is created if none exist
        if not QltyInspectionTemplateHdr.FindFirst() then
            QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);

        // [WHEN] AssistEditQltyInspectionTemplate is called with no filter
        FoundTemplate := QltyInspectionUtility.AssistEditQltyInspectionTemplate(Template);

        // [THEN] A template code is found and matches the template
        LibraryAssert.IsTrue(FoundTemplate, 'Should claim found template code.');
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, Template, 'The template code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupQltyInspectionTemplateListHandler')]
    procedure EditQltyInspectionTemplate_TemplateFilter()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Template: Code[20];
        FoundTemplate: Boolean;
    begin
        // [SCENARIO] Validate quality inspection template lookup with template filter

        // [GIVEN] A quality inspection template is created if none exist
        if not QltyInspectionTemplateHdr.FindFirst() then
            QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);

        Template := QltyInspectionTemplateHdr.Code;
        // [WHEN] AssistEditQltyInspectionTemplate is called with template filter
        FoundTemplate := QltyInspectionUtility.AssistEditQltyInspectionTemplate(Template);

        // [THEN] A template code is found and matches the template
        LibraryAssert.IsTrue(FoundTemplate, 'Should claim found template code.');
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, Template, 'The template code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupLocationListHandler')]
    procedure EditLocation_NoFilter()
    var
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LocationToUse: Code[20];
        FoundLocation: Boolean;
    begin
        // [SCENARIO] Validate location lookup without filter

        // [GIVEN] A location is created if none exist
        if not Location.FindFirst() then
            LibraryWarehouse.CreateLocation(Location);

        // [WHEN] AssistEditLocation is called with no filter
        FoundLocation := QltyInspectionUtility.AssistEditLocation(LocationToUse);

        // [THEN] A location is found and the location code matches
        LibraryAssert.IsTrue(FoundLocation, 'Should claim found location.');
        LibraryAssert.AreEqual(Location.Code, LocationToUse, 'The location code should match.');
    end;

    [Test]
    [HandlerFunctions('LookupLocationListHandler')]
    procedure EditLocation_LocationFilter()
    var
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LocationToUse: Code[20];
        FoundLocation: Boolean;
    begin
        // [SCENARIO] Validate location lookup with location filter

        // [GIVEN] A location is created if none exist
        if not Location.FindFirst() then
            LibraryWarehouse.CreateLocation(Location);

        LocationToUse := Location.Code;
        // [WHEN] AssistEditLocation is called with location filter
        FoundLocation := QltyInspectionUtility.AssistEditLocation(LocationToUse);

        // [THEN] A location is found and the location code matches
        LibraryAssert.IsTrue(FoundLocation, 'Should claim found location.');
        LibraryAssert.AreEqual(Location.Code, LocationToUse, 'The location code should match.');
    end;

    [Test]
    procedure CleanupWhereClause2048()
    var
        Output: Text;
    begin
        // [SCENARIO] Validate where clause cleanup reducing length to 2048 characters or less

        // [WHEN] CleanUpWhereClause2048 is called with input where clause
        Output := QltyInspectionUtility.CleanUpWhereClause2048(InputWhereClause400Tok);

        // [THEN] The output length is 2048 characters or less
        LibraryAssert.IsTrue(StrLen(Output) <= 2048, 'Should reduce length to 2048 characters or less');
    end;

    [Test]
    procedure CleanupWhereClause()
    var
        Output: Text;
    begin
        // [SCENARIO] Validate where clause cleanup splitting filter at WHERE keyword

        // [WHEN] CleanUpWhereClause is called with input containing WHERE keyword
        Output := QltyInspectionUtility.CleanUpWhereClause(InputWhereClauseTok);

        // [THEN] The output returns the filter portion after WHERE
        LibraryAssert.AreEqual(CorrectOutputTok, Output, 'Should return filter at WHERE')
    end;

    [Test]
    procedure CleanupWhereClause_ShouldReturnBlank()
    var
        Output: Text;
    begin
        // [SCENARIO] Validate where clause cleanup returns blank when no WHERE keyword present

        // [WHEN] CleanUpWhereClause is called with input without WHERE keyword
        Output := QltyInspectionUtility.CleanUpWhereClause(InputWhereClause2Tok);

        // [THEN] The output is blank
        LibraryAssert.AreEqual('', Output, 'Should not return a filter without WHERE.');
    end;

    [Test]
    procedure DeserializeFilterIntoItemAttributesBuffer()
    var
        TempFilterItemAttributesBuffer: Record "Filter Item Attributes Buffer" temporary;
        Filter: Text;
    begin
        // [SCENARIO] Validate deserialization of filter into item attributes buffer

        // [GIVEN] A filter string with multiple attributes
        Filter := AttributeTok;

        // [WHEN] DeserializeFilterIntoItemAttributesBuffer is called with the filter
        QltyInspectionUtility.DeserializeFilterIntoItemAttributesBuffer(Filter, TempFilterItemAttributesBuffer);

        // [THEN] Two attributes are deserialized and their attribute names and values match
        LibraryAssert.AreEqual(2, TempFilterItemAttributesBuffer.Count(), 'There should be two attributes deserialized.');
        repeat
            LibraryAssert.IsTrue(((TempFilterItemAttributesBuffer.Attribute = 'Color') or (TempFilterItemAttributesBuffer.Attribute = 'ModelYear')), 'Attributes should match.');
            if TempFilterItemAttributesBuffer.Attribute = 'Color' then
                LibraryAssert.IsTrue(TempFilterItemAttributesBuffer.Value = 'Red', 'Value should match Attribute.')
            else
                LibraryAssert.IsTrue(TempFilterItemAttributesBuffer.Value = '2019', 'Value should match Attribute.')
        until TempFilterItemAttributesBuffer.Next(-1) = 0;
    end;

    [Test]
    procedure SerializeItemAttributesBufferIntoText()
    var
        TempFilterItemAttributesBuffer: Record "Filter Item Attributes Buffer" temporary;
        Filter: Text;
    begin
        // [SCENARIO] Validate serialization of item attributes buffer into text

        // [GIVEN] Two item attributes are added to the buffer
        TempFilterItemAttributesBuffer.Init();
        TempFilterItemAttributesBuffer.Attribute := 'Color';
        TempFilterItemAttributesBuffer.Value := 'Red';
        TempFilterItemAttributesBuffer.Insert();
        TempFilterItemAttributesBuffer.Init();
        TempFilterItemAttributesBuffer.Attribute := 'ModelYear';
        TempFilterItemAttributesBuffer.Value := '2019';
        TempFilterItemAttributesBuffer.Insert();

        // [WHEN] SerializeItemAttributesBufferIntoText is called
        Filter := QltyInspectionUtility.SerializeItemAttributesBufferIntoText(TempFilterItemAttributesBuffer);

        // [THEN] The serialization is comma separated and matches the provided attributes
        LibraryAssert.AreEqual(AttributeTok, Filter, 'Serialization should be comma separated and match provided attributes.');
    end;

    [Test]
    [HandlerFunctions('FilterItemAttributesHandler')]
    procedure BuildItemAttributeFilter()
    var
        ItemAttribute: Record "Item Attribute";
        SecondItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        SecondItemAttributeValue: Record "Item Attribute Value";
        LibraryInventory: Codeunit "Library - Inventory";
        Filter: Text;
    begin
        // [SCENARIO] Validate building item attribute filter by adding a second attribute

        // [GIVEN] Two item attributes with values are created
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Option, '');
        LibraryInventory.CreateItemAttribute(SecondItemAttribute, SecondItemAttribute.Type::Integer, '');
        LibraryInventory.CreateItemAttributeWithValue(ItemAttribute, ItemAttributeValue, ItemAttribute.Type::Option, 'Red');
        LibraryInventory.CreateItemAttributeWithValue(SecondItemAttribute, SecondItemAttributeValue, ItemAttribute.Type::Integer, '2019');

        Filter := StrSubstNo(Attribute2Tok, ItemAttribute.Name, ItemAttributeValue.Value);

        // [WHEN] BuildItemAttributeFilter is called to add a second attribute
        QltyInspectionUtility.BuildItemAttributeFilter(Filter);

        // [THEN] The filter contains both attributes
        LibraryAssert.AreEqual(StrSubstNo(Attribute3Tok, ItemAttribute.Name, ItemAttributeValue.Value, SecondItemAttribute.Name, SecondItemAttributeValue.Value), Filter, 'Should match provided attributes.');
    end;

    /// <summary>
    /// Handles the Objects TestPage, returning the first record
    /// </summary>
    /// <param name="Objects"></param>
    [ModalPageHandler]
    procedure LookupObjectsHandler_FirstRec(var Objects: TestPage Objects)
    begin
        Objects.First();
        Objects.OK().Invoke();
    end;

    /// <summary>
    /// Handles Objects Lookup TestPage, returning the filtered record
    /// </summary>
    /// <param name="Objects"></param>
    [ModalPageHandler]
    procedure LookupObjectsHandler_FilteredRec(var Objects: TestPage Objects)
    begin
        Objects.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Fields Lookup TestPage, returning the first record
    /// </summary>
    /// <param name="FieldsLookup"></param>
    [ModalPageHandler]
    procedure LookupFieldsHandler_FirstRec(var FieldsLookup: TestPage "Fields Lookup")
    begin
        FieldsLookup.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Zone List TestPage, returning the first record
    /// </summary>
    /// <param name="ZoneList"></param>
    [ModalPageHandler]
    procedure LookupZoneListHandler_FirstRec(var ZoneList: TestPage "Zone List")
    begin
        ZoneList.First();
        ZoneList.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Zone List TestPage, returning the filtered record
    /// </summary>
    /// <param name="ZoneList"></param>
    [ModalPageHandler]
    procedure LookupZoneListHandler_FilteredRec(var ZoneList: TestPage "Zone List")
    begin
        ZoneList.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Bin List TestPage, returning the first record
    /// </summary>
    /// <param name="BinList"></param>
    [ModalPageHandler]
    procedure LookupBinListHandler_FirstRec(var BinList: TestPage "Bin List")
    begin
        BinList.First();
        BinList.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Bin List TestPage, returning the filtered record
    /// </summary>
    /// <param name="BinList"></param>
    [ModalPageHandler]
    procedure LookupBinListHandler_FilteredRec(var BinList: TestPage "Bin List")
    begin
        BinList.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Item List TestPage, returning the first record
    /// </summary>
    /// <param name="ItemList"></param>
    [ModalPageHandler]
    procedure LookupItemListHandler_FirstRec(var ItemList: TestPage "Item List")
    begin
        ItemList.First();
        ItemList.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Item List TestPage, returning the filtered record
    /// </summary>
    /// <param name="ItemList"></param>
    [ModalPageHandler]
    procedure LookupItemListHandler_FilteredRec(var ItemList: TestPage "Item List")
    begin
        ItemList.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Item Categories TestPage, returning the first record
    /// </summary>
    /// <param name="ItemCategories"></param>
    [ModalPageHandler]
    procedure LookupItemCategoriesHandler_FirstRec(var ItemCategories: TestPage "Item Categories")
    begin
        ItemCategories.First();
        ItemCategories.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Item Categories TestPage, returning the filtered record
    /// </summary>
    /// <param name="ItemCategories"></param>
    [ModalPageHandler]
    procedure LookupItemCategoriesHandler_FilteredRec(var ItemCategories: TestPage "Item Categories")
    begin
        ItemCategories.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Inventory Posting Group TestPage, returning the first record
    /// </summary>
    /// <param name="InventoryPostingGroups"></param>
    [ModalPageHandler]
    procedure LookupInventoryPostingGroupsHandler_FirstRec(var InventoryPostingGroups: TestPage "Inventory Posting Groups")
    begin
        InventoryPostingGroups.First();
        InventoryPostingGroups.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Inventory Posting Group TestPage, returning the filtered record
    /// </summary>
    /// <param name="InventoryPostingGroups"></param>
    [ModalPageHandler]
    procedure LookupInventoryPostingGroupsHandler_FilteredRec(var InventoryPostingGroups: TestPage "Inventory Posting Groups")
    begin
        InventoryPostingGroups.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Vendor List TestPage, returning the first record
    /// </summary>
    /// <param name="VendorList"></param>
    [ModalPageHandler]
    procedure LookupVendorListHandler_FirstRec(var VendorList: TestPage "Vendor List")
    begin
        VendorList.First();
        VendorList.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Vendor List TestPage, returning the filtered record
    /// </summary>
    /// <param name="VendorList"></param>
    [ModalPageHandler]
    procedure LookupVendorListHandler_FilteredRec(var VendorList: TestPage "Vendor List")
    begin
        VendorList.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Customer List TestPage, returning the first record
    /// </summary>
    /// <param name="CustomerList"></param>
    [ModalPageHandler]
    procedure LookupCustomerListHandler_FirstRec(var CustomerList: TestPage "Customer List")
    begin
        CustomerList.First();
        CustomerList.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Customer List TestPage, returning the filtered record
    /// </summary>
    /// <param name="CustomerList"></param>
    [ModalPageHandler]
    procedure LookupCustomerListHandler_FilteredRec(var CustomerList: TestPage "Customer List")
    begin
        CustomerList.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Machine Center List TestPage, returning the first record
    /// </summary>
    /// <param name="MachineCenterList"></param>
    [ModalPageHandler]
    procedure LookupMachineCenterListHandler(var MachineCenterList: TestPage "Machine Center List")
    begin
        MachineCenterList.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Routing List TestPage, returning the first record
    /// </summary>
    /// <param name="RoutingList"></param>
    [ModalPageHandler]
    procedure LookupRoutingListHandler(var RoutingList: TestPage "Routing List")
    begin
        RoutingList.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Qlty. Routing Line Lookup TestPage, returning the first record
    /// </summary>
    /// <param name="QltyRoutingLineLookup"></param>
    [ModalPageHandler]
    procedure LookupQltyRoutingLineHandler(var QltyRoutingLineLookup: TestPage "Qlty. Routing Line Lookup")
    begin
        QltyRoutingLineLookup.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Work Center List TestPage, returning the first record
    /// </summary>
    /// <param name="WorkCenterList"></param>
    [ModalPageHandler]
    procedure LookupWorkCenterListHandler(var WorkCenterList: TestPage "Work Center List")
    begin
        WorkCenterList.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Purchasing Codes TestPage, returning the first record
    /// </summary>
    /// <param name="PurchasingCodes"></param>
    [ModalPageHandler]
    procedure LookupPurchasingCodesHandler(var PurchasingCodes: TestPage "Purchasing Codes")
    begin
        PurchasingCodes.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Return Reasons TestPage, returning the first record
    /// </summary>
    /// <param name="ReturnReasons"></param>
    [ModalPageHandler]
    procedure LookupReturnReasonsHandler(var ReturnReasons: TestPage "Return Reasons")
    begin
        ReturnReasons.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Fields Lookup TestPage, returning the first record
    /// </summary>
    /// <param name="QltyInspectionTemplateList"></param>
    [ModalPageHandler]
    procedure LookupQltyInspectionTemplateListHandler(var QltyInspectionTemplateList: TestPage "Qlty. Inspection Template List")
    begin
        QltyInspectionTemplateList.OK().Invoke();
    end;

    /// <summary>
    /// Handles the Location List TestPage, returning the first record
    /// </summary>
    /// <param name="LocationList"></param>
    [ModalPageHandler]
    procedure LookupLocationListHandler(var LocationList: TestPage "Location List")
    begin
        LocationList.OK().Invoke();
    end;

    /// <summary>
    /// Handles the FilterPageBuilder, returning an "No." filter
    /// </summary>
    /// <param name="RecordRef"></param>
    /// <returns></returns>
    [FilterPageHandler]
    procedure FilterBuilderPageHandler(var RecordRef: RecordRef): Boolean;
    begin
        RecordRef.SetView(StrSubstNo(ViewTok, Code20));
        exit(true);
    end;

    /// <summary>
    /// Handles the FilterItemAttributes TestPage, adding a ModelYear attribute
    /// </summary>
    /// <param name="FilterItemsByAttribute"></param>
    [ModalPageHandler]
    procedure FilterItemAttributesHandler(var FilterItemsByAttribute: TestPage "Filter Items by Attribute")
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        ItemAttribute.FindLast();
        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        ItemAttributeValue.FindLast();
        FilterItemsByAttribute.New();
        FilterItemsByAttribute.Attribute.SetValue(ItemAttribute.Name);
        FilterItemsByAttribute.Value.SetValue(ItemAttributeValue.Value);
        FilterItemsByAttribute.OK().Invoke();
    end;
}

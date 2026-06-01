// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;
using Microsoft.Sales.Customer;
using Microsoft.Test.QualityManagement.TestLibraries;
using System.TestLibraries.Utilities;

codeunit 139955 "Qlty. Tests - Generation Rule"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryAssert: Codeunit "Library Assert";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        ItemFilterTok: Label 'WHERE(No.=FILTER(%1))', Comment = '%1=item no.', Locked = true;
        ItemAttributeFilterTok: Label '"%1"=Filter(1))', Comment = '%1=attribute', Locked = true;
        CouldNotFindGenerationRuleErr: Label 'Could not find any compatible inspection generation rules for the template %1. Navigate to Quality Inspection Generation Rules and create a generation rule for the template %1', Comment = '%1=the template';
        CouldNotFindSourceErr: Label 'There are generation rules for the template %1, however there is no source configuration that describes how to connect control fields. Navigate to Quality Inspection Source Configuration list and create a source configuration for table(s) %2', Comment = '%1=the template, %2=the table';

    [Test]
    procedure ActivationTriggerFindGenerationRule_ManualOnly_ManualRuleSearch()
    var
        TempOutQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        PurchaseLineRecordRef: RecordRef;
    begin
        // [SCENARIO] Find a generation rule with Manual only activation trigger when performing a manual rule search

        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

        // [GIVEN] A generation rule with Manual only activation trigger is created
        DeleteAllAndCreateOneGenerationRule(QltyInspectionTemplateHdr.Code, Enum::"Qlty. Gen. Rule Act. Trigger"::"Manual only");

        // [WHEN] A manual rule search is performed for Purchase Line
        PurchaseLineRecordRef.Open(Database::"Purchase Line");

        // [THEN] The generation rule is found
        LibraryAssert.IsTrue(QltyInspectionUtility.FindMatchingGenerationRule(false, true, PurchaseLineRecordRef, Item, QltyInspectionTemplateHdr.Code, TempOutQltyInspectionGenRule), 'Should find generation rule');
    end;

    [Test]
    procedure ActivationTriggerFindGenerationRule_ManualOnly_AutoRuleSearch()
    var
        TempOutQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        PurchaseLineRecordRef: RecordRef;
    begin
        // [SCENARIO] Verify that a generation rule with Manual only activation trigger is not found when performing an automatic rule search

        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

        // [GIVEN] A generation rule with Manual only activation trigger is created
        DeleteAllAndCreateOneGenerationRule(QltyInspectionTemplateHdr.Code, Enum::"Qlty. Gen. Rule Act. Trigger"::"Manual only");

        // [WHEN] An automatic rule search is performed for Purchase Line
        PurchaseLineRecordRef.Open(Database::"Purchase Line");

        // [THEN] The generation rule is not found
        LibraryAssert.IsFalse(QltyInspectionUtility.FindMatchingGenerationRule(false, false, PurchaseLineRecordRef, Item, QltyInspectionTemplateHdr.Code, TempOutQltyInspectionGenRule), 'Should not find generation rule');
    end;

    [Test]
    procedure ActivationTriggerFindGenerationRule_AutoOnly_AutoRuleSearch()
    var
        TempOutQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Find a generation rule with Automatic only activation trigger when performing an automatic rule search

        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

        // [GIVEN] A generation rule with Automatic only activation trigger is created
        DeleteAllAndCreateOneGenerationRule(QltyInspectionTemplateHdr.Code, Enum::"Qlty. Gen. Rule Act. Trigger"::"Automatic only");

        // [WHEN] An automatic rule search is performed for Purchase Line
        RecordRef.Open(Database::"Purchase Line");

        // [THEN] The generation rule is found
        LibraryAssert.IsTrue(QltyInspectionUtility.FindMatchingGenerationRule(false, false, RecordRef, Item, QltyInspectionTemplateHdr.Code, TempOutQltyInspectionGenRule), 'Should find generation rule');
    end;

    [Test]
    procedure ActivationTriggerFindGenerationRule_AutoOnly_ManualRuleSearch()
    var
        TempOutQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Verify that a generation rule with Automatic only activation trigger is not found when performing a manual rule search

        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

        // [GIVEN] A generation rule with Automatic only activation trigger is created
        DeleteAllAndCreateOneGenerationRule(QltyInspectionTemplateHdr.Code, Enum::"Qlty. Gen. Rule Act. Trigger"::"Automatic only");

        // [WHEN] A manual rule search is performed for Purchase Line
        RecordRef.Open(Database::"Purchase Line");

        // [THEN] The generation rule is not found
        LibraryAssert.IsFalse(QltyInspectionUtility.FindMatchingGenerationRule(false, true, RecordRef, Item, QltyInspectionTemplateHdr.Code, TempOutQltyInspectionGenRule), 'Should not find generation rule');
    end;

    [Test]
    procedure ActivationTriggerFindGenerationRule_ManualAndAuto_AutoRuleSearch()
    var
        TempOutQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Find a generation rule with Manual or Automatic activation trigger when performing an automatic rule search

        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

        // [GIVEN] A generation rule with Manual or Automatic activation trigger is created
        DeleteAllAndCreateOneGenerationRule(QltyInspectionTemplateHdr.Code, Enum::"Qlty. Gen. Rule Act. Trigger"::"Manual or Automatic");

        // [WHEN] An automatic rule search is performed for Purchase Line
        RecordRef.Open(Database::"Purchase Line");

        // [THEN] The generation rule is found
        LibraryAssert.IsTrue(QltyInspectionUtility.FindMatchingGenerationRule(false, false, RecordRef, Item, QltyInspectionTemplateHdr.Code, TempOutQltyInspectionGenRule), 'Should find generation rule');
    end;

    [Test]
    procedure ActivationTriggerFindGenerationRule_ManualAndAuto_ManualRuleSearch()
    var
        TempOutQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Find a generation rule with Manual or Automatic activation trigger when performing a manual rule search

        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

        // [GIVEN] A generation rule with Manual or Automatic activation trigger is created
        DeleteAllAndCreateOneGenerationRule(QltyInspectionTemplateHdr.Code, Enum::"Qlty. Gen. Rule Act. Trigger"::"Manual or Automatic");

        // [WHEN] A manual rule search is performed for Purchase Line
        RecordRef.Open(Database::"Purchase Line");

        // [THEN] The generation rule is found
        LibraryAssert.IsTrue(QltyInspectionUtility.FindMatchingGenerationRule(false, true, RecordRef, Item, QltyInspectionTemplateHdr.Code, TempOutQltyInspectionGenRule), 'Should find generation rule');
    end;

    [Test]
    procedure ActivationTriggerFindGenerationRule_Disabled_ManualRuleSearch()
    var
        TempOutQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Verify that a generation rule with Disabled activation trigger is not found when performing a manual rule search

        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

        // [GIVEN] A generation rule with Disabled activation trigger is created
        DeleteAllAndCreateOneGenerationRule(QltyInspectionTemplateHdr.Code, Enum::"Qlty. Gen. Rule Act. Trigger"::Disabled);

        // [WHEN] A manual rule search is performed for Purchase Line
        RecordRef.Open(Database::"Purchase Line");

        // [THEN] The generation rule is not found
        LibraryAssert.IsFalse(QltyInspectionUtility.FindMatchingGenerationRule(false, true, RecordRef, Item, QltyInspectionTemplateHdr.Code, TempOutQltyInspectionGenRule), 'Should not find generation rule');
    end;

    [Test]
    procedure ActivationTriggerFindGenerationRule_Disabled_AutoRuleSearch()
    var
        TempOutQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        RecordRef: RecordRef;
        GenRuleActivTrigger: Enum "Qlty. Gen. Rule Act. Trigger";
    begin
        // [SCENARIO] Verify that a generation rule with Disabled activation trigger is not found when performing an automatic rule search

        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

        // [GIVEN] A generation rule with Disabled activation trigger is created
        DeleteAllAndCreateOneGenerationRule(QltyInspectionTemplateHdr.Code, GenRuleActivTrigger::Disabled);

        // [WHEN] An automatic rule search is performed for Purchase Line
        RecordRef.Open(Database::"Purchase Line");

        // [THEN] The generation rule is not found
        LibraryAssert.IsFalse(QltyInspectionUtility.FindMatchingGenerationRule(false, false, RecordRef, Item, QltyInspectionTemplateHdr.Code, TempOutQltyInspectionGenRule), 'Should not find generation rule');
    end;

    [Test]
    procedure FindGenerationRule_ItemFilter()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        TempOutQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Find a generation rule that has an item filter and verify it matches the specified item

        // [GIVEN] An item is created
        LibraryInventory.CreateItem(Item);

        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

        // [GIVEN] A generation rule with Manual or Automatic activation trigger is created
        DeleteAllAndCreateOneGenerationRule(QltyInspectionTemplateHdr.Code, Enum::"Qlty. Gen. Rule Act. Trigger"::"Manual or Automatic");

        // [GIVEN] The generation rule is updated with an item filter
        QltyInspectionGenRule.FindFirst();
        QltyInspectionGenRule."Item Filter" := StrSubstNo(ItemFilterTok, Item."No.");
        QltyInspectionGenRule.Modify();

        // [WHEN] A manual rule search is performed for Purchase Line with the item
        RecordRef.Open(Database::"Purchase Line");

        // [THEN] The generation rule is found
        LibraryAssert.IsTrue(QltyInspectionUtility.FindMatchingGenerationRule(false, true, RecordRef, Item, QltyInspectionTemplateHdr.Code, TempOutQltyInspectionGenRule), 'Should find generation rule');
    end;

    [Test]
    procedure FindGenerationRule_ItemAttributeFilter()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        TempOutQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        LibraryInventory: Codeunit "Library - Inventory";
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Find a generation rule that has an item attribute filter and verify it matches items with the specified attribute

        // [GIVEN] An item is created with an attribute value
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemAttributeWithValue(ItemAttribute, ItemAttributeValue, ItemAttribute.Type::Integer, '1');
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute.ID, ItemAttributeValue.ID);

        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

        // [GIVEN] A generation rule with Manual or Automatic activation trigger is created
        DeleteAllAndCreateOneGenerationRule(QltyInspectionTemplateHdr.Code, Enum::"Qlty. Gen. Rule Act. Trigger"::"Manual or Automatic");

        // [GIVEN] The generation rule is updated with an item attribute filter
        QltyInspectionGenRule.FindFirst();
        QltyInspectionGenRule."Item Attribute Filter" := (StrSubstNo(ItemAttributeFilterTok, ItemAttribute.Name));
        QltyInspectionGenRule.Modify();

        // [WHEN] A manual rule search is performed for Purchase Line with the item
        RecordRef.Open(Database::"Purchase Line");

        // [THEN] The generation rule is found
        LibraryAssert.IsTrue(QltyInspectionUtility.FindMatchingGenerationRule(false, true, RecordRef, Item, QltyInspectionTemplateHdr.Code, TempOutQltyInspectionGenRule), 'Should find generation rule');
    end;

    [Test]
    procedure SetFilterToApplicableTemplates_NoFoundGenRule_ShouldError()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
    begin
        // [SCENARIO] Attempt to set filters to applicable templates when no generation rule exists and verify error is raised

        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

        // [WHEN] Filters are set to applicable templates without any generation rule
        // [THEN] An error is raised indicating no compatible generation rules found
        asserterror QltyInspectionUtility.SetFilterToApplicableTemplates(QltyInspectionTemplateHdr.Code, SpecificQltyInspectSourceConfig);
        LibraryAssert.ExpectedError(StrSubstNo(CouldNotFindGenerationRuleErr, QltyInspectionTemplateHdr.Code));
    end;

    [Test]
    procedure SetFilterToApplicableTemplates_NoFoundSourceConfig_ShouldError()
    var
        Customer: Record Customer;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Attempt to set filters to applicable templates when a generation rule exists but no source configuration exists and verify error is raised

        // [GIVEN] All existing source configurations for Customer table are deleted
        SpecificQltyInspectSourceConfig.SetRange("From Table No.", Database::Customer);
        if not SpecificQltyInspectSourceConfig.IsEmpty() then
            SpecificQltyInspectSourceConfig.DeleteAll();

        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

        // [GIVEN] A prioritized generation rule for Customer table is created
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::Customer, QltyInspectionGenRule);

        // [WHEN] Filters are set to applicable templates without source configuration
        RecordRef.GetTable(Customer);

        // [THEN] An error is raised indicating no source configuration found for the table
        asserterror QltyInspectionUtility.SetFilterToApplicableTemplates(QltyInspectionTemplateHdr.Code, SpecificQltyInspectSourceConfig);
        LibraryAssert.ExpectedError(StrSubstNo(CouldNotFindSourceErr, QltyInspectionTemplateHdr.Code, Database::Customer));
    end;

    [Test]
    procedure SetFilterToApplicableTemplates()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        RecordRef: RecordRef;
        Filter: Text;
    begin
        // [SCENARIO] Set filters to applicable templates and verify the source configuration is filtered correctly

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A quality inspection template is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

        // [GIVEN] A prioritized generation rule for Purchase Line table is created
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [WHEN] Filters are set to applicable templates
        QltyInspectionUtility.SetFilterToApplicableTemplates(QltyInspectionTemplateHdr.Code, SpecificQltyInspectSourceConfig);

        // [THEN] The source configuration record is filtered to the Purchase Line table
        RecordRef.GetTable(SpecificQltyInspectSourceConfig);
        Filter := RecordRef.GetFilters();
        LibraryAssert.IsTrue(Filter.Contains(Format(Database::"Purchase Line")), 'Filter should have Purchase Line table.');
    end;

    [Test]
    procedure GetFilterForAvailableConfigurations()
    var
        SpecificQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        Filters: Text;
    begin
        // [SCENARIO] Get filter for available source configurations and verify it includes the configured table

        // [GIVEN] All existing source configurations are deleted
        SpecificQltyInspectSourceConfig.DeleteAll();

        // [GIVEN] A source configuration is created for Purchase Line to Qlty. Inspection Header
        SpecificQltyInspectSourceConfig.Init();
        SpecificQltyInspectSourceConfig."From Table No." := Database::"Purchase Line";
        SpecificQltyInspectSourceConfig."To Table No." := Database::"Qlty. Inspection Header";
        SpecificQltyInspectSourceConfig.Insert();

        // [WHEN] Filter for available configurations is retrieved
        Filters := QltyInspectionUtility.GetFilterForAvailableConfigurations();

        // [THEN] The filter contains the Purchase Line table number
        LibraryAssert.IsTrue(Filters.Contains(Format(Database::"Purchase Line")), 'Should contain table no.');
    end;

    local procedure DeleteAllAndCreateOneGenerationRule(TemplateCode: Code[20]; ActivationTrigger: Enum "Qlty. Gen. Rule Act. Trigger")
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionGenRule.Init();
        QltyInspectionUtility.SetEntryNo(QltyInspectionGenRule);
        QltyInspectionGenRule.Insert();
        QltyInspectionGenRule."Source Table No." := Database::"Purchase Line";
        QltyInspectionGenRule."Template Code" := TemplateCode;
        QltyInspectionGenRule."Activation Trigger" := ActivationTrigger;
        QltyInspectionGenRule.Modify();
    end;
}

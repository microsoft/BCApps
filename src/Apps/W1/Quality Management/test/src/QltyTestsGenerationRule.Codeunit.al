// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.DemoData.QualityManagement;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Tracking;
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
        LibraryInventory: Codeunit "Library - Inventory";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        ItemFilterTok: Label 'WHERE(No.=FILTER(%1))', Comment = '%1=item no.', Locked = true;
        ItemAttributeFilterTok: Label '"%1"=Filter(1))', Comment = '%1=attribute', Locked = true;
        CouldNotFindGenerationRuleErr: Label 'Could not find any compatible inspection generation rules for the template %1. Navigate to Quality Inspection Generation Rules and create a generation rule for the template %1', Comment = '%1=the template';
        CouldNotFindSourceErr: Label 'There are generation rules for the template %1, however there is no source configuration that describes how to connect control fields. Navigate to Quality Inspection Source Configuration list and create a source configuration for table(s) %2', Comment = '%1=the template, %2=the table';
        TableMissingErr: Label 'You must choose a Table for this generation rule', Locked = true;
        LegacyDescriptionTok: Label 'Legacy rule', Locked = true;
        NoCompatibleGenRuleQstFragmentTok: Label 'Could not find any compatible inspection generation rules for the template', Locked = true;
        NoCompatibleGenRuleQuestionSeen: Boolean;
        BeansCategoryTok: Label 'BEANS', Locked = true;
        TrackedBeansItemNoTok: Label 'WRB-1002', Locked = true;
        CustomizedRuleDescTok: Label 'Customized beans inspection', Locked = true;

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

    [Test]
    procedure Insert_NoSourceTableNo_ShouldError()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
    begin
        // [SCENARIO] Inserting a generation rule without setting Source Table No. raises an actionable error pointing to the Table assist-edit button

        // [GIVEN] A template exists
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

        // [GIVEN] All existing generation rules are removed
        QltyInspectionGenRule.DeleteAll();

        // [GIVEN] A generation rule is initialized with Template Code but no Source Table No.
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Template Code" := QltyInspectionTemplateHdr.Code;

        // [WHEN] Inserting the rule with triggers enabled
        asserterror QltyInspectionGenRule.Insert(true);

        // [THEN] The actionable error is raised
        LibraryAssert.ExpectedError(TableMissingErr);
    end;

    [Test]
    procedure Modify_ClearSourceTableNo_ShouldError()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
    begin
        // [SCENARIO] Modifying a generation rule to clear Source Table No. raises the actionable error

        // [GIVEN] A valid generation rule for Purchase Line exists
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] The saved rule is read back so the before-image (xRec) reflects the table it has on disk, mirroring a user editing an existing rule
        QltyInspectionGenRule.Get(QltyInspectionGenRule."Entry No.");

        // [GIVEN] Source Table No. is cleared on the record buffer
        QltyInspectionGenRule."Source Table No." := 0;

        // [WHEN] Modifying the rule with triggers enabled
        asserterror QltyInspectionGenRule.Modify(true);

        // [THEN] The actionable error is raised
        LibraryAssert.ExpectedError(TableMissingErr);
    end;

    [Test]
    procedure Insert_WithSourceTableNo_Succeeds()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
    begin
        // [SCENARIO] Inserting a generation rule with Source Table No. set succeeds without raising the actionable error

        // [GIVEN] A template exists
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

        // [GIVEN] All existing generation rules are removed
        QltyInspectionGenRule.DeleteAll();

        // [GIVEN] A generation rule with Template Code and Source Table No. is initialized
        QltyInspectionGenRule.Init();
        QltyInspectionGenRule."Template Code" := QltyInspectionTemplateHdr.Code;
        QltyInspectionGenRule."Source Table No." := Database::"Purchase Line";

        // [WHEN] Inserting the rule with triggers enabled
        QltyInspectionGenRule.Insert(true);

        // [THEN] The rule is persisted
        LibraryAssert.IsFalse(QltyInspectionGenRule.IsEmpty(), 'The generation rule should be persisted after insert');
    end;

    [Test]
    procedure LegacyRuleWithoutTable_CanBeModifiedAndDeleted()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        LegacyEntryNo: Integer;
    begin
        // [SCENARIO] A pre-existing rule with no Source Table No. (legacy data created before the mandatory-table guard) can still be edited and deleted

        // [GIVEN] A template exists
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

        // [GIVEN] All existing generation rules are removed
        QltyInspectionGenRule.DeleteAll();

        // [GIVEN] A legacy rule persisted without a table, bypassing triggers (Insert(false) mimics data created before the guard existed)
        QltyInspectionGenRule.Init();
        QltyInspectionUtility.SetEntryNo(QltyInspectionGenRule);
        QltyInspectionGenRule."Template Code" := QltyInspectionTemplateHdr.Code;
        QltyInspectionGenRule."Source Table No." := 0;
        QltyInspectionGenRule.Insert(false);
        LegacyEntryNo := QltyInspectionGenRule."Entry No.";

        // [WHEN] Editing a non-table field with triggers enabled
        QltyInspectionGenRule.Description := LegacyDescriptionTok;
        QltyInspectionGenRule.Modify(true);

        // [THEN] The modify succeeds - the OnModify guard is skipped for rows that were already table-less
        LibraryAssert.AreEqual(LegacyDescriptionTok, QltyInspectionGenRule.Description, 'A legacy rule without a table should remain editable');

        // [WHEN] Deleting the legacy rule
        QltyInspectionGenRule.Delete(true);

        // [THEN] It is gone - legacy rows are not bricked by the mandatory-table enforcement
        LibraryAssert.IsFalse(QltyInspectionGenRule.Get(LegacyEntryNo), 'A legacy rule without a table should be deletable');
    end;

    [Test]
    [HandlerFunctions('NoCompatibleGenRuleConfirmHandler,GenRulesFilteredToTemplateModalHandler')]
    procedure SourceLookup_NoCompatibleRule_WarnsAndOpensGenRulesFilteredToTemplate()
    var
        TargetQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        OtherQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        HasCompatibleRule: Boolean;
    begin
        // [SCENARIO] When the Source lookup finds no compatible generation rule for the chosen template, it warns the user and opens the Generation Rules page filtered to that template

        // [GIVEN] Setup, a target template with no rules, and a different template that does have an enabled rule
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionGenRule.DeleteAll();
        QltyInspectionUtility.CreateTemplate(TargetQltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreateTemplate(OtherQltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreatePrioritizedRule(OtherQltyInspectionTemplateHdr, Database::"Purchase Line");

        // [WHEN] The Source lookup pre-check runs for the target template (via the test library wrapper around the report procedure)
        NoCompatibleGenRuleQuestionSeen := false;
        HasCompatibleRule := QltyInspectionUtility.EnsureCompatibleGenerationRuleExists(TargetQltyInspectionTemplateHdr.Code);

        // [THEN] The warning question was shown (NoCompatibleGenRuleConfirmHandler) and the Generation Rules page opened filtered to the target template (GenRulesFilteredToTemplateModalHandler)
        LibraryAssert.IsTrue(NoCompatibleGenRuleQuestionSeen, 'The lookup should warn that no compatible generation rule exists for the template');
        // [THEN] Still no compatible rule afterwards because none was created
        LibraryAssert.IsFalse(HasCompatibleRule, 'No compatible rule should exist for the target template');
    end;

    [Test]
    procedure DemoBeansTrackedPurchase_ManualSelectsBeans()
    var
        Item: Record Item;
        CreateQMInspTemplateHdr: Codeunit "Create QM Insp. Template Hdr";
    begin
        // [FEATURE] [AI test 0.3] [Quality Management]
        // [SCENARIO] A manual purchase inspection for tracked WRB-1002 selects the seeded BEANS template.
        Initialize();

        // [GIVEN] The real demo rules and tracked item "I" in the BEANS category.
        SeedDemoGenerationRules();
        CreateTrackedDemoItem(Item, TrackedBeansItemNoTok, BeansCategoryTok);

        // [WHEN] A manual purchase rule is resolved without specifying a template.
        // [THEN] BEANS takes precedence over the generic RECEIVE rule.
        VerifyDemoPurchaseRule(Item, true, CreateQMInspTemplateHdr.Beans());
    end;

    [Test]
    procedure DemoBeansTrackedPurchase_AutomaticSelectsBeans()
    var
        Item: Record Item;
        CreateQMInspTemplateHdr: Codeunit "Create QM Insp. Template Hdr";
    begin
        // [FEATURE] [AI test 0.3] [Quality Management]
        // [SCENARIO] An automatic purchase inspection for tracked WRB-1002 selects the seeded BEANS template.
        Initialize();

        // [GIVEN] The real demo rules and tracked item "I" in the BEANS category.
        SeedDemoGenerationRules();
        CreateTrackedDemoItem(Item, TrackedBeansItemNoTok, BeansCategoryTok);

        // [WHEN] An automatic purchase rule is resolved without specifying a template.
        // [THEN] BEANS takes precedence over the generic RECEIVE rule.
        VerifyDemoPurchaseRule(Item, false, CreateQMInspTemplateHdr.Beans());
    end;

    [Test]
    procedure DemoBeansPurchase_OtherItemSelectsBeans()
    var
        Item: Record Item;
        CreateQMInspTemplateHdr: Codeunit "Create QM Insp. Template Hdr";
    begin
        // [FEATURE] [AI test 0.3] [Quality Management]
        // [SCENARIO] The seeded BEANS rule matches the category, not only the demo item number.
        Initialize();

        // [GIVEN] The real demo rules and another tracked BEANS item "I".
        SeedDemoGenerationRules();
        CreateTrackedDemoItem(Item, '', BeansCategoryTok);

        // [WHEN] Manual and automatic purchase rules are resolved for "I".
        // [THEN] Both select BEANS independently of the item number.
        VerifyDemoPurchaseRule(Item, true, CreateQMInspTemplateHdr.Beans());
        VerifyDemoPurchaseRule(Item, false, CreateQMInspTemplateHdr.Beans());
    end;

    [Test]
    procedure DemoPurchase_NonBeansItemSelectsReceive()
    var
        Item: Record Item;
        ItemCategory: Record "Item Category";
        CreateQMInspTemplateHdr: Codeunit "Create QM Insp. Template Hdr";
    begin
        // [FEATURE] [AI test 0.3] [Quality Management]
        // [SCENARIO] A tracked item outside BEANS retains the generic RECEIVE purchase rule.
        Initialize();

        // [GIVEN] The real demo rules and tracked item "I" in a different category.
        SeedDemoGenerationRules();
        LibraryInventory.CreateItemCategory(ItemCategory);
        CreateTrackedDemoItem(Item, '', ItemCategory.Code);

        // [WHEN] Manual and automatic purchase rules are resolved for "I".
        // [THEN] The category-specific rule does not displace RECEIVE.
        VerifyDemoPurchaseRule(Item, true, CreateQMInspTemplateHdr.Receive());
        VerifyDemoPurchaseRule(Item, false, CreateQMInspTemplateHdr.Receive());
    end;

    [Test]
    procedure DemoPurchase_NonItemLineSelectsReceive()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        CreateQMInspTemplateHdr: Codeunit "Create QM Insp. Template Hdr";
        PurchaseLineRecordRef: RecordRef;
    begin
        // [FEATURE] [AI test 0.3] [Quality Management]
        // [SCENARIO] An item-filtered demo rule does not match a purchase line without an item.
        Initialize();

        // [GIVEN] The real demo rules and a non-item purchase line.
        SeedDemoGenerationRules();
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        PurchaseLine.Type := PurchaseLine.Type::"G/L Account";
        PurchaseLineRecordRef.GetTable(PurchaseLine);

        // [WHEN] A purchase generation rule is resolved without an item.
        LibraryAssert.IsTrue(
            QltyInspectionUtility.FindMatchingGenerationRule(false, true, PurchaseLineRecordRef, Item, '', TempQltyInspectionGenRule),
            'The generic purchase generation rule must match a non-item line.');

        // [THEN] The item-filtered BEANS rule is skipped in favor of RECEIVE.
        LibraryAssert.AreEqual(CreateQMInspTemplateHdr.Receive(), TempQltyInspectionGenRule."Template Code", 'A non-item purchase line must select the generic RECEIVE rule.');
        PurchaseLineRecordRef.Close();
    end;

    [Test]
    procedure DemoBeansRule_HasPurchaseScopeAndPriority()
    var
        BeansQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReceiveQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        // [FEATURE] [AI test 0.3] [Quality Management]
        // [SCENARIO] Demo generation creates a BEANS category purchase rule before the unchanged RECEIVE rule.
        Initialize();

        // [GIVEN] No generation rules exist.

        // [WHEN] The real demo template and generation-rule seeders run.
        SeedDemoGenerationRules();

        // [THEN] BEANS and RECEIVE have the intended scope, activation and relative priority.
        VerifyDemoRuleScope(BeansQltyInspectionGenRule, ReceiveQltyInspectionGenRule);
    end;

    [Test]
    procedure DemoBeansRule_RepeatedSeedingIsIdempotent()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        BeansSystemId: Guid;
        ReceiveSystemId: Guid;
    begin
        // [FEATURE] [AI test 0.3] [Quality Management]
        // [SCENARIO] Repeating demo generation preserves the existing rule identities and creates no duplicates.
        Initialize();

        // [GIVEN] Both rules have been created by the real demo seeders.
        SeedDemoGenerationRules();
        LibraryAssert.IsTrue(QltyInspectionGenRule.Get(3), 'The demo seeder must create the BEANS rule.');
        BeansSystemId := QltyInspectionGenRule.SystemId;
        QltyInspectionGenRule.Get(4);
        ReceiveSystemId := QltyInspectionGenRule.SystemId;

        // [WHEN] The same demo seeders run again.
        SeedDemoGenerationRules();

        // [THEN] Both original records remain and there are exactly two rules.
        VerifyDemoRuleIdentities(BeansSystemId, ReceiveSystemId);
    end;

    [Test]
    procedure DemoBeansRule_RepeatedSeedingPreservesCustomization()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        CustomizedItemFilter: Text;
    begin
        // [FEATURE] [AI test 0.3] [Quality Management]
        // [SCENARIO] The default demo overwrite guard preserves a customized BEANS rule on regeneration.
        Initialize();

        // [GIVEN] A rule created by the real seeder has user-customized fields.
        SeedDemoGenerationRules();
        LibraryAssert.IsTrue(QltyInspectionGenRule.Get(3), 'The demo seeder must create the BEANS rule.');
        CreateTrackedDemoItem(Item, '', BeansCategoryTok);
        Item.SetRange("No.", Item."No.");
        CustomizedItemFilter := Item.GetView(false);
        QltyInspectionGenRule.Validate("Item Filter", CustomizedItemFilter);
        QltyInspectionGenRule.Validate(Description, CustomizedRuleDescTok);
        QltyInspectionGenRule.Validate("Sort Order", 17);
        QltyInspectionGenRule.Validate("Activation Trigger", QltyInspectionGenRule."Activation Trigger"::Disabled);
        QltyInspectionGenRule.Modify(true);

        // [WHEN] The real demo generation runs again without enabling overwrite.
        SeedDemoGenerationRules();

        // [THEN] The user's filter, description, priority and activation are preserved.
        VerifyCustomizedDemoRule(CustomizedItemFilter);
    end;

    local procedure Initialize()
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        QltyInspectionGenRule.DeleteAll();
    end;

    local procedure SeedDemoGenerationRules()
    begin
        Commit();
        Codeunit.Run(Codeunit::"Create QM Insp. Template Hdr");
        Codeunit.Run(Codeunit::"Create QM Generation Rule");
    end;

    local procedure CreateTrackedDemoItem(var Item: Record Item; ItemNo: Code[20]; ItemCategoryCode: Code[20])
    var
        ItemCategory: Record "Item Category";
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if not ItemCategory.Get(ItemCategoryCode) then begin
            LibraryInventory.CreateItemCategory(ItemCategory);
            ItemCategory.Rename(ItemCategoryCode);
        end;
        if not Item.Get(ItemNo) then begin
            LibraryInventory.CreateItem(Item);
            if ItemNo <> '' then
                Item.Rename(ItemNo);
        end;
        Item.Validate("Item Category Code", ItemCategory.Code);
        if Item."Item Tracking Code" = '' then begin
            LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
            ItemTrackingCode.Validate("Lot Specific Tracking", true);
            ItemTrackingCode.Modify(true);
            Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        end;
        Item.Modify(true);
    end;

    local procedure VerifyDemoPurchaseRule(var Item: Record Item; IsManualCreation: Boolean; ExpectedTemplateCode: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        PurchaseLineRecordRef: RecordRef;
    begin
        LibraryAssert.AreNotEqual('', Item."Item Tracking Code", 'The purchase fixture must be tracked.');
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := Item."No.";
        PurchaseLineRecordRef.GetTable(PurchaseLine);
        LibraryAssert.IsTrue(
            QltyInspectionUtility.FindMatchingGenerationRule(false, IsManualCreation, PurchaseLineRecordRef, Item, '', TempQltyInspectionGenRule),
            'A seeded purchase generation rule must match the item.');
        LibraryAssert.AreEqual(ExpectedTemplateCode, TempQltyInspectionGenRule."Template Code", 'The seeded purchase rule must select the template for the item category.');
        PurchaseLineRecordRef.Close();
    end;

    local procedure VerifyDemoRuleScope(var BeansQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule"; var ReceiveQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule")
    var
        FilteredItem: Record Item;
        CreateQMInspTemplateHdr: Codeunit "Create QM Insp. Template Hdr";
    begin
        LibraryAssert.IsTrue(BeansQltyInspectionGenRule.Get(3), 'The demo seeder must create the BEANS rule.');
        LibraryAssert.AreEqual(CreateQMInspTemplateHdr.Beans(), BeansQltyInspectionGenRule."Template Code", 'Entry 3 must select BEANS.');
        LibraryAssert.AreEqual(BeansQltyInspectionGenRule.Intent::Purchase, BeansQltyInspectionGenRule.Intent, 'BEANS must have Purchase intent.');
        LibraryAssert.AreEqual(Database::"Purchase Line", BeansQltyInspectionGenRule."Source Table No.", 'BEANS must apply to Purchase Line.');
        LibraryAssert.AreEqual(BeansQltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", BeansQltyInspectionGenRule."Activation Trigger", 'BEANS must support both activation modes.');
        LibraryAssert.AreEqual(30, BeansQltyInspectionGenRule."Sort Order", 'BEANS must have sort order 30.');
        LibraryAssert.AreNotEqual('', BeansQltyInspectionGenRule."Item Filter", 'BEANS must have an item category filter.');
        FilteredItem.SetView(BeansQltyInspectionGenRule."Item Filter");
        LibraryAssert.AreEqual(BeansCategoryTok, FilteredItem.GetRangeMin("Item Category Code"), 'The item filter must select the BEANS category.');
        LibraryAssert.AreEqual(BeansCategoryTok, FilteredItem.GetRangeMax("Item Category Code"), 'The item filter must not include other categories.');

        ReceiveQltyInspectionGenRule.Get(4);
        LibraryAssert.AreEqual(CreateQMInspTemplateHdr.Receive(), ReceiveQltyInspectionGenRule."Template Code", 'Entry 4 must retain RECEIVE.');
        LibraryAssert.AreEqual(ReceiveQltyInspectionGenRule.Intent::Purchase, ReceiveQltyInspectionGenRule.Intent, 'RECEIVE must retain Purchase intent.');
        LibraryAssert.AreEqual(Database::"Purchase Line", ReceiveQltyInspectionGenRule."Source Table No.", 'RECEIVE must retain Purchase Line scope.');
        LibraryAssert.AreEqual(ReceiveQltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", ReceiveQltyInspectionGenRule."Activation Trigger", 'RECEIVE must retain both activation modes.');
        LibraryAssert.AreEqual(40, ReceiveQltyInspectionGenRule."Sort Order", 'RECEIVE must retain sort order 40.');
        LibraryAssert.AreEqual('', ReceiveQltyInspectionGenRule."Item Filter", 'RECEIVE must remain an unfiltered fallback.');
        LibraryAssert.IsTrue(BeansQltyInspectionGenRule."Sort Order" < ReceiveQltyInspectionGenRule."Sort Order", 'BEANS must precede RECEIVE.');
    end;

    local procedure VerifyDemoRuleIdentities(BeansSystemId: Guid; ReceiveSystemId: Guid)
    var
        BeansQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        ReceiveQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        VerifyDemoRuleScope(BeansQltyInspectionGenRule, ReceiveQltyInspectionGenRule);
        LibraryAssert.AreEqual(BeansSystemId, BeansQltyInspectionGenRule.SystemId, 'Regeneration must retain the BEANS record.');
        LibraryAssert.AreEqual(ReceiveSystemId, ReceiveQltyInspectionGenRule.SystemId, 'Regeneration must retain the RECEIVE record.');
        LibraryAssert.AreEqual(2, BeansQltyInspectionGenRule.Count(), 'Regeneration must not create duplicate rules.');
    end;

    local procedure VerifyCustomizedDemoRule(CustomizedItemFilter: Text)
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
    begin
        QltyInspectionGenRule.Get(3);
        LibraryAssert.AreEqual(CustomizedItemFilter, QltyInspectionGenRule."Item Filter", 'Regeneration must retain the customized item filter.');
        LibraryAssert.AreEqual(CustomizedRuleDescTok, QltyInspectionGenRule.Description, 'Regeneration must retain the customized description.');
        LibraryAssert.AreEqual(17, QltyInspectionGenRule."Sort Order", 'Regeneration must retain the customized priority.');
        LibraryAssert.AreEqual(QltyInspectionGenRule."Activation Trigger"::Disabled, QltyInspectionGenRule."Activation Trigger", 'Regeneration must retain the customized activation.');
        LibraryAssert.AreEqual(2, QltyInspectionGenRule.Count(), 'Regeneration must not create a second BEANS rule.');
    end;

    [ConfirmHandler]
    procedure NoCompatibleGenRuleConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Incidental confirms raised during setup are answered without asserting; only the no-compatible-rule warning is tracked
        if StrPos(Question, NoCompatibleGenRuleQstFragmentTok) > 0 then
            NoCompatibleGenRuleQuestionSeen := true;
        Reply := true;
    end;

    [ModalPageHandler]
    procedure GenRulesFilteredToTemplateModalHandler(var QltyInspectionGenRules: TestPage "Qlty. Inspection Gen. Rules")
    begin
        // The page is opened filtered to the target template, which has no rules, so the rule that exists for a different template must not be shown
        LibraryAssert.IsFalse(QltyInspectionGenRules.First(), 'The Generation Rules page should open filtered to the selected template (rules of other templates must not appear)');
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

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using System.TestLibraries.Utilities;

codeunit 139994 "Subc. ReqWkshTemplUpgrade Test"
{
    // [FEATURE] Subcontracting Req. Wksh. Template Type Upgrade
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryAssert: Codeunit "Library Assert";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";

    [Test]
    procedure MigrationConvertsLegacyRawTypeValueToCurrentSubcontractingValue()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade: Codeunit "Subc. Req Wksh Templ Upgrade";
#pragma warning restore AL0432
    begin
        // [SCENARIO 644283] Migrating "Req. Wksh. Template".Type converts the pre-renumbering raw value (99001500) to the current Subcontracting value (20500)
        Initialize();

        // [GIVEN] A Req. Wksh. Template whose Type field holds the legacy raw value 99001500, seeded through RecordRef/FieldRef
        CreateReqWkshTemplateWithRawTypeValue(ReqWkshTemplate, LegacySubcontractingTypeValue());

        // [WHEN] The Req. Wksh. Template Type migration runs
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade.MigrateReqWkshTemplateTypeFromLegacyValue();
#pragma warning restore AL0432

        // [THEN] The template's Type is the current, typed Subcontracting value
        ReqWkshTemplate.Get(ReqWkshTemplate.Name);
        Assert.AreEqual(ReqWkshTemplate.Type::Subcontracting, ReqWkshTemplate.Type, 'Type should be converted to the current Subcontracting value.');

        ReqWkshTemplate.Delete();
    end;

    [Test]
    procedure MigrationDoesNotAffectUnrelatedTemplateTypes()
    var
        PlanningReqWkshTemplate: Record "Req. Wksh. Template";
        LegacyReqWkshTemplate: Record "Req. Wksh. Template";
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade: Codeunit "Subc. Req Wksh Templ Upgrade";
#pragma warning restore AL0432
    begin
        // [SCENARIO 644283] Migrating "Req. Wksh. Template".Type does not touch templates that already have a valid, unrelated Type value
        Initialize();

        // [GIVEN] A Req. Wksh. Template with Type = Planning, set through the normal typed Validate
        CreateReqWkshTemplateWithTypedType(PlanningReqWkshTemplate, PlanningReqWkshTemplate.Type::Planning);

        // [GIVEN] A second Req. Wksh. Template holding the legacy raw value, so the migration has matching data to act on
        CreateReqWkshTemplateWithRawTypeValue(LegacyReqWkshTemplate, LegacySubcontractingTypeValue());

        // [WHEN] The Req. Wksh. Template Type migration runs
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade.MigrateReqWkshTemplateTypeFromLegacyValue();
#pragma warning restore AL0432

        // [THEN] The unrelated Planning template is unchanged
        PlanningReqWkshTemplate.Get(PlanningReqWkshTemplate.Name);
        Assert.AreEqual(PlanningReqWkshTemplate.Type::Planning, PlanningReqWkshTemplate.Type, 'Unrelated Planning template Type must remain unchanged.');

        PlanningReqWkshTemplate.Delete();
        LegacyReqWkshTemplate.Delete();
    end;

    [Test]
    procedure MigrationRunningTwiceIsHarmless()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade: Codeunit "Subc. Req Wksh Templ Upgrade";
#pragma warning restore AL0432
    begin
        // [SCENARIO 644283] Running the Req. Wksh. Template Type migration a second time is a harmless no-op (idempotent)
        Initialize();

        // [GIVEN] A Req. Wksh. Template holding the legacy raw value, already migrated once
        CreateReqWkshTemplateWithRawTypeValue(ReqWkshTemplate, LegacySubcontractingTypeValue());
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade.MigrateReqWkshTemplateTypeFromLegacyValue();
#pragma warning restore AL0432
        ReqWkshTemplate.Get(ReqWkshTemplate.Name);
        Assert.AreEqual(ReqWkshTemplate.Type::Subcontracting, ReqWkshTemplate.Type, 'Type should be converted to the current Subcontracting value after the first run.');

        // [WHEN] The migration runs a second time
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade.MigrateReqWkshTemplateTypeFromLegacyValue();
#pragma warning restore AL0432

        // [THEN] The Type value remains the current, typed Subcontracting value and no error occurs
        ReqWkshTemplate.Get(ReqWkshTemplate.Name);
        Assert.AreEqual(ReqWkshTemplate.Type::Subcontracting, ReqWkshTemplate.Type, 'Re-running the migration must be harmless and keep the Subcontracting value.');

        ReqWkshTemplate.Delete();
    end;

    [Test]
    procedure InitializeReusesSurvivingDefaultWorksheet()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Cleared extension setup is initialized when the default worksheet survives reinstallation.
        Initialize();

        // [GIVEN] Blank Subcontracting setup and surviving template and batch "S".
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ReqWkshTemplate, 'SUBCONTR');
        CreateSubcontractingBatch(RequisitionWkshName, ReqWkshTemplate.Name, 'SUBCONTR');

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Existing records are selected and the scalar defaults are persisted.
        VerifyDefaultSetup('SUBCONTR', 'SUBCONTR');
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
    end;

    [Test]
    procedure InitializeReusesCustomWorksheetWithoutChanges()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Existing custom worksheet records are reused unchanged, including on repeated initialization.
        Initialize();

        // [GIVEN] Blank setup and custom template "C" with batch "B".
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ReqWkshTemplate, 'CUSTOM');
        ReqWkshTemplate.Recurring := true;
        ReqWkshTemplate."Increment Batch Name" := true;
        ReqWkshTemplate.Modify();
        CreateSubcontractingBatch(RequisitionWkshName, ReqWkshTemplate.Name, 'CUSTOMBAT');

        // [WHEN] Company defaults are initialized twice.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Custom records are selected without duplicates or metadata changes.
        VerifyDefaultSetup(ReqWkshTemplate.Name, RequisitionWkshName.Name);
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
    end;

    [Test]
    procedure InitializeCreatesMissingBatchForExistingTemplate()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] An existing template without a batch receives a default batch and company defaults.
        Initialize();

        // [GIVEN] Blank setup and custom template "C" without batches.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ReqWkshTemplate, 'CUSTOM');

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] A default batch is created beneath the surviving template.
        VerifyDefaultSetup(ReqWkshTemplate.Name, 'SUBCONTR');
        RequisitionWkshName.Get(ReqWkshTemplate.Name, 'SUBCONTR');
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
    end;

    [Test]
    procedure FreshInitializationIsIdempotent()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Fresh initialization creates defaults and a second call leaves those records unchanged.
        Initialize();

        // [GIVEN] Blank setup and no Subcontracting worksheets.
        PrepareUninitializedSetup(ManufacturingSetup);

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Default selections and scalar settings are persisted.
        VerifyDefaultSetup('SUBCONTR', 'SUBCONTR');
        ReqWkshTemplate.Get('SUBCONTR');
        RequisitionWkshName.Get('SUBCONTR', 'SUBCONTR');
        VerifyCreatedWorksheet(ReqWkshTemplate, RequisitionWkshName);

        // [WHEN] Company defaults are initialized again.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Setup and worksheet identities remain unchanged.
        VerifyDefaultSetup('SUBCONTR', 'SUBCONTR');
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
    end;

    [Test]
    procedure InitializeCreatesAbsentManufacturingSetup()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A company without Manufacturing Setup receives the complete Subcontracting defaults.
        Initialize();

        // [GIVEN] Neither Manufacturing Setup nor Subcontracting worksheets exist.
        PrepareUninitializedSetup(ManufacturingSetup);
        ManufacturingSetup.Delete();

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Manufacturing Setup is created with valid worksheet selections and defaults.
        VerifyDefaultSetup('SUBCONTR', 'SUBCONTR');
        VerifyWorksheetCounts('SUBCONTR', 1, 1);
    end;

    [Test]
    procedure InitializePreservesNonFirstSelectedWorksheetAndSettings()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        FirstReqWkshTemplate: Record "Req. Wksh. Template";
        SelectedReqWkshTemplate: Record "Req. Wksh. Template";
        FirstRequisitionWkshName: Record "Requisition Wksh. Name";
        SelectedRequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Valid non-first selections and deliberately false or blank settings survive repeated initialization.
        Initialize();

        // [GIVEN] Template "Z" and its second batch are selected instead of the first available records.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(FirstReqWkshTemplate, 'AFIRST');
        CreateSubcontractingBatch(FirstRequisitionWkshName, FirstReqWkshTemplate.Name, 'AFIRST');
        CreateSubcontractingTemplate(SelectedReqWkshTemplate, 'ZSELECTED');
        CreateSubcontractingBatch(FirstRequisitionWkshName, SelectedReqWkshTemplate.Name, 'AFIRST');
        CreateSubcontractingBatch(SelectedRequisitionWkshName, SelectedReqWkshTemplate.Name, 'ZSELECTED');
        ManufacturingSetup.Validate("Subcontracting Template Name", SelectedReqWkshTemplate.Name);
        ManufacturingSetup.Validate("Subcontracting Batch Name", SelectedRequisitionWkshName.Name);
        ManufacturingSetup."Component Direct Unit Cost" := ManufacturingSetup."Component Direct Unit Cost"::"Prod. Order Component";
        ManufacturingSetup.Validate("Subc. Default Comp. Location", ManufacturingSetup."Subc. Default Comp. Location"::Purchase);
        ManufacturingSetup.Modify();

        // [WHEN] Company defaults are initialized twice.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Every configured field and the selected worksheet records remain unchanged.
        VerifyConfiguredSetup(ManufacturingSetup, SelectedReqWkshTemplate.Name, SelectedRequisitionWkshName.Name);
        VerifyWorksheetUnchanged(SelectedReqWkshTemplate, SelectedRequisitionWkshName, 2, 2);
    end;

    [Test]
    procedure InitializeRepairsSelectedTemplateWithoutResettingScalars()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        FirstReqWkshTemplate: Record "Req. Wksh. Template";
        SelectedReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A selected template alone proves prior configuration when its missing batch is repaired.
        Initialize();

        // [GIVEN] Template "Z" is selected without a batch and scalar fields are deliberately false or blank.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(FirstReqWkshTemplate, 'AFIRST');
        CreateSubcontractingTemplate(SelectedReqWkshTemplate, 'ZSELECTED');
        ManufacturingSetup.Validate("Subcontracting Template Name", SelectedReqWkshTemplate.Name);
        ManufacturingSetup.Modify();

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] The missing batch is created for the selected template without resetting scalar fields.
        VerifyConfiguredSetup(ManufacturingSetup, SelectedReqWkshTemplate.Name, 'SUBCONTR');
        RequisitionWkshName.Get(SelectedReqWkshTemplate.Name, 'SUBCONTR');
        VerifyWorksheetUnchanged(SelectedReqWkshTemplate, RequisitionWkshName, 2, 1);
    end;

    [Test]
    procedure InitializePreservesCustomLeadTimeWithBlankSelections()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A custom transfer lead time prevents scalar defaulting while blank worksheet selections are repaired.
        Initialize();

        // [GIVEN] Custom lead time with false information lines and blank selections, plus surviving worksheet "C".
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ReqWkshTemplate, 'CUSTOM');
        CreateSubcontractingBatch(RequisitionWkshName, ReqWkshTemplate.Name, 'CUSTOMBAT');
        Evaluate(ManufacturingSetup."Subc. Comp. Transfer Lead Time", '<3D>');
        ManufacturingSetup.Modify();

        // [WHEN] Company defaults are initialized twice.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Selections are repaired and the custom lead time and false information lines are retained.
        VerifyConfiguredSetup(ManufacturingSetup, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
    end;

    [Test]
    procedure InitializePreservesComponentCostOnlyConfiguration()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A component cost choice alone prevents scalar defaulting when worksheets must be created.
        Initialize();

        // [GIVEN] Only component cost is configured and there are no worksheets.
        PrepareUninitializedSetup(ManufacturingSetup);
        ManufacturingSetup."Component Direct Unit Cost" := ManufacturingSetup."Component Direct Unit Cost"::"Prod. Order Component";
        ManufacturingSetup.Modify();

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Worksheets are created without changing any configured scalar field.
        VerifyConfiguredSetup(ManufacturingSetup, 'SUBCONTR', 'SUBCONTR');
        VerifyWorksheetCounts('SUBCONTR', 1, 1);
    end;

    [Test]
    procedure InitializePreservesComponentLocationOnlyConfiguration()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A component location choice alone prevents scalar defaulting when worksheets must be created.
        Initialize();

        // [GIVEN] Only component location is configured and there are no worksheets.
        PrepareUninitializedSetup(ManufacturingSetup);
        ManufacturingSetup.Validate("Subc. Default Comp. Location", ManufacturingSetup."Subc. Default Comp. Location"::Purchase);
        ManufacturingSetup.Modify();

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Worksheets are created without changing any configured scalar field.
        VerifyConfiguredSetup(ManufacturingSetup, 'SUBCONTR', 'SUBCONTR');
        VerifyWorksheetCounts('SUBCONTR', 1, 1);
    end;

    [Test]
    procedure InitializePreservesBlankLeadTimeWithInformationLines()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Enabled information lines alone prove configuration and preserve a deliberately blank lead time.
        Initialize();

        // [GIVEN] Only information lines are enabled and there are no worksheets.
        PrepareUninitializedSetup(ManufacturingSetup);
        ManufacturingSetup."Create Prod. Order Info Line" := true;
        ManufacturingSetup.Modify();

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Worksheet creation does not replace the blank lead time.
        VerifyConfiguredSetup(ManufacturingSetup, 'SUBCONTR', 'SUBCONTR');
        VerifyWorksheetCounts('SUBCONTR', 1, 1);
    end;

    [Test]
    procedure SetupHelperSucceedsWithExistingTemplate()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
        SetupAvailable: Boolean;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] The public setup helper reports availability rather than creation for an existing worksheet.
        Initialize();

        // [GIVEN] Blank setup and surviving custom worksheet "C".
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ReqWkshTemplate, 'CUSTOM');
        CreateSubcontractingBatch(RequisitionWkshName, ReqWkshTemplate.Name, 'CUSTOMBAT');

        // [WHEN] The setup helper is called directly.
        SetupAvailable := SubcontractingCompInit.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup(ManufacturingSetup);

        // [THEN] The helper succeeds and fills the caller's selections without mutating worksheet records.
        VerifySetupHelperResult(SetupAvailable, ManufacturingSetup, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
    end;

    [Test]
    procedure InitializeCreatesAlternativeTemplateOnNameCollision()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] Initialization creates an alternative template without changing a conflicting Planning worksheet.
        Initialize();

        // [GIVEN] Blank setup and a Planning template named SUBCONTR with a custom batch.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateConflictingWorksheet(ReqWkshTemplate, RequisitionWkshName);

        // [WHEN] Company defaults are initialized twice.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Defaults use the alternative template and the conflicting worksheet is unchanged.
        VerifyDefaultSetup('SUBCONTR1', 'SUBCONTR');
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
        VerifyAlternativeWorksheet('SUBCONTR1');
    end;

    [Test]
    procedure CreateReqWkshTemplateCreatesAlternativeOnNameCollision()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ExpectedReqWkshTemplate: Record "Req. Wksh. Template";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
        TemplateCreated: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] Direct template creation returns a new alternative without changing the conflicting worksheet or setup.
        Initialize();

        // [GIVEN] Blank setup and a Planning template named SUBCONTR with a custom batch.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateConflictingWorksheet(ExpectedReqWkshTemplate, RequisitionWkshName);

        // [WHEN] The default template is created using an unfiltered record.
        TemplateCreated := SubcontractingCompInit.CreateReqWkshTemplate(ReqWkshTemplate, false);

        // [THEN] An alternative template is created while the conflicting worksheet and setup remain unchanged.
        Assert.IsTrue(TemplateCreated, 'An available alternative name must allow template creation.');
        Assert.AreEqual('SUBCONTR1', ReqWkshTemplate.Name, 'The first available alternative name must be used.');
        ReqWkshTemplate.Get(ReqWkshTemplate.Name);
        Assert.AreEqual(ReqWkshTemplate.Type::Subcontracting, ReqWkshTemplate.Type, 'The alternative must have the Subcontracting type.');
        Assert.AreEqual(Page::"Subc. Subcontracting Worksheet", ReqWkshTemplate."Page ID", 'The alternative must use the Subcontracting worksheet page.');
        VerifyWorksheetUnchanged(ExpectedReqWkshTemplate, RequisitionWkshName, 1, 1);
        VerifyConfiguredSetup(ManufacturingSetup, '', '');
    end;

    [Test]
    procedure SetupHelperSelectsAlternativeOnTemplateNameCollision()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
        SetupAvailable: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] The setup helper replaces incompatible selections with an alternative Subcontracting worksheet.
        Initialize();

        // [GIVEN] Setup selects Planning template "P" named SUBCONTR and its custom batch.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateConflictingWorksheet(ReqWkshTemplate, RequisitionWkshName);
        ManufacturingSetup."Subcontracting Template Name" := ReqWkshTemplate.Name;
        ManufacturingSetup."Subcontracting Batch Name" := RequisitionWkshName.Name;
        ManufacturingSetup.Modify();

        // [WHEN] The setup helper is called directly.
        SetupAvailable := SubcontractingCompInit.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup(ManufacturingSetup);

        // [THEN] The caller receives valid selections while persisted setup and the Planning worksheet remain unchanged.
        VerifySetupHelperResult(SetupAvailable, ManufacturingSetup, 'SUBCONTR1', 'SUBCONTR');
        VerifyConfiguredSetup(ManufacturingSetup, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
        VerifyAlternativeWorksheet('SUBCONTR1');
    end;

    [Test]
    procedure InitializeReusesValidTemplateWithConflictingDefaultName()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ConflictingReqWkshTemplate: Record "Req. Wksh. Template";
        ConflictingRequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] A valid Subcontracting template is reused even when the default name belongs to a Planning template.
        Initialize();

        // [GIVEN] Planning template "P" occupies SUBCONTR and Subcontracting template "S" has a custom batch.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateConflictingWorksheet(ConflictingReqWkshTemplate, ConflictingRequisitionWkshName);
        CreateSubcontractingTemplate(ReqWkshTemplate, 'CUSTOM');
        CreateSubcontractingBatch(RequisitionWkshName, ReqWkshTemplate.Name, 'CUSTOMBAT');

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Setup uses the valid template while both worksheets remain unchanged.
        VerifyDefaultSetup(ReqWkshTemplate.Name, RequisitionWkshName.Name);
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
        VerifyWorksheetUnchanged(ConflictingReqWkshTemplate, ConflictingRequisitionWkshName, 1, 1);
    end;

    [Test]
    procedure CreateReqWkshTemplateReturnsExistingTemplateWithoutCreation()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ExpectedReqWkshTemplate: Record "Req. Wksh. Template";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
        TemplateCreated: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] A false creation result still returns an existing valid template for callers to reuse.
        Initialize();

        // [GIVEN] Subcontracting template "S" and its custom batch already exist.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ExpectedReqWkshTemplate, 'CUSTOM');
        CreateSubcontractingBatch(RequisitionWkshName, ExpectedReqWkshTemplate.Name, 'CUSTOMBAT');

        // [WHEN] Default template creation is requested.
        TemplateCreated := SubcontractingCompInit.CreateReqWkshTemplate(ReqWkshTemplate, false);

        // [THEN] No template is created and the existing valid template is returned unchanged.
        Assert.IsFalse(TemplateCreated, 'Reusing a template must not report successful creation.');
        Assert.AreEqual(ExpectedReqWkshTemplate.Name, ReqWkshTemplate.Name, 'The existing valid template must be returned.');
        VerifyWorksheetUnchanged(ExpectedReqWkshTemplate, RequisitionWkshName, 1, 1);
        LibraryAssert.AreEqualDateTime(ExpectedReqWkshTemplate.SystemModifiedAt, ReqWkshTemplate.SystemModifiedAt, 'A template with the correct page must not be modified.');
    end;

    [Test]
    procedure InitializeSkipsOccupiedAlternativeTemplateNames()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        OccupiedReqWkshTemplate: Record "Req. Wksh. Template";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
        Suffix: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] Alternative naming skips occupied names and stays within the template name length.
        Initialize();

        // [GIVEN] Planning templates occupy the default name and alternatives through suffix 99.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateConflictingWorksheet(ReqWkshTemplate, RequisitionWkshName);
        for Suffix := 1 to 99 do begin
            OccupiedReqWkshTemplate.Init();
            OccupiedReqWkshTemplate.Name := CopyStr('SUBCONTR' + Format(Suffix, 0, 9), 1, MaxStrLen(OccupiedReqWkshTemplate.Name));
            OccupiedReqWkshTemplate.Type := OccupiedReqWkshTemplate.Type::Planning;
            OccupiedReqWkshTemplate.Insert(true);
        end;

        // [WHEN] Company defaults are initialized twice.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] The first available length-safe name is used and occupied templates are not changed.
        VerifyDefaultSetup('SUBCONT100', 'SUBCONTR');
        VerifyAlternativeWorksheet('SUBCONT100');
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
        OccupiedReqWkshTemplate.Get('SUBCONTR99');
        Assert.AreEqual(OccupiedReqWkshTemplate.Type::Planning, OccupiedReqWkshTemplate.Type, 'Occupied alternative names must retain their type.');
    end;

    [Test]
    procedure CreateReqWkshTemplateRepairsExistingTemplatePageOnly()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ExpectedReqWkshTemplate: Record "Req. Wksh. Template";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
        TemplateCreated: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] Reusing a Subcontracting template migrates only its legacy Subcontracting worksheet page.
        Initialize();

        // [GIVEN] Subcontracting template "S" has the legacy Subcontracting page and custom metadata and batch.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ExpectedReqWkshTemplate, 'CUSTOM');
        ExpectedReqWkshTemplate."Page ID" := 99000886;
        ExpectedReqWkshTemplate.Recurring := true;
        ExpectedReqWkshTemplate."Increment Batch Name" := true;
        ExpectedReqWkshTemplate.Modify();
        CreateSubcontractingBatch(RequisitionWkshName, ExpectedReqWkshTemplate.Name, 'CUSTOMBAT');

        // [WHEN] Default template creation is requested.
        TemplateCreated := SubcontractingCompInit.CreateReqWkshTemplate(ReqWkshTemplate, false);

        // [THEN] The existing template is returned with only its page corrected.
        Assert.IsFalse(TemplateCreated, 'Correcting a page must not report template creation.');
        Assert.AreEqual(ExpectedReqWkshTemplate.Name, ReqWkshTemplate.Name, 'The existing template must be reused.');
        ExpectedReqWkshTemplate."Page ID" := Page::"Subc. Subcontracting Worksheet";
        VerifyWorksheetUnchanged(ExpectedReqWkshTemplate, RequisitionWkshName, 1, 1);
        VerifyConfiguredSetup(ManufacturingSetup, '', '');
    end;

    [Test]
    procedure InitializeRepairsSelectedTemplatePageOnly()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        FirstReqWkshTemplate: Record "Req. Wksh. Template";
        SelectedReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] Initialization migrates the selected legacy Subcontracting page without switching templates or resetting settings.
        Initialize();

        // [GIVEN] Non-first Subcontracting template "S" is selected with the legacy Subcontracting page.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(FirstReqWkshTemplate, 'AFIRST');
        CreateSubcontractingTemplate(SelectedReqWkshTemplate, 'ZSELECTED');
        SelectedReqWkshTemplate."Page ID" := 99000886;
        SelectedReqWkshTemplate.Recurring := true;
        SelectedReqWkshTemplate."Increment Batch Name" := true;
        SelectedReqWkshTemplate.Modify();
        CreateSubcontractingBatch(RequisitionWkshName, SelectedReqWkshTemplate.Name, 'CUSTOMBAT');
        ManufacturingSetup.Validate("Subcontracting Template Name", SelectedReqWkshTemplate.Name);
        ManufacturingSetup.Validate("Subcontracting Batch Name", RequisitionWkshName.Name);
        ManufacturingSetup.Modify();

        // [WHEN] Company defaults are initialized twice.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Only the selected template page changes.
        SelectedReqWkshTemplate."Page ID" := Page::"Subc. Subcontracting Worksheet";
        VerifyWorksheetUnchanged(SelectedReqWkshTemplate, RequisitionWkshName, 2, 1);
        VerifyConfiguredSetup(ManufacturingSetup, SelectedReqWkshTemplate.Name, RequisitionWkshName.Name);
    end;

    [Test]
    procedure CreateReqWkshTemplatePreservesUnrelatedPage()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ExpectedReqWkshTemplate: Record "Req. Wksh. Template";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
        TemplateCreated: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] Reusing a Subcontracting template preserves a page other than the legacy Subcontracting worksheet.
        Initialize();

        // [GIVEN] Subcontracting template "S" has a Planning page selected by the customer.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ExpectedReqWkshTemplate, 'CUSTOM');
        ExpectedReqWkshTemplate."Page ID" := Page::"Planning Worksheet";
        ExpectedReqWkshTemplate.Modify();
        CreateSubcontractingBatch(RequisitionWkshName, ExpectedReqWkshTemplate.Name, 'CUSTOMBAT');

        // [WHEN] Default template creation is requested.
        TemplateCreated := SubcontractingCompInit.CreateReqWkshTemplate(ReqWkshTemplate, false);

        // [THEN] The existing template and its unrelated page are unchanged.
        Assert.IsFalse(TemplateCreated, 'Reusing a template must not report creation.');
        VerifyWorksheetUnchanged(ExpectedReqWkshTemplate, RequisitionWkshName, 1, 1);
        LibraryAssert.AreEqualDateTime(ExpectedReqWkshTemplate.SystemModifiedAt, ReqWkshTemplate.SystemModifiedAt, 'An unrelated page must not cause template modification.');
    end;

    [Test]
    procedure InitializePreservesSelectedTemplateUnrelatedPage()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] Initialization preserves an unrelated page on the selected Subcontracting template.
        Initialize();

        // [GIVEN] Subcontracting template "S" is selected with a Planning page.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ReqWkshTemplate, 'CUSTOM');
        ReqWkshTemplate."Page ID" := Page::"Planning Worksheet";
        ReqWkshTemplate.Modify();
        CreateSubcontractingBatch(RequisitionWkshName, ReqWkshTemplate.Name, 'CUSTOMBAT');
        ManufacturingSetup.Validate("Subcontracting Template Name", ReqWkshTemplate.Name);
        ManufacturingSetup.Validate("Subcontracting Batch Name", RequisitionWkshName.Name);
        ManufacturingSetup.Modify();

        // [WHEN] Company defaults are initialized twice.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] The selected worksheet and all configured settings remain unchanged.
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
        VerifyConfiguredSetup(ManufacturingSetup, ReqWkshTemplate.Name, RequisitionWkshName.Name);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. ReqWkshTemplUpgrade Test");
        LibrarySetupStorage.Restore();
    end;

    local procedure PrepareUninitializedSetup(var ManufacturingSetup: Record "Manufacturing Setup")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        if not ManufacturingSetup.Get() then begin
            ManufacturingSetup.Init();
            ManufacturingSetup.Insert(true);
        end;
        Clear(LibrarySetupStorage);
        LibrarySetupStorage.Save(Database::"Manufacturing Setup");
        ManufacturingSetup."Subcontracting Template Name" := '';
        ManufacturingSetup."Subcontracting Batch Name" := '';
        ManufacturingSetup."Create Prod. Order Info Line" := false;
        Clear(ManufacturingSetup."Subc. Comp. Transfer Lead Time");
        ManufacturingSetup."Component Direct Unit Cost" := ManufacturingSetup."Component Direct Unit Cost"::Standard;
        ManufacturingSetup."Subc. Default Comp. Location" := ManufacturingSetup."Subc. Default Comp. Location"::Empty;
        ManufacturingSetup.Modify();

        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::Subcontracting);
        if ReqWkshTemplate.FindSet() then
            repeat
                RequisitionWkshName.SetRange("Worksheet Template Name", ReqWkshTemplate.Name);
                RequisitionWkshName.DeleteAll();
            until ReqWkshTemplate.Next() = 0;
        ReqWkshTemplate.DeleteAll();
    end;

    local procedure CreateConflictingWorksheet(var ReqWkshTemplate: Record "Req. Wksh. Template"; var RequisitionWkshName: Record "Requisition Wksh. Name")
    begin
        RequisitionWkshName.SetRange("Worksheet Template Name", 'SUBCONTR');
        RequisitionWkshName.DeleteAll();
        RequisitionWkshName.Reset();
        ReqWkshTemplate.SetRange(Name, 'SUBCONTR');
        ReqWkshTemplate.DeleteAll();
        ReqWkshTemplate.Reset();

        ReqWkshTemplate.Init();
        ReqWkshTemplate.Validate(Name, 'SUBCONTR');
        ReqWkshTemplate.Validate(Type, ReqWkshTemplate.Type::Planning);
        ReqWkshTemplate.Description := 'Customer planning template';
        ReqWkshTemplate.Insert(true);
        ReqWkshTemplate.Recurring := true;
        ReqWkshTemplate."Increment Batch Name" := true;
        ReqWkshTemplate.Modify();
        Assert.AreEqual(Page::"Planning Worksheet", ReqWkshTemplate."Page ID", 'The conflicting template must retain its Planning page.');
        CreateSubcontractingBatch(RequisitionWkshName, ReqWkshTemplate.Name, 'CUSTOMBAT');
    end;

    local procedure CreateSubcontractingTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; TemplateName: Code[10])
    begin
        ReqWkshTemplate.Init();
        ReqWkshTemplate.Validate(Name, TemplateName);
        ReqWkshTemplate.Validate(Type, ReqWkshTemplate.Type::Subcontracting);
        ReqWkshTemplate.Validate("Page ID", Page::"Subc. Subcontracting Worksheet");
        ReqWkshTemplate.Description := 'Custom template description';
        ReqWkshTemplate.Insert(true);
    end;

    local procedure CreateSubcontractingBatch(var RequisitionWkshName: Record "Requisition Wksh. Name"; TemplateName: Code[10]; BatchName: Code[10])
    begin
        RequisitionWkshName.Init();
        RequisitionWkshName.Validate("Worksheet Template Name", TemplateName);
        RequisitionWkshName.Validate(Name, BatchName);
        RequisitionWkshName.Description := 'Custom batch description';
        RequisitionWkshName.Insert(true);
    end;

    local procedure VerifyDefaultSetup(TemplateName: Code[10]; BatchName: Code[10])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ExpectedLeadTime: DateFormula;
    begin
        ManufacturingSetup.Get();
        Evaluate(ExpectedLeadTime, '<1D>');
        VerifySetupSelections(ManufacturingSetup, TemplateName, BatchName);
        Assert.IsTrue(ManufacturingSetup."Create Prod. Order Info Line", 'Uninitialized setup must enable production order information lines.');
        Assert.AreEqual(ExpectedLeadTime, ManufacturingSetup."Subc. Comp. Transfer Lead Time", 'Uninitialized setup must receive the one-day transfer lead time.');
        Assert.AreEqual(ManufacturingSetup."Component Direct Unit Cost"::Standard, ManufacturingSetup."Component Direct Unit Cost", 'Initialization must retain the standard component cost choice.');
        Assert.AreEqual(ManufacturingSetup."Subc. Default Comp. Location"::Empty, ManufacturingSetup."Subc. Default Comp. Location", 'Initialization must retain the empty component location choice.');
    end;

    local procedure VerifyConfiguredSetup(ExpectedManufacturingSetup: Record "Manufacturing Setup"; TemplateName: Code[10]; BatchName: Code[10])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        VerifySetupSelections(ManufacturingSetup, TemplateName, BatchName);
        Assert.AreEqual(ExpectedManufacturingSetup."Create Prod. Order Info Line", ManufacturingSetup."Create Prod. Order Info Line", 'Initialization must preserve the configured information-line choice.');
        Assert.AreEqual(ExpectedManufacturingSetup."Subc. Comp. Transfer Lead Time", ManufacturingSetup."Subc. Comp. Transfer Lead Time", 'Initialization must preserve the configured transfer lead time, including blank.');
        Assert.AreEqual(ExpectedManufacturingSetup."Component Direct Unit Cost", ManufacturingSetup."Component Direct Unit Cost", 'Initialization must preserve the component cost choice.');
        Assert.AreEqual(ExpectedManufacturingSetup."Subc. Default Comp. Location", ManufacturingSetup."Subc. Default Comp. Location", 'Initialization must preserve the component location choice.');
    end;

    local procedure VerifySetupSelections(ManufacturingSetup: Record "Manufacturing Setup"; TemplateName: Code[10]; BatchName: Code[10])
    begin
        Assert.AreEqual(TemplateName, ManufacturingSetup."Subcontracting Template Name", 'Initialization must select the available Subcontracting template.');
        Assert.AreEqual(BatchName, ManufacturingSetup."Subcontracting Batch Name", 'Initialization must select the available batch under the resolved template.');
    end;

    local procedure VerifySetupHelperResult(SetupAvailable: Boolean; ManufacturingSetup: Record "Manufacturing Setup"; TemplateName: Code[10]; BatchName: Code[10])
    begin
        Assert.IsTrue(SetupAvailable, 'An existing Subcontracting worksheet must make the setup helper succeed.');
        VerifySetupSelections(ManufacturingSetup, TemplateName, BatchName);
    end;

    local procedure VerifyCreatedWorksheet(ReqWkshTemplate: Record "Req. Wksh. Template"; RequisitionWkshName: Record "Requisition Wksh. Name")
    begin
        Assert.AreEqual(ReqWkshTemplate.Type::Subcontracting, ReqWkshTemplate.Type, 'The created template must have the Subcontracting type.');
        Assert.AreEqual(Page::"Subc. Subcontracting Worksheet", ReqWkshTemplate."Page ID", 'The created template must use the Subcontracting worksheet page.');
        Assert.IsFalse(ReqWkshTemplate.Recurring, 'The default template must not be recurring.');
        Assert.AreEqual(ReqWkshTemplate.Name, RequisitionWkshName."Worksheet Template Name", 'The created batch must belong to the created template.');
    end;

    local procedure VerifyAlternativeWorksheet(TemplateName: Code[10])
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshTemplate.Get(TemplateName);
        RequisitionWkshName.Get(TemplateName, 'SUBCONTR');
        VerifyCreatedWorksheet(ReqWkshTemplate, RequisitionWkshName);
        VerifyWorksheetCounts(TemplateName, 1, 1);
    end;

    local procedure VerifyWorksheetUnchanged(ExpectedReqWkshTemplate: Record "Req. Wksh. Template"; ExpectedRequisitionWkshName: Record "Requisition Wksh. Name"; TemplateCount: Integer; BatchCount: Integer)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshTemplate.Get(ExpectedReqWkshTemplate.Name);
        RequisitionWkshName.Get(ExpectedRequisitionWkshName."Worksheet Template Name", ExpectedRequisitionWkshName.Name);
        Assert.AreEqual(ExpectedReqWkshTemplate.SystemId, ReqWkshTemplate.SystemId, 'Initialization must reuse the template identity.');
        Assert.AreEqual(ExpectedReqWkshTemplate.Description, ReqWkshTemplate.Description, 'Initialization must preserve the template description.');
        Assert.AreEqual(ExpectedReqWkshTemplate.Type, ReqWkshTemplate.Type, 'Initialization must preserve the template type.');
        Assert.AreEqual(ExpectedReqWkshTemplate."Page ID", ReqWkshTemplate."Page ID", 'Initialization must preserve the template page.');
        Assert.AreEqual(ExpectedReqWkshTemplate.Recurring, ReqWkshTemplate.Recurring, 'Initialization must preserve the recurring choice.');
        Assert.AreEqual(ExpectedReqWkshTemplate."Increment Batch Name", ReqWkshTemplate."Increment Batch Name", 'Initialization must preserve the increment batch choice.');
        Assert.AreEqual(ExpectedRequisitionWkshName.SystemId, RequisitionWkshName.SystemId, 'Initialization must reuse the batch identity.');
        Assert.AreEqual(ExpectedRequisitionWkshName.Description, RequisitionWkshName.Description, 'Initialization must preserve the batch description.');
        VerifyWorksheetCounts(ReqWkshTemplate.Name, TemplateCount, BatchCount);
    end;

    local procedure VerifyWorksheetCounts(TemplateName: Code[10]; TemplateCount: Integer; BatchCount: Integer)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::Subcontracting);
        RequisitionWkshName.SetRange("Worksheet Template Name", TemplateName);
        Assert.AreEqual(TemplateCount, ReqWkshTemplate.Count(), 'Initialization must not create duplicate Subcontracting templates.');
        Assert.AreEqual(BatchCount, RequisitionWkshName.Count(), 'Initialization must not create duplicate batches under the resolved template.');
    end;

    local procedure CreateReqWkshTemplateWithRawTypeValue(var ReqWkshTemplate: Record "Req. Wksh. Template"; RawTypeValue: Integer)
    var
        ReqWkshTemplateRecordRef: RecordRef;
        TypeFieldRef: FieldRef;
    begin
        ReqWkshTemplate.Init();
        ReqWkshTemplate.Name := CopyStr(LibraryUtility.GenerateRandomCode(ReqWkshTemplate.FieldNo(Name), Database::"Req. Wksh. Template"), 1, MaxStrLen(ReqWkshTemplate.Name));
        ReqWkshTemplate.Insert();

        ReqWkshTemplateRecordRef.GetTable(ReqWkshTemplate);
        TypeFieldRef := ReqWkshTemplateRecordRef.Field(ReqWkshTemplate.FieldNo(Type));
        TypeFieldRef.Value := RawTypeValue;
        ReqWkshTemplateRecordRef.Modify();
    end;

    local procedure CreateReqWkshTemplateWithTypedType(var ReqWkshTemplate: Record "Req. Wksh. Template"; TypeValue: Enum "Req. Worksheet Template Type")
    begin
        ReqWkshTemplate.Init();
        ReqWkshTemplate.Validate(Name, CopyStr(LibraryUtility.GenerateRandomCode(ReqWkshTemplate.FieldNo(Name), Database::"Req. Wksh. Template"), 1, MaxStrLen(ReqWkshTemplate.Name)));
        ReqWkshTemplate.Validate(Type, TypeValue);
        ReqWkshTemplate.Insert(true);
    end;

    local procedure LegacySubcontractingTypeValue(): Integer
    begin
        // Raw value the Subcontracting enum extension value used before the object renumbering (Bug 644283).
        exit(99001500);
    end;
}

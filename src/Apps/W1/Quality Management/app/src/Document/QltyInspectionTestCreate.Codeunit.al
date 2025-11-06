// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Workflow;
using System.Reflection;

codeunit 20404 "Qlty. Inspection Test - Create"
{
    EventSubscriberInstance = Manual;
    InherentPermissions = X;
    Permissions =
        tabledata "Qlty. Inspection Test Header" = Rim,
        tabledata "Qlty. Inspection Test Line" = Rim,
        tabledata "Qlty. I. Grade Condition Conf." = RIM;

    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        LastCreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        RelatedReservFilterReservationEntry: Record "Reservation Entry";
        QltyGenerationRuleMgmt: Codeunit "Qlty. Generation Rule Mgmt.";
        QltyTraversal: Codeunit "Qlty. Traversal";
        LastQltyInspTestCreateStatus: Enum "Qlty. Insp. Test Create Status";
        PreventShowingGeneratedTestEvenIfConfigured: Boolean;
        AvoidThrowingErrorWhenPossible: Boolean;
        ProgrammerErrNotARecordRefErr: Label 'Cannot find tests with %1. Please supply a "Record" or "RecordRef".', Comment = '%1=the variant being supplied that is not a RecordRef. Your system might have an extension or customization that needs to be re-configured.';
        CannotFindTemplateErr: Label 'Cannot find a Quality Inspection Template or Quality Inspection Test Generation Rule to match  %1. Ensure there is a Quality Inspection Test Generation Rule that will match this record.', Comment = '%1=The record identifier';
        UnableToCreateATestForErr: Label 'Unable to create a test for the record [%1], please review the Quality Inspection Source Configuration and also the Quality Inspection Test Generation Rules, you likely need additional configuration to work with this record.', Comment = '%1=the record id of what is being attempted to have a test created for.';
        NoSpecificTemplateTok: Label '', Locked = true;
        MultiRecordTestSourceFieldErr: Label 'Test %1 has been created, however neither %2 nor %4 had applicable source fields to map to the test. Navigate to the Quality Source Configuration for table %3 and apply source field mapping.', Comment = '%1=the test, %2=target record,  %3=the number to set configuration for,%4=triggering record';
        RegisteredLogEventIDTok: Label 'QIERR0001', Locked = true;
        DetailRecordTok: Label 'Target', Locked = true;
        UnableToCreateATestForParentOrChildErr: Label 'Cannot find enough details to make a test for your record(s).  Try making sure that there is a source configuration for your record, and then also make sure there is sufficient information in your test generation rules.  Two tables involved are %1 and %2.', Comment = '%1=the parent table, %2=the child and original table.';
        UnableToCreateATestForRecordErr: Label 'Cannot find enough details to make a test for your record(s).  Try making sure that there is a source configuration for your record, and then also make sure there is sufficient information in your test generation rules.  The table involved is %1.', Comment = '%1=the table involved.';
        RecordShouldBeTemporaryErr: Label 'This code is only intended to run in a temporary fashion. This error is likely occurring from an integration issue.';
        UnknownRecordTok: Label 'Unknown record', Locked = true;

    /// <summary>
    /// Creates a quality inspection test from a variant object using generation rule configuration.
    /// Automatically determines the most appropriate test template based on configured generation rules.
    /// 
    /// The variant can be a Record, RecordRef, or RecordId. The procedure will:
    /// 1. Match against configured generation rules for the record's table
    /// 2. Select appropriate template based on rule conditions
    /// 3. Create test with appropriate source field mapping
    /// 4. Return success/failure status
    /// 
    /// Common usage: Creating tests automatically from triggers or manually from user actions.
    /// </summary>
    /// <param name="ReferenceVariant">The source record (Record, RecordRef, or RecordId) to create a test from</param>
    /// <param name="IsManualCreation">True when user manually creates test; False for automatic/triggered creation</param>
    /// <returns>True if test was successfully created; False if no matching rules or creation failed</returns>
    procedure CreateTestWithVariant(ReferenceVariant: Variant; IsManualCreation: Boolean): Boolean
    begin
        exit(CreateTestWithVariantAndTemplate(ReferenceVariant, IsManualCreation, NoSpecificTemplateTok));
    end;

    /// <summary>
    /// Creates a quality inspection test from a variant object using a specified template.
    /// Bypasses automatic template selection and uses the provided template code directly.
    /// 
    /// Use this when:
    /// - Template is predetermined (not rule-based selection)
    /// - Specific template is required regardless of generation rules
    /// - Manual test creation with user-selected template
    /// 
    /// If OptionalSpecificTemplate is empty, behaves like CreateTestWithVariant (rule-based selection).
    /// </summary>
    /// <param name="ReferenceVariant">The source record (Record, RecordRef, or RecordId) to create a test from</param>
    /// <param name="IsManualCreation">True when user manually creates test; False for automatic/triggered creation</param>
    /// <param name="OptionalSpecificTemplate">The specific template code to use; empty string for rule-based selection</param>
    /// <returns>True if test was successfully created; False if template not found or creation failed</returns>
    procedure CreateTestWithVariantAndTemplate(ReferenceVariant: Variant; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]): Boolean
    var
        Dummy2Variant: Variant;
        Dummy3Variant: Variant;
        Dummy4Variant: Variant;
    begin
        LastQltyInspTestCreateStatus := InternalCreateTestWithVariantAndTemplate(ReferenceVariant, IsManualCreation, OptionalSpecificTemplate, Dummy2Variant, Dummy3Variant, Dummy4Variant);

        exit(LastQltyInspTestCreateStatus = LastQltyInspTestCreateStatus::Created);
    end;

    local procedure InternalCreateTestWithVariantAndTemplate(ReferenceVariant: Variant; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]; OptionalRec2Variant: Variant; OptionalRec3Variant: Variant; OptionalRec4Variant: Variant) QltyInspTestCreateStatus: Enum "Qlty. Insp. Test Create Status"
    var
        TempDummyQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
        DataTypeManagement: Codeunit "Data Type Management";
        TargetRecordRef: RecordRef;
    begin
        if not (ReferenceVariant.IsRecordId() or ReferenceVariant.IsRecordRef() or ReferenceVariant.IsRecord()) then
            exit(QltyInspTestCreateStatus::"Unable to Create");

        if not DataTypeManagement.GetRecordRef(ReferenceVariant, TargetRecordRef) then
            exit(QltyInspTestCreateStatus::"Unable to Create");

        if TargetRecordRef.Number() = 0 then
            exit(QltyInspTestCreateStatus::"Unable to Create");

        exit(InternalCreateTestWithSpecificTemplate(TargetRecordRef, IsManualCreation, OptionalSpecificTemplate, OptionalRec2Variant, OptionalRec3Variant, OptionalRec4Variant, TempDummyQltyInTestGenerationRule));
    end;

    local procedure InternalCreateTestWithGenerationRule(ReferenceVariant: Variant; OptionalRec2Variant: Variant; OptionalRec3Variant: Variant; OptionalRec4Variant: Variant; IsManualCreation: Boolean; var TempFiltersQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary) QltyInspTestCreateStatus: Enum "Qlty. Insp. Test Create Status"
    var
        DataTypeManagement: Codeunit "Data Type Management";
        TargetRecordRef: RecordRef;
    begin
        if not (ReferenceVariant.IsRecordId() or ReferenceVariant.IsRecordRef() or ReferenceVariant.IsRecord()) then
            exit(QltyInspTestCreateStatus::"Unable to Create");

        if not DataTypeManagement.GetRecordRef(ReferenceVariant, TargetRecordRef) then
            exit(QltyInspTestCreateStatus::"Unable to Create");

        if TargetRecordRef.Number() = 0 then
            exit(QltyInspTestCreateStatus::"Unable to Create");

        exit(InternalCreateTestWithSpecificTemplate(TargetRecordRef, IsManualCreation, NoSpecificTemplateTok, OptionalRec2Variant, OptionalRec3Variant, OptionalRec4Variant, TempFiltersQltyInTestGenerationRule));
    end;

    /// <summary>
    /// Creates a test using multiple variant records, attempting each in sequence until successful.
    /// Allows filtering generation rules by auto test creation trigger through the provided generation rule record.
    /// 
    /// Creation strategy:
    /// 1. Try creating test from OptionalRec1Variant with others as additional source context
    /// 2. If fails, try OptionalRec2Variant with others as context
    /// 3. If fails, try OptionalRec3Variant with others as context
    /// 4. If fails, try OptionalRec4Variant with others as context
    /// 5. Return success if any attempt succeeds
    /// 
    /// The TempFiltersQltyInTestGenerationRule parameter allows filtering by auto test creation trigger
    /// (e.g., only create tests configured for "On Post" or "On Ship" triggers).
    /// 
    /// Common usage: Complex scenarios with multiple related records (e.g., Header + Line + Item + Vendor).
    /// </summary>
    /// <param name="OptionalRec1Variant">First record variant to attempt test creation from</param>
    /// <param name="OptionalRec2Variant">Second record variant; used as source context if Rec1 succeeds, otherwise attempted as primary</param>
    /// <param name="OptionalRec3Variant">Third record variant; used as source context or attempted as primary</param>
    /// <param name="OptionalRec4Variant">Fourth record variant; used as source context or attempted as primary</param>
    /// <param name="IsManualCreation">True for manual creation; False for automatic/triggered creation</param>
    /// <param name="TempFiltersQltyInTestGenerationRule">Temporary record with filters to limit which generation rules apply (e.g., filter by Auto Test Creation Trigger)</param>
    /// <returns>True if test was successfully created from any variant; False if all attempts failed</returns>
    procedure CreateTestWithMultiVariants(OptionalRec1Variant: Variant; OptionalRec2Variant: Variant; OptionalRec3Variant: Variant; OptionalRec4Variant: Variant; IsManualCreation: Boolean; var TempFiltersQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary) HasTest: Boolean
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        PreviousAvoidErrorState: Boolean;
        ScenarioIterator: Integer;
    begin
        PreviousAvoidErrorState := AvoidThrowingErrorWhenPossible;
        AvoidThrowingErrorWhenPossible := true;
        ScenarioIterator := 1;
        repeat
            LastQltyInspTestCreateStatus := LastQltyInspTestCreateStatus::Unknown;
            case ScenarioIterator of
                1:
                    LastQltyInspTestCreateStatus := InternalCreateTestWithGenerationRule(OptionalRec1Variant, OptionalRec2Variant, OptionalRec3Variant, OptionalRec4Variant, IsManualCreation, TempFiltersQltyInTestGenerationRule);
                2:
                    LastQltyInspTestCreateStatus := InternalCreateTestWithGenerationRule(OptionalRec2Variant, OptionalRec1Variant, OptionalRec3Variant, OptionalRec4Variant, IsManualCreation, TempFiltersQltyInTestGenerationRule);
                3:
                    LastQltyInspTestCreateStatus := InternalCreateTestWithGenerationRule(OptionalRec3Variant, OptionalRec1Variant, OptionalRec2Variant, OptionalRec4Variant, IsManualCreation, TempFiltersQltyInTestGenerationRule);
                4:
                    begin
                        AvoidThrowingErrorWhenPossible := PreviousAvoidErrorState;
                        LastQltyInspTestCreateStatus := InternalCreateTestWithGenerationRule(OptionalRec4Variant, OptionalRec1Variant, OptionalRec2Variant, OptionalRec3Variant, IsManualCreation, TempFiltersQltyInTestGenerationRule);
                    end;
            end;
            if LastQltyInspTestCreateStatus = LastQltyInspTestCreateStatus::Created then
                HasTest := GetCreatedTest(QltyInspectionTestHeader);
            ScenarioIterator += 1;
        until (ScenarioIterator > 4) or (LastQltyInspTestCreateStatus in [LastQltyInspTestCreateStatus::Created, LastQltyInspTestCreateStatus::Skipped]);

        AvoidThrowingErrorWhenPossible := PreviousAvoidErrorState;
    end;

    procedure CreateTestWithMultiVariantsAndTemplate(OptionalRec1Variant: Variant; OptionalRec2Variant: Variant; OptionalRec3Variant: Variant; OptionalRec4Variant: Variant; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]) HasTest: Boolean
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        PreviousAvoidErrorState: Boolean;
        ScenarioIterator: Integer;
    begin
        PreviousAvoidErrorState := AvoidThrowingErrorWhenPossible;
        AvoidThrowingErrorWhenPossible := true;
        ScenarioIterator := 1;
        repeat
            LastQltyInspTestCreateStatus := LastQltyInspTestCreateStatus::Unknown;
            case ScenarioIterator of
                1:
                    LastQltyInspTestCreateStatus := InternalCreateTestWithVariantAndTemplate(OptionalRec1Variant, IsManualCreation, OptionalSpecificTemplate, OptionalRec2Variant, OptionalRec3Variant, OptionalRec4Variant);
                2:
                    LastQltyInspTestCreateStatus := InternalCreateTestWithVariantAndTemplate(OptionalRec2Variant, IsManualCreation, OptionalSpecificTemplate, OptionalRec1Variant, OptionalRec3Variant, OptionalRec4Variant);
                3:
                    LastQltyInspTestCreateStatus := InternalCreateTestWithVariantAndTemplate(OptionalRec3Variant, IsManualCreation, OptionalSpecificTemplate, OptionalRec1Variant, OptionalRec2Variant, OptionalRec4Variant);
                4:
                    begin
                        AvoidThrowingErrorWhenPossible := PreviousAvoidErrorState;
                        LastQltyInspTestCreateStatus := InternalCreateTestWithVariantAndTemplate(OptionalRec4Variant, IsManualCreation, OptionalSpecificTemplate, OptionalRec1Variant, OptionalRec2Variant, OptionalRec4Variant);
                    end;
            end;
            if LastQltyInspTestCreateStatus = LastQltyInspTestCreateStatus::Created then
                HasTest := GetCreatedTest(QltyInspectionTestHeader);
            ScenarioIterator += 1;
        until (ScenarioIterator > 4) or (LastQltyInspTestCreateStatus in [LastQltyInspTestCreateStatus::Created, LastQltyInspTestCreateStatus::Skipped]);

        AvoidThrowingErrorWhenPossible := PreviousAvoidErrorState;
    end;

    /// <summary>
    /// 
    /// Use this to create a Quality Inspection Test for any given record.
    /// The generatin rule configuration will be used to find the most appropriate
    /// test to create.
    /// 
    /// </summary>
    /// <param name="TargetRecordRef">The record to try and create a test from.</param>
    /// <param name="IsManualCreation">Explicitly set if this test is being manually created or not.</param>
    procedure CreateTest(TargetRecordRef: RecordRef; IsManualCreation: Boolean): Boolean
    var
        Dummy2Variant: Variant;
        Dummy3Variant: Variant;
        Dummy4Variant: Variant;
    begin
        LastQltyInspTestCreateStatus := InternalCreateTestWithVariantAndTemplate(TargetRecordRef, IsManualCreation, NoSpecificTemplateTok, Dummy2Variant, Dummy3Variant, Dummy4Variant);

        exit(LastQltyInspTestCreateStatus = LastQltyInspTestCreateStatus::Created);
    end;

    /// <summary>
    /// If you do not know which template you need, use CreateTest.
    /// If you do know which template you need, then use this procedure.
    /// The caller must know in advance that the template and configuration is correct.
    /// </summary>
    /// <param name="TargetRecordRef">The record to try and create a test from.</param>
    /// <param name="IsManualCreation">Explicitly set if this test is being manually created or not.</param>
    /// <param name="OptionalSpecificTemplate">The specific template to create</param>
    /// <returns></returns>
    procedure CreateTestWithSpecificTemplate(TargetRecordRef: RecordRef; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]): Boolean
    var
        Dummy2Variant: Variant;
        Dummy3Variant: Variant;
    begin
        LastQltyInspTestCreateStatus := InternalCreateTestWithSpecificTemplate(TargetRecordRef, IsManualCreation, OptionalSpecificTemplate, Dummy2Variant, Dummy3Variant);

        exit(LastQltyInspTestCreateStatus = LastQltyInspTestCreateStatus::Created);
    end;

    local procedure InternalCreateTestWithSpecificTemplate(TargetRecordRef: RecordRef; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]; OptionalRec2Variant: Variant; OptionalRec3Variant: Variant): Enum "Qlty. Insp. Test Create Status"
    var
        TempDummyQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
        DummyRec4Variant: Variant;
    begin
        exit(InternalCreateTestWithSpecificTemplate(TargetRecordRef, IsManualCreation, OptionalSpecificTemplate, OptionalRec2Variant, OptionalRec3Variant, DummyRec4Variant, TempDummyQltyInTestGenerationRule));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. In. Test Generation Rule", 'R', InherentPermissionsScope::Both)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Test Header", 'RIM', InherentPermissionsScope::Both)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Test Line", 'RIM', InherentPermissionsScope::Both)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. I. Grade Condition Conf.", 'RIM', InherentPermissionsScope::Both)]
    [InherentPermissions(PermissionObjectType::Codeunit, Codeunit::"Qlty. Permission Mgmt.", 'X', InherentPermissionsScope::Both)]
    [InherentPermissions(PermissionObjectType::Codeunit, Codeunit::"Qlty. Start Workflow", 'X', InherentPermissionsScope::Both)]
    local procedure InternalCreateTestWithSpecificTemplate(TargetRecordRef: RecordRef; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]; OptionalRec2Variant: Variant; OptionalRec3Variant: Variant; OptionalRec4Variant: Variant; var TempFiltersQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary) QltyInspTestCreateStatus: Enum "Qlty. Insp. Test Create Status"
    var
        TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        TempSourceFieldsFilledStubTestBufferQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
        RelatedItem: Record Item;
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
        QltyStartWorkflow: Codeunit "Qlty. Start Workflow";
        RecordRefToBufferTriggeringRecord: RecordRef;
        OriginalRecordId: RecordId;
        NullRecordId: RecordId;
        Handled: Boolean;
        OriginalRecordTableNo: Integer;
        IsNewlyCreatedTest: Boolean;
    begin
        if not QltyManagementSetup.ReadPermission() then
            exit(QltyInspTestCreateStatus::"Unable to Create");
        if not QltyManagementSetup.Get() then
            exit(QltyInspTestCreateStatus::"Unable to Create");

        if QltyManagementSetup.Visibility = QltyManagementSetup.Visibility::Hide then
            exit(QltyInspTestCreateStatus::"Unable to Create");

        if TargetRecordRef.Number() = 0 then
            exit(QltyInspTestCreateStatus::"Unable to Create");

        Clear(LastCreatedQltyInspectionTestHeader);

        TempQltyInTestGenerationRule.CopyFilters(TempFiltersQltyInTestGenerationRule);

        if IsManualCreation then
            QltyPermissionMgmt.TestCanCreateManualTest()
        else
            if not QltyPermissionMgmt.CanCreateAutoTest() then
                exit(QltyInspTestCreateStatus::"Unable to Create");

        OriginalRecordId := TargetRecordRef.RecordId();
        OriginalRecordTableNo := TargetRecordRef.Number();
        RecordRefToBufferTriggeringRecord.Open(TargetRecordRef.Number(), true);
        RecordRefToBufferTriggeringRecord.Copy(TargetRecordRef, false);
        RecordRefToBufferTriggeringRecord.Insert(false);
        OnBeforeCreateTest(TargetRecordRef, IsManualCreation, OptionalSpecificTemplate, Handled, OptionalRec2Variant, OptionalRec3Variant);
        if Handled then
            exit(QltyInspTestCreateStatus::"Unable to Create");

        if TempFiltersQltyInTestGenerationRule."Item Filter" <> '' then
            RelatedItem.SetView(TempFiltersQltyInTestGenerationRule."Item Filter");

        QltyTraversal.FindRelatedItem(RelatedItem, TargetRecordRef, OptionalRec2Variant, OptionalRec3Variant, OptionalRec4Variant);

        if not QltyGenerationRuleMgmt.FindMatchingGenerationRule(IsManualCreation and (not AvoidThrowingErrorWhenPossible), IsManualCreation, TargetRecordRef, RelatedItem, OptionalSpecificTemplate, TempQltyInTestGenerationRule) then
            if OptionalSpecificTemplate = '' then begin
                if IsManualCreation and (not AvoidThrowingErrorWhenPossible) then
                    Error(CannotFindTemplateErr, Format(OriginalRecordId));

                exit(QltyInspTestCreateStatus::"Unable to Create");
            end else begin
                TempQltyInTestGenerationRule."Template Code" := OptionalSpecificTemplate;
                TempQltyInTestGenerationRule."Source Table No." := TargetRecordRef.Number();
            end;

        if (TempSourceFieldsFilledStubTestBufferQltyInspectionTestHeader."Template Code" = '') and (TempQltyInTestGenerationRule."Template Code" <> '') then
            TempSourceFieldsFilledStubTestBufferQltyInspectionTestHeader."Template Code" := TempQltyInTestGenerationRule."Template Code";

        if TargetRecordRef.Number() <> 0 then begin
            if RecordRefToBufferTriggeringRecord.RecordId() <> TargetRecordRef.RecordId() then
                QltyTraversal.ApplySourceFields(RecordRefToBufferTriggeringRecord, TempSourceFieldsFilledStubTestBufferQltyInspectionTestHeader, false, false);
            ApplyAllSourceFieldsToStub(TempSourceFieldsFilledStubTestBufferQltyInspectionTestHeader, TargetRecordRef, OptionalRec2Variant, OptionalRec3Variant, OptionalRec4Variant)
        end else
            ApplyAllSourceFieldsToStub(TempSourceFieldsFilledStubTestBufferQltyInspectionTestHeader, RecordRefToBufferTriggeringRecord, OptionalRec2Variant, OptionalRec3Variant, OptionalRec4Variant);

        if GetExistingOrCreateNewTestFor(TempSourceFieldsFilledStubTestBufferQltyInspectionTestHeader, TargetRecordRef, RecordRefToBufferTriggeringRecord, TempQltyInTestGenerationRule, QltyInspectionTestHeader, IsNewlyCreatedTest) then begin
            QltyInspectionTestHeader.SetIsCreating(true);
            LastCreatedQltyInspectionTestHeader := QltyInspectionTestHeader;
            OnAfterCreateTestBeforeDialog(TargetRecordRef, RecordRefToBufferTriggeringRecord, IsManualCreation, OptionalSpecificTemplate, TempQltyInTestGenerationRule, QltyInspectionTestHeader, Handled, OptionalRec2Variant, OptionalRec3Variant);
            if Handled then
                exit;

            QltyInspTestCreateStatus := QltyInspTestCreateStatus::Created;
            if QltyInspectionTestHeader."Trigger RecordId" = NullRecordId then begin
                QltyInspectionTestHeader."Trigger RecordId" := OriginalRecordId;
                QltyInspectionTestHeader."Trigger Record Table No." := OriginalRecordTableNo;
                QltyInspectionTestHeader.Modify(false);
            end;

            QltyInspectionTestHeader.UpdateGradeFromLines();
            QltyInspectionTestHeader.UpdateBrickFields();

            QltyInspectionTestHeader.SetIsCreating(true);
            QltyInspectionTestHeader.Modify(false);
            QltyInspectionTestLine.Reset();
            QltyInspectionTestLine.SetRange("Test No.", QltyInspectionTestHeader."No.");
            QltyInspectionTestLine.SetRange("Retest No.", QltyInspectionTestHeader."Retest No.");
            if QltyInspectionTestLine.FindSet() then
                repeat
                    QltyInspectionTestLine.UpdateExpressionsInOtherTestLinesInSameTest();
                until QltyInspectionTestLine.Next() = 0;

            QltyInspectionTestHeader.SetIsCreating(false);
            LastCreatedQltyInspectionTestHeader := QltyInspectionTestHeader;

            if IsNewlyCreatedTest then
                QltyStartWorkflow.StartWorkflowTestCreated(QltyInspectionTestHeader);

            if GuiAllowed() then
                if (not PreventShowingGeneratedTestEvenIfConfigured) and
                   ((QltyManagementSetup."Show Test Behavior" = QltyManagementSetup."Show Test Behavior"::"Automatic and manually created tests") or
                   (IsManualCreation and (QltyManagementSetup."Show Test Behavior" = QltyManagementSetup."Show Test Behavior"::"Only manually created tests")))
                then
                    Page.Run(Page::"Qlty. Inspection Test", QltyInspectionTestHeader);
        end else begin
            LogCreateTestProblem(TargetRecordRef, UnableToCreateATestForErr, Format(OriginalRecordId));
            if IsManualCreation and (not AvoidThrowingErrorWhenPossible) then
                Error(UnableToCreateATestForErr, Format(OriginalRecordId));
        end;

        OnAfterCreateTestAfterDialog(TargetRecordRef, RecordRefToBufferTriggeringRecord, IsManualCreation, OptionalSpecificTemplate, TempQltyInTestGenerationRule, QltyInspectionTestHeader, OptionalRec2Variant, OptionalRec3Variant);
    end;

    /// <summary>
    /// Finds an existing test based on the supplied variant, typically a record.
    /// </summary>
    /// <param name="ReferenceVariant">This should be a record, record ref, or record id</param>
    /// <param name="QltyInspectionTestHeader">The created test</param>
    /// <returns></returns>
    procedure FindExistingTestsWithVariant(RaiseErrorIfNoRuleIsFound: Boolean; ReferenceVariant: Variant; var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"): Boolean
    var
        Dummy2Variant: Variant;
        Dummy3Variant: Variant;
        Dummy4Variant: Variant;
    begin
        exit(FindExistingTestsWithMultipleVariants(RaiseErrorIfNoRuleIsFound, ReferenceVariant, Dummy2Variant, Dummy3Variant, Dummy4Variant, QltyInspectionTestHeader));
    end;

    /// <summary>
    /// Finds existing tests based on the multiple variants supplied.
    /// </summary>
    /// <param name="ReferenceVariant"></param>
    /// <param name="OptionalVariant2"></param>
    /// <param name="OptionalVariant3"></param>
    /// <param name="QltyInspectionTestHeader">The created test</param>
    /// <returns></returns>
    internal procedure FindExistingTestsWithMultipleVariants(RaiseErrorIfNoRuleIsFound: Boolean; ReferenceVariant: Variant; OptionalVariant2: Variant; OptionalVariant3: Variant; OptionalVariant4: Variant; var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
        TargetRecordRef: RecordRef;
        Optional2RecordRef: RecordRef;
        Optional3RecordRef: RecordRef;
        Optional4RecordRef: RecordRef;
    begin
        if not DataTypeManagement.GetRecordRef(ReferenceVariant, TargetRecordRef) then
            Error(ProgrammerErrNotARecordRefErr, Format(ReferenceVariant));

        if TargetRecordRef.Number() = 0 then
            Error(ProgrammerErrNotARecordRefErr, Format(ReferenceVariant));

        if not DataTypeManagement.GetRecordRef(OptionalVariant2, Optional2RecordRef) then;
        if not DataTypeManagement.GetRecordRef(OptionalVariant3, Optional3RecordRef) then;
        if not DataTypeManagement.GetRecordRef(OptionalVariant4, Optional4RecordRef) then;
        exit(FindExistingTests(RaiseErrorIfNoRuleIsFound, TargetRecordRef, Optional2RecordRef, Optional3RecordRef, Optional4RecordRef, QltyInspectionTestHeader));
    end;

    /// <summary>
    /// Finds existing tests based on the setup on the quality inspector.
    /// </summary>
    /// <param name="TargetRecordRef">The main target record that the test will be created against</param>
    /// <param name="QltyInspectionTestHeader">The created test</param>
    /// <returns></returns>
    internal procedure FindExistingTests(RaiseErrorIfNoRuleIsFound: Boolean; TargetRecordRef: RecordRef; Optional2RecordRef: RecordRef; Optional3RecordRef: RecordRef; Optional4RecordRef: RecordRef; var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header") Result: Boolean;
    var
        TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
        RelatedItem: Record Item;
        PotentialMatchQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Handled: Boolean;
    begin
        OnBeforeFindExistingTests(TargetRecordRef, Optional2RecordRef, Optional3RecordRef, Optional4RecordRef, QltyInspectionTestHeader, Result, Handled);
        if Handled then
            exit;

        QltyTraversal.FindRelatedItem(RelatedItem, TargetRecordRef, Optional2RecordRef, Optional3RecordRef, Optional4RecordRef);
        if not QltyGenerationRuleMgmt.FindMatchingGenerationRule(false, TargetRecordRef, RelatedItem, NoSpecificTemplateTok, TempQltyInTestGenerationRule) then begin
            LogCreateTestProblem(TargetRecordRef, CannotFindTemplateErr, Format(TargetRecordRef.RecordId()));
            if RaiseErrorIfNoRuleIsFound and (not AvoidThrowingErrorWhenPossible) then
                Error(CannotFindTemplateErr, Format(TargetRecordRef.RecordId()));
        end;

        QltyInspectionTestHeader.Reset();
        TempQltyInTestGenerationRule.Reset();
        if TempQltyInTestGenerationRule.FindSet() then
            repeat
                if FindExistingTest(TargetRecordRef, Optional2RecordRef, Optional3RecordRef, Optional4RecordRef, TempQltyInTestGenerationRule, PotentialMatchQltyInspectionTestHeader, true) then begin
                    Result := true;
                    repeat
                        QltyInspectionTestHeader.SetRange("No.", PotentialMatchQltyInspectionTestHeader."No.");
                        QltyInspectionTestHeader.SetRange("Retest No.", PotentialMatchQltyInspectionTestHeader."Retest No.");
                        if QltyInspectionTestHeader.FindFirst() then
                            QltyInspectionTestHeader.Mark(true);
                    until PotentialMatchQltyInspectionTestHeader.Next() = 0;
                end;
            until TempQltyInTestGenerationRule.Next() = 0
        else begin
            Clear(TempQltyInTestGenerationRule);
            if FindExistingTest(TargetRecordRef, Optional2RecordRef, Optional3RecordRef, Optional4RecordRef, TempQltyInTestGenerationRule, PotentialMatchQltyInspectionTestHeader, true) then begin
                Result := true;
                repeat
                    QltyInspectionTestHeader.SetRange("No.", PotentialMatchQltyInspectionTestHeader."No.");
                    QltyInspectionTestHeader.SetRange("Retest No.", PotentialMatchQltyInspectionTestHeader."Retest No.");
                    if QltyInspectionTestHeader.FindFirst() then
                        QltyInspectionTestHeader.Mark(true);
                until PotentialMatchQltyInspectionTestHeader.Next() = 0;
            end;
        end;
        if Result then begin
            QltyInspectionTestHeader.SetRange("No.");
            QltyInspectionTestHeader.SetRange("Retest No.");
            QltyInspectionTestHeader.MarkedOnly(true);
        end;
    end;

    /// <summary>
    /// Will either find an existing open test, or create a new test.
    /// </summary>
    /// <param name="TargetRecordRef">The main target record that the test will be created against</param>
    /// <param name="TempQltyInTestGenerationRule">The generation rule that helped determine which template to use.</param>
    /// <param name="QltyInspectionTestHeader">The created test</param>
    /// <returns></returns>
    local procedure GetExistingOrCreateNewTestFor(var TempSourceFieldsFilledStubTestBufferQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary; TargetRecordRef: RecordRef; OriginalTriggeringRecordRef: RecordRef; TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary; var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var TestIsNew: Boolean) HasTest: Boolean
    var
        ExistingQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        NeedNewTest: Boolean;
        HasExistingTest: Boolean;
        ShouldCreateRetest: Boolean;
        CouldApplyAnyFields: Boolean;
    begin
        TestIsNew := false;

        QltyManagementSetup.Get();
        if QltyManagementSetup."Create Test Behavior" = QltyManagementSetup."Create Test Behavior"::"Always create new test" then begin
            NeedNewTest := true;
            HasExistingTest := false;
        end else begin
            HasExistingTest := FindExistingTestWithStub(TempSourceFieldsFilledStubTestBufferQltyInspectionTestHeader, TempQltyInTestGenerationRule, ExistingQltyInspectionTestHeader, false);

            case QltyManagementSetup."Create Test Behavior" of
                QltyManagementSetup."Create Test Behavior"::"Always create new test":
                    begin
                        NeedNewTest := true;
                        ShouldCreateRetest := false;
                    end;
                QltyManagementSetup."Create Test Behavior"::"Always create retest":
                    begin
                        ShouldCreateRetest := true;
                        NeedNewTest := true;
                    end;
                QltyManagementSetup."Create Test Behavior"::"Create retest if matching test is finished":
                    if not HasExistingTest then begin
                        NeedNewTest := true;
                        ShouldCreateRetest := false;
                    end else begin
                        NeedNewTest := ExistingQltyInspectionTestHeader.Status = ExistingQltyInspectionTestHeader.Status::Finished;
                        ShouldCreateRetest := ExistingQltyInspectionTestHeader.Status = ExistingQltyInspectionTestHeader.Status::Finished;
                        HasTest := not NeedNewTest;
                    end;
                QltyManagementSetup."Create Test Behavior"::"Use existing open test if available":
                    if not HasExistingTest then begin
                        NeedNewTest := true;
                        ShouldCreateRetest := false;
                    end else begin
                        NeedNewTest := ExistingQltyInspectionTestHeader.Status = ExistingQltyInspectionTestHeader.Status::Finished;
                        ShouldCreateRetest := false;
                        HasTest := not NeedNewTest;
                    end;
                QltyManagementSetup."Create Test Behavior"::"Use any existing test if available":
                    begin
                        NeedNewTest := not HasExistingTest;
                        ShouldCreateRetest := false;
                    end;
                else
                    OnCustomCreateTestBehavior(TargetRecordRef, OriginalTriggeringRecordRef, TempQltyInTestGenerationRule, HasExistingTest, ExistingQltyInspectionTestHeader, NeedNewTest, ShouldCreateRetest);
            end;
        end;
        if NeedNewTest then begin
            QltyInspectionTestHeader.Init();
            QltyInspectionTestHeader.SetIsCreating(true);
            if HasExistingTest and ShouldCreateRetest then
                InitRetestHeader(ExistingQltyInspectionTestHeader, QltyInspectionTestHeader);

            QltyInspectionTestHeader.TransferFields(TempSourceFieldsFilledStubTestBufferQltyInspectionTestHeader, false);
            QltyInspectionTestHeader.Validate("Template Code", TempQltyInTestGenerationRule."Template Code");

            QltyInspectionTestHeader."Source RecordId" := TargetRecordRef.RecordId();
            QltyInspectionTestHeader."Source Record Table No." := TargetRecordRef.Number();
            QltyInspectionTestHeader."Trigger RecordId" := OriginalTriggeringRecordRef.RecordId();
            QltyInspectionTestHeader."Trigger Record Table No." := OriginalTriggeringRecordRef.Number();
            QltyInspectionTestHeader."Source Table No." := TargetRecordRef.Number();
            QltyInspectionTestHeader.SetIsCreating(true);

            if OriginalTriggeringRecordRef.RecordId() <> TargetRecordRef.RecordId() then
                CouldApplyAnyFields := QltyTraversal.ApplySourceFields(OriginalTriggeringRecordRef, QltyInspectionTestHeader, false, false);

            CouldApplyAnyFields := CouldApplyAnyFields or QltyTraversal.ApplySourceFields(TargetRecordRef, QltyInspectionTestHeader, false, false);
            if not CouldApplyAnyFields then
                if OriginalTriggeringRecordRef.RecordId() <> TargetRecordRef.RecordId() then
                    Message(MultiRecordTestSourceFieldErr, QltyInspectionTestHeader."No.", TargetRecordRef.RecordId(), TargetRecordRef.Number(), OriginalTriggeringRecordRef.RecordId());

            HasTest := QltyInspectionTestHeader.Insert(true);
            TestIsNew := true;
            CreateQualityTestResultLinesFromTemplate(QltyInspectionTestHeader);
        end else
            if HasExistingTest then
                if QltyInspectionTestHeader.Get(ExistingQltyInspectionTestHeader."No.", ExistingQltyInspectionTestHeader."Retest No.") then begin
                    QltyInspectionTestHeader.SetRecFilter();
                    HasTest := true;
                end;

        exit(HasTest);
    end;

    /// <summary>
    /// This will create the Quality Inspection Test lines for the given header.
    /// </summary>
    /// <param name="QltyInspectionTestHeader">The quality inspection test involved</param>
    local procedure CreateQualityTestResultLinesFromTemplate(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        QltyGradeConditionMgmt: Codeunit "Qlty. Grade Condition Mgmt.";
        QltyGradeEvaluation: Codeunit "Qlty. Grade Evaluation";
    begin
        QltyInspectionTemplateLine.SetRange("Template Code", QltyInspectionTestHeader."Template Code");
        QltyInspectionTemplateLine.SetAutoCalcFields("Allowable Values");
        if QltyInspectionTemplateLine.FindSet() then
            repeat
                QltyInspectionTestLine.Init();
                QltyInspectionTestLine."Template Code" := QltyInspectionTestHeader."Template Code";
                QltyInspectionTestLine."Template Line No." := QltyInspectionTemplateLine."Line No.";
                QltyInspectionTestLine."Test No." := QltyInspectionTestHeader."No.";
                QltyInspectionTestLine."Retest No." := QltyInspectionTestHeader."Retest No.";
                QltyInspectionTestLine."Line No." := QltyInspectionTemplateLine."Line No.";

                QltyInspectionTestLine.Validate("Field Code", QltyInspectionTemplateLine."Field Code");
                QltyInspectionTestLine.Description := QltyInspectionTemplateLine.Description;
                QltyInspectionTemplateLine.CalcFields("Allowable Values");
                QltyInspectionTestLine."Allowable Values" := QltyInspectionTemplateLine."Allowable Values";
                QltyInspectionTestLine."Unit of Measure Code" := QltyInspectionTemplateLine."Unit of Measure Code";
                QltyInspectionTestLine.Insert();
                QltyGradeConditionMgmt.CopyGradeConditionsFromTemplateToTest(QltyInspectionTemplateLine, QltyInspectionTestLine);
                QltyInspectionTestHeader.SetPreventAutoAssignment(true);
            until QltyInspectionTemplateLine.Next() = 0;

        QltyInspectionTestLine.Reset();
        QltyInspectionTestLine.SetRange("Test No.", QltyInspectionTestHeader."No.");
        QltyInspectionTestLine.SetRange("Retest No.", QltyInspectionTestHeader."Retest No.");
        if QltyInspectionTestLine.FindSet(true) then
            repeat
                if QltyGradeEvaluation.TryValidateTestLine(QltyInspectionTestLine, QltyInspectionTestHeader) then begin
                    QltyInspectionTestLine.Modify(true);
                    QltyInspectionTestHeader.Modify(true);
                end;
            until QltyInspectionTestLine.Next() = 0;

        QltyInspectionTestHeader.SetPreventAutoAssignment(false);
    end;

    /// <summary>
    /// Finds an existing test using optionally supplied variants of records/recordids/recordrefs
    /// </summary>
    /// <param name="TargetRecordRef"></param>
    /// <param name="OptionalVariant2">Must be a recordid,recordref,or record</param>
    /// <param name="OptionalVariant3">Must be a recordid,recordref,or record</param>
    /// <param name="OptionalVariant4">Must be a recordid,recordref,or record</param>
    /// <param name="TempQltyInTestGenerationRule">Must be a recordid,recordref,or record</param>
    /// <param name="ExistingQltyInspectionTestHeader"></param>
    /// <param name="FindAll"></param>
    /// <returns></returns>
    procedure FindExistingTestWithVariant(TargetRecordRef: RecordRef; OptionalVariant2: Variant; OptionalVariant3: Variant; OptionalVariant4: Variant; TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary; var ExistingQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; FindAll: Boolean): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
        Optional2RecordRef: RecordRef;
        Optional3RecordRef: RecordRef;
        Optional4RecordRef: RecordRef;
    begin
        if not DataTypeManagement.GetRecordRef(OptionalVariant2, Optional2RecordRef) then;
        if not DataTypeManagement.GetRecordRef(OptionalVariant3, Optional3RecordRef) then;
        if not DataTypeManagement.GetRecordRef(OptionalVariant4, Optional4RecordRef) then;
        exit(FindExistingTest(TargetRecordRef, Optional2RecordRef, Optional3RecordRef, Optional4RecordRef, TempQltyInTestGenerationRule, ExistingQltyInspectionTestHeader, FindAll));
    end;

    /// <summary>
    /// Finds an existing test that matches the source criteria.
    /// If there are multiple tests finds the retest.
    /// </summary>
    /// <param name="TargetRecordRef">The main target record that the test will be created against</param>
    /// <param name="TempQltyInTestGenerationRule">The generation rule that helped determine which template to use.</param>
    /// <param name="ExistingQltyInspectionTestHeader"></param>
    /// <returns></returns>
    procedure FindExistingTest(TargetRecordRef: RecordRef; Optional2RecordRef: RecordRef; Optional3RecordRef: RecordRef; Optional4RecordRef: RecordRef; TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary; var ExistingQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; FindAll: Boolean): Boolean
    var
        TempInStubSearchForSimilarTestBufferQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary;
    begin
        if not QltyManagementSetup.Get() then
            exit(false);

        ExistingQltyInspectionTestHeader.Reset();
        ApplyAllSourceFieldsToStub(TempInStubSearchForSimilarTestBufferQltyInspectionTestHeader, TargetRecordRef, Optional2RecordRef, Optional3RecordRef, Optional4RecordRef);

        exit(FindExistingTestWithStub(TempInStubSearchForSimilarTestBufferQltyInspectionTestHeader, TempQltyInTestGenerationRule, ExistingQltyInspectionTestHeader, FindAll));
    end;

    local procedure FindExistingTestWithStub(var TempInStubSearchForSimilarTestBufferQltyInspectionTestHeader: Record "Qlty. Inspection Test Header" temporary; var TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary; var ExistingQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; FindAll: Boolean): Boolean
    begin
        if not QltyManagementSetup.Get() then
            exit(false);

        if (TempQltyInTestGenerationRule."Template Code" <> '') and (TempInStubSearchForSimilarTestBufferQltyInspectionTestHeader."Template Code" = '') then
            TempInStubSearchForSimilarTestBufferQltyInspectionTestHeader."Template Code" := TempQltyInTestGenerationRule."Template Code";

        ExistingQltyInspectionTestHeader.TransferFields(TempInStubSearchForSimilarTestBufferQltyInspectionTestHeader, false);
        case QltyManagementSetup."Find Existing Behavior" of
            QltyManagementSetup."Find Existing Behavior"::"By Standard Source Fields":
                ExistingQltyInspectionTestHeader.SetCurrentKey("Template Code", "Source Table No.", "Source Type", "Source Sub Type", "Source Document No.", "Source Document Line No.", "Source Item No.", "Source Variant Code", "Source Serial No.", "Source Lot No.", "Source Task No.", "Source Package No.");
            QltyManagementSetup."Find Existing Behavior"::"By Source Record":
                ExistingQltyInspectionTestHeader.SetCurrentKey("Template Code", "Source RecordId", "Source Record Table No.");
            QltyManagementSetup."Find Existing Behavior"::"By Item Tracking":
                ExistingQltyInspectionTestHeader.SetCurrentKey("Source Item No.", "Source Variant Code", "Source Serial No.", "Source Lot No.", "Template Code", "Source Package No.");
            QltyManagementSetup."Find Existing Behavior"::"By Document and Item only":
                ExistingQltyInspectionTestHeader.SetCurrentKey("Source Document No.", "Source Document Line No.", "Source Item No.", "Source Variant Code");
        end;

        ExistingQltyInspectionTestHeader.SetRecFilter();
        ExistingQltyInspectionTestHeader.SetRange("No.");
        ExistingQltyInspectionTestHeader.SetRange("Retest No.");
        ExistingQltyInspectionTestHeader.SetRange("Template Code");

        if QltyManagementSetup."Find Existing Behavior" <> QltyManagementSetup."Find Existing Behavior"::"By Source Record" then
            ExistingQltyInspectionTestHeader.SetRange("Source Table No.");

        if QltyManagementSetup."Find Existing Behavior" = QltyManagementSetup."Find Existing Behavior"::"By Document and Item only" then begin
            ExistingQltyInspectionTestHeader.SetRange("Source Lot No.");
            ExistingQltyInspectionTestHeader.SetRange("Source Serial No.");
            ExistingQltyInspectionTestHeader.SetRange("Source Package No.");
        end;

        ExistingQltyInspectionTestHeader.SetCurrentKey("No.", "Retest No.");
        if FindAll then
            exit(ExistingQltyInspectionTestHeader.FindSet())
        else
            exit(ExistingQltyInspectionTestHeader.FindLast());
    end;

    /// <summary>
    /// Use this to create a Retest.
    /// </summary>
    /// <param name="FromThisQltyInspectionTestHeader"></param>
    /// <param name="CreatedRetestQltyInspectionTestHeader"></param>
    procedure CreateRetest(FromThisQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var CreatedRetestQltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    var
        ExistingQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        Handled: Boolean;
    begin
        QltyManagementSetup.Get();

        OnBeforeCreateRetest(FromThisQltyInspectionTestHeader, CreatedRetestQltyInspectionTestHeader, Handled);
        if Handled then
            exit;

        ExistingQltyInspectionTestHeader.SetRange("No.", FromThisQltyInspectionTestHeader."No.");
        ExistingQltyInspectionTestHeader.SetCurrentKey("No.", "Retest No.");
        ExistingQltyInspectionTestHeader.FindLast();

        InitRetestHeader(ExistingQltyInspectionTestHeader, CreatedRetestQltyInspectionTestHeader);
        CreatedRetestQltyInspectionTestHeader.Insert(true);
        CreateQualityTestResultLinesFromTemplate(CreatedRetestQltyInspectionTestHeader);

        LastCreatedQltyInspectionTestHeader := CreatedRetestQltyInspectionTestHeader;

        if GuiAllowed() then
            if QltyManagementSetup."Show Test Behavior" in [QltyManagementSetup."Show Test Behavior"::"Automatic and manually created tests", QltyManagementSetup."Show Test Behavior"::"Only manually created tests"] then
                Page.Run(Page::"Qlty. Inspection Test", CreatedRetestQltyInspectionTestHeader);

        OnAfterCreateRetest(FromThisQltyInspectionTestHeader, CreatedRetestQltyInspectionTestHeader);
    end;

    local procedure InitRetestHeader(FromThisQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var CreatedRetestQltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    begin
        CreatedRetestQltyInspectionTestHeader.Init();
        CreatedRetestQltyInspectionTestHeader."No." := FromThisQltyInspectionTestHeader."No.";
        CreatedRetestQltyInspectionTestHeader."Retest No." := FromThisQltyInspectionTestHeader."Retest No." + 1;
        CreatedRetestQltyInspectionTestHeader.Validate("Template Code", CreatedRetestQltyInspectionTestHeader."Template Code");
        CreatedRetestQltyInspectionTestHeader.TransferFields(FromThisQltyInspectionTestHeader, false);
        CreatedRetestQltyInspectionTestHeader.Status := CreatedRetestQltyInspectionTestHeader.Status::Open;
        CreatedRetestQltyInspectionTestHeader."Finished By User ID" := '';
        CreatedRetestQltyInspectionTestHeader."Finished Date" := 0DT;
        CreatedRetestQltyInspectionTestHeader.Validate("Grade Code", '');
    end;

    /// <summary>
    /// 
    /// Returns the last created test in the scope of the instance of this codeunit.
    /// Only use if you just called one of the CreateTest() procedures.
    /// 
    /// </summary>
    /// <param name="LastCreatedQltyInspectionTestHeader2"></param>
    /// <returns>True if the last created test is available and exists. Returns false if no test was created previously or is othewise no longer available.</returns>
    procedure GetCreatedTest(var LastCreatedQltyInspectionTestHeader2: Record "Qlty. Inspection Test Header") StillExists: Boolean
    begin
        if LastCreatedQltyInspectionTestHeader."No." = '' then
            exit;

        LastCreatedQltyInspectionTestHeader2 := LastCreatedQltyInspectionTestHeader;
        LastCreatedQltyInspectionTestHeader2.SetRecFilter();
        StillExists := LastCreatedQltyInspectionTestHeader2.FindFirst();
    end;

    /// <summary>
    /// Returns the last created status.
    /// </summary>
    /// <returns></returns>
    procedure GetLastCreatedStatus(): Enum "Qlty. Insp. Test Create Status"
    begin
        exit(LastQltyInspTestCreateStatus);
    end;

    /// <summary>
    /// Use this to log QIERR0001
    /// </summary>
    /// <param name="ContextRecordRef"></param>
    /// <param name="Input"></param>
    /// <param name="Variable1"></param>
    local procedure LogCreateTestProblem(ContextRecordRef: RecordRef; Input: Text; Variable1: Text)
    var
        DetailRecord: Text;
    begin
        if ContextRecordRef.Number() <> 0 then
            DetailRecord := Format(ContextRecordRef.RecordId())
        else
            DetailRecord := UnknownRecordTok;

        LogMessage(RegisteredLogEventIDTok, StrSubstNo(Input, Variable1), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, DetailRecordTok, DetailRecord);
    end;

    /// <summary>
    /// Use this with Marked records.
    /// </summary>
    /// <param name="TempTrackingSpecification">You must mark your records as a pre-requisite.</param>
    internal procedure CreateMultipleTestsForMarkedTrackingSpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        TempNotUsedOptionalFiltersQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
        TempRecCopyOfTrackingSpecificationRecordRef: RecordRef;
    begin
        Clear(TempRecCopyOfTrackingSpecificationRecordRef);
        TempRecCopyOfTrackingSpecificationRecordRef.Open(Database::"Tracking Specification", true);
        if not TempRecCopyOfTrackingSpecificationRecordRef.IsTemporary() then
            Error(RecordShouldBeTemporaryErr);
        TempTrackingSpecification.MarkedOnly();
        if TempTrackingSpecification.FindSet() then
            repeat
                TempRecCopyOfTrackingSpecificationRecordRef.Copy(TempTrackingSpecification, false);
                TempRecCopyOfTrackingSpecificationRecordRef.Insert();
            until TempTrackingSpecification.Next() = 0;

        CreateMultipleTestsForMultipleRecords(TempRecCopyOfTrackingSpecificationRecordRef, true, TempNotUsedOptionalFiltersQltyInTestGenerationRule);
    end;

    internal procedure CreateMultipleTestsForMultipleRecords(var SetOfRecordsRecordRef: RecordRef; IsManualCreation: Boolean)
    var
        TempDummyFiltersQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
    begin
        CreateMultipleTestsForMultipleRecords(SetOfRecordsRecordRef, IsManualCreation, TempDummyFiltersQltyInTestGenerationRule);
    end;

    internal procedure CreateMultipleTestsForMultipleRecords(var SetOfRecordsRecordRef: RecordRef; IsManualCreation: Boolean; var TempFiltersQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary)
    var
        Createds: List of [Code[20]];
    begin
        CreateMultipleTestsWithoutDisplaying(SetOfRecordsRecordRef, IsManualCreation, TempFiltersQltyInTestGenerationRule, Createds);

        if IsManualCreation and GuiAllowed() then
            DisplayTestsIfConfigured(IsManualCreation, Createds);
    end;

    internal procedure DisplayTestsIfConfigured(IsManualCreation: Boolean; var Createds: List of [Code[20]])
    var
        CreatedQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        TestNo: Code[20];
        PipeSeparatedFilter: Text;
    begin
        QltyManagementSetup.Get();

        if GuiAllowed() and
           ((QltyManagementSetup."Show Test Behavior" in [QltyManagementSetup."Show Test Behavior"::"Automatic and manually created tests"]) or
           (IsManualCreation and (QltyManagementSetup."Show Test Behavior" in [QltyManagementSetup."Show Test Behavior"::"Only manually created tests"])))
        then begin
            foreach TestNo in Createds do
                if TestNo <> '' then begin
                    if StrLen(PipeSeparatedFilter) > 1 then
                        PipeSeparatedFilter += '|';
                    PipeSeparatedFilter += TestNo;
                end;

            CreatedQltyInspectionTestHeader.SetFilter("No.", PipeSeparatedFilter);
            if Createds.Count() = 1 then begin
                CreatedQltyInspectionTestHeader.SetCurrentKey("No.", "Retest No.");
                CreatedQltyInspectionTestHeader.FindLast();
                Page.Run(Page::"Qlty. Inspection Test", CreatedQltyInspectionTestHeader);
            end else begin
                CreatedQltyInspectionTestHeader.FindSet();
                Page.Run(Page::"Qlty. Inspection Test List", CreatedQltyInspectionTestHeader);
            end;
        end;
    end;


    /// <summary>
    /// Use this if you need to keep track of multiple tests without displaying the results.
    /// </summary>
    /// <param name="SetOfRecordsRecordRef"></param>
    /// <param name="IsManualCreation"></param>
    /// <param name="ptrecOptionalFiltersGenerationRule"></param>
    /// <param name="Createds"></param>
    internal procedure CreateMultipleTestsWithoutDisplaying(var SetOfRecordsRecordRef: RecordRef; IsManualCreation: Boolean; var TempFiltersQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary; var Createds: List of [Code[20]])
    var
        TempCopyOfSingleRecordRecordRef: RecordRef;
        ParentRecordRef: RecordRef;
        FailedTests: List of [Text];
        CountOfTestsCreatedForLine: Integer;
    begin
        QltyManagementSetup.Get();

        if SetOfRecordsRecordRef.IsTemporary() then
            SetOfRecordsRecordRef.Reset();
        if SetOfRecordsRecordRef.Findset() then
            repeat
                Clear(TempCopyOfSingleRecordRecordRef);
                TempCopyOfSingleRecordRecordRef.Open(SetOfRecordsRecordRef.Number(), true);

                TempCopyOfSingleRecordRecordRef.Copy(SetOfRecordsRecordRef, false);
                TempCopyOfSingleRecordRecordRef.Insert(false);
                CountOfTestsCreatedForLine := CreateTestForSelfOrDirectParent(
                    TempCopyOfSingleRecordRecordRef,
                    TempFiltersQltyInTestGenerationRule,
                    ParentRecordRef,
                    Createds,
                    true,
                    IsManualCreation);
                if CountOfTestsCreatedForLine = 0 then
                    FailedTests.Add(Format(SetOfRecordsRecordRef.RecordId()));
            until SetOfRecordsRecordRef.Next() = 0;

        if Createds.Count() = 0 then begin
            if AvoidThrowingErrorWhenPossible then
                exit;

            if ParentRecordRef.Number() <> 0 then
                Error(UnableToCreateATestForParentOrChildErr, ParentRecordRef.Name, SetOfRecordsRecordRef.Name)
            else
                Error(UnableToCreateATestForRecordErr, SetOfRecordsRecordRef.Name);
        end;
    end;

    local procedure CreateTestForSelfOrDirectParent(var TempSelfRecordRef: RecordRef; var TempFiltersQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary; var FoundParentRecordRef: RecordRef; var CreatedTestNoList: List of [Code[20]]; PreventTestFromDisplayingEvenIfConfigured: Boolean; IsManualCreation: Boolean) TestsCreated: Integer
    var
        LastCreatedQltyInspectionTestHeader2: Record "Qlty. Inspection Test Header";
        Item: Record Item;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        LocalQltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
        ReservationManagement: Codeunit "Reservation Management";
        ParentRecordRef: RecordRef;
        VariantEmptyOrTrackingSpecification: Variant;
        Dummy4Variant: Variant;
    begin
        TestsCreated := 0;

        LocalQltyInspectionTestCreate.SetPreventDisplayingTestEvenIfConfigured(PreventTestFromDisplayingEvenIfConfigured);

        Clear(FoundParentRecordRef);
        if QltyTraversal.FindSingleParentRecord(TempSelfRecordRef, ParentRecordRef) then begin
            FoundParentRecordRef.Open(ParentRecordRef.Number());
            FoundParentRecordRef.Get(ParentRecordRef.RecordId());
        end;
        Clear(Item);
        Clear(RelatedReservFilterReservationEntry);
        Clear(VariantEmptyOrTrackingSpecification);
        RelatedReservFilterReservationEntry.SetRange("Entry No.", -1);

        if TempFiltersQltyInTestGenerationRule."Item Filter" <> '' then begin
            Item.FilterGroup(20);
            Item.SetView(TempFiltersQltyInTestGenerationRule."Item Filter");
            Item.FilterGroup(0);
        end;

        if QltyTraversal.FindRelatedItem(Item, ParentRecordRef, TempSelfRecordRef, VariantEmptyOrTrackingSpecification, Dummy4Variant) then begin
            if (Item."No." <> '') and (TempFiltersQltyInTestGenerationRule."Item Attribute Filter" <> '') then
                if not QltyGenerationRuleMgmt.DoesMatchItemAttributeFiltersOrNoFilter(TempFiltersQltyInTestGenerationRule, Item) then
                    exit;

            if QltyItemTracking.IsLotTracked(Item."No.") or QltyItemTracking.IsSerialTracked(Item."No.") or QltyItemTracking.IsPackageTracked(Item."No.") then begin
                BindSubscription(this);
                ReservationManagement.SetReservSource(ParentRecordRef);
                UnbindSubscription(this);
                RelatedReservFilterReservationEntry.SetRange("Entry No.");
                RelatedReservFilterReservationEntry.SetRange("Source ID", RelatedReservFilterReservationEntry."Source ID");
                RelatedReservFilterReservationEntry.SetRange("Source Ref. No.", RelatedReservFilterReservationEntry."Source Ref. No.");
                RelatedReservFilterReservationEntry.SetRange("Source Type", RelatedReservFilterReservationEntry."Source Type");
                RelatedReservFilterReservationEntry.SetRange("Source Subtype", RelatedReservFilterReservationEntry."Source Subtype");
                RelatedReservFilterReservationEntry.SetRange("Source Batch Name", RelatedReservFilterReservationEntry."Source Batch Name");
                RelatedReservFilterReservationEntry.SetRange("Source Prod. Order Line", RelatedReservFilterReservationEntry."Source Prod. Order Line");

                case TempSelfRecordRef.Number() of
                    Database::"Tracking Specification":
                        begin
                            TempSelfRecordRef.SetTable(TempTrackingSpecification);
                            RelatedReservFilterReservationEntry.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
                            RelatedReservFilterReservationEntry.SetRange("Serial No.", TempTrackingSpecification."Serial No.");
                            RelatedReservFilterReservationEntry.SetRange("Package No.", TempTrackingSpecification."Package No.");
                        end;
                    else
                        RelatedReservFilterReservationEntry.SetFilter("Qty. to Handle (Base)", '>0');
                end;
            end;

            RelatedReservFilterReservationEntry.SetRange("Item No.", Item."No.");
            if RelatedReservFilterReservationEntry.FindSet() then;
            repeat
                Clear(VariantEmptyOrTrackingSpecification);
                if RelatedReservFilterReservationEntry."Item No." <> '' then begin
                    Clear(TempTrackingSpecification);
                    TempTrackingSpecification.DeleteAll(false);
                    TempTrackingSpecification.SetSourceFromReservEntry(RelatedReservFilterReservationEntry);
                    TempTrackingSpecification.CopyTrackingFromReservEntry(RelatedReservFilterReservationEntry);
                    TempTrackingSpecification.Insert();
                    VariantEmptyOrTrackingSpecification := TempTrackingSpecification;
                end;

                if LocalQltyInspectionTestCreate.CreateTestWithMultiVariants(ParentRecordRef, TempSelfRecordRef, VariantEmptyOrTrackingSpecification, Dummy4Variant, IsManualCreation, TempFiltersQltyInTestGenerationRule) then
                    if LocalQltyInspectionTestCreate.GetCreatedTest(LastCreatedQltyInspectionTestHeader2) then begin
                        TestsCreated += 1;
                        if not CreatedTestNoList.Contains(LastCreatedQltyInspectionTestHeader2."No.") then
                            CreatedTestNoList.Add(LastCreatedQltyInspectionTestHeader2."No.");
                    end;
            until RelatedReservFilterReservationEntry.Next() = 0;
        end else begin
            if TempFiltersQltyInTestGenerationRule."Item Filter" <> '' then begin
                Clear(Item);
                if QltyTraversal.FindRelatedItem(Item, ParentRecordRef, TempSelfRecordRef, VariantEmptyOrTrackingSpecification, Dummy4Variant) then
                    exit;
            end;

            if LocalQltyInspectionTestCreate.CreateTestWithMultiVariants(TempSelfRecordRef, ParentRecordRef, Dummy4Variant, Dummy4Variant, IsManualCreation, TempFiltersQltyInTestGenerationRule) then
                if LocalQltyInspectionTestCreate.GetCreatedTest(LastCreatedQltyInspectionTestHeader2) then begin
                    TestsCreated += 1;
                    if not CreatedTestNoList.Contains(LastCreatedQltyInspectionTestHeader2."No.") then
                        CreatedTestNoList.Add(LastCreatedQltyInspectionTestHeader2."No.");
                end;
        end;
    end;

    internal procedure SetPreventDisplayingTestEvenIfConfigured(PreventTestFromDisplayingEvenIfConfigured: Boolean)
    begin
        PreventShowingGeneratedTestEvenIfConfigured := PreventTestFromDisplayingEvenIfConfigured;
    end;

    /// <summary>
    /// Stubs in and filles the source config fields.
    /// </summary>
    /// <param name="TestStubToFillQualityOrder"></param>
    /// <param name="MandatoryPrimaryRecordRef"></param>
    /// <param name="OptionalVariant2"></param>
    /// <param name="OptionalVariant3"></param>
    /// <param name="OptionalVariant4"></param>
    /// <returns></returns>
    local procedure ApplyAllSourceFieldsToStub(var TestStubToFillQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; MandatoryPrimaryRecordRef: RecordRef; OptionalVariant2: Variant; OptionalVariant3: Variant; OptionalVariant4: Variant): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
        Optional2RecordRef: RecordRef;
        Optional3RecordRef: RecordRef;
        Optional4RecordRef: RecordRef;
    begin
        if not DataTypeManagement.GetRecordRef(OptionalVariant2, Optional2RecordRef) then;
        if not DataTypeManagement.GetRecordRef(OptionalVariant3, Optional3RecordRef) then;
        if not DataTypeManagement.GetRecordRef(OptionalVariant4, Optional4RecordRef) then;

        if MandatoryPrimaryRecordRef.Number() <> 0 then begin
            TestStubToFillQltyInspectionTestHeader."Source Table No." := MandatoryPrimaryRecordRef.Number();
            TestStubToFillQltyInspectionTestHeader."Source Record Table No." := MandatoryPrimaryRecordRef.Number();
            QltyTraversal.ApplySourceFields(MandatoryPrimaryRecordRef, TestStubToFillQltyInspectionTestHeader, false, false);
            TestStubToFillQltyInspectionTestHeader."Source RecordId" := MandatoryPrimaryRecordRef.RecordId();
        end;

        if Optional2RecordRef.Number() <> 0 then begin
            QltyTraversal.ApplySourceFields(Optional2RecordRef, TestStubToFillQltyInspectionTestHeader, false, false);
            TestStubToFillQltyInspectionTestHeader."Source RecordId 2" := Optional2RecordRef.RecordId();
        end;

        if Optional3RecordRef.Number() <> 0 then begin
            QltyTraversal.ApplySourceFields(Optional3RecordRef, TestStubToFillQltyInspectionTestHeader, false, false);
            TestStubToFillQltyInspectionTestHeader."Source RecordId 3" := Optional3RecordRef.RecordId();
        end;

        if Optional4RecordRef.Number() <> 0 then begin
            QltyTraversal.ApplySourceFields(Optional4RecordRef, TestStubToFillQltyInspectionTestHeader, false, false);
            TestStubToFillQltyInspectionTestHeader."Source RecordId 4" := Optional4RecordRef.RecordId();
        end;
    end;

    #region Event Subscribers

    /// <summary>
    /// Used with BindSubscription to help find related reservation entries.
    /// </summary>
    /// <param name="SourceRecRef"></param>
    /// <param name="CalcReservEntry"></param>
    /// <param name="Direction"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Management", 'OnAfterSetReservSource', '', true, true)]
    local procedure HandleReservationManagementOnAfterSetReservSource(var SourceRecRef: RecordRef; var CalcReservEntry: Record "Reservation Entry"; var Direction: Enum "Transfer Direction")
    begin
        RelatedReservFilterReservationEntry := CalcReservEntry;
    end;

    #endregion Event Subscribers

    /// <summary>
    /// OnBeforeCreateTest is called before a test is created.
    /// Use this event to do additional checks before a test is created.
    /// </summary>
    /// <param name="TargetRecordRef">The main target record that the test will be created against</param>
    /// <param name="IsManualCreation">True when the test is being manually created and not automatically triggered</param>
    /// <param name="OptionalSpecificTemplate">When supplied refers to a specific desired template</param>
    /// <param name="OptionalRec2Variant">For complex automation can be additional source records</param>
    /// <param name="OptionalRec3Variant">For complex automation can be additional source records</param>
    /// <param name="IsHandled">Set to true to replace the default behavior, set to false to extend it and continue</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTest(var TargetRecordRef: RecordRef; var IsManualCreation: Boolean; var OptionalSpecificTemplate: Code[20]; var IsHandled: Boolean; var OptionalRec2Variant: Variant; var OptionalRec3Variant: Variant)
    begin
    end;

    /// <summary>
    /// OnAfterCreateTestBeforeDialog gets called after a Quality Inspection Test has been created and
    /// before any interactive dialog is shown.
    /// </summary>
    /// <param name="TargetRecordRef">The main target record that the test will be created against</param>
    /// <param name="TriggeringRecordRef">Typically the same as the target record ref. Used in complex customizations.</param>
    /// <param name="IsManualCreation">True when the test is being manually created and not automatically triggered</param>
    /// <param name="OptionalSpecificTemplate">When supplied refers to a specific desired template</param>
    /// <param name="TempQltyInTestGenerationRule">The generation rule that helped determine which template to use.</param>
    /// <param name="QualityOrder">The quality inspection test</param>
    /// <param name="IsHandled">Set to true to replace the default behavior, set to false to extend it and continue</param>
    /// <param name="OptionalRec2Variant">For complex automation can be additional source records</param>
    /// <param name="OptionalRec3Variant">For complex automation can be additional source records</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTestBeforeDialog(var TargetRecordRef: RecordRef; var TriggeringRecordRef: RecordRef; var IsManualCreation: Boolean; var OptionalSpecificTemplate: Code[20]; var TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary; var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var IsHandled: Boolean; var OptionalRec2Variant: Variant; var OptionalRec3Variant: Variant)
    begin
    end;

    /// <summary>
    /// OnAfterCreateTestAfterDialog gets called after a Quality Inspection Test has been created after any interactive dialog is shown
    /// </summary>
    /// <param name="TargetRecordRef">The main target record that the test will be created against</param>
    /// <param name="TriggeringRecordRef">Typically the same as the target record ref. Used in complex customizations.</param>
    /// <param name="IsManualCreation">True when the test is being manually created and not automatically triggered</param>
    /// <param name="OptionalSpecificTemplate">When supplied refers to a specific desired template</param>
    /// <param name="TempQltyInTestGenerationRule">The generation rule that helped determine which template to use.</param>
    /// <param name="QualityOrder">The quality inspection test</param>
    /// <param name="OptionalRec2Variant">For complex automation can be additional source records</param>
    /// <param name="OptionalRec3Variant">For complex automation can be additional source records</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateTestAfterDialog(var TargetRecordRef: RecordRef; var TriggeringRecordRef: RecordRef; var IsManualCreation: Boolean; var OptionalSpecificTemplate: Code[20]; var TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary; var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var OptionalRec2Variant: Variant; var OptionalRec3Variant: Variant)
    begin
    end;

    /// <summary>
    /// Implement OnCustomCreateTestBehavior if you have also extended enum 20402 "Qlty. Create Test Behavior"
    /// This is where you will provide any custom create test behaviors to match your enum extension.
    /// Only set handled to true if you want to skip the remaining behavior.
    /// </summary>
    /// <param name="TargetRecordRef">The record the test is being created against</param>
    /// <param name="OriginalTriggeringRecordRef">The record that triggered the test</param>
    /// <param name="TempQltyInTestGenerationRule">The generation rule</param>
    /// <param name="HasExistingTest">Whether it has an existing test</param>
    /// <param name="ExistingQltyInspectionTestHeader">Optionally an existing test that matches</param>
    /// <param name="NeedNewTest">Choose whether it should need a new test</param>
    /// <param name="ShouldCreateRetest">Choose whether it should create a Retest</param>
    [IntegrationEvent(false, false)]
    local procedure OnCustomCreateTestBehavior(var TargetRecordRef: RecordRef; var OriginalTriggeringRecordRef: RecordRef; var TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary; var HasExistingTest: Boolean; var ExistingQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var NeedNewTest: Boolean; var ShouldCreateRetest: Boolean)
    begin
    end;

    /// <summary>
    /// OnBeforeCreateRetest supplies an opportunity to change how manual Retests are performed.
    /// </summary>
    /// <param name="FromThisQltyInspectionTestHeader">Which test the retest is being requested to be created from</param>
    /// <param name="CreatedReQltyInspectionTestHeader">If you are setting Handled to true you must supply a valid retest record here.</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateRetest(var FromThisQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var CreatedReQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var Handled: Boolean)
    begin
    end;

    /// <summary>
    /// OnAfterCreateRetest gives an opportunity to integrate with the retest record after a manual retest is created.
    /// </summary>
    /// <param name="FromThisQltyInspectionTestHeader">Which test the retest is being requested to be created from</param>
    /// <param name="CreatedReQltyInspectionTestHeader">The created retest</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateRetest(var FromThisQltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var CreatedReQltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    begin
    end;

    /// <summary>
    /// OnBeforeFindExistingTests provides an opportunity to override how an existing test is found.
    /// </summary>
    /// <param name="TargetRecordRef">The main target record that the test will be created against</param>
    /// <param name="Optional2RecordRef">Optional.  Some events, typically automatic events, will have multiple records to assist with setting source details.</param>
    /// <param name="Optional3RecordRef">Optional.  Some events, typically automatic events, will have multiple records to assist with setting source details.</param>
    /// <param name="Optional4RecordRef">Optional.  Some events, typically automatic events, will have multiple records to assist with setting source details.</param>
    /// <param name="QltyInspectionTestHeader">The found test</param>
    /// <param name="Result">Set to true if you found the record. If you set to true you must also supply QltyInspectionTestHeader</param>
    /// <param name="Handled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindExistingTests(TargetRecordRef: RecordRef; Optional2RecordRef: RecordRef; Optional3RecordRef: RecordRef; Optional4RecordRef: RecordRef; var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var Result: Boolean; var Handled: Boolean)
    begin
    end;
}

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
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Integration.Inventory;
using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Utilities;
using Microsoft.QualityManagement.Workflow;
using System.Reflection;

codeunit 20404 "Qlty. Inspection - Create"
{
    EventSubscriberInstance = Manual;
    InherentPermissions = X;
    Permissions =
        tabledata "Qlty. Inspection Header" = Rim,
        tabledata "Qlty. Inspection Line" = Rim,
        tabledata "Qlty. I. Result Condit. Conf." = RIM;

    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        LastCreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        RelatedReservFilterReservationEntry: Record "Reservation Entry";
        QltyInspecGenRuleMgmt: Codeunit "Qlty. Inspec. Gen. Rule Mgmt.";
        QltyTraversal: Codeunit "Qlty. Traversal";
        LastQltyInspectionCreateStatus: Enum "Qlty. Inspection Create Status";
        PreventShowingGeneratedInspectionEvenIfConfigured: Boolean;
        AvoidThrowingErrorWhenPossible: Boolean;
        ProgrammerErrNotARecordRefErr: Label 'Cannot find inspections with %1. Please supply a "Record" or "RecordRef".', Comment = '%1=the variant being supplied that is not a RecordRef. Your system might have an extension or customization that needs to be re-configured.';
        CannotFindTemplateErr: Label 'Cannot find a Quality Inspection Template or Quality Inspection Generation Rule to match %1. Ensure there is a Quality Inspection Generation Rule that will match this record.', Comment = '%1=The record identifier';
        UnableToCreateInspectionForErr: Label 'Unable to create an inspection for the record [%1], please review the Quality Inspection Source Configuration and also the Quality Inspection Generation Rules, you likely need additional configuration to work with this record.', Comment = '%1=the record id of what is being attempted to have an inspection created for.';
        NoSpecificTemplateTok: Label '', Locked = true;
        MultiRecordInspectionSourceFieldErr: Label 'Inspection %1 has been created, however neither %2 nor %4 had applicable source fields to map to the inspection. Navigate to the Quality Source Configuration for table %3 and apply source field mapping.', Comment = '%1=the inspection, %2=target record,  %3=the number to set configuration for,%4=triggering record';
        RegisteredLogEventIDTok: Label 'QMERR0001', Locked = true;
        DetailRecordTok: Label 'Target', Locked = true;
        UnableToCreateInspectionForParentOrChildErr: Label 'Cannot find enough details to make an inspection for your record(s).  Try making sure that there is a source configuration for your record, and then also make sure there is sufficient information in your inspection generation rules.  Two tables involved are %1 and %2.', Comment = '%1=the parent table, %2=the child and original table.';
        UnableToCreateInspectionForRecordErr: Label 'Cannot find enough details to make an inspection for your record(s).  Try making sure that there is a source configuration for your record, and then also make sure there is sufficient information in your inspection generation rules.  The table involved is %1.', Comment = '%1=the table involved.';
        RecordShouldBeTemporaryErr: Label 'This code is only intended to run in a temporary fashion. This error is likely occurring from an integration issue.';
        UnknownRecordTok: Label 'Unknown record', Locked = true;

    /// <summary>
    /// Creates a quality inspection from a variant object using generation rule configuration.
    /// Automatically determines the most appropriate inspection template based on configured generation rules.
    /// 
    /// The variant can be a Record, RecordRef, or RecordId. The procedure will:
    /// 1. Match against configured generation rules for the record's table
    /// 2. Select appropriate template based on rule conditions
    /// 3. Create inspection with appropriate source field mapping
    /// 4. Return success/failure status
    /// 
    /// Common usage: Creating inspections automatically from triggers or manually from user actions.
    /// </summary>
    /// <param name="ReferenceVariant">The source record (Record, RecordRef, or RecordId) to create an inspection from</param>
    /// <param name="IsManualCreation">True when user manually creates inspection; False for automatic/triggered creation</param>
    /// <returns>True if inspection was successfully created; False if no matching rules or creation failed</returns>
    internal procedure CreateInspectionWithVariant(ReferenceVariant: Variant; IsManualCreation: Boolean): Boolean
    begin
        exit(CreateInspectionWithVariantAndTemplate(ReferenceVariant, IsManualCreation, NoSpecificTemplateTok));
    end;

    /// <summary>
    /// Creates a quality inspection from a variant object using a specified template.
    /// Bypasses automatic template selection and uses the provided template code directly.
    /// 
    /// Use this when:
    /// - Template is predetermined (not rule-based selection)
    /// - Specific template is required regardless of generation rules
    /// - Manual inspection creation with user-selected template
    /// 
    /// If OptionalSpecificTemplate is empty, behaves like CreateInspectionWithVariant (rule-based selection).
    /// </summary>
    /// <param name="ReferenceVariant">The source record (Record, RecordRef, or RecordId) to create an inspection from</param>
    /// <param name="IsManualCreation">True when user manually creates inspection; False for automatic/triggered creation</param>
    /// <param name="OptionalSpecificTemplate">The specific template code to use; empty string for rule-based selection</param>
    /// <returns>True if inspection was successfully created; False if template not found or creation failed</returns>
    internal procedure CreateInspectionWithVariantAndTemplate(ReferenceVariant: Variant; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]): Boolean
    var
        Dummy2Variant: Variant;
        Dummy3Variant: Variant;
        Dummy4Variant: Variant;
    begin
        LastQltyInspectionCreateStatus := InternalCreateInspectionWithVariantAndTemplate(ReferenceVariant, IsManualCreation, OptionalSpecificTemplate, Dummy2Variant, Dummy3Variant, Dummy4Variant);

        exit(LastQltyInspectionCreateStatus = LastQltyInspectionCreateStatus::Created);
    end;

    local procedure InternalCreateInspectionWithVariantAndTemplate(ReferenceVariant: Variant; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]; OptionalRec2Variant: Variant; OptionalRec3Variant: Variant; OptionalRec4Variant: Variant) QltyInspectionCreateStatus: Enum "Qlty. Inspection Create Status"
    var
        TempDummyQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        TargetRecordRef: RecordRef;
    begin
        if not (ReferenceVariant.IsRecordId() or ReferenceVariant.IsRecordRef() or ReferenceVariant.IsRecord()) then
            exit(QltyInspectionCreateStatus::"Unable to Create");

        if not QltyMiscHelpers.GetRecordRefFromVariant(ReferenceVariant, TargetRecordRef) then
            exit(QltyInspectionCreateStatus::"Unable to Create");

        exit(InternalCreateInspectionWithSpecificTemplate(TargetRecordRef, IsManualCreation, OptionalSpecificTemplate, OptionalRec2Variant, OptionalRec3Variant, OptionalRec4Variant, TempDummyQltyInspectionGenRule));
    end;

    local procedure InternalCreateInspectionWithGenerationRule(ReferenceVariant: Variant; OptionalRec2Variant: Variant; OptionalRec3Variant: Variant; OptionalRec4Variant: Variant; IsManualCreation: Boolean; var TempFiltersQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary) QltyInspectionCreateStatus: Enum "Qlty. Inspection Create Status"
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        TargetRecordRef: RecordRef;
    begin
        if not (ReferenceVariant.IsRecordId() or ReferenceVariant.IsRecordRef() or ReferenceVariant.IsRecord()) then
            exit(QltyInspectionCreateStatus::"Unable to Create");

        if not QltyMiscHelpers.GetRecordRefFromVariant(ReferenceVariant, TargetRecordRef) then
            exit(QltyInspectionCreateStatus::"Unable to Create");

        exit(InternalCreateInspectionWithSpecificTemplate(TargetRecordRef, IsManualCreation, NoSpecificTemplateTok, OptionalRec2Variant, OptionalRec3Variant, OptionalRec4Variant, TempFiltersQltyInspectionGenRule));
    end;

    /// <summary>
    /// Creates an inspection using multiple variant records, attempting each in sequence until successful.
    /// Allows filtering generation rules by auto inspection creation trigger through the provided generation rule record.
    /// 
    /// Creation strategy:
    /// 1. Try creating inspection from OptionalRec1Variant with others as additional source context
    /// 2. If fails, try OptionalRec2Variant with others as context
    /// 3. If fails, try OptionalRec3Variant with others as context
    /// 4. If fails, try OptionalRec4Variant with others as context
    /// 5. Return success if any attempt succeeds
    /// 
    /// The TempFiltersQltyInspectionGenRule parameter allows filtering by auto inspection creation trigger
    /// (e.g., only create inspections configured for "On Post" or "On Ship" triggers).
    /// 
    /// Common usage: Complex scenarios with multiple related records (e.g., Header + Line + Item + Vendor).
    /// </summary>
    /// <param name="OptionalRec1Variant">First record variant to attempt inspection creation from</param>
    /// <param name="OptionalRec2Variant">Second record variant; used as source context if Rec1 succeeds, otherwise attempted as primary</param>
    /// <param name="OptionalRec3Variant">Third record variant; used as source context or attempted as primary</param>
    /// <param name="OptionalRec4Variant">Fourth record variant; used as source context or attempted as primary</param>
    /// <param name="IsManualCreation">True for manual creation; False for automatic/triggered creation</param>
    /// <param name="TempFiltersQltyInspectionGenRule">Temporary record with filters to limit which generation rules apply (e.g., filter by Auto Inspection Creation Trigger)</param>
    /// <returns>True if inspection was successfully created from any variant; False if all attempts failed</returns>
    internal procedure CreateInspectionWithMultiVariants(OptionalRec1Variant: Variant; OptionalRec2Variant: Variant; OptionalRec3Variant: Variant; OptionalRec4Variant: Variant; IsManualCreation: Boolean; var TempFiltersQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary) HasInspection: Boolean
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PreviousAvoidErrorState: Boolean;
        ScenarioIterator: Integer;
    begin
        PreviousAvoidErrorState := AvoidThrowingErrorWhenPossible;
        AvoidThrowingErrorWhenPossible := true;
        ScenarioIterator := 1;
        repeat
            LastQltyInspectionCreateStatus := LastQltyInspectionCreateStatus::Unknown;
            case ScenarioIterator of
                1:
                    LastQltyInspectionCreateStatus := InternalCreateInspectionWithGenerationRule(OptionalRec1Variant, OptionalRec2Variant, OptionalRec3Variant, OptionalRec4Variant, IsManualCreation, TempFiltersQltyInspectionGenRule);
                2:
                    LastQltyInspectionCreateStatus := InternalCreateInspectionWithGenerationRule(OptionalRec2Variant, OptionalRec1Variant, OptionalRec3Variant, OptionalRec4Variant, IsManualCreation, TempFiltersQltyInspectionGenRule);
                3:
                    LastQltyInspectionCreateStatus := InternalCreateInspectionWithGenerationRule(OptionalRec3Variant, OptionalRec1Variant, OptionalRec2Variant, OptionalRec4Variant, IsManualCreation, TempFiltersQltyInspectionGenRule);
                4:
                    begin
                        AvoidThrowingErrorWhenPossible := PreviousAvoidErrorState;
                        LastQltyInspectionCreateStatus := InternalCreateInspectionWithGenerationRule(OptionalRec4Variant, OptionalRec1Variant, OptionalRec2Variant, OptionalRec3Variant, IsManualCreation, TempFiltersQltyInspectionGenRule);
                    end;
            end;
            if LastQltyInspectionCreateStatus = LastQltyInspectionCreateStatus::Created then
                HasInspection := GetCreatedInspection(QltyInspectionHeader);
            ScenarioIterator += 1;
        until (ScenarioIterator > 4) or (LastQltyInspectionCreateStatus in [LastQltyInspectionCreateStatus::Created, LastQltyInspectionCreateStatus::Skipped]);

        AvoidThrowingErrorWhenPossible := PreviousAvoidErrorState;
    end;

    internal procedure CreateInspectionWithMultiVariantsAndTemplate(OptionalRec1Variant: Variant; OptionalRec2Variant: Variant; OptionalRec3Variant: Variant; OptionalRec4Variant: Variant; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]) HasInspection: Boolean
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PreviousAvoidErrorState: Boolean;
        ScenarioIterator: Integer;
    begin
        PreviousAvoidErrorState := AvoidThrowingErrorWhenPossible;
        AvoidThrowingErrorWhenPossible := true;
        ScenarioIterator := 1;
        repeat
            LastQltyInspectionCreateStatus := LastQltyInspectionCreateStatus::Unknown;
            case ScenarioIterator of
                1:
                    LastQltyInspectionCreateStatus := InternalCreateInspectionWithVariantAndTemplate(OptionalRec1Variant, IsManualCreation, OptionalSpecificTemplate, OptionalRec2Variant, OptionalRec3Variant, OptionalRec4Variant);
                2:
                    LastQltyInspectionCreateStatus := InternalCreateInspectionWithVariantAndTemplate(OptionalRec2Variant, IsManualCreation, OptionalSpecificTemplate, OptionalRec1Variant, OptionalRec3Variant, OptionalRec4Variant);
                3:
                    LastQltyInspectionCreateStatus := InternalCreateInspectionWithVariantAndTemplate(OptionalRec3Variant, IsManualCreation, OptionalSpecificTemplate, OptionalRec1Variant, OptionalRec2Variant, OptionalRec4Variant);
                4:
                    begin
                        AvoidThrowingErrorWhenPossible := PreviousAvoidErrorState;
                        LastQltyInspectionCreateStatus := InternalCreateInspectionWithVariantAndTemplate(OptionalRec4Variant, IsManualCreation, OptionalSpecificTemplate, OptionalRec1Variant, OptionalRec2Variant, OptionalRec4Variant);
                    end;
            end;
            if LastQltyInspectionCreateStatus = LastQltyInspectionCreateStatus::Created then
                HasInspection := GetCreatedInspection(QltyInspectionHeader);
            ScenarioIterator += 1;
        until (ScenarioIterator > 4) or (LastQltyInspectionCreateStatus in [LastQltyInspectionCreateStatus::Created, LastQltyInspectionCreateStatus::Skipped]);

        AvoidThrowingErrorWhenPossible := PreviousAvoidErrorState;
    end;

    /// <summary>
    /// 
    /// Use this to create a Quality Inspection for any given record.
    /// The generatin rule configuration will be used to find the most appropriate
    /// inspection to create.
    /// 
    /// </summary>
    /// <param name="TargetRecordRef">The record to try and create an inspection from.</param>
    /// <param name="IsManualCreation">Explicitly set if this inspection is being manually created or not.</param>
    internal procedure CreateInspection(TargetRecordRef: RecordRef; IsManualCreation: Boolean): Boolean
    var
        Dummy2Variant: Variant;
        Dummy3Variant: Variant;
        Dummy4Variant: Variant;
    begin
        LastQltyInspectionCreateStatus := InternalCreateInspectionWithVariantAndTemplate(TargetRecordRef, IsManualCreation, NoSpecificTemplateTok, Dummy2Variant, Dummy3Variant, Dummy4Variant);

        exit(LastQltyInspectionCreateStatus = LastQltyInspectionCreateStatus::Created);
    end;

    /// <summary>
    /// If you do not know which template you need, use CreateInspection.
    /// If you do know which template you need, then use this procedure.
    /// The caller must know in advance that the template and configuration is correct.
    /// </summary>
    /// <param name="TargetRecordRef">The record to try and create an inspection from.</param>
    /// <param name="IsManualCreation">Explicitly set if this inspection is being manually created or not.</param>
    /// <param name="OptionalSpecificTemplate">The specific template to create</param>
    /// <returns></returns>
    internal procedure CreateInspectionWithSpecificTemplate(TargetRecordRef: RecordRef; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]): Boolean
    var
        Dummy2Variant: Variant;
        Dummy3Variant: Variant;
    begin
        LastQltyInspectionCreateStatus := InternalCreateInspectionWithSpecificTemplate(TargetRecordRef, IsManualCreation, OptionalSpecificTemplate, Dummy2Variant, Dummy3Variant);

        exit(LastQltyInspectionCreateStatus = LastQltyInspectionCreateStatus::Created);
    end;

    local procedure InternalCreateInspectionWithSpecificTemplate(TargetRecordRef: RecordRef; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]; OptionalRec2Variant: Variant; OptionalRec3Variant: Variant): Enum "Qlty. Inspection Create Status"
    var
        TempDummyQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        DummyRec4Variant: Variant;
    begin
        exit(InternalCreateInspectionWithSpecificTemplate(TargetRecordRef, IsManualCreation, OptionalSpecificTemplate, OptionalRec2Variant, OptionalRec3Variant, DummyRec4Variant, TempDummyQltyInspectionGenRule));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Gen. Rule", 'R', InherentPermissionsScope::Both)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Header", 'RIM', InherentPermissionsScope::Both)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Line", 'RIM', InherentPermissionsScope::Both)]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. I. Result Condit. Conf.", 'RIM', InherentPermissionsScope::Both)]
    [InherentPermissions(PermissionObjectType::Codeunit, Codeunit::"Qlty. Permission Mgmt.", 'X', InherentPermissionsScope::Both)]
    [InherentPermissions(PermissionObjectType::Codeunit, Codeunit::"Qlty. Start Workflow", 'X', InherentPermissionsScope::Both)]
    local procedure InternalCreateInspectionWithSpecificTemplate(TargetRecordRef: RecordRef; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]; OptionalRec2Variant: Variant; OptionalRec3Variant: Variant; OptionalRec4Variant: Variant; var TempFiltersQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary) QltyInspectionCreateStatus: Enum "Qlty. Inspection Create Status"
    var
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        TempSourceFieldsFilledStubInspectionBufferQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        RelatedItem: Record Item;
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
        QltyStartWorkflow: Codeunit "Qlty. Start Workflow";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        RecordRefToBufferTriggeringRecord: RecordRef;
        OriginalRecordId: RecordId;
        NullRecordId: RecordId;
        IsHandled: Boolean;
        OriginalRecordTableNo: Integer;
        IsNewlyCreatedInspection: Boolean;
    begin
        case true of
            TargetRecordRef.Number() = 0,
            not QltyManagementSetup.GetSetupRecord():
                exit(QltyInspectionCreateStatus::"Unable to Create");
        end;

        Clear(LastCreatedQltyInspectionHeader);

        TempQltyInspectionGenRule.CopyFilters(TempFiltersQltyInspectionGenRule);

        if IsManualCreation then
            QltyPermissionMgmt.VerifyCanCreateManualInspection();

        OriginalRecordId := TargetRecordRef.RecordId();
        OriginalRecordTableNo := TargetRecordRef.Number();
        RecordRefToBufferTriggeringRecord.Open(TargetRecordRef.Number(), true);
        RecordRefToBufferTriggeringRecord.Copy(TargetRecordRef, false);
        RecordRefToBufferTriggeringRecord.Insert(false);
        OnBeforeCreateInspection(TargetRecordRef, IsManualCreation, OptionalSpecificTemplate, IsHandled, OptionalRec2Variant, OptionalRec3Variant);
        if IsHandled then
            exit(QltyInspectionCreateStatus::"Unable to Create");

        if TempFiltersQltyInspectionGenRule."Item Filter" <> '' then
            RelatedItem.SetView(TempFiltersQltyInspectionGenRule."Item Filter");

        QltyTraversal.FindRelatedItem(RelatedItem, TargetRecordRef, OptionalRec2Variant, OptionalRec3Variant, OptionalRec4Variant);

        if not QltyInspecGenRuleMgmt.FindMatchingGenerationRule(IsManualCreation and (not AvoidThrowingErrorWhenPossible), IsManualCreation, TargetRecordRef, RelatedItem, OptionalSpecificTemplate, TempQltyInspectionGenRule) then
            if OptionalSpecificTemplate = '' then begin
                if IsManualCreation and (not AvoidThrowingErrorWhenPossible) then
                    Error(CannotFindTemplateErr, Format(OriginalRecordId));

                exit(QltyInspectionCreateStatus::"Unable to Create");
            end else begin
                TempQltyInspectionGenRule."Template Code" := OptionalSpecificTemplate;
                TempQltyInspectionGenRule."Source Table No." := TargetRecordRef.Number();
            end;

        if (TempSourceFieldsFilledStubInspectionBufferQltyInspectionHeader."Template Code" = '') and (TempQltyInspectionGenRule."Template Code" <> '') then
            TempSourceFieldsFilledStubInspectionBufferQltyInspectionHeader."Template Code" := TempQltyInspectionGenRule."Template Code";

        if TargetRecordRef.Number() <> 0 then begin
            if RecordRefToBufferTriggeringRecord.RecordId() <> TargetRecordRef.RecordId() then
                QltyTraversal.ApplySourceFields(RecordRefToBufferTriggeringRecord, TempSourceFieldsFilledStubInspectionBufferQltyInspectionHeader, false, false);
            ApplyAllSourceFieldsToStub(TempSourceFieldsFilledStubInspectionBufferQltyInspectionHeader, TargetRecordRef, OptionalRec2Variant, OptionalRec3Variant, OptionalRec4Variant)
        end else
            ApplyAllSourceFieldsToStub(TempSourceFieldsFilledStubInspectionBufferQltyInspectionHeader, RecordRefToBufferTriggeringRecord, OptionalRec2Variant, OptionalRec3Variant, OptionalRec4Variant);

        if GetExistingOrCreateNewInspectionFor(TempSourceFieldsFilledStubInspectionBufferQltyInspectionHeader, TargetRecordRef, RecordRefToBufferTriggeringRecord, TempQltyInspectionGenRule, QltyInspectionHeader, IsNewlyCreatedInspection) then begin
            QltyInspectionHeader.SetIsCreating(true);
            LastCreatedQltyInspectionHeader := QltyInspectionHeader;
            OnAfterCreateInspectionBeforeDialog(TargetRecordRef, RecordRefToBufferTriggeringRecord, IsManualCreation, OptionalSpecificTemplate, TempQltyInspectionGenRule, QltyInspectionHeader, OptionalRec2Variant, OptionalRec3Variant);

            QltyInspectionCreateStatus := QltyInspectionCreateStatus::Created;
            if QltyInspectionHeader."Trigger RecordId" = NullRecordId then begin
                QltyInspectionHeader."Trigger RecordId" := OriginalRecordId;
                QltyInspectionHeader."Trigger Record Table No." := OriginalRecordTableNo;
                QltyInspectionHeader.Modify(false);
            end;

            QltyInspectionHeader.UpdateResultFromLines();

            QltyInspectionHeader.SetIsCreating(true);
            QltyInspectionHeader.Modify(false);
            QltyInspectionLine.Reset();
            QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
            QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
            if QltyInspectionLine.FindSet() then
                repeat
                    QltyInspectionLine.UpdateExpressionsInOtherInspectionLinesInSameInspection();
                until QltyInspectionLine.Next() = 0;

            QltyInspectionHeader.SetIsCreating(false);
            LastCreatedQltyInspectionHeader := QltyInspectionHeader;

            if IsNewlyCreatedInspection then
                QltyStartWorkflow.StartWorkflowInspectionCreated(QltyInspectionHeader);

            if GuiAllowed() and not PreventShowingGeneratedInspectionEvenIfConfigured
                and (QltyInspectionHeader."No." <> '') then
                if IsManualCreation then
                    Page.Run(Page::"Qlty. Inspection", QltyInspectionHeader)
                else
                    QltyNotificationMgmt.NotifyInspectionCreated(QltyInspectionHeader);
        end else begin
            LogCreateInspectionProblem(TargetRecordRef, UnableToCreateInspectionForErr, Format(OriginalRecordId));
            if IsManualCreation and (not AvoidThrowingErrorWhenPossible) then
                Error(UnableToCreateInspectionForErr, Format(OriginalRecordId));
        end;

        OnAfterCreateInspectionAfterDialog(TargetRecordRef, RecordRefToBufferTriggeringRecord, IsManualCreation, OptionalSpecificTemplate, TempQltyInspectionGenRule, QltyInspectionHeader, OptionalRec2Variant, OptionalRec3Variant);
    end;

    /// <summary>
    /// Finds an existing inspection based on the supplied variant, typically a record.
    /// </summary>
    /// <param name="ReferenceVariant">This should be a record, record ref, or record id</param>
    /// <param name="QltyInspectionHeader">The created inspection</param>
    /// <returns></returns>
    internal procedure FindExistingInspectionWithVariant(RaiseErrorIfNoRuleIsFound: Boolean; ReferenceVariant: Variant; var QltyInspectionHeader: Record "Qlty. Inspection Header"): Boolean
    var
        Dummy2Variant: Variant;
        Dummy3Variant: Variant;
        Dummy4Variant: Variant;
    begin
        exit(FindExistingInspectionWithMultipleVariants(RaiseErrorIfNoRuleIsFound, ReferenceVariant, Dummy2Variant, Dummy3Variant, Dummy4Variant, QltyInspectionHeader));
    end;

    /// <summary>
    /// Finds existing inspections based on the multiple variants supplied.
    /// </summary>
    /// <param name="ReferenceVariant"></param>
    /// <param name="OptionalVariant2"></param>
    /// <param name="OptionalVariant3"></param>
    /// <param name="QltyInspectionHeader">The created inspection</param>
    /// <returns></returns>
    internal procedure FindExistingInspectionWithMultipleVariants(RaiseErrorIfNoRuleIsFound: Boolean; ReferenceVariant: Variant; OptionalVariant2: Variant; OptionalVariant3: Variant; OptionalVariant4: Variant; var QltyInspectionHeader: Record "Qlty. Inspection Header"): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        TargetRecordRef: RecordRef;
        Optional2RecordRef: RecordRef;
        Optional3RecordRef: RecordRef;
        Optional4RecordRef: RecordRef;
    begin
        if not QltyMiscHelpers.GetRecordRefFromVariant(ReferenceVariant, TargetRecordRef) then
            Error(ProgrammerErrNotARecordRefErr, Format(ReferenceVariant));

        if not DataTypeManagement.GetRecordRef(OptionalVariant2, Optional2RecordRef) then;
        if not DataTypeManagement.GetRecordRef(OptionalVariant3, Optional3RecordRef) then;
        if not DataTypeManagement.GetRecordRef(OptionalVariant4, Optional4RecordRef) then;
        exit(FindExistingInspection(RaiseErrorIfNoRuleIsFound, TargetRecordRef, Optional2RecordRef, Optional3RecordRef, Optional4RecordRef, QltyInspectionHeader));
    end;

    /// <summary>
    /// Finds existing inspections based on the setup on the quality inspector.
    /// </summary>
    /// <param name="TargetRecordRef">The main target record that the inspection will be created against</param>
    /// <param name="QltyInspectionHeader">The created inspection</param>
    /// <returns></returns>
    internal procedure FindExistingInspection(RaiseErrorIfNoRuleIsFound: Boolean; TargetRecordRef: RecordRef; Optional2RecordRef: RecordRef; Optional3RecordRef: RecordRef; Optional4RecordRef: RecordRef; var QltyInspectionHeader: Record "Qlty. Inspection Header") Result: Boolean;
    var
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        RelatedItem: Record Item;
        PotentialMatchQltyInspectionHeader: Record "Qlty. Inspection Header";
        IsHandled: Boolean;
    begin
        OnBeforeFindExistingInspection(TargetRecordRef, Optional2RecordRef, Optional3RecordRef, Optional4RecordRef, QltyInspectionHeader, Result, IsHandled);
        if IsHandled then
            exit;

        QltyTraversal.FindRelatedItem(RelatedItem, TargetRecordRef, Optional2RecordRef, Optional3RecordRef, Optional4RecordRef);
        if not QltyInspecGenRuleMgmt.FindMatchingGenerationRule(false, TargetRecordRef, RelatedItem, NoSpecificTemplateTok, TempQltyInspectionGenRule) then begin
            LogCreateInspectionProblem(TargetRecordRef, CannotFindTemplateErr, Format(TargetRecordRef.RecordId()));
            if RaiseErrorIfNoRuleIsFound and (not AvoidThrowingErrorWhenPossible) then
                Error(CannotFindTemplateErr, Format(TargetRecordRef.RecordId()));
        end;

        QltyInspectionHeader.Reset();
        TempQltyInspectionGenRule.Reset();
        if TempQltyInspectionGenRule.FindSet() then
            repeat
                if FindExistingInspection(TargetRecordRef, Optional2RecordRef, Optional3RecordRef, Optional4RecordRef, TempQltyInspectionGenRule, PotentialMatchQltyInspectionHeader, true) then begin
                    Result := true;
                    repeat
                        QltyInspectionHeader.SetRange("No.", PotentialMatchQltyInspectionHeader."No.");
                        QltyInspectionHeader.SetRange("Re-inspection No.", PotentialMatchQltyInspectionHeader."Re-inspection No.");
                        if QltyInspectionHeader.FindFirst() then
                            QltyInspectionHeader.Mark(true);
                    until PotentialMatchQltyInspectionHeader.Next() = 0;
                end;
            until TempQltyInspectionGenRule.Next() = 0
        else begin
            Clear(TempQltyInspectionGenRule);
            if FindExistingInspection(TargetRecordRef, Optional2RecordRef, Optional3RecordRef, Optional4RecordRef, TempQltyInspectionGenRule, PotentialMatchQltyInspectionHeader, true) then begin
                Result := true;
                repeat
                    QltyInspectionHeader.SetRange("No.", PotentialMatchQltyInspectionHeader."No.");
                    QltyInspectionHeader.SetRange("Re-inspection No.", PotentialMatchQltyInspectionHeader."Re-inspection No.");
                    if QltyInspectionHeader.FindFirst() then
                        QltyInspectionHeader.Mark(true);
                until PotentialMatchQltyInspectionHeader.Next() = 0;
            end;
        end;
        if Result then begin
            QltyInspectionHeader.SetRange("No.");
            QltyInspectionHeader.SetRange("Re-inspection No.");
            QltyInspectionHeader.MarkedOnly(true);
        end;
    end;

    /// <summary>
    /// Will either find an existing open inspection, or create a new inspection.
    /// </summary>
    /// <param name="TargetRecordRef">The main target record that the inspection will be created against</param>
    /// <param name="TempQltyInspectionGenRule">The generation rule that helped determine which template to use.</param>
    /// <param name="QltyInspectionHeader">The created inspection</param>
    /// <returns></returns>
    local procedure GetExistingOrCreateNewInspectionFor(var TempSourceFieldsFilledStubInspectionBufferQltyInspectionHeader: Record "Qlty. Inspection Header" temporary; TargetRecordRef: RecordRef; OriginalTriggeringRecordRef: RecordRef; TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var InspectionIsNew: Boolean) HasInspection: Boolean
    var
        PrecedingQltyInspectionHeader: Record "Qlty. Inspection Header";
        NeedNewInspection: Boolean;
        HasExistingInspection: Boolean;
        ShouldCreateReinspection: Boolean;
        CouldApplyAnyFields: Boolean;
    begin
        InspectionIsNew := false;

        QltyManagementSetup.Get();
        if QltyManagementSetup."Inspection Creation Option" = QltyManagementSetup."Inspection Creation Option"::"Always create new inspection" then begin
            NeedNewInspection := true;
            HasExistingInspection := false;
        end else begin
            HasExistingInspection := FindExistingInspectionWithStub(TempSourceFieldsFilledStubInspectionBufferQltyInspectionHeader, TempQltyInspectionGenRule, PrecedingQltyInspectionHeader, false);

            case QltyManagementSetup."Inspection Creation Option" of
                QltyManagementSetup."Inspection Creation Option"::"Always create new inspection":
                    begin
                        NeedNewInspection := true;
                        ShouldCreateReinspection := false;
                    end;
                QltyManagementSetup."Inspection Creation Option"::"Always create re-inspection":
                    begin
                        ShouldCreateReinspection := true;
                        NeedNewInspection := true;
                    end;
                QltyManagementSetup."Inspection Creation Option"::"Create re-inspection if matching inspection is finished":
                    if not HasExistingInspection then begin
                        NeedNewInspection := true;
                        ShouldCreateReinspection := false;
                    end else begin
                        NeedNewInspection := PrecedingQltyInspectionHeader.Status = PrecedingQltyInspectionHeader.Status::Finished;
                        ShouldCreateReinspection := PrecedingQltyInspectionHeader.Status = PrecedingQltyInspectionHeader.Status::Finished;
                        HasInspection := not NeedNewInspection;
                    end;
                QltyManagementSetup."Inspection Creation Option"::"Use existing open inspection if available":
                    if not HasExistingInspection then begin
                        NeedNewInspection := true;
                        ShouldCreateReinspection := false;
                    end else begin
                        NeedNewInspection := PrecedingQltyInspectionHeader.Status = PrecedingQltyInspectionHeader.Status::Finished;
                        ShouldCreateReinspection := false;
                        HasInspection := not NeedNewInspection;
                    end;
                QltyManagementSetup."Inspection Creation Option"::"Use any existing inspection if available":
                    begin
                        NeedNewInspection := not HasExistingInspection;
                        ShouldCreateReinspection := false;
                    end;
                else
                    OnCustomCreateInspectionBehavior(TargetRecordRef, OriginalTriggeringRecordRef, TempQltyInspectionGenRule, HasExistingInspection, PrecedingQltyInspectionHeader, NeedNewInspection, ShouldCreateReinspection);
            end;
        end;
        if NeedNewInspection then begin
            QltyInspectionHeader.Init();
            QltyInspectionHeader.SetIsCreating(true);
            if HasExistingInspection and ShouldCreateReinspection then
                InitReinspectionHeader(PrecedingQltyInspectionHeader, QltyInspectionHeader);

            QltyInspectionHeader.TransferFields(TempSourceFieldsFilledStubInspectionBufferQltyInspectionHeader, false);
            QltyInspectionHeader.Validate("Template Code", TempQltyInspectionGenRule."Template Code");

            QltyInspectionHeader."Source RecordId" := TargetRecordRef.RecordId();
            QltyInspectionHeader."Source Record Table No." := TargetRecordRef.Number();
            QltyInspectionHeader."Trigger RecordId" := OriginalTriggeringRecordRef.RecordId();
            QltyInspectionHeader."Trigger Record Table No." := OriginalTriggeringRecordRef.Number();
            QltyInspectionHeader."Source Table No." := TargetRecordRef.Number();
            QltyInspectionHeader.SetIsCreating(true);

            if OriginalTriggeringRecordRef.RecordId() <> TargetRecordRef.RecordId() then
                CouldApplyAnyFields := QltyTraversal.ApplySourceFields(OriginalTriggeringRecordRef, QltyInspectionHeader, false, false);

            CouldApplyAnyFields := CouldApplyAnyFields or QltyTraversal.ApplySourceFields(TargetRecordRef, QltyInspectionHeader, false, false);
            if not CouldApplyAnyFields then
                if OriginalTriggeringRecordRef.RecordId() <> TargetRecordRef.RecordId() then
                    Message(MultiRecordInspectionSourceFieldErr, QltyInspectionHeader."No.", TargetRecordRef.RecordId(), TargetRecordRef.Number(), OriginalTriggeringRecordRef.RecordId());

            HasInspection := QltyInspectionHeader.Insert(true);
            InspectionIsNew := true;
            CreateQualityInspectionResultLinesFromTemplate(QltyInspectionHeader);
        end else
            if HasExistingInspection then
                if QltyInspectionHeader.Get(PrecedingQltyInspectionHeader."No.", PrecedingQltyInspectionHeader."Re-inspection No.") then begin
                    QltyInspectionHeader.SetRecFilter();
                    HasInspection := true;
                end;

        exit(HasInspection);
    end;

    /// <summary>
    /// This will create the Quality Inspection lines for the given header.
    /// </summary>
    /// <param name="QltyInspectionHeader">The quality inspection involved</param>
    local procedure CreateQualityInspectionResultLinesFromTemplate(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
        QltyResultEvaluation: Codeunit "Qlty. Result Evaluation";
    begin
        QltyInspectionTemplateLine.SetRange("Template Code", QltyInspectionHeader."Template Code");
        QltyInspectionTemplateLine.SetAutoCalcFields("Allowable Values");
        if QltyInspectionTemplateLine.FindSet() then
            repeat
                QltyInspectionLine.Init();
                QltyInspectionLine."Template Code" := QltyInspectionHeader."Template Code";
                QltyInspectionLine."Template Line No." := QltyInspectionTemplateLine."Line No.";
                QltyInspectionLine."Inspection No." := QltyInspectionHeader."No.";
                QltyInspectionLine."Re-inspection No." := QltyInspectionHeader."Re-inspection No.";
                QltyInspectionLine."Line No." := QltyInspectionTemplateLine."Line No.";

                QltyInspectionLine.Validate("Test Code", QltyInspectionTemplateLine."Test Code");
                QltyInspectionLine.Description := QltyInspectionTemplateLine.Description;
                QltyInspectionLine."Allowable Values" := QltyInspectionTemplateLine."Allowable Values";
                QltyInspectionLine."Unit of Measure Code" := QltyInspectionTemplateLine."Unit of Measure Code";
                QltyInspectionLine.Insert();
                QltyResultConditionMgmt.CopyResultConditionsFromTemplateToInspection(QltyInspectionTemplateLine, QltyInspectionLine);
                QltyInspectionHeader.SetPreventAutoAssignment(true);
            until QltyInspectionTemplateLine.Next() = 0;

        QltyInspectionLine.Reset();
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.SetRange("Re-inspection No.", QltyInspectionHeader."Re-inspection No.");
        if QltyInspectionLine.FindSet(true) then
            repeat
                if QltyResultEvaluation.TryValidateQltyInspectionLine(QltyInspectionLine, QltyInspectionHeader) then begin
                    QltyInspectionLine.Modify(true);
                    QltyInspectionHeader.Modify(true);
                end;
            until QltyInspectionLine.Next() = 0;

        QltyInspectionHeader.SetPreventAutoAssignment(false);
    end;

    /// <summary>
    /// Finds an existing inspection using optionally supplied variants of records/recordids/recordrefs
    /// </summary>
    /// <param name="TargetRecordRef"></param>
    /// <param name="OptionalVariant2">Must be a recordid,recordref,or record</param>
    /// <param name="OptionalVariant3">Must be a recordid,recordref,or record</param>
    /// <param name="OptionalVariant4">Must be a recordid,recordref,or record</param>
    /// <param name="TempQltyInspectionGenRule">Must be a recordid,recordref,or record</param>
    /// <param name="PrecedingQltyInspectionHeader"></param>
    /// <param name="FindAll"></param>
    /// <returns></returns>
    internal procedure FindExistingInspectionWithVariant(TargetRecordRef: RecordRef; OptionalVariant2: Variant; OptionalVariant3: Variant; OptionalVariant4: Variant; TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary; var PrecedingQltyInspectionHeader: Record "Qlty. Inspection Header"; FindAll: Boolean): Boolean
    var
        DataTypeManagement: Codeunit "Data Type Management";
        Optional2RecordRef: RecordRef;
        Optional3RecordRef: RecordRef;
        Optional4RecordRef: RecordRef;
    begin
        if not DataTypeManagement.GetRecordRef(OptionalVariant2, Optional2RecordRef) then;
        if not DataTypeManagement.GetRecordRef(OptionalVariant3, Optional3RecordRef) then;
        if not DataTypeManagement.GetRecordRef(OptionalVariant4, Optional4RecordRef) then;
        exit(FindExistingInspection(TargetRecordRef, Optional2RecordRef, Optional3RecordRef, Optional4RecordRef, TempQltyInspectionGenRule, PrecedingQltyInspectionHeader, FindAll));
    end;

    /// <summary>
    /// Finds an existing inspection that matches the source criteria.
    /// If there are multiple inspections finds the re-inspection.
    /// </summary>
    /// <param name="TargetRecordRef">The main target record that the inspection will be created against</param>
    /// <param name="TempQltyInspectionGenRule">The generation rule that helped determine which template to use.</param>
    /// <param name="PrecedingQltyInspectionHeader"></param>
    /// <returns></returns>
    internal procedure FindExistingInspection(TargetRecordRef: RecordRef; Optional2RecordRef: RecordRef; Optional3RecordRef: RecordRef; Optional4RecordRef: RecordRef; TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary; var PrecedingQltyInspectionHeader: Record "Qlty. Inspection Header"; FindAll: Boolean): Boolean
    var
        TempInStubSearchForSimilarInspectionBufferQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
    begin
        if not QltyManagementSetup.Get() then
            exit(false);

        PrecedingQltyInspectionHeader.Reset();
        ApplyAllSourceFieldsToStub(TempInStubSearchForSimilarInspectionBufferQltyInspectionHeader, TargetRecordRef, Optional2RecordRef, Optional3RecordRef, Optional4RecordRef);

        exit(FindExistingInspectionWithStub(TempInStubSearchForSimilarInspectionBufferQltyInspectionHeader, TempQltyInspectionGenRule, PrecedingQltyInspectionHeader, FindAll));
    end;

    local procedure FindExistingInspectionWithStub(var TempInStubSearchForSimilarInspectionBufferQltyInspectionHeader: Record "Qlty. Inspection Header" temporary; var TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary; var PrecedingQltyInspectionHeader: Record "Qlty. Inspection Header"; FindAll: Boolean): Boolean
    begin
        if not QltyManagementSetup.Get() then
            exit(false);

        if (TempQltyInspectionGenRule."Template Code" <> '') and (TempInStubSearchForSimilarInspectionBufferQltyInspectionHeader."Template Code" = '') then
            TempInStubSearchForSimilarInspectionBufferQltyInspectionHeader."Template Code" := TempQltyInspectionGenRule."Template Code";

        PrecedingQltyInspectionHeader.TransferFields(TempInStubSearchForSimilarInspectionBufferQltyInspectionHeader, false);
        case QltyManagementSetup."Inspection Search Criteria" of
            QltyManagementSetup."Inspection Search Criteria"::"By Standard Source Fields":
                PrecedingQltyInspectionHeader.SetCurrentKey("Template Code", "Source Table No.", "Source Type", "Source Sub Type", "Source Document No.", "Source Document Line No.", "Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Package No.", "Source Task No.");
            QltyManagementSetup."Inspection Search Criteria"::"By Source Record":
                PrecedingQltyInspectionHeader.SetCurrentKey("Template Code", "Source RecordId", "Source Record Table No.");
            QltyManagementSetup."Inspection Search Criteria"::"By Item Tracking":
                PrecedingQltyInspectionHeader.SetCurrentKey("Source Item No.", "Source Variant Code", "Source Lot No.", "Source Serial No.", "Source Package No.", "Template Code");
            QltyManagementSetup."Inspection Search Criteria"::"By Document and Item only":
                PrecedingQltyInspectionHeader.SetCurrentKey("Source Document No.", "Source Document Line No.", "Source Item No.", "Source Variant Code");
        end;

        PrecedingQltyInspectionHeader.SetRecFilter();
        PrecedingQltyInspectionHeader.SetRange("No.");
        PrecedingQltyInspectionHeader.SetRange("Re-inspection No.");
        PrecedingQltyInspectionHeader.SetRange("Template Code");

        if QltyManagementSetup."Inspection Search Criteria" <> QltyManagementSetup."Inspection Search Criteria"::"By Source Record" then
            PrecedingQltyInspectionHeader.SetRange("Source Table No.");

        if QltyManagementSetup."Inspection Search Criteria" = QltyManagementSetup."Inspection Search Criteria"::"By Document and Item only" then begin
            PrecedingQltyInspectionHeader.SetRange("Source Lot No.");
            PrecedingQltyInspectionHeader.SetRange("Source Serial No.");
            PrecedingQltyInspectionHeader.SetRange("Source Package No.");
        end;

        PrecedingQltyInspectionHeader.SetCurrentKey("No.", "Re-inspection No.");
        if FindAll then
            exit(PrecedingQltyInspectionHeader.FindSet())
        else
            exit(PrecedingQltyInspectionHeader.FindLast());
    end;

    /// <summary>
    /// Use this to create a Re-inspection.
    /// </summary>
    /// <param name="FromThisQltyInspectionHeader"></param>
    /// <param name="CreatedReinspectionQltyInspectionHeader"></param>
    internal procedure CreateReinspection(FromThisQltyInspectionHeader: Record "Qlty. Inspection Header"; var CreatedReinspectionQltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        PrecedingQltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        IsHandled: Boolean;
    begin
        QltyManagementSetup.Get();

        OnBeforeCreateReinspection(FromThisQltyInspectionHeader, CreatedReinspectionQltyInspectionHeader, IsHandled);
        if IsHandled then
            exit;

        PrecedingQltyInspectionHeader.LockTable();
        PrecedingQltyInspectionHeader.SetRange("No.", FromThisQltyInspectionHeader."No.");
        PrecedingQltyInspectionHeader.SetCurrentKey("No.", "Re-inspection No.");
        PrecedingQltyInspectionHeader.FindLast();
        if PrecedingQltyInspectionHeader."Most Recent Re-inspection" then begin
            PrecedingQltyInspectionHeader."Most Recent Re-inspection" := false;
            PrecedingQltyInspectionHeader.Modify();
        end;

        InitReinspectionHeader(PrecedingQltyInspectionHeader, CreatedReinspectionQltyInspectionHeader);
        CreatedReinspectionQltyInspectionHeader.Insert(true);
        CreateQualityInspectionResultLinesFromTemplate(CreatedReinspectionQltyInspectionHeader);

        LastCreatedQltyInspectionHeader := CreatedReinspectionQltyInspectionHeader;

        if GuiAllowed() then
            QltyNotificationMgmt.NotifyInspectionCreated(CreatedReinspectionQltyInspectionHeader);

        OnAfterCreateReinspection(FromThisQltyInspectionHeader, CreatedReinspectionQltyInspectionHeader);
    end;

    local procedure InitReinspectionHeader(FromThisQltyInspectionHeader: Record "Qlty. Inspection Header"; var CreatedReinspectionQltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
        CreatedReinspectionQltyInspectionHeader.Init();
        CreatedReinspectionQltyInspectionHeader."No." := FromThisQltyInspectionHeader."No.";
        CreatedReinspectionQltyInspectionHeader."Re-inspection No." := FromThisQltyInspectionHeader."Re-inspection No." + 1;
        CreatedReinspectionQltyInspectionHeader.Validate("Template Code", CreatedReinspectionQltyInspectionHeader."Template Code");
        CreatedReinspectionQltyInspectionHeader.TransferFields(FromThisQltyInspectionHeader, false);
        CreatedReinspectionQltyInspectionHeader.Status := CreatedReinspectionQltyInspectionHeader.Status::Open;
        CreatedReinspectionQltyInspectionHeader."Finished By User ID" := '';
        CreatedReinspectionQltyInspectionHeader."Finished Date" := 0DT;
        CreatedReinspectionQltyInspectionHeader.Validate("Result Code", '');
    end;

    /// <summary>
    /// 
    /// Returns the last created inspection in the scope of the instance of this codeunit.
    /// Only use if you just called one of the CreateInspection() procedures.
    /// 
    /// </summary>
    /// <param name="LastCreatedQltyInspectionHeader2"></param>
    /// <returns>True if the last created inspection is available and exists. Returns false if no inspection was created previously or is othewise no longer available.</returns>
    internal procedure GetCreatedInspection(var LastCreatedQltyInspectionHeader2: Record "Qlty. Inspection Header") StillExists: Boolean
    begin
        if LastCreatedQltyInspectionHeader."No." = '' then
            exit;

        LastCreatedQltyInspectionHeader2 := LastCreatedQltyInspectionHeader;
        LastCreatedQltyInspectionHeader2.SetRecFilter();
        StillExists := LastCreatedQltyInspectionHeader2.FindFirst();
    end;

    /// <summary>
    /// Returns the last created status.
    /// </summary>
    /// <returns></returns>
    internal procedure GetLastCreatedStatus(): Enum "Qlty. Inspection Create Status"
    begin
        exit(LastQltyInspectionCreateStatus);
    end;

    /// <summary>
    /// Use this to log QMERR0001
    /// </summary>
    /// <param name="ContextRecordRef"></param>
    /// <param name="Input"></param>
    /// <param name="Variable1"></param>
    local procedure LogCreateInspectionProblem(ContextRecordRef: RecordRef; Input: Text; Variable1: Text)
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
    internal procedure CreateMultipleInspectionsForMarkedTrackingSpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
        CreateMultipleInspectionsForMarkedTrackingSpecification(TempTrackingSpecification, true);
    end;

    /// <summary>
    /// Use this with Marked records.
    /// </summary>
    /// <param name="TempTrackingSpecification">You must mark your records as a pre-requisite.</param>
    /// <param name="IsManualCreation">Whether this is a manual test creation or automated.</param>
    internal procedure CreateMultipleInspectionsForMarkedTrackingSpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary; IsManualCreation: Boolean)
    var
        TempNotUsedOptionalFiltersQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
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

        CreateMultipleInspectionsForMultipleRecords(TempRecCopyOfTrackingSpecificationRecordRef, IsManualCreation, TempNotUsedOptionalFiltersQltyInspectionGenRule);
    end;

    internal procedure CreateMultipleInspectionsForMultipleRecords(var SetOfRecordsRecordRef: RecordRef; IsManualCreation: Boolean)
    var
        TempDummyFiltersQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
    begin
        CreateMultipleInspectionsForMultipleRecords(SetOfRecordsRecordRef, IsManualCreation, TempDummyFiltersQltyInspectionGenRule);
    end;

    internal procedure CreateMultipleInspectionsForMultipleRecords(var SetOfRecordsRecordRef: RecordRef; IsManualCreation: Boolean; var TempFiltersQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary)
    var
        CreatedQltyInspectionIds: List of [Code[20]];
    begin
        CreateMultipleInspectionsWithoutDisplaying(SetOfRecordsRecordRef, IsManualCreation, TempFiltersQltyInspectionGenRule, CreatedQltyInspectionIds);

        if IsManualCreation and GuiAllowed() then
            DisplayInspectionsIfConfigured(IsManualCreation, CreatedQltyInspectionIds);
    end;

    internal procedure DisplayInspectionsIfConfigured(IsManualCreation: Boolean; var CreatedQltyInspectionIds: List of [Code[20]])
    var
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        InspectionNo: Code[20];
        PipeSeparatedFilter: Text;
    begin
        QltyManagementSetup.Get();

        if GuiAllowed() then begin
            foreach InspectionNo in CreatedQltyInspectionIds do
                if InspectionNo <> '' then begin
                    if StrLen(PipeSeparatedFilter) > 1 then
                        PipeSeparatedFilter += '|';
                    PipeSeparatedFilter += InspectionNo;
                end;

            CreatedQltyInspectionHeader.SetFilter("No.", PipeSeparatedFilter);
            if CreatedQltyInspectionIds.Count() = 1 then begin
                CreatedQltyInspectionHeader.SetCurrentKey("No.", "Re-inspection No.");
                CreatedQltyInspectionHeader.FindLast();
                if IsManualCreation then
                    Page.Run(Page::"Qlty. Inspection", CreatedQltyInspectionHeader)
                else
                    QltyNotificationMgmt.NotifyInspectionCreated(CreatedQltyInspectionHeader);
            end else begin
                CreatedQltyInspectionHeader.FindSet();
                if IsManualCreation then
                    Page.Run(Page::"Qlty. Inspection List", CreatedQltyInspectionHeader)
                else
                    QltyNotificationMgmt.NotifyMultipleInspectionsCreated(CreatedQltyInspectionHeader);
            end;
        end;
    end;

    /// <summary>
    /// Use this if you need to keep track of multiple inspections without displaying the results.
    /// </summary>
    /// <param name="SetOfRecordsRecordRef"></param>
    /// <param name="IsManualCreation"></param>
    /// <param name="ptrecOptionalFiltersGenerationRule"></param>
    /// <param name="CreatedQltyInspectionIds"></param>
    internal procedure CreateMultipleInspectionsWithoutDisplaying(var SetOfRecordsRecordRef: RecordRef; IsManualCreation: Boolean; var TempFiltersQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary; var CreatedQltyInspectionIds: List of [Code[20]])
    var
        TempCopyOfSingleRecordRecordRef: RecordRef;
        ParentRecordRef: RecordRef;
        FailedInspectionIds: List of [Text];
        CountOfInspectionsCreatedForLine: Integer;
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
                CountOfInspectionsCreatedForLine := CreateInspectionForSelfOrDirectParent(
                    TempCopyOfSingleRecordRecordRef,
                    TempFiltersQltyInspectionGenRule,
                    ParentRecordRef,
                    CreatedQltyInspectionIds,
                    true,
                    IsManualCreation);
                if CountOfInspectionsCreatedForLine = 0 then
                    FailedInspectionIds.Add(Format(SetOfRecordsRecordRef.RecordId()));
            until SetOfRecordsRecordRef.Next() = 0;

        if CreatedQltyInspectionIds.Count() = 0 then begin
            if AvoidThrowingErrorWhenPossible then
                exit;

            if ParentRecordRef.Number() <> 0 then
                Error(UnableToCreateInspectionForParentOrChildErr, ParentRecordRef.Name, SetOfRecordsRecordRef.Name)
            else
                Error(UnableToCreateInspectionForRecordErr, SetOfRecordsRecordRef.Name);
        end;
    end;

    local procedure CreateInspectionForSelfOrDirectParent(var TempSelfRecordRef: RecordRef; var TempFiltersQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary; var FoundParentRecordRef: RecordRef; var CreatedQltyInspectionIds: List of [Code[20]]; PreventInspectionFromDisplayingEvenIfConfigured: Boolean; IsManualCreation: Boolean) InspectionCreatedCount: Integer
    var
        LastCreatedQltyInspectionHeader2: Record "Qlty. Inspection Header";
        Item: Record Item;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        LocalQltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
        ReservationManagement: Codeunit "Reservation Management";
        ParentRecordRef: RecordRef;
        VariantEmptyOrTrackingSpecification: Variant;
        Dummy4Variant: Variant;
    begin
        InspectionCreatedCount := 0;

        LocalQltyInspectionCreate.SetPreventDisplayingInspectionEvenIfConfigured(PreventInspectionFromDisplayingEvenIfConfigured);

        Clear(FoundParentRecordRef);
        if QltyTraversal.FindSingleParentRecord(TempSelfRecordRef, ParentRecordRef) then begin
            FoundParentRecordRef.Open(ParentRecordRef.Number());
            FoundParentRecordRef.Get(ParentRecordRef.RecordId());
        end;
        Clear(Item);
        Clear(RelatedReservFilterReservationEntry);
        Clear(VariantEmptyOrTrackingSpecification);
        RelatedReservFilterReservationEntry.SetRange("Entry No.", -1);

        if TempFiltersQltyInspectionGenRule."Item Filter" <> '' then begin
            Item.FilterGroup(20);
            Item.SetView(TempFiltersQltyInspectionGenRule."Item Filter");
            Item.FilterGroup(0);
        end;

        if QltyTraversal.FindRelatedItem(Item, ParentRecordRef, TempSelfRecordRef, VariantEmptyOrTrackingSpecification, Dummy4Variant) then begin
            if (Item."No." <> '') and (TempFiltersQltyInspectionGenRule."Item Attribute Filter" <> '') then
                if not QltyInspecGenRuleMgmt.DoesMatchItemAttributeFiltersOrNoFilter(TempFiltersQltyInspectionGenRule, Item) then
                    exit;

            if QltyItemTracking.IsItemTrackingUsed(Item."No.") then begin
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

                if LocalQltyInspectionCreate.CreateInspectionWithMultiVariants(ParentRecordRef, TempSelfRecordRef, VariantEmptyOrTrackingSpecification, Dummy4Variant, IsManualCreation, TempFiltersQltyInspectionGenRule) then
                    if LocalQltyInspectionCreate.GetCreatedInspection(LastCreatedQltyInspectionHeader2) then begin
                        InspectionCreatedCount += 1;
                        if not CreatedQltyInspectionIds.Contains(LastCreatedQltyInspectionHeader2."No.") then
                            CreatedQltyInspectionIds.Add(LastCreatedQltyInspectionHeader2."No.");
                    end;
            until RelatedReservFilterReservationEntry.Next() = 0;
        end else begin
            if TempFiltersQltyInspectionGenRule."Item Filter" <> '' then begin
                Clear(Item);
                if QltyTraversal.FindRelatedItem(Item, ParentRecordRef, TempSelfRecordRef, VariantEmptyOrTrackingSpecification, Dummy4Variant) then
                    exit;
            end;

            if LocalQltyInspectionCreate.CreateInspectionWithMultiVariants(TempSelfRecordRef, ParentRecordRef, Dummy4Variant, Dummy4Variant, IsManualCreation, TempFiltersQltyInspectionGenRule) then
                if LocalQltyInspectionCreate.GetCreatedInspection(LastCreatedQltyInspectionHeader2) then begin
                    InspectionCreatedCount += 1;
                    if not CreatedQltyInspectionIds.Contains(LastCreatedQltyInspectionHeader2."No.") then
                        CreatedQltyInspectionIds.Add(LastCreatedQltyInspectionHeader2."No.");
                end;
        end;
    end;

    internal procedure SetPreventDisplayingInspectionEvenIfConfigured(PreventDisplayingInspectionEvenIfConfigured: Boolean)
    begin
        PreventShowingGeneratedInspectionEvenIfConfigured := PreventDisplayingInspectionEvenIfConfigured;
    end;

    /// <summary>
    /// Stubs in and filles the source config fields.
    /// </summary>
    /// <param name="InspectionStubToFillQualityOrder"></param>
    /// <param name="MandatoryPrimaryRecordRef"></param>
    /// <param name="OptionalVariant2"></param>
    /// <param name="OptionalVariant3"></param>
    /// <param name="OptionalVariant4"></param>
    /// <returns></returns>
    local procedure ApplyAllSourceFieldsToStub(var InspectionStubToFillQltyInspectionHeader: Record "Qlty. Inspection Header"; MandatoryPrimaryRecordRef: RecordRef; OptionalVariant2: Variant; OptionalVariant3: Variant; OptionalVariant4: Variant): Boolean
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
            InspectionStubToFillQltyInspectionHeader."Source Table No." := MandatoryPrimaryRecordRef.Number();
            InspectionStubToFillQltyInspectionHeader."Source Record Table No." := MandatoryPrimaryRecordRef.Number();
            QltyTraversal.ApplySourceFields(MandatoryPrimaryRecordRef, InspectionStubToFillQltyInspectionHeader, false, false);
            InspectionStubToFillQltyInspectionHeader."Source RecordId" := MandatoryPrimaryRecordRef.RecordId();
        end;

        if Optional2RecordRef.Number() <> 0 then begin
            QltyTraversal.ApplySourceFields(Optional2RecordRef, InspectionStubToFillQltyInspectionHeader, false, false);
            InspectionStubToFillQltyInspectionHeader."Source RecordId 2" := Optional2RecordRef.RecordId();
        end;

        if Optional3RecordRef.Number() <> 0 then begin
            QltyTraversal.ApplySourceFields(Optional3RecordRef, InspectionStubToFillQltyInspectionHeader, false, false);
            InspectionStubToFillQltyInspectionHeader."Source RecordId 3" := Optional3RecordRef.RecordId();
        end;

        if Optional4RecordRef.Number() <> 0 then begin
            QltyTraversal.ApplySourceFields(Optional4RecordRef, InspectionStubToFillQltyInspectionHeader, false, false);
            InspectionStubToFillQltyInspectionHeader."Source RecordId 4" := Optional4RecordRef.RecordId();
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
    /// OnBeforeCreateInspection is called before an inspection is created.
    /// Use this event to do additional checks before an inspection is created.
    /// </summary>
    /// <param name="TargetRecordRef">The main target record that the inspection will be created against</param>
    /// <param name="IsManualCreation">True when the inspection is being manually created and not automatically triggered</param>
    /// <param name="OptionalSpecificTemplate">When supplied refers to a specific desired template</param>
    /// <param name="OptionalRec2Variant">For complex automation can be additional source records</param>
    /// <param name="OptionalRec3Variant">For complex automation can be additional source records</param>
    /// <param name="IsHandled">Set to true to replace the default behavior, set to false to extend it and continue</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateInspection(var TargetRecordRef: RecordRef; var IsManualCreation: Boolean; var OptionalSpecificTemplate: Code[20]; var IsHandled: Boolean; var OptionalRec2Variant: Variant; var OptionalRec3Variant: Variant)
    begin
    end;

    /// <summary>
    /// OnAfterCreateInspectionBeforeDialog gets called after a Quality Inspection has been created and
    /// before any interactive dialog is shown.
    /// </summary>
    /// <param name="TargetRecordRef">The main target record that the inspection will be created against</param>
    /// <param name="TriggeringRecordRef">Typically the same as the target record ref. Used in complex customizations.</param>
    /// <param name="IsManualCreation">True when the inspection is being manually created and not automatically triggered</param>
    /// <param name="OptionalSpecificTemplate">When supplied refers to a specific desired template</param>
    /// <param name="TempQltyInspectionGenRule">The generation rule that helped determine which template to use.</param>
    /// <param name="QualityOrder">The quality inspection</param>
    /// <param name="OptionalRec2Variant">For complex automation can be additional source records</param>
    /// <param name="OptionalRec3Variant">For complex automation can be additional source records</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInspectionBeforeDialog(var TargetRecordRef: RecordRef; var TriggeringRecordRef: RecordRef; var IsManualCreation: Boolean; var OptionalSpecificTemplate: Code[20]; var TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var OptionalRec2Variant: Variant; var OptionalRec3Variant: Variant)
    begin
    end;

    /// <summary>
    /// OnAfterCreateInspectionAfterDialog gets called after a Quality Inspection has been created after any interactive dialog is shown
    /// </summary>
    /// <param name="TargetRecordRef">The main target record that the inspection will be created against</param>
    /// <param name="TriggeringRecordRef">Typically the same as the target record ref. Used in complex customizations.</param>
    /// <param name="IsManualCreation">True when the inspection is being manually created and not automatically triggered</param>
    /// <param name="OptionalSpecificTemplate">When supplied refers to a specific desired template</param>
    /// <param name="TempQltyInspectionGenRule">The generation rule that helped determine which template to use.</param>
    /// <param name="QualityOrder">The quality inspection</param>
    /// <param name="OptionalRec2Variant">For complex automation can be additional source records</param>
    /// <param name="OptionalRec3Variant">For complex automation can be additional source records</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInspectionAfterDialog(var TargetRecordRef: RecordRef; var TriggeringRecordRef: RecordRef; var IsManualCreation: Boolean; var OptionalSpecificTemplate: Code[20]; var TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var OptionalRec2Variant: Variant; var OptionalRec3Variant: Variant)
    begin
    end;

    /// <summary>
    /// Implement OnCustomCreateInspectionBehavior if you have also extended enum 20402 "Qlty. Inspect. Creation Option"
    /// This is where you will provide any custom Inspection Creation Options to match your enum extension.
    /// Only set handled to true if you want to skip the remaining behavior.
    /// </summary>
    /// <param name="TargetRecordRef">The record the inspection is being created against</param>
    /// <param name="OriginalTriggeringRecordRef">The record that triggered the inspection</param>
    /// <param name="TempQltyInspectionGenRule">The generation rule</param>
    /// <param name="HasExistingInspection">Whether it has an existing inspection</param>
    /// <param name="PrecedingQltyInspectionHeader">Optionally an existing inspection that matches</param>
    /// <param name="NeedNewInspection">Choose whether it should need a new inspection</param>
    /// <param name="ShouldCreateReinspection">Choose whether it should create a Reinspection</param>
    [IntegrationEvent(false, false)]
    local procedure OnCustomCreateInspectionBehavior(var TargetRecordRef: RecordRef; var OriginalTriggeringRecordRef: RecordRef; var TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary; var HasExistingInspection: Boolean; var PrecedingQltyInspectionHeader: Record "Qlty. Inspection Header"; var NeedNewInspection: Boolean; var ShouldCreateReinspection: Boolean)
    begin
    end;

    /// <summary>
    /// OnBeforeCreateReinspection supplies an opportunity to change how manual Re-inspections are performed.
    /// </summary>
    /// <param name="FromThisQltyInspectionHeader">Which inspection the re-inspection is being requested to be created from</param>
    /// <param name="CreatedReQltyInspectionHeader">If you are setting Handled to true you must supply a valid re-inspection record here.</param>
    /// <param name="IsHandled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReinspection(var FromThisQltyInspectionHeader: Record "Qlty. Inspection Header"; var CreatedReQltyInspectionHeader: Record "Qlty. Inspection Header"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// OnAfterCreateReinspection gives an opportunity to integrate with the re-inspection record after a manual re-inspection is created.
    /// </summary>
    /// <param name="FromThisQltyInspectionHeader">Which inspection the re-inspection is being requested to be created from</param>
    /// <param name="CreatedReQltyInspectionHeader">The created re-inspection</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateReinspection(var FromThisQltyInspectionHeader: Record "Qlty. Inspection Header"; var CreatedReQltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
    end;

    /// <summary>
    /// OnBeforeFindExistingInspection provides an opportunity to override how an existing inspection is found.
    /// </summary>
    /// <param name="TargetRecordRef">The main target record that the inspection will be created against</param>
    /// <param name="Optional2RecordRef">Optional.  Some events, typically automatic events, will have multiple records to assist with setting source details.</param>
    /// <param name="Optional3RecordRef">Optional.  Some events, typically automatic events, will have multiple records to assist with setting source details.</param>
    /// <param name="Optional4RecordRef">Optional.  Some events, typically automatic events, will have multiple records to assist with setting source details.</param>
    /// <param name="QltyInspectionHeader">The found inspection</param>
    /// <param name="Result">Set to true if you found the record. If you set to true you must also supply QltyInspectionHeader</param>
    /// <param name="IsHandled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindExistingInspection(TargetRecordRef: RecordRef; Optional2RecordRef: RecordRef; Optional3RecordRef: RecordRef; Optional4RecordRef: RecordRef; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}
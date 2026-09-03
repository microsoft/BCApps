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
        tabledata "Qlty. Management Setup" = r,
        tabledata "Qlty. Inspection Gen. Rule" = r,
        tabledata "Qlty. Inspection Header" = rim,
        tabledata "Qlty. Inspection Line" = rim,
        tabledata "Qlty. I. Result Condit. Conf." = rim,
        tabledata "Qlty. Inspection Template Line" = r;

    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        LastCreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        RelatedReservFilterReservationEntry: Record "Reservation Entry";
        QltyInspecGenRuleMgmt: Codeunit "Qlty. Inspec. Gen. Rule Mgmt.";
        QltyTraversal: Codeunit "Qlty. Traversal";
        LastQltyInspectionCreateStatus: Enum "Qlty. Inspection Create Status";
        PreventShowingGeneratedInspectionEvenIfConfigured: Boolean;
        AvoidThrowingErrorWhenPossible: Boolean;
        LastInspectionIsNewlyCreated: Boolean;
        ProgrammerErrNotARecordRefErr: Label 'Cannot find inspections with %1. Please supply a "Record" or "RecordRef".', Comment = '%1=the variant being supplied that is not a RecordRef. Your system might have an extension or customization that needs to be re-configured.';
        CannotFindTemplateErr: Label 'Cannot find a Quality Inspection Template or Quality Inspection Generation Rule to match %1. Ensure there is a Quality Inspection Generation Rule that will match this record.', Comment = '%1=The record identifier';
        UnableToCreateInspectionForErr: Label 'Unable to create an inspection for the record [%1], please review the Quality Inspection Source Configuration and also the Quality Inspection Generation Rules, you likely need additional configuration to work with this record.', Comment = '%1=the record id of what is being attempted to have an inspection created for.';
        NoSpecificTemplateTok: Label '', Locked = true;
        MultiRecordInspectionSourceFieldErr: Label 'Inspection %1 has been created, however neither %2 nor %4 had applicable source fields to map to the inspection. Navigate to the Quality Source Configuration for table %3 and apply source field mapping.', Comment = '%1=the inspection, %2=target record,  %3=the number to set configuration for,%4=triggering record';
        RegisteredLogEventIDTok: Label 'QMERR0001', Locked = true;
        DetailRecordTok: Label 'Target', Locked = true;
        UnableToCreateInspectionForParentOrChildErr: Label 'Cannot find enough details to make an inspection for your record(s). Try making sure that there is a source configuration for your record, and then also make sure there is sufficient information in your inspection generation rules. Two tables involved are %1 and %2.', Comment = '%1=the parent table, %2=the child and original table.';
        UnableToCreateInspectionForRecordErr: Label 'Cannot find enough details to make an inspection for your record(s). Try making sure that there is a source configuration for your record, and then also make sure there is sufficient information in your inspection generation rules. The table involved is %1.', Comment = '%1=the table involved.';
        RecordShouldBeTemporaryErr: Label 'This code is only intended to run in a temporary fashion. This error is likely occurring from an integration issue.';
        SomeInspectionsMatchedQst: Label 'No new inspections were created, but %1 existing inspections matched. Do you want to see them?', Comment = '%1=the count of existing inspections that were matched (reused).';
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

    /// <summary>
    /// Converts a primary record variant to a record reference and creates an inspection with optional source context.
    /// </summary>
    /// <param name="ReferenceVariant">The primary source Record, RecordRef, or RecordId.</param>
    /// <param name="IsManualCreation">Specifies whether creation was requested manually.</param>
    /// <param name="OptionalSpecificTemplate">The template code to use, or an empty value for generation-rule selection.</param>
    /// <param name="OptionalRec2Variant">An optional secondary source record.</param>
    /// <param name="OptionalRec3Variant">An optional tertiary source record.</param>
    /// <param name="OptionalRec4Variant">An optional fourth source record.</param>
    /// <returns>The inspection creation status.</returns>
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

    /// <summary>
    /// Converts a primary record variant and creates an inspection using filtered generation rules and optional source context.
    /// </summary>
    /// <param name="ReferenceVariant">The primary source Record, RecordRef, or RecordId.</param>
    /// <param name="OptionalRec2Variant">An optional secondary source record.</param>
    /// <param name="OptionalRec3Variant">An optional tertiary source record.</param>
    /// <param name="OptionalRec4Variant">An optional fourth source record.</param>
    /// <param name="IsManualCreation">Specifies whether creation was requested manually.</param>
    /// <param name="TempFiltersQltyInspectionGenRule">The temporary generation-rule filters to apply.</param>
    /// <returns>The inspection creation status.</returns>
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

    /// <summary>
    /// Tries each supplied record variant as the primary source until an inspection is created with the specified template.
    /// </summary>
    /// <param name="OptionalRec1Variant">The first source record candidate.</param>
    /// <param name="OptionalRec2Variant">The second source record candidate.</param>
    /// <param name="OptionalRec3Variant">The third source record candidate.</param>
    /// <param name="OptionalRec4Variant">The fourth source record candidate.</param>
    /// <param name="IsManualCreation">Specifies whether creation was requested manually.</param>
    /// <param name="OptionalSpecificTemplate">The template code to use.</param>
    /// <returns>True if an inspection was created and remains available; otherwise, false.</returns>
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
    /// Creates or reuses an inspection for the supplied records through the generation rule engine, with the same
    /// automatic semantics as the app's own triggered creation paths. Intended for extensions that need to create
    /// inspections at a moment the app does not trigger itself, for example from an event subscriber on a document
    /// or posting routine.
    ///
    /// Automatic semantics:
    /// - Only generation rules with an activation trigger of "Manual or Automatic" or "Automatic only" are considered.
    /// - The filters on TempFiltersQltyInspectionGenRule are applied to the rule search, in the same way the app's own
    ///   triggers filter on their trigger field (for example "Warehouse Receipt Trigger"). Pass an unfiltered temporary
    ///   record to consider every automatic rule for the source table.
    /// - No inspection page is opened and no inspection-created notification is raised. The caller receives the
    ///   resolved inspection and decides whether to surface it. Workflow and integration events raised by inspection
    ///   creation fire as for any automatic creation.
    /// - No error is raised when no generation rule matches. The procedure returns false when no rule matches, when
    ///   Quality Management Setup is missing, or when a subscriber to OnBeforeCreateInspection handles the creation.
    ///
    /// Up to four records can be supplied. The engine promotes each supplied record to primary in turn until an
    /// inspection is resolved, and applies the source configuration of every supplied record to the inspection, so the
    /// inspection may be created from a record other than the first. Unused slots can be left as unassigned variants.
    /// A temporary "Tracking Specification" record positioned on one tracking line can be passed in any slot to supply
    /// lot, serial and package information.
    ///
    /// Whether an existing inspection is reused or a new one is created follows the "Inspection Creation Option" and
    /// "Inspection Search Criteria" in Quality Management Setup.
    /// </summary>
    /// <param name="PrimaryRecordVariant">The record to create the inspection for (Record, RecordRef, or RecordId).</param>
    /// <param name="OptionalRelated2Variant">An optional related record used for rule matching and source field mapping, or an unassigned variant.</param>
    /// <param name="OptionalRelated3Variant">An optional related record used for rule matching and source field mapping, or an unassigned variant.</param>
    /// <param name="OptionalRelated4Variant">An optional related record used for rule matching and source field mapping, or an unassigned variant.</param>
    /// <param name="TempFiltersQltyInspectionGenRule">A temporary record whose filters restrict which generation rules are considered; leave unfiltered to consider every automatic rule.</param>
    /// <param name="QltyInspectionHeader">The created or reused inspection with a record filter applied, or a cleared record when nothing was resolved.</param>
    /// <param name="IsNewlyCreated">True when the inspection was inserted by this call; false when an existing inspection was reused or nothing was resolved.</param>
    /// <returns>True if an inspection was created or reused; otherwise, false.</returns>
    procedure CreateInspectionFromRuleEngine(PrimaryRecordVariant: Variant; OptionalRelated2Variant: Variant; OptionalRelated3Variant: Variant; OptionalRelated4Variant: Variant; var TempFiltersQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var IsNewlyCreated: Boolean): Boolean
    var
        PreviousPreventShowingState: Boolean;
        HasInspection: Boolean;
    begin
        Clear(QltyInspectionHeader);
        IsNewlyCreated := false;

        // The flag is assigned directly rather than through SetPreventDisplayingInspectionEvenIfConfigured so the
        // previous value can be restored, leaving the instance unchanged for the caller after this call.
        PreviousPreventShowingState := PreventShowingGeneratedInspectionEvenIfConfigured;
        PreventShowingGeneratedInspectionEvenIfConfigured := true;
        HasInspection := CreateInspectionWithMultiVariants(PrimaryRecordVariant, OptionalRelated2Variant, OptionalRelated3Variant, OptionalRelated4Variant, false, TempFiltersQltyInspectionGenRule);
        PreventShowingGeneratedInspectionEvenIfConfigured := PreviousPreventShowingState;

        if not HasInspection then
            exit(false);

        if not GetCreatedInspection(QltyInspectionHeader) then begin
            Clear(QltyInspectionHeader);
            exit(false);
        end;

        IsNewlyCreated := IsLastInspectionNewlyCreated();
        exit(true);
    end;

    /// <summary>
    /// Creates or reuses inspections for the supplied records and each line of a temporary tracking specification
    /// buffer, through the generation rule engine with the same automatic semantics as CreateInspectionFromRuleEngine.
    /// One creation call is issued per tracking line, with the tracking line supplied as the fourth record, which is
    /// the same shape the app's own receiving triggers use for tracked sources. The buffer is iterated
    /// within its current filters, so the caller can restrict the lines to process, and is left positioned on the last
    /// processed line. When the buffer holds no lines, a single creation call is issued without tracking information.
    /// The caller supplies the tracking lines, so any source can be served, including sources for which the app has no
    /// tracking collector of its own.
    ///
    /// Several tracking lines can resolve to the same inspection depending on the "Inspection Creation Option" and
    /// "Inspection Search Criteria" in Quality Management Setup, so the resolved inspections are returned as
    /// deduplicated lists of inspection numbers rather than assumed to be one per tracking line. The inspection
    /// resolved for a number is its latest re-inspection, which is the record found by filtering on "No." and
    /// calling FindLast on the "No.", "Re-inspection No." key.
    /// </summary>
    /// <param name="PrimaryRecordVariant">The record to create the inspections for (Record, RecordRef, or RecordId).</param>
    /// <param name="OptionalRelated2Variant">An optional related record used for rule matching and source field mapping, or an unassigned variant.</param>
    /// <param name="OptionalRelated3Variant">An optional related record used for rule matching and source field mapping, or an unassigned variant.</param>
    /// <param name="TempTrackingSpecification">The temporary tracking specification lines to create inspections for, iterated within their current filters.</param>
    /// <param name="TempFiltersQltyInspectionGenRule">A temporary record whose filters restrict which generation rules are considered; leave unfiltered to consider every automatic rule.</param>
    /// <param name="NewlyCreatedQltyInspectionIds">The numbers of the inspections inserted by this call, without duplicates.</param>
    /// <param name="AllResolvedQltyInspectionIds">The numbers of every inspection created or reused by this call, without duplicates.</param>
    /// <returns>True if at least one inspection was created or reused; otherwise, false.</returns>
    procedure CreateInspectionsFromRuleEngine(PrimaryRecordVariant: Variant; OptionalRelated2Variant: Variant; OptionalRelated3Variant: Variant; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempFiltersQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary; var NewlyCreatedQltyInspectionIds: List of [Code[20]]; var AllResolvedQltyInspectionIds: List of [Code[20]]): Boolean
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        DummyVariant: Variant;
        IsNewlyCreated: Boolean;
    begin
        Clear(NewlyCreatedQltyInspectionIds);
        Clear(AllResolvedQltyInspectionIds);

        if TempTrackingSpecification.FindSet() then
            repeat
                if CreateInspectionFromRuleEngine(PrimaryRecordVariant, OptionalRelated2Variant, OptionalRelated3Variant, TempTrackingSpecification, TempFiltersQltyInspectionGenRule, QltyInspectionHeader, IsNewlyCreated) then
                    TrackResolvedInspectionNo(QltyInspectionHeader."No.", IsNewlyCreated, NewlyCreatedQltyInspectionIds, AllResolvedQltyInspectionIds);
            until TempTrackingSpecification.Next() = 0
        else
            if CreateInspectionFromRuleEngine(PrimaryRecordVariant, OptionalRelated2Variant, OptionalRelated3Variant, DummyVariant, TempFiltersQltyInspectionGenRule, QltyInspectionHeader, IsNewlyCreated) then
                TrackResolvedInspectionNo(QltyInspectionHeader."No.", IsNewlyCreated, NewlyCreatedQltyInspectionIds, AllResolvedQltyInspectionIds);

        exit(AllResolvedQltyInspectionIds.Count() > 0);
    end;

    /// <summary>
    /// Creates an inspection for a record reference using matching generation-rule configuration.
    /// Use this to create a quality inspection for any given record.
    /// The generation rule configuration will be used to find the most appropriate
    /// inspection to create.
    /// </summary>
    /// <param name="TargetRecordRef">The primary source record.</param>
    /// <param name="IsManualCreation">Specifies whether creation was requested manually.</param>
    /// <returns>True if an inspection was created; otherwise, false.</returns>
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
    /// Creates an inspection for a record reference using a specific template.
    /// If you do not know which template you need, use CreateInspection.
    /// If you do know which template you need, then use this procedure.
    /// The caller must know in advance that the template and configuration is correct.
    /// </summary>
    /// <param name="TargetRecordRef">The primary source record.</param>
    /// <param name="IsManualCreation">Specifies whether creation was requested manually.</param>
    /// <param name="OptionalSpecificTemplate">The template code to use.</param>
    /// <returns>True if an inspection was created; otherwise, false.</returns>
    internal procedure CreateInspectionWithSpecificTemplate(TargetRecordRef: RecordRef; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]): Boolean
    var
        Dummy2Variant: Variant;
        Dummy3Variant: Variant;
    begin
        LastQltyInspectionCreateStatus := InternalCreateInspectionWithSpecificTemplate(TargetRecordRef, IsManualCreation, OptionalSpecificTemplate, Dummy2Variant, Dummy3Variant);

        exit(LastQltyInspectionCreateStatus = LastQltyInspectionCreateStatus::Created);
    end;

    /// <summary>
    /// Creates an inspection with a specific template and up to two additional source records.
    /// </summary>
    /// <param name="TargetRecordRef">The primary source record.</param>
    /// <param name="IsManualCreation">Specifies whether creation was requested manually.</param>
    /// <param name="OptionalSpecificTemplate">The template code to use.</param>
    /// <param name="OptionalRec2Variant">An optional secondary source record.</param>
    /// <param name="OptionalRec3Variant">An optional tertiary source record.</param>
    /// <returns>The inspection creation status.</returns>
    local procedure InternalCreateInspectionWithSpecificTemplate(TargetRecordRef: RecordRef; IsManualCreation: Boolean; OptionalSpecificTemplate: Code[20]; OptionalRec2Variant: Variant; OptionalRec3Variant: Variant): Enum "Qlty. Inspection Create Status"
    var
        TempDummyQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        DummyRec4Variant: Variant;
    begin
        exit(InternalCreateInspectionWithSpecificTemplate(TargetRecordRef, IsManualCreation, OptionalSpecificTemplate, OptionalRec2Variant, OptionalRec3Variant, DummyRec4Variant, TempDummyQltyInspectionGenRule));
    end;

    /// <summary>
    /// Resolves generation configuration, source fields, reuse policy, workflows, and user feedback for inspection creation.
    /// </summary>
    /// <param name="TargetRecordRef">The primary source record.</param>
    /// <param name="IsManualCreation">Specifies whether creation was requested manually.</param>
    /// <param name="OptionalSpecificTemplate">The template code to use, or an empty value for generation-rule selection.</param>
    /// <param name="OptionalRec2Variant">An optional secondary source record.</param>
    /// <param name="OptionalRec3Variant">An optional tertiary source record.</param>
    /// <param name="OptionalRec4Variant">An optional fourth source record.</param>
    /// <param name="TempFiltersQltyInspectionGenRule">The temporary generation-rule filters to apply.</param>
    /// <returns>The inspection creation status.</returns>
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
        LastInspectionIsNewlyCreated := false;

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
            LastInspectionIsNewlyCreated := IsNewlyCreatedInspection;

            if IsNewlyCreatedInspection then
                QltyStartWorkflow.StartWorkflowInspectionCreated(QltyInspectionHeader);

            if GuiAllowed() and
               not PreventShowingGeneratedInspectionEvenIfConfigured and
               (QltyInspectionHeader."No." <> '')
            then
                if IsManualCreation then begin
                    if not TryRunInspectionPage(Page::"Qlty. Inspection", QltyInspectionHeader) then
                        QltyNotificationMgmt.NotifyInspectionCreated(QltyInspectionHeader);
                end else
                    if IsNewlyCreatedInspection then
                        QltyNotificationMgmt.NotifyInspectionCreated(QltyInspectionHeader);
        end else begin
            LastInspectionIsNewlyCreated := false;
            LogCreateInspectionProblem(TargetRecordRef, UnableToCreateInspectionForErr, Format(OriginalRecordId));
            if IsManualCreation and (not AvoidThrowingErrorWhenPossible) then
                Error(UnableToCreateInspectionForErr, Format(OriginalRecordId));
        end;

        OnAfterCreateInspectionAfterDialog(TargetRecordRef, RecordRefToBufferTriggeringRecord, IsManualCreation, OptionalSpecificTemplate, TempQltyInspectionGenRule, QltyInspectionHeader, OptionalRec2Variant, OptionalRec3Variant);
    end;

    /// <summary>
    /// Tries to open an inspection page for the supplied inspection record or filtered set.
    /// Attempts to run the specified inspection page for the given inspection header.
    /// Wrapped as a TryFunction because <c>Page.Run</c> will throw a permission error
    /// when the current user is not permitted to read the underlying inspection records.
    /// Callers should treat a false return as "page could not be shown" and fall back to a
    /// non-interactive path such as a notification.
    /// </summary>
    /// <param name="PageId">The page identifier to run.</param>
    /// <param name="QltyInspectionHeader">The inspection record or filtered set to display.</param>
    [TryFunction]
    local procedure TryRunInspectionPage(PageId: Integer; var QltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
        Page.Run(PageId, QltyInspectionHeader);
    end;

    /// <summary>
    /// Finds existing inspections for a primary source record variant.
    /// </summary>
    /// <param name="RaiseErrorIfNoRuleIsFound">Specifies whether a missing generation rule should cause an error.</param>
    /// <param name="ReferenceVariant">The primary source Record, RecordRef, or RecordId.</param>
    /// <param name="QltyInspectionHeader">The marked set of matching inspections.</param>
    /// <returns>True if at least one matching inspection was found; otherwise, false.</returns>
    internal procedure FindExistingInspectionWithVariant(RaiseErrorIfNoRuleIsFound: Boolean; ReferenceVariant: Variant; var QltyInspectionHeader: Record "Qlty. Inspection Header"): Boolean
    var
        Dummy2Variant: Variant;
        Dummy3Variant: Variant;
        Dummy4Variant: Variant;
    begin
        exit(FindExistingInspectionWithMultipleVariants(RaiseErrorIfNoRuleIsFound, ReferenceVariant, Dummy2Variant, Dummy3Variant, Dummy4Variant, QltyInspectionHeader));
    end;

    /// <summary>
    /// Finds existing inspections using a primary source variant and up to three related source variants.
    /// </summary>
    /// <param name="RaiseErrorIfNoRuleIsFound">Specifies whether a missing generation rule should cause an error.</param>
    /// <param name="ReferenceVariant">The primary source Record, RecordRef, or RecordId.</param>
    /// <param name="OptionalVariant2">An optional secondary source record.</param>
    /// <param name="OptionalVariant3">An optional tertiary source record.</param>
    /// <param name="OptionalVariant4">An optional fourth source record.</param>
    /// <param name="QltyInspectionHeader">The marked set of matching inspections.</param>
    /// <returns>True if at least one matching inspection was found; otherwise, false.</returns>
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
    /// Finds and marks inspections matching generation rules and the supplied source records.
    /// </summary>
    /// <param name="RaiseErrorIfNoRuleIsFound">Specifies whether a missing generation rule should cause an error.</param>
    /// <param name="TargetRecordRef">The primary source record.</param>
    /// <param name="Optional2RecordRef">An optional secondary source record.</param>
    /// <param name="Optional3RecordRef">An optional tertiary source record.</param>
    /// <param name="Optional4RecordRef">An optional fourth source record.</param>
    /// <param name="QltyInspectionHeader">The marked set of matching inspections.</param>
    /// <returns>True if at least one matching inspection was found; otherwise, false.</returns>
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
    /// Reuses or creates an inspection according to setup and generation-rule context.
    /// </summary>
    /// <param name="TempSourceFieldsFilledStubInspectionBufferQltyInspectionHeader">The temporary header containing resolved source fields.</param>
    /// <param name="TargetRecordRef">The primary source record.</param>
    /// <param name="OriginalTriggeringRecordRef">The record that triggered creation.</param>
    /// <param name="TempQltyInspectionGenRule">The generation rule used to select the template and behavior.</param>
    /// <param name="QltyInspectionHeader">The resolved existing or newly created inspection.</param>
    /// <param name="InspectionIsNew">Set to true when a new inspection is inserted.</param>
    /// <returns>True if an existing or newly created inspection was resolved; otherwise, false.</returns>
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
    /// Creates inspection lines and result conditions from the header's template and evaluates the new lines.
    /// </summary>
    /// <param name="QltyInspectionHeader">The inspection for which to create lines.</param>
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
    /// Finds inspections matching a primary source record, optional source variants, and a generation rule.
    /// </summary>
    /// <param name="TargetRecordRef">The primary source record.</param>
    /// <param name="OptionalVariant2">An optional secondary source Record, RecordRef, or RecordId.</param>
    /// <param name="OptionalVariant3">An optional tertiary source Record, RecordRef, or RecordId.</param>
    /// <param name="OptionalVariant4">An optional fourth source Record, RecordRef, or RecordId.</param>
    /// <param name="TempQltyInspectionGenRule">The generation rule used to constrain matching.</param>
    /// <param name="PrecedingQltyInspectionHeader">The matching inspection record or record set.</param>
    /// <param name="FindAll">Specifies whether to return all matches instead of the latest match.</param>
    /// <returns>True if at least one matching inspection was found; otherwise, false.</returns>
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
    /// Finds inspections matching up to four source records and a generation rule.
    /// </summary>
    /// <param name="TargetRecordRef">The primary source record.</param>
    /// <param name="Optional2RecordRef">An optional secondary source record.</param>
    /// <param name="Optional3RecordRef">An optional tertiary source record.</param>
    /// <param name="Optional4RecordRef">An optional fourth source record.</param>
    /// <param name="TempQltyInspectionGenRule">The generation rule used to constrain matching.</param>
    /// <param name="PrecedingQltyInspectionHeader">The matching inspection record or record set.</param>
    /// <param name="FindAll">Specifies whether to return all matches instead of the latest match.</param>
    /// <returns>True if at least one matching inspection was found; otherwise, false.</returns>
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

    /// <summary>
    /// Applies configured search criteria to a source-field stub and finds matching inspections.
    /// </summary>
    /// <param name="TempInStubSearchForSimilarInspectionBufferQltyInspectionHeader">The temporary source-field stub used to build filters.</param>
    /// <param name="TempQltyInspectionGenRule">The generation rule used to supply the template constraint.</param>
    /// <param name="PrecedingQltyInspectionHeader">The matching inspection record or record set.</param>
    /// <param name="FindAll">Specifies whether to return all matches instead of the latest match.</param>
    /// <returns>True if at least one matching inspection was found; otherwise, false.</returns>
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
    /// Creates the next reinspection from the latest inspection with the same number.
    /// </summary>
    /// <param name="FromThisQltyInspectionHeader">The inspection for which a reinspection is requested.</param>
    /// <param name="CreatedReinspectionQltyInspectionHeader">The created reinspection.</param>
    internal procedure CreateReinspection(FromThisQltyInspectionHeader: Record "Qlty. Inspection Header"; var CreatedReinspectionQltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        PrecedingQltyInspectionHeader: Record "Qlty. Inspection Header";
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

        OnAfterCreateReinspection(FromThisQltyInspectionHeader, CreatedReinspectionQltyInspectionHeader);
    end;

    /// <summary>
    /// Initializes an open reinspection by copying the preceding inspection and clearing completion values.
    /// </summary>
    /// <param name="FromThisQltyInspectionHeader">The preceding inspection to copy.</param>
    /// <param name="CreatedReinspectionQltyInspectionHeader">The reinspection header to initialize.</param>
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
    /// Gets the inspection resolved by the latest creation call on this codeunit instance.
    /// Only use if you just called one of the CreateInspection() procedures.
    /// </summary>
    /// <param name="LastCreatedQltyInspectionHeader2">The latest resolved inspection with a record filter applied.</param>
    /// <returns>True if the latest resolved inspection still exists; otherwise, false.</returns>
    internal procedure GetCreatedInspection(var LastCreatedQltyInspectionHeader2: Record "Qlty. Inspection Header") StillExists: Boolean
    begin
        if LastCreatedQltyInspectionHeader."No." = '' then
            exit;

        LastCreatedQltyInspectionHeader2 := LastCreatedQltyInspectionHeader;
        LastCreatedQltyInspectionHeader2.SetRecFilter();
        StillExists := LastCreatedQltyInspectionHeader2.FindFirst();
    end;

    /// <summary>
    /// Gets the status from the latest inspection creation attempt.
    /// </summary>
    /// <returns>The latest inspection creation status.</returns>
    internal procedure GetLastCreatedStatus(): Enum "Qlty. Inspection Create Status"
    begin
        exit(LastQltyInspectionCreateStatus);
    end;

    /// <summary>
    /// Determines whether the latest resolved inspection was newly inserted rather than reused.
    /// </summary>
    /// <returns>True if the latest resolved inspection was newly created; otherwise, false.</returns>
    internal procedure IsLastInspectionNewlyCreated(): Boolean
    begin
        if LastCreatedQltyInspectionHeader."No." = '' then
            exit(false);

        exit(LastInspectionIsNewlyCreated);
    end;

    /// <summary>
    /// Logs an inspection creation error with source-record context.
    /// </summary>
    /// <param name="ContextRecordRef">The source record associated with the error.</param>
    /// <param name="Input">The message template to log.</param>
    /// <param name="Variable1">The value substituted into the message template.</param>
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
    /// Creates inspections for the marked temporary tracking specifications as a manual operation.
    /// </summary>
    /// <param name="TempTrackingSpecification">The temporary tracking specifications whose marked records to process.</param>
    internal procedure CreateMultipleInspectionsForMarkedTrackingSpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
        CreateMultipleInspectionsForMarkedTrackingSpecification(TempTrackingSpecification, true);
    end;

    /// <summary>
    /// Creates inspections for the marked temporary tracking specifications.
    /// </summary>
    /// <param name="TempTrackingSpecification">The temporary tracking specifications whose marked records to process.</param>
    /// <param name="IsManualCreation">Specifies whether creation was requested manually.</param>
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

    /// <summary>
    /// Creates inspections for a set of records without generation-rule filters.
    /// </summary>
    /// <param name="SetOfRecordsRecordRef">The record reference containing the records to process.</param>
    /// <param name="IsManualCreation">Specifies whether creation was requested manually.</param>
    internal procedure CreateMultipleInspectionsForMultipleRecords(var SetOfRecordsRecordRef: RecordRef; IsManualCreation: Boolean)
    var
        TempDummyFiltersQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
    begin
        CreateMultipleInspectionsForMultipleRecords(SetOfRecordsRecordRef, IsManualCreation, TempDummyFiltersQltyInspectionGenRule);
    end;

    /// <summary>
    /// Creates or resolves inspections for a set of records and displays manual results when appropriate.
    /// </summary>
    /// <param name="SetOfRecordsRecordRef">The record reference containing the records to process.</param>
    /// <param name="IsManualCreation">Specifies whether creation was requested manually.</param>
    /// <param name="TempFiltersQltyInspectionGenRule">The temporary generation-rule filters to apply.</param>
    internal procedure CreateMultipleInspectionsForMultipleRecords(var SetOfRecordsRecordRef: RecordRef; IsManualCreation: Boolean; var TempFiltersQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary)
    var
        NewlyCreatedQltyInspectionIds, AllResolvedQltyInspectionIds : List of [Code[20]];
        NewlyCreatedCount, ExistingMatchedCount : Integer;
    begin
        CreateMultipleInspectionsWithoutDisplaying(SetOfRecordsRecordRef, IsManualCreation, TempFiltersQltyInspectionGenRule, NewlyCreatedQltyInspectionIds, AllResolvedQltyInspectionIds);

        if IsManualCreation and GuiAllowed() then begin
            NewlyCreatedCount := NewlyCreatedQltyInspectionIds.Count();
            if NewlyCreatedCount > 0 then
                DisplayInspectionsIfConfigured(IsManualCreation, NewlyCreatedQltyInspectionIds)
            else begin
                ExistingMatchedCount := AllResolvedQltyInspectionIds.Count();
                if ExistingMatchedCount > 0 then
                    if Confirm(StrSubstNo(SomeInspectionsMatchedQst, ExistingMatchedCount), true) then
                        DisplayInspectionsIfConfigured(IsManualCreation, AllResolvedQltyInspectionIds);
            end;
        end;
    end;

    /// <summary>
    /// Shows one or more resolved inspections, falling back to notifications when pages cannot be opened or filters are too long.
    /// </summary>
    /// <param name="IsManualCreation">Specifies whether creation was requested manually.</param>
    /// <param name="ToDisplayQltyInspectionIds">The inspection numbers to display or report.</param>
    internal procedure DisplayInspectionsIfConfigured(IsManualCreation: Boolean; var ToDisplayQltyInspectionIds: List of [Code[20]])
    var
        CreatedQltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyNotificationMgmt: Codeunit "Qlty. Notification Mgmt.";
        InspectionNo: Code[20];
        PipeSeparatedFilter: Text;
        FilterExceedsMaxLength: Boolean;
        MaxSafeFilterLength: Integer;
    begin
        QltyManagementSetup.Get();
        MaxSafeFilterLength := 1024;

        if GuiAllowed() then begin
            foreach InspectionNo in ToDisplayQltyInspectionIds do
                if InspectionNo <> '' then begin
                    if StrLen(PipeSeparatedFilter) > 1 then
                        PipeSeparatedFilter += '|';
                    PipeSeparatedFilter += InspectionNo;
                    if StrLen(PipeSeparatedFilter) > MaxSafeFilterLength then begin
                        FilterExceedsMaxLength := true;
                        break;
                    end;
                end;

            if FilterExceedsMaxLength then begin
                QltyNotificationMgmt.NotifyMultipleInspectionsCreatedByCount(ToDisplayQltyInspectionIds.Count());
                exit;
            end;

            CreatedQltyInspectionHeader.SetFilter("No.", PipeSeparatedFilter);
            if ToDisplayQltyInspectionIds.Count() = 1 then begin
                CreatedQltyInspectionHeader.SetCurrentKey("No.", "Re-inspection No.");
                CreatedQltyInspectionHeader.FindLast();
                if IsManualCreation then begin
                    if not TryRunInspectionPage(Page::"Qlty. Inspection", CreatedQltyInspectionHeader) then
                        QltyNotificationMgmt.NotifyInspectionCreated(CreatedQltyInspectionHeader);
                end else
                    QltyNotificationMgmt.NotifyInspectionCreated(CreatedQltyInspectionHeader);
            end else begin
                CreatedQltyInspectionHeader.FindSet();
                if IsManualCreation then begin
                    if not TryRunInspectionPage(Page::"Qlty. Inspection List", CreatedQltyInspectionHeader) then
                        QltyNotificationMgmt.NotifyMultipleInspectionsCreated(CreatedQltyInspectionHeader);
                end else
                    QltyNotificationMgmt.NotifyMultipleInspectionsCreated(CreatedQltyInspectionHeader);
            end;
        end;
    end;

    /// <summary>
    /// Resolves inspections for multiple records without displaying them and separates new from reused inspections.
    /// </summary>
    /// <param name="SetOfRecordsRecordRef">The record reference containing the records to process.</param>
    /// <param name="IsManualCreation">Specifies whether creation was requested manually.</param>
    /// <param name="TempFiltersQltyInspectionGenRule">The temporary generation-rule filters to apply.</param>
    /// <param name="NewlyCreatedQltyInspectionIds">The inspection numbers newly inserted by this call.</param>
    /// <param name="AllResolvedQltyInspectionIds">All inspection numbers resolved by creation or reuse.</param>
    internal procedure CreateMultipleInspectionsWithoutDisplaying(var SetOfRecordsRecordRef: RecordRef; IsManualCreation: Boolean; var TempFiltersQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary; var NewlyCreatedQltyInspectionIds: List of [Code[20]]; var AllResolvedQltyInspectionIds: List of [Code[20]])
    var
        TempCopyOfSingleRecordRecordRef: RecordRef;
        ParentRecordRef: RecordRef;
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
                CreateInspectionForSelfOrDirectParent(
                    TempCopyOfSingleRecordRecordRef,
                    TempFiltersQltyInspectionGenRule,
                    ParentRecordRef,
                    NewlyCreatedQltyInspectionIds,
                    AllResolvedQltyInspectionIds,
                    true,
                    IsManualCreation);
            until SetOfRecordsRecordRef.Next() = 0;

        // Error only when no inspection was resolved at all (neither newly created nor matching ones reused).
        if AllResolvedQltyInspectionIds.Count() = 0 then begin
            if AvoidThrowingErrorWhenPossible then
                exit;

            if ParentRecordRef.Number() <> 0 then
                Error(UnableToCreateInspectionForParentOrChildErr, ParentRecordRef.Name, SetOfRecordsRecordRef.Name)
            else
                Error(UnableToCreateInspectionForRecordErr, SetOfRecordsRecordRef.Name);
        end;
    end;

    /// <summary>
    /// Resolves inspections for a record, its direct parent, related item, and applicable tracking entries.
    /// </summary>
    /// <param name="TempSelfRecordRef">The temporary source record to process.</param>
    /// <param name="TempFiltersQltyInspectionGenRule">The temporary generation-rule filters to apply.</param>
    /// <param name="FoundParentRecordRef">The direct parent record when one is found.</param>
    /// <param name="NewlyCreatedQltyInspectionIds">The inspection numbers newly inserted by this call.</param>
    /// <param name="AllResolvedQltyInspectionIds">All inspection numbers resolved by creation or reuse.</param>
    /// <param name="PreventInspectionFromDisplayingEvenIfConfigured">Specifies whether generated inspections must remain hidden.</param>
    /// <param name="IsManualCreation">Specifies whether creation was requested manually.</param>
    local procedure CreateInspectionForSelfOrDirectParent(var TempSelfRecordRef: RecordRef; var TempFiltersQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary; var FoundParentRecordRef: RecordRef; var NewlyCreatedQltyInspectionIds: List of [Code[20]]; var AllResolvedQltyInspectionIds: List of [Code[20]]; PreventInspectionFromDisplayingEvenIfConfigured: Boolean; IsManualCreation: Boolean)
    var
        Item: Record Item;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
        ReservationManagement: Codeunit "Reservation Management";
        ParentRecordRef: RecordRef;
        VariantEmptyOrTrackingSpecification: Variant;
        Dummy4Variant: Variant;
    begin
        QltyInspectionCreate.SetPreventDisplayingInspectionEvenIfConfigured(PreventInspectionFromDisplayingEvenIfConfigured);

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

                if QltyInspectionCreate.CreateInspectionWithMultiVariants(ParentRecordRef, TempSelfRecordRef, VariantEmptyOrTrackingSpecification, Dummy4Variant, IsManualCreation, TempFiltersQltyInspectionGenRule) then
                    TrackResolvedInspection(QltyInspectionCreate, NewlyCreatedQltyInspectionIds, AllResolvedQltyInspectionIds);
            until RelatedReservFilterReservationEntry.Next() = 0;
        end else begin
            if TempFiltersQltyInspectionGenRule."Item Filter" <> '' then begin
                Clear(Item);
                if QltyTraversal.FindRelatedItem(Item, ParentRecordRef, TempSelfRecordRef, VariantEmptyOrTrackingSpecification, Dummy4Variant) then
                    exit;
            end;

            if QltyInspectionCreate.CreateInspectionWithMultiVariants(TempSelfRecordRef, ParentRecordRef, Dummy4Variant, Dummy4Variant, IsManualCreation, TempFiltersQltyInspectionGenRule) then
                TrackResolvedInspection(QltyInspectionCreate, NewlyCreatedQltyInspectionIds, AllResolvedQltyInspectionIds);
        end;
    end;

    /// <summary>
    /// Adds the latest resolved inspection to deduplicated all-resolved and newly-created lists.
    /// Records the inspection returned by the last create call on <paramref name="QltyInspectionCreate"/> in the
    /// supplied tracking lists, deduplicating by inspection "No.". The all-resolved list captures both newly created
    /// and reused matching inspections so callers can detect reuse; the newly-created list only captures inspections that were
    /// actually inserted and is used to drive "created inspections" notifications and display.
    /// </summary>
    /// <param name="QltyInspectionCreate">The creation codeunit containing the latest resolved inspection.</param>
    /// <param name="NewlyCreatedQltyInspectionIds">The list of newly inserted inspection numbers.</param>
    /// <param name="AllResolvedQltyInspectionIds">The list of all resolved inspection numbers.</param>
    local procedure TrackResolvedInspection(var QltyInspectionCreate: Codeunit "Qlty. Inspection - Create"; var NewlyCreatedQltyInspectionIds: List of [Code[20]]; var AllResolvedQltyInspectionIds: List of [Code[20]])
    var
        LastResolvedQltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        if not QltyInspectionCreate.GetCreatedInspection(LastResolvedQltyInspectionHeader) then
            exit;

        TrackResolvedInspectionNo(LastResolvedQltyInspectionHeader."No.", QltyInspectionCreate.IsLastInspectionNewlyCreated(), NewlyCreatedQltyInspectionIds, AllResolvedQltyInspectionIds);
    end;

    /// <summary>
    /// Adds an inspection number to the deduplicated all-resolved list, and to the newly-created list when it was inserted rather than reused.
    /// </summary>
    /// <param name="InspectionNo">The inspection number to record.</param>
    /// <param name="IsNewlyCreated">True when the inspection was inserted rather than reused.</param>
    /// <param name="NewlyCreatedQltyInspectionIds">The list of newly inserted inspection numbers.</param>
    /// <param name="AllResolvedQltyInspectionIds">The list of all resolved inspection numbers.</param>
    local procedure TrackResolvedInspectionNo(InspectionNo: Code[20]; IsNewlyCreated: Boolean; var NewlyCreatedQltyInspectionIds: List of [Code[20]]; var AllResolvedQltyInspectionIds: List of [Code[20]])
    begin
        if not AllResolvedQltyInspectionIds.Contains(InspectionNo) then
            AllResolvedQltyInspectionIds.Add(InspectionNo);

        if IsNewlyCreated then
            if not NewlyCreatedQltyInspectionIds.Contains(InspectionNo) then
                NewlyCreatedQltyInspectionIds.Add(InspectionNo);
    end;

    /// <summary>
    /// Sets whether generated inspections should remain hidden even when setup would display them.
    /// </summary>
    /// <param name="PreventDisplayingInspectionEvenIfConfigured">The display-suppression state to use.</param>
    internal procedure SetPreventDisplayingInspectionEvenIfConfigured(PreventDisplayingInspectionEvenIfConfigured: Boolean)
    begin
        PreventShowingGeneratedInspectionEvenIfConfigured := PreventDisplayingInspectionEvenIfConfigured;
    end;

    /// <summary>
    /// Populates an inspection stub from a primary source record and up to three optional source records.
    /// </summary>
    /// <param name="InspectionStubToFillQltyInspectionHeader">The inspection stub to populate.</param>
    /// <param name="MandatoryPrimaryRecordRef">The primary source record.</param>
    /// <param name="OptionalVariant2">An optional secondary source record.</param>
    /// <param name="OptionalVariant3">An optional tertiary source record.</param>
    /// <param name="OptionalVariant4">An optional fourth source record.</param>
    /// <returns>False because the current implementation does not assign a return value.</returns>
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
    /// Captures the calculated reservation-entry filters while the subscriber is explicitly bound.
    /// </summary>
    /// <param name="SourceRecRef">The reservation source record.</param>
    /// <param name="CalcReservEntry">The calculated reservation entry whose filters are captured.</param>
    /// <param name="Direction">The transfer direction used by reservation management.</param>
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
    /// <param name="QltyInspectionHeader">The resolved inspection.</param>
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
    /// <param name="QltyInspectionHeader">The resolved inspection.</param>
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
    /// <param name="Optional2RecordRef">Optional. Some events, typically automatic events, will have multiple records to assist with setting source details.</param>
    /// <param name="Optional3RecordRef">Optional. Some events, typically automatic events, will have multiple records to assist with setting source details.</param>
    /// <param name="Optional4RecordRef">Optional. Some events, typically automatic events, will have multiple records to assist with setting source details.</param>
    /// <param name="QltyInspectionHeader">The found inspection</param>
    /// <param name="Result">Set to true if you found the record. If you set to true you must also supply QltyInspectionHeader</param>
    /// <param name="IsHandled">Set to true to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindExistingInspection(TargetRecordRef: RecordRef; Optional2RecordRef: RecordRef; Optional3RecordRef: RecordRef; Optional4RecordRef: RecordRef; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}
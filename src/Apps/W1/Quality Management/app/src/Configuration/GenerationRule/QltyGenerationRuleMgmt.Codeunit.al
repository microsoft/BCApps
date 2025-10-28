// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.GenerationRule;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;

/// <summary>
/// Methods to assist with quality inspection test generation rule management.
/// </summary>
codeunit 20405 "Qlty. Generation Rule Mgmt."
{
    var
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        QltyTraversal: Codeunit "Qlty. Traversal";
        UnexpectedAndNoDetailsErr: Label 'Something unexpected went wrong trying to find a matching quality inspection test generation rule. Please review your Quality Inspection source table configuration.';
        CouldNotFindGenerationRuleErr: Label 'Could not find any compatible test generation rules for the template %1. Navigate to Quality Inspection Test Generation Rules and create a generation rule for the template %1', Comment = '%1=the template';
        CouldNotFindSourceErr: Label 'There are generation rules for the template %1, however there is no source configuration that describes how to connect control fields. Navigate to Quality Inspection Source Configuration list and create a source configuration for table(s) %2', Comment = '%1=the template, %2=the table';
        UnexpectedUnableWithADetailErr: Label 'Cannot find a test to create that will work with [%1]. Please review your Quality Inspection Source table configurations and your Quality Inspection Test Generation Rules.', Comment = '%1=the id/name';
        NoGenRuleErr: Label 'Cannot find a test to create that will work with [%1]. Please review your Quality Inspection Source table configurations and your Quality Inspection Test Generation Rules.', Comment = '%1=the id/name';

    /// <summary>
    /// Sets the filter on the target configuration to sources that could match the supplied template.
    /// Use this to restrict which possible sources exist based on the input record.
    /// </summary>
    /// <param name="TemplateCode"></param>
    /// <param name="QltyInspectSourceConfig"></param>
    internal procedure SetFilterToApplicableTemplates(TemplateCode: Code[20]; var QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.")
    var
        TempSearchQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
        TempAvailableQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config." temporary;
        Filter: Text;
        KnownTableIds: List of [Integer];
        CanLoopDoTargets: Boolean;
        CanCreateTestDirectly: Boolean;
        TablesToConfigure: Text;
    begin
        if not FindAllCompatibleGenerationRules(TemplateCode, TempSearchQltyInTestGenerationRule) then
            Error(CouldNotFindGenerationRuleErr, TemplateCode);

        TempSearchQltyInTestGenerationRule.Reset();
        if TempSearchQltyInTestGenerationRule.FindSet() then begin
            Filter := '0';
            repeat
                TempAvailableQltyInspectSourceConfig.Reset();
                TempAvailableQltyInspectSourceConfig.DeleteAll(false);

                CanLoopDoTargets := QltyTraversal.FindPossibleTargetsBasedOnConfigRecursive(TempSearchQltyInTestGenerationRule."Source Table No.", TempAvailableQltyInspectSourceConfig);
                if not CanLoopDoTargets then begin
                    if StrLen(TablesToConfigure) > 0 then
                        TablesToConfigure += ', ' + Format(TempSearchQltyInTestGenerationRule."Source Table No.")
                    else
                        TablesToConfigure := Format(TempSearchQltyInTestGenerationRule."Source Table No.");
                end else begin
                    TempAvailableQltyInspectSourceConfig.Reset();
                    if TempAvailableQltyInspectSourceConfig.FindSet() then
                        repeat
                            if not KnownTableIds.Contains(TempAvailableQltyInspectSourceConfig."From Table No.") then begin
                                KnownTableIds.Add(TempAvailableQltyInspectSourceConfig."From Table No.");
                                Filter += '|';
                                Filter += Format(TempAvailableQltyInspectSourceConfig."From Table No.");
                                CanCreateTestDirectly := true;
                            end;
                        until TempAvailableQltyInspectSourceConfig.Next() = 0;
                end;
            until TempSearchQltyInTestGenerationRule.Next() = 0;
            QltyInspectSourceConfig.SetFilter("From Table No.", Filter);
        end;
        if not CanCreateTestDirectly then
            Error(CouldNotFindSourceErr, TemplateCode, TablesToConfigure);
    end;

    /// <summary>
    /// Sets the filter on the target configuration to sources that could match the supplied template.
    /// Use this to restrict which possible sources exist based on the input record.
    /// </summary>
    /// <param name="TemplateCode"></param>
    /// <param name="QltyInspectSourceConfig"></param>
    internal procedure GetFilterForAvailableConfigurations() Filter: Text
    var
        AvailableQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        KnownTableIds: List of [Integer];
    begin
        Filter := '0';
        if AvailableQltyInspectSourceConfig.FindSet() then
            repeat
                if not KnownTableIds.Contains(AvailableQltyInspectSourceConfig."From Table No.") then begin
                    KnownTableIds.Add(AvailableQltyInspectSourceConfig."From Table No.");
                    Filter += '|';
                    Filter += Format(AvailableQltyInspectSourceConfig."From Table No.");
                end;
                if not KnownTableIds.Contains(AvailableQltyInspectSourceConfig."To Table No.") and
                  (AvailableQltyInspectSourceConfig."To Table No." <> Database::"Qlty. Inspection Test Header") then begin
                    KnownTableIds.Add(AvailableQltyInspectSourceConfig."To Table No.");
                    Filter += '|';
                    Filter += Format(AvailableQltyInspectSourceConfig."To Table No.");
                end;
            until AvailableQltyInspectSourceConfig.Next() = 0;
    end;

    /// <summary>
    /// Finds first matching Generation Rule
    /// </summary>
    /// <param name="RaiseErrorIfNoRuleIsFound">specifies whether an error should be raised if no rule is found</param>
    /// <param name="TargetRecordRef">target recordref for rules search</param>
    /// <param name="OptionalItem">optional item to filter rules search</param>
    /// <param name="OptionalSpecificTemplate">Optional template to filter rules search</param>
    /// <param name="TempQltyInTestGenerationRule">Returned Generation Rule</param>
    /// <returns>true if a matching Generation Rule was found</returns>
    procedure FindMatchingGenerationRule(RaiseErrorIfNoRuleIsFound: Boolean; var TargetRecordRef: RecordRef; var OptionalItem: Record Item; OptionalSpecificTemplate: Code[20]; var TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary) Found: Boolean
    var
        TempAvailableQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config." temporary;
        TempAlreadyConsideredsWhileSearchingQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config." temporary;
    begin
        if not QltyTraversal.FindPossibleTargetsBasedOnConfigRecursive(TargetRecordRef.Number(), TempAvailableQltyInspectSourceConfig) then
            if RaiseErrorIfNoRuleIsFound then
                Error(UnexpectedUnableWithADetailErr, Format(TargetRecordRef.RecordId()));

        Found := FindFirstGenerationRuleAndRecordBasedOnRecursive(
            QltyMiscHelpers.GetArbitraryMaximumRecursion(),
                false,
                RaiseErrorIfNoRuleIsFound,
                TargetRecordRef,
                OptionalItem,
                TempAvailableQltyInspectSourceConfig,
                TempAlreadyConsideredsWhileSearchingQltyInspectSourceConfig,
                OptionalSpecificTemplate,
                TempQltyInTestGenerationRule);
    end;

    /// <summary>
    /// Finds first matching Generation Rule, filtered by Generation Rule Activation Trigger
    /// </summary>
    /// <param name="RaiseErrorIfNoRuleIsFound">specifies whether an error should be raised if no rule is found</param>
    /// <param name="IsManualCreation">specifies whether to search for rules targeted at manual creation or automatic creation.</param>
    /// <param name="TargetRecordRef">target recordref for rules search</param>
    /// <param name="OptionalItem">optional item to filter rules search</param>
    /// <param name="OptionalSpecificTemplate">Optional template to filter rules search</param>
    /// <param name="TempQltyInTestGenerationRule">Returned Generation Rule</param>
    /// <returns>true if a matching Generation Rule was found</returns>
    procedure FindMatchingGenerationRule(RaiseErrorIfNoRuleIsFound: Boolean; IsManualCreation: Boolean; var TargetRecordRef: RecordRef; var OptionalItem: Record Item; OptionalSpecificTemplate: Code[20]; var TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary) Found: Boolean
    var
        TempAvailableQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config." temporary;
        TempAlreadyConsideredsWhileSearchingQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config." temporary;
    begin
        if not QltyTraversal.FindPossibleTargetsBasedOnConfigRecursive(TargetRecordRef.Number(), TempAvailableQltyInspectSourceConfig) then
            if RaiseErrorIfNoRuleIsFound then
                Error(NoGenRuleErr, Format(TargetRecordRef.RecordId()));

        Found := FindFirstGenerationRuleAndRecordBasedOnRecursive(
            QltyMiscHelpers.GetArbitraryMaximumRecursion(),
            true,
            IsManualCreation,
            TargetRecordRef,
            OptionalItem,
            TempAvailableQltyInspectSourceConfig,
            TempAlreadyConsideredsWhileSearchingQltyInspectSourceConfig,
            OptionalSpecificTemplate,
            TempQltyInTestGenerationRule);
    end;

    /// <summary>
    /// Finds the first matching generation rule and record.
    /// Note that TempQltyInTestGenerationRule can be used to supply optional input filters, however it will be replaced upon output.
    /// </summary>
    /// <param name="MaxRecursion"></param>
    /// <param name="UseActivationFilter"></param>
    /// <param name="IsManualCreation"></param>
    /// <param name="TargetRecordRef"></param>
    /// <param name="OptionalItem"></param>
    /// <param name="TempAvailableQltyInspectSourceConfig"></param>
    /// <param name="TempAlreadySearchedsQltyInspectSourceConfig"></param>
    /// <param name="OptionalSpecificTemplate"></param>
    /// <param name="TempQltyInTestGenerationRule">Filters are copied from the input, but will be replaced on output.</param>
    /// <returns></returns>
    local procedure FindFirstGenerationRuleAndRecordBasedOnRecursive(MaxRecursion: Integer; UseActivationFilter: Boolean; IsManualCreation: Boolean; var TargetRecordRef: RecordRef; var OptionalItem: Record Item; var TempAvailableQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config." temporary; var TempAlreadySearchedsQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config." temporary; OptionalSpecificTemplate: Code[20]; var TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary) Found: Boolean
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        SearchItem: Record Item;
        FoundLinkRecordRef: RecordRef;
        TemporaryTestMatchRecordRef: RecordRef;
    begin
        MaxRecursion := MaxRecursion - 1;
        if MaxRecursion <= 0 then
            Error(UnexpectedAndNoDetailsErr);

        QltyInTestGenerationRule.CopyFilters(TempQltyInTestGenerationRule);
        QltyInTestGenerationRule.SetRange("Source Table No.", TargetRecordRef.Number());
        if OptionalSpecificTemplate <> '' then
            QltyInTestGenerationRule.SetRange("Template Code", OptionalSpecificTemplate);

        if UseActivationFilter then
            if IsManualCreation then
                QltyInTestGenerationRule.SetFilter("Activation Trigger", '%1|%2', QltyInTestGenerationRule."Activation Trigger"::"Manual or Automatic", QltyInTestGenerationRule."Activation Trigger"::"Manual only")
            else
                QltyInTestGenerationRule.SetFilter("Activation Trigger", '%1|%2', QltyInTestGenerationRule."Activation Trigger"::"Manual or Automatic", QltyInTestGenerationRule."Activation Trigger"::"Automatic only");

        QltyInTestGenerationRule.SetCurrentKey("Sort Order");
        QltyInTestGenerationRule.Ascending(true);
        if QltyInTestGenerationRule.FindSet() then
            repeat
                Clear(TemporaryTestMatchRecordRef);
                TemporaryTestMatchRecordRef.Open(TargetRecordRef.Number(), true);
                TemporaryTestMatchRecordRef.Copy(TargetRecordRef);
                if TemporaryTestMatchRecordRef.Insert(false) then;
                TemporaryTestMatchRecordRef.Reset();
                TemporaryTestMatchRecordRef.SetView(QltyInTestGenerationRule."Condition Filter");
                if TemporaryTestMatchRecordRef.FindFirst() then
                    if (QltyInTestGenerationRule."Item Filter" <> '') and (OptionalItem."No." <> '') then begin
                        Clear(SearchItem);
                        SearchItem := OptionalItem;
                        SearchItem.SetRecFilter();
                        SearchItem.FilterGroup(20);
                        SearchItem.SetView(QltyInTestGenerationRule."Item Filter");
                        if SearchItem.Count() > 0 then
                            if DoesMatchItemAttributeFiltersOrNoFilter(QltyInTestGenerationRule, OptionalItem) then begin
                                TempQltyInTestGenerationRule := QltyInTestGenerationRule;
                                Found := TempQltyInTestGenerationRule.Insert();
                            end;

                        OptionalItem.FilterGroup(0);
                        SearchItem.FilterGroup(0);
                    end else
                        if (OptionalItem."No." <> '') and (QltyInTestGenerationRule."Item Attribute Filter" <> '') then begin
                            if DoesMatchItemAttributeFiltersOrNoFilter(QltyInTestGenerationRule, OptionalItem) then begin
                                TempQltyInTestGenerationRule := QltyInTestGenerationRule;
                                Found := TempQltyInTestGenerationRule.Insert();
                            end;
                        end else begin
                            TempQltyInTestGenerationRule := QltyInTestGenerationRule;
                            Found := TempQltyInTestGenerationRule.Insert();
                        end;
            until (QltyInTestGenerationRule.Next() = 0) or (Found);

        if not Found then begin
            TempAvailableQltyInspectSourceConfig.Reset();
            TempAvailableQltyInspectSourceConfig.SetRange("To Table No.", TargetRecordRef.Number());
            if TempAvailableQltyInspectSourceConfig.FindSet() then
                repeat
                    TempAlreadySearchedsQltyInspectSourceConfig.Reset();
                    if not TempAlreadySearchedsQltyInspectSourceConfig.Get(TempAvailableQltyInspectSourceConfig.Code) then begin
                        TempAlreadySearchedsQltyInspectSourceConfig := TempAvailableQltyInspectSourceConfig;
                        if TempAlreadySearchedsQltyInspectSourceConfig.Insert() then;
                        if QltyTraversal.FindFromTableLinkedRecordWithToTable(true, false, TempAvailableQltyInspectSourceConfig, TargetRecordRef, FoundLinkRecordRef) then
                            if FindFirstGenerationRuleAndRecordBasedOnRecursive(MaxRecursion, UseActivationFilter, IsManualCreation, FoundLinkRecordRef, OptionalItem, TempAvailableQltyInspectSourceConfig, TempAlreadySearchedsQltyInspectSourceConfig, OptionalSpecificTemplate, TempQltyInTestGenerationRule) then begin
                                Found := true;
                                TargetRecordRef := FoundLinkRecordRef;
                            end;
                    end;
                until (TempAvailableQltyInspectSourceConfig.Next() = 0) or Found;
        end;
    end;

    /// <summary>
    /// If there is no item attribute filter, returns true.
    /// If there is an item attribute filter, then it must match.
    /// </summary>
    /// <returns></returns>
    local procedure DoesMatchItemAttributeFiltersOrNoFilter(var QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule"; var Item: Record Item): Boolean
    var
        TempFilterItemAttributesBuffer: Record "Filter Item Attributes Buffer" temporary;
        TempsItem: Record Item temporary;
        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
        ItemAttributeManagement: Codeunit "Item Attribute Management";
    begin
        if Item."No." = '' then
            exit(false);
        if QltyInTestGenerationRule."Item Attribute Filter" = '' then
            exit(true);

        QltyFilterHelpers.DeserializeFilterIntoItemAttributesBuffer(QltyInTestGenerationRule."Item Attribute Filter", TempFilterItemAttributesBuffer);
        QltyFilterHelpers.SetItemFilterForItemAttributeFilterSearching(Item."No.");
        BindSubscription(QltyFilterHelpers);
        ItemAttributeManagement.FindItemsByAttributes(TempFilterItemAttributesBuffer, TempsItem);
        UnbindSubscription(QltyFilterHelpers);
        QltyFilterHelpers.SetItemFilterForItemAttributeFilterSearching('');

        exit(not TempsItem.IsEmpty());
    end;

    internal procedure FindAllCompatibleGenerationRules(TemplateCode: Code[20]; var TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary) Found: Boolean
    var
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
    begin
        QltyInTestGenerationRule.SetRange("Template Code", TemplateCode);
        QltyInTestGenerationRule.SetFilter("Activation Trigger", '<>%1', QltyInTestGenerationRule."Activation Trigger"::Disabled);
        QltyInTestGenerationRule.SetCurrentKey("Sort Order");
        QltyInTestGenerationRule.Ascending(true);
        if QltyInTestGenerationRule.FindSet() then
            repeat
                TempQltyInTestGenerationRule := QltyInTestGenerationRule;
                if TempQltyInTestGenerationRule.Insert() then;
                Found := true;
            until QltyInTestGenerationRule.Next() = 0;
    end;
}

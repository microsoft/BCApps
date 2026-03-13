// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.SourceConfiguration;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Purchases.Vendor;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Sales.Customer;
using System.Reflection;

/// <summary>
/// Methods to assist with traversing records, connecting one record to another.
/// </summary>
codeunit 20408 "Qlty. Traversal"
{
    var
        QltyConfigurationHelpers: Codeunit "Qlty. Configuration Helpers";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        ControlInfoToVisibility: Dictionary of [Text, Boolean];
        ControlInfoToCaptionClass: Dictionary of [Text, Text];
        SomethingUnexpectedChainErr: Label 'Something unexpected happened while trying to chain records together to create a Quality Inspection. Please review your Quality Inspection source configuration.';
        PleaseReviewSourceTableConfigErr: Label 'Please review your Quality Inspection Source configuration. It seems like the configuration might be recursive, duplicated, reversed, or incompatible. You might also just have too deeply nested connections. Open the Quality Inspection Source configuration and review your configuration.';
        UnexpectedApplyingSourceFieldsErr: Label 'Something unexpected went wrong populating source field information for the table %1. Please review your Quality Inspection source table configuration.', Comment = '%1 = the table number';
        ConfigurationNestingOrCircularErr: Label 'Please review your Quality Inspection Source Configuration. There could be excessive nesting or circular dependencies.', Locked = true;

    /// <summary>
    /// Finds a linked record based on the configured source configuration by traversing from a target table to a source table.
    /// Uses field mappings defined in the source configuration to match records between tables.
    /// </summary>
    /// <param name="SingleOnly">If true, finds only the first matching record; if false, finds all matching records</param>
    /// <param name="AllowTrackingMapping">If true, allows finding records via item tracking mappings in addition to chained table mappings</param>
    /// <param name="TempFromQltyInspectSourceConfig">Temporary source configuration record defining the table relationship and field mappings</param>
    /// <param name="ToTableRecordRef">Input: RecordRef to the target table record to search from</param>
    /// <param name="FromTableRecordRef">Output: RecordRef to the found source table record(s)</param>
    /// <returns>True if at least one linked record was found; False otherwise</returns>
    internal procedure FindFromTableLinkedRecordWithToTable(SingleOnly: Boolean; AllowTrackingMapping: Boolean; var TempFromQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config." temporary; var ToTableRecordRef: RecordRef; var FromTableRecordRef: RecordRef) Found: Boolean
    var
        QltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        ValueInCurrentVariant: Variant;
    begin
        Found := false;
        if TempFromQltyInspectSourceConfig."To Table No." <> ToTableRecordRef.Number() then
            Error(SomethingUnexpectedChainErr);

        Clear(FromTableRecordRef);
        FromTableRecordRef.Open(TempFromQltyInspectSourceConfig."From Table No.");
        if TempFromQltyInspectSourceConfig."From Table Filter" <> '' then
            FromTableRecordRef.SetView(TempFromQltyInspectSourceConfig."From Table Filter");

        QltyInspectSrcFldConf.SetRange(Code, TempFromQltyInspectSourceConfig.Code);
        if AllowTrackingMapping then
            QltyInspectSrcFldConf.SetFilter("To Type", '%1|%2', QltyInspectSrcFldConf."To Type"::"Chained table", QltyInspectSrcFldConf."To Type"::"Item Tracking")
        else
            QltyInspectSrcFldConf.SetRange("To Type", QltyInspectSrcFldConf."To Type"::"Chained table");
        if QltyInspectSrcFldConf.FindSet() then begin
            repeat
                ValueInCurrentVariant := ToTableRecordRef.Field(QltyInspectSrcFldConf."To Field No.").Value();
                FromTableRecordRef.Field(QltyInspectSrcFldConf."From Field No.").SetRange(ValueInCurrentVariant);
            until QltyInspectSrcFldConf.Next() = 0;
            if SingleOnly then
                Found := FromTableRecordRef.FindFirst()
            else
                Found := FromTableRecordRef.FindSet();
        end;
    end;

    /// <summary>
    /// Finds a linked record based on the configured source configuration by traversing from a source table to a target table.
    /// Uses field mappings defined in the source configuration to match records between tables.
    /// This is the inverse operation of FindFromTableLinkedRecordWithToTable.
    /// </summary>
    /// <param name="SingleOnly">If true, finds only the first matching record; if false, finds all matching records</param>
    /// <param name="AllowTrackingMapping">If true, allows finding records via item tracking mappings in addition to chained table mappings</param>
    /// <param name="TempQltyInspectSourceConfig">Temporary source configuration record defining the table relationship and field mappings</param>
    /// <param name="FromRecordRef">Input: RecordRef to the source table record to search from</param>
    /// <param name="ToTableRecordRef">Output: RecordRef to the found target table record(s)</param>
    /// <returns>True if at least one linked record was found; False otherwise</returns>
    internal procedure FindToTableLinkedRecordWithFromTable(SingleOnly: Boolean; AllowTrackingMapping: Boolean; var TempQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config." temporary; var FromRecordRef: RecordRef; var ToTableRecordRef: RecordRef) Found: Boolean
    var
        QltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        ValueInCurrentVariant: Variant;
    begin
        Found := false;
        if TempQltyInspectSourceConfig."From Table No." <> FromRecordRef.Number() then
            Error(SomethingUnexpectedChainErr);

        Clear(ToTableRecordRef);
        ToTableRecordRef.Open(TempQltyInspectSourceConfig."To Table No.");

        QltyInspectSrcFldConf.SetRange(Code, TempQltyInspectSourceConfig.Code);
        if AllowTrackingMapping then
            QltyInspectSrcFldConf.SetFilter("To Type", '%1|%2', QltyInspectSrcFldConf."To Type"::"Chained table", QltyInspectSrcFldConf."To Type"::"Item Tracking")
        else
            QltyInspectSrcFldConf.SetRange("To Type", QltyInspectSrcFldConf."To Type"::"Chained table");
        if QltyInspectSrcFldConf.FindSet() then begin
            repeat
                ValueInCurrentVariant := FromRecordRef.Field(QltyInspectSrcFldConf."From Field No.").Value();
                ToTableRecordRef.Field(QltyInspectSrcFldConf."To Field No.").SetRange(ValueInCurrentVariant);
            until QltyInspectSrcFldConf.Next() = 0;
            if SingleOnly then
                Found := ToTableRecordRef.FindFirst()
            else
                Found := ToTableRecordRef.FindSet();
        end;
    end;

    /// <summary>
    /// Finds all possible target configurations recursively based on a source table number.
    /// This is used when manually creating an inspection to determine which source configurations
    /// are available for the given table.
    /// 
    /// The procedure recursively searches through chained table relationships to find all
    /// paths that lead to Quality Inspection Header records.
    /// </summary>
    /// <param name="InputTable">The source table number to find possible targets for</param>
    /// <param name="TempAvailableQltyInspectSourceConfig">Output: Temporary record containing all available source configurations</param>
    /// <returns>True if at least one possible target configuration was found; False otherwise</returns>
    internal procedure FindPossibleTargetsBasedOnConfigRecursive(InputTable: Integer; var TempAvailableQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config." temporary): Boolean
    begin
        exit(FindPossibleTargetsBasedOnConfigRecursiveWithList(QltyConfigurationHelpers.GetArbitraryMaximumRecursion(), InputTable, TempAvailableQltyInspectSourceConfig));
    end;

    local procedure FindPossibleTargetsBasedOnConfigRecursiveWithList(CurrentRecursionDepth: Integer; InputTable: Integer; var TempAvailableQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config." temporary) Found: Boolean
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
    begin
        CurrentRecursionDepth -= 1;
        if CurrentRecursionDepth <= 0 then
            Error(PleaseReviewSourceTableConfigErr);

        QltyInspectSourceConfig.SetRange(Enabled, true);
        QltyInspectSourceConfig.SetRange("From Table No.", InputTable);
        QltyInspectSourceConfig.SetRange("To Table No.", Database::"Qlty. Inspection Header");
        QltyInspectSourceConfig.SetRange("To Type", QltyInspectSourceConfig."To Type"::Inspection);
        if QltyInspectSourceConfig.FindSet() then
            repeat
                TempAvailableQltyInspectSourceConfig.Reset();
                TempAvailableQltyInspectSourceConfig.SetRange(Code, QltyInspectSourceConfig.Code);
                if TempAvailableQltyInspectSourceConfig.IsEmpty() then begin
                    TempAvailableQltyInspectSourceConfig.Reset();
                    TempAvailableQltyInspectSourceConfig.Init();
                    TempAvailableQltyInspectSourceConfig := QltyInspectSourceConfig;
                    Found := Found or TempAvailableQltyInspectSourceConfig.Insert(false);
                end;
            until QltyInspectSourceConfig.Next() = 0;

        QltyInspectSourceConfig.Reset();
        QltyInspectSourceConfig.SetRange(Enabled, true);
        QltyInspectSourceConfig.SetRange("To Table No.", InputTable);
        QltyInspectSourceConfig.SetRange("To Type", QltyInspectSourceConfig."To Type"::"Chained table");
        if QltyInspectSourceConfig.FindSet() then
            repeat
                TempAvailableQltyInspectSourceConfig.Reset();
                TempAvailableQltyInspectSourceConfig.SetRange(Code, QltyInspectSourceConfig.Code);
                if TempAvailableQltyInspectSourceConfig.IsEmpty() then begin
                    TempAvailableQltyInspectSourceConfig.Reset();
                    TempAvailableQltyInspectSourceConfig.Init();
                    TempAvailableQltyInspectSourceConfig := QltyInspectSourceConfig;
                    Found := Found or TempAvailableQltyInspectSourceConfig.Insert(false);
                    Found := Found or FindPossibleTargetsBasedOnConfigRecursiveWithList(CurrentRecursionDepth, QltyInspectSourceConfig."From Table No.", TempAvailableQltyInspectSourceConfig);
                end;
            until QltyInspectSourceConfig.Next() = 0;

        QltyInspectSourceConfig.Reset();
        QltyInspectSourceConfig.SetRange(Enabled, true);
        QltyInspectSourceConfig.SetRange("From Table No.", InputTable);
        QltyInspectSourceConfig.SetRange("To Type", QltyInspectSourceConfig."To Type"::"Chained table");
        if QltyInspectSourceConfig.FindSet() then
            repeat
                TempAvailableQltyInspectSourceConfig.Reset();
                TempAvailableQltyInspectSourceConfig.SetRange(Code, QltyInspectSourceConfig.Code);
                if TempAvailableQltyInspectSourceConfig.IsEmpty() then begin
                    TempAvailableQltyInspectSourceConfig.Reset();
                    TempAvailableQltyInspectSourceConfig.Init();
                    TempAvailableQltyInspectSourceConfig := QltyInspectSourceConfig;
                    Found := Found or TempAvailableQltyInspectSourceConfig.Insert(false);
                    Found := Found or FindPossibleTargetsBasedOnConfigRecursiveWithList(CurrentRecursionDepth, QltyInspectSourceConfig."To Table No.", TempAvailableQltyInspectSourceConfig);
                end;
            until QltyInspectSourceConfig.Next() = 0;
    end;

    /// <summary>
    /// Populates source fields in the Quality Inspection Header record based on the target record.
    /// Uses source configuration to traverse parent records if necessary to populate all required fields.
    /// 
    /// This procedure is essential for automatically filling in inspection header fields (like Source Item No.,
    /// Source Document No., etc.) from the originating document or record.
    /// </summary>
    /// <param name="TargetRecordRef">The main target record that the inspection will be created against (e.g., Purchase Line, Sales Line)</param>
    /// <param name="QltyInspectionHeader">The Quality Inspection Header to populate with source field values</param>
    /// <param name="RaiseErrorIfNoConfigIsFound">If true, raises an error when no source configuration exists; if false, returns silently</param>
    /// <param name="ForceSetValues">If true, overwrites existing field values; if false, only sets empty fields</param>
    /// <returns>True if source fields could be applied; False otherwise</returns>
    internal procedure ApplySourceFields(var TargetRecordRef: RecordRef; var QltyInspectionHeader: Record "Qlty. Inspection Header"; RaiseErrorIfNoConfigIsFound: Boolean; ForceSetValues: Boolean) CouldApply: Boolean
    var
        TempAvailableQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config." temporary;
        TemporaryInspectionMatchRecordRef: RecordRef;
    begin
        CouldApply := FindPossibleTargetsBasedOnConfigRecursive(TargetRecordRef.Number(), TempAvailableQltyInspectSourceConfig);

        if not CouldApply then
            if RaiseErrorIfNoConfigIsFound then
                Error(UnexpectedApplyingSourceFieldsErr, TargetRecordRef.Number())
            else
                exit(false);

        Clear(TemporaryInspectionMatchRecordRef);
        TemporaryInspectionMatchRecordRef.open(TargetRecordRef.Number(), true);
        TemporaryInspectionMatchRecordRef.Copy(TargetRecordRef, false);
        if TemporaryInspectionMatchRecordRef.Insert(false) then;
        QltyInspectionHeader.SetIsCreating(true);
        CouldApply := ApplySourceRecursive(
            QltyConfigurationHelpers.GetArbitraryMaximumRecursion(),
            TemporaryInspectionMatchRecordRef,
            TempAvailableQltyInspectSourceConfig,
            QltyInspectionHeader,
            ForceSetValues);
        QltyInspectionHeader.SetIsCreating(false);
    end;

    /// <summary>
    /// Recursively applies source fields from parent records to the Quality Inspection Header.
    /// Traverses the configured chain of table relationships to populate all relevant source fields.
    /// 
    /// This is the internal recursive implementation that walks up the chain of parent records,
    /// applying field mappings at each level until all source fields are populated.
    /// </summary>
    /// <param name="CurrentRecursionDepth">Maximum recursion depth to prevent infinite loops (decremented with each call)</param>
    /// <param name="TargetRecordRef">Current record in the traversal chain</param>
    /// <param name="TempAvailableQltyInspectSourceConfig">Available source configurations for the current traversal level</param>
    /// <param name="QltyInspectionHeader">The Quality Inspection Header being populated</param>
    /// <param name="ForceSetValues">If true, overwrites existing field values; if false, only sets empty fields</param>
    /// <returns>True if source fields could be applied at this level or any parent level; False otherwise</returns>
    local procedure ApplySourceRecursive(CurrentRecursionDepth: Integer; var TargetRecordRef: RecordRef; var TempAvailableQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config." temporary; var QltyInspectionHeader: Record "Qlty. Inspection Header"; ForceSetValues: Boolean) CouldApply: Boolean
    var
        LinkedQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        LinkedRecordRef: RecordRef;
    begin
        CurrentRecursionDepth -= 1;
        if CurrentRecursionDepth <= 0 then
            Error(PleaseReviewSourceTableConfigErr);

        TempAvailableQltyInspectSourceConfig.Reset();
        TempAvailableQltyInspectSourceConfig.SetRange("From Table No.", TargetRecordRef.Number());
        if TempAvailableQltyInspectSourceConfig.FindSet() then
            repeat
                TargetRecordRef.SetRecFilter();

                TargetRecordRef.FilterGroup(20);
                TargetRecordRef.SetView('');
                TargetRecordRef.FilterGroup(0);
                if TempAvailableQltyInspectSourceConfig."From Table Filter" <> '' then begin
                    TargetRecordRef.FilterGroup(20);
                    TargetRecordRef.SetView(TempAvailableQltyInspectSourceConfig."From Table Filter");
                    TargetRecordRef.FilterGroup(0);
                end;
                if TargetRecordRef.FindFirst() then
                    CouldApply := CouldApply or ApplySourceFieldsFrom(TargetRecordRef, TempAvailableQltyInspectSourceConfig, QltyInspectionHeader, ForceSetValues);

                TargetRecordRef.FilterGroup(20);
                TargetRecordRef.SetView('');
                TargetRecordRef.FilterGroup(0);
            until TempAvailableQltyInspectSourceConfig.Next() = 0;

        LinkedQltyInspectSourceConfig.Reset();
        LinkedQltyInspectSourceConfig.SetRange(Enabled, true);
        LinkedQltyInspectSourceConfig.SetRange("To Table No.", TargetRecordRef.Number());
        LinkedQltyInspectSourceConfig.SetRange("To Type", LinkedQltyInspectSourceConfig."To Type"::"Chained table");
        if LinkedQltyInspectSourceConfig.FindSet() then
            repeat
                if FindFromTableLinkedRecordWithToTable(true, false, LinkedQltyInspectSourceConfig, TargetRecordRef, LinkedRecordRef) then
                    CouldApply := CouldApply or
                        ApplySourceRecursive(
                            CurrentRecursionDepth,
                            LinkedRecordRef,
                            LinkedQltyInspectSourceConfig,
                            QltyInspectionHeader,
                            ForceSetValues)
            until LinkedQltyInspectSourceConfig.Next() = 0;
    end;

    /// <summary>
    /// Sets source fields in the Quality Inspection Header from a specific source record.
    /// Applies field-level mappings defined in the source configuration to copy values from the
    /// source record to corresponding inspection header fields.
    /// 
    /// This is called for each parent record in the chain to populate relevant fields.
    /// Handles field priority settings to determine whether to overwrite existing values.
    /// </summary>
    /// <param name="FromRecordRef">The source record to copy field values from</param>
    /// <param name="TempQltyInspectSourceConfig">The source configuration defining field mappings</param>
    /// <param name="QltyInspectionHeader">The Quality Inspection Header to populate</param>
    /// <param name="ForceSetValues">If true, overwrites existing field values; if false, respects priority settings</param>
    /// <returns>True if at least one source field was successfully applied; False otherwise</returns>
    local procedure ApplySourceFieldsFrom(var FromRecordRef: RecordRef; var TempQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config." temporary; var QltyInspectionHeader: Record "Qlty. Inspection Header"; ForceSetValues: Boolean) CouldApply: Boolean
    var
        QltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        RecordRef: RecordRef;
        FromFieldRef: FieldRef;
        ToFieldRef: FieldRef;
        OldVariantValue: Variant;
        FromVariantValue: Variant;
        OldFieldWasSet: Boolean;
        NewValueWasSet: Boolean;
        BigInteger: BigInteger;
        CurrentDecimal: Decimal;
        MaxTextLength: Integer;
        TempValueToSetAsText: Text;
    begin
        QltyInspectSrcFldConf.SetRange(Code, TempQltyInspectSourceConfig.Code);
        QltyInspectSrcFldConf.SetRange("To Type", QltyInspectSrcFldConf."To Type"::Inspection);
        QltyInspectSrcFldConf.SetFilter("To Field No.", '<>0');
        QltyInspectSrcFldConf.SetFilter("From Field No.", '<>0');
        QltyInspectSrcFldConf.SetLoadFields("From Field No.", "To Field No.", "Priority Test");
        if QltyInspectSrcFldConf.FindSet() then begin
            RecordRef.GetTable(QltyInspectionHeader);
            repeat
                FromFieldRef := FromRecordRef.Field(QltyInspectSrcFldConf."From Field No.");
                if FromFieldRef.Class = FromFieldRef.Class::FlowField then
                    FromFieldRef.CalcField();
                FromVariantValue := FromFieldRef.Value();
                ToFieldRef := RecordRef.Field(QltyInspectSrcFldConf."To Field No.");
                if ToFieldRef.Class = ToFieldRef.Class::FlowField then
                    ToFieldRef.CalcField();

                OldVariantValue := ToFieldRef.Value();

                OldFieldWasSet := false;
                case ToFieldRef.Type of
                    FieldType::Integer, FieldType::BigInteger, FieldType::Duration:
                        if Evaluate(BigInteger, Format(OldVariantValue)) then
                            OldFieldWasSet := BigInteger <> 0;
                    FieldType::Decimal:
                        if Evaluate(CurrentDecimal, Format(OldVariantValue)) then
                            OldFieldWasSet := CurrentDecimal <> 0;
                    else
                        OldFieldWasSet := Format(OldVariantValue) <> '';
                end;
                NewValueWasSet := false;

                case FromFieldRef.Type of
                    FieldType::Integer, FieldType::BigInteger, FieldType::Duration:
                        if Evaluate(BigInteger, Format(FromVariantValue)) then
                            NewValueWasSet := BigInteger <> 0;
                    FieldType::Decimal:
                        if Evaluate(CurrentDecimal, Format(FromVariantValue)) then
                            NewValueWasSet := CurrentDecimal <> 0;
                    else
                        NewValueWasSet := Format(FromVariantValue) <> '';
                end;

                if NewValueWasSet and (ForceSetValues or (not OldFieldWasSet) or (QltyInspectSrcFldConf."Priority Test" = QltyInspectSrcFldConf."Priority Test"::Priority)) then begin
                    MaxTextLength := 0;
                    if FromFieldRef.Type in [FieldType::Text, FieldType::Code] then
                        MaxTextLength := ToFieldRef.Length;

                    if MaxTextLength <= 0 then
                        ToFieldRef.Validate(FromVariantValue)
                    else begin
                        TempValueToSetAsText := Format(FromVariantValue);
                        if StrLen(TempValueToSetAsText) > 1 then
                            ToFieldRef.Validate(CopyStr(TempValueToSetAsText, 1, MaxTextLength))
                        else
                            ToFieldRef.Validate(FromVariantValue);
                    end;
                end;
                CouldApply := true;
            until QltyInspectSrcFldConf.Next() = 0;
            RecordRef.SetTable(QltyInspectionHeader);
        end;
    end;

    /// <summary>
    /// Retrieves the dynamic caption text for a control based on source configuration field mappings.
    /// Used to display field captions from source documents (e.g., "Item No." vs "Product Code") 
    /// in the inspection header UI. Caches results for performance.
    /// </summary>
    /// <param name="InputQltyInspectionHeader">The inspection header whose source configuration determines the caption</param>
    /// <param name="Input">The field name or caption to resolve</param>
    /// <returns>The resolved caption text to display for the control, or empty string if not found</returns>
    internal procedure GetControlCaptionClass(InputQltyInspectionHeader: Record "Qlty. Inspection Header"; Input: Text) ResultText: Text
    var
        SourceKey: Text;
    begin
        SourceKey := GetSourceKey(InputQltyInspectionHeader, Input);
        if ControlInfoToCaptionClass.ContainsKey(SourceKey) then begin
            if ControlInfoToCaptionClass.Get(SourceKey, ResultText) then;

            if ResultText = '' then
                ResultText := GetSourceFieldInfo(InputQltyInspectionHeader, Database::"Qlty. Inspection Header", Input, SourceKey);
        end;
    end;

    /// <summary>
    /// Determines whether a control should be visible based on source configuration.
    /// Controls are visible only if there's a valid field mapping from the source document.
    /// Caches visibility state for performance.
    /// </summary>
    /// <param name="InputQltyInspectionHeader">The inspection header whose source configuration determines visibility</param>
    /// <param name="Input">The field name or caption to check visibility for</param>
    /// <returns>True if the control should be visible; False otherwise</returns>
    internal procedure GetControlVisibleState(InputQltyInspectionHeader: Record "Qlty. Inspection Header"; Input: Text) Visible: Boolean;
    var
        CurrentKey: Text;
    begin
        CurrentKey := GetSourceKey(InputQltyInspectionHeader, Input);

        if not ControlInfoToVisibility.ContainsKey(CurrentKey) then
            DetermineControlInformation(InputQltyInspectionHeader, Input);

        if ControlInfoToVisibility.ContainsKey(CurrentKey) then
            if ControlInfoToVisibility.Get(CurrentKey, Visible) then;
    end;

    local procedure GetSourceKey(InputQltyInspectionHeader: Record "Qlty. Inspection Header"; Input: Text): Text
    begin
        exit(Format(InputQltyInspectionHeader.RecordId()) + Format(InputQltyInspectionHeader."Source RecordId") + Input);
    end;

    /// <summary>
    /// Clears cached control information and forces re-evaluation of caption and visibility.
    /// Call this when source configuration or inspection header source records change to ensure
    /// controls display current information. Removes stale cache entries and triggers refresh.
    /// </summary>
    /// <param name="InputQltyInspectionHeader">The inspection header whose control information needs refresh</param>
    /// <param name="Input">The field name or caption to refresh</param>
    internal procedure DetermineControlInformation(InputQltyInspectionHeader: Record "Qlty. Inspection Header"; Input: Text)
    var
        CurrentKey: Text;
    begin
        CurrentKey := GetSourceKey(InputQltyInspectionHeader, Input);

        if ControlInfoToCaptionClass.ContainsKey(CurrentKey) then
            if ControlInfoToCaptionClass.Remove(CurrentKey) then;
        if ControlInfoToVisibility.ContainsKey(CurrentKey) then
            if ControlInfoToVisibility.Remove(CurrentKey) then;

        GetSourceFieldInfo(InputQltyInspectionHeader, Database::"Qlty. Inspection Header", Input, CurrentKey);
    end;

    local procedure GetSourceFieldInfo(InputQltyInspectionHeader: Record "Qlty. Inspection Header"; InputTable: Integer; Input: Text; CacheKey: Text) ResultText: Text
    var
        SourceField: Record Field;
        TestText: Text;
        BackupFieldCaption: Text;
        OFFromTableIds: List of [Integer];
        FromTableIterator: Integer;
        ListOfConsideredSourceRecords: List of [Text];
    begin
        ResultText := Input;
        ControlInfoToVisibility.Set(CacheKey, false);

        SourceField.SetRange(TableNo, InputTable);
        SourceField.SetRange(FieldName, Input);
        if not SourceField.FindFirst() then begin
            SourceField.SetRange("Field Caption", Input);
            if not SourceField.FindFirst() then
                exit;
        end;

        if InputQltyInspectionHeader."Source RecordId".TableNo() > 0 then
            OFFromTableIds.Add(InputQltyInspectionHeader."Source RecordId".TableNo());

        if InputQltyInspectionHeader."Source RecordId 2".TableNo() > 0 then
            OFFromTableIds.Add(InputQltyInspectionHeader."Source RecordId 2".TableNo());

        if InputQltyInspectionHeader."Source RecordId 3".TableNo() > 0 then
            OFFromTableIds.Add(InputQltyInspectionHeader."Source RecordId 3".TableNo());

        if InputQltyInspectionHeader."Source RecordId 4".TableNo() > 0 then
            OFFromTableIds.Add(InputQltyInspectionHeader."Source RecordId 4".TableNo());

        foreach FromTableIterator in OFFromTableIds do begin
            TestText := GetSourceFieldInfoFromChain(ListOfConsideredSourceRecords, QltyConfigurationHelpers.GetArbitraryMaximumRecursion(), FromTableIterator, InputTable, SourceField."No.", BackupFieldCaption);
            if TestText <> '' then
                break;
        end;

        if TestText.Trim() = '' then
            TestText := BackupFieldCaption;

        if TestText.Trim() <> '' then begin
            ControlInfoToVisibility.Set(CacheKey, true);
            ControlInfoToCaptionClass.Set(CacheKey, TestText);
            ResultText := TestText;
        end;
    end;

    local procedure GetSourceFieldInfoFromChain(var ListOfConsideredSourceRecords: List of [Text]; Recursion: Integer; FromTable: Integer; ToTable: Integer; TestFieldNo: Integer; var BackupFieldCaption: Text) ResultText: Text
    var
        CurrentField: Record Field;
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        QltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        ChainedQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        Test: Text;
    begin
        Recursion -= 1;
        if Recursion <= 0 then
            Error(ConfigurationNestingOrCircularErr);

        QltyInspectSourceConfig.SetRange(Enabled, true);
        QltyInspectSourceConfig.SetRange("From Table No.", FromTable);
        QltyInspectSourceConfig.SetRange("To Table No.", ToTable);
        if not QltyInspectSourceConfig.FindSet() then
            exit;

        repeat
            if not ListOfConsideredSourceRecords.Contains(QltyInspectSourceConfig.Code) then begin
                ListOfConsideredSourceRecords.Add(QltyInspectSourceConfig.Code);
                QltyInspectSrcFldConf.SetRange(Code, QltyInspectSourceConfig.Code);
                QltyInspectSrcFldConf.SetRange("To Table No.", ToTable);
                QltyInspectSrcFldConf.SetRange("To Field No.", TestFieldNo);
                QltyInspectSrcFldConf.SetRange("To Type", QltyInspectSrcFldConf."To Type"::Inspection);
                if QltyInspectSrcFldConf.FindFirst() then begin
                    if QltyInspectSrcFldConf."Display As" <> '' then
                        ResultText := QltyInspectSrcFldConf."Display As"
                    else begin
                        CurrentField.Reset();
                        CurrentField.SetRange(TableNo, QltyInspectSrcFldConf."From Table No.");
                        CurrentField.SetRange("No.", QltyInspectSrcFldConf."From Field No.");
                        if CurrentField.FindFirst() then
                            BackupFieldCaption := CurrentField."Field Caption";
                    end;
                    if ResultText <> '' then
                        exit;
                end;
            end;

            ChainedQltyInspectSourceConfig.Reset();
            ChainedQltyInspectSourceConfig.SetRange(Enabled, true);
            ChainedQltyInspectSourceConfig.SetRange("To Table No.", ToTable);
            ChainedQltyInspectSourceConfig.SetRange("To Type", ChainedQltyInspectSourceConfig."To Type"::"Chained table");
            if ChainedQltyInspectSourceConfig.FindSet() then
                repeat
                    if not ListOfConsideredSourceRecords.Contains(ChainedQltyInspectSourceConfig.Code) then begin
                        QltyInspectSrcFldConf.Reset();
                        QltyInspectSrcFldConf.SetRange(Code, QltyInspectSrcFldConf.Code);
                        QltyInspectSrcFldConf.SetRange("To Table No.", ToTable);
                        QltyInspectSrcFldConf.SetRange("To Field No.", TestFieldNo);
                        QltyInspectSrcFldConf.SetRange("To Type", QltyInspectSrcFldConf."To Type"::Inspection);
                        Test := GetSourceFieldInfoFromChain(
                            ListOfConsideredSourceRecords,
                            Recursion,
                            ChainedQltyInspectSourceConfig."From Table No.",
                            ChainedQltyInspectSourceConfig."To Table No.",
                            TestFieldNo,
                            BackupFieldCaption);
                        if Test <> '' then
                            ResultText := Test;
                    end;
                until (ChainedQltyInspectSourceConfig.Next() = 0) or (ResultText <> '');

            if ResultText <> '' then
                exit;

            ChainedQltyInspectSourceConfig.Reset();
            ChainedQltyInspectSourceConfig.SetRange(Enabled, true);
            ChainedQltyInspectSourceConfig.SetRange("To Table No.", FromTable);
            ChainedQltyInspectSourceConfig.SetRange("To Type", ChainedQltyInspectSourceConfig."To Type"::"Chained table");
            if ChainedQltyInspectSourceConfig.FindSet() then
                repeat
                    if not ListOfConsideredSourceRecords.Contains(ChainedQltyInspectSourceConfig.Code) then begin
                        QltyInspectSrcFldConf.Reset();
                        QltyInspectSrcFldConf.SetRange(Code, QltyInspectSrcFldConf.Code);
                        QltyInspectSrcFldConf.SetRange("To Table No.", FromTable);
                        QltyInspectSrcFldConf.SetRange("To Field No.", TestFieldNo);
                        QltyInspectSrcFldConf.SetRange("To Type", QltyInspectSrcFldConf."To Type"::Inspection);
                        Test := GetSourceFieldInfoFromChain(
                            ListOfConsideredSourceRecords,
                            Recursion,
                            ChainedQltyInspectSourceConfig."From Table No.",
                            ChainedQltyInspectSourceConfig."To Table No.",
                            TestFieldNo,
                            BackupFieldCaption);
                        if Test <> '' then
                            ResultText := Test;
                    end;
                until (ChainedQltyInspectSourceConfig.Next() = 0) or (ResultText <> '')
        until QltyInspectSourceConfig.Next() = 0;
    end;

    /// <summary>
    /// Finds the single parent record for a given child record using source configuration relationships.
    /// Accepts flexible input types (Record, RecordId, or RecordRef) and resolves to the parent record
    /// following the configured "To Table" chain. Useful for navigating upward from detail records
    /// to header records (e.g., from Purchase Line to Purchase Header).
    /// </summary>
    /// <param name="ChildRecordVariant">The child record as a Record, RecordId, or RecordRef</param>
    /// <param name="FoundParentRecordRef">Output: The resolved parent RecordRef if found</param>
    /// <returns>True if a single parent record was found; False otherwise</returns>
    internal procedure FindSingleParentRecordWithVariant(ChildRecordVariant: Variant; var FoundParentRecordRef: RecordRef): Boolean;
    var
        ChildRecordRef: RecordRef;
    begin
        if not QltyMiscHelpers.GetRecordRefFromVariant(ChildRecordVariant, ChildRecordRef) then
            exit(false);

        exit(FindSingleParentRecord(ChildRecordRef, FoundParentRecordRef));
    end;

    /// <summary>
    /// Finds the single parent record for a given child record using source configuration relationships.
    /// Searches both "From Table" and "To Table" configurations to locate the parent record.
    /// Uses configured filters and field relationships to navigate the record hierarchy.
    /// 
    /// Common use cases:
    /// - Navigate from Purchase Line to Purchase Header
    /// - Navigate from Sales Line to Sales Header
    /// - Navigate from Production Order Component to Production Order
    /// </summary>
    /// <param name="InFromThisRecordRef">The child RecordRef to find the parent for</param>
    /// <param name="FoundParentRecordRef">Output: The resolved parent RecordRef if found</param>
    /// <returns>True if a single parent record was found; False otherwise</returns>
    internal procedure FindSingleParentRecord(var InFromThisRecordRef: RecordRef; var FoundParentRecordRef: RecordRef) Worked: Boolean;
    var
        FromQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        ToQltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        PreviousView: Text;
    begin
        PreviousView := InFromThisRecordRef.GetView();

        FromQltyInspectSourceConfig.SetRange("From Table No.", InFromThisRecordRef.Number());
        FromQltyInspectSourceConfig.SetFilter("To Type", '<>%1', FromQltyInspectSourceConfig."To Type"::Inspection);
        if FromQltyInspectSourceConfig.FindSet() then
            repeat
                InFromThisRecordRef.SetRecFilter();
                InFromThisRecordRef.FilterGroup(20);
                InFromThisRecordRef.SetView('');
                InFromThisRecordRef.FilterGroup(0);
                if FromQltyInspectSourceConfig."From Table Filter" <> '' then begin
                    InFromThisRecordRef.FilterGroup(20);
                    InFromThisRecordRef.SetView(FromQltyInspectSourceConfig."From Table Filter");
                    InFromThisRecordRef.FilterGroup(0);
                end;
                if InFromThisRecordRef.FindFirst() then
                    Worked := FindToTableLinkedRecordWithFromTable(
                        true,
                        true,
                        FromQltyInspectSourceConfig,
                        InFromThisRecordRef,
                        FoundParentRecordRef);
            until (FromQltyInspectSourceConfig.Next() = 0) or Worked;

        if not Worked then begin
            ToQltyInspectSourceConfig.Reset();
            ToQltyInspectSourceConfig.SetRange("To Table No.", InFromThisRecordRef.Number());
            if ToQltyInspectSourceConfig.FindSet() then
                repeat
                    Worked := FindFromTableLinkedRecordWithToTable(
                        true,
                        true,
                        ToQltyInspectSourceConfig,
                        InFromThisRecordRef,
                        FoundParentRecordRef);
                until (ToQltyInspectSourceConfig.Next() = 0) or Worked;
        end;
        InFromThisRecordRef.SetView(PreviousView);
    end;

    /// <summary>
    /// Searches for a related Item record by sequentially checking supplied record variants.
    /// This is an overload that accepts 4 optional variants and internally calls the 5-variant version.
    /// Uses early-exit pattern for improved readability and performance.
    /// 
    /// This procedure enables finding the Item regardless of which source record type is provided.
    /// 
    /// Search order:
    /// 1. TargetRecordRef - Primary record to search from → exit immediately if found
    /// 2. Optional2Variant - Second record to check → exit immediately if found
    /// 3. Optional3Variant - Third record to check → exit immediately if found
    /// 4. Optional4Variant - Fourth record to check → exit immediately if found
    /// 5. Parent of TargetRecordRef - If all else fails, find parent and search there
    /// 
    /// </summary>
    /// <param name="Item">Output parameter that will contain the found Item record with all fields populated</param>
    /// <param name="TargetRecordRef">Primary record reference to search from (e.g., Purchase Line, Sales Line)</param>
    /// <param name="Optional2Variant">Second optional variant to search (e.g., Purchase Header)</param>
    /// <param name="Optional3Variant">Third optional variant to search (optional)</param>
    /// <param name="Optional4Variant">Fourth optional variant to search (optional)</param>
    /// <returns>True if an Item was found in any of the provided variants or their parent; False otherwise</returns>
    internal procedure FindRelatedItem(var Item: Record Item; TargetRecordRef: RecordRef; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant): Boolean
    var
        DummyVariant: Variant;
    begin
        exit(FindRelatedItem(Item, TargetRecordRef, Optional2Variant, Optional3Variant, Optional4Variant, DummyVariant));
    end;

    /// <summary>
    /// Searches for a related Item record by sequentially checking supplied record variants.
    /// Uses early-exit pattern for improved readability and performance.
    /// 
    /// This procedure uses a custom search algorithm specific to Item lookups:
    /// - Items can be found through "Source Item No." field in Quality Inspections
    /// - Items have complex relationships through multiple document types
    /// - Direct Item records need immediate return without further lookup
    /// 
    /// Search sequence:
    /// 1. Check TargetRecordRef via FindRelatedItemIn → exit immediately if found
    /// 2. Check Optional2Variant via FindRelatedItemIn → exit immediately if found
    /// 3. Check Optional3Variant via FindRelatedItemIn → exit immediately if found
    /// 4. Check Optional4Variant via FindRelatedItemIn → exit immediately if found
    /// 5. Check Optional5Variant via FindRelatedItemIn → exit immediately if found
    /// 6. Find parent of TargetRecordRef and search parent → return result
    /// 
    /// Common usage examples:
    /// - Finding Item from Purchase Order Line (contains "No." field with Item number)
    /// - Finding Item from Production Order (contains "Source No." with Item number)
    /// - Finding Item from Sales Order Line (contains "No." field with Item number)
    /// - Finding Item from Transfer Line (contains "Item No." field)
    /// </summary>
    /// <param name="Item">Output parameter that will contain the found Item record with all fields populated</param>
    /// <param name="TargetRecordRef">Primary record reference to search from (e.g., line-level document)</param>
    /// <param name="Optional2Variant">Second optional variant to search (can be Record, RecordRef, or RecordId)</param>
    /// <param name="Optional3Variant">Third optional variant to search (optional)</param>
    /// <param name="Optional4Variant">Fourth optional variant to search (optional)</param>
    /// <param name="Optional5Variant">Fifth optional variant to search (optional)</param>
    /// <returns>True if an Item was found in any of the provided variants or their parent; False otherwise</returns>
    internal procedure FindRelatedItem(var Item: Record Item; TargetRecordRef: RecordRef; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant; Optional5Variant: Variant): Boolean
    var
        ParentRecordRef: RecordRef;
    begin
        case true of
            FindRelatedItemIn(Item, TargetRecordRef),
            FindRelatedItemIn(Item, Optional2Variant),
            FindRelatedItemIn(Item, Optional3Variant),
            FindRelatedItemIn(Item, Optional4Variant),
            FindRelatedItemIn(Item, Optional5Variant):
                exit(true);
        end;

        // Try to find parent record and search in it
        if not FindSingleParentRecord(TargetRecordRef, ParentRecordRef) then
            exit(false);

        exit(FindRelatedItemIn(Item, ParentRecordRef));
    end;

    /// <summary>
    /// Searches for a related Item record within a specific record variant using source field configuration.
    /// Handles direct Item records and indirect lookups through "Source Item No." field mappings.
    /// 
    /// This is the core lookup implementation used by the FindRelatedItem overloads.
    /// 
    /// Lookup strategy:
    /// 1. If CurrentVariant is an Item record → return it directly
    /// 2. Search Quality Inspection Source Field Configuration for mappings to "Source Item No."
    /// 3. For each enabled mapping, read the source field value and attempt Item.SetRange()
    /// 4. Return first successfully found Item
    /// 
    /// Common scenarios:
    /// - Purchase Line with "No." field → Item lookup
    /// - Production Order with "Source No." field → Item lookup
    /// - Transfer Line with "Item No." field → Item lookup
    /// </summary>
    /// <param name="Item">Output: The found Item record with all fields populated</param>
    /// <param name="CurrentVariant">The record variant to search (Record, RecordRef, or RecordId)</param>
    /// <returns>True if an Item was found and loaded into Item; False otherwise</returns>
    internal procedure FindRelatedItemIn(var Item: Record Item; CurrentVariant: Variant): Boolean
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        QltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        TempQltyInspectionHeader: Record "Qlty. Inspection Header" temporary;
        RecordRef: RecordRef;
        FromFieldReference: FieldRef;
        PossibleItemNo: Text;
    begin
        if not QltyMiscHelpers.GetRecordRefFromVariant(CurrentVariant, RecordRef) then
            exit(false);

        // Try direct record match first
        if RecordRef.Number() = Database::Item then begin
            RecordRef.SetTable(Item);
            exit(Item.Get(Item."No."));
        end;

        // Search through Quality Inspection configuration
        QltyInspectSrcFldConf.SetRange("From Table No.", RecordRef.Number());
        QltyInspectSrcFldConf.SetRange("To Type", QltyInspectSrcFldConf."To Type"::Inspection);
        QltyInspectSrcFldConf.SetRange("To Table No.", Database::"Qlty. Inspection Header");
        QltyInspectSrcFldConf.SetRange("To Field No.", TempQltyInspectionHeader.FieldNo("Source Item No."));
        if QltyInspectSrcFldConf.FindSet() then
            repeat
                if QltyInspectSourceConfig.Code <> QltyInspectSrcFldConf.Code then
                    if QltyInspectSourceConfig.Get(QltyInspectSrcFldConf.Code) then;

                if QltyInspectSourceConfig.Enabled and (QltyInspectSrcFldConf."From Field No." <> 0) then begin
                    FromFieldReference := RecordRef.Field(QltyInspectSrcFldConf."From Field No.");
                    if FromFieldReference.Class() = FieldClass::FlowField then
                        FromFieldReference.CalcField();
                    PossibleItemNo := Format(FromFieldReference.Value());
                    if PossibleItemNo <> '' then begin
                        Item.FilterGroup(21);
                        Item.SetRange("No.", CopyStr(PossibleItemNo, 1, MaxStrLen(Item."No.")));
                        if Item.FindFirst() then begin
                            Item.SetRange("No.");
                            Item.FilterGroup(0);
                            Item.SetRecFilter();
                            exit(true);
                        end else begin
                            Item.SetRange("No.");
                            Item.FilterGroup(0);
                        end;
                    end;
                end;
            until QltyInspectSrcFldConf.Next() = 0;

        exit(false);
    end;

    /// <summary>
    /// Searches for a related Vendor record by sequentially checking supplied record variants.
    /// Uses early-exit pattern for improved readability and performance.
    /// 
    /// Search sequence:
    /// 1. Check Optional1Variant for Vendor → exit immediately if found
    /// 2. Check Optional2Variant for Vendor → exit immediately if found
    /// 3. Check Optional3Variant for Vendor → exit immediately if found
    /// 4. Check Optional4Variant for Vendor → exit immediately if found
    /// 5. Check Optional5Variant for Vendor → exit immediately if found
    /// 6. Find parent of Optional1Variant and check parent → return result
    /// 
    /// Common usage: Finding Vendor from Purchase Order Line, Purchase Header, or Item
    /// </summary>
    /// <param name="Vendor">Output parameter that will contain the found Vendor record with all fields populated</param>
    /// <param name="Optional1Variant">First variant to search (typically primary record like Purchase Line)</param>
    /// <param name="Optional2Variant">Second variant to search (typically parent like Purchase Header)</param>
    /// <param name="Optional3Variant">Third variant to search (optional)</param>
    /// <param name="Optional4Variant">Fourth variant to search (optional)</param>
    /// <param name="Optional5Variant">Fifth variant to search (optional)</param>
    /// <returns>True if a Vendor was found in any variant or parent; False otherwise</returns>
    internal procedure FindRelatedVendor(var Vendor: Record Vendor; Optional1Variant: Variant; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant; Optional5Variant: Variant): Boolean
    var
        ParentRecordRef: RecordRef;
    begin
        case true of
            FindRelatedVendorIn(Vendor, Optional1Variant),
            FindRelatedVendorIn(Vendor, Optional2Variant),
            FindRelatedVendorIn(Vendor, Optional3Variant),
            FindRelatedVendorIn(Vendor, Optional4Variant),
            FindRelatedVendorIn(Vendor, Optional5Variant):
                exit(true);
        end;

        // Try to find parent record and search in it
        if not FindSingleParentRecordWithVariant(Optional1Variant, ParentRecordRef) then
            exit(false);

        exit(FindRelatedVendorIn(Vendor, ParentRecordRef));
    end;

    /// <summary>
    /// Searches for a related Vendor record within a specific record variant using field relationships.
    /// Handles direct Vendor records and indirect lookups through field mappings to "Source Vendor No."
    /// 
    /// Lookup strategy:
    /// 1. If CurrentVariant is a Vendor record → return it directly
    /// 2. Call FindRelatedRecordByFieldRelation to search for Vendor No. field mappings
    /// 3. If a vendor number is found, attempt Vendor.Get() with that number
    /// 
    /// Common scenarios:
    /// - Purchase Header with "Buy-from Vendor No." → Vendor lookup
    /// - Purchase Line with "Buy-from Vendor No." → Vendor lookup
    /// - Item with "Vendor No." → Vendor lookup
    /// </summary>
    /// <param name="Vendor">Output: The found Vendor record with all fields populated</param>
    /// <param name="CurrentVariant">The record variant to search (Record, RecordRef, or RecordId)</param>
    /// <returns>True if a Vendor was found and loaded into Vendor; False otherwise</returns>
    internal procedure FindRelatedVendorIn(var Vendor: Record Vendor; CurrentVariant: Variant): Boolean
    var
        RecordRef: RecordRef;
        VendorNo: Text;
    begin
        if not QltyMiscHelpers.GetRecordRefFromVariant(CurrentVariant, RecordRef) then
            exit(false);

        // Try direct record match first
        if RecordRef.Number() = Database::Vendor then begin
            RecordRef.SetTable(Vendor);
            exit(Vendor.Get(Vendor."No."));
        end;

        // Search through field relationships
        if FindRelatedRecordByFieldRelation(RecordRef, Database::Vendor, MaxStrLen(Vendor."No."), VendorNo) then
            exit(Vendor.Get(VendorNo));

        exit(false);
    end;

    /// <summary>
    /// Searches for a related Customer record by sequentially checking supplied record variants.
    /// Uses early-exit pattern for improved readability and performance.
    /// 
    /// Search sequence:
    /// 1. Check Optional1Variant for Customer → exit immediately if found
    /// 2. Check Optional2Variant for Customer → exit immediately if found
    /// 3. Check Optional3Variant for Customer → exit immediately if found
    /// 4. Check Optional4Variant for Customer → exit immediately if found
    /// 5. Check Optional5Variant for Customer → exit immediately if found
    /// 6. Find parent of Optional1Variant and check parent → return result
    /// 
    /// Common usage: Finding Customer from Sales Order Line, Sales Header, or Item
    /// </summary>
    /// <param name="Customer">Output parameter that will contain the found Customer record with all fields populated</param>
    /// <param name="Optional1Variant">First variant to search (typically primary record like Sales Line)</param>
    /// <param name="Optional2Variant">Second variant to search (typically parent like Sales Header)</param>
    /// <param name="Optional3Variant">Third variant to search (optional)</param>
    /// <param name="Optional4Variant">Fourth variant to search (optional)</param>
    /// <param name="Optional5Variant">Fifth variant to search (optional)</param>
    /// <returns>True if a Customer was found in any variant or parent; False otherwise</returns>
    internal procedure FindRelatedCustomer(var Customer: Record Customer; Optional1Variant: Variant; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant; Optional5Variant: Variant): Boolean
    var
        ParentRecordRef: RecordRef;
    begin
        case true of
            FindRelatedCustomerIn(Customer, Optional1Variant),
            FindRelatedCustomerIn(Customer, Optional2Variant),
            FindRelatedCustomerIn(Customer, Optional3Variant),
            FindRelatedCustomerIn(Customer, Optional4Variant),
            FindRelatedCustomerIn(Customer, Optional5Variant):
                exit(true);
        end;

        // Try to find parent record and search in it
        if not FindSingleParentRecordWithVariant(Optional1Variant, ParentRecordRef) then
            exit(false);

        exit(FindRelatedCustomerIn(Customer, ParentRecordRef));
    end;

    /// <summary>
    /// Searches for a related Customer record within a specific record variant using field relationships.
    /// Handles direct Customer records and indirect lookups through field mappings to "Source Customer No."
    /// 
    /// Lookup strategy:
    /// 1. If CurrentVariant is a Customer record → return it directly
    /// 2. Call FindRelatedRecordByFieldRelation to search for Customer No. field mappings
    /// 3. If a customer number is found, attempt Customer.Get() with that number
    /// 
    /// Common scenarios:
    /// - Sales Header with "Sell-to Customer No." → Customer lookup
    /// - Sales Line with "Sell-to Customer No." → Customer lookup
    /// - Service Header with "Customer No." → Customer lookup
    /// </summary>
    /// <param name="Customer">Output: The found Customer record with all fields populated</param>
    /// <param name="CurrentVariant">The record variant to search (Record, RecordRef, or RecordId)</param>
    /// <returns>True if a Customer was found and loaded into Customer; False otherwise</returns>
    internal procedure FindRelatedCustomerIn(var Customer: Record Customer; CurrentVariant: Variant): Boolean
    var
        RecordRef: RecordRef;
        CustomerNo: Text;
    begin
        if not QltyMiscHelpers.GetRecordRefFromVariant(CurrentVariant, RecordRef) then
            exit(false);

        // Try direct record match first
        if RecordRef.Number() = Database::Customer then begin
            RecordRef.SetTable(Customer);
            exit(Customer.Get(Customer."No."));
        end;

        // Search through field relationships
        if FindRelatedRecordByFieldRelation(RecordRef, Database::Customer, MaxStrLen(Customer."No."), CustomerNo) then
            exit(Customer.Get(CustomerNo));

        exit(false);
    end;

    /// <summary>
    /// Searches for a related Routing Header record by sequentially checking supplied record variants.
    /// Uses early-exit pattern for improved readability and performance.
    /// 
    /// Search sequence:
    /// 1. Check Optional1Variant for Routing → exit immediately if found
    /// 2. Check Optional2Variant for Routing → exit immediately if found
    /// 3. Check Optional3Variant for Routing → exit immediately if found
    /// 4. Check Optional4Variant for Routing → exit immediately if found
    /// 5. Check Optional5Variant for Routing → exit immediately if found
    /// 6. Find parent of Optional1Variant and check parent → return result
    /// 
    /// Common usage: Finding Routing from Production Order Line, Item, or Routing Line
    /// </summary>
    /// <param name="RoutingHeader">Output parameter that will contain the found Routing Header record with all fields populated</param>
    /// <param name="Optional1Variant">First variant to search (typically primary record like Production Order Line)</param>
    /// <param name="Optional2Variant">Second variant to search (typically parent or related Item)</param>
    /// <param name="Optional3Variant">Third variant to search (optional)</param>
    /// <param name="Optional4Variant">Fourth variant to search (optional)</param>
    /// <param name="Optional5Variant">Fifth variant to search (optional)</param>
    /// <returns>True if a Routing was found in any variant or parent; False otherwise</returns>
    internal procedure FindRelatedRouting(var RoutingHeader: Record "Routing Header"; Optional1Variant: Variant; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant; Optional5Variant: Variant): Boolean
    var
        ParentRecordRef: RecordRef;
    begin
        case true of
            FindRelatedRoutingIn(RoutingHeader, Optional1Variant),
            FindRelatedRoutingIn(RoutingHeader, Optional2Variant),
            FindRelatedRoutingIn(RoutingHeader, Optional3Variant),
            FindRelatedRoutingIn(RoutingHeader, Optional4Variant),
            FindRelatedRoutingIn(RoutingHeader, Optional5Variant):
                exit(true);
        end;

        // Try to find parent record and search in it
        if not FindSingleParentRecordWithVariant(Optional1Variant, ParentRecordRef) then
            exit(false);

        exit(FindRelatedRoutingIn(RoutingHeader, ParentRecordRef));
    end;

    /// <summary>
    /// Searches for a related Routing Header within a specific record variant using field relationships.
    /// Handles direct Routing Header records and indirect lookups through field mappings.
    /// 
    /// Lookup strategy:
    /// 1. If CurrentVariant is a Routing Header record → return it directly
    /// 2. Call FindRelatedRecordByFieldRelation to search for Routing No. field mappings
    /// 3. If a routing number is found, attempt Routing Header.Get() with that number
    /// 
    /// Common scenarios:
    /// - Production Order with "Routing No." → Routing lookup
    /// - Item with "Routing No." → Routing lookup
    /// - Routing Line with "Routing No." → Routing Header lookup
    /// </summary>
    /// <param name="RoutingHeader">Output: The found Routing Header record with all fields populated</param>
    /// <param name="CurrentVariant">The record variant to search (Record, RecordRef, or RecordId)</param>
    /// <returns>True if a Routing Header was found and loaded into RoutingHeader; False otherwise</returns>
    internal procedure FindRelatedRoutingIn(var RoutingHeader: Record "Routing Header"; CurrentVariant: Variant): Boolean
    var
        RecordRef: RecordRef;
        RoutingNo: Text;
    begin
        if not QltyMiscHelpers.GetRecordRefFromVariant(CurrentVariant, RecordRef) then
            exit(false);

        // Try direct record match first
        if RecordRef.Number() = Database::"Routing Header" then begin
            RecordRef.SetTable(RoutingHeader);
            exit(RoutingHeader.Get(RoutingHeader."No."));
        end;

        // Search through field relationships
        if FindRelatedRecordByFieldRelation(RecordRef, Database::"Routing Header", MaxStrLen(RoutingHeader."No."), RoutingNo) then
            exit(RoutingHeader.Get(RoutingNo));

        exit(false);
    end;

    /// <summary>
    /// Searches for a related Production BOM Header record by sequentially checking supplied record variants.
    /// Uses early-exit pattern for improved readability and performance.
    /// 
    /// Search sequence:
    /// 1. Check Optional1Variant for BOM → exit immediately if found
    /// 2. Check Optional2Variant for BOM → exit immediately if found
    /// 3. Check Optional3Variant for BOM → exit immediately if found
    /// 4. Check Optional4Variant for BOM → exit immediately if found
    /// 5. Check Optional5Variant for BOM → exit immediately if found
    /// 6. Find parent of Optional1Variant and check parent → return result
    /// 
    /// Common usage: Finding Production BOM from Production Order Line, Item, or BOM Line
    /// </summary>
    /// <param name="ProductionBOMHeader">Output parameter that will contain the found Production BOM Header record with all fields populated</param>
    /// <param name="Optional1Variant">First variant to search (typically primary record like Production Order Line)</param>
    /// <param name="Optional2Variant">Second variant to search (typically parent or related Item)</param>
    /// <param name="Optional3Variant">Third variant to search (optional)</param>
    /// <param name="Optional4Variant">Fourth variant to search (optional)</param>
    /// <param name="Optional5Variant">Fifth variant to search (optional)</param>
    /// <returns>True if a Production BOM was found in any variant or parent; False otherwise</returns>
    internal procedure FindRelatedBillOfMaterial(var ProductionBOMHeader: Record "Production BOM Header"; Optional1Variant: Variant; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant; Optional5Variant: Variant): Boolean
    var
        ParentRecordRef: RecordRef;
    begin
        case true of
            FindRelatedBillOfMaterialIn(ProductionBOMHeader, Optional1Variant),
            FindRelatedBillOfMaterialIn(ProductionBOMHeader, Optional2Variant),
            FindRelatedBillOfMaterialIn(ProductionBOMHeader, Optional3Variant),
            FindRelatedBillOfMaterialIn(ProductionBOMHeader, Optional4Variant),
            FindRelatedBillOfMaterialIn(ProductionBOMHeader, Optional5Variant):
                exit(true);
        end;

        // Try to find parent record and search in it
        if not FindSingleParentRecordWithVariant(Optional1Variant, ParentRecordRef) then
            exit(false);

        exit(FindRelatedBillOfMaterialIn(ProductionBOMHeader, ParentRecordRef));
    end;

    /// <summary>
    /// Searches for a related Production BOM Header within a specific record variant using field relationships.
    /// Handles direct BOM Header records and indirect lookups through both field mappings and table relations.
    /// 
    /// Lookup strategy (more complex than other FindRelated* procedures):
    /// 1. If CurrentVariant is a Production BOM Header → return it directly
    /// 2. Find all fields in the source table that relate to Production BOM Header
    /// 3. For each related field:
    ///    a. Check if there's an enabled Quality Inspection Source Field Configuration
    ///    b. If configured, read the field value and attempt Production BOM Header.Get()
    ///    c. If not configured but field has table relation, try direct field value lookup
    /// 4. Return first successfully found Production BOM Header
    /// 
    /// Common scenarios:
    /// - Production Order with "Production BOM No." → BOM lookup
    /// - Item with "Production BOM No." → BOM lookup
    /// - Production BOM Line with parent BOM No. → BOM Header lookup
    /// </summary>
    /// <param name="ProductionBOMHeader">Output: The found Production BOM Header record with all fields populated</param>
    /// <param name="CurrentVariant">The record variant to search (Record, RecordRef, or RecordId)</param>
    /// <returns>True if a Production BOM Header was found and loaded into ProductionBOMHeader; False otherwise</returns>
    internal procedure FindRelatedBillOfMaterialIn(var ProductionBOMHeader: Record "Production BOM Header"; CurrentVariant: Variant): Boolean
    var
        CurrentField: Record Field;
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        QltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        RecordRef: RecordRef;
        FromFieldReference: FieldRef;
        PossibleBillOfMaterialNo: Text;
    begin
        if not QltyMiscHelpers.GetRecordRefFromVariant(CurrentVariant, RecordRef) then
            exit(false);

        // Try direct record match first
        if RecordRef.Number() = Database::"Production BOM Header" then begin
            RecordRef.SetTable(ProductionBOMHeader);
            exit(ProductionBOMHeader.Get(ProductionBOMHeader."No."));
        end;

        // Search through field relationships
        CurrentField.SetRange(TableNo, RecordRef.Number());
        CurrentField.SetRange(RelationTableNo, Database::"Production BOM Header");
        if CurrentField.FindSet() then
            repeat
                QltyInspectSrcFldConf.SetRange("From Table No.", RecordRef.Number());
                QltyInspectSrcFldConf.SetRange("To Type", QltyInspectSrcFldConf."To Type"::Inspection);
                QltyInspectSrcFldConf.SetRange("To Table No.", Database::"Qlty. Inspection Header");
                QltyInspectSrcFldConf.SetRange("From Field No.", CurrentField."No.");
                if QltyInspectSrcFldConf.FindSet() then
                    repeat
                        if QltyInspectSourceConfig.Code <> QltyInspectSrcFldConf.Code then
                            if QltyInspectSourceConfig.Get(QltyInspectSrcFldConf.Code) then;

                        if QltyInspectSourceConfig.Enabled then
                            if QltyInspectSrcFldConf."From Field No." <> 0 then begin
                                FromFieldReference := RecordRef.Field(QltyInspectSrcFldConf."From Field No.");
                                if FromFieldReference.Class() = FieldClass::FlowField then
                                    FromFieldReference.CalcField();

                                PossibleBillOfMaterialNo := Format(FromFieldReference.Value());
                                if PossibleBillOfMaterialNo <> '' then
                                    if ProductionBOMHeader.Get(CopyStr(PossibleBillOfMaterialNo, 1, MaxStrLen(ProductionBOMHeader."No."))) then
                                        exit(true);
                            end;

                    until QltyInspectSrcFldConf.Next() = 0
                else begin
                    FromFieldReference := RecordRef.Field(CurrentField."No.");
                    if FromFieldReference.Class() = FieldClass::FlowField then
                        FromFieldReference.CalcField();

                    PossibleBillOfMaterialNo := Format(FromFieldReference.Value());
                    if PossibleBillOfMaterialNo <> '' then
                        if ProductionBOMHeader.Get(CopyStr(PossibleBillOfMaterialNo, 1, MaxStrLen(ProductionBOMHeader."No."))) then
                            exit(true);
                end;
            until CurrentField.Next() = 0;

        exit(false);
    end;

    /// <summary>
    /// Searches for a related Production Order Routing Line by sequentially checking supplied record variants.
    /// Uses an exact table number match strategy through the GetIfAnExactMatch helper procedure.
    /// 
    /// Unlike other FindRelated* procedures that search through field mappings, this procedure
    /// looks for an exact Production Order Routing Line record in the provided variants.
    /// 
    /// Search sequence (through GetIfAnExactMatch):
    /// 1. Check Optional1Variant for exact table match → exit if found
    /// 2. Check Optional2Variant for exact table match → exit if found
    /// 3. Check Optional3Variant for exact table match → exit if found
    /// 4. Check Optional4Variant for exact table match → exit if found
    /// 5. Check Optional5Variant for exact table match → exit if found
    /// 6. Find parent of Optional1Variant and check parent → return result
    /// 
    /// Common usage: Finding routing line from Production Order, Manufacturing process records
    /// </summary>
    /// <param name="ProdOrderRoutingLine">Output: The found Production Order Routing Line record</param>
    /// <param name="Optional1Variant">First variant to check (typically Production Order or related record)</param>
    /// <param name="Optional2Variant">Second variant to check (optional)</param>
    /// <param name="Optional3Variant">Third variant to check (optional)</param>
    /// <param name="Optional4Variant">Fourth variant to check (optional)</param>
    /// <param name="Optional5Variant">Fifth variant to check (optional)</param>
    /// <returns>True if a Production Order Routing Line was found in any variant or parent; False otherwise</returns>
    internal procedure FindRelatedProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; Optional1Variant: Variant; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant; Optional5Variant: Variant): Boolean
    var
        RecordRefToProdOrderRoutingLine: RecordRef;
    begin
        RecordRefToProdOrderRoutingLine.GetTable(ProdOrderRoutingLine);
        if GetIfAnExactMatch(RecordRefToProdOrderRoutingLine, Optional1Variant, Optional2Variant, Optional3Variant, Optional4Variant, Optional5Variant) then begin
            RecordRefToProdOrderRoutingLine.SetTable(ProdOrderRoutingLine);
            exit(true);
        end;
    end;

    /// <summary>
    /// Searches for an exact record match by sequentially checking supplied record variants.
    /// Uses early-exit pattern for improved readability and performance.
    /// 
    /// This is a helper procedure that looks for a record matching the exact table number specified
    /// in FoundRecordRef. The FoundRecordRef parameter must be initialized with the target
    /// table number before calling this procedure.
    /// 
    /// Unlike the FindRelated* procedures which search for specific entity types, this procedure
    /// performs a generic table-number-based match, useful for finding specific record types like
    /// Prod. Order Routing Line that don't fit the standard relationship patterns.
    /// 
    /// Search sequence:
    /// 1. Check Optional1Variant for exact table match → exit immediately if found
    /// 2. Check Optional2Variant for exact table match → exit immediately if found
    /// 3. Check Optional3Variant for exact table match → exit immediately if found
    /// 4. Check Optional4Variant for exact table match → exit immediately if found
    /// 5. Check Optional5Variant for exact table match → exit immediately if found
    /// 6. Find parent of Optional1Variant and check parent → return result
    /// 
    /// Usage: Primarily used by FindRelatedProdOrderRoutingLine to locate routing line records
    /// </summary>
    /// <param name="FoundRecordRef">Input/Output: Must contain the target table number on input; contains the found record on output</param>
    /// <param name="Optional1Variant">First variant to check for exact table match</param>
    /// <param name="Optional2Variant">Second variant to check for exact table match</param>
    /// <param name="Optional3Variant">Third variant to check for exact table match</param>
    /// <param name="Optional4Variant">Fourth variant to check for exact table match</param>
    /// <param name="Optional5Variant">Fifth variant to check for exact table match</param>
    /// <returns>True if an exact table match was found in any variant or parent; False otherwise</returns>
    local procedure GetIfAnExactMatch(var FoundRecordRef: RecordRef; Optional1Variant: Variant; Optional2Variant: Variant; Optional3Variant: Variant; Optional4Variant: Variant; Optional5Variant: Variant): Boolean
    var
        ParentRecordRef: RecordRef;
    begin
        case true of
            GetIfAnExactMatch(FoundRecordRef, Optional1Variant),
            GetIfAnExactMatch(FoundRecordRef, Optional2Variant),
            GetIfAnExactMatch(FoundRecordRef, Optional3Variant),
            GetIfAnExactMatch(FoundRecordRef, Optional4Variant),
            GetIfAnExactMatch(FoundRecordRef, Optional5Variant):
                exit(true);
        end;

        // Try to find parent record and search in it
        if not FindSingleParentRecordWithVariant(Optional1Variant, ParentRecordRef) then
            exit(false);

        exit(GetIfAnExactMatch(FoundRecordRef, ParentRecordRef));
    end;

    /// <summary>
    /// Checks if a specific record variant exactly matches the target table number specified in FoundRecordRef.
    /// This is the single-variant implementation called by the multi-variant overload.
    /// 
    /// Comparison logic:
    /// 1. Convert CurrentVariant to RecordRef
    /// 2. Check if RecordRef table number matches FoundRecordRef table number
    /// 3. If match found, copy RecordRef to FoundRecordRef and set record filter
    /// 4. Attempt to find the record with the filter applied
    /// 
    /// Note: FoundRecordRef must be initialized with the target table number before calling.
    /// This procedure is used internally by GetIfAnExactMatch(5-variant overload) and FindRelatedProdOrderRoutingLine.
    /// </summary>
    /// <param name="FoundRecordRef">Input: Target table number; Output: Found record if match successful</param>
    /// <param name="CurrentVariant">The record variant to check (Record, RecordRef, or RecordId)</param>
    /// <returns>True if CurrentVariant's table number matches FoundRecordRef's table number and record exists; False otherwise</returns>
    local procedure GetIfAnExactMatch(var FoundRecordRef: RecordRef; CurrentVariant: Variant): Boolean
    var
        RecordRef: RecordRef;
    begin
        if not QltyMiscHelpers.GetRecordRefFromVariant(CurrentVariant, RecordRef) then
            exit(false);

        if RecordRef.Number() = FoundRecordRef.Number() then begin
            FoundRecordRef := RecordRef;
            FoundRecordRef.SetRecFilter();
            exit(FoundRecordRef.FindFirst());
        end;
    end;

    /// <summary>
    /// Generic helper to find a related record by searching through field relationships.
    /// This implements the common pattern used by all FindRelated*In procedures.
    /// </summary>
    /// <param name="RecordRef">The source RecordRef to search from</param>
    /// <param name="TargetTableNo">The target table number to find</param>
    /// <param name="MaxFieldLength">Maximum field length for the target record's No. field</param>
    /// <param name="RecordNoAsText">Output parameter containing the found record number</param>
    /// <returns>True if a related record was found</returns>
    local procedure FindRelatedRecordByFieldRelation(RecordRef: RecordRef; TargetTableNo: Integer; MaxFieldLength: Integer; var RecordNoAsText: Text): Boolean
    var
        CurrentField: Record Field;
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
        QltyInspectSrcFldConf: Record "Qlty. Inspect. Src. Fld. Conf.";
        FromFieldReference: FieldRef;
        PossibleRecordNo: Text;
    begin
        CurrentField.SetRange(TableNo, RecordRef.Number());
        CurrentField.SetRange(RelationTableNo, TargetTableNo);
        if CurrentField.FindSet() then
            repeat
                QltyInspectSrcFldConf.SetRange("From Table No.", RecordRef.Number());
                QltyInspectSrcFldConf.SetRange("To Type", QltyInspectSrcFldConf."To Type"::Inspection);
                QltyInspectSrcFldConf.SetRange("To Table No.", Database::"Qlty. Inspection Header");
                QltyInspectSrcFldConf.SetRange("From Field No.", CurrentField."No.");
                if QltyInspectSrcFldConf.FindSet() then
                    repeat
                        if QltyInspectSourceConfig.Code <> QltyInspectSrcFldConf.Code then
                            if QltyInspectSourceConfig.Get(QltyInspectSrcFldConf.Code) then;

                        if QltyInspectSourceConfig.Enabled then
                            if QltyInspectSrcFldConf."From Field No." <> 0 then begin
                                FromFieldReference := RecordRef.Field(QltyInspectSrcFldConf."From Field No.");
                                if FromFieldReference.Class() = FieldClass::FlowField then
                                    FromFieldReference.CalcField();

                                PossibleRecordNo := Format(FromFieldReference.Value());
                                if PossibleRecordNo <> '' then begin
                                    RecordNoAsText := CopyStr(PossibleRecordNo, 1, MaxFieldLength);
                                    exit(true);
                                end;
                            end;
                    until QltyInspectSrcFldConf.Next() = 0;
            until CurrentField.Next() = 0;

        exit(false);
    end;
}

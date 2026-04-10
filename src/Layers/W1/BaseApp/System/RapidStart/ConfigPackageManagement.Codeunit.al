namespace System.IO;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Company;
using System.Environment;
using System.Environment.Configuration;
using System.Reflection;
using System.Telemetry;

codeunit 8611 "Config. Package Management"
{
    TableNo = "Config. Package Record";

    trigger OnRun()
    begin
        Clear(RecordsInsertedCount);
        Clear(RecordsModifiedCount);
        InsertPackageRecord(Rec);
    end;

    var
        TempConfigRecordForProcessing: Record "Config. Record For Processing" temporary;
        TempAppliedConfigPackageRecord: Record "Config. Package Record" temporary;
        TempConfigPackageFieldCache: Record "Config. Package Field" temporary;
        TempConfigPackageFieldOrdered: Record "Config. Package Field" temporary;
        ConfigProgressBar: Codeunit "Config. Progress Bar";
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        ConfigMgt: Codeunit "Config. Management";
        TypeHelper: Codeunit "Type Helper";
        ValidationFieldID: Integer;
        RecordsInsertedCount: Integer;
        RecordsModifiedCount: Integer;
        ApplyMode: Option ,PrimaryKey,NonKeyFields;

        ErrorTypeEnum: Option General,TableRelation;
        HideDialog: Boolean;
#pragma warning disable AA0470
        KeyFieldValueMissingErr: Label 'The value of the key field %1 has not been filled in for record %2 : %3.', Comment = 'Parameter 1 - field name, 2 - table name, 3 - code value. Example: The value of the key field Customer Posting Group has not been filled in for record Customer : XXXXX.';
#pragma warning restore AA0470
        ValidatingTableRelationsMsg: Label 'Validating table relations';
#pragma warning disable AA0470
        RecordsXofYMsg: Label 'Records: %1 of %2', Comment = 'Sample: 5 of 1025. 1025 is total number of records, 5 is a number of the current record ';
#pragma warning restore AA0470
        ApplyingPackageMsg: Label 'Applying package %1', Comment = '%1 = The name of the package being applied.';
        ApplyingTableMsg: Label 'Applying table %1', Comment = '%1 = The name of the table being applied.';
        NoTablesAndErrorsMsg: Label '%1 tables are processed.\%2 errors found.\%3 records inserted.\%4 records modified.', Comment = '%1 = number of tables processed, %2 = number of errors, %3 = number of records inserted, %4 = number of records modified';
        NoTablesMsg: Label '%1 tables are processed.', Comment = '%1 = The number of tables that were processed.';
        UpdatingDimSetsMsg: Label 'Updating dimension sets';
        ProcessingOrderErr: Label 'Cannot set up processing order numbers. A cycle reference exists in the primary keys for table %1.', Comment = '%1 = The name of the table.';
        ReferenceSameTableErr: Label 'Some lines refer to the same table. You cannot assign a table to a package more than one time.';
        BlankTxt: Label '[Blank]';
        DimValueDoesNotExistsErr: Label 'Dimension Value %1 %2 does not exist.', Comment = '%1 = Dimension Code, %2 = Dimension Value Code';
        MSGPPackageCodeTxt: Label 'GB.ENU.CSV';
        QBPackageCodeTxt: Label 'DM.IIF';
        RapidStartTxt: Label 'RapidStart', Locked = true;
        ImportNotAllowedErr: Label 'Cannot import table %1 through a Configuration Package.', Comment = '%1 = The name of the table.';
        RSNotificaitonMsg: Label 'Use configuration packages to import data when setting up new companies. Depending on the amount of data, this can take time and impact system performance for all users.';
        UsingBigRSPackageTxt: Label 'The user is shown a warning for action: %1. reason: %2', Locked = true;
        AcknowledgePerformanceImpactTxt: Label 'The user was informed about the potential of poor perfomance and decided to continue. Process: %1', Locked = true;
        LearnMoreTok: Label 'Learn more';
        ApplyPackageLbl: Label 'Apply Package';
        DisableNotificationLbl: Label 'Don''t show this again';
        PackagageImportedNotificationNameLbl: Label 'Configuration Package Imported';
        PackagageImportedNotificationDescriptionLbl: Label 'Notify user when a configuration package has been imported.';
        PackageImportedNotificationTxt: Label 'Configuration package %1 has been imported, now you need to apply it.', Comment = '%1 - package code';
        RapidStartDocumentationUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2121629';
        ConfigurationPackageApplyDataStartMsg: Label 'Configuration package apply started: %1', Comment = '%1 - package code', Locked = true;
        ConfigurationPackageApplyDataFinishMsg: Label 'Configuration package applied successfully: %1', Locked = true;
        ConfigurationPackageDeletedMsg: Label 'Configuration package deleted successfully: %1', Locked = true;


    procedure InsertPackage(var ConfigPackage: Record "Config. Package"; PackageCode: Code[20]; PackageName: Text[50]; ExcludeConfigTables: Boolean)
    begin
        ConfigPackage.Code := PackageCode;
        ConfigPackage."Package Name" := PackageName;
        ConfigPackage."Exclude Config. Tables" := ExcludeConfigTables;
        ConfigPackage.Insert();
    end;

    procedure InsertPackageTable(var ConfigPackageTable: Record "Config. Package Table"; PackageCode: Code[20]; TableID: Integer)
    begin
        if not ConfigPackageTable.Get(PackageCode, TableID) then begin
            ConfigPackageTable.Init();
            ConfigPackageTable.Validate("Package Code", PackageCode);
            ConfigPackageTable.Validate("Table ID", TableID);
            ConfigPackageTable.Insert(true);
        end;
    end;

    procedure InsertPackageTableWithoutValidation(var ConfigPackageTable: Record "Config. Package Table"; PackageCode: Code[20]; TableID: Integer)
    begin
        if not ConfigPackageTable.Get(PackageCode, TableID) then begin
            ConfigPackageTable.Init();
            ConfigPackageTable."Package Code" := PackageCode;
            ConfigPackageTable."Table ID" := TableID;
            ConfigPackageTable.Insert();
        end;
    end;

    procedure InsertPackageField(var ConfigPackageField: Record "Config. Package Field"; PackageCode: Code[20]; TableID: Integer; FieldID: Integer; FieldName: Text[30]; FieldCaption: Text[250]; SetInclude: Boolean; SetValidate: Boolean; SetLocalize: Boolean; SetDimension: Boolean)
    var
        SkipRelationTableID: Boolean;
    begin
        if not ConfigPackageField.Get(PackageCode, TableID, FieldID) then begin
            ConfigPackageField.Init();
            ConfigPackageField.Validate("Package Code", PackageCode);
            ConfigPackageField.Validate("Table ID", TableID);
            ConfigPackageField.Validate(Dimension, SetDimension);
            OnInsertPackageFieldOnBeforeValidateFieldID(ConfigPackageField);
            ConfigPackageField.Validate("Field ID", FieldID);
            ConfigPackageField.Validate("Field Name", FieldName);
            ConfigPackageField."Field Caption" := FieldCaption;
            ConfigPackageField."Primary Key" := ConfigValidateMgt.IsKeyField(TableID, FieldID);
            ConfigPackageField."Include Field" := SetInclude or ConfigPackageField."Primary Key";
            SkipRelationTableID := not SetDimension;
            OnInsertPackageFieldOnAfterCalcSkipRelationTableID(ConfigPackageField, SkipRelationTableID);
            if SkipRelationTableID then begin
                ConfigPackageField."Relation Table ID" := ConfigValidateMgt.GetRelationTableID(TableID, FieldID);
                ConfigPackageField."Validate Field" :=
                  ConfigPackageField."Include Field" and SetValidate and not ValidateException(TableID, FieldID);
            end;
            ConfigPackageField."Localize Field" := SetLocalize;
            ConfigPackageField.Dimension := SetDimension;
            if SetDimension then
                ConfigPackageField."Processing Order" := ConfigPackageField."Field ID";
            OnInsertPackageFieldOnBeforeInsert(ConfigPackageField);
            ConfigPackageField.Insert();
        end;
    end;

    procedure InsertPackageFilter(var ConfigPackageFilter: Record "Config. Package Filter"; PackageCode: Code[20]; TableID: Integer; ProcessingRuleNo: Integer; FieldID: Integer; FieldFilter: Text[250])
    begin
        if not ConfigPackageFilter.Get(PackageCode, TableID, 0, FieldID) then begin
            ConfigPackageFilter.Init();
            ConfigPackageFilter.Validate("Package Code", PackageCode);
            ConfigPackageFilter.Validate("Table ID", TableID);
            ConfigPackageFilter.Validate("Processing Rule No.", ProcessingRuleNo);
            ConfigPackageFilter.Validate("Field ID", FieldID);
            ConfigPackageFilter.Validate("Field Filter", FieldFilter);
            ConfigPackageFilter.Insert();
        end else
            if ConfigPackageFilter."Field Filter" <> FieldFilter then begin
                ConfigPackageFilter."Field Filter" := FieldFilter;
                ConfigPackageFilter.Modify();
            end;
    end;

    procedure InsertPackageRecord(ConfigPackageRecord: Record "Config. Package Record")
    var
        ConfigPackageTable: Record "Config. Package Table";
        RecRef: RecordRef;
        DelayedInsert: Boolean;
        IsHandled: Boolean;
    begin
        if (ConfigPackageRecord."Package Code" = '') or (ConfigPackageRecord."Table ID" = 0) then
            exit;

        if ConfigMgt.IsSystemTable(ConfigPackageRecord."Table ID") then
            exit;

        RecRef.Open(ConfigPackageRecord."Table ID");

        if not IsImportAllowed(ConfigPackageRecord."Table ID") then
            Error(ImportNotAllowedErr, RecRef.Caption);

        if ApplyMode <> ApplyMode::NonKeyFields then
            RecRef.Init();

        ConfigPackageTable.Get(ConfigPackageRecord."Package Code", ConfigPackageRecord."Table ID");
        DelayedInsert := ConfigPackageTable."Delayed Insert";

        IsHandled := false;
        OnInsertPackageRecordOnAfterDelayedInsert(RecRef, ConfigPackageRecord, ConfigPackageTable, ApplyMode, DelayedInsert, IsHandled);
        if IsHandled then
            exit;

        InsertPrimaryKeyFields(RecRef, ConfigPackageRecord, true, DelayedInsert);

        if ApplyMode = ApplyMode::PrimaryKey then
            UpdateKeyInfoForConfigPackageRecord(RecRef, ConfigPackageRecord);

        if (ApplyMode = ApplyMode::NonKeyFields) or DelayedInsert then
            ModifyRecordDataFields(RecRef, ConfigPackageRecord, true, DelayedInsert);
    end;

    procedure InsertPackageData(var ConfigPackageData: Record "Config. Package Data"; PackageCode: Code[20]; TableID: Integer; No: Integer; FieldID: Integer; Value: Text[2048]; Invalid: Boolean)
    begin
        if not ConfigPackageData.Get(PackageCode, TableID, No, FieldID) then begin
            ConfigPackageData.Init();
            ConfigPackageData."Package Code" := PackageCode;
            ConfigPackageData."Table ID" := TableID;
            ConfigPackageData."No." := No;
            ConfigPackageData."Field ID" := FieldID;
            ConfigPackageData.Value := Value;
            ConfigPackageData.Invalid := Invalid;
            ConfigPackageData.Insert();
        end else
            if ConfigPackageData.Value <> Value then begin
                ConfigPackageData.Value := Value;
                ConfigPackageData.Modify();
            end;
    end;

    procedure InsertProcessingRule(var ConfigTableProcessingRule: Record "Config. Table Processing Rule"; ConfigPackageTable: Record "Config. Package Table"; RuleNo: Integer; NewAction: Option)
    begin
        ConfigTableProcessingRule.Validate("Package Code", ConfigPackageTable."Package Code");
        ConfigTableProcessingRule.Validate("Table ID", ConfigPackageTable."Table ID");
        ConfigTableProcessingRule.Validate("Rule No.", RuleNo);
        ConfigTableProcessingRule.Validate(Action, NewAction);
        ConfigTableProcessingRule.Insert(true);
    end;

    procedure InsertProcessingRuleCustom(var ConfigTableProcessingRule: Record "Config. Table Processing Rule"; ConfigPackageTable: Record "Config. Package Table"; RuleNo: Integer; CodeunitID: Integer)
    begin
        ConfigTableProcessingRule.Validate("Package Code", ConfigPackageTable."Package Code");
        ConfigTableProcessingRule.Validate("Table ID", ConfigPackageTable."Table ID");
        ConfigTableProcessingRule.Validate("Rule No.", RuleNo);
        ConfigTableProcessingRule.Validate(Action, ConfigTableProcessingRule.Action::Custom);
        ConfigTableProcessingRule.Validate("Custom Processing Codeunit ID", CodeunitID);
        ConfigTableProcessingRule.Insert(true);
    end;

    procedure SetSkipTableTriggers(var ConfigPackageTable: Record "Config. Package Table"; PackageCode: Code[20]; TableID: Integer; Skip: Boolean)
    begin
        if ConfigPackageTable.Get(PackageCode, TableID) then begin
            ConfigPackageTable.Validate("Skip Table Triggers", Skip);
            ConfigPackageTable.Modify(true);
        end;
    end;

    procedure GetNumberOfRecordsInserted(): Integer
    begin
        exit(RecordsInsertedCount);
    end;

    procedure GetNumberOfRecordsModified(): Integer
    begin
        exit(RecordsModifiedCount);
    end;

    local procedure InsertPrimaryKeyFields(var RecRef: RecordRef; ConfigPackageRecord: Record "Config. Package Record"; DoInsert: Boolean; var DelayedInsert: Boolean)
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageField: Record "Config. Package Field";
        TempConfigPackageField: Record "Config. Package Field" temporary;
        ConfigPackageError: Record "Config. Package Error";
        RecRef1: RecordRef;
        FieldRef: FieldRef;
        IsHandled: Boolean;
    begin
        ConfigPackageData.SetRange("Package Code", ConfigPackageRecord."Package Code");
        ConfigPackageData.SetRange("Table ID", ConfigPackageRecord."Table ID");
        ConfigPackageData.SetRange("No.", ConfigPackageRecord."No.");

        GetKeyFieldsOrder(RecRef, ConfigPackageRecord."Package Code", TempConfigPackageField);
        GetFieldsMarkedAsPrimaryKey(ConfigPackageRecord."Package Code", RecRef.Number, TempConfigPackageField);

        TempConfigPackageField.Reset();
        TempConfigPackageField.SetCurrentKey("Package Code", "Table ID", "Processing Order");

        TempConfigPackageField.FindSet();
        repeat
            FieldRef := RecRef.Field(TempConfigPackageField."Field ID");
            ConfigPackageData.SetRange("Field ID", TempConfigPackageField."Field ID");
            if ConfigPackageData.FindFirst() then begin
                ConfigPackageField.Get(ConfigPackageData."Package Code", ConfigPackageData."Table ID", ConfigPackageData."Field ID");

                IsHandled := false;
                OnInsertPrimaryKeyFieldsOnBeforeUpdateValueUsingMapping(RecRef, ConfigPackageData, ConfigPackageField, ConfigPackageRecord, IsHandled);
                if not IsHandled then
                    UpdateValueUsingMapping(ConfigPackageData, ConfigPackageField, ConfigPackageRecord."Package Code");
                ValidationFieldID := FieldRef.Number;
                ConfigValidateMgt.EvaluateTextToFieldRef(
                  ConfigPackageData.Value, FieldRef, ConfigPackageField."Validate Field" and (ApplyMode = ApplyMode::PrimaryKey));
            end else
                Error(KeyFieldValueMissingErr, FieldRef.Name, RecRef.Name, ConfigPackageData."No.");
        until TempConfigPackageField.Next() = 0;

        RecRef1 := RecRef.Duplicate();

        if RecRef1.Find() then begin
            RecRef := RecRef1;
            exit
        end;
        if ((ConfigPackageRecord."Package Code" = QBPackageCodeTxt) or (ConfigPackageRecord."Package Code" = MSGPPackageCodeTxt)) and
           (ConfigPackageRecord."Table ID" = 15)
        then
            if ConfigPackageError.Get(
                 ConfigPackageRecord."Package Code", ConfigPackageRecord."Table ID", ConfigPackageRecord."No.", 1)
            then
                exit;

        if DelayedInsert then
            exit;

        if DoInsert then begin
            DelayedInsert := InsertRecord(RecRef, ConfigPackageRecord);
            RecordsInsertedCount += 1;
        end else
            DelayedInsert := false;
    end;

    local procedure UpdateKeyInfoForConfigPackageRecord(RecRef: RecordRef; ConfigPackageRecord: Record "Config. Package Record")
    var
        ConfigPackageData: Record "Config. Package Data";
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        KeyFieldCount: Integer;
    begin
        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldCount := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(KeyFieldCount);

            ConfigPackageData.Get(
              ConfigPackageRecord."Package Code", ConfigPackageRecord."Table ID", ConfigPackageRecord."No.", FieldRef.Number);
            ConfigPackageData.Value := Format(FieldRef.Value);
            ConfigPackageData.Modify();
        end;
    end;

    procedure InitPackageRecord(var ConfigPackageRecord: Record "Config. Package Record"; PackageCode: Code[20]; TableID: Integer)
    var
        NextNo: Integer;
    begin
        ConfigPackageRecord.Reset();
        ConfigPackageRecord.SetRange("Package Code", PackageCode);
        ConfigPackageRecord.SetRange("Table ID", TableID);
        if ConfigPackageRecord.FindLast() then
            NextNo := ConfigPackageRecord."No." + 1
        else
            NextNo := 1;

        ConfigPackageRecord.Init();
        ConfigPackageRecord."Package Code" := PackageCode;
        ConfigPackageRecord."Table ID" := TableID;
        ConfigPackageRecord."No." := NextNo;
        ConfigPackageRecord.Insert();
    end;

    local procedure InsertRecord(var RecRef: RecordRef; ConfigPackageRecord: Record "Config. Package Record"): Boolean
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigInsertWithValidation: Codeunit "Config. Insert With Validation";
        IsHandled: Boolean;
    begin
        ConfigPackageTable.Get(ConfigPackageRecord."Package Code", ConfigPackageRecord."Table ID");
        if ConfigPackageTable."Skip Table Triggers" then begin
            IsHandled := false;
            OnInsertRecordOnBeforeInsertRecRef(RecRef, ConfigPackageRecord, IsHandled);
            if not IsHandled then
                RecRef.Insert();
        end else begin
            Commit();
            ConfigInsertWithValidation.SetInsertParameters(RecRef);
            if not ConfigInsertWithValidation.Run() then begin
                ClearLastError();
                exit(true);
            end;
        end;
        exit(false);
    end;

    local procedure ModifyRecordDataFields(var RecRef: RecordRef; ConfigPackageRecord: Record "Config. Package Record"; DoModify: Boolean; DelayedInsert: Boolean)
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageField: Record "Config. Package Field";
        ConfigQuestion: Record "Config. Question";
        "Field": Record "Field";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageError: Record "Config. Package Error";
        ConfigQuestionnaireMgt: Codeunit "Questionnaire Management";
        IsHandled: Boolean;
    begin
        OnBeforeModifyRecordDataFields(RecRef, ConfigPackageRecord, DoModify, DelayedInsert);
        ConfigPackageField.Reset();
        ConfigPackageField.SetCurrentKey("Package Code", "Table ID", "Processing Order");
        ConfigPackageField.SetRange("Package Code", ConfigPackageRecord."Package Code");
        ConfigPackageField.SetRange("Table ID", ConfigPackageRecord."Table ID");
        ConfigPackageField.SetRange("Include Field", true);
        ConfigPackageField.SetRange(Dimension, false);

        ConfigPackageTable.Get(ConfigPackageRecord."Package Code", ConfigPackageRecord."Table ID");
        if DoModify or DelayedInsert then
            ApplyTemplate(ConfigPackageTable, RecRef);

        OnModifyRecordDataFieldsOnBeforeFindConfigPackageField(ConfigPackageField, ConfigPackageRecord, RecRef, DoModify, DelayedInsert);
        if ConfigPackageField.FindSet() then
            repeat
                ValidationFieldID := ConfigPackageField."Field ID";
                if ((ConfigPackageRecord."Package Code" = QBPackageCodeTxt) or (ConfigPackageRecord."Package Code" = MSGPPackageCodeTxt)) and
                   ((ConfigPackageRecord."Table ID" = 15) or (ConfigPackageRecord."Table ID" = 18) or
                    (ConfigPackageRecord."Table ID" = 23) or (ConfigPackageRecord."Table ID" = 27))
                then
                    if ConfigPackageError.Get(
                         ConfigPackageRecord."Package Code", ConfigPackageRecord."Table ID", ConfigPackageRecord."No.", 1)
                    then
                        exit;

                ModifyRecordDataField(
                  ConfigPackageRecord, ConfigPackageField, ConfigPackageData, ConfigPackageTable, RecRef, DoModify, DelayedInsert, true);
            until ConfigPackageField.Next() = 0;

        if not DoModify then
            exit;
        if not RecRef.IsDirty() then
            exit;

        if DelayedInsert then begin
            IsHandled := false;
            OnModifyRecordDataFieldsOnBeforeRecRefInsert(RecRef, ConfigPackageTable, IsHandled, ConfigPackageRecord);
            if not IsHandled then
                RecRef.Insert(true);
        end else begin
            IsHandled := false;
            OnModifyRecordDataFieldsOnBeforeRecRefModify(RecRef, ConfigPackageTable, RecordsModifiedCount, IsHandled, ConfigPackageRecord);
            if not IsHandled then
                RecRef.Modify(not ConfigPackageTable."Skip Table Triggers");
            OnModifyRecordDataFieldsOnAfterRecRefModify(RecRef);
            RecordsModifiedCount += 1;
        end;

        OnModifyRecordDataFieldsOnAfterRecRefUpdated(RecRef);

        if RecRef.Number = Database::"Config. Question" then begin
            RecRef.SetTable(ConfigQuestion);

            SetFieldFilter(Field, ConfigQuestion."Table ID", ConfigQuestion."Field ID");
            if Field.FindFirst() then
                ConfigQuestionnaireMgt.ModifyConfigQuestionAnswer(ConfigQuestion, Field);
        end;
    end;

    local procedure ModifyRecordDataField(var ConfigPackageRecord: Record "Config. Package Record"; var ConfigPackageField: Record "Config. Package Field"; var ConfigPackageData: Record "Config. Package Data"; var ConfigPackageTable: Record "Config. Package Table"; var RecRef: RecordRef; DoModify: Boolean; DelayInsert: Boolean; ReadConfigPackageData: Boolean)
    var
        FieldRef: FieldRef;
        IsTemplate: Boolean;
        SkipEvaluate: Boolean;
        IsHandled: Boolean;
    begin
        if ConfigPackageField."Primary Key" or ConfigPackageField.AutoIncrement then
            exit;

        if ReadConfigPackageData then
            if not ConfigPackageData.Get(
                 ConfigPackageRecord."Package Code", ConfigPackageRecord."Table ID", ConfigPackageRecord."No.", ConfigPackageField."Field ID")
            then
                exit;

        IsTemplate := IsTemplateField(ConfigPackageTable."Data Template", ConfigPackageField."Field ID");
        if not IsTemplate or (IsTemplate and (ConfigPackageData.Value <> '')) then begin
            FieldRef := RecRef.Field(ConfigPackageField."Field ID");
            IsHandled := false;
            OnModifyRecordDataFieldOnBeforeUpdateValueUsingMapping(ConfigPackageData, ConfigPackageField, ConfigPackageRecord, RecRef, IsHandled);
            if not IsHandled then
                UpdateValueUsingMapping(ConfigPackageData, ConfigPackageField, ConfigPackageRecord."Package Code");

            GetCachedConfigPackageField(ConfigPackageData);
            IsHandled := false;
            OnModifyRecordDataFieldOnAfterGetCachedConfigPackageField(RecRef, FieldRef, ConfigPackageField, ConfigPackageData, IsHandled);
            if not IsHandled then
                case true of
                    IsBLOBFieldInternal(TempConfigPackageFieldCache."Processing Order"):
                        EvaluateBLOBToFieldRef(ConfigPackageData, FieldRef);
                    IsMediaSetFieldInternal(TempConfigPackageFieldCache."Processing Order"):
                        ImportMediaSetFiles(ConfigPackageData, FieldRef, DoModify);
                    IsMediaFieldInternal(TempConfigPackageFieldCache."Processing Order"):
                        ImportMediaFiles(ConfigPackageData, FieldRef, DoModify);
                    else begin
                        SkipEvaluate := false;
                        OnModifyRecordDataFieldOnBeforeEvaluateTextToFieldRef(ConfigPackageField, ConfigPackageData, ConfigPackageTable, DelayInsert, ApplyMode, FieldRef, SkipEvaluate);
                        if not SkipEvaluate then
                            ConfigValidateMgt.EvaluateTextToFieldRef(ConfigPackageData.Value, FieldRef, ConfigPackageField."Validate Field" and ((ApplyMode = ApplyMode::NonKeyFields) or DelayInsert));
                    end;
                end;
        end;
    end;

    procedure RemoveRecordsWithObsoleteTableID(TableID: Integer; TableIDFieldNo: Integer)
    var
        TableMetadata: Record "Table Metadata";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(TableID);
        FieldRef := RecRef.Field(TableIDFieldNo);
        TableMetadata.SetRange(ObsoleteState, TableMetadata.ObsoleteState::Removed);
        if TableMetadata.FindSet() then
            repeat
                FieldRef.SetRange(TableMetadata.ID);
                if not RecRef.IsEmpty() then
                    RecRef.DeleteAll(true);
            until TableMetadata.Next() = 0;
        RecRef.Close();
    end;

    local procedure ApplyTemplate(ConfigPackageTable: Record "Config. Package Table"; var RecRef: RecordRef)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateMgt: Codeunit "Config. Template Management";
    begin
        if ConfigTemplateHeader.Get(ConfigPackageTable."Data Template") then begin
            ConfigTemplateMgt.UpdateRecord(ConfigTemplateHeader, RecRef);
            InsertDimensionsFromTemplates(ConfigPackageTable."Table ID", ConfigTemplateHeader, RecRef);
        end;
    end;

    local procedure InsertDimensionsFromTemplates(TableID: Integer; ConfigTemplateHeader: Record "Config. Template Header"; var RecRef: RecordRef)
    var
        DimensionsTemplate: Record "Dimensions Template";
        FieldRef: FieldRef;
        KeyRef: KeyRef;
    begin
        KeyRef := RecRef.KeyIndex(1);
        if KeyRef.FieldCount = 1 then begin
            FieldRef := KeyRef.FieldIndex(1);
            if Format(FieldRef.Value) <> '' then
                DimensionsTemplate.InsertDimensionsFromTemplates(
                  ConfigTemplateHeader, Format(FieldRef.Value), TableID);
        end;
    end;

    local procedure IsTemplateField(TemplateCode: Code[20]; FieldNo: Integer): Boolean
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        if TemplateCode = '' then
            exit(false);

        if not ConfigTemplateHeader.Get(TemplateCode) then
            exit(false);

        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
        ConfigTemplateLine.SetRange("Field ID", FieldNo);
        ConfigTemplateLine.SetRange(Type, ConfigTemplateLine.Type::Field);
        if not ConfigTemplateLine.IsEmpty() then
            exit(true);

        ConfigTemplateLine.SetRange("Field ID");
        ConfigTemplateLine.SetRange(Type, ConfigTemplateLine.Type::Template);
        if ConfigTemplateLine.FindSet() then
            repeat
                if IsTemplateField(ConfigTemplateLine."Template Code", FieldNo) then
                    exit(true);
            until ConfigTemplateLine.Next() = 0;
        exit(false);
    end;

    procedure ValidatePackageRelations(var ConfigPackageTable: Record "Config. Package Table"; var TempConfigPackageTable: Record "Config. Package Table" temporary; SetupProcessingOrderForTables: Boolean)
    var
        TableCount: Integer;
    begin
        if SetupProcessingOrderForTables then
            SetupProcessingOrder(ConfigPackageTable);

        TableCount := ConfigPackageTable.Count;
        if not HideDialog then
            ConfigProgressBar.Init(TableCount, 1, ValidatingTableRelationsMsg);

        ConfigPackageTable.ModifyAll(Validated, false);

        ConfigPackageTable.SetCurrentKey("Package Processing Order", "Processing Order");
        if ConfigPackageTable.FindSet() then
            repeat
                ConfigPackageTable.CalcFields("Table Name");
                if not HideDialog then
                    ConfigProgressBar.Update(ConfigPackageTable."Table Name");
                ValidateTableRelation(ConfigPackageTable."Package Code", ConfigPackageTable."Table ID", TempConfigPackageTable);

                TempConfigPackageTable.Init();
                TempConfigPackageTable."Package Code" := ConfigPackageTable."Package Code";
                TempConfigPackageTable."Table ID" := ConfigPackageTable."Table ID";
                TempConfigPackageTable.Insert();
                ConfigPackageTable.Validated := true;
                ConfigPackageTable.Modify();
            until ConfigPackageTable.Next() = 0;
        if not HideDialog then
            ConfigProgressBar.Close();

        if not HideDialog then
            Message(NoTablesMsg, TableCount);
    end;

    local procedure ValidateTableRelation(PackageCode: Code[20]; TableId: Integer; var ValidatedConfigPackageTable: Record "Config. Package Table")
    var
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageRecord: Record "Config. Package Record";
        RecRef: RecordRef;
        DelayedInsert: Boolean;
    begin
        ConfigPackageRecord.SetRange("Package Code", PackageCode);
        ConfigPackageRecord.SetRange("Table ID", TableId);
        if ConfigPackageRecord.FindSet() then
            repeat
                Clear(RecRef);
                RecRef.Open(TableId, true);
                InsertPrimaryKeyFields(RecRef, ConfigPackageRecord, false, DelayedInsert);

                ConfigPackageField.SetCurrentKey("Package Code", "Table ID", "Processing Order");
                ConfigPackageField.SetRange("Package Code", PackageCode);
                ConfigPackageField.SetRange("Table ID", TableId);
                ConfigPackageField.SetRange("Validate Field", true);
                if ConfigPackageField.FindSet() then
                    repeat
                        ValidateFieldRelationInRecord(ConfigPackageField, ValidatedConfigPackageTable, ConfigPackageRecord, RecRef);
                    until ConfigPackageField.Next() = 0;
                RecRef.Close();
            until ConfigPackageRecord.Next() = 0;
    end;

    procedure ValidateFieldRelationInRecord(ConfigPackageField: Record "Config. Package Field"; var ValidatedConfigPackageTable: Record "Config. Package Table"; ConfigPackageRecord: Record "Config. Package Record"; RecRef: RecordRef) NoValidateErrors: Boolean
    var
        ConfigPackageData: Record "Config. Package Data";
    begin
        NoValidateErrors := true;

        ConfigPackageData.SetRange("Package Code", ConfigPackageField."Package Code");
        ConfigPackageData.SetRange("Table ID", ConfigPackageField."Table ID");
        ConfigPackageData.SetRange("Field ID", ConfigPackageField."Field ID");
        ConfigPackageData.SetRange("No.", ConfigPackageRecord."No.");
        if ConfigPackageData.FindSet() then
            repeat
                NoValidateErrors :=
                  NoValidateErrors and
                  ValidatePackageDataRelation(
                    ConfigPackageData, ValidatedConfigPackageTable, ConfigPackageField, true, ConfigPackageRecord, RecRef);
            until ConfigPackageData.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ValidateSinglePackageDataRelation(var ConfigPackageData: Record "Config. Package Data"): Boolean
    var
        TempConfigPackageTable: Record "Config. Package Table" temporary;
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageRecord: Record "Config. Package Record";
        RecRef: RecordRef;
        DelayedInsert: Boolean;
    begin
        RecRef.Open(ConfigPackageData."Table ID", true);
        ConfigPackageRecord.Get(ConfigPackageData."Package Code", ConfigPackageData."Table ID", ConfigPackageData."No.");
        InsertPrimaryKeyFields(RecRef, ConfigPackageRecord, false, DelayedInsert);
        ConfigPackageField.Get(ConfigPackageData."Package Code", ConfigPackageData."Table ID", ConfigPackageData."Field ID");
        exit(ValidatePackageDataRelation(ConfigPackageData, TempConfigPackageTable, ConfigPackageField, false, ConfigPackageRecord, RecRef));
    end;

    local procedure ValidatePackageDataRelation(var ConfigPackageData: Record "Config. Package Data"; var ValidatedConfigPackageTable: Record "Config. Package Table"; var ConfigPackageField: Record "Config. Package Field"; GenerateFieldError: Boolean; ConfigPackageRecord: Record "Config. Package Record"; RecRef: RecordRef): Boolean
    var
        ErrorText: Text[250];
        RelationTableNo: Integer;
        RelationFieldNo: Integer;
        DataInPackageData: Boolean;
    begin
        if Format(ConfigPackageData.Value) <> '' then begin
            DataInPackageData := false;
            if GetRelationInfo(ConfigPackageField, RelationTableNo, RelationFieldNo) then
                DataInPackageData :=
                  ValidateFieldRelationAgainstPackageData(
                    ConfigPackageData, ValidatedConfigPackageTable, RelationTableNo, RelationFieldNo);

            OnAfterValidatePackageDataRelation(
              ConfigPackageData, ConfigPackageField, ValidatedConfigPackageTable, RelationTableNo, RelationFieldNo, DataInPackageData);

            if not DataInPackageData then begin
                ErrorText := ValidateFieldRelationAgainstCompanyData(ConfigPackageData, ConfigPackageRecord, RecRef);
                if ErrorText <> '' then begin
                    if GenerateFieldError then
                        FieldError(ConfigPackageData, ErrorText, ErrorTypeEnum::TableRelation);
                    exit(false);
                end;
            end;
        end;

        if PackageErrorsExists(ConfigPackageData, ErrorTypeEnum::TableRelation) then
            CleanFieldError(ConfigPackageData);
        exit(true);
    end;

    procedure ValidateException(TableID: Integer; FieldID: Integer) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateException(TableID, FieldID, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case TableID of
            // Dimension Value ID: ERROR message
            Database::"Dimension Value":
                exit(FieldID = 12);
            // Default Dimension: multi-relations
            Database::"Default Dimension":
                exit(FieldID = 2);
            // VAT %: CheckVATIdentifier
            Database::Microsoft.Finance.VAT.Setup."VAT Posting Setup":
                exit(FieldID = 4);
            // Table ID - OnValidate
            Database::"Config. Template Header":
                exit(FieldID = 3);
            // Field ID relation
            Database::"Config. Template Line":
                exit(FieldID in [4, 8, 12]);
            // Dimensions as Columns
            Database::"Config. Line":
                exit(FieldID = 12);
            // Customer : Contact OnValidate
            Database::Microsoft.Sales.Customer.Customer:
                exit(FieldID = 8);
            // Vendor : Contact OnValidate
            Database::Microsoft.Purchases.Vendor.Vendor:
                exit(FieldID = 8);
            // Item : Base Unit of Measure, Production BOM No. OnValidate
            Database::Microsoft.Inventory.Item.Item:
                exit(FieldID in [8, 99000751]);
            // "No." to pass not manual No. Series
            Database::Microsoft.Sales.Document."Sales Header", Database::Microsoft.Purchases.Document."Purchase Header":
                exit(FieldID = 3);
            // "Document No." conditional relation
            Database::Microsoft.Sales.Document."Sales Line", Database::Microsoft.Purchases.Document."Purchase Line":
                exit(FieldID = 3);
            // "Code"/"City" fields of Post Code record
            Database::Microsoft.Foundation.Address."Post Code":
                exit(FieldID in [1, 2]);
        end;
        exit(false);
    end;

    internal procedure ShowWarningOnImportingBigConfPackageFromExcel(FileSize: Integer): Action
    begin
        exit(ShowWarningOnImportingBigConfPackage(FileSize, 'Excel'));
    end;

    internal procedure ShowWarningOnImportingBigConfPackageFromRapidStart(FileSize: Integer): Action
    begin
        exit(ShowWarningOnImportingBigConfPackage(FileSize, 'RapidStart'));
    end;

    local procedure ShowWarningOnImportingBigConfPackage(FileSize: Integer; ImportingThrough: Text): Action
    var
        EnvironmentInformation: Codeunit "Environment Information";
        ConfigPackageWarning: Page "Config. Package Warning";
        BigFileSize: Integer;
    begin
        if not EnvironmentInformation.IsSaaS() then
            exit(Action::OK);

        BigFileSize := 3145728; // 3 MBytes
        if FileSize > BigFileSize then begin
            Session.LogMessage('0000BV2', StrSubstNo(UsingBigRSPackageTxt, 'Import ' + ImportingThrough, 'FileSize: ' + Format(FileSize)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RapidStartTxt);
            ConfigPackageWarning.SwitchContextToImport();
            ConfigPackageWarning.RunModal();
            if ConfigPackageWarning.GetAction() = Action::OK then
                Session.LogMessage('0000BV3', StrSubstNo(AcknowledgePerformanceImpactTxt, 'Import ' + ImportingThrough), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RapidStartTxt);
            exit(ConfigPackageWarning.GetAction());
        end;
        exit(Action::OK);
    end;

    internal procedure ShowWarningOnApplyingBigConfPackage(RecordCount: Integer): Action
    var
        EnvironmentInformation: Codeunit "Environment Information";
        ConfigPackageWarning: Page "Config. Package Warning";
        RecordCountLimit: Integer;
    begin
        if not EnvironmentInformation.IsSaaS() then
            exit(Action::OK);

        RecordCountLimit := 5000;
        if RecordCount > RecordCountLimit then begin
            Session.LogMessage('0000BVJ', StrSubstNo(UsingBigRSPackageTxt, 'Apply Package', 'Records: ' + Format(RecordCount)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RapidStartTxt);
            ConfigPackageWarning.SwitchContextToApply();
            ConfigPackageWarning.RunModal();
            if ConfigPackageWarning.GetAction() = Action::OK then
                Session.LogMessage('0000BVK', StrSubstNo(AcknowledgePerformanceImpactTxt, 'Apply Package'), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RapidStartTxt);
            exit(ConfigPackageWarning.GetAction());
        end;
        exit(Action::OK);
    end;

    internal procedure SentPackageImportedNotification(ConfigPackageCode: Code[20])
    var
        MyNotifications: Record "My Notifications";
        PackageImportedNotification: Notification;
    begin
        if not GuiAllowed() then
            exit;

        if not MyNotifications.IsEnabled(GetPackageImportedNotificationId()) then
            exit;

        PackageImportedNotification.Id := GetPackageImportedNotificationId();
        PackageImportedNotification.Message(StrSubstNo(PackageImportedNotificationTxt, ConfigPackageCode));
        PackageImportedNotification.SetData('PackageCode', ConfigPackageCode);
        PackageImportedNotification.Scope(NotificationScope::LocalScope);
        PackageImportedNotification.AddAction(ApplyPackageLbl, Codeunit::"Config. Package Management", 'ApplyPackageFromNotification');
        PackageImportedNotification.AddAction(DisableNotificationLbl, Codeunit::"Config. Package Management", 'DisableNotification');

        PackageImportedNotification.Send();
    end;

    local procedure GetPackageImportedNotificationId(): Guid
    begin
        exit('bf856162-cfac-4b73-94b5-ea744bc531a2');
    end;

    internal procedure ApplyPackageFromNotification(var PackageImportedNotification: Notification)
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackage: Record "Config. Package";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        PackageCode: Code[20];
    begin
        PackageCode := CopyStr(PackageImportedNotification.GetData('PackageCode'), 1, MaxStrLen(PackageCode));

        if not ConfigPackage.Get(PackageCode) then
            exit;

        ConfigPackageTable.SetRange("Package Code", PackageCode);
        ConfigPackageMgt.ApplyPackage(ConfigPackage, ConfigPackageTable, true);
    end;

    internal procedure DisableNotification(var PackageImportedNotification: Notification)
    var
        MyNotifications: Record "My Notifications";
    begin
        MyNotifications.InsertDefault(PackageImportedNotification.Id, PackagageImportedNotificationNameLbl, PackagageImportedNotificationDescriptionLbl, false);
        MyNotifications.Disable(PackageImportedNotification.Id)
    end;

    internal procedure ShowRapidStartNotification()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        RSNotificaiton: Notification;
    begin
        if not EnvironmentInformation.IsSaaS() then
            exit;

        if not IsExistingCompany() then
            exit;

        RSNotificaiton.Message(RSNotificaitonMsg);
        RSNotificaiton.AddAction(LearnMoreTok, Codeunit::"Config. Package Management", 'LearnMoreNotificationAction');
        RSNotificaiton.Send();
    end;

    internal procedure LearnMoreNotificationAction(var Notification: Notification)
    begin
        HyperLink(RapidStartDocumentationUrlTxt);
    end;

    local procedure IsExistingCompany(): Boolean
    var
        CompanyInformation: Record "Company Information";
        ThreeMonths: Duration;
    begin
        if not CompanyInformation.Get() then
            exit(false);

        if CompanyInformation."Created DateTime" = 0DT then
            exit(false);

        ThreeMonths := CreateDateTime(CalcDate('<+3M>', Today()), Time()) - CurrentDateTime();
        exit(CurrentDateTime() - CompanyInformation."Created DateTime" > ThreeMonths);
    end;

    procedure IsDimSetIDField(TableId: Integer; FieldId: Integer): Boolean
    var
        DimensionValue: Record "Dimension Value";
    begin
        exit((TableId = Database::"Dimension Value") and (DimensionValue.FieldNo("Dimension Value ID") = FieldId));
    end;

    local procedure GetRelationInfo(ConfigPackageField: Record "Config. Package Field"; var RelationTableNo: Integer; var RelationFieldNo: Integer): Boolean
    begin
        exit(
          ConfigValidateMgt.GetRelationInfoByIDs(
            ConfigPackageField."Table ID", ConfigPackageField."Field ID", RelationTableNo, RelationFieldNo));
    end;

    local procedure ValidateFieldRelationAgainstCompanyData(ConfigPackageData: Record "Config. Package Data"; ConfigPackageRecord: Record "Config. Package Record"; RecRef: RecordRef): Text[250]
    var
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageTable: Record "Config. Package Table";
        FieldRef: FieldRef;
    begin
        ConfigPackageField.Get(ConfigPackageData."Package Code", ConfigPackageData."Table ID", ConfigPackageData."Field ID");
        ConfigPackageTable.Get(ConfigPackageData."Package Code", ConfigPackageData."Table ID");
        ModifyRecordDataField(ConfigPackageRecord, ConfigPackageField, ConfigPackageData, ConfigPackageTable, RecRef, false, false, false);

        FieldRef := RecRef.Field(ConfigPackageData."Field ID");
        ConfigValidateMgt.EvaluateValue(FieldRef, ConfigPackageData.Value, false);

        GetFieldsOrderInternal(RecRef, ConfigPackageRecord."Package Code");
        exit(
            ValidateFieldRefRelationAgainstCompanyDataAndPackage(
                FieldRef, TempConfigPackageFieldOrdered, ConfigPackageRecord."Package Code"));
    end;

    procedure ValidateFieldRelationAgainstPackageData(ConfigPackageData: Record "Config. Package Data"; var ValidatedConfigPackageTable: Record "Config. Package Table"; RelationTableNo: Integer; RelationFieldNo: Integer): Boolean
    var
        RelatedConfigPackageData: Record "Config. Package Data";
        ConfigPackageTable: Record "Config. Package Table";
        TablePriority: Integer;
    begin
        if not ConfigPackageTable.Get(ConfigPackageData."Package Code", RelationTableNo) then
            exit(false);

        TablePriority := ConfigPackageTable."Processing Order";
        if ConfigValidateMgt.IsRelationInKeyFields(ConfigPackageData."Table ID", ConfigPackageData."Field ID") then begin
            ConfigPackageTable.Get(ConfigPackageData."Package Code", ConfigPackageData."Table ID");

            if ConfigPackageTable."Processing Order" < TablePriority then
                exit(false);

            // That current order will be for apply data
            ValidatedConfigPackageTable.Reset();
            ValidatedConfigPackageTable.SetRange("Table ID", RelationTableNo);
            if ValidatedConfigPackageTable.IsEmpty() then
                exit(false);
        end;

        RelatedConfigPackageData.SetRange("Package Code", ConfigPackageData."Package Code");
        RelatedConfigPackageData.SetRange("Table ID", RelationTableNo);
        RelatedConfigPackageData.SetRange("Field ID", RelationFieldNo);
        RelatedConfigPackageData.SetRange(Value, ConfigPackageData.Value);
        exit(not RelatedConfigPackageData.IsEmpty);
    end;

    procedure RecordError(var ConfigPackageRecord: Record "Config. Package Record"; ValidationFieldID: Integer; ErrorText: Text[250])
    var
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackageData: Record "Config. Package Data";
        RecordID: RecordID;
    begin
        if ErrorText = '' then
            exit;

        ConfigPackageError.Init();
        ConfigPackageError."Package Code" := ConfigPackageRecord."Package Code";
        ConfigPackageError."Table ID" := ConfigPackageRecord."Table ID";
        ConfigPackageError."Record No." := ConfigPackageRecord."No.";
        ConfigPackageError."Field ID" := ValidationFieldID;
        ConfigPackageError."Error Text" := ErrorText;

        ConfigPackageData.SetRange("Package Code", ConfigPackageRecord."Package Code");
        ConfigPackageData.SetRange("Table ID", ConfigPackageRecord."Table ID");
        ConfigPackageData.SetRange("No.", ConfigPackageRecord."No.");
        if Evaluate(RecordID, GetRecordIDOfRecordError(ConfigPackageData)) then
            ConfigPackageError."Record ID" := RecordID;
        if not ConfigPackageError.Insert() then
            ConfigPackageError.Modify();
        ConfigPackageRecord.Invalid := true;
        ConfigPackageRecord.Modify();
    end;

    procedure FieldError(var ConfigPackageData: Record "Config. Package Data"; ErrorText: Text[250]; ErrorType: Option ,TableRelation)
    var
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackageData2: Record "Config. Package Data";
        RecordID: RecordID;
    begin
        if ErrorText = '' then
            exit;

        ConfigPackageError.Init();
        ConfigPackageError."Package Code" := ConfigPackageData."Package Code";
        ConfigPackageError."Table ID" := ConfigPackageData."Table ID";
        ConfigPackageError."Record No." := ConfigPackageData."No.";
        ConfigPackageError."Field ID" := ConfigPackageData."Field ID";
        ConfigPackageError."Error Text" := ErrorText;
        ConfigPackageError."Error Type" := ErrorType;

        ConfigPackageData2.SetRange("Package Code", ConfigPackageData."Package Code");
        ConfigPackageData2.SetRange("Table ID", ConfigPackageData."Table ID");
        ConfigPackageData2.SetRange("No.", ConfigPackageData."No.");
        if Evaluate(RecordID, GetRecordIDOfRecordError(ConfigPackageData2)) then
            ConfigPackageError."Record ID" := RecordID;
        if not ConfigPackageError.Insert() then
            ConfigPackageError.Modify();

        ConfigPackageData.Invalid := true;
        ConfigPackageData.Modify();

        ConfigPackageRecord.Get(ConfigPackageData."Package Code", ConfigPackageData."Table ID", ConfigPackageData."No.");
        ConfigPackageRecord.Invalid := true;
        ConfigPackageRecord.Modify();
    end;

    procedure CleanRecordError(var ConfigPackageRecord: Record "Config. Package Record")
    var
        ConfigPackageError: Record "Config. Package Error";
    begin
        ConfigPackageError.SetRange("Package Code", ConfigPackageRecord."Package Code");
        ConfigPackageError.SetRange("Table ID", ConfigPackageRecord."Table ID");
        ConfigPackageError.SetRange("Record No.", ConfigPackageRecord."No.");
        ConfigPackageError.DeleteAll();
    end;

    procedure CleanFieldError(var ConfigPackageData: Record "Config. Package Data")
    var
        ConfigPackageError: Record "Config. Package Error";
        ConfigPackageRecord: Record "Config. Package Record";
        HasError: Boolean;
    begin
        if ConfigPackageError.Get(ConfigPackageData."Package Code", ConfigPackageData."Table ID", ConfigPackageData."No.", ConfigPackageData."Field ID") then begin
            ConfigPackageError.Delete();
            ConfigPackageData.Invalid := false;
            ConfigPackageData.Modify();

            ConfigPackageRecord.Get(ConfigPackageData."Package Code", ConfigPackageData."Table ID", ConfigPackageData."No.");
            HasError := IsRecordErrorsExists(ConfigPackageRecord);
            if ConfigPackageRecord.Invalid <> HasError then begin
                ConfigPackageRecord.Invalid := HasError;
                ConfigPackageRecord.Modify();
            end;
        end;
    end;

    procedure CleanPackageErrors(PackageCode: Code[20]; TableFilter: Text)
    var
        ConfigPackageError: Record "Config. Package Error";
    begin
        ConfigPackageError.SetRange("Package Code", PackageCode);
        if TableFilter <> '' then
            ConfigPackageError.SetFilter("Table ID", TableFilter);

        ConfigPackageError.DeleteAll();
    end;

    local procedure PackageErrorsExists(ConfigPackageData: Record "Config. Package Data"; ErrorType: Option General,TableRelation): Boolean
    var
        ConfigPackageError: Record "Config. Package Error";
    begin
        if not ConfigPackageError.Get(
             ConfigPackageData."Package Code", ConfigPackageData."Table ID", ConfigPackageData."No.", ConfigPackageData."Field ID")
        then
            exit(false);

        if ConfigPackageError."Error Type" = ErrorType then
            exit(true);

        exit(false)
    end;

    procedure GetValidationFieldID(): Integer
    begin
        exit(ValidationFieldID);
    end;

    procedure ApplyConfigLines(var ConfigLine: Record "Config. Line")
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigMgt: Codeunit "Config. Management";
        "Filter": Text;
    begin
        ConfigLine.FindFirst();
        ConfigPackage.Get(ConfigLine."Package Code");
        ConfigPackageTable.SetRange("Package Code", ConfigLine."Package Code");
        Filter := ConfigMgt.MakeTableFilter(ConfigLine, false);

        if Filter = '' then
            exit;

        ConfigPackageTable.SetFilter("Table ID", Filter);
        ApplyPackage(ConfigPackage, ConfigPackageTable, true);
    end;

    procedure ApplyPackage(ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; SetupProcessingOrderForTables: Boolean) ErrorCount: Integer
    var
        DimSetEntry: Record "Dimension Set Entry";
        ConfigPackageTableParent: Record "Config. Package Table";
        LocalConfigPackageRecord: Record "Config. Package Record";
        LocalConfigPackageField: Record "Config. Package Field";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        DimensionsNotifications: Codeunit "Dimensions Notifications";
        TableCount: Integer;
        RSApplyDataStartMsg: Label 'Apply of data started.', Locked = true;
        RSApplyDataFinishMsg: Label 'Apply of data finished. Error count: %1. Duration: %2 milliseconds. Total Records: %3. Total Fields: %4.', Locked = true;
        DurationAsInt: BigInteger;
        StartTime: DateTime;
        DimSetIDUsed: Boolean;
        RecordCount: Integer;
        FieldCount: Integer;
        ExecutionId: Guid;
        Dimensions: Dictionary of [Text, Text];
        IsHandled: Boolean;
    begin
        FeatureTelemetry.LogUptake('0000E3E', 'Configuration packages', Enum::"Feature Uptake Status"::"Used");

        LocalConfigPackageRecord.SetRange("Package Code", ConfigPackage.Code);
        RecordCount := LocalConfigPackageRecord.Count();
        LocalConfigPackageField.SetRange("Package Code", ConfigPackage.code);
        FieldCount := LocalConfigPackageField.Count();
        if GuiAllowed() then begin
            Commit();
            if ShowWarningOnApplyingBigConfPackage(RecordCount) = Action::Cancel then
                exit;
            if not DimensionsNotifications.ConfirmPackageHasDimensionsWarning(ConfigPackage.Code) then
                exit;
        end;

        StartTime := CurrentDateTime();
        ExecutionId := CreateGuid();
        Dimensions.Add('Category', RapidStartTxt);
        Dimensions.Add('PackageCode', ConfigPackage.SystemId);
        Dimensions.Add('ExecutionId', Format(ExecutionId, 0, 4));
        Session.LogMessage('0000E3N', StrSubstNo(ConfigurationPackageApplyDataStartMsg, ConfigPackage.SystemId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
        Session.LogMessage('00009Q8', RSApplyDataStartMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RapidStartTxt);

        ConfigPackage.CalcFields("No. of Records", "No. of Errors");
        TableCount := ConfigPackageTable.Count();
        if (ConfigPackage.Code <> MSGPPackageCodeTxt) and (ConfigPackage.Code <> QBPackageCodeTxt) then
            // Hold the error count for duplicate records.
            ErrorCount := ConfigPackage."No. of Errors";
        if (TableCount = 0) or (ConfigPackage."No. of Records" = 0) then
            exit;
        IsHandled := false;
        OnApplyPackageOnBeforeCleanPackageErrors(ConfigPackage, IsHandled);
        if not IsHandled then
            if (ConfigPackage.Code <> MSGPPackageCodeTxt) and (ConfigPackage.Code <> QBPackageCodeTxt) then
                // Skip this code to hold the error count for duplicate records.
                CleanPackageErrors(ConfigPackage.Code, ConfigPackageTable.GetFilter("Table ID"));

        if SetupProcessingOrderForTables then begin
            SetupProcessingOrder(ConfigPackageTable);
            Commit();
        end;

        DimSetIDUsed := false;
        if ConfigPackageTable.FindSet() then
            repeat
                DimSetIDUsed := ConfigMgt.IsDimSetIDTable(ConfigPackageTable."Table ID");
            until (ConfigPackageTable.Next() = 0) or DimSetIDUsed;

        if DimSetIDUsed and not DimSetEntry.IsEmpty() then
            UpdateDimSetIDValues(ConfigPackage);
        if (ConfigPackage.Code <> MSGPPackageCodeTxt) and (ConfigPackage.Code <> QBPackageCodeTxt) then
            DeleteAppliedPackageRecords(TempAppliedConfigPackageRecord); // Do not delete PackageRecords till transactions are created

        Commit();
        OnApplyPackageOnAfterCommit(ConfigPackageTable);

        TempAppliedConfigPackageRecord.DeleteAll();
        TempConfigRecordForProcessing.DeleteAll();
        Clear(RecordsInsertedCount);
        Clear(RecordsModifiedCount);

        // Handle independent tables
        ConfigPackageTable.SetRange("Parent Table ID", 0);
        ApplyPackageTables(ConfigPackage, ConfigPackageTable, ApplyMode::PrimaryKey);
        ApplyPackageTables(ConfigPackage, ConfigPackageTable, ApplyMode::NonKeyFields);

        // Handle children tables
        ConfigPackageTable.SetFilter("Parent Table ID", '>0');
        if ConfigPackageTable.FindSet() then
            repeat
                ConfigPackageTableParent.Get(ConfigPackage.Code, ConfigPackageTable."Parent Table ID");
                if ConfigPackageTableParent."Parent Table ID" = 0 then
                    ConfigPackageTable.Mark(true);
            until ConfigPackageTable.Next() = 0;
        ConfigPackageTable.MarkedOnly(true);
        ApplyPackageTables(ConfigPackage, ConfigPackageTable, ApplyMode::PrimaryKey);
        ApplyPackageTables(ConfigPackage, ConfigPackageTable, ApplyMode::NonKeyFields);

        // Handle grandchildren tables
        ConfigPackageTable.ClearMarks();
        ConfigPackageTable.MarkedOnly(false);
        if ConfigPackageTable.FindSet() then
            repeat
                ConfigPackageTableParent.Get(ConfigPackage.Code, ConfigPackageTable."Parent Table ID");
                if ConfigPackageTableParent."Parent Table ID" > 0 then
                    ConfigPackageTable.Mark(true);
            until ConfigPackageTable.Next() = 0;
        ConfigPackageTable.MarkedOnly(true);
        ApplyPackageTables(ConfigPackage, ConfigPackageTable, ApplyMode::PrimaryKey);
        ApplyPackageTables(ConfigPackage, ConfigPackageTable, ApplyMode::NonKeyFields);

        ProcessAppliedPackageRecords(TempConfigRecordForProcessing, TempAppliedConfigPackageRecord);
        if (ConfigPackage.Code <> MSGPPackageCodeTxt) and (ConfigPackage.Code <> QBPackageCodeTxt) then
            DeleteAppliedPackageRecords(TempAppliedConfigPackageRecord); // Do not delete PackageRecords till transactions are created

        ConfigPackage.CalcFields("No. of Errors");
        ErrorCount := ConfigPackage."No. of Errors" - ErrorCount;
        if ErrorCount < 0 then
            ErrorCount := 0;

        RecordsModifiedCount := MaxInt(RecordsModifiedCount - RecordsInsertedCount, 0);
        DurationAsInt := CurrentDateTime() - StartTime;

        Dimensions.Add('ErrorCount', Format(ErrorCount));
        Dimensions.Add('ExecutionTimeInMs', Format(DurationAsInt));
        Dimensions.Add('RecordCount', Format(RecordCount));
        Dimensions.Add('FieldCount', Format(FieldCount));
        Session.LogMessage('0000E3O', StrSubstNo(ConfigurationPackageApplyDataFinishMsg, ConfigPackage.SystemId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
        // Tag used for analytics
        Session.LogMessage('00009Q9', StrSubstNo(RSApplyDataFinishMsg, ErrorCount, DurationAsInt, RecordCount, FieldCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', RapidStartTxt);
        FeatureTelemetry.LogUsage('0000E3B', 'Configuration packages', 'Package applied');

        if not HideDialog then
            Message(NoTablesAndErrorsMsg, TableCount, ErrorCount, RecordsInsertedCount, RecordsModifiedCount);
    end;

    local procedure ApplyPackageTables(ConfigPackage: Record "Config. Package"; var ConfigPackageTable: Record "Config. Package Table"; ApplyMode: Option ,PrimaryKey,NonKeyFields)
    var
        ConfigPackageRecord: Record "Config. Package Record";
    begin
        ConfigPackageTable.SetCurrentKey("Package Processing Order", "Processing Order");

        if not HideDialog then
            ConfigProgressBar.Init(ConfigPackageTable.Count, 1,
              StrSubstNo(ApplyingPackageMsg, ConfigPackage.Code));
        if ConfigPackageTable.FindSet() then
            repeat
                ConfigPackageTable.CalcFields("Table Name");
                ConfigPackageRecord.SetRange("Package Code", ConfigPackageTable."Package Code");
                ConfigPackageRecord.SetRange("Table ID", ConfigPackageTable."Table ID");
                OnApplyPackageTablesOnFilterConfigPackageRecord(ConfigPackage, ConfigPackageRecord);
                if not HideDialog then
                    ConfigProgressBar.Update(ConfigPackageTable."Table Name");
                if not IsTableErrorsExists(ConfigPackageTable) then// Added to show item duplicate errors
                    ApplyPackageRecords(
                      ConfigPackageRecord, ConfigPackageTable."Package Code", ConfigPackageTable."Table ID", ApplyMode);
            until ConfigPackageTable.Next() = 0;

        if not HideDialog then
            ConfigProgressBar.Close();
    end;

    procedure ApplySelectedPackageRecords(var ConfigPackageRecord: Record "Config. Package Record"; PackageCode: Code[20]; TableNo: Integer)
    begin
        TempAppliedConfigPackageRecord.DeleteAll();
        TempConfigRecordForProcessing.DeleteAll();

        ApplyPackageRecords(ConfigPackageRecord, PackageCode, TableNo, ApplyMode::PrimaryKey);
        ApplyPackageRecords(ConfigPackageRecord, PackageCode, TableNo, ApplyMode::NonKeyFields);

        ProcessAppliedPackageRecords(TempConfigRecordForProcessing, TempAppliedConfigPackageRecord);
        DeleteAppliedPackageRecords(TempAppliedConfigPackageRecord);
    end;

    local procedure ApplyPackageRecords(var ConfigPackageRecord: Record "Config. Package Record"; PackageCode: Code[20]; TableNo: Integer; ApplyMode: Option ,PrimaryKey,NonKeyFields)
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        ConfigProgressBarRecord: Codeunit "Config. Progress Bar";
        RecRef: RecordRef;
        RecordCount: Integer;
        StepCount: Integer;
        Counter: Integer;
        ProcessingRuleIsSet: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApplyPackageRecords(ConfigPackageRecord, PackageCode, TableNo, ApplyMode, ConfigPackageMgt, TempAppliedConfigPackageRecord, ProcessingRuleIsSet, TempConfigRecordForProcessing, ConfigTableProcessingRule, RecordsInsertedCount, RecordsModifiedCount, HideDialog, IsHandled);
        if not IsHandled then begin
            ConfigPackageTable.Get(PackageCode, TableNo);
            ProcessingRuleIsSet := ConfigTableProcessingRule.FindTableRules(ConfigPackageTable);

            ConfigPackageMgt.SetApplyMode(ApplyMode);
            RecordCount := ConfigPackageRecord.Count();
            if not HideDialog and (RecordCount > 1000) then begin
                StepCount := Round(RecordCount / 100, 1);
                ConfigPackageTable.CalcFields("Table Name");
                ConfigProgressBarRecord.Init(
                  RecordCount, StepCount, StrSubstNo(ApplyingTableMsg, ConfigPackageTable."Table Name"));
            end;

            Counter := 0;
            if ConfigPackageRecord.FindSet() then begin
                RecRef.Open(ConfigPackageRecord."Table ID");
                if ConfigPackageTable."Delete Recs Before Processing" then begin
                    RecRef.DeleteAll();
                    Commit();
                end;
                repeat
                    Counter := Counter + 1;
                    if (ApplyMode = ApplyMode::PrimaryKey) or not IsRecordErrorsExistsInPrimaryKeyFields(ConfigPackageRecord) then begin
                        if ConfigPackageMgt.Run(ConfigPackageRecord) then begin
                            if not ((ApplyMode = ApplyMode::PrimaryKey) or IsRecordErrorsExists(ConfigPackageRecord)) then begin
                                CollectAppliedPackageRecord(ConfigPackageRecord, TempAppliedConfigPackageRecord);
                                if ProcessingRuleIsSet then
                                    CollectRecordForProcessingAction(ConfigPackageRecord, ConfigTableProcessingRule);
                            end
                        end else
                            if GetLastErrorText <> '' then begin
                                ConfigPackageMgt.RecordError(
                                  ConfigPackageRecord, ConfigPackageMgt.GetValidationFieldID(), CopyStr(GetLastErrorText, 1, 250));
                                ClearLastError();
                                Commit();
                            end;
                        RecordsInsertedCount += ConfigPackageMgt.GetNumberOfRecordsInserted();
                        RecordsModifiedCount += ConfigPackageMgt.GetNumberOfRecordsModified();
                    end;
                    if not HideDialog and (RecordCount > 1000) then
                        ConfigProgressBarRecord.Update(StrSubstNo(RecordsXofYMsg, Counter, RecordCount));
                until ConfigPackageRecord.Next() = 0;
            end;

            if not HideDialog and (RecordCount > 1000) then
                ConfigProgressBarRecord.Close();
        end;
        OnAfterApplyPackageRecords(ConfigPackageRecord, PackageCode, TableNo);
    end;

    local procedure CollectRecordForProcessingAction(ConfigPackageRecord: Record "Config. Package Record"; var ConfigTableProcessingRule: Record "Config. Table Processing Rule")
    begin
        ConfigTableProcessingRule.FindSet();
        repeat
            if ConfigPackageRecord.FitsProcessingFilter(ConfigTableProcessingRule."Rule No.") then
                TempConfigRecordForProcessing.AddRecord(ConfigPackageRecord, ConfigTableProcessingRule."Rule No.");
        until ConfigTableProcessingRule.Next() = 0;
    end;

    local procedure CollectAppliedPackageRecord(ConfigPackageRecord: Record "Config. Package Record"; var TempConfigPackageRecord: Record "Config. Package Record" temporary)
    begin
        TempConfigPackageRecord.Init();
        TempConfigPackageRecord := ConfigPackageRecord;
        TempConfigPackageRecord.Insert();
    end;

    local procedure DeleteAppliedPackageRecords(var TempConfigPackageRecord: Record "Config. Package Record" temporary)
    var
        ConfigPackageRecord: Record "Config. Package Record";
    begin
        if TempConfigPackageRecord.FindSet() then
            repeat
                ConfigPackageRecord.TransferFields(TempConfigPackageRecord);
                ConfigPackageRecord.Delete(true);
            until TempConfigPackageRecord.Next() = 0;
        TempConfigPackageRecord.DeleteAll();
        Commit();
    end;

    procedure ApplyConfigTables(ConfigPackage: Record "Config. Package")
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        ConfigPackageTable.Reset();
        ConfigPackageTable.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageTable.SetFilter("Table ID", '%1|%2|%3|%4|%5|%6|%7|%8',
          Database::"Config. Template Header", Database::"Config. Template Line",
          Database::"Config. Questionnaire", Database::"Config. Question Area", Database::"Config. Question",
          Database::"Config. Line", Database::"Config. Package Filter", Database::"Config. Table Processing Rule");
        if not ConfigPackageTable.IsEmpty() then begin
            Commit();
            SetHideDialog(true);
            ApplyPackageTables(ConfigPackage, ConfigPackageTable, ApplyMode::PrimaryKey);
            ApplyPackageTables(ConfigPackage, ConfigPackageTable, ApplyMode::NonKeyFields);
            DeleteAppliedPackageRecords(TempAppliedConfigPackageRecord);
        end;
    end;

    local procedure ProcessAppliedPackageRecords(var TempConfigRecordForProcessing: Record "Config. Record For Processing" temporary; var TempConfigPackageRecord: Record "Config. Package Record" temporary)
    var
        ConfigTableProcessingRule: Record "Config. Table Processing Rule";
        Subscriber: Variant;
    begin
        OnPreProcessPackage(TempConfigRecordForProcessing, Subscriber);
        if TempConfigRecordForProcessing.FindSet() then
            repeat
                if not ConfigTableProcessingRule.Process(TempConfigRecordForProcessing) then begin
                    TempConfigRecordForProcessing.FindConfigRecord(TempConfigPackageRecord);
                    RecordError(TempConfigPackageRecord, 0, CopyStr(GetLastErrorText, 1, 250));
                    TempConfigPackageRecord.Delete(); // Remove it from the buffer to avoid deletion in the package
                    Commit();
                end;
            until TempConfigRecordForProcessing.Next() = 0;
        TempConfigRecordForProcessing.DeleteAll();
        OnPostProcessPackage();
    end;

    procedure SetApplyMode(NewApplyMode: Option ,PrimaryKey,NonKeyFields)
    begin
        ApplyMode := NewApplyMode;
    end;

    procedure SetFieldFilter(var "Field": Record "Field"; TableID: Integer; FieldID: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetFieldFilter(Field, TableID, FieldID, IsHandled);
        if IsHandled then
            exit;

        Field.Reset();
        if TableID > 0 then
            Field.SetRange(TableNo, TableID);
        if FieldID > 0 then
            Field.SetRange("No.", FieldID)
        else
            Field.SetFilter("No.", '<>%1&<>%2&<>%3&<>%4&<>%5',
                    Field.FieldNo(SystemId),
                    Field.FieldNo(SystemCreatedAt),
                    Field.FieldNo(SystemCreatedBy),
                    Field.FieldNo(SystemModifiedAt),
                    Field.FieldNo(SystemModifiedBy));
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetRange(Enabled, true);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
    end;

    procedure SelectAllPackageFields(var ConfigPackageField: Record "Config. Package Field"; SetInclude: Boolean)
    var
        ConfigPackageField2: Record "Config. Package Field";
    begin
        ConfigPackageField.SetRange("Primary Key", false);
        ConfigPackageField.SetRange("Include Field", not SetInclude);
        if ConfigPackageField.FindSet() then
            repeat
                ConfigPackageField2.Get(ConfigPackageField."Package Code", ConfigPackageField."Table ID", ConfigPackageField."Field ID");
                ConfigPackageField2."Include Field" := SetInclude;
                ConfigPackageField2."Validate Field" :=
                  SetInclude and not ValidateException(ConfigPackageField."Table ID", ConfigPackageField."Field ID");
                ConfigPackageField2.Modify();
            until ConfigPackageField.Next() = 0;
        ConfigPackageField.SetRange("Include Field");
        ConfigPackageField.SetRange("Primary Key");
    end;

    procedure SetupProcessingOrder(var ConfigPackageTable: Record "Config. Package Table")
    var
        ConfigPackageTableLoop: Record "Config. Package Table";
        TempConfigPackageTable: Record "Config. Package Table" temporary;
        Flag: Integer;
        IsHandled: Boolean;
    begin
        OnBeforeSetupProcessingOrder(ConfigPackageTable, IsHandled);
        if IsHandled then
            exit;

        ConfigPackageTableLoop.CopyFilters(ConfigPackageTable);
        if not ConfigPackageTableLoop.FindSet(true) then
            exit;

        Flag := -1; // flag for all selected records: record processing order no was not initialized

        repeat
            ConfigPackageTableLoop."Processing Order" := Flag;
            ConfigPackageTableLoop.Modify();
        until ConfigPackageTableLoop.Next() = 0;

        ConfigPackageTable.FindSet(true);
        repeat
            if ConfigPackageTable."Processing Order" = Flag then begin
                SetupTableProcessingOrder(ConfigPackageTable."Package Code", ConfigPackageTable."Table ID", TempConfigPackageTable, 1);
                TempConfigPackageTable.Reset();
                TempConfigPackageTable.DeleteAll();
            end;
        until ConfigPackageTable.Next() = 0;
    end;

    local procedure SetupTableProcessingOrder(PackageCode: Code[20]; TableId: Integer; var CheckedConfigPackageTable: Record "Config. Package Table"; StackLevel: Integer): Integer
    var
        ConfigPackageTable: Record "Config. Package Table";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        I: Integer;
        ProcessingOrder: Integer;
    begin
        if CheckedConfigPackageTable.Get(PackageCode, TableId) then
            Error(ProcessingOrderErr, TableId);

        CheckedConfigPackageTable.Init();
        CheckedConfigPackageTable."Package Code" := PackageCode;
        CheckedConfigPackageTable."Table ID" := TableId;
        // level to cleanup temptable from field branch checking history for case with multiple field branches
        CheckedConfigPackageTable."Processing Order" := StackLevel;
        CheckedConfigPackageTable.Insert();

        RecRef.Open(TableId);
        KeyRef := RecRef.KeyIndex(1);

        ProcessingOrder := 1;

        for I := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(I);
            if (FieldRef.Relation <> 0) and (FieldRef.Relation <> TableId) then
                if ConfigPackageTable.Get(PackageCode, FieldRef.Relation) then begin
                    ProcessingOrder :=
                      MaxInt(
                        SetupTableProcessingOrder(PackageCode, FieldRef.Relation, CheckedConfigPackageTable, StackLevel + 1) + 1, ProcessingOrder);
                    ClearFieldBranchCheckingHistory(PackageCode, CheckedConfigPackageTable, StackLevel);
                end;
        end;

        if ConfigPackageTable.Get(PackageCode, TableId) then begin
            ConfigPackageTable."Processing Order" := ProcessingOrder;
            AdjustProcessingOrder(ConfigPackageTable);
            ConfigPackageTable.Modify();
        end;

        exit(ProcessingOrder);
    end;

    local procedure AdjustProcessingOrder(var ConfigPackageTable: Record "Config. Package Table")
    var
        RelatedConfigPackageTable: Record "Config. Package Table";
    begin
        case ConfigPackageTable."Table ID" of
            Database::Microsoft.Finance.GeneralLedger.Account."G/L Account Category":
                // Pushing G/L Account Category before G/L Account
                if RelatedConfigPackageTable.Get(ConfigPackageTable."Package Code", Database::Microsoft.Finance.GeneralLedger.Account."G/L Account") then
                    ConfigPackageTable."Processing Order" := RelatedConfigPackageTable."Processing Order" - 1;
            Database::Microsoft.Sales.Document."Sales Header" .. Database::Microsoft.Purchases.Document."Purchase Line":
                // Moving Sales/Purchase Documents down
                ConfigPackageTable."Processing Order" += 4;
            Database::Microsoft.Pricing.Calculation."Price Calculation Setup",
                Database::"Company Information":
                ConfigPackageTable."Processing Order" += 1;
            Database::Microsoft.Foundation.Reporting."Custom Report Layout":
                // Moving Layouts to be on the top
                ConfigPackageTable."Processing Order" := 0;
            // Moving Jobs tables down so contacts table can be processed first
            Database::Microsoft.Projects.Project.Job.Job, Database::Microsoft.Projects.Project.Job."Job Task",
                Database::Microsoft.Projects.Project.Planning."Job Planning Line", Database::Microsoft.Projects.Project.Journal."Job Journal Line",
                Database::Microsoft.Projects.Project.Journal."Job Journal Batch", Database::Microsoft.Projects.Project.Job."Job Posting Group",
                Database::Microsoft.Projects.Project.Journal."Job Journal Template", Database::Microsoft.CRM.Setup."Job Responsibility":
                ConfigPackageTable."Processing Order" += 4;
        end;
    end;

    local procedure ClearFieldBranchCheckingHistory(PackageCode: Code[20]; var CheckedConfigPackageTable: Record "Config. Package Table"; StackLevel: Integer)
    begin
        CheckedConfigPackageTable.SetRange("Package Code", PackageCode);
        CheckedConfigPackageTable.SetFilter("Processing Order", '>%1', StackLevel);
        CheckedConfigPackageTable.DeleteAll();
    end;

    local procedure MaxInt(Int1: Integer; Int2: Integer): Integer
    begin
        if Int1 > Int2 then
            exit(Int1);

        exit(Int2);
    end;

    local procedure GetDimSetID(PackageCode: Code[20]; DimSetValue: Text[2048]): Integer
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageData2: Record "Config. Package Data";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
    begin
        ConfigPackageData.SetRange("Package Code", PackageCode);
        ConfigPackageData.SetRange("Table ID", Database::"Dimension Set Entry");
        ConfigPackageData.SetRange("Field ID", TempDimSetEntry.FieldNo("Dimension Set ID"));
        if ConfigPackageData.FindSet() then
            repeat
                if ConfigPackageData.Value = DimSetValue then begin
                    TempDimSetEntry.Init();
                    ConfigPackageData2.Get(
                      ConfigPackageData."Package Code", ConfigPackageData."Table ID", ConfigPackageData."No.",
                      TempDimSetEntry.FieldNo("Dimension Code"));
                    TempDimSetEntry.Validate("Dimension Code", Format(ConfigPackageData2.Value));
                    ConfigPackageData2.Get(
                      ConfigPackageData."Package Code", ConfigPackageData."Table ID", ConfigPackageData."No.",
                      TempDimSetEntry.FieldNo("Dimension Value Code"));
                    TempDimSetEntry.Validate(
                      "Dimension Value Code", CopyStr(Format(ConfigPackageData2.Value), 1, MaxStrLen(TempDimSetEntry."Dimension Value Code")));
                    TempDimSetEntry.Insert();
                end;
            until ConfigPackageData.Next() = 0;

        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;

    procedure GetDimSetIDForRecord(ConfigPackageRecord: Record "Config. Package Record"): Integer
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageField: Record "Config. Package Field";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimValue: Record "Dimension Value";
        DimMgt: Codeunit DimensionManagement;
        ConfigPackageMgt: Codeunit "Config. Package Management";
        DimCode: Code[20];
        DimValueCode: Code[20];
        DimValueNotFound: Boolean;
    begin
        ConfigPackageData.SetRange("Package Code", ConfigPackageRecord."Package Code");
        ConfigPackageData.SetRange("Table ID", ConfigPackageRecord."Table ID");
        ConfigPackageData.SetRange("No.", ConfigPackageRecord."No.");
        ConfigPackageData.SetRange("Field ID", ConfigMgt.DimensionFieldID(), ConfigMgt.DimensionFieldID() + 999);
        ConfigPackageData.SetFilter(Value, '<>%1', '');
        if ConfigPackageData.FindSet() then
            repeat
                if ConfigPackageField.Get(ConfigPackageData."Package Code", ConfigPackageData."Table ID", ConfigPackageData."Field ID") then begin
                    ConfigPackageField.TestField(Dimension);
                    DimCode := CopyStr(Format(ConfigPackageField."Field Name"), 1, 20);
                    DimValueCode := CopyStr(Format(ConfigPackageData.Value), 1, MaxStrLen(TempDimSetEntry."Dimension Value Code"));
                    TempDimSetEntry.Init();
                    TempDimSetEntry.Validate("Dimension Code", DimCode);
                    if DimValue.Get(DimCode, DimValueCode) then begin
                        TempDimSetEntry.Validate("Dimension Value Code", DimValueCode);
                        TempDimSetEntry.Insert();
                    end else begin
                        ConfigPackageMgt.FieldError(
                          ConfigPackageData, StrSubstNo(DimValueDoesNotExistsErr, DimCode, DimValueCode), ErrorTypeEnum::General);
                        DimValueNotFound := true;
                    end;
                end;
            until ConfigPackageData.Next() = 0;
        if DimValueNotFound then
            exit(0);
        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;

    local procedure UpdateDimSetIDValues(ConfigPackage: Record "Config. Package")
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageTableDim: Record "Config. Package Table";
        ConfigPackageDataDimSet: Record "Config. Package Data";
        DimSetEntry: Record "Dimension Set Entry";
    begin
        ConfigPackageTableDim.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageTableDim.SetRange("Table ID", Database::Dimension, Database::"Default Dimension Priority");
        if not ConfigPackageTableDim.IsEmpty() then begin
            ApplyPackageTables(ConfigPackage, ConfigPackageTableDim, ApplyMode::PrimaryKey);
            ApplyPackageTables(ConfigPackage, ConfigPackageTableDim, ApplyMode::NonKeyFields);
        end;

        ConfigPackageDataDimSet.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageDataDimSet.SetRange("Table ID", Database::"Dimension Set Entry");
        ConfigPackageDataDimSet.SetRange("Field ID", DimSetEntry.FieldNo("Dimension Set ID"));
        if ConfigPackageDataDimSet.IsEmpty() then
            exit;

        ConfigPackageData.Reset();
        ConfigPackageData.SetRange("Package Code", ConfigPackage.Code);
        ConfigPackageData.SetFilter("Table ID", '<>%1', Database::"Dimension Set Entry");
        ConfigPackageData.SetRange("Field ID", Database::"Dimension Set Entry");
        if ConfigPackageData.FindSet(true) then begin
            if not HideDialog then
                ConfigProgressBar.Init(ConfigPackageData.Count, 1, UpdatingDimSetsMsg);
            repeat
                ConfigPackageTable.Get(ConfigPackage.Code, ConfigPackageData."Table ID");
                ConfigPackageTable.CalcFields("Table Name");
                if not HideDialog then
                    ConfigProgressBar.Update(ConfigPackageTable."Table Name");
                if ConfigPackageData.Value <> '' then begin
                    ConfigPackageData.Value := Format(GetDimSetID(ConfigPackage.Code, ConfigPackageData.Value));
                    ConfigPackageData.Modify();
                end;
            until ConfigPackageData.Next() = 0;
            if not HideDialog then
                ConfigProgressBar.Close();
        end;
    end;

    procedure UpdateDefaultDimValues(ConfigPackageRecord: Record "Config. Package Record"; MasterNo: Code[20])
    var
        ConfigPackageTableDim: Record "Config. Package Table";
        ConfigPackageRecordDim: Record "Config. Package Record";
        ConfigPackageDataDim: array[4] of Record "Config. Package Data";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageData: Record "Config. Package Data";
        DefaultDim: Record "Default Dimension";
        DimValue: Record "Dimension Value";
        RecordFound: Boolean;
    begin
        ConfigPackageRecord.TestField("Package Code");
        ConfigPackageRecord.TestField("Table ID");

        ConfigPackageData.SetRange("Package Code", ConfigPackageRecord."Package Code");
        ConfigPackageData.SetRange("Table ID", ConfigPackageRecord."Table ID");
        ConfigPackageData.SetRange("No.", ConfigPackageRecord."No.");
        ConfigPackageData.SetRange("Field ID", ConfigMgt.DimensionFieldID(), ConfigMgt.DimensionFieldID() + 999);
        ConfigPackageData.SetFilter(Value, '<>%1', '');

        if ConfigPackageData.IsEmpty() then
            exit;

        if ConfigPackageData.FindSet() then
            repeat
                if ConfigPackageField.Get(ConfigPackageData."Package Code", ConfigPackageData."Table ID", ConfigPackageData."Field ID") then begin
                    // find if Dimension Code already exist
                    RecordFound := false;

                    ConfigPackageDataDim[1].SetRange("Package Code", ConfigPackageRecord."Package Code");
                    ConfigPackageDataDim[1].SetRange("Table ID", Database::"Default Dimension");
                    ConfigPackageDataDim[1].SetRange("Field ID", DefaultDim.FieldNo("Table ID"));
                    ConfigPackageDataDim[1].SetRange(Value, Format(ConfigPackageRecord."Table ID"));
                    if not ConfigPackageDataDim[1].IsEmpty() then
                        if ConfigPackageDataDim[1].FindSet() then
                            repeat
                                if ConfigPackageDataDim[2].Get(ConfigPackageRecord."Package Code", Database::"Default Dimension", ConfigPackageDataDim[1]."No.", DefaultDim.FieldNo("No.")) and
                                    (ConfigPackageDataDim[2].Value = MasterNo)
                                then
                                    if ConfigPackageDataDim[3].Get(ConfigPackageRecord."Package Code", Database::"Default Dimension", ConfigPackageDataDim[2]."No.", DefaultDim.FieldNo("Dimension Code")) and
                                        (ConfigPackageDataDim[3].Value = ConfigPackageField."Field Name")
                                    then
                                        RecordFound := true;
                            until (ConfigPackageDataDim[1].Next() = 0) or RecordFound;

                    if not RecordFound then begin
                        if not ConfigPackageTableDim.Get(ConfigPackageRecord."Package Code", Database::"Default Dimension") then
                            InsertPackageTable(ConfigPackageTableDim, ConfigPackageRecord."Package Code", Database::"Default Dimension");
                        InitPackageRecord(ConfigPackageRecordDim, ConfigPackageTableDim."Package Code", ConfigPackageTableDim."Table ID");
                        // Insert Default Dimension record
                        InsertPackageData(ConfigPackageDataDim[4],
                            ConfigPackageRecordDim."Package Code", ConfigPackageRecordDim."Table ID", ConfigPackageRecordDim."No.",
                            DefaultDim.FieldNo("Table ID"), Format(ConfigPackageRecord."Table ID"), false);
                        InsertPackageData(ConfigPackageDataDim[4],
                            ConfigPackageRecordDim."Package Code", ConfigPackageRecordDim."Table ID", ConfigPackageRecordDim."No.",
                            DefaultDim.FieldNo("No."), Format(MasterNo), false);
                        InsertPackageData(ConfigPackageDataDim[4],
                            ConfigPackageRecordDim."Package Code", ConfigPackageRecordDim."Table ID", ConfigPackageRecordDim."No.",
                            DefaultDim.FieldNo("Dimension Code"), ConfigPackageField."Field Name", false);
                        if IsBlankDim(ConfigPackageData.Value) then
                            InsertPackageData(ConfigPackageDataDim[4],
                                ConfigPackageRecordDim."Package Code", ConfigPackageRecordDim."Table ID", ConfigPackageRecordDim."No.",
                                DefaultDim.FieldNo("Dimension Value Code"), '', false)
                        else
                            InsertPackageData(ConfigPackageDataDim[4],
                                ConfigPackageRecordDim."Package Code", ConfigPackageRecordDim."Table ID", ConfigPackageRecordDim."No.",
                                DefaultDim.FieldNo("Dimension Value Code"), ConfigPackageData.Value, false);
                    end else begin
                        ConfigPackageDataDim[3].Get(ConfigPackageRecord."Package Code", Database::"Default Dimension", ConfigPackageDataDim[2]."No.", DefaultDim.FieldNo("Dimension Value Code"));
                        ConfigPackageDataDim[3].Value := ConfigPackageData.Value;
                        ConfigPackageDataDim[3].Modify();
                    end;
                    // Insert Dimension value if needed
                    if not IsBlankDim(ConfigPackageData.Value) then
                        if not DimValue.Get(ConfigPackageField."Field Name", ConfigPackageData.Value) then begin
                            ConfigPackageRecord.TestField("Package Code");
                            if not ConfigPackageTableDim.Get(ConfigPackageRecord."Package Code", Database::"Dimension Value") then
                                InsertPackageTable(ConfigPackageTableDim, ConfigPackageRecord."Package Code", Database::"Dimension Value");
                            InitPackageRecord(ConfigPackageRecordDim, ConfigPackageTableDim."Package Code", ConfigPackageTableDim."Table ID");
                            InsertPackageData(ConfigPackageDataDim[4],
                                ConfigPackageRecordDim."Package Code", ConfigPackageRecordDim."Table ID", ConfigPackageRecordDim."No.",
                                DimValue.FieldNo("Dimension Code"), ConfigPackageField."Field Name", false);
                            InsertPackageData(ConfigPackageDataDim[4],
                                ConfigPackageRecordDim."Package Code", ConfigPackageRecordDim."Table ID", ConfigPackageRecordDim."No.",
                                DimValue.FieldNo(Code), ConfigPackageData.Value, false);
                        end;
                end;
            until ConfigPackageData.Next() = 0;
    end;

    local procedure IsBlankDim(Value: Text[2048]): Boolean
    begin
        exit(UpperCase(Value) = UpperCase(BlankTxt));
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure AddConfigTables(PackageCode: Code[20])
    var
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigLine: Record "Config. Line";
    begin
        ConfigPackageTable.Init();
        InsertPackageTable(ConfigPackageTable, PackageCode, Database::"Config. Questionnaire");
        InsertPackageTable(ConfigPackageTable, PackageCode, Database::"Config. Question Area");
        InsertPackageTable(ConfigPackageTable, PackageCode, Database::"Config. Question");
        InsertPackageTable(ConfigPackageTable, PackageCode, Database::"Config. Template Header");
        InsertPackageTable(ConfigPackageTable, PackageCode, Database::"Config. Template Line");
        InsertPackageTable(ConfigPackageTable, PackageCode, Database::"Config. Tmpl. Selection Rules");
        InsertPackageTable(ConfigPackageTable, PackageCode, Database::"Config. Line");
        InsertPackageFilter(ConfigPackageFilter, PackageCode, Database::"Config. Line", 0, ConfigLine.FieldNo("Package Code"), PackageCode);
        InsertPackageTable(ConfigPackageTable, PackageCode, Database::"Config. Package Filter");
        InsertPackageFilter(
          ConfigPackageFilter, PackageCode, Database::"Config. Package Filter", 0, ConfigPackageFilter.FieldNo("Package Code"), PackageCode);
        InsertPackageTable(ConfigPackageTable, PackageCode, Database::"Config. Field Map");
        InsertPackageTable(ConfigPackageTable, PackageCode, Database::"Config. Table Processing Rule");
        OnAddConfigTablesOnBeforeSetSkipTableTriggers(ConfigPackageTable, PackageCode);
        SetSkipTableTriggers(ConfigPackageTable, PackageCode, Database::"Config. Table Processing Rule", true);
        InsertPackageFilter(
          ConfigPackageFilter, PackageCode, Database::"Config. Table Processing Rule", 0,
          ConfigPackageFilter.FieldNo("Package Code"), PackageCode);
    end;

    procedure AssignPackage(var ConfigLine: Record "Config. Line"; PackageCode: Code[20])
    var
        ConfigLine2: Record "Config. Line";
        TempConfigLine: Record "Config. Line" temporary;
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageTable2: Record "Config. Package Table";
        LineTypeFilter: Text;
    begin
        CreateConfigLineBuffer(ConfigLine, TempConfigLine, PackageCode);
        CheckConfigLinesToAssign(TempConfigLine);

        LineTypeFilter := ConfigLine.GetFilter("Line Type");
        ConfigLine.SetFilter("Package Code", '<>%1', PackageCode);
        ConfigLine.SetRange("Line Type");
        if ConfigLine.FindSet(true) then
            repeat
                ConfigLine.CheckBlocked();
                if ConfigLine.Status <= ConfigLine.Status::"In Progress" then begin
                    if ConfigLine."Line Type" = ConfigLine."Line Type"::Table then begin
                        ConfigLine.TestField("Table ID");
                        if ConfigPackageTable.Get(ConfigLine."Package Code", ConfigLine."Table ID") then begin
                            ConfigLine2.SetRange("Package Code", PackageCode);
                            ConfigLine2.SetRange("Table ID", ConfigLine."Table ID");
                            CheckConfigLinesToAssign(ConfigLine2);
                            InsertPackageTable(ConfigPackageTable2, PackageCode, ConfigLine."Table ID");
                            ChangePackageCode(ConfigLine."Package Code", PackageCode, ConfigLine."Table ID");
                            ConfigPackageTable.Delete(true);
                        end else
                            if not ConfigPackageTable.Get(PackageCode, ConfigLine."Table ID") then
                                InsertPackageTable(ConfigPackageTable, PackageCode, ConfigLine."Table ID");
                    end;
                    ConfigLine."Package Code" := PackageCode;
                    ConfigLine.Modify();
                end;
            until ConfigLine.Next() = 0;

        ConfigLine.SetRange("Package Code");
        if LineTypeFilter <> '' then
            ConfigLine.SetFilter("Line Type", LineTypeFilter);
    end;

    local procedure ChangePackageCode(OldPackageCode: Code[20]; NewPackageCode: Code[20]; TableID: Integer)
    var
        ConfigPackageRecord: Record "Config. Package Record";
        TempConfigPackageRecord: Record "Config. Package Record" temporary;
        ConfigPackageData: Record "Config. Package Data";
        TempConfigPackageData: Record "Config. Package Data" temporary;
        ConfigPackageFilter: Record "Config. Package Filter";
        TempConfigPackageFilter: Record "Config. Package Filter" temporary;
        ConfigPackageError: Record "Config. Package Error";
        TempConfigPackageError: Record "Config. Package Error" temporary;
    begin
        TempConfigPackageRecord.DeleteAll();
        ConfigPackageRecord.SetRange("Package Code", OldPackageCode);
        ConfigPackageRecord.SetRange("Table ID", TableID);
        if ConfigPackageRecord.FindSet(true) then
            repeat
                TempConfigPackageRecord := ConfigPackageRecord;
                TempConfigPackageRecord."Package Code" := NewPackageCode;
                TempConfigPackageRecord.Insert();
            until ConfigPackageRecord.Next() = 0;
        if TempConfigPackageRecord.FindSet() then
            repeat
                ConfigPackageRecord := TempConfigPackageRecord;
                ConfigPackageRecord.Insert();
            until TempConfigPackageRecord.Next() = 0;

        TempConfigPackageData.DeleteAll();
        ConfigPackageData.SetRange("Package Code", OldPackageCode);
        ConfigPackageData.SetRange("Table ID", TableID);
        if ConfigPackageData.FindSet(true) then
            repeat
                TempConfigPackageData := ConfigPackageData;
                TempConfigPackageData."Package Code" := NewPackageCode;
                TempConfigPackageData.Insert();
            until ConfigPackageData.Next() = 0;
        if TempConfigPackageData.FindSet() then
            repeat
                ConfigPackageData := TempConfigPackageData;
                ConfigPackageData.Insert();
            until TempConfigPackageData.Next() = 0;

        TempConfigPackageError.DeleteAll();
        ConfigPackageError.SetRange("Package Code", OldPackageCode);
        ConfigPackageError.SetRange("Table ID", TableID);
        if ConfigPackageError.FindSet(true) then
            repeat
                TempConfigPackageError := ConfigPackageError;
                TempConfigPackageError."Package Code" := NewPackageCode;
                TempConfigPackageError.Insert();
            until ConfigPackageError.Next() = 0;
        if TempConfigPackageError.FindSet() then
            repeat
                ConfigPackageError := TempConfigPackageError;
                ConfigPackageError.Insert();
            until TempConfigPackageError.Next() = 0;

        TempConfigPackageFilter.DeleteAll();
        ConfigPackageFilter.SetRange("Package Code", OldPackageCode);
        ConfigPackageFilter.SetRange("Table ID", TableID);
        if ConfigPackageFilter.FindSet(true) then
            repeat
                TempConfigPackageFilter := ConfigPackageFilter;
                TempConfigPackageFilter."Package Code" := NewPackageCode;
                TempConfigPackageFilter.Insert();
            until ConfigPackageFilter.Next() = 0;
        if TempConfigPackageFilter.FindSet() then
            repeat
                ConfigPackageFilter := TempConfigPackageFilter;
                ConfigPackageFilter.Insert();
            until TempConfigPackageFilter.Next() = 0;
    end;

    procedure CheckConfigLinesToAssign(var ConfigLine: Record "Config. Line")
    var
        TempAllObj: Record AllObj temporary;
    begin
        ConfigLine.SetRange("Line Type", ConfigLine."Line Type"::Table);
        if ConfigLine.FindSet() then
            repeat
                if TempAllObj.Get(TempAllObj."Object Type"::Table, ConfigLine."Table ID") then
                    Error(ReferenceSameTableErr);
                TempAllObj."Object Type" := TempAllObj."Object Type"::Table;
                TempAllObj."Object ID" := ConfigLine."Table ID";
                TempAllObj.Insert();
            until ConfigLine.Next() = 0;
    end;

    local procedure CreateConfigLineBuffer(var ConfigLineNew: Record "Config. Line"; var ConfigLineBuffer: Record "Config. Line"; PackageCode: Code[20])
    var
        ConfigLine: Record "Config. Line";
    begin
        ConfigLine.SetRange("Package Code", PackageCode);
        AddConfigLineToBuffer(ConfigLine, ConfigLineBuffer);
        AddConfigLineToBuffer(ConfigLineNew, ConfigLineBuffer);
    end;

    local procedure AddConfigLineToBuffer(var ConfigLine: Record "Config. Line"; var ConfigLineBuffer: Record "Config. Line")
    begin
        if ConfigLine.FindSet() then
            repeat
                if not ConfigLineBuffer.Get(ConfigLine."Line No.") then begin
                    ConfigLineBuffer.Init();
                    ConfigLineBuffer.TransferFields(ConfigLine);
                    ConfigLineBuffer.Insert();
                end;
            until ConfigLine.Next() = 0;
    end;

    procedure GetRelatedTables(var ConfigPackageTable: Record "Config. Package Table")
    var
        TempConfigPackageTable: Record "Config. Package Table" temporary;
        "Field": Record "Field";
        IsHandled: Boolean;
    begin
        TempConfigPackageTable.DeleteAll();
        if ConfigPackageTable.FindSet() then
            repeat
                SetFieldFilter(Field, ConfigPackageTable."Table ID", 0);
                Field.SetFilter(RelationTableNo, '<>%1&<>%2&..%3', 0, ConfigPackageTable."Table ID", 99000999);
                IsHandled := false;
                OnBeforeGetFieldRelationTableNo(ConfigPackageTable, Field, TempConfigPackageTable, IsHandled);
                if not IsHandled then
                    if Field.FindSet() then
                        repeat
                            TempConfigPackageTable."Package Code" := ConfigPackageTable."Package Code";
                            TempConfigPackageTable."Table ID" := Field.RelationTableNo;
                            if TempConfigPackageTable.Insert() then;
                        until Field.Next() = 0;
            until ConfigPackageTable.Next() = 0;

        ConfigPackageTable.Reset();
        if TempConfigPackageTable.FindSet() then
            repeat
                if not ConfigPackageTable.Get(TempConfigPackageTable."Package Code", TempConfigPackageTable."Table ID") then
                    InsertPackageTable(ConfigPackageTable, TempConfigPackageTable."Package Code", TempConfigPackageTable."Table ID");
            until TempConfigPackageTable.Next() = 0;
    end;

    local procedure GetKeyFieldsOrder(RecRef: RecordRef; PackageCode: Code[20]; var TempConfigPackageField: Record "Config. Package Field" temporary)
    var
        ConfigPackageField: Record "Config. Package Field";
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        KeyFieldCount: Integer;
    begin
        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldCount := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(KeyFieldCount);
            ValidationFieldID := FieldRef.Number;

            if ConfigPackageField.Get(PackageCode, RecRef.Number, FieldRef.Number) then;

            TempConfigPackageField.Init();
            TempConfigPackageField."Package Code" := PackageCode;
            TempConfigPackageField."Table ID" := RecRef.Number;
            TempConfigPackageField."Field ID" := FieldRef.Number;
            TempConfigPackageField."Processing Order" := ConfigPackageField."Processing Order";
            TempConfigPackageField.Insert();
        end;
        OnAfterGetKeyFieldsOrder(RecRef, PackageCode, TempConfigPackageField, ValidationFieldID);
    end;

    local procedure GetFieldsMarkedAsPrimaryKey(PackageCode: Code[20]; TableID: Integer; var TempConfigPackageField: Record "Config. Package Field" temporary)
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        ConfigPackageField.SetRange("Package Code", PackageCode);
        ConfigPackageField.SetRange("Table ID", TableID);
        ConfigPackageField.FilterGroup(-1);
        ConfigPackageField.SetRange("Primary Key", true);
        ConfigPackageField.SetRange(AutoIncrement, true);
        ConfigPackageField.FilterGroup(0);
        if ConfigPackageField.FindSet() then
            repeat
                TempConfigPackageField.TransferFields(ConfigPackageField);
                if TempConfigPackageField.Insert() then;
            until ConfigPackageField.Next() = 0;
    end;

    procedure GetFieldsOrder(RecRef: RecordRef; PackageCode: Code[20]; var TempConfigPackageField: Record "Config. Package Field" temporary)
    var
        ConfigPackageField: Record "Config. Package Field";
        FieldRef: FieldRef;
        FieldCount: Integer;
    begin
        for FieldCount := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(FieldCount);

            if ConfigPackageField.Get(PackageCode, RecRef.Number, FieldRef.Number) then;

            TempConfigPackageField.Init();
            TempConfigPackageField."Package Code" := PackageCode;
            TempConfigPackageField."Table ID" := RecRef.Number;
            TempConfigPackageField."Field ID" := FieldRef.Number;
            TempConfigPackageField."Processing Order" := ConfigPackageField."Processing Order";
            TempConfigPackageField.Insert();
        end;
    end;

    local procedure GetFieldsOrderInternal(RecRef: RecordRef; PackageCode: Code[20])
    begin
        TempConfigPackageFieldOrdered.Reset();
        TempConfigPackageFieldOrdered.SetRange("Package Code", PackageCode);
        TempConfigPackageFieldOrdered.SetRange("Table ID", RecRef.Number);
        if not TempConfigPackageFieldOrdered.IsEmpty() then
            exit;

        GetFieldsOrder(RecRef, PackageCode, TempConfigPackageFieldOrdered);
    end;

    local procedure IsRecordErrorsExists(ConfigPackageRecord: Record "Config. Package Record"): Boolean
    var
        ConfigPackageError: Record "Config. Package Error";
    begin
        ConfigPackageError.SetRange("Package Code", ConfigPackageRecord."Package Code");
        ConfigPackageError.SetRange("Table ID", ConfigPackageRecord."Table ID");
        ConfigPackageError.SetRange("Record No.", ConfigPackageRecord."No.");
        exit(not ConfigPackageError.IsEmpty);
    end;

    local procedure IsRecordErrorsExistsInPrimaryKeyFields(ConfigPackageRecord: Record "Config. Package Record"): Boolean
    var
        ConfigPackageError: Record "Config. Package Error";
    begin
        ConfigPackageError.SetRange("Package Code", ConfigPackageRecord."Package Code");
        ConfigPackageError.SetRange("Table ID", ConfigPackageRecord."Table ID");
        ConfigPackageError.SetRange("Record No.", ConfigPackageRecord."No.");

        if ConfigPackageError.FindSet() then
            repeat
                if ConfigValidateMgt.IsKeyField(ConfigPackageError."Table ID", ConfigPackageError."Field ID") then
                    exit(true);
            until ConfigPackageError.Next() = 0;

        exit(false);
    end;

    procedure UpdateConfigLinePackageData(ConfigPackageCode: Code[20])
    var
        ConfigLine: Record "Config. Line";
        ConfigPackageData: Record "Config. Package Data";
        ShiftLineNo: BigInteger;
        ShiftVertNo: Integer;
        TempValue: BigInteger;
    begin
        ConfigLine.Reset();
        if not ConfigLine.FindLast() then
            exit;

        ShiftLineNo := ConfigLine."Line No." + 10000L;
        ShiftVertNo := ConfigLine."Vertical Sorting" + 1;

        ConfigPackageData.SetRange("Package Code", ConfigPackageCode);
        ConfigPackageData.SetRange("Table ID", Database::"Config. Line");
        ConfigPackageData.SetRange("Field ID", ConfigLine.FieldNo("Line No."));
        if ConfigPackageData.FindSet() then
            repeat
                if Evaluate(TempValue, ConfigPackageData.Value) then begin
                    ConfigPackageData.Value := Format(TempValue + ShiftLineNo);
                    ConfigPackageData.Modify();
                end;
            until ConfigPackageData.Next() = 0;
        ConfigPackageData.SetRange("Field ID", ConfigLine.FieldNo("Vertical Sorting"));
        if ConfigPackageData.FindSet() then
            repeat
                if Evaluate(TempValue, ConfigPackageData.Value) then begin
                    ConfigPackageData.Value := Format(TempValue + ShiftVertNo);
                    ConfigPackageData.Modify();
                end;
            until ConfigPackageData.Next() = 0;
    end;

    procedure HandlePackageDataDimSetIDForRecord(ConfigPackageRecord: Record "Config. Package Record")
    var
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageMgt: Codeunit "Config. Package Management";
        DimPackageDataExists: Boolean;
        DimSetID: Integer;
    begin
        DimSetID := ConfigPackageMgt.GetDimSetIDForRecord(ConfigPackageRecord);
        DimPackageDataExists :=
          GetDimPackageDataFromRecord(ConfigPackageData, ConfigPackageRecord);
        if DimSetID = 0 then begin
            if DimPackageDataExists then
                ConfigPackageData.Delete(true);
        end else
            if not DimPackageDataExists then
                CreateDimPackageDataFromRecord(ConfigPackageData, ConfigPackageRecord, DimSetID)
            else
                if ConfigPackageData.Value <> Format(DimSetID) then begin
                    ConfigPackageData.Value := Format(DimSetID);
                    ConfigPackageData.Modify();
                end;
    end;

    local procedure GetDimPackageDataFromRecord(var ConfigPackageData: Record "Config. Package Data"; ConfigPackageRecord: Record "Config. Package Record"): Boolean
    begin
        exit(
          ConfigPackageData.Get(
            ConfigPackageRecord."Package Code", ConfigPackageRecord."Table ID", ConfigPackageRecord."No.",
            Database::"Dimension Set Entry"));
    end;

    local procedure CreateDimPackageDataFromRecord(var ConfigPackageData: Record "Config. Package Data"; ConfigPackageRecord: Record "Config. Package Record"; DimSetID: Integer)
    var
        ConfigPackageField: Record "Config. Package Field";
    begin
        if ConfigPackageField.Get(ConfigPackageRecord."Package Code", ConfigPackageRecord."Table ID", Database::"Dimension Set Entry") then begin
            ConfigPackageField.Validate("Include Field", true);
            ConfigPackageField.Modify(true);
        end;

        ConfigPackageData.Init();
        ConfigPackageData."Package Code" := ConfigPackageRecord."Package Code";
        ConfigPackageData."Table ID" := ConfigPackageRecord."Table ID";
        ConfigPackageData."Field ID" := Database::"Dimension Set Entry";
        ConfigPackageData."No." := ConfigPackageRecord."No.";
        ConfigPackageData.Value := Format(DimSetID);
        ConfigPackageData.Insert();
    end;

    local procedure UpdateValueUsingMapping(var ConfigPackageData: Record "Config. Package Data"; ConfigPackageField: Record "Config. Package Field"; PackageCode: Code[20])
    var
        ConfigFieldMap: Record "Config. Field Map";
        NewValue: Text[2048];
    begin
        ConfigFieldMap.SetCurrentKey("Package Code", "Table ID", "Field ID", "Old Value");
        ConfigFieldMap.SetRange("Package Code", ConfigPackageData."Package Code");
        ConfigFieldMap.SetRange("Table ID", ConfigPackageField."Table ID");
        ConfigFieldMap.SetRange("Field ID", ConfigPackageField."Field ID");
        ConfigFieldMap.SetRange("Old Value", ConfigPackageData.Value);
        if ConfigFieldMap.FindFirst() then
            NewValue := ConfigFieldMap."New Value";

        if (NewValue = '') and (ConfigPackageField."Relation Table ID" <> 0) then
            NewValue := GetMappingFromPKOfRelatedTable(ConfigPackageField, ConfigPackageData.Value);

        if NewValue <> '' then begin
            ConfigPackageData.Validate(Value, NewValue);
            ConfigPackageData.Modify();
        end;

        if ConfigPackageField."Create Missing Codes" then
            CreateMissingCodes(ConfigPackageData, ConfigPackageField."Relation Table ID", PackageCode);
    end;

    local procedure CreateMissingCodes(var ConfigPackageData: Record "Config. Package Data"; RelationTableID: Integer; PackageCode: Code[20])
    var
        RecRef: RecordRef;
        FieldRef: array[16] of FieldRef;
        KeyRef: KeyRef;
        i: Integer;
    begin
        RecRef.Open(RelationTableID);
        KeyRef := RecRef.KeyIndex(1);
        for i := 1 to KeyRef.FieldCount do begin
            FieldRef[i] := KeyRef.FieldIndex(i);
            FieldRef[i].Value(RelatedKeyFieldValue(ConfigPackageData, RelationTableID, FieldRef[i].Number));
        end;

        // even "Create Missing Codes" is marked we should not create for blank account numbers and blank/zero account categories should not be created
        if ConfigPackageData."Table ID" <> 15 then begin
            if RecRef.Insert() then;
        end else
            if (ConfigPackageData.Value <> '') and ((ConfigPackageData.Value <> '0') and (ConfigPackageData."Field ID" = 80)) or
               ((PackageCode <> QBPackageCodeTxt) and (PackageCode <> MSGPPackageCodeTxt))
            then
                if RecRef.Insert() then;
    end;

    local procedure RelatedKeyFieldValue(var ConfigPackageData: Record "Config. Package Data"; TableID: Integer; FieldNo: Integer): Text[2048]
    var
        ConfigPackageDataOtherFields: Record "Config. Package Data";
        TableRelationsMetadata: Record "Table Relations Metadata";
    begin
        TableRelationsMetadata.SetRange("Table ID", ConfigPackageData."Table ID");
        TableRelationsMetadata.SetRange("Related Table ID", TableID);
        TableRelationsMetadata.SetRange("Related Field No.", FieldNo);
        if TableRelationsMetadata.FindFirst() then begin
            ConfigPackageDataOtherFields.Get(
              ConfigPackageData."Package Code", ConfigPackageData."Table ID", ConfigPackageData."No.", TableRelationsMetadata."Field No.");
            exit(ConfigPackageDataOtherFields.Value);
        end;

        TableRelationsMetadata.SetRange("Table ID", TableID);
        TableRelationsMetadata.SetRange("Field No.", FieldNo);
        TableRelationsMetadata.SetRange("Related Table ID", ConfigPackageData."Table ID");
        TableRelationsMetadata.SetRange("Related Field No.");
        if TableRelationsMetadata.FindFirst() then begin
            ConfigPackageDataOtherFields.Get(
              ConfigPackageData."Package Code", ConfigPackageData."Table ID",
              ConfigPackageData."No.", TableRelationsMetadata."Related Field No.");
            exit(ConfigPackageDataOtherFields.Value);
        end;

        exit(ConfigPackageData.Value);
    end;

    local procedure GetMappingFromPKOfRelatedTable(ConfigPackageField: Record "Config. Package Field"; MappingOldValue: Text[2048]): Text[2048]
    var
        ConfigPackageField2: Record "Config. Package Field";
        ConfigFieldMap: Record "Config. Field Map";
    begin
        ConfigPackageField2.SetRange("Package Code", ConfigPackageField."Package Code");
        ConfigPackageField2.SetRange("Table ID", ConfigPackageField."Relation Table ID");
        ConfigPackageField2.SetRange("Primary Key", true);
        if ConfigPackageField2.FindFirst() then begin
            ConfigFieldMap.SetCurrentKey("Package Code", "Table ID", "Field ID", "Old Value");
            ConfigFieldMap.SetRange("Package Code", ConfigPackageField2."Package Code");
            ConfigFieldMap.SetRange("Table ID", ConfigPackageField2."Table ID");
            ConfigFieldMap.SetRange("Field ID", ConfigPackageField2."Field ID");
            ConfigFieldMap.SetRange("Old Value", MappingOldValue);
            if ConfigFieldMap.FindFirst() then
                exit(ConfigFieldMap."New Value");
        end;
    end;

    procedure ShowFieldMapping(ConfigPackageField: Record "Config. Package Field")
    var
        ConfigFieldMap: Record "Config. Field Map";
        ConfigFieldMappingPage: Page "Config. Field Mapping";
    begin
        Clear(ConfigFieldMappingPage);
        ConfigFieldMap.FilterGroup(2);
        ConfigFieldMap.SetCurrentKey("Package Code", "Table ID", "Field ID", "Old Value");
        ConfigFieldMap.SetRange("Package Code", ConfigPackageField."Package Code");
        ConfigFieldMap.SetRange("Table ID", ConfigPackageField."Table ID");
        ConfigFieldMap.SetRange("Field ID", ConfigPackageField."Field ID");
        ConfigFieldMap.FilterGroup(0);
        ConfigFieldMappingPage.SetTableView(ConfigFieldMap);
        ConfigFieldMappingPage.RunModal();
    end;

    procedure IsBLOBField(TableId: Integer; FieldId: Integer): Boolean
    var
        "Field": Record "Field";
    begin
        if TypeHelper.GetField(TableId, FieldId, Field) then
            exit(Field.Type = Field.Type::BLOB);
        exit(false);
    end;

    local procedure IsBLOBFieldInternal(FieldType: Integer): Boolean
    var
        "Field": Record "Field";
    begin
        exit(FieldType = Field.Type::BLOB);
    end;

    local procedure EvaluateBLOBToFieldRef(var ConfigPackageData: Record "Config. Package Data"; var FieldRef: FieldRef)
    begin
        ConfigPackageData.CalcFields("BLOB Value");
        FieldRef.Value := ConfigPackageData."BLOB Value";
    end;

    procedure IsMediaSetField(TableId: Integer; FieldId: Integer): Boolean
    var
        "Field": Record "Field";
    begin
        if TypeHelper.GetField(TableId, FieldId, Field) then
            exit(Field.Type = Field.Type::MediaSet);
        exit(false);
    end;

    local procedure IsMediaSetFieldInternal(FieldType: Integer): Boolean
    var
        "Field": Record "Field";
    begin
        exit(FieldType = Field.Type::MediaSet);
    end;

    local procedure ImportMediaSetFiles(var ConfigPackageData: Record "Config. Package Data"; var FieldRef: FieldRef; DoModify: Boolean)
    var
        TempConfigMediaBuffer: Record "Config. Media Buffer" temporary;
        MediaSetIDConfigPackageData: Record "Config. Package Data";
        BlobMediaSetConfigPackageData: Record "Config. Package Data";
        BlobInStream: InStream;
        MediaSetID: Text;
    begin
        if not CanImportMediaField(ConfigPackageData, FieldRef, DoModify, MediaSetID) then
            exit;

        MediaSetIDConfigPackageData.SetRange("Package Code", ConfigPackageData."Package Code");
        MediaSetIDConfigPackageData.SetRange("Table ID", Database::"Config. Media Buffer");
        MediaSetIDConfigPackageData.SetRange("Field ID", TempConfigMediaBuffer.FieldNo("Media Set ID"));
        MediaSetIDConfigPackageData.SetRange(Value, MediaSetID);

        if not MediaSetIDConfigPackageData.FindSet() then
            exit;

        TempConfigMediaBuffer.Init();
        TempConfigMediaBuffer.Insert();
        BlobMediaSetConfigPackageData.SetAutoCalcFields("BLOB Value");

        repeat
            BlobMediaSetConfigPackageData.Get(
              MediaSetIDConfigPackageData."Package Code", MediaSetIDConfigPackageData."Table ID", MediaSetIDConfigPackageData."No.",
              TempConfigMediaBuffer.FieldNo("Media Blob"));
            BlobMediaSetConfigPackageData."BLOB Value".CreateInStream(BlobInStream);
            TempConfigMediaBuffer."Media Set".ImportStream(BlobInStream, '');
            TempConfigMediaBuffer.Modify();
        until MediaSetIDConfigPackageData.Next() = 0;

        FieldRef.Value := Format(TempConfigMediaBuffer."Media Set");
    end;

    procedure IsMediaField(TableId: Integer; FieldId: Integer): Boolean
    var
        "Field": Record "Field";
    begin
        if TypeHelper.GetField(TableId, FieldId, Field) then
            exit(Field.Type = Field.Type::Media);
        exit(false);
    end;

    local procedure IsMediaFieldInternal(FieldType: Integer): Boolean
    var
        "Field": Record "Field";
    begin
        exit(FieldType = Field.Type::Media);
    end;

    local procedure GetCachedConfigPackageField(ConfigPackageData: Record "Config. Package Data")
    var
        "Field": Record "Field";
    begin
        if not TempConfigPackageFieldCache.Get(ConfigPackageData."Package Code", ConfigPackageData."Table ID", ConfigPackageData."Field ID") then begin
            TempConfigPackageFieldCache.Init();
            TempConfigPackageFieldCache."Package Code" := ConfigPackageData."Package Code";
            TempConfigPackageFieldCache."Table ID" := ConfigPackageData."Table ID";
            TempConfigPackageFieldCache."Field ID" := ConfigPackageData."Field ID";
            if TypeHelper.GetField(TempConfigPackageFieldCache."Table ID", TempConfigPackageFieldCache."Field ID", Field) then
                TempConfigPackageFieldCache."Processing Order" := Field.Type;
            TempConfigPackageFieldCache.Insert();
        end;
    end;

    local procedure ImportMediaFiles(var ConfigPackageData: Record "Config. Package Data"; var FieldRef: FieldRef; DoModify: Boolean)
    var
        TempConfigMediaBuffer: Record "Config. Media Buffer" temporary;
        MediaIDConfigPackageData: Record "Config. Package Data";
        BlobMediaConfigPackageData: Record "Config. Package Data";
        BlobInStream: InStream;
        MediaID: Text;
    begin
        if not CanImportMediaField(ConfigPackageData, FieldRef, DoModify, MediaID) then
            exit;

        MediaIDConfigPackageData.SetRange("Package Code", ConfigPackageData."Package Code");
        MediaIDConfigPackageData.SetRange("Table ID", Database::"Config. Media Buffer");
        MediaIDConfigPackageData.SetRange("Field ID", TempConfigMediaBuffer.FieldNo("Media ID"));
        MediaIDConfigPackageData.SetRange(Value, MediaID);

        if not MediaIDConfigPackageData.FindFirst() then
            exit;

        BlobMediaConfigPackageData.SetAutoCalcFields("BLOB Value");

        BlobMediaConfigPackageData.Get(
          MediaIDConfigPackageData."Package Code", MediaIDConfigPackageData."Table ID", MediaIDConfigPackageData."No.",
          TempConfigMediaBuffer.FieldNo("Media Blob"));
        BlobMediaConfigPackageData."BLOB Value".CreateInStream(BlobInStream);

        TempConfigMediaBuffer.Init();
        TempConfigMediaBuffer.Media.ImportStream(BlobInStream, '');
        TempConfigMediaBuffer.Insert();

        FieldRef.Value := Format(TempConfigMediaBuffer.Media);
    end;

    local procedure CanImportMediaField(var ConfigPackageData: Record "Config. Package Data"; var FieldRef: FieldRef; DoModify: Boolean; var MediaID: Text): Boolean
    var
        RecRef: RecordRef;
        DummyNotInitializedGuid: Guid;
    begin
        if not DoModify then
            exit(false);

        RecRef := FieldRef.Record();
        if RecRef.Number = Database::"Config. Media Buffer" then
            exit(false);

        MediaID := Format(ConfigPackageData.Value);
        if (MediaID = Format(DummyNotInitializedGuid)) or (MediaID = '') then
            exit(false);

        exit(true);
    end;

    local procedure GetRecordIDOfRecordError(var ConfigPackageData: Record "Config. Package Data"): Text
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        RecordID: Text;
        KeyFieldCount: Integer;
        KeyFieldValNotEmpty: Boolean;
    begin
        if not ConfigPackageData.FindSet() then
            exit;

        RecRef.Open(ConfigPackageData."Table ID");
        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldCount := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(KeyFieldCount);

            if not ConfigPackageData.Get(ConfigPackageData."Package Code", ConfigPackageData."Table ID", ConfigPackageData."No.",
                 FieldRef.Number)
            then
                exit;

            if ConfigPackageData.Value <> '' then
                KeyFieldValNotEmpty := true;

            if KeyFieldCount = 1 then
                RecordID := RecRef.Name + ': ' + ConfigPackageData.Value
            else
                RecordID += ', ' + ConfigPackageData.Value;
        end;

        if not KeyFieldValNotEmpty then
            exit;

        exit(RecordID);
    end;

    local procedure IsTableErrorsExists(ConfigPackageTable: Record "Config. Package Table"): Boolean
    var
        ConfigPackageError: Record "Config. Package Error";
    begin
        if ConfigPackageTable."Table ID" = 27 then begin
            ConfigPackageError.SetRange("Package Code", ConfigPackageTable."Package Code");
            ConfigPackageError.SetRange("Table ID", ConfigPackageTable."Table ID");
            if ConfigPackageError.Find('-') then
                repeat
                    if StrPos(ConfigPackageError."Error Text", 'is a duplicate item number') > 0 then
                        exit(not ConfigPackageError.IsEmpty);
                until ConfigPackageError.Next() = 0;
        end
    end;

    procedure IsFieldMultiRelation(TableID: Integer; FieldID: Integer): Boolean
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
    begin
        TableRelationsMetadata.SetRange("Table ID", TableID);
        TableRelationsMetadata.SetRange("Field No.", FieldID);
        exit(TableRelationsMetadata.Count > 1);
    end;

    procedure ValidateFieldRefRelationAgainstCompanyData(FieldRef: FieldRef; var ConfigPackageFieldOrder: Record "Config. Package Field"): Text[250]
    begin
        exit(ValidateFieldRefRelationAgainstCompanyDataAndPackage(FieldRef, ConfigPackageFieldOrder, ''));
    end;

    local procedure ValidateFieldRefRelationAgainstCompanyDataAndPackage(FieldRef: FieldRef; var ConfigPackageFieldOrder: Record "Config. Package Field"; PackageCode: Code[20]): Text[250];
    var
        ConfigTryValidate: Codeunit "Config. Try Validate";
        RecRef: RecordRef;
        RecRef2: RecordRef;
        FieldRef2: FieldRef;
    begin
        RecRef := FieldRef.Record();

        RecRef2.Open(RecRef.Number, true);
        CopyRecRefFields(PackageCode, RecRef2, RecRef, FieldRef, ConfigPackageFieldOrder);
        RecRef2.Insert();

        FieldRef2 := RecRef2.Field(FieldRef.Number);

        ConfigTryValidate.SetValidateParameters(FieldRef2, FieldRef.Value);

        Commit();
        if not ConfigTryValidate.Run() then
            exit(CopyStr(GetLastErrorText, 1, 250));

        exit('');
    end;

    local procedure CopyRecRefFields(PackageCode: Code[20]; RecRef: RecordRef; SourceRecRef: RecordRef; FieldRefToExclude: FieldRef; var ConfigPackageFieldOrder: Record "Config. Package Field")
    var
        FieldRef: FieldRef;
        SourceFieldRef: FieldRef;
    begin
        ConfigPackageFieldOrder.Reset();
        ConfigPackageFieldOrder.SetCurrentKey("Package Code", "Table ID", "Processing Order");
        if PackageCode <> '' then
            ConfigPackageFieldOrder.SetRange("Package Code", PackageCode);
        ConfigPackageFieldOrder.SetRange("Table ID", RecRef.Number);
        if ConfigPackageFieldOrder.FindSet() then
            repeat
                SourceFieldRef := SourceRecRef.Field(ConfigPackageFieldOrder."Field ID");
                if FieldRefToExclude.Name = SourceFieldRef.Name then
                    exit;
                FieldRef := RecRef.Field(ConfigPackageFieldOrder."Field ID");
                FieldRef.Value := SourceFieldRef.Value();
            until ConfigPackageFieldOrder.Next() = 0;
    end;

    local procedure IsImportAllowed(TableId: Integer): Boolean
    begin
        exit(not (TableId in [Database::Microsoft.Integration.SyncEngine."Integration Table Mapping", Database::Microsoft.Integration.SyncEngine."Integration Field Mapping",
                                Database::Microsoft.Integration.Entity."Sales Invoice Entity Aggregate", Database::Microsoft.Integration.Entity."Sales Order Entity Buffer",
                                Database::Microsoft.Integration.Entity."Sales Quote Entity Buffer", Database::Microsoft.Integration.Entity."Sales Cr. Memo Entity Buffer",
                                Database::Microsoft.Integration.Entity."Purch. Inv. Entity Aggregate", Database::Microsoft.Integration.Entity."Purch. Cr. Memo Entity Buffer"]));

    end;

    [EventSubscriber(ObjectType::Table, Database::"Config. Package", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure SendTelemetryOnDeleteConfigPackage(RunTrigger: Boolean; var Rec: Record "Config. Package")
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        Dimensions.Add('Category', RapidStartTxt);
        Dimensions.Add('PackageCode', Rec.SystemId);
        Session.LogMessage('0000E3P', StrSubstNo(ConfigurationPackageDeletedMsg, Rec.SystemId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyPackageRecords(var ConfigPackageRecord: Record "Config. Package Record"; PackageCode: Code[20]; TableNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetKeyFieldsOrder(RecordRef: RecordRef; PackageCode: Code[20]; var TempConfigPackageField: Record "Config. Package Field" temporary; var ValidationFieldID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePackageDataRelation(ConfigPackageData: Record "Config. Package Data"; ConfigPackageField: Record "Config. Package Field"; var ConfigPackageTable: Record "Config. Package Table"; var RelationTableNo: Integer; var RelationFieldNo: Integer; var DataInPackageData: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFieldRelationTableNo(ConfigPackageTable: Record "Config. Package Table"; var "Field": Record "Field"; var TempConfigPackageTable: Record "Config. Package Table" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetFieldFilter(var "Field": Record "Field"; TableID: Integer; FieldID: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyPackageRecords(var ConfigPackageRecord: Record "Config. Package Record"; var PackageCode: Code[20]; var TableNo: Integer; var ApplyMode: Option; var ConfigPackageManagement: Codeunit "Config. Package Management"; var TempAppliedConfigPackageRecord: Record "Config. Package Record" temporary; var ProcessingRuleIsSet: Boolean; var TempConfigRecordForProcessing: Record "Config. Record For Processing" temporary; var ConfigTableProcessingRule: Record "Config. Table Processing Rule"; var RecordsInsertedCount: Integer; var RecordsModifiedCount: Integer; var HideDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyRecordDataFields(var RecRef: RecordRef; ConfigPackageRecord: Record "Config. Package Record"; DoModify: Boolean; DelayedInsert: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetupProcessingOrder(var ConfigPackageTable: Record "Config. Package Table"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateException(TableID: Integer; FieldID: Integer; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyRecordDataFieldOnBeforeEvaluateTextToFieldRef(var ConfigPackageField: Record "Config. Package Field"; var ConfigPackageData: Record "Config. Package Data"; var ConfigPackageTable: Record "Config. Package Table"; DelayedInsert: Boolean; ApplyMode: Option; FieldRef: FieldRef; var SkipEvaluate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyRecordDataFieldOnBeforeUpdateValueUsingMapping(var ConfigPackageData: Record "Config. Package Data"; var ConfigPackageField: Record "Config. Package Field"; ConfigPackageRecord: Record "Config. Package Record"; var RecordRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyRecordDataFieldsOnBeforeFindConfigPackageField(var ConfigPackageField: Record "Config. Package Field"; ConfigPackageRecord: Record "Config. Package Record"; RecRef: RecordRef; DoModify: Boolean; DelayedInsert: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnPreProcessPackage(var ConfigRecordForProcessing: Record "Config. Record For Processing"; var Subscriber: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnPostProcessPackage()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyRecordDataFieldsOnAfterRecRefModify(var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyRecordDataFieldsOnAfterRecRefUpdated(var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPackageFieldOnAfterCalcSkipRelationTableID(var ConfigPackageField: Record "Config. Package Field"; var SkipRelationTableID: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPackageFieldOnBeforeInsert(var ConfigPackageField: Record "Config. Package Field")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPackageFieldOnBeforeValidateFieldID(var ConfigPackageField: Record "Config. Package Field")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertRecordOnBeforeInsertRecRef(var RecRef: RecordRef; ConfigPackageRecord: Record "Config. Package Record"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyRecordDataFieldsOnBeforeRecRefInsert(var RecRef: RecordRef; ConfigPackageTable: Record "Config. Package Table"; var IsHandled: Boolean; ConfigPackageRecord: Record "Config. Package Record")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyRecordDataFieldsOnBeforeRecRefModify(var RecRef: RecordRef; ConfigPackageTable: Record "Config. Package Table"; var RecordsModifiedCount: Integer; var IsHandled: Boolean; ConfigPackageRecord: Record "Config. Package Record")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyRecordDataFieldOnAfterGetCachedConfigPackageField(var RecordRef: RecordRef; var FieldRef: FieldRef; var ConfigPackageField: Record "Config. Package Field"; var ConfigPackageData: Record "Config. Package Data"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyPackageOnBeforeCleanPackageErrors(var ConfigPackage: Record "Config. Package"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyPackageTablesOnFilterConfigPackageRecord(var ConfigPackage: Record "Config. Package"; var ConfigPackageRecord: Record "Config. Package Record")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPackageRecordOnAfterDelayedInsert(var RecordRef: RecordRef; ConfigPackageRecord: Record "Config. Package Record"; ConfigPackageTable: Record "Config. Package Table"; var ApplyMode: Option; DelayedInsert: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPrimaryKeyFieldsOnBeforeUpdateValueUsingMapping(var RecordRef: RecordRef; ConfigPackageData: Record "Config. Package Data"; var ConfigPackageField: Record "Config. Package Field"; ConfigPackageRecord: Record "Config. Package Record"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyPackageOnAfterCommit(var ConfigPackageTable: Record "Config. Package Table")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddConfigTablesOnBeforeSetSkipTableTriggers(var ConfigPackageTable: Record "Config. Package Table"; var PackageCode: Code[20])
    begin
    end;
}

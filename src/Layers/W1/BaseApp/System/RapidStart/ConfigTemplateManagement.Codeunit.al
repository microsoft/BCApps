namespace System.IO;

using System.Reflection;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 8612 "Config. Template Management"
{

    trigger OnRun()
    begin
    end;

    var
        HierarchyErr: Label 'The template %1 is in this hierarchy and contains the same field.', Comment = '%1 - Field Value';
        NoSeriesErr: Label 'A number series has not been set up for table %1 %2. The instance could not be created.', Comment = '%1 = Table ID, %2 = Table caption';
#pragma warning disable AA0470
        InstanceErr: Label 'The instance %1 already exists in table %2 %3.', Comment = '%2 = Table ID, %3 = Table caption';
#pragma warning restore AA0470
        KeyFieldValueErr: Label 'The value for the key field %1 is not filled for the instance.', Comment = '%1 - Field Name';
        UpdatingRelatedTable: Boolean;

    procedure UpdateFromTemplateSelection(var RecRef: RecordRef)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateFromTemplateSelection(ConfigTemplateHeader, RecRef, IsHandled);
        if IsHandled then
            exit;

        ConfigTemplateHeader.SetRange("Table ID", RecRef.Number);
        if PAGE.RunModal(PAGE::"Config. Template List", ConfigTemplateHeader, ConfigTemplateHeader.Code) = ACTION::LookupOK then
            UpdateRecord(ConfigTemplateHeader, RecRef);
    end;

    procedure UpdateRecord(ConfigTemplateHeader: Record "Config. Template Header"; var RecRef: RecordRef)
    var
        TempDummyField: Record "Field" temporary;
        SkipFieldValidation: Boolean;
    begin
        OnBeforeUpdateWithSkipFields(SkipFieldValidation, RecRef, TempDummyField);
        UpdateRecordWithSkipFields(ConfigTemplateHeader, RecRef, SkipFieldValidation, TempDummyField);
    end;

    local procedure UpdateRecordWithSkipFields(ConfigTemplateHeader: Record "Config. Template Header"; var RecRef: RecordRef; SkipFields: Boolean; var TempSkipFields: Record "Field" temporary)
    begin
        if TestKeyFields(RecRef, ConfigTemplateHeader) then
            InsertTemplate(RecRef, ConfigTemplateHeader, SkipFields, TempSkipFields)
        else begin
            InsertRecordWithKeyFields(RecRef, ConfigTemplateHeader);
            if TestKeyFields(RecRef, ConfigTemplateHeader) then
                InsertTemplate(RecRef, ConfigTemplateHeader, SkipFields, TempSkipFields)
            else
                Error(NoSeriesErr, RecRef.Number, RecRef.Caption);
        end;

        OnAfterUpdateRecordWithSkipFields(ConfigTemplateHeader, RecRef, SkipFields, TempSkipFields);
    end;

    procedure InsertTemplate(var RecRef: RecordRef; ConfigTemplateHeader: Record "Config. Template Header"; SkipFields: Boolean; var TempSkipField: Record "Field")
    var
        ConfigTemplateLine: Record "Config. Template Line";
        ConfigTemplateHeader2: Record "Config. Template Header";
#if CLEAN25
        ConfigValidateMgt: Codeunit "Config. Validate Management";
#endif
        FieldRef: FieldRef;
        RecRef2: RecordRef;
        SkipCurrentField: Boolean;
        FieldIsModified: Boolean;
        IsHandled: Boolean;
        IsNotSkipped: Boolean;
    begin
        OnBeforeInsertTemplate(ConfigTemplateLine, ConfigTemplateHeader);
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
        if ConfigTemplateLine.FindSet() then
            repeat
                case ConfigTemplateLine.Type of
                    ConfigTemplateLine.Type::Field:
                        if ConfigTemplateLine."Field ID" <> 0 then begin
                            if SkipFields then
                                SkipCurrentField := ShouldSkipField(TempSkipField, ConfigTemplateLine."Field ID", ConfigTemplateLine."Table ID")
                            else
                                SkipCurrentField := false;

                            if not SkipCurrentField then begin
                                FieldRef := RecRef.Field(ConfigTemplateLine."Field ID");

                                IsHandled := false;
                                OnInsertTemplateBeforeValidateFieldValue(RecRef, FieldRef, ConfigTemplateLine."Default Value", ConfigTemplateLine."Language ID", IsHandled, ConfigTemplateLine);
                                if not IsHandled then begin
#if CLEAN25
                                    ConfigValidateMgt.ValidateFieldValue(RecRef, FieldRef, ConfigTemplateLine."Default Value", false, ConfigTemplateLine."Language ID");                                    
#else
                                    IsNotSkipped := ValidateFieldValue(RecRef, FieldRef, ConfigTemplateLine);
#endif
                                    FieldIsModified := IsNotSkipped or FieldIsModified;
                                end;
                            end;
                        end;
                    ConfigTemplateLine.Type::Template:
                        if ConfigTemplateLine."Template Code" <> '' then
                            if ConfigTemplateHeader2.Get(ConfigTemplateLine."Template Code") then
                                if ConfigTemplateHeader2."Table ID" = ConfigTemplateHeader."Table ID" then
                                    InsertTemplate(RecRef, ConfigTemplateHeader2, SkipFields, TempSkipField)
                                else begin
                                    UpdatingRelatedTable := true;
                                    RecRef2.Open(ConfigTemplateHeader2."Table ID");
                                    UpdateRecord(ConfigTemplateHeader2, RecRef2);
                                    UpdatingRelatedTable := false;
                                end;
                    else
                        OnInsertTemplateCaseElse(ConfigTemplateLine, ConfigTemplateHeader2, FieldRef, RecRef2, SkipFields, TempSkipField, RecRef);
                end;
            until ConfigTemplateLine.Next() = 0;

        IsHandled := false;
        OnAfterInsertTemplateBeforeModify(ConfigTemplateLine, ConfigTemplateHeader, FieldIsModified, IsHandled);

        if IsHandled then
            exit;

        if FieldIsModified then
            RecRef.Modify(true);
    end;

    procedure ApplyTemplate(var OriginalRecRef: RecordRef; var TempFieldsAssigned: Record "Field" temporary; var TemplateAppliedRecRef: RecordRef; var ConfigTemplateHeader: Record "Config. Template Header"): Boolean
    var
        BackupRecRef: RecordRef;
        AssignedFieldRef: FieldRef;
        APIFieldRef: FieldRef;
        SkipFields: Boolean;
    begin
        TempFieldsAssigned.Reset();
        SkipFields := TempFieldsAssigned.FindSet();

        BackupRecRef := OriginalRecRef.Duplicate();
        TemplateAppliedRecRef := OriginalRecRef.Duplicate();

        UpdateRecordWithSkipFields(ConfigTemplateHeader, TemplateAppliedRecRef, SkipFields, TempFieldsAssigned);

        // Assign values set back in case validating unrelated field has modified them
        if SkipFields then
            repeat
                AssignedFieldRef := BackupRecRef.Field(TempFieldsAssigned."No.");
                APIFieldRef := TemplateAppliedRecRef.Field(TempFieldsAssigned."No.");
                APIFieldRef.Value := AssignedFieldRef.Value();
            until TempFieldsAssigned.Next() = 0;

        exit(true);
    end;

#if not CLEAN25
    local procedure ValidateFieldValue(var RecRef: RecordRef; FieldRef: FieldRef; ConfigTemplateLine: Record "Config. Template Line"): Boolean
    var
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeModifyRecordWithField(RecRef, FieldRef, ConfigTemplateLine."Default Value", ConfigTemplateLine."Language ID", IsHandled, ConfigTemplateLine);
        if IsHandled then
            exit(false);

        ConfigValidateMgt.ValidateFieldValue(RecRef, FieldRef, ConfigTemplateLine."Default Value", false, ConfigTemplateLine."Language ID");
        exit(true);
    end;
#endif

    local procedure TestKeyFields(var RecRef: RecordRef; ConfigTemplateHeader: Record "Config. Template Header") Result: Boolean
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        KeyFieldCount: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestKeyFields(RecRef, ConfigTemplateHeader, Result, IsHandled);
        if IsHandled then
            exit;

        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldCount := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(KeyFieldCount);
            if Format(FieldRef.Value) = '' then
                exit(false);
        end;
        exit(true);
    end;

    procedure TestHierarchy(ConfigTemplateLine: Record "Config. Template Line")
    var
        TempConfigTemplateLine: Record "Config. Template Line" temporary;
    begin
        GetHierarchicalLines(TempConfigTemplateLine, ConfigTemplateLine);
        TempConfigTemplateLine.SetFilter("Field ID", '>%1', 0);
        // exclude config. lines not handled yet
        if TempConfigTemplateLine.FindSet() then
            repeat
                TempConfigTemplateLine.SetRange("Field ID", TempConfigTemplateLine."Field ID");
                TempConfigTemplateLine.SetRange("Table ID", TempConfigTemplateLine."Table ID");
                if TempConfigTemplateLine.Count > 1 then
                    Error(HierarchyErr, TempConfigTemplateLine."Data Template Code");
                TempConfigTemplateLine.DeleteAll();
                TempConfigTemplateLine.SetFilter("Field ID", '>%1', 0);
            until TempConfigTemplateLine.Next() = 0;
    end;

    local procedure GetHierarchicalLines(var ConfigTemplateLineBuf: Record "Config. Template Line"; ConfigTemplateLine: Record "Config. Template Line")
    var
        SubConfigTemplateLine: Record "Config. Template Line";
        CurrConfigTemplateLine: Record "Config. Template Line";
    begin
        CurrConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateLine."Data Template Code");
        if CurrConfigTemplateLine.FindSet() then
            repeat
                // get current version of record because it's may not be in DB yet
                if CurrConfigTemplateLine."Line No." = ConfigTemplateLine."Line No." then
                    CurrConfigTemplateLine := ConfigTemplateLine;
                if CurrConfigTemplateLine.Type = CurrConfigTemplateLine.Type::Field then begin
                    ConfigTemplateLineBuf := CurrConfigTemplateLine;
                    if not ConfigTemplateLineBuf.Find() then
                        ConfigTemplateLineBuf.Insert();
                end else begin
                    SubConfigTemplateLine.Init();
                    SubConfigTemplateLine."Data Template Code" := CurrConfigTemplateLine."Template Code";
                    GetHierarchicalLines(ConfigTemplateLineBuf, SubConfigTemplateLine);
                end;
            until CurrConfigTemplateLine.Next() = 0;
    end;

    local procedure InsertRecordWithKeyFields(var RecRef: RecordRef; ConfigTemplateHeader: Record "Config. Template Header")
    var
        ConfigTemplateLine: Record "Config. Template Line";
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        RecRef1: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        KeyFieldCount: Integer;
        MessageString: Text[250];
    begin
        OnBeforeInsertRecordWithKeyFields(RecRef, ConfigTemplateHeader);
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);

        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldCount := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(KeyFieldCount);
            ConfigTemplateLine.SetRange("Field ID", FieldRef.Number);
            if ConfigTemplateLine.FindFirst() then begin
                OnInsertRecordWithKeyFieldsOnBeforeValidateFieldValue(ConfigTemplateHeader, ConfigTemplateLine);
                ConfigValidateMgt.ValidateFieldValue(
                  RecRef, FieldRef, ConfigTemplateLine."Default Value", false, ConfigTemplateLine."Language ID");
            end
            else
                if KeyRef.FieldCount <> 1 then
                    Error(KeyFieldValueErr, FieldRef.Name);
        end;

        RecRef1 := RecRef.Duplicate();

        if RecRef1.Find('=') then begin
            if UpdatingRelatedTable then
                exit;
            MessageString := MessageString + ' ' + Format(FieldRef.Value);
            MessageString := DelChr(MessageString, '<');
            Error(InstanceErr, MessageString, RecRef.Number, RecRef.Caption);
        end;

        OnInsertRecordWithKeyFieldsOnBeforeRecRefInsert(RecRef);
        RecRef.Insert(true);
    end;

    procedure SetUpdatingRelatedTable(NewUpdatingRelatedTable: Boolean)
    begin
        UpdatingRelatedTable := NewUpdatingRelatedTable;
    end;

    procedure CreateConfigTemplateAndLines(var "Code": Code[10]; Description: Text[100]; TableID: Integer; DefaultValuesFieldRefArray: array[100] of FieldRef)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        FieldRef: FieldRef;
        I: Integer;
    begin
        ConfigTemplateHeader.Init();

        if Code = '' then
            Code := GetNextAvailableCode(TableID);

        ConfigTemplateHeader.Code := Code;
        ConfigTemplateHeader.Description := Description;
        ConfigTemplateHeader."Table ID" := TableID;
        OnCreateConfigTemplateAndLinesOnBeforeConfigTemplateHeaderInsert(ConfigTemplateHeader);
        ConfigTemplateHeader.Insert(true);

        for I := 1 to ArrayLen(DefaultValuesFieldRefArray) do begin
            FieldRef := DefaultValuesFieldRefArray[I];
            InsertConfigTemplateLineFromField(Code, FieldRef, TableID);
        end;
    end;

    procedure UpdateConfigTemplateAndLines("Code": Code[10]; Description: Text[100]; TableID: Integer; DefaultValuesFieldRefArray: array[100] of FieldRef)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        FieldRef: FieldRef;
        I: Integer;
    begin
        ConfigTemplateHeader.Get(Code);
        ConfigTemplateHeader.Description := Description;
        ConfigTemplateHeader.Modify();

        for I := 1 to ArrayLen(DefaultValuesFieldRefArray) do begin
            FieldRef := DefaultValuesFieldRefArray[I];
            UpdateConfigTemplateLines(Code, FieldRef, TableID);
        end;
    end;

    procedure ApplyTemplateLinesWithoutValidation(ConfigTemplateHeader: Record "Config. Template Header"; var RecordRef: RecordRef)
    var
        ConfigTemplateLine: Record "Config. Template Line";
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        FieldRef: FieldRef;
    begin
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
        if ConfigTemplateLine.FindSet() then
            repeat
                if ConfigTemplateLine.Type = ConfigTemplateLine.Type::Field then
                    if RecordRef.FieldExist(ConfigTemplateLine."Field ID") then begin
                        FieldRef := RecordRef.Field(ConfigTemplateLine."Field ID");
                        OnApplyTemplateLinesWithoutValidationOnBeforeValidateFieldValue(ConfigTemplateHeader, ConfigTemplateLine);
                        ConfigValidateMgt.ValidateFieldValue(
                          RecordRef, FieldRef, ConfigTemplateLine."Default Value", true, ConfigTemplateLine."Language ID");
                        RecordRef.Modify(false);
                        OnApplyTemplLinesWithoutValidationAfterRecRefCheck(ConfigTemplateHeader, ConfigTemplateLine, RecordRef);
                    end;
            until ConfigTemplateLine.Next() = 0;
    end;

    procedure GetNextAvailableCode(TableID: Integer): Code[10]
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        NextCode: Code[10];
        TplExists: Boolean;
    begin
        ConfigTemplateHeader.SetRange("Table ID", TableID);
        TplExists := ConfigTemplateHeader.FindLast();

        if TplExists and (IncStr(ConfigTemplateHeader.Code) <> '') then
            NextCode := ConfigTemplateHeader.Code
        else begin
            ConfigTemplateHeader."Table ID" := TableID;
            ConfigTemplateHeader.CalcFields("Table Caption");
            NextCode := CopyStr(ConfigTemplateHeader."Table Caption", 1, 4) + '000001';
        end;

        while ConfigTemplateHeader.Get(NextCode) do
            NextCode := IncStr(NextCode);

        exit(NextCode);
    end;

    procedure AddRelatedTemplate("Code": Code[10]; RelatedTemplateCode: Code[10])
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateLine.SetRange("Data Template Code", Code);
        ConfigTemplateLine.SetRange(Type, ConfigTemplateLine.Type::"Related Template");
        ConfigTemplateLine.SetRange("Template Code", RelatedTemplateCode);

        if not ConfigTemplateLine.IsEmpty() then
            exit;

        Clear(ConfigTemplateLine);
        ConfigTemplateLine."Data Template Code" := Code;
        ConfigTemplateLine."Template Code" := RelatedTemplateCode;
        ConfigTemplateLine."Line No." := GetNextLineNo(Code);
        ConfigTemplateLine.Type := ConfigTemplateLine.Type::"Related Template";
        ConfigTemplateLine.Insert(true);
    end;

    procedure RemoveRelatedTemplate("Code": Code[10]; RelatedTemplateCode: Code[10])
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateLine.SetRange("Data Template Code", Code);
        ConfigTemplateLine.SetRange(Type, ConfigTemplateLine.Type::"Related Template");
        ConfigTemplateLine.SetRange("Template Code", RelatedTemplateCode);

        if ConfigTemplateLine.FindFirst() then
            ConfigTemplateLine.Delete(true);
    end;

    procedure DeleteRelatedTemplates(ConfigTemplateHeaderCode: Code[10]; TableID: Integer)
    var
        ConfigTemplateLine: Record "Config. Template Line";
        RelatedConfigTemplateHeader: Record "Config. Template Header";
    begin
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeaderCode);
        ConfigTemplateLine.SetRange(Type, ConfigTemplateLine.Type::"Related Template");

        if ConfigTemplateLine.FindSet() then
            repeat
                RelatedConfigTemplateHeader.Get(ConfigTemplateLine."Template Code");
                if RelatedConfigTemplateHeader."Table ID" = TableID then begin
                    RelatedConfigTemplateHeader.Delete(true);
                    ConfigTemplateLine.Delete(true);
                end;
            until ConfigTemplateLine.Next() = 0;
    end;

    procedure ReplaceDefaultValueForAllTemplates(TableID: Integer; FieldID: Integer; DefaultValue: Text[250])
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateHeader.SetRange("Table ID", TableID);
        if ConfigTemplateHeader.FindSet() then
            repeat
                ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
                ConfigTemplateLine.SetRange("Field ID", FieldID);
                ConfigTemplateLine.DeleteAll();
                InsertConfigTemplateLine(ConfigTemplateHeader.Code, FieldID, DefaultValue, TableID);
            until ConfigTemplateHeader.Next() = 0;
    end;

    procedure InsertConfigTemplateLineFromField(ConfigTemplateHeaderCode: Code[10]; FieldRef: FieldRef; TableID: Integer)
    var
        DummyConfigTemplateLine: Record "Config. Template Line";
    begin
        if IsNotInitializedFieldRef(FieldRef) then
            exit;

        DummyConfigTemplateLine."Default Value" := FieldRef.Value();
        InsertConfigTemplateLine(ConfigTemplateHeaderCode, FieldRef.Number, DummyConfigTemplateLine."Default Value", TableID);
    end;

    procedure InsertConfigTemplateLine(ConfigTemplateHeaderCode: Code[10]; FieldID: Integer; DefaultValue: Text[2048]; TableID: Integer)
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateLine.Init();
        ConfigTemplateLine."Data Template Code" := ConfigTemplateHeaderCode;
        ConfigTemplateLine.Type := ConfigTemplateLine.Type::Field;
        ConfigTemplateLine."Line No." := GetNextLineNo(ConfigTemplateHeaderCode);
        ConfigTemplateLine."Field ID" := FieldID;
        ConfigTemplateLine."Table ID" := TableID;
        ConfigTemplateLine."Default Value" := DefaultValue;

        ConfigTemplateLine.Insert(true);
    end;

    local procedure GetNextLineNo(ConfigTemplateHeaderCode: Code[10]): Integer
    var
        ConfigTemplateLine: Record "Config. Template Line";
    begin
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeaderCode);
        if ConfigTemplateLine.FindLast() then
            exit(ConfigTemplateLine."Line No." + 10000);

        exit(10000);
    end;

    procedure RemoveEmptyFieldsFromTemplateHeader(var RecRef: RecordRef; ConfigTemplateHeader: Record "Config. Template Header")
    var
        ConfigTemplateLine: Record "Config. Template Line";
        FieldRef: FieldRef;
    begin
        ConfigTemplateLine.SetRange("Data Template Code", ConfigTemplateHeader.Code);
        if ConfigTemplateLine.FindSet() then
            repeat
                if ConfigTemplateLine.Type = ConfigTemplateLine.Type::Field then
                    if ConfigTemplateLine."Field ID" <> 0 then begin
                        FieldRef := RecRef.Field(ConfigTemplateLine."Field ID");
                        if Format(FieldRef.Value) = '' then
                            ConfigTemplateLine.Delete();
                    end;
            until ConfigTemplateLine.Next() = 0;
    end;

    local procedure ShouldSkipField(var TempSkipField: Record "Field"; CurrentFieldNo: Integer; CurrentTableNo: Integer): Boolean
    begin
        TempSkipField.Reset();
        exit(TempSkipField.Get(CurrentTableNo, CurrentFieldNo));
    end;

    [Scope('OnPrem')]
    procedure LookupFieldValueFromConfigTemplateLine(ConfigTemplateLine: Record "Config. Template Line"; var FieldValue: Text): Boolean
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        RecVar: Variant;
        LookupTableId: Integer;
        LookupPageId: Integer;
        LookupFieldId: Integer;
    begin
        GetLookupParameters(ConfigTemplateLine, LookupTableId, LookupPageId, LookupFieldId);
        if (LookupTableId = 0) or (LookupPageId = 0) or (LookupFieldId = 0) then
            exit(false);

        RecRef.Open(LookupTableId);
        if LookupTableId = Database::"Dimension Value" then
            SetDimensionFilter(ConfigTemplateLine, FieldRef, RecRef);

        RecVar := RecRef;
        if PAGE.RunModal(LookupPageId, RecVar) = ACTION::LookupOK then begin
            RecRef.GetTable(RecVar);
            FieldRef := RecRef.Field(LookupFieldId);
            FieldValue := Format(FieldRef.Value);
            exit(true);
        end;

        exit(false);
    end;

    local procedure SetDimensionFilter(ConfigTemplateLine: Record "Config. Template Line"; var FieldRef: FieldRef; var RecRef: RecordRef)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if ConfigTemplateLine."Field Name" = GeneralLedgerSetup.FieldName("Global Dimension 1 Code") then begin
            FieldRef := RecRef.Field(1);
            FieldRef.SetFilter(GeneralLedgerSetup."Global Dimension 1 Code");
        end;
        if ConfigTemplateLine."Field Name" = GeneralLedgerSetup.FieldName("Global Dimension 2 Code") then begin
            FieldRef := RecRef.Field(1);
            FieldRef.SetFilter(GeneralLedgerSetup."Global Dimension 2 Code");
        end;
    end;

    local procedure GetLookupParameters(ConfigTemplateLine: Record "Config. Template Line"; var LookupTableId: Integer; var LookupPageId: Integer; var LookupFieldId: Integer)
    var
        TableMetadata: Record "Table Metadata";
        TableRelationsMetadata: Record "Table Relations Metadata";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        TableRelationsMetadata.SetRange("Table ID", ConfigTemplateLine."Table ID");
        TableRelationsMetadata.SetRange("Field No.", ConfigTemplateLine."Field ID");
        if TableRelationsMetadata.IsEmpty() then
            exit;

        RecRef.Open(ConfigTemplateLine."Table ID");
        if TableRelationsMetadata.Count > 1 then
            ApplyConfigTemplateLineValues(ConfigTemplateLine, RecRef);

        FieldRef := RecRef.Field(ConfigTemplateLine."Field ID");
        if not TableMetadata.Get(FieldRef.Relation) then
            exit;
        LookupTableId := TableMetadata.ID;
        LookupPageId := TableMetadata.LookupPageID;

        TableRelationsMetadata.SetRange("Related Table ID", TableMetadata.ID);
        if not TableRelationsMetadata.FindFirst() then
            exit;
        LookupFieldId := TableRelationsMetadata."Related Field No.";
    end;

    local procedure ApplyConfigTemplateLineValues(SourceConfigTemplateLine: Record "Config. Template Line"; RecRef: RecordRef)
    var
        ConfigTemplateLine: Record "Config. Template Line";
        "Field": Record "Field";
        TypeHelper: Codeunit "Type Helper";
        FieldRef: FieldRef;
    begin
        ConfigTemplateLine.SetRange("Data Template Code", SourceConfigTemplateLine."Data Template Code");
        ConfigTemplateLine.SetFilter("Field ID", '<>%1', SourceConfigTemplateLine."Field ID");
        if ConfigTemplateLine.FindSet() then
            repeat
                FieldRef := RecRef.Field(ConfigTemplateLine."Field ID");
                Field.Get(ConfigTemplateLine."Table ID", ConfigTemplateLine."Field ID");
                if Field.Type <> Field.Type::Option then
                    FieldRef.Value(ConfigTemplateLine."Default Value")
                else
                    FieldRef.Value(
                      TypeHelper.GetOptionNo(ConfigTemplateLine."Default Value", FieldRef.OptionMembers));
            until ConfigTemplateLine.Next() = 0;
    end;

    local procedure UpdateConfigTemplateLines(Code: Code[10]; FieldRef: FieldRef; TableID: Integer)
    var
        ConfigTemplateLine: Record "Config. Template Line";
        Value: Text[2048];
    begin
        if IsNotInitializedFieldRef(FieldRef) then
            exit;

        ConfigTemplateLine.SetFilter("Data Template Code", Code);
        ConfigTemplateLine.SetFilter(Type, '=%1', ConfigTemplateLine.Type::Field);
        ConfigTemplateLine.SetFilter("Field ID", '=%1', FieldRef.Number);
        ConfigTemplateLine.SetFilter("Table ID", '=%1', TableID);

        if ConfigTemplateLine.FindLast() then begin
            Value := Format(FieldRef.Value);
            if Value <> ConfigTemplateLine."Default Value" then begin
                ConfigTemplateLine."Default Value" := Value;
                ConfigTemplateLine."Language ID" := GlobalLanguage;
                ConfigTemplateLine.Modify(true);
            end;
        end else
            InsertConfigTemplateLineFromField(Code, FieldRef, TableID);
    end;

    local procedure IsNotInitializedFieldRef(FieldRef: FieldRef) Resul: Boolean
    var
        LastErrorCode: Text;
    begin
        if not TryGetFieldNumberFromFieldRef(FieldRef) then begin
            LastErrorCode := GetLastErrorCode;
            Resul := LastErrorCode = 'NotInitialized';
        end;

        OnAfterIsNotInitializedFieldRef(FieldRef, Resul);
    end;

    [TryFunction]
    local procedure TryGetFieldNumberFromFieldRef(FieldRef: FieldRef)
    var
        FieldNumber: Integer;
    begin
        FieldNumber := FieldRef.Number;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsNotInitializedFieldRef(FieldRef: FieldRef; var Resul: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateRecordWithSkipFields(ConfigTemplateHeader: Record "Config. Template Header"; var RecRef: RecordRef; SkipFields: Boolean; var TempSkipFields: Record "Field" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyTemplLinesWithoutValidationAfterRecRefCheck(ConfigTemplateHeader: Record "Config. Template Header"; ConfigTemplateLine: Record "Config. Template Line"; var RecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTemplate(var ConfigTemplateLine: Record "Config. Template Line"; var ConfigTemplateHeader: Record "Config. Template Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTemplateBeforeModify(var ConfigTemplateLine: Record "Config. Template Line"; var ConfigTemplateHeader: Record "Config. Template Header"; var FieldIsModified: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnInsertTemplateBeforeValidateFieldValue', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyRecordWithField(var RecRef: RecordRef; FieldRef: FieldRef; Value: Text[2048]; LanguageID: Integer; var IsHandled: Boolean; ConfigTemplateLine: Record "Config. Template Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnInsertTemplateBeforeValidateFieldValue(var RecRef: RecordRef; FieldRef: FieldRef; Value: Text[2048]; LanguageID: Integer; var IsHandled: Boolean; ConfigTemplateLine: Record "Config. Template Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestKeyFields(var RecRef: RecordRef; ConfigTemplateHeader: Record "Config. Template Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWithSkipFields(var SkipFieldValidation: Boolean; var RecRef: RecordRef; var TempDummyField: Record "Field" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateFromTemplateSelection(var ConfigTemplateHeader: Record "Config. Template Header"; RecRef: RecordRef; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTemplateCaseElse(var ConfigTemplateLine: Record "Config. Template Line"; var ConfigTemplateHeader: Record "Config. Template Header"; FldRef: FieldRef; var RecRef: RecordRef; SkipFields: Boolean; var TempSkipField: record Field; OldRecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertRecordWithKeyFieldsOnBeforeRecRefInsert(var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertRecordWithKeyFields(var RecRef: RecordRef; ConfigTemplateHeader: Record "Config. Template Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertRecordWithKeyFieldsOnBeforeValidateFieldValue(var ConfigTemplateHeader: Record "Config. Template Header"; var ConfigTemplateLine: Record "Config. Template Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyTemplateLinesWithoutValidationOnBeforeValidateFieldValue(var ConfigTemplateHeader: Record "Config. Template Header"; var ConfigTemplateLine: Record "Config. Template Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateConfigTemplateAndLinesOnBeforeConfigTemplateHeaderInsert(var ConfigTemplateHeader: Record "Config. Template Header")
    begin
    end;
}


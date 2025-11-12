// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;

using System.Reflection;

table 1237 "Transformation Rule"
{
    Caption = 'Transformation Rule';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Transformation Rules";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Transformation Type"; Enum "Transformation Rule Type")
        {
            Caption = 'Transformation Type';

            trigger OnValidate()
            begin
                if Rec."Transformation Type" <> xRec."Transformation Type" then begin
                    "Find Value" := '';
                    "Replace Value" := '';
                    "Start Position" := 0;
                    Length := 0;
                    "Ending Text" := '';
                    "Starting Text" := '';
                end;

                if not IsDataFormatUpdateAllowed() then begin
                    "Data Format" := '';
                    "Data Formatting Culture" := '';
                end;
            end;
        }
        field(10; "Find Value"; Text[250])
        {
            Caption = 'Find Value';

            trigger OnValidate()
            begin
                if Rec."Find Value" <> '' then
                    ValidateTransformationRuleField(Rec.FieldNo("Find Value"));
            end;
        }
        field(11; "Replace Value"; Text[250])
        {
            Caption = 'Replace Value';

            trigger OnValidate()
            begin
                if Rec."Replace Value" <> '' then
                    ValidateTransformationRuleField(Rec.FieldNo("Replace Value"));
            end;
        }
        field(12; "Starting Text"; Text[250])
        {
            Caption = 'Starting Text';

            trigger OnValidate()
            begin
                if Rec."Starting Text" <> '' then
                    ValidateTransformationRuleField(Rec.FieldNo("Starting Text"));
            end;
        }
        field(13; "Ending Text"; Text[250])
        {
            Caption = 'Ending Text';

            trigger OnValidate()
            begin
                if Rec."Ending Text" <> '' then
                    ValidateTransformationRuleField(Rec.FieldNo("Ending Text"));
            end;
        }
        field(15; "Start Position"; Integer)
        {
            BlankZero = true;
            Caption = 'Start Position';

            trigger OnValidate()
            begin
                if Rec."Start Position" <> 0 then
                    ValidateTransformationRuleField(Rec.FieldNo("Start Position"));
            end;
        }
        field(16; Length; Integer)
        {
            BlankZero = true;
            Caption = 'Length';


            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnValidateLengthOnBeforeTestTransformationType(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;
                if Rec.Length <> 0 then
                    ValidateTransformationRuleField(Rec.FieldNo(Length));
            end;
        }
        field(18; "Data Format"; Text[100])
        {
            Caption = 'Data Format';

            trigger OnValidate()
            begin
                if not IsDataFormatUpdateAllowed() then
                    TestField("Data Format", '');

                if Rec."Data Format" <> '' then
                    ValidateTransformationRuleField(Rec.FieldNo("Data Format"));
            end;
        }
        field(20; "Data Formatting Culture"; Text[10])
        {
            Caption = 'Data Formatting Culture';

            trigger OnValidate()
            begin
                if not IsDataFormatUpdateAllowed() then
                    TestField("Data Formatting Culture", '');

                if Rec."Data Formatting Culture" <> '' then
                    ValidateTransformationRuleField(Rec.FieldNo("Data Formatting Culture"));
            end;
        }
        field(30; "Next Transformation Rule"; Code[20])
        {
            Caption = 'Next Transformation Rule';
            TableRelation = "Transformation Rule".Code;
        }
        field(50; "Table ID"; Integer)
        {
            Caption = 'Table ID';

            trigger OnLookup()
            var
                ConfigValidateMgt: Codeunit "Config. Validate Management";
            begin
                ConfigValidateMgt.LookupTable("Table ID");
                if "Table ID" <> 0 then
                    Validate("Table ID");
            end;

            trigger OnValidate()
            begin
                CalcFields("Table Caption");
                if Rec."Table ID" <> 0 then
                    ValidateTransformationRuleField(Rec.FieldNo("Table ID"));
            end;
        }
        field(51; "Table Caption"; Text[250])
        {
            Caption = 'Table ID';
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table ID")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Source Field ID"; Integer)
        {
            Caption = 'Source Field ID';
            TableRelation = Field."No." where(TableNo = field("Table ID"));

            trigger OnValidate()
            begin
                if ("Source Field ID" <> 0) and ("Target Field ID" = "Source Field ID") then
                    FieldError("Source Field ID");
                CalcFields("Source Field Caption");

                if Rec."Source Field ID" <> 0 then
                    ValidateTransformationRuleField(Rec.FieldNo("Source Field ID"));
            end;
        }
        field(53; "Source Field Caption"; Text[250])
        {
            Caption = 'Source Field Caption';
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table ID"),
                                                              "No." = field("Source Field ID")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(54; "Target Field ID"; Integer)
        {
            Caption = 'Target Field ID';
            TableRelation = Field."No." where(TableNo = field("Table ID"));

            trigger OnValidate()
            begin
                if ("Target Field ID" <> 0) and ("Target Field ID" = "Source Field ID") then
                    FieldError("Target Field ID");
                CalcFields("Target Field Caption");

                if Rec."Target Field ID" <> 0 then
                    ValidateTransformationRuleField(Rec.FieldNo("Target Field ID"));
            end;
        }
        field(55; "Target Field Caption"; Text[250])
        {
            Caption = 'Target Field Caption';
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table ID"),
                                                              "No." = field("Target Field ID")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(56; "Field Lookup Rule"; Option)
        {
            Caption = 'Field Lookup Rule';
            OptionMembers = Target,"Original If Target Is Blank";

            trigger OnValidate()
            begin
                ValidateTransformationRuleField(Rec.FieldNo("Field Lookup Rule"));
            end;
        }
        field(57; Precision; Decimal)
        {
            Caption = 'Precision';
            DecimalPlaces = 0 : 10;

            trigger OnValidate()
            begin
                if Rec.Precision <> 0 then
                    ValidateTransformationRuleField(Rec.FieldNo(Precision));
            end;
        }
        field(58; Direction; Text[1])
        {
            Caption = 'Direction';

            trigger OnValidate()
            begin
                if Rec.Direction <> '' then
                    ValidateTransformationRuleField(Rec.FieldNo(Direction));
            end;
        }
        field(70; "Extract From Date Type"; Enum "Extract From Date Type")
        {
            Caption = 'Extract From Date Type';

            trigger OnValidate()
            begin
                ValidateTransformationRuleField(Rec.FieldNo("Extract From Date Type"));
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CheckMandatoryFields();
    end;

    trigger OnModify()
    begin
        CheckMandatoryFields();
    end;

    var
        UNIXTIMESTAMPTxt: Label 'UNIXTIMESTAMP', Comment = 'Assigned to Transformation.Code field for Unix Timestamp';
        UNIXTimeStampDescTxt: Label 'Transforming UNIX timestamp to text format.';
        UPPERCASETxt: Label 'UPPERCASE', Comment = 'Assigned to Transformation.Code field for Upper case';
        UpperCaseDescTxt: Label 'Upper Case Text';
        LOWERCASETxt: Label 'LOWERCASE', Comment = 'Assigned to Transformation.Code field for Lower case';
        LowerCaseDescTxt: Label 'Lower Case Text';
        TITLECASETxt: Label 'TITLECASE', Comment = 'Assigned to Transformation.Code field for Title case';
        TitleCaseDescTxt: Label 'Title Case Text';
        TRIMTxt: Label 'TRIM', Comment = 'Assigned to Transformation.Code field for Trim';
        TrimDescTxt: Label 'Trim Text';
        FOURTH_TO_SIXTH_CHARTxt: Label 'FOURTH_TO_SIXTH_CHAR', Comment = 'Assigned to Transformation.Code field for getting the 4th to 6th characters in a string';
        FourthToSixthCharactersDescTxt: Label 'Fourth to Sixth Characters Text';
        YYYYMMDDDateTxt: Label 'YYYYMMDD_DATE', Comment = 'Assigned to Transformation.Code field for converting dates from yyyyMMdd format';
        YYYYMMDDDateDescTxt: Label 'yyyyMMdd Date Text';
        YYYYMMDDHHMMSSTxt: Label 'YYYYMMDDHHMMSS_FMT', Comment = 'Assigned to Transformation.Code field for converting dates from yyyyMMdd format';
        YYYYMMDDHHMMSSDescTxt: Label 'yyyyMMddHHmmss Date/Time Format';
        ALPHANUMERIC_ONLYTxt: Label 'ALPHANUMERIC_ONLY', Comment = 'Assigned to Transformation.Code field for getting only the Alphanumeric characters in a string';
        AlphaNumericDescTxt: Label 'Alphanumeric Text Only';
        DKNUMBERFORMATTxt: Label 'DK_DECIMAL_FORMAT', Comment = 'Assigned to Transformation.Code field for getting decimal formatting rule for Danish numbers';
        DKNUMBERFORMATDescTxt: Label 'Danish Decimal Format';
        USDATEFORMATTxt: Label 'US_DATE_FORMAT', Comment = 'Assigned to Transformation.Code field for getting date formatting rule from U.S. dates';
        USDATEFORMATDescTxt: Label 'U.S. Date Format';
        USDATETIMEFORMATTxt: Label 'US_DATETIME_FORMAT', Comment = 'Assigned to Transformation.Code field for getting date formatting rule from U.S. dates';
        USDATETIMEFORMATDescTxt: Label 'U.S. Date/Time Format';
        DeleteNOTPROVIDEDTxt: Label 'DELETE_NOTPROVIDED', Comment = 'NOTPROVIDED should stay in english because it is a constant value. DELETE should be translated.';
        DeleteNOTPROVIDEDDescriptionTxt: Label 'Delete NOTPROVIDED value', Comment = 'NOTPROVIDED should stay in english because it is a constant value. ''Delete'' and ''value'' should be translated.';
#if not CLEAN28
        AppendSpaceTxt: Label 'ADDSPCEND', Locked = true;
        AppendSpaceDescriptionTxt: Label 'Adds a single empty space character to the end of the input string.', MaxLength = 100;
#endif

    procedure CreateDefaultTransformations()
    begin
        InsertRec(UPPERCASETxt, UpperCaseDescTxt, "Transformation Type"::Uppercase, 0, 0, '', '');
        InsertRec(LOWERCASETxt, LowerCaseDescTxt, "Transformation Type"::Lowercase, 0, 0, '', '');
        InsertRec(TITLECASETxt, TitleCaseDescTxt, "Transformation Type"::"Title Case", 0, 0, '', '');
        InsertRec(TRIMTxt, TrimDescTxt, "Transformation Type"::Trim, 0, 0, '', '');
        InsertRec(FOURTH_TO_SIXTH_CHARTxt, FourthToSixthCharactersDescTxt, "Transformation Type"::Substring, 4, 3, '', '');
        InsertRec(YYYYMMDDDateTxt, YYYYMMDDDateDescTxt, "Transformation Type"::"Date Formatting", 0, 0, 'yyyyMMdd', '');
        InsertRec(YYYYMMDDHHMMSSTxt, YYYYMMDDHHMMSSDescTxt, "Transformation Type"::"Date and Time Formatting", 0, 0, 'yyyyMMddHHmmss', '');
        InsertRec(ALPHANUMERIC_ONLYTxt, AlphaNumericDescTxt, "Transformation Type"::"Remove Non-Alphanumeric Characters", 0, 0, '', '');
        InsertRec(DKNUMBERFORMATTxt, DKNUMBERFORMATDescTxt, "Transformation Type"::"Decimal Formatting", 0, 0, '', 'da-DK');
        InsertRec(USDATEFORMATTxt, USDATEFORMATDescTxt, "Transformation Type"::"Date Formatting", 0, 0, '', 'en-US');
        InsertRec(USDATETIMEFORMATTxt, USDATETIMEFORMATDescTxt, "Transformation Type"::"Date and Time Formatting", 0, 0, '', 'en-US');
        InsertRec(UNIXTIMESTAMPTxt, UNIXTimeStampDescTxt, "Transformation Type"::Unixtimestamp, 0, 0, '', '');
        OnCreateTransformationRules();
        InsertFindAndReplaceRule(
          DeleteNOTPROVIDEDTxt, DeleteNOTPROVIDEDDescriptionTxt, "Transformation Type"::"Regular Expression - Replace",
          'NOTPROVIDED', '', '');
    end;

    procedure ValidateTransformationRuleField(FieldNo: Integer)
    var
        TransformationRule: Interface "Transformation Rule";
    begin
        TransformationRule := Rec."Transformation Type";
        TransformationRule.ValidateTransformationRuleField(FieldNo, Rec, xRec);
    end;

    procedure IsDataFormatUpdateAllowed(): Boolean
    var
        TransformationRule: Interface "Transformation Rule";
        IsHandled: Boolean;
        DataFormatUpdateAllowed: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsDataFormatUpdateAllowed(CurrFieldNo, DataFormatUpdateAllowed, IsHandled);
        if IsHandled then
            exit(DataFormatUpdateAllowed);

        TransformationRule := Rec."Transformation Type";
        exit(TransformationRule.IsDataFormatUpdateAllowed());
    end;

    procedure InsertRec(NewCode: Code[20]; NewDescription: Text[100]; NewTransformationType: Enum "Transformation Rule Type"; NewStartPosition: Integer; NewLength: Integer; NewDataFormat: Text[100]; NewDataFormattingCulture: Text[10])
    var
        TransformationRule: Record "Transformation Rule";
    begin
        if TransformationRule.Get(NewCode) then
            exit;

        TransformationRule.CreateRule(
            NewCode, NewDescription, NewTransformationType, NewStartPosition, NewLength, NewDataFormat, NewDataFormattingCulture);
    end;

    procedure CreateRule(NewCode: Code[20]; NewDescription: Text[100]; NewTransformationType: Enum "Transformation Rule Type"; NewStartPosition: Integer; NewLength: Integer; NewDataFormat: Text[100]; NewDataFormattingCulture: Text[10])
    begin
        Init();
        Validate(Code, NewCode);
        Validate(Description, NewDescription);
        Validate("Transformation Type", NewTransformationType);
        Validate("Start Position", NewStartPosition);
        Validate(Length, NewLength);
        Validate("Data Format", NewDataFormat);
        Validate("Data Formatting Culture", NewDataFormattingCulture);
        Insert(true);
    end;

    procedure InsertFindAndReplaceRule(NewCode: Code[20]; NewDescription: Text[100]; NewTransformationType: Enum "Transformation Rule Type"; NewFindValue: Text[250]; NewReplaceValue: Text[250]; NextTransformationRule: Code[20])
    var
        TransformationRule: Record "Transformation Rule";
    begin
        if TransformationRule.Get(NewCode) then
            exit;

        TransformationRule.ReplaceRule(NewCode, NewDescription, NewTransformationType, NewFindValue, NewReplaceValue, NextTransformationRule);
    end;

    procedure ReplaceRule(NewCode: Code[20]; NewDescription: Text[100]; NewTransformationType: Enum "Transformation Rule Type"; NewFindValue: Text[250]; NewReplaceValue: Text[250])
    begin
        Init();
        Validate(Code, NewCode);
        Validate(Description, NewDescription);
        Validate("Transformation Type", NewTransformationType);
        Validate("Find Value", NewFindValue);
        Validate("Replace Value", NewReplaceValue);
        Insert(true);
    end;

    procedure ReplaceRule(NewCode: Code[20]; NewDescription: Text[100]; NewTransformationType: Enum "Transformation Rule Type"; NewFindValue: Text[250]; NewReplaceValue: Text[250]; NextTransformationRule: Code[20])
    begin
        Init();
        Validate(Code, NewCode);
        Validate(Description, NewDescription);
        Validate("Transformation Type", NewTransformationType);
        Validate("Find Value", NewFindValue);
        Validate("Replace Value", NewReplaceValue);
        Validate("Next Transformation Rule", NextTransformationRule);
        Insert(true);
    end;

    procedure TransformText(OldValue: Text): Text
    var
        NextTransformationRule: Record "Transformation Rule";
        TransformationRule: Interface "Transformation Rule";
        NewValue: Text;
    begin
        NewValue := OldValue;
        TransformationRule := Rec."Transformation Type";
        TransformationRule.TransformText(Rec, OldValue, NewValue);

        if "Next Transformation Rule" <> '' then
            if NextTransformationRule.Get("Next Transformation Rule") then
                exit(NextTransformationRule.TransformText(NewValue));

        exit(NewValue);
    end;

    procedure GetFourthToSixthSubstringCode(): Code[20]
    begin
        exit(FOURTH_TO_SIXTH_CHARTxt);
    end;

    procedure GetUSDateFormatCode(): Code[20]
    begin
        exit(USDATEFORMATTxt);
    end;

    procedure GetUSDateTimeFormatCode(): Code[20]
    begin
        exit(USDATETIMEFORMATTxt);
    end;

    procedure GetUppercaseCode(): Code[20]
    begin
        exit(UPPERCASETxt);
    end;

    procedure GetLowercaseCode(): Code[20]
    begin
        exit(LOWERCASETxt);
    end;

    procedure GetTitlecaseCode(): Code[20]
    begin
        exit(TITLECASETxt);
    end;

    procedure GetTrimCode(): Code[20]
    begin
        exit(TRIMTxt);
    end;

    procedure GetAlphanumericCode(): Code[20]
    begin
        exit(ALPHANUMERIC_ONLYTxt);
    end;

    procedure GetDanishDecimalFormatCode(): Code[20]
    begin
        exit(DKNUMBERFORMATTxt);
    end;

    procedure GetYYYYMMDDCode(): Code[20]
    begin
        exit(YYYYMMDDDateTxt);
    end;

    procedure GetYYYYMMDDHHMMSSCode(): Code[20]
    begin
        exit(YYYYMMDDHHMMSSTxt);
    end;

    procedure GetDeleteNOTPROVIDEDCode(): Code[20]
    begin
        exit(DeleteNOTPROVIDEDTxt);
    end;

#if not CLEAN28
    [Obsolete('This is an unused procedure.', '28.0')]
    procedure GetAppendSpaceCode(): Code[20]
    begin
        exit(AppendSpaceTxt);
    end;

#endif
    procedure EditNextTransformationRule()
    var
        TransformationRule: Record "Transformation Rule";
    begin
        if "Next Transformation Rule" = '' then
            exit;

        TransformationRule.Get("Next Transformation Rule");
        PAGE.Run(PAGE::"Transformation Rule Card", TransformationRule);
    end;

    local procedure CheckMandatoryFields()
    var
        TransformationRule: Interface "Transformation Rule";
    begin
        TransformationRule := Rec."Transformation Type";
        TransformationRule.CheckMandatoryFieldsInTransformationRule(Rec);
    end;

#if not CLEAN28
    [Obsolete('This is an unused procedure.', '28.0')]
    procedure InsertAppendSpaceTransformation()
    begin
        InsertFindAndReplaceRule(AppendSpaceTxt, AppendSpaceDescriptionTxt, "Transformation Type"::"Regular Expression - Replace", '$', ' ', '');
    end;

#endif
    [IntegrationEvent(false, false)]
    procedure OnTransformation(TransformationCode: Code[20]; InputText: Text; var OutputText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnCreateTransformationRules()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeIsDataFormatUpdateAllowed(FieldNumber: Integer; var DataFormatUpdateAllowed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnValidateLengthOnBeforeTestTransformationType(var TransformationRule: Record "Transformation Rule"; xTransformationRule: Record "Transformation Rule"; var IsHandled: Boolean)
    begin
    end;
}

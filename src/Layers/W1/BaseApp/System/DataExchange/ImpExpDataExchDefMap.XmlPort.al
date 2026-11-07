namespace System.IO;

xmlport 1225 "Imp / Exp Data Exch Def & Map"
{
    Caption = 'Imp / Exp Data Exch Def & Map';
    Encoding = UTF8;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement("Data Exch. Def"; "Data Exch. Def")
            {
                MinOccurs = Zero;
                XmlName = 'DataExchDef';
                fieldattribute(Code; "Data Exch. Def".Code)
                {
                }
                fieldattribute(Name; "Data Exch. Def".Name)
                {
                }
                fieldattribute(Type; "Data Exch. Def".Type)
                {
                    FieldValidate = no;
                }
                fieldattribute(ReadingWritingXMLport; "Data Exch. Def"."Reading/Writing XMLport")
                {
                    FieldValidate = no;
                    Occurrence = Optional;

                    trigger OnBeforePassField()
                    begin
                        if "Data Exch. Def"."Reading/Writing XMLport" = 0 then
                            currXMLport.Skip();
                    end;
                }
                fieldattribute(ExternalDataHandlingCodeunit; "Data Exch. Def"."Ext. Data Handling Codeunit")
                {
                    Occurrence = Optional;

                    trigger OnBeforePassField()
                    begin
                        if "Data Exch. Def"."Ext. Data Handling Codeunit" = 0 then
                            currXMLport.Skip();
                    end;
                }
                fieldattribute(HeaderLines; "Data Exch. Def"."Header Lines")
                {
                    Occurrence = Optional;

                    trigger OnBeforePassField()
                    begin
                        if "Data Exch. Def"."Header Lines" = 0 then
                            currXMLport.Skip();
                    end;
                }
                fieldattribute(HeaderTag; "Data Exch. Def"."Header Tag")
                {
                    Occurrence = Optional;
                }
                fieldattribute(FooterTag; "Data Exch. Def"."Footer Tag")
                {
                    Occurrence = Optional;
                }
                fieldattribute(ColumnSeparator; "Data Exch. Def"."Column Separator")
                {
                    Occurrence = Optional;

                    trigger OnBeforePassField()
                    begin
                        if "Data Exch. Def"."Column Separator" = "Data Exch. Def"."Column Separator"::Comma then
                            currXMLport.Skip();
                    end;
                }
                fieldattribute(CustomColumnSeparator; "Data Exch. Def"."Custom Column Separator")
                {
                    Occurrence = Optional;

                    trigger OnBeforePassField()
                    begin
                        if "Data Exch. Def"."Column Separator" <> "Data Exch. Def"."Column Separator"::Custom then
                            currXMLport.Skip();
                    end;
                }
                fieldattribute(FileEncoding; "Data Exch. Def"."File Encoding")
                {
                    Occurrence = Optional;

                    trigger OnBeforePassField()
                    begin
                        if "Data Exch. Def"."File Encoding" = "Data Exch. Def"."File Encoding"::WINDOWS then
                            currXMLport.Skip();
                    end;
                }
                fieldattribute(FileType; "Data Exch. Def"."File Type")
                {
                    FieldValidate = no;
                    Occurrence = Optional;
                }
                fieldattribute(ReadingWritingCodeunit; "Data Exch. Def"."Reading/Writing Codeunit")
                {
                    Occurrence = Optional;

                    trigger OnBeforePassField()
                    begin
                        if "Data Exch. Def"."Reading/Writing Codeunit" = 0 then
                            currXMLport.Skip();
                    end;
                }
                fieldattribute(ValidationCodeunit; "Data Exch. Def"."Validation Codeunit")
                {
                    Occurrence = Optional;

                    trigger OnBeforePassField()
                    begin
                        if "Data Exch. Def"."Validation Codeunit" = 0 then
                            currXMLport.Skip();
                    end;
                }
                fieldattribute(DataHandlingCodeunit; "Data Exch. Def"."Data Handling Codeunit")
                {
                    Occurrence = Optional;

                    trigger OnBeforePassField()
                    begin
                        if "Data Exch. Def"."Data Handling Codeunit" = 0 then
                            currXMLport.Skip();
                    end;
                }
                fieldattribute(UserFeedbackCodeunit; "Data Exch. Def"."User Feedback Codeunit")
                {
                    Occurrence = Optional;

                    trigger OnBeforePassField()
                    begin
                        if "Data Exch. Def"."User Feedback Codeunit" = 0 then
                            currXMLport.Skip();
                    end;
                }
                fieldattribute(LineSeparator; "Data Exch. Def"."Line Separator")
                {
                    Occurrence = Optional;
                    FieldValidate = no;
                }
                tableelement("Data Exch. Line Def"; "Data Exch. Line Def")
                {
                    LinkFields = "Data Exch. Def Code" = field(Code);
                    LinkTable = "Data Exch. Def";
                    MinOccurs = Zero;
                    XmlName = 'DataExchLineDef';
                    SourceTableView = sorting("Data Exch. Def Code", "Parent Code");
                    fieldattribute(LineType; "Data Exch. Line Def"."Line Type")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(Code; "Data Exch. Line Def".Code)
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(Name; "Data Exch. Line Def".Name)
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(ColumnCount; "Data Exch. Line Def"."Column Count")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(DataLineTag; "Data Exch. Line Def"."Data Line Tag")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(Namespace; "Data Exch. Line Def".Namespace)
                    {
                        Occurrence = Optional;

                        trigger OnBeforePassField()
                        begin
                            if "Data Exch. Line Def".Namespace = '' then
                                currXMLport.Skip();
                        end;
                    }
                    fieldattribute(ParentCode; "Data Exch. Line Def"."Parent Code")
                    {
                        Occurrence = Optional;
                    }
                    tableelement("Data Exch. Column Def"; "Data Exch. Column Def")
                    {
                        LinkFields = "Data Exch. Def Code" = field("Data Exch. Def Code"), "Data Exch. Line Def Code" = field(Code);
                        LinkTable = "Data Exch. Line Def";
                        MinOccurs = Zero;
                        XmlName = 'DataExchColumnDef';
                        fieldattribute(ColumnNo; "Data Exch. Column Def"."Column No.")
                        {
                        }
                        fieldattribute(Name; "Data Exch. Column Def".Name)
                        {
                        }
                        fieldattribute(Show; "Data Exch. Column Def".Show)
                        {
                        }
                        fieldattribute(DataType; "Data Exch. Column Def"."Data Type")
                        {
                        }
                        fieldattribute(DataFormat; "Data Exch. Column Def"."Data Format")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Data Exch. Column Def"."Data Format" = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        fieldattribute(DataFormattingCulture; "Data Exch. Column Def"."Data Formatting Culture")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Data Exch. Column Def"."Data Formatting Culture" = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        fieldattribute(Description; "Data Exch. Column Def".Description)
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Data Exch. Column Def".Description = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        fieldattribute(Length; "Data Exch. Column Def".Length)
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Data Exch. Column Def".Length = 0 then
                                    currXMLport.Skip();
                            end;
                        }
                        fieldattribute(Constant; "Data Exch. Column Def".Constant)
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Data Exch. Column Def".Constant = '' then
                                    currXMLport.Skip();
                            end;
                        }
                        fieldattribute(Path; "Data Exch. Column Def".Path)
                        {
                            Occurrence = Optional;
                        }
                        fieldattribute(NegativeSignIdentifier; "Data Exch. Column Def"."Negative-Sign Identifier")
                        {
                            Occurrence = Optional;
                        }
                        fieldattribute(TextPaddingRequired; "Data Exch. Column Def"."Text Padding Required")
                        {
                            Occurrence = Optional;
                        }
                        textattribute(PadCharacter)
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassVariable()
                            begin
                                if "Data Exch. Column Def"."Pad Character" = ' ' then
                                    PadCharacter := XMLSpaceTxt
                                else
                                    PadCharacter := "Data Exch. Column Def"."Pad Character";
                            end;

                            trigger OnAfterAssignVariable()
                            begin
                                if PadCharacter = XMLSpaceTxt then
                                    "Data Exch. Column Def"."Pad Character" := ' '
                                else
                                    "Data Exch. Column Def"."Pad Character" := PadCharacter;
                            end;
                        }
                        fieldattribute(Justification; "Data Exch. Column Def".Justification)
                        {
                            Occurrence = Optional;
                        }
                        fieldattribute(UseNodeNameAsValue; "Data Exch. Column Def"."Use Node Name as Value")
                        {
                            Occurrence = Optional;
                        }
                        fieldattribute(BlankZero; "Data Exch. Column Def"."Blank Zero")
                        {
                            Occurrence = Optional;
                        }
                        fieldattribute(ExportIfNotBlank; "Data Exch. Column Def"."Export If Not Blank")
                        {
                            Occurrence = Optional;
                        }
                    }
                    tableelement("Data Exch. Mapping"; "Data Exch. Mapping")
                    {
                        LinkFields = "Data Exch. Def Code" = field("Data Exch. Def Code"), "Data Exch. Line Def Code" = field(Code);
                        LinkTable = "Data Exch. Line Def";
                        MinOccurs = Zero;
                        XmlName = 'DataExchMapping';
                        fieldattribute(TableId; "Data Exch. Mapping"."Table ID")
                        {
                        }
                        fieldattribute(UseAsIntermediateTable; "Data Exch. Mapping"."Use as Intermediate Table")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if not "Data Exch. Mapping"."Use as Intermediate Table" then
                                    currXMLport.Skip();
                            end;
                        }
                        fieldattribute(Name; "Data Exch. Mapping".Name)
                        {
                        }
                        fieldattribute(KeyIndex; "Data Exch. Mapping"."Key Index")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Data Exch. Mapping"."Key Index" = 0 then
                                    currXMLport.Skip();
                            end;
                        }
                        fieldattribute(MappingCodeunit; "Data Exch. Mapping"."Mapping Codeunit")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Data Exch. Mapping"."Mapping Codeunit" = 0 then
                                    currXMLport.Skip();
                            end;
                        }
                        fieldattribute(DataExchNoFieldID; "Data Exch. Mapping"."Data Exch. No. Field ID")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Data Exch. Mapping"."Data Exch. No. Field ID" = 0 then
                                    currXMLport.Skip();
                            end;
                        }
                        fieldattribute(DataExchLineFieldID; "Data Exch. Mapping"."Data Exch. Line Field ID")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Data Exch. Mapping"."Data Exch. Line Field ID" = 0 then
                                    currXMLport.Skip();
                            end;
                        }
                        fieldattribute(PreMappingCodeunit; "Data Exch. Mapping"."Pre-Mapping Codeunit")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Data Exch. Mapping"."Pre-Mapping Codeunit" = 0 then
                                    currXMLport.Skip();
                            end;
                        }
                        fieldattribute(PostMappingCodeunit; "Data Exch. Mapping"."Post-Mapping Codeunit")
                        {
                            Occurrence = Optional;

                            trigger OnBeforePassField()
                            begin
                                if "Data Exch. Mapping"."Post-Mapping Codeunit" = 0 then
                                    currXMLport.Skip();
                            end;
                        }
                        tableelement("Data Exch. Field Mapping"; "Data Exch. Field Mapping")
                        {
                            LinkFields = "Data Exch. Def Code" = field("Data Exch. Def Code"), "Data Exch. Line Def Code" = field("Data Exch. Line Def Code"), "Table ID" = field("Table ID");
                            LinkTable = "Data Exch. Mapping";
                            MinOccurs = Zero;
                            XmlName = 'DataExchFieldMapping';
                            fieldattribute(ColumnNo; "Data Exch. Field Mapping"."Column No.")
                            {
                                Occurrence = Optional;

                                trigger OnBeforePassField()
                                begin
                                    if "Data Exch. Field Mapping"."Column No." = 0 then
                                        currXMLport.Skip();
                                end;
                            }
                            fieldattribute(FieldID; "Data Exch. Field Mapping"."Field ID")
                            {
                                Occurrence = Optional;

                                trigger OnBeforePassField()
                                begin
                                    if "Data Exch. Field Mapping"."Field ID" = 0 then
                                        currXMLport.Skip();
                                end;
                            }
                            fieldattribute(Optional; "Data Exch. Field Mapping".Optional)
                            {
                                Occurrence = Optional;

                                trigger OnBeforePassField()
                                begin
                                    if not "Data Exch. Field Mapping".Optional then
                                        currXMLport.Skip();
                                end;
                            }
                            fieldattribute(Priority; "Data Exch. Field Mapping".Priority)
                            {
                                Occurrence = Optional;

                                trigger OnBeforePassField()
                                begin
                                    if "Data Exch. Field Mapping".Priority = 0 then
                                        currXMLport.Skip();
                                end;
                            }
                            fieldattribute(UseDefaultValue; "Data Exch. Field Mapping"."Use Default Value")
                            {
                                Occurrence = Optional;

                                trigger OnBeforePassField()
                                begin
                                    if not "Data Exch. Field Mapping"."Use Default Value" then
                                        currXMLport.Skip();
                                end;
                            }
                            fieldattribute(DefaultValue; "Data Exch. Field Mapping"."Default Value")
                            {
                                Occurrence = Optional;

                                trigger OnBeforePassField()
                                begin
                                    if "Data Exch. Field Mapping"."Default Value" = '' then
                                        currXMLport.Skip();
                                end;
                            }
                            fieldattribute(Multiplier; "Data Exch. Field Mapping".Multiplier)
                            {
                                Occurrence = Optional;

                                trigger OnBeforePassField()
                                begin
                                    if "Data Exch. Field Mapping".Multiplier = 1 then
                                        currXMLport.Skip();
                                end;
                            }
                            fieldattribute(OverwriteValue; "Data Exch. Field Mapping"."Overwrite Value") //AMC-JN Missing as this is an attribute in table 1225
                            {
                                Occurrence = Optional;

                                trigger OnBeforePassField()
                                begin
                                    if not "Data Exch. Field Mapping"."Overwrite Value" then
                                        currXMLport.Skip();
                                end;
                            }
                            fieldattribute(TargetTableID; "Data Exch. Field Mapping"."Target Table ID")
                            {
                                Occurrence = Optional;

                                trigger OnBeforePassField()
                                begin
                                    if "Data Exch. Field Mapping"."Target Table ID" = 0 then
                                        currXMLport.Skip();
                                end;
                            }
                            fieldattribute(TargetFieldID; "Data Exch. Field Mapping"."Target Field ID")
                            {
                                Occurrence = Optional;

                                trigger OnBeforePassField()
                                begin
                                    if "Data Exch. Field Mapping"."Target Table ID" = 0 then
                                        currXMLport.Skip();
                                end;
                            }
                            textattribute(TransformationRule)
                            {
                                Occurrence = Optional;

                                trigger OnBeforePassVariable()
                                var
                                    TransformationRuleRec: Record "Transformation Rule";
                                begin
                                    case "Data Exch. Field Mapping"."Transformation Rule" of
                                        TransformationRuleRec.GetUppercaseCode():
                                            TransformationRule := 'UPPERCASE';
                                        TransformationRuleRec.GetLowercaseCode():
                                            TransformationRule := 'LOWERCASE';
                                        TransformationRuleRec.GetTitlecaseCode():
                                            TransformationRule := 'TITLECASE';
                                        TransformationRuleRec.GetTrimCode():
                                            TransformationRule := 'TRIM';
                                        TransformationRuleRec.GetFourthToSixthSubstringCode():
                                            TransformationRule := 'FOURTH_TO_SIXTH_CHAR';
                                        TransformationRuleRec.GetYYYYMMDDCode():
                                            TransformationRule := 'YYYYMMDD_DATE';
                                        TransformationRuleRec.GetYYYYMMDDHHMMSSCode():
                                            TransformationRule := 'YYYYMMDDHHMMSS_FMT';
                                        TransformationRuleRec.GetAlphanumericCode():
                                            TransformationRule := 'ALPHANUMERIC_ONLY';
                                        TransformationRuleRec.GetDanishDecimalFormatCode():
                                            TransformationRule := 'DK_DECIMAL_FORMAT';
                                        TransformationRuleRec.GetUSDateFormatCode():
                                            TransformationRule := 'US_DATE_FORMAT';
                                        TransformationRuleRec.GetUSDateTimeFormatCode():
                                            TransformationRule := 'US_DATETIME_FORMAT';
                                        TransformationRuleRec.GetDeleteNOTPROVIDEDCode():
                                            TransformationRule := 'DELETE_NOTPROVIDED';
                                        else begin
                                            TransformationRule := "Data Exch. Field Mapping"."Transformation Rule";
                                            AddTransformationRule(TransformationRule);
                                        end;
                                    end;
                                end;

                                trigger OnAfterAssignVariable()
                                var
                                    TransformationRuleRec: Record "Transformation Rule";
                                begin
                                    case TransformationRule of
                                        'UPPERCASE':
                                            "Data Exch. Field Mapping".Validate("Transformation Rule", TransformationRuleRec.GetUppercaseCode());
                                        'LOWERCASE':
                                            "Data Exch. Field Mapping".Validate("Transformation Rule", TransformationRuleRec.GetLowercaseCode());
                                        'TITLECASE':
                                            "Data Exch. Field Mapping".Validate("Transformation Rule", TransformationRuleRec.GetTitlecaseCode());
                                        'TRIM':
                                            "Data Exch. Field Mapping".Validate("Transformation Rule", TransformationRuleRec.GetTrimCode());
                                        'FOURTH_TO_SIXTH_CHAR':
                                            "Data Exch. Field Mapping".Validate("Transformation Rule", TransformationRuleRec.GetFourthToSixthSubstringCode());
                                        'YYYYMMDD_DATE':
                                            "Data Exch. Field Mapping".Validate("Transformation Rule", TransformationRuleRec.GetYYYYMMDDCode());
                                        'YYYYMMDDHHMMSS_FMT':
                                            "Data Exch. Field Mapping".Validate("Transformation Rule", TransformationRuleRec.GetYYYYMMDDHHMMSSCode());
                                        'ALPHANUMERIC_ONLY':
                                            "Data Exch. Field Mapping".Validate("Transformation Rule", TransformationRuleRec.GetAlphanumericCode());
                                        'DK_DECIMAL_FORMAT':
                                            "Data Exch. Field Mapping".Validate("Transformation Rule", TransformationRuleRec.GetDanishDecimalFormatCode());
                                        'US_DATE_FORMAT':
                                            "Data Exch. Field Mapping".Validate("Transformation Rule", TransformationRuleRec.GetUSDateFormatCode());
                                        'US_DATETIME_FORMAT':
                                            "Data Exch. Field Mapping".Validate("Transformation Rule", TransformationRuleRec.GetUSDateTimeFormatCode());
                                        'DELETE_NOTPROVIDED':
                                            "Data Exch. Field Mapping".Validate("Transformation Rule", TransformationRuleRec.GetDeleteNOTPROVIDEDCode());
                                        else
                                            "Data Exch. Field Mapping"."Transformation Rule" := TransformationRule;
                                    end;
                                end;
                            }
                            tableelement(temptransformationrulerec; "Transformation Rule")
                            {
                                AutoReplace = true;
                                MinOccurs = Zero;
                                XmlName = 'TransformationRules';
                                UseTemporary = true;
                                fieldelement(Code; TempTransformationRuleRec.Code)
                                {
                                }
                                fieldelement(Description; TempTransformationRuleRec.Description)
                                {
                                }
                                fieldelement(TransformationType; TempTransformationRuleRec."Transformation Type")
                                {
                                }
                                textelement(FindValue)
                                {
                                    trigger OnBeforePassVariable()
                                    begin
                                        if TempTransformationRuleRec."Find Value" = ' ' then
                                            FindValue := XMLSpaceTxt
                                        else
                                            FindValue := TempTransformationRuleRec."Find Value";
                                    end;

                                    trigger OnAfterAssignVariable()
                                    begin
                                        if FindValue = XMLSpaceTxt then
                                            TempTransformationRuleRec."Find Value" := ' '
                                        else
                                            TempTransformationRuleRec."Find Value" := FindValue;
                                    end;
                                }
                                textelement(ReplaceValue)
                                {
                                    trigger OnBeforePassVariable()
                                    begin
                                        if TempTransformationRuleRec."Replace Value" = ' ' then
                                            ReplaceValue := XMLSpaceTxt
                                        else
                                            ReplaceValue := TempTransformationRuleRec."Replace Value";
                                    end;

                                    trigger OnAfterAssignVariable()
                                    begin
                                        if ReplaceValue = XMLSpaceTxt then
                                            TempTransformationRuleRec."Replace Value" := ' '
                                        else
                                            TempTransformationRuleRec."Replace Value" := ReplaceValue;
                                    end;
                                }
                                fieldelement(StartPosition; TempTransformationRuleRec."Start Position")
                                {
                                }
                                fieldelement(Length; TempTransformationRuleRec.Length)
                                {
                                }
                                fieldelement(DataFormat; TempTransformationRuleRec."Data Format")
                                {
                                }
                                fieldelement(DataFormattingCulture; TempTransformationRuleRec."Data Formatting Culture")
                                {
                                }
                                fieldelement(NextTransformationRule; TempTransformationRuleRec."Next Transformation Rule")
                                {
                                    MinOccurs = Zero;
                                }
                                fieldelement(TableID; TempTransformationRuleRec."Table ID")
                                {
                                }
                                fieldelement(SourceFieldID; TempTransformationRuleRec."Source Field ID")
                                {
                                }
                                fieldelement(TargetFieldID; TempTransformationRuleRec."Target Field ID")
                                {
                                }
                                fieldelement(FieldLookupRule; TempTransformationRuleRec."Field Lookup Rule")
                                {
                                }
                                fieldelement(Precision; TempTransformationRuleRec.Precision)
                                {
                                }
                                fieldelement(Direction; TempTransformationRuleRec.Direction)
                                {
                                }
                                fieldelement(ExportFromDateType; TempTransformationRuleRec."Extract From Date Type")
                                {
                                    MinOccurs = Zero;
                                }
                                trigger OnAfterInsertRecord()
                                var
                                    TransformationRuleRec: Record "Transformation Rule";
                                begin
                                    if not TransformationRuleRec.Get(TempTransformationRuleRec.Code) then begin
                                        TransformationRuleRec := TempTransformationRuleRec;
                                        TransformationRuleRec.Insert();
                                    end;
                                    FindValue := '';
                                    ReplaceValue := '';
                                end;
                            }

                            trigger OnAfterGetRecord()
                            begin
                                TempTransformationRuleRec.DeleteAll();
                            end;
                        }
                        tableelement("Data Exch. Field Grouping"; "Data Exch. Field Grouping")
                        {
                            LinkFields = "Data Exch. Def Code" = field("Data Exch. Def Code"), "Data Exch. Line Def Code" = field("Data Exch. Line Def Code"), "Table ID" = field("Table ID");
                            LinkTable = "Data Exch. Mapping";
                            MinOccurs = Zero;
                            XmlName = 'DataExchFieldGrouping';

                            fieldattribute(FieldID; "Data Exch. Field Grouping"."Field ID")
                            {
                                Occurrence = Optional;

                                trigger OnBeforePassField()
                                begin
                                    if "Data Exch. Field Grouping"."Field ID" = 0 then
                                        currXMLport.Skip();
                                end;
                            }
                        }

                        trigger OnAfterGetRecord()
                        begin
                            "Data Exch. Field Mapping".Init();
                            "Data Exch. Field Mapping"."Column No." := 0;
                        end;
                    }
                }

                trigger OnBeforeInsertRecord()
                begin
                    "Data Exch. Def".Validate(Type);
                    "Data Exch. Def".Validate("File Type");
                    "Data Exch. Def".Validate("Reading/Writing XMLport");
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }
    var
        XMLSpaceTxt: Label '&#032;', Comment = 'Specifies XML representaion of space character.', Locked = true;

    local procedure AddTransformationRule(TransformationRule: Text)
    var
        TransformationRuleRec: Record "Transformation Rule";
    begin
        while (TransformationRule <> '') and not TempTransformationRuleRec.Get(TransformationRule) do begin
            TransformationRuleRec.Get(TransformationRule);
            TempTransformationRuleRec := TransformationRuleRec;
            TempTransformationRuleRec.Insert();
            TransformationRule := TransformationRuleRec."Next Transformation Rule";
        end;
    end;
}
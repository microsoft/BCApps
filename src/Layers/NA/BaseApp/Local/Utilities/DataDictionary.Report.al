// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using System.IO;
using System.Security.AccessControl;
using System.Utilities;

report 10315 "Data Dictionary"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Utilities/DataDictionary.rdlc';
    Caption = 'Data Dictionary';

    dataset
    {
        dataitem(TableDef; "Data Dictionary Info")
        {
            DataItemTableView = sorting("Table No.", "Field No.", Type, Language, "Key No.", "Line No.") where(Type = filter(Table), "Table No." = filter(< 2000000001));
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(TODAY; Format(Today))
            {
            }
            column(TableDef__Table_No__; "Table No.")
            {
            }
            column(TableDef_Name; Name)
            {
            }
            column(TableDef__Table_No___Control1020005; "Table No.")
            {
            }
            column(TableDef_Name_Control1020007; Name)
            {
            }
            column(TablePropertiesDescription_1_; TablePropertiesDescription[1])
            {
            }
            column(TablePropertiesDescription_2_; TablePropertiesDescription[2])
            {
            }
            column(TableDef_Field_No_; "Field No.")
            {
            }
            column(TableDef_Type; Type)
            {
            }
            column(TableDef_Language; Language)
            {
            }
            column(TableDef_Key_No_; "Key No.")
            {
            }
            column(TableDef_Line_No_; "Line No.")
            {
            }
            column(Data_DictionaryCaption; Data_DictionaryCaptionLbl)
            {
            }
            column(Table_No_Caption; Table_No_CaptionLbl)
            {
            }
            column(Continued_____Caption; Continued_____CaptionLbl)
            {
            }
            column(TableDef__Table_No___Control1020005Caption; FieldCaption("Table No."))
            {
            }
            dataitem(FieldDef; "Data Dictionary Info")
            {
                DataItemLink = "Table No." = field("Table No.");
                DataItemTableView = sorting("Table No.", "Field No.", Type, Language, "Key No.", "Line No.") where(Type = filter(Field));
                column(FieldDef__Field_No__; "Field No.")
                {
                }
                column(FieldDef_Name; Name)
                {
                }
                column(FieldDef__Data_Type_; "Data Type")
                {
                }
                column(FieldDef_Length; Length)
                {
                }
                column(FieldDef_Enabled; Enabled)
                {
                }
                column(FieldDef__Field_Class_; "Field Class")
                {
                }
                column(FieldDef_OnLookup; OnLookup)
                {
                }
                column(FieldDef_OnValidate; OnValidate)
                {
                }
                column(FieldDef_Description; Description)
                {
                }
                column(FieldDef_Table_No_; "Table No.")
                {
                }
                column(FieldDef_Type; Type)
                {
                }
                column(FieldDef_Language; Language)
                {
                }
                column(FieldDef_Key_No_; "Key No.")
                {
                }
                column(FieldDef_Line_No_; "Line No.")
                {
                }
                column(FieldDef__Field_No__Caption; FieldCaption("Field No."))
                {
                }
                column(FieldDef_NameCaption; FieldCaption(Name))
                {
                }
                column(FieldDef__Data_Type_Caption; FieldCaption("Data Type"))
                {
                }
                column(FieldDef_LengthCaption; FieldCaption(Length))
                {
                }
                column(FieldDef_EnabledCaption; FieldCaption(Enabled))
                {
                }
                column(FieldDef__Field_Class_Caption; FieldCaption("Field Class"))
                {
                }
                column(FieldDef_OnLookupCaption; FieldCaption(OnLookup))
                {
                }
                column(FieldDef_OnValidateCaption; FieldCaption(OnValidate))
                {
                }
                column(Field_No_Caption; Field_No_CaptionLbl)
                {
                }
                column(NameCaption; NameCaptionLbl)
                {
                }
                column(Data_TypeCaption; Data_TypeCaptionLbl)
                {
                }
                column(LengthCaption; LengthCaptionLbl)
                {
                }
                column(EnabledCaption; EnabledCaptionLbl)
                {
                }
                column(Field_ClassCaption; Field_ClassCaptionLbl)
                {
                }
                column(OnLookupCaption; OnLookupCaptionLbl)
                {
                }
                column(OnValidateCaption; OnValidateCaptionLbl)
                {
                }
                column(Description_Caption; Description_CaptionLbl)
                {
                }
                dataitem(CaptionML; "Data Dictionary Info")
                {
                    DataItemLink = "Table No." = field("Table No."), "Field No." = field("Field No.");
                    DataItemTableView = sorting("Table No.", "Field No.", Type, Language, "Key No.", "Line No.") where(Type = filter(Caption));
                    column(CaptionML_Value; Value)
                    {
                    }
                    column(Caption______CaptionML_Language________; 'Caption (' + Language + ') :')
                    {
                    }
                    column(ShowCaptions; ShowCaptions)
                    {
                    }
                    column(CaptionML_Table_No_; "Table No.")
                    {
                    }
                    column(CaptionML_Field_No_; "Field No.")
                    {
                    }
                    column(CaptionML_Type; Type)
                    {
                    }
                    column(CaptionML_Language; Language)
                    {
                    }
                    column(CaptionML_Key_No_; "Key No.")
                    {
                    }
                    column(CaptionML_Line_No_; "Line No.")
                    {
                    }
                }
                dataitem(OptionString; "Data Dictionary Info")
                {
                    DataItemLink = "Table No." = field("Table No."), "Field No." = field("Field No.");
                    DataItemTableView = sorting("Table No.", "Field No.", Type, Language, "Key No.", "Line No.") where(Type = filter(Option));
                    column(OptionString_Value; Value)
                    {
                    }
                    column(ShowOptionStrings; ShowOptionStrings)
                    {
                    }
                    column(OptionString_Table_No_; "Table No.")
                    {
                    }
                    column(OptionString_Field_No_; "Field No.")
                    {
                    }
                    column(OptionString_Type; Type)
                    {
                    }
                    column(OptionString_Language; Language)
                    {
                    }
                    column(OptionString_Key_No_; "Key No.")
                    {
                    }
                    column(OptionString_Line_No_; "Line No.")
                    {
                    }
                    column(Option_Values__Caption; Option_Values__CaptionLbl)
                    {
                    }
                }
                dataitem(TableRelation; "Data Dictionary Info")
                {
                    DataItemLink = "Table No." = field("Table No."), "Field No." = field("Field No.");
                    DataItemTableView = sorting("Table No.", "Field No.", Type, Language, "Key No.", "Line No.") where(Type = filter(Relation));
                    column(ShowTableRelations; ShowTableRelations)
                    {
                    }
                    column(TableRelation_Value; Value)
                    {
                    }
                    column(ShowTableRelations_Control7; ShowTableRelations)
                    {
                    }
                    column(TableRelation_Value_Control1020032; Value)
                    {
                    }
                    column(ShowTableRelations_Control8; ShowTableRelations)
                    {
                    }
                    column(TableRelation_Table_No_; "Table No.")
                    {
                    }
                    column(TableRelation_Field_No_; "Field No.")
                    {
                    }
                    column(TableRelation_Type; Type)
                    {
                    }
                    column(TableRelation_Language; Language)
                    {
                    }
                    column(TableRelation_Key_No_; "Key No.")
                    {
                    }
                    column(TableRelation_Line_No_; "Line No.")
                    {
                    }
                    column(Table_Relatation_Caption; Table_Relatation_CaptionLbl)
                    {
                    }
                    column(Continued_____Caption_Control1020075; Continued_____Caption_Control1020075Lbl)
                    {
                    }
                    column(Table_Relatation_Caption_Control1020033; Table_Relatation_Caption_Control1020033Lbl)
                    {
                    }
                }
                dataitem(CalcFormula; "Data Dictionary Info")
                {
                    DataItemLink = "Table No." = field("Table No."), "Field No." = field("Field No.");
                    DataItemTableView = sorting("Table No.", "Field No.", Type, Language, "Key No.", "Line No.") where(Type = filter(CalcFormula));
                    column(ShowCalcFormulas; ShowCalcFormulas)
                    {
                    }
                    column(CalcFormula_Value; Value)
                    {
                    }
                    column(ShowCalcFormulas_Control9; TotalKey4)
                    {
                    }
                    column(CalcFormula_Value_Control1020044; Value)
                    {
                    }
                    column(ShowCalcFormulas_Control12; ShowCalcFormulas)
                    {
                    }
                    column(CalcFormula_Table_No_; "Table No.")
                    {
                    }
                    column(CalcFormula_Field_No_; "Field No.")
                    {
                    }
                    column(CalcFormula_Type; Type)
                    {
                    }
                    column(CalcFormula_Language; Language)
                    {
                    }
                    column(CalcFormula_Key_No_; "Key No.")
                    {
                    }
                    column(CalcFormula_Line_No_; "Line No.")
                    {
                    }
                    column(CalcFormula_Caption; CalcFormula_CaptionLbl)
                    {
                    }
                    column(Continued_____Caption_Control1020077; Continued_____Caption_Control1020077Lbl)
                    {
                    }
                    column(CalcFormula_Caption_Control1020039; CalcFormula_Caption_Control1020039Lbl)
                    {
                    }
                }
            }
            dataitem("Keys"; "Data Dictionary Info")
            {
                DataItemLink = "Table No." = field("Table No.");
                DataItemTableView = sorting("Table No.", "Field No.", Type, Language, "Key No.", "Line No.") where(Type = filter(Key));
                column(ShowKeys; ShowKeys)
                {
                }
                column(ShowKeys_Control14; ShowKeys)
                {
                }
                column(Keys__Key_No__; "Key No.")
                {
                }
                column(Keys_Enabled; Enabled)
                {
                }
                column(TotalKey; TotalKey)
                {
                }
                column(TotalKey4; TotalKey4)
                {
                }
                column(Keys_Enabled_Control1020049; Enabled)
                {
                }
                column(Keys__Key_No___Control1020041; "Key No.")
                {
                }
                column(TotalKey_Control4; TotalKey)
                {
                }
                column(TotalKey2; TotalKey2)
                {
                }
                column(Keys_Table_No_; "Table No.")
                {
                }
                column(Keys_Field_No_; "Field No.")
                {
                }
                column(Keys_Type; Type)
                {
                }
                column(Keys_Language; Language)
                {
                }
                column(Keys_Line_No_; "Line No.")
                {
                }
                column(Keys_Enabled_Control1020049Caption; FieldCaption(Enabled))
                {
                }
                column(ValueCaption; ValueCaptionLbl)
                {
                }
                column(KeysCaption; KeysCaptionLbl)
                {
                }
                column(Keys__Key_No___Control1020041Caption; FieldCaption("Key No."))
                {
                }
                column(Key_No_Caption; Key_No_CaptionLbl)
                {
                }
                column(EnabledCaption_Control1020048; EnabledCaption_Control1020048Lbl)
                {
                }
                column(ValueCaption_Control1020059; ValueCaption_Control1020059Lbl)
                {
                }
                column(Continued_____Caption_Control1020060; Continued_____Caption_Control1020060Lbl)
                {
                }
                dataitem(SumIndexFields; "Data Dictionary Info")
                {
                    DataItemLink = "Table No." = field("Table No."), "Key No." = field("Key No.");
                    DataItemTableView = sorting("Table No.", "Field No.", Type, Language, "Key No.", "Line No.") where(Type = filter(SumIndexField));
                    column(ShowSumIndexFields4; ShowSumIndexFields4)
                    {
                    }
                    column(SumIndexFields_Value; Value)
                    {
                    }
                    column(ShowSumIndexFields2; ShowSumIndexFields2)
                    {
                    }
                    column(SumIndexFields_Value_Control1020057; Value)
                    {
                    }
                    column(ShowSumIndexFieldS3; ShowSumIndexFieldS3)
                    {
                    }
                    column(SumIndexFields_Table_No_; "Table No.")
                    {
                    }
                    column(SumIndexFields_Field_No_; "Field No.")
                    {
                    }
                    column(SumIndexFields_Type; Type)
                    {
                    }
                    column(SumIndexFields_Language; Language)
                    {
                    }
                    column(SumIndexFields_Key_No_; "Key No.")
                    {
                    }
                    column(SumIndexFields_Line_No_; "Line No.")
                    {
                    }
                    column(Sum_Index_Fields_Caption; Sum_Index_Fields_CaptionLbl)
                    {
                    }
                    column(Continued_____Caption_Control1020079; Continued_____Caption_Control1020079Lbl)
                    {
                    }
                    column(Sum_Index_Fields_Caption_Control1020052; Sum_Index_Fields_Caption_Control1020052Lbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        ShowSumIndexFields4 := (ShowSumIndexFields and (Keys."Line No." = 1000));
                        ShowSumIndexFields2 := (ShowSumIndexFields and
                                                ("Line No." = 1000) and
                                                (Keys."Line No." = 1000));
                        ShowSumIndexFieldS3 := (ShowSumIndexFields and
                                                ("Line No." > 1000) and
                                                (Keys."Line No." = 1000));
                    end;
                }
                dataitem(KeyGroups; "Data Dictionary Info")
                {
                    DataItemLink = "Table No." = field("Table No."), "Key No." = field("Key No.");
                    DataItemTableView = sorting("Table No.", "Field No.", Type, Language, "Key No.", "Line No.") where(Type = filter(KeyGroup));
                    column(KeyGroups_Value; Value)
                    {
                    }
                    column(ShowKeyGroups2; ShowKeyGroups2)
                    {
                    }
                    column(KeyGroups_Table_No_; "Table No.")
                    {
                    }
                    column(KeyGroups_Field_No_; "Field No.")
                    {
                    }
                    column(KeyGroups_Type; Type)
                    {
                    }
                    column(KeyGroups_Language; Language)
                    {
                    }
                    column(KeyGroups_Key_No_; "Key No.")
                    {
                    }
                    column(KeyGroups_Line_No_; "Line No.")
                    {
                    }
                    column(Key_Group_Caption; Key_Group_CaptionLbl)
                    {
                    }
                    column(Continued_____Caption_Control1020081; Continued_____Caption_Control1020081Lbl)
                    {
                    }
                    column(Key_Group_Caption_Control1020058; Key_Group_Caption_Control1020058Lbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        ShowKeyGroups2 := (ShowKeyGroups and (Keys."Line No." = 1000));
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    DataDictionary: Record "Data Dictionary Info";
                begin
                    if ShowKeys then begin
                        Clear(TotalKey);
                        DataDictionary.SetRange("Table No.", "Table No.");
                        DataDictionary.SetRange(Type, Type);
                        DataDictionary.SetRange("Field No.", "Field No.");
                        DataDictionary.SetRange("Key No.", "Key No.");
                        if DataDictionary.FindSet() then
                            repeat
                                TotalKey := TotalKey + DataDictionary.Value;
                            until (DataDictionary.Next() = 0)
                    end;
                    TotalKey4 := (ShowKeys and (StrLen(TotalKey) <= MaxStrLen(Value)));
                    TotalKey2 := (ShowKeys and
                                  (StrLen(TotalKey) > MaxStrLen(Value)) and
                                  ("Line No." = 1000));
                end;
            }
            dataitem(PermissionRange; "Data Dictionary Info")
            {
                DataItemLink = "Table No." = field("Table No.");
                DataItemTableView = sorting("Table No.", "Field No.", Type, Language, "Key No.", "Line No.") where(Type = filter(Permission));
                column(ShowPermissions; ShowPermissions)
                {
                }
                column(PermissionRange_Description; Description)
                {
                }
                column(PermissionRange__Read_Permission_; "Read Permission")
                {
                }
                column(PermissionRange__Insert_Permission_; "Insert Permission")
                {
                }
                column(PermissionRange__Modify_Permission_; "Modify Permission")
                {
                }
                column(PermissionRange__Delete_Permission_; "Delete Permission")
                {
                }
                column(PermissionRange__Execute_Permission_; "Execute Permission")
                {
                }
                column(ShowPermissions_Control5; ShowPermissions)
                {
                }
                column(PermissionRange_Table_No_; "Table No.")
                {
                }
                column(PermissionRange_Field_No_; "Field No.")
                {
                }
                column(PermissionRange_Type; Type)
                {
                }
                column(PermissionRange_Language; Language)
                {
                }
                column(PermissionRange_Key_No_; "Key No.")
                {
                }
                column(PermissionRange_Line_No_; "Line No.")
                {
                }
                column(PermissionsCaption; PermissionsCaptionLbl)
                {
                }
                column(ReadCaption; ReadCaptionLbl)
                {
                }
                column(InsertCaption; InsertCaptionLbl)
                {
                }
                column(ModifyCaption; ModifyCaptionLbl)
                {
                }
                column(DeleteCaption; DeleteCaptionLbl)
                {
                }
                column(ExecuteCaption; ExecuteCaptionLbl)
                {
                }
            }
            dataitem(NewPage; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
            }

            trigger OnAfterGetRecord()
            begin
                TablePropertiesDescription[1] := CopyStr(Description, 1, StrPos(Description, VersionListTag) - 3);
                TablePropertiesDescription[2] := CopyStr(Description, StrPos(Description, VersionListTag));
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Instructions; Instructions)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Instructions';
                        Editable = false;
                        MultiLine = true;
                        ToolTip = 'Specifies if instructions on using the report are included.';
                    }
                    group(Control1020016)
                    {
                        ShowCaption = false;
                        group("Table Information")
                        {
                            Caption = 'Table Information';
                            field(ShowCaptions; ShowCaptions)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Show Captions';
                                ToolTip = 'Specifies if object captions are included in the dictionary.';
                            }
                            field(ShowOptionStrings; ShowOptionStrings)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Show Option Strings';
                                ToolTip = 'Specifies if option strings are included in the dictionary.';
                            }
                            field(ShowTableRelations; ShowTableRelations)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Show Table Relations';
                                ToolTip = 'Specifies if table relation information is included in the dictionary.';
                            }
                            field(ShowCalcFormulas; ShowCalcFormulas)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Show CalcFormulas';
                            }
                        }
                        field(ShowKeys; ShowKeys)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Show Key Information';
                            ToolTip = 'Specifies if key information is included in the dictionary.';

                            trigger OnValidate()
                            begin
                                ShowKeysOnPush();
                            end;
                        }
                        field(ShowSumIndexFieldsControl; ShowSumIndexFields)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Show Sum Index Fields';
                            Enabled = ShowSumIndexFieldsControlEnabl;
                            ToolTip = 'Specifies if sum index (SIFT) fields are included in the dictionary.';
                        }
                        field(ShowKeyGroupControl; ShowKeyGroups)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Show Key Groups';
                            Enabled = ShowKeyGroupControlEnable;
                            ToolTip = 'Specifies if key groups are included in the dictionary.';
                        }
                        field(ShowPermissions; ShowPermissions)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Show Permissions';
                            ToolTip = 'Specifies if permission information is included in the dictionary.';
                        }
                    }
                    field(OneTablePerPage; OneTablePerPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'One Table per Page';
                        ToolTip = 'Specifies that each page shows data for one table.';
                    }
                    field(DeleteData; DeleteData)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Delete Data when the report is done';
                        ToolTip = 'Specifies that the found data is deleted when you close the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            ShowKeyGroupControlEnable := true;
            ShowSumIndexFieldsControlEnabl := true;
        end;

        trigger OnOpenPage()
        begin
            OneTablePerPage := true;
            ShowKeys := true;
            SetAllOptions(true);

            Instructions := 'To create the Data Dictionary, You will need to export all the table\' +
              'objects in the database in a text format.';
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        DataDictionary: Record "Data Dictionary Info";
    begin
        FilePtr.Close();
        if DeleteData then
            if DataDictionary.FindFirst() then
                DataDictionary.DeleteAll();
    end;

    trigger OnPreReport()
    var
        DataDictionary: Record "Data Dictionary Info";
        FileMgt: Codeunit "File Management";
    begin
        if FileName = '' then
            FileName := FileMgt.UploadFile('', '*.txt');

        if DataDictionary.FindFirst() then
            DataDictionary.DeleteAll();

        ParseFile(FileName);
    end;

    var
        ObjectTag: Label 'OBJECT Table';
        FieldsTag: Label 'FIELDS';
        ObjectPropertiesTag: Label 'OBJECT-PROPERTIES';
        PropertiesTag: Label 'PROPERTIES';
        KeysTag: Label 'KEYS';
        CodeTag: Label 'CODE';
        CalcFieldsTag: Label 'CALCFIELDS';
        DateTag: Label 'Date=';
        TimeTag: Label 'Time=';
        ModifiedTag: Label 'Modified=';
        VersionListTag: Label 'Version List=';
        OptionCaptionMLTag: Label 'OptionCaptionML=';
        CaptionMLTag: Label 'CaptionML=';
        FieldClassTag: Label 'FieldClass=';
        DescriptionTag: Label 'Description=';
        TableRelationTag: Label 'TableRelation=';
        ValidateTableRelationTag: Label 'ValidateTableRelation=';
        TestTableRelationTag: Label 'TestTableRelation=';
        OptionStringTag: Label 'OptionString=';
        CalcFormulaTag: Label 'CalcFormula=';
        DecimalPlacesTag: Label 'DecimalPlaces=';
        SumIndexFieldsTag: Label 'SumIndexFields=';
        KeyGroupsTag: Label 'KeyGroups=';
        OnLookupTag: Label 'OnLookup=';
        OnValidateTag: Label 'OnValidate=';
        SIFTLevelsToMaintainTag: Label 'SIFTLevelsToMaintain=';
        WhereTag: Label 'WHERE';
        StartOfField: Label '    {';
        EndOfField: Label '}';
        StartOfList: Label '[';
        EndOfList: Label ']';
        CountryTag: Label '=';
        EndOfValue: Label ';';
        FilePtr: File;
        ReadCount: Integer;
        FileLen: Integer;
        OneTablePerPage: Boolean;
        MultipleCaptionML: Boolean;
        EndOfSubValue: Label ',';
        CurrentTableNo: Integer;
        CurrentFieldNo: Integer;
        SkipCode: Boolean;
        FilterValue: Label '|';
        Status: Dialog;
        ShowCaptions: Boolean;
        ShowOptionStrings: Boolean;
        ShowTableRelations: Boolean;
        ShowCalcFormulas: Boolean;
        ShowKeys: Boolean;
        ShowSumIndexFields: Boolean;
        ShowKeyGroups: Boolean;
        ShowPermissions: Boolean;
        Instructions: Text[1000];
        TotalKey: Text[1000];
        DeleteData: Boolean;
        TablePropertiesDescription: array[2] of Text[100];
        ShowSumIndexFieldsControlEnabl: Boolean;
        ShowKeyGroupControlEnable: Boolean;
        TotalKey2: Boolean;
        TotalKey4: Boolean;
        ShowSumIndexFields2: Boolean;
        ShowSumIndexFieldS3: Boolean;
        ShowSumIndexFields4: Boolean;
        ShowKeyGroups2: Boolean;
        FileName: Text;
        Data_DictionaryCaptionLbl: Label 'Data Dictionary';
        Table_No_CaptionLbl: Label 'Table No.';
        Continued_____CaptionLbl: Label '(Continued ...)';
        Field_No_CaptionLbl: Label 'Field No.';
        NameCaptionLbl: Label 'Name';
        Data_TypeCaptionLbl: Label 'Data Type';
        LengthCaptionLbl: Label 'Length';
        EnabledCaptionLbl: Label 'Enabled';
        Field_ClassCaptionLbl: Label 'Field Class';
        OnLookupCaptionLbl: Label 'OnLookup';
        OnValidateCaptionLbl: Label 'OnValidate';
        Description_CaptionLbl: Label 'Description:';
        Option_Values__CaptionLbl: Label 'Option Values :';
        Table_Relatation_CaptionLbl: Label 'Table relation:';
        Continued_____Caption_Control1020075Lbl: Label '(Continued ...)';
        Table_Relatation_Caption_Control1020033Lbl: Label 'Table relation:';
        CalcFormula_CaptionLbl: Label 'CalcFormula:';
        Continued_____Caption_Control1020077Lbl: Label '(Continued ...)';
        CalcFormula_Caption_Control1020039Lbl: Label 'CalcFormula:';
        ValueCaptionLbl: Label 'Value';
        KeysCaptionLbl: Label 'Keys';
        Key_No_CaptionLbl: Label 'Key No.';
        EnabledCaption_Control1020048Lbl: Label 'Enabled';
        ValueCaption_Control1020059Lbl: Label 'Value';
        Continued_____Caption_Control1020060Lbl: Label '(Continued ...)';
        Sum_Index_Fields_CaptionLbl: Label 'Sum Index Fields:';
        Continued_____Caption_Control1020079Lbl: Label '(Continued ...)';
        Sum_Index_Fields_Caption_Control1020052Lbl: Label 'Sum Index Fields:';
        Key_Group_CaptionLbl: Label 'Key Group:';
        Continued_____Caption_Control1020081Lbl: Label '(Continued ...)';
        Key_Group_Caption_Control1020058Lbl: Label 'Key Group:';
        PermissionsCaptionLbl: Label 'Permissions';
        ReadCaptionLbl: Label 'Read';
        InsertCaptionLbl: Label 'Insert';
        ModifyCaptionLbl: Label 'Modify';
        DeleteCaptionLbl: Label 'Delete';
        ExecuteCaptionLbl: Label 'Execute';

    procedure ParseFile(FileName: Text)
    var
        ReadLine: Text[1024];
    begin
        FilePtr.TextMode(true);
        FilePtr.Open(FileName);
        Status.Open('Filename  : #1############################################ \' +
          'Table No. : #2######### #6################################ \' +
          'Field No. : #3######### \' +
          '            @9@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\');

        FileLen := FilePtr.Len;

        Status.Update(1, FilePtr.Name);

        while ReadCount <= FileLen do begin
            ReadLine := ReadData();

            if StrPos(ReadLine, ObjectTag) <> 0 then begin
                SkipCode := false;
                GetTableInfo(ReadLine);
            end;

            if not SkipCode then begin
                if StrPos(ReadLine, ObjectPropertiesTag) <> 0 then
                    GetTableProperties();

                if ((StrPos(ReadLine, FieldsTag) <> 0) and
                    (StrPos(ReadLine, CalcFieldsTag) = 0))
                then
                    GetFieldInfo(ReadLine);

                if StrPos(ReadLine, KeysTag) <> 0 then begin
                    GetKeyInfo(ReadLine);
                    GetPermissionRange();
                end;
            end;
        end;

        Status.Close();
    end;

    procedure GetTableInfo(Input: Text[1024])
    var
        Pos1: Integer;
        Pos2: Integer;
        DataDictionary: Record "Data Dictionary Info";
    begin
        Pos1 := StrPos(Input, ObjectTag) + StrLen(ObjectTag) + 1;
        Input := CopyStr(Input, Pos1);

        Pos1 := 1;
        Pos2 := StrPos(Input, ' ') - 1;

        Clear(DataDictionary);
        DataDictionary.Init();
        Evaluate(DataDictionary."Table No.", GetInfo(Input, Pos1, Pos2));
        DataDictionary.Type := DataDictionary.Type::Table;
        DataDictionary.Name := CopyStr(Input, 1, MaxStrLen(DataDictionary.Name));
        if DataDictionary.Insert() then begin
            CurrentTableNo := DataDictionary."Table No.";
            CurrentFieldNo := 0
        end;

        Status.Update(2, CurrentTableNo);
    end;

    procedure GetTableProperties()
    var
        InputText: Text[1024];
        DataDictionary: Record "Data Dictionary Info";
    begin
        DataDictionary.SetRange("Table No.", CurrentTableNo);
        DataDictionary.SetRange(Type, DataDictionary.Type::Table);
        if DataDictionary.FindFirst() then;

        while StrPos(InputText, PropertiesTag) = 0 do begin
            InputText := ReadData();

            if (StrPos(InputText, DateTag) <> 0) or
               (StrPos(InputText, TimeTag) <> 0) or
               (StrPos(InputText, ModifiedTag) <> 0) or
               (StrPos(InputText, VersionListTag) <> 0)
            then begin
                InputText := DelChr(InputText, '<', ' ');
                InputText := DelChr(InputText, '>', EndOfValue);
                if DataDictionary.Description <> '' then
                    DataDictionary.Description :=
                      CopyStr(DataDictionary.Description + ', ', 1, MaxStrLen(DataDictionary.Description));
                DataDictionary.Description :=
                  CopyStr(DataDictionary.Description + InputText, 1, MaxStrLen(DataDictionary.Description));
            end;
        end;

        if StrPos(InputText, PropertiesTag) <> 0 then begin
            DataDictionary.Description := DelChr(DataDictionary.Description, '<>', ' ');
            DataDictionary.Modify();
        end;
    end;

    procedure GetFieldInfo(var InputText: Text[1024])
    var
        DataDictionary: Record "Data Dictionary Info";
    begin
        while StrPos(InputText, KeysTag) = 0 do begin
            InputText := ReadData();

            if StrPos(InputText, StartOfField) <> 0 then begin
                DataDictionary.Init();
                DataDictionary."Table No." := CurrentTableNo;
                DataDictionary.Type := DataDictionary.Type::Field;
                DataDictionary."Field Class" := 'Normal';
                GetFieldDef(InputText, DataDictionary)
            end;

            GetFieldProperties(InputText, DataDictionary);
        end;
    end;

    procedure GetFieldDef(var InputText: Text[1024]; var InDataDictionary: Record "Data Dictionary Info")
    begin
        Status.Update(6, 'Getting Field Definition ...');

        InputText := CopyStr(InputText, StrPos(InputText, StartOfField) + StrLen(StartOfField) + 1);
        Evaluate(InDataDictionary."Field No.", ParseFieldLine(InputText));
        if InDataDictionary.Insert() then
            CurrentFieldNo := InDataDictionary."Field No.";

        InDataDictionary.Enabled := CopyStr(ParseFieldLine(InputText), 1, MaxStrLen(InDataDictionary.Enabled));
        if InDataDictionary.Enabled = '' then
            InDataDictionary.Enabled := 'Yes';
        InDataDictionary.Name := CopyStr(ParseFieldLine(InputText), 1, MaxStrLen(InDataDictionary.Name));
        InDataDictionary."Data Type" := CopyStr(ParseFieldLine(InputText), 1, MaxStrLen(InDataDictionary."Data Type"));
        ParseFieldType(InDataDictionary);

        Status.Update(3, CurrentFieldNo);
    end;

    procedure GetFieldProperties(var InputText: Text[1024]; InDataDictionary: Record "Data Dictionary Info")
    begin
        Status.Update(6, 'Getting Field Properties ...');

        if ((StrPos(InputText, TableRelationTag) <> 0) and
            (StrPos(InputText, ValidateTableRelationTag) = 0) and
            (StrPos(InputText, TestTableRelationTag) = 0))
        then
            GetFieldTableRelation(InputText);

        if StrPos(InputText, FieldClassTag) <> 0 then
            GetFieldClass(InputText, InDataDictionary);

        if StrPos(InputText, CalcFormulaTag) <> 0 then
            GetFieldCalcFormula(InputText);

        if StrPos(InputText, DescriptionTag) <> 0 then
            GetFieldDescription(InputText, InDataDictionary);

        if StrPos(InputText, OnLookupTag) <> 0 then
            GetOnLookup(InputText);

        if StrPos(InputText, OnValidateTag) <> 0 then
            GetOnValidate(InputText);

        if (((StrPos(InputText, CaptionMLTag) <> 0) and
             (StrPos(InputText, OptionCaptionMLTag) = 0))
            or MultipleCaptionML)
        then
            GetFieldCaptionML(InputText);

        if StrPos(InputText, DecimalPlacesTag) <> 0 then
            GetFieldDecimalPlaces(InputText, InDataDictionary);

        if StrPos(InputText, OptionStringTag) <> 0 then
            GetFieldOptionString(InputText);
    end;

    procedure ParseFieldLine(var InputText: Text[1024]): Text[1024]
    var
        TempText: Text[1024];
        Pos1: Integer;
        Pos2: Integer;
    begin
        SetPositions(Pos1, Pos2, InputText, '*');
        if Pos2 > 0 then
            TempText := GetInfo(InputText, Pos1, Pos2)
        else begin
            TempText := ' ';
            InputText := CopyStr(InputText, 2)
        end;

        exit(TempText);
    end;

    procedure ParseFieldType(var InDataDictionary: Record "Data Dictionary Info")
    var
        DataTypes: array[17] of Text[20];
        ICount: Integer;
        TempDataType: Text[20];
    begin
        // **************************************
        // This list must be left in this order
        // **************************************
        DataTypes[1] := 'BigInteger';
        DataTypes[2] := 'Binary';
        DataTypes[3] := 'BLOB';
        DataTypes[4] := 'Boolean';
        DataTypes[5] := 'Code';
        DataTypes[6] := 'DateTime';
        DataTypes[7] := 'DateFormula';
        DataTypes[8] := 'Date';
        DataTypes[9] := 'Decimal';
        DataTypes[10] := 'Duration';
        DataTypes[11] := 'GUID';
        DataTypes[12] := 'Integer';
        DataTypes[13] := 'Option';
        DataTypes[14] := 'RecordID';
        DataTypes[15] := 'TableFilter';
        DataTypes[16] := 'Text';
        DataTypes[17] := 'Time';

        TempDataType := InDataDictionary."Data Type";

        for ICount := 1 to 17 do
            if StrPos(TempDataType, UpperCase(DataTypes[ICount])) <> 0 then begin
                InDataDictionary."Data Type" := CopyStr(TempDataType, 1, StrLen(DataTypes[ICount]));

                if StrLen(TempDataType) <> StrLen(DataTypes[ICount]) then
                    InDataDictionary.Length := CopyStr(TempDataType, StrLen(DataTypes[ICount]) + 1);

                InDataDictionary.Modify();
                exit
            end;
    end;

    procedure GetFieldClass(var InputText: Text[1024]; var InDataDictionary: Record "Data Dictionary Info")
    var
        Pos1: Integer;
        Pos2: Integer;
    begin
        Status.Update(6, 'Getting Field Class ...');

        SetPositions(Pos1, Pos2, InputText, FieldClassTag);
        InDataDictionary."Field Class" :=
          CopyStr(GetInfo(InputText, Pos1, Pos2), 1, MaxStrLen(InDataDictionary."Field Class"));
        InDataDictionary.Modify();
    end;

    procedure GetFieldDescription(var InputText: Text[1024]; var InDataDictionary: Record "Data Dictionary Info")
    var
        Pos1: Integer;
        Pos2: Integer;
    begin
        Status.Update(6, 'Getting Field Description ...');

        SetPositions(Pos1, Pos2, InputText, DescriptionTag);
        InDataDictionary.Description :=
          CopyStr(GetInfo(InputText, Pos1, Pos2), 1, MaxStrLen(InDataDictionary.Description));
        InDataDictionary.Modify();
    end;

    procedure GetFieldDecimalPlaces(var InputText: Text[1024]; var InDataDictionary: Record "Data Dictionary Info")
    var
        Pos1: Integer;
        Pos2: Integer;
    begin
        Status.Update(6, 'Getting Decimal Places ...');

        SetPositions(Pos1, Pos2, InputText, DecimalPlacesTag);
        InDataDictionary.Length :=
          CopyStr(GetInfo(InputText, Pos1, Pos2), 1, MaxStrLen(InDataDictionary.Length));
        InDataDictionary.Modify();
    end;

    procedure GetFieldCaptionML(var InputText: Text[1024])
    var
        Pos1: Integer;
        Pos2: Integer;
        DataDictionary: Record "Data Dictionary Info";
    begin
        Status.Update(6, 'Getting Field Caption ML ...');

        DataDictionary.Init();
        DataDictionary."Table No." := CurrentTableNo;
        DataDictionary.Type := DataDictionary.Type::Caption;
        DataDictionary."Field No." := CurrentFieldNo;

        if not MultipleCaptionML then begin
            SetPositions(Pos1, Pos2, InputText, CaptionMLTag);
            InputText := CopyStr(InputText, Pos1, Pos2);
        end else
            InputText := DelChr(InputText, '<', ' ');

        if StrPos(InputText, StartOfList) <> 0 then begin
            InputText := CopyStr(InputText, 2);
            MultipleCaptionML := true
        end;

        Pos1 := 1;
        Pos2 := StrPos(InputText, CountryTag);

        Pos2 := Pos2 - Pos1;
        DataDictionary.Language :=
          CopyStr(GetInfo(InputText, Pos1, Pos2), 1, MaxStrLen(DataDictionary.Language));

        Pos2 := StrPos(InputText, EndOfValue);
        if Pos2 = 0 then
            Pos2 := StrPos(InputText, EndOfField);
        if Pos2 = 0 then
            Pos2 := StrLen(InputText);

        Pos2 := Pos2 - Pos1 + 1;
        DataDictionary.Value :=
          CopyStr(GetInfo(InputText, Pos1, Pos2), 1, MaxStrLen(DataDictionary.Value));

        if StrPos(DataDictionary.Value, EndOfList) <> 0 then begin
            DataDictionary.Value := CopyStr(DataDictionary.Value, 1, StrPos(DataDictionary.Value, EndOfList) - 1);
            MultipleCaptionML := false
        end;

        DataDictionary.Insert();
    end;

    procedure GetFieldOptionString(var InputText: Text[1024])
    var
        Pos1: Integer;
        Pos2: Integer;
        DataDictionary: Record "Data Dictionary Info";
    begin
        Status.Update(6, 'Getting Field Option String ...');

        DataDictionary.Init();
        DataDictionary."Table No." := CurrentTableNo;
        DataDictionary.Type := DataDictionary.Type::Option;
        DataDictionary."Field No." := CurrentFieldNo;
        DataDictionary."Line No." := 1000;

        SetPositions(Pos1, Pos2, InputText, OptionStringTag);

        InputText := CopyStr(InputText, Pos1, Pos2);

        if StrPos(InputText, StartOfList) <> 0 then begin
            InputText := CopyStr(InputText, 2);
            Pos2 := Pos2 - 1;
        end;

        if Pos2 > MaxStrLen(DataDictionary.Value) then
            MultipleLines(InputText, DataDictionary, EndOfSubValue, true)
        else begin
            Pos1 := 1;
            DataDictionary.Value := CopyStr(InputText, Pos1, Pos2)
        end;

        if StrPos(DataDictionary.Value, EndOfList) <> 0 then
            DataDictionary.Value := CopyStr(DataDictionary.Value, 1, StrPos(DataDictionary.Value, EndOfList) - 1);

        DataDictionary.Insert();
    end;

    procedure GetFieldTableRelation(var InputText: Text[1024])
    var
        Pos1: Integer;
        Pos2: Integer;
        DataDictionary: Record "Data Dictionary Info";
    begin
        Status.Update(6, 'Getting Table Relations ...');

        DataDictionary.Init();
        DataDictionary."Table No." := CurrentTableNo;
        DataDictionary.Type := DataDictionary.Type::Relation;
        DataDictionary."Field No." := CurrentFieldNo;
        DataDictionary."Line No." := 1000;

        SetPositions(Pos1, Pos2, InputText, TableRelationTag);

        InputText := CopyStr(InputText, Pos1);

        if ((StrPos(InputText, EndOfValue) = 0) and
            (StrPos(InputText, EndOfField) = 0))
        then
            while ((StrPos(InputText, EndOfValue) = 0) and
                   (StrPos(InputText, EndOfField) = 0))
            do begin
                if StrLen(InputText) > MaxStrLen(DataDictionary.Value) then begin
                    if StrPos(InputText, WhereTag) <> 0 then
                        MultipleLines(InputText, DataDictionary, WhereTag, true)
                    else
                        MultipleLines(InputText, DataDictionary, FilterValue, true)
                end else
                    DataDictionary.Value := CopyStr(InputText, 1, MaxStrLen(DataDictionary.Value));

                DataDictionary.Insert();

                InputText := ReadData();
                InputText := DelChr(InputText, '<', ' ');
                DataDictionary."Line No." := DataDictionary."Line No." + 1000;
            end;

        if StrLen(InputText) > MaxStrLen(DataDictionary.Value) then begin
            if StrPos(InputText, WhereTag) <> 0 then
                MultipleLines(InputText, DataDictionary, WhereTag, true)
            else
                MultipleLines(InputText, DataDictionary, FilterValue, true)
        end else begin
            Pos1 := 1;
            Pos2 := StrPos(InputText, EndOfValue);
            if Pos2 = 0 then
                Pos2 := StrPos(InputText, EndOfField);

            DataDictionary.Value := CopyStr(InputText, 1, Pos2 - Pos1);
        end;

        DataDictionary.Insert();
    end;

    procedure GetFieldCalcFormula(var InputText: Text[1024])
    var
        Pos1: Integer;
        Pos2: Integer;
        DataDictionary: Record "Data Dictionary Info";
    begin
        Status.Update(6, 'Getting Field CalcFormula ...');

        DataDictionary.Init();
        DataDictionary."Table No." := CurrentTableNo;
        DataDictionary.Type := DataDictionary.Type::CalcFormula;
        DataDictionary."Field No." := CurrentFieldNo;
        DataDictionary."Line No." := 1000;

        Pos1 := StrPos(InputText, CalcFormulaTag) + StrLen(CalcFormulaTag);
        InputText := CopyStr(InputText, Pos1);

        while ((StrPos(InputText, EndOfValue) = 0) and
               (StrPos(InputText, EndOfField) = 0))
        do begin
            InputText := DelChr(InputText, '<', ' ');

            if StrLen(InputText) > MaxStrLen(DataDictionary.Value) then
                MultipleLines(InputText, DataDictionary, FilterValue, true)
            else
                DataDictionary.Value := CopyStr(InputText, 1, MaxStrLen(DataDictionary.Value));

            DataDictionary.Insert();

            InputText := ReadData();
            DataDictionary."Line No." := DataDictionary."Line No." + 1000;
            DataDictionary.Value := '';
        end;

        Pos1 := 1;
        Pos2 := StrPos(InputText, EndOfValue);
        if Pos2 = 0 then
            Pos2 := StrPos(InputText, EndOfField);

        InputText := DelChr(InputText, '<', ' ');
        DataDictionary.Value := CopyStr(InputText, 1, Pos2 - Pos1);
        DataDictionary.Value := DelChr(DataDictionary.Value, '>', ';');

        DataDictionary.Insert();
    end;

    procedure GetOnValidate(var InputText: Text[1024])
    var
        DataDictionary: Record "Data Dictionary Info";
    begin
        DataDictionary.SetRange("Table No.", CurrentTableNo);
        DataDictionary.SetRange(Type, DataDictionary.Type::Field);
        DataDictionary.SetRange("Field No.", CurrentFieldNo);
        if DataDictionary.FindFirst() then begin
            DataDictionary.OnValidate := true;
            DataDictionary.Modify();
        end;

        MatchBeginEnd(InputText);
    end;

    procedure GetOnLookup(var InputText: Text[1024])
    var
        DataDictionary: Record "Data Dictionary Info";
    begin
        DataDictionary.SetRange("Table No.", CurrentTableNo);
        DataDictionary.SetRange(Type, DataDictionary.Type::Field);
        DataDictionary.SetRange("Field No.", CurrentFieldNo);
        if DataDictionary.FindFirst() then begin
            DataDictionary.OnLookup := true;
            DataDictionary.Modify();
        end;

        MatchBeginEnd(InputText);
    end;

    procedure GetKeyInfo(var InputText: Text[1024])
    var
        DataDictionary: Record "Data Dictionary Info";
    begin
        Status.Update(6, 'Getting Key Information ...');

        while StrPos(InputText, CodeTag) = 0 do begin
            InputText := ReadData();

            if StrPos(InputText, StartOfField) <> 0 then begin
                DataDictionary.Init();
                DataDictionary."Table No." := CurrentTableNo;
                DataDictionary.Type := DataDictionary.Type::Key;
                DataDictionary."Field No." := 0;
                DataDictionary."Line No." := 1000;
                DataDictionary."Key No." := DataDictionary."Key No." + 1;
                GetKeyDef(InputText, DataDictionary);
            end;

            GetKeyProperties(InputText, DataDictionary);
        end;

        SkipCode := true;
    end;

    procedure GetKeyDef(var InputText: Text[1024]; InDataDictionary: Record "Data Dictionary Info")
    var
        Pos1: Integer;
        Pos2: Integer;
        KeyText: Text[1024];
    begin
        Status.Update(6, 'Getting Key Definition ...');

        SetPositions(Pos1, Pos2, InputText, StartOfField);

        InDataDictionary.Enabled := CopyStr(GetInfo(InputText, Pos1, Pos2), 1, MaxStrLen(InDataDictionary.Enabled));
        if InDataDictionary.Enabled = '' then
            InDataDictionary.Enabled := 'Yes';

        Pos1 := 1;
        Pos2 := StrPos(InputText, EndOfValue);
        if Pos2 = 0 then
            Pos2 := StrPos(InputText, EndOfField);

        KeyText := GetInfo(InputText, Pos1, Pos2 - 1);

        if Pos2 > MaxStrLen(InDataDictionary.Value) then
            MultipleLines(KeyText, InDataDictionary, EndOfSubValue, false)
        else
            InDataDictionary.Value := CopyStr(KeyText, 1, MaxStrLen(InDataDictionary.Value));

        InDataDictionary.Insert();
    end;

    procedure GetKeyProperties(var InputText: Text[1024]; InDataDictionary: Record "Data Dictionary Info")
    begin
        Status.Update(6, 'Getting Key Properties ...');

        if StrPos(InputText, SumIndexFieldsTag) <> 0 then
            GetKeySumIndexFields(InputText, InDataDictionary);

        if StrPos(InputText, KeyGroupsTag) <> 0 then
            GetKeyGroups(InputText, InDataDictionary);

        if StrPos(InputText, SIFTLevelsToMaintainTag) <> 0 then
            GetSIFTLevelsToMaintain(InputText, (StrPos(InputText, StartOfList) <> 0));
    end;

    procedure GetKeySumIndexFields(var InputText: Text[1024]; InDataDictionary: Record "Data Dictionary Info")
    var
        Pos1: Integer;
        Pos2: Integer;
        SumIndexFieldsText: Text[1024];
    begin
        Status.Update(6, 'Getting Key Sum Index Fields ...');

        InDataDictionary.Type := InDataDictionary.Type::SumIndexField;

        SetPositions(Pos1, Pos2, InputText, SumIndexFieldsTag);
        SumIndexFieldsText := GetInfo(InputText, Pos1, Pos2);

        MultipleLines(SumIndexFieldsText, InDataDictionary, EndOfSubValue, true);

        InDataDictionary.Insert();
    end;

    procedure GetKeyGroups(var InputText: Text[1024]; InDataDictionary: Record "Data Dictionary Info")
    var
        Pos1: Integer;
        Pos2: Integer;
    begin
        Status.Update(6, 'Getting Key Groups ...');

        InDataDictionary.Type := InDataDictionary.Type::KeyGroup;

        SetPositions(Pos1, Pos2, InputText, KeyGroupsTag);
        InDataDictionary.Value := CopyStr(GetInfo(InputText, Pos1, Pos2), 1, MaxStrLen(InDataDictionary.Value));

        InDataDictionary.Insert();
    end;

    procedure GetSIFTLevelsToMaintain(var InputText: Text[1024]; ListUsed: Boolean)
    begin
        Status.Update(6, 'Getting SIFT Levels To Maintain ...');

        if ListUsed then
            while StrPos(InputText, EndOfList) = 0 do
                InputText := ReadData();
    end;

    procedure GetPermissionRange()
    var
        PermissionRange: Record "Permission Range";
        InsertPermission: Boolean;
        ICount: Integer;
    begin
        Status.Update(6, 'Getting related Permissions ...');
        ICount := 0;

        PermissionRange.SetRange("Object Type", PermissionRange."Object Type"::TableData);
        if PermissionRange.Find('-') then
            repeat
                if (CurrentTableNo >= PermissionRange.From) and
                   (CurrentTableNo <= PermissionRange."To")
                then
                    BuildPermission(PermissionRange, 'TableData for Table Object ' + Format(CurrentTableNo),
                      ICount);
            until (PermissionRange.Next() = 0);

        PermissionRange.SetRange("Object Type", PermissionRange."Object Type"::Table);
        if PermissionRange.Find('-') then
            repeat
                if (CurrentTableNo >= PermissionRange.From) and
                   (CurrentTableNo <= PermissionRange."To")
                then
                    InsertPermission := (PermissionRange."Insert Permission" <> PermissionRange."Insert Permission"::" ");
            until ((PermissionRange.Next() = 0) or InsertPermission);

        ICount := 1;

        if InsertPermission then
            BuildPermission(PermissionRange, 'Access to all fields.', ICount)
        else begin
            PermissionRange.Reset();
            PermissionRange.SetRange("Object Type", PermissionRange."Object Type"::FieldNumber);
            PermissionRange.SetRange("Insert Permission", PermissionRange."Insert Permission"::Yes);
            if PermissionRange.Find('-') then
                repeat
                    BuildPermission(PermissionRange, 'Fields From ' + Format(PermissionRange.From) +
                      ' - To ' + Format(PermissionRange."To"), ICount);
                    ICount := ICount + 1;
                until (PermissionRange.Next() = 0);
        end;
    end;

    procedure BuildPermission(PermissionRange: Record "Permission Range"; PermissionDescription: Text[250]; PermissionCount: Integer)
    var
        DataDictionary: Record "Data Dictionary Info";
    begin
        DataDictionary.Init();
        DataDictionary."Table No." := CurrentTableNo;
        DataDictionary.Type := DataDictionary.Type::Permission;
        DataDictionary."Field No." := PermissionCount;
        DataDictionary."Line No." := PermissionRange."To";
        DataDictionary."Read Permission" := (PermissionRange."Read Permission" <> PermissionRange."Read Permission"::" ");
        DataDictionary."Insert Permission" := (PermissionRange."Insert Permission" <> PermissionRange."Insert Permission"::" ");
        DataDictionary."Modify Permission" := (PermissionRange."Modify Permission" <> PermissionRange."Modify Permission"::" ");
        DataDictionary."Delete Permission" := (PermissionRange."Delete Permission" <> PermissionRange."Delete Permission"::" ");
        DataDictionary."Execute Permission" := (PermissionRange."Execute Permission" <> PermissionRange."Execute Permission"::" ");
        DataDictionary.Description := CopyStr(PermissionDescription, 1, MaxStrLen(DataDictionary.Description));
        DataDictionary.Insert();
    end;

    procedure MultipleLines(var InputText: Text[1024]; var InDataDictionary: Record "Data Dictionary Info"; Delimiter: Text[30]; Indent: Boolean)
    var
        ICount: Integer;
        EndOfText: Integer;
        Pos1: Integer;
        Pos2: Integer;
    begin
        EndOfText := StrLen(InputText);

        for ICount := 1 to EndOfText do begin
            Pos1 := 1;
            Pos2 := StrPos(InputText, Delimiter);
            if Pos2 = 0 then
                Pos2 := StrLen(InputText);

            if (StrLen(InDataDictionary.Value) + Pos2) > MaxStrLen(InDataDictionary.Value) then begin
                InDataDictionary.Insert();
                InDataDictionary."Line No." := InDataDictionary."Line No." + 1000;
                InDataDictionary.Value := '';
                if Indent then
                    InDataDictionary.Value := '    '
            end;

            InDataDictionary.Value := InDataDictionary.Value +
              CopyStr(InputText, Pos1, Pos2 - Pos1 + StrLen(Delimiter));
            InputText := CopyStr(InputText, Pos2 + StrLen(Delimiter));
            ICount := ICount + Pos2
        end;
    end;

    procedure GetInfo(var InputText: Text[1024]; Pos1: Integer; Pos2: Integer): Text[1024]
    var
        ExitText: Text[1024];
    begin
        if Pos2 <> 0 then begin
            ExitText := CopyStr(InputText, Pos1, Pos2);
            ExitText := DelChr(ExitText, '<>', ' ');
            InputText := CopyStr(InputText, Pos2 + Pos1 + 1)
        end else begin
            ExitText := CopyStr(InputText, Pos1);
            ExitText := DelChr(ExitText, '<>', ' ');
            InputText := CopyStr(ExitText, Pos1 + 1)
        end;

        exit(ExitText);
    end;

    procedure SetPositions(var Pos1: Integer; var Pos2: Integer; InputText: Text[1024]; Tag: Text[50])
    begin
        Pos1 := StrPos(InputText, Tag) + StrLen(Tag);
        Pos2 := StrPos(InputText, EndOfValue);
        if Pos2 = 0 then
            Pos2 := StrPos(InputText, EndOfField);

        Pos2 := Pos2 - Pos1;
    end;

    procedure ReadData(): Text[1024]
    var
        Input: Text[1024];
    begin
        ReadCount := ReadCount + FilePtr.Read(Input) + 2;
        Status.Update(9, Round(ReadCount / FileLen * 10000, 1.0));
        exit(Input);
    end;

    procedure MatchBeginEnd(var InputText: Text[1024])
    var
        BeginCount: Integer;
        EndCount: Integer;
        IncludeVAR: Boolean;
    begin
        repeat
            if StrPos(InputText, 'BEGIN') <> 0 then begin
                BeginCount := BeginCount + 1;
                if IncludeVAR then
                    IncludeVAR := false;
            end;

            if StrPos(InputText, 'END') <> 0 then
                EndCount := EndCount + 1;
            if (StrPos(InputText, 'VAR') <> 0) and not IncludeVAR then
                IncludeVAR := true;

            InputText := ReadData();

        until ((BeginCount - EndCount = 0) and not IncludeVAR);
    end;

    procedure SetAllOptions(Input: Boolean)
    begin
        SetTableOptions(Input);
        SetKeyOptions(ShowKeys);
        SetPermissionOptions(Input);
    end;

    procedure SetTableOptions(Input: Boolean)
    begin
        ShowCaptions := Input;
        ShowOptionStrings := Input;
        ShowTableRelations := Input;
        ShowCalcFormulas := Input;
    end;

    procedure SetKeyOptions(Input: Boolean)
    begin
        ShowSumIndexFields := Input;
        ShowKeyGroups := Input;
    end;

    procedure SetPermissionOptions(Input: Boolean)
    begin
        ShowPermissions := Input;
    end;

    local procedure ShowKeysOnPush()
    begin
        SetKeyOptions(ShowKeys);
        ShowSumIndexFieldsControlEnabl := ShowKeys;
        ShowKeyGroupControlEnable := ShowKeys;
    end;

    procedure InitializeRequest(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}


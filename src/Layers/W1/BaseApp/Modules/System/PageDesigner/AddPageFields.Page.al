namespace System.Tooling;

using System;
using System.Reflection;

page 9621 "Add Page Fields"
{
    Caption = 'New Field';
    DeleteAllowed = false;
    Editable = true;
    LinksAllowed = false;
    PageType = NavigatePage;
    SourceTable = "Page Table Field";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group("Select Type")
            {
                Caption = 'Select Type';
                Visible = CurrentNavigationPage = CurrentNavigationPage::FieldSelectionPage;
                label(NewFieldDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'By adding a new field to the table you can store and display additional information about a data entry.';
                }
                part(FieldTypes; "Table Field Types ListPart")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Choose type of field';
                    Description = 'Choose type of field''';
                    Editable = false;
                }
            }
            group("Step details")
            {
                Caption = 'Step details';
                Visible = (CurrentNavigationPage = CurrentNavigationPage::FieldBasicDefinitionPage) and (NewFieldType <> 'Boolean');
                group("Step 1 of 2")
                {
                    Caption = 'Step 1 of 2';
                    group(Step1Header)
                    {
                        Caption = 'FIELD DEFINITION';
                        InstructionalText = 'Fill in information about the new field. You can change the field information later if you need to.';
                        field(NewFieldName; NewFieldName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Name';
                            ShowMandatory = true;

                            trigger OnValidate()
                            begin
                                NewFieldCaption := NewFieldName;
                            end;
                        }
                        field(NewFieldCaption; NewFieldCaption)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Caption';
                        }
                        field(NewDescription; NewFieldDescr)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Description';
                            MultiLine = true;
                        }
                        group(Control47)
                        {
                            ShowCaption = false;
                            Visible = NewFieldType = 'Related Data Field';
                            field(RelatedFieldType; RelatedFieldType)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Linked value Type';

                                trigger OnValidate()
                                begin
                                    if RelatedFieldType = RelatedFieldType::"Linked value" then
                                        FilterType := FilterType::FIELD;
                                end;
                            }
                        }
                    }
                }
            }
            group("Step 2")
            {
                Caption = 'Step 2';
                Visible = CurrentNavigationPage = CurrentNavigationPage::FieldAdvancedDefinitionPage;
                group("Step 2 of 2")
                {
                    Caption = 'Step 2 of 2';
                    InstructionalText = 'Choose how the system initializes and validates the text that is typed or pasted into the field.';
                    group(Control14)
                    {
                        ShowCaption = false;
                        Visible = NewFieldType <> 'Related Data Field';
                        group(Control19)
                        {
                            ShowCaption = false;
                            Visible = IsNumberFieldTypeVisible;
                            field(NumberFieldType; NumberFieldTypes)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Field data type';

                                trigger OnValidate()
                                begin
                                    case NumberFieldTypes of
                                        NumberFieldTypes::BigInteger:
                                            begin
                                                NewFieldType := 'BigInteger';
                                                FieldTypeEnumValue := NavDesignerFieldType.BigInteger;
                                            end;
                                        NumberFieldTypes::Decimal:
                                            begin
                                                NewFieldType := 'Decimal';
                                                FieldTypeEnumValue := NavDesignerFieldType.Decimal;
                                            end;
                                        NumberFieldTypes::Integer:
                                            begin
                                                NewFieldType := 'Integer';
                                                FieldTypeEnumValue := NavDesignerFieldType.Integer;
                                            end;
                                    end;
                                end;
                            }
                            group(Control36)
                            {
                                ShowCaption = false;
                                Visible = NumberFieldTypes = NumberFieldTypes::"Decimal";
                                field(Field_NoOfDecimalPlaces; Field_NoOfDecimalPlaces)
                                {
                                    ApplicationArea = Basic, Suite;
                                    Caption = 'Number of decimal places';
                                    NotBlank = true;
                                }
                            }
                            field(Editable; IsFieldEditable)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Editable';
                            }
                            field(IsBlankZero; IsBlankZero)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'If zero show blank';
                            }
                        }
                        group(Control25)
                        {
                            ShowCaption = false;
                            Visible = IsTextFieldTypeVisible;
                            field(TextFieldType; TextFieldType)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Field data type';

                                trigger OnValidate()
                                begin
                                    case TextFieldType of
                                        TextFieldType::Code:
                                            begin
                                                NewFieldType := 'Code';
                                                FieldTypeEnumValue := NavDesignerFieldType.Code;
                                                TextFieldTypeDataLength := 10;
                                            end;
                                        TextFieldType::Text:
                                            begin
                                                NewFieldType := 'Text';
                                                FieldTypeEnumValue := NavDesignerFieldType.Text;
                                                TextFieldTypeDataLength := 30;
                                            end;
                                    end;
                                end;
                            }
                            field(DataLength; TextFieldTypeDataLength)
                            {
                                ApplicationArea = Basic, Suite;
                                BlankNumbers = BlankZero;
                                Caption = 'Text Length';
                            }
                            group(Control53)
                            {
                                ShowCaption = false;
                                Visible = TextFieldType = TextFieldType::"Text";
                            }
                            field(Editable_text; IsFieldEditable)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Editable';
                            }
                        }
                        group(Control26)
                        {
                            ShowCaption = false;
                            Visible = IsDateTimeFieldTypeVisible;
                            field(DateTimeFieldType; DateTimeFieldType)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Field data type';

                                trigger OnValidate()
                                begin
                                    case DateTimeFieldType of
                                        DateTimeFieldType::Time:
                                            begin
                                                NewFieldType := 'Time';
                                                FieldTypeMessage := TimeFieldDescMsg;
                                                FieldTypeEnumValue := NavDesignerFieldType.Time;
                                            end;
                                        DateTimeFieldType::Date:
                                            begin
                                                NewFieldType := 'Date';
                                                FieldTypeMessage := DateFieldDescMsg;
                                                FieldTypeEnumValue := NavDesignerFieldType.Date;
                                            end;
                                        DateTimeFieldType::DateTime:
                                            begin
                                                NewFieldType := 'DateTime';
                                                FieldTypeMessage := DateTimeFieldDescMsg;
                                                FieldTypeEnumValue := NavDesignerFieldType.DateTime;
                                            end
                                    end;
                                end;
                            }
                            field(typeDesc; FieldTypeMessage)
                            {
                                ApplicationArea = Basic, Suite;
                                Editable = false;
                                MultiLine = true;
                                ShowCaption = false;
                            }
                        }
                        group(Control15)
                        {
                            Editable = true;
                            ShowCaption = false;
                            Visible = IsOptionDetailsVisible;
                            field(OptionsValue; NewOptionsFieldValues)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Options Value';
                            }
                            field(InitialValue; NewFieldInitialValue)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Initial Value';
                            }
                        }
                    }
                    group(Control39)
                    {
                        ShowCaption = false;
                        Visible = NewFieldType = 'Related Data Field';
                        group("Please select the related table and then the corresponding field.")
                        {
                            Caption = 'Please select the related table and then the corresponding field.';
                            field(TableSearch; RelatedTableName)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Table';

                                trigger OnLookup(var Text: Text): Boolean
                                var
                                    AvailableTables: Record "Table Metadata";
                                begin
                                    if PAGE.RunModal(PAGE::"Available Table Selection List", AvailableTables) = ACTION::LookupOK then begin
                                        RelatedTableName := AvailableTables.Name;
                                        RelatedTableNumber := AvailableTables.ID;
                                        RelatedTableFilterFieldName := '';
                                        RelatedTableFieldName := '';
                                    end;
                                end;

                                trigger OnValidate()
                                var
                                    AvailableTables: Record "Table Metadata";
                                    IsNumber: Integer;
                                begin
                                    if Evaluate(IsNumber, RelatedTableName) then
                                        AvailableTables.SetRange(ID, IsNumber)
                                    else
                                        AvailableTables.SetRange(Name, RelatedTableName);

                                    if AvailableTables.FindFirst() then begin
                                        RelatedTableNumber := AvailableTables.ID;
                                        RelatedTableName := AvailableTables.Name;
                                        RelatedTableFilterFieldName := '';
                                        RelatedTableFieldName := '';
                                    end else
                                        if RelatedTableName = '' then begin
                                            RelatedTableFilterFieldName := '';
                                            RelatedTableFieldName := '';
                                        end else
                                            Error(InvalidTableNumberOrNameErr, RelatedTableName);
                                end;
                            }
                            field(FieldName; RelatedTableFieldName)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Field';
                                Editable = RelatedTableName <> '';

                                trigger OnLookup(var Text: Text): Boolean
                                var
                                    FieldTable: Record "Field";
                                begin
                                    FieldTable.SetFilter(TableNo, Format(RelatedTableNumber));
                                    FieldTable.SetFilter(ObsoleteState, '<>%1', FieldTable.ObsoleteState::Removed);
                                    if PAGE.RunModal(PAGE::"Available Field Selection Page", FieldTable) = ACTION::LookupOK then
                                        RelatedTableFieldName := FieldTable."Field Caption";
                                end;

                                trigger OnValidate()
                                var
                                    FieldTable: Record "Field";
                                begin
                                    FieldTable.SetRange("Field Caption", RelatedTableFieldName);
                                    FieldTable.SetFilter(TableNo, Format(RelatedTableNumber));
                                    FieldTable.SetFilter(ObsoleteState, '<>%1', FieldTable.ObsoleteState::Removed);

                                    if FieldTable.FindFirst() then
                                        RelatedTableFieldName := FieldTable."Field Caption"
                                    else
                                        if RelatedTableFieldName <> '' then
                                            Error(InvalidRelatedFieldNameErr, RelatedTableFieldName);
                                end;
                            }
                        }
                        group(Control40)
                        {
                            ShowCaption = false;
                            Visible = RelatedFieldType = RelatedFieldType::"Computed value";
                            field(Method; RelatedFieldMethod)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Method';
                            }
                            field(ReverseSign; RelatedFieldFormulaCalc_ReverseSign)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Reverse Sign';
                            }
                        }
                        group(FilterSection)
                        {
                            Caption = 'RELATED TABLE FILTER CRITERIA';
                            Enabled = (RelatedTableName <> '') and (RelatedTableFieldName <> '');
                            field(RelatedTableFilterField; RelatedTableFilterFieldName)
                            {
                                ApplicationArea = Basic, Suite;
                                Caption = 'Filtered field';

                                trigger OnLookup(var Text: Text): Boolean
                                var
                                    FieldTable: Record "Field";
                                begin
                                    FieldTable.SetFilter(TableNo, Format(RelatedTableNumber));
                                    FieldTable.SetFilter(ObsoleteState, '<>%1', FieldTable.ObsoleteState::Removed);
                                    if PAGE.RunModal(PAGE::"Available Field Selection Page", FieldTable) = ACTION::LookupOK then begin
                                        RelatedTableFilterFieldName := FieldTable."Field Caption";
                                        FieldType := Format(FieldTable.Type);
                                    end;
                                end;

                                trigger OnValidate()
                                var
                                    FieldTable: Record "Field";
                                begin
                                    FieldTable.SetRange("Field Caption", RelatedTableFilterFieldName);
                                    FieldTable.SetFilter(TableNo, Format(RelatedTableNumber));
                                    FieldTable.SetFilter(ObsoleteState, '<>%1', FieldTable.ObsoleteState::Removed);
                                    if FieldTable.FindFirst() then
                                        FieldType := Format(FieldTable.Type)
                                    else
                                        if RelatedTableFilterFieldName <> '' then
                                            Error(InvalidRelatedFieldNameErr, RelatedTableFilterFieldName);
                                end;
                            }
                            group(Control48)
                            {
                                ShowCaption = false;
                                Visible = RelatedFieldType = RelatedFieldType::"Computed value";
                                field("Filter Type"; FilterType)
                                {
                                    ApplicationArea = Basic, Suite;
                                    Caption = 'Filter Type';
                                }
                            }
                            group(Control59)
                            {
                                ShowCaption = false;
                                Visible = FilterType = FilterType::"FIELD";
                                field(CurrentTableFilterField; CurrentTableFilterFieldName)
                                {
                                    ApplicationArea = Basic, Suite;
                                    Caption = 'Filter Value From field';

                                    trigger OnLookup(var Text: Text): Boolean
                                    var
                                        PageTableField: Record "Page Table Field";
                                    begin
                                        PageTableField.SetFilter("Page ID", Format(PageId));

                                        if (FieldType = 'Text') or (FieldType = 'Code') then
                                            PageTableField.SetFilter(Type, '%1|%2', PageTableField.Type::Text, PageTableField.Type::Code)
                                        else
                                            if FieldType = 'Integer' then
                                                PageTableField.SetFilter(Type, '%1', PageTableField.Type::Integer)
                                            else
                                                if FieldType = 'Date' then
                                                    PageTableField.SetFilter(Type, '%1', PageTableField.Type::Date);

                                        if PAGE.RunModal(PAGE::"Page Fields Selection List", PageTableField) = ACTION::LookupOK then
                                            CurrentTableFilterFieldName := PageTableField.Caption;
                                    end;

                                    trigger OnValidate()
                                    var
                                        PageTableField: Record "Page Table Field";
                                    begin
                                        PageTableField.SetRange(Caption, CurrentTableFilterFieldName);
                                        if PageTableField.FindFirst() then
                                            RelatedTableFilterFieldName := PageTableField.Caption
                                        else
                                            if RelatedTableFilterFieldName <> '' then
                                                Error(InvalidRelatedFieldNameErr, CurrentTableFilterFieldName);
                                    end;
                                }
                            }
                            group(Control60)
                            {
                                ShowCaption = false;
                                Visible = FilterType <> FilterType::"FIELD";
                                field(Value; FilterValue)
                                {
                                    ApplicationArea = Basic, Suite;
                                    Caption = 'Value';
                                }
                            }
                        }
                    }
                }
            }
            group(Control52)
            {
                Caption = 'Step details';
                Visible = (CurrentNavigationPage = CurrentNavigationPage::FieldBasicDefinitionPage) and (NewFieldType = 'Boolean');
                group(Step1Header_Boolean)
                {
                    Caption = 'FIELD DEFINITION';
                    InstructionalText = 'Fill in information about the new field. You can change the field information later if you need to.';
                    field(NewFieldName_Boolean; NewFieldName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Name';
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            NewFieldCaption := NewFieldName;
                        end;
                    }
                    field(NewFieldCaption_Boolean; NewFieldCaption)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Caption';
                    }
                    field(NewDescription_Boolean; NewFieldDescr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Description';
                        MultiLine = true;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Next)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Image = NextRecord;
                InFooterBar = true;
                Visible = IsNextVisible;

                trigger OnAction()
                begin
                    case CurrentNavigationPage of
                        CurrentNavigationPage::FieldBasicDefinitionPage:
                            begin
                                if NewFieldName = '' then
                                    Error(MandateFieldNameErr);
                                LoadRequestedPage(CurrentNavigationPage::FieldAdvancedDefinitionPage);
                            end;
                    end;
                end;
            }
            action(Previous)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous';
                Image = PreviousRecord;
                InFooterBar = true;
                Visible = IsBackVisible;

                trigger OnAction()
                begin
                    case CurrentNavigationPage of
                        CurrentNavigationPage::FieldBasicDefinitionPage:
                            LoadRequestedPage(CurrentNavigationPage::FieldSelectionPage);
                        CurrentNavigationPage::FieldAdvancedDefinitionPage:
                            LoadRequestedPage(CurrentNavigationPage::FieldBasicDefinitionPage);
                    end;
                end;
            }
            action(Create)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create';
                Image = NextRecord;
                InFooterBar = true;
                Visible = IsCreateBtnVisible;

                trigger OnAction()
                var
                    FieldTypeOptions: Option Number,Text,Boolean,DateTime,RelatedData,Option;
                begin
                    ClearAllDynamicFieldsVisibility();
                    Evaluate(FieldTypeOptions, CurrPage.FieldTypes.PAGE.GetSelectedRecType());
                    case FieldTypeOptions of
                        FieldTypeOptions::Number:
                            begin
                                NewFieldType := 'Integer';
                                IsNumberFieldTypeVisible := true;
                                FieldTypeEnumValue := NavDesignerFieldType.Integer;
                            end;
                        FieldTypeOptions::Text:
                            begin
                                NewFieldType := 'Text';
                                TextFieldTypeDataLength := 30;
                                IsTextFieldTypeVisible := true;
                                FieldTypeEnumValue := NavDesignerFieldType.Text;
                            end;
                        FieldTypeOptions::Boolean:
                            begin
                                NewFieldType := 'Boolean';
                                IsFinishBtnVisible := true;
                                IsNextVisible := false;
                                FieldTypeEnumValue := NavDesignerFieldType.Boolean;
                            end;
                        FieldTypeOptions::DateTime:
                            begin
                                NewFieldType := 'Date';
                                IsDateTimeFieldTypeVisible := true;
                                FieldTypeEnumValue := NavDesignerFieldType.Date;
                            end;
                        FieldTypeOptions::RelatedData:
                            begin
                                NewFieldType := 'Related Data Field';
                                RelatedFieldType := RelatedFieldType::"Linked value";
                                FilterType := FilterType::FIELD;
                            end;
                        FieldTypeOptions::Option:
                            begin
                                NewFieldType := 'Option';
                                IsOptionDetailsVisible := true;
                                FieldTypeEnumValue := NavDesignerFieldType.Option;
                            end;
                    end;
                    LoadRequestedPage(CurrentNavigationPage::FieldBasicDefinitionPage);
                end;
            }
            action(Finish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Image = Approve;
                InFooterBar = true;
                Visible = IsFinishBtnVisible;

                trigger OnAction()
                begin
                    SaveNewFieldDefinition();
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        DesignerPageId: Codeunit DesignerPageId;
    begin
        InitializeVariables();
        PageId := DesignerPageId.GetPageId();
        RelatedFieldType := RelatedFieldType::"Computed value";
        CurrentNavigationPage := CurrentNavigationPage::FieldSelectionPage;
    end;

    var
        NavDesignerProperty: DotNet DesignerFieldProperty;
        NavDesignerFieldType: DotNet DesignerFieldType;
        NavDesigner: DotNet NavDesignerALFunctions;
        PropertyDictionary: DotNet GenericDictionary2;
        IsNextVisible: Boolean;
        IsBackVisible: Boolean;
        IsCreateBtnVisible: Boolean;
        IsFinishBtnVisible: Boolean;
        NewFieldName: Text;
        NewFieldDescr: Text;
        NewFieldCaption: Text;
        NewOptionsFieldValues: Text;
        NewFieldInitialValue: Text;
        PageId: Integer;
        NewFieldId: Integer;
        NewFieldType: Text;
        NumberFieldTypes: Option "Integer",Decimal,BigInteger;
        TextFieldType: Option Text,"Code";
        IsTextFieldTypeVisible: Boolean;
        IsNumberFieldTypeVisible: Boolean;
        DateTimeFieldType: Option Date,DateTime,Time;
        IsDateTimeFieldTypeVisible: Boolean;
        TextFieldTypeDataLength: Integer;
        Field_NoOfDecimalPlaces: Text;
        IsOptionDetailsVisible: Boolean;
        IsFieldEditable: Boolean;
        IsBlankZero: Boolean;
        RelatedTableFieldName: Text;
        RelatedTableName: Text;
        RelatedFieldMethod: Option "Sum","Average","Count";
        FilterType: Option "CONST","FILTER","FIELD";
        RelatedTableNumber: Integer;
        RelatedTableFilterFieldName: Text;
        CurrentTableFilterFieldName: Text;
        FilterValue: Text;
        RelatedFieldFormulaCalc_ReverseSign: Boolean;
        RelatedFieldType: Option "Linked value","Computed value";
        FieldType: Text;
        MandateFieldNameErr: Label 'Field name is required.';
        RelatedFieldValidationErrorErr: Label 'Table and Field values are required.';
        FieldCreationErrorErr: Label 'Error occurred while creating the field. Please validate the input values are correct and field name is unique.';
        InvalidRelatedFieldNameErr: Label '%1 field not found.', Comment = '%1 = Field name';
        InvalidTableNumberOrNameErr: Label '%1 table not found.', Comment = '%1 = Table name';
        CurrentNavigationPage: Option FieldSelectionPage,FieldBasicDefinitionPage,FieldAdvancedDefinitionPage;
        DateFieldDescMsg: Label 'Stores date of an event';
        FieldTypeMessage: Text;
        TimeFieldDescMsg: Label 'Stores time of an event';
        DateTimeFieldDescMsg: Label 'Stores Date and Time of an event';
        FieldTypeEnumValue: Integer;
        PageIdNotFoundErr: Label 'Please navigate to a card details page and begin process for field creation.';

    local procedure SaveNewFieldDefinition()
    var
        FieldDetails: Record "Field";
    begin
        FieldType := NewFieldType;
        if NewFieldType = 'Related Data Field' then begin
            if (RelatedTableName = '') or (RelatedTableFieldName = '') then
                Error(RelatedFieldValidationErrorErr);

            FieldDetails.SetFilter(TableNo, Format(RelatedTableNumber));
            FieldDetails.SetFilter(FieldName, RelatedTableFieldName);
            if FieldDetails.FindFirst() then begin
                FieldType := Format(FieldDetails.Type);
                TextFieldTypeDataLength := 0;
                if (FieldType = 'Text') or (FieldType = 'Code') then
                    TextFieldTypeDataLength := FieldDetails.Len;
            end;
        end;

        PropertyDictionary := PropertyDictionary.Dictionary();
        PropertyDictionary.Add(NavDesignerProperty.Description, NewFieldDescr);
        PropertyDictionary.Add(NavDesignerProperty.Caption, NewFieldCaption);

        case NewFieldType of
            'Text', 'Code':
                PropertyDictionary.Add(NavDesignerProperty.Editable(), ConvertToBooleanText(IsFieldEditable));
            'Decimal':
                begin
                    PropertyDictionary.Add(NavDesignerProperty.DecimalPlaces, Format(Field_NoOfDecimalPlaces));
                    PropertyDictionary.Add(NavDesignerProperty.BlankZero, ConvertToBooleanText(IsBlankZero));
                end;
            'Integer', 'BigInteger':
                PropertyDictionary.Add(NavDesignerProperty.BlankZero, ConvertToBooleanText(IsBlankZero));
            'Option':
                begin
                    PropertyDictionary.Add(NavDesignerProperty.OptionString, NewOptionsFieldValues);
                    PropertyDictionary.Add(NavDesignerProperty.InitValue, NewFieldInitialValue);
                end;
        end;

        if PageId > 0 then
            NewFieldId := NavDesigner.CreateTableField(PageId, NewFieldName, FieldTypeEnumValue, TextFieldTypeDataLength, PropertyDictionary)
        else
            Error(PageIdNotFoundErr);

        if NewFieldId = 0 then
            Error(FieldCreationErrorErr);
    end;

    local procedure InitializeVariables()
    begin
        IsCreateBtnVisible := true;
        IsBackVisible := false;
        IsNextVisible := false;
        IsFinishBtnVisible := false;

        ClearAllDynamicFieldsVisibility();

        NewFieldName := '';
        NewFieldDescr := '';
        NewFieldCaption := '';
        NewFieldInitialValue := '';
        RelatedTableFieldName := '';
        RelatedTableName := '';
        FilterValue := '';
        FieldTypeMessage := DateFieldDescMsg;
    end;

    local procedure ClearAllDynamicFieldsVisibility()
    begin
        IsNumberFieldTypeVisible := false;
        IsTextFieldTypeVisible := false;
        IsDateTimeFieldTypeVisible := false;
        IsOptionDetailsVisible := false;
    end;

    local procedure LoadRequestedPage("Page": Option)
    begin
        IsBackVisible := true;
        IsNextVisible := true;
        IsFinishBtnVisible := false;
        IsCreateBtnVisible := false;

        case Page of
            CurrentNavigationPage::FieldSelectionPage:
                begin
                    CurrentNavigationPage := CurrentNavigationPage::FieldSelectionPage;
                    InitializeVariables();
                end;
            CurrentNavigationPage::FieldBasicDefinitionPage:
                begin
                    CurrentNavigationPage := CurrentNavigationPage::FieldBasicDefinitionPage;
                    if NewFieldType = 'Boolean' then begin
                        IsNextVisible := false;
                        IsFinishBtnVisible := true;
                    end;
                end;
            CurrentNavigationPage::FieldAdvancedDefinitionPage:
                begin
                    CurrentNavigationPage := CurrentNavigationPage::FieldAdvancedDefinitionPage;
                    IsNextVisible := false;
                    IsFinishBtnVisible := true;
                end;
            else
                LoadRequestedPage(CurrentNavigationPage::FieldSelectionPage);
        end;
    end;

    local procedure ConvertToBooleanText(Value: Boolean): Text
    var
        Result: Text;
    begin
        Result := 'True';
        if not Value then
            Result := 'False';
        exit(Result);
    end;
}


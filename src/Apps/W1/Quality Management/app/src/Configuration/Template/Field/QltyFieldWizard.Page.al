// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Field;

using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;

/// <summary>
/// The field wizard is used to help guide a user with the creation or editing of a net new field.
/// </summary>
page 20432 "Qlty. Field Wizard"
{
    Caption = 'Quality Field Wizard';
    PageType = NavigatePage;
    UsageCategory = None;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            group(SettingsForiStepNewOrExisting)
            {
                Visible = (CurrentStepCounter = Step1NewOrExisting) and (not EditingExistingField);

                field(ChooseNewField; NewField)
                {
                    Caption = 'New field';
                    ToolTip = 'Specifies to add a new field.';

                    trigger OnValidate()
                    begin
                        ChooseExistingFieldOrFields := not NewField;
                        CurrPage.Update();
                    end;
                }
                field(ChooseExistingField; ChooseExistingFieldOrFields)
                {
                    Caption = 'Existing fields';
                    ToolTip = 'Specifies to add an existing field.';

                    trigger OnValidate()
                    begin
                        NewField := not ChooseExistingFieldOrFields;
                        CurrPage.Update();
                    end;
                }
                group(SettingsForWrapExistingFields)
                {
                    Visible = ChooseExistingFieldOrFields or NewField;
                    ShowCaption = false;
                    Caption = '';

                    part("Qlty. Choose Existing Fields"; "Qlty. Choose Existing Fields")
                    {
                        Enabled = ChooseExistingFieldOrFields;
                        UpdatePropagation = Both;
                    }
                }
            }
            group(SettingsForEditingExistingField)
            {
                Caption = 'Edit Existing Field';
                ShowCaption = false;
                Visible = (Step2AddNewField = CurrentStepCounter) and EditingExistingField;

                group(SettingsForEditExistingShortName)
                {
                    Caption = 'Short name (Field Code)';
                    InstructionalText = 'A short name for this field. This code is what will be used to reference this new field.';

                    field(ChooseEditExistingShortName; FieldShortName)
                    {
                        ToolTip = 'Specifies a Short Name for this field.';
                        Caption = 'Field Code:';
                        ShowCaption = true;
                        ShowMandatory = true;
                        Editable = false;
                    }
                }
                group(SettingsForExistingFieldDescription)
                {
                    Caption = 'Description';
                    InstructionalText = 'Change the description for what this field represents.';

                    field(ChooseEditDescription; FieldDescription)
                    {
                        ToolTip = 'Change the description for what this field represents.';
                        Caption = 'Description';
                        ShowCaption = false;
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            HandleFieldDescriptionOnValidate();
                        end;
                    }
                }
                group(SettingsForEditExistingType)
                {
                    Caption = 'What type of data is it?';
                    InstructionalText = 'Is this a number, a choice from a pre-defined list, or something else?';

                    field(ChooseEditExistingType; SimpleFieldType)
                    {
                        OptionCaption = 'A number,A choice from a list,Free Text,Date,Advanced Configuration';
                        Caption = 'What type of data is it?';
                        ShowCaption = false;
                        ToolTip = 'Is this a number, a choice from a pre-defined list, or something else?';

                        trigger OnValidate()
                        begin
                            HandleFieldValidateType();
                        end;
                    }
                }
            }
            group(SettingsForCreateSingleNewField)
            {
                Caption = 'Add a New Field';
                ShowCaption = false;
                Visible = (Step2AddNewField = CurrentStepCounter) and not EditingExistingField;

                group(SettingsForDescription)
                {
                    Caption = 'Description';
                    InstructionalText = 'Type a relevant description for what this new field represents.';

                    field(ChooseDescription; FieldDescription)
                    {
                        ToolTip = 'Type a relevant description for what this new field represents.';
                        Caption = 'Description';
                        ShowCaption = false;
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            HandleFieldDescriptionOnValidate();
                        end;
                    }
                    group(SettingsForChooseDataLink)
                    {
                        Visible = not ShowNewFieldCode;
                        Caption = ' ';
                        ShowCaption = false;

                        field(ChooseChoose; 'Choose the type of data this will hold.')
                        {
                            Caption = ' ';
                            ToolTip = 'Choose the type of data this will hold.';
                            Editable = false;
                            ShowCaption = false;
                            Visible = not ShowNewFieldCode;

                            trigger OnDrillDown()
                            begin
                                HandleFieldDescriptionOnValidate();
                            end;
                        }
                    }
                }
                group(SettingsForShortName)
                {
                    Caption = 'Short name (Field Code)';
                    InstructionalText = 'A short name for this field. This code is what will be used to reference this new field.';
                    Visible = ShowNewFieldCode;

                    field(ChooseShortName; FieldShortName)
                    {
                        ToolTip = 'Specifies a Short Name for this field.';
                        Caption = 'Short name.';
                        ShowCaption = false;
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            HandleFieldCodeOnValidate();
                        end;
                    }
                }
                group(SettingsForType)
                {
                    Caption = 'What type of data is it?';
                    InstructionalText = 'Is this a number, a choice from a pre-defined list, or something else?';
                    Visible = ShowNewFieldType;

                    field(ChooseType; SimpleFieldType)
                    {
                        OptionCaption = 'A number,A choice from a list,Free Text,Date,Advanced Configuration';
                        Caption = 'What type of data is it?';
                        ShowCaption = false;
                        ToolTip = 'Is this a number, a choice from a pre-defined list, or something else?';

                        trigger OnValidate()
                        begin
                            HandleFieldValidateType();
                        end;
                    }
                }
            }
            group(SettingsForFieldDataTypeDetails)
            {
                Visible = (Step3FieldDataTypeDetails = CurrentStepCounter);

                part(NumberFieldDetails; "Qlty. Field Number Card Part")
                {
                    Visible = ShowNumberDataType;
                    UpdatePropagation = Both;
                    Caption = 'Number Field Details';
                }
                part(FieldChoices; "Qlty. Lookup Code Part")
                {
                    Visible = ShowChoiceDataType;
                    UpdatePropagation = Both;
                    Caption = 'Choices';
                }
                part(FieldDetails; "Qlty. Field Card Part")
                {
                    Visible = ShowAnythingElse;
                    UpdatePropagation = Both;
                    Caption = 'Field Details';
                }
            }
        }
        area(FactBoxes)
        {
            part("Most Recent Picture"; "Qlty. Most Recent Picture")
            {
                Caption = 'Picture';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Back)
            {
                Caption = 'Back';
                ToolTip = 'Back';
                Enabled = IsBackEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction();
                begin
                    BackAction();
                end;
            }
            action(Next)
            {
                Caption = 'Next';
                ToolTip = 'Next';
                Enabled = IsNextEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction();
                begin
                    NextAction();
                end;
            }
            action(Finish)
            {
                Caption = 'Finish';
                ToolTip = 'Finish';
                Enabled = IsFinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction();
                begin
                    FinishAction();
                end;
            }
        }
    }

    var
        CurrentStepCounter: Integer;
        FinishActionChosen: Boolean;
        NewField: Boolean;
        ChooseExistingFieldOrFields: Boolean;
        IsBackEnabled: Boolean;
        AddedOrChooseAField: Boolean;
        IsNextEnabled: Boolean;
        IsFinishEnabled: Boolean;
        IsMovingForward: Boolean;
        ShowNewFieldCode: Boolean;
        ShowNewFieldType: Boolean;
        ShowNumberDataType: Boolean;
        ShowChoiceDataType: Boolean;
        ShowAnythingElse: Boolean;
        IsRunningFromFieldDirectly: Boolean;
        EditingExistingField: Boolean;
        Step1NewOrExisting: Integer;
        Step2AddNewField: Integer;
        Step3FieldDataTypeDetails: Integer;
        FieldsToAdd: List of [Code[20]];
        FieldDescription: Text[100];
        FieldShortName: Code[20];
        SimpleFieldType: Option TypeNumber,TypeChoice,TypeFreeText,TypeDate,TypeAdvanced;
        ListOfAddedFields: List of [Code[20]];
        ChoicesQst: Label 'Use the existing field,Change the description', Locked = true;
        ChoicesMsg: Label 'There is already a field with that description. Do you want to use the existing field instead?';
        ShouldBeAtLeastThreeCharsErr: Label 'A description should be at least three characters.';

    trigger OnInit();
    begin
        NewField := true;
        Step1NewOrExisting := 1;
        Step2AddNewField := 2;
        Step3FieldDataTypeDetails := 3;
        if IsRunningFromFieldDirectly then
            ChangeToStep(Step2AddNewField)
        else
            ChangeToStep(Step1NewOrExisting);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        RefreshStep();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        QltyField: Record "Qlty. Field";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        TempAddedField: Code[20];
    begin
        if not FinishActionChosen then
            foreach TempAddedField in ListOfAddedFields do begin
                QltyInspectionTemplateLine.Reset();
                QltyInspectionTemplateLine.SetRange("Field Code", TempAddedField);
                if QltyInspectionTemplateLine.IsEmpty() then
                    if QltyField.Get(TempAddedField) then
                        if QltyField."Wizard Internal" = QltyField."Wizard Internal"::"In Progress" then
                            if QltyField.Delete() then;
            end
        else
            foreach TempAddedField in ListOfAddedFields do
                if QltyField.Get(TempAddedField) then begin
                    QltyField."Wizard Internal" := QltyField."Wizard Internal"::Complete;
                    QltyField.UpdateAllowedValuesFromTableLookup();
                    QltyField.Modify(false);
                end;
    end;

    local procedure RefreshStep()
    begin
        ChangeToStep(CurrentStepCounter);
    end;

    local procedure ChangeToStep(Step: Integer);
    var
    begin
        if Step < 1 then
            Step := 1;

        if Step > 5 then
            Step := 5;

        IsMovingForward := Step > CurrentStepCounter;

        if IsMovingForward then
            LeavingStepMovingForward(CurrentStepCounter, Step);

        EvaluateStep(Step);
        CurrentStepCounter := Step;
        CurrPage.Update(false);
    end;

    local procedure EvaluateStep(Step: Integer)
    begin
        OnEvaluateStep(Step, IsBackEnabled, IsNextEnabled, IsFinishEnabled);
        case Step of
            Step1NewOrExisting:
                begin
                    IsBackEnabled := false;
                    IsNextEnabled := NewField;
                    IsFinishEnabled := false;

                    if ChooseExistingFieldOrFields then begin
                        UpdateChosenExistingFieldsFromPart();
                        IsFinishEnabled := FieldsToAdd.Count() > 0;
                    end
                end;

            Step2AddNewField:
                begin
                    IsBackEnabled := (not IsRunningFromFieldDirectly) and (not EditingExistingField);
                    IsNextEnabled := (StrLen(FieldDescription) >= 2) and (StrLen(FieldShortName) >= 2);
                    if IsNextEnabled and (SimpleFieldType in [SimpleFieldType::TypeFreeText, SimpleFieldType::TypeDate]) then begin
                        IsFinishEnabled := true;
                        IsNextEnabled := false;
                    end else
                        IsFinishEnabled := false;
                end;
            Step3FieldDataTypeDetails:
                begin
                    IsBackEnabled := true;
                    IsNextEnabled := false;
                    IsFinishEnabled := true;
                end;
        end;
    end;

    local procedure UpdateChosenExistingFieldsFromPart()
    begin
        CurrPage."Qlty. Choose Existing Fields".Page.GetFieldsToAdd(FieldsToAdd);
    end;

    local procedure LeavingStepMovingForward(LeavingThisStep: Integer; var MovingToStep: Integer);
    begin
        OnLeavingStepMovingForward(LeavingThisStep, MovingToStep);
        case LeavingThisStep of
            Step2AddNewField:
                AddOrUpdateInternalField();
            Step3FieldDataTypeDetails:
                AddOrUpdateInternalField();
        end;
    end;

    local procedure BackAction();
    begin
        CurrPage.Update(true);
        ChangeToStep(CurrentStepCounter - 1);
    end;

    local procedure NextAction();
    begin
        CurrPage.Update(true);
        ChangeToStep(CurrentStepCounter + 1);
    end;

    local procedure FinishAction();
    begin
        FinishActionChosen := true;
        AddOrUpdateInternalField();
        OnFinishActionAfterAddUpdateInternalField();
        AddedOrChooseAField := NewField or EditingExistingField or (ChooseExistingFieldOrFields and (FieldsToAdd.Count() > 0));

        if AddedOrChooseAField and NewField then
            if not FieldsToAdd.Contains(FieldShortName) then
                FieldsToAdd.Add(FieldShortName);

        CurrPage.Close();
    end;

    procedure GetFieldsToAdd(var ListOfFieldsToAdd: List of [Code[20]]): Boolean
    begin
        ListOfFieldsToAdd := FieldsToAdd;
        exit(AddedOrChooseAField);
    end;

    local procedure HandleFieldDescriptionOnValidate()
    var
        TempQltyField: Record "Qlty. Field" temporary;
    begin
        if StrLen(FieldDescription) < 3 then
            Error(ShouldBeAtLeastThreeCharsErr);
        CheckForExistingFieldWithSameDescription();

        if not EditingExistingField then
            TempQltyField.SuggestUnusedFieldCodeFromDescription(FieldDescription, FieldShortName);

        UpdateNewExistingFieldVisibilityStates();
        EvaluateStep(CurrentStepCounter);
    end;

    local procedure CheckForExistingFieldWithSameDescription()
    var
        QltyField: Record "Qlty. Field";
    begin
        if EditingExistingField then
            QltyField.SetFilter(Code, '<>%1', FieldShortName);

        QltyField.SetRange(Description, FieldDescription);
        if QltyField.FindFirst() then
            case StrMenu(ChoicesQst, 1, ChoicesMsg) of
                1:
                    if IsRunningFromFieldDirectly then
                        CurrPage.Close()
                    else begin
                        CurrentStepCounter := Step1NewOrExisting;
                        ChooseExistingFieldOrFields := true;
                        NewField := false;
                        CurrPage."Qlty. Choose Existing Fields".Page.SetChooseField(QltyField.Code, true);
                        CurrPage.Update();
                    end;
            end;

        if not EditingExistingField then
            QltyField.SuggestUnusedFieldCodeFromDescription(FieldDescription, FieldShortName);
    end;

    local procedure HandleFieldCodeOnValidate()
    var
        TempQltyField: Record "Qlty. Field" temporary;
    begin
        TempQltyField.SuggestUnusedFieldCodeFromDescription(FieldShortName, FieldShortName);
        UpdateNewExistingFieldVisibilityStates();
    end;

    local procedure HandleFieldValidateType()
    begin
        UpdateNewExistingFieldVisibilityStates();
    end;

    local procedure UpdateNewExistingFieldVisibilityStates()
    begin
        ShowNewFieldCode := StrLen(FieldDescription) > 1;
        ShowNewFieldType := StrLen(FieldShortName) > 1;

        ShowNumberDataType := SimpleFieldType = SimpleFieldType::TypeNumber;
        ShowChoiceDataType := SimpleFieldType = SimpleFieldType::TypeChoice;

        ShowAnythingElse := SimpleFieldType = SimpleFieldType::TypeAdvanced;
        CurrPage.Update();
    end;

    local procedure AddOrUpdateInternalField()
    var
        QltyField: Record "Qlty. Field";
        TempPreviousVersionOfQltyField: Record "Qlty. Field" temporary;
        QltyLookupCode: Record "Qlty. Lookup Code";
    begin
        if FieldShortName = '' then
            exit;

        if not QltyField.Get(FieldShortName) then begin
            QltyField.Init();
            QltyField."Wizard Internal" := QltyField."Wizard Internal"::"In Progress";
            QltyField.Code := FieldShortName;
            QltyField.Description := FieldDescription;
            QltyField.Insert();
        end;

        TempPreviousVersionOfQltyField := QltyField;
        QltyField.Description := FieldDescription;
        if not ListOfAddedFields.Contains(FieldShortName) then
            ListOfAddedFields.Add(FieldShortName);
        case SimpleFieldType of
            SimpleFieldType::TypeDate:
                QltyField."Field Type" := QltyField."Field Type"::"Field Type Date";
            SimpleFieldType::TypeFreeText:
                QltyField."Field Type" := QltyField."Field Type"::"Field Type Text";
            SimpleFieldType::TypeNumber:
                begin
                    QltyField."Field Type" := QltyField."Field Type"::"Field Type Decimal";
                    QltyField."Allowable Values" := CopyStr(CurrPage.NumberFieldDetails.Page.GetAllowableValues(), 1, MaxStrLen(QltyField."Allowable Values"));
                end;
            SimpleFieldType::TypeChoice:
                begin
                    QltyField."Field Type" := QltyField."Field Type"::"Field Type Table Lookup";
                    if QltyField."Lookup Table No." = 0 then begin
                        QltyField.Validate("Lookup Table No.", Database::"Qlty. Lookup Code");
                        QltyField.Validate("Lookup Field No.", QltyLookupCode.FieldNo(Code));
                    end;
                end;
        end;
        if QltyField."Wizard Internal" = QltyField."Wizard Internal"::Complete then
            if TempPreviousVersionOfQltyField."Field Type" <> QltyField."Field Type" then
                QltyField.HandleOnValidateFieldType(false);

        QltyField.UpdateAllowedValuesFromTableLookup();
        QltyField.Modify();
        LoadPagePart(QltyField.Code);
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Use this to start the edit field wizard page from the context of an existing field.
    /// </summary>
    /// <param name="QltyField"></param>
    /// <returns></returns>
    procedure RunModalEditExistingField(var QltyField: Record "Qlty. Field"): Action
    begin
        EditingExistingField := true;
        FieldShortName := QltyField.Code;
        FieldDescription := QltyField.Description;
        case QltyField."Field Type" of
            QltyField."Field Type"::"Field Type Decimal":
                SimpleFieldType := SimpleFieldType::TypeNumber;
            QltyField."Field Type"::"Field Type Table Lookup":
                SimpleFieldType := SimpleFieldType::TypeChoice;
            QltyField."Field Type"::"Field Type Text":
                SimpleFieldType := SimpleFieldType::TypeFreeText;
            QltyField."Field Type"::"Field Type Date":
                SimpleFieldType := SimpleFieldType::TypeDate;
            else
                SimpleFieldType := SimpleFieldType::TypeAdvanced;
        end;
        LoadPagePart(FieldShortName);
        UpdateNewExistingFieldVisibilityStates();
        ChangeToStep(Step2AddNewField);

        exit(CurrPage.RunModal());
    end;

    /// <summary>
    /// Use RunModalForField to start the page in a modal form for a new field.
    /// </summary>
    /// <returns></returns>
    procedure RunModalForField(): Action
    begin
        IsRunningFromFieldDirectly := true;
        ChangeToStep(Step2AddNewField);
        exit(CurrPage.RunModal());
    end;

    local procedure LoadPagePart(FieldCode: Code[20])
    begin
        case SimpleFieldType of
            SimpleFieldType::TypeNumber:
                CurrPage.NumberFieldDetails.Page.LoadExistingField(FieldCode);
            SimpleFieldType::TypeChoice:
                CurrPage.FieldChoices.Page.LoadExistingField(FieldCode);
            SimpleFieldType::TypeAdvanced:
                CurrPage.FieldDetails.Page.LoadExistingField(FieldCode);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLeavingStepMovingForward(LeavingThisStep: Integer; var MovingToStep: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEvaluateStep(Step: Integer; var IsBackEnabled: Boolean; var IsNextEnabled: Boolean; var IsFinishEnabled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFinishActionAfterAddUpdateInternalField()
    begin
    end;
}

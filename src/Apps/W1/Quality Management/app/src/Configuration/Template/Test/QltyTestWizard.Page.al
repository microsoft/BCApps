// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Test;

using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;

/// <summary>
/// The test wizard is used to help guide a user with the creation or editing of a net new test.
/// </summary>
page 20432 "Qlty. Test Wizard"
{
    Caption = 'Quality Test Wizard';
    PageType = NavigatePage;
    UsageCategory = None;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            group(SettingsForStepNewOrExisting)
            {
                Visible = (CurrentStepCounter = Step1NewOrExisting) and (not EditingExistingTest);

                field(ChooseNewTest; NewTest)
                {
                    Caption = 'New test';
                    ToolTip = 'Specifies to add a new test.';

                    trigger OnValidate()
                    begin
                        ChooseExistingTestOrTests := not NewTest;
                        CurrPage.Update();
                    end;
                }
                field(ChooseExistingTest; ChooseExistingTestOrTests)
                {
                    Caption = 'Existing tests';
                    ToolTip = 'Specifies to add an existing test.';

                    trigger OnValidate()
                    begin
                        NewTest := not ChooseExistingTestOrTests;
                        CurrPage.Update();
                    end;
                }
                group(SettingsForWrapExistingTests)
                {
                    Visible = ChooseExistingTestOrTests or NewTest;
                    ShowCaption = false;
                    Caption = '';

                    part("Qlty. Choose Existing Tests"; "Qlty. Choose Existing Tests")
                    {
                        Enabled = ChooseExistingTestOrTests;
                        UpdatePropagation = Both;
                    }
                }
            }
            group(SettingsForEditingExistingTest)
            {
                Caption = 'Edit Existing Test';
                ShowCaption = false;
                Visible = (Step2AddNewTest = CurrentStepCounter) and EditingExistingTest;

                group(SettingsForEditExistingShortName)
                {
                    Caption = 'Short name (Test Code)';
                    InstructionalText = 'A short name for this test. This code is what will be used to reference this new test.';

                    field(ChooseEditExistingShortName; TestShortName)
                    {
                        ToolTip = 'Specifies a Short Name for this test.';
                        Caption = 'Test Code:';
                        ShowCaption = true;
                        ShowMandatory = true;
                        Editable = false;
                    }
                }
                group(SettingsForExistingTestDescription)
                {
                    Caption = 'Description';
                    InstructionalText = 'Change the description for what this test represents.';

                    field(ChooseEditDescription; TestDescription)
                    {
                        ToolTip = 'Change the description for what this test represents.';
                        Caption = 'Description';
                        ShowCaption = false;
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            HandleTestDescriptionOnValidate();
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
            group(SettingsForCreateSingleNewTest)
            {
                Caption = 'Add a New Test';
                ShowCaption = false;
                Visible = (Step2AddNewTest = CurrentStepCounter) and not EditingExistingTest;

                group(SettingsForDescription)
                {
                    Caption = 'Description';
                    InstructionalText = 'Type a relevant description for what this new test represents.';

                    field(ChooseDescription; TestDescription)
                    {
                        ToolTip = 'Type a relevant description for what this new test represents.';
                        Caption = 'Description';
                        ShowCaption = false;
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            HandleTestDescriptionOnValidate();
                        end;
                    }
                    group(SettingsForChooseDataLink)
                    {
                        Visible = not ShowNewTestCode;
                        Caption = ' ';
                        ShowCaption = false;

                        field(ChooseChoose; 'Choose the type of data this will hold.')
                        {
                            Caption = ' ';
                            ToolTip = 'Choose the type of data this will hold.';
                            Editable = false;
                            ShowCaption = false;
                            Visible = not ShowNewTestCode;

                            trigger OnDrillDown()
                            begin
                                HandleTestDescriptionOnValidate();
                            end;
                        }
                    }
                }
                group(SettingsForShortName)
                {
                    Caption = 'Short name (Test Code)';
                    InstructionalText = 'A short name for this test. This code is what will be used to reference this new test.';
                    Visible = ShowNewTestCode;

                    field(ChooseShortName; TestShortName)
                    {
                        ToolTip = 'Specifies a Short Name for this test.';
                        Caption = 'Short name.';
                        ShowCaption = false;
                        ShowMandatory = true;

                        trigger OnValidate()
                        begin
                            HandleTestCodeOnValidate();
                        end;
                    }
                }
                group(SettingsForType)
                {
                    Caption = 'What type of data is it?';
                    InstructionalText = 'Is this a number, a choice from a pre-defined list, or something else?';
                    Visible = ShowNewValueType;

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

                part(NumberFieldDetails; "Qlty. Test Number Card Part")
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
                part(TestDetails; "Qlty. Test Card Part")
                {
                    Visible = ShowAnythingElse;
                    UpdatePropagation = Both;
                    Caption = 'Test Details';
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
        NewTest: Boolean;
        ChooseExistingTestOrTests: Boolean;
        IsBackEnabled: Boolean;
        AddedOrChooseATest: Boolean;
        IsNextEnabled: Boolean;
        IsFinishEnabled: Boolean;
        IsMovingForward: Boolean;
        ShowNewTestCode: Boolean;
        ShowNewValueType: Boolean;
        ShowNumberDataType: Boolean;
        ShowChoiceDataType: Boolean;
        ShowAnythingElse: Boolean;
        IsRunningFromTestDirectly: Boolean;
        EditingExistingTest: Boolean;
        Step1NewOrExisting: Integer;
        Step2AddNewTest: Integer;
        Step3FieldDataTypeDetails: Integer;
        TestsToAdd: List of [Code[20]];
        TestDescription: Text[100];
        TestShortName: Code[20];
        SimpleFieldType: Option TypeNumber,TypeChoice,TypeFreeText,TypeDate,TypeAdvanced;
        ListOfAddedFields: List of [Code[20]];
        ChoicesQst: Label 'Use the existing test,Change the description', Locked = true;
        ChoicesMsg: Label 'There is already a test with that description. Do you want to use the existing test instead?';
        ShouldBeAtLeastThreeCharsErr: Label 'A description should be at least three characters.';

    trigger OnInit();
    begin
        NewTest := true;
        Step1NewOrExisting := 1;
        Step2AddNewTest := 2;
        Step3FieldDataTypeDetails := 3;
        if IsRunningFromTestDirectly then
            ChangeToStep(Step2AddNewTest)
        else
            ChangeToStep(Step1NewOrExisting);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        RefreshStep();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        QltyTest: Record "Qlty. Test";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        TempAddedField: Code[20];
    begin
        if not FinishActionChosen then
            foreach TempAddedField in ListOfAddedFields do begin
                QltyInspectionTemplateLine.Reset();
                QltyInspectionTemplateLine.SetRange("Test Code", TempAddedField);
                if QltyInspectionTemplateLine.IsEmpty() then
                    if QltyTest.Get(TempAddedField) then
                        if QltyTest."Wizard Internal" = QltyTest."Wizard Internal"::"In Progress" then
                            if QltyTest.Delete() then;
            end
        else
            foreach TempAddedField in ListOfAddedFields do
                if QltyTest.Get(TempAddedField) then begin
                    QltyTest."Wizard Internal" := QltyTest."Wizard Internal"::Complete;
                    QltyTest.UpdateAllowedValuesFromTableLookup();
                    QltyTest.Modify(false);
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
            LeavingStepMovingForward(CurrentStepCounter);

        EvaluateStep(Step);
        CurrentStepCounter := Step;
        CurrPage.Update(false);
    end;

    local procedure EvaluateStep(Step: Integer)
    begin
        case Step of
            Step1NewOrExisting:
                begin
                    IsBackEnabled := false;
                    IsNextEnabled := NewTest;
                    IsFinishEnabled := false;

                    if ChooseExistingTestOrTests then begin
                        UpdateChosenExistingTestsFromPart();
                        IsFinishEnabled := TestsToAdd.Count() > 0;
                    end
                end;

            Step2AddNewTest:
                begin
                    IsBackEnabled := (not IsRunningFromTestDirectly) and (not EditingExistingTest);
                    IsNextEnabled := (StrLen(TestDescription) >= 2) and (StrLen(TestShortName) >= 2);
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

    local procedure UpdateChosenExistingTestsFromPart()
    begin
        CurrPage."Qlty. Choose Existing Tests".Page.GetTestsToAdd(TestsToAdd);
    end;

    local procedure LeavingStepMovingForward(LeavingThisStep: Integer);
    begin
        case LeavingThisStep of
            Step2AddNewTest:
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
        AddedOrChooseATest := NewTest or EditingExistingTest or (ChooseExistingTestOrTests and (TestsToAdd.Count() > 0));

        if AddedOrChooseATest and NewTest then
            if not TestsToAdd.Contains(TestShortName) then
                TestsToAdd.Add(TestShortName);

        CurrPage.Close();
    end;

    procedure GetFieldsToAdd(var ListOfFieldsToAdd: List of [Code[20]]): Boolean
    begin
        ListOfFieldsToAdd := TestsToAdd;
        exit(AddedOrChooseATest);
    end;

    local procedure HandleTestDescriptionOnValidate()
    var
        TempQltyTest: Record "Qlty. Test" temporary;
    begin
        if StrLen(TestDescription) < 3 then
            Error(ShouldBeAtLeastThreeCharsErr);
        CheckForExistingTestWithSameDescription();

        if not EditingExistingTest then
            TempQltyTest.SuggestUnusedTestCodeFromDescription(TestDescription, TestShortName);

        UpdateNewExistingFieldVisibilityStates();
        EvaluateStep(CurrentStepCounter);
    end;

    local procedure CheckForExistingTestWithSameDescription()
    var
        QltyTest: Record "Qlty. Test";
    begin
        if EditingExistingTest then
            QltyTest.SetFilter(Code, '<>%1', TestShortName);

        QltyTest.SetRange(Description, TestDescription);
        if QltyTest.FindFirst() then
            case StrMenu(ChoicesQst, 1, ChoicesMsg) of
                1:
                    if IsRunningFromTestDirectly then
                        CurrPage.Close()
                    else begin
                        CurrentStepCounter := Step1NewOrExisting;
                        ChooseExistingTestOrTests := true;
                        NewTest := false;
                        CurrPage."Qlty. Choose Existing Tests".Page.SetChooseTest(QltyTest.Code, true);
                        CurrPage.Update();
                    end;
            end;

        if not EditingExistingTest then
            QltyTest.SuggestUnusedTestCodeFromDescription(TestDescription, TestShortName);
    end;

    local procedure HandleTestCodeOnValidate()
    var
        TempQltyTest: Record "Qlty. Test" temporary;
    begin
        TempQltyTest.SuggestUnusedTestCodeFromDescription(TestShortName, TestShortName);
        UpdateNewExistingFieldVisibilityStates();
    end;

    local procedure HandleFieldValidateType()
    begin
        UpdateNewExistingFieldVisibilityStates();
    end;

    local procedure UpdateNewExistingFieldVisibilityStates()
    begin
        ShowNewTestCode := StrLen(TestDescription) > 1;
        ShowNewValueType := StrLen(TestShortName) > 1;

        ShowNumberDataType := SimpleFieldType = SimpleFieldType::TypeNumber;
        ShowChoiceDataType := SimpleFieldType = SimpleFieldType::TypeChoice;

        ShowAnythingElse := SimpleFieldType = SimpleFieldType::TypeAdvanced;
        CurrPage.Update();
    end;

    local procedure AddOrUpdateInternalField()
    var
        QltyTest: Record "Qlty. Test";
        TempPreviousVersionOfQltyTest: Record "Qlty. Test" temporary;
        QltyLookupCode: Record "Qlty. Lookup Code";
    begin
        if TestShortName = '' then
            exit;

        if not QltyTest.Get(TestShortName) then begin
            QltyTest.Init();
            QltyTest."Wizard Internal" := QltyTest."Wizard Internal"::"In Progress";
            QltyTest.Code := TestShortName;
            QltyTest.Description := TestDescription;
            QltyTest.Insert();
        end;

        TempPreviousVersionOfQltyTest := QltyTest;
        QltyTest.Description := TestDescription;
        if not ListOfAddedFields.Contains(TestShortName) then
            ListOfAddedFields.Add(TestShortName);
        case SimpleFieldType of
            SimpleFieldType::TypeDate:
                QltyTest."Test Value Type" := QltyTest."Test Value Type"::"Value Type Date";
            SimpleFieldType::TypeFreeText:
                QltyTest."Test Value Type" := QltyTest."Test Value Type"::"Value Type Text";
            SimpleFieldType::TypeNumber:
                begin
                    QltyTest."Test Value Type" := QltyTest."Test Value Type"::"Value Type Decimal";
                    QltyTest."Allowable Values" := CopyStr(CurrPage.NumberFieldDetails.Page.GetAllowableValues(), 1, MaxStrLen(QltyTest."Allowable Values"));
                end;
            SimpleFieldType::TypeChoice:
                begin
                    QltyTest."Test Value Type" := QltyTest."Test Value Type"::"Value Type Table Lookup";
                    if QltyTest."Lookup Table No." = 0 then begin
                        QltyTest.Validate("Lookup Table No.", Database::"Qlty. Lookup Code");
                        QltyTest.Validate("Lookup Field No.", QltyLookupCode.FieldNo(Code));
                    end;
                end;
        end;
        if QltyTest."Wizard Internal" = QltyTest."Wizard Internal"::Complete then
            if TempPreviousVersionOfQltyTest."Test Value Type" <> QltyTest."Test Value Type" then
                QltyTest.HandleOnValidateTestValueType(false);

        QltyTest.UpdateAllowedValuesFromTableLookup();
        QltyTest.Modify();
        LoadPagePart(QltyTest.Code);
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Use this to start the edit test wizard page from the context of an existing test.
    /// </summary>
    /// <param name="QltyTest"></param>
    /// <returns></returns>
    procedure RunModalEditExistingTest(var QltyTest: Record "Qlty. Test"): Action
    begin
        EditingExistingTest := true;
        TestShortName := QltyTest.Code;
        TestDescription := QltyTest.Description;
        case QltyTest."Test Value Type" of
            QltyTest."Test Value Type"::"Value Type Decimal":
                SimpleFieldType := SimpleFieldType::TypeNumber;
            QltyTest."Test Value Type"::"Value Type Table Lookup":
                SimpleFieldType := SimpleFieldType::TypeChoice;
            QltyTest."Test Value Type"::"Value Type Text":
                SimpleFieldType := SimpleFieldType::TypeFreeText;
            QltyTest."Test Value Type"::"Value Type Date":
                SimpleFieldType := SimpleFieldType::TypeDate;
            else
                SimpleFieldType := SimpleFieldType::TypeAdvanced;
        end;
        LoadPagePart(TestShortName);
        UpdateNewExistingFieldVisibilityStates();
        ChangeToStep(Step2AddNewTest);

        exit(CurrPage.RunModal());
    end;

    /// <summary>
    /// Use RunModalForTest to start the page in a modal form for a new test.
    /// </summary>
    /// <returns></returns>
    procedure RunModalForTest(): Action
    begin
        IsRunningFromTestDirectly := true;
        ChangeToStep(Step2AddNewTest);
        exit(CurrPage.RunModal());
    end;

    local procedure LoadPagePart(TestCode: Code[20])
    begin
        case SimpleFieldType of
            SimpleFieldType::TypeNumber:
                CurrPage.NumberFieldDetails.Page.LoadExistingTest(TestCode);
            SimpleFieldType::TypeChoice:
                CurrPage.FieldChoices.Page.LoadExistingTest(TestCode);
            SimpleFieldType::TypeAdvanced:
                CurrPage.TestDetails.Page.LoadExistingTest(TestCode);
        end;
    end;

}

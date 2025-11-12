// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

page 5189 "Create Rating"
{
    Caption = 'Create Rating';
    DataCaptionExpression = Rec."Profile Questionnaire Code" + ' ' + Rec.Description;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    SourceTable = "Profile Questionnaire Line";

    layout
    {
        area(content)
        {
            group(Step3)
            {
                Caption = 'Step 3';
                InstructionalText = 'Please specify the range of points required to get the different answer options.';
                Visible = Step3Visible;
                field(GetProfileLineAnswerDesc; Rec.GetProfileLineAnswerDesc())
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Please select one of the options below to specify the points your contact must earn in order to receive this rating.';
                    Editable = false;
                    MultiLine = true;
                }
                group(Control3)
                {
                    ShowCaption = false;
                    field("Interval Option"; Rec."Interval Option")
                    {
                        ApplicationArea = RelationshipMgmt;
                        ValuesAllowed = Interval;

                        trigger OnValidate()
                        begin
                            if Rec."Interval Option" = Rec."Interval Option"::Interval then
                                IntervalIntervalOptionOnValida();
                        end;
                    }
                    field("Wizard From Value"; Rec."Wizard From Value")
                    {
                        ApplicationArea = RelationshipMgmt;
                        BlankZero = true;
                        Caption = 'From:';
                        DecimalPlaces = 0 :;
                        Enabled = WizardFromValueEnable;
                    }
                    field("Wizard To Value"; Rec."Wizard To Value")
                    {
                        ApplicationArea = RelationshipMgmt;
                        BlankZero = true;
                        Caption = 'To:';
                        DecimalPlaces = 0 :;
                        Enabled = WizardToValueEnable;
                    }
                }
                group(Control32)
                {
                    ShowCaption = false;
                    field("Interval Option2"; Rec."Interval Option")
                    {
                        ApplicationArea = RelationshipMgmt;
                        ValuesAllowed = Minimum;

                        trigger OnValidate()
                        begin
                            if Rec."Interval Option" = Rec."Interval Option"::Minimum then
                                MinimumIntervalOptionOnValidat();
                        end;
                    }
                    field(Minimum; Rec."Wizard From Value")
                    {
                        ApplicationArea = RelationshipMgmt;
                        BlankZero = true;
                        Caption = 'From:';
                        DecimalPlaces = 0 :;
                        Enabled = MinimumEnable;
                    }
                }
                group(Control33)
                {
                    ShowCaption = false;
                    field("Interval Option3"; Rec."Interval Option")
                    {
                        ApplicationArea = RelationshipMgmt;
                        ValuesAllowed = Maximum;

                        trigger OnValidate()
                        begin
                            if Rec."Interval Option" = Rec."Interval Option"::Maximum then
                                MaximumIntervalOptionOnValidat();
                        end;
                    }
                    field(Maximum; Rec."Wizard To Value")
                    {
                        ApplicationArea = RelationshipMgmt;
                        BlankZero = true;
                        Caption = 'To:';
                        DecimalPlaces = 0 :;
                        Enabled = MaximumEnable;
                    }
                }
            }
            group(Step1)
            {
                Caption = 'Step 1';
                InstructionalText = 'This wizard helps you define the methods you will use to rate your contacts.';
                Visible = Step1Visible;
                field("Profile Questionnaire Code"; Rec."Profile Questionnaire Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'For which questionnaire should this rating be created';
                    TableRelation = "Profile Questionnaire Header";
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Describe the type of rating (for example, Overall Customer Rating)';
                    MultiLine = true;
                }
                field("Min. % Questions Answered"; Rec."Min. % Questions Answered")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'What percentage of questions need to be answered before a rating is assigned?';
                    MultiLine = true;
                }
            }
            group(Step4)
            {
                Caption = 'Step 4';
                InstructionalText = 'When you choose Finish, the questions and answers you have created will be saved and the Answer Points window will open. In this window, you can assign points to each answer.';
                Visible = Step4Visible;
                part(SubForm; "Create Rating Subform")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    Visible = SubFormVisible;
                }
            }
            group(Step2)
            {
                Caption = 'Step 2';
                Visible = Step2Visible;
                field("Answer Option"; Rec."Answer Option")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Specify which of the following grouping methods you will use to rate your contacts.';
                    ValuesAllowed = HighLow, ABC, Custom;

                    trigger OnValidate()
                    begin
                        if Rec."Answer Option" = Rec."Answer Option"::Custom then
                            CustomAnswerOptionOnValidate();
                        if Rec."Answer Option" = Rec."Answer Option"::ABC then
                            ABCAnswerOptionOnValidate();
                        if Rec."Answer Option" = Rec."Answer Option"::HighLow then
                            HighLowAnswerOptionOnValidate();
                    end;
                }
                field(NoOfAnswers; Rec.NoOfProfileAnswers())
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Number of possible answers:';
                    Enabled = NoOfAnswersEnable;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowAnswers();
                        CurrPage.Update();
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Back)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Back';
                Enabled = BackEnable;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    ShowStep(false);
                    Rec.PerformPrevWizardStatus();
                    ShowStep(true);
                    UpdateCntrls();
                    CurrPage.Update(true);
                end;
            }
            action(Next)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Next';
                Enabled = NextEnable;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    Rec.CheckStatus();
                    ShowStep(false);
                    Rec.PerformNextWizardStatus();
                    ShowStep(true);
                    UpdateCntrls();
                    CurrPage.Update(true);
                end;
            }
            action(Finish)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Finish';
                Enabled = FinishEnable;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    Rec.CheckStatus();
                    Rec.FinishWizard();
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        MaximumEnable := true;
        MinimumEnable := true;
        WizardToValueEnable := true;
        WizardFromValueEnable := true;
        NoOfAnswersEnable := true;
        NextEnable := true;
        SubFormVisible := true;
    end;

    trigger OnOpenPage()
    begin
        FormWidth := CancelXPos + CancelWidth + 220;
        FrmXPos := Round((FrmWidth - FormWidth) / 2, 1) + FrmXPos;
        FrmWidth := FormWidth;

        Rec.Validate("Auto Contact Classification", true);
        Rec.Validate("Contact Class. Field", Rec."Contact Class. Field"::Rating);
        Rec.Modify();

        Rec.ValidateAnswerOption();
        Rec.ValidateIntervalOption();

        ShowStep(true);

        UpdateCntrls();
    end;

    var
        TempProfileLineAnswer: Record "Profile Questionnaire Line" temporary;
        FormWidth: Integer;
        CancelXPos: Integer;
        CancelWidth: Integer;
        FrmXPos: Integer;
        FrmWidth: Integer;
        Step1Visible: Boolean;
        Step2Visible: Boolean;
        Step3Visible: Boolean;
        Step4Visible: Boolean;
        SubFormVisible: Boolean;
        NextEnable: Boolean;
        BackEnable: Boolean;
        FinishEnable: Boolean;
        NoOfAnswersEnable: Boolean;
        WizardFromValueEnable: Boolean;
        WizardToValueEnable: Boolean;
        MinimumEnable: Boolean;
        MaximumEnable: Boolean;

    local procedure ShowStep(Visible: Boolean)
    begin
        case Rec."Wizard Step" of
            Rec."Wizard Step"::"1":
                begin
                    NextEnable := true;
                    BackEnable := false;
                    Step1Visible := Visible;
                    if Visible then;
                end;
            Rec."Wizard Step"::"2":
                begin
                    Step2Visible := Visible;
                    BackEnable := true;
                    NextEnable := true;
                end;
            Rec."Wizard Step"::"3":
                begin
                    Step3Visible := Visible;
                    if Visible then begin
                        BackEnable := true;
                        NextEnable := true;
                        FinishEnable := false;
                    end;
                end;
            Rec."Wizard Step"::"4":
                begin
                    if Visible then begin
                        Rec.GetAnswers(TempProfileLineAnswer);
                        CurrPage.SubForm.PAGE.SetRecords(Rec, TempProfileLineAnswer);
                    end;
                    FinishEnable := true;
                    NextEnable := false;
                    Step4Visible := Visible;
                    CurrPage.SubForm.PAGE.UpdateForm();
                end;
        end;
    end;

    local procedure UpdateCntrls()
    begin
        NoOfAnswersEnable := Rec."Answer Option" = Rec."Answer Option"::Custom;
        WizardFromValueEnable := Rec."Interval Option" = Rec."Interval Option"::Interval;
        WizardToValueEnable := Rec."Interval Option" = Rec."Interval Option"::Interval;
        MinimumEnable := Rec."Interval Option" = Rec."Interval Option"::Minimum;
        MaximumEnable := Rec."Interval Option" = Rec."Interval Option"::Maximum;
    end;

    local procedure IntervalIntervalOptionOnValida()
    begin
        Rec.ValidateIntervalOption();
        UpdateCntrls();
    end;

    local procedure MinimumIntervalOptionOnValidat()
    begin
        Rec.ValidateIntervalOption();
        UpdateCntrls();
    end;

    local procedure MaximumIntervalOptionOnValidat()
    begin
        Rec.ValidateIntervalOption();
        UpdateCntrls();
    end;

    local procedure HighLowAnswerOptionOnValidate()
    begin
        Rec.ValidateAnswerOption();
        UpdateCntrls();
    end;

    local procedure ABCAnswerOptionOnValidate()
    begin
        Rec.ValidateAnswerOption();
        UpdateCntrls();
    end;

    local procedure CustomAnswerOptionOnValidate()
    begin
        Rec.ValidateAnswerOption();
        Rec.ShowAnswers();
        UpdateCntrls();
    end;
}


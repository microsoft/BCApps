namespace System.IO;

page 8611 "Config. Question Area"
{
    Caption = 'Config. Question Area';
    PageType = ListPlus;
    PopulateAllFields = true;
    SourceTable = "Config. Question Area";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    NotBlank = true;
                    ToolTip = 'Specifies the code for the question area. You fill in a value for the code when you create a question area for your setup questionnaire.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the question area code.';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the table that the question area manages. You can select any application table from the Objects window.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the table that is supporting the setup questionnaire area. The name comes from the name property of the table.';
                }
            }
            part(ConfigQuestionSubform; "Config. Question Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Questionnaire Code" = field("Questionnaire Code"),
                              "Question Area Code" = field(Code);
                SubPageView = sorting("Questionnaire Code", "Question Area Code", "No.")
                              order(ascending);
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Question")
            {
                Caption = '&Question';
                Image = Questionaire;
                separator(Action13)
                {
                }
                action(UpdateQuestions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Update Questions';
                    Image = Refresh;
                    ToolTip = 'Fill the question list based on the fields in the table on which the question area is based.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(ConfigQuestionArea);
                        if ConfigQuestionArea.FindSet() then begin
                            repeat
                                QuestionnaireMgt.UpdateQuestions(ConfigQuestionArea);
                            until ConfigQuestionArea.Next() = 0;
                            Message(QuestionsUpdatedMsg);
                        end;
                    end;
                }
                action(ApplyAnswers)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Apply Answers';
                    Image = Apply;
                    ToolTip = 'Implement answers in the questionnaire in the related setup fields.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(ConfigQuestionArea);
                        if ConfigQuestionArea.FindSet() then begin
                            repeat
                                QuestionnaireMgt.ApplyAnswer(ConfigQuestionArea);
                            until ConfigQuestionArea.Next() = 0;
                            Message(AnswersAppliedMsg);
                        end;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(UpdateQuestions_Promoted; UpdateQuestions)
                {
                }
                actionref(ApplyAnswers_Promoted; ApplyAnswers)
                {
                }
            }
        }
    }

    var
        ConfigQuestionArea: Record "Config. Question Area";
        QuestionnaireMgt: Codeunit "Questionnaire Management";
        QuestionsUpdatedMsg: Label 'Questions have been updated.';
        AnswersAppliedMsg: Label 'Answers have been applied.';
}


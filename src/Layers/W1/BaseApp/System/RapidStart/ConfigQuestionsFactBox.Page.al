namespace System.IO;

page 8633 "Config. Questions FactBox"
{
    Caption = 'Configuration Questions';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Config. Question";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Questionnaire Code"; Rec."Questionnaire Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the questionnaire.';
                    Visible = false;
                }
                field("Question Area Code"; Rec."Question Area Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the question area.';
                    Visible = false;
                }
                field(Question; Rec.Question)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a question that is to be answered on the setup questionnaire. On the Actions tab, in the Question group, choose Update Questions to auto populate the question list based on the fields in the table on which the question area is based. You can modify the text to be more meaningful to the person responsible for filling out the questionnaire. For example, you could rewrite the Name? question as What is the name of your company?';
                }
                field(Answer; Rec.Answer)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the answer to the question. The answer to the question should match the format of the answer option and must be a value that the database supports. If it does not, then there will be an error when you apply the answer.';
                }
            }
        }
    }

    actions
    {
    }
}


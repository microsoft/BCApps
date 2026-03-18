namespace System.IO;

page 8610 "Config. Questionnaire"
{
    AdditionalSearchTerms = 'rapid start implementation migrate setup questionnaire';
    ApplicationArea = Suite;
    Caption = 'Configuration Questionnaire';
    PageType = List;
    SourceTable = "Config. Questionnaire";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the configuration questionnaire that you are creating.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the configuration questionnaire.';
                }
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
            group("&Questionnaire")
            {
                Caption = '&Questionnaire';
                Image = Questionaire;
                action(ExportToExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&xport to Excel';
                    Ellipsis = true;
                    Image = ExportToExcel;
                    ToolTip = 'Export data in the questionnaire to Excel.';

                    trigger OnAction()
                    begin
                        Rec.TestField(Code);
                        if QuestionnaireMgt.ExportQuestionnaireToExcel('', Rec) then
                            Message(QuestionnaireExportedMsg);
                    end;
                }
                separator(Action9)
                {
                }
                action(ExportToXML)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Export to XML';
                    Ellipsis = true;
                    Image = Export;
                    ToolTip = 'Export information in the questionnaire to Excel.';

                    trigger OnAction()
                    begin
                        if QuestionnaireMgt.ExportQuestionnaireAsXML('', Rec) then
                            Message(QuestionnaireExportedMsg)
                        else
                            Message(QuestionnaireExportCanceledMsg);
                    end;
                }
                action(ImportFromXML)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Import from XML';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Import information from XML into the questionnaire. Save the filled Excel file as "XML Data" to produce the XML file to import.';

                    trigger OnAction()
                    begin
                        if QuestionnaireMgt.ImportQuestionnaireAsXMLFromClient() then
                            Message(QuestionnaireImportedMsg);
                    end;
                }
                separator(Action6)
                {
                }
                action("&Update Questionnaire")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Update Questionnaire';
                    Image = Refresh;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    ToolTip = 'Fill the question list based on the fields in the table on which the question area is based.';

                    trigger OnAction()
                    begin
                        if QuestionnaireMgt.UpdateQuestionnaire(Rec) then
                            Message(QuestionnaireUpdatedMsg);
                    end;
                }
                action("&Apply Answers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Apply Answers';
                    Image = Apply;
                    ToolTip = 'Implement answers in the questionnaire in the related setup fields.';

                    trigger OnAction()
                    begin
                        if QuestionnaireMgt.ApplyAnswers(Rec) then
                            Message(AnswersAppliedMsg);
                    end;
                }
            }
        }
        area(navigation)
        {
            group(Areas)
            {
                Caption = 'Areas';
                action("&Question Areas")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Question Areas';
                    Image = View;
                    RunObject = Page "Config. Question Areas";
                    RunPageLink = "Questionnaire Code" = field(Code);
                    ToolTip = 'View the areas that questions are grouped by.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("&Apply Answers_Promoted"; "&Apply Answers")
                {
                }
                actionref("&Question Areas_Promoted"; "&Question Areas")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Excel', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(ExportToExcel_Promoted; ExportToExcel)
                {
                }
                actionref(ExportToXML_Promoted; ExportToXML)
                {
                }
                actionref(ImportFromXML_Promoted; ImportFromXML)
                {
                }
            }
        }
    }

    var
        QuestionnaireMgt: Codeunit "Questionnaire Management";

        QuestionnaireExportedMsg: Label 'The questionnaire has been successfully exported.';
        QuestionnaireImportedMsg: Label 'The questionnaire has been successfully imported.';
        QuestionnaireExportCanceledMsg: Label 'The export of the questionnaire has been canceled.';
        QuestionnaireUpdatedMsg: Label 'The questionnaire has been updated.';
        AnswersAppliedMsg: Label 'Answers have been applied.';
}


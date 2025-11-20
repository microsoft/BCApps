// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Reports;

page 5110 "Profile Questionnaire Setup"
{
    AutoSplitKey = true;
    Caption = 'Profile Questionnaire Setup';
    DataCaptionExpression = CaptionExpr;
    PageType = List;
    SaveValues = true;
    SourceTable = "Profile Questionnaire Line";

    layout
    {
        area(content)
        {
            field(ProfileQuestionnaireCodeName; CurrentQuestionsChecklistCode)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Profile Questionnaire Code';
                ToolTip = 'Specifies the profile questionnaire.';
                Visible = ProfileQuestionnaireCodeNameVi;

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord();
                    Commit();
                    if PAGE.RunModal(0, ProfileQuestnHeader) = ACTION::LookupOK then begin
                        ProfileQuestnHeader.Get(ProfileQuestnHeader.Code);
                        CurrentQuestionsChecklistCode := ProfileQuestnHeader.Code;
                        ProfileManagement.SetName(CurrentQuestionsChecklistCode, Rec, 0);
                        CurrPage.Update(false);
                    end;
                end;

                trigger OnValidate()
                begin
                    ProfileQuestnHeader.Get(CurrentQuestionsChecklistCode);
                    CurrentQuestionsChecklistCodeO();
                end;
            }
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies whether the entry is a question or an answer.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the profile question or answer.';
                }
                field("Multiple Answers"; Rec."Multiple Answers")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the question has more than one possible answer.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = RelationshipMgmt;
                    HideValue = PriorityHideValue;
                    ToolTip = 'Specifies the priority you give to the answer and where it should be displayed on the lines of the Contact Card. There are five options:';
                }
                field("Auto Contact Classification"; Rec."Auto Contact Classification")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies that the question is automatically answered when you run the Update Contact Classification batch job.';
                }
                field("From Value"; Rec."From Value")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the value from which the automatic classification of your contacts starts.';
                }
                field("To Value"; Rec."To Value")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the value that the automatic classification of your contacts stops at.';
                }
                field("No. of Contacts"; Rec."No. of Contacts")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of contacts that have given this answer.';
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
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Question Details")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Question Details';
                    Image = Questionaire;
                    Scope = Repeater;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View detailed information about the questions within the questionnaire.';

                    trigger OnAction()
                    begin
                        case Rec.Type of
                            Rec.Type::Question:
                                PAGE.RunModal(PAGE::"Profile Question Details", Rec);
                            Rec.Type::Answer:
                                Error(Text000);
                        end;
                    end;
                }
                action("Answer Where-Used")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Answer Where-Used';
                    Image = Trace;
                    ToolTip = 'View which questions the current answer is based on with the number of points given.';

                    trigger OnAction()
                    var
                        Rating: Record Rating;
                    begin
                        case Rec.Type of
                            Rec.Type::Question:
                                Error(Text001);
                            Rec.Type::Answer:
                                begin
                                    Rating.SetRange("Rating Profile Quest. Code", Rec."Profile Questionnaire Code");
                                    Rating.SetRange("Rating Profile Quest. Line No.", Rec."Line No.");
                                    PAGE.RunModal(PAGE::"Answer Where-Used", Rating);
                                end;
                        end;
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                separator(Action34)
                {
                }
                action("Update &Classification")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Update &Classification';
                    Image = Refresh;
                    ToolTip = 'Update automatic classification of your contacts. This batch job updates all the answers to the profile questions that are automatically answered by the program, based on customer, vendor or contact data.';

                    trigger OnAction()
                    var
                        ProfileQuestnHeader: Record "Profile Questionnaire Header";
                    begin
                        ProfileQuestnHeader.Get(CurrentQuestionsChecklistCode);
                        ProfileQuestnHeader.SetRecFilter();
                        REPORT.Run(REPORT::"Update Contact Classification", true, false, ProfileQuestnHeader);
                    end;
                }
                separator(Action31)
                {
                }
                action("Move &Up")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Move &Up';
                    Image = MoveUp;
                    Scope = Repeater;
                    ToolTip = 'Change the sorting order of the lines.';

                    trigger OnAction()
                    begin
                        Rec.MoveUp();
                    end;
                }
                action("Move &Down")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Move &Down';
                    Image = MoveDown;
                    Scope = Repeater;
                    ToolTip = 'Change the sorting order of the lines.';

                    trigger OnAction()
                    begin
                        Rec.MoveDown();
                    end;
                }
                separator(Action32)
                {
                    Caption = '';
                }
                action(Print)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Print';
                    Image = Print;
                    ToolTip = 'Print the information in the window. A print request window opens where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        ProfileQuestnHeader: Record "Profile Questionnaire Header";
                    begin
                        ProfileQuestnHeader.SetRange(Code, CurrentQuestionsChecklistCode);
                        REPORT.Run(REPORT::"Questionnaire - Handouts", true, false, ProfileQuestnHeader);
                    end;
                }
                action("Test Report")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Test Report';
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    var
                        ProfileQuestnHeader: Record "Profile Questionnaire Header";
                    begin
                        ProfileQuestnHeader.SetRange(Code, CurrentQuestionsChecklistCode);
                        REPORT.Run(REPORT::"Questionnaire - Test", true, false, ProfileQuestnHeader);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Move &Up_Promoted"; "Move &Up")
                {
                }
                actionref("Move &Down_Promoted"; "Move &Down")
                {
                }
                group(Category_Category5)
                {
                    Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 4.';

                    actionref("Question Details_Promoted"; "Question Details")
                    {
                    }
                    actionref("Answer Where-Used_Promoted"; "Answer Where-Used")
                    {
                    }
                }
                actionref("Update &Classification_Promoted"; "Update &Classification")
                {
                }
                actionref(Print_Promoted; Print)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        PriorityHideValue := false;
        StyleIsStrong := false;
        DescriptionIndent := 0;

        if Rec.Type = Rec.Type::Question then begin
            StyleIsStrong := true;
            PriorityHideValue := true;
        end else
            DescriptionIndent := 1;
    end;

    trigger OnInit()
    begin
        ProfileQuestionnaireCodeNameVi := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Profile Questionnaire Code" := CurrentQuestionsChecklistCode;
        Rec.Type := Rec.Type::Answer;
    end;

    trigger OnOpenPage()
    var
        ProfileQuestionnaireHeader: Record "Profile Questionnaire Header";
    begin
        if Rec.GetFilter("Profile Questionnaire Code") <> '' then begin
            ProfileQuestionnaireHeader.SetFilter(Code, Rec.GetFilter("Profile Questionnaire Code"));
            if ProfileQuestionnaireHeader.Count = 1 then begin
                ProfileQuestionnaireHeader.FindFirst();
                CurrentQuestionsChecklistCode := ProfileQuestionnaireHeader.Code;
            end;
        end;

        if CurrentQuestionsChecklistCode = '' then
            CurrentQuestionsChecklistCode := ProfileManagement.GetQuestionnaire();

        ProfileManagement.SetName(CurrentQuestionsChecklistCode, Rec, 0);

        CaptionExpr := Rec."Profile Questionnaire Code";
        ProfileQuestionnaireCodeNameVi := false;
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Details only available for questions.';
#pragma warning restore AA0074
        ProfileQuestnHeader: Record "Profile Questionnaire Header";
        ProfileManagement: Codeunit ProfileManagement;
#pragma warning disable AA0074
        Text001: Label 'Where-Used only available for answers.';
#pragma warning restore AA0074
        CaptionExpr: Text[100];
        ProfileQuestionnaireCodeNameVi: Boolean;
        DescriptionIndent: Integer;
        StyleIsStrong: Boolean;
        PriorityHideValue: Boolean;

    protected var
        CurrentQuestionsChecklistCode: Code[20];

    local procedure CurrentQuestionsChecklistCodeO()
    begin
        ProfileManagement.SetName(CurrentQuestionsChecklistCode, Rec, 0);
    end;
}


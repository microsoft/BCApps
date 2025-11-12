// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

using System.Environment;

page 5172 "Answer Points"
{
    Caption = 'Answer Points';
    DataCaptionExpression = GetCaption();
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Profile Questionnaire Line";

    layout
    {
        area(content)
        {
            repeater(Questions)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies whether the entry is a question or an answer.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the profile question or answer.';
                }
                field("No. of Contacts"; Rec."No. of Contacts")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of contacts that have given this answer.';
                }
                field(Points; Points)
                {
                    ApplicationArea = RelationshipMgmt;
                    BlankZero = true;
                    Caption = 'Points';
                    DecimalPlaces = 0 : 0;
                    ToolTip = 'Specifies all questions and answers in the profile questionnaire.';

                    trigger OnValidate()
                    var
                        Rating: Record Rating;
                    begin
                        Rec.TestField(Type, Rec.Type::Answer);

                        if Rating.Get(TargetQuestnCode, TargetQuestLineNo, Rec."Profile Questionnaire Code", Rec."Line No.") then
                            if Points = 0 then
                                Rating.Delete()
                            else begin
                                Rating.Points := Points;
                                Rating.Modify();
                            end
                        else begin
                            Rating."Profile Questionnaire Code" := TargetQuestnCode;
                            Rating."Profile Questionnaire Line No." := TargetQuestLineNo;
                            Rating."Rating Profile Quest. Code" := Rec."Profile Questionnaire Code";
                            Rating."Rating Profile Quest. Line No." := Rec."Line No.";
                            Rating.Points := Points;
                            Rating.Insert(true);
                        end;
                    end;
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
            action(Questionnaire)
            {
                ApplicationArea = RelationshipMgmt;
                Image = Questionnaire;

                trigger OnAction()
                var
                    ProfileQuestnHeader: Record "Profile Questionnaire Header";
                begin
                    if ProfileQuestnHeader.Get(Rec."Profile Questionnaire Code") then
                        if PAGE.RunModal(
                             PAGE::"Profile Questionnaire List", ProfileQuestnHeader) = ACTION::LookupOK
                        then begin
                            Rec.SetRange("Profile Questionnaire Code", ProfileQuestnHeader.Code);
                            CurrQuestnCode := ProfileQuestnHeader.Code;
                            SetRatingFilter();
                            CurrPage.Update();
                        end;
                end;
            }
            group("&Points")
            {
                Caption = '&Points';
                action(List)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    ToolTip = 'View the answers from which a contact can gain points when you calculate the rating.';

                    trigger OnAction()
                    var
                        Rating: Record Rating;
                    begin
                        Rating.SetRange("Profile Questionnaire Code", TargetQuestnCode);
                        Rating.SetRange("Profile Questionnaire Line No.", TargetQuestLineNo);
                        if PAGE.RunModal(PAGE::"Answer Points List", Rating) = ACTION::LookupOK then begin
                            CurrQuestnCode := Rating."Rating Profile Quest. Code";
                            Rec.SetRange("Profile Questionnaire Code", CurrQuestnCode);
                            Rec.Get(CurrQuestnCode, Rating."Rating Profile Quest. Line No.");
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

                actionref(Questionnaire_Promoted; Questionnaire)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Rating: Record Rating;
    begin
        if Rating.Get(TargetQuestnCode, TargetQuestLineNo, Rec."Profile Questionnaire Code", Rec."Line No.") then
            Points := Rating.Points
        else
            Points := 0;
    end;

    trigger OnAfterGetRecord()
    var
        Rating: Record Rating;
    begin
        if Rating.Get(TargetQuestnCode, TargetQuestLineNo, Rec."Profile Questionnaire Code", Rec."Line No.") then
            Points := Rating.Points
        else
            Points := 0;

        StyleIsStrong := Rec.Type = Rec.Type::Question;
        if Rec.Type <> Rec.Type::Question then
            DescriptionIndent := 1
        else
            DescriptionIndent := 0;
    end;

    trigger OnOpenPage()
    var
        TempProfileQuestnLine: Record "Profile Questionnaire Line";
    begin
        TargetQuestnCode := Rec."Profile Questionnaire Code";
        TargetQuestLineNo := Rec."Line No.";
        TargetQuestnLineNoEnd := Rec."Line No.";
        CurrQuestnCode := Rec."Profile Questionnaire Code";

        if TempProfileQuestnLine.Get(TargetQuestnCode, Rec."Line No.") then
            while (TempProfileQuestnLine.Next() <> 0) and
                  (TempProfileQuestnLine.Type = TempProfileQuestnLine.Type::Answer)
            do
                TargetQuestnLineNoEnd := TempProfileQuestnLine."Line No.";

        SetRatingFilter();
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";
        CurrQuestnCode: Code[20];
        TargetQuestnCode: Code[20];
        TargetQuestLineNo: Integer;
        TargetQuestnLineNoEnd: Integer;
        Points: Decimal;
        StyleIsStrong: Boolean;
        DescriptionIndent: Integer;

    procedure SetRatingFilter()
    begin
        Rec.FilterGroup(2);
        if CurrQuestnCode = TargetQuestnCode then
            Rec.SetFilter("Line No.", '<%1|>%2', TargetQuestLineNo, TargetQuestnLineNoEnd)
        else
            Rec.SetRange("Line No.");
        Rec.FilterGroup(0);
    end;

    local procedure GetCaption(): Text
    begin
        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone then
            exit(StrSubstNo('%1 %2', CurrPage.Caption, Rec."Profile Questionnaire Code"));

        exit(Format(Rec."Profile Questionnaire Code"));
    end;
}


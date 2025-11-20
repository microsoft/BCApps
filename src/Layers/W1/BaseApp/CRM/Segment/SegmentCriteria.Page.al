// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

page 5143 "Segment Criteria"
{
    Caption = 'Segment Criteria';
    DataCaptionFields = "Segment No.";
    Editable = false;
    PageType = List;
    SourceTable = "Segment Criteria Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = ActionTableIndent;
                IndentationControls = ActionTable;
                ShowCaption = false;
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the segment criteria line.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the type of information that the line shows. There are two options: Action or Filter.';
                    Visible = false;
                }
                field(ActionTable; Rec.ActionTable())
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Action/Table';
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the actions that you have performed (adding or removing contacts) in order to define the segment criteria. The related table is shown under each action.';
                }
                field("Filter"; GetSegmentCriteriaFilter())
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Filter';
                    ToolTip = 'Specifies which segment criteria are shown.';
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
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Save)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Save';
                    Image = Save;
                    ToolTip = 'Save the segment criteria.';

                    trigger OnAction()
                    var
                        SegHeader: Record "Segment Header";
                    begin
                        SegHeader.Get(Rec."Segment No.");
                        SegHeader.SaveCriteria();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StyleIsStrong := Rec.Type = Rec.Type::Action;
        if Rec.Type <> Rec.Type::Action then
            ActionTableIndent := 1
        else
            ActionTableIndent := 0;
    end;

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey("Segment No.", "Line No.");
        Rec.SetRange(Type);
    end;

    var
        StyleIsStrong: Boolean;
        ActionTableIndent: Integer;

    local procedure GetSegmentCriteriaFilter(): Text
    var
        SegCriteriaManagement: Codeunit SegCriteriaManagement;
    begin
        exit(SegCriteriaManagement.GetSegCriteriaFilters(Rec."Table No.", Rec."Table View"));
    end;
}


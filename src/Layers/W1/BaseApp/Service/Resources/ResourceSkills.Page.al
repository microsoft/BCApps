// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Resources;

page 6019 "Resource Skills"
{
    Caption = 'Resource Skills';
    DataCaptionFields = "No.", "Skill Code";
    PageType = List;
    SourceTable = "Resource Skill";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Jobs;
                    Visible = TypeVisible;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Jobs;
                    Visible = NoVisible;
                }
                field("Skill Code"; Rec."Skill Code")
                {
                    ApplicationArea = Jobs;
                    Visible = SkillCodeVisible;
                }
                field("Assigned From"; Rec."Assigned From")
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    Editable = false;
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
    }

    trigger OnDeleteRecord(): Boolean
    begin
        Clear(ResSkill);
        CurrPage.SetSelectionFilter(ResSkill);
        ResSkillMgt.PrepareRemoveMultipleResSkills(ResSkill);

        ResSkillMgt.RemoveResSkill(Rec);

        if ResSkill.Count = 1 then
            ResSkillMgt.DropGlobals();
    end;

    trigger OnInit()
    begin
        NoVisible := true;
        SkillCodeVisible := true;
        TypeVisible := true;
    end;

    trigger OnOpenPage()
    var
        i: Integer;
    begin
        SkillCodeVisible := Rec.GetFilter("Skill Code") = '';
        NoVisible := Rec.GetFilter("No.") = '';

        TypeVisible := true;

        for i := 0 to 3 do begin
            Rec.FilterGroup(i);
            if Rec.GetFilter(Type) <> '' then
                TypeVisible := false
        end;

        Rec.FilterGroup(0);
    end;

    var
        ResSkill: Record "Resource Skill";
        ResSkillMgt: Codeunit "Resource Skill Mgt.";
        TypeVisible: Boolean;
        SkillCodeVisible: Boolean;
        NoVisible: Boolean;
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

page 99000799 "Standard Tasks"
{
    ApplicationArea = Manufacturing;
    Caption = 'Standard Tasks';
    PageType = List;
    SourceTable = "Standard Task";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the standard task code.';
                }
                field(Control4; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the description of the standard task.';
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
            group("&Std. Task")
            {
                Caption = '&Std. Task';
                Image = Tools;
                action(Tools)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Tools';
                    Image = Tools;
                    RunObject = Page "Standard Task Tools";
                    RunPageLink = "Standard Task Code" = field(Code);
                    ToolTip = 'View or edit information about tools that apply to operations that represent the standard task.';
                }
                action(Personnel)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Personnel';
                    Image = User;
                    RunObject = Page "Standard Task Personnel";
                    RunPageLink = "Standard Task Code" = field(Code);
                    ToolTip = 'View or edit information about personnel that applies to operations that represent the standard task.';
                }
                action(Description)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Description';
                    Image = Description;
                    RunObject = Page "Standard Task Descript. Sheet";
                    RunPageLink = "Standard Task Code" = field(Code);
                    ToolTip = 'View or edit a special description that applies to operations that represent the standard task. ';
                }
                action("Quality Measures")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Quality Measures';
                    Image = TaskQualityMeasure;
                    RunObject = Page "Standard Task Qlty Measures";
                    RunPageLink = "Standard Task Code" = field(Code);
                    ToolTip = 'View or edit information about quality measures that apply to operations that represent the standard task.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Task)
            {
                Caption = 'Task';

                actionref(Tools_Promoted; Tools)
                {
                }
                actionref(Personnel_Promoted; Personnel)
                {
                }
                actionref(Description_Promoted; Description)
                {
                }
                actionref("Quality Measures_Promoted"; "Quality Measures")
                {
                }
            }
        }
    }

#if not CLEAN27
    [Scope('OnPrem')]
    procedure GetSelectionFilter(): Code[80]
    var
        StandardTask: Record "Standard Task";
        FirstStdTask: Code[30];
        LastStdTask: Code[30];
        SelectionFilter: Code[250];
        StdTaskCount: Integer;
        More: Boolean;
    begin
        CurrPage.SetSelectionFilter(StandardTask);
        StdTaskCount := StandardTask.Count();
        if StdTaskCount > 0 then begin
            StandardTask.Find('-');
            while StdTaskCount > 0 do begin
                StdTaskCount := StdTaskCount - 1;
                StandardTask.MarkedOnly(false);
                FirstStdTask := StandardTask.Code;
                LastStdTask := FirstStdTask;
                More := (StdTaskCount > 0);
                while More do
                    if StandardTask.Next() = 0 then
                        More := false
                    else
                        if not StandardTask.Mark() then
                            More := false
                        else begin
                            LastStdTask := StandardTask.Code;
                            StdTaskCount := StdTaskCount - 1;
                            if StdTaskCount = 0 then
                                More := false;
                        end;
                if SelectionFilter <> '' then
                    SelectionFilter := SelectionFilter + '|';
                if FirstStdTask = LastStdTask then
                    SelectionFilter := SelectionFilter + FirstStdTask
                else
                    SelectionFilter := SelectionFilter + FirstStdTask + '..' + LastStdTask;
                if StdTaskCount > 0 then begin
                    StandardTask.MarkedOnly(true);
                    StandardTask.Next();
                end;
            end;
        end;
        exit(SelectionFilter);
    end;
#endif
}


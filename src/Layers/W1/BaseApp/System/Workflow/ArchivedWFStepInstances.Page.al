namespace System.Automation;

page 1530 "Archived WF Step Instances"
{
    ApplicationArea = Suite;
    Caption = 'Archived Workflow Step Instances';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    Permissions = TableData "Workflow Step Instance Archive" = d;
    SourceTable = "Workflow Step Instance Archive";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(ID; Rec.ID)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, for the archived workflow step instance, the workflow step ID of the workflow step instance.';
                }
                field("Workflow Code"; Rec."Workflow Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, for the archived workflow step instance, the workflow that the workflow step instance belongs to.';
                }
                field("Workflow Step ID"; Rec."Workflow Step ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, for the archived workflow step instance, the workflow step ID of the workflow step instance.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, for the archived workflow step instance, the workflow step instance.';
                }
                field("Entry Point"; Rec."Entry Point")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the workflow step that starts the workflow. The first workflow step is always of type Entry Point.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, for the archived workflow step instance, the status of the workflow step instance. Active means that the step instance in ongoing. Completed means that the workflow step instance is done. Ignored means that the workflow step instance was skipped in favor of another path.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, for the archived workflow step instance, if the workflow step instance is an event, a response, or a sub-workflow.';
                }
                field("Function Name"; Rec."Function Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, for the archived workflow step instance, the name of the function that is used by the workflow step instance.';
                }
                field(Argument; Rec.Argument)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, for the archived workflow step instance, the values of the parameters that are required by the workflow step instance.';
                }
                field("Created Date-Time"; Rec."Created Date-Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, for the archived workflow step instance, the date and time when the workflow step instance was created.';
                }
                field("Created By User ID"; Rec."Created By User ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, for the workflow step instance, the user who created the workflow step instance.';
                }
                field("Last Modified Date-Time"; Rec."Last Modified Date-Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, for the archived workflow step instance, the date and time when a user last participated in the workflow step instance.';
                }
                field("Last Modified By User ID"; Rec."Last Modified By User ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, for the archived workflow step instance, the date and time when a user last participated in the workflow step instance.';
                }
                field("Previous Workflow Step ID"; Rec."Previous Workflow Step ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, for the archived workflow step instance, the step that you want to precede the step that you are specifying on the line. You use this field to specify branching of steps when one of multiple possible events does not occur and you want the following step to specify another possible event as a branch of the previous step. In this case, both steps have the same value in the Previous Workflow Step ID field.';
                }
                field("Next Workflow Step ID"; Rec."Next Workflow Step ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, for the archived workflow step instance, another workflow step than the next one in the sequence that you want to start, for example, because the event on the workflow step failed to meet a condition.';
                }
                field("Record ID"; RecordIDText)
                {
                    ApplicationArea = Suite;
                    Caption = 'Record ID';
                    ToolTip = 'Specifies, for the archived workflow step instance, the ID of the record that the workflow instance acts on.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(DeleteArchive)
            {
                ApplicationArea = Suite;
                Caption = 'Delete Archive';
                Image = Delete;
                ToolTip = 'Delete archived workflow step instances. None of the instances are used in active workflows.';

                trigger OnAction()
                begin
                    if Confirm(DeleteArchiveQst) then
                        Rec.DeleteAll(true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(DeleteArchive_Promoted; DeleteArchive)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        RecordIDText := Format(Rec."Record ID", 0, 1);
    end;

    var
        DeleteArchiveQst: Label 'Are you sure you want to delete all the archived workflow step instances?';
        RecordIDText: Text;

    procedure SetWorkflowCode(WorkflowCode: Code[20])
    begin
        Rec.SetRange("Workflow Code", WorkflowCode);
    end;
}


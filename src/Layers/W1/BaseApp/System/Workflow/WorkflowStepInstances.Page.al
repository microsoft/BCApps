namespace System.Automation;

page 1504 "Workflow Step Instances"
{
    ApplicationArea = Suite;
    Caption = 'Workflow Step Instances';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Workflow Step Instance";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(ID; Rec.ID)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the workflow step instance.';
                }
                field("Workflow Code"; Rec."Workflow Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the workflow that the workflow step instance belongs to.';
                }
                field("Workflow Step ID"; Rec."Workflow Step ID")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ID of workflow step in the workflow that the workflow step instance belongs to.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the workflow step instance.';
                }
                field("Entry Point"; Rec."Entry Point")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the workflow step that starts the workflow. The first workflow step is always of type Entry Point.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the status of the workflow step instance. Active means that the step instance in ongoing. Completed means that the workflow step instance is done. Ignored means that the workflow step instance was skipped in favor of another path.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the workflow step instance is an event, a response, or a sub-workflow.';
                }
                field("Function Name"; Rec."Function Name")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the function that is used by the workflow step instance.';
                }
                field(Argument; Rec.Argument)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the values of the parameters that are required by the workflow step instance.';
                }
                field("Created Date-Time"; Rec."Created Date-Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date and time when the workflow step instance was created.';
                }
                field("Created By User ID"; Rec."Created By User ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user who created the workflow step instance.';
                }
                field("Last Modified Date-Time"; Rec."Last Modified Date-Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date and time when a user last participated in the workflow step instance.';
                }
                field("Last Modified By User ID"; Rec."Last Modified By User ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user who last participated in the workflow step instance.';
                }
                field("Previous Workflow Step ID"; Rec."Previous Workflow Step ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the step that you want to precede the step that you are specifying on the line. You use this field to specify branching of steps when one of multiple possible events does not occur and you want the following step to specify another possible event as a branch of the previous step. In this case, both steps have the same value in the Previous Workflow Step ID field.';
                }
                field("Next Workflow Step ID"; Rec."Next Workflow Step ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies another workflow step than the next one in the sequence that you want to start, for example, because the event on the workflow step failed to meet a condition.';
                }
                field("Record ID"; RecordIDText)
                {
                    ApplicationArea = Suite;
                    Caption = 'Record ID';
                    ToolTip = 'Specifies the ID of the record that the workflow instance acts on.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        RecordIDText := Format(Rec."Record ID", 0, 1);
    end;

    trigger OnOpenPage()
    begin
        if Workflow.Code <> '' then
            Rec.SetRange("Workflow Code", Workflow.Code);
    end;

    var
        Workflow: Record Workflow;
        RecordIDText: Text;

    procedure SetWorkflow(WorkflowTemplate: Record Workflow)
    begin
        Workflow := WorkflowTemplate;
    end;
}


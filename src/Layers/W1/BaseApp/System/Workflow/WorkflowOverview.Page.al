namespace System.Automation;

page 1529 "Workflow Overview"
{
    Caption = 'Workflow Overview';
    DataCaptionFields = "Workflow Code", "Record ID";
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "Workflow Step Instance";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                IndentationColumn = Indent;
                IndentationControls = Description;
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    Caption = 'Workflow Step';
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the workflow step instance.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Suite;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the status of the workflow step instance. Active means that the step instance in ongoing. Completed means that the workflow step instance is done. Ignored means that the workflow step instance was skipped in favor of another path.';
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
                field(WorkflowRecord; WorkflowRecord)
                {
                    ApplicationArea = Suite;
                    Caption = 'Record';
                    ToolTip = 'Specifies the record from which the window is opened from the Workflow FactBox.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdatePageControls();
    end;

    var
        StyleTxt: Text;
        WorkflowRecord: Text;
        Indent: Integer;

    local procedure GetDescription(): Text
    var
        WorkflowEvent: Record "Workflow Event";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        case Rec.Type of
            Rec.Type::"Event":
                if WorkflowEvent.Get(Rec."Function Name") then
                    exit(WorkflowEvent.Description);
            Rec.Type::Response:
                if WorkflowStepArgument.Get(Rec.Argument) then
                    exit(WorkflowResponseHandling.GetDescription(WorkflowStepArgument));
        end;
        exit('');
    end;

    local procedure GetStyle(): Text
    begin
        case Rec.Status of
            Rec.Status::Completed:
                exit('Favorable');
            Rec.Status::Active:
                exit('');
            else
                exit('Subordinate');
        end;
    end;

    local procedure UpdatePageControls()
    begin
        if Rec.Type = Rec.Type::"Event" then
            Indent := 0
        else
            Indent := 2;

        Rec.Description := CopyStr(GetDescription(), 1, MaxStrLen(Rec.Description));
        StyleTxt := GetStyle();
        WorkflowRecord := Format(Rec."Record ID", 0, 1);
    end;
}


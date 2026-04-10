namespace System.Automation;

page 1528 "Workflow Status FactBox"
{
    Caption = 'Workflows';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    ShowFilter = false;
    SourceTable = "Workflow Step Instance";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(WorkflowDescription; WorkflowDescription)
                {
                    ApplicationArea = Suite;
                    Caption = 'Active Workflows';
                    ToolTip = 'Specifies the number of enabled workflows that are currently running.';

                    trigger OnDrillDown()
                    var
                        TempWorkflowStepInstance: Record "Workflow Step Instance" temporary;
                    begin
                        TempWorkflowStepInstance.BuildTempWorkflowTree(Rec.ID);
                        PAGE.RunModal(PAGE::"Workflow Overview", TempWorkflowStepInstance);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if Workflow.Get(Rec."Workflow Code") then
            WorkflowDescription := Workflow.Description;
    end;

    trigger OnOpenPage()
    begin
        IsVisible := true;
    end;

    var
        Workflow: Record Workflow;
        WorkflowDescription: Text;
        IsVisible: Boolean;

    procedure SetFilterOnWorkflowRecord(WorkflowStepRecID: RecordID): Boolean
    var
        WorkflowStepInstance: Record "Workflow Step Instance";
        InstanceID: Guid;
    begin
        Rec.DeleteAll();
        WorkflowStepInstance.SetRange("Record ID", WorkflowStepRecID);
        if not WorkflowStepInstance.FindSet() then
            exit(false);

        repeat
            if WorkflowStepInstance.ID <> InstanceID then begin
                Rec := WorkflowStepInstance;
                Rec.Insert();
            end;
            InstanceID := WorkflowStepInstance.ID;
        until WorkflowStepInstance.Next() = 0;
        exit(not Rec.IsEmpty);
    end;
}


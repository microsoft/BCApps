namespace System.Automation;

report 1510 "Copy Workflow"
{
    Caption = 'Copy Workflow';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CopyWorkflow();
    end;

    var
        FromWorkflow: Record Workflow;
        ToWorkflow: Record Workflow;
        FromWorkflowCode: Code[20];
        StepsExistQst: Label 'The existing workflow steps will be deleted.\\Do you want to continue?';
        SelfCopyErr: Label 'You cannot copy a workflow into itself.';

    local procedure CopyWorkflow()
    begin
        FromWorkflow.Get(FromWorkflowCode);

        if FromWorkflow.Code = ToWorkflow.Code then
            Error(SelfCopyErr);

        if ToWorkflow.Description = '' then
            ToWorkflow.Description := FromWorkflow.Description;
        if ToWorkflow.Category = '' then
            ToWorkflow.Category := FromWorkflow.Category;
        ToWorkflow.Modify();

        CopyWorkflowSteps();
    end;

    local procedure CopyWorkflowSteps()
    var
        FromWorkflowStep: Record "Workflow Step";
        FromWorkflowStepArgument: Record "Workflow Step Argument";
        ToWorkflowStep: Record "Workflow Step";
    begin
        ToWorkflowStep.SetRange("Workflow Code", ToWorkflow.Code);
        if not ToWorkflowStep.IsEmpty() then
            if not Confirm(StepsExistQst) then
                CurrReport.Quit();

        ToWorkflowStep.DeleteAll(true);

        FromWorkflowStep.SetRange("Workflow Code", FromWorkflow.Code);
        if FromWorkflowStep.FindSet() then
            repeat
                ToWorkflowStep.Copy(FromWorkflowStep);
                ToWorkflowStep."Workflow Code" := ToWorkflow.Code;
                if FromWorkflowStepArgument.Get(FromWorkflowStep.Argument) then
                    ToWorkflowStep.Argument := FromWorkflowStepArgument.Clone();
                ToWorkflowStep.Insert(true);

                CopyWorkflowRules(FromWorkflowStep, ToWorkflowStep);
            until FromWorkflowStep.Next() = 0;
    end;

    local procedure CopyWorkflowRules(FromWorkflowStep: Record "Workflow Step"; ToWorkflowStep: Record "Workflow Step")
    var
        FromWorkflowRule: Record "Workflow Rule";
        ToWorkflowRule: Record "Workflow Rule";
    begin
        if FromWorkflowStep.FindWorkflowRules(FromWorkflowRule) then
            repeat
                ToWorkflowRule.Copy(FromWorkflowRule);
                ToWorkflowRule.ID := 0;
                ToWorkflowRule."Workflow Code" := ToWorkflowStep."Workflow Code";
                ToWorkflowRule."Workflow Step ID" := ToWorkflowStep.ID;
                ToWorkflowRule.Insert(true);
            until FromWorkflowRule.Next() = 0;
    end;

    procedure InitCopyWorkflow(NewFromWorkflow: Record Workflow; NewToWorkflow: Record Workflow)
    begin
        FromWorkflowCode := NewFromWorkflow.Code;
        ToWorkflow := NewToWorkflow;
    end;
}


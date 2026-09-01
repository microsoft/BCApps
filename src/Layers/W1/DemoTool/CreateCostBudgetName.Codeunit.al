codeunit 119091 "Create Cost Budget Name"
{

    trigger OnRun()
    var
        CostBudgetName: Record "Cost Budget Name";
    begin
        CostBudgetName.Init();
        CostBudgetName.Name := XDEFAULT;
        CostBudgetName.Description := XSTANDARD;

        if not CostBudgetName.Insert() then
            CostBudgetName.Modify();
    end;

    var
        XDEFAULT: Label 'DEFAULT', Comment = 'Default is a name of Cost Budget.';
        XSTANDARD: Label 'STANDARD', Comment = 'Standard is a description of Cost Budget Name.';
}


codeunit 101732 "Create Item Budget Name"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(0, XBUDGET + ' ' + CopyStr(Format(
              DemoDataSetup."Starting Year" + 1), 3, 2), XCustomerBudget, false, XCUSTOMERGROUP, XSALESPERSON, '');
        InsertData(1, XDEFAULT, XDefaultbudget, false, '', '', '');
        InsertData(0, XDEFAULT, XDefaultbudget, false, XCUSTOMERGROUP, '', '');
    end;

    var
        ItemBudgetName: Record "Item Budget Name";
        XBUDGET: Label 'BUDGET';
        XDEFAULT: Label 'DEFAULT';
        XCUSTOMERGROUP: Label 'CUSTOMERGROUP';
        XSALESPERSON: Label 'SALESPERSON';
        XCustomerBudget: Label 'Customer Budget';
        XDefaultbudget: Label 'Default budget';
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertData(AnalysisArea: Option Sales,Purchase,Inventory; Name: Code[10]; Description: Text[80]; Blocked: Boolean; BudgetDim1Code: Code[20]; BudgetDim2Code: Code[20]; BudgetDim3Code: Code[20])
    begin
        ItemBudgetName.Init();
        ItemBudgetName.Validate("Analysis Area", AnalysisArea);
        ItemBudgetName.Validate(Name, Name);
        ItemBudgetName.Insert(true);
        ItemBudgetName.Validate(Description, Description);
        ItemBudgetName.Validate(Blocked, Blocked);
        ItemBudgetName.Validate("Budget Dimension 1 Code", BudgetDim1Code);
        ItemBudgetName.Validate("Budget Dimension 2 Code", BudgetDim2Code);
        ItemBudgetName.Validate("Budget Dimension 3 Code", BudgetDim3Code);
        ItemBudgetName.Modify(true);
    end;
}


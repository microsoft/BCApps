codeunit 101095 "Create G/L Budget Name"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(Format(DemoDataSetup."Starting Year"), '', '', '', '');
        InsertData(Format(DemoDataSetup."Starting Year" + 1), XAREA, XSALESCAMPAIGN, '', '');
    end;

    var
        "G/L Budget Name": Record "G/L Budget Name";
        Xbudget: Label 'budget';
        XAREA: Label 'AREA';
        XSALESCAMPAIGN: Label 'SALESCAMPAIGN';
        Text000: Label '%1 %2';
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertData(Name: Code[10]; BudgetDim1Code: Code[20]; BudgetDim2Code: Code[20]; BudgetDim3Code: Code[20]; BudgetDim4Code: Code[20])
    begin
        "G/L Budget Name".Init();
        "G/L Budget Name".Validate(Name, Name);
        "G/L Budget Name".Validate(Description, StrSubstNo(Text000, Name, Xbudget));
        "G/L Budget Name".Insert();
        "G/L Budget Name".Validate("Budget Dimension 1 Code", BudgetDim1Code);
        "G/L Budget Name".Validate("Budget Dimension 2 Code", BudgetDim2Code);
        "G/L Budget Name".Validate("Budget Dimension 3 Code", BudgetDim3Code);
        "G/L Budget Name".Validate("Budget Dimension 4 Code", BudgetDim4Code);
        "G/L Budget Name".Modify();
    end;
}


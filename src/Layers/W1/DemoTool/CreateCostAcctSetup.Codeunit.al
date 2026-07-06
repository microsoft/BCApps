codeunit 119081 "Create Cost Acct. Setup"
{

    trigger OnRun()
    var
        CostAccountingSetup: Record "Cost Accounting Setup";
        GLSetup: Record "General Ledger Setup";
        DemoDataSetup: Record "Demo Data Setup";
    begin
        DemoDataSetup.Get();
        CostAccountingSetup.Init();
        CostAccountingSetup."Align G/L Account" := CostAccountingSetup."Align G/L Account"::"No Alignment";
        CostAccountingSetup."Starting Date for G/L Transfer" := DMY2Date(1, 1, DemoDataSetup."Starting Year");

        CostAccountingSetup."Last Allocation ID" := XA0;
        CostAccountingSetup."Last Allocation Doc. No." := XALLOC0;
        if GLSetup.Get() then begin
            CostAccountingSetup."Cost Center Dimension" := GLSetup."Global Dimension 1 Code";
            CostAccountingSetup."Cost Object Dimension" := GLSetup."Global Dimension 2 Code";
        end;

        if not CostAccountingSetup.Insert(true) then
            CostAccountingSetup.Modify();
    end;

    var
        XA0: Label 'A0';
        XALLOC0: Label 'ALLOC0', Comment = 'ALLOC stands for Allocation. The string must end with a 0. The purpose is to create a document numbers as in ALLOC72';
}


codeunit 119092 "Create Cost Budget Lines"
{

    trigger OnRun()
    var
        CostType: Record "Cost Type";
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
    begin
        DemoDataSetup.Get();
        CostType.Reset();
        CostType.SetRange(Type, CostType.Type::"Cost Type");

        if CostType.Find('-') then
            repeat
                if CostCenter.Find('-') then
                    repeat
                        CostType.SetFilter("Cost Center Filter", CostCenter.Code);
                        CostType.SetRange("Cost Object Filter");
                        CostType.SetRange("Date Filter", DMY2Date(1, 1, DemoDataSetup."Starting Year"),
                          DMY2Date(31, 12, DemoDataSetup."Starting Year"));
                        CostType.CalcFields("Net Change");
                        if CostType."Net Change" <> 0 then
                            InsertData(CostType."No.", CostCenter.Code, '', CostType."Net Change");
                    until CostCenter.Next() = 0;

                if CostObject.Find('-') then
                    repeat
                        CostType.SetRange("Cost Center Filter");
                        CostType.SetFilter("Cost Object Filter", CostObject.Code);
                        CostType.SetRange("Date Filter", DMY2Date(1, 1, DemoDataSetup."Starting Year"),
                          DMY2Date(31, 12, DemoDataSetup."Starting Year"));
                        CostType.CalcFields("Net Change");
                        if CostType."Net Change" <> 0 then
                            InsertData(CostType."No.", '', CostObject.Code, CostType."Net Change");
                    until CostObject.Next() = 0;
            until CostType.Next() = 0;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XDEFAULT: Label 'DEFAULT', Comment = 'Default is a name of Cost Budget.';
        CostBudgetRegNo: Integer;

    procedure InsertData(CostTypeNo: Code[20]; CostCenterCode: Code[20]; CostObjectCode: Code[20]; CostBudgetEntryAmount: Decimal)
    var
        CostBudgetEntry: Record "Cost Budget Entry";
        CostAccMgt: Codeunit "Cost Account Mgt";
        i: Integer;
        LastCostBudgetLineNo: Integer;
        BudDatum: Date;
        DateFormula: DateFormula;
    begin
        Evaluate(DateFormula, '<1M>');
        BudDatum := DMY2Date(1, 1, DemoDataSetup."Starting Year");

        CostBudgetEntry.Reset();
        if CostBudgetEntry.FindLast() then
            LastCostBudgetLineNo := CostBudgetEntry."Entry No."
        else
            LastCostBudgetLineNo := 1;

        for i := 1 to 24 do begin  // 24 Month from starting Date
            CostBudgetEntry.Init();
            LastCostBudgetLineNo := LastCostBudgetLineNo + 1;
            CostBudgetEntry."Entry No." := LastCostBudGetLineNo;
            CostBudgetEntry."Budget Name" := XDEFAULT;
            CostBudgetEntry."Cost Type No." := CostTypeNo;
            CostBudgetEntry.Date := BudDatum;
            CostBudgetEntry."Cost Center Code" := CostCenterCode;
            CostBudgetEntry."Cost Object Code" := CostObjectCode;

            // Base per Month
            CostBudgetEntry.Amount := CostBudgetEntryAmount / 12;

            // Starting July, + 20%
            if Date2DMY(BudDatum, 2) > 6 then
                CostBudgetEntry.Amount := CostBudgetEntry.Amount * 1.2;

            // Starting Dez, + 30%
            if Date2DMY(BudDatum, 2) = 12 then
                CostBudgetEntry.Amount := CostBudgetEntry.Amount * 1.3;

            // 2008: + 10%
            if Date2DMY(BudDatum, 3) = DemoDataSetup."Starting Year" + 1 then
                CostBudgetEntry.Amount := CostBudgetEntry.Amount * 1.1;

            // 2009: + 20%
            if Date2DMY(BudDatum, 3) = DemoDataSetup."Starting Year" + 2 then
                CostBudgetEntry.Amount := CostBudgetEntry.Amount * 1.2;

            if CostBudgetEntry.Amount < 10000 then
                CostBudgetEntry.Amount := Round(CostBudgetEntry.Amount, 100)
            else
                CostBudgetEntry.Amount := Round(CostBudgetEntry.Amount, 1000);

            if not CostBudgetEntry.Insert() then
                CostBudgetEntry.Modify();

            BudDatum := CalcDate(DateFormula, BudDatum);  // for next month

            if CostBudgetRegNo = 0 then
                CostBudgetRegNo :=
                  CostAccMgt.InsertCostBudgetRegister(
                    CostBudgetEntry."Entry No.", CostBudgetEntry."Budget Name", CostBudgetEntry.Amount)
            else
                CostAccMgt.UpdateCostBudgetRegister(
                  CostBudgetRegNo, CostBudgetEntry."Entry No.", CostBudgetEntry.Amount);
        end;
    end;
}


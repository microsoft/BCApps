codeunit 101734 "Create Item Budget Entry"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(11, 0, XBUDGET + ' ' + CopyStr(Format(
              DemoDataSetup."Starting Year" + 1), 3, 2), 19030101D, 0, 0, 6000, XLARGE);
        InsertData(12, 0, XBUDGET + ' ' + CopyStr(Format(
              DemoDataSetup."Starting Year" + 1), 3, 2), 19030101D, 0, 0, 20000, XMEDIUM);
        InsertData(13, 0, XBUDGET + ' ' + CopyStr(Format(
              DemoDataSetup."Starting Year" + 1), 3, 2), 19030101D, 0, 0, 13000, XSMALL);
    end;

    var
        ItemBudgetEntry: Record "Item Budget Entry";
        XBUDGET: Label 'BUDGET';
        XLARGE: Label 'LARGE';
        XMEDIUM: Label 'MEDIUM';
        XSMALL: Label 'SMALL';
        DemoDataSetup: Record "Demo Data Setup";
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure InsertData(EntryNo: Integer; AnalysisArea: Option Sales,Purchase,Inventory; BudgetName: Code[10]; Date: Date; Qty: Decimal; CostAmount: Decimal; SalesAmount: Decimal; BudgetDim1Code: Code[20])
    begin
        ItemBudgetEntry.Init();
        ItemBudgetEntry.Validate("Entry No.", EntryNo);
        ItemBudgetEntry.Validate("Analysis Area", AnalysisArea);
        ItemBudgetEntry.Validate("Budget Name", BudgetName);
        ItemBudgetEntry.Validate(Date, MakeAdjustments.AdjustDate(Date));
        ItemBudgetEntry.Validate(Quantity, Qty);
        ItemBudgetEntry.Validate("Cost Amount", CostAmount);
        ItemBudgetEntry.Validate("Sales Amount", SalesAmount);
        ItemBudgetEntry.Validate("Budget Dimension 1 Code", BudgetDim1Code);
        ItemBudgetEntry.Insert(true);
    end;
}


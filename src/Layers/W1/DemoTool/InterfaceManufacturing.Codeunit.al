codeunit 119000 "Interface Manufacturing"
{

    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        ModifySalesAndRecSetup: Codeunit "Modify Sales & Rec. Setup";
        MakeAdjustments: Codeunit "Make Adjustments";
        Window: Dialog;
        Steps: Integer;
        MaxSteps: Integer;

    procedure Create()
    begin
        DemoDataSetup.Get();
        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, 'Manufacturing');

        Steps := 0;
        MaxSteps := 36;

        RunCodeunit(CODEUNIT::"Create Manufacturing Setup");
        RunCodeunit(CODEUNIT::"Create Manufacturing Item");
        RunCodeunit(CODEUNIT::"Setup Manufacturing on Item");
        RunCodeunit(CODEUNIT::"Create Bins");
        RunCodeunit(CODEUNIT::"Create Item Variants");
        RunCodeunit(CODEUNIT::"Create Unit of Measures");
        RunCodeunit(CODEUNIT::"Create Item Unit of Measures");
        RunCodeunit(CODEUNIT::"Create Availability Setup");
        RunCodeunit(CODEUNIT::"Create Work Shifts");
        RunCodeunit(CODEUNIT::"Create Shop Calendar");
        RunCodeunit(CODEUNIT::"Create Shop Cal. Working Day");
        RunCodeunit(CODEUNIT::"Create Shop Cal. Holiday");
        RunCodeunit(CODEUNIT::"Create Work Center Group");
        RunCodeunit(CODEUNIT::"Create Cap. Unit of Measure");
        RunCodeunit(CODEUNIT::"Create Work Center");
        RunCodeunit(CODEUNIT::"Create Machine Center");
        RunCodeunit(CODEUNIT::"Create Constrained Capacity");
        RunCodeunit(CODEUNIT::"Create Order Promising Setup");
        RunCodeunit(CODEUNIT::"Create Stop Codes");
        RunCodeunit(CODEUNIT::"Create Scrap Codes");
        RunCodeunit(CODEUNIT::"Create Routing Link");
        RunCodeunit(CODEUNIT::"Create Cal. Absent. Entries");
        RunCodeunit(CODEUNIT::"Create Calendars");
        RunCodeunit(CODEUNIT::"Create Prod. BOM Headers");
        RunCodeunit(CODEUNIT::"Create Prod. BOM Lines");
        RunCodeunit(CODEUNIT::"Update Prod. BOM Headers");
        RunCodeunit(CODEUNIT::"Create Routing Headers");
        RunCodeunit(CODEUNIT::"Create Routing Lines");
        RunCodeunit(CODEUNIT::"Update Routing Headers");
        RunCodeunit(CODEUNIT::"Calculate Setup");
        RunCodeunit(CODEUNIT::"Modify Sales & Rec. Setup");
        if not DemoDataSetup."Skip sequence of actions" then begin
            RunCodeunit(CODEUNIT::"Create Sales Header Manf");
            RunCodeunit(CODEUNIT::"Create Sales Line Manf");
            RunCodeunit(CODEUNIT::"Create Item Journal Line manf.");
            if DemoDataSetup.Distribution then
                RunCodeunit(CODEUNIT::"Create Dist. Prod. Order");
        end;
        Window.Close();
    end;

    procedure Post(PostingDate: Date)
    begin
        DemoDataSetup.Get();
        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, 'Manufacturing');
        Steps := 0;
        MaxSteps := 1;

        if PostingDate = MakeAdjustments.AdjustDate(19021231D) then
            RunCodeunit(CODEUNIT::"Post Revaluation");
        Window.Close();
    end;

    procedure "After Posting"()
    begin
        DemoDataSetup.Get();
        Window.Open(DemoDataSetup."Progress Window Design");
        Window.Update(3, 'Manufacturing');

        Steps := 0;
        MaxSteps := 11;
        RunCodeunit(CODEUNIT::"Create Prod. Forecast Name");
        ModifySalesAndRecSetup.Finalize();

        WorkDate := MakeAdjustments.AdjustDate(19030131D);
        RunCodeunit(CODEUNIT::"Modify Manufacturing Setup");
        RunCodeunit(CODEUNIT::"Create Mfg. Order");
        RunCodeunit(CODEUNIT::"Change Status Mfg. Order");
        RunCodeunit(CODEUNIT::"Post Consumption Mfg. Order");
        RunCodeunit(CODEUNIT::"Post Output Mfg. Order");
        RunCodeunit(CODEUNIT::"Finish Released Mfg. Order");
        RunCodeunit(CODEUNIT::"Make Mfg. Order from Sales");
        RunCodeunit(CODEUNIT::"Create Prod. Forecast Entry");
        RunCodeunit(CODEUNIT::"Finalize Manufacturing Setup");
        Window.Close();
    end;

    procedure RunCodeunit(CodeunitID: Integer)
    var
        AllObj: Record AllObj;
    begin
        AllObj.Get(AllObj."Object Type"::Codeunit, CodeunitID);
        Window.Update(1, StrSubstNo('%1 %2', AllObj."Object ID", AllObj."Object Name"));
        Steps := Steps + 1;
        Window.Update(2, Round(Steps / MaxSteps * 10000, 1));
        CODEUNIT.Run(CodeunitID);
    end;
}


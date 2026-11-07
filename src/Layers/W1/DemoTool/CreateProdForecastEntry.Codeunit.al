codeunit 119064 "Create Prod. Forecast Entry"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('1000', 19030701D, '', 300);
        InsertData('1000', 19030801D, '', 300);
        InsertData('1000', 19030901D, '', 200);
        InsertData('1000', 19031001D, '', 150);
        InsertData('1000', 19031101D, '', 100);
        InsertData('1000', 19031201D, '', 100);
        InsertData('1001', 19030701D, '', 30);
        InsertData('1001', 19030801D, '', 30);
        InsertData('1001', 19030901D, '', 20);
        InsertData('1001', 19031001D, '', 20);
        InsertData('1001', 19031101D, '', 10);
        InsertData('1001', 19031201D, '', 10);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        ProductionForecastEntry: Record "Production Forecast Entry";
        "Entry No.": Integer;
        CA: Codeunit "Make Adjustments";

    procedure InsertData(ItemNo: Code[20]; Date: Date; LocationCode: Code[10]; "ForecastQuantity(Base)": Decimal)
    begin
        Date := CA.AdjustDate(Date);
        ProductionForecastEntry.Init();
        "Entry No." := "Entry No." + 1;
        ProductionForecastEntry.Validate("Entry No.", "Entry No.");
        ProductionForecastEntry.Validate("Production Forecast Name", Format(DemoDataSetup."Starting Year" + 1));
        ProductionForecastEntry.Validate("Item No.", ItemNo);
        ProductionForecastEntry.Validate("Forecast Date", Date);
        ProductionForecastEntry.Validate("Location Code", LocationCode);
        ProductionForecastEntry.Validate("Forecast Quantity (Base)", "ForecastQuantity(Base)");
        ProductionForecastEntry.Insert();
    end;
}


codeunit 101293 "Create Reminder Level"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(DemoDataSetup.DomesticCode(), 1, '<2D>', 43, '<7D>');
        InsertData(DemoDataSetup.DomesticCode(), 2, '<2D>', 86, '<7D>');
        InsertData(DemoDataSetup.DomesticCode(), 3, '<2D>', 128, '<7D>');
        InsertData(DemoDataSetup.ForeignCode(), 1, '<3D>', 0, '<7D>');
        InsertData(DemoDataSetup.ForeignCode(), 2, '<3D>', 0, '<7D>');
        InsertData(DemoDataSetup.ForeignCode(), 3, '<3D>', 0, '<7D>');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertData("Code": Code[10]; Level: Integer; DateCalc: Code[10]; AdditionalFee: Decimal; "Due Date Calculation": Code[20])
    var
        ReminderLevel: Record "Reminder Level";
    begin
        ReminderLevel.Init();
        ReminderLevel.Validate("Reminder Terms Code", Code);
        ReminderLevel."No." := Level;
        Evaluate(ReminderLevel."Grace Period", DateCalc);
        ReminderLevel.Validate("Grace Period");
        ReminderLevel.Validate(
          "Additional Fee (LCY)",
          Round(AdditionalFee * DemoDataSetup."Local Currency Factor", DemoDataSetup."Local Precision Factor"));
        Evaluate(ReminderLevel."Due Date Calculation", "Due Date Calculation");
        ReminderLevel.Validate("Due Date Calculation");
        ReminderLevel.Insert();
    end;
}


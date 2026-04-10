codeunit 132459 "Job Queue Confirm Guiallowed"
{

    trigger OnRun()
    begin
        if GuiAllowed then
            if Confirm(TestConfirmQst) then;
    end;

    var
        TestConfirmQst: Label 'Test Confirm';
}


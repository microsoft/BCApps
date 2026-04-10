codeunit 132457 "Job Queue Confirm"
{

    trigger OnRun()
    begin
        if Confirm(TestConfirmQst) then;
    end;

    var
        TestConfirmQst: Label 'Test Confirm';
}


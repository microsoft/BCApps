codeunit 132441 TestCodeunitRunError
{

    trigger OnRun()
    begin
        Error(TestCodeunitRunErr);
    end;

    var
        TestCodeunitRunErr: Label 'TestCodeunitRunError', Locked = true;
}


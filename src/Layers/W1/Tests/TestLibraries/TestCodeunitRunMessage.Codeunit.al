codeunit 132440 TestCodeunitRunMessage
{

    trigger OnRun()
    begin
        Message(TestCodeunitRunMsg);
    end;

    var
        TestCodeunitRunMsg: Label 'TestCodeunitRunMessage', Locked = true;
}


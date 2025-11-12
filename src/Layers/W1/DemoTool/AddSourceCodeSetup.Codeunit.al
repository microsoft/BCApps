codeunit 117555 "Add Source Code Setup"
{

    trigger OnRun()
    begin
        SourceCodeSetup.Get();
        SourceCodeSetup."Service Management" := XSERVICE;
        SourceCodeSetup.Modify();
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        XSERVICE: Label 'SERVICE';
}


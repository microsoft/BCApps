codeunit 119200 "Create Named Forward Links"
{

    trigger OnRun()
    var
        NamedForwardLink: Record "Named Forward Link";
    begin
        NamedForwardLink.Load();
    end;
}


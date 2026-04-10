codeunit 163402 "Create Bank Orders"
{

    trigger OnRun()
    begin
        // temporary fix for bug 12020
        exit;
    end;

    var
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";

    procedure Post(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlPostLine.RunWithCheck(GenJnlLine);
        GenJnlLine.Delete();
    end;
}


codeunit 160900 "Create Reference File Setup"
{

    trigger OnRun()
    begin
        InsertData(XNBL);
    end;

    var
        XNBL: Label 'NBL';

    procedure InsertData("No.": Code[20])
    var
#if not CLEAN30
        "Reference File Setup": Record "Reference File Setup";
        BankingDemo: Codeunit "Banking Payments Demo FI";
#endif
        ReplacementSetup: Record Microsoft.Bank.Setup."Reference File Setup FI";
    begin
#if not CLEAN30
        if not BankingDemo.IsEnabled() then begin
#pragma warning disable AL0432
            "Reference File Setup".Init();
            "Reference File Setup".Validate("No.", "No.");
            "Reference File Setup".Insert();
#pragma warning restore AL0432
            exit;
        end;
#endif
        ReplacementSetup.Init();
        ReplacementSetup.Validate("No.", "No.");
        ReplacementSetup.Insert();
    end;
}

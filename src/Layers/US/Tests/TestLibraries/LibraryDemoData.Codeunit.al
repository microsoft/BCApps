codeunit 130300 "Library - Demo Data"
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure VerifyGenPostingSetupAccounts()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.FindSet();
        repeat
            if GeneralPostingSetup."Gen. Bus. Posting Group" = '' then begin
                GeneralPostingSetup.TestField("Sales Account", '');
                GeneralPostingSetup.TestField("Purch. Account", '');
            end else begin
                GeneralPostingSetup.TestField("Sales Account");
                GeneralPostingSetup.TestField("Purch. Account");
            end;
            GeneralPostingSetup.TestField("COGS Account");
            GeneralPostingSetup.TestField("Inventory Adjmt. Account");
            GeneralPostingSetup.TestField("Direct Cost Applied Account");
        until GeneralPostingSetup.Next() = 0;
    end;
}


codeunit 101410 "Create IC G/L Account"
{
    // Create IC G/L Account


    trigger OnRun()
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.Find('-') then
            repeat
                InsertData(GLAccount."No.", GLAccount.Name, GLAccount."Account Type", GLAccount."Income/Balance", false, GLAccount."No.");
            until GLAccount.Next() = 0;
    end;

    procedure InsertData("No.": Code[20]; Name: Text[100]; "Account Type": Enum "G/L Account Type"; "Income/Balance": Enum "G/L Account Report Type"; Blocked: Boolean; "Map-to G/L Acc. No": Code[30])
    var
        ICGLAccount: Record "IC G/L Account";
    begin
        ICGLAccount.Init();
        ICGLAccount."No." := "No.";
        ICGLAccount.Name := Name;
        ICGLAccount."Account Type" := "Account Type";
        ICGLAccount."Income/Balance" := "Income/Balance";
        ICGLAccount.Blocked := Blocked;
        ICGLAccount.Validate("Map-to G/L Acc. No.", "Map-to G/L Acc. No");
        ICGLAccount.Insert();
    end;
}


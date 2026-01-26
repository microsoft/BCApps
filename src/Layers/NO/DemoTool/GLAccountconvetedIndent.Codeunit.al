codeunit 160800 "G/L Account conveted -Indent"
{

    trigger OnRun()
    begin
        /*IF NOT
           CONFIRM(
             Text000 +
             Text001 +
             Text002 +
             Text003,TRUE)
        THEN
          EXIT;
        */
        Indent();

    end;

    var
        Text004: Label 'Indenting the Chart of Accounts #1##########';
        Text005: Label 'End-Total %1 is missing a matching Begin-Total.';
        ArrayExceededErr: Label 'You can only indent %1 levels for accounts of the type Begin-Total.', Comment = '%1 = A number bigger than 1';
        GLAcc: Record "G/L Account";
        Window: Dialog;
        AccNo: array[10] of Code[20];
        i: Integer;
        icglacc: Record "IC G/L Account";

    procedure Indent()
    begin
        Window.Open(Text004);

        GLAcc.SetCurrentKey("No.");
        if GLAcc.Find('-') then
            repeat
                Window.Update(1, GLAcc."No.");

                if GLAcc."Account Type" = GLAcc."Account Type"::"End-Total" then begin
                    if i < 1 then
                        Error(
                          Text005,
                          GLAcc."No.");
                    GLAcc.Totaling := AccNo[i] + '..' + GLAcc."No.";
                    i := i - 1;
                end;

                GLAcc.Indentation := i;
                GLAcc.Modify();

                if GLAcc."Account Type" = GLAcc."Account Type"::"Begin-Total" then begin
                    i := i + 1;
                    if i > ArrayLen(AccNo) then
                        Error(ArrayExceededErr, ArrayLen(AccNo));
                    AccNo[i] := GLAcc."No.";
                end;
                GLAcc.CalcFields("Balance at Date", "Net Change", "Budgeted Amount", Balance, "Budget at Date", "Debit Amount",
                           "Credit Amount", "Budgeted Debit Amount", "Budgeted Credit Amount",
                           "Additional-Currency Net Change");
                GLAcc.Modify();
            until GLAcc.Next() = 0;

        Window.Close();
    end;

    procedure IndentIC()
    begin
        Window.Open(Text004);
        if icglacc.Find('-') then
            repeat
                Window.Update(1, icglacc."No.");

                if icglacc."Account Type" = icglacc."Account Type"::"End-Total" then begin
                    if i < 1 then
                        Error(
                          Text005,
                          icglacc."No.");
                    i := i - 1;
                end;

                icglacc.Indentation := i;
                icglacc.Modify();

                if icglacc."Account Type" = icglacc."Account Type"::"Begin-Total" then begin
                    i := i + 1;
                    if i > ArrayLen(AccNo) then
                        Error(ArrayExceededErr, ArrayLen(AccNo));
                    AccNo[i] := icglacc."No.";
                end;
            until icglacc.Next() = 0;

        Window.Close();
    end;
}


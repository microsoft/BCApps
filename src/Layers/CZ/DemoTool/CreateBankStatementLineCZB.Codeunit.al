codeunit 163509 "Create Bank Statement Line CZB"
{

    trigger OnRun()
    begin
        InsertData('BVYP0001', 'Látky a.s.', '100011/0100', '11190046', -53288.40);
        InsertData('BVYP0001', 'Elektro s.r.o.', '158468239/0300', '3458911', -3025.0);
        InsertData('BVYP0001', 'Výběr z ATM', '', '', -20000.0);
        InsertData('BVYP0001', 'ABC nábytek s.r.o.', '', '1001', 61886.0);
        InsertData('BVYP0001', 'Elektro s.r.o. - záloha', '158468239/0300', '1214448', -11011.0);
        InsertData('BVYP0002', 'Vklad hotovosti na účet', '', '', 50000.0);
        InsertData('BVYP0002', 'ABC nábytek s.r.o.', '1000100001/0100', '1003', 14925.0);
    end;

    var
        BankStatementLine: Record "Bank Statement Line CZB";
        LineNo: Integer;
        PreviousDocumentNo: Code[20];

    procedure InsertData(BankStatementNo: Code[20]; Description: Text[100]; AccountNo: Text[30]; VariableSymbol: Code[10]; Amount: Decimal)
    begin
        BankStatementLine.Init();
        BankStatementLine."Bank Statement No." := BankStatementNo;

        if PreviousDocumentNo <> BankStatementNo then begin
            LineNo := 0;
            PreviousDocumentNo := BankStatementNo;
        end;

        LineNo := LineNo + 10000;

        BankStatementLine.Validate("Line No.", LineNo);
        BankStatementLine.Validate(Description, Description);
        BankStatementLine.Validate("Account No.", AccountNo);
        BankStatementLine."Variable Symbol" := VariableSymbol;
        BankStatementLine.Validate(Amount, Amount);
        BankStatementLine.Insert();
    end;
}


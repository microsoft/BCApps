codeunit 160101 "Create Domiciliation"
{

    trigger OnRun()
    var
        TempDec: Decimal;
    begin
        DomNo := 1450034468;
        TempDec := 100.0;
        if Cust.Find('-') then
            repeat
                Cust."Domiciliation No." := Format(DomNo * TempDec + DomNo mod 97, 12, 1);
                Cust.Modify();
                DomNo := DomNo + 11
            until Cust.Next() = 0
    end;

    var
        Cust: Record Customer;
        DomNo: Integer;
}


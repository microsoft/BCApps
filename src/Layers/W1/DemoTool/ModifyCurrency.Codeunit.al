codeunit 101904 "Modify Currency"
{

    trigger OnRun()
    begin
        Currency.Reset();
        if Currency.Find('-') then
            repeat
                Currency.Validate("Unrealized Gains Acc.", CA.Convert('999310'));
                Currency.Validate("Unrealized Losses Acc.", CA.Convert('999320'));
                Currency.Validate("Realized Gains Acc.", CA.Convert('999330'));
                Currency.Validate("Realized Losses Acc.", CA.Convert('999340'));
                Currency.Modify();
            until Currency.Next() = 0;
    end;

    var
        Currency: Record Currency;
        CA: Codeunit "Make Adjustments";
}


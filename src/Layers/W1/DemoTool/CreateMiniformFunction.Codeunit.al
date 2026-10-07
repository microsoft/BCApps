codeunit 118857 "Create Miniform Function"
{

    trigger OnRun()
    begin
        InsertData('LOGIN', 'ESC');

        InsertData('PHYSICALINV', 'ESC');
        InsertData('PHYSICALINV', 'FIRST');
        InsertData('PHYSICALINV', 'LAST');
        InsertData('PHYSICALINV', 'LNDN');
        InsertData('PHYSICALINV', 'LNUP');

        InsertData('WHSEACTLINES', 'ESC');
        InsertData('WHSEACTLINES', 'FIRST');
        InsertData('WHSEACTLINES', 'LAST');
        InsertData('WHSEACTLINES', 'REGISTER');
        InsertData('WHSEACTLINES', 'RESET');
        InsertData('WHSEACTLINES', 'LNDN');
        InsertData('WHSEACTLINES', 'LNUP');

        InsertData('WHSEBATCHLIST', 'ESC');
        InsertData('WHSEBATCHLIST', 'FIRST');
        InsertData('WHSEBATCHLIST', 'LAST');
        InsertData('WHSEBATCHLIST', 'PGDN');
        InsertData('WHSEBATCHLIST', 'PGUP');
        InsertData('WHSEBATCHLIST', 'LNDN');
        InsertData('WHSEBATCHLIST', 'LNUP');

        InsertData('WHSEMOVELIST', 'ESC');
        InsertData('WHSEMOVELIST', 'FIRST');
        InsertData('WHSEMOVELIST', 'LAST');
        InsertData('WHSEMOVELIST', 'PGDN');
        InsertData('WHSEMOVELIST', 'PGUP');
        InsertData('WHSEMOVELIST', 'LNDN');
        InsertData('WHSEMOVELIST', 'LNUP');

        InsertData('WHSEPICKLIST', 'ESC');
        InsertData('WHSEPICKLIST', 'FIRST');
        InsertData('WHSEPICKLIST', 'LAST');
        InsertData('WHSEPICKLIST', 'PGDN');
        InsertData('WHSEPICKLIST', 'PGUP');
        InsertData('WHSEPICKLIST', 'LNDN');
        InsertData('WHSEPICKLIST', 'LNUP');

        InsertData('WHSEPUTLIST', 'ESC');
        InsertData('WHSEPUTLIST', 'FIRST');
        InsertData('WHSEPUTLIST', 'LAST');
        InsertData('WHSEPUTLIST', 'PGDN');
        InsertData('WHSEPUTLIST', 'PGUP');
        InsertData('WHSEPUTLIST', 'LNDN');
        InsertData('WHSEPUTLIST', 'LNUP');
    end;

    var
        MiniformFunction: Record "Miniform Function";

    procedure InsertData(MiniformCode: Code[20]; FunctionCode: Code[20])
    begin
        MiniformFunction.Init();
        MiniformFunction.Validate("Miniform Code", MiniformCode);
        MiniformFunction.Validate("Function Code", FunctionCode);
        MiniformFunction.Insert(true);
    end;
}


codeunit 101301 "Create Finance Charge Text"
{

    trigger OnRun()
    begin
        LineNo := 10000;
        InsertDomestic();
        InsertForeign();
    end;

    var
        LineNo: Integer;
        OldCode: Text[30];
        OldPosition: Option Starting,Ending;
        X1point5DOM: Label '1.5 DOM.';
        XPleasepaythetotalofPERCENT7: Label 'Please pay the total of %7.';
        X2POINT0FOR: Label '2.0 FOR.';

    procedure InsertDomestic()
    begin
        InsertData(X1point5DOM, 1, XPleasepaythetotalofPERCENT7);
    end;

    procedure InsertForeign()
    begin
        InsertData(X2POINT0FOR, 1, XPleasepaythetotalofPERCENT7);
    end;

    procedure InsertData("Code": Code[10]; Position: Option; Description: Text[100])
    var
        FinChrgText: Record "Finance Charge Text";
    begin
        FinChrgText.Init();
        if (OldCode = Code) and (OldPosition = Position) then
            LineNo := LineNo + 10000;
        FinChrgText.Validate("Fin. Charge Terms Code", Code);
        FinChrgText.Validate(Position, Position);
        FinChrgText.Validate(Text, Description);
        FinChrgText.Insert();
        OldCode := Code;
        OldPosition := Position;
    end;
}


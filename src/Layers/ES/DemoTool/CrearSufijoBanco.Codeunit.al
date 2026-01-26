codeunit 161009 "Crear Sufijo Banco"
{

    trigger OnRun()
    begin
        InsertData(XWWBEUR, '344', XBillGroupforDiscount);
        InsertData(XWWBEUR, '355', XBillGroupforCollection);

        InsertData(XNBL, '221', XBillGroupforDiscount);
        InsertData(XNBL, '222', XBillGroupforCollection);
    end;

    var
        Sufix: Record Suffix;
        XBillGroupforCollection: Label 'Biil Group for Collection';
        XBillGroupforDiscount: Label 'Biil Group for Discount';
        XNBL: Label 'NBL';
        XWWBEUR: Label 'WWB-EUR';

    procedure InsertData(BankAccCode: Code[20]; SufixCode: Code[3]; Description: Text[30])
    begin
        Sufix.Init();
        Sufix.Validate("Bank Acc. Code", BankAccCode);
        Sufix.Validate(Suffix, SufixCode);
        Sufix.Validate(Description, Description);
        Sufix.Insert();
    end;
}


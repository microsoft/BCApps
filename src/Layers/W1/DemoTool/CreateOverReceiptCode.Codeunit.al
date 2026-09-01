codeunit 122005 "Create Over-Receipt Code"
{
    trigger OnRun()
    begin
        InsertData(XOR10, XOR10Desc, 10, true);
    end;

    var
        XOR10: Label 'OVERRCPT10', Comment = 'Max Length = 10';
        XOR10Desc: Label 'Over receipt up to 10% of quantity';

    local procedure InsertData(OverReceiptCodeTxt: Code[20]; Description: Text[100]; OverReceiptTolerance: Decimal; Default: Boolean)
    var
        OverReceiptCode: Record "Over-Receipt Code";
    begin
        OverReceiptCode.Init();
        OverReceiptCode.Validate(Code, OverReceiptCodeTxt);
        OverReceiptCode.Validate(Description, Description);
        OverReceiptCode.Validate("Over-Receipt Tolerance %", OverReceiptTolerance);
        OverReceiptCode.Validate(Default, Default);
        OverReceiptCode.Insert();
    end;
}
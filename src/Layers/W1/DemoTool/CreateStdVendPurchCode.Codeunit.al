codeunit 101048 "Create Std. Vend. Purch. Code"
{

    trigger OnRun()
    begin
        InsertData('10000', XPAPER);
        InsertData('10000', XPOSTAGE);
        InsertData('20000', XCLEANING);
        InsertData('30000', XPAINT);
    end;

    var
        StdVendPurchCode: Record "Standard Vendor Purchase Code";
        XPAPER: Label 'PAPER';
        XPOSTAGE: Label 'POSTAGE';
        XCLEANING: Label 'CLEANING';
        XPAINT: Label 'PAINT';

    procedure InsertData(VendNo: Code[20]; "Code": Code[10])
    begin
        StdVendPurchCode.Init();
        StdVendPurchCode.Validate("Vendor No.", VendNo);
        StdVendPurchCode.Validate(Code, Code);
        StdVendPurchCode.Insert();
    end;
}


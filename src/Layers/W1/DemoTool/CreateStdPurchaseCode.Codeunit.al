codeunit 101046 "Create Std. Purchase Code"
{

    trigger OnRun()
    begin
        InsertData(XCLEANING, XMlycleaningexpensesforbldgs);
        InsertData(XPAINT, XStandardpaintorder);
        InsertData(XPAPER, XPrintingpaper);
        InsertData(XPOSTAGE, XPostageexpenses);
    end;

    var
        StdPurchCode: Record "Standard Purchase Code";
        XCLEANING: Label 'CLEANING';
        XMlycleaningexpensesforbldgs: Label 'Monthly cleaning expenses for buildings';
        XPAINT: Label 'PAINT';
        XStandardpaintorder: Label 'Standard paint order';
        XPAPER: Label 'PAPER';
        XPrintingpaper: Label 'Printing paper';
        XPOSTAGE: Label 'POSTAGE';
        XPostageexpenses: Label 'Postage expenses';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    begin
        StdPurchCode.Init();
        StdPurchCode.Validate(Code, Code);
        StdPurchCode.Validate(Description, Description);
        StdPurchCode.Insert();
    end;
}


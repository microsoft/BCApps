codeunit 161347 "Create VAT Register"
{

    trigger OnRun()
    begin
        InsertData(XxEUPURCH, VATRegister.Type::Purchase, XEUPurchaseRegister, (0D));
        InsertData(XxEXTPURCH, VATRegister.Type::Purchase, XExtraEUPurchaseRegister, (0D));
        InsertData(XxNATPURCH, VATRegister.Type::Purchase, XNationalPurchaseRegister, (0D));
        InsertData(XxEUSALES, VATRegister.Type::Sale, XEUSalesRegister, (0D));
        InsertData(XxEXTSALES, VATRegister.Type::Sale, XExtraEUSalesRegister, (0D));
        InsertData(XxNATSALES, VATRegister.Type::Sale, XNationalSalesRegister, (0D));
    end;

    var
        XxEUPURCH: Label 'EUPURCH';
        XEUPurchaseRegister: Label 'EU Purchase Register';
        XxEXTPURCH: Label 'EXTPURCH';
        XExtraEUPurchaseRegister: Label 'ExtraEU Purchase Register';
        XxNATPURCH: Label 'NATPURCH';
        XNationalPurchaseRegister: Label 'National Purchase Register';
        XxEUSALES: Label 'EUSALES';
        XEUSalesRegister: Label 'EU Sales Register';
        XxEXTSALES: Label 'EXTSALES';
        XExtraEUSalesRegister: Label 'ExtraEU Sales Register';
        XxNATSALES: Label 'NATSALES';
        XNationalSalesRegister: Label 'National Sales Register';
        VATRegister: Record "VAT Register";

    procedure InsertData("Code": Code[10]; Type: Option; Description: Text[30]; LastPrintingDate: Date)
    begin
        VATRegister.Init();
        VATRegister.Validate(Code, Code);
        VATRegister.Validate(Type, Type);
        VATRegister.Validate(Description, Description);
        VATRegister.Validate("Last Printing Date", LastPrintingDate);
        VATRegister.Insert();
    end;
}


codeunit 101323 "Create VAT Bus. Posting Gr."
{

    trigger OnRun()
    begin
        InsertData(XPURCHASE, XPurchasewithVAT);
        InsertData(XSALES, XSaleswithVAT);
        InsertData(XPURCHNOVAT, XPurchasewithoutVAT);
        InsertData(XADVPAY, XAdvancesReceived);
        InsertData(XPAYROLL, XPayrollDesc);
        InsertData(XTEST, XTEST);
    end;

    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        XPURCHASE: Label 'PURCHASE';
        XPurchasewithVAT: Label 'Purchase(with VAT)';
        XSALES: Label 'SALES';
        XSaleswithVAT: Label 'Sales (with VAT)';
        XADVPAY: Label 'ADVPAY';
        XAdvancesReceived: Label 'Advance Received';
        XPURCHNOVAT: Label 'PURCHNOVAT';
        XPurchasewithoutVAT: Label 'Purchase (without VAT)';
        XPAYROLL: Label 'PAYROLL';
        XPayrollDesc: Label 'Payroll';
        XTEST: Label '_TEST';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    begin
        VATBusinessPostingGroup.Init();
        VATBusinessPostingGroup.Validate(Code, Code);
        VATBusinessPostingGroup.Validate(Description, Description);
        VATBusinessPostingGroup.Insert();
    end;

    procedure InsertMiniAppData()
    begin
        InsertData(XPURCHASE, XPurchasewithVAT);
        InsertData(XSALES, XSaleswithVAT);
        InsertData(XTEST, XTEST);
    end;

    procedure GetDomesticVATGroup(): Code[10]
    begin
        exit(XSALES);
    end;

    procedure GetPurchaseCode(): Code[10]
    begin
        exit(XPURCHASE);
    end;
}


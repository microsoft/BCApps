codeunit 101325 "Create VAT Posting Setup"
{

    trigger OnRun()
    begin
        InsertDataRU(XADVPAY, XADVPAY20, XADVPAY20, 20, 0, 1, '62-1021', '68-4220', 1, '62-1021', '', '', '', '', '', false, 'S');
        InsertDataRU(XPURCHASE, XADVPAY20, XADVPAY20, 20, 2, 1, '', '', 0, '', '76-8000', '68-4230', '', '', '', false, 'S');
        InsertDataRU(XPURCHNOVAT, XMATNOVAT, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHNOVAT, XMAT20, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHNOVAT, XINTASNOVAT, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHNOVAT, XINTASS20, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHNOVAT, XFANOVAT, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHNOVAT, XFACONOVAT, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHNOVAT, XFAECON20, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHNOVAT, XFA10, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHNOVAT, XFA20, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHNOVAT, XFUTEXP20ST, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHNOVAT, XFUTEXP20LT, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHNOVAT, XCUSTOMS, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHNOVAT, XCUSTOMS20, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHNOVAT, XGOODSNOVAT, XGOODSNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', true, 'E');
        InsertDataRU(XPURCHNOVAT, XGOODS20, XGOODS20, 0, 0, 0, '', '', 0, '', '', '', '', '', '', true, 'E');
        InsertDataRU(XPURCHNOVAT, XSERVNOVAT, XSERVNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', true, 'E');
        InsertDataRU(XPURCHNOVAT, XSERV20, XSERV20, 0, 0, 0, '', '', 0, '', '', '', '', '', '', true, 'E');
        InsertDataRU(XPURCHASE, XMAT10, XVAT10, 10, 0, 0, '', '', 2, '19-3100', '68-4300', '', '', '', '91-2430', false, 'S');
        InsertDataRU(XPURCHASE, XMAT20, XVAT20, 20, 0, 0, '', '', 2, '19-3100', '68-4300', '', '', '', '91-2430', false, 'S');
        InsertDataRU(XPURCHASE, XMATNOVAT, XMATNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', true, 'E');
        InsertDataRU(XPURCHASE, XTAXAGENT20, XVAT20, 20, 0, 3, '', '', 0, '', '68-4310', '19-4000', '', '', '91-2430', false, 'E');
        InsertDataRU(XPURCHASE, XINTASS20, XVAT20, 20, 0, 1, '', '', 0, '', '68-4300', '19-2000', XVATSET, XDEFAULT, '91-2430', false, 'S');
        InsertDataRU(XPURCHASE, XFACONT20, XVAT20, 20, 0, 1, '', '', 0, '', '68-4300', '19-1100', XVATSET, XDEFAULT, '91-2430', false, 'S');
        InsertDataRU(XPURCHASE, XFAECON20, XVAT20, 20, 0, 1, '', '', 0, '', '68-4300', '19-1200', XVATSET, XDEFAULT, '91-2430', false, 'S');
        InsertDataRU(XPURCHASE, XFA10, XVAT10, 10, 0, 1, '', '', 0, '', '68-4300', '19-1000', XVATSET, XDEFAULT, '91-2430', false, 'S');
        InsertDataRU(XPURCHASE, XFA20, XVAT20, 20, 0, 1, '', '', 0, '', '68-4300', '19-1000', XVATSET, XDEFAULT, '91-2430', false, 'S');
        InsertDataRU(XPURCHASE, XFUTEXP20ST, XVAT20, 20, 0, 0, '', '', 0, '19-3200', '68-4300', '', '', '', '91-2430', false, 'S');
        InsertDataRU(XPURCHASE, XFUTEXP20LT, XVAT20, 20, 0, 0, '', '', 0, '19-3200', '68-4300', '', '', '', '91-2430', false, 'S');
        InsertDataRU(XPURCHASE, XCUSTOMS, XCUSTOMS, 0, 0, 0, '', '', 0, '', '', '', '', '', '', true, 'E');
        InsertDataRU(XPURCHASE, XCUSTOMS10, XVAT10, 10, 2, 0, '', '', 1, '19-5000', '68-4420', '', '', '', '91-2430', false, 'S');
        InsertDataRU(XPURCHASE, XCUSTOMS20, XCUSTOMS20, 20, 2, 0, '', '', 1, '19-5000', '68-4420', '', '', '', '91-2430', false, 'S');
        InsertDataRU(XPURCHASE, XGOODSNOVAT, XGOODSNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', true, 'E');
        InsertDataRU(XPURCHASE, XGOODS10, XVAT10, 10, 0, 0, '', '', 2, '19-3300', '68-4300', '', '', '', '91-2430', false, 'S');
        InsertDataRU(XPURCHASE, XGOODS20, XVAT20, 20, 0, 0, '', '', 2, '19-3300', '68-4300', '', '', '', '91-2430', false, 'S');
        InsertDataRU(XPURCHASE, XGOODS0, XGOODS0, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHASE, XSERV0, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHASE, XSERVNOVAT, XSERVNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', true, 'E');
        InsertDataRU(XPURCHASE, XSERV20, XVAT20, 20, 0, 0, '', '', 2, '19-3200', '68-4300', '', '', '', '91-2430', false, 'S');
        InsertDataRU(XPURCHNOVAT, XNOREFUND, XNOREFUND, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHASE, XNOREFUND, XNOREFUND, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHASE, XNOREFUND10, XNOREFUND10, 10, 0, 0, '', '', 0, '', '91-2430', '', '', '', '91-2430', false, 'S');
        InsertDataRU(XPURCHASE, XNOREFUND20, XNOREFUND20, 20, 0, 0, '', '', 0, '', '91-2430', '', '', '', '91-2430', false, 'S');
        InsertDataRU(XSALES, XFINISH0, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XSALES, XFINISH10, XVAT10, 10, 0, 0, '68-4200', '', 1, '90-3320', '', '', '', '', '', false, 'S');
        InsertDataRU(XSALES, XFINISH20, XVAT20, 20, 0, 0, '68-4200', '', 1, '90-3310', '', '', '', '', '', false, 'S');
        InsertDataRU(XSALES, XMATNOVAT, XMATNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', true, 'E');
        InsertDataRU(XSALES, XMAT10, XVAT10, 10, 0, 0, '68-4400', '', 1, '91-2420', '', '', '', '', '', false, 'S');
        InsertDataRU(XSALES, XMAT20, XVAT20, 20, 0, 0, '68-4400', '', 1, '91-2420', '', '', '', '', '', false, 'S');
        InsertDataRU(XSALES, XTAXAGENT20, XVAT20, 20, 0, 0, '68-4430', '', 0, '', '', '', '', '', '', false, 'S');
        InsertDataRU(XSALES, XINTASNOVAT, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XSALES, XINTASS20, XVAT20, 20, 0, 0, '68-4200', '', 1, '91-2420', '', '', '', '', '', false, 'S');
        InsertDataRU(XSALES, XFANOVAT, XFANOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', true, 'E');
        InsertDataRU(XSALES, XFA10, XVAT10, 10, 0, 0, '68-4400', '', 1, '91-2410', '', '', '', '', '', false, 'S');
        InsertDataRU(XSALES, XFA20, XVAT20, 20, 0, 0, '68-4400', '', 1, '91-2410', '', '', '', '', '', false, 'S');
        InsertDataRU(XPURCHASE, XFANOVAT, XFANOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', true, 'E');
        InsertDataRU(XSALES, XCUSTOMS, XVAT20, 20, 0, 0, '68-4200', '', 1, '90-3110', '', '', '', '', '', false, 'S');
        InsertDataRU(XSALES, XCUSTOMS20, XVAT20, 20, 0, 0, '68-4200', '', 1, '90-3110', '', '', '', '', '', false, 'S');
        InsertDataRU(XSALES, XGOODSNOVAT, XGOODSNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', true, 'E');
        InsertDataRU(XSALES, XGOODS0, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XSALES, XGOODS10, XVAT10, 10, 0, 0, '68-4200', '', 1, '90-3120', '', '', '', '', '', false, 'S');
        InsertDataRU(XSALES, XGOODS20, XVAT20, 20, 0, 0, '68-4200', '', 1, '90-3110', '', '', '', '', '', false, 'S');
        InsertDataRU(XSALES, XSERVNOVAT, XSERVNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', true, '');
        InsertDataRU(XSALES, XSERV0, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XSALES, XSERV20, XVAT20, 20, 0, 0, '68-4200', '', 1, '90-3210', '', '', '', '', '', false, 'S');
        InsertDataRU(XSALES, XRENT20, XVAT20, 20, 0, 0, '68-4400', '', 1, '91-2490', '', '', '', '', '', false, 'S');

        // test automation
        InsertDataRU(XPURCHNOVAT, XTEST, XTEST + '0', 0, 0, 0, '', '', 0, '', '', '', '', '', '', true, 'E');
        InsertDataRU(XPURCHASE, XTEST, XTEST + '1', 20, 0, 0, '', '', 2, '19-3300', '68-4300', '', '', '', '91-2430', false, 'S');
        InsertDataRU(XSALES, XTEST, XTEST + '2', 20, 0, 0, '68-4200', '', 1, '90-3110', '', '', '', '', '', false, 'S');
        InsertDataRU(XTEST, XSERVNOVAT, XTEST + '3', 0, 0, 0, '', '', 0, '', '', '', '', '', '', true, 'E');
        InsertDataRU(XTEST, XSERV20, XTEST + '6', 20, 0, 0, '68-4200', '', 1, '90-3210', '68-4300', '', '', '', '', false, 'S');
        InsertDataRU(XTEST, XTEST, XTEST + '4', 20, 0, 0, '68-4200', '', 1, '90-3110', '68-4300', '', '', '', '', false, 'S');
        InsertDataRU(XTEST, '', XTEST + '5', 20, 0, 0, '68-4200', '', 1, '90-3110', '68-4300', '', '', '', '', false, 'S');
        InsertDataRU(XTEST, XFINISH20, XTEST + '7', 20, 0, 0, '68-4200', '', 1, '90-3310', '68-4300', '', '', '', '', false, 'S');
        InsertDataRU(XTEST, XGOODS20, XTEST + '8', 20, 0, 0, '68-4200', '', 1, '90-3110', '68-4300', '', '', '', '', false, 'S');
        InsertDataRU(XTEST, XGOODS10, XTEST + '81', 10, 0, 0, '68-4200', '', 1, '90-3110', '68-4300', '', '', '', '', false, 'S');
        InsertDataRU(XTEST, XMAT20, XTEST + '8', 20, 0, 0, '68-4200', '', 1, '19-3100', '68-4300', '', '', '', '', false, 'S');
        InsertDataRU(XTEST, XCUSTOMS, XTEST + '9', 0, 0, 0, '', '', 0, '', '', '', '', '', '', true, 'E');
        InsertDataRU(XTEST, XFA20, XTEST + '10', 20, 0, 0, '68-4400', '', 1, '91-2410', '68-4300', '', '', '', '', false, 'S');
        InsertDataRU(XTEST, XFA10, XTEST + '101', 10, 0, 0, '68-4400', '', 1, '91-2410', '68-4300', '', '', '', '', false, 'S');
        InsertDataRU(XTEST, XTAXAGENT20, XTEST + 'T', 20, 0, 3, '68-4200', '', 0, '', '68-4310', '19-4000', '', '', '91-2430', false, 'S');
    end;

    var
        CA: Codeunit "Make Adjustments";
        XNOVAT: Label 'NO VAT';
        XVAT10: Label 'VAT10';
        XPURCHASE: Label 'PURCHASE';
        XSALES: Label 'SALES';
        XADVPAY: Label 'ADVPAY';
        XADVPAY20: Label 'ADVPAY20', Comment = 'ADVPAY20';
        XFINISH0: Label 'FINISH0';
        XFINISH10: Label 'FINISH10';
        XFINISH20: Label 'FINISH20', Comment = 'FINISH20';
        XMATNOVAT: Label 'MATNOVAT';
        XMAT10: Label 'MAT10';
        XMAT20: Label 'MAT20', Comment = 'MAT20';
        XTAXAGENT20: Label 'TAXAGENT20', Comment = 'TAXAGENT20';
        XINTASNOVAT: Label 'INTASNOVAT';
        XINTASS20: Label 'INTASS20', Comment = 'INTASS20';
        XFANOVAT: Label 'FANOVAT';
        XFACONOVAT: Label 'FACONOVAT';
        XFACONT20: Label 'FACONT20', Comment = 'FACONT20';
        XFAECON20: Label 'FAECON20', Comment = 'FAECON20';
        XFA10: Label 'FA10';
        XFA20: Label 'FA20', Comment = 'FA20';
        XFUTEXP20ST: Label 'FUTEXP20ST', Comment = 'FUTEXP20ST';
        XFUTEXP20LT: Label 'FUTEXP20LT', Comment = 'FUTEXP20LT';
        XCUSTOMS: Label 'CUSTOMS';
        XCUSTOMS10: Label 'CUSTOMS10';
        XCUSTOMS20: Label 'CUSTOMS20', Comment = 'CUSTOMS20';
        XSERVNOVAT: Label 'SERVNOVAT';
        XSERV0: Label 'SERV0';
        XSERV20: Label 'SERV20', Comment = 'SERV20';
        XGOODSNOVAT: Label 'GOODSNOVAT';
        XGOODS0: Label 'GOODS0';
        XGOODS10: Label 'GOODS10';
        XGOODS20: Label 'GOODS20', Comment = 'GOODS20';
        XRENT20: Label 'RENT20', Comment = 'RENT20';
        XVAT20: Label 'VAT20', Comment = 'VAT20';
        XVATSET: Label 'VATSET';
        XDEFAULT: Label 'DEFAULT';
        XPURCHNOVAT: Label 'PURCHNOVAT';
        XNOREFUND10: Label 'NOREFUND10';
        XNOREFUND20: Label 'NOREFUND20', Comment = 'NOREFUND20';
        XNOREFUND: Label 'NOREFUND';
        XTEST: Label '_TEST';

    procedure InsertMiniAppData()
    begin
        InsertDataRU(XPURCHASE, XFA20, XVAT20, 20, 0, 1, '', '', 0, '', '68-4300', '19-1000', XVATSET, XDEFAULT, '91-2430', false, 'S');
        InsertDataRU(XPURCHASE, XGOODS20, XVAT20, 20, 0, 0, '', '', 2, '19-3300', '68-4300', '', '', '', '91-2430', false, 'S');
        InsertDataRU(XPURCHASE, XGOODS0, XGOODS0, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHASE, XSERV0, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XPURCHASE, XSERV20, XVAT20, 20, 0, 0, '', '', 2, '19-3200', '68-4300', '', '', '', '91-2430', false, 'S');
        InsertDataRU(XSALES, XFA20, XVAT20, 20, 0, 0, '68-4400', '', 1, '91-2410', '', '', '', '', '', false, 'S');
        InsertDataRU(XSALES, XGOODS20, XVAT20, 20, 0, 0, '68-4200', '', 1, '90-3110', '', '', '', '', '', false, 'S');
        InsertDataRU(XSALES, XGOODS0, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XSALES, XSERV0, XNOVAT, 0, 0, 0, '', '', 0, '', '', '', '', '', '', false, 'E');
        InsertDataRU(XSALES, XSERV20, XVAT20, 20, 0, 0, '68-4200', '', 1, '90-3210', '', '', '', '', '', false, 'S');

        // test automation
        InsertDataRU(XPURCHASE, XTEST, XTEST + '1', 20, 0, 0, '', '', 2, '19-3300', '68-4300', '', '', '', '91-2430', false, 'S');
        InsertDataRU(XSALES, XTEST, XTEST + '2', 20, 0, 0, '68-4200', '', 1, '90-3110', '', '', '', '', '', false, 'S');
        InsertDataRU(XTEST, XSERV20, XTEST + '6', 20, 0, 0, '68-4200', '', 1, '90-3210', '68-4300', '', '', '', '', false, 'S');
        InsertDataRU(XTEST, XTEST, XTEST + '4', 20, 0, 0, '68-4200', '', 1, '90-3110', '68-4300', '', '', '', '', false, 'S');
        InsertDataRU(XTEST, '', XTEST + '5', 20, 0, 0, '68-4200', '', 1, '90-3110', '68-4300', '', '', '', '', false, 'S');
        InsertDataRU(XTEST, XGOODS20, XTEST + '8', 20, 0, 0, '68-4200', '', 1, '90-3110', '68-4300', '', '', '', '', false, 'S');
        InsertDataRU(XTEST, XGOODS0, XTEST + '81', 10, 0, 0, '68-4200', '', 1, '90-3110', '68-4300', '', '', '', '', false, 'S');
        InsertDataRU(XTEST, XFA20, XTEST + '10', 20, 0, 0, '68-4400', '', 1, '91-2410', '68-4300', '', '', '', '', false, 'S');
    end;

    procedure InsertDataRU(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; VATIdentifier: Code[10]; VATPerc: Decimal; VATCalculationType: Option; UnrealizedVATType: Option; SalesVATAccount: Code[20]; SalesVATUnrealAccount: Code[20]; TransVATType: Option; TransVATAccount: Code[20]; PurchaseVATAccount: Code[20]; PurchVATUnrealAccount: Code[20]; VATSettlementTemplate: Code[10]; VATSettlementBatch: Code[10]; VATWriteoffAccount: Code[20]; VATExempt: Boolean; TaxCategory: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        VATPostingSetup.Validate("VAT Identifier", VATProdPostingGroup);
        VATPostingSetup.Validate("VAT %", VATPerc);
        VATPostingSetup."VAT Calculation Type" := "Tax Calculation Type".FromInteger(VATCalculationType);
        VATPostingSetup."Unrealized VAT Type" := UnrealizedVATType;
        VATPostingSetup.Validate("Sales VAT Account", CA.Convert(SalesVATAccount));
        VATPostingSetup.Validate("Sales VAT Unreal. Account", CA.Convert(SalesVATUnrealAccount));
        VATPostingSetup."Trans. VAT Type" := TransVATType;
        VATPostingSetup.Validate("Trans. VAT Account", CA.Convert(TransVATAccount));
        VATPostingSetup.Validate("Purchase VAT Account", CA.Convert(PurchaseVATAccount));
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", CA.Convert(PurchVATUnrealAccount));
        VATPostingSetup."VAT Settlement Template" := VATSettlementTemplate;
        VATPostingSetup."VAT Settlement Batch" := VATSettlementBatch;
        VATPostingSetup.Validate("Write-Off VAT Account", CA.Convert(VATWriteoffAccount));
        VATPostingSetup.Validate("VAT Exempt", VATExempt);
        VATPostingSetup.Validate("Tax Category", TaxCategory);
        if VATSettlementTemplate <> '' then
            VATPostingSetup.Validate("Manual VAT Settlement", true);
        if VATPostingSetup."VAT Bus. Posting Group" = XPURCHNOVAT then
            VATPostingSetup.Validate("Not Include into VAT Ledger",
              VATPostingSetup."Not Include into VAT Ledger"::"Purchases & Sales");
        VATPostingSetup.Insert();
    end;
}


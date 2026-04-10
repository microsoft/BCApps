codeunit 101324 "Create VAT Prod. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
            InsertData(XADVPAY20, XAdvancesRubAndAcurrVAT20);
            InsertData(XFINISH0, StrSubstNo(XFinishedProduct, '0%'));
            InsertData(XFINISH10, StrSubstNo(XFinishedProduct, '10%'));
            InsertData(XFINISH20, StrSubstNo(XFinishedProduct, '20%'));
            InsertData(XMATNOVAT, StrSubstNo(XInventories, XVATExempt));
            InsertData(XMAT10, StrSubstNo(XInventories, XVAT10));
            InsertData(XMAT20, StrSubstNo(XInventories, XVAT20));
            InsertData(XTAXAGENT20, XTaxAgentVAT20);
            InsertData(XINTASNOVAT, StrSubstNo(XIntangibleAssets, XVATExempt));
            InsertData(XINTASS20, StrSubstNo(XIntangibleAssets, XVAT20));
            InsertData(XFANOVAT, XFAVATExepmt);
            InsertData(XFACONOVAT, StrSubstNo(XConstrOfFAUsingContrWork, XVATExempt));
            InsertData(XFACONT20, StrSubstNo(XConstrOfFAUsingContrWork, XVAT20));
            InsertData(XFAECNOVAT, StrSubstNo(XSelfFinanceConstrOfFA, XVATExempt));
            InsertData(XFAECON20, StrSubstNo(XSelfFinanceConstrOfFA, XVAT20));
            InsertData(XFA10, StrSubstNo(XFixedAssets, XVAT10));
            InsertData(XFA20, StrSubstNo(XFixedAssets, XVAT20));
            InsertData(XFUTEXP20ST, XDeferralsLessYearWithinFECard);
            InsertData(XFUTEXP20LT, XDeferralMoreYearWithinFECard);
            InsertData(XCUSTOMS, XVATInCaseOfImportIntoRFVATExempt);
            InsertData(XCUSTOMS10, StrSubstNo(XVATInCaseOfImportIntoRF, '10'));
            InsertData(XCUSTOMS20, StrSubstNo(XVATInCaseOfImportIntoRF, '20'));
            InsertData(XSERVNOVAT, StrSubstNo(XJobsServices, XVATExempt));
            InsertData(XSERV0, StrSubstNo(XJobsServices, XVAT0));
            InsertData(XSERV20, StrSubstNo(XJobsServices, XVAT20));
            InsertData(XGOODSNOVAT, StrSubstNo(XGoods, XVATExempt));
            InsertData(XGOODS0, StrSubstNo(XGoods, XVAT0));
            InsertData(XGOODS10, StrSubstNo(XGoods, XVAT10));
            InsertData(XGOODS20, StrSubstNo(XGoods, XVAT20));
            InsertData(XRENT20, XEstateRentVAT20);
            InsertData(XNOREFUND, XExpensesNotIntendedForTaxPurpVATExempt);
            InsertData(XNOREFUND10, StrSubstNo(XVATNotOffset, '10%'));
            InsertData(XNOREFUND20, StrSubstNo(XVATNotOffset, '20%'));
            InsertData(XTEST, XTEST);
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
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
        XFAECNOVAT: Label 'FAECNOVAT';
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
        XNOREFUND10: Label 'NOREFUND10';
        XNOREFUND20: Label 'NOREFUND20', Comment = 'NOREFUND20';
        XNOREFUND: Label 'NOREFUND';
        XAdvancesRubAndAcurrVAT20: Label 'Advances rub. and currency VAT 20%';
        XFinishedProduct: Label 'Finished product VAT %1%';
        XInventories: Label 'Inventories %1';
        XTaxAgentVAT20: Label 'Tax agent VAT 20%';
        XIntangibleAssets: Label 'Intangible assets %1';
        XFAVATExepmt: Label 'Fixed assets VAT exempt';
        XConstrOfFAUsingContrWork: Label 'Constraction of FA using contract work %1';
        XVATExempt: Label 'VAT exempt';
        XVAT0: Label 'VAT 0%';
        XVAT10: Label 'VAT 10%';
        XVAT20: Label 'VAT 20%', Comment = 'VAT 20%';
        XSelfFinanceConstrOfFA: Label 'Self-financing construction of FA %1';
        XFixedAssets: Label 'Fixed assets %1';
        XDeferralsLessYearWithinFECard: Label 'Deferrals < 1 year (within FE card)';
        XDeferralMoreYearWithinFECard: Label 'Deferrals > 1 year (within FE card)';
        XVATInCaseOfImportIntoRFVATExempt: Label 'VAT in case of import into RF territory VAT exempt';
        XVATInCaseOfImportIntoRF: Label 'VAT %1% import into RF territory VAT exempt';
        XJobsServices: Label 'Jobs, services %1';
        XGoods: Label 'Goods %1';
        XEstateRentVAT20: Label 'Estate rent VAT 20%';
        XExpensesNotIntendedForTaxPurpVATExempt: Label 'Expenses not intended for tax purposes VAT exempt';
        XVATNotOffset: Label 'VAT not offset %1';
        XTEST: Label '_TEST';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.Init();
        VATProductPostingGroup.Validate(Code, Code);
        VATProductPostingGroup.Validate(Description, Description);
        VATProductPostingGroup.Insert();
    end;

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
            InsertData(XFA20, StrSubstNo(XFixedAssets, XVAT20));
            InsertData(XGOODS0, StrSubstNo(XGoods, XVAT0));
            InsertData(XGOODS20, StrSubstNo(XGoods, XVAT20));
            InsertData(XSERV0, StrSubstNo(XJobsServices, XVAT0));
            InsertData(XSERV20, StrSubstNo(XJobsServices, XVAT20));
            InsertData(XTEST, XTEST);
        end;
    end;

    procedure GetGoods20Code(): Code[10]
    begin
        exit(XGOODS20);
    end;

    procedure GetServ20Code(): Code[10]
    begin
        exit(XSERV20);
    end;
}


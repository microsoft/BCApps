codeunit 101251 "Create Gen. Prod. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(XASSETSFA, XInvestmentsInNonCurrAssetsFA, XFA20);
        InsertData(XASSETSOTH, XInvestmentsInNonCurrAssetsMisc, XINTASS20);
        InsertData(XASSETSACT, XNonCurrAssetsToBeAllocated, XSERV20);
        InsertData(XFINISH0, XFinishedProductNoVAT, XFINISH0);
        InsertData(XFINISH10, XFinishedProductVAT10, XFINISH10);
        InsertData(XFINISH20, XFinishedProductVAT20, XFINISH20);
        InsertData(XPROFINVEST, XLucrativeInvestInTangAssets, '');
        InsertData(XMATMFG, XRawMaterials, XMAT20);
        InsertData(XINTASSETS, XIntangibleAssets, XINTASS20);
        InsertData(XEQUIPMENT, XEquipForInstallation, XFA20);
        InsertData(XFA, XFixedAssets, XFA20);
        InsertData(XFUTEXP, XFutureExpenses, '');
        InsertData(XCUSTOMSVAT, XVATOnImportedGoods, XCUSTOMS20);
        InsertData(XPACKAGE, XTareAndEmptyTare, '');
        InsertData(XGOODS, XGoodsOnStockNoVAT, XGOODSNOVAT);
        InsertData(XGOODS0, XGoodsOnStockVAT0, XGOODS0);
        InsertData(XGOODS10, XGoodsOnStockVAT10, XGOODS10);
        InsertData(XGOODS20, XGoodsOnStockVAT20, XGOODS20);
        InsertData(XSERV, XJobsAndServicesNoVAT, XSERVNOVAT);
        InsertData(XSERV0, XJobsAndServicesVAT0, XSERV0);
        InsertData(XSERV20, XJobsAndServicesVAT20, XSERV20);
        InsertData(XFININVEST, XFinancialInvestments, '');
        InsertData(XEXPENSES, XExpensesAndCosts, '');
        InsertData(XMISCINCEXP, XMiscIncomeAndExpense, '');
        InsertData(XGOODSOOB, XGoodsOutOfBalance, '');
        InsertData(DemoDataSetup.ManufactCode(), XProductionAssets, '');
        InsertData(XTEST, XTestAutomation, XTEST);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XRawMaterials: Label 'Raw Materials';
        XFreightDescriptionTxt: Label 'Freight, etc.';
        XASSETSFA: Label 'ASSETSFA';
        XASSETSOTH: Label 'ASSETSOTH';
        XASSETSACT: Label 'ASSETSACT';
        XFINISH0: Label 'FINISH0';
        XFINISH10: Label 'FINISH10';
        XFINISH20: Label 'FINISH20', Comment = 'FINISH20';
        XPROFINVEST: Label 'PROFINVEST';
        XMATMFG: Label 'MATMFG';
        XINTASSETS: Label 'INTASSETS';
        XEQUIPMENT: Label 'EQUIPMENT';
        XFA: Label 'FA';
        XFUTEXP: Label 'FUTEXP';
        XCUSTOMSVAT: Label 'CUSTOMSVAT';
        XPACKAGE: Label 'PACKAGE';
        XGOODS: Label 'GOODS';
        XGOODS0: Label 'GOODS0';
        XGOODS10: Label 'GOODS10';
        XGOODS20: Label 'GOODS20', Comment = 'GOODS20';
        XSERVNOVAT: Label 'SERVNOVAT';
        XSERV: Label 'SERV';
        XSERV0: Label 'SERV0';
        XSERV20: Label 'SERV20', Comment = 'SERV20';
        XFININVEST: Label 'FININVEST';
        XEXPENSES: Label 'EXPENSES';
        XFA20: Label 'FA20', Comment = 'FA20';
        XINTASS20: Label 'INTASS20', Comment = 'INTASS20';
        XMAT20: Label 'MAT20', Comment = 'MAT20';
        XCUSTOMS20: Label 'CUSTOMS20', Comment = 'CUSTOMS20';
        XMISCINCEXP: Label 'MISCINCEXP';
        XGOODSNOVAT: Label 'GOODSNOVAT';
        XGOODSOOB: Label 'GOODSOOB';
        XInvestmentsInNonCurrAssetsFA: Label 'Investment in non-current assets - Fixed Assets';
        XInvestmentsInNonCurrAssetsMisc: Label 'Investment in non-current assets - Miscellaneous';
        XNonCurrAssetsToBeAllocated: Label 'Non-current Assets to be allocated';
        XFinishedProductNoVAT: Label 'Finished product (No VAT)';
        XFinishedProductVAT10: Label 'Finished product (VAT 10%)';
        XFinishedProductVAT20: Label 'Finished product (VAT 20%)';
        XLucrativeInvestInTangAssets: Label 'Lucrative investments in tangible assets';
        XIntangibleAssets: Label 'Intangible Assets';
        XEquipForInstallation: Label 'Equipment for installation';
        XFixedAssets: Label 'Fixed assets';
        XFutureExpenses: Label 'Future expenses';
        XVATOnImportedGoods: Label 'VAT On imported goods';
        XTareAndEmptyTare: Label 'Tare and empty tare';
        XGoodsOnStockNoVAT: Label 'Goods on stock (No VAT)';
        XGoodsOnStockVAT0: Label 'Goods on stock (VAT 0%)';
        XGoodsOnStockVAT10: Label 'Goods on stock (VAT 10%)';
        XGoodsOnStockVAT20: Label 'Goods on stock (VAT 20%)';
        XJobsAndServicesNoVAT: Label 'Jobs, services: acc. 90 (No VAT)';
        XJobsAndServicesVAT0: Label 'Jobs, services: acc. 90 (VAT 10%)';
        XJobsAndServicesVAT20: Label 'Jobs, services: acc. 90 (VAT 20%)';
        XFinancialInvestments: Label 'Financial investments';
        XExpensesAndCosts: Label 'Expenses and costs';
        XMiscIncomeAndExpense: Label 'Miscellaneous income and expense';
        XGoodsOutOfBalance: Label 'Goods out of balance';
        XProductionAssets: Label 'Production Assets';
        XTEST: Label '_TEST';
        XTestAutomation: Label 'Test Automation';

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        InsertData(XGOODS10, XGoodsOnStockNoVAT, XGOODS10);
        InsertData(XGOODS0, XGoodsOnStockNoVAT, XGOODS0);
        InsertData(XGOODS20, XGoodsOnStockVAT20, XGOODS20);
        InsertData(XSERV0, XJobsAndServicesVAT0, XSERV0);
        InsertData(XSERV20, XJobsAndServicesVAT20, XSERV20);
        InsertData(XASSETSFA, XInvestmentsInNonCurrAssetsFA, XFA20);
        InsertData(XFA, XFixedAssets, XFA20);
        InsertData(XEXPENSES, XExpensesAndCosts, '');
        InsertData(DemoDataSetup.FreightCode(), XFreightDescriptionTxt, XGOODS20);
        InsertData(XTEST, XTestAutomation, XTEST);
    end;

    procedure InsertData(NewCode: Code[20]; NewDescription: Text[50]; DefVATProdPostingGroup: Code[20])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GenProductPostingGroup.Init();
        GenProductPostingGroup.Validate(Code, NewCode);
        GenProductPostingGroup.Validate(Description, NewDescription);
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then
            GenProductPostingGroup."Def. VAT Prod. Posting Group" := DefVATProdPostingGroup;
        GenProductPostingGroup.Insert();
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


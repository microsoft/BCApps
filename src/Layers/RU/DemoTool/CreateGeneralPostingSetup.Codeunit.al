codeunit 101252 "Create General Posting Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertDataRU('', XFINISH20, '', '', '', '', '', '43-9998', '', '', '', '');
        InsertDataRU('', XMATMFG, '', '', '', '', '', '10-9998', '', '', '', '');
        InsertDataRU('', XPACKAGE, '', '', '', '', '', '10-9998', '', '', '', '');
        InsertDataRU('', XGOODS20, '', '', '', '', '', '41-9998', '', '', '', '');
        InsertDataRU('', XSERV20, '90-1210', '91-2331', '91-2331', '', '', '', '90-1210', '', '', '');
        InsertDataRU('', DemoDataSetup.ManufactCode(), '', '', '', '', '', '', '', '', '10-9998', '');
        InsertDataRU(XBUSINESS, XASSETSFA, '91-1302', '', '', '', '', '', '91-1302', '', '', '');
        InsertDataRU(XBUSINESS, XASSETSOTH, '91-1305', '', '', '', '', '', '91-1305', '', '', '');
        InsertDataRU(XBUSINESS, XASSETSACT, '', '', '', '', '', '', '', '', '', '');
        InsertDataRU(XBUSINESS, XFINISH0,
          '90-1330', '91-2331', '91-2331', '15-3000', '90-2330', '15-3000', '90-1330', '15-3000', '15-3000', '');
        InsertDataRU(XBUSINESS, XFINISH10,
          '90-1320', '91-2331', '91-2331', '15-3000', '90-2320', '15-3000', '90-1320', '15-3000', '15-3000', '');
        InsertDataRU(XBUSINESS, XFINISH20,
          '90-1310', '91-2331', '91-2331', '15-3000', '90-2310', '15-3000', '90-1310', '15-3000', '15-3000', '');
        InsertDataRU(XBUSINESS, XPROFINVEST, '91-1305', '', '', '', '', '', '91-1305', '', '', '');
        InsertDataRU(XBUSINESS, XMATMFG,
          '91-1305', '91-2331', '91-2331', '15-1000', '91-2305', '15-1000', '91-1305', '15-1000', '15-1000', '');
        InsertDataRU(XBUSINESS, XINTASSETS, '91-1305', '', '', '', '', '', '91-1305', '', '', '');
        InsertDataRU(XBUSINESS, XEQUIPMENT,
          '91-1305', '', '', '15-1000', '91-2305', '15-1000', '91-1305', '15-1000', '15-1000', '');
        InsertDataRU(XBUSINESS, XFA, '91-1302', '', '', '', '', '', '91-1302', '', '', '');
        InsertDataRU(XBUSINESS, XEXPENSES, '', '', '', '', '', '', '', '', '', '');
        InsertDataRU(XBUSINESS, XFUTEXP, '', '', '', '', '', '', '', '', '', '');
        InsertDataRU(XBUSINESS, XCUSTOMSVAT, '', '', '', '', '', '', '', '', '', '');
        InsertDataRU(XBUSINESS, XFUTEXP, '', '', '', '', '', '', '', '', '', '');
        InsertDataRU(XBUSINESS, XPACKAGE,
          '90-1110', '91-2331', '91-2331', '15-2000', '90-2110', '15-2000', '90-1110', '15-2000', '15-2000', '16-1000');
        InsertDataRU(XBUSINESS, XGOODSOOB, '', '', '', '99-1190', '', '99-1190', '', '99-1190', '99-1190', '');
        InsertDataRU(XBUSINESS, XGOODS,
          '90-1140', '91-2331', '91-2331', '15-2000', '90-2140', '15-2000', '90-1140', '15-2000', '15-2000', '16-1000');
        InsertDataRU(XBUSINESS, XGOODS0,
          '90-1130', '91-2331', '91-2331', '15-2000', '90-2130', '15-2000', '90-1130', '15-2000', '15-2000', '16-1000');
        InsertDataRU(XBUSINESS, XGOODS10,
          '90-1120', '91-2331', '91-2331', '15-2000', '90-2120', '15-2000', '90-1120', '15-2000', '15-2000', '16-1000');
        InsertDataRU(XBUSINESS, XGOODS20,
          '90-1110', '91-2331', '91-2331', '15-2000', '90-2110', '15-2000', '90-1110', '15-2000', '15-3000', '16-1000');
        InsertDataRU(XBUSINESS, XSERV, '90-1240', '91-2331', '91-2331', '', '', '', '90-1240', '', '', '');
        InsertDataRU(XBUSINESS, XSERV0, '90-1230', '91-2331', '91-2331', '', '', '', '90-1230', '', '', '');
        InsertDataRU(XBUSINESS, XSERV20, '90-1210', '91-2331', '91-2331', '', '', '', '90-1210', '', '', '');
        InsertDataRU(XBUSINESS, XFININVEST, '', '', '', '', '', '', '', '', '', '');
        InsertDataRU(XSTARTBAL, XFINISH10, '', '', '', '', '', '99-1002', '', '', '99-1002', '99-1002');
        InsertDataRU(XSTARTBAL, XFINISH20, '', '', '', '', '', '99-1002', '', '', '99-1002', '99-1002');
        InsertDataRU(XSTARTBAL, XMATMFG, '', '', '', '', '', '99-1002', '', '', '99-1002', '99-1002');
        InsertDataRU(XSTARTBAL, XEQUIPMENT, '', '', '', '', '', '99-1002', '', '', '99-1002', '99-1002');
        InsertDataRU(XSTARTBAL, XPACKAGE, '', '', '', '', '', '99-1002', '', '', '99-1002', '99-1002');
        InsertDataRU(XSTARTBAL, XGOODS10, '', '', '', '', '', '99-1002', '', '', '99-1002', '99-1002');
        InsertDataRU(XSTARTBAL, XGOODS20, '', '', '', '', '', '99-1002', '', '', '99-1002', '99-1002');
        InsertDataRU(XINTERCOMP, XGOODS10, '90-1120', '', '', '15-2000', '90-2120', '15-2000', '41-1000', '15-2000', '15-2000', '');
        InsertDataRU(XINTERCOMP, XGOODS20, '90-1110', '', '', '15-2000', '90-2110', '15-2000', '41-1000', '15-2000', '15-2000', '');
        InsertDataRU(XINCOME_91, XFINISH0, '', '', '', '', '', '91-1316', '', '', '', '');
        InsertDataRU(XINCOME_91, XFINISH10, '', '', '', '', '', '91-1316', '', '', '', '');
        InsertDataRU(XINCOME_91, XFINISH20, '', '', '', '', '', '91-1316', '', '', '', '');
        InsertDataRU(XINCOME_91, XMATMFG, '', '', '', '', '', '91-1316', '', '', '', '');
        InsertDataRU(XINCOME_91, XPACKAGE, '', '', '', '', '', '91-1316', '', '', '', '');
        InsertDataRU(XINCOME_91, XGOODS, '', '', '', '', '', '91-1316', '', '', '', '');
        InsertDataRU(XINCOME_91, XGOODS0, '', '', '', '', '', '91-1316', '', '', '', '');
        InsertDataRU(XINCOME_91, XGOODS10, '', '', '', '', '', '91-1316', '', '', '', '');
        InsertDataRU(XINCOME_91, XGOODS20, '', '', '', '', '', '91-1316', '', '', '', '');
        InsertDataRU(XEXP + '_08_31', XMATMFG, '', '', '', '', '', '08-3100', '', '', '', '');
        InsertDataRU(XEXP + '_08_31', XEQUIPMENT, '', '', '', '', '', '08-3100', '', '', '', '');
        InsertDataRU(XEXP + '_08_32', XMATMFG, '', '', '', '', '', '08-3200', '', '', '', '');
        InsertDataRU(XEXP + '_08_32', XEQUIPMENT, '', '', '', '', '', '08-3200', '', '', '', '');
        InsertDataRU(XEXP + '_08_33', XMATMFG, '', '', '', '', '', '08-3300', '', '', '', '');
        InsertDataRU(XEXP + '_08_33', XEQUIPMENT, '', '', '', '', '', '08-3300', '', '', '', '');
        InsertDataRU(XEXP + '_08_80', XMATMFG, '', '', '', '', '', '08-8000', '', '', '', '');
        InsertDataRU(XEXP + '_08_80', XEQUIPMENT, '', '', '', '', '', '08-8000', '', '', '', '');
        InsertDataRU(XEXP + '_08_90', XMATMFG, '', '', '', '', '', '08-9000', '', '', '', '');
        InsertDataRU(XEXP + '_08_90', XEQUIPMENT, '', '', '', '', '', '08-8000', '', '', '', '');
        InsertDataRU(XEXP + '_20', XMATMFG, '', '', '', '', '', '20-1100', '', '', '', '');
        InsertDataRU(XEXP + '_21', XMATMFG, '', '', '', '', '', '21-1000', '', '', '', '');
        InsertDataRU(XEXP + '_23', XMATMFG, '', '', '', '', '', '23-1000', '', '', '', '');
        InsertDataRU(XEXP + '_25', XMATMFG, '', '', '', '', '', '25-1000', '', '', '', '');
        InsertDataRU(XEXP + '_26', XMATMFG, '', '', '', '', '', '26-2000', '', '', '', '');
        InsertDataRU(XEXP + '_29', XMATMFG, '', '', '', '', '', '29-1000', '', '', '', '');
        InsertDataRU(XEXP + '_44', XMATMFG, '', '', '', '', '', '44-2100', '', '', '', '');
        InsertDataRU(XEXP + '_94', XFINISH0, '', '', '', '', '', '94-1000', '', '', '', '');
        InsertDataRU(XEXP + '_94', XFINISH10, '', '', '', '', '', '94-1000', '', '', '', '');
        InsertDataRU(XEXP + '_94', XFINISH20, '', '', '', '', '', '94-1000', '', '', '', '');
        InsertDataRU(XEXP + '_94', XMATMFG, '', '', '', '', '', '94-1000', '', '', '', '');
        InsertDataRU(XEXP + '_94', XPACKAGE, '', '', '', '', '', '94-1000', '', '', '', '');
        InsertDataRU(XEXP + '_94', XGOODS, '', '', '', '', '', '94-1000', '', '', '', '');
        InsertDataRU(XEXP + '_94', XGOODS0, '', '', '', '', '', '94-1000', '', '', '', '');
        InsertDataRU(XEXP + '_94', XGOODS10, '', '', '', '', '', '94-1000', '', '', '', '');
        InsertDataRU(XEXP + '_94', XGOODS20, '', '', '', '', '', '94-1000', '', '', '', '');
        InsertDataRU(XBUSINESS, XMISCINCEXP, '', '', '', '', '', '', '', '', '', '');
        InsertDataRU(XEXP + '_20' + XN, XMATMFG, '', '', '', '', '', '20-2995', '', '', '', '');
        InsertDataRU(XEXP + '_26' + XN, XMATMFG, '', '', '', '', '', '26-9995', '', '', '', '');
        InsertDataRU(XEXP + '_44' + XN, XMATMFG, '', '', '', '', '', '44-2995', '', '', '', '');
        InsertDataRU(XEXP + '_91' + XN, XMATMFG, '', '', '', '', '', '91-2391', '', '', '', '');
        // test automation
        InsertTest();
    end;

    var
        "General Posting Setup": Record "General Posting Setup";
        DemoDataSetup: Record "Demo Data Setup";
        CA: Codeunit "Make Adjustments";
        XBUSINESS: Label 'BUSINESS';
        XSTARTBAL: Label 'STARTBAL';
        XINTERCOMP: Label 'INTERCOMP';
        XINCOME_91: Label 'INCOME_91';
        XEXP: Label 'EXP';
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
        XSERV: Label 'SERV';
        XSERV0: Label 'SERV0';
        XSERV20: Label 'SERV20', Comment = 'SERV20';
        XFININVEST: Label 'FININVEST';
        XEXPENSES: Label 'EXPENSES';
        XMISCINCEXP: Label 'MISCINCEXP';
        XGOODSOOB: Label 'GOODSOOB';
        XN: Label 'N';
        XTEST: Label '_TEST';

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        InsertDataRU('', XGOODS20, '', '', '', '', '', '41-9998', '', '', '', '');
        InsertDataRU('', XSERV20, '90-1210', '91-2331', '91-2331', '', '', '', '90-1210', '', '', '');
        InsertDataRU(XBUSINESS, XASSETSFA, '91-1302', '', '', '', '', '', '91-1302', '', '', '');
        InsertDataRU(XBUSINESS, XASSETSOTH, '91-1305', '', '', '', '', '', '91-1305', '', '', '');
        InsertDataRU(XBUSINESS, XASSETSACT, '', '', '', '', '', '', '', '', '', '');
        InsertDataRU(XBUSINESS, XFA, '91-1302', '', '', '', '', '', '91-1302', '', '', '');
        InsertDataRU(XBUSINESS, XEXPENSES, '', '', '', '', '', '', '', '', '', '');
        InsertDataRU(XBUSINESS, XCUSTOMSVAT, '', '', '', '', '', '', '', '', '', '');
        InsertDataRU('', DemoDataSetup.FreightCode(), '', '', '', '', '', '', '', '', '', '');
        InsertDataRU(XBUSINESS, XPACKAGE,
          '90-1110', '91-2331', '91-2331', '15-2000', '90-2110', '15-2000', '90-1110', '15-2000', '15-2000', '16-1000');
        InsertDataRU(XBUSINESS, XGOODSOOB, '', '', '', '99-1190', '', '99-1190', '', '99-1190', '99-1190', '');
        InsertDataRU(XBUSINESS, XGOODS,
          '90-1140', '91-2331', '91-2331', '15-2000', '90-2140', '15-2000', '90-1140', '15-2000', '15-2000', '16-1000');
        InsertDataRU(XBUSINESS, XGOODS0,
          '90-1130', '91-2331', '91-2331', '15-2000', '90-2130', '15-2000', '90-1130', '15-2000', '15-2000', '16-1000');
        InsertDataRU(XBUSINESS, XGOODS10,
          '90-1120', '91-2331', '91-2331', '15-2000', '90-2120', '15-2000', '90-1120', '15-2000', '15-2000', '16-1000');
        InsertDataRU(XBUSINESS, XGOODS20,
          '90-1110', '91-2331', '91-2331', '15-2000', '90-2110', '15-2000', '90-1110', '15-2000', '15-3000', '16-1000');
        InsertDataRU(XBUSINESS, XSERV0, '90-1230', '91-2331', '91-2331', '', '', '', '90-1230', '', '', '');
        InsertDataRU(XBUSINESS, XSERV20, '90-1210', '91-2331', '91-2331', '', '', '', '90-1210', '', '', '');
        InsertDataRU(XBUSINESS, XFININVEST, '', '', '', '', '', '', '', '', '', '');
        InsertDataRU(XINTERCOMP, XGOODS10, '90-1120', '', '', '15-2000', '90-2120', '15-2000', '41-1000', '15-2000', '15-2000', '');
        InsertDataRU(XINTERCOMP, XGOODS20, '90-1110', '', '', '15-2000', '90-2110', '15-2000', '41-1000', '15-2000', '15-2000', '');
        InsertDataRU(XBUSINESS, XMISCINCEXP, '', '', '', '', '', '', '', '', '', '');
        InsertDataRU(XBUSINESS, DemoDataSetup.FreightCode(),
          '90-1140', '91-2331', '91-2331', '15-2000', '90-2140', '15-2000', '90-1140', '15-2000', '15-2000', '16-1000');
        InsertDataRU(XINTERCOMP, DemoDataSetup.FreightCode(),
          '90-1140', '91-2331', '91-2331', '15-2000', '90-2140', '15-2000', '90-1140', '15-2000', '15-2000', '16-1000');
        // test automation
        InsertTest();
        UpdateTest(XTEST, XGOODS20);
    end;

    procedure InsertDataRU(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; SalesAccount: Code[20]; SalesLineDiscAccount: Code[20]; SalesInvDiscAccount: Code[20]; PurchAccount: Code[20]; COGSAccount: Code[20]; InventoryAdjmtAccount: Code[20]; SalesCreditMemoAccount: Code[20]; PurchCreditMemoAccount: Code[20]; DirectCostAppliedAccount: Code[20]; PurchaseVarianceAccount: Code[20])
    begin
        "General Posting Setup".Init();
        "General Posting Setup"."Gen. Bus. Posting Group" := GenBusPostingGroup;
        "General Posting Setup"."Gen. Prod. Posting Group" := GenProdPostingGroup;
        "General Posting Setup"."Sales Account" := CA.Convert(SalesAccount);
        "General Posting Setup"."Sales Line Disc. Account" := CA.Convert(SalesLineDiscAccount);
        "General Posting Setup"."Sales Inv. Disc. Account" := CA.Convert(SalesInvDiscAccount);
        "General Posting Setup"."COGS Account" := CA.Convert(COGSAccount);
        "General Posting Setup"."Purch. Account" := CA.Convert(PurchAccount);
        "General Posting Setup"."COGS Account (Interim)" := "General Posting Setup"."COGS Account";
        "General Posting Setup"."Inventory Adjmt. Account" := CA.Convert(InventoryAdjmtAccount);
        "General Posting Setup"."Invt. Accrual Acc. (Interim)" := "General Posting Setup"."Inventory Adjmt. Account";
        "General Posting Setup"."Sales Credit Memo Account" := CA.Convert(SalesCreditMemoAccount);
        "General Posting Setup"."Purch. Credit Memo Account" := CA.Convert(PurchCreditMemoAccount);
        "General Posting Setup"."Direct Cost Applied Account" := CA.Convert(DirectCostAppliedAccount);
        "General Posting Setup"."Purchase Variance Account" := CA.Convert(PurchaseVarianceAccount);
        if "General Posting Setup".Insert() then;
    end;

    procedure InsertTest()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GenProductPostingGroup.Reset();
        if GenProductPostingGroup.FindSet() then
            repeat
                if GeneralPostingSetup.Get(XBUSINESS, GenProductPostingGroup.Code) then begin
                    GeneralPostingSetup."Gen. Bus. Posting Group" := XTEST;
                    GeneralPostingSetup.Insert();
                end;
            until GenProductPostingGroup.Next() = 0;

        if GeneralPostingSetup.Get('', XGOODS20) then begin
            GeneralPostingSetup."Gen. Prod. Posting Group" := XTEST;
            GeneralPostingSetup.Insert();
        end;

        if GeneralPostingSetup.Get(XBUSINESS, XGOODS20) then begin
            GeneralPostingSetup."Gen. Prod. Posting Group" := XTEST;
            GeneralPostingSetup.Insert();
        end;

        if GeneralPostingSetup.Get(XBUSINESS, XGOODS20) then begin
            GeneralPostingSetup."Gen. Bus. Posting Group" := XTEST;
            GeneralPostingSetup."Gen. Prod. Posting Group" := XTEST;
            if GeneralPostingSetup."Purch. Line Disc. Account" = '' then
                GeneralPostingSetup."Purch. Line Disc. Account" := GeneralPostingSetup."Sales Line Disc. Account";
            if GeneralPostingSetup."Purch. Inv. Disc. Account" = '' then
                GeneralPostingSetup."Purch. Inv. Disc. Account" := GeneralPostingSetup."Sales Inv. Disc. Account";
            GeneralPostingSetup.Insert();
        end;
    end;

    procedure UpdateTest(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    begin
        "General Posting Setup".Get(GenBusPostingGroup, GenProdPostingGroup);
        "General Posting Setup"."Sales Pmt. Disc. Debit Acc." := "General Posting Setup"."Sales Account";
        "General Posting Setup"."Sales Pmt. Disc. Credit Acc." := "General Posting Setup"."Sales Account";
        "General Posting Setup"."Sales Pmt. Tol. Debit Acc." := "General Posting Setup"."Sales Account";
        "General Posting Setup"."Sales Pmt. Tol. Credit Acc." := "General Posting Setup"."Sales Account";
        "General Posting Setup"."Sales Prepayments Account" := "General Posting Setup"."Sales Account";

        "General Posting Setup"."Purch. Line Disc. Account" := "General Posting Setup"."Purch. Account";
        "General Posting Setup"."Purch. Inv. Disc. Account" := "General Posting Setup"."Purch. Account";
        "General Posting Setup"."Purch. Pmt. Disc. Credit Acc." := "General Posting Setup"."Purch. Account";
        "General Posting Setup"."Purch. Pmt. Disc. Debit Acc." := "General Posting Setup"."Purch. Account";
        "General Posting Setup"."Purch. Pmt. Tol. Debit Acc." := "General Posting Setup"."Purch. Account";
        "General Posting Setup"."Purch. Pmt. Tol. Credit Acc." := "General Posting Setup"."Purch. Account";
        "General Posting Setup"."Purch. Prepayments Account" := "General Posting Setup"."Purch. Account";
        "General Posting Setup"."Purch. FA Disc. Account" := "General Posting Setup"."Purch. Account";
        "General Posting Setup"."Invt. Accrual Acc. (Interim)" := "General Posting Setup"."Inventory Adjmt. Account";
        "General Posting Setup"."COGS Account (Interim)" := "General Posting Setup"."COGS Account";
        "General Posting Setup"."Sales Full Tax VAT Account" := "General Posting Setup"."Sales Account";
        "General Posting Setup"."Overhead Applied Account" := "General Posting Setup"."Direct Cost Applied Account";
        "General Posting Setup".Modify();
    end;
}


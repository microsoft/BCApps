codeunit 161504 "Create CH Gen. Posting Setup"
{

    trigger OnRun()
    begin
        xVerkRechRabKto := '3901';
        xVerkSkontoKto := '3900';
        xEinkRechRabKto := '4901';
        xEinkSkontoKto := '4900';

        xProjErtragKto := '3420';
        xProjAufwKto := '4420';

        // Zeilen vorbereiten und schreiben
        // "Gen. Bus. Posting Group","Gen. Prod. Posting Group","Sales Account","Purch. Account","COGS Account",ISDefSal,ISDefPurch
        InsertLine(xCodeCH, xCodeHandel, '3200', '4200', '3280', '', '', true, true);
        InsertLine(xCodeCH, xCodeRohmat, '3000', '4000', '3080', '', '', true, true);
        InsertLine(xCodeCH, xCodeArbeit, '3400', '4400', '', '', '', true, true);

        InsertLine(xCodeEU, xCodeHandel, '3202', '4202', '3280', '', '', true, true);
        InsertLine(xCodeEU, xCodeRohmat, '3002', '4002', '3080', '', '', true, true);
        InsertLine(xCodeEU, xCodeArbeit, '3002', '4002', '3080', '', '', true, true);
        InsertLine(xCodeINTERNAT, xCodeHandel, '3204', '4204', '3280', '', '', true, true);
        InsertLine(xCodeINTERNAT, xCodeRohmat, '3004', '4004', '3080', '', '', true, true);

        InsertLine('', xCodeHandel, '', '', '3280', xProjErtragKto, xProjAufwKto, false, false);
        InsertLine('', xCodeRohmat, '', '', '3080', xProjErtragKto, xProjAufwKto, false, false);
        InsertLine('', xCodeArbeit, '', '', '', xProjErtragKto, xProjAufwKto, false, false);

        AddPrepayAccounts(xCodeCH, xCodeHandel, '1193', '2031');
        AddPrepayAccounts(xCodeCH, xCodeRohmat, '1193', '2031');
        AddPrepayAccounts(xCodeCH, xCodeArbeit, '1193', '2031');

        AddPrepayAccounts(xCodeEU, xCodeHandel, '1192', '2030');
        AddPrepayAccounts(xCodeEU, xCodeRohmat, '1192', '2030');
        AddPrepayAccounts(xCodeEU, xCodeArbeit, '1192', '2030');
        AddPrepayAccounts(xCodeINTERNAT, xCodeHandel, '1192', '2030');
        AddPrepayAccounts(xCodeINTERNAT, xCodeRohmat, '1192', '2030');

        AddPrepayAccounts('', xCodeHandel, '1192', '2030');
        AddPrepayAccounts('', xCodeRohmat, '1192', '2030');
        AddPrepayAccounts('', xCodeArbeit, '1192', '2030');
    end;

    var
        GeneralPostingSetup: Record "General Posting Setup";
        xVerkRechRabKto: Code[10];
        xVerkSkontoKto: Code[10];
        xEinkRechRabKto: Code[10];
        xEinkSkontoKto: Code[10];
        xProjErtragKto: Code[10];
        xProjAufwKto: Code[10];
        xCodeCH: Label 'NATIONAL';
        xCodeEU: Label 'EU';
        xCodeINTERNAT: Label 'EXPORT';
        xCodeHandel: Label 'RETAIL';
        xCodeRohmat: Label 'RAW MAT';
        xCodeArbeit: Label 'SERVICES';

    procedure InsertLine(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; SalesAccount: Code[20]; PurchAccount: Code[20]; COGSAccount: Code[20]; JobSalesAdjmtAccount: Code[20]; JobCostAdjmtAccount: Code[20]; IsDefaultSales: Boolean; IsDefaultPurchase: Boolean)
    begin
        GeneralPostingSetup.Init();
        GeneralPostingSetup."Gen. Bus. Posting Group" := GenBusPostingGroup;
        GeneralPostingSetup."Gen. Prod. Posting Group" := GenProdPostingGroup;
        GeneralPostingSetup."Sales Account" := SalesAccount;
        GeneralPostingSetup."Purch. Account" := PurchAccount;
        GeneralPostingSetup."COGS Account" := COGSAccount;

        if IsDefaultSales then begin
            GeneralPostingSetup."Sales Pmt. Disc. Debit Acc." := xVerkSkontoKto;
            GeneralPostingSetup."Sales Pmt. Disc. Credit Acc." := xVerkSkontoKto;
            GeneralPostingSetup."Sales Inv. Disc. Account" := xVerkRechRabKto;
            GeneralPostingSetup."Sales Line Disc. Account" := GeneralPostingSetup."Sales Account";
            GeneralPostingSetup."Sales Credit Memo Account" := GeneralPostingSetup."Sales Account";
            GeneralPostingSetup."Sales Pmt. Tol. Debit Acc." := xVerkSkontoKto;
            GeneralPostingSetup."Sales Pmt. Tol. Credit Acc." := xVerkSkontoKto;
        end;
        if IsDefaultPurchase then begin
            GeneralPostingSetup."Purch. Pmt. Disc. Credit Acc." := xEinkSkontoKto;
            GeneralPostingSetup."Purch. Pmt. Disc. Debit Acc." := xEinkSkontoKto;
            GeneralPostingSetup."Purch. Inv. Disc. Account" := xEinkRechRabKto;
            GeneralPostingSetup."Purch. Credit Memo Account" := GeneralPostingSetup."Purch. Account";
            GeneralPostingSetup."Purch. Line Disc. Account" := GeneralPostingSetup."Purch. Account";
            GeneralPostingSetup."Purch. Pmt. Tol. Debit Acc." := xEinkSkontoKto;
            GeneralPostingSetup."Purch. Pmt. Tol. Credit Acc." := xEinkSkontoKto;
        end;

        GeneralPostingSetup."Inventory Adjmt. Account" := GeneralPostingSetup."COGS Account";
        if not GeneralPostingSetup.Insert() then
            GeneralPostingSetup.Modify();
    end;

    procedure AddPrepayAccounts(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; SalesPrepAccount: Code[20]; PurchPrepAccount: Code[20])
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup."Sales Prepayments Account" := SalesPrepAccount;
        GeneralPostingSetup."Purch. Prepayments Account" := PurchPrepAccount;
        GeneralPostingSetup.Modify();
    end;

    procedure InsertMiniAppData()
    var
        DemoDataSetup: Record "Demo Data Setup";
    begin
        xVerkRechRabKto := '3901';
        xVerkSkontoKto := '';
        xEinkRechRabKto := '4901';
        xEinkSkontoKto := '';

        xProjErtragKto := '3420';
        xProjAufwKto := '4420';

        // Zeilen vorbereiten und schreiben
        // "Gen. Bus. Posting Group","Gen. Prod. Posting Group","Sales Account","Purch. Account","COGS Account",ISDefSal,ISDefPurch
        InsertLine(DemoDataSetup.DomesticCode(), xCodeHandel, '3200', '4200', '3280', '', '', true, true);
        InsertLine(DemoDataSetup.DomesticCode(), xCodeArbeit, '3400', '4400', '3080', '', '', true, true);

        InsertLine(xCodeEU, xCodeHandel, '3202', '4202', '3280', '', '', true, true);
        InsertLine(xCodeEU, xCodeArbeit, '3002', '4002', '3080', '', '', true, true);
        InsertLine(xCodeINTERNAT, xCodeHandel, '3204', '4204', '3280', '', '', true, true);

        InsertLine('', xCodeHandel, '', '', '3280', xProjErtragKto, xProjAufwKto, false, false);
        InsertLine('', xCodeArbeit, '', '', '', xProjErtragKto, xProjAufwKto, false, false);

        AddPrepayAccounts(DemoDataSetup.DomesticCode(), xCodeHandel, '1193', '2031');
        AddPrepayAccounts(DemoDataSetup.DomesticCode(), xCodeArbeit, '1193', '2031');
        AddCostAccounts(DemoDataSetup.DomesticCode(), xCodeHandel, '3280');
        AddCostAccounts(DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '3280');
        AddCostAccounts(DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '3280');

        AddPrepayAccounts(xCodeEU, xCodeHandel, '1192', '2030');
        AddPrepayAccounts(xCodeEU, xCodeArbeit, '1192', '2030');
        AddPrepayAccounts(xCodeINTERNAT, xCodeHandel, '1192', '2030');

        AddPrepayAccounts('', xCodeHandel, '1192', '2030');
        AddPrepayAccounts('', xCodeArbeit, '1192', '2030');
    end;

    local procedure AddCostAccounts(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; DirCostAppliedAcc: Code[20])
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup.Validate("Direct Cost Applied Account", DirCostAppliedAcc);
        GeneralPostingSetup.Modify();
    end;
}


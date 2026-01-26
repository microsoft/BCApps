codeunit 101252 "Create General Posting Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        AdjustForPmtDisc := DemoDataSetup."Adjust for Payment Discount";
        InsertData('', DemoDataSetup.MiscCode(), '', '');
        InsertData('', DemoDataSetup.NoVATCode(), '', '');
        InsertData('', DemoDataSetup.RawMatCode(), '', '');
        InsertData('', DemoDataSetup.RetailCode(), '', '');
        InsertData('', DemoDataSetup.ServicesCode(), '', '');
        InsertData('', DemoDataSetup.ManufactCode(), '', '');
        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '996110', '997110');
        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '996110', '997110');
        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '996210', '997210');
        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '996110', '997110');
        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '996410', '997110');
        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '996110', '997110');
        InsertData(DemoDataSetup.EUCode(), DemoDataSetup.MiscCode(), '996120', '997120');
        InsertData(DemoDataSetup.EUCode(), DemoDataSetup.NoVATCode(), '996120', '997120');
        InsertData(DemoDataSetup.EUCode(), DemoDataSetup.RawMatCode(), '996220', '997220');
        InsertData(DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '996120', '997120');
        InsertData(DemoDataSetup.EUCode(), DemoDataSetup.ServicesCode(), '996420', '997120');
        InsertData(DemoDataSetup.EUCode(), DemoDataSetup.ManufactCode(), '996120', '997120');
        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.MiscCode(), '996130', '997130');
        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), '996130', '997130');
        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '996230', '997230');
        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '996130', '997130');
        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.ServicesCode(), '996430', '997130');
        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.ManufactCode(), '996130', '997130');
    end;

    var
        GeneralPostingSetup: Record "General Posting Setup";
        DemoDataSetup: Record "Demo Data Setup";
        CA: Codeunit "Make Adjustments";
        CreateGLAccount: Codeunit "Create G/L Account";
        AdjustForPmtDisc: Boolean;

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        AdjustForPmtDisc := false;
        InsertData2(DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), CreateGLAccount.ResaleofGoods(), CreateGLAccount.SalesDiscounts(), CreateGLAccount.GoodsforResale(), CreateGLAccount.PurchaseDiscounts(), CreateGLAccount.GoodsforResale(), CreateGLAccount.CostofMaterials(), CreateGLAccount.CostofMaterials());
        InsertData2(DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), CreateGLAccount.ResaleofGoods(), CreateGLAccount.SalesDiscounts(), CreateGLAccount.GoodsforResale(), CreateGLAccount.PurchaseDiscounts(), CreateGLAccount.GoodsforResale(), CreateGLAccount.CostofMaterials(), CreateGLAccount.CostofMaterials());
        InsertData2(DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), CreateGLAccount.ResaleofGoods(), CreateGLAccount.SalesDiscounts(), CreateGLAccount.GoodsforResale(), CreateGLAccount.PurchaseDiscounts(), CreateGLAccount.GoodsforResale(), CreateGLAccount.CostofMaterials(), CreateGLAccount.CostofMaterials());

        InsertData2(DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), CreateGLAccount.SalesofServiceWork(), CreateGLAccount.SalesDiscounts(), CreateGLAccount.OtherExternalServices(), CreateGLAccount.PurchaseDiscounts(), CreateGLAccount.OtherExternalServices(), CreateGLAccount.CostofLabor(), CreateGLAccount.CostofLabor());
        InsertData2(DemoDataSetup.ExportCode(), DemoDataSetup.ServicesCode(), CreateGLAccount.SalesofServiceWork(), CreateGLAccount.SalesDiscounts(), CreateGLAccount.OtherExternalServices(), CreateGLAccount.PurchaseDiscounts(), CreateGLAccount.OtherExternalServices(), CreateGLAccount.CostofLabor(), CreateGLAccount.CostofLabor());

        InsertData2(DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), CreateGLAccount.ResaleofGoods(), CreateGLAccount.SalesDiscounts(), CreateGLAccount.GoodsforResale(), CreateGLAccount.PurchaseDiscounts(), CreateGLAccount.GoodsforResale(), CreateGLAccount.CostofMaterials(), CreateGLAccount.CostofMaterials());
        InsertData2(DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), CreateGLAccount.ResaleofGoods(), CreateGLAccount.SalesDiscounts(), CreateGLAccount.GoodsforResale(), CreateGLAccount.PurchaseDiscounts(), CreateGLAccount.GoodsforResale(), CreateGLAccount.CostofMaterials(), CreateGLAccount.CostofMaterials());
        InsertData2('', DemoDataSetup.RetailCode(), '', '', '', '', CreateGLAccount.GoodsforResale(), CreateGLAccount.CostofMaterials(), CreateGLAccount.CostofMaterials());
        InsertData2('', DemoDataSetup.NoVATCode(), '', '', '', '', CreateGLAccount.GoodsforResale(), CreateGLAccount.CostofMaterials(), CreateGLAccount.CostofMaterials());
    end;

    procedure InsertData(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; SalesAccount: Code[20]; PurchaseAccount: Code[20])
    begin
        GeneralPostingSetup.Init();
        GeneralPostingSetup.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        GeneralPostingSetup.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GeneralPostingSetup.Validate("Sales Account", CA.Convert(SalesAccount));
        GeneralPostingSetup.Validate("Sales Credit Memo Account", CA.Convert(SalesAccount));
        GeneralPostingSetup.Validate("Purch. Account", CA.Convert(PurchaseAccount));
        GeneralPostingSetup.Validate("Purch. Credit Memo Account", CA.Convert(PurchaseAccount));
        UpdatePmtDiscAccounts();
        UpdatePmtTolAccounts();
        UpdatePrepmtAccounts();
        UpdateInvDiscAccounts();

        case GeneralPostingSetup."Gen. Prod. Posting Group" of
            DemoDataSetup.RawMatCode():
                begin
                    GeneralPostingSetup.Validate("COGS Account", CA.Convert('997290'));
                    GeneralPostingSetup.Validate("COGS Account (Interim)", CA.Convert('997289'));
                    GeneralPostingSetup.Validate("Inventory Adjmt. Account", CA.Convert('997170'));
                    GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", CA.Convert('997271'));
                    GeneralPostingSetup.Validate("Direct Cost Applied Account", CA.Convert('997170'));
                end;
            DemoDataSetup.RetailCode(),
            DemoDataSetup.MiscCode(),
            DemoDataSetup.NoVATCode():
                begin
                    GeneralPostingSetup.Validate("COGS Account", CA.Convert('997290'));
                    GeneralPostingSetup.Validate("COGS Account (Interim)", CA.Convert('997189'));
                    GeneralPostingSetup.Validate("Inventory Adjmt. Account", CA.Convert('997170'));
                    GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", CA.Convert('997171'));
                    GeneralPostingSetup.Validate("Direct Cost Applied Account", CA.Convert('997170'));
                end;
            DemoDataSetup.ServicesCode(),
            DemoDataSetup.FreightCode():
                begin
                    GeneralPostingSetup.Validate("COGS Account", CA.Convert('997290'));
                    GeneralPostingSetup.Validate("COGS Account (Interim)", CA.Convert('997189'));
                    GeneralPostingSetup.Validate("Inventory Adjmt. Account", CA.Convert('997170'));
                    GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", CA.Convert('997171'));
                    GeneralPostingSetup.Validate("Direct Cost Applied Account", CA.Convert('997170'));
                end;
        end;
        GeneralPostingSetup.Insert();
    end;

    local procedure UpdatePmtDiscAccounts()
    begin
        if GeneralPostingSetup."Gen. Bus. Posting Group" <> '' then
            if AdjustForPmtDisc then begin
                GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", CA.Convert('999250'));
                GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", CA.Convert('999130'));
                GeneralPostingSetup.Validate("Sales Pmt. Disc. Credit Acc.", CA.Convert('999255'));
                GeneralPostingSetup.Validate("Purch. Pmt. Disc. Debit Acc.", CA.Convert('999135'));
            end;
    end;

    local procedure UpdatePmtTolAccounts()
    begin
        if GeneralPostingSetup."Gen. Bus. Posting Group" <> '' then
            if AdjustForPmtDisc then begin
                GeneralPostingSetup.Validate("Sales Pmt. Tol. Debit Acc.", CA.Convert('999260'));
                GeneralPostingSetup.Validate("Purch. Pmt. Tol. Credit Acc.", CA.Convert('999160'));
                GeneralPostingSetup.Validate("Sales Pmt. Tol. Credit Acc.", CA.Convert('999270'));
                GeneralPostingSetup.Validate("Purch. Pmt. Tol. Debit Acc.", CA.Convert('999170'));
            end;
    end;

    local procedure UpdatePrepmtAccounts()
    begin
        if DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::Extended then
            exit;

        if GeneralPostingSetup."Gen. Bus. Posting Group" = DemoDataSetup.DomesticCode() then
            case GeneralPostingSetup."Gen. Prod. Posting Group" of
                DemoDataSetup.MiscCode(),
                DemoDataSetup.RawMatCode(),
                DemoDataSetup.RetailCode():
                    begin
                        GeneralPostingSetup.Validate("Sales Prepayments Account", CA.Convert('995380'));
                        GeneralPostingSetup.Validate("Purch. Prepayments Account", CA.Convert('992430'));
                    end;
                DemoDataSetup.NoVATCode():
                    begin
                        GeneralPostingSetup.Validate("Sales Prepayments Account", CA.Convert('995360'));
                        GeneralPostingSetup.Validate("Purch. Prepayments Account", CA.Convert('992410'));
                    end;
                DemoDataSetup.ServicesCode():
                    begin
                        GeneralPostingSetup.Validate("Sales Prepayments Account", CA.Convert('995360'));
                        GeneralPostingSetup.Validate("Purch. Prepayments Account", CA.Convert('992410'));
                    end;
            end;
    end;

    local procedure UpdateInvDiscAccounts()
    begin
        if GeneralPostingSetup."Gen. Bus. Posting Group" <> '' then
            case GeneralPostingSetup."Gen. Prod. Posting Group" of
                DemoDataSetup.RawMatCode():
                    begin
                        GeneralPostingSetup.Validate("Sales Line Disc. Account", CA.Convert('996910'));
                        GeneralPostingSetup.Validate("Sales Inv. Disc. Account", CA.Convert('996910'));
                        GeneralPostingSetup.Validate("Purch. Line Disc. Account", CA.Convert('997240'));
                        GeneralPostingSetup.Validate("Purch. Inv. Disc. Account", CA.Convert('997240'));
                    end;
                DemoDataSetup.RetailCode(),
                DemoDataSetup.MiscCode(),
                DemoDataSetup.NoVATCode(),
                DemoDataSetup.ServicesCode(),
                DemoDataSetup.FreightCode(),
                DemoDataSetup.ManufactCode():
                    begin
                        GeneralPostingSetup.Validate("Sales Line Disc. Account", CA.Convert('996910'));
                        GeneralPostingSetup.Validate("Sales Inv. Disc. Account", CA.Convert('996910'));
                        GeneralPostingSetup.Validate("Purch. Line Disc. Account", CA.Convert('997140'));
                        GeneralPostingSetup.Validate("Purch. Inv. Disc. Account", CA.Convert('997140'));
                    end;
            end;
    end;

    local procedure InsertData2("Gen. Bus. Posting Group": Code[20]; "Gen. Prod. Posting Group": Code[20]; SalesAccount: Code[20]; SalesDiscAccount: Code[20]; PurchaseAccount: Code[20]; PurchaseDiscAccount: Code[20]; InventoryAccount: Code[20]; COGSAccount: Code[20]; InventoryAdjAccount: Code[20])
    begin
        GeneralPostingSetup.Init();
        GeneralPostingSetup.Validate("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
        GeneralPostingSetup.Validate("Gen. Prod. Posting Group", "Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Sales Account", SalesAccount);
        GeneralPostingSetup.Validate("Sales Credit Memo Account", SalesAccount);
        GeneralPostingSetup.Validate("Sales Inv. Disc. Account", SalesDiscAccount);
        GeneralPostingSetup.Validate("Sales Line Disc. Account", SalesDiscAccount);
        GeneralPostingSetup.Validate("Purch. Account", PurchaseAccount);
        GeneralPostingSetup.Validate("Purch. Credit Memo Account", PurchaseAccount);
        GeneralPostingSetup.Validate("Purch. Inv. Disc. Account", PurchaseDiscAccount);
        GeneralPostingSetup.Validate("Purch. Line Disc. Account", PurchaseDiscAccount);
        GeneralPostingSetup.Validate("Inventory Adjmt. Account", InventoryAdjAccount);
        GeneralPostingSetup.Validate("Direct Cost Applied Account", InventoryAccount);
        GeneralPostingSetup.Validate("Overhead Applied Account", InventoryAccount);
        GeneralPostingSetup.Validate("COGS Account", COGSAccount);
        UpdatePmtDiscAccounts2();
        UpdatePmtTolAccounts2();
        GeneralPostingSetup.Insert();
    end;

    local procedure UpdatePmtDiscAccounts2()
    begin
        if GeneralPostingSetup."Gen. Bus. Posting Group" <> '' then
            if AdjustForPmtDisc then begin
                GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", CreateGLAccount.SalesDiscounts());
                GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", CreateGLAccount.PurchaseDiscounts());
                GeneralPostingSetup.Validate("Sales Pmt. Disc. Credit Acc.", CreateGLAccount.SalesDiscounts());
                GeneralPostingSetup.Validate("Purch. Pmt. Disc. Debit Acc.", CreateGLAccount.PurchaseDiscounts());
            end;
    end;

    local procedure UpdatePmtTolAccounts2()
    begin
        if GeneralPostingSetup."Gen. Bus. Posting Group" <> '' then
            if AdjustForPmtDisc then begin
                GeneralPostingSetup.Validate("Sales Pmt. Tol. Debit Acc.", CreateGLAccount.PayableInvoiceRounding());
                GeneralPostingSetup.Validate("Purch. Pmt. Tol. Credit Acc.", CreateGLAccount.PayableInvoiceRounding());
                GeneralPostingSetup.Validate("Sales Pmt. Tol. Credit Acc.", CreateGLAccount.PayableInvoiceRounding());
                GeneralPostingSetup.Validate("Purch. Pmt. Tol. Debit Acc.", CreateGLAccount.PayableInvoiceRounding());
            end;
    end;
}


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
        GetGLAccNo: Codeunit "Get G/L Account No. and Name";
        AdjustForPmtDisc: Boolean;

    procedure InsertMiniAppData()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        DemoDataSetup.Get();
        AdjustForPmtDisc := false; // CA
        InsertData2('', DemoDataSetup.ManufactCode(), '', '');
        InsertData2('', DemoDataSetup.RetailCode(), '', '');
        InsertData2('', DemoDataSetup.RawMatCode(), '', '');
        InsertData2('', DemoDataSetup.ServicesCode(), '', '');
        InsertData2('', DemoDataSetup.Zero(), '', '');
        InsertData2(DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), GetGLAccNo.SalesRetailDom(), GetGLAccNo.PurchRetailDom());
        InsertData2(DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), GetGLAccNo.SalesRawMaterialsDom(), GetGLAccNo.PurchRawMaterialsDom());
        InsertData2(DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), GetGLAccNo.SalesRetailDom(), GetGLAccNo.PurchRetailDom());
        InsertData2(DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), GetGLAccNo.SalesResourcesDom(), GetGLAccNo.PurchRetailDom());
        InsertData2(DemoDataSetup.DomesticCode(), DemoDataSetup.Zero(), GetGLAccNo.SalesRetailDom(), GetGLAccNo.PurchRetailDom());
        InsertData2(DemoDataSetup.ExportCode(), DemoDataSetup.ManufactCode(), GetGLAccNo.SalesRetailExport(), GetGLAccNo.PurchRetailExport());
        InsertData2(DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), GetGLAccNo.SalesRawMaterialsExport(), GetGLAccNo.PurchRawMaterialsExport());
        InsertData2(DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), GetGLAccNo.SalesRetailExport(), GetGLAccNo.PurchRetailExport());
        InsertData2(DemoDataSetup.ExportCode(), DemoDataSetup.ServicesCode(), GetGLAccNo.SalesResourcesExport(), GetGLAccNo.PurchRetailExport());
        InsertData2(DemoDataSetup.ExportCode(), DemoDataSetup.Zero(), GetGLAccNo.SalesRetailExport(), GetGLAccNo.PurchRetailExport());
        if GeneralPostingSetup.FindSet() then
            repeat
                if GeneralPostingSetup."Gen. Prod. Posting Group" = DemoDataSetup.RawMatCode() then begin
                    GeneralPostingSetup.Validate("Direct Cost Applied Account", GetGLAccNo.DirectCostAppliedRawmat());
                    GeneralPostingSetup.Validate("Overhead Applied Account", GetGLAccNo.OverheadAppliedRawmat());
                    GeneralPostingSetup.Validate("Purchase Variance Account", GetGLAccNo.PurchaseVarianceRawmat());
                end
                else begin
                    GeneralPostingSetup.Validate("Direct Cost Applied Account", GetGLAccNo.DirectCostAppliedRetail());
                    GeneralPostingSetup.Validate("Overhead Applied Account", GetGLAccNo.OverheadAppliedRetail());
                    GeneralPostingSetup.Validate("Purchase Variance Account", GetGLAccNo.PurchaseVarianceRetail());
                end;
                GeneralPostingSetup.Modify();
            until GeneralPostingSetup.Next() = 0;
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
                    GeneralPostingSetup.Validate("COGS Account (Interim)", CA.Convert('992132'));
                    GeneralPostingSetup.Validate("Inventory Adjmt. Account", CA.Convert('997270'));
                    GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", CA.Convert('995530'));
                end;
            DemoDataSetup.RetailCode(),
            DemoDataSetup.MiscCode(),
            DemoDataSetup.NoVATCode():
                begin
                    GeneralPostingSetup.Validate("COGS Account", CA.Convert('997190'));
                    GeneralPostingSetup.Validate("COGS Account (Interim)", CA.Convert('992112'));
                    GeneralPostingSetup.Validate("Inventory Adjmt. Account", CA.Convert('997170'));
                    GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", CA.Convert('995510'));
                end;
            DemoDataSetup.ServicesCode(),
            DemoDataSetup.FreightCode():
                begin
                    GeneralPostingSetup.Validate("COGS Account", CA.Convert('997190'));
                    GeneralPostingSetup.Validate("COGS Account (Interim)", CA.Convert('992112'));
                    GeneralPostingSetup.Validate("Inventory Adjmt. Account", CA.Convert('997170'));
                    GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", CA.Convert('995510'));
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
        if GeneralPostingSetup."Gen. Bus. Posting Group" = DemoDataSetup.DomesticCode() then
            case GeneralPostingSetup."Gen. Prod. Posting Group" of
                DemoDataSetup.MiscCode(),
                DemoDataSetup.RawMatCode(),
                DemoDataSetup.RetailCode(),
                DemoDataSetup.NoVATCode(),
                DemoDataSetup.ServicesCode():
                    begin
                        GeneralPostingSetup.Validate("Sales Prepayments Account", CA.Convert('995360'));
                        GeneralPostingSetup.Validate("Purch. Prepayments Account", CA.Convert('992410'));
                    end;
            end;
    end;

    local procedure UpdatePrepmtMiniAccounts()
    begin
        if GeneralPostingSetup."Gen. Bus. Posting Group" = DemoDataSetup.DomesticCode() then
            case GeneralPostingSetup."Gen. Prod. Posting Group" of
                DemoDataSetup.ManufactCode(),
                DemoDataSetup.RetailCode(),
                DemoDataSetup.Zero():
                    begin
                        GeneralPostingSetup.Validate("Sales Prepayments Account", GetGLAccNo.CustomerPrepaymentsRetail());
                        GeneralPostingSetup.Validate("Purch. Prepayments Account", GetGLAccNo.VendorPrepaymentsRetail());
                    end;
                DemoDataSetup.ServicesCode():
                    begin
                        GeneralPostingSetup.Validate("Sales Prepayments Account", GetGLAccNo.CustomerPrepaymentsServices());
                        GeneralPostingSetup.Validate("Purch. Prepayments Account", GetGLAccNo.VendorPrepaymentsServices());
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

    local procedure UpdateInvDiscMiniAccounts()
    begin
        if GeneralPostingSetup."Gen. Bus. Posting Group" <> '' then
            case GeneralPostingSetup."Gen. Prod. Posting Group" of
                DemoDataSetup.RawMatCode():
                    begin
                        GeneralPostingSetup.Validate("Sales Line Disc. Account", GetGLAccNo.DiscountGranted());
                        GeneralPostingSetup.Validate("Sales Inv. Disc. Account", GetGLAccNo.DiscountGranted());
                        GeneralPostingSetup.Validate("Purch. Line Disc. Account", GetGLAccNo.DiscReceivedRawMaterials());
                        GeneralPostingSetup.Validate("Purch. Inv. Disc. Account", GetGLAccNo.DiscReceivedRawMaterials());
                    end;

                DemoDataSetup.RetailCode(),
                DemoDataSetup.ManufactCode(),
                DemoDataSetup.Zero(),
                DemoDataSetup.ServicesCode():
                    begin
                        GeneralPostingSetup.Validate("Sales Line Disc. Account", GetGLAccNo.DiscountGranted());
                        GeneralPostingSetup.Validate("Sales Inv. Disc. Account", GetGLAccNo.DiscountGranted());
                        GeneralPostingSetup.Validate("Purch. Line Disc. Account", GetGLAccNo.DiscReceivedRetail());
                        GeneralPostingSetup.Validate("Purch. Inv. Disc. Account", GetGLAccNo.DiscReceivedRetail());
                    end;
            end;
    end;

    procedure InsertData2(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; SalesAccount: Code[20]; PurchaseAccount: Code[20])
    begin
        GeneralPostingSetup.Init();
        GeneralPostingSetup.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        GeneralPostingSetup.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GeneralPostingSetup.Validate("Sales Account", SalesAccount);
        GeneralPostingSetup.Validate("Purch. Account", PurchaseAccount);

        if GeneralPostingSetup."Gen. Bus. Posting Group" = DemoDataSetup.DomesticCode() then
            case GeneralPostingSetup."Gen. Prod. Posting Group" of
                DemoDataSetup.RawMatCode():
                    begin
                        GeneralPostingSetup.Validate("Sales Credit Memo Account", GetGLAccNo.SalesRawMaterialsDom());
                        GeneralPostingSetup.Validate("Purch. Credit Memo Account", GetGLAccNo.PurchRawMaterialsDom());
                        GeneralPostingSetup.Validate("COGS Account", GetGLAccNo.CostofRawMaterialsSold());
                        GeneralPostingSetup.Validate("COGS Account (Interim)", GetGLAccNo.CostofRawMatSoldInterim());
                        GeneralPostingSetup.Validate("Inventory Adjmt. Account", GetGLAccNo.InventoryAdjmtRawMat());
                        GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", GetGLAccNo.InvAdjmtInterimRawMat());
                    end;
                DemoDataSetup.RetailCode(),
                DemoDataSetup.ManufactCode(),
                DemoDataSetup.Zero():
                    begin
                        GeneralPostingSetup.Validate("Sales Credit Memo Account", GetGLAccNo.SalesRetailDom());
                        GeneralPostingSetup.Validate("Purch. Credit Memo Account", GetGLAccNo.PurchRetailDom());
                        GeneralPostingSetup.Validate("COGS Account", GetGLAccNo.CostofRetailSold());
                        GeneralPostingSetup.Validate("COGS Account (Interim)", GetGLAccNo.CostofResaleSoldInterim());
                        GeneralPostingSetup.Validate("Inventory Adjmt. Account", GetGLAccNo.InventoryAdjmtRetail());
                        GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", GetGLAccNo.InvAdjmtInterimRetail());
                    end;
                DemoDataSetup.ServicesCode():
                    begin
                        GeneralPostingSetup.Validate("Sales Credit Memo Account", GetGLAccNo.SalesResourcesDom());
                        GeneralPostingSetup.Validate("Purch. Credit Memo Account", GetGLAccNo.PurchRetailDom());
                        GeneralPostingSetup.Validate("COGS Account", GetGLAccNo.CostofRetailSold());
                        GeneralPostingSetup.Validate("COGS Account (Interim)", GetGLAccNo.CostofResaleSoldInterim());
                        GeneralPostingSetup.Validate("Inventory Adjmt. Account", GetGLAccNo.InventoryAdjmtRetail());
                        GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", GetGLAccNo.InvAdjmtInterimRetail());
                    end;
            end;
        UpdatePmtDiscAccounts();
        UpdatePmtTolAccounts();
        UpdatePrepmtMiniAccounts();
        UpdateInvDiscMiniAccounts();
        UpdateExportAcounts();
        UpdateProdPostingAccounts();
        GeneralPostingSetup.Insert();
    end;

    procedure UpdateExportAcounts()
    begin
        if GeneralPostingSetup."Gen. Bus. Posting Group" = DemoDataSetup.ExportCode() then
            case GeneralPostingSetup."Gen. Prod. Posting Group" of
                DemoDataSetup.RawMatCode():
                    begin
                        GeneralPostingSetup.Validate("Sales Credit Memo Account", GetGLAccNo.SalesRawMaterialsExport());
                        GeneralPostingSetup.Validate("Purch. Credit Memo Account", GetGLAccNo.PurchRawMaterialsExport());
                        GeneralPostingSetup.Validate("COGS Account", GetGLAccNo.CostofRawMaterialsSold());
                        GeneralPostingSetup.Validate("COGS Account (Interim)", GetGLAccNo.CostofRawMatSoldInterim());
                        GeneralPostingSetup.Validate("Inventory Adjmt. Account", GetGLAccNo.InventoryAdjmtRawMat());
                        GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", GetGLAccNo.InvAdjmtInterimRawMat());
                    end;
                DemoDataSetup.RetailCode(),
                DemoDataSetup.ManufactCode(),
                DemoDataSetup.Zero():
                    begin
                        GeneralPostingSetup.Validate("Sales Credit Memo Account", GetGLAccNo.SalesRetailExport());
                        GeneralPostingSetup.Validate("Purch. Credit Memo Account", GetGLAccNo.PurchRetailExport());
                        GeneralPostingSetup.Validate("COGS Account", GetGLAccNo.CostofRetailSold());
                        GeneralPostingSetup.Validate("COGS Account (Interim)", GetGLAccNo.CostofResaleSoldInterim());
                        GeneralPostingSetup.Validate("Inventory Adjmt. Account", GetGLAccNo.InventoryAdjmtRetail());
                        GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", GetGLAccNo.InvAdjmtInterimRetail());
                    end;
                DemoDataSetup.ServicesCode():
                    begin
                        GeneralPostingSetup.Validate("Sales Credit Memo Account", GetGLAccNo.SalesResourcesExport());
                        GeneralPostingSetup.Validate("Purch. Credit Memo Account", GetGLAccNo.PurchRetailExport());
                        GeneralPostingSetup.Validate("COGS Account", GetGLAccNo.CostofRetailSold());
                        GeneralPostingSetup.Validate("COGS Account (Interim)", GetGLAccNo.CostofResaleSoldInterim());
                        GeneralPostingSetup.Validate("Inventory Adjmt. Account", GetGLAccNo.InventoryAdjmtRetail());
                        GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", GetGLAccNo.InvAdjmtInterimRetail());
                    end;
            end;
    end;

    procedure UpdateProdPostingAccounts()
    begin
        if GeneralPostingSetup."Gen. Bus. Posting Group" = '' then
            case GeneralPostingSetup."Gen. Prod. Posting Group" of
                DemoDataSetup.RawMatCode():
                    begin
                        GeneralPostingSetup.Validate("COGS Account", GetGLAccNo.CostofRetailSold());
                        GeneralPostingSetup.Validate("COGS Account (Interim)", GetGLAccNo.CostofRawMatSoldInterim());
                        GeneralPostingSetup.Validate("Inventory Adjmt. Account", GetGLAccNo.InventoryAdjmtRawMat());
                        GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", GetGLAccNo.InvAdjmtInterimRawMat());
                    end;
                DemoDataSetup.RetailCode(),
                DemoDataSetup.ManufactCode(),
                DemoDataSetup.Zero(),
                DemoDataSetup.ServicesCode():
                    begin
                        GeneralPostingSetup.Validate("COGS Account", GetGLAccNo.CostofRetailSold());
                        GeneralPostingSetup.Validate("COGS Account (Interim)", GetGLAccNo.CostofResaleSoldInterim());
                        GeneralPostingSetup.Validate("Inventory Adjmt. Account", GetGLAccNo.InventoryAdjmtRetail());
                        GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", GetGLAccNo.InvAdjmtInterimRetail());
                    end;
            end;
    end;
}


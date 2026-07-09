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
        AdjustForPmtDisc: Boolean;

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        AdjustForPmtDisc := false;
        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '996110', '997110');
        InsertData(DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '996120', '997120');
        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '996130', '997130');
        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '996410', '997110');
        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.ServicesCode(), '996430', '997130');
        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '996110', '997110');
        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), '996130', '997130');
        InsertData('', DemoDataSetup.RetailCode(), '', '');
        InsertData('', DemoDataSetup.NoVATCode(), '', '');
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
                    GeneralPostingSetup.Validate("Direct Cost Applied Account", CA.Convert('997270'));
                end;
            DemoDataSetup.RetailCode(),
            DemoDataSetup.MiscCode(),
            DemoDataSetup.NoVATCode():
                begin
                    GeneralPostingSetup.Validate("COGS Account", CA.Convert('997190'));
                    GeneralPostingSetup.Validate("COGS Account (Interim)", CA.Convert('992112'));
                    GeneralPostingSetup.Validate("Inventory Adjmt. Account", CA.Convert('997170'));
                    GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", CA.Convert('995510'));
                    GeneralPostingSetup.Validate("Direct Cost Applied Account", CA.Convert('997170'));
                end;
            DemoDataSetup.ServicesCode(),
            DemoDataSetup.FreightCode():
                begin
                    GeneralPostingSetup.Validate("COGS Account", CA.Convert('997190'));
                    GeneralPostingSetup.Validate("COGS Account (Interim)", CA.Convert('992112'));
                    GeneralPostingSetup.Validate("Inventory Adjmt. Account", CA.Convert('997170'));
                    GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", CA.Convert('995510'));
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
                        GeneralPostingSetup.Validate("Sales Prepayments Account", CA.Convert('995370'));
                        GeneralPostingSetup.Validate("Purch. Prepayments Account", CA.Convert('992420'));
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
}


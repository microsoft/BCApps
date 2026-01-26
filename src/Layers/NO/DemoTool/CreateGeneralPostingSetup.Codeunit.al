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
        InsertData(XCUSTDOM, DemoDataSetup.MiscCode(), '996210', '');
        InsertData(XCUSTDOM, DemoDataSetup.NoVATCode(), '996210', '');
        InsertData(XCUSTDOM, DemoDataSetup.RawMatCode(), '996210', '');
        InsertData(XCUSTDOM, DemoDataSetup.RetailCode(), '996110', '');
        InsertData(XCUSTDOM, DemoDataSetup.ServicesCode(), '996410', '');
        InsertData(XCUSTFOR, DemoDataSetup.MiscCode(), '996210', '');
        InsertData(XCUSTFOR, DemoDataSetup.NoVATCode(), '996210', '');
        InsertData(XCUSTFOR, DemoDataSetup.RawMatCode(), '996230', '');
        InsertData(XCUSTFOR, DemoDataSetup.RetailCode(), '996130', '');
        InsertData(XCUSTFOR, DemoDataSetup.ServicesCode(), '996430', '');
        InsertData(XVENDDOM, DemoDataSetup.MiscCode(), '', '997110');
        InsertData(XVENDDOM, DemoDataSetup.NoVATCode(), '', '997110');
        InsertData(XVENDDOM, DemoDataSetup.RawMatCode(), '', '997110');
        InsertData(XVENDDOM, DemoDataSetup.RetailCode(), '', '997110');
        InsertData(XVENDDOM, DemoDataSetup.ServicesCode(), '', '997110');
        InsertData(XVENDFOR, DemoDataSetup.MiscCode(), '', '997130');
        InsertData(XVENDFOR, DemoDataSetup.NoVATCode(), '', '997230');
        InsertData(XVENDFOR, DemoDataSetup.RawMatCode(), '', '997230');
        InsertData(XVENDFOR, DemoDataSetup.RetailCode(), '', '997130');
        InsertData(XVENDFOR, DemoDataSetup.ServicesCode(), '', '997130');
    end;

    var
        GeneralPostingSetup: Record "General Posting Setup";
        DemoDataSetup: Record "Demo Data Setup";
        CA: Codeunit "Make Adjustments";
        AdjustForPmtDisc: Boolean;
        XCUSTDOM: Label 'CUSTDOM';
        XCUSTFOR: Label 'CUSTFOR';
        XVENDDOM: Label 'VENDDOM';
        XVENDFOR: Label 'VENDFOR';

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        AdjustForPmtDisc := false;
        InsertData(XCUSTDOM, DemoDataSetup.RetailCode(), '996110', '');
        InsertData(XCUSTDOM, DemoDataSetup.ServicesCode(), '996410', '');
        InsertData(XCUSTDOM, DemoDataSetup.NoVATCode(), '996210', '');
        InsertData(XCUSTFOR, DemoDataSetup.RetailCode(), '996130', '');
        InsertData(XCUSTFOR, DemoDataSetup.ServicesCode(), '996430', '');
        InsertData(XCUSTFOR, DemoDataSetup.NoVATCode(), '996210', '');
        InsertData(XVENDDOM, DemoDataSetup.RetailCode(), '', '997110');
        InsertData(XVENDDOM, DemoDataSetup.ServicesCode(), '', '997110');
        InsertData(XVENDDOM, DemoDataSetup.NoVATCode(), '', '997110');
        InsertData(XVENDFOR, DemoDataSetup.RetailCode(), '', '997130');
        InsertData(XVENDFOR, DemoDataSetup.ServicesCode(), '', '997130');
        InsertData(XVENDFOR, DemoDataSetup.NoVATCode(), '', '997230');
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
    end;

    local procedure UpdatePrepmtAccounts()
    begin
        if DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::Extended then
            exit;

        if GeneralPostingSetup."Gen. Bus. Posting Group" in [XCUSTDOM, XVENDDOM, XCUSTFOR, XVENDFOR] then
            case GeneralPostingSetup."Gen. Prod. Posting Group" of
                DemoDataSetup.MiscCode(),
                DemoDataSetup.NoVATCode(),
                DemoDataSetup.RawMatCode(),
                DemoDataSetup.RetailCode(),
                DemoDataSetup.ServicesCode():
                    begin
                        GeneralPostingSetup.Validate("Sales Prepayments Account", CA.Convert('995350'));
                        GeneralPostingSetup.Validate("Purch. Prepayments Account", CA.Convert('992400'));
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


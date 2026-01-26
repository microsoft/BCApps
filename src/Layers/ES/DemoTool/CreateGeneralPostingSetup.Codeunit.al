codeunit 101252 "Create General Posting Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        AdjustForPmtDisc := true;
        InsertData('', DemoDataSetup.MiscCode(), '', '');
        InsertData('', DemoDataSetup.NoVATCode(), '', '');
        InsertData('', DemoDataSetup.RawMatCode(), '', '');
        InsertData('', DemoDataSetup.RetailCode(), '', '');
        InsertData('', DemoDataSetup.ServicesCode(), '', '');
        InsertData('', DemoDataSetup.ManufactCode(), '', '');
        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), '', '');
        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '');
        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.RawMatCode(), '996210', '997210');
        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), '996110', '997110');
        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), '996410', '');
        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.ManufactCode(), '996110', '997110');
        InsertData(DemoDataSetup.EUCode(), DemoDataSetup.MiscCode(), '', '');
        InsertData(DemoDataSetup.EUCode(), DemoDataSetup.NoVATCode(), '', '');
        InsertData(DemoDataSetup.EUCode(), DemoDataSetup.RawMatCode(), '996220', '997220');
        InsertData(DemoDataSetup.EUCode(), DemoDataSetup.RetailCode(), '996120', '997120');
        InsertData(DemoDataSetup.EUCode(), DemoDataSetup.ServicesCode(), '996420', '');
        InsertData(DemoDataSetup.EUCode(), DemoDataSetup.ManufactCode(), '996120', '997120');
        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.MiscCode(), '', '');
        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), '', '');
        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.RawMatCode(), '996230', '997230');
        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.RetailCode(), '996130', '997130');
        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.ServicesCode(), '996430', '');
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
        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.ServicesCode(), '996430', '');
        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), '', '');
        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), '', '');
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
        UpdateJobAccounts();

        case GeneralPostingSetup."Gen. Prod. Posting Group" of
            DemoDataSetup.RawMatCode():
                begin
                    GeneralPostingSetup.Validate("COGS Account", CA.Convert('997290'));
                    GeneralPostingSetup.Validate("COGS Account (Interim)", CA.Convert('992131'));
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
        if AdjustForPmtDisc then
            case GeneralPostingSetup."Gen. Prod. Posting Group" of
                DemoDataSetup.RawMatCode():
                    if GeneralPostingSetup."Gen. Bus. Posting Group" <> '' then
                        case GeneralPostingSetup."Gen. Bus. Posting Group" of
                            DemoDataSetup.DomesticCode():
                                begin
                                    GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", CA.Convert('7063001'));
                                    GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", CA.Convert('6061001'));
                                end;
                            DemoDataSetup.EUCode():
                                begin
                                    GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", CA.Convert('7063002'));
                                    GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", CA.Convert('6061002'));
                                end;
                            DemoDataSetup.ExportCode():
                                begin
                                    GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", CA.Convert('7063003'));
                                    GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", CA.Convert('6061002'));
                                end;
                        end;
                DemoDataSetup.RetailCode():
                    if GeneralPostingSetup."Gen. Bus. Posting Group" <> '' then
                        case GeneralPostingSetup."Gen. Bus. Posting Group" of
                            DemoDataSetup.DomesticCode():
                                begin
                                    GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", CA.Convert('7060001'));
                                    GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", CA.Convert('6060001'));
                                end;
                            DemoDataSetup.EUCode():
                                begin
                                    GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", CA.Convert('7060002'));
                                    GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", CA.Convert('6060002'));
                                end;
                            DemoDataSetup.ExportCode():
                                begin
                                    GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", CA.Convert('7060003'));
                                    GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", CA.Convert('6060003'));
                                end;
                        end;
                DemoDataSetup.MiscCode(),
              DemoDataSetup.NoVATCode(),
              DemoDataSetup.ServicesCode(),
              DemoDataSetup.FreightCode():
                    if GeneralPostingSetup."Gen. Bus. Posting Group" <> '' then
                        case GeneralPostingSetup."Gen. Bus. Posting Group" of
                            DemoDataSetup.DomesticCode():
                                begin
                                    GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", CA.Convert('7060001'));
                                    GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", CA.Convert('6062001'));
                                end;
                            DemoDataSetup.EUCode():
                                begin
                                    GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", CA.Convert('7060002'));
                                    GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", CA.Convert('6062002'));
                                end;
                            DemoDataSetup.ExportCode():
                                begin
                                    GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", CA.Convert('7060003'));
                                    GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", CA.Convert('6062003'));
                                end;
                        end;
                DemoDataSetup.ManufactCode():
                    if GeneralPostingSetup."Gen. Bus. Posting Group" <> '' then
                        case GeneralPostingSetup."Gen. Bus. Posting Group" of
                            DemoDataSetup.DomesticCode():
                                begin
                                    GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", CA.Convert('7062001'));
                                    GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", CA.Convert('6061001'));
                                end;
                            DemoDataSetup.EUCode():
                                begin
                                    GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", CA.Convert('7062002'));
                                    GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", CA.Convert('6061002'));
                                end;
                            DemoDataSetup.ExportCode():
                                begin
                                    GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", CA.Convert('7062003'));
                                    GeneralPostingSetup.Validate("Purch. Pmt. Disc. Credit Acc.", CA.Convert('6061003'));
                                end;
                        end;
            end;
    end;

    local procedure UpdatePmtTolAccounts()
    begin
    end;

    local procedure UpdatePrepmtAccounts()
    begin
        if DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::Extended then
            exit;

        case GeneralPostingSetup."Gen. Bus. Posting Group" of
            DemoDataSetup.DomesticCode():
                begin
                    GeneralPostingSetup.Validate("Sales Prepayments Account", CA.Convert('4380001'));
                    GeneralPostingSetup.Validate("Purch. Prepayments Account", CA.Convert('4070001'));
                end;
            DemoDataSetup.EUCode():
                begin
                    GeneralPostingSetup.Validate("Sales Prepayments Account", CA.Convert('4380002'));
                    GeneralPostingSetup.Validate("Purch. Prepayments Account", CA.Convert('4070002'));
                end;
            DemoDataSetup.ExportCode():
                begin
                    GeneralPostingSetup.Validate("Sales Prepayments Account", CA.Convert('4380003'));
                    GeneralPostingSetup.Validate("Purch. Prepayments Account", CA.Convert('4070003'));
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

    local procedure UpdateJobAccounts()
    begin
        case GeneralPostingSetup."Gen. Prod. Posting Group" of
            DemoDataSetup.RawMatCode():
                begin
                    GeneralPostingSetup.Validate("Job Sales Adjmt. Account", CA.Convert('996290'));
                    GeneralPostingSetup.Validate("Job Cost Adjmt. Account", CA.Convert('997280'));
                end;
            DemoDataSetup.RetailCode(),
            DemoDataSetup.MiscCode(),
            DemoDataSetup.NoVATCode():
                begin
                    GeneralPostingSetup.Validate("Job Sales Adjmt. Account", CA.Convert('996190'));
                    GeneralPostingSetup.Validate("Job Cost Adjmt. Account", CA.Convert('997180'));
                end;
            DemoDataSetup.ServicesCode(),
            DemoDataSetup.FreightCode():
                begin
                    GeneralPostingSetup.Validate("Job Sales Adjmt. Account", CA.Convert('996490'));
                    GeneralPostingSetup.Validate("Job Cost Adjmt. Account", CA.Convert('997480'));
                end;
        end;
    end;
}


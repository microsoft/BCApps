codeunit 101325 "Create VAT Posting Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        case DemoDataSetup."Company Type" of
            DemoDataSetup."Company Type"::VAT:
                begin
                    // NAVCZ
                    InsertData('', DemoDataSetup.NoVATCode(), 0, 0, '');
                    InsertData('', DemoDataSetup.SecondReducedVATItemCode(), 0, 0, '');
                    InsertData('', DemoDataSetup.SecondReducedVATServiceCode(), 0, 0, '');
                    InsertData('', DemoDataSetup.FirstReducedVATItemCode(), 0, 0, '');
                    InsertData('', DemoDataSetup.FirstReducedVATServiceCode(), 0, 0, '');
                    InsertData('', DemoDataSetup.BaseVATItemCode(), 0, 0, '');
                    InsertData('', DemoDataSetup.BaseVATServiceCode(), 0, 0, '');
                    InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), 0, 0, '');
                    InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.SecondReducedVATItemCode(), DemoDataSetup.SecondReducedVATRate(), 0, '');
                    InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.SecondReducedVATServiceCode(), DemoDataSetup.SecondReducedVATRate(), 0, '');
                    InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.FirstReducedVATItemCode(), DemoDataSetup.FirstReducedVATRate(), 0, '');
                    InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.FirstReducedVATServiceCode(), DemoDataSetup.FirstReducedVATRate(), 0, '');
                    InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.FirstReducedVATReverseChargeCode(), DemoDataSetup.FirstReducedVATRate(), 1, '');
                    InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.BaseVATItemCode(), DemoDataSetup.BaseVATRate(), 0, '');
                    InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.BaseVATServiceCode(), DemoDataSetup.BaseVATRate(), 0, '');
                    InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.BaseVATReverseChargeCode(), DemoDataSetup.BaseVATRate(), 1, '');
                    InsertData(DemoDataSetup.EUCode(), DemoDataSetup.NoVATCode(), 0, 0, '');
                    InsertData(DemoDataSetup.EUCode(), DemoDataSetup.SecondReducedVATItemCode(), DemoDataSetup.SecondReducedVATRate(), 1, '');
                    InsertData(DemoDataSetup.EUCode(), DemoDataSetup.SecondReducedVATServiceCode(), DemoDataSetup.SecondReducedVATRate(), 1, '');
                    InsertData(DemoDataSetup.EUCode(), DemoDataSetup.FirstReducedVATItemCode(), DemoDataSetup.FirstReducedVATRate(), 1, '');
                    InsertData(DemoDataSetup.EUCode(), DemoDataSetup.FirstReducedVATServiceCode(), DemoDataSetup.FirstReducedVATRate(), 1, '');
                    InsertData(DemoDataSetup.EUCode(), DemoDataSetup.BaseVATItemCode(), DemoDataSetup.BaseVATRate(), 1, '');
                    InsertData(DemoDataSetup.EUCode(), DemoDataSetup.BaseVATServiceCode(), DemoDataSetup.BaseVATRate(), 1, '');
                    InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), 0, 0, '');
                    InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.SecondReducedVATItemCode(), 0, 0, '');
                    InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.SecondReducedVATServiceCode(), DemoDataSetup.SecondReducedVATRate(), 0, '');
                    InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.FirstReducedVATItemCode(), 0, 0, '');
                    InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.FirstReducedVATServiceCode(), DemoDataSetup.FirstReducedVATRate(), 0, '');
                    InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.BaseVATItemCode(), 0, 0, '');
                    InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.BaseVATServiceCode(), DemoDataSetup.BaseVATRate(), 0, '');
                    InsertData(DemoDataSetup.NPCode(), DemoDataSetup.NoVATCode(), 0, 0, '');
                    InsertData(DemoDataSetup.NPCode(), DemoDataSetup.SecondReducedVATItemCode(), DemoDataSetup.SecondReducedVATRate(), 0, '');
                    InsertData(DemoDataSetup.NPCode(), DemoDataSetup.SecondReducedVATServiceCode(), DemoDataSetup.SecondReducedVATRate(), 0, '');
                    InsertData(DemoDataSetup.NPCode(), DemoDataSetup.FirstReducedVATItemCode(), DemoDataSetup.FirstReducedVATRate(), 0, '');
                    InsertData(DemoDataSetup.NPCode(), DemoDataSetup.FirstReducedVATServiceCode(), DemoDataSetup.FirstReducedVATRate(), 0, '');
                    InsertData(DemoDataSetup.NPCode(), DemoDataSetup.FirstReducedVATReverseChargeCode(), DemoDataSetup.FirstReducedVATRate(), 1, '');
                    InsertData(DemoDataSetup.NPCode(), DemoDataSetup.BaseVATItemCode(), DemoDataSetup.BaseVATRate(), 0, '');
                    InsertData(DemoDataSetup.NPCode(), DemoDataSetup.BaseVATServiceCode(), DemoDataSetup.BaseVATRate(), 0, '');
                    InsertData(DemoDataSetup.NPCode(), DemoDataSetup.BaseVATReverseChargeCode(), DemoDataSetup.BaseVATRate(), 1, '');
                    // NAVCZ
                end;
            DemoDataSetup."Company Type"::"Sales Tax":
                InsertSalesTaxData('E');
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        CA: Codeunit "Make Adjustments";
        XPostingSetupTxt: Label 'Setup for %1 / %2', Comment = '%1 = Business Group; %2 = Product Group';

    procedure InsertSalesTaxData(TaxCategory: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Bus. Posting Group", '');
        VATPostingSetup.Validate("VAT Prod. Posting Group", '');
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Validate("Tax Category", TaxCategory);
        VATPostingSetup.Insert();
    end;

    procedure InsertData("VAT Bus. Posting Group": Code[20]; "VAT Prod. Posting Group": Code[20]; "VAT %": Decimal; "VAT Calculation Type": Option; TaxCategory: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Bus. Posting Group", "VAT Bus. Posting Group");
        VATPostingSetup.Validate("VAT Prod. Posting Group", "VAT Prod. Posting Group");
        VATPostingSetup.Validate(Description,
          CopyStr(
            StrSubstNo(XPostingSetupTxt, "VAT Bus. Posting Group", "VAT Prod. Posting Group"),
            1, MaxStrLen(VATPostingSetup.Description)));
        VATPostingSetup.Validate("VAT %", "VAT %");
        VATPostingSetup.Validate("VAT Calculation Type", "VAT Calculation Type");
        VATPostingSetup.Validate("Tax Category", TaxCategory);
        VATPostingSetup.Validate("Adjust for Payment Discount", DemoDataSetup."Adjust for Payment Discount");
        if DemoDataSetup."Advanced Setup" then
            VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup."VAT Identifier" := VATPostingSetup."VAT Prod. Posting Group"; // NAVCZ

        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then
            case VATPostingSetup."VAT Prod. Posting Group" of
                // NAVCZ
                DemoDataSetup.BaseVATItemCode(),
                DemoDataSetup.BaseVATServiceCode(),
                DemoDataSetup.BaseVATReverseChargeCode():
                    begin
                        SetAccounts(VATPostingSetup, '995610', '995630', '995620', '995615', '995635', '995625');
                        VATPostingSetup."VAT Rate CZL" := VATPostingSetup."VAT Rate CZL"::Base;
                        if VATPostingSetup."VAT Prod. Posting Group" in [DemoDataSetup.BaseVATServiceCode(), DemoDataSetup.BaseVATItemCode()] then
                            case VATPostingSetup."VAT Bus. Posting Group" of
                                DemoDataSetup.DomesticCode(), '':
                                    begin
                                        VATPostingSetup."Sales Adv. Letter VAT Acc. CZZ" := CA.Convert('995640');
                                        VATPostingSetup."Sales Adv. Letter Account CZZ" := CA.Convert('995360');
                                        VATPostingSetup."Purch. Adv.Letter VAT Acc. CZZ" := CA.Convert('995640');
                                        VATPostingSetup."Purch. Adv. Letter Account CZZ" := CA.Convert('992410');
                                    end;
                                DemoDataSetup.EUCode():
                                    begin
                                        VATPostingSetup."Sales Adv. Letter VAT Acc. CZZ" := CA.Convert('995640');
                                        VATPostingSetup."Sales Adv. Letter Account CZZ" := CA.Convert('995370');
                                        VATPostingSetup."Purch. Adv.Letter VAT Acc. CZZ" := CA.Convert('995640');
                                        VATPostingSetup."Purch. Adv. Letter Account CZZ" := CA.Convert('992420');
                                    end;
                            end;

                        if (VATPostingSetup."VAT Bus. Posting Group" = DemoDataSetup.NPCode()) and
                           (VATPostingSetup."VAT Prod. Posting Group" = DemoDataSetup.BaseVATItemCode())
                        then begin
                            VATPostingSetup."Sales Adv. Letter VAT Acc. CZZ" := CA.Convert('995640');
                            VATPostingSetup."Sales Adv. Letter Account CZZ" := CA.Convert('995360');
                            VATPostingSetup."Purch. Adv.Letter VAT Acc. CZZ" := CA.Convert('995640');
                            VATPostingSetup."Purch. Adv. Letter Account CZZ" := CA.Convert('992410');
                        end;
                    end;
                DemoDataSetup.FirstReducedVATItemCode(),
                DemoDataSetup.FirstReducedVATServiceCode(),
                DemoDataSetup.FirstReducedVATReverseChargeCode():
                    begin
                        SetAccounts(VATPostingSetup, '995613', '995636', '995622', '995613', '995636', '995613');
                        VATPostingSetup."VAT Rate CZL" := VATPostingSetup."VAT Rate CZL"::Reduced;
                        if VATPostingSetup."VAT Prod. Posting Group" in [DemoDataSetup.FirstReducedVATServiceCode(), DemoDataSetup.FirstReducedVATItemCode()] then
                            case VATPostingSetup."VAT Bus. Posting Group" of
                                DemoDataSetup.DomesticCode(), '':
                                    begin
                                        VATPostingSetup."Sales Adv. Letter VAT Acc. CZZ" := CA.Convert('995641');
                                        VATPostingSetup."Sales Adv. Letter Account CZZ" := CA.Convert('995360');
                                        VATPostingSetup."Purch. Adv.Letter VAT Acc. CZZ" := CA.Convert('995641');
                                        VATPostingSetup."Purch. Adv. Letter Account CZZ" := CA.Convert('992410');
                                    end;
                                DemoDataSetup.EUCode():
                                    begin
                                        VATPostingSetup."Sales Adv. Letter VAT Acc. CZZ" := CA.Convert('995641');
                                        VATPostingSetup."Sales Adv. Letter Account CZZ" := CA.Convert('995370');
                                        VATPostingSetup."Purch. Adv.Letter VAT Acc. CZZ" := CA.Convert('995641');
                                        VATPostingSetup."Purch. Adv. Letter Account CZZ" := CA.Convert('992420');
                                    end;
                            end;

                        if (VATPostingSetup."VAT Bus. Posting Group" = DemoDataSetup.NPCode()) and
                           (VATPostingSetup."VAT Prod. Posting Group" = DemoDataSetup.FirstReducedVATItemCode())
                        then begin
                            VATPostingSetup."Sales Adv. Letter VAT Acc. CZZ" := CA.Convert('995641');
                            VATPostingSetup."Sales Adv. Letter Account CZZ" := CA.Convert('995360');
                            VATPostingSetup."Purch. Adv.Letter VAT Acc. CZZ" := CA.Convert('995641');
                            VATPostingSetup."Purch. Adv. Letter Account CZZ" := CA.Convert('992410');
                        end;
                    end;
                DemoDataSetup.SecondReducedVATItemCode(),
                DemoDataSetup.SecondReducedVATServiceCode():
                    begin
                        SetAccounts(VATPostingSetup, '995611', '995631', '995621', '995616', '995631', '995626');
                        VATPostingSetup."VAT Rate CZL" := VATPostingSetup."VAT Rate CZL"::"Reduced 2";
                    end;
                DemoDataSetup.NoVATCode():
                    SetAccounts(VATPostingSetup, '995610', '995630', '995620', '995615', '995635', '995625');
            // NAVCZ
            end;

        // NAVCZ
        if (VATPostingSetup."VAT Bus. Posting Group" = DemoDataSetup.EUCode()) and
           (VATPostingSetup."VAT Prod. Posting Group" in [DemoDataSetup.BaseVATServiceCode(), DemoDataSetup.FirstReducedVATServiceCode(), DemoDataSetup.SecondReducedVATServiceCode()])
        then
            VATPostingSetup.Validate("EU Service", true);

        if ((VATPostingSetup."VAT Bus. Posting Group" = DemoDataSetup.EUCode()) and
            (VATPostingSetup."VAT Prod. Posting Group" <> DemoDataSetup.NoVATCode())) or
           ((VATPostingSetup."VAT Bus. Posting Group" = DemoDataSetup.ExportCode()) and
            (VATPostingSetup."VAT Prod. Posting Group" = DemoDataSetup.NoVATCode()))
        then
            VATPostingSetup."VIES Sales CZL" := true;

        if (VATPostingSetup."VAT Bus. Posting Group" = DemoDataSetup.DomesticCode()) and
           not (VATPostingSetup."VAT Prod. Posting Group" in [DemoDataSetup.NoVATCode(), DemoDataSetup.FirstReducedVATReverseChargeCode(), DemoDataSetup.BaseVATReverseChargeCode()])
        then
            VATPostingSetup."Purch. VAT Curr. Exch. Acc CZL" := '343880';
        // NAVCZ

        VATPostingSetup.Insert();
    end;

    local procedure SetAccounts(var VATPostingSetup: Record "VAT Posting Setup"; SalesVATAccount: Code[20]; PurchaseVATAccount: Code[20]; ReverseChargeVATAcc: Code[20]; SalesVATUnrealAccount: Code[20]; PurchaseVATUnrealAccount: Code[20]; ReverseChargeVATUnrealAcc: Code[20])
    begin
        VATPostingSetup.Validate("Sales VAT Account", CA.Convert(SalesVATAccount));
        VATPostingSetup.Validate("Purchase VAT Account", CA.Convert(PurchaseVATAccount));
        if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
            VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", CA.Convert(ReverseChargeVATAcc));
        if VATPostingSetup."Unrealized VAT Type" > 0 then begin
            VATPostingSetup.Validate("Sales VAT Unreal. Account", CA.Convert(SalesVATUnrealAccount));
            VATPostingSetup.Validate("Purch. VAT Unreal. Account", CA.Convert(PurchaseVATUnrealAccount));
            if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
                VATPostingSetup.Validate("Reverse Chrg. VAT Unreal. Acc.", CA.Convert(ReverseChargeVATUnrealAcc));
        end;
    end;
}


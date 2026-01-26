codeunit 101325 "Create VAT Posting Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        case DemoDataSetup."Company Type" of
            DemoDataSetup."Company Type"::VAT:
                begin
                    InsertData(XCC, XS0, 0, 1, '', '', 'E');
                    InsertData(XCC, XS1, 6, 1, '', '995520', 'S');
                    InsertData(XCC, XS3, 21, 1, '', '995520', 'S');
                    InsertData(DemoDataSetup.EUCode(), XG0, 0, 1, '', '', 'E');
                    InsertData(DemoDataSetup.EUCode(), XG1, 6, 1, '', '995520', 'S');
                    InsertData(DemoDataSetup.EUCode(), XG2, 12, 1, '', '995520', 'S');
                    InsertData(DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), DemoDataSetup."Goods VAT Rate", 1, '', '995520', 'S');
                    InsertData(DemoDataSetup.EUCode(), XI0, 0, 1, '', '', 'E');
                    InsertData(DemoDataSetup.EUCode(), XI3, 21, 1, '', '995520', 'S');
                    InsertData(DemoDataSetup.EUCode(), XS0, 0, 1, '', '', 'E');
                    InsertData(DemoDataSetup.EUCode(), XS1, 6, 1, '', '995520', 'S');
                    InsertData(DemoDataSetup.EUCode(), XS3, 21, 1, '', '995520', 'S');
                    InsertData(XIMPEXP, XG0, 0, 0, '', '', 'E');
                    InsertData(XIMPEXP, XG1, 0, 0, '', '', 'E');
                    InsertData(XIMPEXP, XG2, 0, 0, '', '', 'E');
                    InsertData(XIMPEXP, DemoDataSetup.GoodsVATCode(), 0, 0, '', '', 'E');
                    InsertData(XIMPEXP, XI0, 0, 0, '', '', 'E');
                    InsertData(XIMPEXP, XI3, 0, 0, '', '', 'E');
                    InsertData(XIMPEXP, XS0, 0, 0, '', '', 'E');
                    InsertData(XIMPEXP, XS1, 0, 0, '', '', 'E');
                    InsertData(XIMPEXP, XS3, 0, 0, '', '', 'E');
                    InsertData(XIMPREV, XG0, 0, 1, '', '', 'E');
                    InsertData(XIMPREV, XG1, 6, 1, '', '995520', 'S');
                    InsertData(XIMPREV, XG2, 12, 1, '', '995520', 'S');
                    InsertData(XIMPREV, DemoDataSetup.GoodsVATCode(), DemoDataSetup."Goods VAT Rate", 1, '', '995520', 'S');
                    InsertData(XIMPREV, XI0, 0, 1, '', '', 'E');
                    InsertData(XIMPREV, XI3, 21, 1, '', '995520', 'S');
                    InsertData(XIMPREV, XS0, 0, 0, '', '', 'E');
                    InsertData(XIMPREV, XS1, 6, 1, '', '995520', 'S');
                    InsertData(XIMPREV, XS3, 21, 1, '', '995520', 'S');
                    InsertData(DemoDataSetup.DomesticCode(), XG0, 0, 0, '', '', 'E');
                    InsertData(DemoDataSetup.DomesticCode(), XG1, 6, 0, '995510', '995520', 'S');
                    InsertData(DemoDataSetup.DomesticCode(), XG2, 12, 0, '995510', '995520', 'S');
                    InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), DemoDataSetup."Goods VAT Rate", 0, '995510', '995520', 'S');
                    InsertData(DemoDataSetup.DomesticCode(), XI0, 0, 0, '', '', 'E');
                    InsertData(DemoDataSetup.DomesticCode(), XI3, 21, 0, '995510', '995520', 'S');
                    InsertData(DemoDataSetup.DomesticCode(), XS0, 0, 0, '', '', 'E');
                    InsertData(DemoDataSetup.DomesticCode(), XS1, 6, 0, '995510', '995520', 'S');
                    InsertData(DemoDataSetup.DomesticCode(), XS3, 21, 0, '995510', '995520', 'S');
                    InsertData(DemoDataSetup.DomesticCode(), XVAT, 0, 2, '995510', '995520', 'E');
                end;
            DemoDataSetup."Company Type"::"Sales Tax":
                InsertSalesTaxData('E');
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        CA: Codeunit "Make Adjustments";
        XPostingSetupTxt: Label 'Setup for %1 / %2', Comment = '%1 = Business Group; %2 = Product Group';
        XCC: Label 'CC';
        XIMPEXP: Label 'IMPEXP';
        XIMPREV: Label 'IMPREV';
        XG0: Label 'G0';
        XG1: Label 'G1';
        XG2: Label 'G2';
        XS0: Label 'S0';
        XS1: Label 'S1';
        XS3: Label 'S3';
        XI0: Label 'I0';
        XI3: Label 'I3';
        XVAT: Label 'VAT';

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

    procedure InsertData("VAT Bus. Posting Group": Code[20]; "VAT Prod. Posting Group": Code[20]; "VAT %": Decimal; "VAT Calculation Type": Option; "Sales Account": Code[20]; "Purchase Account": Code[20]; TaxCategory: Code[10])
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
        VATPostingSetup."VAT Identifier" := VATPostingSetup."VAT Prod. Posting Group";
        VATPostingSetup.Validate("Tax Category", TaxCategory);
        VATPostingSetup.Validate("Adjust for Payment Discount", DemoDataSetup."Adjust for Payment Discount");
        if DemoDataSetup."Advanced Setup" then
            VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Sales VAT Account", CA.Convert('995510'));
        VATPostingSetup.Validate("Purchase VAT Account", CA.Convert('995520'));
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", CA.Convert('995520'));

        VATPostingSetup.Insert();
    end;
}


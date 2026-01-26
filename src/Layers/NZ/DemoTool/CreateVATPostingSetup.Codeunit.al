codeunit 101325 "Create VAT Posting Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        case DemoDataSetup."Company Type" of
            DemoDataSetup."Company Type"::VAT:
                begin
                    InsertData('', DemoDataSetup.ServicesVATCode(), 0, 0, '995611', '995621', 'E');
                    InsertData('', DemoDataSetup.GoodsVATCode(), 0, 0, '995615', '995625', 'E');
                    InsertData('', DemoDataSetup.NoVATCode(), 0, 0, '995615', '995625', 'E');
                    InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), 9, 0, '995611', '995621', 'S');
                    InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), 15, 0, '995615', '995625', 'S');
                    InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), 0, 0, '995615', '995625', 'E');
                    InsertData(DemoDataSetup.MiscCode(), DemoDataSetup.ServicesVATCode(), 9, 0, '995611', '995621', 'S');
                    InsertData(DemoDataSetup.MiscCode(), DemoDataSetup.GoodsVATCode(), 15, 0, '995615', '995625', 'S');
                    InsertData(DemoDataSetup.MiscCode(), DemoDataSetup.NoVATCode(), 0, 0, '995615', '995625', 'E');
                    InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), 0, 0, '995611', '995621', 'E');
                    InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), 0, 0, '995615', '995625', 'E');
                    InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), 0, 0, '995615', '995625', 'E');
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

        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then
            case VATPostingSetup."VAT Prod. Posting Group" of
                DemoDataSetup.ServicesVATCode(),
                DemoDataSetup.GoodsVATCode(),
                DemoDataSetup.NoVATCode():
                    begin
                        VATPostingSetup.Validate("Sales VAT Account", CA.Convert("Sales Account"));
                        VATPostingSetup.Validate("Purchase VAT Account", CA.Convert("Purchase Account"));
                        if "VAT Calculation Type" = 1 then
                            VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", CA.Convert(''));
                        if VATPostingSetup."Unrealized VAT Type" > 0 then begin
                            VATPostingSetup.Validate("Sales VAT Unreal. Account", CA.Convert('995613'));
                            VATPostingSetup.Validate("Purch. VAT Unreal. Account", CA.Convert('995623'));
                            if "VAT Calculation Type" = 1 then
                                VATPostingSetup.Validate("Reverse Chrg. VAT Unreal. Acc.", CA.Convert(''));
                        end;
                    end;
            end;

        VATPostingSetup.Insert();
    end;
}


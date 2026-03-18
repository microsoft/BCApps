codeunit 101325 "Create VAT Posting Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        case DemoDataSetup."Company Type" of
            DemoDataSetup."Company Type"::VAT:
                begin
                    if DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::Extended then
                        InsertData('', '', 0, 0, 'E');
                    InsertData('', DemoDataSetup.ServicesVATCode(), 0, 0, 'E');
                    InsertData('', DemoDataSetup.GoodsVATCode(), 0, 0, 'E');
                    if DemoDataSetup."Reduced VAT Rate" > 0 then
                        InsertData('', DemoDataSetup.ReducedVATCode(), 0, 0, 'E');
                    InsertData('', DemoDataSetup.NoVATCode(), 0, 0, 'E');
                    InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), DemoDataSetup."Services VAT Rate", 0, 'S');
                    InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), DemoDataSetup."Goods VAT Rate", 0, 'S');
                    InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), 0, 0, 'E');
                    InsertData(DemoDataSetup.EUCode(), DemoDataSetup.ServicesVATCode(), DemoDataSetup."Services VAT Rate", 1, 'S');
                    InsertData(DemoDataSetup.EUCode(), DemoDataSetup.GoodsVATCode(), DemoDataSetup."Goods VAT Rate", 1, 'S');
                    InsertData(DemoDataSetup.EUCode(), DemoDataSetup.NoVATCode(), 0, 0, 'E');
                    InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), 0, 0, 'E');
                    InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), 0, 0, 'E');
                    InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), 0, 0, 'E');
                    if DemoDataSetup."Reduced VAT Rate" > 0 then begin
                        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.ReducedVATCode(), DemoDataSetup."Reduced VAT Rate", 0, 'S');
                        InsertData(DemoDataSetup.EUCode(), DemoDataSetup.ReducedVATCode(), DemoDataSetup."Reduced VAT Rate", 1, 'S');
                        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.ReducedVATCode(), 0, 0, 'E');
                    end;
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
        VATPostingSetup."VAT Identifier" := VATPostingSetup."VAT Prod. Posting Group";
        VATPostingSetup.Validate("Tax Category", TaxCategory);
        VATPostingSetup.Validate("Adjust for Payment Discount", DemoDataSetup."Adjust for Payment Discount");
        if DemoDataSetup."Advanced Setup" then
            VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);

        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then
            case VATPostingSetup."VAT Prod. Posting Group" of
                DemoDataSetup.GoodsVATCode():
                    SetAccounts(VATPostingSetup, '995610', '995630', '995620', '995615', '995635', '995625');
                DemoDataSetup.ServicesVATCode(),
                DemoDataSetup.ReducedVATCode():
                    begin
                        SetAccounts(VATPostingSetup, '995611', '995631', '995621', '995616', '995636', '995626');
                        if VATPostingSetup."VAT Bus. Posting Group" = DemoDataSetup.EUCode() then
                            VATPostingSetup.Validate("EU Service", true);
                    end;
                DemoDataSetup.NoVATCode():
                    SetAccounts(VATPostingSetup, '995610', '995630', '995620', '995615', '995635', '995625');
            end;

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


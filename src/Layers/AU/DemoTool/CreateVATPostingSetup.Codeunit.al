codeunit 101325 "Create VAT Posting Setup"
{

    trigger OnRun()
    var
        GetGLAccNo: Codeunit "Create G/L Account";
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then
            case DemoDataSetup."Company Type" of
                DemoDataSetup."Company Type"::VAT:
                    begin
                        InsertData('', DemoDataSetup.ServicesVATCode(), DemoDataSetup."Services VAT Rate", 0, '995611', '995621', '');
                        InsertData('', DemoDataSetup.GoodsVATCode(), DemoDataSetup."Goods VAT Rate", 0, '995610', '995620', '');
                        InsertData('', DemoDataSetup.NoVATCode(), 0, 0, '995611', '995621', '');
                        InsertData('', XASSET, 10, 0, '995611', '995621', '');
                        InsertData('', XINPUTTAX, 0, 0, '995650', '995650', '');
                        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), DemoDataSetup."Services VAT Rate", 0, '995611', '995621', '');
                        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.GoodsVATCode(), DemoDataSetup."Goods VAT Rate", 0, '995610', '995620', '');
                        InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.NoVATCode(), 0, 0, '995611', '995621', '');
                        InsertData(DemoDataSetup.DomesticCode(), XASSET, 10, 0, '995611', '995621', '');
                        InsertData(DemoDataSetup.DomesticCode(), XINPUTTAX, 0, 0, '995650', '995650', '');
                        InsertData(DemoDataSetup.MiscCode(), DemoDataSetup.ServicesVATCode(), 10, 0, '995611', '995621', '');
                        InsertData(DemoDataSetup.MiscCode(), DemoDataSetup.GoodsVATCode(), DemoDataSetup."Goods VAT Rate", 0, '995610', '995620', '');
                        InsertData(DemoDataSetup.MiscCode(), DemoDataSetup.NoVATCode(), 0, 0, '995611', '995621', '');
                        InsertData(DemoDataSetup.MiscCode(), XASSET, 10, 0, '995611', '995621', '');
                        InsertData(DemoDataSetup.MiscCode(), XINPUTTAX, 0, 0, '995650', '995650', '');
                        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.ServicesVATCode(), 0, 0, '995611', '995621', '');
                        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.GoodsVATCode(), 0, 0, '995610', '995620', '');
                        InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.NoVATCode(), 0, 0, '995611', '995621', '');
                        InsertData(DemoDataSetup.ExportCode(), XASSET, 0, 0, '995611', '995621', '');
                        InsertData(DemoDataSetup.ExportCode(), XINPUTTAX, 0, 0, '995650', '995650', '');
                    end;
                DemoDataSetup."Company Type"::"Sales Tax":
                    InsertSalesTaxData('E');
            end
        else begin
            InsertData('', '', 0, 0, '', '', '');
            InsertData('', DemoDataSetup.NonGST(), 0, 0, '', '', '');
            InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.GSTTen(), 10, 0, GetGLAccNo.GSTPayable(), GetGLAccNo.GSTReceivable(), '');
            InsertData(DemoDataSetup.DomesticCode(), DemoDataSetup.NonGST(), 0, 0, GetGLAccNo.GSTPayable(), GetGLAccNo.GSTReceivable(), '');
            InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.GSTTen(), 10, 0, GetGLAccNo.GSTPayable(), GetGLAccNo.GSTReceivable(), '');
            InsertData(DemoDataSetup.ExportCode(), DemoDataSetup.NonGST(), 0, 0, GetGLAccNo.GSTPayable(), GetGLAccNo.GSTReceivable(), '');
            InsertData(DemoDataSetup.MiscCode(), DemoDataSetup.GSTTen(), 10, 0, GetGLAccNo.GSTPayable(), GetGLAccNo.GSTReceivable(), '');
            InsertData(DemoDataSetup.MiscCode(), DemoDataSetup.NonGST(), 0, 0, GetGLAccNo.GSTPayable(), GetGLAccNo.GSTReceivable(), '');
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        CA: Codeunit "Make Adjustments";
        XPostingSetupTxt: Label 'Setup for %1 / %2', Comment = '%1 = Business Group; %2 = Product Group';
        XASSET: Label 'ASSET';
        XINPUTTAX: Label 'INPUTTAX';

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
            if VATPostingSetup."VAT Bus. Posting Group" <> '' then
                case VATPostingSetup."VAT Prod. Posting Group" of
                    DemoDataSetup.GoodsVATCode():
                        begin
                            VATPostingSetup.Validate("Sales VAT Account", CA.Convert("Sales Account"));
                            VATPostingSetup.Validate("Purchase VAT Account", CA.Convert("Purchase Account"));
                            if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
                                VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", CA.Convert('995660'));
                            if VATPostingSetup."Unrealized VAT Type" > 0 then begin
                                VATPostingSetup.Validate("Sales VAT Unreal. Account", CA.Convert('995615'));
                                VATPostingSetup.Validate("Purch. VAT Unreal. Account", CA.Convert('995635'));
                                if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
                                    VATPostingSetup.Validate("Reverse Chrg. VAT Unreal. Acc.", CA.Convert('995660'));
                            end;
                        end;
                    DemoDataSetup.ServicesVATCode():
                        begin
                            VATPostingSetup.Validate("Sales VAT Account", CA.Convert("Sales Account"));
                            VATPostingSetup.Validate("Purchase VAT Account", CA.Convert("Purchase Account"));
                            if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
                                VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", CA.Convert('995660'));
                            if VATPostingSetup."Unrealized VAT Type" > 0 then begin
                                VATPostingSetup.Validate("Sales VAT Unreal. Account", CA.Convert('995615'));
                                VATPostingSetup.Validate("Purch. VAT Unreal. Account", CA.Convert('995635'));
                                if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
                                    VATPostingSetup.Validate("Reverse Chrg. VAT Unreal. Acc.", CA.Convert('995660'));
                            end;
                        end;
                    DemoDataSetup.NoVATCode():
                        begin
                            VATPostingSetup.Validate("Sales VAT Account", CA.Convert("Sales Account"));
                            VATPostingSetup.Validate("Purchase VAT Account", CA.Convert("Purchase Account"));
                            if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
                                VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", CA.Convert('995660'));
                        end;
                    XINPUTTAX,
                    XASSET:
                        begin
                            VATPostingSetup.Validate("Sales VAT Account", CA.Convert("Sales Account"));
                            VATPostingSetup.Validate("Purchase VAT Account", CA.Convert("Purchase Account"));
                            if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT" then
                                VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", CA.Convert('995660'));
                        end;
                    DemoDataSetup.GSTTen(),
                    DemoDataSetup.NonGST():
                        begin
                            VATPostingSetup.Validate("Sales VAT Account", CA.Convert("Sales Account"));
                            VATPostingSetup.Validate("Purchase VAT Account", CA.Convert("Purchase Account"));
                        end;
                end;

        VATPostingSetup.Insert();
    end;
}


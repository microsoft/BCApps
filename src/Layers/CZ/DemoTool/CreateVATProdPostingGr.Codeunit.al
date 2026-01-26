codeunit 101324 "Create VAT Prod. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
            InsertData(DemoDataSetup.NoVATCode(), XMiscellaneousWithoutVAT);
            // NAVCZ
            InsertData(DemoDataSetup.BaseVATItemCode(), StrSubstNo(XVATItem, DemoDataSetup.BaseVATRate()));
            InsertData(DemoDataSetup.BaseVATServiceCode(), StrSubstNo(XVATService, DemoDataSetup.BaseVATRate()));
            InsertData(DemoDataSetup.BaseVATReverseChargeCode(), StrSubstNo(XVATReverseCharge, DemoDataSetup.BaseVATRate()));
            InsertData(DemoDataSetup.FirstReducedVATItemCode(), StrSubstNo(XVATItem, DemoDataSetup.FirstReducedVATRate()));
            InsertData(DemoDataSetup.FirstReducedVATServiceCode(), StrSubstNo(XVATService, DemoDataSetup.FirstReducedVATRate()));
            InsertData(DemoDataSetup.FirstReducedVATReverseChargeCode(), StrSubstNo(XVATReverseCharge, DemoDataSetup.FirstReducedVATRate()));
            InsertData(DemoDataSetup.SecondReducedVATItemCode(), StrSubstNo(XVATItem, DemoDataSetup.SecondReducedVATRate()));
            InsertData(DemoDataSetup.SecondReducedVATServiceCode(), StrSubstNo(XVATService, DemoDataSetup.SecondReducedVATRate()));
            // NAVCZ
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XMiscellaneousWithoutVAT: Label 'Miscellaneous without VAT';
        XVATItem: Label 'VAT %1% item';
        XVATService: Label 'VAT %1% service';
        XVATReverseCharge: Label 'VAT %1% reverse charge';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.Init();
        VATProductPostingGroup.Validate(Code, Code);
        VATProductPostingGroup.Validate(Description, Description);
        VATProductPostingGroup.Insert();
    end;
}


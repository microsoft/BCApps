codeunit 101324 "Create VAT Prod. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then begin
            if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
                DemoDataSetup.TestField(DemoDataSetup."Goods VAT Rate");
                DemoDataSetup.TestField(DemoDataSetup."Services VAT Rate");
                InsertData(DemoDataSetup.GoodsVATCode(), StrSubstNo(XMiscellaneousVAT, DemoDataSetup."Goods VAT Rate"));
                InsertData(DemoDataSetup.ServicesVATCode(), StrSubstNo(XMiscellaneousVAT, DemoDataSetup."Services VAT Rate"));
                InsertData(DemoDataSetup.NoVATCode(), XMiscellaneousWithoutVAT);
                if DemoDataSetup."Reduced VAT Rate" > 0 then
                    InsertData(DemoDataSetup.ReducedVATCode(), StrSubstNo(XMiscellaneousVAT, DemoDataSetup."Reduced VAT Rate"));
                InsertData(XINPUTTAX, XInputTaxed);
                InsertData(XASSET, XAssetwith10PERCENTVAT);
            end;
        end
        else begin
            InsertData(DemoDataSetup.NonGST(), XNONGST);
            InsertData(DemoDataSetup.GSTTen(), XGstTen);
            InsertData(DemoDataSetup.GoodsVATCode(), StrSubstNo(XMiscellaneousVAT, DemoDataSetup."Goods VAT Rate"));
            InsertData(DemoDataSetup.ServicesVATCode(), StrSubstNo(XMiscellaneousVAT, DemoDataSetup."Services VAT Rate"));
            InsertData(DemoDataSetup.NoVATCode(), XMiscellaneousWithoutVAT);
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XMiscellaneousVAT: Label 'Miscellaneous %1 VAT';
        XMiscellaneousWithoutVAT: Label 'Miscellaneous without VAT';
        XINPUTTAX: Label 'INPUTTAX';
        XInputTaxed: Label 'Input Taxed';
        XASSET: Label 'ASSET';
        XNONGST: Label 'NON GST';
        XGstTen: Label 'GST10';
        XAssetwith10PERCENTVAT: Label 'Asset with 10% VAT';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.Init();
        VATProductPostingGroup.Validate(Code, Code);
        VATProductPostingGroup.Validate(Description, Description);
        if VATProductPostingGroup.Insert() then;
    end;
}


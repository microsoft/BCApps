codeunit 101324 "Create VAT Prod. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
            DemoDataSetup.TestField("Goods VAT Rate");
            DemoDataSetup.TestField("Services VAT Rate");
            InsertData(XG0, XGoodsNoVAT);
            InsertData(XG1, XGoods6PERCENTVAT);
            InsertData(XG2, XGoods12PERCENTVAT);
            InsertData(DemoDataSetup.GoodsVATCode(), XGoods21PERCENTVAT);
            InsertData(XS0, XServicesNoVAT);
            InsertData(XS1, XServices6PERCENTVAT);
            InsertData(DemoDataSetup.ServicesVATCode(), XServices21PERCENTVAT);
            InsertData(XI0, XInvestments0PERCENTVAT);
            InsertData(XI3, XInvestments21PERCENTVAT);
            InsertData(XVAT, XOnlyVAT);
            InsertData(DemoDataSetup.NoVATCode(), XMiscellaneousWithoutVAT);
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XG0: Label 'G0';
        XGoodsNoVAT: Label 'Goods No VAT';
        XG1: Label 'G1';
        XGoods6PERCENTVAT: Label 'Goods 6% VAT';
        XG2: Label 'G2';
        XGoods12PERCENTVAT: Label 'Goods 12% VAT';
        XGoods21PERCENTVAT: Label 'Goods 21% VAT';
        XS0: Label 'S0';
        XServicesNoVAT: Label 'Services No VAT';
        XS1: Label 'S1';
        XServices6PERCENTVAT: Label 'Services 6% VAT';
        XServices21PERCENTVAT: Label 'Services 21% VAT';
        XI0: Label 'I0';
        XInvestments0PERCENTVAT: Label 'Investments 0% VAT';
        XI3: Label 'I3';
        XInvestments21PERCENTVAT: Label 'Investments 21% VAT';
        XVAT: Label 'VAT';
        XOnlyVAT: Label 'Only VAT';
        XMiscellaneousWithoutVAT: Label 'Miscellaneous without VAT';

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


codeunit 101324 "Create VAT Prod. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
            DemoDataSetup.TestField("Goods VAT Rate");
            DemoDataSetup.TestField("Services VAT Rate");
            InsertData(DemoDataSetup.GoodsVATCode(), StrSubstNo(XMiscellaneousVAT, DemoDataSetup."Goods VAT Rate"));
            InsertData(DemoDataSetup.ServicesVATCode(), StrSubstNo(XMiscellaneousVAT, DemoDataSetup."Services VAT Rate"));
            InsertData(DemoDataSetup.NoVATCode(), XMiscellaneousWithoutVAT);
            if DemoDataSetup."Reduced VAT Rate" > 0 then
                InsertData(DemoDataSetup.ReducedVATCode(), StrSubstNo(XMiscellaneousVAT, DemoDataSetup."Reduced VAT Rate"));
            InsertData(XONLY, XManuallyposted);
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XMiscellaneousVAT: Label 'Miscellaneous %1 VAT';
        XMiscellaneousWithoutVAT: Label 'Miscellaneous without VAT';
        XONLY: Label 'ONLY';
        XManuallyposted: Label 'Manually posted VAT';

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


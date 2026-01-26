codeunit 101324 "Create VAT Prod. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
            InsertData(DemoDataSetup.ServicesVATCode(), StrSubstNo(XMiscellaneousVAT, DemoDataSetup.ServicesVATCode()));
            InsertData(DemoDataSetup.NoVATCode(), NoVatTxt);
            InsertData(DemoDataSetup.GoodsVATCode(), StrSubstNo(XMiscellaneousVAT, DemoDataSetup.GoodsVATCode()));
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XMiscellaneousVAT: Label 'Miscellaneous %1 VAT', Comment = '%1 = VAT percentage';
        NoVatTxt: Label 'No VAT';

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


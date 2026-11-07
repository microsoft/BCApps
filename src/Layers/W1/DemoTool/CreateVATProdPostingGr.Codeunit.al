codeunit 101324 "Create VAT Prod. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
            DemoDataSetup.TestField("Goods VAT Rate");
            DemoDataSetup.TestField("Services VAT Rate");
            InsertData(DemoDataSetup.GoodsVATCode(), StrSubstNo(NormalVatTxt, DemoDataSetup."Goods VAT Rate"));
            // NORMAL
            InsertData(DemoDataSetup.ServicesVATCode(), StrSubstNo(ReducedVatTxt, DemoDataSetup."Services VAT Rate"));
            // REDUCED
            if DemoDataSetup."Data Type" <> DemoDataSetup."Data Type"::Extended then begin
                InsertData(DemoDataSetup.GoodsVATCodeSRV(), StrSubstNo(XMiscellaneousVAT, DemoDataSetup."Goods VAT Rate"));
                // SERV NORM
                InsertData(DemoDataSetup.ServicesVATCodeSRV(), StrSubstNo(XMiscellaneousVAT, DemoDataSetup."Services VAT Rate"));
                // SERV RED
                InsertData(DemoDataSetup.FullServicesVATCode(), XVATOnlyInvoices + ' ' + Format(DemoDataSetup."Services VAT Rate") + '%');
                // FULL RED
                InsertData(DemoDataSetup.FullGoodsVATCode(), XVATOnlyInvoices + ' ' + Format(DemoDataSetup."Goods VAT Rate") + '%');
                // FULL NORM
            end;
            InsertData(DemoDataSetup.NoVATCode(), NoVatTxt);
            if DemoDataSetup."Reduced VAT Rate" > 0 then
                InsertData(DemoDataSetup.ReducedVATCode(), StrSubstNo(XMiscellaneousVAT, DemoDataSetup."Reduced VAT Rate"));
        end;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XMiscellaneousVAT: Label 'Miscellaneous %1 VAT';
        XVATOnlyInvoices: Label 'VAT Only Invoices';
        NormalVatTxt: Label 'Standard VAT (%1%)', Comment = '%1=a number specifying the VAT percentage';
        ReducedVatTxt: Label 'Reduced VAT (%1%)', Comment = '%1=a number specifying the VAT percentage';
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


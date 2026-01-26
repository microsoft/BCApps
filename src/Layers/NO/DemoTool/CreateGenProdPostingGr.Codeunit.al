codeunit 101251 "Create Gen. Prod. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(DemoDataSetup.MiscCode(), XMiscellaneouswithVAT, XVAT24);
        InsertData(DemoDataSetup.NoVATCode(), XMiscellaneouswithoutVAT, XWITHVAT);
        InsertData(DemoDataSetup.RawMatCode(), XRawMaterials, XVAT24);
        InsertData(DemoDataSetup.RetailCode(), XRetail2, XVAT24);
        InsertData(DemoDataSetup.ServicesCode(), XResourcesetc, XVAT12);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XMiscellaneouswithVAT: Label 'Miscellaneous with VAT';
        XMiscellaneouswithoutVAT: Label 'Miscellaneous without VAT';
        XRawMaterials: Label 'Raw Materials';
        XRetail2: Label 'Retail';
        XResourcesetc: Label 'Resources, etc.';
        XFreightDescriptionTxt: Label 'Freight, etc.';
        XVAT24: Label 'High';
        XVAT12: Label 'Low';
        XWITHVAT: Label 'Without';

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        InsertData(DemoDataSetup.MiscCode(), XMiscellaneouswithVAT, XVAT24);
        InsertData(DemoDataSetup.NoVATCode(), XMiscellaneouswithoutVAT, XWITHVAT);
        InsertData(DemoDataSetup.RawMatCode(), XRawMaterials, XVAT24);
        InsertData(DemoDataSetup.FreightCode(), XFreightDescriptionTxt, XVAT24);
        InsertData(DemoDataSetup.RetailCode(), XRetail2, XVAT24);
        InsertData(DemoDataSetup.ServicesCode(), XResourcesetc, XVAT12);
    end;

    procedure InsertData(NewCode: Code[20]; NewDescription: Text[50]; DefVATProdPostingGroup: Code[20])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GenProductPostingGroup.Init();
        GenProductPostingGroup.Validate(Code, NewCode);
        GenProductPostingGroup.Validate(Description, NewDescription);
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then
            GenProductPostingGroup."Def. VAT Prod. Posting Group" := DefVATProdPostingGroup;
        GenProductPostingGroup.Insert();
    end;
}


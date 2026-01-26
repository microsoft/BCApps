codeunit 101251 "Create Gen. Prod. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(DemoDataSetup.MiscCode(), XMiscellaneouswithVAT, '');
        InsertData(DemoDataSetup.NoVATCode(), XMiscellaneouswithoutVAT, '');
        InsertData(DemoDataSetup.RawMatCode(), XRawMaterials, '');
        InsertData(DemoDataSetup.RetailCode(), XRetail2, '');
        InsertData(DemoDataSetup.ServicesCode(), XResourcesetc, '');
        InsertData(DemoDataSetup.ManufactCode(), XCapacities, '');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XMiscellaneouswithVAT: Label 'Miscellaneous with VAT';
        XMiscellaneouswithoutVAT: Label 'Miscellaneous without VAT';
        XRawMaterials: Label 'Raw Materials';
        XRetail2: Label 'Retail';
        XResourcesetc: Label 'Resources, etc.';
        XCapacities: Label 'Capacities';

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        InsertData(DemoDataSetup.MiscCode(), XMiscellaneouswithVAT, '');
        InsertData(DemoDataSetup.Zero(), XMiscellaneouswithoutVAT, '');
        InsertData(DemoDataSetup.RawMatCode(), XRawMaterials, '');
        InsertData(DemoDataSetup.RetailCode(), XRetail2, '');
        InsertData(DemoDataSetup.ServicesCode(), XResourcesetc, '');
        InsertData(DemoDataSetup.ManufactCode(), XCapacities, '');
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


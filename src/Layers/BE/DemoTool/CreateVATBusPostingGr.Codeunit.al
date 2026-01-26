codeunit 101323 "Create VAT Bus. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
            InsertData(DemoDataSetup.DomesticCode(), XDomesticcustomersandvendors); // BE
            InsertData(DemoDataSetup.EUCode(), XCustomersandvendorsinEU);
            InsertData(XIMPEXP, XOthercustomersandvendorsnotEU);
            InsertData(XIMPREV, XImportReverseChargeVAT);
            InsertData(XCC, XCocontractor);
        end;
    end;

    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        DemoDataSetup: Record "Demo Data Setup";
        XDomesticcustomersandvendors: Label 'Domestic customers and vendors';
        XCustomersandvendorsinEU: Label 'Customers and vendors in EU';
        XOthercustomersandvendorsnotEU: Label 'Other customers and vendors (not EU)';
        XIMPEXP: Label 'IMPEXP';
        XIMPREV: Label 'IMPREV';
        XImportReverseChargeVAT: Label 'Import Reverse Charge VAT';
        XCC: Label 'CC';
        XCocontractor: Label 'Cocontractor';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    begin
        VATBusinessPostingGroup.Init();
        VATBusinessPostingGroup.Validate(Code, Code);
        VATBusinessPostingGroup.Validate(Description, Description);
        VATBusinessPostingGroup.Insert();
    end;

    procedure GetDomesticVATGroup(): Code[10]
    begin
        DemoDataSetup.Get();
        exit(DemoDataSetup.DomesticCode());
    end;
}


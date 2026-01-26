codeunit 101323 "Create VAT Bus. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
            InsertData(DemoDataSetup.DomesticCode(), XDomesticcustomersandvendors, XxITVNSLS, XxITVNPUR);
            InsertData(DemoDataSetup.EUCode(), XCustomersandvendorsinEU, XxEUVNSLS, XxEUVNPUR);
            InsertData(DemoDataSetup.ExportCode(), XOthercustomersandvendorsnotEU, XxEXTVNSLS, XxEXTVNPUR);
        end;
    end;

    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        DemoDataSetup: Record "Demo Data Setup";
        XDomesticcustomersandvendors: Label 'Domestic customers and vendors';
        XCustomersandvendorsinEU: Label 'Customers and vendors in EU';
        XOthercustomersandvendorsnotEU: Label 'Other customers and vendors (not EU)';
        XxITVNSLS: Label 'IT-VN-SLS';
        XxITVNPUR: Label 'IT-VN-PUR';
        XxEUVNSLS: Label 'EU-VN-SLS';
        XxEUVNPUR: Label 'EU-VN-PUR';
        XxEXTVNSLS: Label 'EXT-VN-SLS';
        XxEXTVNPUR: Label 'EXT-VN-PUR';

    procedure InsertData("Code": Code[10]; Description: Text[50]; "Default Sales Operation Type": Code[10]; "Default Purch. Operation Type": Code[10])
    begin
        VATBusinessPostingGroup.Init();
        VATBusinessPostingGroup.Validate(Code, Code);
        VATBusinessPostingGroup.Validate(Description, Description); // IT
        VATBusinessPostingGroup.Validate("Default Sales Operation Type", "Default Sales Operation Type");
        VATBusinessPostingGroup.Validate("Default Purch. Operation Type", "Default Purch. Operation Type");
        VATBusinessPostingGroup.Insert();
    end;

    procedure GetDomesticVATGroup(): Code[10]
    begin
        DemoDataSetup.Get();
        exit(DemoDataSetup.DomesticCode());
    end;
}


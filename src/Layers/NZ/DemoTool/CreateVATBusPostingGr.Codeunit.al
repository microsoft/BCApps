codeunit 101323 "Create VAT Bus. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
            InsertData(DemoDataSetup.DomesticCode(), XDomesticcustomersandvendors); // NZ
            InsertData(DemoDataSetup.MiscCode(), XCustomersandvendorsinMISC);
            InsertData(DemoDataSetup.ExportCode(), XOthercustsandvendorsnotMISC);
        end;
    end;

    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        DemoDataSetup: Record "Demo Data Setup";
        XDomesticcustomersandvendors: Label 'Domestic customers and vendors';
        XCustomersandvendorsinMISC: Label 'Customers and vendors in MISC';
        XOthercustsandvendorsnotMISC: Label 'Other customers and vendors (not MISC)';

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


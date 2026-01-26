codeunit 101250 "Create Gen. Bus. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then
            case DemoDataSetup."Company Type" of
                DemoDataSetup."Company Type"::"Sales Tax":
                    begin
                        InsertData(DemoDataSetup.DomesticCode(), XDomesticcustomersandvendors, '');
                        InsertData(DemoDataSetup.EUCode(), XCustomersandvendorsinEU, '');
                        InsertData(DemoDataSetup.ExportCode(), XOthercustomersandvendorsnotEU, '');
                    end;
                DemoDataSetup."Company Type"::VAT:
                    begin
                        InsertData(DemoDataSetup.DomesticCode(), XDomesticcustomersandvendors, DemoDataSetup.DomesticCode());
                        InsertData(DemoDataSetup.EUCode(), XCustomersandvendorsinEU, DemoDataSetup.MiscCode());
                        InsertData(DemoDataSetup.ExportCode(), XOthercustomersandvendorsnotEU, DemoDataSetup.ExportCode());
                    end;
            end
        else
            InsertMiniAppData();
    end;

    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        DemoDataSetup: Record "Demo Data Setup";
        XDomesticcustomersandvendors: Label 'Domestic customers and vendors';
        XCustomersandvendorsinEU: Label 'Customers and vendors in EU';
        XOthercustomersandvendorsnotEU: Label 'Other customers and vendors (not EU)';
        XInterCompany: Label 'Intercompany';

    procedure InsertData("Code": Code[20]; Description: Text[50]; DefVATBusPostingGroup: Code[20])
    begin
        GenBusinessPostingGroup.Init();
        GenBusinessPostingGroup.Validate(Code, Code);
        GenBusinessPostingGroup.Validate(Description, Description);
        GenBusinessPostingGroup."Def. VAT Bus. Posting Group" := DefVATBusPostingGroup;
        if DefVATBusPostingGroup <> '' then
            GenBusinessPostingGroup."Auto Insert Default" := true;
        GenBusinessPostingGroup.Insert();
    end;

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        InsertData(DemoDataSetup.DomesticCode(), XDomesticcustomersandvendors, '');
        InsertData(DemoDataSetup.ExportCode(), XOthercustomersandvendorsnotEU, '');
        InsertData(DemoDataSetup.InterCompCode(), XInterCompany, '');
    end;
}


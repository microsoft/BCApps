codeunit 101250 "Create Gen. Bus. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        case DemoDataSetup."Company Type" of
            DemoDataSetup."Company Type"::"Sales Tax":
                begin
                    InsertData(DemoDataSetup.DomesticCode(), XDomesticcustomersandvendors, '');
                    InsertData(DemoDataSetup.EUCode(), XCustomersandvendorsinEU, '');
                    InsertData(DemoDataSetup.ExportCode(), XOthercustomersandvendorsnotEU, '');
                end;
            DemoDataSetup."Company Type"::VAT:
                begin
                    InsertData(XCUSTDOM, XCustDomestic, XCUSTHIGH);
                    InsertData(XCUSTFOR, XCustForeign, XCUSTNOVAT);
                    InsertData(XVENDDOM, XVendDomestic, XVENDHIGH);
                    InsertData(XVENDFOR, XVendForeign, XVENDNOVAT);
                end;
        end;
    end;

    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        DemoDataSetup: Record "Demo Data Setup";
        XDomesticcustomersandvendors: Label 'Domestic customers and vendors';
        XCustomersandvendorsinEU: Label 'Customers and vendors in EU';
        XOthercustomersandvendorsnotEU: Label 'Other customers and vendors (not EU)';
        XCUSTDOM: Label 'CUSTDOM';
        XCustDomestic: Label 'Domestic customers';
        XCUSTFOR: Label 'CUSTFOR';
        XCustForeign: Label 'Foreign customers';
        XVENDDOM: Label 'VENDDOM';
        XVendDomestic: Label 'Domestic vendors';
        XVENDFOR: Label 'VENDFOR';
        XVendForeign: Label 'Foreign vendors';
        XCUSTHIGH: Label 'CUSTHIGH';
        XCUSTNOVAT: Label 'CUSTNOVAT';
        XVENDHIGH: Label 'VENDHIGH';
        XVENDNOVAT: Label 'VENDNOVAT';

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
        InsertData(XCUSTDOM, XCustDomestic, XCUSTHIGH);
        InsertData(XCUSTFOR, XCustForeign, XCUSTNOVAT);
        InsertData(XVENDDOM, XVendDomestic, XVENDHIGH);
        InsertData(XVENDFOR, XVendForeign, XVENDNOVAT);
    end;

    procedure GetDomesticBusGroup(): Code[20]
    begin
        exit(XCUSTDOM);
    end;

    procedure VendorDomesticCode(): Code[20]
    begin
        exit(XVENDDOM);
    end;

    procedure VendorForeignCode(): Code[20]
    begin
        exit(XVENDFOR);
    end;
}


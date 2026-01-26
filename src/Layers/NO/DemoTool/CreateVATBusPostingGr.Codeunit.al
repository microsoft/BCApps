codeunit 101323 "Create VAT Bus. Posting Gr."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then begin
            InsertData(XCUSTNOVAT, XCustomerWithout); // NO
            InsertData(XCUSTHIGH, XCustomerHigh);
            InsertData(XCUSTLOW, XCustomerLow);
            InsertData(XVENDNOVAT, XVendorWithout);
            InsertData(XVENDHIGH, XVendorHigh);
            InsertData(XVENDLOW, XVendorLow);
        end;
    end;

    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        DemoDataSetup: Record "Demo Data Setup";
        XCUSTNOVAT: Label 'CUSTNOVAT';
        XCUSTHIGH: Label 'CUSTHIGH';
        XCUSTLOW: Label 'CUSTLOW';
        XVENDNOVAT: Label 'VENDNOVAT';
        XVENDHIGH: Label 'VENDHIGH';
        XVENDLOW: Label 'VENDLOW';
        XCustomerWithout: Label 'Customer - no vat.';
        XCustomerHigh: Label 'Customer - high vat';
        XCustomerLow: Label 'Customer - low vat';
        XVendorWithout: Label 'Vendor - no vat.';
        XVendorHigh: Label 'Vendor - high vat';
        XVendorLow: Label 'Vendor - low vat';

    procedure InsertData("Code": Code[10]; Description: Text[50])
    begin
        VATBusinessPostingGroup.Init();
        VATBusinessPostingGroup.Validate(Code, Code);
        VATBusinessPostingGroup.Validate(Description, Description);
        VATBusinessPostingGroup.Insert();
    end;

    procedure GetDomesticVATGroup(): Code[20]
    begin
        exit(XCUSTHIGH);
    end;

    procedure VendorHighVatCode(): Code[20]
    begin
        exit(XVENDHIGH);
    end;
}


codeunit 163417 "Create Tax Authority"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if not DemoDataSetup."Skip creation of master data" then begin
            InsertData('00010', XTaxAuth1Name, XTaxAuth1Address, '103054', '7735012340', '46405756', 2);
            InsertData('00020', XTaxAuth2Name, XTaxAuth2Address, '109456', '7735012358', '46405757', 2);
            InsertData('00030', XTaxAuth3Name, XTaxAuth3Address, '197342', '5006863203', '50060100', 2);
        end;
    end;

    var
        XTaxAuth1Name: Label 'TAXAUT 35';
        DemoDataSetup: Record "Demo Data Setup";
        Vendor: Record Vendor;
        XTaxAuth1Address: Label '25 One Way Street';
        XTaxAuth2Name: Label 'TAXAUT 40';
        XTaxAuth2Address: Label '12 Kensington Road';
        XTaxAuth3Name: Label 'TAXAUT 1';
        XTaxAuth3Address: Label '28 Day Drive';
        CreatePostCode: Codeunit "Create Post Code";

    procedure InsertData("No.": Code[20]; Name: Text[30]; Address: Text[30]; "Post Code": Text[30]; "VAT Registration No.": Text[20]; "KPP Code": Code[10]; "Vendor Type": Option Vendor,Employee,"Tax Authority")
    begin
        Vendor.Init();
        Vendor.Validate("No.", "No.");
        Vendor.Validate(Name, Name);
        Vendor.Validate(Address, Address);
        Vendor."Post Code" := CreatePostCode.FindPostCode("Post Code");
        Vendor.City := CreatePostCode.FindCity("Post Code");
        Vendor."VAT Registration No." := "VAT Registration No.";
        Vendor.Validate("KPP Code", "KPP Code");
        Vendor.Validate("Vendor Type", "Vendor Type");
        Vendor.Insert(true);
    end;
}


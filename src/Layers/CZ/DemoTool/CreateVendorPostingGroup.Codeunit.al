codeunit 101093 "Create Vendor Posting Group"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(
          DemoDataSetup.DomesticCode(), XDomesticVendorsTxt,
          '995410', '998910', '999135', '999130', '998910', '999150', '999160', '999170');
        // NAVCZ
        InsertData(
          DemoDataSetup.ForeignCode(), XForeignVendorsTxt, '995420', '998910', '999135', '999130', '998910', '999150', '999160', '999170');
        // NAVCZ
        InsertData(
          DemoDataSetup.EUCode(), XVendorsInEUTxt, '995430', '998910', '999135', '999130', '998910', '999150', '999160', '999170'); // NAVCZ
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XDomesticVendorsTxt: Label 'Domestic vendors';
        XVendorsInEUTxt: Label 'Vendors in EU';
        XForeignVendorsTxt: Label 'Foreign vendors (not EU)';

    procedure InsertData("Code": Code[20]; PostingGroupDescription: Text[50]; "Payables Account": Code[20]; "Service Charge Acc.": Code[20]; "Pmt. Disc. Debit Acc.": Code[20]; "Pmt. Disc. Credit Acc.": Code[20]; "Invoice Rounding Account": Code[20]; "Application Rounding Account": Code[20]; "Payment Tolerance credit Acc.": Code[20]; "Payment Tolerance Debit Acc.": Code[20])
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        VendorPostingGroup.Init();
        VendorPostingGroup.Validate(Code, Code);
        VendorPostingGroup.Validate(Description, PostingGroupDescription);
        VendorPostingGroup.Validate("Payables Account", MakeAdjustments.Convert("Payables Account"));
        VendorPostingGroup.Validate("Service Charge Acc.", MakeAdjustments.Convert("Service Charge Acc."));
        VendorPostingGroup.Validate("Payment Disc. Debit Acc.", MakeAdjustments.Convert("Pmt. Disc. Debit Acc."));
        VendorPostingGroup.Validate("Payment Disc. Credit Acc.", MakeAdjustments.Convert("Pmt. Disc. Credit Acc."));
        VendorPostingGroup.Validate("Invoice Rounding Account", MakeAdjustments.Convert("Invoice Rounding Account"));
        // NAVCZ
        VendorPostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", '663100');
        VendorPostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", '563100');
        VendorPostingGroup.Validate("Credit Rounding Account", '668100');
        VendorPostingGroup.Validate("Debit Rounding Account", '568100');
        // NAVCZ
        VendorPostingGroup.Validate("Payment Tolerance Debit Acc.", MakeAdjustments.Convert("Payment Tolerance Debit Acc."));
        VendorPostingGroup.Validate("Payment Tolerance Credit Acc.", MakeAdjustments.Convert("Payment Tolerance credit Acc."));
        VendorPostingGroup.Insert();
    end;
}

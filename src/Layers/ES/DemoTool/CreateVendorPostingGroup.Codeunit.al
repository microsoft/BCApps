codeunit 101093 "Create Vendor Posting Group"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(
          DemoDataSetup.DomesticCode(), XDomesticVendorsTxt,
          '995410', '998910', '', '', '6690001', '999110', '998610', '7691001', '7691001', '4010001', '4000003', '4010002');
        InsertData(
          DemoDataSetup.ForeignCode(), XForeignVendorsTxt,
          '995420', '998910', '', '', '6690001', '999110', '998610', '7691001', '7691001', '', '', '');
        InsertData(
          DemoDataSetup.EUCode(), XVendorsInEUTxt,
          '995410', '998910', '', '', '6690001', '999110', '998610', '7691001', '7691001', '4010001', '4000003', '4010002');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XDomesticVendorsTxt: Label 'Domestic vendors';
        XVendorsInEUTxt: Label 'Vendors in EU';
        XForeignVendorsTxt: Label 'Foreign vendors (not EU)';

    procedure InsertData("Code": Code[20]; PostingGroupDescription: Text[50]; "Payables Account": Code[20]; "Service Charge Acc.": Code[20]; "Pmt. Disc. Debit Acc.": Code[20]; "Pmt. Disc. Credit Acc.": Code[20]; "Invoice Rounding Account": Code[20]; "Credit Appl. Rounding Account": Code[20]; "Debit Appl. Rounding Account": Code[20]; "Payment Tolerance credit Acc.": Code[20]; "Payment Tolerance Debit Acc.": Code[20]; "Bills Account": Code[20]; "Invoices in  Pmt. Ord. Acc.": Code[20]; "Bills in Payment Order Acc.": Code[20])
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
        VendorPostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", MakeAdjustments.Convert("Credit Appl. Rounding Account"));
        VendorPostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", MakeAdjustments.Convert("Debit Appl. Rounding Account"));
        VendorPostingGroup.Validate("Credit Rounding Account", MakeAdjustments.Convert("Invoice Rounding Account"));
        VendorPostingGroup.Validate("Debit Rounding Account", MakeAdjustments.Convert("Invoice Rounding Account"));
        VendorPostingGroup.Validate("Payment Tolerance Debit Acc.", MakeAdjustments.Convert("Payment Tolerance Debit Acc."));
        VendorPostingGroup.Validate("Payment Tolerance Credit Acc.", MakeAdjustments.Convert("Payment Tolerance credit Acc."));
        VendorPostingGroup.Validate("Bills Account", MakeAdjustments.Convert("Bills Account"));
        VendorPostingGroup.Validate("Invoices in  Pmt. Ord. Acc.", MakeAdjustments.Convert("Invoices in  Pmt. Ord. Acc."));
        VendorPostingGroup.Validate("Bills in Payment Order Acc.", MakeAdjustments.Convert("Bills in Payment Order Acc."));
        VendorPostingGroup.Insert();
    end;
}


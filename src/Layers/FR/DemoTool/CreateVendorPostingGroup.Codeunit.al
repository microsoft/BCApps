codeunit 101093 "Create Vendor Posting Group"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(
          DemoDataSetup.DomesticCode(), XDomesticVendorsTxt,
          '995410', '998910', '999135', '999130', '999140', '999150', '999160', '999170', '666500', '658500', '758500');
        InsertData(
          DemoDataSetup.ForeignCode(), XForeignVendorsTxt,
          '995420', '998910', '999135', '999130', '999140', '999150', '999160', '999170', '666500', '658500', '758500');
        InsertData(
          DemoDataSetup.EUCode(), XVendorsInEUTxt, '995410', '998910', '999135', '999130', '999140', '999150', '999160', '999170', '666500', '658500', '758500');
        // Modif Demo Finance (CM) : ajout d'un groupe pour le module réglement
        InsertData(XFRANCEEFF, '', '403000', '998910', '999135', '999130', '999140', '999150', '999160', '999170', '666500', '658500', '758500');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XDomesticVendorsTxt: Label 'Domestic vendors';
        XVendorsInEUTxt: Label 'Vendors in EU';
        XForeignVendorsTxt: Label 'Foreign vendors (not EU)';
        XFRANCEEFF: Label 'FRANCE-EFF';

    procedure InsertData("Code": Code[20]; PostingGroupDescription: Text[50]; "Payables Account": Code[20]; "Service Charge Acc.": Code[20]; "Pmt. Disc. Debit Acc.": Code[20]; "Pmt. Disc. Credit Acc.": Code[20]; "Invoice Rounding Account": Code[20]; "Application Rounding Account": Code[20]; "Payment Tolerance credit Acc.": Code[20]; "Payment Tolerance Debit Acc.": Code[20]; "Debit Curr. Appln. Rndg. Acc.": Code[10]; "Debit Rounding Account": Code[10]; "Credit Rounding Account": Code[10])
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
        VendorPostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", MakeAdjustments.Convert("Application Rounding Account"));
        VendorPostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", MakeAdjustments.Convert("Application Rounding Account"));
        VendorPostingGroup.Validate("Credit Rounding Account", MakeAdjustments.Convert("Application Rounding Account"));
        VendorPostingGroup.Validate("Debit Rounding Account", MakeAdjustments.Convert("Application Rounding Account"));
        VendorPostingGroup.Validate("Payment Tolerance Debit Acc.", MakeAdjustments.Convert("Payment Tolerance Debit Acc."));
        VendorPostingGroup.Validate("Payment Tolerance Credit Acc.", MakeAdjustments.Convert("Payment Tolerance credit Acc."));
        VendorPostingGroup."Debit Curr. Appln. Rndg. Acc." := "Debit Curr. Appln. Rndg. Acc.";
        VendorPostingGroup."Debit Rounding Account" := "Debit Rounding Account";
        VendorPostingGroup."Credit Rounding Account" := "Credit Rounding Account";
        VendorPostingGroup.Insert();
    end;
}


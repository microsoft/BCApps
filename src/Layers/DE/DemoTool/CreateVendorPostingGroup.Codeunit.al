codeunit 101093 "Create Vendor Posting Group"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        AdjustForPmtDisc := true;

        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then begin
            InsertData(DemoDataSetup.DomesticCode(), XDomesticVendorsTxt, '995410', '998910', '999135', '999130', '999140', '999150', '999160', '999170');
            InsertData(DemoDataSetup.ForeignCode(), XForeignVendorsTxt, '995420', '998910', '999135', '999130', '999140', '999150', '999160', '999170');
            InsertData(DemoDataSetup.EUCode(), XVendorsInEUTxt, '995420', '998910', '999135', '999130', '999140', '999150', '999160', '999170');
        end else begin
            InsertData(DemoDataSetup.DomesticCode(), XDomesticVendorsTxt, CreateGLAccount.AccountsPayableDomestic(), CreateGLAccount.MiscVATPayable(), CreateGLAccount.PurchaseDiscounts(), CreateGLAccount.PurchaseDiscounts(), CreateGLAccount.PayableInvoiceRounding(), CreateGLAccount.PayableInvoiceRounding(), CreateGLAccount.Miscexternalexpenses(), CreateGLAccount.Miscexternalexpenses());
            InsertData(DemoDataSetup.ForeignCode(), XForeignVendorsTxt, CreateGLAccount.AccountsPayableForeign(), CreateGLAccount.MiscVATPayable(), CreateGLAccount.PurchaseDiscounts(), CreateGLAccount.PurchaseDiscounts(), CreateGLAccount.PayableInvoiceRounding(), CreateGLAccount.PayableInvoiceRounding(), CreateGLAccount.Miscexternalexpenses(), CreateGLAccount.Miscexternalexpenses());
            InsertData(DemoDataSetup.EUCode(), XVendorsInEUTxt, CreateGLAccount.AccountsPayableForeign(), CreateGLAccount.MiscVATPayable(), CreateGLAccount.PurchaseDiscounts(), CreateGLAccount.PurchaseDiscounts(), CreateGLAccount.PayableInvoiceRounding(), CreateGLAccount.PayableInvoiceRounding(), CreateGLAccount.Miscexternalexpenses(), CreateGLAccount.Miscexternalexpenses());
        end;
    end;

    var
        CreateGLAccount: Codeunit "Create G/L Account";
        DemoDataSetup: Record "Demo Data Setup";
        AdjustForPmtDisc: Boolean;
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
        if not AdjustForPmtDisc then begin
            VendorPostingGroup.Validate("Payment Disc. Debit Acc.", MakeAdjustments.Convert("Pmt. Disc. Debit Acc."));
            VendorPostingGroup.Validate("Payment Disc. Credit Acc.", MakeAdjustments.Convert("Pmt. Disc. Credit Acc."));
        end;
        VendorPostingGroup.Validate("Invoice Rounding Account", MakeAdjustments.Convert("Invoice Rounding Account"));
        VendorPostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", MakeAdjustments.Convert("Application Rounding Account"));
        VendorPostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", MakeAdjustments.Convert("Application Rounding Account"));
        VendorPostingGroup.Validate("Credit Rounding Account", MakeAdjustments.Convert("Application Rounding Account"));
        VendorPostingGroup.Validate("Debit Rounding Account", MakeAdjustments.Convert("Application Rounding Account"));
        VendorPostingGroup.Validate("Payment Tolerance Debit Acc.", MakeAdjustments.Convert("Payment Tolerance Debit Acc."));
        VendorPostingGroup.Validate("Payment Tolerance Credit Acc.", MakeAdjustments.Convert("Payment Tolerance credit Acc."));
        VendorPostingGroup.Insert();
    end;
}


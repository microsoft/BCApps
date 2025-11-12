codeunit 101413 "Create IC Partner"
{

    trigger OnRun()
    var
        GLAccountCategory: Record "G/L Account Category";
        CreateGLAccount: Codeunit "Create G/L Account";
        CreateGenBusPostGroup: Codeunit "Create Gen. Bus. Posting Gr.";
        CreateGenPostingSetup: Codeunit "Create General Posting Setup";
        CreateCustomer: Codeunit "Create Customer";
        CreateVendor: Codeunit "Create Vendor";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        DemoDataSetup.Get();

        CreateICSetup();

        // Gen. Bus Posting Group
        CreateGenBusPostGroup.InsertData(XINTERCOMP, XIntercompanylc, '');
        CreateGenPostingSetup.InsertData(XINTERCOMP, DemoDataSetup.MiscCode(), '996120', '997120');
        CreateGenPostingSetup.InsertData(XINTERCOMP, DemoDataSetup.NoVATCode(), '996120', '997120');
        CreateGenPostingSetup.InsertData(XINTERCOMP, DemoDataSetup.RawMatCode(), '996120', '997120');
        CreateGenPostingSetup.InsertData(XINTERCOMP, DemoDataSetup.RetailCode(), '996120', '997120');

        CreateGLAccount.InsertData('992325', XCustomersIntercompany, 0, 1, 0, '', 0, '', '', '', '', false);
        CreateGLAccount.InsertData('995425', XVendorsIntercompany, 0, 1, 0, '', 0, '', '', '', '', false);

        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Assets, GLAccountCategoryMgt.GetAR());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);
        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Assets, GLAccountCategoryMgt.GetCurrentLiabilities());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);

        // IC Cutomer, Vendor
        CreateCustomer.InsertData(XIC1030, 'Cronus Cardoxy Procurement', 'Geradeausweg 77', 'DE-20097', '', '', 'EUR', 'DE', '',
          '111111111', '', '', '');
        CreateCustomer.InsertData(XIC1020, 'Cronus Cardoxy Sales', 'Ligeudvej 24', 'DK-2100', '', '', 'DKK', 'DK', '',
          '34192020', '', '', '');
        CreateVendor.InsertData(XIC1030, 'Cronus Cardoxy Procurement', 'Geradeausweg 77', 'DE-20097', '', '', 'EUR', 'DE',
          '111111111', '', '', '', '');
        CreateVendor.InsertData(XIC1020, 'Cronus Cardoxy Sales', 'Ligeudvej 24', 'DK-2100', '', '', 'DKK', 'DK',
          '34192020', '', '', '', '');

        InsertData(XICP20, 'Cronus Cardoxy Sales', 'DKK', 0, '', '992325', '995425', false, XIC1020, XIC1020);
        InsertData(XICP30, 'Cronus Cardoxy Procurement', 'EUR', 0, '', '992325', '995425', false, XIC1030, XIC1030);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        ICPartner: Record "IC Partner";
        XINTERCOMP: Label 'INTERCOMP';
        XICGJNL: Label 'IC_GJNL';
        XInterCompanyGenJnl: Label 'InterCompany Gen. Jnl';
        XIC0010: Label 'IC-0010';
        XIC9999: Label 'IC9999';
        XCustomersIntercompany: Label 'Customers, Intercompany';
        XVendorsIntercompany: Label 'Vendors, Intercompany';
        XIC1030: Label 'IC1030';
        XIC1020: Label 'IC1020';
        XICP20: Label 'ICP20';
        XICP30: Label 'ICP30';
        XIntercompanylc: Label 'Intercompany';
        XDEFAULT: Label 'DEFAULT';
        XDefaultJournalBatch: Label 'Default Journal Batch';

    procedure InsertData("Code": Code[20]; Name: Text[30]; "Currency Code": Code[10]; "Inbox Type": Option "File Location",Database; "Inbox Details": Text[30]; "Receivables Account": Code[30]; "Payables Account": Code[30]; Blocked: Boolean; CustomerNo: Code[10]; VendorNo: Code[10])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        CA: Codeunit "Make Adjustments";
    begin
        if "Currency Code" = DemoDataSetup."Currency Code" then
            "Currency Code" := '';
        ICPartner.Init();
        ICPartner.Code := Code;
        ICPartner.Name := Name;
        ICPartner."Currency Code" := "Currency Code";
        ICPartner."Inbox Type" := "IC Partner Inbox Type".FromInteger("Inbox Type");
        ICPartner."Inbox Details" := "Inbox Details";
        ICPartner.Validate("Receivables Account", CA.Convert("Receivables Account"));
        ICPartner.Validate("Payables Account", CA.Convert("Payables Account"));
        ICPartner.Blocked := Blocked;
        ICPartner.Insert();

        if (CustomerNo <> '') and Customer.Get(CustomerNo) then begin
            Customer.Validate("IC Partner Code", Code);
            Customer.Modify();
        end;
        if (VendorNo <> '') and Vendor.Get(VendorNo) then begin
            Vendor.Validate("IC Partner Code", Code);
            Vendor.Modify();
        end;
    end;

    procedure CreateICSetup()
    begin
        CreateICSetup('ICP01');
    end;

    procedure CreateICSetup(ICPartnerCode: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        ICSetup: Record "IC Setup";
        CreateGenJournalTemplate: Codeunit "Create Gen. Journal Template";
        CreateGenJournalBatch: Codeunit "Create Gen. Journal Batch";
    begin
        if not GenJournalTemplate.Get(XINTERCOMP) then
            CreateGenJournalTemplate.InsertData(
                XINTERCOMP, XIntercompanylc, "Gen. Journal Template Type"::Intercompany, false, XINTERCOMP, XICGJNL, XInterCompanyGenJnl, XIC0010, XIC9999);
        if not GenJournalBatch.Get(XINTERCOMP, XDEFAULT) then
            CreateGenJournalBatch.InsertData(XINTERCOMP, XDEFAULT, XDefaultJournalBatch, "Gen. Journal Account Type"::"G/L Account", '', true, false);

        if not ICSetup.Get() then begin
            ICSetup.Init();
            ICSetup.Insert();
        end;

        ICSetup."IC Partner Code" := ICPartnerCode;
        ICSetup."Auto. Send Transactions" := true;
        ICSetup."Default IC Gen. Jnl. Template" := XINTERCOMP;
        ICSetup."Default IC Gen. Jnl. Batch" := XDEFAULT;
        ICSetup.Modify();
    end;
}


codeunit 101566 "Create Job Responsibility"
{

    trigger OnRun()
    begin
        InsertData(XAPR, XAccountsPayableResponsible);
        InsertData(XARR, XAccsReceivableResponsible);
        InsertData(XMARKETING, XMarketingResponsible);
        InsertData(XPURCHASE, XPurchaseResponsible);
        InsertData(XSALE, XSalesResponsible);
    end;

    var
        "Job Responsibility": Record "Job Responsibility";
        XAPR: Label 'APR';
        XAccountsPayableResponsible: Label 'Accounts Payable Responsible';
        XARR: Label 'ARR';
        XAccsReceivableResponsible: Label 'Accs. Receivable Responsible';
        XMARKETING: Label 'MARKETING';
        XMarketingResponsible: Label 'Marketing Responsible';
        XPURCHASE: Label 'PURCHASE';
        XPurchaseResponsible: Label 'Purchase Responsible';
        XSALE: Label 'SALE';
        XSalesResponsible: Label 'Sales Responsible';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        "Job Responsibility".Init();
        "Job Responsibility".Validate(Code, Code);
        "Job Responsibility".Validate(Description, Description);
        "Job Responsibility".Insert();
    end;

    procedure CreateEvaluationData()
    begin
        UpdateCustomerContactJobResposibility();
        UpdateVendorContactJobResposibility();
    end;

    local procedure UpdateCustomerContactJobResposibility()
    var
        Customer: Record Customer;
        Contact: Record Contact;
    begin
        if Customer.FindSet() then
            repeat
                Contact.Get(Customer."Primary Contact No.");
                InsertContactJobResponsibility(Contact."No.", XPURCHASE);
            until Customer.Next() = 0;
    end;

    local procedure UpdateVendorContactJobResposibility()
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
    begin
        if Vendor.FindSet() then
            repeat
                Contact.Get(Vendor."Primary Contact No.");
                InsertContactJobResponsibility(Contact."No.", XSALE);
            until Vendor.Next() = 0;
    end;

    local procedure InsertContactJobResponsibility(ContactNo: Code[20]; JobResponsibilityCode: Code[10])
    var
        ContactJobResponsibility: Record "Contact Job Responsibility";
    begin
        ContactJobResponsibility.Init();
        ContactJobResponsibility.Validate("Contact No.", ContactNo);
        ContactJobResponsibility.Validate("Job Responsibility Code", JobResponsibilityCode);
        ContactJobResponsibility.Insert();
    end;
}


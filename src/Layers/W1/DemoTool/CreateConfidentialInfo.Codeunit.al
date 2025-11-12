codeunit 101614 "Create Confidential Info."
{

    trigger OnRun()
    begin
        InsertData(XEH, XINSURANCE, XLifeInsurance);
        InsertData(XEH, XRETIRE, XSavingsinNewBankofLondon);
        InsertData(XEH, XSALARY, XMonthlySalaryof20000);
        InsertData(XEH, XSTOCK, X200StockOptions);

        InsertData(XOF, XINSURANCE, XLifeInsurance);
        InsertData(XOF, XRETIRE, XSavingsinWorldWideBank);
        InsertData(XOF, XRETIRE, XSavingsinPensionFund);
        InsertData(XOF, XSALARY, XMonthlySalaryof30000);

        InsertData(XLT, XINSURANCE, XLifeInsurance);
        InsertData(XLT, XRETIRE, XSavingsinPensionFund);
        InsertData(XLT, XSALARY, XMonthlySalaryof20000);
        InsertData(XLT, XSTOCK, X200StockOptions);

        InsertData(XJO, XINSURANCE, XLifeInsurance);
        InsertData(XJO, XRETIRE, XSavingsinWorldWideBank);
        InsertData(XJO, XRETIRE, XSavingsinPensionFund);
        InsertData(XJO, XSALARY, XMonthlySalaryofLCY25000);
        InsertData(XJO, XSTOCK, X250StockOptions);

        InsertData(XRB, XINSURANCE, XLifeInsurance);
        InsertData(XRB, XRETIRE, XSavingsinWorldWideBank);
        InsertData(XRB, XRETIRE, XSavingsinPensionFund);
        InsertData(XRB, XSALARY, XMonthlySalaryof25000);
        InsertData(XRB, XSTOCK, X250StockOptions);

        InsertData(XMH, XINSURANCE, XLifeInsurance);
        InsertData(XMH, XRETIRE, XSavingsinPensionFund);
        InsertData(XMH, XSALARY, XMonthlySalaryof20000);
        InsertData(XMH, XSTOCK, X200StockOptions);

        InsertData(XTD, XINSURANCE, XLifeInsurance);
        InsertData(XTD, XRETIRE, XSavingsinPensionFund);
        InsertData(XTD, XSALARY, XMonthlySalaryof20000);
        InsertData(XTD, XSTOCK, X200StockOptions);
    end;

    var
        ConfidentialInformation: Record "Confidential Information";
        "Line No.": Integer;
        "Old Employee No.": Code[20];
        XEH: Label 'EH';
        XOF: Label 'OF';
        XLT: Label 'LT';
        XJO: Label 'JO';
        XRB: Label 'RB';
        XMH: Label 'MH';
        XTD: Label 'TD';
        XINSURANCE: Label 'INSURANCE';
        XLifeInsurance: Label 'Life Insurance';
        XRETIRE: Label 'RETIRE';
        XSavingsinNewBankofLondon: Label 'Savings in New Bank of London';
        XSALARY: Label 'SALARY';
        XMonthlySalaryof20000: Label 'Monthly Salary of 20,000';
        XSTOCK: Label 'STOCK';
        X200StockOptions: Label '200 Stock Options';
        XSavingsinWorldWideBank: Label 'Savings in World Wide Bank';
        XSavingsinPensionFund: Label 'Savings in Pension Fund';
        XMonthlySalaryof30000: Label 'Monthly Salary of 30,000';
        XMonthlySalaryofLCY25000: Label 'Monthly Salary of LCY 25,000';
        X250StockOptions: Label '250 Stock Options';
        XMonthlySalaryof25000: Label 'Monthly Salary of 25,000';

    procedure InsertData("Employee No.": Code[20]; "Confidential Code": Code[10]; Description: Text[30])
    begin
        ConfidentialInformation."Employee No." := "Employee No.";
        ConfidentialInformation."Confidential Code" := "Confidential Code";
        if "Old Employee No." = "Employee No." then
            "Line No." := "Line No." + 10000
        else
            "Line No." := 10000;
        "Old Employee No." := "Employee No.";
        ConfidentialInformation."Line No." := "Line No.";
        ConfidentialInformation.Description := Description;
        ConfidentialInformation.Insert();
    end;
}


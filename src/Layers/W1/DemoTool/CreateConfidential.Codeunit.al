codeunit 101613 "Create Confidential"
{

    trigger OnRun()
    begin
        InsertData(XINSURANCE, XInsurancePremiumsPaid);
        InsertData(XRETIRE, XCompanyPensionPlan);
        InsertData(XSALARY, XMonthlySalary);
        InsertData(XSTOCK, XEmployeeStockOptions);
    end;

    var
        Confidential: Record Confidential;
        XINSURANCE: Label 'INSURANCE';
        XInsurancePremiumsPaid: Label 'Insurance Premiums Paid';
        XRETIRE: Label 'RETIRE';
        XCompanyPensionPlan: Label 'Company Pension Plan';
        XSALARY: Label 'SALARY';
        XMonthlySalary: Label 'Monthly Salary';
        XSTOCK: Label 'STOCK';
        XEmployeeStockOptions: Label 'Employee Stock Options';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        Confidential.Code := Code;
        Confidential.Description := Description;
        Confidential.Insert();
    end;
}


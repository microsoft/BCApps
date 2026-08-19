codeunit 101587 "Create Profile Quest. Header"
{

    trigger OnRun()
    begin
        InsertData(XCOMPANY, XGeneralcompanyinformation, 1, '');
        InsertData(XCUSTOMER, XCustomerinformation, 1, XCUST);
        InsertData(XLEADQ, XLeadQualification, 1, XPROS);
        InsertData(XPERSON, XGeneralpersonalinformation, 2, '');
        InsertData(XPORTF, XCustomerPortfolioManagement, 1, XCUST);
        InsertData(XPOTENTIAL, XCustomerSalesPotential, 1, XCUST);
        InsertData(XSATISF, XCustomerSatisfactionIndex, 0, XCUST);
    end;

    var
        "Profile Questionnaire Header": Record "Profile Questionnaire Header";
        XCOMPANY: Label 'COMPANY';
        XGeneralcompanyinformation: Label 'General company information';
        XCUSTOMER: Label 'CUSTOMER';
        XCustomerinformation: Label 'Customer information';
        XCUST: Label 'CUST';
        XLEADQ: Label 'LEADQ';
        XLeadQualification: Label 'Lead Qualification';
        XPROS: Label 'PROS';
        XPERSON: Label 'PERSON';
        XGeneralpersonalinformation: Label 'General personal information';
        XPORTF: Label 'PORTF';
        XCustomerPortfolioManagement: Label 'Customer Portfolio Management';
        XPOTENTIAL: Label 'POTENTIAL';
        XCustomerSalesPotential: Label 'Customer Sales Potential';
        XSATISF: Label 'SATISF';
        XCustomerSatisfactionIndex: Label 'Customer Satisfaction Index';

    procedure InsertData("Code": Code[10]; Description: Text[30]; "Contact Type": Option; "Business Relation Code": Code[10])
    begin
        "Profile Questionnaire Header".Init();
        "Profile Questionnaire Header".Validate(Code, Code);
        "Profile Questionnaire Header".Validate(Description, Description);
        "Profile Questionnaire Header".Validate("Contact Type", "Contact Type");
        "Profile Questionnaire Header".Validate("Business Relation Code", "Business Relation Code");
        "Profile Questionnaire Header".Insert();
    end;

    procedure InsertEvaluationData()
    begin
        InsertData(XCOMPANY, XGeneralcompanyinformation, 1, '');
        InsertData(XCUSTOMER, XCustomerinformation, 1, XCUST);
        InsertData(XPERSON, XGeneralpersonalinformation, 2, '');
    end;
}


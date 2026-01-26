codeunit 117559 "Add G/L Account"
{

    trigger OnRun()
    begin
        InsertRec('995795', XPrepaidServiceContractslc, XPREPAIDSERVICECONTRACTS, '2', '1', '0', '2',
             19020922D, '493000..493999', '0', '', '', '', '');
        InsertRec('995796', XPrepaidHardwareContractslc, XPREPAIDHARDWARECONTRACTS, '0', '1', '1', '3',
             19020922D, '', '2', XDOM, XSERVICES, XNATIONAL, XG3);
        InsertRec('995797', XPrepaidSoftwareContractslc, XPREPAIDSOFTWARECONTRACTS, '0', '1', '1', '3',
             19020922D, '', '2', XDOM, XSERVICES, XNATIONAL, XG3);
        InsertRec('996950', XSalesofServiceContractslc, XSALESOFSERVICECONTRACTS, '2', '0', '0', '1',
             19020922D, '705000..705999', '0', '', '', '', '');
        InsertRec('996955', XServiceContractSalelc, XSERVICECONTRACTSALE, '0', '0', '1', '2', 19020922D, '',
             '2', XDOM, XSERVICES, XNATIONAL, XG3);

        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Liabilities, GLAccountCategoryMgt.GetCurrentLiabilities());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);

        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Income, GLAccountCategoryMgt.GetIncomeService());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);
        GLAccIndent.Indent();
    end;

    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccIndent: Codeunit "G/L Account-Indent";
        XPrepaidServiceContractslc: Label 'Prepaid Service Contracts';
        XPREPAIDSERVICECONTRACTS: Label 'PREPAID SERVICE CONTRACTS';
        XPrepaidHardwareContractslc: Label 'Prepaid Hardware Contracts';
        XPREPAIDHARDWARECONTRACTS: Label 'PREPAID HARDWARE CONTRACTS';
        XNATIONAL: Label 'NATIONAL';
        XSERVICES: Label 'SERVICES';
        XPrepaidSoftwareContractslc: Label 'Prepaid Software Contracts';
        XPREPAIDSOFTWARECONTRACTS: Label 'PREPAID SOFTWARE CONTRACTS';
        XSalesofServiceContractslc: Label 'Sales of Service Contracts';
        XSALESOFSERVICECONTRACTS: Label 'SALES OF SERVICE CONTRACTS';
        XServiceContractSalelc: Label 'Service Contract Sale';
        XSERVICECONTRACTSALE: Label 'SERVICE CONTRACT SALE';
        MakeAdjustments: Codeunit "Make Adjustments";
        CreateGLAccount: Codeunit "Create G/L Account";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        XDOM: Label 'DOM';
        XG3: Label 'G3';

    procedure InsertRec(Fld1: Text[250]; Fld2: Text[250]; Fld3: Text[250]; Fld4: Text[250]; Fld9: Text[250]; Fld14: Text[250]; Fld19: Text[250]; Fld26: Date; Fld34: Text[250]; Fld43: Text[250]; Fld44: Text[250]; Fld45: Text[250]; Fld57: Text[250]; Fld58: Text[250])
    var
        NewRec: Record "G/L Account";
    begin
        NewRec.Init();
        Evaluate(NewRec."No.", MakeAdjustments.Convert(Fld1));
        Evaluate(NewRec.Name, Fld2);
        Evaluate(NewRec."Search Name", Fld3);
        Evaluate(NewRec."Account Type", Fld4);
        Evaluate(NewRec."Income/Balance", Fld9);
        Evaluate(NewRec."Direct Posting", Fld14);
        Evaluate(NewRec.Indentation, Fld19);
        NewRec."Last Date Modified" := MakeAdjustments.AdjustDate(Fld26);
        Evaluate(NewRec.Totaling, Fld34);
        Evaluate(NewRec."Gen. Posting Type", Fld43);
        Evaluate(NewRec."Gen. Bus. Posting Group", Fld44);
        Evaluate(NewRec."Gen. Prod. Posting Group", Fld45);
        Evaluate(NewRec."VAT Bus. Posting Group", Fld57);
        Evaluate(NewRec."VAT Prod. Posting Group", Fld58);
        NewRec.Insert();
    end;
}


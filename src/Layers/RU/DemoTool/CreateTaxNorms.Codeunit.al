codeunit 163409 "Create Tax Norms"
{

    trigger OnRun()
    var
        NormTempLine: Record "Tax Reg. Norm Template Line";
    begin
        DemoSetup.Get();

        NormJurisdiction.ImportSettings('LocalFiles\' + DemoSetup."Language Code" + '_Norms.xml');

        // Create norm setup
        InsertNormTermName(XNORMS, XSALARY, XSalaryFund);
        InsertNormTermLine(XNORMS, XSALARY, 10000, 0, 1, '70-000..70-999', 3);
        InsertNormTempLine(XNORMS, XSALARY, 10000, 1, XSalaryFund, XSALARY, 0, XSALARY, '', '', '', XCPED);

        InsertNormTermName(XNORMS, XREVENUE, XRevenuefromSales);
        InsertNormTermLine(XNORMS, XREVENUE, 10000, 0, 1, '90-1000..90-1999', 3);
        InsertNormTempLine(XNORMS, XREVENUE, 10000, 1, XRevenuefromSales, XREVENUE, 0, XREVENUE, '', '', '', XCPED);

        InsertNormTermName(XNORMS, XREVENUEI, XRevenuefromSalesItem);
        InsertNormTermLine(XNORMS, XREVENUEI, 10000, 0, 1, '90-1000..90-1199', 3);
        InsertNormTempLine(XNORMS, XREVENUEI, 10000, 1, XRevenuefromSalesItem, XREVENUE, 0, XREVENUE, '', '', '', XCPED);

        InsertNormTempLine(XNORMS, XMEDINS, 10000, 0, XSalaryFund, XSALARY, NormTempLine."Expression Type"::Link, XSALARY, '', XSALARY, XSALARY, '');
        InsertNormTempLine(XNORMS, XMEDINS, 20000, 0, XMedInsExpenseNorm, XNORM, NormTempLine."Expression Type"::Total, XMEDNORM, '', '', '', '');
        InsertNormTempLine(XNORMS, XMEDINS, 30000, 0, XMedInsExpenseLimit, XLIMIT, NormTempLine."Expression Type"::Total, StrSubstNo('%1 * %2', XSALARY, XNORM), XNORMS, '', '', '');
        InsertNormTempLine(XNORMS, XMEDINS, 40000, 2, XMedInsExpenseActual, XACTUAL, NormTempLine."Expression Type"::Term, '', '', '', '', '');
        InsertNormTempLine(XNORMS, XMEDINS, 50000, 1, XMedInsExpenseWithLimit, XWITHLIMIT, NormTempLine."Expression Type"::Total, StrSubstNo('%1 ? %2', XACTUAL, XLIMIT), '', '', '', '');
    end;

    var
        DemoSetup: Record "Demo Data Setup";
        NormJurisdiction: Record "Tax Register Norm Jurisdiction";
        MakeAdjustments: Codeunit "Make Adjustments";
        XNORMS: Label 'NORMS';
        XSALARY: Label 'SALARY';
        XSalaryFund: Label 'Salary Fund';
        XMEDINS: Label 'MEDINS';
        XMEDNORM: Label 'MEDNORM';
        XMedInsExpenseNorm: Label 'Voluntary Medical Insurance Expense Norm';
        XMedInsExpenseLimit: Label 'Voluntary Medical Insurance Expense Limit';
        XMedInsExpenseActual: Label 'Voluntary Medical Insurance Actual Expenses';
        XMedInsExpenseWithLimit: Label 'Voluntary Medical Insurance Expenses within Limit';
        XNORM: Label 'NORM';
        XLIMIT: Label 'LIMIT';
        XACTUAL: Label 'ACTUAL';
        XWITHLIMIT: Label 'WITHLIMIT';
        XCPED: Label 'CP..ED';
        XREVENUEI: Label 'REVENUEI';
        XRevenuefromSalesItem: Label 'Revenue from Items Sales';
        XREVENUE: Label 'REVENUE';
        XRevenuefromSales: Label 'Revenue from Sales';

    procedure InsertNormJurisdiction("Code": Code[10]; Description: Text[50])
    var
        NormJurisdiction: Record "Tax Register Norm Jurisdiction";
    begin
        NormJurisdiction.Init();
        NormJurisdiction.Code := Code;
        NormJurisdiction.Description := Description;
        NormJurisdiction.Insert();
    end;

    procedure InsertNormGroup(NormJurisdictionCode: Code[10]; "Code": Code[10]; Description: Text[50]; SearchDetail: Integer; StoringMethod: Integer)
    var
        NormGroup: Record "Tax Register Norm Group";
    begin
        NormGroup.Init();
        NormGroup."Norm Jurisdiction Code" := NormJurisdictionCode;
        NormGroup.Code := Code;
        NormGroup.Description := Description;
        NormGroup."Search Detail" := SearchDetail;
        NormGroup."Storing Method" := StoringMethod;
        NormGroup.Insert();
    end;

    procedure InsertNormDetail(NormJurisdictionCode: Code[10]; NormGroupCode: Code[10]; EffectiveDate: Date; Norm: Decimal)
    var
        NormDetail: Record "Tax Register Norm Detail";
    begin
        NormDetail.Init();
        NormDetail."Norm Jurisdiction Code" := NormJurisdictionCode;
        NormDetail."Norm Group Code" := NormGroupCode;
        NormDetail."Effective Date" := MakeAdjustments.AdjustDate(EffectiveDate);
        NormDetail.Norm := Norm;
        NormDetail.Insert();
    end;

    procedure InsertNormTermName(NormJurisdictionCode: Code[10]; TermCode: Code[10]; Description: Text[250])
    var
        NormTermName: Record "Tax Reg. Norm Term";
    begin
        NormTermName.Init();
        NormTermName.Validate("Norm Jurisdiction Code", NormJurisdictionCode);
        NormTermName.Validate("Term Code", TermCode);
        NormTermName.Validate(Description, Description);
        NormTermName.Insert();
    end;

    procedure InsertNormTermLine(NormJurisdictionCode: Code[10]; TermCode: Code[10]; LineNo: Integer; Operation: Integer; AccountType: Integer; AccountNo: Code[20]; AmountType: Integer)
    var
        NormTermLine: Record "Tax Reg. Norm Term Formula";
    begin
        NormTermLine.Init();
        NormTermLine.Validate("Norm Jurisdiction Code", NormJurisdictionCode);
        NormTermLine.Validate("Term Code", TermCode);
        NormTermLine.Validate("Line No.", LineNo);
        NormTermLine.Validate(Operation, Operation);
        NormTermLine.Validate("Account Type", AccountType);
        NormTermLine.Validate("Account No.", AccountNo);
        NormTermLine.Validate("Amount Type", AmountType);
        NormTermLine.Insert();
    end;

    procedure InsertNormTempLine(NormJurisdictionCode: Code[10]; NormGroupCode: Code[10]; LineNo: Integer; LineType: Integer; Description: Text[150]; LineCode: Code[10]; ExpressionType: Integer; Expression: Text[150]; JurisdictionCode: Code[10]; LinkGroupCode: Code[10]; LinkLineCode: Code[10]; Period: Code[30])
    var
        NormTempLine: Record "Tax Reg. Norm Template Line";
    begin
        NormTempLine.Init();
        NormTempLine.Validate("Norm Jurisdiction Code", NormJurisdictionCode);
        NormTempLine.Validate("Norm Group Code", NormGroupCode);
        NormTempLine.Validate("Line No.", LineNo);
        NormTempLine.Validate("Line Code", LineCode);
        NormTempLine.Validate("Line Type", LineType);
        NormTempLine.Validate(Description, Description);
        NormTempLine.Validate("Expression Type", ExpressionType);
        NormTempLine.Validate(Expression, Expression);
        NormTempLine.Validate("Jurisdiction Code", JurisdictionCode);
        NormTempLine.Validate("Link Group Code", LinkGroupCode);
        NormTempLine.Validate("Link Line Code", LinkLineCode);
        NormTempLine.Validate(Period, Period);
        NormTempLine.Insert();
    end;
}


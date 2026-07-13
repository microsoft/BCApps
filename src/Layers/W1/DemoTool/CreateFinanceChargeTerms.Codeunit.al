codeunit 101005 "Create Finance Charge Terms"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(
          X1point5DOM, X1POINT5PCTforDomCustomers, 1.5, 30, 86, 86, '<5D>', '<1M>', XPCT4PCTfinancechargeofPCT6, XSumfinancechargeofPCT5);
        InsertData(
          X2POINT0FOR, X2POINT0PCTforForCustomers, 2, 30, 0, 0, '<7D>', '<1M>', XPCT4PCTfinancechargeofPCT6, XSumfinancechargeofPCT5);
    end;

    var
        "Finance Charge": Record "Finance Charge Terms";
        DemoDataSetup: Record "Demo Data Setup";
        X1point5DOM: Label '1.5 DOM.';
        XPCT4PCTfinancechargeofPCT6: Label '%4% finance charge of %6';
        X1POINT5PCTforDomCustomers: Label '1.5 % for Domestic Customers';
        X2POINT0FOR: Label '2.0 FOR.';
        X2POINT0PCTforForCustomers: Label '2.0 % for Foreign Customers';
        XSumfinancechargeofPCT5: Label 'Sum finance charge of %5', Comment = '%5 - amount';

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        InsertData(
          X1point5DOM, X1POINT5PCTforDomCustomers, 1.5, 30, 0, 0, '<5D>', '<1M>', XPCT4PCTfinancechargeofPCT6, XSumfinancechargeofPCT5);
        InsertData(
          X2POINT0FOR, X2POINT0PCTforForCustomers, 2, 30, 0, 0, '<7D>', '<1M>', XPCT4PCTfinancechargeofPCT6, XSumfinancechargeofPCT5);
    end;

    procedure InsertData("Code": Code[10]; Description: Text[30]; "Interest Rate": Decimal; "Interest Period": Integer; "Minimum Amount": Decimal; "Additional Fee": Decimal; "Grace Period": Code[20]; "Due Date Calculation": Code[20]; "Line Description": Text[30]; MultipleLinesDescription: Text[30])
    begin
        "Finance Charge".Init();
        "Finance Charge".Validate(Code, Code);
        "Finance Charge".Validate("Interest Rate", "Interest Rate");
        "Finance Charge".Validate("Interest Period (Days)", "Interest Period");

        Evaluate("Finance Charge"."Grace Period", "Grace Period");
        "Finance Charge".Validate("Grace Period");

        Evaluate("Finance Charge"."Due Date Calculation", "Due Date Calculation");
        "Finance Charge".Validate("Due Date Calculation");

        "Finance Charge".Validate(Description, Description);
        "Finance Charge".Validate("Line Description", "Line Description");
        "Finance Charge".Validate("Detailed Lines Description", MultipleLinesDescription);
        "Finance Charge".Validate(
          "Minimum Amount (LCY)",
          Round("Minimum Amount" * DemoDataSetup."Local Currency Factor", DemoDataSetup."Local Precision Factor"));
        "Finance Charge".Validate(
          "Additional Fee (LCY)",
          Round("Additional Fee" * DemoDataSetup."Local Currency Factor", DemoDataSetup."Local Precision Factor"));

        "Finance Charge".Insert();
    end;
}


codeunit 101345 "Create Analysis View"
{

    trigger OnRun()
    var
        AnalysisView: Record "Analysis View";
        Adjust: Codeunit "Make Adjustments";
    begin
        InsertAnalysisView(
          XCUSTOMER, XCustomerGroupAnalysis, false,
          Adjust.Convert('996100') + '..' + Adjust.Convert('996995'),
          Adjust.AdjustDate(19030101D), 3, false, XAREA, XCUSTOMERGROUP, '', '',
          AnalysisView."Account Source"::"G/L Account");
        InsertAnalysisView(
          XCAMPAIGN, XCampaignAnalysisRetail, false,
          Adjust.Convert('996100') + '..' + Adjust.Convert('996995') + '|' +
          Adjust.Convert('997100') + '..' + Adjust.Convert('997995'),
          Adjust.AdjustDate(19030101D), 2, false, XSALESCAMPAIGN, XAREA, XBUSINESSGROUP, XSALESPERSON,
          AnalysisView."Account Source"::"G/L Account");
        InsertAnalysisView(
          XREVENUE, XSalesRevenue, false,
          Adjust.Convert('996100') + '..' + Adjust.Convert('996995'),
          Adjust.AdjustDate(19020101D), 3, true, XAREA, XDEPARTMENT, XPROJECT, '',
          AnalysisView."Account Source"::"G/L Account");
        InsertAnalysisView(
          XDEPTEXP, XDepartmentalExpenses, false,
          Adjust.Convert('997100') + '..' + Adjust.Convert('998790'),
          Adjust.AdjustDate(19020101D), 3, true, XDEPARTMENT, '', '', '',
          AnalysisView."Account Source"::"G/L Account");

        InsertAnalysisView(
          XCASHFLOW, XAnalysisOfCashReceipts,
          false,
          '0009..0999',
          Adjust.AdjustDate(DMY2Date(1, 1, 1903)),
          AnalysisView."Date Compression"::Month,
          false,
          XDEPARTMENT, XAREA, '', '',
          AnalysisView."Account Source"::"Cash Flow Account");
    end;

    var
        XCUSTOMER: Label 'CUSTOMER';
        XCustomerGroupAnalysis: Label 'Customer Group Analysis';
        XAREA: Label 'AREA';
        XCUSTOMERGROUP: Label 'CUSTOMERGROUP';
        XCAMPAIGN: Label 'CAMPAIGN';
        XCampaignAnalysisRetail: Label 'Campaign Analysis (Retail)';
        XSALESCAMPAIGN: Label 'SALESCAMPAIGN';
        XBUSINESSGROUP: Label 'BUSINESSGROUP';
        XSALESPERSON: Label 'SALESPERSON';
        XREVENUE: Label 'REVENUE';
        XSalesRevenue: Label 'Sales Revenue';
        XDEPARTMENT: Label 'DEPARTMENT';
        XPROJECT: Label 'PROJECT';
        XDEPTEXP: Label 'DEPTEXP';
        XDepartmentalExpenses: Label 'Departmental Expenses';
        XCASHFLOW: Label 'CASHFLOW', Comment = 'Cashflow is a name of Analysis View Code.';
        XAnalysisOfCashReceipts: Label 'Analysis of cash receipts';
        XGLCODE: Label 'GEN_LEDGER', Comment = 'General Ledger is a name of Analysis View Code.';
        XGLNAME: Label 'General Ledger';

    procedure InsertAnalysisView("Code": Code[10]; Name: Text[50]; UpdateOnPosting: Boolean; AccFilter: Code[250]; StartDate: Date; DateCompr: Option "None",Day,Week,Month,Quarter,Year,Period; IncludeBudget: Boolean; Dim1Code: Code[20]; Dim2Code: Code[20]; Dim3Code: Code[20]; Dim4Code: Code[20]; AccountSource: Enum "Analysis Account Source")
    var
        AnalysisView: Record "Analysis View";
    begin
        AnalysisView.Init();
        AnalysisView.Validate(Code, Code);
        AnalysisView.Validate(Name, Name);
        AnalysisView.Validate("Update on Posting", UpdateOnPosting);
        AnalysisView.Validate("Account Filter", AccFilter);
        AnalysisView."Account Source" := AccountSource;
        AnalysisView.Validate("Starting Date", StartDate);
        AnalysisView.Validate("Date Compression", DateCompr);
        AnalysisView.Validate("Include Budgets", IncludeBudget);
        AnalysisView.Insert(true);
        AnalysisView.Validate("Dimension 1 Code", Dim1Code);
        AnalysisView.Validate("Dimension 2 Code", Dim2Code);
        AnalysisView.Validate("Dimension 3 Code", Dim3Code);
        AnalysisView.Validate("Dimension 4 Code", Dim4Code);
        AnalysisView.Modify();
    end;

    procedure CreateEvaluationData()
    var
        AnalysisView: Record "Analysis View";
        Adjust: Codeunit "Make Adjustments";
    begin
        InsertAnalysisView(
          XGLCODE, XGLNAME, false, '',
          Adjust.AdjustDate(DMY2Date(1, 1, 1902)), AnalysisView."Date Compression"::Day, false, '', '', '', '',
          AnalysisView."Account Source"::"G/L Account");
        InsertAnalysisView(
          XREVENUE, XSalesRevenue, false,
          '40000..49999',
          Adjust.AdjustDate(DMY2Date(1, 1, 1902)), AnalysisView."Date Compression"::Day, false, XAREA, XDEPARTMENT, XCUSTOMERGROUP, '',
          AnalysisView."Account Source"::"G/L Account");
    end;
}


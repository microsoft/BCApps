codeunit 101752 "Create Item Analysis View"
{

    trigger OnRun()
    begin
        InsertData(0, XCUSTOMERS, XCustomers1, false, false, 1, XCUSTOMERGROUP, XSALESPERSON, '', true, false);
        InsertData(0, XDEFAULT, XDefaultanalysisview, false, false, 1, XAREA, XCUSTOMERGROUP, XSALESPERSON, false, false);
        InsertData(1, XDEFAULT, XDefaultanalysisview, false, false, 1, XAREA, XPURCHASER, XPROJECT, false, false);
        InsertData(2, XDEFAULT, XDefaultanalysisview, false, false, 1, XAREA, XCUSTOMERGROUP, XSALESPERSON, false, false);
    end;

    var
        ItemAnalysisView: Record "Item Analysis View";
        XCUSTOMERS: Label 'CUSTOMERS';
        XDEFAULT: Label 'DEFAULT';
        XCustomers1: Label 'Customers';
        XDefaultanalysisview: Label 'Default analysis view';
        XCUSTOMERGROUP: Label 'CUSTOMERGROUP';
        XAREA: Label 'AREA';
        XSALESPERSON: Label 'SALESPERSON';
        XPURCHASER: Label 'PURCHASER';
        XPROJECT: Label 'PROJECT';

    procedure InsertData(AnalysisArea: Option Sales,Purchase,Inventory; "Code": Code[10]; Name: Text[50]; UpdateOnPosting: Boolean; Blocked: Boolean; DateCompression: Option "None",Day,Week,Month,Quarter,Year,Period; Dim1Code: Code[20]; Dim2Code: Code[20]; Dim3Code: Code[20]; IncludeBudgets: Boolean; RefreshBlocked: Boolean)
    begin
        ItemAnalysisView.Init();
        ItemAnalysisView.Validate("Analysis Area", AnalysisArea);
        ItemAnalysisView.Validate(Code, Code);
        ItemAnalysisView.Insert(true);
        ItemAnalysisView.Validate(Name, Name);
        ItemAnalysisView.Validate("Update on Posting", UpdateOnPosting);
        ItemAnalysisView.Validate(Blocked, Blocked);
        ItemAnalysisView.Validate("Date Compression", DateCompression);
        ItemAnalysisView.Validate("Dimension 1 Code", Dim1Code);
        ItemAnalysisView.Validate("Dimension 2 Code", Dim2Code);
        ItemAnalysisView.Validate("Dimension 3 Code", Dim3Code);
        ItemAnalysisView.Validate("Include Budgets", IncludeBudgets);
        ItemAnalysisView.Validate("Refresh When Unblocked", RefreshBlocked);
        ItemAnalysisView.Modify(true);
    end;
}


codeunit 101571 "Create Campaign"
{

    trigger OnRun()
    begin
        InsertData(XCP1001, XIncreasesale, 19021101D, 19030401D, XHR, XCAMP, XSALES, '', X5START);
        InsertData(XCP1002, XEvent, 19030118D, 19030121D, XBC, XCAMP, XSALES, '', X9DONE);
        InsertData(XCP1003, XWorkingplacearrangement, 19030108D, 19030401D, XOF, XCAMP, XSALES, '', X5START);
        InsertData(XCP1004, XSpringoffer, 19030301D, 19030601D, XBC, XCAMP, XSALES, '', X1PLAN);
    end;

    var
        Campaign: Record Campaign;
        XCP1001: Label 'CP1001';
        XIncreasesale: Label 'Increase sale';
        XHR: Label 'HR';
        XCAMP: Label 'CAMP';
        XSALES: Label 'SALES';
        X5START: Label '5-START';
        XCP1002: Label 'CP1002';
        XEvent: Label 'Event';
        XBC: Label 'BC';
        X9DONE: Label '9-DONE';
        XCP1003: Label 'CP1003';
        XWorkingplacearrangement: Label 'Working place arrangement';
        XOF: Label 'OF';
        XCP1004: Label 'CP1004';
        XSpringoffer: Label 'Spring offer';
        X1PLAN: Label '1-PLAN';
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure InsertData("No.": Code[10]; Description: Text[50]; "Starting Date": Date; "Ending Date": Date; "Salesperson Code": Code[10]; "No. Series": Code[10]; "Global Dimension 1 Code": Code[10]; "Global Dimension 2 Code": Code[10]; "Status Code": Code[10])
    begin
        Campaign.Init();
        Campaign.Validate("No.", "No.");
        Campaign.Validate(Description, Description);
        Campaign.Validate("Starting Date", MakeAdjustments.AdjustDate("Starting Date"));
        Campaign.Validate("Ending Date", MakeAdjustments.AdjustDate("Ending Date"));
        Campaign.Validate("Salesperson Code", "Salesperson Code");
        Campaign.Validate("No. Series", "No. Series");
        Campaign.Validate("Status Code", "Status Code");
        Campaign.Insert();
        Campaign.Validate("Global Dimension 1 Code", "Global Dimension 1 Code");
        Campaign.Validate("Global Dimension 2 Code", "Global Dimension 2 Code");
        Campaign.Modify();
    end;

    procedure CreateEvaluationData()
    begin
        InsertData(XCP1001, XIncreasesale, 19021101D, 19030401D, XHR, XCAMP, '', '', X5START);
        InsertData(XCP1002, XEvent, 19030118D, 19030121D, XBC, XCAMP, '', '', X9DONE);
        InsertData(XCP1003, XWorkingplacearrangement, 19030108D, 19030401D, XOF, XCAMP, '', '', X5START);
    end;
}


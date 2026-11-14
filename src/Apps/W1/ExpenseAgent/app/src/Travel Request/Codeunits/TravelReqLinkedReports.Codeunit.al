// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.SpendRequest;

/// <summary>
/// Finds and shows the expense reports linked to a travel request, either on the report header or on any of its lines.
/// </summary>
codeunit 6914 "Travel Req. Linked Reports"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Spend Request" = r;

    procedure ShowExpenseReports(TravelRequestNo: Code[20])
    var
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        MarkLinkedExpenseReports(ExpenseReportHeader, TravelRequestNo);
        Page.Run(Page::"Expense Reports", ExpenseReportHeader);
    end;

    procedure ShowPostedExpenseReports(TravelRequestNo: Code[20])
    var
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
    begin
        MarkLinkedPostedExpenseReports(PostedExpenseReportHeader, TravelRequestNo);
        Page.Run(Page::"Posted Expense Reports", PostedExpenseReportHeader);
    end;

    procedure ShowExpenseReportsFromError(LinkedReportError: ErrorInfo)
    var
        SpendRequest: Record "Spend Request";
    begin
        SpendRequest.Get(LinkedReportError.RecordId);
        ShowExpenseReports(SpendRequest."No.");
    end;

    procedure ShowPostedExpenseReportsFromError(LinkedReportError: ErrorInfo)
    var
        SpendRequest: Record "Spend Request";
    begin
        SpendRequest.Get(LinkedReportError.RecordId);
        ShowPostedExpenseReports(SpendRequest."No.");
    end;

    local procedure MarkLinkedExpenseReports(var ExpenseReportHeader: Record "Expense Report Header"; TravelRequestNo: Code[20])
    var
        ExpenseReportLine: Record "Expense Report Line";
        LastDocumentNo: Code[20];
    begin
        ExpenseReportHeader.SetLoadFields("No.");
        ExpenseReportHeader.SetRange("Spend Request No.", TravelRequestNo);
        if ExpenseReportHeader.FindSet() then
            repeat
                ExpenseReportHeader.Mark(true);
            until ExpenseReportHeader.Next() = 0;
        ExpenseReportHeader.SetRange("Spend Request No.");

        // Lines come in document order, so each linked report header is read only once.
        LastDocumentNo := '';
        ExpenseReportLine.SetLoadFields("Document No.");
        ExpenseReportLine.SetRange("Spend Request No.", TravelRequestNo);
        if ExpenseReportLine.FindSet() then
            repeat
                if ExpenseReportLine."Document No." <> LastDocumentNo then begin
                    LastDocumentNo := ExpenseReportLine."Document No.";
                    if ExpenseReportHeader.Get(LastDocumentNo) then
                        ExpenseReportHeader.Mark(true);
                end;
            until ExpenseReportLine.Next() = 0;

        // The page shows the marked reports with all their fields.
        ExpenseReportHeader.SetLoadFields();
        ExpenseReportHeader.MarkedOnly(true);
    end;

    local procedure MarkLinkedPostedExpenseReports(var PostedExpenseReportHeader: Record "Posted Expense Report Header"; TravelRequestNo: Code[20])
    var
        PostedExpenseReportLine: Record "Posted Expense Report Line";
        LastDocumentNo: Code[20];
    begin
        // Canceled reports no longer use the travel request, so they are left out.
        PostedExpenseReportHeader.SetLoadFields("No.", Canceled);
        PostedExpenseReportHeader.SetRange("Spend Request No.", TravelRequestNo);
        PostedExpenseReportHeader.SetRange(Canceled, false);
        if PostedExpenseReportHeader.FindSet() then
            repeat
                PostedExpenseReportHeader.Mark(true);
            until PostedExpenseReportHeader.Next() = 0;
        PostedExpenseReportHeader.SetRange("Spend Request No.");

        // Lines come in document order, so each linked report header is read only once.
        LastDocumentNo := '';
        PostedExpenseReportLine.SetLoadFields("Document No.");
        PostedExpenseReportLine.SetRange("Spend Request No.", TravelRequestNo);
        PostedExpenseReportLine.SetRange("Is Canceled", false);
        if PostedExpenseReportLine.FindSet() then
            repeat
                if PostedExpenseReportLine."Document No." <> LastDocumentNo then begin
                    LastDocumentNo := PostedExpenseReportLine."Document No.";
                    if PostedExpenseReportHeader.Get(LastDocumentNo) then
                        if not PostedExpenseReportHeader.Canceled then
                            PostedExpenseReportHeader.Mark(true);
                end;
            until PostedExpenseReportLine.Next() = 0;

        // The page shows the marked reports with all their fields.
        PostedExpenseReportHeader.SetLoadFields();
        PostedExpenseReportHeader.MarkedOnly(true);
    end;
}

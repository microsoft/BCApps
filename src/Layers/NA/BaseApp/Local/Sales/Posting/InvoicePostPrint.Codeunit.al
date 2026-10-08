// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 10022 "Invoice-Post + Print"
{
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        SalesHeader.Copy(Rec);
        Code();
        Rec := SalesHeader;
    end;

    var
        SalesHeader: Record "Sales Header";
        SalesShptHeader: Record "Sales Shipment Header";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnRcptHeader: Record "Return Receipt Header";
        ReportSelection: Record "Report Selections";
        SalesPost: Codeunit "Sales-Post";
        Text1020001: Label 'Do you want to invoice and print the %1?';

    local procedure "Code"()
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
            if not Confirm(Text1020001, false, SalesHeader."Document Type") then
                exit;
            SalesHeader.Ship := false;
            SalesHeader.Invoice := true;
            SalesPost.Run(SalesHeader);

            SalesInvHeader."No." := SalesHeader."Last Posting No.";
            SalesInvHeader.SetRecFilter();
            PrintReport(ReportSelection.Usage::"S.Invoice");
        end;
    end;

    local procedure PrintReport(ReportUsage: Enum "Report Selection Usage")
    begin
        ReportSelection.Reset();
        ReportSelection.SetRange(Usage, ReportUsage);
        ReportSelection.Find('-');
        repeat
            ReportSelection.TestField("Report ID");
            case ReportUsage of
                ReportSelection.Usage::"S.Invoice":
                    REPORT.Run(ReportSelection."Report ID", false, false, SalesInvHeader);
                ReportSelection.Usage::"S.Cr.Memo":
                    REPORT.Run(ReportSelection."Report ID", false, false, SalesCrMemoHeader);
                ReportSelection.Usage::"S.Shipment":
                    REPORT.Run(ReportSelection."Report ID", false, false, SalesShptHeader);
                ReportSelection.Usage::"S.Ret.Rcpt.":
                    REPORT.Run(ReportSelection."Report ID", false, false, ReturnRcptHeader);
            end;
        until ReportSelection.Next() = 0;
    end;
}


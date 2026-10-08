// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.CashDesk;

codeunit 11772 "Cash Document-Release Send CZP"
{
    TableNo = "Cash Document Header CZP";

    trigger OnRun()
    begin
        GlobalCashDocumentHeaderCZP.Copy(Rec);
        Code();
        Rec := GlobalCashDocumentHeaderCZP;
    end;

    var
        GlobalCashDocumentHeaderCZP: Record "Cash Document Header CZP";
        ApprovalProcessErr: Label 'This document can only be released when the approval process is complete.';

    local procedure Code()
    begin
        Codeunit.Run(Codeunit::"Cash Document-Release CZP", GlobalCashDocumentHeaderCZP);
        Commit();
        if (GlobalCashDocumentHeaderCZP."Document Type" = GlobalCashDocumentHeaderCZP."Document Type"::Receipt) and
           (GlobalCashDocumentHeaderCZP."Partner Type" = GlobalCashDocumentHeaderCZP."Partner Type"::Customer) and
           (GlobalCashDocumentHeaderCZP."Partner No." <> '')
        then
            SendRecord(GlobalCashDocumentHeaderCZP);
    end;

    procedure PerformManualRelease(var CashDocumentHeaderCZP: Record "Cash Document Header CZP")
    var
        CashDocumentApprovMgtCZP: Codeunit "Cash Document Approv. Mgt. CZP";
    begin
        if CashDocumentApprovMgtCZP.IsCashDocApprovalsWorkflowEnabled(CashDocumentHeaderCZP) and
           (CashDocumentHeaderCZP.Status = CashDocumentHeaderCZP.Status::Open)
        then
            Error(ApprovalProcessErr);

        Codeunit.Run(Codeunit::"Cash Document-Release Send CZP", CashDocumentHeaderCZP);
    end;

    local procedure SendRecord(var CashDocumentHeaderCZP: Record "Cash Document Header CZP")
    begin
        CashDocumentHeaderCZP.Reset();
        CashDocumentHeaderCZP.SetRecFilter();
        CashDocumentHeaderCZP.SendRecords();
    end;
}

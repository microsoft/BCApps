// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.CashDesk;

codeunit 11773 "Cash Document-Post + Send CZP"
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
        WithoutConfirmation: Boolean;

    procedure PostWithoutConfirmation(var ParmCashDocumentHeaderCZP: Record "Cash Document Header CZP")
    begin
        WithoutConfirmation := true;
        GlobalCashDocumentHeaderCZP.Copy(ParmCashDocumentHeaderCZP);
        Code();
        ParmCashDocumentHeaderCZP := GlobalCashDocumentHeaderCZP;
    end;

    local procedure Code()
    begin
        if WithoutConfirmation then
            Codeunit.Run(Codeunit::"Cash Document-Post CZP", GlobalCashDocumentHeaderCZP)
        else
            Codeunit.Run(Codeunit::"Cash Document-Post(Yes/No) CZP", GlobalCashDocumentHeaderCZP);
        Commit();
        if (GlobalCashDocumentHeaderCZP."Document Type" = GlobalCashDocumentHeaderCZP."Document Type"::Receipt) and
           (GlobalCashDocumentHeaderCZP."Partner Type" = GlobalCashDocumentHeaderCZP."Partner Type"::Customer) and
           (GlobalCashDocumentHeaderCZP."Partner No." <> '')
        then
            SendPostedDocument(GlobalCashDocumentHeaderCZP);
    end;

    local procedure SendPostedDocument(var CashDocumentHeaderCZP: Record "Cash Document Header CZP")
    var
        PostedCashDocumentHdrCZP: Record "Posted Cash Document Hdr. CZP";
    begin
        PostedCashDocumentHdrCZP.Get(CashDocumentHeaderCZP."Cash Desk No.", CashDocumentHeaderCZP."No.");
        PostedCashDocumentHdrCZP.SetRecFilter();
        PostedCashDocumentHdrCZP.SendRecords();
    end;
}

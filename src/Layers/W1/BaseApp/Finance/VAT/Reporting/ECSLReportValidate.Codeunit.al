// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Utilities;

codeunit 143 "ECSL Report Validate"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    begin
        ErrorMessage.SetContext(Rec.RecordId);
        ErrorMessage.ClearLog();

        if not Rec.IsPeriodValid() then begin
            ErrorMessage.LogMessage(Rec, Rec.FieldNo("No."), ErrorMessage."Message Type"::Error, InvalidPeriodErr);
            exit;
        end;

        ValidateVATReportHasLine(Rec);
        CheckVATRegNoOnLines(Rec);
        CheckZeroAmountOnLines(Rec);
    end;

    var
        ErrorMessage: Record "Error Message";

        NoLineFoundErr: Label 'You cannot release a blank VAT report.';
#pragma warning disable AA0470
        ZeroTotalValueErr: Label 'You cannot release the report because line No. %1 has zero as the Total Value Of Supplies.', Comment = 'Placeholder 1 holds the line no that cause the error';
        NoVatRegNoErr: Label 'You cannot release the report because line No. %1 is missing a VAT Registration Number. You need to correct this on the sales document and post it again.', Comment = 'Placeholder 1 holds the line no that cause the error';
#pragma warning restore AA0470
        InvalidPeriodErr: Label 'The period is not valid.';

    local procedure ValidateVATReportHasLine(VATReportHeader: Record "VAT Report Header")
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
    begin
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        if ECSLVATReportLine.Count = 0 then
            ErrorMessage.LogMessage(VATReportHeader, VATReportHeader.FieldNo("No."), ErrorMessage."Message Type"::Error, NoLineFoundErr);
    end;

    local procedure CheckVATRegNoOnLines(VATReportHeader: Record "VAT Report Header")
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
    begin
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        ECSLVATReportLine.SetRange("Customer VAT Reg. No.", '');
        if ECSLVATReportLine.FindSet() then
            repeat
                ErrorMessage.LogMessage(ECSLVATReportLine, ECSLVATReportLine.FieldNo("Customer VAT Reg. No."),
                  ErrorMessage."Message Type"::Error, StrSubstNo(NoVatRegNoErr, ECSLVATReportLine."Line No."));
            until ECSLVATReportLine.Next() = 0;
    end;

    local procedure CheckZeroAmountOnLines(VATReportHeader: Record "VAT Report Header")
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
    begin
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        ECSLVATReportLine.SetRange("Total Value Of Supplies", 0);

        if ECSLVATReportLine.FindSet() then
            repeat
                ErrorMessage.LogMessage(ECSLVATReportLine, ECSLVATReportLine.FieldNo("Total Value Of Supplies"),
                  ErrorMessage."Message Type"::Error, StrSubstNo(ZeroTotalValueErr, ECSLVATReportLine."Line No."));
            until ECSLVATReportLine.Next() = 0;
    end;
}


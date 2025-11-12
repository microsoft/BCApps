// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

codeunit 744 "VAT Report Validate"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    begin
        ClearErrorLog();

        ValidateVATReportLinesExists(Rec);
        ValidateVATReportHeader();
        ValidateVATReportLines();

        ShowErrorLog();
    end;

    var
        TempVATReportErrorLog: Record "VAT Report Error Log" temporary;
        VATStatementReportLine: Record "VAT Statement Report Line";
        ErrorID: Integer;

#pragma warning disable AA0074
        Text000: Label 'You cannot release the VAT report because no lines exist.';
#pragma warning restore AA0074

    local procedure ClearErrorLog()
    begin
        TempVATReportErrorLog.Reset();
        TempVATReportErrorLog.DeleteAll();
    end;

    local procedure InsertErrorLog(ErrorMessage: Text[250])
    begin
        if TempVATReportErrorLog.FindLast() then
            ErrorID := TempVATReportErrorLog."Entry No." + 1
        else
            ErrorID := 1;

        TempVATReportErrorLog.Init();
        TempVATReportErrorLog."Entry No." := ErrorID;
        TempVATReportErrorLog."Error Message" := ErrorMessage;
        TempVATReportErrorLog.Insert();
    end;

    local procedure ShowErrorLog()
    begin
        if not TempVATReportErrorLog.IsEmpty() then begin
            PAGE.Run(PAGE::"VAT Report Error Log", TempVATReportErrorLog);
            Error('');
        end;
    end;

    local procedure ValidateVATReportLinesExists(VATReportHeader: Record "VAT Report Header")
    begin
        VATStatementReportLine.SetRange("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code");
        VATStatementReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        if VATStatementReportLine.IsEmpty() then begin
            InsertErrorLog(Text000);
            ShowErrorLog();
        end;
    end;

    local procedure ValidateVATReportHeader()
    begin
    end;

    local procedure ValidateVATReportLines()
    begin
    end;
}


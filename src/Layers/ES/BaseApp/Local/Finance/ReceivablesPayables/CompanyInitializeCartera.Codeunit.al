// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 7000010 "Company-Initialize Cartera"
{

    trigger OnRun()
    begin
        if not CarteraSetup.FindFirst() then begin
            CarteraSetup.Init();
            CarteraSetup.Insert();
        end;

        InsertSourceCode(SourceCodeSetup."Cartera Journal", Text1100000, Text1100001);

        if not CarteraReportSelection.FindFirst() then begin
            InsertBGPORepSelection(CarteraReportSelection.Usage::"Bill Group", '1', REPORT::"Bill Group Listing");
            InsertBGPORepSelection(CarteraReportSelection.Usage::"Posted Bill Group", '1', REPORT::"Posted Bill Group Listing");
            InsertBGPORepSelection(CarteraReportSelection.Usage::"Closed Bill Group", '1', REPORT::"Closed Bill Group Listing");
            InsertBGPORepSelection(CarteraReportSelection.Usage::Bill, '1', REPORT::"Receivable Bill");
            InsertBGPORepSelection(CarteraReportSelection.Usage::"Bill Group - Test", '1', REPORT::"Bill Group - Test");
            InsertBGPORepSelection(CarteraReportSelection.Usage::"Posted Payment Order", '1', REPORT::"Posted Payment Order Listing");
            InsertBGPORepSelection(CarteraReportSelection.Usage::"Closed Payment Order", '1', REPORT::"Closed Payment Order Listing");
            InsertBGPORepSelection(CarteraReportSelection.Usage::"Payment Order", '1', REPORT::"Payment Order Listing");
            InsertBGPORepSelection(CarteraReportSelection.Usage::"Payment Order - Test", '1', REPORT::"Payment Order - Test");
        end;
    end;

    var
        Text1100000: Label 'CARJNL';
        CarteraSetup: Record "Cartera Setup";
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
        CarteraReportSelection: Record "Cartera Report Selections";
        Text1100001: Label 'Cartera Journal';

    local procedure InsertSourceCode(var SourceCodeDefCode: Code[10]; "Code": Code[10]; Description: Text[50])
    begin
        SourceCodeDefCode := Code;
        SourceCode.Init();
        SourceCode.Code := Code;
        SourceCode.Description := Description;
        if SourceCode.Insert() then;
    end;

    local procedure InsertBGPORepSelection(ReportUsage: Enum "Report Selection Usage Cartera"; Sequence: Code[10]; ReportID: Integer)
    begin
        CarteraReportSelection.Init();
        CarteraReportSelection.Usage := ReportUsage;
        CarteraReportSelection.Sequence := Sequence;
        CarteraReportSelection."Report ID" := ReportID;
        CarteraReportSelection.Insert();
    end;
}


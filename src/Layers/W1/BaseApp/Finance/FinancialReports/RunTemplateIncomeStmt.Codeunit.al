#if not CLEAN26
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.Environment;
using System.Integration;
using System.Telemetry;

codeunit 577 "Run Template Income Stmt."
{
    ObsoleteReason = 'This report is deprecated and will be removed in a future release.';
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';

    trigger OnRun()
    var
        ODataUtility: Codeunit ODataUtility;
        ObjectTypeParam: Option ,,,,,,,,"Page","Query";
        StatementType: Option BalanceSheet,SummaryTrialBalance,CashFlowStatement,StatementOfRetainedEarnings,AgedAccountsReceivable,AgedAccountsPayable,IncomeStatement;
    begin
        LogUsageTelemetry();
        if not (ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Phone, CLIENTTYPE::Tablet]) then
            ODataUtility.GenerateExcelTemplateWorkBook(ObjectTypeParam::Page, ServiceNameParmLbl, true,
              StatementType::IncomeStatement)
        else begin
            Message(OfficeMobileMsg);
            exit;
        end;
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";

        OfficeMobileMsg: Label 'Excel Reports cannot be opened in this environment because this version of Office does not support the file format.';
        ServiceNameParmLbl: Label 'ExcelTemplateIncomeStatement', Locked = true;

    local procedure LogUsageTelemetry()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions.Add('CodeunitId', Format(Codeunit::"Run Template Income Stmt.", 0, 9));
        TelemetryDimensions.Add('ExcelTemplateName', ServiceNameParmLbl);
        FeatureTelemetry.LogUsage('0000ONV', 'Excel Template', 'Run Income Statement Excel Report', TelemetryDimensions);
    end;
}

#endif

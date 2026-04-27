// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

codeunit 683 "Upgrade Payment Practices"
{
    Access = Internal;
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        BackfillReportingScheme();
    end;

    local procedure BackfillReportingScheme()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        PaymentPeriodMgt: Codeunit "Payment Period Mgt.";
        ReportingScheme: Enum "Paym. Prac. Reporting Scheme";
    begin
        ReportingScheme := PaymentPeriodMgt.DetectReportingScheme();

        PaymentPracticeHeader.SetRange("Reporting Scheme", 0);
        if PaymentPracticeHeader.FindSet() then
            repeat
                PaymentPracticeHeader."Reporting Scheme" := ReportingScheme;
                PaymentPracticeHeader.Modify();
            until PaymentPracticeHeader.Next() = 0;
    end;
}

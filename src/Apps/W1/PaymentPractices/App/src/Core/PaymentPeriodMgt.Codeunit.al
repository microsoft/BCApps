// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using System.Environment;

codeunit 695 "Payment Period Mgt."
{
    Access = Internal;

    procedure InsertDefaultTemplate(): Code[20]
    begin
        exit(InsertDefaultTemplate(DetectReportingScheme()));
    end;

    procedure InsertDefaultTemplate(ReportingScheme: Enum "Paym. Prac. Reporting Scheme"): Code[20]
    var
        PaymentPeriodHeader: Record "Payment Period Header";
        PaymentPeriodLine: Record "Payment Period Line";
        TempPaymentPeriodLine: Record "Payment Period Line" temporary;
        DefaultPeriods: Interface PaymentPracticeDefaultPeriods;
        PeriodHeaderCode: Code[20];
        PeriodHeaderDescr: Text[250];
    begin
        DefaultPeriods := ReportingScheme;
        DefaultPeriods.GetDefaultPaymentPeriods(PeriodHeaderCode, PeriodHeaderDescr, TempPaymentPeriodLine);

        PaymentPeriodHeader.Init();
        PaymentPeriodHeader.Code := PeriodHeaderCode;
        PaymentPeriodHeader.Description := PeriodHeaderDescr;
        PaymentPeriodHeader."Reporting Scheme" := ReportingScheme;
        PaymentPeriodHeader.Default := true;
        PaymentPeriodHeader.Insert();

        TempPaymentPeriodLine.Reset();
        if TempPaymentPeriodLine.FindSet() then
            repeat
                PaymentPeriodLine.Init();
                PaymentPeriodLine."Period Header Code" := PeriodHeaderCode;
                PaymentPeriodLine."Line No." := TempPaymentPeriodLine."Line No.";
                PaymentPeriodLine."Days From" := TempPaymentPeriodLine."Days From";
                PaymentPeriodLine."Days To" := TempPaymentPeriodLine."Days To";
                PaymentPeriodLine.Description := TempPaymentPeriodLine.Description;
                PaymentPeriodLine.Insert();
            until TempPaymentPeriodLine.Next() = 0;

        exit(PeriodHeaderCode);
    end;

    procedure GetDefaultTemplateCode(): Code[20]
    var
        TempPaymentPeriodLine: Record "Payment Period Line" temporary;
        ReportingScheme: Enum "Paym. Prac. Reporting Scheme";
        DefaultPeriods: Interface PaymentPracticeDefaultPeriods;
        PeriodHeaderCode: Code[20];
        PeriodHeaderDescr: Text[250];
    begin
        ReportingScheme := DetectReportingScheme();
        DefaultPeriods := ReportingScheme;
        DefaultPeriods.GetDefaultPaymentPeriods(PeriodHeaderCode, PeriodHeaderDescr, TempPaymentPeriodLine);
        exit(PeriodHeaderCode);
    end;

    procedure DetectReportingScheme(): Enum "Paym. Prac. Reporting Scheme"
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        case EnvironmentInformation.GetApplicationFamily() of
            'GB':
                exit("Paym. Prac. Reporting Scheme"::"Dispute & Retention");
            'AU', 'NZ':
                exit("Paym. Prac. Reporting Scheme"::"Small Business");
            else
                exit("Paym. Prac. Reporting Scheme"::Standard);
        end;
    end;
}

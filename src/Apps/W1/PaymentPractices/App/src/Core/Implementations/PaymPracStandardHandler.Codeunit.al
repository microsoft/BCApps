// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using System.Environment;

codeunit 680 "Paym. Prac. Standard Handler" implements PaymentPracticeDefaultPeriods, PaymentPracticeSchemeHandler
{
    Access = Internal;

    procedure GetDefaultPaymentPeriods(var PeriodHeaderCode: Code[20]; var PeriodHeaderDescription: Text[250]; var TempPaymentPeriodLine: Record "Payment Period Line" temporary)
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        case EnvironmentInformation.GetApplicationFamily() of
            'FR':
                GetDefaultPeriods_FR(PeriodHeaderCode, PeriodHeaderDescription, TempPaymentPeriodLine);
            else
                GetDefaultPeriods_W1(PeriodHeaderCode, PeriodHeaderDescription, TempPaymentPeriodLine);
        end;
    end;

    procedure ValidateHeader(var PaymentPracticeHeader: Record "Payment Practice Header")
    begin
        // Standard scheme: no additional validation
    end;

    procedure UpdatePaymentPracData(var PaymentPracticeData: Record "Payment Practice Data"): Boolean
    begin
        exit(true);
    end;

    procedure CalculateHeaderTotals(var PaymentPracticeHeader: Record "Payment Practice Header"; var PaymentPracticeData: Record "Payment Practice Data")
    begin
        // Standard scheme: no additional header totals
    end;

    procedure CalculateLineTotals(var PaymentPracticeLine: Record "Payment Practice Line"; var PaymentPracticeData: Record "Payment Practice Data")
    begin
        // Standard scheme: no additional line totals
    end;

    local procedure GetDefaultPeriods_W1(var PeriodHeaderCode: Code[20]; var PeriodHeaderDescription: Text[250]; var TempPaymentPeriodLine: Record "Payment Period Line" temporary)
    begin
        PeriodHeaderCode := 'W1-DEFAULT';
        PeriodHeaderDescription := 'W1 Payment Periods (0-30, 31-60, 61-90, 91-120, 121+)';
        InsertTempLine(TempPaymentPeriodLine, 10000, 0, 30);
        InsertTempLine(TempPaymentPeriodLine, 20000, 31, 60);
        InsertTempLine(TempPaymentPeriodLine, 30000, 61, 90);
        InsertTempLine(TempPaymentPeriodLine, 40000, 91, 120);
        InsertTempLine(TempPaymentPeriodLine, 50000, 121, 0);
    end;

    local procedure GetDefaultPeriods_FR(var PeriodHeaderCode: Code[20]; var PeriodHeaderDescription: Text[250]; var TempPaymentPeriodLine: Record "Payment Period Line" temporary)
    begin
        PeriodHeaderCode := 'FR-DEFAULT';
        PeriodHeaderDescription := 'FR Payment Periods (0-30, 31-60, 61-90, 91+)';
        InsertTempLine(TempPaymentPeriodLine, 10000, 0, 30);
        InsertTempLine(TempPaymentPeriodLine, 20000, 31, 60);
        InsertTempLine(TempPaymentPeriodLine, 30000, 61, 90);
        InsertTempLine(TempPaymentPeriodLine, 40000, 91, 0);
    end;

    local procedure InsertTempLine(var TempPaymentPeriodLine: Record "Payment Period Line" temporary; LineNo: Integer; DaysFrom: Integer; DaysTo: Integer)
    begin
        TempPaymentPeriodLine.Init();
        TempPaymentPeriodLine."Line No." := LineNo;
        TempPaymentPeriodLine."Days From" := DaysFrom;
        TempPaymentPeriodLine."Days To" := DaysTo;
        TempPaymentPeriodLine.UpdateDescription();
        TempPaymentPeriodLine.Insert();
    end;
}

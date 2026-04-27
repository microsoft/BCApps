// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

codeunit 682 "Paym. Prac. Small Bus. Handler" implements PaymentPracticeSchemeHandler
{
    Access = Internal;

    procedure ValidateHeader(var PaymentPracticeHeader: Record "Payment Practice Header")
    begin
    end;

    procedure UpdatePaymentPracData(var PaymentPracticeData: Record "Payment Practice Data"): Boolean
    begin
        exit(true);
    end;

    procedure CalculateHeaderTotals(var PaymentPracticeHeader: Record "Payment Practice Header"; var PaymentPracticeData: Record "Payment Practice Data")
    begin
    end;

    procedure CalculateLineTotals(var PaymentPracticeLine: Record "Payment Practice Line"; var PaymentPracticeData: Record "Payment Practice Data")
    begin
    end;
}

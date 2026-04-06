// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

enum 680 "Paym. Prac. Reporting Scheme" implements PaymentPracticeDefaultPeriods, PaymentPracticeSchemeHandler
{
    Extensible = true;

    value(0; Standard)
    {
        Implementation = PaymentPracticeDefaultPeriods = "Paym. Prac. Standard Handler", PaymentPracticeSchemeHandler = "Paym. Prac. Standard Handler";
    }
    value(1; "Dispute & Retention")
    {
        Implementation = PaymentPracticeDefaultPeriods = "Paym. Prac. Dispute Ret. Hdlr", PaymentPracticeSchemeHandler = "Paym. Prac. Dispute Ret. Hdlr";
    }
    value(2; "Small Business")
    {
        Implementation = PaymentPracticeDefaultPeriods = "Paym. Prac. Small Bus. Handler", PaymentPracticeSchemeHandler = "Paym. Prac. Small Bus. Handler";
    }
}

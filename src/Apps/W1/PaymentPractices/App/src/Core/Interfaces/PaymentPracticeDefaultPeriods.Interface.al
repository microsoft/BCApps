// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

interface PaymentPracticeDefaultPeriods
{
    /// <summary>
    /// Returns the default payment period template code, description, and line buckets for a given reporting scheme.
    /// </summary>
    /// <param name="PeriodHeaderCode">The code of the default period header template.</param>
    /// <param name="PeriodHeaderDescription">The description of the default period header template.</param>
    /// <param name="TempPaymentPeriodLine">Temporary record set populated with the default period line buckets.</param>
    procedure GetDefaultPaymentPeriods(var PeriodHeaderCode: Code[20]; var PeriodHeaderDescription: Text[250]; var TempPaymentPeriodLine: Record "Payment Period Line" temporary)
}

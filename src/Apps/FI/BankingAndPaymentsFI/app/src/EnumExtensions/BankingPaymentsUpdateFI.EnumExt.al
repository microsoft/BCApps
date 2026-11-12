// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using System.Environment.Configuration;

#if not CLEAN30
enumextension 13590 "Banking Payments Update FI" extends "Feature To Update"
{
    value(13581; BankingAndPaymentsFI)
    {
        Implementation = "Feature Data Update" = "Banking Payments Update FI";
        ObsoleteState = Pending;
        ObsoleteReason = 'Finnish Banking and Payments will be enabled by default in version 30.0.';
        ObsoleteTag = '30.0';
    }
}
#endif

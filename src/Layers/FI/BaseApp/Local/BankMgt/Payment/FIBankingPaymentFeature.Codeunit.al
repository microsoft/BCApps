// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

#if not CLEAN29
using System.Environment.Configuration;
#endif

codeunit 32000003 "FI Banking Payment Feature"
{
    Access = Internal;

    procedure IsEnabled(): Boolean
#if not CLEAN29
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
#endif
    begin
#if not CLEAN29
        exit(FeatureManagementFacade.IsEnabled(FeatureIdTok));
#else
        exit(true);
#endif
    end;

    var
#if not CLEAN29
        FeatureIdTok: Label 'BankingAndPaymentsFI', Locked = true;
#endif
}

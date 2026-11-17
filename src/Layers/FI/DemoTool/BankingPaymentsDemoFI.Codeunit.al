// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN30
codeunit 160901 "Banking Payments Demo FI"
{
    procedure IsEnabled(): Boolean
    var
        FeatureManagementFacade: Codeunit System.Environment.Configuration."Feature Management Facade";
    begin
        exit(FeatureManagementFacade.IsEnabled('BankingAndPaymentsFI'));
    end;
}
#endif

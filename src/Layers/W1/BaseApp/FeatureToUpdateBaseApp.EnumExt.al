// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using Microsoft.Pricing.Calculation;

enumextension 2611 "Feature To Update - BaseApp" extends "Feature To Update"
{
    value(7049; SalesPrices)
    {
        Implementation = "Feature Data Update" = "Feature - Price Calculation";
    }
#if not CLEAN25
    value(5878; GLCurrencyRevaluation)
    {
        Implementation = "Feature Data Update" = "Feature-GLCurrencyRevaluation";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature G/L Currency REvaluation will be enabled by default in version 27.0.';
        ObsoleteTag = '24.0';
    }
#endif
#if not CLEAN26
    value(5892; Manufacturing_FlushingMethod_ActivateManualWoPick)
    {
        Implementation = "Feature Data Update" = "Feature-ManualFlushingMethod";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature ''Manual Flushing Method without requiring pick'' will be enabled by default in version 29.0.';
        ObsoleteTag = '26.0';
    }
#endif
#if not CLEAN28
    value(8200; FinancialReportDefaults)
    {
        Implementation = "Feature Data Update" = Microsoft.Finance.FinancialReports."Feature - Fin. Report Default";
        ObsoleteState = Pending;
        ObsoleteReason = 'Financial Report defaults feature will be always enabled in version 29.0';
        ObsoleteTag = '28.0';
    }
#endif
}

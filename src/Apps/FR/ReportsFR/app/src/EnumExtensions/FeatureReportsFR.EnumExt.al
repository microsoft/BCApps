#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using System.Environment.Configuration;

enumextension 10825 "Feature - Reports FR" extends "Feature To Update"
{
    value(10825; FRReports)
    {
        Implementation = "Feature Data Update" = "Feature - Reports FR";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature Reports FR will be enabled by default in version 33.0.';
        ObsoleteTag = '30.0';
    }
}
#endif

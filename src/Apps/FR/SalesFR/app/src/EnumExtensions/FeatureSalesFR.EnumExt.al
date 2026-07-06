#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.SalesFR;

using System.Environment.Configuration;

enumextension 10800 "Feature - Sales FR" extends "Feature To Update"
{
    value(10800; SalesFR)
    {
        Implementation = "Feature Data Update" = "Feature - Sales FR";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature GovTalk will be enabled by default in version 31.0.';
        ObsoleteTag = '28.0';
    }
}
#endif

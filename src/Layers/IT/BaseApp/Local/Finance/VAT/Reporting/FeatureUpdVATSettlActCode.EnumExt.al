#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Environment.Configuration;

enumextension 12136 "FeatureUpd VATSettl Act. Code" extends "Feature To Update"
{
    value(12136; ITCalcAndPostPerActivityCode)
    {
        Implementation = "Feature Data Update" = "VATSettl ActCode FeatDataUpd";
        ObsoleteState = Pending;
        ObsoleteReason = 'Feature VAT Settlement By Activity Code will be enabled by default in version 30.0.';
        ObsoleteTag = '27.0';
    }
}
#endif
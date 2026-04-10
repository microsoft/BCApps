// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

using System.Environment.Configuration;

tableextension 7049 "Feature Price Calc. Parameters" extends "Feature Data Update Status"
{
    fields
    {
        field(7049; "Use Default Price Lists"; Boolean)
        {
            Caption = 'Use default price lists';
            DataClassification = CustomerContent;
        }
    }
}
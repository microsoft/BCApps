// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

tableextension 11380 "Country/Region NL" extends "Country/Region"
{
    fields
    {
        field(11400; "SEPA Allowed"; Boolean)
        {
            Caption = 'SEPA Allowed';
            DataClassification = CustomerContent;
        }
    }
}


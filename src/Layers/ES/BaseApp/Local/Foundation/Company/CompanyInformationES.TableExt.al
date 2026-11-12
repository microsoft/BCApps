// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

#pragma warning disable AS0088
tableextension 10726 "Company Information ES" extends "Company Information"
{
    fields
    {
        field(10702; "Payment Days Code"; Code[10])
        {
            Caption = 'Payment Days Code';
            DataClassification = CustomerContent;
        }
        field(10703; "Non-Paymt. Periods Code"; Code[10])
        {
            Caption = 'Non-Paymt. Periods Code';
            DataClassification = CustomerContent;
        }
    }
}

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using System.Environment.Configuration;

#pragma warning disable AS0072, AS0136
tableextension 20571 "Subc. Application Area Setup" extends "Application Area Setup"
{
    fields
    {
        field(20500; Subcontracting; Boolean)
        {
            Caption = 'Subcontracting';
            DataClassification = CustomerContent;
        }
    }
}
#pragma warning restore AS0072, AS0136

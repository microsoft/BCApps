// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

enum 243 "VAT Reg. Log Details Field"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Name)
    {
        Caption = 'Name';
    }
    value(1; Address)
    {
        Caption = 'Address';
    }
    value(2; Street)
    {
        Caption = 'Street';
    }
    value(3; "Post Code")
    {
        Caption = 'Post Code';
    }
    value(4; City)
    {
        Caption = 'City';
    }
}

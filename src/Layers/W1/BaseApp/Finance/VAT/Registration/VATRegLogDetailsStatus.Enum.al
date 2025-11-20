// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

enum 242 "VAT Reg. Log Details Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Not Verified")
    {
        Caption = 'Not Verified';
    }
    value(1; Valid)
    {
        Caption = 'Valid';
    }
    value(2; "Not Valid")
    {
        Caption = 'Not Valid';
    }
    value(3; "Partially Valid")
    {
        Caption = 'Partially Valid';
    }
    value(4; Ignored)
    {
        Caption = 'Ignored';
    }
}

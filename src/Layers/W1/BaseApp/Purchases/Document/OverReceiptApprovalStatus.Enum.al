// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

enum 8511 "Over-Receipt Approval Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
    }
    value(1; Pending)
    {
        Caption = 'Pending';
    }
    value(2; Approved)
    {
        Caption = 'Approved';
    }
}

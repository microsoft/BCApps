// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

enum 5508 "Purch. Cr. Memo Entity Status"
{
    Extensible = false;
    AssignmentCompatibility = true;

    value(0; Draft)
    {
        Caption = 'Draft';
    }
    value(1; "In Review")
    {
        Caption = 'In Review';
    }
    value(2; Open)
    {
        Caption = 'Open';
    }
    value(3; Canceled)
    {
        Caption = 'Canceled';
    }
    value(4; Corrective)
    {
        Caption = 'Corrective';
    }
    value(5; Paid)
    {
        Caption = 'Paid';
    }
}
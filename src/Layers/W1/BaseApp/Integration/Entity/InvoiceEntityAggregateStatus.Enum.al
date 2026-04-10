// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

#pragma warning disable AL0659
enum 5477 "Invoice Entity Aggregate Status"
#pragma warning restore AL0659
{
    Extensible = false;
    AssignmentCompatibility = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Draft)
    {
        Caption = 'Draft';
    }
    value(2; "In Review")
    {
        Caption = 'In Review';
    }
    value(3; Open)
    {
        Caption = 'Open';
    }
    value(4; Paid)
    {
        Caption = 'Paid';
    }
    value(5; Canceled)
    {
        Caption = 'Canceled';
    }
    value(6; Corrective)
    {
        Caption = 'Corrective';
    }
}
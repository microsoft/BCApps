// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

#pragma warning disable AL0659
enum 5496 "Purchase Order Entity Buffer Status"
#pragma warning restore AL0659
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
}
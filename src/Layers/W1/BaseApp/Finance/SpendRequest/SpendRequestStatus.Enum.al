// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

/// <summary>
/// Generic approval lifecycle status for spend request documents.
/// </summary>
enum 6841 "Spend Request Status"
{
    Extensible = true;
    Caption = 'Spend Request Status';

    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; Released)
    {
        Caption = 'Released';
    }
    value(2; Approved)
    {
        Caption = 'Approved';
    }
    value(3; Rejected)
    {
        Caption = 'Rejected';
    }
    value(4; Closed)
    {
        Caption = 'Closed';
    }
}

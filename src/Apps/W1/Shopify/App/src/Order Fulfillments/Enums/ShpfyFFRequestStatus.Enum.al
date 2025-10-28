// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Enum Shpfy FF Request Status (ID 30178).
/// </summary>
enum 30178 "Shpfy FF Request Status"
{
    Access = Public;
    Caption = 'Shopify Fulfillment Request Status';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Accepted)
    {
        Caption = 'Accepted';
    }
    value(2; "Cancellation Accepted")
    {
        Caption = 'Cancellation Accepted';
    }
    value(3; "Cancellation Rejected")
    {
        Caption = 'Cancellation Rejected';
    }
    value(4; "Cancellation Requested")
    {
        Caption = 'Cancellation Requested';
    }
    value(5; Closed)
    {
        Caption = 'Closed';
    }
    value(6; Rejected)
    {
        Caption = 'Rejected';
    }
    value(7; Submitted)
    {
        Caption = 'Submitted';
    }
    value(8; Unsubmitted)
    {
        Caption = 'Unsubmitted';
    }
}

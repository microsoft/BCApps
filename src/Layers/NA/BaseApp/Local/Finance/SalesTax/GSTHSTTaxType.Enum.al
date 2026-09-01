// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

enum 10025 "GST HST Tax Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Acquisition") { Caption = 'Acquisition'; }
    value(2; "Self Assessment") { Caption = 'Self Assessment'; }
    value(3; "Rebate") { Caption = 'Rebate'; }
    value(4; "New Housing Rebates") { Caption = 'New Housing Rebates'; }
    value(5; "Pension Rebate") { Caption = 'Pension Rebate'; }
}

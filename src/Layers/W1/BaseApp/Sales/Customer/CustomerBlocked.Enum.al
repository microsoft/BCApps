// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

enum 139 "Customer Blocked"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Ship") { Caption = 'Ship'; }
    value(2; "Invoice") { Caption = 'Invoice'; }
    value(3; "All") { Caption = 'All'; }
}

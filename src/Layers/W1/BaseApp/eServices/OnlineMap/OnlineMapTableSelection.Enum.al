// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.OnlineMap;

enum 802 "Online Map Table Selection"
{
    Extensible = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Bank") { Caption = 'Bank'; }
    value(2; "Contact") { Caption = 'Contact'; }
    value(3; "Customer") { Caption = 'Customer'; }
    value(4; "Employee") { Caption = 'Employee'; }
    value(5; "Job") { Caption = 'Project'; }
    value(6; "Location") { Caption = 'Location'; }
    value(7; "Resource") { Caption = 'Resource'; }
    value(8; "Vendor") { Caption = 'Vendor'; }
    value(9; "Ship-to Address") { Caption = 'Ship-to Address'; }
    value(10; "Order Address") { Caption = 'Order Address'; }
}

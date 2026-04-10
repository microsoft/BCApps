// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

enum 344 "Navigate Contact Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Vendor") { Caption = 'Vendor'; }
    value(2; "Customer") { Caption = 'Customer'; }
    value(3; "Bank Account") { Caption = 'Bank Account'; }
}

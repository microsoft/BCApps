// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

enum 421 "Sales Bill-to Options"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Default (Customer)") { Caption = 'Default (Customer)'; }
    value(1; "Another Customer") { Caption = 'Another Customer'; }
    value(2; "Custom Address") { Caption = 'Custom Address'; }
}

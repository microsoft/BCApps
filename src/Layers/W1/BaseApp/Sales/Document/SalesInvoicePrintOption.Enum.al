// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

enum 230 "Sales Invoice Print Option"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(1; "Draft Invoice")
    {
        Caption = 'Draft Invoice';
    }
    value(2; "Pro Forma Invoice")
    {
        Caption = 'Pro Forma Invoice';
    }
}

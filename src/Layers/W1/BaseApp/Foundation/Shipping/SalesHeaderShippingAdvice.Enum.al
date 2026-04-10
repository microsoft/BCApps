// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Shipping;

enum 3657 "Sales Header Shipping Advice"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Partial)
    {
        Caption = 'Partial';
    }
    value(1; Complete)
    {
        Caption = 'Complete';
    }
}

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

enum 5504 "Tax Buffer Type"
{
    Extensible = false;
    AssignmentCompatibility = true;

    value(0; "Sales Tax")
    {
        Caption = 'Sales Tax';
    }
    value(1; VAT)
    {
        Caption = 'VAT';
    }
}
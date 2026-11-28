// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Registration;

enum 7405 "Registration No. Party Role"
{
    Extensible = false;

    value(0; Company)
    {
        Caption = 'Company';
    }
    value(1; "Sales Bill-to")
    {
        Caption = 'Sales Bill-to';
    }
    value(2; "Purchase Buy-from")
    {
        Caption = 'Purchase Buy-from';
    }
}

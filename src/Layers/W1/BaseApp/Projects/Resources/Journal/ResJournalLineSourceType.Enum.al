// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Journal;

enum 207 "Res. Journal Line Source Type"
{
    Extensible = true;

    value(0; " ")
    {
    }
    value(1; "Customer")
    {
        Caption = 'Customer';
    }
    value(2; "Vendor")
    {
        Caption = 'Vendor';
    }
}

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Journal;

enum 208 "Res. Journal Line Entry Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Usage")
    {
        Caption = 'Usage';
    }
    value(1; "Sale")
    {
        Caption = 'Sale';
    }
    value(2; "Purchase")
    {
        Caption = 'Purchase';
    }
}

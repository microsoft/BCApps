// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

/// <summary>
/// Determines how item charge lines are represented in an exported e-document.
/// </summary>
enum 6430 "Item Charge E-Invoice Mapping"
{
    Extensible = true;
    Caption = 'Item Charge E-Invoice Mapping';

    value(0; Automatic)
    {
        Caption = 'Automatic';
    }
    value(1; "Document Allowance/Charge")
    {
        Caption = 'Document Level Allowance/Charge';
    }
    value(2; "Line Allowance/Charge")
    {
        Caption = 'Invoice Line Allowance/Charge';
    }
    value(3; "Line with Unit Code")
    {
        Caption = 'Invoice Line with Unit Code';
    }
}

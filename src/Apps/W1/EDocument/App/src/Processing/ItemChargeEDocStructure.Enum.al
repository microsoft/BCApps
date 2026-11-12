// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

/// <summary>
/// The structure that an item charge line is exported as in an e-document.
/// </summary>
enum 6534 "Item Charge E-Doc. Structure"
{
    Extensible = true;
    Caption = 'Item Charge E-Document Structure';

    value(0; "Line with Unit Code")
    {
        Caption = 'Invoice Line with Unit Code';
    }
    value(1; "Document Allowance/Charge")
    {
        Caption = 'Document Level Allowance/Charge';
    }
    value(2; "Line Allowance/Charge")
    {
        Caption = 'Invoice Line Allowance/Charge';
    }
}

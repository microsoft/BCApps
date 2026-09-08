// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

/// <summary>
/// Determines how item charge lines are represented in an exported e-document.
/// </summary>
/// <remarks>
/// The enum is extensible, but the built-in classification only resolves the members declared here.
/// An extension that adds a member is responsible for turning it into a structure: subscribe to
/// "E-Doc. Item Charge Mapping".OnAfterGetItemChargeStructure and OnAfterGetSalesCrMemoItemChargeStructure,
/// read the value from the "E-Document Service" record the event passes, and set the Structure parameter
/// accordingly. Both events are raised last, so the structure a subscriber sets wins over the built-in
/// classification.
/// </remarks>
enum 6533 "Item Charge E-Invoice Mapping"
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

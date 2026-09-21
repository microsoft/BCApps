// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

/// <summary>
/// Overrides per item charge how the charge is represented in an exported e-document.
/// The blank value means that no override is set and the setting of the exporting service applies.
/// Automatic is a real override: it forces the automatic classification even if the service forces a structure.
/// </summary>
/// <remarks>
/// The enum is extensible, but the built-in classification only resolves the members declared here.
/// An extension that adds a member is responsible for turning it into a structure: subscribe to
/// "E-Doc. Item Charge Mapping".OnAfterGetItemChargeStructure and OnAfterGetSalesCrMemoItemChargeStructure,
/// read the value from the "Item Charge" the "No." of the charge line the event passes points at, and set
/// the Structure parameter accordingly. Both events are raised last, so the structure a subscriber sets wins
/// over the built-in classification.
/// </remarks>
enum 6535 "Item Charge Mapping Override"
{
    Extensible = true;
    Caption = 'Item Charge Mapping Override';

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; Automatic)
    {
        Caption = 'Automatic';
    }
    value(2; "Document Allowance/Charge")
    {
        Caption = 'Document Level Allowance/Charge';
    }
    value(3; "Line Allowance/Charge")
    {
        Caption = 'Invoice Line Allowance/Charge';
    }
    value(4; "Line with Unit Code")
    {
        Caption = 'Invoice Line with Unit Code';
    }
}

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.eServices.EDocument;

tableextension 6536 "E-Doc. Item Charge" extends "Item Charge"
{
    fields
    {
        field(6530; "E-Invoice Mapping"; Enum "Item Charge Mapping Override")
        {
            Caption = 'E-Invoice Mapping';
            ToolTip = 'Specifies how this item charge is represented in exported e-documents, overriding the Item Charge Mapping setting of the exporting e-document service. If empty, the setting of the service applies. Automatic is itself an override: the item charge is classified based on its assignment to invoice lines, even if the service enforces a fixed representation.';
            DataClassification = CustomerContent;
        }
        field(6531; "E-Invoice Reason Text"; Text[100])
        {
            Caption = 'E-Invoice Reason Text';
            ToolTip = 'Specifies the allowance or charge reason text that is exported for this item charge in e-documents.';
            DataClassification = CustomerContent;
        }
        field(6532; "E-Invoice Reason Code"; Code[10])
        {
            Caption = 'E-Invoice Reason Code';
            ToolTip = 'Specifies the allowance or charge reason code that is exported for this item charge in e-documents.';
            DataClassification = CustomerContent;
        }
        field(6533; "E-Invoice Unit Code"; Code[10])
        {
            Caption = 'E-Invoice Unit Code';
            ToolTip = 'Specifies the unit code that is exported when this item charge is represented as an invoice line in e-documents. If empty, the unit code C62 is exported.';
            DataClassification = CustomerContent;
        }
    }
}

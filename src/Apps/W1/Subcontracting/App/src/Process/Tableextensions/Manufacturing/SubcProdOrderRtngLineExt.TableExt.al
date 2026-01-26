// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Vendor;

tableextension 99001506 "Subc. ProdOrderRtngLine Ext." extends "Prod. Order Routing Line"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(99001550; "Vendor No. Subc. Price"; Code[20])
        {
            Caption = 'Vendor No. Subcontracting Prices';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = Vendor;
        }
        field(99001551; Subcontracting; Boolean)
        {
            CalcFormula = exist("Work Center" where("No." = field("Work Center No."),
                                                    "Subcontractor No." = filter(<> '')));
            Caption = 'Subcontracting';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies whether the Work Center Group is set up with a Vendor for Subcontracting.';
        }
    }
}
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.RoleCenters;
using Microsoft.Purchases.Document;

tableextension 20529 "Subc. Manufacturing Cue" extends "Manufacturing Cue"
{
    fields
    {
        field(20560; "Subcontracting Purchase Orders"; Integer)
        {
            AccessByPermission = tabledata "Purchase Header" = R;
            CalcFormula = count("Purchase Header" where("Document Type" = const(Order),
                                                         "Subc. Order" = const(true)));
            Caption = 'Subcontracting Purchase Orders';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of open purchase orders that are subcontracting orders.';
        }
        field(20561; "Subc. Purch. Lines Outstd."; Integer)
        {
            AccessByPermission = tabledata "Purchase Line" = R;
            CalcFormula = count("Purchase Line" where("Document Type" = const(Order),
                                                       "Subc. Purchase Line Type" = filter(<> None),
                                                       "Outstanding Quantity" = filter(<> 0)));
            Caption = 'Outstanding Subc. Purch. Lines';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of outstanding subcontracting purchase order lines that have not yet been fully received.';
        }
        field(20562; "Subc. Purch. Lines Total"; Integer)
        {
            AccessByPermission = tabledata "Purchase Line" = R;
            CalcFormula = count("Purchase Line" where("Document Type" = const(Order),
                                                       "Subc. Purchase Line Type" = filter(<> None)));
            Caption = 'Total Subc. Purchase Lines';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the total number of subcontracting purchase order lines.';
        }
        field(20563; "Transfers to Subcontractor"; Integer)
        {
            AccessByPermission = tabledata "Transfer Header" = R;
            CalcFormula = count("Transfer Header" where("Subc. Source Type" = const(Subcontracting),
                                                         "Subc. Return Order" = const(false)));
            Caption = 'Transfers to Subcontractor';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of transfer orders to subcontractors.';
        }
        field(20564; "Returns from Subcontractor"; Integer)
        {
            AccessByPermission = tabledata "Transfer Header" = R;
            CalcFormula = count("Transfer Header" where("Subc. Source Type" = const(Subcontracting),
                                                         "Subc. Return Order" = const(true)));
            Caption = 'Returns from Subcontractor';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of transfer orders that are returns from subcontractors.';
        }
    }
}

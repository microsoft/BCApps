// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.RoleCenters;
using Microsoft.Purchases.Document;

tableextension 99001527 "Subc. Manufacturing Cue" extends "Manufacturing Cue"
{
    fields
    {
        field(99001560; "Subc. Purch. Lines Outstd."; Integer)
        {
            CalcFormula = count("Purchase Line" where("Document Type" = const(Order),
                                                       "Subc. Purchase Line Type" = filter(<> None),
                                                       "Outstanding Quantity" = filter(<> 0)));
            Caption = 'Outstanding Subc. Purch. Lines';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of outstanding subcontracting purchase order lines that have not yet been fully received.';
        }
        field(99001561; "Subc. Purch. Lines Total"; Integer)
        {
            CalcFormula = count("Purchase Line" where("Document Type" = const(Order),
                                                       "Subc. Purchase Line Type" = filter(<> None)));
            Caption = 'Total Subc. Purchase Lines';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the total number of subcontracting purchase order lines.';
        }
    }
}

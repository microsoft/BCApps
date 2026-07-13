// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Sales.Customer;

page 27014 "SAT Customer Subform"
{
    Caption = 'SAT Customer Subform';
    PageType = ListPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved customer.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the involved customer.';
                }
                field("CFDI Purpose"; Rec."CFDI Purpose")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the CFDI document. ';
                }
                field("CFDI Relation"; Rec."CFDI Relation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the relation of the CFDI document. ';
                }
            }
        }
    }

    actions
    {
    }
}


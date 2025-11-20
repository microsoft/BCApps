// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

page 1380 "Select Customer Templ. List"
{
    Caption = 'Select a template for a new customer';
    PageType = List;
    SourceTable = "Customer Templ.";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Contact Type"; Rec."Contact Type")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
}

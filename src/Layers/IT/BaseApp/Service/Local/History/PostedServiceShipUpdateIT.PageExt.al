// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

pageextension 12168 "Posted Service Ship. Update IT" extends "Posted Service Ship. - Update"
{
    layout
    {
        addafter("Shipping Agent Code")
        {
            field("Additional Information"; Rec."Additional Information")
            {
                ApplicationArea = Service;
                Editable = true;
                ToolTip = 'Specifies additional declaration information that is needed for the shipment.';
            }
            field("Additional Notes"; Rec."Additional Notes")
            {
                ApplicationArea = Service;
                Editable = true;
                ToolTip = 'Specifies additional notes that are needed for the shipment.';
            }
            field("Additional Instructions"; Rec."Additional Instructions")
            {
                ApplicationArea = Service;
                Editable = true;
                ToolTip = 'Specifies additional instructions that are needed for the shipment.';
            }
            field("TDD Prepared By"; Rec."TDD Prepared By")
            {
                ApplicationArea = Service;
                Editable = true;
                ToolTip = 'Specifies the user ID of the transport delivery document (TDD) for the posted service shipment.';
            }
            field("3rd Party Loader Type"; Rec."3rd Party Loader Type")
            {
                ApplicationArea = Service;
                Editable = true;
                ToolTip = 'Specifies the type of third party that is responsible for loading the items for this document.';
            }
            field("3rd Party Loader No."; Rec."3rd Party Loader No.")
            {
                ApplicationArea = Service;
                Editable = true;
                ToolTip = 'Specifies the ID of the vendor or contact that is responsible for loading the items for this document.';
            }
        }
    }
}
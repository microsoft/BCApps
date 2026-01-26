// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

pageextension 12462 "Posted Service Shipment IT" extends "Posted Service Shipment"
{
    layout
    {
        addafter("Ship-to E-Mail")
        {
            field("Additional Information"; Rec."Additional Information")
            {
                ApplicationArea = Service;
                Editable = false;
                ToolTip = 'Specifies additional declaration information that is needed for the shipment.';
            }
            field("Additional Notes"; Rec."Additional Notes")
            {
                ApplicationArea = Service;
                Editable = false;
                ToolTip = 'Specifies additional notes that are needed for the shipment.';
            }
            field("Additional Instructions"; Rec."Additional Instructions")
            {
                ApplicationArea = Service;
                Editable = false;
                ToolTip = 'Specifies additional instructions that are needed for the shipment.';
            }
            field("TDD Prepared By"; Rec."TDD Prepared By")
            {
                ApplicationArea = Service;
                Editable = false;
                ToolTip = 'Specifies the user ID of the transport delivery document (TDD) for the posted service shipment.';
            }
        }
        addafter("Shipping Agent Service Code")
        {
            field("3rd Party Loader Type"; Rec."3rd Party Loader Type")
            {
                ApplicationArea = Service;
                Editable = false;
                ToolTip = 'Specifies the type of third party that is responsible for loading the items for this document.';
            }
            field("3rd Party Loader No."; Rec."3rd Party Loader No.")
            {
                ApplicationArea = Service;
                Editable = false;
                ToolTip = 'Specifies the ID of the vendor or contact that is responsible for loading the items for this document.';
            }
        }
    }
}
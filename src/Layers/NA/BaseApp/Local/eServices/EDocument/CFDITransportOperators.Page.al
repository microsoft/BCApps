// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 27007 "CFDI Transport Operators"
{
    DelayedInsert = true;
    Caption = 'CFDI Transport Operators';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "CFDI Transport Operator";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Operator Code"; Rec."Operator Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the operator of the vehicle that transports the goods or merchandise.';
                }
                field("Operator Name"; Rec."Operator Name")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the name of the operator of the vehicle that transports the goods or merchandise.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }
}


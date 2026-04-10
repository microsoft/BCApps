// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.RateChange;

pageextension 6478 "Serv. VAT Rate Change Setup" extends "VAT Rate Change Setup"
{
    layout
    {
        addafter("Update Gen. Prod. Post. Groups")
        {
            field("Update Serv. Price Adj. Detail"; Rec."Update Serv. Price Adj. Detail")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the VAT rate change for service price adjustment detail.';
            }
        }
        addafter("Ignore Status on Purch. Docs.")
        {
            field("Update Service Docs."; Rec."Update Service Docs.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the VAT rate change for service lines.';
            }
            field("Ignore Status on Service Docs."; Rec."Ignore Status on Service Docs.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies that all existing service documents regardless of release status are updated.';
            }
        }
    }
}

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

page 12132 "Customs Authority Vendors"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customs Authority Vendors';
    PageType = List;
    SourceTable = "Customs Authority Vendor";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor who you want to identify as representing the customs authorities.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the vendor who you selected in the Vendor No. field.';
                }
            }
        }
    }

    actions
    {
    }
}


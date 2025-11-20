// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

page 936 "Alt. Vendor Posting Groups"
{
    Caption = 'Alternative Vendor Posting Groups';
    DataCaptionFields = "Alt. Vendor Posting Group";
    PageType = List;
    SourceTable = "Alt. Vendor Posting Group";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Alt. Vendor Posting Group"; Rec."Alt. Vendor Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor group for posting business transactions to general general ledger accounts.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control2; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control3; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

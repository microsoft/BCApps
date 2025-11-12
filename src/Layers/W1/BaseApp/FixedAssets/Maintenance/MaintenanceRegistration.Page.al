// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Maintenance;

using Microsoft.FixedAssets.FixedAsset;

page 5625 "Maintenance Registration"
{
    AutoSplitKey = true;
    Caption = 'Maintenance Registration';
    DataCaptionFields = "FA No.";
    PageType = List;
    SourceTable = "Maintenance Registration";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("FA No."; Rec."FA No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the related fixed asset. ';
                    Visible = false;
                }
                field("Service Date"; Rec."Service Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date when the fixed asset is being serviced.';
                }
                field("Maintenance Vendor No."; Rec."Maintenance Vendor No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the vendor who services the fixed asset for this entry.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies a comment for the service, repairs or maintenance to be performed on the fixed asset.';
                }
                field("Service Agent Name"; Rec."Service Agent Name")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the name of the service agent who is servicing the fixed asset.';
                }
                field("Service Agent Phone No."; Rec."Service Agent Phone No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the phone number of the service agent who is servicing the fixed asset.';
                }
                field("Service Agent Mobile Phone"; Rec."Service Agent Mobile Phone")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the mobile phone number of the service agent who is servicing the fixed asset.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.Get(Rec."FA No.");
        Rec."Maintenance Vendor No." := FixedAsset."Maintenance Vendor No.";
    end;
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FixedAsset;

page 5658 "Main Asset Components"
{
    AutoSplitKey = false;
    Caption = 'Main Asset Components';
    DataCaptionFields = "Main Asset No.";
    PageType = List;
    SourceTable = "Main Asset Component";
    AboutTitle = 'About Main Asset Components';
    AboutText = 'You can overview all the component fixed assets updated to a main fixed asset.';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Main Asset No."; Rec."Main Asset No.")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("FA No."; Rec."FA No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the related fixed asset. ';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
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
                Visible = false;
            }
        }
    }

    actions
    {
    }
}


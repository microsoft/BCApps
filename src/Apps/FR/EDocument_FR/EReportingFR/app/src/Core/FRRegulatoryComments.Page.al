// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

page 10971 "FR Regulatory Comments"
{
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'French Regulatory Comments';
    DataCaptionFields = "Document No.";
    PageType = List;
    SourceTable = "FR Regulatory Comment";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Comments)
            {
                field("Comment Type"; Rec."Comment Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the regulatory purpose of the comment.';
                }
                field("Comment Text"; Rec."Comment Text")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the regulatory comment included in the French electronic invoice.';
                }
            }
        }
    }
}
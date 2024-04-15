// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

page 420 "No. Series Relationships Part"
{
    PageType = ListPart;
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    SourceTable = "No. Series Relationship";
    Caption = 'No. Series Relationships';
    DataCaptionFields = "Code";

    layout
    {
        area(Content)
        {
            repeater(Repeater)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    Caption = 'Code';
                    ToolTip = 'Specifies the number series code that represents the related number series.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    DrillDown = false;
                    ToolTip = 'Specifies the description of the number series represented by the code in the Code field.';
                    Visible = false;
                }
                field("Series Code"; Rec."Series Code")
                {
                    Caption = 'Series Code';
                    ToolTip = 'Specifies the code for a number series that you want to include in the group of related number series.';
                }
                field("Series Description"; Rec."Series Description")
                {
                    Caption = 'Series Description';
                    DrillDown = false;
                    ToolTip = 'Specifies the description of the number series represented by the code in the Series Code field.';
                }
            }
        }
    }
}
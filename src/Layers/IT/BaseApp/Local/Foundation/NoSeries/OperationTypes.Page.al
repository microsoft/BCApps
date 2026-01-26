// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.NoSeries;

page 12144 "Operation Types"
{
    Caption = 'Operation Types';
    Editable = false;
    PageType = List;
    SourceTable = "No. Series";
    SourceTableView = where("No. Series Type" = filter(Sales | Purchase));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code that identifies the type of operation.';
                }
                field("No. Series Type"; Rec."No. Series Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series type that is associated with the number series code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description.';
                }
            }
        }
    }

    actions
    {
    }
}


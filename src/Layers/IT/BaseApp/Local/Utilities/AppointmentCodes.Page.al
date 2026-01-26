// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

page 12125 "Appointment Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Appointment Codes';
    PageType = List;
    SourceTable = "Appointment Code";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a number that identifies the company that can submit VAT statements on behalf of other legal entities.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a text description of the appointment code.';
                }
            }
        }
    }

    actions
    {
    }
}


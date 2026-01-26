// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

page 10706 "Statistical Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Statistical Codes';
    PageType = List;
    SourceTable = "Statistical Code";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1100001)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the statistical code for the payment.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the statistical code.';
                }
            }
        }
    }

    actions
    {
    }
}


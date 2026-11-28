// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

page 410 "Business Activities"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Business Activities';
    PageType = List;
    SourceTable = "Business Activity";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code that identifies the company''s business activity.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the business activity code.';
                }
            }
        }
    }
}
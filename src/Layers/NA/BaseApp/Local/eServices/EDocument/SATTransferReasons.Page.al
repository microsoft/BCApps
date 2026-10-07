// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 27038 "SAT Transfer Reasons"
{
    DelayedInsert = true;
    Caption = 'SAT Transfer Reasons';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "SAT Transfer Reason";
    ApplicationArea = BasicMX;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a code for this entry according to the SAT transfer reason definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a description for this entry according to the SAT transfer reason definition.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }
}


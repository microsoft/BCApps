// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 27023 "SAT Permission Types"
{
    DelayedInsert = true;
    Caption = 'SAT Permission Types';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "SAT Permission Type";
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
                    ToolTip = 'Specifies a code for this entry according to the SAT permission type definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a description for this entry according to the SAT permission type definition.';
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


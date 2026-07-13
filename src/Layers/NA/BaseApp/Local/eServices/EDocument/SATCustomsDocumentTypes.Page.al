// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 27048 "SAT Customs Document Types"
{
    DelayedInsert = true;
    Caption = 'SAT Customs Documents';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "SAT Customs Document Type";
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
                    ToolTip = 'Specifies a code for this entry according to the SAT customs document definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a description for this entry according to the SAT custom document definition.';
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


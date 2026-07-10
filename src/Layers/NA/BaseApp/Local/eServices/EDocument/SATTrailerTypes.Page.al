// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 27022 "SAT Trailer Types"
{
    DelayedInsert = true;
    Caption = 'SAT Trailer Types';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "SAT Trailer Type";
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
                    ToolTip = 'Specifies a code for this entry according to the SAT trailer type definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a description for this entry according to the SAT trailer type definition.';
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


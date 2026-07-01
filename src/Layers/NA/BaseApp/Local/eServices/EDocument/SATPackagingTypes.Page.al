// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 27025 "SAT Packaging Types"
{
    DelayedInsert = true;
    Caption = 'SAT Packaging Types';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "SAT Packaging Type";
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
                    ToolTip = 'Specifies a code for this entry according to the SAT packaging type definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a description for this entry according to the SAT packaging type definition.';
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


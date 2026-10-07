// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 27021 "SAT Federal Motor Transports"
{
    DelayedInsert = true;
    Caption = 'SAT Federal Motor Transports';
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "SAT Federal Motor Transport";
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
                    ToolTip = 'Specifies a code for this entry according to the SAT federal motor transport definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a description for this entry according to the SAT federal motor transport definition.';
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


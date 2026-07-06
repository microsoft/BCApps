// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 27019 "SAT Weight Unit of Measures"
{
    Caption = 'SAT Weight Unit of Measures';
    PageType = List;
    SourceTable = "SAT Weight Unit of Measure";
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
                    ToolTip = 'Specifies a code for this entry according to the SAT weight unit of measure definition.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a name for this entry according to the SAT weight unit of measure definition.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a description for this entry according to the SAT weight unit of measure definition.';
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


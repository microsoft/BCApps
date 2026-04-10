// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Projects.Resources.Resource;

page 912 "Component - Resource Details"
{
    Caption = 'Component - Resource Details';
    PageType = CardPart;
    SourceTable = Resource;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Assembly;
                Caption = 'Resource No.';
                ToolTip = 'Specifies a number for the resource.';
            }
            field(Type; Rec.Type)
            {
                ApplicationArea = Assembly;
                ToolTip = 'Specifies whether the resource is a person or a machine.';
            }
            field("Job Title"; Rec."Job Title")
            {
                ApplicationArea = Assembly;
                ToolTip = 'Specifies the person''s job title.';
            }
            field("Base Unit of Measure"; Rec."Base Unit of Measure")
            {
                ApplicationArea = Assembly;
                ToolTip = 'Specifies the base unit used to measure the resource, such as hour, piece, or kilometer. The base unit of measure also serves as the conversion basis for alternate units of measure.';
            }
            field("Unit Cost"; Rec."Unit Cost")
            {
                ApplicationArea = Assembly;
                ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
            }
        }
    }

    actions
    {
    }
}


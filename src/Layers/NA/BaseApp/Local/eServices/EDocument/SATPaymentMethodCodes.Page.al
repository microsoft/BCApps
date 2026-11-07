// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

page 27002 "SAT Payment Method Codes"
{
    Caption = 'SAT Payment Method Codes';
    PageType = List;
    SourceTable = "SAT Payment Method Code";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the SAT payment method.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a description the SAT payment method.';
                }
            }
        }
    }

    actions
    {
    }
}


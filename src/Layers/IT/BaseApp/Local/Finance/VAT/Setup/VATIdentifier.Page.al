// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

page 12140 "VAT Identifier"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Identifier';
    PageType = List;
    SourceTable = "VAT Identifier";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a VAT identifier code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the VAT identifier.';
                }
                field("Subject to VAT Plafond"; Rec."Subject to VAT Plafond")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT code is subject to a VAT exemption ceiling.';
                }
            }
        }
    }

    actions
    {
    }
}


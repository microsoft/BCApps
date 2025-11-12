// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

page 7710 "ADCS Users"
{
    AdditionalSearchTerms = 'scanner,handheld,automated data capture,barcode';
    ApplicationArea = ADCS;
    Caption = 'ADCS Users';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "ADCS User";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'Group';
                field(Name; Rec.Name)
                {
                    ApplicationArea = ADCS;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of an ADCS user.';
                }
                field(Password; Rec.Password)
                {
                    ApplicationArea = ADCS;
                    Caption = 'Password';
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the password of an ADCS user.';
                }
            }
        }
    }

    actions
    {
    }
}


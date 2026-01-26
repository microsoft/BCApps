// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 11412 "Elec. Tax Declaration List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Electronic Tax Declarations';
    CardPageID = "Elec. Tax Declaration Card";
    Editable = false;
    PageType = List;
    SourceTable = "Elec. Tax Declaration Header";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1000000)
            {
                ShowCaption = false;
                field("Declaration Type"; Rec."Declaration Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the electronic declaration concerns a VAT or ICP declaration.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the electronic declaration that you are setting up.';
                }
                field("Declaration Period"; Rec."Declaration Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the declaration period.';
                }
                field("Declaration Year"; Rec."Declaration Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the declaration year.';
                }
                field("Message ID"; Rec."Message ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the response message from the Tax authority.';
                }
                field("Our Reference"; Rec."Our Reference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unique identification for the electronic declaration.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the electronic declaration.';
                }
            }
        }
    }

    actions
    {
    }
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using System.Reflection;

page 2000005 "Export Protocols"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Export Protocols';
    PageType = List;
    SourceTable = "Export Protocol";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1010000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code that identifies the export protocol.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the export protocol entry.';
                }
                field("Code Expenses"; Rec."Code Expenses")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code that describes the type of expenses associated with the export protocol entry.';
                }
                field("Check Object ID"; Rec."Check Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = true;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the identification number of the verification process, which checks on the object before the payment file is exported.';
                }
                field("Check Object Name"; Rec."Check Object Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of a verification process used to check on the object before the payment file is exported.';
                }
                field("Export Object Type"; Rec."Export Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the object that defines the format of the payment file export.';
                }
                field("Export Object ID"; Rec."Export Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    Lookup = true;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the identification number of the object, which defines the report format of the payment file export.';
                }
                field("Export No. Series"; Rec."Export No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series used to assign identification numbers to the payment file export.';
                }
                field("Grouped Payment"; Rec."Grouped Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the BtchBookg element is set to true or false in the SEPA xml file.';
                }
            }
        }
    }

    actions
    {
    }
}


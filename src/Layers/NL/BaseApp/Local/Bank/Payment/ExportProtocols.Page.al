// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using System.Reflection;

page 11000012 "Export Protocols"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Export Protocols';
    PageType = List;
    SourceTable = "Export Protocol";
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
                    ToolTip = 'Specifies an export protocol code that you want attached to the entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of what the export protocol stands for.';
                }
                field("Check ID"; Rec."Check ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the ID for the codeunit used to check the payment histories.';
                }
                field("Check Name"; Rec."Check Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the check codeunit.';
                }
                field("Export Object Type"; Rec."Export Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the Export Object.';
                }
                field("Export ID"; Rec."Export ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the ID for the batch job used to export payment histories.';
                }
                field("Export Name"; Rec."Export Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the export batch job.';
                }
                field("Docket ID"; Rec."Docket ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the ID for the report used to inform the contact on combined payments.';
                }
                field("Docket Name"; Rec."Docket Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the docket report.';
                }
                field("Default File Names"; Rec."Default File Names")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the file locations to export payment and collection data to.';
                }
                field("Generate Checksum"; Rec."Generate Checksum")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to generate a checksum and store it in the payment history.';

                }
                field("Checksum Algorithm"; Rec."Checksum Algorithm")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the checksum algorithm.';
                    Enabled = Rec."Generate Checksum";

                }
                field("Append Checksum to File"; Rec."Append Checksum to File")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to append the checksum to the report file.';
                    Enabled = Rec."Generate Checksum";
                }


            }
        }
    }

    actions
    {
    }
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

pageextension 11030 "Intrastat Report DE" extends "Intrastat Report"
{
    layout
    {

        addafter(General)
        {
            group(ExportParamenters)
            {
                Caption = 'Export Parameters';
                field("Submission Channel"; Rec."Submission Channel")
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Submission Channel';
                    ToolTip = 'Specifies how the Intrastat report is submitted. To choose the default submission channel, open Intrastat Report Setup.';
                }
                field("Test Submission"; Rec."Test Submission")
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Test Submission';
                    ToolTip = 'Specifies if the exported XML will be used for test submission.';
                }
            }
        }
    }
}

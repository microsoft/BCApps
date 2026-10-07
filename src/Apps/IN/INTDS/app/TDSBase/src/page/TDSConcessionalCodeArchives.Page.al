// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TDS.TDSBase;

page 18699 "TDS Concessional Code Archives"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = History;
    SourceTable = "TDS Concessional Code Archive";
    Caption = 'TDS Concessional Code Archives';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    SourceTableView = sorting("Archived On") order(descending);

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor code.';
                }
                field(Section; Rec.Section)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the section code under which tax has been deducted.';
                }
                field("Concessional Code"; Rec."Concessional Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the concessional code if concessional rate was applicable.';
                }
                field("Certificate No."; Rec."Certificate No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the concessional certificate number of the deductee.';
                }
                field("Certificate Value"; Rec."Certificate Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original certificate value.';
                }
                field("Used Certificate Value"; Rec."Used Certificate Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the certificate value already consumed when the certificate was archived.';
                }
                field("Remaining Certificate Value"; Rec."Remaining Certificate Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remaining certificate value at the time of archival.';
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the starting date of the archived certificate.';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ending date of the archived certificate.';
                }
                field("Archived On"; Rec."Archived On")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the certificate was archived (replaced by a newer certificate).';
                }
                field("Archived By"; Rec."Archived By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user who triggered the archival.';
                }
            }
        }
    }
}

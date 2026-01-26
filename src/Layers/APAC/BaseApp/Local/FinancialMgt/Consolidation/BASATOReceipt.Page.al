// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Setup;

page 11605 "BAS ATO Receipt"
{
    ApplicationArea = Basic, Suite;
    Caption = 'BAS ATO Receipt';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    Permissions = TableData "BAS Calculation Sheet" = rm;
    SourceTable = "BAS Calculation Sheet";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(A1; Rec.A1)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ID of the BAS document number that is provided by the Australian Tax Office (ATO).';
                }
                field("BAS Version"; Rec."BAS Version")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the version number of the BAS document.';
                }
                field("ATO Receipt No."; Rec."ATO Receipt No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the receipt number that is issued from the Australian Taxation Office (ATO) after the ATO has received a completed BAS.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.TestField("Enable GST (Australia)", true);
    end;
}


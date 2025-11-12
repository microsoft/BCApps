// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Maintenance;

page 5991 "Troubleshooting List"
{
    ApplicationArea = Service;
    Caption = 'Troubleshooting';
    CardPageID = Troubleshooting;
    Editable = false;
    PageType = List;
    SourceTable = "Troubleshooting Header";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the troubleshooting issue.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("T&roublesh.")
            {
                Caption = 'T&roublesh.';
                Image = Setup;
                action(Setup)
                {
                    ApplicationArea = Service;
                    Caption = 'Setup';
                    Image = Setup;
                    ToolTip = 'Set up troubleshooting.';

                    trigger OnAction()
                    begin
                        TblshtgSetup.Reset();
                        TblshtgSetup.SetCurrentKey("Troubleshooting No.");
                        TblshtgSetup.SetRange("Troubleshooting No.", Rec."No.");
                        PAGE.RunModal(PAGE::"Troubleshooting Setup", TblshtgSetup)
                    end;
                }
            }
        }
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    var
        TblshtgSetup: Record "Troubleshooting Setup";
}


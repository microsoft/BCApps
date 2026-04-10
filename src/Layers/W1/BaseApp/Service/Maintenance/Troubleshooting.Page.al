// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Maintenance;

page 5990 Troubleshooting
{
    Caption = 'Troubleshooting';
    PageType = ListPlus;
    SourceTable = "Troubleshooting Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
            }
            part(Control7; "Troubleshooting Subform")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = field("No.");
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
                        Page.RunModal(Page::"Troubleshooting Setup", TblshtgSetup);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if PageCaptionPrefix <> '' then
            CurrPage.Caption := PageCaptionPrefix + ' - ' + CurrPage.Caption();
    end;

    var
        TblshtgSetup: Record "Troubleshooting Setup";
        PageCaptionPrefix: Text;


    procedure SetPageCaptionPrefix(PageCaptionPrefixToSet: Text)
    begin
        PageCaptionPrefix := PageCaptionPrefixToSet;
    end;
}

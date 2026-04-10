// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.OnlineMap;

page 804 "Online Map Parameter Setup"
{
    Caption = 'Online Map Parameter Setup';
    PageType = List;
    SourceTable = "Online Map Parameter Setup";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Map Service"; Rec."Map Service")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Directions Service"; Rec."Directions Service")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Directions from Location Serv."; Rec."Directions from Location Serv.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("URL Encode Non-ASCII Chars"; Rec."URL Encode Non-ASCII Chars")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Miles/Kilometers Option List"; Rec."Miles/Kilometers Option List")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Quickest/Shortest Option List"; Rec."Quickest/Shortest Option List")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ExtendedDatatype = URL;
                }
            }
        }
        area(factboxes)
        {
            part("Online Map Substitution Parameter"; "Online Map Parameter FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Online Map Substitution Parameter';
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Insert Default")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Insert Default';
                Image = Insert;
                ToolTip = 'Insert default settings for the online map. This will overwrite any settings you may have.';

                trigger OnAction()
                begin
                    Rec.InsertDefaults();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Insert Default_Promoted"; "&Insert Default")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        OnlineMapParameterSetup: Record "Online Map Parameter Setup";
    begin
        if OnlineMapParameterSetup.IsEmpty() then
            OnlineMapParameterSetup.InsertDefaults();
    end;
}


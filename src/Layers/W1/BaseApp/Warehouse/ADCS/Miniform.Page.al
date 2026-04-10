// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

using System.Reflection;

page 7700 Miniform
{
    Caption = 'Miniform';
    DataCaptionFields = "Code";
    PageType = ListPlus;
    SourceTable = "Miniform Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = ADCS;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ADCS;
                }
                field("Form Type"; Rec."Form Type")
                {
                    ApplicationArea = ADCS;
                }
                field("No. of Records in List"; Rec."No. of Records in List")
                {
                    ApplicationArea = ADCS;
                }
                field("Handling Codeunit"; Rec."Handling Codeunit")
                {
                    ApplicationArea = ADCS;
                    LookupPageID = Objects;
                }
                field("Next Miniform"; Rec."Next Miniform")
                {
                    ApplicationArea = ADCS;
                }
                field("Start Miniform"; Rec."Start Miniform")
                {
                    ApplicationArea = ADCS;
                }
            }
            part(Control9; "Miniform Subform")
            {
                ApplicationArea = ADCS;
                SubPageLink = "Miniform Code" = field(Code);
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
            group("&Mini Form")
            {
                Caption = '&Mini Form';
                Image = MiniForm;
                action("&Functions")
                {
                    ApplicationArea = ADCS;
                    Caption = '&Functions';
                    Image = "Action";
                    RunObject = Page "Miniform Functions";
                    RunPageLink = "Miniform Code" = field(Code);
                    ToolTip = 'Access functions to set up the ADCS interface.';
                }
            }
        }
    }
}


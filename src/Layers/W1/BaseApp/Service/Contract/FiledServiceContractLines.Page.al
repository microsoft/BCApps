// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

page 6086 "Filed Service Contract Lines"
{
    Caption = 'Filed Service Contract Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Filed Contract Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Contract Type"; Rec."Contract Type")
                {
                    ApplicationArea = Service;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Service;
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                }
                field("Service Item Group Code"; Rec."Service Item Group Code")
                {
                    ApplicationArea = Service;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Response Time (Hours)"; Rec."Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated time interval after work on the service order starts.';
                }
                field("Line Cost"; Rec."Line Cost")
                {
                    ApplicationArea = Service;
                }
                field("Line Value"; Rec."Line Value")
                {
                    ApplicationArea = Service;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Service;
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Service;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Service;
                }
                field(Profit; Rec.Profit)
                {
                    ApplicationArea = Service;
                }
                field("Invoiced to Date"; Rec."Invoiced to Date")
                {
                    ApplicationArea = Service;
                }
                field("Service Period"; Rec."Service Period")
                {
                    ApplicationArea = Service;
                }
                field("Last Planned Service Date"; Rec."Last Planned Service Date")
                {
                    ApplicationArea = Service;
                }
                field("Next Planned Service Date"; Rec."Next Planned Service Date")
                {
                    ApplicationArea = Service;
                }
                field("Last Service Date"; Rec."Last Service Date")
                {
                    ApplicationArea = Service;
                }
                field("Last Preventive Maint. Date"; Rec."Last Preventive Maint. Date")
                {
                    ApplicationArea = Service;
                }
                field("Credit Memo Date"; Rec."Credit Memo Date")
                {
                    ApplicationArea = Service;
                }
                field("Contract Expiration Date"; Rec."Contract Expiration Date")
                {
                    ApplicationArea = Service;
                }
                field("New Line"; Rec."New Line")
                {
                    ApplicationArea = Service;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Show Document")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    var
                        FiledServiceContractHeader: Record "Filed Service Contract Header";
                    begin
                        FiledServiceContractHeader.Get(Rec."Entry No.");
                        Page.Run(Page::"Filed Service Contract", FiledServiceContractHeader);
                    end;
                }
            }
        }
    }
}


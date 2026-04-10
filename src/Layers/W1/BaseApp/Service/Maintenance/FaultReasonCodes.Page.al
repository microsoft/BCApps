// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Maintenance;

using Microsoft.Service.Document;

page 5929 "Fault Reason Codes"
{
    ApplicationArea = Service;
    Caption = 'Fault Reason Codes';
    PageType = List;
    SourceTable = "Fault Reason Code";
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
                    ApplicationArea = Service;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Exclude Warranty Discount"; Rec."Exclude Warranty Discount")
                {
                    ApplicationArea = Service;
                }
                field("Exclude Contract Discount"; Rec."Exclude Contract Discount")
                {
                    ApplicationArea = Service;
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
            group("&Fault")
            {
                Caption = '&Fault';
                Image = Error;
                action("Serv&ice Line List")
                {
                    ApplicationArea = Service;
                    Caption = 'Serv&ice Line List';
                    Image = ServiceLines;
                    RunObject = Page "Service Line List";
                    RunPageLink = "Fault Reason Code" = field(Code);
                    RunPageView = sorting("Fault Reason Code");
                    ToolTip = 'View the service lines that contain the fault code.';
                }
                action("Service Item Line List")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Item Line List';
                    Image = ServiceItem;
                    RunObject = Page "Service Item Lines";
                    RunPageLink = "Fault Reason Code" = field(Code);
                    RunPageView = sorting("Fault Reason Code");
                    ToolTip = 'View the list of ongoing service item lines.';
                }
            }
        }
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := false;
    end;
}


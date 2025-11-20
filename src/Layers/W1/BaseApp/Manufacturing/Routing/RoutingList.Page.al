// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;

using Microsoft.Manufacturing.Comment;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Reports;

page 99000764 "Routing List"
{
    AdditionalSearchTerms = 'operations,process structure';
    ApplicationArea = Manufacturing;
    Caption = 'Routings';
    CardPageID = Routing;
    DataCaptionFields = "No.", Description;
    Editable = false;
    PageType = List;
    AboutTitle = 'About Routings';
    AboutText = 'Create and manage routings that define the sequence and structure of manufacturing operations, assign resources and quality measures, and control production scheduling with support for multiple versions and statuses.';
    SourceTable = "Routing Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description for the routing header.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies in which order operations in the routing are performed.';
                    Visible = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the status of this routing.';
                }
                field("Version Nos."; Rec."Version Nos.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number series you want to use to create a new version of this routing.';
                    Visible = false;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies when the routing card was last modified.';
                    Visible = false;
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Routing")
            {
                Caption = '&Routing';
                Image = Route;
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Manufacturing Comment Sheet";
                    RunPageLink = "Table Name" = const("Routing Header"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("&Versions")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Versions';
                    Image = RoutingVersions;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    RunObject = Page "Routing Version List";
                    RunPageLink = "Routing No." = field("No.");
                    ToolTip = 'View or edit other versions of the routing, typically with other operations data. ';
                }
                action("Where-used")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Where-used';
                    Image = "Where-Used";
                    RunObject = Page "Where-Used Item List";
                    RunPageLink = "Routing No." = field("No.");
                    RunPageView = sorting("Routing No.");
                    ToolTip = 'View a list of BOMs in which the item is used.';
                }
            }
        }
        area(reporting)
        {
            action("Routing Sheet")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Routing Sheet';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Routing Sheet";
                ToolTip = 'View basic information for routings, such as send-ahead quantity, setup time, run time and time unit. This report shows you the operations to be performed in this routing, the work or machine centers to be used, the personnel, the tools, and the description of each operation.';
            }
        }
        area(Promoted)
        {
        }
    }
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.Finance.Dimension;
using System.Security.User;

page 6267 "Service Quote Archives"
{
    ApplicationArea = Service;
    Caption = 'Service Quote Archives';
    CardPageID = "Service Quote Archive";
    DataCaptionFields = "Customer No.";
    Editable = false;
    PageType = List;
    SourceTable = "Service Header Archive";
    SourceTableView = where("Document Type" = const(Quote));
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(ServiceQuoteArchives)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                }
                field("Version No."; Rec."Version No.")
                {
                    ApplicationArea = Service;
                }
                field("Date Archived"; Rec."Date Archived")
                {
                    ApplicationArea = Service;
                }
                field("Time Archived"; Rec."Time Archived")
                {
                    ApplicationArea = Service;
                }
                field("Archived By"; Rec."Archived By")
                {
                    ApplicationArea = Service;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Archived By");
                    end;
                }
                field("Interaction Exist"; Rec."Interaction Exist")
                {
                    ApplicationArea = RelationshipMgmt;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Service;
                }
                field("Order Time"; Rec."Order Time")
                {
                    ApplicationArea = Service;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a document number that refers to the customer''s numbering system.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Service;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Service;
                }
                field("Notify Customer"; Rec."Notify Customer")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Service Order Type"; Rec."Service Order Type")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Response Date"; Rec."Response Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Payment Discount %"; Rec."Payment Discount %")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Warning Status"; Rec."Warning Status")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Allocated Hours"; Rec."Allocated Hours")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Finishing Date"; Rec."Finishing Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Your Reference"; Rec."Your Reference")
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
            group("Ver&sion")
            {
                Caption = 'Ver&sion';
                Image = Versions;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Archive Comment Sheet";
                    RunPageLink = "Table Name" = const("Service Header"),
                                  "Table Subtype" = field("Document Type"),
                                  "No." = field("No."),
                                  Type = const(General),
                                  "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                  "Version No." = field("Version No.");
                    ToolTip = 'View comments for the record.';
                }
            }
        }
    }
}


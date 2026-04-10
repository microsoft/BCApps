// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Ledger;

using System.Security.User;

page 5931 "Service Register"
{
    ApplicationArea = Service;
    Caption = 'Service Registers';
    Editable = false;
    PageType = List;
    SourceTable = "Service Register";
    UsageCategory = History;

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
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = Service;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Service;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("From Entry No."; Rec."From Entry No.")
                {
                    ApplicationArea = Service;
                }
                field("To Entry No."; Rec."To Entry No.")
                {
                    ApplicationArea = Service;
                }
                field("From Warranty Entry No."; Rec."From Warranty Entry No.")
                {
                    ApplicationArea = Service;
                }
                field("To Warranty Entry No."; Rec."To Warranty Entry No.")
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
            group("&Register")
            {
                Caption = '&Register';
                Image = Register;
                action("Service Ledger")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Ledger';
                    Image = ServiceLedger;
                    RunObject = Codeunit "Serv Reg.-Show Ledger Entries";
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents.';
                }
                action("Warranty Ledger")
                {
                    ApplicationArea = Service;
                    Caption = 'Warranty Ledger';
                    Image = WarrantyLedger;
                    RunObject = Codeunit "Serv Reg.-Show WarrLdgEntries";
                    ToolTip = 'View all of the warranty ledger entries for service items or service orders. The entries are the result of posting transactions in service documents.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Service Ledger_Promoted"; "Service Ledger")
                {
                }
                actionref("Warranty Ledger_Promoted"; "Warranty Ledger")
                {
                }
            }
        }
    }
}


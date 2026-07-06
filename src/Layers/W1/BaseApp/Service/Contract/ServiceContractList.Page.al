// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Service.Reports;

page 6051 "Service Contract List"
{
    Caption = 'Service Contract List';
    DataCaptionFields = "Contract Type";
    Editable = false;
    PageType = List;
    SourceTable = "Service Contract Header";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                }
                field("Contract Type"; Rec."Contract Type")
                {
                    ApplicationArea = Service;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                }
                field("Expiration Date"; Rec."Expiration Date")
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
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(ShowDocument)
                {
                    ApplicationArea = Service;
                    Caption = 'Show Document';
                    Image = EditLines;
                    ShortCutKey = 'Return';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        OpenRelatedCard();
                    end;
                }
            }
        }
        area(reporting)
        {
            group(General)
            {
                Caption = 'General';
                Image = "Report";
                action("Service Items Out of Warranty")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Items Out of Warranty';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Service Items Out of Warranty";
                }
            }
            group(Contract)
            {
                Caption = 'Contract';
                Image = "Report";
                action("Service Contract-Customer")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Contract-Customer';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Service Contract - Customer";
                }
                action("Service Contract-Salesperson")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Contract-Salesperson';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Serv. Contract - Salesperson";
                }
                action("Service Contract Details")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Contract Details';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Service Contract-Detail";
                }
                action("Service Contract Profit")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Contract Profit';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Service Profit (Contracts)";
                }
                action("Maintenance Visit - Planning")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Maintenance Visit - Planning';
                    Image = "Report";
                    RunObject = Report "Maintenance Visit - Planning";
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = "Report";
                action("Contract, Service Order Test")
                {
                    ApplicationArea = Service;
                    Caption = 'Contract, Service Order Test';
                    Image = "Report";
                    RunObject = Report "Contr. Serv. Orders - Test";
                }
                action("Contract Invoice Test")
                {
                    ApplicationArea = Service;
                    Caption = 'Contract Invoice Test';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Contract Invoicing";
                }
                action("Contract Price Update - Test")
                {
                    ApplicationArea = Service;
                    Caption = 'Contract Price Update - Test';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Contract Price Update - Test";
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Maintenance Visit - Planning_Promoted"; "Maintenance Visit - Planning")
                {
                }
                actionref("Contract, Service Order Test_Promoted"; "Contract, Service Order Test")
                {
                }
            }
        }
    }

    local procedure OpenRelatedCard()
    begin
        case Rec."Contract Type" of
            Rec."Contract Type"::Quote:
                PAGE.Run(PAGE::"Service Contract Quote", Rec);
            Rec."Contract Type"::Contract:
                PAGE.Run(PAGE::"Service Contract", Rec);
        end;
    end;
}


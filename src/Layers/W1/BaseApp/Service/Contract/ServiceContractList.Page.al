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
                    ToolTip = 'Specifies the status of the service contract or contract quote.';
                }
                field("Contract Type"; Rec."Contract Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the contract.';
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service contract or service contract quote.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the service contract.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer who owns the service items in the service contract/contract quote.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer in the service contract.';
                    Visible = false;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the service contract.';
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service contract expires.';
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
                    ToolTip = 'View information about warranty end dates, serial numbers, number of active contracts, items description, and names of customers. You can print a list of service items that are out of warranty.';
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
                    ToolTip = 'View information about status, next invoice date, invoice period, amount per period, and annual amount. You can print a list of service contracts for each customer in a selected time period.';
                }
                action("Service Contract-Salesperson")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Contract-Salesperson';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Serv. Contract - Salesperson";
                    ToolTip = 'View customer number, name, description, starting date and the annual amount for each service contract. You can use the report to calculate and document sales commission. You can print a list of service contracts for each salesperson for a selected period.';
                }
                action("Service Contract Details")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Contract Details';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Service Contract-Detail";
                    ToolTip = 'View detailed information for the service contract.';
                }
                action("Service Contract Profit")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Contract Profit';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Service Profit (Contracts)";
                    ToolTip = 'View profit information for the service contract.';
                }
                action("Maintenance Visit - Planning")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Maintenance Visit - Planning';
                    Image = "Report";
                    RunObject = Report "Maintenance Visit - Planning";
                    ToolTip = 'View the service zone code, group code, contract number, customer number, service period, as well as the service date. You can select the schedule for one or more responsibility centers. The report shows the service dates of all the maintenance visits for the chosen responsibility centers. You can print all your schedules for maintenance visits.';
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
                    ToolTip = 'View the numbers of contracts, the numbers and the names of customers, as well as some other information relating to the service orders that are created for the period that you have specified. You can test which service contracts include service items that are due for service within the specified period.';
                }
                action("Contract Invoice Test")
                {
                    ApplicationArea = Service;
                    Caption = 'Contract Invoice Test';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Contract Invoicing";
                    ToolTip = 'Specifies billable profits for the project task that are related to G/L accounts.';
                }
                action("Contract Price Update - Test")
                {
                    ApplicationArea = Service;
                    Caption = 'Contract Price Update - Test';
                    Image = "Report";
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = "Report";
                    RunObject = Report "Contract Price Update - Test";
                    ToolTip = 'View the contracts numbers, customer numbers, contract amounts, price update percentages, and any errors that occur. You can test which service contracts need price updates up to the date that you have specified.';
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


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

page 6075 "Serv. Contr. List (Serv. Item)"
{
    Caption = 'Service Contract List';
    DataCaptionFields = "Service Item No.";
    Editable = false;
    PageType = List;
    SourceTable = "Service Contract Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Contract Status"; Rec."Contract Status")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the status of the contract.';
                }
                field("Contract Type"; Rec."Contract Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the contract.';
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service contract or service contract quote associated with the service contract line.';
                }
                field(ContractDescription; ContractDescription)
                {
                    ApplicationArea = Service;
                    Caption = 'Contract Description';
                    ToolTip = 'Specifies billable prices for the job task that are related to G/L accounts.';
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item that is subject to the service contract.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    Caption = 'Contract Line Description';
                    ToolTip = 'Specifies billable profits for the job task that are related to G/L accounts, expressed in the local currency.';
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                    Visible = false;
                }
                field("Response Time (Hours)"; Rec."Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the response time for the service item associated with the service contract.';
                }
                field("Line Cost"; Rec."Line Cost")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the calculated cost of the service item line in the service contract or contract quote.';
                }
                field("Line Value"; Rec."Line Value")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the value of the service item line in the contract or contract quote.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
                    Visible = false;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
                field(Profit; Rec.Profit)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the profit, expressed as the difference between the Line Amount and Line Cost fields on the service contract line.';
                }
                field("Service Period"; Rec."Service Period")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the period of time that must pass between each servicing of an item.';
                }
                field("Next Planned Service Date"; Rec."Next Planned Service Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date of the next planned service on the item included in the contract.';
                }
                field("Last Planned Service Date"; Rec."Last Planned Service Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date of the last planned service on this item.';
                    Visible = false;
                }
                field("Last Preventive Maint. Date"; Rec."Last Preventive Maint. Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the last time preventative service was performed on this item.';
                    Visible = false;
                }
                field("Last Service Date"; Rec."Last Service Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service item on the line was last serviced.';
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the service contract.';
                }
                field("Contract Expiration Date"; Rec."Contract Expiration Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when an item should be removed from the contract.';
                }
                field("Credit Memo Date"; Rec."Credit Memo Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when you can create a credit memo for the service item that needs to be removed from the service contract.';
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
                action("&Show Document")
                {
                    ApplicationArea = Service;
                    Caption = '&Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the information on the line comes from.';

                    trigger OnAction()
                    begin
                        case Rec."Contract Type" of
                            Rec."Contract Type"::Quote:
                                begin
                                    ServContractHeader.Get(Rec."Contract Type", Rec."Contract No.");
                                    PAGE.Run(PAGE::"Service Contract Quote", ServContractHeader);
                                end;
                            Rec."Contract Type"::Contract:
                                begin
                                    ServContractHeader.Get(Rec."Contract Type", Rec."Contract No.");
                                    PAGE.Run(PAGE::"Service Contract", ServContractHeader);
                                end;
                        end;
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ServContractHeader: Record "Service Contract Header";
    begin
        ServContractHeader.Get(Rec."Contract Type", Rec."Contract No.");
        ContractDescription := ServContractHeader.Description;
    end;

    var
        ServContractHeader: Record "Service Contract Header";
        ContractDescription: Text[100];
}


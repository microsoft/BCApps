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
                }
                field("Contract Type"; Rec."Contract Type")
                {
                    ApplicationArea = Service;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
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
                    Visible = false;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Service;
                }
                field(Profit; Rec.Profit)
                {
                    ApplicationArea = Service;
                }
                field("Service Period"; Rec."Service Period")
                {
                    ApplicationArea = Service;
                }
                field("Next Planned Service Date"; Rec."Next Planned Service Date")
                {
                    ApplicationArea = Service;
                }
                field("Last Planned Service Date"; Rec."Last Planned Service Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Last Preventive Maint. Date"; Rec."Last Preventive Maint. Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Last Service Date"; Rec."Last Service Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                }
                field("Contract Expiration Date"; Rec."Contract Expiration Date")
                {
                    ApplicationArea = Service;
                }
                field("Credit Memo Date"; Rec."Credit Memo Date")
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


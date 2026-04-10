// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Finance.Dimension;

page 6055 "Service Contract Template"
{
    Caption = 'Service Contract Template';
    PageType = Card;
    SourceTable = "Service Contract Template";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEdit(Rec);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Contract Group Code"; Rec."Contract Group Code")
                {
                    ApplicationArea = Service;
                }
                field("Service Order Type"; Rec."Service Order Type")
                {
                    ApplicationArea = Service;
                }
                field("Default Service Period"; Rec."Default Service Period")
                {
                    ApplicationArea = Service;
                }
                field("Price Update Period"; Rec."Price Update Period")
                {
                    ApplicationArea = Service;
                }
                field("Default Response Time (Hours)"; Rec."Default Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the default response time for the service contract created from this service contract template.';
                }
                field("Max. Labor Unit Price"; Rec."Max. Labor Unit Price")
                {
                    ApplicationArea = Service;
                }
            }
            group(Invoice)
            {
                Caption = 'Invoice';
                field("Serv. Contract Acc. Gr. Code"; Rec."Serv. Contract Acc. Gr. Code")
                {
                    ApplicationArea = Service;
                }
                field("Invoice Period"; Rec."Invoice Period")
                {
                    ApplicationArea = Service;
                }
                field("Price Inv. Increase Code"; Rec."Price Inv. Increase Code")
                {
                    ApplicationArea = Service;
                    Caption = 'Contract Increase Text';
                }
                field(Prepaid; Rec.Prepaid)
                {
                    ApplicationArea = Service;
                    Enabled = PrepaidEnable;

                    trigger OnValidate()
                    begin
                        PrepaidOnAfterValidate();
                    end;
                }
                field("Allow Unbalanced Amounts"; Rec."Allow Unbalanced Amounts")
                {
                    ApplicationArea = Service;
                }
                field("Combine Invoices"; Rec."Combine Invoices")
                {
                    ApplicationArea = Service;
                }
                field("Automatic Credit Memos"; Rec."Automatic Credit Memos")
                {
                    ApplicationArea = Service;
                }
                field("Contract Lines on Invoice"; Rec."Contract Lines on Invoice")
                {
                    ApplicationArea = Service;
                }
                field("Invoice after Service"; Rec."Invoice after Service")
                {
                    ApplicationArea = Service;
                    Enabled = InvoiceAfterServiceEnable;

                    trigger OnValidate()
                    begin
                        InvoiceafterServiceOnAfterVali();
                    end;
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
            group("&Contract Template")
            {
                Caption = '&Contract Template';
                Image = Template;
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(5968),
                                  "No." = field("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("Service Dis&counts")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Dis&counts';
                    Image = Discount;
                    RunObject = Page "Contract/Service Discounts";
                    RunPageLink = "Contract Type" = const(Template),
                                  "Contract No." = field("No.");
                    ToolTip = 'View or edit the discounts that you grant for the contract on spare parts in particular service item groups, the discounts on resource hours for resources in particular resource groups, and the discounts on particular service costs.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ActivateFields();
    end;

    trigger OnInit()
    begin
        InvoiceAfterServiceEnable := true;
        PrepaidEnable := true;
    end;

    trigger OnOpenPage()
    begin
        ActivateFields();
    end;

    var
        PrepaidEnable: Boolean;
        InvoiceAfterServiceEnable: Boolean;

    local procedure ActivateFields()
    begin
        PrepaidEnable := (not Rec."Invoice after Service" or Rec.Prepaid);
        InvoiceAfterServiceEnable := (not Rec.Prepaid or Rec."Invoice after Service");
    end;

    local procedure InvoiceafterServiceOnAfterVali()
    begin
        ActivateFields();
    end;

    local procedure PrepaidOnAfterValidate()
    begin
        ActivateFields();
    end;
}


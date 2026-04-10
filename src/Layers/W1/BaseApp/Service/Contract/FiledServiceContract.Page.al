// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Foundation.Address;

page 6072 "Filed Service Contract"
{
    Caption = 'Filed Service Contract';
    DataCaptionExpression = Format(Rec."Contract Type") + ' ' + Rec."Contract No.";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    SourceTable = "Filed Service Contract Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = Service;
                }
                group("Sell-to")
                {
                    Caption = 'Sell-to';
                    field(Name; Rec.Name)
                    {
                        ApplicationArea = Service;
                    }
                    field(Address; Rec.Address)
                    {
                        ApplicationArea = Service;
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = Service;
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = Service;
                    }
                    group(Control9)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field(County; Rec.County)
                        {
                            ApplicationArea = Service;
                        }
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = Service;
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = Service;
                    }
                    field("Contact Name"; Rec."Contact Name")
                    {
                        ApplicationArea = Service;
                    }
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Service;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Service;
                    ExtendedDatatype = EMail;
                }
                field("Contract Group Code"; Rec."Contract Group Code")
                {
                    ApplicationArea = Service;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Service;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = Service;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Service;
                }
                field("Change Status"; Rec."Change Status")
                {
                    ApplicationArea = Service;
                }
            }
            part(Control93; "Filed Service Contract Subform")
            {
                ApplicationArea = Service;
                Editable = false;
                SubPageLink = "Entry No." = field("Entry No.");
                SubPageView = sorting("Entry No.", "Line No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                }
                field("Bill-to Contact No."; Rec."Bill-to Contact No.")
                {
                    ApplicationArea = Service;
                }
                group("Bill-to")
                {
                    Caption = 'Bill-to';
                    field("Bill-to Name"; Rec."Bill-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                    }
                    field("Bill-to Address"; Rec."Bill-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                    }
                    field("Bill-to Address 2"; Rec."Bill-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                    }
                    field("Bill-to City"; Rec."Bill-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                    }
                    group(Control20)
                    {
                        ShowCaption = false;
                        Visible = IsBillToCountyVisible;
                        field("Bill-to County"; Rec."Bill-to County")
                        {
                            ApplicationArea = Service;
                            CaptionClass = '5,1,' + Rec."Bill-to Country/Region Code";
                        }
                    }
                    field("Bill-to Post Code"; Rec."Bill-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                    }
                    field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
                    }
                    field("Bill-to Contact"; Rec."Bill-to Contact")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
                    }
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Service;
                }
                field("Serv. Contract Acc. Gr. Code"; Rec."Serv. Contract Acc. Gr. Code")
                {
                    ApplicationArea = Service;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Service;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Direct Debit Mandate ID"; Rec."Direct Debit Mandate ID")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Service;
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                }
                group("Ship-to")
                {
                    Caption = 'Ship-to';
                    field("Ship-to Name"; Rec."Ship-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                    }
                    field("Ship-to Address"; Rec."Ship-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                    }
                    field("Ship-to Address 2"; Rec."Ship-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                    }
                    field("Ship-to City"; Rec."Ship-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                    }
                    group(Control29)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; Rec."Ship-to County")
                        {
                            ApplicationArea = Service;
                            CaptionClass = '5,1,' + Rec."Ship-to Country/Region Code";
                        }
                    }
                    field("Ship-to Post Code"; Rec."Ship-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                    }
                    field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
                    }
                    field("Ship-to Phone No."; Rec."Ship-to Phone No.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Phone No.';
                    }
                }
            }
            group(Service)
            {
                Caption = 'Service';
                field("Service Zone Code"; Rec."Service Zone Code")
                {
                    ApplicationArea = Service;
                }
                field("Service Period"; Rec."Service Period")
                {
                    ApplicationArea = Service;
                }
                field("First Service Date"; Rec."First Service Date")
                {
                    ApplicationArea = Service;
                }
                field("Response Time (Hours)"; Rec."Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the default response time for the service items in the filed service contract or contract quote.';
                }
                field("Service Order Type"; Rec."Service Order Type")
                {
                    ApplicationArea = Service;
                }
            }
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                field("Annual Amount"; Rec."Annual Amount")
                {
                    ApplicationArea = Service;
                }
                field("Allow Unbalanced Amounts"; Rec."Allow Unbalanced Amounts")
                {
                    ApplicationArea = Service;
                }
                field("Calcd. Annual Amount"; Rec."Calcd. Annual Amount")
                {
                    ApplicationArea = Service;
                }
                field("Invoice Period"; Rec."Invoice Period")
                {
                    ApplicationArea = Service;
                }
                field("Next Invoice Date"; Rec."Next Invoice Date")
                {
                    ApplicationArea = Service;
                }
                field("Amount per Period"; Rec."Amount per Period")
                {
                    ApplicationArea = Service;
                }
                field(NextInvoicePeriod; Rec.NextInvoicePeriod())
                {
                    ApplicationArea = Service;
                    Caption = 'Next Invoice Period';
                    ToolTip = 'Specifies the next invoice period for the filed service contract agreements between your customers and your company.';
                }
                field("Last Invoice Date"; Rec."Last Invoice Date")
                {
                    ApplicationArea = Service;
                }
                field(Prepaid; Rec.Prepaid)
                {
                    ApplicationArea = Service;
                }
                field("Automatic Credit Memos"; Rec."Automatic Credit Memos")
                {
                    ApplicationArea = Service;
                }
                field("Invoice after Service"; Rec."Invoice after Service")
                {
                    ApplicationArea = Service;
                }
                field("Combine Invoices"; Rec."Combine Invoices")
                {
                    ApplicationArea = Service;
                }
                field("Contract Lines on Invoice"; Rec."Contract Lines on Invoice")
                {
                    ApplicationArea = Service;
                }
            }
            group("Price Update")
            {
                Caption = 'Price Update';
                field("Price Update Period"; Rec."Price Update Period")
                {
                    ApplicationArea = Service;
                }
                field("Next Price Update Date"; Rec."Next Price Update Date")
                {
                    ApplicationArea = Service;
                }
                field("Last Price Update %"; Rec."Last Price Update %")
                {
                    ApplicationArea = Service;
                }
                field("Last Price Update Date"; Rec."Last Price Update Date")
                {
                    ApplicationArea = Service;
                }
                field("Print Increase Text"; Rec."Print Increase Text")
                {
                    ApplicationArea = Service;
                }
                field("Price Inv. Increase Code"; Rec."Price Inv. Increase Code")
                {
                    ApplicationArea = Service;
                }
            }
            group(Detail)
            {
                Caption = 'Detail';
                field("Cancel Reason Code"; Rec."Cancel Reason Code")
                {
                    ApplicationArea = Service;
                }
                field("Max. Labor Unit Price"; Rec."Max. Labor Unit Price")
                {
                    ApplicationArea = Service;
                }
            }
            group("Filed Detail")
            {
                Caption = 'Filed Detail';
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("File Date"; Rec."File Date")
                {
                    ApplicationArea = Service;
                }
                field("File Time"; Rec."File Time")
                {
                    ApplicationArea = Service;
                }
                field("Reason for Filing"; Rec."Reason for Filing")
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
            group("&Contract")
            {
                Caption = '&Contract';
                Image = Agreement;
                action("Service Dis&counts")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Dis&counts';
                    Image = Discount;
                    RunObject = Page "Filed Contract/Serv. Discounts";
                    RunPageLink = "Entry No." = field("Entry No.");
                    ToolTip = 'View the discounts that you grant for the filed contract on spare parts in particular service item groups, the discounts on resource hours for resources in particular resource groups, and the discounts on particular service costs.';
                }
                action("Service &Hours")
                {
                    ApplicationArea = Service;
                    Caption = 'Service &Hours';
                    Image = ServiceHours;
                    RunObject = Page "Filed Contract Service Hours";
                    RunPageLink = "Entry No." = field("Entry No.");
                    ToolTip = 'View the service hours that are valid for the filed service contract. This window displays the starting and ending service hours for the contract for each weekday.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Service;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Filed Serv. Contract Cm. Sheet";
                    RunPageLink = "Entry No." = field("Entry No."),
                                  "Table Line No." = const(0);
                    ToolTip = 'View comments for the record.';
                }
            }
        }
    }

    var
        IsShipToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsBillToCountyVisible: Boolean;

    trigger OnOpenPage()
    begin
        Rec.SetSecurityFilterOnResponsibilityCenter();

        ActivateFields();
    end;

    local procedure ActivateFields()
    var
        FormatAddress: Codeunit "Format Address";
    begin
        IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
        IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
    end;
}


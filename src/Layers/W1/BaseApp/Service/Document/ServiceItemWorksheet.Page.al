// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Availability;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;
using Microsoft.Service.Item;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Pricing;
using Microsoft.Service.Setup;

page 5906 "Service Item Worksheet"
{
    Caption = 'Service Item Worksheet';
    DataCaptionExpression = Caption();
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Service Item Line";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the service order linked to this service item line.';
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the service item number registered in the Service Item table.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the item number linked to this service item.';
                }
                field("Service Item Group Code"; Rec."Service Item Group Code")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the code of the service item group for this item.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the serial number of this item.';
                }
                field("Fault Reason Code"; Rec."Fault Reason Code")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the fault reason code for the item.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Service;
                    Caption = 'Document Type';
                    Editable = false;
                    ToolTip = 'Specifies whether the service document is a service order or service quote.';
                }
                field("Loaner No."; Rec."Loaner No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the loaner that has been lent to the customer in the service order to replace this item.';
                }
                field("Service Shelf No."; Rec."Service Shelf No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service shelf this item is stored on.';
                }
                field("Service Price Group Code"; Rec."Service Price Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the service price group associated with the item.';
                }
                field("Fault Area Code"; Rec."Fault Area Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the fault area code for this item.';
                }
                field("Symptom Code"; Rec."Symptom Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the symptom code for this item.';
                }
                field("Fault Code"; Rec."Fault Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the fault code for this item.';
                }
                field("Resolution Code"; Rec."Resolution Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the resolution code for this item.';
                }
                field("Repair Status Code"; Rec."Repair Status Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the repair status of this service item.';
                }
            }
            part(ServInvLines; "Service Item Worksheet Subform")
            {
                ApplicationArea = Service;
                SubPageLink = "Document Type" = field("Document Type"),
                              "Document No." = field("Document No."),
                              "Service Item No." = field("Service Item No."),
                              "Service Item Line No." = field("Line No.");
                UpdatePropagation = Both;
            }
            group(Customer)
            {
                Caption = 'Customer';
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    Caption = 'Customer No.';
                    Editable = false;
                    ToolTip = 'Specifies the customer number associated with the service contract.';
                }
                group(Control3)
                {
                    ShowCaption = false;
                    field("ServHeader.Name"; ServHeader.Name)
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer.';
                    }
                    field("ServHeader.Address"; ServHeader.Address)
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        Editable = false;
                        ToolTip = 'Specifies the address.';
                    }
#pragma warning disable AA0100
                    field("ServHeader.""Address 2"""; ServHeader."Address 2")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        Editable = false;
                        ToolTip = 'Specifies the address.';
                    }
                    field("ServHeader.City"; ServHeader.City)
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        Editable = false;
                        ToolTip = 'Specifies the city of the customer''s address.';
                    }
                    group(Control13)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field("ServHeader.County"; ServHeader.County)
                        {
                            ApplicationArea = Service;
                            Caption = 'County';
                        }
                    }
#pragma warning disable AA0100
                    field("ServHeader.""Post Code"""; ServHeader."Post Code")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                    }
#pragma warning disable AA0100
                    field("ServHeader.""Country/Region Code"""; ServHeader."Country/Region Code")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';

                        trigger OnValidate()
                        begin
                            IsSellToCountyVisible := FormatAddress.UseCounty(ServHeader."Country/Region Code");
                        end;
                    }
#pragma warning disable AA0100
                    field("ServHeader.""Contact Name"""; ServHeader."Contact Name")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the person you regularly contact when you do business with this customer.';
                    }
                }
#pragma warning disable AA0100
                field("ServHeader.""Phone No."""; ServHeader."Phone No.")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Phone No.';
                    Editable = false;
                    ToolTip = 'Specifies the phone number of the customer.';
                }
                field("Location of Service Item"; Rec."Location of Service Item")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the code of the location of this item.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    Caption = 'Ship-to Code';
                    Editable = false;
                    ToolTip = 'Specifies the ship-to code of the service item associated with the service contract or service order.';
                }
                group(Control15)
                {
                    ShowCaption = false;
                    field(ShiptoName; ShiptoName)
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer at the shipping address. ';
                    }
                    field(ShiptoAddress; ShiptoAddress)
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        Editable = false;
                        ToolTip = 'Specifies the customer''s shipping address.';
                    }
                    field(ShiptoAddress2; ShiptoAddress2)
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        Editable = false;
                        ToolTip = 'Specifies an additional part of the customer''s shipping address.';
                    }
                    field(ShiptoPostCode; ShiptoPostCode)
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        Editable = false;
                        ToolTip = 'Specifies the customer''s post code.';
                    }
                    field(ShiptoCity; ShiptoCity)
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        Editable = false;
                        ToolTip = 'Specifies the city of the customer''s address.';
                    }
                    group(Control21)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field(ShiptoCounty; ShiptoCounty)
                        {
                            ApplicationArea = Service;
                            Caption = 'County';
                        }
                    }
                    field(ShiptoCountryRegion; ShiptoCountryRegion)
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';

                        trigger OnValidate()
                        begin
                            IsShipToCountyVisible := FormatAddress.UseCounty(ShiptoCountryRegion);
                        end;
                    }
#pragma warning disable AA0100
                    field("ServHeader.""Ship-to Contact"""; ServHeader."Ship-to Contact")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
                        Editable = false;
                        ToolTip = 'Specifies the contact person at the customer''s address.';
                    }
                }
#pragma warning disable AA0100
                field("ServHeader.""Ship-to Phone"""; ServHeader."Ship-to Phone")
#pragma warning restore AA0100
                {
                    ApplicationArea = Service;
                    Caption = 'Ship-to Phone No.';
                    Editable = false;
                    ToolTip = 'Specifies the phone number at the shipping address.';
                }
            }
            group(Details)
            {
                Caption = 'Details';
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the service contract associated with the item or service on the line.';
                }
                field(Warranty; Rec.Warranty)
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies that warranty on either parts or labor exists for this item.';
                }
                field("Response Date"; Rec."Response Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the estimated date when service should start on this service item line.';
                }
                field("Response Time"; Rec."Response Time")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the estimated time when service should start on this service item.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the service priority for this item.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date when service on this item began and when the repair status changed to In process.';
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the time when service on this item began and when the repair status changed to In process.';
                }
                field("Finishing Date"; Rec."Finishing Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the finishing date of the service and when the repair status of this item changes to Finished.';
                }
                field("Finishing Time"; Rec."Finishing Time")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the finishing time of the service and when the repair status of this item changes to Finished.';
                }
                field("No. of Previous Services"; Rec."No. of Previous Services")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of services performed on service items with the same item and serial number as this service item.';
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
            group("&Worksheet")
            {
                Caption = '&Worksheet';
                Image = Worksheet;
                group("Com&ments")
                {
                    Caption = 'Com&ments';
                    Image = ViewComments;
                    action(Faults)
                    {
                        ApplicationArea = Service;
                        Caption = 'Faults';
                        Image = Error;
                        RunObject = Page "Service Comment Sheet";
                        RunPageLink = "Table Name" = const("Service Header"),
                                      "Table Subtype" = field("Document Type"),
                                      "No." = field("Document No."),
                                      "Table Line No." = field("Line No."),
                                      Type = const(Fault);
                        ToolTip = 'View or edit the different fault codes that you can assign to service items. You can use fault codes to identify the different service item faults or the actions taken on service items for each combination of fault area and symptom codes.';
                    }
                    action(Resolutions)
                    {
                        ApplicationArea = Service;
                        Caption = 'Resolutions';
                        Image = Completed;
                        RunObject = Page "Service Comment Sheet";
                        RunPageLink = "Table Name" = const("Service Header"),
                                      "Table Subtype" = field("Document Type"),
                                      "No." = field("Document No."),
                                      "Table Line No." = field("Line No."),
                                      Type = const(Resolution);
                        ToolTip = 'View or edit the different resolution codes that you can assign to service items. You can use resolution codes to identify methods used to solve typical service problems.';
                    }
                    action(Internal)
                    {
                        ApplicationArea = Service;
                        Caption = 'Internal';
                        Image = Comment;
                        RunObject = Page "Service Comment Sheet";
                        RunPageLink = "Table Name" = const("Service Header"),
                                      "Table Subtype" = field("Document Type"),
                                      "No." = field("Document No."),
                                      "Table Line No." = field("Line No."),
                                      Type = const(Internal);
                        ToolTip = 'View or register internal comments for the service item. Internal comments are for internal use only and are not printed on reports.';
                    }
                    action(Accessories)
                    {
                        ApplicationArea = Service;
                        Caption = 'Accessories';
                        Image = ServiceAccessories;
                        RunObject = Page "Service Comment Sheet";
                        RunPageLink = "Table Name" = const("Service Header"),
                                      "Table Subtype" = field("Document Type"),
                                      "No." = field("Document No."),
                                      "Table Line No." = field("Line No."),
                                      Type = const(Accessory);
                        ToolTip = 'View or register comments for the accessories to the service item.';
                    }
                    action(Loaners)
                    {
                        ApplicationArea = Service;
                        Caption = 'Loaners';
                        Image = Loaners;
                        RunObject = Page "Service Comment Sheet";
                        RunPageLink = "Table Name" = const("Service Header"),
                                      "Table Subtype" = field("Document Type"),
                                      "No." = field("Document No."),
                                      "Table Line No." = field("Line No."),
                                      Type = const("Service Item Loaner");
                        ToolTip = 'View or select from items that you lend out temporarily to customers to replace items that they have in service.';
                    }
                }
                group("Service &Item")
                {
                    Caption = 'Service &Item';
                    Image = ServiceItem;
                    action(Card)
                    {
                        ApplicationArea = Service;
                        Caption = 'Card';
                        Image = EditLines;
                        RunObject = Page "Service Item Card";
                        RunPageLink = "No." = field("Service Item No.");
                        ShortCutKey = 'Shift+F7';
                        ToolTip = 'View or change detailed information about the record on the document or journal line.';
                    }
                    action("&Log")
                    {
                        ApplicationArea = Service;
                        Caption = '&Log';
                        Image = Approve;
                        RunObject = Page "Service Item Log";
                        RunPageLink = "Service Item No." = field("Service Item No.");
                        ToolTip = 'View a list of the service item changes that have been logged, for example, when the warranty has changed or a component has been added. This window displays the field that was changed, the old value and the new value, and the date and time that the field was changed.';
                    }
                }
                action("&Fault/Resol. Codes Relationships")
                {
                    ApplicationArea = Service;
                    Caption = '&Fault/Resol. Codes Relationships';
                    Image = FaultDefault;
                    ToolTip = 'View or edit the relationships between fault codes, including the fault, fault area, and symptom codes, as well as resolution codes and service item groups. It displays the existing combinations of these codes for the service item group of the service item from which you accessed the window and the number of occurrences for each one.';

                    trigger OnAction()
                    begin
                        SelectFaultResolutionCode();
                    end;
                }
                action("&Troubleshooting")
                {
                    ApplicationArea = Service;
                    Caption = '&Troubleshooting';
                    Image = Troubleshoot;
                    ToolTip = 'View or edit information about technical problems with a service item.';

                    trigger OnAction()
                    begin
                        TblshtgHeader.ShowForServItemLine(Rec);
                    end;
                }
                action("Demand Overview")
                {
                    ApplicationArea = Planning;
                    Caption = 'Demand Overview';
                    Image = Forecast;
                    ToolTip = 'Get an overview of demand for your items when planning sales, production, projects, or service management and when they will be available.';

                    trigger OnAction()
                    var
                        DemandOverview: Page "Demand Overview";
                    begin
                        DemandOverview.SetCalculationParameter(true);
                        DemandOverview.SetParameters(0D, Microsoft.Inventory.Requisition."Demand Order Source Type"::"Service Demand", Rec."Document No.", '', '');
                        DemandOverview.RunModal();
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Adjust Service Price")
                {
                    ApplicationArea = Service;
                    Caption = 'Adjust Service Price';
                    Image = PriceAdjustment;
                    ToolTip = 'Adjust existing service prices according to changed costs, spare parts, and resource hours. Note that prices are not adjusted for service items that belong to service contracts, service items with a warranty, items service on lines that are partially or fully invoiced. When you run the service price adjustment, all discounts in the order are replaced by the values of the service price adjustment.';

                    trigger OnAction()
                    var
                        ServPriceMgmt: Codeunit "Service Price Management";
                    begin
                        ServPriceMgmt.ShowPriceAdjustment(Rec);
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Service;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    ServItemLine: Record "Service Item Line";
                    ServDocumentPrint: Codeunit "Serv. Document Print";
                begin
                    ServItemLine := Rec;
                    ServItemLine.SetRecFilter();
                    ServDocumentPrint.PrintServiceItemWorksheet(ServItemLine);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("Adjust Service Price_Promoted"; "Adjust Service Price")
                {
                }
                actionref("&Fault/Resol. Codes Relationships_Promoted"; "&Fault/Resol. Codes Relationships")
                {
                }
                actionref("Demand Overview_Promoted"; "Demand Overview")
                {
                }
                actionref("&Troubleshooting_Promoted"; "&Troubleshooting")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ServHeader.Get(Rec."Document Type", Rec."Document No.");
        UpdateShiptoCode();
        if Rec."Serial No." = '' then
            Rec."No. of Previous Services" := 0;

        Rec.SetRange("Line No.");
        if not ServItem.Get(Rec."Service Item No.") then
            Clear(ServItem);

        CurrPage.ServInvLines.PAGE.SetValues(Rec."Line No.");
    end;

    trigger OnOpenPage()
    begin
        IsSellToCountyVisible := FormatAddress.UseCounty(ServHeader."Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(ServHeader."Ship-to Country/Region Code");
    end;

    var
        ServHeader: Record "Service Header";
        ShiptoAddr: Record "Ship-to Address";
        ServItem: Record "Service Item";
        TblshtgHeader: Record "Troubleshooting Header";
        FormatAddress: Codeunit "Format Address";
        ShiptoName: Text[100];
        ShiptoAddress: Text[100];
        ShiptoAddress2: Text[50];
        ShiptoPostCode: Code[20];
        ShiptoCity: Text[30];
        ShiptoCounty: Text[30];
        ShiptoCountryRegion: Code[10];
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;

#pragma warning disable AA0470
        CannotOpenWindowErr: Label 'You cannot open the window because %1 is %2 in the %3 table.';
#pragma warning restore AA0470

    procedure Caption(): Text
    begin
        if Rec."Service Item No." <> '' then
            exit(StrSubstNo('%1 %2', Rec."Service Item No.", Rec.Description));
        if Rec."Item No." <> '' then
            exit(StrSubstNo('%1 %2', Rec."Item No.", Rec.Description));
        exit(StrSubstNo('%1 %2', Rec."Serial No.", Rec.Description));
    end;

    local procedure SelectFaultResolutionCode()
    var
        ServSetup: Record "Service Mgt. Setup";
        FaultResolutionRelation: Page "Fault/Resol. Cod. Relationship";
    begin
        ServSetup.Get();
        case ServSetup."Fault Reporting Level" of
            ServSetup."Fault Reporting Level"::None:
                Error(
                  CannotOpenWindowErr,
                  ServSetup.FieldCaption("Fault Reporting Level"), ServSetup."Fault Reporting Level", ServSetup.TableCaption());
        end;
        Clear(FaultResolutionRelation);
        FaultResolutionRelation.SetDocument(DATABASE::"Service Item Line", Rec."Document Type".AsInteger(), Rec."Document No.", Rec."Line No.");
        FaultResolutionRelation.SetFilters(Rec."Symptom Code", Rec."Fault Code", Rec."Fault Area Code", Rec."Service Item Group Code");
        FaultResolutionRelation.RunModal();
        CurrPage.Update(false);
    end;

    local procedure UpdateShiptoCode()
    begin
        ServHeader.Get(Rec."Document Type", Rec."Document No.");
        if Rec."Ship-to Code" = '' then begin
            ShiptoName := ServHeader.Name;
            ShiptoAddress := ServHeader.Address;
            ShiptoAddress2 := ServHeader."Address 2";
            ShiptoPostCode := ServHeader."Post Code";
            ShiptoCity := ServHeader.City;
            ShiptoCounty := ServHeader.County;
            ShiptoCountryRegion := ServHeader."Country/Region Code";
        end else begin
            ShiptoAddr.Get(Rec."Customer No.", Rec."Ship-to Code");
            ShiptoName := ShiptoAddr.Name;
            ShiptoAddress := ShiptoAddr.Address;
            ShiptoAddress2 := ShiptoAddr."Address 2";
            ShiptoPostCode := ShiptoAddr."Post Code";
            ShiptoCity := ShiptoAddr.City;
            ShiptoCounty := ShiptoAddr.County;
            ShiptoCountryRegion := ShiptoAddr."Country/Region Code";
        end;
    end;
}


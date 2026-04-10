// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.Finance.Dimension;
using Microsoft.Service.Setup;

page 6275 "Service Quote Archive Lines"
{
    Caption = 'Service Quote Archive Lines';
    DataCaptionFields = "Document Type", "Document No.";
    PageType = Worksheet;
    PopulateAllFields = true;
    SourceTable = "Service Line Archive";

    layout
    {
        area(content)
        {
            field(SelectionFilter; SelectionFilter)
            {
                ApplicationArea = Service;
                Caption = 'Service Quote Lines Filter';
                OptionCaption = 'All,Per Selected Service Item Line,Service Item Line Non-Related';
                ToolTip = 'Specifies a selection filter.';

                trigger OnValidate()
                begin
                    SelectionFilterOnAfterValidate();
                end;
            }
            repeater(ServiceQuoteArchiveLines)
            {
                ShowCaption = false;
                Editable = false;

                field("Service Item Line No."; Rec."Service Item Line No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                }
                field("Service Item Serial No."; Rec."Service Item Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;
                }
                field("Service Item Line Description"; Rec."Service Item Line Description")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies the description of the service item line in the service quote.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Service;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field(Nonstock; Rec.Nonstock)
                {
                    ApplicationArea = Service;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    DecimalPlaces = 0 : 5;
                }
                field("Fault Reason Code"; Rec."Fault Reason Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Fault Area Code"; Rec."Fault Area Code")
                {
                    ApplicationArea = Service;
                    Visible = FaultAreaCodeVisible;
                }
                field("Symptom Code"; Rec."Symptom Code")
                {
                    ApplicationArea = Service;
                    Visible = SymptomCodeVisible;
                }
                field("Fault Code"; Rec."Fault Code")
                {
                    ApplicationArea = Service;
                    Visible = FaultCodeVisible;
                }
                field("Resolution Code"; Rec."Resolution Code")
                {
                    ApplicationArea = Service;
                    Visible = ResolutionCodeVisible;
                }
                field("Serv. Price Adjmt. Gr. Code"; Rec."Serv. Price Adjmt. Gr. Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                }
                field("Line Discount Type"; Rec."Line Discount Type")
                {
                    ApplicationArea = Service;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Inv. Discount Amount"; Rec."Inv. Discount Amount")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                }
                field("Exclude Warranty"; Rec."Exclude Warranty")
                {
                    ApplicationArea = Service;
                }
                field("Exclude Contract Discount"; Rec."Exclude Contract Discount")
                {
                    ApplicationArea = Service;
                }
                field(Warranty; Rec.Warranty)
                {
                    ApplicationArea = Service;
                }
                field("Warranty Disc. %"; Rec."Warranty Disc. %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    Visible = false;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                }
                field("Contract Disc. %"; Rec."Contract Disc. %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    Visible = false;
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    Visible = false;
                }
                field("VAT Base Amount"; Rec."VAT Base Amount")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    Visible = false;
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Posting Group"; Rec."Posting Group")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Service;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Line)
            {
                Caption = 'Line';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnOpenPage(Rec, FaultAreaCodeVisible, SymptomCodeVisible, FaultCodeVisible, ResolutionCodeVisible, IsHandled);
        if not IsHandled then begin
            Clear(SelectionFilter);
            SetSelectionFilter();

            ServiceMgtSetup.SetLoadFields("Fault Reporting Level");
            ServiceMgtSetup.Get();
            case ServiceMgtSetup."Fault Reporting Level" of
                ServiceMgtSetup."Fault Reporting Level"::None:
                    begin
                        FaultAreaCodeVisible := false;
                        SymptomCodeVisible := false;
                        FaultCodeVisible := false;
                        ResolutionCodeVisible := false;
                    end;
                ServiceMgtSetup."Fault Reporting Level"::Fault:
                    begin
                        FaultAreaCodeVisible := false;
                        SymptomCodeVisible := false;
                        FaultCodeVisible := true;
                        ResolutionCodeVisible := true;
                    end;
                ServiceMgtSetup."Fault Reporting Level"::"Fault+Symptom":
                    begin
                        FaultAreaCodeVisible := false;
                        SymptomCodeVisible := true;
                        FaultCodeVisible := true;
                        ResolutionCodeVisible := true;
                    end;
                ServiceMgtSetup."Fault Reporting Level"::"Fault+Symptom+Area (IRIS)":
                    begin
                        FaultAreaCodeVisible := true;
                        SymptomCodeVisible := true;
                        FaultCodeVisible := true;
                        ResolutionCodeVisible := true;
                    end;
            end;
        end;

        OnAfterOnOpenPage(ServiceMgtSetup, FaultAreaCodeVisible, SymptomCodeVisible, FaultCodeVisible, ResolutionCodeVisible);
    end;

    var
        ServiceItemLineNo: Integer;
        SelectionFilter: Option "All Service Lines","Lines per Selected Service Item","Lines Not Item Related";
        FaultAreaCodeVisible: Boolean;
        SymptomCodeVisible: Boolean;
        FaultCodeVisible: Boolean;
        ResolutionCodeVisible: Boolean;

    procedure Initialize(ServiceItemLineNoToSet: Integer)
    begin
        ServiceItemLineNo := ServiceItemLineNoToSet;
        OnAfterInitialize(Rec, ServiceItemLineNo, SelectionFilter);
    end;

    procedure SetSelectionFilter()
    begin
        case SelectionFilter of
            SelectionFilter::"All Service Lines":
                Rec.SetRange("Service Item Line No.");
            SelectionFilter::"Lines per Selected Service Item":
                Rec.SetRange("Service Item Line No.", ServiceItemLineNo);
            SelectionFilter::"Lines Not Item Related":
                Rec.SetRange("Service Item Line No.", 0);
        end;
        CurrPage.Update(false);
    end;

    local procedure SelectionFilterOnAfterValidate()
    begin
        CurrPage.Update();
        SetSelectionFilter();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnOpenPage(var ServiceLineArchive: Record "Service Line Archive"; var FaultAreaCodeVisible: Boolean; var SymptomCodeVisible: Boolean; var FaultCodeVisible: Boolean; var ResolutionCodeVisible: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnOpenPage(var ServiceMgtSetup: Record "Service Mgt. Setup"; var FaultAreaCodeVisible: Boolean; var SymptomCodeVisible: Boolean; var FaultCodeVisible: Boolean; var ResolutionCodeVisible: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitialize(var ServiceLineArchive: Record "Service Line Archive"; var ServiceItemLineNo: Integer; var SelectionFilter: Option "All Service Lines","Lines per Selected Service Item","Lines Not Item Related");
    begin
    end;
}
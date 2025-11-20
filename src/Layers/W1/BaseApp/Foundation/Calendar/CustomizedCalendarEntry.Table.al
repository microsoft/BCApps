// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Calendar;

using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 7603 "Customized Calendar Entry"
{
    Caption = 'Customized Calendar Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Source Type"; Enum "Calendar Source Type")
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(2; "Source Code"; Code[20])
        {
            Caption = 'Source Code';
            Editable = false;
        }
        field(3; "Additional Source Code"; Code[20])
        {
            Caption = 'Additional Source Code';
        }
        field(4; "Base Calendar Code"; Code[10])
        {
            Caption = 'Base Calendar Code';
            Editable = false;
            TableRelation = "Base Calendar";
        }
        field(5; Date; Date)
        {
            Caption = 'Date';
            Editable = false;
        }
        field(6; Description; Text[30])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                UpdateExceptionEntry();
            end;
        }
        field(7; Nonworking; Boolean)
        {
            Caption = 'Nonworking';
            Editable = true;

            trigger OnValidate()
            begin
                UpdateExceptionEntry();
            end;
        }
    }

    keys
    {
        key(Key1; "Source Type", "Source Code", "Additional Source Code", "Base Calendar Code", Date)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure UpdateExceptionEntry()
    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
    begin
        CustomizedCalendarChange.SetRange("Source Type", "Source Type");
        CustomizedCalendarChange.SetRange("Source Code", "Source Code");
        CustomizedCalendarChange.SetRange("Base Calendar Code", "Base Calendar Code");
        CustomizedCalendarChange.SetRange(Date, Date);
        CustomizedCalendarChange.DeleteAll();

        CustomizedCalendarChange.Init();
        CustomizedCalendarChange."Source Type" := "Source Type";
        CustomizedCalendarChange."Source Code" := "Source Code";
        CustomizedCalendarChange."Base Calendar Code" := "Base Calendar Code";
        CustomizedCalendarChange.Validate(Date, Date);
        CustomizedCalendarChange.Nonworking := Nonworking;
        CustomizedCalendarChange.Description := Description;
        OnUpdateExceptionEntryOnBeforeInsert(CustomizedCalendarChange, Rec);
        CustomizedCalendarChange.Insert();

        OnAfterUpdateExceptionEntry(CustomizedCalendarChange, Rec);
    end;

    procedure GetCaption() TableCaption: Text[250]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Location: Record Location;
        ShippingAgentService: Record "Shipping Agent Services";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCaption(Rec, TableCaption, IsHandled);
        if not IsHandled then
            case "Source Type" of
                "Source Type"::Company:
                    exit(CompanyName);
                "Source Type"::Customer:
                    if Customer.Get("Source Code") then
                        exit("Source Code" + ' ' + Customer.Name);
                "Source Type"::Vendor:
                    if Vendor.Get("Source Code") then
                        exit("Source Code" + ' ' + Vendor.Name);
                "Source Type"::Location:
                    if Location.Get("Source Code") then
                        exit("Source Code" + ' ' + Location.Name);
                "Source Type"::"Shipping Agent":
                    if ShippingAgentService.Get("Source Code", "Additional Source Code") then
                        exit("Source Code" + ' ' + "Additional Source Code" + ' ' + ShippingAgentService.Description);
                else
                    OnGetCaptionOnCaseElse(Rec, TableCaption);
            end;
    end;

    procedure CopyFromCustomizedCalendarChange(CustomizedCalendarChange: Record "Customized Calendar Change")
    begin
        "Source Type" := CustomizedCalendarChange."Source Type";
        "Source Code" := CustomizedCalendarChange."Source Code";
        "Additional Source Code" := CustomizedCalendarChange."Additional Source Code";
        "Base Calendar Code" := CustomizedCalendarChange."Base Calendar Code";
        Date := CustomizedCalendarChange.Date;
        Description := CustomizedCalendarChange.Description;
        Nonworking := CustomizedCalendarChange.Nonworking;
        OnAfterCopyFromCustomizedCalendarChange(CustomizedCalendarChange, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromCustomizedCalendarChange(CustomizedCalendarChange: Record "Customized Calendar Change"; var CustomizedCalendarEntry: Record "Customized Calendar Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateExceptionEntry(var CustomizedCalendarChange: Record "Customized Calendar Change"; CustomizedCalendarEntry: Record "Customized Calendar Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCaption(var CustomizedCalendarEntry: Record "Customized Calendar Entry"; var TableCaption: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCaptionOnCaseElse(var CustomizedCalendarEntry: Record "Customized Calendar Entry"; var TableCaption: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateExceptionEntryOnBeforeInsert(var CustomizedCalendarChange: Record "Customized Calendar Change"; CustomizedCalendarEntry: Record "Customized Calendar Entry")
    begin
    end;
}


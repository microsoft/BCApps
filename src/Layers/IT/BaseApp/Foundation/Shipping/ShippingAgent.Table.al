// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Shipping;

using Microsoft.CRM.Contact;
using Microsoft.Foundation.Calendar;
using Microsoft.Integration.Dataverse;
using Microsoft.Purchases.Vendor;

table 291 "Shipping Agent"
{
    Caption = 'Shipping Agent';
    DataCaptionFields = "Code", Name;
    DrillDownPageID = "Shipping Agents";
    LookupPageID = "Shipping Agents";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "Internet Address"; Text[250])
        {
            Caption = 'Internet Address';
            ExtendedDatatype = URL;
        }
        field(4; "Account No."; Text[30])
        {
            Caption = 'Account No.';
        }
        field(12180; Address; Text[80])
        {
            Caption = 'Address';
        }
        field(12181; "Shipping Agent Type"; Option)
        {
            Caption = 'Shipping Agent Type';
            OptionCaption = ' ,Vendor,Contact';
            OptionMembers = " ",Vendor,Contact;

            trigger OnValidate()
            begin
                if "Shipping Agent Type" <> xRec."Shipping Agent Type" then
                    "Shipping Agent No." := '';
            end;
        }
        field(12182; "Shipping Agent No."; Code[20])
        {
            Caption = 'Shipping Agent No.';
            TableRelation = if ("Shipping Agent Type" = const(Vendor)) Vendor."No."
            else
            if ("Shipping Agent Type" = const(Contact)) Contact."No." where(Type = filter(Company));
        }
#if not CLEANSCHEMA26
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dataverse';
            Editable = false;
            ObsoleteReason = 'Replaced by page control Coupled to Dataverse';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Name)
        {
        }
    }

    trigger OnDelete()
    var
        ShippingAgentServices: Record "Shipping Agent Services";
    begin
        ShippingAgentServices.SetRange("Shipping Agent Code", Code);
        ShippingAgentServices.DeleteAll();

        CalendarManagement.DeleteCustomizedBaseCalendarData(CustomizedCalendarChange."Source Type"::"Shipping Agent", Code);
    end;

    trigger OnRename()
    var
        CRMSyncHelper: Codeunit "CRM Synch. Helper";
    begin
        CalendarManagement.RenameCustomizedBaseCalendarData(CustomizedCalendarChange."Source Type"::"Shipping Agent", Code, xRec.Code);
        CRMSyncHelper.UpdateCDSOptionMapping(xRec.RecordId(), RecordId());
    end;

    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CalendarManagement: Codeunit "Calendar Management";

    procedure ShippingAgentVendorOrContact(ShippingAgentCode: Code[10]): Boolean
    begin
        if Get(ShippingAgentCode) and
          ("Shipping Agent Type" <> "Shipping Agent Type"::" ")
        then begin
            TestField("Shipping Agent No.");
            exit(true);
        end;
    end;

    procedure GetTDDAddr(ShippingAgentCode: Code[10]; var AddrArray: array[8] of Text[100])
    var
        Vendor: Record Vendor;
        Contact: Record Contact;
    begin
        Get(ShippingAgentCode);
        case "Shipping Agent Type" of
            "Shipping Agent Type"::Vendor:
                Vendor.GetTDDAddr("Shipping Agent No.", AddrArray);
            "Shipping Agent Type"::Contact:
                Contact.GetTDDAddr("Shipping Agent No.", AddrArray);
        end;
    end;

    procedure GetTrackingInternetAddr(PackageTrackingNo: Text[50]) TrackingInternetAddr: Text
    var
        HttpStr: Text;
        HttpsStr: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetTrackingInternetAddr(Rec, TrackingInternetAddr, IsHandled, PackageTrackingNo);
        if IsHandled then
            exit;

        HttpStr := 'http://';
        HttpsStr := 'https://';
        TrackingInternetAddr := StrSubstNo("Internet Address", PackageTrackingNo);

        if (StrPos(TrackingInternetAddr, HttpStr) = 0) and (StrPos(TrackingInternetAddr, HttpsStr) = 0) then
            TrackingInternetAddr := HttpStr + TrackingInternetAddr;
    end;

#pragma warning disable AS0027
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTrackingInternetAddr(var ShippingAgent: Record "Shipping Agent"; var TrackingInternetAddr: Text; var IsHandled: Boolean; PackageTrackingNo: Text[50])
    begin
    end;
#pragma warning restore AS0027
}

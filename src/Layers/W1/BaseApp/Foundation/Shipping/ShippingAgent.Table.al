// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Shipping;

using Microsoft.Foundation.Calendar;
using Microsoft.Integration.Dataverse;

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
            ToolTip = 'Specifies a shipping agent code.';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
            ToolTip = 'Specifies a description of the shipping agent.';
        }
        field(3; "Internet Address"; Text[250])
        {
            Caption = 'Internet Address';
            ToolTip = 'Specifies the URL for the shipping agent''s package tracking system. To let users track specific packages, add %1 to the URL. When users track a package, the tracking number will replace %1. Example, http://www.providername.com/track?awb=%1.';
            ExtendedDatatype = URL;
        }
        field(4; "Account No."; Text[30])
        {
            Caption = 'Account No.';
            ToolTip = 'Specifies the account number that the shipping agent has assigned to your company.';
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

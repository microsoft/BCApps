// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Item;
using Microsoft.Service.Pricing;
using Microsoft.Service.Setup;

table 5972 "Contract/Service Discount"
{
    Caption = 'Contract/Service Discount';
    DataCaptionFields = "Contract Type", "Contract No.";
    LookupPageID = "Contract/Service Discounts";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Contract Type"; Enum "Service Contract Type")
        {
            Caption = 'Contract Type';
        }
        field(2; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = if ("Contract Type" = const(Template)) "Service Contract Template"."No."
            else
            if ("Contract Type" = const(Contract)) "Service Contract Header"."Contract No." where("Contract Type" = const(Contract))
            else
            if ("Contract Type" = const(Quote)) "Service Contract Header"."Contract No." where("Contract Type" = const(Quote));
        }
        field(4; Type; Enum "Service Contract Discount Type")
        {
            Caption = 'Type';
        }
        field(5; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const("Service Item Group")) "Service Item Group".Code
            else
            if (Type = const("Resource Group")) "Resource Group"."No."
            else
            if (Type = const(Cost)) "Service Cost".Code;
            //This property is currently not supported
            //TestTableRelation = true;
        }
        field(6; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(7; "Discount %"; Decimal)
        {
            Caption = 'Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Contract Type", "Contract No.", Type, "No.", "Starting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if "Contract Type" = "Contract Type"::Contract then begin
            VerifyContractOpen();
            ServMgtSetup.Get();
            if ServMgtSetup."Register Contract Changes" then
                ContractChangeLog.LogContractChange(
                  "Contract No.", 2, StrSubstNo('%1 %2 %3', Type, "No.", FieldCaption("No.")), 2,
                  Format("No."), '', '', 0);
        end;
    end;

    trigger OnInsert()
    begin
        TestField("Contract No.");
        if "Contract Type" = "Contract Type"::Contract then begin
            VerifyContractOpen();
            ServMgtSetup.Get();
            if ServMgtSetup."Register Contract Changes" then
                ContractChangeLog.LogContractChange(
                  "Contract No.", 2, StrSubstNo('%1 %2 %3', Type, "No.", FieldCaption("No.")), 1,
                  '', Format("No."), '', 0);
        end;
    end;

    trigger OnModify()
    begin
        if "Contract Type" = "Contract Type"::Contract then begin
            VerifyContractOpen();
            ServMgtSetup.Get();
            if "Discount %" <> xRec."Discount %" then
                if ServMgtSetup."Register Contract Changes" then
                    ContractChangeLog.LogContractChange(
                      "Contract No.", 2, StrSubstNo('%1 %2 %3', Type, "No.", FieldCaption("Discount %")), 0,
                      Format(xRec."Discount %"), Format("Discount %"), '', 0);
        end;
    end;

    trigger OnRename()
    begin
        Error(Text000);
    end;

    var
        ContractChangeLog: Record "Contract Change Log";
        ServMgtSetup: Record "Service Mgt. Setup";

#pragma warning disable AA0074
        Text000: Label 'You cannot rename the record.';
#pragma warning restore AA0074

    local procedure VerifyContractOpen()
    var
        ServiceContractHeader: Record "Service Contract Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyContractOpen(Rec, IsHandled);
        if IsHandled then
            exit;

        ServiceContractHeader.Get("Contract Type", "Contract No.");
        ServiceContractHeader.TestField("Change Status", ServiceContractHeader."Change Status"::Open);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyContractOpen(var ContractServiceDiscount: Record "Contract/Service Discount"; var IsHandled: Boolean)
    begin
    end;
}


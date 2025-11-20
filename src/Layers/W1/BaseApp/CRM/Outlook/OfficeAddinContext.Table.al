// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using System;

table 1600 "Office Add-in Context"
{
    Caption = 'Office Add-in Context';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Email; Text[80])
        {
            Caption = 'Email';
            Description = 'Email address of the Outlook contact.';
        }
        field(2; Name; Text[250])
        {
            Caption = 'Name';
            Description = 'Display name of the Outlook contact.';
        }
        field(3; "Document Type"; Text[20])
        {
            Caption = 'Document Type';
            Description = 'Type of the referenced document.';
        }
        field(4; "Document No."; Code[250])
        {
            Caption = 'Document No.';
            Description = 'No. of the referenced document.';
        }
        field(5; "Regular Expression Match"; Text[250])
        {
            Caption = 'Regular Expression Match';
            Description = 'Raw regular expression match.';
        }
        field(6; Duration; Text[20])
        {
            Caption = 'Duration';
            Description = 'Duration of the meeting.';
        }
        field(8; Command; Text[30])
        {
            Caption = 'Command';
            Description = 'Outlook add-in command.';
        }
        field(12; "Item ID"; Text[250])
        {
            Caption = 'Item ID';
            Description = 'Exchange item ID.';
        }
        field(13; Version; Text[20])
        {
            Caption = 'Version';
            Description = 'Add-in version';
        }
        field(14; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
        }
        field(15; Subject; Text[250])
        {
            Caption = 'Subject';
            Description = 'Subject of the appointment or message.';
        }
        field(16; "Item Type"; Option)
        {
            Caption = 'Item Type';
            OptionCaption = 'Message,Appointment';
            OptionMembers = Message,Appointment;
        }
        field(18; Mode; Option)
        {
            Caption = 'Mode';
            OptionCaption = 'Read,Compose';
            OptionMembers = Read,Compose;
        }
        field(20; Company; Text[50])
        {
            Caption = 'Company';
            DataClassification = OrganizationIdentifiableInformation;
        }
    }

    keys
    {
        key(Key1; Email)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure CommandType() Type: Integer
    var
        DummyOfficeContactDetails: Record "Office Contact Details";
        OutlookCommand: DotNet OutlookCommand;
    begin
        case Command of
            OutlookCommand.NewPurchaseCreditMemo, OutlookCommand.NewPurchaseInvoice, OutlookCommand.NewPurchaseOrder:
                Type := DummyOfficeContactDetails."Associated Table"::Vendor;
            OutlookCommand.NewSalesCreditMemo, OutlookCommand.NewSalesInvoice,
          OutlookCommand.NewSalesOrder, OutlookCommand.NewSalesQuote:
                Type := DummyOfficeContactDetails."Associated Table"::Customer;
            else
                Type := DummyOfficeContactDetails."Associated Table"::" ";
        end;
    end;

    procedure IsAppointment(): Boolean
    begin
        exit("Item Type" = "Item Type"::Appointment);
    end;
}


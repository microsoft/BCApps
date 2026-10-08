// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;

table 10970 "FR E-Invoice Message"
{
    Access = Internal;
    Caption = 'FR E-Invoice Message';
    DataClassification = CustomerContent;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "FR E-Invoice Message VAT" = d;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "E-Document Entry No."; Integer)
        {
            Caption = 'E-Document Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "E-Document"."Entry No";
        }
        field(3; Type; Enum "FR E-Invoice Message Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the French lifecycle status represented by this message.';
        }
        field(4; "Source Occurrence ID"; Guid)
        {
            Caption = 'Source Occurrence ID';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the immutable source identifier used to prevent duplicate lifecycle messages.';
        }
        field(5; "Original Entry No."; Integer)
        {
            Caption = 'Original Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "FR E-Invoice Message"."Entry No.";
            ToolTip = 'Specifies the original collected message reversed by a negative collected message.';
        }
        field(6; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the payment amount reported by a collected or negative collected message.';
        }
        field(7; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the currency of the reported payment amount.';
        }
        field(8; "Event Date"; Date)
        {
            Caption = 'Event Date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the business date on which the lifecycle event occurred.';
        }
        field(9; "Detailed Ledger Entry No."; Integer)
        {
            Caption = 'Detailed Ledger Entry No.';
            DataClassification = SystemMetadata;
        }
        field(10; "Reason Code"; Code[20])
        {
            Caption = 'Reason Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the reason code supplied for the lifecycle status.';
        }
        field(11; "Reason Description"; Text[500])
        {
            Caption = 'Reason Description';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the reason description supplied for the lifecycle status.';
        }
        field(12; "E-Document Message Entry No."; Integer)
        {
            Caption = 'E-Document Message Entry No.';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the related generic E-Document message entry.';
        }
        field(13; "Created At"; DateTime)
        {
            Caption = 'Created At';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies when the French lifecycle message was created.';
        }
        field(14; "External Message ID"; Text[250])
        {
            Caption = 'External Message ID';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the identifier assigned to an incoming lifecycle message by the external service.';
        }
        field(15; "Received At"; DateTime)
        {
            Caption = 'Received At';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies when the incoming lifecycle message was received.';
        }
        field(16; "Sender Platform ID"; Text[50])
        {
            Caption = 'Sender Platform ID';
            DataClassification = OrganizationIdentifiableInformation;
            ToolTip = 'Specifies the frozen identifier of the sender platform.';
        }
        field(17; "Sender Platform Scheme"; Code[4])
        {
            Caption = 'Sender Platform Scheme';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the frozen identifier scheme of the sender platform.';
        }
        field(18; "Sender Platform Name"; Text[100])
        {
            Caption = 'Sender Platform Name';
            DataClassification = OrganizationIdentifiableInformation;
            ToolTip = 'Specifies the frozen name of the sender platform.';
        }
        field(19; "Invoice Issue Date"; Date)
        {
            Caption = 'Invoice Issue Date';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the frozen issue date of the invoice.';
        }
        field(20; "Invoice Receipt At"; DateTime)
        {
            Caption = 'Invoice Receipt At';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the frozen date and time when the sender platform received the invoice.';
        }
        field(21; "Invoice Issuer ID"; Text[50])
        {
            Caption = 'Invoice Issuer ID';
            DataClassification = OrganizationIdentifiableInformation;
            ToolTip = 'Specifies the frozen SIREN identifier of the invoice issuer.';
        }
        field(22; "Invoice Issuer Scheme"; Code[4])
        {
            Caption = 'Invoice Issuer Scheme';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the frozen identifier scheme of the invoice issuer.';
        }
        field(23; "Invoice Issuer Name"; Text[100])
        {
            Caption = 'Invoice Issuer Name';
            DataClassification = OrganizationIdentifiableInformation;
            ToolTip = 'Specifies the frozen name of the invoice issuer.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Occurrence; "E-Document Entry No.", "Source Occurrence ID", Type)
        {
            Unique = true;
        }
        key(EDocumentType; "E-Document Entry No.", Type)
        {
        }
        key(DetailedLedgerEntry; Type, "Detailed Ledger Entry No.")
        {
        }
        key(EDocumentMessage; "E-Document Message Entry No.")
        {
        }
    }

    trigger OnDelete()
    var
        FREInvoiceMessageVAT: Record "FR E-Invoice Message VAT";
    begin
        FREInvoiceMessageVAT.SetRange("Message Entry No.", Rec."Entry No.");
        FREInvoiceMessageVAT.DeleteAll(false);
    end;
}
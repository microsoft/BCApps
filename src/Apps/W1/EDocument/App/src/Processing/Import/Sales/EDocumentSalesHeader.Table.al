// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Sales;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.Sales.Customer;
using System.Telemetry;

table 6153 "E-Document Sales Header"
{
    Access = Internal;
    ReplicateData = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "E-Document Entry No."; Integer)
        {
            Caption = 'E-Document Entry No.';
            TableRelation = "E-Document"."Entry No";
            DataClassification = SystemMetadata;
            ValidateTableRelation = true;
        }
        #region External data - Sales fields [2-100]
        field(2; "Buyer Company Name"; Text[250])
        {
            Caption = 'Buyer Company Name';
            DataClassification = CustomerContent;
        }
        field(3; "Buyer Company Id"; Text[250])
        {
            Caption = 'Buyer Company Id';
            DataClassification = CustomerContent;
        }
        field(4; "Buyer Order No."; Text[100])
        {
            Caption = 'Buyer Order No.';
            DataClassification = CustomerContent;
        }
        field(5; "Seller Sales Order No."; Text[100])
        {
            Caption = 'Seller Sales Order No.';
            DataClassification = CustomerContent;
        }
        field(6; "Document Date"; Date)
        {
            Caption = 'Document Date';
            DataClassification = CustomerContent;
        }
        field(7; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
            DataClassification = CustomerContent;
        }
        field(8; "Note"; Text[250])
        {
            Caption = 'Note';
            DataClassification = CustomerContent;
        }
        field(9; "Customer Reference"; Text[100])
        {
            Caption = 'Customer Reference';
            DataClassification = CustomerContent;
        }
        field(10; "Seller Company Name"; Text[250])
        {
            Caption = 'Seller Company Name';
            DataClassification = CustomerContent;
        }
        field(11; "Seller Address"; Text[250])
        {
            Caption = 'Seller Address';
            DataClassification = CustomerContent;
        }
        field(12; "Seller Address Recipient"; Text[250])
        {
            Caption = 'Seller Address Recipient';
            DataClassification = CustomerContent;
        }
        field(13; "Buyer Address"; Text[250])
        {
            Caption = 'Buyer Address';
            DataClassification = CustomerContent;
        }
        field(14; "Buyer Address Recipient"; Text[250])
        {
            Caption = 'Buyer Address Recipient';
            DataClassification = CustomerContent;
        }
        field(15; "Originator Company Name"; Text[250])
        {
            Caption = 'Originator Company Name';
            DataClassification = CustomerContent;
        }
        field(16; "Accounting Customer Name"; Text[250])
        {
            Caption = 'Accounting Customer Name';
            DataClassification = CustomerContent;
        }
        field(17; "Sub Total"; Decimal)
        {
            Caption = 'Sub Total';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(18; "Total Discount"; Decimal)
        {
            Caption = 'Total Discount';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(19; "Total VAT"; Decimal)
        {
            Caption = 'Total VAT';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(20; Total; Decimal)
        {
            Caption = 'Total';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(21; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
        }
        field(22; "Buyer VAT Id"; Text[100])
        {
            Caption = 'Buyer VAT Id';
            DataClassification = CustomerContent;
        }
        field(23; "Seller VAT Id"; Text[100])
        {
            Caption = 'Seller VAT Id';
            DataClassification = CustomerContent;
        }
        field(24; "Buyer GLN"; Text[13])
        {
            Caption = 'Buyer Global Location Number';
            DataClassification = CustomerContent;
        }
        field(25; "Seller GLN"; Text[13])
        {
            Caption = 'Seller Global Location Number';
            DataClassification = CustomerContent;
        }
        field(26; "Order Type Code"; Text[10])
        {
            Caption = 'Order Type Code';
            DataClassification = CustomerContent;
        }
        field(27; "Buyer External Id"; Text[250])
        {
            Caption = 'Buyer External Id';
            DataClassification = CustomerContent;
        }
        #endregion Sales fields

        #region Business Central Data - Validated fields [101-200]
        field(101; "[BC] Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            DataClassification = CustomerContent;
            TableRelation = Customer."No.";
        }
        #endregion Business Central Data
    }
    keys
    {
        key(PK; "E-Document Entry No.")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
        Telemetry: Codeunit Telemetry;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Set('Category', FeatureName());
        CustomDimensions.Set('SystemId', EDocImpSessionTelemetry.CreateSystemIdText(Rec.SystemId));
        Telemetry.LogMessage('0000UEU', DeleteDraftPerformedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
        FeatureTelemetry.LogUsage('0000UET', FeatureName(), 'Discard draft');
    end;

    procedure GetFromEDocument(EDocument: Record "E-Document")
    begin
        Clear(Rec);
        if Rec.Get(EDocument."Entry No") then;
    end;

    procedure InsertForEDocument(EDocument: Record "E-Document")
    begin
        if not Rec.Get(EDocument."Entry No") then begin
            Rec."E-Document Entry No." := EDocument."Entry No";
            Rec.Insert();
        end;
    end;

    procedure GetBCCustomer() Customer: Record Customer
    begin
        if Customer.Get(Rec."[BC] Customer No.") then;
    end;

    internal procedure FeatureName(): Text
    begin
        exit('E-Document Sales Order Import');
    end;

    var
        DeleteDraftPerformedTxt: Label 'User deleted the draft.', Locked = true;
}

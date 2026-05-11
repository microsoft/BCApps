// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Purchase;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.Log;
using System.Telemetry;

table 6100 "E-Document Purchase Header"
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
        #region External data - Purchase fields [2-100]
        field(2; "Customer Company Name"; Text[250])
        {
            Caption = 'Customer Company Name';
            DataClassification = CustomerContent;
        }
        field(3; "Customer Company Id"; Text[250])
        {
            Caption = 'Customer Company Id';
            DataClassification = CustomerContent;
        }
        field(4; "Purchase Order No."; Text[100])
        {
            Caption = 'Purchase Order No.';
            DataClassification = CustomerContent;
        }
        field(5; "Sales Invoice No."; Text[100])
        {
            Caption = 'Sales Invoice No.';
            DataClassification = CustomerContent;
        }
        field(6; "Invoice Date"; Date)
        {
            Caption = 'Invoice Date';
            DataClassification = CustomerContent;
        }
        field(7; "Due Date"; Date)
        {
            Caption = 'Due Date';
            DataClassification = CustomerContent;
        }
        field(8; "Document Date"; Date)
        {
            Caption = 'Document Date';
            DataClassification = CustomerContent;
        }
        field(9; "Vendor Company Name"; Text[250])
        {
            Caption = 'Vendor Company Name';
            DataClassification = CustomerContent;
        }
        field(10; "Vendor Address"; Text[250])
        {
            Caption = 'Vendor Address';
            DataClassification = CustomerContent;
        }
        field(11; "Vendor Address Recipient"; Text[250])
        {
            Caption = 'Vendor Address Recipient';
            DataClassification = CustomerContent;
        }
        field(12; "Customer Address"; Text[250])
        {
            Caption = 'Customer Address';
            DataClassification = CustomerContent;
        }
        field(13; "Customer Address Recipient"; Text[250])
        {
            Caption = 'Customer Address Recipient';
            DataClassification = CustomerContent;
        }
        field(14; "Billing Address"; Text[250])
        {
            Caption = 'Billing Address';
            DataClassification = CustomerContent;
        }
        field(15; "Billing Address Recipient"; Text[250])
        {
            Caption = 'Billing Address Recipient';
            DataClassification = CustomerContent;
        }
        field(16; "Shipping Address"; Text[250])
        {
            Caption = 'Shipping Address';
            DataClassification = CustomerContent;
        }
        field(17; "Shipping Address Recipient"; Text[250])
        {
            Caption = 'Shipping Address Recipient';
            DataClassification = CustomerContent;
        }
        field(18; "Sub Total"; Decimal)
        {
            Caption = 'Sub Total';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(19; "Total Discount"; Decimal)
        {
            Caption = 'Total Discount';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(20; "Total VAT"; Decimal)
        {
            Caption = 'Total VAT';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(21; Total; Decimal)
        {
            Caption = 'Total';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(22; "Amount Due"; Decimal)
        {
            Caption = 'Amount Due';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(23; "Previous Unpaid Balance"; Decimal)
        {
            Caption = 'Previous Unpaid Balance';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(24; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
        }
        field(25; "Remittance Address"; Text[250])
        {
            Caption = 'Remittance Address';
            DataClassification = CustomerContent;
        }
        field(26; "Remittance Address Recipient"; Text[250])
        {
            Caption = 'Remittance Address Recipient';
            DataClassification = CustomerContent;
        }
        field(27; "Service Address"; Text[250])
        {
            Caption = 'Service Address';
            DataClassification = CustomerContent;
        }
        field(28; "Service Address Recipient"; Text[250])
        {
            Caption = 'Service Address Recipient';
            DataClassification = CustomerContent;
        }
        field(29; "Service Start Date"; Date)
        {
            Caption = 'Service Start Date';
            DataClassification = CustomerContent;
        }
        field(30; "Service End Date"; Date)
        {
            Caption = 'Service End Date';
            DataClassification = CustomerContent;
        }
        field(31; "Vendor VAT Id"; Text[100])
        {
            Caption = 'Vendor VAT Id';
            DataClassification = CustomerContent;
        }
        field(32; "Customer VAT Id"; Text[100])
        {
            Caption = 'Customer VAT Id';
            DataClassification = CustomerContent;
        }
        field(33; "Payment Terms"; Text[250])
        {
            Caption = 'Payment Terms';
            DataClassification = CustomerContent;
        }
        field(34; "Customer GLN"; Text[13])
        {
            Caption = 'Customer Global Location Number';
            DataClassification = CustomerContent;
        }
        field(35; "Vendor GLN"; Text[13])
        {
            Caption = 'Vendor Global Location Number';
            DataClassification = CustomerContent;
        }
        field(36; "Vendor External Id"; Text[250])
        {
            Caption = 'Vendor External Id';
            DataClassification = CustomerContent;
        }
        field(37; "Vendor Contact Name"; Text[250])
        {
            Caption = 'Vendor Contact Name';
            DataClassification = CustomerContent;
        }
        field(38; "Posting Description"; Text[100])
        {
            Caption = 'Posting Description';
            DataClassification = CustomerContent;
        }
        field(39; "Applies-to Doc. No."; Text[100])
        {
            Caption = 'Applies-to Doc. No.';
            DataClassification = CustomerContent;
        }
        field(40; "Vendor Invoice No."; Text[100])
        {
            Caption = 'Vendor Invoice No.';
            DataClassification = CustomerContent;
        }
        field(41; "Total Line Amount"; Decimal)
        {
            Caption = 'Total Line Amount';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Editable = false;
        }
        field(42; "Total Line VAT Amount"; Decimal)
        {
            Caption = 'Total Line VAT Amount';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Editable = false;
        }
        field(43; "Total Line Amt. Incl. VAT"; Decimal)
        {
            Caption = 'Total Line Amt. Incl. VAT';
            DataClassification = CustomerContent;
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Editable = false;
        }
        #endregion Purchase fields

        #region Business Central Data - Validated fields [101-200]
        field(101; "[BC] Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            DataClassification = CustomerContent;
            TableRelation = Vendor."No.";
        }
        field(102; "[BC] Purchase Order No."; Code[20])
        {
            Caption = 'Purchase Order No.';
            DataClassification = CustomerContent;
            TableRelation = "Purchase Header"."No." where("Document Type" = const(Order));
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
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Set('Category', FeatureName());
        CustomDimensions.Set('SystemId', EDocImpSessionTelemetry.CreateSystemIdText(Rec.SystemId));
        Telemetry.LogMessage('0000PCQ', DeleteDraftPerformedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
        FeatureTelemetry.LogUsage('0000PCV', FeatureName(), 'Discard draft');
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

    procedure GetBCVendor() Vendor: Record Vendor
    begin
        if Vendor.Get(Rec."[BC] Vendor No.") then;
    end;

    internal procedure LogHeaderLinesMismatch()
    var
        ActivityLog: Codeunit "Activity Log Builder";
        Reasoning: Text[250];
        SubTotalMismatchReasonLbl: Label 'The document Sub Total %1 does not match the computed Total Line Amount %2.', Comment = '%1 = Sub Total from document, %2 = computed Total Line Amount';
        VATMismatchReasonLbl: Label 'The document Total VAT %1 does not match the computed Total Line VAT Amount %2.', Comment = '%1 = Total VAT from document, %2 = computed Total Line VAT Amount';
        TotalMismatchReasonLbl: Label 'The document Total %1 does not match the computed Total Line Amt. Incl. VAT %2.', Comment = '%1 = Total from document, %2 = computed Total Line Amt. Incl. VAT';
    begin
        if (Rec."Sub Total" <> 0) and (Rec."Sub Total" <> Rec."Total Line Amount") then begin
            Reasoning := CopyStr(StrSubstNo(SubTotalMismatchReasonLbl, Rec."Sub Total", Rec."Total Line Amount"), 1, MaxStrLen(Reasoning));
            ActivityLog
                .Init(Database::"E-Document Purchase Header", Rec.FieldNo("Total Line Amount"), Rec.SystemId)
                .SetExplanation(Reasoning)
                .SetType(Enum::"Activity Log Type"::"AL")
                .Log();
        end;

        if (Rec."Total VAT" <> 0) and (Rec."Total VAT" <> Rec."Total Line VAT Amount") then begin
            Reasoning := CopyStr(StrSubstNo(VATMismatchReasonLbl, Rec."Total VAT", Rec."Total Line VAT Amount"), 1, MaxStrLen(Reasoning));
            ActivityLog
                .Init(Database::"E-Document Purchase Header", Rec.FieldNo("Total Line VAT Amount"), Rec.SystemId)
                .SetExplanation(Reasoning)
                .SetType(Enum::"Activity Log Type"::"AL")
                .Log();
        end;

        if (Rec.Total <> 0) and (Rec.Total <> Rec."Total Line Amt. Incl. VAT") then begin
            Reasoning := CopyStr(StrSubstNo(TotalMismatchReasonLbl, Rec.Total, Rec."Total Line Amt. Incl. VAT"), 1, MaxStrLen(Reasoning));
            ActivityLog
                .Init(Database::"E-Document Purchase Header", Rec.FieldNo("Total Line Amt. Incl. VAT"), Rec.SystemId)
                .SetExplanation(Reasoning)
                .SetType(Enum::"Activity Log Type"::"AL")
                .Log();
        end;
    end;

    internal procedure FeatureName(): Text
    begin
        exit('E-Document Matching Assistance');
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        DeleteDraftPerformedTxt: Label 'User deleted the draft.', Locked = true;

}

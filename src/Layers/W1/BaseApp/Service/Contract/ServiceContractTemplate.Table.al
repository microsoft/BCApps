// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.NoSeries;
using Microsoft.Service.Document;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.Globalization;

table 5968 "Service Contract Template"
{
    Caption = 'Service Contract Template';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Service Contract Template List";
    LookupPageID = "Service Contract Template List";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." <> xRec."No." then begin
                    ServMgtSetup.Get();
                    NoSeries.TestManual(ServMgtSetup."Contract Template Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Invoice Period"; Option)
        {
            Caption = 'Invoice Period';
            OptionCaption = 'Month,Two Months,Quarter,Half Year,Year,None';
            OptionMembers = Month,"Two Months",Quarter,"Half Year",Year,"None";
        }
        field(4; "Max. Labor Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Max. Labor Unit Price';
        }
        field(5; "Combine Invoices"; Boolean)
        {
            Caption = 'Combine Invoices';
        }
        field(6; Prepaid; Boolean)
        {
            Caption = 'Prepaid';

            trigger OnValidate()
            begin
                if "Invoice after Service" and Prepaid then
                    Error(
                      Text001,
                      FieldCaption("Invoice after Service"),
                      FieldCaption(Prepaid));
            end;
        }
        field(7; "Service Zone Code"; Code[10])
        {
            Caption = 'Service Zone Code';
            TableRelation = "Service Zone";
        }
        field(8; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(9; "Default Response Time (Hours)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Default Response Time (Hours)';
            DecimalPlaces = 0 : 5;
        }
        field(10; "Contract Lines on Invoice"; Boolean)
        {
            Caption = 'Contract Lines on Invoice';
        }
        field(11; "Default Service Period"; DateFormula)
        {
            Caption = 'Default Service Period';
        }
        field(14; "Invoice after Service"; Boolean)
        {
            Caption = 'Invoice after Service';

            trigger OnValidate()
            begin
                if not ServHeader.ReadPermission and
                   "Invoice after Service" = true
                then
                    Error(Text000);
                if "Invoice after Service" and Prepaid then
                    Error(
                      Text001,
                      FieldCaption("Invoice after Service"),
                      FieldCaption(Prepaid));
            end;
        }
        field(15; "Allow Unbalanced Amounts"; Boolean)
        {
            Caption = 'Allow Unbalanced Amounts';
        }
        field(16; "Contract Group Code"; Code[10])
        {
            Caption = 'Contract Group Code';
            TableRelation = "Contract Group";
        }
        field(17; "Service Order Type"; Code[10])
        {
            Caption = 'Service Order Type';
            TableRelation = "Service Order Type";
        }
        field(18; "Automatic Credit Memos"; Boolean)
        {
            Caption = 'Automatic Credit Memos';
        }
        field(20; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(21; "Price Update Period"; DateFormula)
        {
            Caption = 'Price Update Period';
        }
        field(22; "Price Inv. Increase Code"; Code[20])
        {
            Caption = 'Price Inv. Increase Code';
            TableRelation = "Standard Text";
        }
        field(23; "Serv. Contract Acc. Gr. Code"; Code[10])
        {
            Caption = 'Serv. Contract Acc. Gr. Code';
            TableRelation = "Service Contract Account Group".Code;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DimMgt.DeleteDefaultDim(DATABASE::"Service Contract Template", "No.");
        ServContract.SetCurrentKey("Template No.");
        ServContract.SetRange("Template No.", "No.");
        ServContract.ModifyAll("Template No.", '');
    end;

    trigger OnInsert()
    begin
        ServMgtSetup.Get();
        if "No." = '' then begin
            ServMgtSetup.TestField("Contract Template Nos.");
                "No. Series" := ServMgtSetup."Contract Template Nos.";
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(DATABASE::"Service Contract Template", xRec."No.", "No.");
    end;

    var
        ServHeader: Record "Service Header";
        ServContractTemplate: Record "Service Contract Template";
        ServContract: Record "Service Contract Header";
        ServMgtSetup: Record "Service Mgt. Setup";
        NoSeries: Codeunit "No. Series";
        DimMgt: Codeunit DimensionManagement;
#pragma warning disable AA0074
        Text000: Label 'You cannot checkmark this field because you do not have permissions for the Service Order Management Area.';
#pragma warning disable AA0470
        Text001: Label 'You cannot select both %1 and %2 check boxes.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure AssistEdit(OldServContractTmplt: Record "Service Contract Template"): Boolean
    begin
        ServContractTemplate := Rec;
        ServMgtSetup.Get();
        ServMgtSetup.TestField("Contract Template Nos.");
        if NoSeries.LookupRelatedNoSeries(ServMgtSetup."Contract Template Nos.", OldServContractTmplt."No. Series", ServContractTemplate."No. Series") then begin
            ServContractTemplate."No." := NoSeries.GetNextNo(ServContractTemplate."No. Series");
            Rec := ServContractTemplate;
            exit(true);
        end;
    end;
}

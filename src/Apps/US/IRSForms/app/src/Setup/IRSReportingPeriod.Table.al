// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 10031 "IRS Reporting Period"
{
    DataClassification = CustomerContent;
    DrillDownPageId = "IRS Reporting Periods";
    LookupPageId = "IRS Reporting Periods";

    fields
    {
        field(1; "No."; Code[20])
        {
            NotBlank = true;
        }
        field(2; "Starting Date"; Date)
        {
            NotBlank = true;

            trigger OnValidate()
            begin
                CheckStartingAndEndingDatesConsistency();
                CheckNoConnectedFormDocuments(FieldCaption("Starting Date"));
            end;
        }
        field(3; "Ending Date"; Date)
        {
            NotBlank = true;

            trigger OnValidate()
            begin
                CheckStartingAndEndingDatesConsistency();
                CheckNoConnectedFormDocuments(FieldCaption("Ending Date"));
            end;
        }
        field(4; Description; Text[250])
        {
        }
        field(5; "IRIS XML Schema Version Test"; Enum "XML Schema Version IRIS")
        {
            Caption = 'IRIS XML Schema Version TEST';
            ToolTip = 'Specifies the XML schema override for new TEST transmissions. Leave empty to use the configured TEST version.';

            trigger OnValidate()
            begin
                ValidateSchemaOverride("IRIS XML Schema Version Test");
            end;
        }
        field(6; "IRIS XML Schema Version Live"; Enum "XML Schema Version IRIS")
        {
            Caption = 'IRIS XML Schema Version Production';
            ToolTip = 'Specifies the XML schema override for new production transmissions. Leave empty to use the configured production version.';

            trigger OnValidate()
            begin
                ValidateSchemaOverride("IRIS XML Schema Version Live");
            end;
        }
        field(100; "Forms In Period"; Integer)
        {
            CalcFormula = count("IRS 1099 Form" where("Period No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(101; "IRIS Transmission"; Boolean)
        {
            Caption = 'IRIS Transmission';
            ToolTip = 'Specifies if the IRIS transmission has been created for this reporting period.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = exist("Transmission IRIS" where("Period No." = field("No.")));
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }

    var
        StartingEndingDateOverlapErr: Label 'The starting date and ending date overlap with an existing reporting period.';
        CannotChangeWhenOpenFormDocumentConnectedErr: Label 'Cannot change %1 when one or more open form documents are connected', Comment = '%1 - field caption';
        StartingDateMoreThanEndingDateErr: Label 'Starting date cannot be greater than ending date';

    trigger OnDelete()
    var
        IRS1099Form: Record "IRS 1099 Form";
        IRS1099VendorFormBoxSetup: Record "IRS 1099 Vendor Form Box Setup";
        IRS1099VendorFormBoxAdj: Record "IRS 1099 Vendor Form Box Adj.";
        DocHeader: Record "IRS 1099 Form Doc. Header";
        PeriodIsUsedErr: Label 'Reporting period %1 is used by 1099 form documents and cannot be deleted.', Comment = '%1 = reporting period';
    begin
        DocHeader.SetRange("Period No.", "No.");
        if not DocHeader.IsEmpty() then
            Error(PeriodIsUsedErr, "No.");
        IRS1099Form.SetRange("Period No.", "No.");
        IRS1099Form.DeleteAll(true);
        IRS1099VendorFormBoxSetup.SetRange("Period No.", "No.");
        IRS1099VendorFormBoxSetup.DeleteAll(true);
        IRS1099VendorFormBoxAdj.SetRange("Period No.", "No.");
        IRS1099VendorFormBoxAdj.DeleteAll(true);
    end;

    internal procedure GetSchemaOverride(TestEnvironment: Boolean): Enum "XML Schema Version IRIS"
    begin
        if TestEnvironment then
            exit("IRIS XML Schema Version Test");
        exit("IRIS XML Schema Version Live");
    end;

    internal procedure SetSchemaOverride(TestEnvironment: Boolean; SchemaVersion: Enum "XML Schema Version IRIS")
    begin
        if TestEnvironment then
            Validate("IRIS XML Schema Version Test", SchemaVersion)
        else
            Validate("IRIS XML Schema Version Live", SchemaVersion);
    end;

    local procedure ValidateSchemaOverride(SchemaVersion: Enum "XML Schema Version IRIS")
    var
        Helper: Codeunit "Helper IRIS";
    begin
        if SchemaVersion <> SchemaVersion::" " then
            Helper.CheckSchemaVersionSupported(SchemaVersion);
    end;

    local procedure CheckNoConnectedFormDocuments(ChangedFieldCaption: Text)
    var
        IRS1099FormDocHeader: Record "IRS 1099 Form Doc. Header";
    begin
        IRS1099FormDocHeader.SetRange("Period No.", "No.");
        if not IRS1099FormDocHeader.IsEmpty() then
            Error(CannotChangeWhenOpenFormDocumentConnectedErr, ChangedFieldCaption);
    end;

    local procedure CheckStartingAndEndingDatesConsistency()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        if (Rec."Starting Date" <> 0D) and (Rec."Ending Date" <> 0D) then begin
            if Rec."Starting Date" > Rec."Ending Date" then
                Error(StartingDateMoreThanEndingDateErr);
            IRSReportingPeriod.SetFilter("No.", '<>%1', Rec."No.");
            if not IRSReportingPeriod.FindSet() then
                exit;
            repeat
                if ("Starting Date" in [IRSReportingPeriod."Starting Date" .. IRSReportingPeriod."Ending Date"]) or
                   ("Ending Date" in [IRSReportingPeriod."Starting Date" .. IRSReportingPeriod."Ending Date"])
                then
                    Error(StartingEndingDateOverlapErr);
            until IRSReportingPeriod.Next() = 0;
        end;
    end;
}

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using Microsoft.Integration.Dataverse;
using System.IO;
using System.Reflection;
using System.Threading;

table 5336 "Integration Field Mapping"
{
    Caption = 'Integration Field Mapping';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'No.';
        }
        field(2; "Integration Table Mapping Name"; Code[20])
        {
            Caption = 'Integration Table Mapping Name';
            TableRelation = "Integration Table Mapping".Name;
        }
        field(3; "Field No."; Integer)
        {
            Caption = 'Field No.';
            ToolTip = 'Specifies the number of the field in Business Central.';
        }
        field(4; "Integration Table Field No."; Integer)
        {
            Caption = 'Integration Table Field No.';
            ToolTip = 'Specifies the number of the field in Dynamics 365 Sales.';
        }
        field(6; Direction; Option)
        {
            Caption = 'Direction';
            ToolTip = 'Specifies the direction of the synchronization.';
            OptionCaption = 'Bidirectional,ToIntegrationTable,FromIntegrationTable';
            OptionMembers = Bidirectional,ToIntegrationTable,FromIntegrationTable;

            trigger OnValidate()
            var
                "Field": Record "Field";
                IntegrationTableMapping: Record "Integration Table Mapping";
                CRMFullSynchReviewLine: Record "CRM Full Synch. Review Line";
                JobQueueEntry: Record "Job Queue Entry";
            begin
                IntegrationTableMapping.Get("Integration Table Mapping Name");
                if IntegrationTableMapping."Int. Table UID Field Type" = Field.Type::Option then
                    if Direction = Direction::Bidirectional then
                        Error(OptionMappingCannotBeBidirectionalErr)
                    else begin
                        IntegrationTableMapping.Direction := Direction;
                        IntegrationTableMapping.Modify();

                        if CRMFullSynchReviewLine.Get("Integration Table Mapping Name") then
                            if CRMFullSynchReviewLine.Direction <> Direction then begin
                                CRMFullSynchReviewLine.Direction := Direction;
                                CRMFullSynchReviewLine.Modify();
                            end;

                        if Direction = Direction::ToIntegrationTable then begin
                            JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId);
                            JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
                            JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
                            if JobQueueEntry.FindFirst() then
                                if JobQueueEntry.Status = JobQueueEntry.Status::Ready then begin
                                    JobQueueEntry.Status := JobQueueEntry.Status::"On Hold with Inactivity Timeout";
                                    JobQueueEntry.Modify();
                                end;
                        end;
                    end;
            end;
        }
        field(7; "Constant Value"; Text[100])
        {
            Caption = 'Constant Value';
            ToolTip = 'Specifies the constant value that the mapped field will be set to.';
        }
        field(8; "Validate Field"; Boolean)
        {
            Caption = 'Validate Field';
            ToolTip = 'Specifies if the field should be validated during assignment in Business Central.';
        }
        field(9; "Validate Integration Table Fld"; Boolean)
        {
            Caption = 'Validate Integration Table Fld';
            ToolTip = 'Specifies if the integration field should be validated during assignment in Dynamics 365 Sales.';
        }
        field(10; "Clear Value on Failed Sync"; Boolean)
        {
            Caption = 'Clear Value on Failed Sync';
            ToolTip = 'Specifies if the field value should be cleared in case of integration error during assignment in Dynamics 365 Sales.';

            trigger OnValidate()
            begin
                TestField("Not Null", false)
            end;
        }
        field(11; Status; Option)
        {
            Caption = 'Status';
            ToolTip = 'Specifies if field synchronization is enabled or disabled.';
            OptionCaption = 'Enabled,Disabled';
            OptionMembers = Enabled,Disabled;
        }
        field(12; "Not Null"; Boolean)
        {
            Caption = 'Not Null';
            ToolTip = 'Specifies if the data transfer should be skipped for destination fields whose new value is going to be null. This is only applicable for GUID fields, such as OwnerId, that must not be changed to null during synchronization.';

            trigger OnValidate()
            begin
                TestField("Clear Value on Failed Sync", false);
                if not IsGUIDField() then
                    Error(NotNullIsApplicableForGUIDErr);
            end;
        }
        field(13; "Transformation Rule"; Code[20])
        {
            Caption = 'Transformation Rule';
            ToolTip = 'Specifies a rule for transforming imported text to a supported value before it can be mapped to a specified field in Microsoft Dynamics 365.';
            DataClassification = SystemMetadata;
            TableRelation = "Transformation Rule";
        }
        field(14; "Transformation Direction"; Enum "CDS Transformation Direction")
        {
            Caption = 'Transformation Direction';
            ToolTip = 'Specifies the direction of the transformation.';

            trigger OnValidate()
            begin
                PutTransferDirection();
            end;
        }
        field(15; "Use For Match-Based Coupling"; Boolean)
        {
            Caption = 'Use For Match-Based Coupling';
            ToolTip = 'Specifies whether to match on this field when looking for the entity to couple to.';
        }
        field(16; "Case-Sensitive Matching"; Boolean)
        {
            Caption = 'Case-Sensitive Matching';
            ToolTip = 'Specifies whether the matching on this field should be case-sensitive.';
        }
        field(17; "Match Priority"; Integer)
        {
            MinValue = 0;
            BlankZero = true;
            Caption = 'Match Priority';
            ToolTip = 'Specifies in which priority order will the groups of matching fields be used to find a match.';
        }
        field(18; "Field Caption"; Text[250])
        {
            Caption = 'Field Caption';
        }
        field(19; "Integration Field Caption"; Text[250])
        {
            Caption = 'Integration Field Caption';
        }
        field(20; "User Defined"; Boolean)
        {
            Caption = 'User Defined';
            ToolTip = 'Specifies if the field is generated manually through the integration table mapping wizard.';
            Description = 'Indicates whether the field mapping was defined manually by the user or by the system.';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Integration Table Mapping Name")
        {
        }
        key(Key3; "Match Priority")
        {
        }
        key(Key4; "Transformation Rule")
        {
        }
    }

    fieldgroups
    {
    }

    var
        NotNullIsApplicableForGUIDErr: Label 'The Not Null value is applicable for GUID fields only.';
        OptionMappingCannotBeBidirectionalErr: Label 'Option mappings can only synchronize from integration table or to integration table.';

    trigger OnInsert()
    begin
        PutTransferDirection();
    end;

    trigger OnModify()
    begin
        PutTransferDirection();
    end;

    procedure CreateRecord(IntegrationTableMappingName: Code[20]; TableFieldNo: Integer; IntegrationTableFieldNo: Integer; SynchDirection: Option; ConstValue: Text; ValidateField: Boolean; ValidateIntegrationTableField: Boolean)
    begin
        CreateRecord(IntegrationTableMappingName, TableFieldNo, IntegrationTableFieldNo, SynchDirection, ConstValue, ValidateField, ValidateIntegrationTableField, true, '', false);
    end;

    internal procedure CreateRecord(IntegrationTableMappingName: Code[20]; TableFieldNo: Integer; IntegrationTableFieldNo: Integer; SynchDirection: Option; ConstValue: Text; ValidateField: Boolean; ValidateIntegrationTableField: Boolean; Enabled: Boolean; TransformationRule: Code[20]; UserDefined: Boolean)
    begin
        Init();
        "No." := 0;
        "Integration Table Mapping Name" := IntegrationTableMappingName;
        "Field No." := TableFieldNo;
        "Integration Table Field No." := IntegrationTableFieldNo;
        Direction := SynchDirection;
        "Constant Value" := CopyStr(ConstValue, 1, MaxStrLen("Constant Value"));
        "Validate Field" := ValidateField;
        "Validate Integration Table Fld" := ValidateIntegrationTableField;
        if Enabled then
            Status := Status::Enabled
        else
            Status := Status::Disabled;

        "Transformation Rule" := TransformationRule;
        "User Defined" := UserDefined;
        Insert();
    end;

    internal procedure SetMatchBasedCouplingFilters(IntegrationTableMapping: Record "Integration Table Mapping")
    var
        LocalField: Record Field;
        IntegrationField: Record Field;
    begin
        Rec.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
        Rec.SetRange("Constant Value", '');
        if not Rec.FindSet() then
            exit;

        repeat
            Rec.Mark(true);
            LocalField.SetRange(TableNo, IntegrationTableMapping."Table ID");
            LocalField.SetRange("No.", Rec."Field No.");
            IntegrationField.SetRange(TableNo, IntegrationTableMapping."Integration Table ID");
            IntegrationField.SetRange("No.", Rec."Integration Table Field No.");
            if LocalField.FindFirst() then
                if IntegrationField.FindFirst() then begin
                    case LocalField.Type of
                        LocalField.Type::Blob,
                        LocalField.Type::Media,
                        LocalField.Type::MediaSet:
                            Rec.Mark(false)
                    end;
                    case IntegrationField.Type of
                        IntegrationField.Type::Blob,
                        IntegrationField.Type::Media,
                        IntegrationField.Type::MediaSet:
                            Rec.Mark(false)
                    end;
                    if LocalField.Type <> IntegrationField.Type then begin
                        case LocalField.Type of
                            LocalField.Type::Guid,
                            LocalField.Type::DateFormula,
                            LocalField.Type::Duration,
                            LocalField.Type::RecordId:
                                Rec.Mark(false);
                        end;
                        case IntegrationField.Type of
                            IntegrationField.Type::Guid,
                            IntegrationField.Type::DateFormula,
                            IntegrationField.Type::Duration,
                            IntegrationField.Type::RecordId:
                                Rec.Mark(false);
                        end;
                    end;
                end;
        until Rec.Next() = 0;
        Rec.MarkedOnly(true);
    end;

    local procedure IsGUIDField(): Boolean
    var
        "Field": Record "Field";
        IntegrationTableMapping: Record "Integration Table Mapping";
        TypeHelper: Codeunit "Type Helper";
    begin
        IntegrationTableMapping.Get("Integration Table Mapping Name");
        if TypeHelper.GetField(IntegrationTableMapping."Integration Table ID", "Integration Table Field No.", Field) then
            exit(Field.Type = Field.Type::GUID);
    end;

    local procedure PutTransferDirection()
    begin
        if Direction <> Direction::Bidirectional then
            case Direction of
                Direction::ToIntegrationTable:
                    "Transformation Direction" := "Transformation Direction"::ToIntegrationTable;
                Direction::FromIntegrationTable:
                    "Transformation Direction" := "Transformation Direction"::FromIntegrationTable;
            end;
    end;
}


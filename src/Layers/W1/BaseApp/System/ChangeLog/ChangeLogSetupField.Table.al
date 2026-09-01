namespace System.Diagnostics;

using System.Reflection;
using System.Telemetry;

table 404 "Change Log Setup (Field)"
{
    Caption = 'Change Log Setup (Field)';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
            TableRelation = "Change Log Setup (Table)";
        }
        field(2; "Field No."; Integer)
        {
            Caption = 'Field No.';
            TableRelation = Field."No." where(TableNo = field("Table No."));
        }
        field(3; "Field Caption"; Text[100])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table No."),
                                                              "No." = field("Field No.")));
            Caption = 'Field Caption';
            FieldClass = FlowField;
        }
        field(4; "Log Insertion"; Boolean)
        {
            Caption = 'Log Insertion';
        }
        field(5; "Log Modification"; Boolean)
        {
            Caption = 'Log Modification';
        }
        field(6; "Log Deletion"; Boolean)
        {
            Caption = 'Log Deletion';
        }
        field(7; "Monitor Sensitive Field"; Boolean)
        {
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                AuditLog: Codeunit "Audit Log";
                EnabledLbl: Label 'Enabled', Locked = true;
                DisabledLbl: Label 'Disabled', Locked = true;
                AuditMessageLbl: Label 'Field Monitoring has been %1 for the field %2 in the table %3 by UserSecurityId %4.', Locked = true;
                AuditMessageTxt: Text;
            begin
                if "Monitor Sensitive Field" then
                    AuditMessageTxt := StrSubstNo(AuditMessageLbl, EnabledLbl, "Field Caption", "Table Caption", UserSecurityId())
                else
                    AuditMessageTxt := StrSubstNo(AuditMessageLbl, DisabledLbl, "Field Caption", "Table Caption", UserSecurityId());

                AuditLog.LogAuditMessage(AuditMessageTxt, SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 3, 0);
            end;
        }
        field(8; Notify; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(9; "Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table No.")));
            Caption = 'Table Caption';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Table No.", "Field No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if "Monitor Sensitive Field" then
            MonitorSensitiveField.DeleteChangeLogSetupTable("Table No.", "Field No.");
    end;

    trigger OnRename()
    begin
        if "Monitor Sensitive Field" then begin
            MonitorSensitiveField.DeleteChangeLogSetupTable(xRec."Table No.", xRec."Field No.");
            MonitorSensitiveField.InsertChangeLogSetupTable(Rec."Table No.");
        end;
    end;

    var
        MonitorSensitiveField: Codeunit "Monitor Sensitive Field";

}


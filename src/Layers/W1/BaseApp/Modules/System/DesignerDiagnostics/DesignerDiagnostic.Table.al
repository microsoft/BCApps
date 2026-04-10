namespace System.Tooling;

using System;

table 9175 "Designer Diagnostic"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Operation ID"; Guid)
        {
            Caption = 'Operation ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Diagnostics ID"; Integer)
        {
            Caption = 'Diagnostics ID';
            DataClassification = SystemMetadata;
        }
        field(3; Severity; Enum Severity)
        {
            Caption = 'Severity';
            DataClassification = SystemMetadata;
        }
        field(4; Message; Text[2048])
        {
            Caption = 'Message';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Operation ID", "Diagnostics ID")
        {
            Clustered = true;
        }
    }

    procedure ConvertNavDesignerDiagnosticSeverityToEnum(NavDesignerDiagnosticSeverity: DotNet NavDesignerDiagnosticSeverity): Enum Severity;
    begin
        case NavDesignerDiagnosticSeverity of
            NavDesignerDiagnosticSeverity.Error:
                exit(Severity::Error);
            NavDesignerDiagnosticSeverity.Warning:
                exit(Severity::Warning);
            NavDesignerDiagnosticSeverity.Info:
                exit(Severity::Information);
            NavDesignerDiagnosticSeverity.Hidden:
                exit(Severity::Hidden);
        end;
        exit(Severity::Information); // Unknown
    end;

}
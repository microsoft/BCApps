table 50000 "CWM Widget"
{
    Caption = 'Widget';
    DataClassification = CustomerContent;
    LookupPageId = "CWM Widget List";
    DrillDownPageId = "CWM Widget List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            begin
                if "No." = xRec."No." then
                    exit;
                WidgetSetup.Get();
                NoSeriesMgt.TestManual(WidgetSetup."Widget Nos.");
                "No. Series" := '';
            end;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Contact Email"; Text[80])
        {
            Caption = 'Contact Email';
            DataClassification = SystemMetadata;
            ExtendedDatatype = EMail;
        }
        field(4; "Linked Customer No."; Code[20])
        {
            Caption = 'Linked Customer No.';
            TableRelation = Customer."No.";
            ValidateTableRelation = false;
        }
        field(10; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
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
        WidgetSetup: Record "CWM Widget Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;

    trigger OnInsert()
    begin
        if "No." = '' then begin
            WidgetSetup.Get();
            WidgetSetup.TestField("Widget Nos.");
            NoSeriesMgt.InitSeries(WidgetSetup."Widget Nos.", xRec."No. Series", 0D, "No.", "No. Series");
        end;
    end;
}

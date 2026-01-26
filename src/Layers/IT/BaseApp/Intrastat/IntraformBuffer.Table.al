#pragma warning disable AA0247
#if not CLEANSCHEMA25 
table 12118 "Intra - form Buffer"
{
    Caption = 'Intra - form Buffer';
    ObsoleteState = Removed;
#pragma warning disable AS0072
    ObsoleteTag = '25.0';
#pragma warning restore AS0072
    ObsoleteReason = 'Intrastat related functionalities are moving to Intrastat extension.';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = SystemMetadata;
            TableRelation = "Intrastat Jnl. Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = SystemMetadata;
            TableRelation = "Intrastat Jnl. Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(3; "No."; Integer)
        {
            Caption = 'No.';
            DataClassification = SystemMetadata;
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Receipt,Shipment';
            OptionMembers = Receipt,Shipment;
        }
        field(5; Date; Date)
        {
            Caption = 'Date';
            DataClassification = SystemMetadata;
        }
        field(6; "Tariff No."; Code[20])
        {
            Caption = 'Tariff No.';
            DataClassification = SystemMetadata;
            TableRelation = "Tariff Number";
        }
        field(8; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            DataClassification = SystemMetadata;
        }
        field(9; "Transaction Type"; Code[10])
        {
            Caption = 'Transaction Type';
            DataClassification = SystemMetadata;
            TableRelation = "Transaction Type";
        }
        field(10; "Transport Method"; Code[10])
        {
            Caption = 'Transport Method';
            DataClassification = SystemMetadata;
        }
        field(14; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
        }
        field(18; "Statistical Value"; Decimal)
        {
            Caption = 'Statistical Value';
            DataClassification = SystemMetadata;
        }
        field(19; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(22; "Total Weight"; Decimal)
        {
            Caption = 'Total Weight';
            DataClassification = SystemMetadata;
        }
        field(23; "Supplementary Units"; Boolean)
        {
            Caption = 'Supplementary Units';
            DataClassification = SystemMetadata;
        }
        field(25; "Country/Region of Origin Code"; Code[10])
        {
            Caption = 'Country/Region of Origin Code';
            DataClassification = SystemMetadata;
        }
        field(27; "Area"; Code[10])
        {
            Caption = 'Area';
            DataClassification = SystemMetadata;
            TableRelation = Area;
        }
        field(28; "Transaction Specification"; Code[10])
        {
            Caption = 'Transaction Specification';
            DataClassification = SystemMetadata;
            TableRelation = "Country/Region";
        }
        field(12100; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
        }
        field(12101; "Source Currency Amount"; Decimal)
        {
            Caption = 'Source Currency Amount';
            DataClassification = SystemMetadata;
        }
        field(12102; "VAT Registration No."; Code[30])
        {
            Caption = 'VAT Registration No.';
            DataClassification = SystemMetadata;
        }
        field(12103; "Corrective entry"; Boolean)
        {
            Caption = 'Corrective entry';
            DataClassification = SystemMetadata;
        }
        field(12104; "Group Code"; Code[10])
        {
            Caption = 'Group Code';
            DataClassification = SystemMetadata;
        }
        field(12105; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = SystemMetadata;
        }
        field(12112; "Statistics Period"; Code[10])
        {
            Caption = 'Statistics Period';
            DataClassification = SystemMetadata;
        }
        field(12115; "Reference Period"; Code[10])
        {
            Caption = 'Reference Period';
            DataClassification = SystemMetadata;
            Numeric = true;
        }
        field(12125; "Service Tariff No."; Code[10])
        {
            Caption = 'Service Tariff No.';
            DataClassification = SystemMetadata;
            TableRelation = "Service Tariff Number";
        }
        field(12178; "Payment Method"; Code[10])
        {
            Caption = 'Payment Method';
            DataClassification = SystemMetadata;
            TableRelation = "Payment Method";
        }
        field(12179; "Custom Office No."; Code[10])
        {
            Caption = 'Custom Office No.';
            DataClassification = SystemMetadata;
        }
        field(12180; "Corrected Intrastat Report No."; Code[10])
        {
            Caption = 'Corrected Intrastat Report No.';
            DataClassification = SystemMetadata;
        }
        field(12183; "Progressive No."; Code[5])
        {
            Caption = 'Progressive No.';
            DataClassification = SystemMetadata;
        }
        field(12184; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
            DataClassification = SystemMetadata;
        }
        field(12185; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "VAT Registration No.", "Transaction Type", "Tariff No.", "Group Code", "Transport Method", "Transaction Specification", "Country/Region of Origin Code", "Area", "Corrective entry", "No.", "EU 3-Party Trade")
        {
            Clustered = true;
        }
        key(Key2; "Reference Period", "VAT Registration No.", "Tariff No.", "Transaction Type", "Corrective entry")
        {
        }
    }

    fieldgroups
    {
    }
}

 
#endif

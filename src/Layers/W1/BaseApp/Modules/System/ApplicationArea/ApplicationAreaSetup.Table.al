namespace System.Environment.Configuration;

using System.Environment;
using System.Reflection;
using System.Security.AccessControl;

table 9178 "Application Area Setup"
{
    Caption = 'Application Area Setup';
    DataPerCompany = false;
    ReplicateData = false;
    InherentEntitlements = rX;
    InherentPermissions = rX;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            TableRelation = Company;
        }
        field(2; "Profile ID"; Code[30])
        {
            Caption = 'Profile ID';
            TableRelation = "All Profile"."Profile ID";
        }
        field(3; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(100; Basic; Boolean)
        {
            Caption = 'Basic';
        }
        field(200; Suite; Boolean)
        {
            Caption = 'Suite';
        }
        field(300; "Relationship Mgmt"; Boolean)
        {
            Caption = 'Relationship Mgmt';
        }
        field(400; Jobs; Boolean)
        {
            Caption = 'Projects';
        }
        field(500; "Fixed Assets"; Boolean)
        {
            Caption = 'Fixed Assets';
        }
        field(600; Location; Boolean)
        {
            Caption = 'Location';
        }
        field(700; BasicHR; Boolean)
        {
            Caption = 'BasicHR';
        }
        field(800; Assembly; Boolean)
        {
            Caption = 'Assembly';
        }
        field(900; "Item Charges"; Boolean)
        {
            Caption = 'Item Charges';
        }
        field(1000; Advanced; Boolean)
        {
            Caption = 'Advanced';
        }
        field(1100; Warehouse; Boolean)
        {
            Caption = 'Warehouse';
        }
        field(1200; Service; Boolean)
        {
            Caption = 'Service';
        }
        field(1300; Manufacturing; Boolean)
        {
            Caption = 'Manufacturing';
        }
        field(1400; Planning; Boolean)
        {
            Caption = 'Planning';
        }
        field(1500; Dimensions; Boolean)
        {
            Caption = 'Dimensions';
        }
        field(1600; "Item Tracking"; Boolean)
        {
            Caption = 'Item Tracking';
        }
        field(1700; Intercompany; Boolean)
        {
            Caption = 'Intercompany';
        }
        field(1800; "Sales Return Order"; Boolean)
        {
            Caption = 'Sales Return Order';
        }
        field(1900; "Purch Return Order"; Boolean)
        {
            Caption = 'Purch Return Order';
        }
        field(2000; Prepayments; Boolean)
        {
            Caption = 'Prepayments';
        }
        field(2100; "Cost Accounting"; Boolean)
        {
            Caption = 'Cost Accounting';
        }
        field(2200; "Sales Budget"; Boolean)
        {
            Caption = 'Sales Budget';
        }
        field(2300; "Purchase Budget"; Boolean)
        {
            Caption = 'Purchase Budget';
        }
        field(2400; "Item Budget"; Boolean)
        {
            Caption = 'Item Budget';
        }
        field(2500; "Sales Analysis"; Boolean)
        {
            Caption = 'Sales Analysis';
        }
        field(2600; "Purchase Analysis"; Boolean)
        {
            Caption = 'Purchase Analysis';
        }
        field(2650; "Inventory Analysis"; Boolean)
        {
            Caption = 'Inventory Analysis';
        }
        field(2800; Reservation; Boolean)
        {
            Caption = 'Reservation';
        }
        field(2900; "Order Promising"; Boolean)
        {
            Caption = 'Order Promising';
        }
        field(3000; ADCS; Boolean)
        {
            Caption = 'ADCS';
        }
        field(3100; Comments; Boolean)
        {
            Caption = 'Comments';
            DataClassification = SystemMetadata;
        }
        field(3200; "Record Links"; Boolean)
        {
            Caption = 'Record Links';
        }
        field(3300; Notes; Boolean)
        {
            Caption = 'Notes';
        }
        field(3400; VAT; Boolean)
        {
            Caption = 'VAT';
        }
        field(3500; "Sales Tax"; Boolean)
        {
            Caption = 'Sales Tax';
        }
        field(3600; "Item References"; Boolean)
        {
            Caption = 'Item References';
        }
        field(5000; "Basic EU"; Boolean)
        {
            Caption = 'Basic EU';
        }
        field(5001; "Basic CA"; Boolean)
        {
            Caption = 'Basic CA';
        }
        field(5002; "Basic US"; Boolean)
        {
            Caption = 'Basic US';
        }
        field(5003; "Basic MX"; Boolean)
        {
            Caption = 'Basic MX';
        }
        field(5004; "Basic AU"; Boolean)
        {
            Caption = 'Basic AU';
        }
        field(5005; "Basic NZ"; Boolean)
        {
            Caption = 'Basic NZ';
        }
        field(5006; "Basic AT"; Boolean)
        {
            Caption = 'Basic AT';
        }
        field(5007; "Basic CH"; Boolean)
        {
            Caption = 'Basic CH';
        }
        field(5008; "Basic DE"; Boolean)
        {
            Caption = 'Basic DE';
        }
        field(5009; "Basic BE"; Boolean)
        {
            Caption = 'Basic BE';
        }
        field(5010; "Basic CZ"; Boolean)
        {
            Caption = 'Basic CZ';
        }
        field(5011; "Basic DK"; Boolean)
        {
            Caption = 'Basic DK';
        }
        field(5012; "Basic ES"; Boolean)
        {
            Caption = 'Basic ES';
        }
        field(5013; "Basic FI"; Boolean)
        {
            Caption = 'Basic FI';
        }
        field(5014; "Basic FR"; Boolean)
        {
            Caption = 'Basic FR';
        }
        field(5015; "Basic GB"; Boolean)
        {
            Caption = 'Basic GB';
        }
        field(5016; "Basic IS"; Boolean)
        {
            Caption = 'Basic IS';
        }
        field(5017; "Basic IT"; Boolean)
        {
            Caption = 'Basic IT';
        }
        field(5018; "Basic NL"; Boolean)
        {
            Caption = 'Basic NL';
        }
        field(5019; "Basic NO"; Boolean)
        {
            Caption = 'Basic NO';
        }
        field(5020; "Basic RU"; Boolean)
        {
            Caption = 'Basic RU';
        }
        field(5021; "Basic SE"; Boolean)
        {
            Caption = 'Basic SE';
        }
    }

    keys
    {
        key(Key1; "Company Name", "Profile ID", "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
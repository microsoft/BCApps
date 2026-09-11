namespace Microsoft.FabricExport;

using System.Fabric;
using System.Reflection;

table 9100 "Fabric Config Package Line"
{
    Caption = 'Fabric Config Package Line';
    Access = Internal;
    DataPerCompany = false;

    fields
    {
        field(1; "Package Code"; Code[20])
        {
            Caption = 'Package Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
            TableRelation = "Fabric Config Package"."Code";
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnValidate()
            var
                TableMetadata: Record "Table Metadata";
                AllObj: Record AllObjWithCaption;
            begin
                if "Table ID" = 0 then begin
                    "Table Name" := '';
                    "Per Company" := true;
                    exit;
                end;
                if AllObj.Get(AllObj."Object Type"::Table, "Table ID") then
                    "Table Name" := CopyStr(AllObj."Object Caption", 1, MaxStrLen("Table Name"));
                if TableMetadata.Get("Table ID") then
                    "Per Company" := TableMetadata.DataPerCompany
                else
                    "Per Company" := true;
            end;
        }
        field(3; "Table Name"; Text[80])
        {
            Caption = 'Table Name';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(4; "Per Company"; Boolean)
        {
            Caption = 'Per Company';
            DataClassification = SystemMetadata;
            Editable = false;
            InitValue = true;
        }
        field(5; "Fabric Schema Type"; Enum "Fabric Schema Type")
        {
            Caption = 'Fabric Schema Type';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Package Code", "Table ID")
        {
            Clustered = true;
        }
        key(TableID; "Table ID")
        {
        }
    }
}

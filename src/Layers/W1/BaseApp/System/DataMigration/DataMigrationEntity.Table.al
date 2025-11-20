namespace System.Integration;

using System.Reflection;

table 1801 "Data Migration Entity"
{
    Caption = 'Data Migration Entity';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            Editable = false;

            trigger OnValidate()
            var
                AllObjWithCaption: Record AllObjWithCaption;
            begin
                AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
                AllObjWithCaption.SetRange("Object ID", "Table ID");
                if AllObjWithCaption.FindFirst() then
                    "Table Name" := AllObjWithCaption."Object Caption";
            end;
        }
        field(2; "Table Name"; Text[250])
        {
            Caption = 'Table Name';
            Editable = false;
        }
        field(3; "No. of Records"; Integer)
        {
            Caption = 'No. of Records';
            Editable = false;
        }
        field(4; Selected; Boolean)
        {
            Caption = 'Selected';
        }
        field(5; Balance; Decimal)
        {
            Caption = 'Balance';
        }
        field(6; Post; Boolean)
        {
            Caption = 'Post';
        }
        field(7; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
    }

    keys
    {
        key(Key1; "Table ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure InsertRecord(TableID: Integer; NoOfPackageRecords: Integer)
    begin
        InsertRecordWithBalance(TableID, NoOfPackageRecords, 0);
    end;

    procedure InsertRecordWithBalance(TableID: Integer; NoOfPackageRecords: Integer; BalanceValue: Decimal)
    begin
        Init();
        Validate("Table ID", TableID);
        Validate("No. of Records", NoOfPackageRecords);
        Validate(Balance, BalanceValue);
        Validate(Selected, NoOfPackageRecords > 0);
        Validate("Posting Date", WorkDate());
        Insert();
    end;
}


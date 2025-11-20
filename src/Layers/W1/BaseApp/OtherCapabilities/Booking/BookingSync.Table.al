namespace Microsoft.Booking;

using Microsoft.Sales.Customer;
using System.Security.AccessControl;
using System.IO;
using System.Environment;

table 6702 "Booking Sync"
{
    Caption = 'Booking Sync';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Booking Mailbox Address"; Text[80])
        {
            Caption = 'Booking Mailbox Address';
        }
        field(3; "Booking Mailbox Name"; Text[250])
        {
            Caption = 'Booking Mailbox Name';
        }
        field(4; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(5; "Last Customer Sync"; DateTime)
        {
            Caption = 'Last Customer Sync';
            Editable = true;
        }
        field(6; "Last Service Sync"; DateTime)
        {
            Caption = 'Last Service Sync';
        }
        field(7; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(8; "Sync Customers"; Boolean)
        {
            Caption = 'Sync Customers';
        }
        field(9; "Customer Filter"; BLOB)
        {
            Caption = 'Customer Filter';
        }
        field(12; "Sync Services"; Boolean)
        {
            Caption = 'Sync Services';
        }
        field(13; "Item Filter"; BLOB)
        {
            Caption = 'Item Filter';
        }
        field(14; "Item Template Code"; Code[10])
        {
            Caption = 'Item Template Code';
            TableRelation = "Config. Template Header".Code where("Table ID" = filter(27));
        }
        field(15; "Customer Templ. Code"; Code[20])
        {
            Caption = 'Customer Template Code';
            TableRelation = "Customer Templ.";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
        key(Key2; "Booking Mailbox Address")
        {
        }
    }

    fieldgroups
    {
    }

    procedure GetCustomerFilter() FilterText: Text
    var
        ReadStream: InStream;
    begin
        CalcFields("Customer Filter");
        "Customer Filter".CreateInStream(ReadStream);
        ReadStream.ReadText(FilterText);
    end;

    procedure GetItemFilter() FilterText: Text
    var
        ReadStream: InStream;
    begin
        CalcFields("Item Filter");
        "Item Filter".CreateInStream(ReadStream);
        ReadStream.ReadText(FilterText);
    end;

    procedure SaveCustomerFilter(FilterText: Text)
    var
        WriteStream: OutStream;
    begin
        Clear("Customer Filter");
        "Customer Filter".CreateOutStream(WriteStream);
        WriteStream.WriteText(FilterText);
        Clear("Last Customer Sync");
        Modify();
    end;

    procedure SaveItemFilter(FilterText: Text)
    var
        WriteStream: OutStream;
    begin
        Clear("Item Filter");
        "Item Filter".CreateOutStream(WriteStream);
        WriteStream.WriteText(FilterText);
        Clear("Last Service Sync");
        Modify();
    end;

    procedure IsSetup(): Boolean
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if EnvironmentInfo.IsSaaS() then
            exit(Get() and ("Last Service Sync" <> 0DT));
    end;
}

namespace Microsoft.Booking;

using Microsoft.Integration.Graph;
using System;
using System.Text;
using System.Utilities;

table 6707 "Booking Item"
{
    Caption = 'Booking Item';
    ExternalName = 'appointments';
    TableType = MicrosoftGraph;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Text[250])
        {
            Caption = 'Id';
            ExternalName = 'id';
            ExternalType = 'Edm.String';
        }
        field(2; "Start Date"; BLOB)
        {
            Caption = 'Start Date';
            ExternalName = 'start';
            ExternalType = 'microsoft.bookings.api.dateTimeTimeZone';
            SubType = Json;
        }
        field(3; "End Date"; BLOB)
        {
            Caption = 'End Date';
            ExternalName = 'end';
            ExternalType = 'microsoft.bookings.api.dateTimeTimeZone';
            SubType = Json;
        }
        field(4; Duration; Duration)
        {
            Caption = 'Duration';
            ExternalName = 'duration';
            ExternalType = 'Edm.Duration';
        }
        field(5; Notes; Text[250])
        {
            Caption = 'Notes';
            ExternalName = 'serviceNotes';
            ExternalType = 'Edm.String';
        }
        field(7; "Price Type"; Option)
        {
            Caption = 'Price Type';
            ExternalName = 'priceType';
            ExternalType = 'microsoft.bookings.api.bookingPriceType';
            OptionCaption = 'Undefined,Fixed Price,Starting At,Hourly,Free,Price Varies,Call Us,Not Set';
            OptionMembers = undefined,fixedPrice,startingAt,hourly,free,priceVaries,callUs,notSet;
        }
        field(8; Price; Decimal)
        {
            Caption = 'Price';
            ExternalName = 'price';
            ExternalType = 'Edm.Double';
        }
        field(10; "Service ID"; Text[50])
        {
            Caption = 'Service ID';
            ExternalName = 'serviceId';
            ExternalType = 'Edm.String';
        }
        field(11; "Service Name"; Text[50])
        {
            Caption = 'Service Name';
            ExternalName = 'serviceName';
            ExternalType = 'Edm.String';
        }
        field(13; "Customer ID"; Text[50])
        {
            Caption = 'Customer ID';
            ExternalName = 'customerId';
            ExternalType = 'Edm.String';
        }
        field(14; "Customer Email"; Text[80])
        {
            Caption = 'Customer Email';
            ExternalName = 'customerEmailAddress';
            ExternalType = 'Edm.String';
        }
        field(15; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
            ExternalName = 'customerName';
            ExternalType = 'Edm.String';
        }
        field(18; "Invoice Link"; Text[250])
        {
            Caption = 'Invoice Link';
            ExternalName = 'invoiceUrl';
            ExternalType = 'Edm.String';
        }
        field(19; "Invoice No."; Text[250])
        {
            Caption = 'Invoice No.';
            ExternalName = 'invoiceId';
            ExternalType = 'Edm.String';
        }
        field(21; "Invoice Status"; Option)
        {
            Caption = 'Invoice Status';
            ExternalName = 'invoiceStatus';
            ExternalType = 'microsoft.bookings.api.bookingInvoiceStatus';
            OptionCaption = 'Draft,Reviewing,Open,Canceled,Paid,Corrective';
            OptionMembers = draft,reviewing,open,canceled,paid,corrective;
        }
        field(22; "Invoice Amount"; Decimal)
        {
            Caption = 'Invoice Amount';
            ExternalName = 'invoiceAmount';
            ExternalType = 'Edm.Double';
        }
        field(23; "Invoice Date"; BLOB)
        {
            Caption = 'Invoice Date';
            ExternalName = 'invoiceDate';
            ExternalType = 'microsoft.bookings.api.dateTimeTimeZone';
            SubType = Json;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        NullJSONTxt: Label 'null', Locked = true;

    procedure GetEndDate(): DateTime
    begin
        exit(GetDate(FieldNo("End Date")));
    end;

    procedure SetEndDate(NewEndDate: DateTime)
    begin
        SetDate(FieldNo("End Date"), NewEndDate);
    end;

    procedure GetInvoiceDate(): DateTime
    begin
        exit(GetDate(FieldNo("Invoice Date")));
    end;

    procedure SetInvoiceDate(NewInvoiceDate: DateTime)
    begin
        SetDate(FieldNo("Invoice Date"), NewInvoiceDate);
    end;

    procedure GetStartDate(): DateTime
    begin
        exit(GetDate(FieldNo("Start Date")));
    end;

    procedure SetStartDate(NewStartDate: DateTime)
    begin
        SetDate(FieldNo("Start Date"), NewStartDate);
    end;

    local procedure GetBlobString(FieldNo: Integer) Content: Text
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        TempBlob.FromRecord(Rec, FieldNo);
        TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
        InStream.Read(Content);
    end;

    local procedure SetBlobString(FieldNo: Integer; String: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        OutStream: OutStream;
    begin
        RecordRef.GetTable(Rec);
        TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.Write(String);
        TempBlob.ToRecordRef(RecordRef, FieldNo);
        RecordRef.SetTable(Rec);
    end;

    local procedure GetDate(FieldNo: Integer) ParsedDateTime: DateTime
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
        DateBlobString: Text;
        DateTimeJsonValue: Text;
    begin
        DateBlobString := GetBlobString(FieldNo);
        if NullJSONTxt <> DateBlobString then begin
            JSONManagement.InitializeObject(DateBlobString);
            JSONManagement.GetJSONObject(JsonObject);
            JSONManagement.GetStringPropertyValueFromJObjectByName(JsonObject, 'dateTime', DateTimeJsonValue);
            Evaluate(ParsedDateTime, DateTimeJsonValue);
        end;
    end;

    local procedure SetDate(FieldNo: Integer; NewDate: DateTime)
    var
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        JsonText: Text;
    begin
        GraphMgtComplexTypes.GetBookingsDateJSON(NewDate, JsonText);
        SetBlobString(FieldNo, JsonText);
    end;

    procedure CheckActionAllowed() Allowed: Boolean
    begin
        Allowed := ("Service Name" <> '') and not IsEmpty();
    end;
}


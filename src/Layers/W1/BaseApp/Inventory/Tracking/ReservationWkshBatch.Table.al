// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using System.Automation;
using System.Utilities;

table 345 "Reservation Wksh. Batch"
{
    Caption = 'Reservation Wksh. Batch';
    DataCaptionFields = Name, Description;
    LookupPageID = "Reservation Wksh. Batches";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[10])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the reservation worksheet you are creating.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a brief description of the reservation worksheet name you are creating.';
        }
        field(11; "Demand Type"; Enum "Reservation Demand Type")
        {
            Caption = 'Demand Type';
            ToolTip = 'Specifies the type of demand that the reservation worksheet will be used for.';
        }
        field(12; "Start Date Formula"; DateFormula)
        {
            Caption = 'Start Date Formula';
            ToolTip = 'Specifies the formula that is used to calculate the start date for the reservation worksheet.';

            trigger OnValidate()
            begin
                CheckDates();
            end;
        }
        field(13; "End Date Formula"; DateFormula)
        {
            Caption = 'End Date Formula';
            ToolTip = 'Specifies the formula that is used to calculate the end date for the reservation worksheet.';

            trigger OnValidate()
            begin
                CheckDates();
            end;
        }
        field(21; "Item Filter"; Blob)
        {
            Caption = 'Item Filter';
        }
        field(22; "Variant Filter"; Blob)
        {
            Caption = 'Variant Filter';
        }
        field(23; "Location Filter"; Blob)
        {
            Caption = 'Location Filter';
        }
        field(40; "No. of Lines"; Integer)
        {
            CalcFormula = count("Reservation Wksh. Line" where("Journal Batch Name" = field(Name)));
            Caption = 'No. of Lines';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the number of lines in this worksheet batch.';
        }

    }

    keys
    {
        key(Key1; Name)
        {
            Clustered = true;
        }
    }

    var
        DateSequenceErr: Label 'Start Date Formula must be less than or equal to End Date Formula';

    trigger OnDelete()
    var
        AllocationPolicy: Record "Allocation Policy";
    begin
        EmptyBatch();

        AllocationPolicy.SetRange("Journal Batch Name", Name);
        AllocationPolicy.DeleteAll(true);
    end;

    procedure EmptyBatch()
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
        ReservationWorksheetLog: Record "Reservation Worksheet Log";
    begin
        ReservationWkshLine.SetRange("Journal Batch Name", Name);
        ReservationWkshLine.DeleteAll(true);

        ReservationWorksheetLog.SetRange("Journal Batch Name", Name);
        ReservationWorksheetLog.DeleteAll();
    end;

    local procedure CheckDates()
    begin
        if (Format("Start Date Formula") <> '') and (Format("End Date Formula") <> '') then
            if CalcDate("Start Date Formula", WorkDate()) > CalcDate("End Date Formula", WorkDate()) then
                Error(DateSequenceErr);
    end;

    procedure GetItemFilterBlobAsText(): Text
    var
        FiltersInStream: InStream;
        ItemFilterText: Text;
    begin
        CalcFields("Item Filter");
        "Item Filter".CreateInStream(FiltersInStream);
        FiltersInStream.ReadText(ItemFilterText);
        exit(ItemFilterText);
    end;

    procedure SetTextFilterToItemFilterBlob(TextFilter: Text)
    var
        FiltersOutStream: OutStream;
    begin
        Clear("Item Filter");
        "Item Filter".CreateOutStream(FiltersOutStream);
        FiltersOutStream.WriteText(TextFilter);
    end;

    procedure GetItemFilterBlobAsViewFilters(): Text
    begin
        exit(GetItemFilterBlobAsRecordRef().GetView());
    end;

    procedure GetItemFilterAsDisplayText(): Text
    begin
        exit(GetItemFilterBlobAsRecordRef().GetFilters);
    end;

    local procedure GetItemFilterBlobAsRecordRef(): RecordRef
    var
        Item: Record Item;
        TempBlob: Codeunit "Temp Blob";
        RequestPageParametersHelper: Codeunit "Request Page Parameters Helper";
        FiltersRecordRef: RecordRef;
    begin
        FiltersRecordRef.GetTable(Item);
        CalcFields("Item Filter");
        TempBlob.FromRecord(Rec, FieldNo("Item Filter"));

        RequestPageParametersHelper.ConvertParametersToFilters(FiltersRecordRef, TempBlob);
        exit(FiltersRecordRef);
    end;

    procedure SetTextFilterToVariantFilterBlob(TextFilter: Text)
    var
        FiltersOutStream: OutStream;
    begin
        Clear("Variant Filter");
        "Variant Filter".CreateOutStream(FiltersOutStream);
        FiltersOutStream.WriteText(TextFilter);
    end;

    procedure GetVariantFilterBlobAsText(): Text
    var
        FiltersInStream: InStream;
        VariantFilterText: Text;
    begin
        CalcFields("Variant Filter");
        "Variant Filter".CreateInStream(FiltersInStream);
        FiltersInStream.ReadText(VariantFilterText);
        exit(VariantFilterText);
    end;

    procedure SetTextFilterToLocationFilterBlob(TextFilter: Text)
    var
        FiltersOutStream: OutStream;
    begin
        Clear("Location Filter");
        "Location Filter".CreateOutStream(FiltersOutStream);
        FiltersOutStream.WriteText(TextFilter);
    end;

    procedure GetLocationFilterBlobAsText(): Text
    var
        FiltersInStream: InStream;
        LocationFilterText: Text;
    begin
        CalcFields("Location Filter");
        "Location Filter".CreateInStream(FiltersInStream);
        FiltersInStream.ReadText(LocationFilterText);
        exit(LocationFilterText);
    end;
}

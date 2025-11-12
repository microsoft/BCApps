// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using System.Reflection;
using System.Utilities;

report 6520 "Item Tracing Specification"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/ItemTracingSpecification.rdlc';
    Caption = 'Item Tracing Specification';
    AllowScheduling = false;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(FormatToday; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(HeaderText1; HeaderText[1])
            {
            }
            column(HeaderText2; HeaderText[2])
            {
            }
            column(HeaderText3; HeaderText[3])
            {
            }
            column(HeaderText4; HeaderText[4])
            {
            }
            column(HeaderText5; HeaderText[5])
            {
            }
            column(HeaderText6; HeaderText[6])
            {
            }
            column(HeaderText7; HeaderText[7])
            {
            }
            column(HeaderText8; HeaderText[8])
            {
            }
            column(GlobVarX; x)
            {
            }
            column(TransactionDescription; TransactionDescription)
            {
            }
            column(BodyText1; BodyText[1])
            {
            }
            column(BodyText2; BodyText[2])
            {
            }
            column(BodyText3; BodyText[3])
            {
            }
            column(BodyText4; BodyText[4])
            {
            }
            column(BodyText5; BodyText[5])
            {
            }
            column(BodyText6; BodyText[6])
            {
            }
            column(BodyText8; BodyText[8])
            {
            }
            column(BodyText7; BodyText[7])
            {
            }
            column(TempTrackEntrySourceType; TempTrackEntry."Source Type")
            {
            }
            column(TempTrackEntrySourceNo; TempTrackEntry."Source No.")
            {
            }
            column(TempTrackEntrySourceName; TempTrackEntry."Source Name")
            {
            }
            column(SecIntBody6ShowOutput; (PrintCustomer and (TempTrackEntry."Source Type" = TempTrackEntry."Source Type"::Customer)) or (PrintVendor and (TempTrackEntry."Source Type" = TempTrackEntry."Source Type"::Vendor)))
            {
            }
            column(ItemTracingSpecificationCaption; ItemTracingSpecificationCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if TempTrackEntry.Next() = 0 then
                    CurrReport.Skip();

                TransactionDescription := PadStr('', TempTrackEntry.Level, '*') + Format(TempTrackEntry.Description);
                if not Item.Get(TempTrackEntry."Item No.") then
                    Clear(Item);

                Clear(RecRef);
                RecRef.Open(DATABASE::"Item Tracing Buffer", true);
                RecRef.GetTable(TempTrackEntry);

                x := 0;
                Clear(BodyText);
                for i := 1 to ArrayLen(HeaderText) do
                    if FldNo[i] <> 0 then begin
                        FldRef := RecRef.Field(FldNo[i]);
                        x += 1;
                        if not HeaderTextCreated then
                            HeaderText[x] := FldRef.Caption;
                        if (i < 9) or
                           ((TempTrackEntry."Source Type" = TempTrackEntry."Source Type"::Customer) and PrintCustomer) or
                           ((TempTrackEntry."Source Type" = TempTrackEntry."Source Type"::Vendor) and PrintVendor)
                        then
                            BodyText[x] := Format(FldRef);
                    end;

                HeaderTextCreated := true;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, NoOfRecords);
                Clear(TempTrackEntry);

                HeaderTextCreated := false;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Print Contact Information")
                    {
                        Caption = 'Print Contact Information';
                        field(Customer; PrintCustomer)
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Customer';
                            ToolTip = 'Specifies the name of the customer.';
                        }
                        field(Vendor; PrintVendor)
                        {
                            ApplicationArea = ItemTracking;
                            Caption = 'Vendor';
                            ToolTip = 'Specifies whether to print the vendors'' contact information in the report.';
                        }
                    }
                    group("Column Selection")
                    {
                        Caption = 'Column Selection';
                        field("FldNo[1]"; FldNo[1])
                        {
                            ApplicationArea = ItemTracking;
                            BlankZero = true;
                            Caption = 'No. 1';
                            ToolTip = 'Specifies the first column selection field that you would like to see in the report.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                LookupField(1);
                            end;

                            trigger OnValidate()
                            begin
                                GetFieldValue(1, FldNo[1]);
                            end;
                        }
                        field("FldNo[2]"; FldNo[2])
                        {
                            ApplicationArea = ItemTracking;
                            BlankZero = true;
                            Caption = 'No. 2';
                            ToolTip = 'Specifies the second column selection field that you would like to see in the report.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                LookupField(2);
                            end;

                            trigger OnValidate()
                            begin
                                GetFieldValue(2, FldNo[2]);
                            end;
                        }
                        field("FldNo[3]"; FldNo[3])
                        {
                            ApplicationArea = ItemTracking;
                            BlankZero = true;
                            Caption = 'No. 3';
                            ToolTip = 'Specifies the third column selection field that you would like to see in the report.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                LookupField(3);
                            end;

                            trigger OnValidate()
                            begin
                                GetFieldValue(3, FldNo[3]);
                            end;
                        }
                        field("FldNo[4]"; FldNo[4])
                        {
                            ApplicationArea = ItemTracking;
                            BlankZero = true;
                            Caption = 'No. 4';
                            ToolTip = 'Specifies the fourth column selection field that you would like to see in the report.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                LookupField(4);
                            end;

                            trigger OnValidate()
                            begin
                                GetFieldValue(4, FldNo[4]);
                            end;
                        }
                        field("FldNo[5]"; FldNo[5])
                        {
                            ApplicationArea = ItemTracking;
                            BlankZero = true;
                            Caption = 'No. 5';
                            ToolTip = 'Specifies the fifth column selection field that you would like to see in the report.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                LookupField(5);
                            end;

                            trigger OnValidate()
                            begin
                                GetFieldValue(5, FldNo[5]);
                            end;
                        }
                        field("FldNo[6]"; FldNo[6])
                        {
                            ApplicationArea = ItemTracking;
                            BlankZero = true;
                            Caption = 'No. 6';
                            ToolTip = 'Specifies the sixth column selection field that you would like to see in the report.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                LookupField(6);
                            end;

                            trigger OnValidate()
                            begin
                                GetFieldValue(6, FldNo[6]);
                            end;
                        }
                        field("FldNo[7]"; FldNo[7])
                        {
                            ApplicationArea = ItemTracking;
                            BlankZero = true;
                            Caption = 'No. 7';
                            ToolTip = 'Specifies the seventh column selection field that you would like to see in the report.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                LookupField(7);
                            end;

                            trigger OnValidate()
                            begin
                                GetFieldValue(7, FldNo[7]);
                            end;
                        }
                        field("FldNo[8]"; FldNo[8])
                        {
                            ApplicationArea = ItemTracking;
                            BlankZero = true;
                            Caption = 'No. 8';
                            ToolTip = 'Specifies the eighth column selection field that you would like to see in the report.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                LookupField(8);
                            end;

                            trigger OnValidate()
                            begin
                                GetFieldValue(8, FldNo[8]);
                            end;
                        }
                    }
                    field("FieldCaption[1]"; FieldCaption[1])
                    {
                        ApplicationArea = ItemTracking;
                        Editable = false;
                        ShowCaption = false;
                    }
                    field("FieldCaption[2]"; FieldCaption[2])
                    {
                        ApplicationArea = ItemTracking;
                        Editable = false;
                        ShowCaption = false;
                    }
                    field("FieldCaption[3]"; FieldCaption[3])
                    {
                        ApplicationArea = ItemTracking;
                        Editable = false;
                        ShowCaption = false;
                    }
                    field("FieldCaption[4]"; FieldCaption[4])
                    {
                        ApplicationArea = ItemTracking;
                        Editable = false;
                        ShowCaption = false;
                    }
                    field("FieldCaption[5]"; FieldCaption[5])
                    {
                        ApplicationArea = ItemTracking;
                        Editable = false;
                        ShowCaption = false;
                    }
                    field("FieldCaption[6]"; FieldCaption[6])
                    {
                        ApplicationArea = ItemTracking;
                        Editable = false;
                        ShowCaption = false;
                    }
                    field("FieldCaption[7]"; FieldCaption[7])
                    {
                        ApplicationArea = ItemTracking;
                        Editable = false;
                        ShowCaption = false;
                    }
                    field("FieldCaption[8]"; FieldCaption[8])
                    {
                        ApplicationArea = ItemTracking;
                        Editable = false;
                        ShowCaption = false;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
        DescriptionCaption = 'Description';
        EmptyStringCaption = '___________________________________________________________________________________________________________________________________________________________________________';
    }

    trigger OnPreReport()
    begin
        if TempTrackEntry.Find() then
            NoOfRecords := TempTrackEntry.Count
        else
            NoOfRecords := 0;
    end;

    var
        Item: Record Item;
        TypeHelper: Codeunit "Type Helper";
        RecRef: RecordRef;
        FldRef: FieldRef;
        TransactionDescription: Text[100];
        PrintCustomer: Boolean;
        PrintVendor: Boolean;
        HeaderTextCreated: Boolean;
        i: Integer;
        x: Integer;
        ItemTracingSpecificationCaptionLbl: Label 'Item Tracing Specification';
        PageCaptionLbl: Label 'Page';

    protected var
        TempTrackEntry: Record "Item Tracing Buffer" temporary;
        NoOfRecords: Integer;
        HeaderText: array[11] of Text;
        BodyText: array[11] of Text;
        FieldCaption: array[11] of Text;
        FldNo: array[11] of Integer;

    procedure TransferEntries(var ItemTrackingEntry: Record "Item Tracing Buffer")
    begin
        ItemTrackingEntry.Reset();
        if ItemTrackingEntry.Find('-') then
            repeat
                TempTrackEntry := ItemTrackingEntry;
                TempTrackEntry.Insert();
            until ItemTrackingEntry.Next() = 0;
    end;

    local procedure LookupField(FieldNumber: Integer)
    var
        "Field": Record "Field";
        FieldSelection: Codeunit "Field Selection";
    begin
        Field.SetRange(TableNo, DATABASE::"Item Tracing Buffer");
        Field.SetFilter(Type,
          '%1|%2|%3|%4|%5|%6|%7|%8',
          Field.Type::Text,
          Field.Type::Date,
          Field.Type::Decimal,
          Field.Type::Boolean,
          Field.Type::Code,
          Field.Type::Option,
          Field.Type::Integer,
          Field.Type::BigInteger);
        if FieldSelection.Open(Field) then
            if FldNo[FieldNumber] <> Field."No." then begin
                FldNo[FieldNumber] := Field."No.";
                FieldCaption[FieldNumber] := Field."Field Caption";
            end;
    end;

    local procedure GetFieldValue(ArrayNo: Integer; FieldNumber: Integer)
    var
        "Field": Record "Field";
    begin
        FieldCaption[ArrayNo] := '';
        if FieldNumber <> 0 then
            if TypeHelper.GetField(DATABASE::"Item Tracing Buffer", FieldNumber, Field) then
                FieldCaption[ArrayNo] := Field."Field Caption";
    end;
}


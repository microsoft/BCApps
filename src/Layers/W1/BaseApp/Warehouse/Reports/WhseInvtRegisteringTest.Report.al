// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Reports;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;
using Microsoft.Warehouse.Journal;
using System.Security.User;
using System.Utilities;

report 7302 "Whse. Invt.-Registering - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Warehouse/Reports/WhseInvtRegisteringTest.rdlc';
    Caption = 'Whse. Invt.-Registering - Test';
    WordMergeDataItem = "Warehouse Journal Batch";

    dataset
    {
        dataitem("Warehouse Journal Batch"; "Warehouse Journal Batch")
        {
            DataItemTableView = sorting("Journal Template Name", Name, "Location Code");
            RequestFilterFields = "Journal Template Name", Name;
            column(Warehouse_Journal_Batch_Journal_Template_Name; "Journal Template Name")
            {
            }
            column(Warehouse_Journal_Batch_Name; Name)
            {
            }
            column(Warehouse_Journal_Batch_Location_Code; "Location Code")
            {
            }
            dataitem("Warehouse Journal Line"; "Warehouse Journal Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Location Code", "Line No.");
                RequestFilterFields = "Registering Date";
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(Warehouse_Journal_Line__Journal_Template_Name_; "Journal Template Name")
                {
                }
                column(Warehouse_Journal_Line__Journal_Batch_Name_; "Journal Batch Name")
                {
                }
                column(Warehouse_Journal_Line__TABLECAPTION__________WhseJnlLineFilter; TableCaption + ': ' + WhseJnlLineFilter)
                {
                }
                column(WhseJnlLineFilter; WhseJnlLineFilter)
                {
                }
                column(Warehouse_Journal_Line__Registering_Date_; Format("Registering Date"))
                {
                }
                column(Warehouse_Journal_Line__Item_No__; "Item No.")
                {
                }
                column(Warehouse_Journal_Line_Description; Description)
                {
                }
                column(Warehouse_Journal_Line_Quantity; Quantity)
                {
                }
                column(Warehouse_Journal_Line__Zone_Code_; "Zone Code")
                {
                }
                column(Warehouse_Journal_Line__Bin_Code_; "Bin Code")
                {
                }
                column(Warehouse_Journal_Line__Whse__Document_No__; "Whse. Document No.")
                {
                }
                column(Warehouse_Journal_Line_Cubage; Cubage)
                {
                }
                column(Warehouse_Journal_Line_Weight; Weight)
                {
                }
                column(Warehouse_Journal_Line__Variant_Code_; "Variant Code")
                {
                }
                column(Warehouse_Journal_Line__Unit_of_Measure_Code_; "Unit of Measure Code")
                {
                }
                column(Warehouse_Journal_Line__Lot_No__; "Lot No.")
                {
                }
                column(Warehouse_Journal_Line__Serial_No__; "Serial No.")
                {
                }
                column(Warehouse_Journal_Line_Line_No_; "Line No.")
                {
                }
                column(Inventory_Registering___TestCaption; Inventory_Registering___TestCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Warehouse_Journal_Line__Journal_Template_Name_Caption; FieldCaption("Journal Template Name"))
                {
                }
                column(Warehouse_Journal_Line__Journal_Batch_Name_Caption; FieldCaption("Journal Batch Name"))
                {
                }
                column(Warehouse_Journal_Line__Registering_Date_Caption; Warehouse_Journal_Line__Registering_Date_CaptionLbl)
                {
                }
                column(Warehouse_Journal_Line__Item_No__Caption; FieldCaption("Item No."))
                {
                }
                column(Warehouse_Journal_Line_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(QuantityCaption; QuantityCaptionLbl)
                {
                }
                column(Warehouse_Journal_Line__Zone_Code_Caption; FieldCaption("Zone Code"))
                {
                }
                column(Warehouse_Journal_Line__Bin_Code_Caption; FieldCaption("Bin Code"))
                {
                }
                column(Warehouse_Journal_Line__Whse__Document_No__Caption; FieldCaption("Whse. Document No."))
                {
                }
                column(CubageCaption; CubageCaptionLbl)
                {
                }
                column(WeightCaption; WeightCaptionLbl)
                {
                }
                column(Warehouse_Journal_Line__Variant_Code_Caption; FieldCaption("Variant Code"))
                {
                }
                column(Warehouse_Journal_Line__Unit_of_Measure_Code_Caption; FieldCaption("Unit of Measure Code"))
                {
                }
                column(Warehouse_Journal_Line__Lot_No__Caption; FieldCaption("Lot No."))
                {
                }
                column(Warehouse_Journal_Line__Serial_No__Caption; FieldCaption("Serial No."))
                {
                }
                dataitem(ErrorLoop; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(ErrorText_Number_; ErrorText[Number])
                    {
                    }
                    column(ErrorText_Number_Caption; ErrorText_Number_CaptionLbl)
                    {
                    }

                    trigger OnPostDataItem()
                    begin
                        ErrorCounter := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, ErrorCounter);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    WhseJnlLine2: Record "Warehouse Journal Line";
                    WhseJnlLine3: Record "Warehouse Journal Line";
                    ItemVariant: Record "Item Variant";
                    UserSetupManagement: Codeunit "User Setup Management";
                    InvtPeriodEndDate: Date;
                    ItemItemVariantLbl: Label '%1 %2', Comment = '%1 - Item No., %2 - Variant Code';
                begin
                    OnBeforeWarehouseJournalLineOnAfterGetRecord("Warehouse Journal Line", ErrorCounter, ErrorText);

                    if ("Item No." = '') and (Quantity = 0) then
                        exit;

                    if "Item No." = '' then
                        AddError(StrSubstNo(Text001, FieldCaption("Item No.")))
                    else begin
                        if not Item.Get("Item No.") then
                            AddError(StrSubstNo(Text002, Item.TableCaption(), "Item No."))
                        else
                            if Item.Blocked then
                                AddError(StrSubstNo(MustBeForErr, Item.FieldCaption(Blocked), false, Item.TableCaption(), "Item No."));

                        if "Warehouse Journal Line"."Variant Code" <> '' then begin
                            ItemVariant.SetLoadFields(Blocked);
                            if ItemVariant.Get("Warehouse Journal Line"."Item No.", "Warehouse Journal Line"."Variant Code") then begin
                                if ItemVariant.Blocked then
                                    AddError(StrSubstNo(MustBeForErr, ItemVariant.FieldCaption(Blocked), false, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, "Warehouse Journal Line"."Item No.", "Warehouse Journal Line"."Variant Code")));
                            end else
                                AddError(StrSubstNo(Text002, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, "Warehouse Journal Line"."Item No.", "Warehouse Journal Line"."Variant Code")));
                        end;
                    end;

                    if "Registering Date" = 0D then
                        AddError(StrSubstNo(Text001, FieldCaption("Registering Date")))
                    else begin
                        if "Registering Date" <> NormalDate("Registering Date") then
                            AddError(StrSubstNo(Text005, FieldCaption("Registering Date")));

                        if "Warehouse Journal Batch"."No. Series" <> '' then
                            if NoSeries."Date Order" and ("Registering Date" < LastPostingDate) then
                                AddError(Text006);
                        LastPostingDate := "Registering Date";

                        if not UserSetupManagement.IsPostingDateValid("Registering Date") then
                            AddError(StrSubstNo(Text007, Format("Registering Date")))
                        else begin
                            InvtPeriodEndDate := "Registering Date";
                            if not InvtPeriod.IsValidDate(InvtPeriodEndDate) then
                                AddError(
                                  StrSubstNo(
                                    Text007, Format("Registering Date")))
                        end;
                    end;

                    if not "Phys. Inventory" then begin
                        if "Qty. (Calculated)" <> 0 then
                            AddError(
                              StrSubstNo(
                                Text011,
                                FieldCaption("Qty. (Calculated)"), FieldCaption("Phys. Inventory"), "Phys. Inventory"));
                        if "Qty. (Phys. Inventory)" <> 0 then
                            AddError(
                              StrSubstNo(
                                Text011,
                                FieldCaption("Qty. (Phys. Inventory)"), FieldCaption("Phys. Inventory"), "Phys. Inventory"));
                    end else begin
                        if "Entry Type" = "Entry Type"::Movement then begin
                            WhseJnlLine2."Entry Type" := WhseJnlLine2."Entry Type"::"Negative Adjmt.";
                            WhseJnlLine3."Entry Type" := WhseJnlLine3."Entry Type"::"Positive Adjmt.";
                            AddError(
                              StrSubstNo(
                                Text014,
                                FieldCaption("Entry Type"),
                                WhseJnlLine2."Entry Type",
                                WhseJnlLine3."Entry Type",
                                FieldCaption("Phys. Inventory"),
                                true));
                        end;
                        if "Qty. (Phys. Inventory)" - "Qty. (Calculated)" <> Quantity then
                            AddError(
                              StrSubstNo(
                                Text015,
                                FieldCaption(Quantity),
                                FieldCaption("Qty. (Phys. Inventory)"),
                                FieldCaption("Qty. (Calculated)"),
                                FieldCaption("Entry Type"),
                                "Entry Type",
                                FieldCaption("Phys. Inventory"),
                                true));
                    end;

                    if "Warehouse Journal Batch"."No. Series" <> '' then begin
                        if LastDocNo <> '' then
                            if ("Whse. Document No." <> LastDocNo) and
                               ("Whse. Document No." <> IncStr(LastDocNo))
                            then
                                AddError(Text017);
                        LastDocNo := "Whse. Document No.";
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    WhseJnlTemplate.Get("Warehouse Journal Batch"."Journal Template Name");
                    if "Warehouse Journal Batch"."No. Series" <> '' then
                        NoSeries.Get("Warehouse Journal Batch"."No. Series");
                    LastPostingDate := 0D;
                    LastDocNo := '';
                end;
            }
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        WhseJnlLineFilter := "Warehouse Journal Line".GetFilters();
        GLSetup.Get();
        InvtSetup.Get();
    end;

    var
        InvtSetup: Record "Inventory Setup";
        GLSetup: Record "General Ledger Setup";
        Item: Record Item;
        WhseJnlTemplate: Record "Warehouse Journal Template";
        NoSeries: Record "No. Series";
        InvtPeriod: Record "Inventory Period";
        WhseJnlLineFilter: Text;
        ErrorCounter: Integer;
        ErrorText: array[30] of Text[250];
        LastPostingDate: Date;
        LastDocNo: Code[20];

        Inventory_Registering___TestCaptionLbl: Label 'Inventory Registering - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Warehouse_Journal_Line__Registering_Date_CaptionLbl: Label 'Registering Date';
        QuantityCaptionLbl: Label 'Quantity';
        CubageCaptionLbl: Label 'Cubage';
        WeightCaptionLbl: Label 'Weight';
        ErrorText_Number_CaptionLbl: Label 'Warning!';

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 must be specified.';
        Text002: Label '%1 %2 does not exist.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        MustBeForErr: Label '%1 must be %2 for %3 %4.';
#pragma warning restore AA0470
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label '%1 must not be a closing date.';
#pragma warning restore AA0470
        Text006: Label 'The lines are not listed according to Registering Date because they were not entered in that order.';
#pragma warning disable AA0470
        Text007: Label '%1 is not within your allowed range of registering dates.';
        Text011: Label '%1 must be 0 when %2 is %3.';
        Text014: Label '%1 must be %2 or %3 when %4 is %5.';
        Text015: Label '%1 must equal %2 - %3 when %4 is %5 and %6 is %7.';
#pragma warning restore AA0470
        Text017: Label 'There is a gap in the number series.';
#pragma warning restore AA0074

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWarehouseJournalLineOnAfterGetRecord(WarehouseJournalLine: Record "Warehouse Journal Line"; var ErrorCounter: Integer; var ErrorText: array[30] of Text[250])
    begin
    end;
}


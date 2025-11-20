// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using System.Security.User;
using System.Utilities;

report 702 "Inventory Posting - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/InventoryPostingTest.rdlc';
    Caption = 'Inventory Posting - Test';

    dataset
    {
        dataitem("Item Journal Batch"; "Item Journal Batch")
        {
            DataItemTableView = sorting("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            column(Item_Journal_Batch_Journal_Template_Name; "Journal Template Name")
            {
            }
            column(Item_Journal_Batch_Name; Name)
            {
            }
            dataitem("Item Journal Line"; "Item Journal Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
                RequestFilterFields = "Posting Date";
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(Item_Journal_Line__Journal_Template_Name_; "Journal Template Name")
                {
                }
                column(Item_Journal_Line__Journal_Batch_Name_; "Journal Batch Name")
                {
                }
                column(Item_Journal_Line__TABLECAPTION__________ItemJnlLineFilter; TableCaption + ': ' + ItemJnlLineFilter)
                {
                }
                column(ItemJnlLineFilter; ItemJnlLineFilter)
                {
                }
                column(ItemLineEntryType; ItemLineEntryType)
                {
                }
                column(JnlTemplateType; JnlTemplateType)
                {
                }
                column(Item_Journal_Line__Item_Journal_Line___Line_No__; "Line No.")
                {
                }
                column(TotalCostAm1; TotalCostAm1)
                {
                }
                column(TotalCostAm2; TotalCostAm2)
                {
                }
                column(TotalCostAm3; TotalCostAm3)
                {
                }
                column(TotalCostAm4; TotalCostAm4)
                {
                }
                column(TotalCostAm5; TotalCostAm5)
                {
                }
                column(TotalAm1; TotalAm1)
                {
                }
                column(TotalAm2; TotalAm2)
                {
                }
                column(TotalAm3; TotalAm3)
                {
                }
                column(TotalAm4; TotalAm4)
                {
                }
                column(TotalAm5; TotalAm5)
                {
                }
                column(Item_Journal_Line__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Item_Journal_Line__Entry_Type_; "Entry Type")
                {
                }
                column(Item_Journal_Line__Item_No__; "Item No.")
                {
                }
                column(Item_Journal_Line_Description; Description)
                {
                }
                column(Item_Journal_Line_Quantity; Quantity)
                {
                }
                column(Item_Journal_Line__Invoiced_Quantity_; "Invoiced Quantity")
                {
                }
                column(Item_Journal_Line__Unit_Amount_; "Unit Amount")
                {
                }
                column(Item_Journal_Line_Amount; Amount)
                {
                }
                column(CostAmount; CostAmount)
                {
                    AutoFormatType = 1;
                }
                column(Item_Journal_Line__Unit_Cost_; "Unit Cost")
                {
                }
                column(Item_Journal_Line_Quantity_Control68; Quantity)
                {
                }
                column(Item_Journal_Line_Description_Control69; Description)
                {
                }
                column(Item_Journal_Line__Source_No__; "Source No.")
                {
                }
                column(Item_Journal_Line__Item_No___Control71; "Item No.")
                {
                }
                column(Item_Journal_Line__Prod__Order_No__; "Order No.")
                {
                }
                column(Item_Journal_Line__Document_No__; "Document No.")
                {
                }
                column(Item_Journal_Line__Output_Quantity_; OutputQuantity)
                {
                }
                column(Item_Journal_Line__Run_Time_; RunTime)
                {
                }
                column(Item_Journal_Line__Setup_Time_; SetupTime)
                {
                }
                column(Item_Journal_Line_Description_Control59; Description)
                {
                }
                column(Item_Journal_Line__No__; "No.")
                {
                }
                column(Item_Journal_Line_Type; Type)
                {
                }
                column(Item_Journal_Line__Operation_No__; OperationNo)
                {
                }
                column(Item_Journal_Line__Unit_Cost__Control99; "Unit Cost")
                {
                }
                column(Item_Journal_Line__Stop_Code_; StopCode)
                {
                }
                column(Item_Journal_Line__Scrap_Code_; ScrapCode)
                {
                }
                column(Item_Journal_Line__Stop_Time_; StopTime)
                {
                }
                column(NoOfEntries_5_; NoOfEntries[5])
                {
                }
                column(NoOfEntries_4_; NoOfEntries[4])
                {
                }
                column(NoOfEntries_3_; NoOfEntries[3])
                {
                }
                column(NoOfEntries_2_; NoOfEntries[2])
                {
                }
                column(NoOfEntries_1_; NoOfEntries[1])
                {
                }
                column(EntryTypeDescription_1_; EntryTypeDescription[1])
                {
                }
                column(TotalCostAmounts_1_; TotalCostAmounts[1])
                {
                    AutoFormatType = 1;
                }
                column(EntryTypeDescription_2_; EntryTypeDescription[2])
                {
                }
                column(TotalCostAmounts_2_; TotalCostAmounts[2])
                {
                    AutoFormatType = 1;
                }
                column(EntryTypeDescription_3_; EntryTypeDescription[3])
                {
                }
                column(TotalCostAmounts_3_; TotalCostAmounts[3])
                {
                    AutoFormatType = 1;
                }
                column(EntryTypeDescription_4_; EntryTypeDescription[4])
                {
                }
                column(TotalCostAmounts_4_; TotalCostAmounts[4])
                {
                    AutoFormatType = 1;
                }
                column(EntryTypeDescription_5_; EntryTypeDescription[5])
                {
                }
                column(TotalCostAmounts_5_; TotalCostAmounts[5])
                {
                    AutoFormatType = 1;
                }
                column(TotalAmount; TotalAmount)
                {
                    AutoFormatType = 1;
                }
                column(TotalCostAmount; TotalCostAmount)
                {
                    AutoFormatType = 1;
                }
                column(Inventory_Posting___TestCaption; Inventory_Posting___TestCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Item_Journal_Line__Journal_Template_Name_Caption; FieldCaption("Journal Template Name"))
                {
                }
                column(Item_Journal_Line__Journal_Batch_Name_Caption; FieldCaption("Journal Batch Name"))
                {
                }
                column(Item_Journal_Line__Posting_Date_Caption; Item_Journal_Line__Posting_Date_CaptionLbl)
                {
                }
                column(Item_Journal_Line__Entry_Type_Caption; Item_Journal_Line__Entry_Type_CaptionLbl)
                {
                }
                column(Item_Journal_Line__Item_No__Caption; FieldCaption("Item No."))
                {
                }
                column(Item_Journal_Line_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(Item_Journal_Line_QuantityCaption; FieldCaption(Quantity))
                {
                }
                column(Item_Journal_Line__Invoiced_Quantity_Caption; FieldCaption("Invoiced Quantity"))
                {
                }
                column(Item_Journal_Line__Unit_Amount_Caption; FieldCaption("Unit Amount"))
                {
                }
                column(Item_Journal_Line_AmountCaption; FieldCaption(Amount))
                {
                }
                column(CostAmountCaption; CostAmountCaptionLbl)
                {
                }
                column(Item_Journal_Line__Unit_Cost_Caption; FieldCaption("Unit Cost"))
                {
                }
                column(Item_Journal_Line_Quantity_Control68Caption; FieldCaption(Quantity))
                {
                }
                column(Item_Journal_Line_Description_Control69Caption; FieldCaption(Description))
                {
                }
                column(Item_Journal_Line__Source_No__Caption; FieldCaption("Source No."))
                {
                }
                column(Item_Journal_Line__Item_No___Control71Caption; FieldCaption("Item No."))
                {
                }
                column(Item_Journal_Line__Prod__Order_No__Caption; FieldCaption("Order No."))
                {
                }
                column(Item_Journal_Line__Document_No__Caption; FieldCaption("Document No."))
                {
                }
                column(Item_Journal_Line__Operation_No__Caption; OperationNoCaption)
                {
                }
                column(Item_Journal_Line_TypeCaption; FieldCaption(Type))
                {
                }
                column(Item_Journal_Line__No__Caption; FieldCaption("No."))
                {
                }
                column(Item_Journal_Line_Description_Control59Caption; FieldCaption(Description))
                {
                }
                column(Item_Journal_Line__Setup_Time_Caption; SetupTimeCaption)
                {
                }
                column(Item_Journal_Line__Run_Time_Caption; RunTimeCaption)
                {
                }
                column(Item_Journal_Line__Output_Quantity_Caption; OutputQuantityCaption)
                {
                }
                column(Item_Journal_Line__Unit_Cost__Control99Caption; FieldCaption("Unit Cost"))
                {
                }
                column(Item_Journal_Line__Stop_Time_Caption; StopTimeCaption)
                {
                }
                column(Item_Journal_Line__Scrap_Code_Caption; ScrapCodeCaption)
                {
                }
                column(Item_Journal_Line__Stop_Code_Caption; StopCodeCaption)
                {
                }
                column(TotalAmountCaption; TotalAmountCaptionLbl)
                {
                }
                dataitem(DimensionLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(DimensionLoop_Number; Number)
                    {
                    }
                    column(DimensionsCaption; DimensionsCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then begin
                            if not DimSetEntry.FindSet() then
                                CurrReport.Break();
                        end else
                            if not Continue then
                                CurrReport.Break();

                        Clear(DimText);
                        Continue := false;
                        repeat
                            OldDimText := DimText;
                            if DimText = '' then
                                DimText := StrSubstNo('%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
                            else
                                DimText :=
                                  StrSubstNo(
                                    '%1; %2 - %3', DimText, DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
                            if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                DimText := OldDimText;
                                Continue := true;
                                exit;
                            end;
                        until DimSetEntry.Next() = 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not ShowDim then
                            CurrReport.Break();
                        DimSetEntry.SetRange("Dimension Set ID", "Item Journal Line"."Dimension Set ID");
                    end;
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
                    ItemVariant: Record "Item Variant";
                    ItemJnlLine2: Record "Item Journal Line";
                    ItemJnlLine3: Record "Item Journal Line";
                    ItemJnlLine4: Record "Item Journal Line";
                    UserSetupManagement: Codeunit "User Setup Management";
                    InvtPeriodEndDate: Date;
                    QtyToPostBase: Decimal;
                    TempErrorText: Text[250];
                    ItemItemVariantLbl: Label '%1 %2', Comment = '%1 - Item No., %2 - Variant Code';
                begin
                    OnBeforeItemJournalLineOnAfterGetRecord("Item Journal Line", ErrorCounter, ErrorText);

                    NoOfEntries["Entry Type".AsInteger() + 1] := 1;

                    CostAmount := "Unit Cost" * Quantity;
                    TotalCostAmounts["Entry Type".AsInteger() + 1] := CostAmount;

                    if "Entry Type" in
                       ["Entry Type"::Purchase,
                        "Entry Type"::"Positive Adjmt.",
                        "Entry Type"::Output]
                    then begin
                        TotalAmount := TotalAmount + Amount;
                        TotalCostAmount := TotalCostAmount + CostAmount;
                    end else begin
                        TotalAmount := TotalAmount - Amount;
                        TotalCostAmount := TotalCostAmount - CostAmount;
                    end;

                    if ("Item No." = '') and (Quantity = 0) then
                        exit;

                    QtyError := false;

                    MakeRecurringTexts("Item Journal Line");

                    if EmptyLine() then begin
                        if not IsValueEntryForDeletedItem() then
                            AddError(StrSubstNo(Text001, FieldCaption("Item No.")))
                    end else begin
                        if not Item.Get("Item No.") then
                            AddError(StrSubstNo(Text002, Item.TableCaption(), "Item No."))
                        else
                            if Item.Blocked then
                                AddError(StrSubstNo(Text003, Item.FieldCaption(Blocked), false, Item.TableCaption(), "Item No."));

                        if "Item Journal Line"."Variant Code" <> '' then begin
                            ItemVariant.SetLoadFields(Blocked);
                            if not ItemVariant.Get("Item Journal Line"."Item No.", "Item Journal Line"."Variant Code") then
                                AddError(StrSubstNo(Text002, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, "Item Journal Line"."Item No.", "Item Journal Line"."Variant Code")))
                            else
                                if ItemVariant.Blocked then
                                    AddError(StrSubstNo(Text003, ItemVariant.FieldCaption(Blocked), false, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, "Item Journal Line"."Item No.", "Item Journal Line"."Variant Code")));
                        end;
                    end;

                    CheckRecurringLine("Item Journal Line");

                    if "Posting Date" = 0D then
                        AddError(StrSubstNo(Text001, FieldCaption("Posting Date")))
                    else begin
                        if "Posting Date" <> NormalDate("Posting Date") then
                            AddError(StrSubstNo(Text005, FieldCaption("Posting Date")));

                        if "Item Journal Batch"."No. Series" <> '' then
                            if NoSeries."Date Order" and ("Posting Date" < LastPostingDate) then
                                AddError(Text006);
                        LastPostingDate := "Posting Date";

                        if not UserSetupManagement.TestAllowedPostingDate("Posting Date", TempErrorText) then
                            AddError(TempErrorText);

                        InvtPeriodEndDate := "Posting Date";
                        if not InvtPeriod.IsValidDate(InvtPeriodEndDate) then
                            AddError(
                              StrSubstNo(
                                Text007, Format("Posting Date")))
                    end;

                    if "Document Date" <> 0D then
                        if "Document Date" <> NormalDate("Document Date") then
                            AddError(StrSubstNo(Text005, FieldCaption("Document Date")));

                    if "Gen. Prod. Posting Group" = '' then
                        AddError(StrSubstNo(Text001, FieldCaption("Gen. Prod. Posting Group")))
                    else
                        if not GenPostingSetup.Get("Gen. Bus. Posting Group", "Gen. Prod. Posting Group") then
                            AddError(
                              StrSubstNo(
                                Text008, GenPostingSetup.TableCaption(),
                                "Gen. Bus. Posting Group", "Gen. Prod. Posting Group"));

                    if InvtSetup."Location Mandatory" then begin
                        if "Location Code" = '' then
                            AddError(StrSubstNo(Text001, FieldCaption("Location Code")));
                        if "Entry Type" = "Entry Type"::Transfer then
                            if "New Location Code" = '' then
                                AddError(StrSubstNo(Text001, FieldCaption("New Location Code")));
                    end;

                    if "Entry Type" in ["Entry Type"::"Positive Adjmt.", "Entry Type"::"Negative Adjmt."] then
                        if "Discount Amount" <> 0 then
                            AddError(StrSubstNo(Text009, FieldCaption("Discount Amount")));

                    if "Entry Type" = "Entry Type"::Transfer then begin
                        if Amount <> 0 then
                            AddError(
                              StrSubstNo(
                                Text011,
                                FieldCaption(Amount), FieldCaption("Entry Type"), Format("Entry Type")));
                        if "Discount Amount" <> 0 then
                            AddError(
                              StrSubstNo(
                                Text011,
                                FieldCaption("Discount Amount"), FieldCaption("Entry Type"), Format("Entry Type")));
                        if Quantity < 0 then
                            AddError(
                              StrSubstNo(
                                Text012,
                                FieldCaption(Quantity), FieldCaption("Entry Type"), Format("Entry Type")));
                        if Quantity <> "Invoiced Quantity" then
                            AddError(
                              StrSubstNo(
                                Text013,
                                FieldCaption("Invoiced Quantity"), FieldCaption(Quantity),
                                FieldCaption("Entry Type"), Format("Entry Type")));
                    end;

                    if not "Phys. Inventory" then begin
                        if "Qty. (Calculated)" <> 0 then
                            AddError(
                              StrSubstNo(
                                Text011,
                                FieldCaption("Qty. (Calculated)"), FieldCaption("Phys. Inventory"), Format("Phys. Inventory")));
                        if "Qty. (Phys. Inventory)" <> 0 then
                            AddError(
                              StrSubstNo(
                                Text011,
                                FieldCaption("Qty. (Phys. Inventory)"), FieldCaption("Phys. Inventory"), Format("Phys. Inventory")));
                    end else begin
                        if not ("Entry Type" in ["Entry Type"::"Positive Adjmt.", "Entry Type"::"Negative Adjmt."]) then begin
                            ItemJnlLine2."Entry Type" := ItemJnlLine2."Entry Type"::"Positive Adjmt.";
                            ItemJnlLine3."Entry Type" := ItemJnlLine3."Entry Type"::"Negative Adjmt.";
                            AddError(
                              StrSubstNo(
                                Text014,
                                FieldCaption("Entry Type"),
                                Format(ItemJnlLine2."Entry Type"),
                                Format(ItemJnlLine3."Entry Type"),
                                FieldCaption("Phys. Inventory"),
                                true));
                        end;
                        if ("Entry Type" = "Entry Type"::"Positive Adjmt.") and
                           ("Qty. (Phys. Inventory)" - "Qty. (Calculated)" <> Quantity)
                        then
                            AddError(
                              StrSubstNo(
                                Text015,
                                FieldCaption(Quantity),
                                FieldCaption("Qty. (Phys. Inventory)"),
                                FieldCaption("Qty. (Calculated)"),
                                FieldCaption("Entry Type"),
                                Format("Entry Type"),
                                FieldCaption("Phys. Inventory"),
                                true));
                        if ("Entry Type" = "Entry Type"::"Negative Adjmt.") and
                           ("Qty. (Calculated)" - "Qty. (Phys. Inventory)" <> Quantity)
                        then
                            AddError(
                              StrSubstNo(
                                Text015,
                                FieldCaption(Quantity),
                                FieldCaption("Qty. (Calculated)"),
                                FieldCaption("Qty. (Phys. Inventory)"),
                                FieldCaption("Entry Type"),
                                Format("Entry Type"),
                                FieldCaption("Phys. Inventory"),
                                true));
                    end;

                    OnAfterGetRecordOnCheckManufacturing("Item Journal Line", QtyError);

                    if (Quantity = 0) and ("Invoiced Quantity" <> 0) then begin
                        if "Item Shpt. Entry No." = 0 then
                            AddError(StrSubstNo(Text001, FieldCaption("Item Shpt. Entry No.")));
                    end else begin
                        if Quantity <> "Invoiced Quantity" then
                            if ("Invoiced Quantity" <> 0) and not QtyError then begin
                                QtyError := true;
                                AddError(StrSubstNo(Text009, FieldCaption("Invoiced Quantity")));
                            end;
                        if "Item Shpt. Entry No." <> 0 then
                            AddError(StrSubstNo(Text016, FieldCaption("Item Shpt. Entry No.")));
                    end;

                    if "Item Journal Batch"."No. Series" <> '' then begin
                        if LastDocNo <> '' then
                            if ("Document No." <> LastDocNo) and ("Document No." <> IncStr(LastDocNo)) then
                                AddError(Text017);
                        LastDocNo := "Document No.";
                    end;

                    DimSetEntry.SetRange("Dimension Set ID", "Dimension Set ID");
                    if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                        AddError(DimMgt.GetDimCombErr());

                    OnAfterCheckDimension("Item Journal Line", ItemJnlTemplate, QtyError);

                    TableID[1] := DATABASE::Item;
                    No[1] := "Item No.";
                    TableID[2] := DATABASE::"Salesperson/Purchaser";
                    No[2] := "Salespers./Purch. Code";
                    CheckDimValuePosting("Item Journal Line");

                    if (ItemJnlTemplate.Type in
                        [ItemJnlTemplate.GetConsumptionTemplateType(), ItemJnlTemplate.Type::Transfer]) or
                       ((ItemJnlTemplate.Type = ItemJnlTemplate.GetProdOrderTemplateType()) and
                        ("Entry Type" = "Entry Type"::Consumption))
                    then begin
                        ItemJnlLine4.Reset();
                        ItemJnlLine4.SetRange("Journal Template Name", "Journal Template Name");
                        ItemJnlLine4.SetRange("Journal Batch Name", "Journal Batch Name");
                        ItemJnlLine4.SetRange("Item No.", "Item No.");
                        ItemJnlLine4.SetRange("Location Code", "Location Code");

                        if ItemJnlLine4.Find('-') then begin
                            QtyToPostBase := 0;
                            repeat
                                QtyToPostBase -= ItemJnlLine4.Signed(ItemJnlLine4."Quantity (Base)")
                            until ItemJnlLine4.Next() = 0;

                            Item.Get("Item No.");
                            if "Location Code" <> '' then
                                Item.SetRange("Location Filter", "Location Code")
                            else
                                Item.SetFilter("Location Filter", '%1', '');
                            Item.CalcFields(Inventory);

                            if Item.Inventory - QtyToPostBase < 0 then
                                if "Location Code" <> '' then
                                    AddError(
                                      StrSubstNo(
                                        Text020,
                                        Item.TableCaption(),
                                        Item."No.",
                                        Location.TableCaption(),
                                        "Location Code"))
                                else
                                    AddError(
                                      StrSubstNo(
                                        Text021,
                                        Item.TableCaption(),
                                        Item."No."));
                        end;
                    end;
                    this.GetLocation("Location Code");
                    if Location."Bin Mandatory" and ("Bin Code" = '') and
                       not Location."Directed Put-away and Pick"
                    then
                        AddError(
                          StrSubstNo(
                            Text001,
                            FieldCaption("Bin Code")));

                    if "Entry Type" = "Entry Type"::Transfer then begin
                        this.GetLocation("New Location Code");
                        if Location."Bin Mandatory" and ("New Bin Code" = '') and
                           not Location."Directed Put-away and Pick"
                        then
                            AddError(
                              StrSubstNo(
                                Text001,
                                FieldCaption("New Bin Code")));
                    end;

                    JnlTemplateType := ItemJnlTemplate.Type.AsInteger();
                    ItemLineEntryType := "Entry Type".AsInteger();

                    case "Entry Type".AsInteger() + 1 of
                        1:
                            begin
                                TotalAm1 := TotalAm1 + Amount;
                                TotalCostAm1 := TotalCostAm1 + CostAmount;
                            end;
                        2:
                            begin
                                TotalAm2 := TotalAm2 + Amount;
                                TotalCostAm2 := TotalCostAm2 + CostAmount;
                            end;
                        3:
                            begin
                                TotalAm3 := TotalAm3 + Amount;
                                TotalCostAm3 := TotalCostAm3 + CostAmount;
                            end;
                        4:
                            begin
                                TotalAm4 := TotalAm4 + Amount;
                                TotalCostAm4 := TotalCostAm4 + CostAmount;
                            end;
                        5:
                            begin
                                TotalAm5 := TotalAm5 + Amount;
                                TotalCostAm5 := TotalCostAm5 + CostAmount;
                            end;
                    end;

                    OnAfterGetRecordOnSetmanufacturingFields(
                        "Item Journal Line",
                        OperationNo, OperationNoCaption, OutputQuantity, OutputQuantityCaption, ScrapCode, ScrapCodeCaption, StopCode, StopCodeCaption,
                        RunTime, RunTimeCaption, SetupTime, SetupTimeCaption, StopTime, StopTimeCaption);

                    OnAfterCheckItemJnLLine("Item Journal Line", Item, ErrorCounter, ErrorText);
                end;

                trigger OnPreDataItem()
                begin
                    ItemJnlTemplate.Get("Item Journal Batch"."Journal Template Name");
                    if ItemJnlTemplate.Recurring then begin
                        if GetFilter("Posting Date") <> '' then
                            AddError(StrSubstNo(Text000, FieldCaption("Posting Date")));
                        SetRange("Posting Date", 0D, WorkDate());
                        if GetFilter("Expiration Date") <> '' then
                            AddError(
                              StrSubstNo(
                                Text000,
                                FieldCaption("Expiration Date")));
                        SetFilter("Expiration Date", '%1 | %2..', 0D, WorkDate());
                    end;
                    Clear(NoOfEntries);
                    Clear(TotalCostAmounts);
                    if "Item Journal Batch"."No. Series" <> '' then
                        NoSeries.Get("Item Journal Batch"."No. Series");
                    LastPostingDate := 0D;
                    LastDocNo := '';
                end;
            }

            trigger OnPreDataItem()
            begin
                if "Item Journal Line".GetFilter("Journal Template Name") <> '' then
                    SetFilter("Journal Template Name", "Item Journal Line".GetFilter("Journal Template Name"));
                if "Item Journal Line".GetFilter("Journal Batch Name") <> '' then
                    SetFilter(Name, "Item Journal Line".GetFilter("Journal Batch Name"));

                for i := 1 to ArrayLen(EntryTypeDescription) do begin
                    "Item Journal Line"."Entry Type" := "Item Ledger Entry Type".FromInteger(i - 1);
                    EntryTypeDescription[i] := Format("Item Journal Line"."Entry Type");
                end;
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
                    field(ShowDim; ShowDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies if you want dimensions information for the journal lines to be included in the report.';
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
    }

    trigger OnPreReport()
    begin
        ItemJnlLineFilter := "Item Journal Line".GetFilters();
        GLSetup.Get();
        InvtSetup.Get();
    end;

    var
        InvtSetup: Record "Inventory Setup";
        GLSetup: Record "General Ledger Setup";
        AccountingPeriod: Record "Accounting Period";
        Item: Record Item;
        ItemJnlTemplate: Record "Item Journal Template";
        GenPostingSetup: Record "General Posting Setup";
        NoSeries: Record "No. Series";
        DimSetEntry: Record "Dimension Set Entry";
        Location: Record Location;
        InvtPeriod: Record "Inventory Period";
        DimMgt: Codeunit DimensionManagement;
        ItemJnlLineFilter: Text;
        EntryTypeDescription: array[7] of Text[30];
        CostAmount: Decimal;
        NoOfEntries: array[7] of Decimal;
        TotalCostAmounts: array[7] of Decimal;
        TotalAmount: Decimal;
        TotalCostAmount: Decimal;
        QtyError: Boolean;
        ErrorCounter: Integer;
        ErrorText: array[30] of Text[250];
        i: Integer;
        LastPostingDate: Date;
        LastDocNo: Code[20];
        TableID: array[10] of Integer;
        JnlTemplateType: Integer;
        ItemLineEntryType: Integer;
        No: array[10] of Code[20];
        DimText: Text[120];
        OldDimText: Text[75];
        ShowDim: Boolean;
        Continue: Boolean;

        OperationNo: Code[20];
        OperationNoCaption: Text;
        ScrapCode: Code[10];
        ScrapCodeCaption: Text;
        StopCode: Code[10];
        StopCodeCaption: Text;
        OutputQuantity: Decimal;
        OutputQuantityCaption: Text;
        RunTime: Decimal;
        RunTimeCaption: Text;
        SetupTime: Decimal;
        SetupTimeCaption: Text;
        StopTime: Decimal;
        StopTimeCaption: Text;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 cannot be filtered when you post recurring journals.';
        Text001: Label '%1 must be specified.';
        Text002: Label '%1 %2 does not exist.';
        Text003: Label '%1 must be %2 for %3 %4.';
        Text005: Label '%1 must not be a closing date.';
#pragma warning restore AA0470
        Text006: Label 'The lines are not listed according to Posting Date because they were not entered in that order.';
#pragma warning disable AA0470
        Text007: Label '%1 is not within your allowed range of posting dates.';
        Text008: Label '%1 %2 %3 does not exist.';
        Text009: Label '%1 must be 0.';
        Text011: Label '%1 must be 0 when %2 is %3.';
        Text012: Label '%1 must not be negative when %2 is %3.';
        Text013: Label '%1 must have the same value as %2 when %3 is %4.';
        Text014: Label '%1 must be %2 or %3 when %4 is %5.';
        Text015: Label '%1 must equal %2 - %3 when %4 is %5 and %6 is %7.';
        Text016: Label '%1 cannot be specified.';
#pragma warning restore AA0470
        Text017: Label 'There is a gap in the number series.';
#pragma warning disable AA0470
        Text020: Label '%1 %2 is not on inventory for %3 %4.';
        Text021: Label '%1 %2 is not on inventory.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TotalAm1: Decimal;
        TotalAm2: Decimal;
        TotalAm3: Decimal;
        TotalAm4: Decimal;
        TotalAm5: Decimal;
        TotalCostAm1: Decimal;
        TotalCostAm2: Decimal;
        TotalCostAm3: Decimal;
        TotalCostAm4: Decimal;
        TotalCostAm5: Decimal;
        Inventory_Posting___TestCaptionLbl: Label 'Inventory Posting - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Item_Journal_Line__Posting_Date_CaptionLbl: Label 'Posting Date';
        Item_Journal_Line__Entry_Type_CaptionLbl: Label 'Entry Type';
        CostAmountCaptionLbl: Label 'Cost Amount';
        TotalAmountCaptionLbl: Label 'Total';
        DimensionsCaptionLbl: Label 'Dimensions';
        ErrorText_Number_CaptionLbl: Label 'Warning!';

    local procedure CheckRecurringLine(ItemJnlLine2: Record "Item Journal Line")
    begin
        if ItemJnlTemplate.Recurring then begin
            if ItemJnlLine2."Recurring Method" = 0 then
                AddError(StrSubstNo(Text001, ItemJnlLine2.FieldCaption("Recurring Method")));
            if Format(ItemJnlLine2."Recurring Frequency") = '' then
                AddError(StrSubstNo(Text001, ItemJnlLine2.FieldCaption("Recurring Frequency")));
            if ItemJnlLine2."Recurring Method" = ItemJnlLine2."Recurring Method"::Variable then
                if ItemJnlLine2.Quantity = 0 then
                    AddError(StrSubstNo(Text001, ItemJnlLine2.FieldCaption(Quantity)));
        end else begin
            if ItemJnlLine2."Recurring Method" <> 0 then
                AddError(StrSubstNo(Text016, ItemJnlLine2.FieldCaption("Recurring Method")));
            if Format(ItemJnlLine2."Recurring Frequency") <> '' then
                AddError(StrSubstNo(Text016, ItemJnlLine2.FieldCaption("Recurring Frequency")));
        end;
    end;

    local procedure MakeRecurringTexts(var ItemJnlLine2: Record "Item Journal Line")
    begin
        if (ItemJnlLine2."Posting Date" <> 0D) and (ItemJnlLine2."Item No." <> '') and (ItemJnlLine2."Recurring Method" <> 0) then
            AccountingPeriod.MakeRecurringTexts(ItemJnlLine2."Posting Date", ItemJnlLine2."Document No.", ItemJnlLine2.Description);
    end;

    local procedure CheckDimValuePosting(var ItemJournalLine: Record "Item Journal Line")
    begin
        OnBeforeCheckDimValuePosting(TableID, No, ItemJournalLine);
        if not DimMgt.CheckDimValuePosting(TableID, No, ItemJournalLine."Dimension Set ID") then
            AddError(DimMgt.GetDimValuePostingErr());
    end;

    procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckDimension(ItemJournalLine: Record "Item Journal Line"; ItemJnlTemplate: Record "Item Journal Template"; QtyError: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemJnLLine(ItemJournalLine: Record "Item Journal Line"; Item: Record Item; var ErrorCounter: Integer; var ErrorText: array[30] of Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDimValuePosting(var TableID: array[10] of Integer; var No: array[10] of Code[20]; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemJournalLineOnAfterGetRecord(ItemJournalLine: Record "Item Journal Line"; var ErrorCounter: Integer; var ErrorText: array[30] of Text[250])
    begin
    end;

    [InternalEvent(true)]
    local procedure OnAfterGetRecordOnCheckManufacturing(var ItemJournalLine: Record "Item Journal Line"; var QtyError: Boolean)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnAfterGetRecordOnSetManufacturingFields(
        var ItemJournalLine: Record "Item Journal Line";
        var OperationNo: Code[20]; var OperationNoCaption: Text; var OutputQuantity: Decimal; var OutputQuantityCaption: Text;
        var ScrapCode: Code[10]; var ScrapCodeCaption: Text; var StopCode: Code[10]; var StopCodeCaption: Text;
        var RunTime: Decimal; var RunTimeCaption: Text; var SetupTime: Decimal; var SetupTimeCaption: Text; var StopTime: Decimal; var StopTimeCaption: Text)
    begin
    end;
}


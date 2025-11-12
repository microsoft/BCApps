// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Reports;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Item;
using Microsoft.Utilities;
using System.Security.User;
using System.Utilities;

report 5877 "Phys. Invt. Order - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Counting/Reports/PhysInvtOrderTest.rdlc';
    Caption = 'Phys. Invt. Order - Test';
    WordMergeDataItem = "Phys. Invt. Order Header";

    dataset
    {
        dataitem("Phys. Invt. Order Header"; "Phys. Invt. Order Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            column(Phys__Inventory_Order_Header_No_; "No.")
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(USERID; UserId)
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(Phys__Inventory_Order_Header___Posting_Date_; Format("Phys. Invt. Order Header"."Posting Date"))
                {
                }
                column(Phys__Inventory_Order_Header___No__; "Phys. Invt. Order Header"."No.")
                {
                }
                column(Phys__Inventory_Order_Header__Status; "Phys. Invt. Order Header".Status)
                {
                }
                column(Phys__Inventory_Order_Header___Person_Responsible_; "Phys. Invt. Order Header"."Person Responsible")
                {
                }
                column(Phys__Inventory_Order_Header__Description; "Phys. Invt. Order Header".Description)
                {
                }
                column(ShowDim; ShowDim)
                {
                }
                column(PageCounter_Number; Number)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Phys__Inventory_Order_Header___TestCaption; Phys__Inventory_Order_Header___TestCaptionLbl)
                {
                }
                column(Phys__Inventory_Order_Header___Posting_Date_Caption; Phys__Inventory_Order_Header___Posting_Date_CaptionLbl)
                {
                }
                column(Phys__Inventory_Order_Header___No__Caption; "Phys. Invt. Order Header".FieldCaption("No."))
                {
                }
                column(Phys__Inventory_Order_Header__StatusCaption; "Phys. Invt. Order Header".FieldCaption(Status))
                {
                }
                column(Phys__Inventory_Order_Header___Person_Responsible_Caption; "Phys. Invt. Order Header".FieldCaption("Person Responsible"))
                {
                }
                column(Phys__Inventory_Order_Header__DescriptionCaption; "Phys. Invt. Order Header".FieldCaption(Description))
                {
                }
                dataitem(HeaderErrorCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(ErrorText_Number_; ErrorText[Number])
                    {
                    }
                    column(HeaderErrorCounter_Number; Number)
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
                dataitem("Phys. Invt. Order Line"; "Phys. Invt. Order Line")
                {
                    DataItemLink = "Document No." = field("No.");
                    DataItemLinkReference = "Phys. Invt. Order Header";
                    DataItemTableView = sorting("Document No.", "Line No.");
                    column(Phys__Inventory_Order_Line__Item_No__; "Item No.")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Location_Code_; "Location Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Bin_Code_; "Bin Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line_Description; Description)
                    {
                    }
                    column(Phys__Inventory_Order_Line__Base_Unit_of_Measure_Code_; "Base Unit of Measure Code")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Qty__Expected__Base__; "Qty. Expected (Base)")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Qty__Recorded__Base__; "Qty. Recorded (Base)")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Quantity__Base__; "Quantity (Base)")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Entry_Type_; "Entry Type")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Recorded_without_Order_; Format("Recorded Without Order"))
                    {
                    }
                    column(Phys__Inventory_Order_Line__Unit_Amount_; "Unit Amount")
                    {
                    }
                    column(Phys__Inventory_Order_Line_Document_No_; "Document No.")
                    {
                    }
                    column(Phys__Inventory_Order_Line_Line_No_; "Line No.")
                    {
                    }
                    column(Phys__Inventory_Order_Line__Item_No__Caption; FieldCaption("Item No."))
                    {
                    }
                    column(Phys__Inventory_Order_Line__Location_Code_Caption; FieldCaption("Location Code"))
                    {
                    }
                    column(Phys__Inventory_Order_Line__Bin_Code_Caption; FieldCaption("Bin Code"))
                    {
                    }
                    column(Phys__Inventory_Order_Line_DescriptionCaption; FieldCaption(Description))
                    {
                    }
                    column(Phys__Inventory_Order_Line__Base_Unit_of_Measure_Code_Caption; FieldCaption("Base Unit of Measure Code"))
                    {
                    }
                    column(Phys__Inventory_Order_Line__Qty__Expected__Base__Caption; FieldCaption("Qty. Expected (Base)"))
                    {
                    }
                    column(Phys__Inventory_Order_Line__Qty__Recorded__Base__Caption; FieldCaption("Qty. Recorded (Base)"))
                    {
                    }
                    column(Phys__Inventory_Order_Line__Quantity__Base__Caption; FieldCaption("Quantity (Base)"))
                    {
                    }
                    column(Phys__Inventory_Order_Line__Entry_Type_Caption; FieldCaption("Entry Type"))
                    {
                    }
                    column(Phys__Inventory_Order_Line__Recorded_without_Order_Caption; Phys__Inventory_Order_Line__Recorded_without_Order_CaptionLbl)
                    {
                    }
                    column(Phys__Inventory_Order_Line__Unit_Amount_Caption; FieldCaption("Unit Amount"))
                    {
                    }
                    dataitem(LineDimensionLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(Number; Number)
                        {
                        }
                        column(DimText_Control44; DimText)
                        {
                        }
                        column(DimTextCaption; DimTextCaptionLbl)
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
                            until (DimSetEntry.Next() = 0);
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowDim then
                                CurrReport.Break();

                            if LineIsEmpty then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(LineErrorCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ErrorText_Number__Control41; ErrorText[Number])
                        {
                        }
                        column(LineErrorCounter_Number; Number)
                        {
                        }
                        column(ErrorText_Number__Control41Caption; ErrorText_Number__Control41CaptionLbl)
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
                        ItemItemVariantLbl: Label '%1 %2', Comment = '%1 - Item No., %2 - Variant Code';
                    begin
                        OnBeforePhysInvtOrderLineOnAfterGetRecord("Phys. Invt. Order Line", ErrorCounter, ErrorText);
                        LineIsEmpty := EmptyLine();
                        if not LineIsEmpty then begin
                            if not "Qty. Exp. Calculated" then
                                AddError(StrSubstNo(MustBeErr, FieldCaption("Qty. Exp. Calculated"), true));
                            if not "On Recording Lines" then
                                AddError(StrSubstNo(MustBeErr, FieldCaption("On Recording Lines"), true));

                            if Item.Get("Item No.") then begin
                                if Item.Blocked then
                                    AddError(StrSubstNo(MustBeForErr, Item.FieldCaption(Blocked), false, Item.TableCaption(), "Item No."));

                                if "Phys. Invt. Order Line"."Variant Code" <> '' then begin
                                    ItemVariant.SetLoadFields(Blocked);
                                    if ItemVariant.Get("Phys. Invt. Order Line"."Item No.", "Phys. Invt. Order Line"."Variant Code") then begin
                                        if ItemVariant.Blocked then
                                            AddError(StrSubstNo(MustBeForErr, ItemVariant.FieldCaption(Blocked), false, ItemVariant.TableCaption(), StrSubstNo(ItemItemVariantLbl, "Phys. Invt. Order Line"."Item No.", "Phys. Invt. Order Line"."Variant Code")));
                                    end else
                                        AddError(StrSubstNo(DoesNotExistErr, StrSubstNo(ItemItemVariantLbl, "Phys. Invt. Order Line"."Item No.", "Phys. Invt. Order Line"."Variant Code"), ItemVariant.TableCaption()));
                                end;
                            end else
                                AddError(StrSubstNo(DoesNotExistErr, "Item No.", Item.TableCaption()));

                            if "Gen. Prod. Posting Group" = '' then
                                AddError(StrSubstNo(MustBeSpecifiedErr, FieldCaption("Gen. Prod. Posting Group")));
                            if "Inventory Posting Group" = '' then
                                AddError(StrSubstNo(MustBeSpecifiedErr, FieldCaption("Inventory Posting Group")));

                            if "Phys. Invt. Order Header".GetSamePhysInvtOrderLine(
                                 "Phys. Invt. Order Line",
                                 ErrorText2,
                                 PhysInvtOrderLine) > 1
                            then
                                AddError(
                                  ErrorText2);

                            if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                                AddError(DimMgt.GetDimCombErr());
                            DimSetEntry.SetRange("Dimension Set ID", "Dimension Set ID");
                        end;
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                if Status <> Status::Finished then
                    AddError(StrSubstNo(MustBeErr, FieldCaption(Status), FinishedTxt));

                if "Posting Date" = 0D then
                    AddError(StrSubstNo(MustBeSpecifiedErr, FieldCaption("Posting Date")))
                else
                    if "Posting Date" <> NormalDate("Posting Date") then
                        AddError(StrSubstNo(MustNotBeClosignDateErr, FieldCaption("Posting Date")))
                    else begin
                        if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
                            if UserId <> '' then
                                if UserSetup.Get(UserId) then begin
                                    AllowPostingFrom := UserSetup."Allow Posting From";
                                    AllowPostingTo := UserSetup."Allow Posting To";
                                end;
                            GLSetup.Get();
                            if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
                                AllowPostingFrom := GLSetup."Allow Posting From";
                                AllowPostingTo := GLSetup."Allow Posting To";
                            end;
                            if AllowPostingTo = 0D then
                                AllowPostingTo := 99991231D;
                        end;
                        if ("Posting Date" < AllowPostingFrom) or ("Posting Date" > AllowPostingTo) then
                            AddError(
                              StrSubstNo(
                                NotAllowedDateRangeErr, FieldCaption("Posting Date")));
                    end;

                if "Posting No." = '' then
                    if "No. Series" <> '' then
                        if "Posting No. Series" = '' then
                            AddError(
                              StrSubstNo(
                                MustBeSpecifiedErr,
                                FieldCaption("Posting No. Series")));

                PhysInvtOrderLine.Reset();
                PhysInvtOrderLine.SetRange("Document No.", "No.");
                if not PhysInvtOrderLine.FindFirst() then
                    AddError(DocumentErrorsMgt.GetNothingToPostErrorMsg());
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowDimensions; ShowDim)
                    {
                        ApplicationArea = Basic, Suite;
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

    var
        MustBeSpecifiedErr: Label '%1 must be specified.', Comment = '%1 = field caption';
        MustBeErr: Label '%1 must be %2.', Comment = '%1 = field caption, %2 = field value';
        MustNotBeClosignDateErr: Label '%1 must not be a closing date.', Comment = '%1 = field caption';
        FinishedTxt: Label 'Finished';
        NotAllowedDateRangeErr: Label '%1 is not within your allowed range of posting dates.', Comment = '%1 = field caption';
        MustBeForErr: Label '%1 must be %2 for %3 %4.', Comment = '%1 = field caption, %2 = value, %3 = table caption, %4 = field caption';
        DoesNotExistErr: Label '%2 %1 does not exist.', Comment = '%1 = Entity No., %2 - Table Caption';
        GLSetup: Record "General Ledger Setup";
        UserSetup: Record "User Setup";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        Item: Record Item;
        DimSetEntry: Record "Dimension Set Entry";
        DimMgt: Codeunit DimensionManagement;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        ErrorText: array[99] of Text[250];
        ErrorText2: Text[250];
        DimText: Text[120];
        OldDimText: Text[120];
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
        ErrorCounter: Integer;
        ShowDim: Boolean;
        Continue: Boolean;
        LineIsEmpty: Boolean;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Phys__Inventory_Order_Header___TestCaptionLbl: Label 'Phys. Inventory Order Header - Test';
        Phys__Inventory_Order_Header___Posting_Date_CaptionLbl: Label 'Posting Date';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        Phys__Inventory_Order_Line__Recorded_without_Order_CaptionLbl: Label 'Recorded Without Order';
        DimTextCaptionLbl: Label 'Line Dimensions';
        ErrorText_Number__Control41CaptionLbl: Label 'Warning!';

    local procedure AddError(Text: Text)
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := CopyStr(Text, 1, MaxStrLen(ErrorText[ErrorCounter]));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePhysInvtOrderLineOnAfterGetRecord(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var ErrorCounter: Integer; var ErrorText: array[99] of Text[250])
    begin
    end;
}


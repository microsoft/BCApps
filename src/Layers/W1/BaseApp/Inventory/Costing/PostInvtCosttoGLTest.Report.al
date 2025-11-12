// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Project.Job;
using System.Security.User;
using System.Utilities;

report 1003 "Post Invt. Cost to G/L - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Costing/PostInvtCosttoGLTest.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Post Invt. Cost to G/L - Test';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            PrintOnlyIfDetail = true;
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO_Text003_SELECTSTR_PostMethod___1_Text005__; StrSubstNo(PostedPostingTypeTxt, SelectStr(PostMethod + 1, PostingTypeTxt)))
            {
            }
            column(DocNo; DocNo)
            {
            }
            column(PostMethod; PostMethod)
            {
            }
            column(ItemValueEntry_TABLECAPTION__________ValueEntryFilter; ItemValueEntry.TableCaption + ': ' + ValueEntryFilter)
            {
            }
            column(ValueEntryFilter; ValueEntryFilter)
            {
            }
            column(Post_Inventory_Cost_to_G_L___TestCaption; Post_Inventory_Cost_to_G_L___TestCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(DocNoCaption; DocNoCaptionLbl)
            {
            }
            column(ItemValueEntry__Item_Ledger_Entry_No__Caption; ItemValueEntry__Item_Ledger_Entry_No__CaptionLbl)
            {
            }
            column(TempInvtPostToGLTestBuf__Value_Entry_No__Caption; TempInvtPostToGLTestBuf__Value_Entry_No__CaptionLbl)
            {
            }
            column(TempInvtPostToGLTestBuf_AmountCaption; TempInvtPostToGLTestBuf_AmountCaptionLbl)
            {
            }
            column(TempInvtPostToGLTestBuf_DescriptionCaption; TempInvtPostToGLTestBuf_DescriptionCaptionLbl)
            {
            }
            column(AccNameCaption; AccNameCaptionLbl)
            {
            }
            column(TempInvtPostToGLTestBuf__Account_No__Caption; TempInvtPostToGLTestBuf__Account_No__CaptionLbl)
            {
            }
            column(TempInvtPostToGLTestBuf__Document_No__Caption; TempInvtPostToGLTestBuf__Document_No__CaptionLbl)
            {
            }
            column(ItemValueEntry__Entry_Type_Caption; ItemValueEntry__Entry_Type_CaptionLbl)
            {
            }
            column(ItemValueEntry__Item_Ledger_Entry_Type_Caption; ItemValueEntry__Item_Ledger_Entry_Type_CaptionLbl)
            {
            }
            column(TempInvtPostToGLTestBuf__Posting_Date_Caption; TempInvtPostToGLTestBuf__Posting_Date_CaptionLbl)
            {
            }
            column(ItemValueEntry__Item_No__Caption; ItemValueEntry__Item_No__CaptionLbl)
            {
            }
            dataitem(PostValueEntryToGL; "Post Value Entry to G/L")
            {
                DataItemTableView = sorting("Item No.", "Posting Date");
                RequestFilterFields = "Item No.", "Posting Date";

                trigger OnAfterGetRecord()
                begin
                    ItemValueEntry.Get("Value Entry No.");

                    if ItemValueEntry."Item Ledger Entry No." = 0 then begin
                        TempCapValueEntry."Entry No." := ItemValueEntry."Entry No.";
                        TempCapValueEntry."Order Type" := ItemValueEntry."Order Type";
                        TempCapValueEntry."Order No." := ItemValueEntry."Order No.";
                        TempCapValueEntry.Insert();
                    end;
                    if (ItemValueEntry."Item Ledger Entry No." = 0) or not ItemValueEntry.Inventoriable then
                        CurrReport.Skip();

                    FillInvtPostToGLTestBuf(ItemValueEntry);
                end;

                trigger OnPostDataItem()
                begin
                    TempCapValueEntry.SetCurrentKey("Order Type", "Order No.");
                    if TempCapValueEntry.Find('-') then
                        repeat
                            ItemValueEntry.Get(TempCapValueEntry."Entry No.");
                            FillInvtPostToGLTestBuf(ItemValueEntry);
                        until TempCapValueEntry.Next() = 0;

                    if PostMethod = PostMethod::"per Posting Group" then begin
                        InvtPostToGL.SetGenJnlBatch(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                        InvtPostToGL.PostInvtPostBufPerPostGrp(DocNo, '');
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    InvtPostToGL.SetRunOnlyCheck(false, true, true);
                    TempCapValueEntry.DeleteAll();
                    OnAfterPostValueEntryToGLOnPreDataItem(PostValueEntryToGL, CompanyName);
                end;
            }
            dataitem(InvtPostToGLTestBuf; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(TempInvtPostToGLTestBuf_Amount; TempInvtPostToGLTestBuf.Amount)
                {
                }
                column(TempInvtPostToGLTestBuf_Description; TempInvtPostToGLTestBuf.Description)
                {
                }
                column(AccName; AccName)
                {
                }
                column(TempInvtPostToGLTestBuf__Account_No__; TempInvtPostToGLTestBuf."Account No.")
                {
                }
                column(TempInvtPostToGLTestBuf__Document_No__; TempInvtPostToGLTestBuf."Document No.")
                {
                }
                column(TempInvtPostToGLTestBuf__Posting_Date_; Format(TempInvtPostToGLTestBuf."Posting Date"))
                {
                }
                column(TempInvtPostToGLTestBuf__Value_Entry_No__; TempInvtPostToGLTestBuf."Value Entry No.")
                {
                }
                column(ItemValueEntry__Item_Ledger_Entry_Type_; ItemValueEntry."Item Ledger Entry Type")
                {
                }
                column(ItemValueEntry__Entry_Type_; ItemValueEntry."Entry Type")
                {
                }
                column(ItemValueEntry__Item_Ledger_Entry_No__; ItemValueEntry."Item Ledger Entry No.")
                {
                }
                column(ItemValueEntry__Item_No__; ItemValueEntry."Item No.")
                {
                }
                column(Line_No_; TempInvtPostToGLTestBuf."Line No.")
                {
                }
                dataitem(DimensionLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(Number; Number)
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

                        DimSetEntry.SetRange("Dimension Set ID", TempInvtPostToGLTestBuf."Dimension Set ID");
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
                    DimMgt: Codeunit DimensionManagement;
                    UserSetupManagement: Codeunit "User Setup Management";
                    TableID: array[10] of Integer;
                    No: array[10] of Code[20];
                    WrongEntryTypeComb: Boolean;
                    TempErrorText: Text[250];
                begin
                    if Number = 1 then
                        TempInvtPostToGLTestBuf.Find('-')
                    else
                        TempInvtPostToGLTestBuf.Next();

                    AccName := '';

                    if TempInvtPostToGLTestBuf."Value Entry No." <> 0 then begin
                        ItemValueEntry.Get(TempInvtPostToGLTestBuf."Value Entry No.");
                        WrongEntryTypeComb := not CheckEntryCombination(ItemValueEntry);
                    end else
                        Clear(ItemValueEntry);

                    if CheckPostingSetup(TempInvtPostToGLTestBuf) and not WrongEntryTypeComb then begin
                        if TempInvtPostToGLTestBuf."Account No." = '' then
                            if TempInvtPostToGLTestBuf."Invt. Posting Group Code" <> '' then
                                AddError(
                                  StrSubstNo(
                                    Text012, GetAccountName(), InvtPostSetup.TableCaption(), TempInvtPostToGLTestBuf."Location Code", TempInvtPostToGLTestBuf."Invt. Posting Group Code"))
                            else
                                AddError(
                                  StrSubstNo(
                                    Text012, GetAccountName(), GenPostSetup.TableCaption(), TempInvtPostToGLTestBuf."Gen. Bus. Posting Group", TempInvtPostToGLTestBuf."Gen. Prod. Posting Group"));

                        if not UserSetupManagement.TestAllowedPostingDate(TempInvtPostToGLTestBuf."Posting Date", TempErrorText) then
                            AddError(TempErrorText);

                        if TempInvtPostToGLTestBuf."Account No." <> '' then
                            CheckGLAcc(TempInvtPostToGLTestBuf);

                        if not DimMgt.CheckDimIDComb(TempInvtPostToGLTestBuf."Dimension Set ID") then
                            AddError(DimMgt.GetDimCombErr());

                        TableID[1] := DimMgt.TypeToTableID1(0);
                        No[1] := TempInvtPostToGLTestBuf."Account No.";
                        TableID[2] := DimMgt.TypeToTableID1(0);
                        No[2] := '';
                        TableID[3] := Database::Job;
                        No[3] := '';
                        TableID[4] := Database::"Salesperson/Purchaser";
                        No[4] := '';
                        TableID[5] := Database::Campaign;
                        No[5] := '';
                        if not DimMgt.CheckDimValuePosting(TableID, No, TempInvtPostToGLTestBuf."Dimension Set ID") then
                            AddError(DimMgt.GetDimValuePostingErr());
                    end;

                    if ShowOnlyWarnings and (ErrorCounter = 0) then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    InvtPostToGL.GetTempInvtPostToGLTestBuf(TempInvtPostToGLTestBuf);
                    SetRange(Number, 1, TempInvtPostToGLTestBuf.Count);
                end;
            }

            trigger OnPreDataItem()
            begin
                GLSetup.GetRecordOnce();
                if not GLSetup."Journal Templ. Name Mandatory" then
                    case PostMethod of
                        PostMethod::"per Posting Group":
                            if DocNo = '' then
                                Error(
                                  EnterWhenPostingErr,
                                  ItemValueEntry.FieldCaption("Document No."), SelectStr(PostMethod + 1, PostingTypeTxt));
                        PostMethod::"per Entry":
                            if DocNo <> '' then
                                Error(
                                  DoNotEnterWhenPostingErr,
                                  ItemValueEntry.FieldCaption("Document No."), SelectStr(PostMethod + 1, PostingTypeTxt));
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
                    field(PostingMethod; PostMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Method';
                        OptionCaption = 'Per Posting Group,Per Entry';
                        ToolTip = 'Specifies if the batch job tests the posting of inventory value to the general ledger per inventory posting group or per posted value entry. If you post per entry, you achieve a detailed specification of how the inventory affects the general ledger.';
                    }
                    field(DocumentNo; DocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the document that is processed by the report or batch job.';
                    }
                    field(ShowDimensions; ShowDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies that the dimensions for each entry or posting group are included.';
                    }
                    field(ShowOnlyWarnings; ShowOnlyWarnings)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Only Warnings';
                        ToolTip = 'Specifies that only the entries that produce errors are included. If you do not select this check box, the report will show all entries that could be posted to the general ledger.';
                    }
                    field(JnlTemplateName; GenJnlLineReq."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Template Name';
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the name of the journal template that is used for the posting.';
                        Visible = IsJournalTemplNameVisible;

                        trigger OnValidate()
                        begin
                            GenJnlLineReq."Journal Batch Name" := '';
                        end;
                    }
                    field(JnlBatchName; GenJnlLineReq."Journal Batch Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch Name';
                        Lookup = true;
                        ToolTip = 'Specifies the name of the journal batch that is used for the posting.';
                        Visible = IsJournalTemplNameVisible;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            GenJnlManagement: Codeunit GenJnlManagement;
                        begin
                            GenJnlManagement.SetJnlBatchName(GenJnlLineReq);
                            if GenJnlLineReq."Journal Batch Name" <> '' then
                                GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                        end;

                        trigger OnValidate()
                        begin
                            if GenJnlLineReq."Journal Batch Name" <> '' then begin
                                GenJnlLineReq.TestField("Journal Template Name");
                                GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GLSetup.GetRecordOnce();
            IsJournalTemplNameVisible := GLSetup."Journal Templ. Name Mandatory";
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        NoSeries: Codeunit "No. Series";
    begin
        OnBeforePreReport(PostValueEntryToGL, ItemValueEntry);

        GLSetup.GetRecordOnce();
        if GLSetup."Journal Templ. Name Mandatory" then begin
            if GenJnlLineReq."Journal Template Name" = '' then
                Error(MissingJournalFieldErr, GenJnlLineReq.FieldCaption("Journal Template Name"));
            if GenJnlLineReq."Journal Batch Name" = '' then
                Error(MissingJournalFieldErr, GenJnlLineReq.FieldCaption("Journal Batch Name"));

            Clear(DocNo);
            GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
            GenJnlBatch.TestField("No. Series");
            DocNo := NoSeries.GetNextNo(GenJnlBatch."No. Series", 0D);
        end;

        ValueEntryFilter := PostValueEntryToGL.GetFilters();
    end;

    var
        EnterWhenPostingErr: Label 'Please enter a %1 when posting %2.', Comment = '%1 - field caption, %2 - posting type';
        DoNotEnterWhenPostingErr: Label 'Do not enter a %1 when posting %2.', Comment = '%1 - field caption, %2 - posting type';
        FieldCombinationErr: Label 'The following combination %1 = %2, %3 = %4, and %5 = %6 is not allowed.', Comment = '%1, %3, %5 - field captions, %2, %4, %6 - field values';
        PostedPostingTypeTxt: Label 'Posted %1', Comment = '%1 - posting type';
        PostingTypeTxt: Label 'per Posting Group,per Entry';
        DoesNotExistErr: Label '%1 %2 does not exist.', Comment = '%1 - field caption, %2 - field value';
        MustBeForErr: Label '%1 must be %2 for %3 %4.', Comment = '%1 and %3 - field captions, %2 and %4 - field values';
        GLSetup: Record "General Ledger Setup";
        GLAcc: Record "G/L Account";
        TempInvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer" temporary;
        TempCapValueEntry: Record "Value Entry" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        ItemValueEntry: Record "Value Entry";
        InvtPostSetup: Record "Inventory Posting Setup";
        GenPostSetup: Record "General Posting Setup";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLineReq: Record "Gen. Journal Line";
        InvtPostToGL: Codeunit "Inventory Posting To G/L";
        PostMethod: Option "per Posting Group","per Entry";
        DocNo: Code[20];
        ValueEntryFilter: Text;
        AccName: Text[100];
        ErrorText: array[50] of Text[250];
        DimText: Text[120];
        OldDimText: Text[75];
        ShowDim: Boolean;
        Continue: Boolean;
        ShowOnlyWarnings: Boolean;
        ErrorCounter: Integer;
        IsJournalTemplNameVisible: Boolean;
        SetupBlockedErr: Label 'Setup is blocked in %1 for %2 %3 and %4 %5.', Comment = '%1 - General/Inventory Posting Setup, %2 %3 %4 %5 - posting groups.';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text011: Label '%1 is missing for %2 %3 and %4 %5.';
        Text012: Label '%1 is missing in %2, %3 %4.';
        Text013: Label '%1 must be false, if %2 is not Direct Cost or Revaluation.';
        Text014: Label '%1 and %2 must be zero, if %3 is not Direct Cost or Revaluation.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Post_Inventory_Cost_to_G_L___TestCaptionLbl: Label 'Post Inventory Cost to G/L - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        DocNoCaptionLbl: Label 'Document No.';
        ItemValueEntry__Item_Ledger_Entry_No__CaptionLbl: Label 'Item Ledger Entry No.';
        TempInvtPostToGLTestBuf__Value_Entry_No__CaptionLbl: Label 'Value Entry No.';
        TempInvtPostToGLTestBuf_AmountCaptionLbl: Label 'Amount';
        TempInvtPostToGLTestBuf_DescriptionCaptionLbl: Label 'Description';
        AccNameCaptionLbl: Label 'Name';
        TempInvtPostToGLTestBuf__Account_No__CaptionLbl: Label 'Account No.';
        TempInvtPostToGLTestBuf__Document_No__CaptionLbl: Label 'Document No.';
        ItemValueEntry__Entry_Type_CaptionLbl: Label 'Value Entry Type';
        ItemValueEntry__Item_Ledger_Entry_Type_CaptionLbl: Label 'Item Ledger Entry Type';
        TempInvtPostToGLTestBuf__Posting_Date_CaptionLbl: Label 'Posting Date';
        ItemValueEntry__Item_No__CaptionLbl: Label 'Item No.';
        DimensionsCaptionLbl: Label 'Dimensions';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        MissingJournalFieldErr: Label 'Please enter a %1 when posting inventory cost to G/L.', Comment = '%1 - field caption';

    local procedure FillInvtPostToGLTestBuf(ValueEntry: Record "Value Entry")
    var
        SkipFillInvtPost: Boolean;
    begin
        SkipFillInvtPost := not InvtPostToGL.BufferInvtPosting(ValueEntry);
        OnFillInvtPostToGLTestBufOnAfterCalcSkipFillInvtPost(ValueEntry, SkipFillInvtPost);
        if SkipFillInvtPost then
            exit;

        if PostMethod = PostMethod::"per Entry" then begin
            GLSetup.GetRecordOnce();
            if GLSetup."Journal Templ. Name Mandatory" then
                InvtPostToGL.SetGenJnlBatch(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
            InvtPostToGL.PostInvtPostBufPerEntry(ValueEntry);
        end;
    end;

    procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    local procedure CheckEntryCombination(ValueEntry: Record "Value Entry"): Boolean
    begin
        if not (ValueEntry."Entry Type" in [ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Entry Type"::Revaluation]) then begin
            if ValueEntry."Expected Cost" then
                AddError(
                  StrSubstNo(
                    Text013, ValueEntry.FieldCaption("Expected Cost"), ValueEntry.FieldCaption("Entry Type")));
            if (ValueEntry."Cost Amount (Expected)" <> 0) or (ValueEntry."Cost Amount (Expected) (ACY)" <> 0) then
                AddError(
                  StrSubstNo(
                    Text014, ValueEntry.FieldCaption("Cost Amount (Expected)"), ValueEntry.FieldCaption("Cost Amount (Expected) (ACY)"),
                    ValueEntry.FieldCaption("Entry Type")));
        end;
        case ValueEntry."Item Ledger Entry Type" of
            ValueEntry."Item Ledger Entry Type"::Sale,
          ValueEntry."Item Ledger Entry Type"::"Positive Adjmt.",
          ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.",
          ValueEntry."Item Ledger Entry Type"::Transfer,
          ValueEntry."Item Ledger Entry Type"::Consumption,
          ValueEntry."Item Ledger Entry Type"::"Assembly Consumption":
                if ValueEntry."Entry Type" in [ValueEntry."Entry Type"::Variance, ValueEntry."Entry Type"::"Indirect Cost"] then begin
                    ErrorNonValidCombination(ValueEntry);
                    exit(false);
                end;
            ValueEntry."Item Ledger Entry Type"::Output,
          ValueEntry."Item Ledger Entry Type"::"Assembly Output":
                if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::Variance) and
                   (ValueEntry."Variance Type" in [ValueEntry."Variance Type"::" ", ValueEntry."Variance Type"::Purchase])
                then begin
                    ErrorNonValidCombination(ValueEntry);
                    exit(false);
                end;
            ValueEntry."Item Ledger Entry Type"::" ":
                if not (ValueEntry."Entry Type" in [ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Entry Type"::"Indirect Cost"]) then begin
                    ErrorNonValidCombination(ValueEntry);
                    exit(false);
                end;
        end;
        exit(true);
    end;

    local procedure ErrorNonValidCombination(ValueEntry: Record "Value Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeErrorNonValidCombination(ValueEntry, IsHandled);
        if IsHandled then
            exit;

        AddError(
              StrSubstNo(
                FieldCombinationErr,
                ValueEntry.FieldCaption("Item Ledger Entry Type"), ValueEntry."Item Ledger Entry Type",
                ValueEntry.FieldCaption("Entry Type"), ValueEntry."Entry Type",
                ValueEntry.FieldCaption("Expected Cost"), ValueEntry."Expected Cost"))
    end;

    local procedure CheckGLAcc(InvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer")
    begin
        if not GLAcc.Get(InvtPostToGLTestBuf."Account No.") then
            AddError(
              StrSubstNo(DoesNotExistErr, GLAcc.TableCaption(), InvtPostToGLTestBuf."Account No."))
        else begin
            AccName := GLAcc.Name;
            if GLAcc.Blocked then
                AddError(
                  StrSubstNo(
                    MustBeForErr,
                    GLAcc.FieldCaption(Blocked), false, GLAcc.TableCaption(), InvtPostToGLTestBuf."Account No."));
            if GLAcc."Account Type" <> GLAcc."Account Type"::Posting then begin
                GLAcc."Account Type" := GLAcc."Account Type"::Posting;
                AddError(
                  StrSubstNo(
                    MustBeForErr,
                    GLAcc.FieldCaption("Account Type"), GLAcc."Account Type", GLAcc.TableCaption(), InvtPostToGLTestBuf."Account No."));
            end;
        end;
    end;

    local procedure CheckPostingSetup(InvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPostingSetup(InvtPostToGLTestBuf, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if InvtPostToGLTestBuf."Invt. Posting Group Code" <> '' then begin
            if not InvtPostSetup.Get(InvtPostToGLTestBuf."Location Code", InvtPostToGLTestBuf."Invt. Posting Group Code") then begin
                AddError(
                  StrSubstNo(
                    Text011,
                    InvtPostSetup.TableCaption(),
                    InvtPostToGLTestBuf.FieldCaption("Location Code"), InvtPostToGLTestBuf."Location Code",
                    InvtPostToGLTestBuf.FieldCaption("Invt. Posting Group Code"), InvtPostToGLTestBuf."Invt. Posting Group Code"));
                exit(false);
            end
        end else begin
            if not GenPostSetup.Get(InvtPostToGLTestBuf."Gen. Bus. Posting Group", InvtPostToGLTestBuf."Gen. Prod. Posting Group") then begin
                AddError(
                  StrSubstNo(
                    Text011,
                    GenPostSetup.TableCaption(),
                    InvtPostToGLTestBuf.FieldCaption("Gen. Bus. Posting Group"), InvtPostToGLTestBuf."Gen. Bus. Posting Group",
                    InvtPostToGLTestBuf.FieldCaption("Gen. Prod. Posting Group"), InvtPostToGLTestBuf."Gen. Prod. Posting Group"));
                exit(false);
            end;
            if GenPostSetup.Blocked then begin
                AddError(
                  StrSubstNo(
                    SetupBlockedErr,
                    GenPostSetup.TableCaption(),
                    InvtPostToGLTestBuf.FieldCaption("Gen. Bus. Posting Group"), InvtPostToGLTestBuf."Gen. Bus. Posting Group",
                    InvtPostToGLTestBuf.FieldCaption("Gen. Prod. Posting Group"), InvtPostToGLTestBuf."Gen. Prod. Posting Group"));
                exit(false);
            end;
        end;
        exit(true);
    end;

    procedure GetAccountName(): Text[80]
    var
        AccountName: Text[80];
        IsHandled: Boolean;
    begin
        case TempInvtPostToGLTestBuf."Inventory Account Type" of
            TempInvtPostToGLTestBuf."Inventory Account Type"::Inventory:
                exit(InvtPostSetup.FieldCaption("Inventory Account"));
            TempInvtPostToGLTestBuf."Inventory Account Type"::"Inventory (Interim)":
                exit(InvtPostSetup.FieldCaption("Inventory Account (Interim)"));
            TempInvtPostToGLTestBuf."Inventory Account Type"::"WIP Inventory":
                exit(InvtPostSetup.FieldCaption("WIP Account"));
            TempInvtPostToGLTestBuf."Inventory Account Type"::"Material Variance":
                exit(InvtPostSetup.FieldCaption("Material Variance Account"));
            TempInvtPostToGLTestBuf."Inventory Account Type"::"Capacity Variance":
                exit(InvtPostSetup.FieldCaption("Capacity Variance Account"));
            TempInvtPostToGLTestBuf."Inventory Account Type"::"Subcontracted Variance":
                exit(InvtPostSetup.FieldCaption("Subcontracted Variance Account"));
            TempInvtPostToGLTestBuf."Inventory Account Type"::"Cap. Overhead Variance":
                exit(InvtPostSetup.FieldCaption("Cap. Overhead Variance Account"));
            TempInvtPostToGLTestBuf."Inventory Account Type"::"Mfg. Overhead Variance":
                exit(InvtPostSetup.FieldCaption("Mfg. Overhead Variance Account"));
            TempInvtPostToGLTestBuf."Inventory Account Type"::"Inventory Adjmt.":
                exit(GenPostSetup.FieldCaption("Inventory Adjmt. Account"));
            TempInvtPostToGLTestBuf."Inventory Account Type"::"Direct Cost Applied":
                exit(GenPostSetup.FieldCaption("Direct Cost Applied Account"));
            TempInvtPostToGLTestBuf."Inventory Account Type"::"Overhead Applied":
                exit(GenPostSetup.FieldCaption("Overhead Applied Account"));
            TempInvtPostToGLTestBuf."Inventory Account Type"::"Purchase Variance":
                exit(GenPostSetup.FieldCaption("Purchase Variance Account"));
            TempInvtPostToGLTestBuf."Inventory Account Type"::COGS:
                exit(GenPostSetup.FieldCaption("COGS Account"));
            TempInvtPostToGLTestBuf."Inventory Account Type"::"COGS (Interim)":
                exit(GenPostSetup.FieldCaption("COGS Account (Interim)"));
            TempInvtPostToGLTestBuf."Inventory Account Type"::"Invt. Accrual (Interim)":
                exit(GenPostSetup.FieldCaption("Invt. Accrual Acc. (Interim)"));
            else begin
                IsHandled := false;
                OnGetAccountNameInventoryAccountTypeCase(TempInvtPostToGLTestBuf, AccountName, IsHandled, InvtPostSetup, GenPostSetup);
                if IsHandled then
                    exit(AccountName);
            end;
        end;

        OnAfterGetAccountName(TempInvtPostToGLTestBuf, InvtPostSetup, GenPostSetup, AccountName);
        exit(AccountName);
    end;

    procedure InitializeRequest(NewPostMethod: Option; NewDocNo: Code[20]; NewShowDim: Boolean; NewShowOnlyWarnings: Boolean)
    begin
        PostMethod := NewPostMethod;
        DocNo := NewDocNo;
        ShowDim := NewShowDim;
        ShowOnlyWarnings := NewShowOnlyWarnings;
    end;

    procedure SetGenJnlBatch(NewJnlTemplName: Code[10]; NewJnlBatchName: Code[10])
    begin
        GenJnlLineReq."Journal Template Name" := NewJnlTemplName;
        GenJnlLineReq."Journal Batch Name" := NewJnlBatchName;
    end;

    procedure GetParameters(var NewPostMethod: Option; var NewDocNo: Code[20]; var NewShowDim: Boolean; var NewShowOnlyWarnings: Boolean)
    begin
        NewPostMethod := PostMethod;
        NewDocNo := DocNo;
        NewShowDim := ShowDim;
        NewShowOnlyWarnings := ShowOnlyWarnings;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccountName(var InvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer"; InvtPostingSetup: Record "Inventory Posting Setup"; GenPostingSetup: Record "General Posting Setup"; var AccountName: Text[80])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostValueEntryToGLOnPreDataItem(var PostValueEntryToGL: Record "Post Value Entry to G/L"; CompanyName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeErrorNonValidCombination(ValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreReport(var PostValueEntryToGL: Record "Post Value Entry to G/L"; var ItemValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillInvtPostToGLTestBufOnAfterCalcSkipFillInvtPost(var ValueEntry: Record "Value Entry"; var SkipFillInvtPost: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAccountNameInventoryAccountTypeCase(InvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer"; var AccountName: Text[80]; var IsHandled: Boolean; InvtPostingSetup: Record "Inventory Posting Setup"; GenPostingSetup: Record "General Posting Setup")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckPostingSetup(InvtPostToGLTestBuf: Record "Invt. Post to G/L Test Buffer"; var Result: Boolean; var IsHandled: Boolean);
    begin
    end;
}


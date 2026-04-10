// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Purchases.Vendor;
using System.Environment;
using System.Utilities;

page 5551 "Fixed Asset Acquisition Wizard"
{
    Caption = 'Fixed Asset Acquisition';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    ShowFilter = false;
    SourceTable = "Gen. Journal Line";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and (Step <> Step::Done);
#pragma warning disable AA0100
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control98)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and (Step = Step::Done);
#pragma warning disable AA0100
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                Caption = '';
                Visible = Step = Step::Intro;
                group("Para1.1")
                {
                    Caption = 'Welcome to Assisted Fixed Asset Acquisition';
                    group("Para1.1.1")
                    {
                        Caption = '';
                        InstructionalText = 'When you acquire a fixed asset, you can post the transaction to a G/L account, a vendor, or a bank account.';
                    }
                    group("Para1.1.2")
                    {
                        Visible = false;
                    }
                }
                group("Para1.2")
                {
                    Caption = '';
                    InstructionalText = 'Choose Next to specify how to post the acquisition.';
                }
            }
            group(Step2)
            {
                Caption = '';
                Visible = Step = Step::"Register Details";
                group("Para2.1")
                {
                    Caption = 'Which ledger do you want to post the acquisition to?';
                    field(TypeOfAcquisitions; AcquisitionOptions)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Post to';
                        OptionCaption = 'G/L Account,Vendor,Bank Account';
                        Tooltip = 'Specifies the ledger type to use for posting the acquisition.';

                        trigger OnValidate()
                        begin
                            case AcquisitionOptions of
                                AcquisitionOptions::"G/L Account":
                                    Rec.Validate("Bal. Account Type", Rec."Bal. Account Type"::"G/L Account");
                                AcquisitionOptions::Vendor:
                                    Rec."Bal. Account Type" := Rec."Bal. Account Type"::Vendor;
                                AcquisitionOptions::"Bank Account":
                                    Rec.Validate("Bal. Account Type", Rec."Bal. Account Type"::"Bank Account");
                            end;
                            ValidateCurrentStep(Step);
                        end;
                    }
                    group(Control34)
                    {
                        ShowCaption = false;
                        Visible = AcquisitionOptions = AcquisitionOptions::"G/L Account";
                        field(BalancingAccountNo; Rec."Bal. Account No.")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Balancing Account No.';
                            ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry for the acquisition line will be posted.';

                            trigger OnValidate()
                            begin
                                ValidateCurrentStep(Step);
                            end;
                        }
                    }
                    group(Control27)
                    {
                        ShowCaption = false;
                        Visible = AcquisitionOptions = AcquisitionOptions::Vendor;
                        field(VendorNo; Rec."Bal. Account No.")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Vendor';
                            ToolTip = 'Specifies the number of the vendor to which a balancing entry for the acquisition line will be posted.';

                            trigger OnValidate()
                            var
                                Vendor: Record Vendor;
                            begin
                                if Vendor.Get(Rec."Bal. Account No.") then
                                    Rec.Validate("Currency Code", Vendor."Currency Code");
                            end;
                        }
                        field(ExternalDocNo; Rec."External Document No.")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'External Document No.';
                            ToolTip = 'Specifies the identification number that the vendor assigned to the document. For example, this number is useful if you need to contact the vendor about the document.';

                            trigger OnValidate()
                            begin
                                ValidateCurrentStep(Step);
                            end;
                        }
                    }
                    group(Control30)
                    {
                        ShowCaption = false;
                        Visible = AcquisitionOptions = AcquisitionOptions::"Bank Account";
                        field("Bank Account"; Rec."Bal. Account No.")
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Bank Account';
                            ToolTip = 'Specifies the number of the bank account to which a balancing entry for the acquisition line will be posted.';

                            trigger OnValidate()
                            begin
                                ValidateCurrentStep(Step);
                            end;
                        }
                    }
                    field(AcquisitionCurrencyCode; Rec."Currency Code")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Currency Code';
                        ToolTip = 'Specifies the Currency code that will be used for the acquisition line will be posted.';
                    }
                }
            }
            group(Step3)
            {
                Caption = '';
                Visible = Step = Step::"FA Details";
                group("Para3.1")
                {
                    Caption = 'Provide information about the fixed asset.';
                    field(AcquisitionCost; Rec.Amount)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Acquisition Cost Incl. VAT';
                        ToolTip = 'Specifies the total amount (including VAT) of the acquisition document.';

                        trigger OnValidate()
                        begin
                            ValidateCurrentStep(Step);
                        end;
                    }
                    field(AcquisitionDate; Rec."Posting Date")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Acquisition Date';
                        ToolTip = 'Specifies the date on which the fixed asset was acquired.';

                        trigger OnValidate()
                        begin
                            ValidateCurrentStep(Step);
                        end;
                    }
                    field(CurrencyCode; Rec."Currency Code")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Currency Code';
                        ToolTip = 'Specifies the Currency code that will be used for the acquisition line will be posted.';
                    }
                }
            }
            group(Step4)
            {
                Caption = '';
                Visible = Step = Step::Done;
                group("Para4.1")
                {
                    Caption = 'That''s it!';
                    InstructionalText = 'The information needed to post the acquisition is  now ready in the fixed asset G/L journal.';
                }
                group("Para4.2")
                {
                    Caption = '';
                    InstructionalText = 'Choose Finish to automatically post the fixed asset G/L journal lines.';
                    field(OpenFAGLJournal; OpenFAGLJournal)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Upon Finish, open the FA G/L journal.';
                        Enabled = EnableOpenFAGLJournal;
                    }
                }
            }
            group(StepInJournal)
            {
                Caption = '';
                Visible = Step = Step::"Already In Journal";
                group("Para5.1")
                {
                    Caption = 'The fixed asset is already planned to be acquired.';
                    InstructionalText = 'Fixed asset G/L journal already contains a line for the acquisition of this fixed asset.';
                }
                group("Para5.2")
                {
                    Caption = '';
                    InstructionalText = 'Choose Finish to open the fixed asset G/L journal. Close this window to take no further action.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(PreviousPage)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Back';
                Enabled = Step <> Step::Intro;
                Image = PreviousRecord;
                InFooterBar = true;
                Visible = Step <> Step::"Already In Journal";

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(NextPage)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Next';
                Enabled = (Step <> Step::Done) and (CurrStepIsValid);
                Image = NextRecord;
                InFooterBar = true;
                Visible = Step <> Step::"Already In Journal";

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(Finish)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Finish';
                Enabled = (Step = Step::Done) or (Step = Step::"Already In Journal");
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    GenJnlLine: Record "Gen. Journal Line";
                    PageGenJnlLine: Record "Gen. Journal Line";
                begin
                    if Step <> Step::"Already In Journal" then
                        Rec.CreateFAAcquisitionLines(GenJnlLine);

                    if OpenFAGLJournal then begin
                        PageGenJnlLine.Validate("Journal Template Name", Rec."Journal Template Name");
                        PageGenJnlLine.Validate("Journal Batch Name", Rec."Journal Batch Name");
                        PageGenJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                        PageGenJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                        PAGE.Run(PAGE::"Fixed Asset G/L Journal", PageGenJnlLine);
                    end else
                        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJnlLine);

                    CurrPage.Close();
                end;
            }
            action("Exit")
            {
                ApplicationArea = FixedAssets;
                Caption = 'Exit';

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
    end;

    trigger OnOpenPage()
    begin
        // We could check if values like FA Posting code, descirption are in the temp
        if not Rec.Get() then begin
            Rec.Init();
            Rec."Journal Template Name" := FixedAssetAcquisitionWizard.SelectFATemplate();
            Rec."Journal Batch Name" := FixedAssetAcquisitionWizard.GetGenJournalBatchName(
                CopyStr(Rec.GetFilter("Account No."), 1, MaxStrLen(Rec."Account No.")));
            Rec."Document Type" := Rec."Document Type"::Invoice;
            Rec."Account Type" := Rec."Account Type"::"Fixed Asset";
            Rec."FA Posting Type" := Rec."FA Posting Type"::"Acquisition Cost";
            Rec."Posting Date" := WorkDate();
            Rec.SetAccountNoFromFilter();
            Rec.Insert();
        end;

        EnableOpenFAGLJournal := JournalBatchIsEmpty();
        OpenFAGLJournal := not EnableOpenFAGLJournal;
        VerifyFADoNotExistInGLJournalLines();
        ValidateCurrentStep(Step);
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        TempBalancingGenJournalLine: Record "Gen. Journal Line" temporary;
        FixedAssetAcquisitionWizard: Codeunit "Fixed Asset Acquisition Wizard";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Intro,"Register Details","FA Details",Done,"Already In Journal";
        TopBannerVisible: Boolean;
        AcquisitionOptions: Option "G/L Account",Vendor,"Bank Account";
        OpenFAGLJournal: Boolean;
        CurrStepIsValid: Boolean;
        EnableOpenFAGLJournal: Boolean;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;
        ValidateCurrentStep(Step);

        if Step = Step::Done then begin
            TempBalancingGenJournalLine.Init();
            TempBalancingGenJournalLine.TransferFields(Rec);
            TempBalancingGenJournalLine."Account No." := '';
            if not TempBalancingGenJournalLine.Insert() then
                TempBalancingGenJournalLine.Modify(true);
        end;

        CurrPage.Update(true);
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;

    local procedure ValidateCurrentStep(CurrentStep: Option)
    begin
        case CurrentStep of
            Step::Intro:
                CurrStepIsValid := true;
            Step::"Register Details":
                begin
                    CurrStepIsValid := Rec."Bal. Account No." <> '';
                    if AcquisitionOptions = AcquisitionOptions::Vendor then
                        CurrStepIsValid := CurrStepIsValid and (Rec."External Document No." <> '');
                end;
            Step::"FA Details":
                CurrStepIsValid := (Rec.Amount >= 0.0) and (Rec."Posting Date" <> 0D);
            Step::Done:
                CurrStepIsValid := true;
            else
                CurrStepIsValid := true;
        end;
    end;

    local procedure JournalBatchIsEmpty(): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", Rec."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
        exit(GenJournalLine.IsEmpty());
    end;

    local procedure VerifyFADoNotExistInGLJournalLines()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Account No.", Rec."Account No.");
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"Fixed Asset");
        GenJournalLine.SetRange("FA Posting Type", Rec."FA Posting Type"::"Acquisition Cost");
        if GenJournalLine.FindFirst() then begin
            Step := Step::"Already In Journal";
            OpenFAGLJournal := true;
            Rec.Copy(GenJournalLine);
            Rec.Insert();
        end
    end;
}


// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Outbox;
using System.Upgrade;

/// <summary>
/// Upgrade codeunit for Intercompany-specific data migrations extracted from Upgrade - BaseApp.
/// </summary>
codeunit 8506 "IC Upgrade - BaseApp"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        UpgradeICPartnerGLAccountNo();
        UpgradeICInboxTransactionAccountNo();
        UpgradeHandledICInboxTransactionAccountNo();
        UpgradeICOutboxTransactionAccountNo();
        UpgradeHandledICOutboxTransactionAccountNo();
        UpgradeICGLAccountNoInPostedGenJournalLine();
        UpgradeICGLAccountNoInStandardGeneralJournalLine();
        UpgradeICOutboxTransactionSourceType();
        UpgradeICTransactionSourceType();
    end;

    local procedure UpgradeICPartnerGLAccountNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        GenJournalLineDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag()) then
            exit;

        GenJournalLine.SetFilter("IC Partner G/L Acc. No.", '<> ''''');
        if GenJournalLine.IsEmpty() then
            exit;

        GenJournalLineDataTransfer.SetTables(Database::"Gen. Journal Line", Database::"Gen. Journal Line");
        GenJournalLineDataTransfer.AddSourceFilter(GenJournalLine.FieldNo("IC Partner G/L Acc. No."), '<> ''''');
        GenJournalLineDataTransfer.AddConstantValue("IC Journal Account Type"::"G/L Account", GenJournalLine.FieldNo("IC Account Type"));
        GenJournalLineDataTransfer.AddFieldValue(GenJournalLine.FieldNo("IC Partner G/L Acc. No."), GenJournalLine.FieldNo("IC Account No."));
        GenJournalLineDataTransfer.CopyFields();
        Clear(GenJournalLineDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag());
    end;

    local procedure UpgradeICInboxTransactionAccountNo()
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        ICInboxTransactionTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag()) then
            exit;

        ICInboxTransaction.SetFilter("IC Partner G/L Acc. No.", '<> ''''');
        if ICInboxTransaction.IsEmpty() then
            exit;

        ICInboxTransactionTransfer.SetTables(Database::"IC Inbox Transaction", Database::"IC Inbox Transaction");
        ICInboxTransactionTransfer.AddSourceFilter(ICInboxTransaction.FieldNo("IC Partner G/L Acc. No."), '<> ''''');
        ICInboxTransactionTransfer.AddConstantValue("IC Journal Account Type"::"G/L Account", ICInboxTransaction.FieldNo("IC Account Type"));
        ICInboxTransactionTransfer.AddFieldValue(ICInboxTransaction.FieldNo("IC Partner G/L Acc. No."), ICInboxTransaction.FieldNo("IC Account No."));
        ICInboxTransactionTransfer.CopyFields();
        Clear(ICInboxTransactionTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag());
    end;

    local procedure UpgradeHandledICInboxTransactionAccountNo()
    var
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        HandledICInboxTransactionTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag()) then
            exit;

        HandledICInboxTrans.SetFilter("IC Partner G/L Acc. No.", '<> ''''');
        if HandledICInboxTrans.IsEmpty() then
            exit;

        HandledICInboxTransactionTransfer.SetTables(Database::"Handled IC Inbox Trans.", Database::"Handled IC Inbox Trans.");
        HandledICInboxTransactionTransfer.AddSourceFilter(HandledICInboxTrans.FieldNo("IC Partner G/L Acc. No."), '<> ''''');
        HandledICInboxTransactionTransfer.AddConstantValue("IC Journal Account Type"::"G/L Account", HandledICInboxTrans.FieldNo("IC Account Type"));
        HandledICInboxTransactionTransfer.AddFieldValue(HandledICInboxTrans.FieldNo("IC Partner G/L Acc. No."), HandledICInboxTrans.FieldNo("IC Account No."));
        HandledICInboxTransactionTransfer.CopyFields();
        Clear(HandledICInboxTransactionTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag());
    end;

    local procedure UpgradeICOutboxTransactionAccountNo()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        ICOutboxTransactionTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag()) then
            exit;

        ICOutboxTransaction.SetFilter("IC Partner G/L Acc. No.", '<> ''''');
        if ICOutboxTransaction.IsEmpty() then
            exit;

        ICOutboxTransactionTransfer.SetTables(Database::"IC Outbox Transaction", Database::"IC Outbox Transaction");
        ICOutboxTransactionTransfer.AddSourceFilter(ICOutboxTransaction.FieldNo("IC Partner G/L Acc. No."), '<> ''''');
        ICOutboxTransactionTransfer.AddConstantValue("IC Journal Account Type"::"G/L Account", ICOutboxTransaction.FieldNo("IC Account Type"));
        ICOutboxTransactionTransfer.AddFieldValue(ICOutboxTransaction.FieldNo("IC Partner G/L Acc. No."), ICOutboxTransaction.FieldNo("IC Account No."));
        ICOutboxTransactionTransfer.CopyFields();
        Clear(ICOutboxTransactionTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag());
    end;

    local procedure UpgradeHandledICOutboxTransactionAccountNo()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        HandledICOutboxTransactionTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag()) then
            exit;

        HandledICOutboxTrans.SetFilter("IC Partner G/L Acc. No.", '<> ''''');
        if HandledICOutboxTrans.IsEmpty() then
            exit;

        HandledICOutboxTransactionTransfer.SetTables(Database::"Handled IC Outbox Trans.", Database::"Handled IC Outbox Trans.");
        HandledICOutboxTransactionTransfer.AddSourceFilter(HandledICOutboxTrans.FieldNo("IC Partner G/L Acc. No."), '<> ''''');
        HandledICOutboxTransactionTransfer.AddConstantValue("IC Journal Account Type"::"G/L Account", HandledICOutboxTrans.FieldNo("IC Account Type"));
        HandledICOutboxTransactionTransfer.AddFieldValue(HandledICOutboxTrans.FieldNo("IC Partner G/L Acc. No."), HandledICOutboxTrans.FieldNo("IC Account No."));
        HandledICOutboxTransactionTransfer.CopyFields();
        Clear(HandledICOutboxTransactionTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag());
    end;

    local procedure UpgradeICGLAccountNoInPostedGenJournalLine()
    var
        PostedGenJournalLine: Record "Posted Gen. Journal Line";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        PostedGenJournalLineDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag()) then
            exit;

        PostedGenJournalLine.SetFilter("IC Partner G/L Acc. No.", '<> ''''');
        if PostedGenJournalLine.IsEmpty() then
            exit;

        PostedGenJournalLineDataTransfer.SetTables(Database::"Posted Gen. Journal Line", Database::"Posted Gen. Journal Line");
        PostedGenJournalLineDataTransfer.AddSourceFilter(PostedGenJournalLine.FieldNo("IC Partner G/L Acc. No."), '<> ''''');
        PostedGenJournalLineDataTransfer.AddConstantValue("IC Journal Account Type"::"G/L Account", PostedGenJournalLine.FieldNo("IC Account Type"));
        PostedGenJournalLineDataTransfer.AddFieldValue(PostedGenJournalLine.FieldNo("IC Partner G/L Acc. No."), PostedGenJournalLine.FieldNo("IC Account No."));
        PostedGenJournalLineDataTransfer.CopyFields();
        Clear(PostedGenJournalLineDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag());
    end;

    local procedure UpgradeICGLAccountNoInStandardGeneralJournalLine()
    var
        StandardGeneralJournalLine: Record "Standard General Journal Line";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        StandardGeneralJournalLineDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag()) then
            exit;

        StandardGeneralJournalLine.SetFilter("IC Partner G/L Acc. No.", '<> ''''');
        if StandardGeneralJournalLine.IsEmpty() then
            exit;

        StandardGeneralJournalLineDataTransfer.SetTables(Database::"Standard General Journal Line", Database::"Standard General Journal Line");
        StandardGeneralJournalLineDataTransfer.AddSourceFilter(StandardGeneralJournalLine.FieldNo("IC Partner G/L Acc. No."), '<> ''''');
        StandardGeneralJournalLineDataTransfer.AddConstantValue("IC Journal Account Type"::"G/L Account", StandardGeneralJournalLine.FieldNo("IC Account Type"));
        StandardGeneralJournalLineDataTransfer.AddFieldValue(StandardGeneralJournalLine.FieldNo("IC Partner G/L Acc. No."), StandardGeneralJournalLine.FieldNo("IC Account No."));
        StandardGeneralJournalLineDataTransfer.CopyFields();
        Clear(StandardGeneralJournalLineDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetICPartnerGLAccountNoUpgradeTag());
    end;

    local procedure UpgradeICOutboxTransactionSourceType()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        ICOutboxTransactionDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICOutboxTransactionSourceTypeUpgradeTag()) then
            exit;

        ICOutboxTransactionDataTransfer.SetTables(Database::"IC Outbox Transaction", Database::"IC Outbox Transaction");
        ICOutboxTransactionDataTransfer.AddFieldValue(ICOutboxTransaction.FieldNo("Source Type"), ICOutboxTransaction.FieldNo("IC Source Type"));
        ICOutboxTransactionDataTransfer.CopyFields();
        Clear(ICOutboxTransactionDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetICOutboxTransactionSourceTypeUpgradeTag());
    end;

    local procedure UpgradeICTransactionSourceType()
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        ICTransactionDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetICTransactionSourceTypeUpgradeTag()) then
            exit;

        ICTransactionDataTransfer.SetTables(Database::"IC Inbox Transaction", Database::"IC Inbox Transaction");
        ICTransactionDataTransfer.AddFieldValue(ICInboxTransaction.FieldNo("Source Type"), ICInboxTransaction.FieldNo("IC Source Type"));
        ICTransactionDataTransfer.CopyFields();
        Clear(ICTransactionDataTransfer);

        ICTransactionDataTransfer.SetTables(Database::"Handled IC Inbox Trans.", Database::"Handled IC Inbox Trans.");
        ICTransactionDataTransfer.AddFieldValue(HandledICInboxTrans.FieldNo("Source Type"), HandledICInboxTrans.FieldNo("IC Source Type"));
        ICTransactionDataTransfer.CopyFields();
        Clear(ICTransactionDataTransfer);

        ICTransactionDataTransfer.SetTables(Database::"Handled IC Outbox Trans.", Database::"Handled IC Outbox Trans.");
        ICTransactionDataTransfer.AddFieldValue(HandledICOutboxTrans.FieldNo("Source Type"), HandledICOutboxTrans.FieldNo("IC Source Type"));
        ICTransactionDataTransfer.CopyFields();
        Clear(ICTransactionDataTransfer);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetICTransactionSourceTypeUpgradeTag());
    end;
}

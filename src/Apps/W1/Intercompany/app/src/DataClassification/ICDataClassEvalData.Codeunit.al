// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.DataExchange;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using System.Privacy;

/// <summary>
/// Extends Data Classification Eval. Data with Intercompany-specific table classification.
/// Classifies all IC-related tables and their fields for GDPR/data sensitivity evaluation.
/// </summary>
codeunit 8500 "IC Data Class. Eval. Data"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classification Eval. Data", 'OnCreateEvaluationDataOnAfterClassifyTablesToNormal', '', false, false)]
    local procedure OnClassifyIntercompanyTables()
    begin
        ClassifyICTablesToNormal();
        ClassifyICOutboxPurchaseHeader();
        ClassifyHandledICInboxPurchHeader();
        ClassifyHandledICInboxSalesHeader();
        ClassifyICInboxPurchaseHeader();
        ClassifyICInboxSalesHeader();
        ClassifyHandledICOutboxPurchHdr();
        ClassifyICPartner();
        ClassifyICOutboxSalesHeader();
        ClassifyHandledICOutboxSalesHeader();
        ClassifyICBankAccount();
        ClassifyICAPILog();
    end;

    local procedure ClassifyICTablesToNormal()
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"IC G/L Account");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"IC Dimension");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"IC Dimension Value");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"IC Outbox Transaction");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"IC Outbox Jnl. Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Handled IC Outbox Trans.");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Handled IC Outbox Jnl. Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"IC Inbox Transaction");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"IC Inbox Jnl. Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Handled IC Inbox Trans.");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Handled IC Inbox Jnl. Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"IC Inbox/Outbox Jnl. Line Dim.");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"IC Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"IC Outbox Sales Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"IC Outbox Purchase Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Handled IC Outbox Sales Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Handled IC Outbox Purch. Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"IC Inbox Sales Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"IC Inbox Purchase Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Handled IC Inbox Sales Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Handled IC Inbox Purch. Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"IC Document Dimension");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"IC Setup");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Buffer IC Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Buffer IC Document Dimension");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Buffer IC Inbox Jnl. Line");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Buffer IC Inbox Purch Header");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Buffer IC Inbox Purchase Line");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Buffer IC Inbox Sales Header");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Buffer IC Inbox Sales Line");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Buffer IC Inbox Transaction");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Buffer IC InOut Jnl. Line Dim.");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"IC Incoming Notification");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"IC Outgoing Notification");
    end;

    local procedure ClassifyICOutboxPurchaseHeader()
    var
        DummyICOutboxPurchaseHeader: Record "IC Outbox Purchase Header";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Outbox Purchase Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICOutboxPurchaseHeader.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICOutboxPurchaseHeader.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICOutboxPurchaseHeader.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICOutboxPurchaseHeader.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICOutboxPurchaseHeader.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICOutboxPurchaseHeader.FieldNo("Ship-to Phone No."));
    end;

    local procedure ClassifyHandledICInboxPurchHeader()
    var
        DummyHandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Handled IC Inbox Purch. Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICInboxPurchHeader.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICInboxPurchHeader.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICInboxPurchHeader.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICInboxPurchHeader.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICInboxPurchHeader.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICInboxPurchHeader.FieldNo("Ship-to Phone No."));
    end;

    local procedure ClassifyHandledICInboxSalesHeader()
    var
        DummyHandledICInboxSalesHeader: Record "Handled IC Inbox Sales Header";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Handled IC Inbox Sales Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICInboxSalesHeader.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICInboxSalesHeader.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICInboxSalesHeader.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICInboxSalesHeader.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICInboxSalesHeader.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICInboxSalesHeader.FieldNo("Ship-to Phone No."));
    end;

    local procedure ClassifyICInboxPurchaseHeader()
    var
        DummyICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Inbox Purchase Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICInboxPurchaseHeader.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICInboxPurchaseHeader.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICInboxPurchaseHeader.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICInboxPurchaseHeader.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICInboxPurchaseHeader.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICInboxPurchaseHeader.FieldNo("Ship-to Phone No."));
    end;

    local procedure ClassifyICInboxSalesHeader()
    var
        DummyICInboxSalesHeader: Record "IC Inbox Sales Header";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Inbox Sales Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICInboxSalesHeader.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICInboxSalesHeader.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICInboxSalesHeader.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICInboxSalesHeader.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICInboxSalesHeader.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICInboxSalesHeader.FieldNo("Ship-to Phone No."));
    end;

    local procedure ClassifyHandledICOutboxPurchHdr()
    var
        DummyHandledICOutboxPurchHdr: Record "Handled IC Outbox Purch. Hdr";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Handled IC Outbox Purch. Hdr";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICOutboxPurchHdr.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICOutboxPurchHdr.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICOutboxPurchHdr.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICOutboxPurchHdr.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICOutboxPurchHdr.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICOutboxPurchHdr.FieldNo("Ship-to Phone No."));
    end;

    local procedure ClassifyICPartner()
    var
        DummyICPartner: Record "IC Partner";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Partner";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICPartner.FieldNo(Name));
    end;

    local procedure ClassifyICOutboxSalesHeader()
    var
        DummyICOutboxSalesHeader: Record "IC Outbox Sales Header";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Outbox Sales Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICOutboxSalesHeader.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICOutboxSalesHeader.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICOutboxSalesHeader.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICOutboxSalesHeader.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICOutboxSalesHeader.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICOutboxSalesHeader.FieldNo("Ship-to Phone No."));
    end;

    local procedure ClassifyHandledICOutboxSalesHeader()
    var
        DummyHandledICOutboxSalesHeader: Record "Handled IC Outbox Sales Header";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Handled IC Outbox Sales Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICOutboxSalesHeader.FieldNo("Ship-to Post Code"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICOutboxSalesHeader.FieldNo("Ship-to City"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICOutboxSalesHeader.FieldNo("Ship-to Address 2"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICOutboxSalesHeader.FieldNo("Ship-to Address"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICOutboxSalesHeader.FieldNo("Ship-to Name"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyHandledICOutboxSalesHeader.FieldNo("Ship-to Phone No."));
    end;

    local procedure ClassifyICBankAccount()
    var
        ICBankAccount: Record "IC Bank Account";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Bank Account";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, ICBankAccount.FieldNo(Name));
        DataClassificationMgt.SetFieldToPersonal(TableNo, ICBankAccount.FieldNo("Bank Account No."));
        DataClassificationMgt.SetFieldToPersonal(TableNo, ICBankAccount.FieldNo(IBAN));
    end;

    local procedure ClassifyICAPILog()
    var
        DummyICAPILog: Record "IC API Log";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        TableNo: Integer;
    begin
        TableNo := Database::"IC API Log";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICAPILog.FieldNo("Request Body"));
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyICAPILog.FieldNo("Response Body"));
    end;
}

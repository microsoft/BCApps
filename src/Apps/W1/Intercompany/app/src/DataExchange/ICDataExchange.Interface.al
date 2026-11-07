// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;

interface "IC Data Exchange"
{
    Access = Internal;

    procedure GetICPartnerICGLAccount(ICPartner: Record "IC Partner"; var TempICPartnerICGLAccount: Record "IC G/L Account" temporary);
    procedure GetICPartnerICDimension(ICPartner: Record "IC Partner"; var TempICPartnerICDimension: Record "IC Dimension" temporary);
    procedure GetICPartnerICDimensionValue(ICPartner: Record "IC Partner"; var TempICPartnerICDimensionValue: Record "IC Dimension Value" temporary);
    procedure GetICPartnerFromICPartner(ICPartner: Record "IC Partner"; var TempRegisteredICPartner: Record "IC Partner" temporary);
    procedure GetICPartnerFromICPartner(ICPartner: Record "IC Partner"; ICPartnerCode: Code[20]; var TempRegisteredICPartner: Record "IC Partner" temporary);
    procedure GetICPartnerICSetup(ICPartner: Record "IC Partner"; var TempICPartnerICSetup: Record "IC Setup" temporary);
    procedure GetICPartnerICSetup(ICPartnerName: Text; var TempICPartnerICSetup: Record "IC Setup" temporary);
    procedure GetICPartnerGeneralLedgerSetup(ICPartner: Record "IC Partner"; var TempICPartnerGeneralLedgerSetup: Record "General Ledger Setup" temporary);
    procedure GetICPartnerGeneralLedgerSetup(ICPartnerName: Text; var TempICPartnerGeneralLedgerSetup: Record "General Ledger Setup" temporary);
    procedure GetICPartnerCompanyInformation(ICPartner: Record "IC Partner"; var TempICPartnerCompanyInformation: Record "Company Information" temporary);
    procedure GetICPartnerCompanyInformation(ICPartnerName: Text; var TempICPartnerCompanyInformation: Record "Company Information" temporary);
    procedure GetICPartnerBankAccount(ICPartner: Record "IC Partner"; var TempICPartnerBankAccount: Record "Bank Account" temporary);
    procedure GetICPartnerICInboxTransaction(ICPartner: Record "IC Partner"; var TempICPartnerICInboxTransaction: Record "IC Inbox Transaction" temporary);
    procedure GetICPartnerHandledICInboxTransaction(ICPartner: Record "IC Partner"; var TempICPartnerHandledICInboxTransaction: Record "Handled IC Inbox Trans." temporary);

    procedure PostICTransactionToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxTransaction: Record "IC Inbox Transaction" temporary);
    procedure PostICJournalLineToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxJnlLine: Record "IC Inbox Jnl. Line" temporary);
    procedure PostICPurchaseHeaderToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxPurchaseHeader: Record "IC Inbox Purchase Header" temporary; var RegisteredPartner: Record "IC Partner" temporary);
    procedure PostICPurchaseLineToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxPurchaseLine: Record "IC Inbox Purchase Line" temporary);
    procedure PostICSalesHeaderToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxSalesHeader: Record "IC Inbox Sales Header" temporary; var RegisteredPartner: Record "IC Partner" temporary);
    procedure PostICSalesLineToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxSalesLine: Record "IC Inbox Sales Line" temporary);
    procedure PostICJournalLineDimensionToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim." temporary);
    procedure PostICDocumentDimensionToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICDocDim: Record "IC Document Dimension" temporary);
    procedure PostICCommentLineToICPartnerInbox(ICPartner: Record "IC Partner"; var TempICPartnerICInboxCommentLine: Record "IC Comment Line" temporary);
    procedure EnqueueAutoAcceptedICInboxTransaction(ICPartner: Record "IC Partner"; ICInboxTransaction: Record "IC Inbox Transaction");
}
